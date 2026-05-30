/// SmartBunda — Digital First Assessment input model
///
/// Holds exactly the fields collected by the streamlined Digital First
/// Assessment wizard (strict keep-list). Used to build a [ClinicalInput] for
/// the clinical rule engine.
library smartbunda.assessment_input;

import 'package:smartbunda/utils/clinical_rules.dart';

class AssessmentInput {
  AssessmentInput({
    // Personal
    this.age,
    this.heightCm,
    this.weightKg,
    // Pregnancy
    this.planningPregnancy = false,
    this.currentlyPregnant = false,
    this.trimester,
    // Medical history
    this.diabetes = false,
    this.epilepsy = false,
    this.chronicKidneyDisease = false,
    this.previousPregnancyComplications = false,
    this.postpartumHemorrhageHistory = false,
    // Lifestyle
    this.dailyCaffeineMg,
    this.smokingExposure = false,
    this.alcoholExposure = false,
    this.physicalActivityLevel,
    // Nutrition
    this.calciumMgPerDay,
    this.ironMgPerDay,
    this.iodineUgPerDay,
    // Laboratory
    this.hemoglobinGdl,
  });

  // Personal
  int? age;
  double? heightCm;
  double? weightKg;

  // Pregnancy
  bool planningPregnancy;
  bool currentlyPregnant;
  int? trimester; // 1, 2, or 3 (only when currentlyPregnant)

  // Medical history
  bool diabetes;
  bool epilepsy;
  bool chronicKidneyDisease;
  bool previousPregnancyComplications;
  bool postpartumHemorrhageHistory;

  // Lifestyle
  double? dailyCaffeineMg;
  bool smokingExposure;
  bool alcoholExposure;
  PhysicalActivityLevel? physicalActivityLevel;

  // Nutrition
  double? calciumMgPerDay;
  double? ironMgPerDay;
  double? iodineUgPerDay;

  // Laboratory
  double? hemoglobinGdl;

  /// Auto-calculated Body Mass Index, or null when height/weight is missing.
  double? get bmi {
    final h = heightCm;
    final w = weightKg;
    if (h == null || w == null || h <= 0 || w <= 0) return null;
    final m = h / 100.0;
    return w / (m * m);
  }

  /// Clinical context derived from pregnancy answers.
  ClinicalContext get clinicalContext {
    if (!currentlyPregnant) return ClinicalContext.prePregnancy;
    switch (trimester) {
      case 1:
        return ClinicalContext.trimesterOne;
      case 2:
        return ClinicalContext.trimesterTwo;
      case 3:
        return ClinicalContext.trimesterThree;
      default:
        return ClinicalContext.trimesterOne;
    }
  }

  /// Build the rule-engine input from the collected answers.
  ClinicalInput toClinicalInput() {
    return ClinicalInput(
      context: clinicalContext,
      ageYears: age,
      bmi: bmi,
      hemoglobinGdl: hemoglobinGdl,
      hasdiabetes: diabetes,
      hasEpilepsy: epilepsy,
      hasCKD: chronicKidneyDisease,
      planningPregnancy: planningPregnancy,
      hasHistoryOfPPH: postpartumHemorrhageHistory,
      dailyCaffeineMg: dailyCaffeineMg,
      calciumMgPerDay: calciumMgPerDay,
      iodineUgPerDay: iodineUgPerDay,
      ironMgPerDay: ironMgPerDay,
      activityLevel: physicalActivityLevel,
    );
  }
}
