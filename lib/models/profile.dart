/// Common pregnancy-related health conditions a patient may report.
/// Ordered roughly by prevalence in antenatal care.
enum MedicalCondition {
  anemia,
  gestationalDiabetes,
  hypertension,
  preeclampsia,
  thyroidDisorder,
  asthma,
  heartDisease,
  obesity,
  multiplePregnancy,
  previousCSection,
}

extension MedicalConditionLabel on MedicalCondition {
  String get label {
    switch (this) {
      case MedicalCondition.anemia:
        return 'Anemia';
      case MedicalCondition.gestationalDiabetes:
        return 'Gestational diabetes';
      case MedicalCondition.hypertension:
        return 'High blood pressure (hypertension)';
      case MedicalCondition.preeclampsia:
        return 'Pre-eclampsia';
      case MedicalCondition.thyroidDisorder:
        return 'Thyroid disorder';
      case MedicalCondition.asthma:
        return 'Asthma';
      case MedicalCondition.heartDisease:
        return 'Heart disease';
      case MedicalCondition.obesity:
        return 'Obesity';
      case MedicalCondition.multiplePregnancy:
        return 'Multiple pregnancy (twins+)';
      case MedicalCondition.previousCSection:
        return 'Previous C-section';
    }
  }

  /// Stable key for persistence (matches enum name).
  String get key => name;

  static MedicalCondition? fromKey(String? value) {
    if (value == null) return null;
    final v = value.trim();
    for (final c in MedicalCondition.values) {
      if (c.name == v) return c;
    }
    return null;
  }
}

/// Body-weight classification per the Malaysian MOH / WHO public-health-action
/// cut-offs (Asian population). See MOH Clinical Practice Guidelines, Table 2.1.
enum BmiCategory { underweight, normal, overweight, obese }

extension BmiCategoryX on BmiCategory {
  String get label => switch (this) {
        BmiCategory.underweight => 'Underweight',
        BmiCategory.normal => 'Normal',
        BmiCategory.overweight => 'Overweight',
        BmiCategory.obese => 'Obese',
      };

  /// Malaysian public-health-action cut-offs (kg/m²):
  /// Underweight <18.5 · Normal 18.5–22.9 · Overweight 23.0–27.4 · Obese ≥27.5.
  static BmiCategory? fromBmi(double bmi) {
    if (bmi <= 0) return null;
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 23.0) return BmiCategory.normal;
    if (bmi < 27.5) return BmiCategory.overweight;
    return BmiCategory.obese;
  }
}

class Profile {
  Profile({
    required this.patientId,
    required this.dob,
    required this.heightCm,
    required this.currentWeightKg,
    required this.bloodType,
    this.hemoglobinGdl,
    this.abdominalCircumferenceCm,
    this.medicalConditions = const <MedicalCondition>{},
    this.conditionNotes,
  });

  final String patientId;
  final String dob;
  final double heightCm;
  final double currentWeightKg;
  final String bloodType;
  final double? hemoglobinGdl;
  final double? abdominalCircumferenceCm;
  final Set<MedicalCondition> medicalConditions;
  final String? conditionNotes;

  double get bmi {
    final heightM = heightCm / 100;
    if (heightM <= 0) return 0;
    return currentWeightKg / (heightM * heightM);
  }

  /// Malaysian MOH/WHO body-weight classification for [bmi] (null when BMI is
  /// unavailable, e.g. height/weight not yet entered).
  BmiCategory? get bmiCategory => BmiCategoryX.fromBmi(bmi);

  int? get age {
    final date = _parseDob(dob);
    if (date == null) return null;
    final now = DateTime.now();
    var years = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
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
    double? hemoglobinGdl,
    double? abdominalCircumferenceCm,
    Set<MedicalCondition>? medicalConditions,
    String? conditionNotes,
  }) {
    return Profile(
      patientId: patientId ?? this.patientId,
      dob: dob ?? this.dob,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      bloodType: bloodType ?? this.bloodType,
      hemoglobinGdl: hemoglobinGdl ?? this.hemoglobinGdl,
      abdominalCircumferenceCm:
          abdominalCircumferenceCm ?? this.abdominalCircumferenceCm,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      conditionNotes: conditionNotes ?? this.conditionNotes,
    );
  }

  static DateTime? _parseDob(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
}
