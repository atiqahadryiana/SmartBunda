import 'package:smartbunda/models/pregnancy.dart';
import 'package:smartbunda/models/profile.dart';

class RecommendedTargets {
  RecommendedTargets({
    required this.calories,
    required this.protein,
    required this.waterMl,
    required this.ironMg,
    required this.calciumMg,
    required this.folateMcg,
    required this.vitaminDMcg,
    required this.vitaminB12Mcg,
    required this.sodiumMg,
    required this.iodineUg,
    this.carbPct = 0.50,
    this.fatPct = 0.30,
  });

  final int calories;
  final int protein;
  final int waterMl;
  final int ironMg;
  final int calciumMg;
  final int folateMcg;
  final int vitaminDMcg;
  final double vitaminB12Mcg;
  final int sodiumMg;
  // Iodine target (μg/day): 200 during pregnancy per MOH guidelines
  final int iodineUg;
  // Macro split percentages — adjusted for gestational diabetes (45–60% carb, 25–35% fat)
  final double carbPct;
  final double fatPct;
}

/// Returns evidence-based daily nutrient targets aligned with MOH Malaysia RNI and
/// the Smartbunda clinical decision rules.
///
/// Energy and protein use base adult-woman RNI with trimester increments:
///   T1 +80 kcal / +0.5 g protein
///   T2 +280 kcal / +8 g protein
///   T3 +470 kcal / +25 g protein
///
/// Condition overrides (require [profile]):
///   IDA (Hb < 11.0 or anemia flag)    → iron 120 mg
///   Gestational diabetes               → macro split 50/17.5/28 %
///   Adolescent (age < 20)              → calcium 1300 mg
RecommendedTargets recommendedFor(Pregnancy? pregnancy, {Profile? profile}) {
  final trimester = pregnancy?.trimesterEnum ?? Trimester.second;

  // Condition flags derived from profile
  final hb = profile?.hemoglobinGdl;
  final hasIDA = (hb != null && hb < 11.0) ||
      (profile?.medicalConditions.contains(MedicalCondition.anemia) ?? false);
  final hasGDM = profile?.medicalConditions
          .contains(MedicalCondition.gestationalDiabetes) ??
      false;
  final ageYears = profile?.age;
  final isAdolescent = ageYears != null && ageYears < 20;

  // Base RNI for Malaysian adult women (non-pregnant)
  const baseCalories = 1900;
  const baseProteinG = 55;

  var calories = baseCalories;
  var protein = baseProteinG;
  var waterMl = 2500;

  switch (trimester) {
    case Trimester.first:
      calories += 80;
      protein += 1;
    case Trimester.second:
      calories += 280;
      protein += 8;
      waterMl = 2700;
    case Trimester.third:
      calories += 470;
      protein += 25;
      waterMl = 2800;
  }

  // GDM: 45–60% carb, 15–20% protein, 25–35% fat (use midpoints)
  var carbPct = 0.50;
  var fatPct = 0.30;
  if (hasGDM) {
    carbPct = 0.50;
    fatPct = 0.28;
    protein = (calories * 0.175 / 4).round(); // 17.5% of kcal ÷ 4 kcal/g
  }

  // Iron: 30 mg during pregnancy (range 30–60 mg); 120 mg for IDA
  final ironMg = hasIDA ? 120 : (pregnancy != null ? 30 : 18);

  // Calcium: 1000 mg for women ≥ 20 y; 1300 mg for adolescents
  final calciumMg = isAdolescent ? 1300 : 1000;

  // Iodine: 200 μg during pregnancy; 150 μg otherwise
  final iodineUg = pregnancy != null ? 200 : 150;

  // Folate: 600 μg during pregnancy; 400 μg pre-pregnancy
  final folateMcg = pregnancy != null ? 600 : 400;

  return RecommendedTargets(
    calories: calories,
    protein: protein,
    waterMl: waterMl,
    ironMg: ironMg,
    calciumMg: calciumMg,
    folateMcg: folateMcg,
    vitaminDMcg: 10,
    vitaminB12Mcg: pregnancy != null ? 2.6 : 2.4,
    sodiumMg: 2000,
    iodineUg: iodineUg,
    carbPct: carbPct,
    fatPct: fatPct,
  );
}
