/// SmartBunda — shared helpers for the AI food-vision scanners.
///
/// The OpenRouter ([FoodVisionService]) and Ollama Cloud
/// ([OllamaVisionService]) scanners use the same prompt and the same
/// JSON-array reply format; only the HTTP request/response envelope differs.
/// This file holds the bits they share so the two stay in sync.
library smartbunda.food_vision_shared;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

// ── Upload payload optimisation ───────────────────────────────────────────

/// Longest-side, in pixels, that the meal photo is downscaled to before being
/// sent to a vision model. Vision LLMs internally tile/resize to ~768px, so
/// uploading anything larger just costs upload + processing time for no
/// recognition gain. Shrinking here is the single biggest scan-latency win.
const int kVisionMaxDimension = 768;

/// JPEG quality used when re-encoding the downscaled photo. 80 keeps dishes
/// clearly recognisable while keeping the payload small.
const int kVisionJpegQuality = 80;

/// Downscales [bytes] to at most [kVisionMaxDimension] on the longest side and
/// re-encodes as JPEG, off the UI thread. Returns the original bytes unchanged
/// if decoding fails or the image is already small enough, so a quirky photo
/// never blocks a scan. Call this ONCE before the scanner chain and pass the
/// result to every scanner.
Future<Uint8List> compressForVision(Uint8List bytes) {
  return compute(_compressForVisionIsolate, bytes);
}

Uint8List _compressForVisionIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final longest =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  if (longest <= kVisionMaxDimension) return bytes;

  final resized = img.copyResize(
    decoded,
    width: decoded.width >= decoded.height ? kVisionMaxDimension : null,
    height: decoded.height > decoded.width ? kVisionMaxDimension : null,
    interpolation: img.Interpolation.average,
  );
  return img.encodeJpg(resized, quality: kVisionJpegQuality);
}

// ── Data types used by both cloud vision scanners ─────────────────────────

class FoodImagePrediction {
  const FoodImagePrediction({
    required this.label,
    required this.confidence,
    this.description,
  });

  final String label;
  final double confidence;

  /// Short description of the dish (e.g. its main ingredients), surfaced on the
  /// result card and saved into the meal entry's notes. Null when not provided.
  final String? description;

  String get confidenceLabel => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Human-readable display name (underscores → spaces, title case).
  String get displayName {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Qualitative confidence tier used for UI badge colour.
  ConfidenceTier get tier {
    if (confidence >= 0.70) return ConfidenceTier.high;
    if (confidence >= 0.40) return ConfidenceTier.medium;
    return ConfidenceTier.low;
  }
}

enum ConfidenceTier { high, medium, low }

class FoodImageClassifierException implements Exception {
  const FoodImageClassifierException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null ? '$message\nCause: $cause' : message;

  /// Returns a short user-facing error that does not expose internals.
  String get userMessage {
    final m = message.toLowerCase();
    if (m.contains('not ready') || m.contains('asset') || m.contains('missing')) {
      return 'Food scanner is not ready yet. '
          'Please reinstall the app or contact support.';
    }
    if (m.contains('precondition') || m.contains('failed') || m.contains('model')) {
      return 'Scanner model error. '
          'Please update the app or contact support. '
          'You can still log meals manually.';
    }
    if (m.contains('image') || m.contains('decode')) {
      return 'Could not read the image. '
          'Try a different photo (JPEG or PNG recommended).';
    }
    return 'Scanner failed. You can still log your meal manually.';
  }
}

// ── Shared prompts ─────────────────────────────────────────────────────────

/// Instructs the vision model to return ONLY a JSON array of detected dishes.
const String kFoodVisionSystemPrompt =
    'You are a food recognition system for a Malaysian maternal-nutrition '
    'app. Identify the complete DISHES or food items in the photo — NOT the '
    'individual ingredients. For example, return "Nasi Lemak" as ONE item, do '
    'not list its rice, sambal, egg, and peanuts separately. Prefer specific '
    'Malaysian dish names (e.g. "Nasi Lemak", "Char Kuey Teow", "Roti Canai") '
    'when applicable, otherwise use the common English food name. '
    'Respond with ONLY a JSON array, no prose, no markdown fences. Each '
    'element must be an object with exactly three keys: "food" (the dish name, '
    'string), "confidence" (number between 0 and 1), and "description" (a short '
    'phrase listing the visible main ingredients or components of that dish, '
    'string). Order the array from most to least confident. Treat a plate that '
    'holds several distinct dishes as separate array items. If the image '
    'clearly contains no food, return an empty array [].';

/// The user turn paired with the image.
const String kFoodVisionUserPrompt =
    'Identify the DISHES in this image (not ingredients). Return only the JSON '
    'array described, with a short ingredient description per dish.';

/// Parses a model reply into predictions. The model is asked for a bare JSON
/// array, but we defensively strip markdown fences and locate the array in
/// case it wraps the JSON in prose.
List<FoodImagePrediction> parseFoodPredictions(String raw) {
  var text = raw.trim();

  // Strip ```json ... ``` / ``` ... ``` fences if present.
  if (text.startsWith('```')) {
    text = text.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();
  }

  // If there's surrounding prose, extract the first [...] block.
  if (!text.startsWith('[')) {
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start != -1 && end > start) {
      text = text.substring(start, end + 1);
    }
  }

  dynamic parsed;
  try {
    parsed = jsonDecode(text);
  } catch (_) {
    return const [];
  }
  if (parsed is! List) return const [];

  final result = <FoodImagePrediction>[];
  for (final item in parsed) {
    if (item is! Map) continue;
    final food = (item['food'] ?? item['name'] ?? item['label']);
    if (food is! String || food.trim().isEmpty) continue;
    final rawDesc = (item['description'] ?? item['ingredients'] ?? item['detail']);
    final desc = rawDesc is String && rawDesc.trim().isNotEmpty
        ? rawDesc.trim()
        : null;
    result.add(
      FoodImagePrediction(
        label: food.trim(),
        confidence: asConfidence(item['confidence']),
        description: desc,
      ),
    );
  }
  return result;
}

/// Coerces a confidence value into the 0–1 range. Accepts numbers, numeric
/// strings, and percentages (e.g. 91 → 0.91); defaults to 0.5 when missing.
double asConfidence(dynamic value) {
  double? n;
  if (value is num) {
    n = value.toDouble();
  } else if (value is String) {
    n = double.tryParse(value.replaceAll('%', '').trim());
  }
  if (n == null) return 0.5;
  if (n > 1.0) n = n / 100.0;
  return n.clamp(0.0, 1.0);
}
