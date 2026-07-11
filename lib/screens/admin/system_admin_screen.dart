import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/system_settings.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/theme/app_components.dart';
import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/widgets/permission_gate.dart';
import 'package:smartbunda/widgets/require_sign_in.dart';
import 'package:smartbunda/widgets/screen_header.dart';
import 'package:smartbunda/screens/admin/activity_log_screen.dart';
import 'package:smartbunda/screens/admin/content_management_screen.dart';
import 'package:smartbunda/screens/admin/nutrition_guideline_admin_screen.dart';
import 'package:smartbunda/screens/food/food_catalog_screen.dart';

class SystemAdminScreen extends ConsumerWidget {
  const SystemAdminScreen({
    super.key,
    this.showAppBar = false,
    this.showSettings = true,
    this.showData = true,
    this.showHealth = true,
    this.title,
    this.subtitle,
  });

  final bool showAppBar;
  final bool showSettings;
  final bool showData;
  final bool showHealth;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(systemSettingsProvider);
    final backupsAsync = ref.watch(backupsProvider);
    final usersAsync = ref.watch(usersProvider);
    final entriesAsync = ref.watch(allEntriesProvider);
    final appointmentsAsync = ref.watch(allAppointmentsProvider);
    final plansAsync = ref.watch(allPlansProvider);
    final alertsAsync = ref.watch(allAlertsProvider);

    final headerTitle = title ?? 'System administration';
    final headerSubtitle =
        subtitle ?? 'Manage settings, backups, and system health.';
    return PermissionGate(
      permission: AccessPermission.systemAdministration,
      title: headerTitle,
      child: RequireSignIn(
      title: headerTitle,
      showAppBar: showAppBar,
      message: 'Please sign in to manage system settings.',
      child: Scaffold(
        appBar: showAppBar ? AppBar(title: Text(headerTitle)) : null,
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ScreenHeader(
              title: headerTitle,
              subtitle: headerSubtitle,
              icon: Icons.settings_suggest,
            ),
            if (showSettings) ...[
              const SizedBox(height: 16),
              Text('Settings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              settingsAsync.when(
                data: (settings) => _SettingsCard(settings: settings),
                loading: () => const _SettingsCardSkeleton(),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
            if (showData) ...[
              const SizedBox(height: 16),
              Text('Data & backup', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _createBackup(context, ref),
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('Create backup'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FoodCatalogScreen()),
                    ),
                    child: const Text('Manage food database'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ContentManagementScreen()),
                    ),
                    child: const Text('Manage content'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              const NutritionGuidelineAdminScreen()),
                    ),
                    child: const Text('Nutrition guidelines'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ActivityLogScreen(showAppBar: true)),
                    ),
                    child: const Text('View activity logs'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              backupsAsync.when(
                data: (backups) {
                  if (backups.isEmpty) {
                    return const Text('No backups yet.');
                  }
                  return Column(
                    children: backups
                        .map(
                          (backup) => Card(
                            child: ListTile(
                              title: Text(backup.label),
                              subtitle: Text(
                                '${backup.createdAt.month}/${backup.createdAt.day} ${backup.createdAt.hour.toString().padLeft(2, '0')}:${backup.createdAt.minute.toString().padLeft(2, '0')}',
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () => ref
                                        .read(systemAdminRepositoryProvider)
                                        .restoreBackup(backup),
                                    child: const Text('Restore'),
                                  ),
                                  TextButton(
                                    onPressed: () => ref
                                        .read(systemAdminRepositoryProvider)
                                        .deleteBackup(backup.id),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const _BackupListSkeleton(),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
            if (showHealth) ...[
              const SizedBox(height: 16),
              Text('System health', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              usersAsync.when(
                data: (users) {
                  final entryCount = entriesAsync.valueOrNull?.values.fold<int>(
                        0,
                        (sum, list) => sum + list.length,
                      ) ??
                      0;
                  final appointmentCount = appointmentsAsync.valueOrNull?.length ?? 0;
                  final planCount = plansAsync.valueOrNull?.length ?? 0;
                  final alertCount = alertsAsync.valueOrNull?.length ?? 0;
                  return Column(
                    children: [
                      _HealthTile(label: 'Users', value: users.length),
                      _HealthTile(label: 'Food entries', value: entryCount),
                      _HealthTile(label: 'Appointments', value: appointmentCount),
                      _HealthTile(label: 'Nutrition plans', value: planCount),
                      _HealthTile(label: 'Active alerts', value: alertCount),
                    ],
                  );
                },
                loading: () => const _SystemHealthSkeleton(),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create backup'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Label (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(systemAdminRepositoryProvider)
                  .createBackup(label: controller.text.trim().isEmpty ? null : controller.text);
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard({required this.settings});

  final SystemSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('App name'),
            subtitle: Text(settings.appName),
          ),
          ListTile(
            title: const Text('Country'),
            subtitle: Text(settings.country),
          ),
          SwitchListTile(
            title: const Text('Enable meal reminders'),
            value: settings.mealLoggingEnabled,
            onChanged: (value) => _update(
              ref,
              settings.copyWith(mealLoggingEnabled: value),
            ),
          ),
          ListTile(
            title: const Text('Reminder hour'),
            subtitle: Text('${settings.defaultReminderHour}:00'),
            trailing: TextButton(
              onPressed: () => _editReminderHour(context, ref, settings),
              child: const Text('Edit'),
            ),
          ),
          ListTile(
            title: const Text('Alert thresholds'),
            subtitle: Text(
              'Calories ${settings.caloriesMin}-${settings.caloriesMax} | Protein ${settings.proteinGMin}g | Iron ${settings.ironMgMin}mg | Folate ${settings.folateMcgMin}mcg',
            ),
            trailing: TextButton(
              onPressed: () => _editThresholds(context, ref, settings),
              child: const Text('Edit'),
            ),
          ),
        ],
      ),
    );
  }

  void _update(WidgetRef ref, SystemSettings updated) {
    ref.read(systemAdminRepositoryProvider).updateSettings(updated);
  }

  Future<void> _editReminderHour(
    BuildContext context,
    WidgetRef ref,
    SystemSettings settings,
  ) async {
    final ctrl = TextEditingController(text: settings.defaultReminderHour.toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminder hour'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Hour (0-23)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final hour = int.tryParse(ctrl.text) ?? settings.defaultReminderHour;
              _update(ref, settings.copyWith(defaultReminderHour: hour.clamp(0, 23)));
              Navigator.of(context).maybePop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editThresholds(
    BuildContext context,
    WidgetRef ref,
    SystemSettings settings,
  ) async {
    final caloriesMinCtrl = TextEditingController(text: settings.caloriesMin.toString());
    final caloriesMaxCtrl = TextEditingController(text: settings.caloriesMax.toString());
    final proteinCtrl = TextEditingController(text: settings.proteinGMin.toString());
    final ironCtrl = TextEditingController(text: settings.ironMgMin.toString());
    final folateCtrl = TextEditingController(text: settings.folateMcgMin.toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert thresholds'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: caloriesMinCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories min'),
              ),
              TextField(
                controller: caloriesMaxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories max'),
              ),
              TextField(
                controller: proteinCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Protein min (g)'),
              ),
              TextField(
                controller: ironCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Iron min (mg)'),
              ),
              TextField(
                controller: folateCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Folate min (mcg)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _update(
                ref,
                settings.copyWith(
                  caloriesMin: int.tryParse(caloriesMinCtrl.text) ?? settings.caloriesMin,
                  caloriesMax: int.tryParse(caloriesMaxCtrl.text) ?? settings.caloriesMax,
                  proteinGMin: int.tryParse(proteinCtrl.text) ?? settings.proteinGMin,
                  ironMgMin: int.tryParse(ironCtrl.text) ?? settings.ironMgMin,
                  folateMcgMin: int.tryParse(folateCtrl.text) ?? settings.folateMcgMin,
                ),
              );
              Navigator.of(context).maybePop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _HealthTile extends StatelessWidget {
  const _HealthTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text('$value'),
      ),
    );
  }
}

class _SettingsCardSkeleton extends StatelessWidget {
  const _SettingsCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SbSkeletonLoader(
              height: 24,
              width: 120,
            ),
            SizedBox(height: 16),
            SbSkeletonLoader(
              height: 16,
              width: 200,
            ),
            SizedBox(height: 8),
            SbSkeletonLoader(
              height: 16,
              width: 150,
            ),
            SizedBox(height: 8),
            SbSkeletonLoader(
              height: 16,
              width: 180,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupListSkeleton extends StatelessWidget {
  const _BackupListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _BackupItemSkeleton(),
        _BackupItemSkeleton(),
        _BackupItemSkeleton(),
      ],
    );
  }
}

class _BackupItemSkeleton extends StatelessWidget {
  const _BackupItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        title: SbSkeletonLoader(
          height: 16,
          width: 120,
        ),
        subtitle: SbSkeletonLoader(
          height: 12,
          width: 100,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SbSkeletonLoader(
              width: 60,
              height: 36,
            ),
            SizedBox(width: 8),
            SbSkeletonLoader(
              width: 60,
              height: 36,
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemHealthSkeleton extends StatelessWidget {
  const _SystemHealthSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _HealthTileSkeleton(),
        _HealthTileSkeleton(),
        _HealthTileSkeleton(),
        _HealthTileSkeleton(),
        _HealthTileSkeleton(),
      ],
    );
  }
}

class _HealthTileSkeleton extends StatelessWidget {
  const _HealthTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        title: SbSkeletonLoader(
          height: 16,
          width: 80,
        ),
        trailing: SbSkeletonLoader(
          height: 16,
          width: 40,
        ),
      ),
    );
  }
}


