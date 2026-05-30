import 'package:smartbunda/models/nutrition_plan.dart';

abstract class NutritionPlanRepository {
  Stream<List<NutritionPlan>> watchPlans(String patientId);
  Stream<List<NutritionPlan>> watchAllPlans();
  Future<NutritionPlan> createPlan(NutritionPlan plan);
  Future<void> updatePlan(NutritionPlan plan);
  Future<void> approvePlan({
    required String planId,
    required String approverId,
  });
  Future<void> rejectPlan({
    required String planId,
    String? reason,
  });
  Map<String, dynamic> exportState();
  void restoreState(Map<String, dynamic> data);
}
