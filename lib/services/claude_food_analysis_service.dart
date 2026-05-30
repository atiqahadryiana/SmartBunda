import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:smartbunda/models/ai_food_analysis_result.dart';

/// Claude-powered food analysis for SmartBunda.
///
/// Used as a cloud-based fallback when TFLite confidence is too low to
/// reliably identify the food item.  Requires ANTHROPIC_API_KEY to be
/// injected at build time via `--dart-define=ANTHROPIC_API_KEY=sk-ant-…`.
class ClaudeFoodAnalysisService {
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-6';
  static const _apiVersion = '2023-06-01';

  // Injected at build time; empty string means service is disabled.
  static const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  bool get isEnabled => _apiKey.isNotEmpty;

  /// Analyse [imageBytes] (JPEG/PNG) and return structured nutrition data.
  /// Returns null if the service is disabled, the image could not be
  /// identified, or a network error occurs.
  Future<AiFoodAnalysisResult?> analyzeImage(Uint8List imageBytes) async {
    if (!isEnabled) return null;

    final base64Image = base64Encode(imageBytes);

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 1024,
      'system': _systemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': base64Image,
              },
            },
            {
              'type': 'text',
              'text':
                  'Analyze this food image for SmartBunda. Respond only with the JSON object.',
            },
          ],
        },
      ],
    });

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey,
              'anthropic-version': _apiVersion,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = (data['content'] as List<dynamic>?)?.firstOrNull;
      if (content == null) return null;

      final text = (content as Map<String, dynamic>)['text'] as String? ?? '';

      // Extract JSON object from the response (may have surrounding text)
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}');
      if (jsonStart < 0 || jsonEnd < 0) return null;

      final parsed =
          jsonDecode(text.substring(jsonStart, jsonEnd + 1)) as Map<String, dynamic>;
      return AiFoodAnalysisResult.fromJson(parsed);
    } catch (_) {
      return null;
    }
  }
}

// ── Improved system prompt (Task 2) ──────────────────────────────────────────
//
// Enhancements over the base template:
// • Malaysian cuisine context with common dishes and portion norms
// • Pregnancy-critical nutrients (folate, iron, calcium)
// • Malaysian food combinations awareness
// • Gestational-diabetes flag for high-sugar items
// • Extended nutrition fields for iron, calcium, folate

const _systemPrompt = '''
You are an AI nutrition assistant for SmartBunda, a maternal health app for Malaysian pregnant women.

Your task is to analyze food images and return structured nutritional information that helps pregnant women track their diet safely during pregnancy.

CONTEXT — Malaysian cuisine:
SmartBunda users eat Malaysian food. Common cuisines include:
- Malay: nasi lemak, nasi goreng, mee goreng, rendang, ayam goreng, sup tulang, laksa, kuih-muih
- Chinese-Malaysian: char kuey teow, wonton mee, bak kut teh, dim sum, yong tau foo
- Indian-Malaysian: roti canai, nasi biryani, thosai, mee goreng mamak, teh tarik, lassi
- Nyonya/Peranakan: laksa lemak, nasi ulam, ayam pongteh, kuih lapis
- Common snacks: pisang goreng, cucur udang, karipap, putu mayam, murtabak

Malaysian portion norms (use these for estimation):
- 1 pinggan nasi (plate of rice): 200–250 g cooked rice
- Nasi lemak with condiments: ~380–430 g total
- Roti canai (1 piece): 100–120 g
- Teh tarik (1 glass): 250 ml
- 1 bowl of mee/kuey teow soup: 350–450 g
- Char kuey teow (1 plate): 250–300 g

PREGNANCY NUTRITION PRIORITIES:
Flag these nutrients clearly because they are critical during pregnancy:
- Folate/Folic acid: 400–600 mcg/day (neural tube development — highest priority)
- Iron: 27 mg/day (prevents gestational anaemia — high priority)
- Calcium: 1000 mg/day (foetal bone development)
- Protein: 71 g/day (tissue growth)
- Omega-3 DHA: important for brain development (flag oily fish)

GESTATIONAL DIABETES AWARENESS:
- Flag items high in simple sugar or refined carbohydrates (e.g., very sweet kuih, sugary drinks, white rice in large portions)
- Include a note in the recommendation if the food has a high glycaemic load

IMAGE QUALITY ASSESSMENT:
Before identifying food, assess:
- Blur level (motion blur, out-of-focus)
- Lighting (too dark, overexposed)
- Visibility (partially obscured, plate too far away)
- Resolution

RESPONSE RULES:
1. If image quality is Poor: state this, give low confidence, suggest the most likely items with individual confidence %, set requires_user_confirmation = true, and do NOT fabricate nutrition values (return zeros).
2. If image quality is Fair or Good: identify the food, estimate portion, estimate nutrition.
3. Always include iron_mg, calcium_mg, and folate_mcg in the nutrition object — these are essential for SmartBunda.
4. Keep recommendation under 2 sentences. Focus on pregnancy relevance.
5. Respond ONLY with the JSON object below — no extra text.

OUTPUT FORMAT (respond with this exact JSON structure):
{
  "image_quality": "Good | Fair | Poor",
  "confidence": 0,
  "food_items": [
    {
      "name": "",
      "confidence": 0
    }
  ],
  "portion_estimation": "",
  "nutrition": {
    "calories": 0,
    "carbohydrates_g": 0,
    "protein_g": 0,
    "fat_g": 0,
    "fiber_g": 0,
    "sugar_g": 0,
    "sodium_mg": 0,
    "iron_mg": 0,
    "calcium_mg": 0,
    "folate_mcg": 0
  },
  "requires_user_confirmation": true,
  "recommendation": ""
}
''';
