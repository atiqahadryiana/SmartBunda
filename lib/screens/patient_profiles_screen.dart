import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../models/app_user.dart';
import '../models/food_entry.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/screen_header.dart';
import 'nutritionist_client_screen.dart';

class PatientProfilesScreen extends ConsumerWidget {
  const PatientProfilesScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final usersAsync = ref.watch(usersProvider);
    final profilesAsync = ref.watch(allProfilesProvider);
    final pregnanciesAsync = ref.watch(allPregnanciesProvider);
    final entriesAsync = ref.watch(allEntriesProvider);

    return RequireSignIn(
      title: strings.t('Patient profiles'),
      showAppBar: showAppBar,
      message: strings.t('Please sign in to view patient profiles.'),
      child: Scaffold(
        appBar: showAppBar
            ? AppBar(title: Text(strings.t('Patient profiles')))
            : null,
        body: usersAsync.when(
          data: (users) {
            final profiles = profilesAsync.valueOrNull;
            final pregnancies = pregnanciesAsync.valueOrNull;
            final entries = entriesAsync.valueOrNull;
            if (profiles == null || entries == null || pregnancies == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final patients = users.where((u) => u.role == UserRole.patient).toList();
            if (patients.isEmpty) {
              return EmptyState(
                icon: Icons.people_outline,
                title: strings.t('No patients yet'),
                message: strings.t('Patients will appear here after registration.'),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ScreenHeader(
                  title: strings.t('Patient profiles'),
                  subtitle: strings.t('Open a patient to review their profile and logs.'),
                  icon: Icons.people_outline,
                ),
                const SizedBox(height: 16),
                ...patients.map((patient) {
                  final profile = profiles[patient.id];
                  final patientEntries = entries[patient.id] ?? const <FoodEntry>[];
                  return Card(
                    child: ListTile(
                      leading: _avatar(profile, patient),
                      title: Text(patient.displayName ?? patient.email),
                      subtitle: Text(_profileSummary(profile, pregnancies[patient.id], strings)),
                      trailing: Text(strings.logsCount(patientEntries.length)),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NutritionistClientScreen(
                              client: patient,
                              entries: patientEntries,
                              profile: profile,
                              pregnancy: pregnancies[patient.id],
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
    );
  }

  String _profileSummary(Profile? profile, Pregnancy? pregnancy, AppStrings strings) {
    final parts = <String>[];
    if (profile == null) {
      parts.add(strings.t('Profile missing'));
    }
    if (pregnancy == null) {
      parts.add(strings.t('Pregnancy not set'));
    } else {
      parts.add(
        strings.pregnancySummary(
          pregnancy.trimesterEnum,
          pregnancy.gestationalWeek,
        ),
      );
    }
    return parts.join(' | ');
  }

  Widget _avatar(Profile? profile, AppUser patient) {
    final name = patient.displayName ?? patient.email;
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join();
    final fallback = initials.isEmpty ? '?' : initials.toUpperCase();
    return CircleAvatar(
      backgroundColor: Colors.pink.shade100,
      child: Text(fallback, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

}
