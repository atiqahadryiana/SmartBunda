import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
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
    final strings = AppStrings.of(context);
    final role = resolvedUser.role;
    final navItems = _navItemsForUser(resolvedUser, strings);
    final pages = navItems.map((item) => item.page).toList();
    final tabs = navItems.map((item) => item.destination).toList();
    final safeIndex = _index.clamp(0, pages.length - 1);
    final name = resolvedUser.displayName ?? resolvedUser.email;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForRole(role, name, strings)),
        actions: _actionsForRole(context, role, strings),
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

  String _titleForRole(UserRole role, String name, AppStrings strings) {
    if (role == UserRole.patient) return strings.hi(name);
    return '${strings.roleLabel(role)}: $name';
  }

  List<Widget> _actionsForRole(
    BuildContext context,
    UserRole role,
    AppStrings strings,
  ) {
    final actions = <Widget>[
      IconButton(
        tooltip: strings.logoutTooltip,
        onPressed: () => _confirmLogout(context, strings),
        icon: const Icon(Icons.logout),
      ),
    ];
    if (role == UserRole.patient) {
      actions.insert(
        0,
        IconButton(
          tooltip: strings.educationTooltip,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EducationScreen()),
          ),
          icon: const Icon(Icons.menu_book_outlined),
        ),
      );
    }
    return actions;
  }

  Future<void> _confirmLogout(BuildContext context, AppStrings strings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.logoutTitle),
        content: Text(strings.logoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).maybePop(false),
            child: Text(strings.no),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).maybePop(true),
            child: Text(strings.yesLogOut),
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

  List<_NavItem> _navItemsForUser(AppUser user, AppStrings strings) {
    final permissions = user.effectivePermissions;
    final items = <_NavItem>[];
    switch (user.role) {
      case UserRole.patient:
        items.addAll([
          _NavItem(
            page: const SummaryScreen(),
            destination: NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              label: strings.navOverview,
            ),
            permission: AccessPermission.reporting,
          ),
          _NavItem(
            page: const FoodLoggingHubScreen(),
            destination: NavigationDestination(
              icon: const Icon(Icons.restaurant_menu),
              label: strings.navLog,
            ),
            permission: AccessPermission.foodLogging,
          ),
          _NavItem(
            page: AppointmentsScreen(role: UserRole.patient),
            destination: NavigationDestination(
              icon: const Icon(Icons.event_available),
              label: strings.navAppointments,
            ),
            permission: AccessPermission.appointments,
          ),
          _NavItem(
            page: const ReportsScreen(role: UserRole.patient),
            destination: NavigationDestination(
              icon: const Icon(Icons.assessment_outlined),
              label: strings.navReports,
            ),
            permission: AccessPermission.reporting,
          ),
          _NavItem(
            page: const ProfileScreen(),
            destination: NavigationDestination(
              icon: const Icon(Icons.person),
              label: strings.navProfile,
            ),
            permission: AccessPermission.patientProfiles,
          ),
        ]);
        break;
      case UserRole.doctor:
        items.addAll([
          _NavItem(
            page: const PatientProfilesScreen(showAppBar: false),
            destination: NavigationDestination(
              icon: const Icon(Icons.people_outline),
              label: strings.navPatients,
            ),
            permission: AccessPermission.patientProfiles,
          ),
          _NavItem(
            page: const NutritionistScreen(role: UserRole.doctor),
            destination: NavigationDestination(
              icon: const Icon(Icons.analytics_outlined),
              label: strings.navAnalysis,
            ),
            permission: AccessPermission.nutritionAnalysis,
          ),
          _NavItem(
            page: NutritionPlanManagementScreen(
              role: UserRole.doctor,
              showAppBar: false,
            ),
            destination: NavigationDestination(
              icon: const Icon(Icons.playlist_add_check),
              label: strings.navPlans,
            ),
            permission: AccessPermission.nutritionPlans,
          ),
          _NavItem(
            page: AppointmentsScreen(role: UserRole.doctor),
            destination: NavigationDestination(
              icon: const Icon(Icons.event_available),
              label: strings.navAppointments,
            ),
            permission: AccessPermission.appointments,
          ),
          _NavItem(
            page: const ReportsScreen(role: UserRole.doctor),
            destination: NavigationDestination(
              icon: const Icon(Icons.assessment_outlined),
              label: strings.navReports,
            ),
            permission: AccessPermission.reporting,
          ),
        ]);
        break;
      case UserRole.dietitian:
        items.addAll([
          _NavItem(
            page: const PatientProfilesScreen(showAppBar: false),
            destination: NavigationDestination(
              icon: const Icon(Icons.people_outline),
              label: strings.navPatients,
            ),
            permission: AccessPermission.patientProfiles,
          ),
          _NavItem(
            page: const NutritionistScreen(role: UserRole.dietitian),
            destination: NavigationDestination(
              icon: const Icon(Icons.analytics_outlined),
              label: strings.navAnalysis,
            ),
            permission: AccessPermission.nutritionAnalysis,
          ),
          _NavItem(
            page: NutritionPlanManagementScreen(
              role: UserRole.dietitian,
              showAppBar: false,
            ),
            destination: NavigationDestination(
              icon: const Icon(Icons.playlist_add_check),
              label: strings.navPlans,
            ),
            permission: AccessPermission.nutritionPlans,
          ),
          _NavItem(
            page: AppointmentsScreen(role: UserRole.dietitian),
            destination: NavigationDestination(
              icon: const Icon(Icons.event_available),
              label: strings.navAppointments,
            ),
            permission: AccessPermission.appointments,
          ),
          _NavItem(
            page: const ReportsScreen(role: UserRole.dietitian),
            destination: NavigationDestination(
              icon: const Icon(Icons.assessment_outlined),
              label: strings.navReports,
            ),
            permission: AccessPermission.reporting,
          ),
        ]);
        break;
      case UserRole.nurse:
        items.addAll([
          _NavItem(
            page: const NurseOverviewScreen(),
            destination: NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              label: strings.navOverview,
            ),
          ),
          _NavItem(
            page: const PatientProfilesScreen(showAppBar: false),
            destination: NavigationDestination(
              icon: const Icon(Icons.people_outline),
              label: strings.navPatients,
            ),
            permission: AccessPermission.patientProfiles,
          ),
          _NavItem(
            page: AppointmentsScreen(role: UserRole.nurse),
            destination: NavigationDestination(
              icon: const Icon(Icons.event_available),
              label: strings.navAppointments,
            ),
            permission: AccessPermission.appointments,
          ),
          _NavItem(
            page: const NurseMonitoringScreen(),
            destination: NavigationDestination(
              icon: const Icon(Icons.monitor_heart_outlined),
              label: strings.navMonitoring,
            ),
            permission: AccessPermission.monitoringAlerts,
          ),
          _NavItem(
            page: const ReportsScreen(role: UserRole.nurse),
            destination: NavigationDestination(
              icon: const Icon(Icons.analytics_outlined),
              label: strings.navReports,
            ),
            permission: AccessPermission.reporting,
          ),
        ]);
        break;
      case UserRole.admin:
        items.addAll([
          _NavItem(
            page: const AdminOverviewScreen(),
            destination: NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              label: strings.navOverview,
            ),
          ),
          _NavItem(
            page: const AdminScreen(),
            destination: NavigationDestination(
              icon: const Icon(Icons.admin_panel_settings),
              label: strings.navAdmin,
            ),
            permission: AccessPermission.userManagement,
          ),
          _NavItem(
            page: const SystemAdminScreen(
              showSettings: false,
              showData: true,
              showHealth: true,
              title: 'Data',
              subtitle: 'Backups, content, and system health.',
            ),
            destination: NavigationDestination(
              icon: const Icon(Icons.storage_outlined),
              label: strings.navData,
            ),
            permission: AccessPermission.systemAdministration,
          ),
          _NavItem(
            page: const ReportsScreen(role: UserRole.admin),
            destination: NavigationDestination(
              icon: const Icon(Icons.assessment_outlined),
              label: strings.navReport,
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
          destination: NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            label: strings.navModules,
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
