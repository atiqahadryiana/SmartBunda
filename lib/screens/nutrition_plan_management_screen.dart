import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/food_entry.dart';
import '../models/nutrition_plan.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/screen_header.dart';

class NutritionPlanManagementScreen extends ConsumerWidget {
  const NutritionPlanManagementScreen({
    super.key,
    required this.role,
    this.showAppBar = false,
  });

  final UserRole role;
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final effectiveRole = user?.role ?? role;

    final plansAsync = effectiveRole == UserRole.patient
        ? ref.watch(plansProvider)
        : ref.watch(allPlansProvider);
    final usersAsync = ref.watch(usersProvider);
    final allEntriesAsync = ref.watch(allEntriesProvider);

    final child = user == null
        ? const SizedBox.shrink()
        : Scaffold(
            appBar: showAppBar ? AppBar(title: const Text('Nutrition plans')) : null,
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenHeader(
                    title: 'Nutrition plans',
                    subtitle: effectiveRole == UserRole.patient
                        ? 'Review the plan shared by your care team.'
                        : 'Create and adjust nutrition targets for patients.',
                    icon: Icons.playlist_add_check,
                    action: effectiveRole == UserRole.patient
                        ? null
                        : FilledButton.icon(
                            onPressed: () => _showPlanForm(context, ref, user),
                            icon: const Icon(Icons.add),
                            label: const Text('Create plan'),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: plansAsync.when(
                      data: (plans) {
                        if (plans.isEmpty) {
                          return const EmptyState(
                            icon: Icons.playlist_add_check,
                            title: 'No plans yet',
                            message: 'Create a plan to set daily nutrition targets.',
                          );
                        }
                        final users = usersAsync.valueOrNull ?? const <AppUser>[];
                        final entries = allEntriesAsync.valueOrNull ?? {};
                        return ListView.separated(
                          itemCount: plans.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final plan = plans[index];
                            final patient = users.firstWhere(
                              (u) => u.id == plan.patientId,
                              orElse: () => AppUser(
                                id: plan.patientId,
                                email: 'unknown@example.com',
                                role: UserRole.patient,
                              ),
                            );
                            final adherence = _adherence(
                              plan,
                              entries[plan.patientId] ?? const <FoodEntry>[],
                            );
                            final status = plan.status.name.toUpperCase();
                            final range = _dateRange(plan.startDate, plan.endDate);
                            return Card(
                              child: ListTile(
                                title: Text(patient.displayName ?? patient.email),
                                subtitle:
                                    Text('$range | $status | ${adherence.toStringAsFixed(0)}%'),
                                trailing: _planActions(context, ref, user, plan),
                                onTap: () => _showPlanDetails(context, plan, patient),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                ],
              ),
            ),
          );

    return RequireSignIn(
      title: 'Nutrition plans',
      showAppBar: showAppBar,
      message: 'Please sign in to view nutrition plans.',
      child: child,
    );
  }

  double _adherence(NutritionPlan plan, List<FoodEntry> entries) {
    final targetCalories = plan.targets?.dailyCalories ?? 0;
    if (targetCalories == 0 || entries.isEmpty) return 0;
    final now = DateTime.now();
    final lastWeek = entries.where((entry) {
      final diff = now.difference(entry.date).inDays;
      return diff >= 0 && diff <= 7;
    });
    if (lastWeek.isEmpty) return 0;
    final totalCalories = lastWeek.fold<int>(0, (sum, e) => sum + e.calories);
    final avgCalories = totalCalories / lastWeek.length;
    return (avgCalories / targetCalories * 100).clamp(0, 200);
  }

  Widget _planActions(BuildContext context, WidgetRef ref, AppUser user, NutritionPlan plan) {
    if (user.role == UserRole.patient) return const SizedBox.shrink();
    if (user.role == UserRole.doctor && plan.status == NutritionPlanStatus.pending) {
      return PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'approve') {
            await ref.read(nutritionPlanRepositoryProvider).approvePlan(
                  planId: plan.id,
                  approverId: user.id,
                );
          } else if (value == 'reject') {
            _showRejectDialog(context, ref, planId: plan.id);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'approve', child: Text('Approve plan')),
          PopupMenuItem(value: 'reject', child: Text('Reject plan')),
        ],
      );
    }
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'edit') {
          _showPlanForm(context, ref, user, plan: plan);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit plan')),
      ],
    );
  }

  Future<void> _showPlanForm(
    BuildContext context,
    WidgetRef ref,
    AppUser user, {
    NutritionPlan? plan,
  }) async {
    final users = ref.read(usersProvider).valueOrNull ?? const <AppUser>[];
    final patients = users.where((u) => u.role == UserRole.patient).toList();
    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patients available yet.')),
      );
      return;
    }
    AppUser? selectedPatient = plan == null
        ? patients.first
        : patients.firstWhere((p) => p.id == plan.patientId, orElse: () => patients.first);
    final startCtrl = TextEditingController(text: plan?.startDate ?? '');
    final endCtrl = TextEditingController(text: plan?.endDate ?? '');
    final notesCtrl = TextEditingController(text: plan?.notes ?? '');
    final calorieCtrl = TextEditingController(
      text: plan?.targets?.dailyCalories.toString() ?? '',
    );
    final proteinCtrl = TextEditingController(
      text: plan?.targets?.proteinG.toString() ?? '',
    );
    final ironCtrl = TextEditingController(
      text: plan?.targets?.ironMg.toString() ?? '',
    );
    final folateCtrl = TextEditingController(
      text: plan?.targets?.folateMcg.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plan == null ? 'Create plan' : 'Edit plan'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<AppUser>(
                    initialValue: selectedPatient,
                    items: patients
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.displayName ?? p.email),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => selectedPatient = value,
                    decoration: const InputDecoration(labelText: 'Patient'),
                    validator: (value) => value == null ? 'Select a patient' : null,
                  ),
                  TextFormField(
                    controller: startCtrl,
                    decoration: const InputDecoration(labelText: 'Start date (YYYY-MM-DD)'),
                  ),
                  TextFormField(
                    controller: endCtrl,
                    decoration: const InputDecoration(labelText: 'End date (YYYY-MM-DD)'),
                  ),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
                  ),
                  _numberField(calorieCtrl, 'Daily calories'),
                  _numberField(proteinCtrl, 'Protein (g)'),
                  _numberField(ironCtrl, 'Iron (mg)'),
                  _numberField(folateCtrl, 'Folate (mcg)'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final patient = selectedPatient!;
              final resolvedStatus = _resolveStatus(user.role, plan?.status);
              final updated = NutritionPlan(
                id: plan?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                patientId: patient.id,
                createdBy: user.id,
                status: resolvedStatus,
                startDate: startCtrl.text.trim().isEmpty ? null : startCtrl.text.trim(),
                endDate: endCtrl.text.trim().isEmpty ? null : endCtrl.text.trim(),
                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                targets: NutritionTargets(
                  dailyCalories: int.tryParse(calorieCtrl.text) ?? 0,
                  proteinG: int.tryParse(proteinCtrl.text) ?? 0,
                  ironMg: double.tryParse(ironCtrl.text) ?? 0,
                  folateMcg: double.tryParse(folateCtrl.text) ?? 0,
                ),
              );
              if (plan == null) {
                await ref.read(nutritionPlanRepositoryProvider).createPlan(updated);
              } else {
                await ref.read(nutritionPlanRepositoryProvider).updatePlan(updated);
              }
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  NutritionPlanStatus _resolveStatus(
    UserRole role,
    NutritionPlanStatus? currentStatus,
  ) {
    if (currentStatus != null) return currentStatus;
    if (role == UserRole.dietitian) return NutritionPlanStatus.pending;
    return NutritionPlanStatus.active;
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref, {
    required String planId,
  }) async {
    final reasonCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject plan'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(nutritionPlanRepositoryProvider).rejectPlan(
                    planId: planId,
                    reason: reasonCtrl.text.trim().isEmpty
                        ? null
                        : reasonCtrl.text.trim(),
                  );
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
    );
  }

  void _showPlanDetails(BuildContext context, NutritionPlan plan, AppUser patient) {
    final targets = plan.targets;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(patient.displayName ?? patient.email),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dates: ${_dateRange(plan.startDate, plan.endDate)}'),
              const SizedBox(height: 8),
              if (targets != null) ...[
                Text('Calories: ${targets.dailyCalories} kcal'),
                Text('Protein: ${targets.proteinG} g'),
                Text('Iron: ${targets.ironMg} mg'),
                Text('Folate: ${targets.folateMcg} mcg'),
              ],
              if ((plan.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Notes: ${plan.notes}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _dateRange(String? start, String? end) {
    final startLabel = (start == null || start.isEmpty) ? 'Start TBD' : start;
    final endLabel = (end == null || end.isEmpty) ? 'End TBD' : end;
    return '$startLabel - $endLabel';
  }
}


