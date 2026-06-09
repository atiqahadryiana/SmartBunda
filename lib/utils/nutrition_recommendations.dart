/// SmartBunda — Nutrition recommendation engine.
///
/// Pure, rule-based tips derived from a (portion-scaled) [FoodNutritionData].
/// Tuned for a single logged item in a pregnancy context. Only fields that are
/// actually present drive tips — null micronutrients are skipped (no fabricated
/// advice). General, non-diagnostic guidance; always defers to the care team.
library smartbunda.nutrition_recommendations;

import 'package:flutter/material.dart';

import 'package:smartbunda/utils/food_nutrition_lookup.dart';

enum TipTone { positive, caution, info }

class NutritionTip {
  const NutritionTip({
    required this.title,
    required this.message,
    required this.tone,
    required this.icon,
  });

  final String title;
  final String message;
  final TipTone tone;
  final IconData icon;
}

class NutritionRecommendations {
  const NutritionRecommendations._();

  /// Generate tips for a single serving's worth of [n] (already portion-scaled).
  static List<NutritionTip> recommend(FoodNutritionData n) {
    final tips = <NutritionTip>[];

    // High sugar (only if known).
    final sugar = n.sugarG;
    if (sugar != null && sugar >= 22) {
      tips.add(const NutritionTip(
        title: 'High in sugar',
        message:
            'This serving is high in sugar. Consider smaller portions, pair it '
            'with protein or fibre, and drink water instead of sweet drinks.',
        tone: TipTone.caution,
        icon: Icons.cake_outlined,
      ));
    }

    // High sodium.
    if (n.sodiumMg >= 600) {
      tips.add(const NutritionTip(
        title: 'High in sodium',
        message:
            'Sodium is on the higher side. Choose fresher ingredients and fewer '
            'processed or heavily seasoned foods to support healthy blood '
            'pressure.',
        tone: TipTone.caution,
        icon: Icons.water_drop_outlined,
      ));
    }

    // Low protein (relative to a meal-sized serving).
    if (n.proteinG < 8 && n.energyKcal >= 200) {
      tips.add(const NutritionTip(
        title: 'Low in protein',
        message:
            'This is light on protein. Add an egg, beans, tofu, fish, or lean '
            'meat to support you and your baby.',
        tone: TipTone.info,
        icon: Icons.egg_outlined,
      ));
    }

    // Good protein.
    if (n.proteinG >= 15) {
      tips.add(const NutritionTip(
        title: 'Good protein source',
        message:
            'Nice — this serving provides a solid amount of protein, which '
            'supports your baby\'s growth.',
        tone: TipTone.positive,
        icon: Icons.fitness_center_outlined,
      ));
    }

    // Good fibre.
    if (n.fibreG >= 5) {
      tips.add(const NutritionTip(
        title: 'Good source of fibre',
        message:
            'The fibre here helps digestion and can ease pregnancy '
            'constipation. Keep up the fibre-rich choices.',
        tone: TipTone.positive,
        icon: Icons.eco_outlined,
      ));
    }

    // Iron — useful during pregnancy.
    if (n.ironMg >= 3) {
      tips.add(const NutritionTip(
        title: 'Contains iron',
        message:
            'This serving provides iron. Pair it with vitamin C (e.g. citrus) '
            'to help your body absorb it.',
        tone: TipTone.positive,
        icon: Icons.bloodtype_outlined,
      ));
    }

    // High energy.
    if (n.energyKcal >= 600) {
      tips.add(const NutritionTip(
        title: 'Energy-dense serving',
        message:
            'This is a calorie-rich portion. That can be fine — just balance it '
            'across your day and stay active as advised by your care team.',
        tone: TipTone.info,
        icon: Icons.local_fire_department_outlined,
      ));
    }

    if (tips.isEmpty) {
      tips.add(const NutritionTip(
        title: 'Balanced choice',
        message:
            'This looks like a reasonable choice. Keep variety across your meals '
            'and follow any targets from your care team.',
        tone: TipTone.positive,
        icon: Icons.check_circle_outline,
      ));
    }

    return tips;
  }
}
