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

  int get calories => caloriesPerServing;
  int get protein => proteinG;
  int get carbs => carbG;
  int get fat => fatG;

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
    final caloriesRaw = _firstNonNull([
      json['caloriesPerServing'],
      json['calories_per_serving'],
      json['calories'],
      nutrients['calories'],
      json['nutrients.calories'],
    ]);
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      servingSize: json['servingSize'] as String? ?? '',
      caloriesPerServing: _intFrom(caloriesRaw),
      proteinG: _intFrom(
        _firstNonNull([
          nutrients['protein_g'],
          nutrients['protein'],
          json['nutrients.protein_g'],
          json['nutrients.protein'],
          json['proteinG'],
          json['protein_g'],
          json['protein'],
        ]),
      ),
      carbG: _intFrom(
        _firstNonNull([
          nutrients['carb_g'],
          nutrients['carbs'],
          nutrients['carb'],
          json['nutrients.carb_g'],
          json['nutrients.carbs'],
          json['nutrients.carb'],
          json['carbG'],
          json['carb_g'],
          json['carbs'],
          json['carb'],
        ]),
      ),
      fatG: _intFrom(
        _firstNonNull([
          nutrients['fat_g'],
          nutrients['fat'],
          json['nutrients.fat_g'],
          json['nutrients.fat'],
          json['fatG'],
          json['fat_g'],
          json['fat'],
        ]),
      ),
      ironMg: _doubleFrom(
        _firstNonNull([
          nutrients['iron_mg'],
          nutrients['iron'],
          json['nutrients.iron_mg'],
          json['nutrients.iron'],
          json['ironMg'],
          json['iron_mg'],
          json['iron'],
        ]),
      ),
      folateMcg: _doubleFrom(
        _firstNonNull([
          nutrients['folate_mcg'],
          nutrients['folate'],
          json['nutrients.folate_mcg'],
          json['nutrients.folate'],
          json['folateMcg'],
          json['folate_mcg'],
          json['folate'],
        ]),
      ),
    );
  }

  static int _intFrom(dynamic raw) {
    final value = _numFrom(raw);
    return value?.toInt() ?? 0;
  }

  static double _doubleFrom(dynamic raw) {
    final value = _numFrom(raw);
    return value?.toDouble() ?? 0;
  }

  static num? _numFrom(dynamic raw) {
    if (raw is num) return raw;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      var normalized = trimmed;
      if (normalized.contains('.') && normalized.contains(',')) {
        normalized = normalized.replaceAll(',', '');
      } else {
        normalized = normalized.replaceAll(',', '.');
      }
      final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(normalized);
      if (match == null) return null;
      return num.tryParse(match.group(0)!);
    }
    return null;
  }

  static dynamic _firstNonNull(List<dynamic> values) {
    for (final value in values) {
      if (value != null) return value;
    }
    return null;
  }
}
