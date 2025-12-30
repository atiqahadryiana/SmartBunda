class FoodLog {
  FoodLog({
    required this.id,
    required this.patientId,
    required this.logDate,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalIronMg,
    required this.totalFolateMcg,
    required this.createdAt,
  });

  final String id;
  final String patientId;
  final DateTime logDate;
  final int totalCalories;
  final int totalProteinG;
  final double totalIronMg;
  final double totalFolateMcg;
  final DateTime? createdAt;

  FoodLog copyWith({
    String? id,
    String? patientId,
    DateTime? logDate,
    int? totalCalories,
    int? totalProteinG,
    double? totalIronMg,
    double? totalFolateMcg,
    DateTime? createdAt,
  }) {
    return FoodLog(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      logDate: logDate ?? this.logDate,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProteinG: totalProteinG ?? this.totalProteinG,
      totalIronMg: totalIronMg ?? this.totalIronMg,
      totalFolateMcg: totalFolateMcg ?? this.totalFolateMcg,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
