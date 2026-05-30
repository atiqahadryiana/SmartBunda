import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:smartbunda/firestore_paths.dart';
import 'package:smartbunda/models/nutrition_plan.dart';
import 'package:smartbunda/services/nutrition_plan_repository.dart';

class FirestoreNutritionPlanRepository implements NutritionPlanRepository {
  FirestoreNutritionPlanRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<NutritionPlan>> watchPlans(String patientId) {
    return _firestore
        .collection(FS.nutritionPlans)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .asyncMap((snapshot) => _attachTargets(snapshot.docs));
  }

  @override
  Stream<List<NutritionPlan>> watchAllPlans() {
    return _firestore
        .collection(FS.nutritionPlans)
        .snapshots()
        .asyncMap((snapshot) => _attachTargets(snapshot.docs));
  }

  @override
  Future<NutritionPlan> createPlan(NutritionPlan plan) async {
    await _firestore
        .collection(FS.nutritionPlans)
        .doc(plan.id)
        .set(_toMap(plan));
    if (plan.targets != null) {
      await _upsertTargets(plan.id, plan.targets!);
    }
    return plan;
  }

  @override
  Future<void> updatePlan(NutritionPlan plan) async {
    await _firestore
        .collection(FS.nutritionPlans)
        .doc(plan.id)
        .set(_toMap(plan), SetOptions(merge: true));
    if (plan.targets != null) {
      await _upsertTargets(plan.id, plan.targets!);
    }
  }

  @override
  Future<void> approvePlan({
    required String planId,
    required String approverId,
  }) async {
    await _firestore.collection(FS.nutritionPlans).doc(planId).set(
      {'status': 'ACTIVE'},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> rejectPlan({
    required String planId,
    String? reason,
  }) async {
    await _firestore.collection(FS.nutritionPlans).doc(planId).set(
      {
        'status': 'INACTIVE',
        'notes': reason,
      },
      SetOptions(merge: true),
    );
  }

  @override
  Map<String, dynamic> exportState() => {};

  @override
  void restoreState(Map<String, dynamic> data) {}

  Map<String, dynamic> _toMap(NutritionPlan plan) {
    return {
      'id': plan.id,
      'patientId': plan.patientId,
      'createdBy': plan.createdBy,
      'notes': plan.notes,
      'status': _statusToString(plan.status),
      'startDate': plan.startDate,
      'endDate': plan.endDate,
    };
  }

  String _statusToString(NutritionPlanStatus status) {
    switch (status) {
      case NutritionPlanStatus.inactive:
        return 'INACTIVE';
      case NutritionPlanStatus.pending:
        return 'PENDING';
      case NutritionPlanStatus.active:
        return 'ACTIVE';
    }
  }

  Future<List<NutritionPlan>> _attachTargets(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) return [];
    final plans = docs.map((doc) => doc.data()).toList();
    final targetsByPlan = <String, NutritionTargets>{};
    for (final plan in plans) {
      final planId = plan['id'] as String? ?? '';
      if (planId.isEmpty) continue;
      final snapshot = await _firestore
          .collection(FS.nutritionTargets)
          .where('planId', isEqualTo: planId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) continue;
      final data = snapshot.docs.first.data();
      final nutrients = (data['nutrientTargets'] as Map?)?.cast<String, dynamic>() ?? {};
      targetsByPlan[planId] = NutritionTargets(
        dailyCalories: (data['dailyCalories'] as num?)?.toInt() ?? 0,
        proteinG: (nutrients['protein_g'] as num?)?.toInt() ?? 0,
        ironMg: (nutrients['iron_mg'] as num?)?.toDouble() ?? 0,
        folateMcg: (nutrients['folate_mcg'] as num?)?.toDouble() ?? 0,
      );
    }
    return plans
        .map(
          (json) => NutritionPlan.fromJson(
            json,
            targets: targetsByPlan[json['id'] as String? ?? ''],
          ),
        )
        .toList();
  }

  Future<void> _upsertTargets(String planId, NutritionTargets targets) async {
    final query = await _firestore
        .collection(FS.nutritionTargets)
        .where('planId', isEqualTo: planId)
        .limit(1)
        .get();
    final docRef = query.docs.isEmpty
        ? _firestore.collection(FS.nutritionTargets).doc()
        : query.docs.first.reference;
    await docRef.set(
      {
        'planId': planId,
        'dailyCalories': targets.dailyCalories,
        'nutrientTargets': {
          'protein_g': targets.proteinG,
          'iron_mg': targets.ironMg,
          'folate_mcg': targets.folateMcg,
        },
      },
      SetOptions(merge: true),
    );
  }
}
