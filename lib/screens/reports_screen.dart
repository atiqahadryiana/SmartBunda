import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../models/app_user.dart';
import '../models/food_entry.dart';
import '../models/pregnancy.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../utils/nutrition_guides.dart';
import '../widgets/empty_state.dart';
import '../widgets/screen_header.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({
    super.key,
    required this.role,
    this.showAppBar = false,
  });

  final UserRole role;
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (role == UserRole.admin) {
      return _AdminAnalyticsView(showAppBar: showAppBar);
    }
    if (role == UserRole.patient) {
      return _PatientReportView(showAppBar: showAppBar);
    }
    return _ClinicianReportView(showAppBar: showAppBar);
  }
}

class _PatientReportView extends ConsumerWidget {
  const _PatientReportView({required this.showAppBar});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);
    final pregnancyAsync = ref.watch(pregnancyProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Reports')) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: entriesAsync.when(
          data: (entries) {
            final pregnancy = pregnancyAsync.valueOrNull;
            final summary = _weeklySummary(entries);
            final targets = _targets(pregnancy);
            final caloriePct = targets.calories == 0
                ? 0
                : (summary.calories / targets.calories * 100);
            final proteinPct = targets.protein == 0
                ? 0
                : (summary.protein / targets.protein * 100);
            return ListView(
              children: [
                const ScreenHeader(
                  title: 'Weekly report',
                  subtitle: 'Track your average intake and progress over the last 7 days.',
                  icon: Icons.assessment_outlined,
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    title: const Text('Average intake'),
                    subtitle: Text(
                      '${summary.calories} kcal | ${summary.protein} g protein',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Target adherence'),
                    subtitle: Text(
                      '${caloriePct.toStringAsFixed(0)}% calories, '
                      '${proteinPct.toStringAsFixed(0)}% protein',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _exportPatientReport(
                    context,
                    summary,
                    targets,
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('Export report'),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  _EntryTotals _weeklySummary(List<FoodEntry> entries) {
    final now = DateTime.now();
    final recent = entries.where((entry) => now.difference(entry.date).inDays <= 7);
    if (recent.isEmpty) {
      return _EntryTotals(calories: 0, protein: 0);
    }
    final totalCalories = recent.fold<int>(0, (sum, e) => sum + e.calories);
    final totalProtein = recent.fold<int>(0, (sum, e) => sum + e.protein);
    final days = recent.map((e) => _dayKey(e.date)).toSet().length;
    return _EntryTotals(
      calories: (totalCalories / days).round(),
      protein: (totalProtein / days).round(),
    );
  }

  _Targets _targets(Pregnancy? pregnancy) {
    final defaults = recommendedFor(pregnancy);
    return _Targets(
      calories: defaults.calories,
      protein: defaults.protein,
    );
  }

  String _dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  Future<void> _exportPatientReport(
    BuildContext context,
    _EntryTotals summary,
    _Targets targets,
  ) async {
    final payload = {
      'avgCalories': summary.calories,
      'avgProtein': summary.protein,
      'calorieTarget': targets.calories,
      'proteinTarget': targets.protein,
      'generatedAt': DateTime.now().toIso8601String(),
    };
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report copied to clipboard')),
      );
    }
  }
}

class _ClinicianReportView extends ConsumerWidget {
  const _ClinicianReportView({required this.showAppBar});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final entriesAsync = ref.watch(allEntriesProvider);
    final pregnanciesAsync = ref.watch(allPregnanciesProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Reports')) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: usersAsync.when(
          data: (users) {
            final patients = users.where((u) => u.role == UserRole.patient).toList();
            final entriesByUser = entriesAsync.valueOrNull ?? {};
            final pregnancies = pregnanciesAsync.valueOrNull ?? {};
            if (patients.isEmpty) {
              return const EmptyState(
                icon: Icons.assessment_outlined,
                title: 'No patient reports yet',
                message: 'Reports will appear once patients start logging meals.',
              );
            }
            return ListView(
              children: [
                const ScreenHeader(
                  title: 'Reports overview',
                  subtitle: 'Tap a patient to review their last 7 days of intake.',
                  icon: Icons.assessment_outlined,
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: patients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    final entries = entriesByUser[patient.id] ?? const <FoodEntry>[];
                    final pregnancy = pregnancies[patient.id];
                    final compliance = _compliance(entries, pregnancy);
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.assessment_outlined),
                        title: Text(patient.displayName ?? patient.email),
                        subtitle:
                            Text('${compliance.toStringAsFixed(0)}% compliance (last 7 days)'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showPatientReport(context, patient, entries, pregnancy),
                      ),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  double _compliance(List<FoodEntry> entries, Pregnancy? pregnancy) {
    if (entries.isEmpty) return 0;
    final now = DateTime.now();
    final recent = entries.where((e) => now.difference(e.date).inDays <= 7).toList();
    if (recent.isEmpty) return 0;
    final targets = recommendedFor(pregnancy);
    final calorieTarget = targets.calories;
    final byDay = <String, int>{};
    for (final entry in recent) {
      final key = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
      byDay[key] = (byDay[key] ?? 0) + entry.calories;
    }
    final onTrackDays =
        byDay.values.where((cal) => cal >= calorieTarget * 0.8).length;
    return byDay.isEmpty ? 0 : (onTrackDays / byDay.length * 100);
  }

  void _showPatientReport(
    BuildContext context,
    AppUser patient,
    List<FoodEntry> entries,
    Pregnancy? pregnancy,
  ) {
    final totals = entries.fold<int>(0, (sum, e) => sum + e.calories);
    final count = entries.length;
    final targets = recommendedFor(pregnancy);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report: ${patient.displayName ?? patient.email}'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Entries logged: $count'),
              Text('Total calories logged: $totals'),
              const SizedBox(height: 8),
              Text('Targets: ${targets.calories} kcal, ${targets.protein} g'),
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
}

class _AdminAnalyticsView extends ConsumerWidget {
  const _AdminAnalyticsView({required this.showAppBar});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final logsAsync = ref.watch(activityLogsProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Analytics')) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: usersAsync.when(
          data: (users) {
            final active = users.where((u) => u.isActive).length;
            final inactive = users.length - active;
            final logins = logsAsync.valueOrNull
                    ?.where((log) => log.type == ActivityType.login)
                    .length ??
                0;
            return ListView(
              children: [
                const ScreenHeader(
                  title: 'System usage',
                  subtitle: 'High-level metrics across all users.',
                  icon: Icons.analytics_outlined,
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    title: const Text('Total users'),
                    trailing: Text('${users.length}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Active accounts'),
                    trailing: Text('$active'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Inactive accounts'),
                    trailing: Text('$inactive'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Total logins'),
                    trailing: Text('$logins'),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _EntryTotals {
  _EntryTotals({required this.calories, required this.protein});
  final int calories;
  final int protein;
}

class _Targets {
  _Targets({required this.calories, required this.protein});
  final int calories;
  final int protein;
}
