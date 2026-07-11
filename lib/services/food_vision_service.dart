/// SmartBunda — AI food vision service.
///
/// Sends a captured/uploaded meal photo to an OpenRouter vision model and asks
/// it to identify the food(s) in the image, returning a ranked list of
/// [FoodImagePrediction] (one per detected dish, highest confidence first).
///
/// The image goes to the configured AI API, the API identifies the food and
/// returns the prediction, and the UI lets the user verify which detections are
/// correct.
///
/// Mobile-only: like [AiAssistantService], it refuses to run on Flutter web so
/// the API key is never shipped in the public web bundle. When no key is
/// configured it throws [FoodImageClassifierException] so the existing scan-flow
/// error handling (manual-entry fallback) kicks in unchanged.
library smartbunda.food_vision_service;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'package:smartbunda/config/ai_config.dart';
import 'package:smartbunda/services/food_vision_shared.dart';

class FoodVisionService {
  FoodVisionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  bool get isAvailable => !kIsWeb && AiConfig.enabled;

  /// Sends [bytes] to the vision model and returns up to [topK] detected foods,
  /// ranked by confidence. Throws [FoodImageClassifierException] on any failure
  /// so the scan flow can fall back to manual entry.
  Future<List<FoodImagePrediction>> classifyBytes(
    Uint8List bytes, {
    int topK = 5,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (kIsWeb) {
      throw const FoodImageClassifierException(
        'AI food scanning is available on the SmartBunda mobile app. '
        'You can still log meals manually.',
      );
    }
    if (!AiConfig.enabled) {
      throw const FoodImageClassifierException(
        'Food scanner is not configured yet. '
        'You can still log meals manually.',
      );
    }
    if (bytes.isEmpty) {
      throw const FoodImageClassifierException(
        'Could not read the selected image. Try a different photo.',
      );
    }

    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    final body = jsonEncode({
      'model': AiConfig.visionModel,
      'messages': [
        {'role': 'system', 'content': kFoodVisionSystemPrompt},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': kFoodVisionUserPrompt},
            {
              'type': 'image_url',
              'image_url': {'url': dataUrl},
            },
          ],
        },
      ],
    });

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer ${AiConfig.openRouterApiKey}',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://smartbunda.app',
              'X-Title': 'SmartBunda',
            },
            body: body,
          )
          .timeout(timeout);
    } catch (error) {
      throw FoodImageClassifierException(
        'Could not reach the food scanner. Please check your connection. '
        'You can still log meals manually.',
        cause: error,
      );
    }

    if (response.statusCode != 200) {
      throw FoodImageClassifierException(
        'Food scanner request failed (${response.statusCode}). '
        'You can still log meals manually.',
      );
    }

    final String content;
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw const FoodImageClassifierException(
          'Food scanner returned an empty response. '
          'You can still log meals manually.',
        );
      }
      final message =
          (choices.first as Map<String, dynamic>)['message']
              as Map<String, dynamic>?;
      content = ((message?['content'] as String?) ?? '').trim();
    } on FoodImageClassifierException {
      rethrow;
    } catch (error) {
      throw FoodImageClassifierException(
        'Could not understand the food scanner response. '
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
