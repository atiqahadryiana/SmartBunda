/// SmartBunda — Nutrition Guideline (highest-priority recommendation source).
///
/// Represents an attached / administrator-provided nutrition guideline. The AI
/// food-recommendation engine treats this as the **#1 source of truth**: its
/// nutrient targets, prohibited foods, and meal rules override generic
/// recommendations whenever they conflict.
///
/// A built-in [maternalDefault] is provided so the engine always has a
/// guideline to follow (MOH Malaysia maternal nutrition). Future work: allow
/// staff to upload/replace guidelines (stored in Firestore); the engine and
/// audit trail already carry the [version] / [source] needed for that.
class NutritionGuideline {
  const NutritionGuideline({
    required this.version,
    required this.source,
    required this.title,
    required this.nutrientTargets,
    required this.prohibitedFoods,
    required this.prohibitedCategories,
    required this.mealRules,
    this.maxSodiumMgPerMeal,
    this.maxSugarGPerMeal,
  });

  /// Guideline version string, stored on every recommendation for traceability.
  final String version;

  /// e.g. "Ministry of Health Malaysia — Maternal Nutrition (built-in)".
  final String source;
  final String title;

  /// Daily nutrient targets the guideline mandates (subset; nulls fall back to
  /// the app's MOH `recommendedFor` targets). Keys: calories, protein, iron,
  /// calcium, folate, sodium.
  final Map<String, num> nutrientTargets;

  /// Lower-cased food names / aliases that must never be recommended.
  final List<String> prohibitedFoods;

  /// Food categories that must never be recommended (e.g. 'alcohol').
  final List<String> prohibitedCategories;

  /// Human-readable meal rules applied/displayed in the compliance section.
  final List<String> mealRules;

  /// Optional per-meal caps used in compliance checks.
  final num? maxSodiumMgPerMeal;
  final num? maxSugarGPerMeal;

  bool prohibits(String foodName, String category) {
    final name = foodName.toLowerCase();
    if (prohibitedCategories.contains(category.toLowerCase())) return true;
    return prohibitedFoods.any((p) => name.contains(p) || p.contains(name));
  }

  Map<String, dynamic> toMap() => {
        'version': version,
        'source': source,
        'title': title,
        'nutrientTargets': nutrientTargets,
        'prohibitedFoods': prohibitedFoods,
        'prohibitedCategories': prohibitedCategories,
        'mealRules': mealRules,
        if (maxSodiumMgPerMeal != null)
          'maxSodiumMgPerMeal': maxSodiumMgPerMeal,
        if (maxSugarGPerMeal != null) 'maxSugarGPerMeal': maxSugarGPerMeal,
      };

  factory NutritionGuideline.fromMap(Map<String, dynamic> data) {
    return NutritionGuideline(
      version: (data['version'] as String?) ?? 'unknown',
      source: (data['source'] as String?) ?? '',
      title: (data['title'] as String?) ?? 'Nutrition Guideline',
      nutrientTargets: (data['nutrientTargets'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v as num),
          ) ??
          const {},
      prohibitedFoods: (data['prohibitedFoods'] as List?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          const [],
      prohibitedCategories: (data['prohibitedCategories'] as List?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          const [],
      mealRules: (data['mealRules'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      maxSodiumMgPerMeal: data['maxSodiumMgPerMeal'] as num?,
      maxSugarGPerMeal: data['maxSugarGPerMeal'] as num?,
    );
  }

  /// Built-in default guideline: MOH Malaysia maternal nutrition + universal
  /// pregnancy food-safety exclusions. Used when no guideline has been
  /// attached by an administrator/clinician.
  static const NutritionGuideline maternalDefault = NutritionGuideline(
    version: 'moh-my-maternal-1.0',
    source: 'Ministry of Health Malaysia — Maternal Nutrition (built-in)',
    title: 'Maternal Nutrition Guideline',
    // Daily targets here are indicative; the engine prefers the patient-specific
    // `recommendedFor()` values and uses these only as guideline-mandated floors.
    nutrientTargets: {
      'protein': 71,
      'iron': 30,
      'calcium': 1000,
      'folate': 600,
      'sodium': 2000,
    },
    // Pregnancy-unsafe foods that must always be excluded.
    prohibitedFoods: [
      'alcohol',
      'raw egg',
      'raw fish',
      'sashimi',
      'sushi',
      'raw oyster',
      'unpasteurized',
      'unpasteurised',
      'soft cheese',
      'pate',
      'liver pate',
      'swordfish',
      'king mackerel',
      'shark',
      'marlin',
      'raw',
    ],
    prohibitedCategories: ['alcohol'],
    mealRules: [
      'Follows MOH maternal nutrition guidance.',
      'Pregnancy-safe food choice (no alcohol, raw or unpasteurized items).',
      'Supports daily protein, iron, calcium and folate targets.',
      'Limits high-sodium and high-sugar choices.',
    ],
    maxSodiumMgPerMeal: 800,
    maxSugarGPerMeal: 25,
  );
}
