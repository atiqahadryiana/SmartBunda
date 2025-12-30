class FoodEntry {
  FoodEntry({
    required this.id,
    required this.userId,
    required this.logId,
    required this.foodId,
    required this.date,
    required this.meal,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.ironMg = 0,
    this.folateMcg = 0,
    this.notes,
  });

  final String id;
  final String userId;
  final String logId;
  final String foodId;
  final DateTime date;
  final String meal;
  final double quantity;
  final String unit;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final double ironMg;
  final double folateMcg;
  final String? notes;

  FoodEntry copyWith({
    String? id,
    String? userId,
    String? logId,
    String? foodId,
    DateTime? date,
    String? meal,
    double? quantity,
    String? unit,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    double? ironMg,
    double? folateMcg,
    String? notes,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      logId: logId ?? this.logId,
      foodId: foodId ?? this.foodId,
      date: date ?? this.date,
      meal: meal ?? this.meal,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      ironMg: ironMg ?? this.ironMg,
      folateMcg: folateMcg ?? this.folateMcg,
      notes: notes ?? this.notes,
    );
  }
}
