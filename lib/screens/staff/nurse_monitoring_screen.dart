import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/models/profile.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/widgets/empty_state.dart';
import 'package:smartbunda/widgets/require_sign_in.dart';
import 'package:smartbunda/widgets/screen_header.dart';
import 'package:smartbunda/screens/staff/nutritionist_client_screen.dart';

class NurseMonitoringScreen extends ConsumerWidget {
  const NurseMonitoringScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final entriesAsync = ref.watch(allEntriesProvider);
    final profilesAsync = ref.watch(allProfilesProvider);
    final pregnanciesAsync = ref.watch(allPregnanciesProvider);

    return RequireSignIn(
      title: 'Monitoring & alerts',
      showAppBar: showAppBar,
      message: 'Please sign in to view monitoring data.',
      child: Scaffold(
        appBar: showAppBar ? AppBar(title: const Text('Monitoring & alerts')) : null,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: usersAsync.when(
            data: (users) {
              final entriesByUser = entriesAsync.valueOrNull;
              final profiles = profilesAsync.valueOrNull;
              final pregnancies = pregnanciesAsync.valueOrNull;
              if (entriesByUser == null || profiles == null || pregnancies == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final patients = users.where((u) => u.role == UserRole.patient).toList();
              if (patients.isEmpty) {
                return const EmptyState(
                  icon: Icons.monitor_heart_outlined,
                  title: 'No patients yet',
                  message: 'Patients will appear here after registration.',
                );
              }

              return ListView(
                children: [
                  const ScreenHeader(
                    title: 'Monitoring & alerts',
                    subtitle: 'Review nutrition summaries and body mass details.',
                    icon: Icons.monitor_heart_outlined,
                  ),
                  const SizedBox(height: 16),
                  ...patients.map((patient) {
                    final profile = profiles[patient.id];
                    final entries = entriesByUser[patient.id] ?? const <FoodEntry>[];
                    final pregnancy = pregnancies[patient.id];
                    final nutrition = _nutritionSummary(entries);
                    final bodyMass = _bodyMassSummary(profile);
                    final bmi = profile?.bmi ?? 0;
                    final isHigh = bmi >= 30;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(patient.displayName ?? patient.email),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nutrition),
                            const SizedBox(height: 4),
                            Text(
                              bodyMass,
                              style: TextStyle(color: isHigh ? Colors.red : null),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NutritionistClientScreen(
                                client: patient,
                                entries: entries,
                                profile: profile,
                                pregnancy: pregnancy,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }

  String _nutritionSummary(List<FoodEntry> entries) {
    if (entries.isEmpty) return 'Nutrition: no logs yet.';
    final now = DateTime.now();
    final recent = entries.where((e) => now.difference(e.date).inDays <= 7).toList();
    if (recent.isEmpty) return 'Nutrition: no logs in the last 7 days.';

    final totals = _totals(recent);
    final days = recent
        .map((e) => '${e.date.year}-${e.date.month}-${e.date.day}')
        .toSet()
        .length;
    final avgCalories = days == 0 ? 0 : (totals.calories / days).round();
    final avgProtein = days == 0 ? 0 : (totals.protein / days).round();
    return 'Nutrition (avg 7d): $avgCalories kcal, $avgProtein g protein.';
  }

  String _bodyMassSummary(Profile? profile) {
    if (profile == null) return 'Body mass: profile missing.';
    final bmi = profile.bmi;
    final status = bmi >= 30 ? 'High BMI' : 'BMI ${bmi.toStringAsFixed(1)}';
    return 'Body mass: ${profile.currentWeightKg.toStringAsFixed(1)} kg, '
        '${profile.heightCm.toStringAsFixed(0)} cm ($status).';
  }

  _Totals _totals(List<FoodEntry> entries) {
    var calories = 0;
    var protein = 0;
    for (final entry in entries) {
      calories += entry.calories;
      protein += entry.protein;
    }
    return _Totals(calories: calories, protein: protein);
  }
}

class _Totals {
  _Totals({required this.calories, required this.protein});

  final int calories;
  final int protein;
}
