/// SmartBunda — AI assistant configuration TEMPLATE.
///
/// SETUP:
///   1. Copy this file to `ai_config.dart` in the same folder.
///   2. Paste your OpenRouter API key into [openRouterApiKey].
///   3. `ai_config.dart` is gitignored — it must NEVER be committed.
///
/// Get a key at https://openrouter.ai/keys
///
/// The AI assistant is intentionally mobile-only. Even with a key present, the
/// service refuses to run on Flutter web so the key is never shipped in the
/// public web bundle (see [AiAssistantService]).
class AiConfig {
  /// OpenRouter API key. Leave as the placeholder here; set the real value only
  /// in the gitignored `ai_config.dart`.
  static const String openRouterApiKey = 'sk-or-v1-REPLACE_ME';

  /// Model used for the nutrition assistant.
  static const String model =
      'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free';

  /// True only when a real key has been provided (not the placeholder).
  static const bool enabled = openRouterApiKey != 'sk-or-v1-REPLACE_ME' &&
      openRouterApiKey.length > 12;
}
