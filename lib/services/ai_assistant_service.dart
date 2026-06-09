/// SmartBunda — AI nutrition assistant service.
///
/// Thin OpenRouter (chat completions) client used by the in-app nutrition
/// assistant. Mobile-only: the service refuses to run on Flutter web so the API
/// key is never shipped in the public web bundle. When no key is configured it
/// throws [AiUnavailable] so the UI can fall back gracefully.
library smartbunda.ai_assistant_service;

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../config/ai_config.dart';

/// A single conversation turn sent to the model.
class ChatTurn {
  const ChatTurn({required this.role, required this.content});

  /// 'user' or 'assistant'.
  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// Thrown when the assistant cannot run (web build, or no key configured).
class AiUnavailable implements Exception {
  const AiUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thrown when the OpenRouter request fails (network / non-200 / parse).
class AiAssistantException implements Exception {
  const AiAssistantException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class AiAssistantService {
  AiAssistantService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint =
      'https://openrouter.ai/api/v1/chat/completions';

  /// Scopes the model to safe, supportive maternal-nutrition guidance.
  static const _systemPrompt =
      'You are the SmartBunda nutrition assistant, supporting pregnant mothers '
      'and new parents. Give brief, warm, practical guidance on pregnancy and '
      'maternal nutrition, hydration, and healthy habits, grounded in general '
      'Malaysian and WHO healthy-eating principles. Keep answers short (2–4 '
      'sentences). You do NOT diagnose, prescribe, or replace medical care: for '
      'anything clinical, symptoms, medication, or concerns, advise the user to '
      'consult their doctor, nurse, or dietitian. If a question is outside '
      'maternal health and nutrition, gently steer back.';

  bool get isAvailable => !kIsWeb && AiConfig.enabled;

  /// Sends [history] (the running conversation) to the model and returns the
  /// assistant reply text. [history] should already include the latest user
  /// turn as its final element.
  Future<String> ask(
    List<ChatTurn> history, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (kIsWeb) {
      throw const AiUnavailable(
        'The AI assistant is available on the SmartBunda mobile app.',
      );
    }
    if (!AiConfig.enabled) {
      throw const AiUnavailable(
        'AI assistant is not configured yet.',
      );
    }

    final body = jsonEncode({
      'model': AiConfig.model,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        ...history.map((t) => t.toJson()),
      ],
      'reasoning': {'enabled': true},
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
      throw const AiAssistantException(
        'Could not reach the assistant. Please check your connection.',
      );
    }

    if (response.statusCode != 200) {
      throw AiAssistantException(
        'Assistant request failed (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw const AiAssistantException('Empty response from assistant.');
      }
      final message =
          (choices.first as Map<String, dynamic>)['message']
              as Map<String, dynamic>?;
      final content = (message?['content'] as String?)?.trim();
      if (content == null || content.isEmpty) {
        throw const AiAssistantException('Empty response from assistant.');
      }
      return content;
    } on AiAssistantException {
      rethrow;
    } catch (_) {
      throw const AiAssistantException(
        'Could not understand the assistant response.',
      );
    }
  }

  void dispose() => _client.close();
}
