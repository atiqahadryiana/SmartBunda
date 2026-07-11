/// SmartBunda — Ollama Cloud food vision service (scanner fallback).
///
/// Used when the primary OpenRouter scanner ([FoodVisionService]) fails. Sends
/// the meal photo to the hosted Ollama Cloud chat API and asks it to identify
/// the food(s), returning a ranked list of [FoodImagePrediction] in the same
/// shape as the primary scanner.
///
/// Ollama Cloud's chat API differs from OpenRouter's: the request is
/// `POST https://ollama.com/api/chat` with `Authorization: Bearer <key>`, the
/// image goes in the message's `images` array as a bare base64 string (no
/// data: URL prefix), and the reply text is under `message.content`.
///
/// Mobile-only: refuses to run on Flutter web so the key is never shipped in
/// the public web bundle. Throws [FoodImageClassifierException] on any failure
/// so the scan flow can fall back to manual entry.
library smartbunda.ollama_vision_service;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'package:smartbunda/config/ai_config.dart';
import 'package:smartbunda/services/food_vision_shared.dart';

class OllamaVisionService {
  OllamaVisionService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://ollama.com/api/chat';

  bool get isAvailable => !kIsWeb && AiConfig.ollamaEnabled;

  /// Sends [bytes] to the Ollama Cloud vision model and returns up to [topK]
  /// detected foods, ranked by confidence.
  Future<List<FoodImagePrediction>> classifyBytes(
    Uint8List bytes, {
    int topK = 5,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (kIsWeb) {
      throw const FoodImageClassifierException(
        'AI food scanning is available on the SmartBunda mobile app. '
        'You can still log meals manually.',
      );
    }
    if (!AiConfig.ollamaEnabled) {
      throw const FoodImageClassifierException(
        'Backup food scanner is not configured yet. '
        'You can still log meals manually.',
      );
    }
    if (bytes.isEmpty) {
      throw const FoodImageClassifierException(
        'Could not read the selected image. Try a different photo.',
      );
    }

    final body = jsonEncode({
      'model': AiConfig.ollamaVisionModel,
      'stream': false,
      'messages': [
        {'role': 'system', 'content': kFoodVisionSystemPrompt},
        {
          'role': 'user',
          'content': kFoodVisionUserPrompt,
          'images': [base64Encode(bytes)],
        },
      ],
    });

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer ${AiConfig.ollamaApiKey}',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(timeout);
    } catch (error) {
      throw FoodImageClassifierException(
        'Could not reach the backup food scanner. Please check your '
        'connection. You can still log meals manually.',
        cause: error,
      );
    }

    if (response.statusCode != 200) {
      throw FoodImageClassifierException(
        'Backup food scanner request failed (${response.statusCode}). '
        'You can still log meals manually.',
      );
    }

    final String content;
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final message = decoded['message'] as Map<String, dynamic>?;
      content = ((message?['content'] as String?) ?? '').trim();
    } catch (error) {
      throw FoodImageClassifierException(
        'Could not understand the backup food scanner response. '
        'You can still log meals manually.',
        cause: error,
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

  void dispose() => _client.close();
}
