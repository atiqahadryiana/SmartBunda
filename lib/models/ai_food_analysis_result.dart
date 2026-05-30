/// Model for the structured JSON response from the Claude AI food analysis.
class AiFoodAnalysisResult {
  const AiFoodAnalysisResult({
    required this.imageQuality,
    required this.confidence,
    required this.foodItems,
    required this.portionEstimation,
    required this.nutrition,
    required this.requiresUserConfirmation,
    required this.recommendation,
  });

  final String imageQuality; // "Good" | "Fair" | "Poor"
  final int confidence; // 0–100
  final List<AiFoodItem> foodItems;
  final String portionEstimation;
  final AiNutrition nutrition;
  final bool requiresUserConfirmation;
  final String recommendation;

  factory AiFoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AiFoodAnalysisResult(
      imageQuality: (json['image_quality'] as String?) ?? 'Fair',
      confidence: (json['confidence'] as num?)?.toInt() ?? 0,
      foodItems: (json['food_items'] as List<dynamic>? ?? [])
          .map((e) => AiFoodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      portionEstimation: (json['portion_estimation'] as String?) ?? '',
      nutrition: AiNutrition.fromJson(
          (json['nutrition'] as Map<String, dynamic>?) ?? {}),
      requiresUserConfirmation:
          (json['requires_user_confirmation'] as bool?) ?? true,
      recommendation: (json['recommendation'] as String?) ?? '',
    );
  }
}

class AiFoodItem {
  const AiFoodItem({required this.name, required this.confidence});

  final String name;
  final int confidence; // 0–100

  factory AiFoodItem.fromJson(Map<String, dynamic> json) {
    return AiFoodItem(
      name: (json['name'] as String?) ?? '',
      confidence: (json['confidence'] as num?)?.toInt() ?? 0,
    );
  }
}

class AiNutrition {
  const AiNutrition({
    required this.calories,
    required this.carbohydratesG,
    required this.proteinG,
    required this.fatG,
    required this.fiberG,
    required this.sugarG,
    required this.sodiumMg,
    this.ironMg = 0,
    this.calciumMg = 0,
    this.folateMcg = 0,
  });

  final int calories;
  final double carbohydratesG;
  final double proteinG;
  final double fatG;
  final double fiberG;
  final double sugarG;
  final double sodiumMg;
  final double ironMg;
  final double calciumMg;
  final double folateMcg;

  factory AiNutrition.fromJson(Map<String, dynamic> json) {
    double d(String key) => (json[key] as num?)?.toDouble() ?? 0.0;
    int i(String key) => (json[key] as num?)?.toInt() ?? 0;
    return AiNutrition(
      calories: i('calories'),
      carbohydratesG: d('carbohydrates_g'),
      proteinG: d('protein_g'),
      fatG: d('fat_g'),
      fiberG: d('fiber_g'),
      sugarG: d('sugar_g'),
      sodiumMg: d('sodium_mg'),
      ironMg: d('iron_mg'),
      calciumMg: d('calcium_mg'),
      folateMcg: d('folate_mcg'),
    );
  }
}
