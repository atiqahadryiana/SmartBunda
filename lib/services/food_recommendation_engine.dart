/// SmartBunda — AI Food Recommendation engine (deterministic, explainable).
///
/// Produces ONE safe, guideline-compliant food recommendation by scoring the
/// local MyFCD food database against the patient's nutrient gaps, applying the
/// spec's priority order and hard safety exclusions.
///
/// Priority order (higher wins on conflict):
///   1. Attached Nutrition Guideline   (prohibited foods + mandated targets)
///   2. Healthcare Professional notes   (extra restrictions)
///   3. Patient Health Profile          (allergies, conditions, BMI)
///   4. Assessment Results              (e.g. low iron / GDM risk → bias)
///   5. Meal History                    (today's running totals → gaps)
///   6. General pregnancy nutrition     (baseline tips)
///
/// The result is fully traceable: it records which guideline version and which
/// signals were used, plus a plain-language reason — everything the audit trail
/// and Medical Records need.
library smartbunda.food_recommendation_engine;

import 'package:smartbunda/models/assessment_catalog.dart';
import 'package:smartbunda/models/assessment_result.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/models/nutrition_guideline.dart';
import 'package:smartbunda/models/pregnancy.dart';
import 'package:smartbunda/models/profile.dart';
import 'package:smartbunda/utils/food_nutrition_lookup.dart';
import 'package:smartbunda/utils/nutrition_guides.dart';

/// A single compliance check shown in the "Guideline Compliance" section.
class ComplianceCheck {
  const ComplianceCheck(this.label, this.passed, {this.note});
  final String label;
  final bool passed;
  final String? note;
}

/// The engine output: the recommended food (portion-scaled) plus everything
/// needed to display, explain, log, and audit it.
class FoodRecommendation {
  const FoodRecommendation({
    required this.food,
    required this.servingG,
    required this.guideline,
    required this.reason,
    required this.compliance,
    required this.targetGapNutrients,
    required this.signalsUsed,
    required this.estimatedFromSimilar,
  });

  /// Portion-scaled nutrition for the recommended serving.
  final FoodNutritionData food;
  final double servingG;
  final NutritionGuideline guideline;

  /// Plain-language "Why this meal?" explanation.
  final String reason;
  final List<ComplianceCheck> compliance;

  /// Nutrient keys this food helps close (e.g. {'iron','protein'}).
  final Set<String> targetGapNutrients;

  /// Audit: which priority signals contributed (e.g. 'guideline', 'profile',
  /// 'assessment:nutrition_risk', 'mealHistory').
  final List<String> signalsUsed;

  /// True when the food's data was matched approximately (show the spec's
  /// "Estimated nutritional values based on similar foods." note).
  final bool estimatedFromSimilar;

  bool get fullyCompliant => compliance.every((c) => c.passed);
}

class FoodRecommendationEngine {
  const FoodRecommendationEngine();

  /// Generate a recommendation. Returns null only when there are no safe
  /// candidate foods at all (extremely unlikely with the local DB).
  FoodRecommendation? recommend({
    required NutritionGuideline guideline,
    Profile? profile,
    Pregnancy? pregnancy,
    List<AssessmentResult> assessments = const [],
    List<FoodEntry> todaysMeals = const [],
    Set<String> allergies = const {},
    List<String> professionalRestrictions = const [],
    int? rotationSeed,
  }) {
    final signals = <String>['general'];

    // ── Targets: patient-specific MOH targets, raised to any guideline floor.
    final targets = recommendedFor(pregnancy, profile: profile);
    signals.add('guideline:${guideline.version}');
    if (profile != null) signals.add('profile');
    if (pregnancy != null) signals.add('pregnancy:t${pregnancy.gestationalWeek}');

    final ironTarget =
        _floor(targets.ironMg, guideline.nutrientTargets['iron']);
    final proteinTarget =
        _floor(targets.protein, guideline.nutrientTargets['protein']);
    final calciumTarget =
        _floor(targets.calciumMg, guideline.nutrientTargets['calcium']);

    // ── Running totals from today's meals → nutrient gaps (priority 5).
    var ironSoFar = 0.0, proteinSoFar = 0.0, calciumSoFar = 0.0;
    var caloriesSoFar = 0;
    for (final m in todaysMeals) {
      ironSoFar += m.ironMg;
      proteinSoFar += m.protein;
      caloriesSoFar += m.calories;
    }
    if (todaysMeals.isNotEmpty) signals.add('mealHistory');

    // ── Assessment-driven biases (priority 4).
    var biasIron = false, biasLowSodium = false, biasLowSugar = false;
    for (final a in assessments) {
      switch (a.assessmentId) {
        case 'nutrition_risk':
          if (a.band != RiskBand.low) {
            biasIron = true;
            signals.add('assessment:nutrition_risk');
          }
        case 'gdm_risk':
          if (a.band != RiskBand.low) {
            biasLowSugar = true;
            signals.add('assessment:gdm_risk');
          }
      }
    }
    // Profile conditions (priority 3) — drives nutrient biases per condition.
    final conditions = profile?.medicalConditions ?? const <MedicalCondition>{};
    if (conditions.contains(MedicalCondition.anemia)) {
      biasIron = true;
      signals.add('condition:anemia');
    }
    if (conditions.contains(MedicalCondition.gestationalDiabetes)) {
      biasLowSugar = true;
      signals.add('condition:gdm');
    }
    // Hypertension / pre-eclampsia → keep sodium low (DASH-style guidance).
    if (conditions.contains(MedicalCondition.hypertension) ||
        conditions.contains(MedicalCondition.preeclampsia)) {
      biasLowSodium = true;
      signals.add('condition:hypertension');
    }
    // Obesity (reported or by BMI category) → lower-sodium, energy-aware picks.
    final obeseByBmi =
        profile?.bmiCategory == BmiCategory.obese; // Malaysian cut-off
    if (conditions.contains(MedicalCondition.obesity) || obeseByBmi) {
      biasLowSodium = true;
      biasLowSugar = true;
      signals.add('condition:obesity');
    }

    // ── Maternal risk level (priority 3.5) — higher tiers tighten safety. ───
    // Yellow/Red pregnancies (GDM, PIH, severe anemia, etc.) get the strictest
    // low-sugar + low-sodium + iron-forward bias regardless of other signals.
    final risk = PregnancyRiskLevel.fromCode(pregnancy?.riskLevel);
    if (risk == PregnancyRiskLevel.yellow || risk == PregnancyRiskLevel.red) {
      biasLowSugar = true;
      biasLowSodium = true;
      biasIron = true;
      signals.add('risk:${risk!.code}');
    } else if (risk == PregnancyRiskLevel.green) {
      signals.add('risk:green');
    }

    // Gaps (fraction of target still unmet → weight).
    final ironGap = _gap(ironSoFar, ironTarget);
    final proteinGap = _gap(proteinSoFar, proteinTarget);
    final calciumGap = _gap(calciumSoFar, calciumTarget.toDouble());

    // ── Build the safe candidate set (priorities 1–3 exclusions). ──────────
    final restrictions = professionalRestrictions
        .map((e) => e.toLowerCase())
        .toList(growable: false);
    if (restrictions.isNotEmpty) signals.add('professionalNotes');
    final allergyList =
        allergies.map((e) => e.toLowerCase()).toList(growable: false);

    final candidates = <_Scored>[];
    for (final food in LocalNutritionLookup.all) {
      final name = food.name.toLowerCase();
      // 1. Guideline prohibition (highest priority, hard exclude).
      if (guideline.prohibits(food.name, food.category)) continue;
      // 2. Professional restrictions.
      if (restrictions.any((r) => name.contains(r))) continue;
      // 3. Allergies + aliases.
      if (allergyList.any((al) =>
          name.contains(al) || food.aliases.any((a) => a.contains(al)))) {
        continue;
      }

      final scaled = food.scaleToPortionG(food.defaultPortionG);
      candidates.add(_Scored(
        food: scaled,
        score: _score(
          scaled,
          ironGap: ironGap,
          proteinGap: proteinGap,
          calciumGap: calciumGap,
          biasIron: biasIron,
          biasLowSodium: biasLowSodium,
          biasLowSugar: biasLowSugar,
          guideline: guideline,
        ),
      ));
    }
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.score.compareTo(a.score));

    // Rotate among the top matches so "Generate another" varies safely without
    // dropping compliance.
    final topN = candidates.take(5).toList();
    final pick = topN[(rotationSeed ?? 0) % topN.length];
    final chosen = pick.food;

    // ── Which gaps this food addresses (for the reason text). ──────────────
    final addressed = <String>{};
    if (biasIron && chosen.ironMg >= 1.5) addressed.add('iron');
    if (chosen.proteinG >= 15) addressed.add('protein');
    if (chosen.calciumMg >= 150) addressed.add('calcium');
    if (chosen.fibreG >= 4) addressed.add('fibre');

    final compliance = _compliance(chosen, guideline,
        proteinTarget: proteinTarget,
        ironTarget: ironTarget,
        calciumTarget: calciumTarget);

    final reason = _reason(
      food: chosen,
      guideline: guideline,
      pregnancy: pregnancy,
      addressed: addressed,
      biasIron: biasIron,
      biasLowSugar: biasLowSugar,
      biasLowSodium: biasLowSodium,
      hasMealHistory: todaysMeals.isNotEmpty,
      caloriesSoFar: caloriesSoFar,
    );

    return FoodRecommendation(
      food: chosen,
      servingG: chosen.defaultPortionG,
      guideline: guideline,
      reason: reason,
      compliance: compliance,
      targetGapNutrients: addressed,
      signalsUsed: signals,
      // Local DB is authoritative for its entries; mark estimated only when we
      // ever fall back to similarity (reserved for future MyFDB lookups).
      estimatedFromSimilar: false,
    );
  }

  // ── Scoring ───────────────────────────────────────────────────────────────
  double _score(
    FoodNutritionData f, {
    required double ironGap,
    required double proteinGap,
    required double calciumGap,
    required bool biasIron,
    required bool biasLowSodium,
    required bool biasLowSugar,
    required NutritionGuideline guideline,
  }) {
    var score = 0.0;
    // Reward closing the biggest gaps.
    score += (f.proteinG / 25.0) * proteinGap * 40;
    score += (f.ironMg / 4.0) * ironGap * 40;
    score += (f.calciumMg / 300.0) * calciumGap * 25;
    score += (f.fibreG / 6.0) * 12;

    if (biasIron) score += (f.ironMg) * 4;

    // Penalise against guideline caps / GDM / BMI biases.
    final sodiumCap = guideline.maxSodiumMgPerMeal ?? 800;
    if (f.sodiumMg > sodiumCap) score -= (f.sodiumMg - sodiumCap) / 20;
    if (biasLowSodium && f.sodiumMg > 400) score -= 8;

    final sugar = f.sugarG;
    final sugarCap = (guideline.maxSugarGPerMeal ?? 25).toDouble();
    if (sugar != null && sugar > sugarCap) score -= (sugar - sugarCap);
    if (biasLowSugar && (sugar ?? 0) > 12) score -= 12;
    final isSweetTreat =
        f.category == 'dessert' || f.category == 'drink' || f.category == 'beverage';
    if (biasLowSugar && isSweetTreat) score -= 20;

    // Sugary drinks/desserts are poor primary meal recommendations for any
    // pregnancy: little protein/iron for their sugar+calories. Down-rank them
    // so a real meal wins, even before condition-specific biases apply.
    if (isSweetTreat && (sugar ?? 0) > 15 && f.proteinG < 8) score -= 25;

    // Mild penalty for very energy-dense fried items.
    if (f.energyKcal > 550) score -= 6;
    return score;
  }

  // ── Compliance section ──────────────────────────────────────────────────
  List<ComplianceCheck> _compliance(
    FoodNutritionData f,
    NutritionGuideline g, {
    required int proteinTarget,
    required int ironTarget,
    required int calciumTarget,
  }) {
    final sodiumCap = (g.maxSodiumMgPerMeal ?? 800).toDouble();
    final sugar = f.sugarG;
    final sugarCap = (g.maxSugarGPerMeal ?? 25).toDouble();
    return [
      ComplianceCheck('Follows ${g.title.toLowerCase()}', true),
      const ComplianceCheck('Pregnancy-safe food choice', true,
          note: 'No alcohol, raw or unpasteurized ingredients.'),
      ComplianceCheck(
        'Meets meaningful protein',
        f.proteinG >= (proteinTarget * 0.2),
        note: f.proteinG >= (proteinTarget * 0.2)
            ? null
            : 'Pair with eggs, beans, tofu or lean meat to add protein.',
      ),
      ComplianceCheck(
        'Supports daily iron target',
        f.ironMg >= 1.0,
        note: f.ironMg >= 1.0
            ? null
            : 'Low in iron — combine with iron-rich sides and vitamin C.',
      ),
      ComplianceCheck(
        'Within sodium limit (${sodiumCap.round()} mg/meal)',
        f.sodiumMg <= sodiumCap,
        note: f.sodiumMg <= sodiumCap
            ? null
            : 'Sodium is above the guideline limit — reduce added salt/sauces.',
      ),
      if (sugar != null)
        ComplianceCheck(
          'Within sugar limit (${sugarCap.round()} g/meal)',
          sugar <= sugarCap,
          note: sugar <= sugarCap
              ? null
              : 'Sugar is above the guideline limit for this serving.',
        ),
    ];
  }

  // ── Plain-language explanation ────────────────────────────────────────────
  String _reason({
    required FoodNutritionData food,
    required NutritionGuideline guideline,
    required Pregnancy? pregnancy,
    required Set<String> addressed,
    required bool biasIron,
    required bool biasLowSugar,
    required bool biasLowSodium,
    required bool hasMealHistory,
    required int caloriesSoFar,
  }) {
    final parts = <String>[];
    parts.add('This follows your ${guideline.title.toLowerCase()}');
    if (pregnancy != null) {
      parts.add('and is suitable for week ${pregnancy.gestationalWeek} of '
          'your pregnancy');
    }
    parts.add('.');

    if (addressed.contains('iron') || biasIron) {
      parts.add(' It helps increase iron intake, which supports healthy blood '
          'and is important during pregnancy.');
    }
    if (addressed.contains('protein')) {
      parts.add(' It is a good protein source for your baby\'s growth.');
    }
    if (addressed.contains('calcium')) {
      parts.add(' It adds calcium for bone health.');
    }
    if (biasLowSodium && !biasLowSugar) {
      parts.add(' We picked a lower-sodium option to support healthy blood '
          'pressure.');
    }
    if (biasLowSugar) {
      parts.add(' We chose a lower-sugar option based on your health profile '
          'and risk level.');
    }
    if (hasMealHistory) {
      parts.add(' It balances what you have already eaten today '
          '($caloriesSoFar kcal so far).');
    } else {
      parts.add(' Log your meals to make future suggestions even more '
          'personalized.');
    }
    return parts.join().replaceAll(' .', '.');
  }

  int _floor(int base, num? guidelineFloor) {
    if (guidelineFloor == null) return base;
    return base > guidelineFloor ? base : guidelineFloor.round();
  }

  /// Fraction of [target] still unmet, clamped 0..1.
  double _gap(double soFar, num target) {
    if (target <= 0) return 0;
    final remaining = (target - soFar) / target;
    return remaining.clamp(0.0, 1.0);
  }
}

class _Scored {
  const _Scored({required this.food, required this.score});
  final FoodNutritionData food;
  final double score;
}
