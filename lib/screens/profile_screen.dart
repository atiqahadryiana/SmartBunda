import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../models/app_user.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/screen_header.dart';
import 'edit_profile_screen.dart';
import 'professional_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final strings = AppStrings.of(context);
    final child = user == null
        ? const SizedBox.shrink()
        : user.role != UserRole.patient
            ? ProfessionalProfileScreen(showAppBar: showAppBar)
            : _profileView(context, ref);

    return RequireSignIn(
      title: strings.profileTitle,
      showAppBar: showAppBar,
      message: strings.signInToViewProfile,
      child: child,
    );
  }

  Widget _profileView(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final pregnancyAsync = ref.watch(pregnancyProvider);
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(strings.profileTitle)) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: profileAsync.when(
          data: (profile) {
            final pregnancy = pregnancyAsync.valueOrNull;
            return ListView(
              children: [
                ScreenHeader(
                  title: strings.profileTitle,
                  subtitle: strings.profileSubtitle,
                  icon: Icons.person_outline,
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: strings.t('Settings'),
                        onPressed: () => _openSettings(context),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                      FilledButton.icon(
                        onPressed: () => _openEdit(context),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(strings.edit),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (profile == null) ...[
                  EmptyState(
                    icon: Icons.person_outline,
                    title: strings.noProfileYet,
                    message: strings.noProfileMessage,
                    action: FilledButton.icon(
                      onPressed: () => _openEdit(context),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(strings.editProfile),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(onTap: () => _openSettings(context)),
                ] else ...[
                  _OutcomesCard(profile: profile, pregnancy: pregnancy),
                  const SizedBox(height: 12),
                  _DetailsCard(profile: profile),
                  const SizedBox(height: 12),
                  _MedicalCard(profile: profile),
                  const SizedBox(height: 12),
                  _PregnancyCard(
                    pregnancy: pregnancy,
                    isLoading: pregnancyAsync.isLoading,
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(onTap: () => _openSettings(context)),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(showAppBar: true),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }
}

/// Card-style entry point into the [SettingsScreen].
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.settings_outlined, color: AppTheme.darkPink),
        title: Text(strings.t('Settings')),
        subtitle: Text(
          strings.t('Language, appearance, notifications, and more.'),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _OutcomesCard extends StatelessWidget {
  const _OutcomesCard({required this.profile, required this.pregnancy});

  final Profile profile;
  final Pregnancy? pregnancy;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final bmi = _bmi(profile);
    final trimester =
        pregnancy == null ? '--' : _trimesterLabel(strings, pregnancy!);
    final week =
        pregnancy == null ? '--' : pregnancy!.gestationalWeek.toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.outcomes,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _OutcomeTile(
                        label: strings.bmiLabel, value: bmi ?? '--')),
                const SizedBox(width: 8),
                Expanded(
                    child: _OutcomeTile(
                        label: strings.trimester, value: trimester)),
                const SizedBox(width: 8),
                Expanded(child: _OutcomeTile(label: strings.week, value: week)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _bmi(Profile profile) {
    if (profile.heightCm <= 0 || profile.currentWeightKg <= 0) return null;
    final heightM = profile.heightCm / 100;
    final bmi = profile.currentWeightKg / (heightM * heightM);
    return bmi.isNaN ? null : bmi.toStringAsFixed(1);
  }
}

class _OutcomeTile extends StatelessWidget {
  const _OutcomeTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.details,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _InfoRow(label: strings.dateOfBirth, value: _label(profile.dob)),
            _InfoRow(
              label: strings.height,
              value: '${profile.heightCm.toStringAsFixed(1)} cm',
            ),
            _InfoRow(
              label: strings.weight,
              value: '${profile.currentWeightKg.toStringAsFixed(1)} kg',
            ),
            _InfoRow(
              label: strings.hemoglobin,
              value: _measurement(profile.hemoglobinGdl, 'g/dL'),
            ),
            _InfoRow(
              label: strings.abdominalCircumference,
              value: _measurement(profile.abdominalCircumferenceCm, 'cm'),
            ),
            _InfoRow(
              label: strings.bloodType,
              value: _label(profile.bloodType),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalCard extends StatelessWidget {
  const _MedicalCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final conditions = _conditions(profile, strings);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.medicalConditions,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(conditions),
          ],
        ),
      ),
    );
  }

  String _conditions(Profile profile, AppStrings strings) {
    final labels = <String>[];
    for (final condition in profile.medicalConditions) {
      switch (condition) {
        case MedicalCondition.anemia:
          labels.add(strings.anemiaLabel);
          break;
        case MedicalCondition.gestationalDiabetes:
          labels.add(strings.gdmLabel);
          break;
      }
    }
    return labels.isEmpty ? strings.noneReported : labels.join(', ');
  }
}

class _PregnancyCard extends StatelessWidget {
  const _PregnancyCard({required this.pregnancy, required this.isLoading});

  final Pregnancy? pregnancy;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.pregnancy,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (pregnancy == null)
              Text(strings.pregnancyNotSet)
            else ...[
              _InfoRow(
                label: strings.gestationalWeek,
                value: pregnancy!.gestationalWeek.toString(),
              ),
              _InfoRow(
                label: strings.trimester,
                value: _trimesterLabel(strings, pregnancy!),
              ),
              _InfoRow(label: strings.edd, value: _label(pregnancy!.edd)),
              _InfoRow(
                  label: strings.riskLevel,
                  value: _label(pregnancy!.riskLevel)),
            ],
          ],
        ),
      ),
    );
  }
}

String _trimesterLabel(AppStrings strings, Pregnancy pregnancy) {
  final label = strings.trimesterLabel(pregnancy.trimesterEnum);
  return strings.isMalay ? 'Trimester $label' : '$label trimester';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _label(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '--' : trimmed;
}

String _measurement(double? value, String unit) {
  if (value == null || value <= 0) return '--';
  return '${value.toStringAsFixed(1)} $unit';
}
