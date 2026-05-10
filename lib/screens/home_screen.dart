import 'dart:ui';

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
import 'health_record_screen.dart';
import 'login_screen.dart';
import 'nurse_monitoring_screen.dart';
import 'nurse_overview_screen.dart';
import 'nutritionist_screen.dart';
import 'nutrition_plan_management_screen.dart';
import 'patient_dashboard_screen.dart';
import 'patient_profiles_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'role_modules_screen.dart';
import 'staff_module_screen.dart';
import 'system_admin_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialUser});

  final AppUser? initialUser;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final resolvedUser = ref.watch(currentUserProvider) ?? widget.initialUser;
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
      appBar: role == UserRole.patient
          ? null
          : AppBar(
              title: Text(_titleForRole(role, name, strings)),
              actions: _actionsForRole(context, role, strings),
            ),
      extendBody: true,
      body: LazyIndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: _FloatingBottomNavigationBar(
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
    if (user.role == UserRole.patient) {
      final patientItems = <_NavItem>[
        _NavItem(
          page: PatientDashboardScreen(
            onOpenTab: (value) => setState(() => _index = value),
            onOpenEducation: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EducationScreen()),
            ),
            onLogout: () => _confirmLogout(context, strings),
          ),
          destination: const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          permission: AccessPermission.reporting,
        ),
        const _NavItem(
          page: HealthRecordScreen(),
          destination: NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            selectedIcon: Icon(Icons.folder_copy),
            label: 'Health Record',
          ),
          permission: AccessPermission.patientProfiles,
        ),
        const _NavItem(
          page: FoodLoggingHubScreen(),
          destination: NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Food & Water Log',
          ),
          permission: AccessPermission.foodLogging,
        ),
        const _NavItem(
          page: AppointmentsScreen(role: UserRole.patient),
          destination: NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Appointment',
          ),
          permission: AccessPermission.appointments,
        ),
        const _NavItem(
          page: ProfileScreen(),
          destination: NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          permission: AccessPermission.patientProfiles,
        ),
      ];
      return patientItems
          .where(
            (item) =>
                item.permission == null ||
                permissions.contains(item.permission),
          )
          .toList();
    }

    if (_isHealthcareStaff(user.role)) {
      final staffItems = <_NavItem>[
        _NavItem(
          page: StaffDashboardScreen(
            role: user.role,
            onOpenPatients: () => setState(() => _index = 1),
            onOpenRecords: () => setState(() => _index = 2),
          ),
          destination: const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          permission: AccessPermission.appointments,
        ),
        _NavItem(
          page: StaffTodayPatientsScreen(role: user.role),
          destination: const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Today\'s Patients',
          ),
          permission: AccessPermission.patientProfiles,
        ),
        _NavItem(
          page: StaffHealthRecordsScreen(role: user.role),
          destination: const NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            selectedIcon: Icon(Icons.folder_copy),
            label: 'Health Records',
          ),
          permission: AccessPermission.patientProfiles,
        ),
        _NavItem(
          page: AppointmentsScreen(role: user.role),
          destination: const NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Appointments',
          ),
          permission: AccessPermission.appointments,
        ),
        const _NavItem(
          page: ProfileScreen(),
          destination: NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          permission: AccessPermission.patientProfiles,
        ),
      ];
      return staffItems
          .where(
            (item) =>
                item.permission == null ||
                permissions.contains(item.permission),
          )
          .toList();
    }

    final items = <_NavItem>[
      _NavItem(
        page: RoleModulesScreen(role: user.role),
        destination: NavigationDestination(
          icon: const Icon(Icons.grid_view_outlined),
          label: strings.navModules,
        ),
      ),
    ];
    switch (user.role) {
      case UserRole.patient:
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
            page: const NutritionPlanManagementScreen(
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
            page: const NutritionPlanManagementScreen(
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
          (item) =>
              item.permission == null || permissions.contains(item.permission),
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

bool _isHealthcareStaff(UserRole role) {
  return role == UserRole.doctor ||
      role == UserRole.dietitian ||
      role == UserRole.nurse;
}

class _FloatingBottomNavigationBar extends StatelessWidget {
  const _FloatingBottomNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 18 : 10),
      scheme.surface.withValues(alpha: isDark ? 220 : 225),
    );

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: isDark ? 55 : 28),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: scheme.primary.withValues(alpha: isDark ? 28 : 18),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 82,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 150),
                ),
              ),
              child: Row(
                children: [
                  for (var index = 0; index < destinations.length; index++)
                    Expanded(
                      child: _FloatingNavItem(
                        destination: destinations[index],
                        selected: selectedIndex == index,
                        onTap: () => onDestinationSelected(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  const _FloatingNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeIcon = destination.selectedIcon ?? destination.icon;
    final icon = selected ? activeIcon : destination.icon;

    return Tooltip(
      message: destination.label,
      child: Semantics(
        selected: selected,
        button: true,
        label: destination.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.symmetric(
              horizontal: selected ? 2 : 0,
              vertical: selected ? 0 : 3,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        scheme.primary.withValues(alpha: 42),
                        scheme.secondary.withValues(alpha: 32),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(22),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 34),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedScale(
              scale: selected ? 1.0 : 0.94,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme.merge(
                    data: IconThemeData(
                      size: selected ? 23 : 22,
                      color:
                          selected ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    child: icon,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 10.5,
                          height: 1.0,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
