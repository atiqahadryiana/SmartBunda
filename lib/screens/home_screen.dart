import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../widgets/lazy_indexed_stack.dart';
import 'admin_screen.dart';
import 'admin_overview_screen.dart';
import 'appointments_screen.dart';
import 'education_screen.dart';
import 'food_logging_hub_screen.dart';
import 'login_screen.dart';
import 'nurse_monitoring_screen.dart';
import 'nurse_overview_screen.dart';
import 'nutritionist_screen.dart';
import 'nutrition_plan_management_screen.dart';
import 'patient_profiles_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'role_modules_screen.dart';
import 'summary_screen.dart';
import 'system_admin_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final resolvedUser = ref.watch(currentUserProvider);
    if (resolvedUser == null) {
      return const LoginScreen();
    }
    final role = resolvedUser.role;
    final navItems = _navItemsForUser(resolvedUser);
    final pages = navItems.map((item) => item.page).toList();
    final tabs = navItems.map((item) => item.destination).toList();
    final safeIndex = _index.clamp(0, pages.length - 1);
    final name = resolvedUser.displayName ?? resolvedUser.email;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForRole(role, name)),
        actions: _actionsForRole(context, role),
      ),
      body: LazyIndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: tabs,
      ),
      // Admin tab accessible only for allowed roles.
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _titleForRole(UserRole role, String name) {
    if (role == UserRole.patient) return 'Hi, $name';
    return '${role.label}: $name';
  }

  List<Widget> _actionsForRole(BuildContext context, UserRole role) {
    final actions = <Widget>[
      IconButton(
        tooltip: 'Logout',
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout),
      ),
    ];
    if (role == UserRole.patient) {
      actions.insert(
        0,
        IconButton(
          tooltip: 'Education',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EducationScreen()),
          ),
          icon: const Icon(Icons.menu_book_outlined),
        ),
      );
    }
    return actions;
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).maybePop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).maybePop(true),
            child: const Text('Yes, log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
  }

  List<_NavItem> _navItemsForUser(AppUser user) {
    final permissions = user.effectivePermissions;
    final items = <_NavItem>[];
    switch (user.role) {
      case UserRole.patient:
        items.addAll([
          const _NavItem(
            page: SummaryScreen(),
            destination: NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Overview',
            ),
            permission: AccessPermission.reporting,
          ),
          const _NavItem(
            page: FoodLoggingHubScreen(),
            destination: NavigationDestination(
              icon: Icon(Icons.restaurant_menu),
              label: 'Log',
            ),
            permission: AccessPermission.foodLogging,
          ),
          _NavItem(
            page: AppointmentsScreen(role: UserRole.patient),
            destination: NavigationDestination(
              icon: Icon(Icons.event_available),
              label: 'Appointments',
            ),
            permission: AccessPermission.appointments,
          ),
          const _NavItem(
            page: ReportsScreen(role: UserRole.patient),
            destination: NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              label: 'Reports',
            ),
            permission: AccessPermission.reporting,
          ),
          const _NavItem(
            page: ProfileScreen(),
            destination: NavigationDestination(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            permission: AccessPermission.patientProfiles,
          ),
        ]);
        break;
      case UserRole.doctor:
        items.addAll([
          const _NavItem(
            page: PatientProfilesScreen(showAppBar: false),
            destination: NavigationDestination(
              icon: Icon(Icons.people_outline),
              label: 'Patients',
            ),
            permission: AccessPermission.patientProfiles,
          ),
          const _NavItem(
            page: NutritionistScreen(role: UserRole.doctor),
            destination: NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              label: 'Analysis',
            ),
            permission: AccessPermission.nutritionAnalysis,
          ),
          _NavItem(
            page: NutritionPlanManagementScreen(
              role: UserRole.doctor,
              showAppBar: false,
            ),
            destination: const NavigationDestination(
              icon: Icon(Icons.playlist_add_check),
              label: 'Plans',
            ),
            permission: AccessPermission.nutritionPlans,
          ),
          _NavItem(
            page: AppointmentsScreen(role: UserRole.doctor),
            destination: const NavigationDestination(
              icon: Icon(Icons.event_available),
              label: 'Appointments',
            ),
            permission: AccessPermission.appointments,
          ),
          const _NavItem(
            page: ReportsScreen(role: UserRole.doctor),
            destination: NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              label: 'Reports',
            ),
            permission: AccessPermission.reporting,
          ),
        ]);
        break;
      case UserRole.dietitian:
        items.addAll([
          const _NavItem(
            page: PatientProfilesScreen(showAppBar: false),
            destination: NavigationDestination(
              icon: Icon(Icons.people_outline),
              label: 'Patients',
            ),
            permission: AccessPermission.patientProfiles,
          ),
          const _NavItem(
            page: NutritionistScreen(role: UserRole.dietitian),
            destination: NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              label: 'Analysis',
            ),
            permission: AccessPermission.nutritionAnalysis,
          ),
          _NavItem(
            page: NutritionPlanManagementScreen(
              role: UserRole.dietitian,
              showAppBar: false,
            ),
            destination: const NavigationDestination(
              icon: Icon(Icons.playlist_add_check),
              label: 'Plans',
            ),
            permission: AccessPermission.nutritionPlans,
          ),
          _NavItem(
            page: AppointmentsScreen(role: UserRole.dietitian),
            destination: const NavigationDestination(
              icon: Icon(Icons.event_available),
              label: 'Appointments',
            ),
            permission: AccessPermission.appointments,
          ),
          const _NavItem(
            page: ReportsScreen(role: UserRole.dietitian),
            destination: NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              label: 'Reports',
            ),
            permission: AccessPermission.reporting,
          ),
        ]);
        break;
      case UserRole.nurse:
        items.addAll([
          const _NavItem(
            page: NurseOverviewScreen(),
            destination: NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Overview',
            ),
          ),
          const _NavItem(
            page: PatientProfilesScreen(showAppBar: false),
            destination: NavigationDestination(
              icon: Icon(Icons.people_outline),
              label: 'Patients',
            ),
            permission: AccessPermission.patientProfiles,
          ),
          _NavItem(
            page: AppointmentsScreen(role: UserRole.nurse),
            destination: NavigationDestination(
              icon: Icon(Icons.event_available),
              label: 'Appointments',
            ),
            permission: AccessPermission.appointments,
          ),
          const _NavItem(
            page: NurseMonitoringScreen(),
            destination: NavigationDestination(
              icon: Icon(Icons.monitor_heart_outlined),
              label: 'Monitoring',
            ),
            permission: AccessPermission.monitoringAlerts,
          ),
          const _NavItem(
            page: ReportsScreen(role: UserRole.nurse),
            destination: NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              label: 'Reports',
            ),
            permission: AccessPermission.reporting,
          ),
        ]);
        break;
      case UserRole.admin:
        items.addAll([
          const _NavItem(
            page: AdminOverviewScreen(),
            destination: NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Overview',
            ),
          ),
          const _NavItem(
            page: AdminScreen(),
            destination: NavigationDestination(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
            permission: AccessPermission.userManagement,
          ),
          const _NavItem(
            page: SystemAdminScreen(
              showSettings: false,
              showData: true,
              showHealth: true,
              title: 'Data',
              subtitle: 'Backups, content, and system health.',
            ),
            destination: NavigationDestination(
              icon: Icon(Icons.storage_outlined),
              label: 'Data',
            ),
            permission: AccessPermission.systemAdministration,
          ),
          const _NavItem(
            page: ReportsScreen(role: UserRole.admin),
            destination: NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              label: 'Report',
            ),
            permission: AccessPermission.reporting,
          ),
        ]);
        break;
    }
    final filtered = items
        .where(
          (item) => item.permission == null || permissions.contains(item.permission),
        )
        .toList();
    if (filtered.isEmpty) {
      return [
        _NavItem(
          page: RoleModulesScreen(role: user.role),
          destination: const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Modules',
          ),
        ),
      ];
    }
    return filtered;
  }
}

class _NavItem {
  const _NavItem({
    required this.page,
    required this.destination,
    this.permission,
  });

  final Widget page;
  final NavigationDestination destination;
  final AccessPermission? permission;
}
