enum Trimester { first, second, third }

class Pregnancy {
  Pregnancy({
    required this.id,
    required this.patientId,
    required this.gestationalWeek,
    required this.trimester,
    required this.edd,
    required this.riskLevel,
    required this.updatedAt,
  });

  final String id;
  final String patientId;
  final int gestationalWeek;
  final int trimester;
  final String edd;
  final String riskLevel;
  final DateTime? updatedAt;

  Trimester get trimesterEnum {
    switch (trimester) {
      case 1:
        return Trimester.first;
      case 2:
        return Trimester.second;
      case 3:
      default:
        return Trimester.third;
    }
  }

  Pregnancy copyWith({
    String? id,
    String? patientId,
    int? gestationalWeek,
    int? trimester,
    String? edd,
    String? riskLevel,
    DateTime? updatedAt,
  }) {
    return Pregnancy(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      gestationalWeek: gestationalWeek ?? this.gestationalWeek,
      trimester: trimester ?? this.trimester,
      edd: edd ?? this.edd,
      riskLevel: riskLevel ?? this.riskLevel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
