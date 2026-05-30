/// SmartBunda Clinical Rule Engine
///
/// IMPORTANT — Medical Safety Notice:
///   All recommendations in this file are derived from predefined clinical
///   screening rules based on Malaysian Ministry of Health (MOH) guidelines
///   and evidence-based perinatal nutrition standards.
///
///   This engine does NOT generate new medical advice.
///   It applies only the rules encoded below.
///   AI assistance is limited to simplifying patient-facing language.
///   No AI-generated dosages, treatments, or overrides are permitted.
///
/// Sources:
///   • Malaysian Dietary Guidelines (MDG 2021)
///   • Malaysian Recommended Nutrient Intakes (RNI 2017)
///   • MOH Antenatal Care Protocol
///   • MOH Pre-pregnancy Health Management Guidelines
library smartbunda.clinical_rules;

// ── Enumerations ─────────────────────────────────────────────────────────────

enum RiskSeverity { low, moderate, high, critical }

enum ClinicalContext {
  prePregnancy,
  trimesterOne,
  trimesterTwo,
  trimesterThree,
  postpartum,
  breastfeeding,
}

/// Self-reported physical activity level used by lifestyle rules.
enum PhysicalActivityLevel { low, moderate, high }

// ── Patient Input ─────────────────────────────────────────────────────────────

/// All patient parameters consumed by the rule engine.
/// Every field is nullable; rules only fire when the relevant value is present.
class ClinicalInput {
  const ClinicalInput({
    required this.context,
    this.ageYears,
    this.bmi,
    this.hemoglobinGdl,
    this.systolicMmHg,
    this.diastolicMmHg,
    this.hasdiabetes = false,
    this.hasEpilepsy = false,
    this.hasCKD = false,
    this.hasHypertension = false,
    this.hasHeartDisease = false,
    this.planningPregnancy = false,
    this.isBreastfeeding = false,
    this.hasHistoryOfPPH = false,
    this.dailyCaffeineMg,
    this.calciumMgPerDay,
    this.iodineUgPerDay,
    this.ironMgPerDay,
    this.activityLevel,
    this.weeklyWeightGainKg,
    this.isPostpartum = false,
  });

  final ClinicalContext context;
  final int? ageYears;
  final double? bmi;
  final double? hemoglobinGdl;
  final int? systolicMmHg;
  final int? diastolicMmHg;
  final bool hasdiabetes;
  final bool hasEpilepsy;
  final bool hasCKD;
  final bool hasHypertension;
  final bool hasHeartDisease;
  final bool planningPregnancy;
  final bool isBreastfeeding;
  final bool hasHistoryOfPPH;
  final double? dailyCaffeineMg;
  final double? calciumMgPerDay;
  final double? iodineUgPerDay;
  final double? ironMgPerDay;
  final PhysicalActivityLevel? activityLevel;
  final double? weeklyWeightGainKg;
  final bool isPostpartum;

  bool get isPregnant =>
      context == ClinicalContext.trimesterOne ||
      context == ClinicalContext.trimesterTwo ||
      context == ClinicalContext.trimesterThree;

  bool get isAdolescent => ageYears != null && ageYears! < 20;
}

// ── Risk Finding ──────────────────────────────────────────────────────────────

class RiskFinding {
  const RiskFinding({
    required this.ruleId,
    required this.name,
    required this.severity,
    required this.triggeredCondition,
    this.detail,
  });

  final String ruleId;
  final String name;
  final RiskSeverity severity;
  final String triggeredCondition;
  final String? detail;

  String get severityLabel {
    switch (severity) {
      case RiskSeverity.low:
        return 'Low';
      case RiskSeverity.moderate:
        return 'Moderate';
      case RiskSeverity.high:
        return 'High';
      case RiskSeverity.critical:
        return 'Critical';
    }
  }
}

// ── Clinical Recommendation ───────────────────────────────────────────────────

class ClinicalRecommendation {
  const ClinicalRecommendation({
    required this.ruleId,
    required this.recommendation,
    required this.purpose,
    this.dose,
    this.duration,
    this.category = RecommendationCategory.general,
  });

  final String ruleId;
  final String recommendation;
  final String purpose;
  final String? dose;
  final String? duration;
  final RecommendationCategory category;
}

enum RecommendationCategory {
  supplement,
  nutrition,
  lifestyle,
  monitoring,
  referral,
  general,
}

// ── Nutritional Requirements ──────────────────────────────────────────────────

class NutritionalRequirement {
  const NutritionalRequirement({
    required this.energyKcal,
    required this.proteinG,
    required this.calciumMg,
    required this.ironMg,
    required this.iodineUg,
    required this.folateMcg,
    required this.waterMl,
    required this.carbPct,
    required this.fatPct,
    this.proteinPct = 0.175,
  });

  final int energyKcal;
  final int proteinG;
  final int calciumMg;
  final int ironMg;
  final int iodineUg;
  final int folateMcg;
  final int waterMl;
  final double carbPct;
  final double fatPct;
  final double proteinPct;
}

// ── Assessment Result ─────────────────────────────────────────────────────────

class ClinicalAssessment {
  const ClinicalAssessment({
    required this.overallRisk,
    required this.risks,
    required this.recommendations,
    required this.nutritionalRequirements,
    required this.assessmentDate,
  });

  final RiskSeverity overallRisk;
  final List<RiskFinding> risks;
  final List<ClinicalRecommendation> recommendations;
  final NutritionalRequirement nutritionalRequirements;
  final DateTime assessmentDate;

  String get overallRiskLabel {
    switch (overallRisk) {
      case RiskSeverity.low:
        return 'Low Risk';
      case RiskSeverity.moderate:
        return 'Moderate Risk';
      case RiskSeverity.high:
        return 'High Risk';
      case RiskSeverity.critical:
        return 'High Risk — Immediate Medical Review';
    }
  }

  bool get hasHighOrCriticalRisk =>
      overallRisk == RiskSeverity.high ||
      overallRisk == RiskSeverity.critical;
}

// ── Clinical Rule Engine ──────────────────────────────────────────────────────

/// Applies the SmartBunda clinical screening rules to a [ClinicalInput] and
/// returns a [ClinicalAssessment].
///
/// Rule IDs follow the format SB-{CATEGORY}-{INDEX} for traceability.
class ClinicalRuleEngine {
  const ClinicalRuleEngine._();

  static ClinicalAssessment evaluate(ClinicalInput input) {
    final risks = <RiskFinding>[];
    final recs  = <ClinicalRecommendation>[];

    // ── PRE-PREGNANCY RULES ─────────────────────────────────────────────────

    if (input.context == ClinicalContext.prePregnancy) {

      // SB-PP-01: BMI-based weight risk
      final bmi = input.bmi;
      if (bmi != null && (bmi <= 18.5 || bmi >= 25.0)) {
        risks.add(RiskFinding(
          ruleId: 'SB-PP-01',
          name: 'Weight-related pregnancy risk',
          severity: bmi >= 30 ? RiskSeverity.high : RiskSeverity.moderate,
          triggeredCondition: bmi <= 18.5
              ? 'BMI ${bmi.toStringAsFixed(1)} ≤ 18.5 (Underweight)'
              : bmi >= 30
                  ? 'BMI ${bmi.toStringAsFixed(1)} ≥ 30 (Obese)'
                  : 'BMI ${bmi.toStringAsFixed(1)} ≥ 25.0 (Overweight)',
          detail: 'Weight outside healthy range increases maternal and fetal risks.',
        ));
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PP-01',
          recommendation: 'Achieve healthy BMI (18.5–24.9) during preconception period.',
          purpose: 'Reduce risks of poor maternal and fetal outcomes',
          category: RecommendationCategory.nutrition,
        ));
      }

      // SB-PP-02: Folic acid for planning pregnancy
      if (input.planningPregnancy) {
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PP-02',
          recommendation: 'Start folic acid supplementation',
          purpose: 'Prevent Neural Tube Defects (NTD)',
          dose: '0.4 mg daily',
          duration: 'At least 3 months before conception, continue through first trimester',
          category: RecommendationCategory.supplement,
        ));
      }

      // SB-PP-03: High-risk NTD — diabetes or epilepsy
      if (input.hasdiabetes || input.hasEpilepsy) {
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PP-03',
          recommendation: 'Increase folic acid supplementation (high-risk NTD)',
          purpose: 'Prevent Neural Tube Defects in high-risk conditions',
          dose: '5 mg daily',
          duration: 'Confirm dose with your doctor before starting',
          category: RecommendationCategory.supplement,
        ));
      }

      // SB-PP-04: Pre-pregnancy anaemia screening
      final hb = input.hemoglobinGdl;
      if (hb != null && hb < 12.0) {
        risks.add(RiskFinding(
          ruleId: 'SB-PP-04',
          name: 'Low haemoglobin — pre-pregnancy screening',
          severity: hb < 10.0 ? RiskSeverity.high : RiskSeverity.moderate,
          triggeredCondition: 'Hb ${hb.toStringAsFixed(1)} g/dL < 12.0 g/dL',
          detail: 'Low Hb before pregnancy increases risk of worsening anaemia during pregnancy.',
        ));
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PP-04',
          recommendation: 'Consult doctor for haematological assessment and optimisation',
          purpose: 'Pre-pregnancy anaemia management',
          category: RecommendationCategory.referral,
        ));
      }

      // SB-PP-05: Hypertension
      if (input.hasHypertension ||
          (input.systolicMmHg != null && input.systolicMmHg! >= 140) ||
          (input.diastolicMmHg != null && input.diastolicMmHg! >= 90)) {
        risks.add(const RiskFinding(
          ruleId: 'SB-PP-05',
          name: 'Hypertension detected',
          severity: RiskSeverity.high,
          triggeredCondition: 'Blood pressure ≥ 140/90 mmHg or hypertension history',
          detail: 'Uncontrolled hypertension significantly increases pregnancy risk.',
        ));
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PP-05',
          recommendation: 'Consult doctor for blood pressure control and medication safety review',
          purpose: 'Ensure safe blood pressure before conception',
          category: RecommendationCategory.referral,
        ));
      }

      // SB-PP-06: Heart disease
      if (input.hasHeartDisease) {
        risks.add(const RiskFinding(
          ruleId: 'SB-PP-06',
          name: 'Cardiac condition identified',
          severity: RiskSeverity.critical,
          triggeredCondition: 'History of heart disease',
          detail: 'Cardiac conditions require specialist review before pregnancy.',
        ));
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PP-06',
          recommendation: 'Cardiologist review and joint pre-conception counselling required',
          purpose: 'Assess cardiac risk before conception',
          category: RecommendationCategory.referral,
        ));
      }

      // SB-PP-07: CKD
      if (input.hasCKD) {
        risks.add(const RiskFinding(
          ruleId: 'SB-PP-07',
          name: 'Chronic Kidney Disease (CKD)',
          severity: RiskSeverity.high,
          triggeredCondition: 'CKD diagnosis confirmed',
          detail: 'CKD increases risk of pre-eclampsia, preterm birth, and fetal growth restriction.',
        ));
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PP-07',
          recommendation: 'Nephrologist and obstetrician joint review before conception',
          purpose: 'Optimise renal function and minimise pregnancy complications',
          category: RecommendationCategory.referral,
        ));
      }
    }

    // ── PREGNANCY RULES ─────────────────────────────────────────────────────

    if (input.isPregnant) {

      // SB-PR-01: Iron Deficiency Anaemia (IDA)
      final hb = input.hemoglobinGdl;
      if (hb != null && hb < 11.0) {
        risks.add(RiskFinding(
          ruleId: 'SB-PR-01',
          name: 'Iron Deficiency Anaemia (IDA)',
          severity: hb < 8.0 ? RiskSeverity.critical : RiskSeverity.high,
          triggeredCondition: 'Hb ${hb.toStringAsFixed(1)} g/dL < 11.0 g/dL in pregnancy',
          detail: 'IDA during pregnancy increases risk of preterm birth, low birth weight, and maternal fatigue.',
        ));
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PR-01',
          recommendation: 'Increase elemental iron supplementation for IDA treatment',
          purpose: 'Correct iron deficiency anaemia during pregnancy',
          dose: '120 mg elemental iron daily',
          duration: 'Until Hb ≥ 11.0 g/dL, then continue standard dose',
          category: RecommendationCategory.supplement,
        ));
      } else if (input.isPregnant) {
        // Standard pregnancy iron for non-IDA
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PR-02',
          recommendation: 'Continue standard iron supplementation during pregnancy',
          purpose: 'Prevent iron deficiency anaemia',
          dose: '30–60 mg elemental iron daily',
          category: RecommendationCategory.supplement,
        ));
      }

      // SB-PR-03: Iodine supplementation
      recs.add(const ClinicalRecommendation(
        ruleId: 'SB-PR-03',
        recommendation: 'Iodine supplementation throughout pregnancy',
        purpose: 'Support fetal brain development and thyroid function',
        dose: '200 μg/day',
        category: RecommendationCategory.supplement,
      ));

      // SB-PR-04: Calcium (age-dependent)
      final calcRec = input.isAdolescent
          ? const ClinicalRecommendation(
              ruleId: 'SB-PR-04A',
              recommendation: 'Calcium supplementation — adolescent dose',
              purpose: 'Support maternal and fetal bone development',
              dose: '1300 mg/day (adolescent)',
              category: RecommendationCategory.supplement,
            )
          : const ClinicalRecommendation(
              ruleId: 'SB-PR-04B',
              recommendation: 'Calcium supplementation',
              purpose: 'Support maternal and fetal bone development',
              dose: '1000 mg/day',
              category: RecommendationCategory.supplement,
            );
      recs.add(calcRec);

      // SB-PR-05: Excessive caffeine
      if (input.dailyCaffeineMg != null && input.dailyCaffeineMg! > 300) {
        risks.add(RiskFinding(
          ruleId: 'SB-PR-05',
          name: 'Excessive caffeine intake',
          severity: RiskSeverity.moderate,
          triggeredCondition:
              'Daily caffeine ${input.dailyCaffeineMg!.toStringAsFixed(0)} mg > 300 mg',
          detail: 'High caffeine intake is associated with increased risk of pregnancy loss and restricted fetal growth.',
        ));
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PR-05',
          recommendation: 'Reduce total daily caffeine intake',
          purpose: 'Reduce risk of miscarriage and fetal growth restriction',
          dose: 'Limit to < 200 mg/day (recommended safe limit)',
          category: RecommendationCategory.lifestyle,
        ));
      }

      // SB-PR-06: Gestational Diabetes — macro distribution
      if (input.hasdiabetes) {
        risks.add(const RiskFinding(
          ruleId: 'SB-PR-06',
          name: 'Gestational Diabetes Mellitus (GDM)',
          severity: RiskSeverity.high,
          triggeredCondition: 'GDM diagnosis confirmed',
          detail: 'GDM requires specific macronutrient distribution to control blood glucose.',
        ));
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PR-06',
          recommendation: 'Follow GDM-specific macronutrient distribution',
          purpose: 'Maintain blood glucose control during pregnancy',
          dose: 'Carbohydrate 45–60% | Protein 15–20% | Fat 25–35%',
          category: RecommendationCategory.nutrition,
        ));
      }

      // SB-PR-07: Preeclampsia risk — low calcium intake
      final calciumIntake = input.calciumMgPerDay;
      if (calciumIntake != null && calciumIntake < 700) {
        risks.add(RiskFinding(
          ruleId: 'SB-PR-07',
          name: 'Low calcium intake — preeclampsia risk',
          severity: RiskSeverity.moderate,
          triggeredCondition:
              'Calcium intake ${calciumIntake.toStringAsFixed(0)} mg/day < 700 mg/day',
          detail: 'Low calcium intake is a modifiable risk factor for preeclampsia.',
        ));
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PR-07',
          recommendation: 'Calcium supplementation to reduce preeclampsia risk',
          purpose: 'Reduce risk of preeclampsia in low-intake populations',
          dose: '1.5–2.0 g calcium supplementation daily',
          category: RecommendationCategory.supplement,
        ));
      }

      // SB-PR-08: Rapid weight gain — possible preeclampsia
      if (input.weeklyWeightGainKg != null &&
          input.weeklyWeightGainKg! > 2.0) {
        risks.add(RiskFinding(
          ruleId: 'SB-PR-08',
          name: 'Rapid weight gain — possible preeclampsia',
          severity: RiskSeverity.high,
          triggeredCondition:
              'Weight gain ${input.weeklyWeightGainKg!.toStringAsFixed(1)} kg/week > 2.0 kg/week',
          detail: 'Sudden rapid weight gain can indicate fluid retention associated with preeclampsia.',
        ));
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PR-08',
          recommendation: 'Immediate medical evaluation for possible preeclampsia',
          purpose: 'Rule out or manage preeclampsia early',
          category: RecommendationCategory.referral,
        ));
      }

      // SB-PR-09: CKD in pregnancy
      if (input.hasCKD) {
        risks.add(const RiskFinding(
          ruleId: 'SB-PR-09',
          name: 'Chronic Kidney Disease in pregnancy',
          severity: RiskSeverity.high,
          triggeredCondition: 'CKD confirmed during pregnancy',
          detail: 'CKD significantly increases maternal and fetal complications.',
        ));
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PR-09',
          recommendation: 'Initiate calcium supplementation under specialist supervision',
          purpose: 'Manage CKD-related mineral imbalance during pregnancy',
          dose: 'Calcium Carbonate 1 g twice daily (BD) — confirm with nephrologist',
          category: RecommendationCategory.supplement,
        ));
      }
    }

    // ── POSTPARTUM & LACTATION RULES ────────────────────────────────────────

    if (input.context == ClinicalContext.postpartum ||
        input.isBreastfeeding) {

      // SB-PL-01: PPH history — continue iron
      if (input.hasHistoryOfPPH) {
        risks.add(const RiskFinding(
          ruleId: 'SB-PL-01',
          name: 'Postpartum anaemia risk — history of PPH',
          severity: RiskSeverity.high,
          triggeredCondition: 'History of postpartum haemorrhage (PPH)',
          detail: 'PPH causes significant blood loss, increasing postpartum anaemia risk.',
        ));
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PL-01',
          recommendation: 'Continue iron supplementation postpartum',
          purpose: 'Replenish iron stores depleted by postpartum haemorrhage',
          duration: '3–6 months postpartum',
          category: RecommendationCategory.supplement,
        ));
      }

      // SB-PL-02: Breastfeeding nutrition
      if (input.isBreastfeeding) {
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PL-02',
          recommendation: 'Increase energy and protein intake for exclusive breastfeeding',
          purpose: 'Support breast milk production and maternal recovery',
          dose: '+500 kcal/day | +19 g protein/day above non-pregnant baseline',
          category: RecommendationCategory.nutrition,
        ));
        recs.add(ClinicalRecommendation(
          ruleId: 'SB-PL-03',
          recommendation: 'Calcium supplementation during breastfeeding',
          purpose: 'Maintain maternal bone density during lactation',
          dose: input.isAdolescent ? '1300 mg/day (adolescent)' : '1000 mg/day',
          category: RecommendationCategory.supplement,
        ));
        recs.add(const ClinicalRecommendation(
          ruleId: 'SB-PL-04',
          recommendation: 'Continue iodine supplementation during breastfeeding',
          purpose: 'Ensure adequate iodine in breast milk for infant neurodevelopment',
          dose: '200 μg/day',
          category: RecommendationCategory.supplement,
        ));
      }
    }

    // ── GENERAL LIFESTYLE & DIETARY RULES (all contexts) ────────────────────

    // SB-GEN-01: Low dietary iron intake
    final ironIntake = input.ironMgPerDay;
    final ironTarget = input.isPregnant ? 27.0 : 18.0;
    if (ironIntake != null && ironIntake < ironTarget) {
      risks.add(RiskFinding(
        ruleId: 'SB-GEN-01',
        name: 'Low dietary iron intake',
        severity: RiskSeverity.moderate,
        triggeredCondition:
            'Iron ${ironIntake.toStringAsFixed(0)} mg/day < ${ironTarget.toStringAsFixed(0)} mg/day target',
        detail:
            'Insufficient dietary iron increases the risk of iron-deficiency anaemia.',
      ));
      recs.add(const ClinicalRecommendation(
        ruleId: 'SB-GEN-01',
        recommendation:
            'Increase iron-rich foods (red meat, leafy greens, legumes) and pair with vitamin C.',
        purpose: 'Support healthy haemoglobin and prevent iron-deficiency anaemia',
        category: RecommendationCategory.nutrition,
      ));
    }

    // SB-GEN-02: Sedentary lifestyle
    if (input.activityLevel == PhysicalActivityLevel.low) {
      recs.add(const ClinicalRecommendation(
        ruleId: 'SB-GEN-02',
        recommendation:
            'Aim for at least 150 minutes of moderate activity per week, as advised by your provider.',
        purpose: 'Support healthy weight, circulation, and mood',
        category: RecommendationCategory.lifestyle,
      ));
    }

    // ── DETERMINE OVERALL RISK ──────────────────────────────────────────────

    final overallRisk = _computeOverallRisk(risks);

    // ── NUTRITIONAL REQUIREMENTS ────────────────────────────────────────────

    final nutrition = _computeNutrition(input);

    return ClinicalAssessment(
      overallRisk: overallRisk,
      risks: risks,
      recommendations: recs,
      nutritionalRequirements: nutrition,
      assessmentDate: DateTime.now(),
    );
  }

  static RiskSeverity _computeOverallRisk(List<RiskFinding> risks) {
    if (risks.isEmpty) return RiskSeverity.low;
    if (risks.any((r) => r.severity == RiskSeverity.critical)) {
      return RiskSeverity.critical;
    }
    if (risks.any((r) => r.severity == RiskSeverity.high)) {
      return RiskSeverity.high;
    }
    if (risks.any((r) => r.severity == RiskSeverity.moderate)) {
      return RiskSeverity.moderate;
    }
    return RiskSeverity.low;
  }

  static NutritionalRequirement _computeNutrition(ClinicalInput input) {
    // Base adult-woman RNI (Malaysian RNI 2017)
    var energy = 1900;
    var protein = 55;
    var waterMl = 2500;
    var carbPct = 0.50;
    var fatPct  = 0.30;
    var proteinPct = 0.175;

    // Trimester-specific increments
    switch (input.context) {
      case ClinicalContext.trimesterOne:
        energy += 80;
        protein += 1;
      case ClinicalContext.trimesterTwo:
        energy += 280;
        protein += 8;
        waterMl = 2700;
      case ClinicalContext.trimesterThree:
        energy += 470;
        protein += 25;
        waterMl = 2800;
      case ClinicalContext.breastfeeding:
      case ClinicalContext.postpartum:
        if (input.isBreastfeeding) {
          energy += 500;
          protein += 19;
          waterMl = 3100;
        }
      case ClinicalContext.prePregnancy:
        break;
    }

    // GDM macro adjustment
    if (input.hasdiabetes && input.isPregnant) {
      carbPct = 0.50;
      fatPct  = 0.28;
      proteinPct = 0.175;
      protein = (energy * proteinPct / 4).round();
    }

    // Iron
    final hb = input.hemoglobinGdl;
    final hasIDA = hb != null && (
      (input.isPregnant && hb < 11.0) ||
      (!input.isPregnant && hb < 12.0)
    );
    final iron = hasIDA
        ? 120
        : input.isPregnant
            ? 60
            : 18;

    // Calcium
    final calcium = input.isAdolescent ? 1300 : 1000;

    // Iodine
    final iodine = (input.isPregnant || input.isBreastfeeding) ? 200 : 150;

    // Folate
    final folate = input.isPregnant ? 600 : 400;

    return NutritionalRequirement(
      energyKcal: energy,
      proteinG: protein,
      calciumMg: calcium,
      ironMg: iron,
      iodineUg: iodine,
      folateMcg: folate,
      waterMl: waterMl,
      carbPct: carbPct,
      fatPct: fatPct,
      proteinPct: proteinPct,
    );
  }
}
