enum MedicalCondition { anemia, gestationalDiabetes }

class Profile {
  Profile({
    required this.patientId,
    required this.dob,
    required this.heightCm,
    required this.currentWeightKg,
    required this.bloodType,
    this.medicalConditions = const <MedicalCondition>{},
  });

  final String patientId;
  final String dob;
  final double heightCm;
  final double currentWeightKg;
  final String bloodType;
  final Set<MedicalCondition> medicalConditions;

  double get bmi {
    final heightM = heightCm / 100;
    if (heightM <= 0) return 0;
    return currentWeightKg / (heightM * heightM);
  }

  int? get age {
    final date = _parseDob(dob);
    if (date == null) return null;
    final now = DateTime.now();
    var years = now.year - date.year;
    if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
      years -= 1;
    }
    return years;
  }

  Profile copyWith({
    String? patientId,
    String? dob,
    double? heightCm,
    double? currentWeightKg,
    String? bloodType,
    Set<MedicalCondition>? medicalConditions,
  }) {
    return Profile(
      patientId: patientId ?? this.patientId,
      dob: dob ?? this.dob,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      bloodType: bloodType ?? this.bloodType,
      medicalConditions: medicalConditions ?? this.medicalConditions,
    );
  }

  static DateTime? _parseDob(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
}
