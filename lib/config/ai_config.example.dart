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

  /// Model used for the nutrition assistant. Must be a real OpenRouter slug.
  static const String model =
      'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free';

  /// Vision model used by the OpenRouter FALLBACK scanner. Must be a real
  /// OpenRouter slug that accepts image input. (Gemini 2.0 Flash shut down
  /// 2026-06-01 and OpenRouter no longer offers a free Gemini vision model;
  /// 'google/gemma-4-31b-it:free' is a current free option. Paid alternative:
  /// 'google/gemini-2.5-flash'.)
  static const String visionModel = 'google/gemma-4-31b-it:free';

  /// Gemini vision model used by the PRIMARY food scanner via Firebase AI Logic
  /// (Gemini Developer API). No API key needed — auth is handled by Firebase AI
  /// Logic. Using gemini-3.5-flash which is current and supported.
  static const String geminiVisionModel = 'gemini-3.5-flash';

  /// SECOND Gemini Flash model (Firebase AI Logic) — separate free-tier quota.
  static const String geminiVisionModelFallback = 'gemini-2.5-flash';

  /// THIRD Gemini Flash model (Firebase AI Logic), the lightest tier. The food
  /// scanner runs every Gemini Flash model Firebase AI Logic offers, in order.
  static const String geminiVisionModelLite = 'gemini-2.5-flash-lite';

  /// True only when a real key has been provided (not the placeholder).
  static const bool enabled = openRouterApiKey != 'sk-or-v1-REPLACE_ME' &&
      openRouterApiKey.length > 12;

  // ── Ollama Cloud fallback (food scanner) ───────────────────────────────────
  // If the OpenRouter vision call fails, the scanner falls back to the hosted
  // Ollama Cloud API. Get a key at https://ollama.com (Settings → API keys).

  /// Ollama Cloud API key. Leave as the placeholder here; set the real value
  /// only in the gitignored `ai_config.dart`.
  static const String ollamaApiKey = 'OLLAMA_REPLACE_ME';

  /// Ollama Cloud vision model used as the scanner fallback.
  static const String ollamaVisionModel = 'llama3.2-vision';

  /// True only when a real Ollama key has been provided.
  static const bool ollamaEnabled =
      ollamaApiKey != 'OLLAMA_REPLACE_ME' && ollamaApiKey.length > 8;

  // ── On-device YOLOv8n-cls food scanner (smart split) ───────────────────────
  // The on-device classifier runs FIRST. Its top prediction is accepted only
  // when its confidence is at least [yoloConfidenceThreshold]; otherwise the
  // scan escalates to the Gemini cloud chain. Tune this on real photos: too
  // low and a wrong on-device guess shortcuts the more capable cloud models;
  // too high and the cloud is hit even when the on-device model was right.

  /// Minimum top-1 confidence (0–1) for the on-device YOLOv8 result to be used
  /// directly instead of escalating to the Gemini cloud scanners.
  static const double yoloConfidenceThreshold = 0.60;
}
