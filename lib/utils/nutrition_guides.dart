import '../models/pregnancy.dart';

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
}

RecommendedTargets recommendedFor(Pregnancy? pregnancy) {
  final trimester = pregnancy?.trimesterEnum ?? Trimester.second;
  // Simple trimester-based defaults; can expand per condition later.
  switch (trimester) {
    case Trimester.first:
      return RecommendedTargets(
        calories: 2000,
        protein: 75,
        waterMl: 2500,
        ironMg: 27,
        calciumMg: 1000,
        folateMcg: 600,
        vitaminDMcg: 10,
        vitaminB12Mcg: 2.6,
        sodiumMg: 2000,
      );
    case Trimester.second:
      return RecommendedTargets(
        calories: 2300,
        protein: 85,
        waterMl: 2700,
        ironMg: 27,
        calciumMg: 1000,
        folateMcg: 600,
        vitaminDMcg: 10,
        vitaminB12Mcg: 2.6,
        sodiumMg: 2000,
      );
    case Trimester.third:
      return RecommendedTargets(
        calories: 2400,
        protein: 90,
        waterMl: 2800,
        ironMg: 27,
        calciumMg: 1000,
        folateMcg: 600,
        vitaminDMcg: 10,
        vitaminB12Mcg: 2.6,
        sodiumMg: 2000,
      );
  }
}
