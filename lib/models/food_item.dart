class FoodItem {
  FoodItem({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.caloriesPerServing,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.ironMg,
    required this.folateMcg,
  });

  final String id;
  final String name;
  final String servingSize;
  final int caloriesPerServing;
  final int proteinG;
  final int carbG;
  final int fatG;
  final double ironMg;
  final double folateMcg;

  FoodItem copyWith({
    String? id,
    String? name,
    String? servingSize,
    int? caloriesPerServing,
    int? proteinG,
    int? carbG,
    int? fatG,
    double? ironMg,
    double? folateMcg,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      servingSize: servingSize ?? this.servingSize,
      caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
      proteinG: proteinG ?? this.proteinG,
      carbG: carbG ?? this.carbG,
      fatG: fatG ?? this.fatG,
      ironMg: ironMg ?? this.ironMg,
      folateMcg: folateMcg ?? this.folateMcg,
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final nutrients = (json['nutrients'] as Map?)?.cast<String, dynamic>() ?? {};
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      servingSize: json['servingSize'] as String? ?? '',
      caloriesPerServing: (json['caloriesPerServing'] as num).toInt(),
      proteinG: (nutrients['protein_g'] as num?)?.toInt() ?? 0,
      carbG: (nutrients['carb_g'] as num?)?.toInt() ?? 0,
      fatG: (nutrients['fat_g'] as num?)?.toInt() ?? 0,
      ironMg: (nutrients['iron_mg'] as num?)?.toDouble() ?? 0,
      folateMcg: (nutrients['folate_mcg'] as num?)?.toDouble() ?? 0,
    );
  }
}
