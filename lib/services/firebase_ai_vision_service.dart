/// SmartBunda — Firebase AI Logic (Gemini Developer API) food vision service.
///
/// PRIMARY food scanner. Sends the meal photo to Gemini via the official
/// `firebase_ai` plugin using the **Gemini Developer API** backend
/// (`FirebaseAI.googleAI()`, NOT Vertex AI) and asks it to identify the
/// food(s), returning a ranked list of [FoodImagePrediction] in the same shape
/// as the OpenRouter / Ollama scanners.
///
/// Auth/keys are handled by Firebase AI Logic on the project, so there is no
/// API key in the client. Works on web and mobile. On any failure it throws
/// [FoodImageClassifierException] so the scan flow can fall back to the other
/// scanners and finally to manual entry.
library smartbunda.firebase_ai_vision_service;

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:firebase_ai/firebase_ai.dart';

import 'package:smartbunda/config/ai_config.dart';
import 'package:smartbunda/services/food_vision_shared.dart';

class FirebaseAiVisionService {
  FirebaseAiVisionService({GenerativeModel? model, String? modelName})
      : _injectedModel = model,
        _modelName = modelName ?? AiConfig.geminiVisionModel;

  final GenerativeModel? _injectedModel;

  /// Which Gemini model this instance targets (defaults to the primary). A
  /// second instance can be built on [AiConfig.geminiVisionModelFallback] to
  /// retry on a model with a separate free-tier quota.
  final String _modelName;

  GenerativeModel? _model;

  /// Lazily builds the Gemini model via the Gemini Developer API backend.
  /// The food-recognition instruction is passed as the system instruction so
  /// the model returns the bare JSON array the shared parser expects.
  GenerativeModel _resolveModel() {
    return _injectedModel ??
        (_model ??= FirebaseAI.googleAI().generativeModel(
          model: _modelName,
          systemInstruction: Content.text(kFoodVisionSystemPrompt),
        ));
  }

  /// Sends [bytes] to Gemini and returns up to [topK] detected foods, ranked by
  /// confidence. Throws [FoodImageClassifierException] on any failure.
  Future<List<FoodImagePrediction>> classifyBytes(
    Uint8List bytes, {
    int topK = 5,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (bytes.isEmpty) {
      throw const FoodImageClassifierException(
        'Could not read the selected image. Try a different photo.',
      );
    }

    final String content;
    try {
      final model = _resolveModel();
      final response = await model.generateContent(
        [
          Content.multi([
            const TextPart(kFoodVisionUserPrompt),
            InlineDataPart('image/jpeg', bytes),
          ]),
        ],
      ).timeout(timeout);
      content = (response.text ?? '').trim();
    } catch (error, stack) {
      // Surface the REAL Firebase AI Logic error so failures (API not enabled,
      // model not found, App Check, auth) are diagnosable instead of hidden
      // behind the generic message below.
      // Log the real cause to the console for diagnostics (not shown to users).
      debugPrint('[FirebaseAiVisionService] Gemini call failed '
          '(model=$_modelName): $error');
      debugPrint('$stack');
      throw FoodImageClassifierException(
        'Could not reach the food scanner. Please check your connection. '
        'You can still log meals manually.',
        cause: error,
      );
    }

    if (content.isEmpty) {
      throw const FoodImageClassifierException(
        'Food scanner returned an empty response. '
        'You can still log meals manually.',
      );
    }

    final predictions = parseFoodPredictions(content);
    if (predictions.isEmpty) {
      throw const FoodImageClassifierException(
        "Couldn't identify any food in this photo. "
        'Try a clearer, closer photo or log the meal manually.',
      );
    }

    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return predictions.take(topK).toList();
  }
}
