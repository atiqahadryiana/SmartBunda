import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../providers/app_providers.dart';
import 'admin_screen.dart';
import 'appointments_screen.dart';
import 'education_screen.dart';
import 'food_logging_hub_screen.dart';
import 'module_overview_screen.dart';
import 'monitoring_screen.dart';
import 'nutrition_plan_management_screen.dart';
import 'nutritionist_screen.dart';
import 'patient_profiles_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'system_admin_screen.dart';

class RoleModulesScreen extends ConsumerWidget {
  const RoleModulesScreen({
    super.key,
    required this.role,
    this.showAppBar = false,
  });

  final UserRole role;
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final modules = _modulesForRole(role);
    final visible = currentUser == null
        ? modules
        : modules
            .where(
              (module) =>
                  module.permission == null || currentUser.hasPermission(module.permission!),
            )
            .toList();
    final coreModules = visible.where((module) => module.sprintIndex != null).toList()
      ..sort((a, b) => a.sprintIndex!.compareTo(b.sprintIndex!));
    final supportModules = visible.where((module) => module.sprintIndex == null).toList();
    final recommended = coreModules.isNotEmpty
        ? coreModules.firstWhere(
            (module) => module.sprintIndex != 0,
            orElse: () => coreModules.first,
          )
        : (supportModules.isNotEmpty ? supportModules.first : null);
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text('${role.label} modules')) : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Getting started', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            _roleGuidance(role),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (recommended != null) ...[
            const SizedBox(height: 12),
            _StartHereCard(
              module: recommended,
              onTap: () => _openModule(context, recommended),
            ),
          ],
          if (coreModules.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Core sprints', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...coreModules.map(
              (module) => _ModuleCard(
                module: module,
                onTap: () => _openModule(context, module),
              ),
            ),
          ],
          if (supportModules.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('More tools', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...supportModules.map(
              (module) => _ModuleCard(
                module: module,
                onTap: () => _openModule(context, module),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_ModuleItem> _modulesForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return [
          _overviewModule(
            title: 'Authentication & Security',
            description: 'Login, password, and session controls.',
            icon: Icons.lock_outline,
            features: _authFeatures,
            sprintIndex: 0,
            permission: AccessPermission.authentication,
          ),
          _module(
            title: 'User management',
            description: 'Manage accounts, roles, and access.',
            icon: Icons.admin_panel_settings,
            builder: (_) => const AdminScreen(showAppBar: true),
            sprintIndex: 1,
            permission: AccessPermission.userManagement,
          ),
          _module(
            title: 'System administration',
            description: 'Settings, data, and system monitoring.',
            icon: Icons.settings_suggest,
            builder: (_) => const SystemAdminScreen(showAppBar: true),
            permission: AccessPermission.systemAdministration,
          ),
        ];
      case UserRole.patient:
        return [
          _overviewModule(
            title: 'Authentication & Security',
            description: 'Login, password, and session controls.',
            icon: Icons.lock_outline,
            features: _authFeatures,
            sprintIndex: 0,
            permission: AccessPermission.authentication,
          ),
          _module(
            title: 'Patient profile & pregnancy',
            description: 'Personal details, pregnancy progress.',
            icon: Icons.person_outline,
            builder: (_) => const ProfileScreen(showAppBar: true),
            sprintIndex: 2,
            permission: AccessPermission.patientProfiles,
          ),
          _module(
            title: 'Food logging & nutrition',
            description: 'Meals, hydration, and nutrition summaries.',
            icon: Icons.restaurant_menu,
            builder: (_) => const FoodLoggingHubScreen(showAppBar: true),
            sprintIndex: 3,
            permission: AccessPermission.foodLogging,
          ),
          _module(
            title: 'Monitoring & alert',
            description: 'Track trends and receive reminders.',
            icon: Icons.monitor_heart_outlined,
            builder: (_) =>
                MonitoringScreen(role: role, showAppBar: true),
            permission: AccessPermission.monitoringAlerts,
          ),
          _module(
            title: 'Appointment & reminder',
            description: 'Schedule visits and follow-ups.',
            icon: Icons.event_available,
            builder: (_) => AppointmentsScreen(role: role, showAppBar: true),
            permission: AccessPermission.appointments,
          ),
          _module(
            title: 'Reporting & analytics',
            description: 'Nutrition progress and compliance reports.',
            icon: Icons.assessment_outlined,
            builder: (_) => ReportsScreen(role: role, showAppBar: true),
            permission: AccessPermission.reporting,
          ),
          _module(
            title: 'Education & content',
            description: 'Guides, tips, and trimester materials.',
            icon: Icons.menu_book_outlined,
            builder: (_) => const EducationScreen(),
            permission: AccessPermission.education,
          ),
        ];
      case UserRole.doctor:
        return [
          _overviewModule(
            title: 'Authentication & Security',
            description: 'Login, password, and session controls.',
            icon: Icons.lock_outline,
            features: _authFeatures,
            sprintIndex: 0,
            permission: AccessPermission.authentication,
          ),
          _module(
            title: 'Patient profile & pregnancy',
            description: 'Review patient details and progress.',
            icon: Icons.people_outline,
            builder: (_) => const PatientProfilesScreen(),
            sprintIndex: 2,
            permission: AccessPermission.patientProfiles,
          ),
          _module(
            title: 'Nutrition analysis & recommendation',
            description: 'Analyze intake and identify gaps.',
            icon: Icons.analytics_outlined,
            builder: (_) => NutritionistScreen(role: role, showAppBar: true),
            sprintIndex: 4,
            permission: AccessPermission.nutritionAnalysis,
          ),
          _module(
            title: 'Nutrition plan management',
            description: 'Build and approve nutrition plans.',
            icon: Icons.playlist_add_check,
            builder: (_) => NutritionPlanManagementScreen(role: role, showAppBar: true),
            permission: AccessPermission.nutritionPlans,
          ),
          _module(
            title: 'Monitoring & alert',
            description: 'Track trends and critical risks.',
            icon: Icons.monitor_heart_outlined,
            builder: (_) =>
                MonitoringScreen(role: role, showAppBar: true),
            permission: AccessPermission.monitoringAlerts,
          ),
          _module(
            title: 'Appointment & reminder',
            description: 'Manage schedules and follow-ups.',
            icon: Icons.event_available,
            builder: (_) => AppointmentsScreen(role: role, showAppBar: true),
            permission: AccessPermission.appointments,
          ),
          _module(
            title: 'Reporting & analytics',
            description: 'Progress reports and compliance insights.',
            icon: Icons.assessment_outlined,
            builder: (_) => ReportsScreen(role: role, showAppBar: true),
            permission: AccessPermission.reporting,
          ),
        ];
      case UserRole.nurse:
        return [
          _overviewModule(
            title: 'Authentication & Security',
            description: 'Login, password, and session controls.',
            icon: Icons.lock_outline,
            features: _authFeatures,
            sprintIndex: 0,
            permission: AccessPermission.authentication,
          ),
          _module(
            title: 'Patient profile & pregnancy',
            description: 'Review patient details and progress.',
            icon: Icons.people_outline,
            builder: (_) => const PatientProfilesScreen(),
            sprintIndex: 2,
            permission: AccessPermission.patientProfiles,
          ),
          _module(
            title: 'Monitoring & alert',
            description: 'Track trends and critical risks.',
            icon: Icons.monitor_heart_outlined,
            builder: (_) =>
                MonitoringScreen(role: role, showAppBar: true),
            permission: AccessPermission.monitoringAlerts,
          ),
          _module(
            title: 'Appointment & reminder',
            description: 'Manage schedules and follow-ups.',
            icon: Icons.event_available,
            builder: (_) => AppointmentsScreen(role: role, showAppBar: true),
            permission: AccessPermission.appointments,
          ),
          _module(
            title: 'Reporting & analytics',
            description: 'Progress reports and compliance insights.',
            icon: Icons.assessment_outlined,
            builder: (_) => ReportsScreen(role: role, showAppBar: true),
            permission: AccessPermission.reporting,
          ),
        ];
      case UserRole.dietitian:
        return [
          _overviewModule(
            title: 'Authentication & Security',
            description: 'Login, password, and session controls.',
            icon: Icons.lock_outline,
            features: _authFeatures,
            sprintIndex: 0,
            permission: AccessPermission.authentication,
          ),
          _module(
            title: 'Patient profile & pregnancy',
            description: 'Review patient details and progress.',
            icon: Icons.people_outline,
            builder: (_) => const PatientProfilesScreen(),
            sprintIndex: 2,
            permission: AccessPermission.patientProfiles,
          ),
          _module(
            title: 'Nutrition analysis & recommendation',
            description: 'Analyze intake and identify gaps.',
            icon: Icons.analytics_outlined,
            builder: (_) => NutritionistScreen(role: role, showAppBar: true),
            sprintIndex: 4,
            permission: AccessPermission.nutritionAnalysis,
          ),
          _module(
            title: 'Nutrition plan management',
            description: 'Build and approve nutrition plans.',
            icon: Icons.playlist_add_check,
            builder: (_) => NutritionPlanManagementScreen(role: role, showAppBar: true),
            permission: AccessPermission.nutritionPlans,
          ),
          _module(
            title: 'Monitoring & alert',
            description: 'Track trends and critical risks.',
            icon: Icons.monitor_heart_outlined,
            builder: (_) =>
                MonitoringScreen(role: role, showAppBar: true),
            permission: AccessPermission.monitoringAlerts,
          ),
          _module(
            title: 'Appointment & reminder',
            description: 'Manage schedules and follow-ups.',
            icon: Icons.event_available,
            builder: (_) => AppointmentsScreen(role: role, showAppBar: true),
            permission: AccessPermission.appointments,
          ),
          _module(
            title: 'Reporting & analytics',
            description: 'Progress reports and compliance insights.',
            icon: Icons.assessment_outlined,
            builder: (_) => ReportsScreen(role: role, showAppBar: true),
            permission: AccessPermission.reporting,
          ),
        ];
    }
  }
}

String _roleGuidance(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'Approve staff, manage users, and keep the system running.';
    case UserRole.patient:
      return 'Complete your profile, then log meals to unlock recommendations.';
    case UserRole.doctor:
      return 'Review patient profiles, analyze intake, and update guidance.';
    case UserRole.nurse:
      return 'Review patient profiles and track monitoring alerts.';
    case UserRole.dietitian:
      return 'Review profiles, analyze intake, and manage nutrition plans.';
  }
}

void _openModule(BuildContext context, _ModuleItem module) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: module.builder),
  );
}

class _StartHereCard extends StatelessWidget {
  const _StartHereCard({required this.module, required this.onTap});

  final _ModuleItem module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: Color.alphaBlend(
        scheme.secondary.withValues(alpha: 20),
        scheme.surface,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.flag_outlined, color: scheme.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start here', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      module.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(module.description),
                    if (module.sprintIndex != null) ...[
                      const SizedBox(height: 6),
                      _SprintChip(index: module.sprintIndex!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.onTap});

  final _ModuleItem module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: scheme.primary.withValues(alpha: 20),
                child: Icon(module.icon, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            module.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (module.sprintIndex != null)
                          _SprintChip(index: module.sprintIndex!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SprintChip extends StatelessWidget {
  const _SprintChip({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withValues(alpha: 90)),
      ),
      child: Text(
        'Sprint $index',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.primary,
        ),
      ),
    );
  }
}

class _ModuleItem {
  const _ModuleItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
    this.sprintIndex,
    this.permission,
  });

  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
  final int? sprintIndex;
  final AccessPermission? permission;
}

_ModuleItem _module({
  required String title,
  required String description,
  required IconData icon,
  required WidgetBuilder builder,
  int? sprintIndex,
  AccessPermission? permission,
}) {
  return _ModuleItem(
    title: title,
    description: description,
    icon: icon,
    builder: builder,
    sprintIndex: sprintIndex,
    permission: permission,
  );
}

_ModuleItem _overviewModule({
  required String title,
  required String description,
  required IconData icon,
  required List<String> features,
  String? footer,
  int? sprintIndex,
  AccessPermission? permission,
}) {
  return _ModuleItem(
    title: title,
    description: description,
    icon: icon,
    builder: (_) => ModuleOverviewScreen(
      title: title,
      description: description,
      features: features,
      icon: icon,
      footer: footer,
    ),
    sprintIndex: sprintIndex,
    permission: permission,
  );
}

const _authFeatures = [
  'User login and logout',
  'Password reset and validation',
  'Session management',
  'Role-based access control',
];
