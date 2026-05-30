import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/screens/admin_screen.dart';
import 'package:smartbunda/screens/appointments_screen.dart';
import 'package:smartbunda/screens/education_screen.dart';
import 'package:smartbunda/screens/food_catalog_screen.dart';
import 'package:smartbunda/screens/hydration_screen.dart';
import 'package:smartbunda/screens/log_screen.dart';
import 'package:smartbunda/screens/module_overview_screen.dart';
import 'package:smartbunda/screens/monitoring_screen.dart';
import 'package:smartbunda/screens/nutrition_plan_management_screen.dart';
import 'package:smartbunda/screens/nutritionist_screen.dart';
import 'package:smartbunda/screens/patient_profiles_screen.dart';
import 'package:smartbunda/screens/profile_screen.dart';
import 'package:smartbunda/screens/reports_screen.dart';
import 'package:smartbunda/screens/summary_screen.dart';
import 'package:smartbunda/screens/system_admin_screen.dart';

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
    final resolvedRole = currentUser?.role ?? role;
    final modules = _modulesForRole(resolvedRole);
    final visible = currentUser == null
        ? modules
        : modules
            .where(
              (module) =>
                  module.permission == null ||
                  currentUser.hasPermission(module.permission!),
            )
            .toList();
    final coreModules = visible
        .where((module) => module.sprintIndex != null)
        .toList()
      ..sort((a, b) => a.sprintIndex!.compareTo(b.sprintIndex!));
    final supportModules =
        visible.where((module) => module.sprintIndex == null).toList();
    final recommended = coreModules.isNotEmpty
        ? coreModules.firstWhere(
            (module) => module.sprintIndex != 0,
            orElse: () => coreModules.first,
          )
        : (supportModules.isNotEmpty ? supportModules.first : null);
    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: Text('${resolvedRole.label} modules'))
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ModulesHeader(role: resolvedRole),
          if (recommended != null) ...[
            const SizedBox(height: 16),
            _StartHereCard(
              module: recommended,
              onTap: () => _openModule(context, recommended),
            ),
          ],
          if (coreModules.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Core sprints',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ModuleGrid(
              modules: coreModules,
              onOpen: (module) => _openModule(context, module),
            ),
          ],
          if (supportModules.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('More tools', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ModuleGrid(
              modules: supportModules,
              onOpen: (module) => _openModule(context, module),
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
            title: 'Food database',
            description: 'Maintain food items and nutrition values.',
            icon: Icons.restaurant_menu_outlined,
            builder: (_) => const FoodCatalogScreen(showAppBar: true),
            permission: AccessPermission.foodDatabase,
          ),
          _module(
            title: 'Appointments',
            description: 'Review and schedule clinic visits.',
            icon: Icons.event_available,
            builder: (_) => AppointmentsScreen(role: role, showAppBar: true),
            permission: AccessPermission.appointments,
          ),
          _module(
            title: 'Reporting & analytics',
            description: 'System reports and usage insights.',
            icon: Icons.assessment_outlined,
            builder: (_) => ReportsScreen(role: role, showAppBar: true),
            permission: AccessPermission.reporting,
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
            title: 'Daily summary',
            description: 'Review daily nutrition progress and recommendations.',
            icon: Icons.dashboard_outlined,
            builder: (_) => const SummaryScreen(showAppBar: true),
            sprintIndex: 1,
            permission: AccessPermission.reporting,
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
            title: 'Meal log',
            description: 'Record meals and nutrition intake.',
            icon: Icons.restaurant_menu,
            builder: (_) => const LogScreen(),
            sprintIndex: 3,
            permission: AccessPermission.foodLogging,
          ),
          _module(
            title: 'Hydration log',
            description: 'Track water intake and daily hydration progress.',
            icon: Icons.water_drop_outlined,
            builder: (_) => const HydrationScreen(),
            sprintIndex: 3,
            permission: AccessPermission.foodLogging,
          ),
          _module(
            title: 'Monitoring & alert',
            description: 'Track trends and receive reminders.',
            icon: Icons.monitor_heart_outlined,
            builder: (_) => MonitoringScreen(role: role, showAppBar: true),
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
            builder: (_) =>
                NutritionPlanManagementScreen(role: role, showAppBar: true),
            permission: AccessPermission.nutritionPlans,
          ),
          _module(
            title: 'Monitoring & alert',
            description: 'Track trends and critical risks.',
            icon: Icons.monitor_heart_outlined,
            builder: (_) => MonitoringScreen(role: role, showAppBar: true),
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
            builder: (_) => MonitoringScreen(role: role, showAppBar: true),
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
            builder: (_) =>
                NutritionPlanManagementScreen(role: role, showAppBar: true),
            permission: AccessPermission.nutritionPlans,
          ),
          _module(
            title: 'Monitoring & alert',
            description: 'Track trends and critical risks.',
            icon: Icons.monitor_heart_outlined,
            builder: (_) => MonitoringScreen(role: role, showAppBar: true),
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

class _ModulesHeader extends StatelessWidget {
  const _ModulesHeader({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: 14),
          scheme.surface,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.grid_view_outlined, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${role.label} modules',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _roleGuidance(role),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({
    required this.modules,
    required this.onOpen,
  });

  final List<_ModuleItem> modules;
  final ValueChanged<_ModuleItem> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 620
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 3.1 : 1.55,
          ),
          itemBuilder: (context, index) {
            final module = modules[index];
            return _ModuleCard(
              module: module,
              onTap: () => onOpen(module),
            );
          },
        );
      },
    );
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
        borderRadius: BorderRadius.circular(8),
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
                    Text('Start here',
                        style: Theme.of(context).textTheme.titleSmall),
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
        borderRadius: BorderRadius.circular(8),
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
