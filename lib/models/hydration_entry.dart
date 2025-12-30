class HydrationEntry {
  HydrationEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.amountMl,
  });

  final String id;
  final String userId;
  final DateTime date;
  final int amountMl;

  HydrationEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? amountMl,
  }) {
    return HydrationEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      amountMl: amountMl ?? this.amountMl,
    );
  }
}
