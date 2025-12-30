import 'dart:async';

import '../models/nutrition_plan.dart';
import 'nutrition_plan_repository.dart';

class InMemoryNutritionPlanRepository implements NutritionPlanRepository {
  final Map<String, NutritionPlan> _plansById = {};
  final Map<String, StreamController<List<NutritionPlan>>> _patientControllers = {};
  late final StreamController<List<NutritionPlan>> _allController;

  InMemoryNutritionPlanRepository() {
    _allController = StreamController<List<NutritionPlan>>.broadcast(
      onListen: _emitAll,
    );
  }

  @override
  Stream<List<NutritionPlan>> watchPlans(String patientId) {
    return (_patientControllers[patientId] ??=
            StreamController<List<NutritionPlan>>.broadcast(
              onListen: () => _emitPatient(patientId),
            ))
        .stream;
  }

  @override
  Stream<List<NutritionPlan>> watchAllPlans() => _allController.stream;

  @override
  Future<NutritionPlan> createPlan(NutritionPlan plan) async {
    _plansById[plan.id] = plan;
    _emitPatient(plan.patientId);
    _emitAll();
    return plan;
  }

  @override
  Future<void> updatePlan(NutritionPlan plan) async {
    if (!_plansById.containsKey(plan.id)) {
      throw Exception('Plan not found');
    }
    _plansById[plan.id] = plan;
    _emitPatient(plan.patientId);
    _emitAll();
  }

  @override
  Future<void> approvePlan({
    required String planId,
    required String approverId,
  }) async {
    final plan = _plansById[planId];
    if (plan == null) {
      throw Exception('Plan not found');
    }
    final updated = plan.copyWith(
      status: NutritionPlanStatus.active,
    );
    _plansById[planId] = updated;
    _emitPatient(updated.patientId);
    _emitAll();
  }

  @override
  Future<void> rejectPlan({
    required String planId,
    String? reason,
  }) async {
    final plan = _plansById[planId];
    if (plan == null) {
      throw Exception('Plan not found');
    }
    final updated = plan.copyWith(
      status: NutritionPlanStatus.inactive,
      notes: reason ?? plan.notes,
    );
    _plansById[planId] = updated;
    _emitPatient(updated.patientId);
    _emitAll();
  }

  @override
  Map<String, dynamic> exportState() {
    return {
      'plans': _plansById.values.map((p) => p.toJson()).toList(),
    };
  }

  @override
  void restoreState(Map<String, dynamic> data) {
    final raw = data['plans'];
    if (raw is List) {
      _plansById
        ..clear()
        ..addEntries(
          raw
              .whereType<Map>()
              .map((e) => NutritionPlan.fromJson(e.cast<String, dynamic>()))
              .map((plan) => MapEntry(plan.id, plan)),
        );
      _emitAll();
      for (final patientId in _plansById.values.map((p) => p.patientId).toSet()) {
        _emitPatient(patientId);
      }
    }
  }

  void _emitPatient(String patientId) {
    _patientControllers[patientId]?.add(_plansForPatient(patientId));
  }

  void _emitAll() {
    _allController.add(_plansById.values.toList());
  }

  List<NutritionPlan> _plansForPatient(String patientId) {
    return _plansById.values.where((p) => p.patientId == patientId).toList();
  }

  void dispose() {
    for (final controller in _patientControllers.values) {
      controller.close();
    }
    _allController.close();
  }
}
