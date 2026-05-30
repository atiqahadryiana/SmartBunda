import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/widgets/lazy_indexed_stack.dart';
import 'package:smartbunda/screens/admin_screen.dart';
import 'package:smartbunda/screens/admin_overview_screen.dart';
import 'package:smartbunda/screens/appointments_screen.dart';
import 'package:smartbunda/screens/education_screen.dart';
import 'package:smartbunda/screens/food_scan_screen.dart';
import 'package:smartbunda/screens/health_record_screen.dart';
import 'package:smartbunda/screens/login_screen.dart';
import 'package:smartbunda/screens/nurse_monitoring_screen.dart';
import 'package:smartbunda/screens/nurse_overview_screen.dart';
import 'package:smartbunda/screens/nutritionist_screen.dart';
import 'package:smartbunda/screens/nutrition_plan_management_screen.dart';
import 'package:smartbunda/screens/patient_dashboard_screen.dart';
import 'package:smartbunda/screens/pre_pregnancy_assessment_screen.dart';
import 'package:smartbunda/screens/patient_profiles_screen.dart';
import 'package:smartbunda/screens/profile_screen.dart';
import 'package:smartbunda/screens/reports_screen.dart';
import 'package:smartbunda/screens/role_modules_screen.dart';
import 'package:smartbunda/screens/staff_module_screen.dart';
import 'package:smartbunda/screens/system_admin_screen.dart';

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
    if (role == UserRole.admin) {
      return const AdminOverviewScreen();
    }
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
      // 4-tab structure: Home → Scan → History → Profile
      // Scanner is top-level navigation (not buried inside Food & Water Log).
      final patientItems = <_NavItem>[
        _NavItem(
          page: PatientDashboardScreen(
            onOpenTab: (value) => setState(() => _index = value),
            onOpenRiskAssessment: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PrePregnancyAssessmentScreen(),
              ),
            ),
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
          page: FoodScanScreen(),
          destination: NavigationDestination(
            icon: Icon(Icons.center_focus_strong_outlined),
            selectedIcon: Icon(Icons.center_focus_strong),
            label: 'Scan',
          ),
          permission: AccessPermission.foodLogging,
        ),
        const _NavItem(
          page: HealthRecordScreen(),
          destination: NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          permission: AccessPermission.patientProfiles,
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

    final items = user.role == UserRole.admin
        ? <_NavItem>[]
        : <_NavItem>[
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Glassmorphism surface: blush-tinted frosted glass
    final surface = isDark
        ? const Color(0xFF18242E).withValues(alpha: 200)
        : Colors.white.withValues(alpha: 195);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            // base shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 60 : 22),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
            // pink glow
            BoxShadow(
              color: const Color(0xFFEC407A).withValues(alpha: isDark ? 40 : 22),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 18)
                      : const Color(0xFFF8BBD0).withValues(alpha: 180),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _GlassNavItem(
                        destination: destinations[i],
                        selected: selectedIndex == i,
                        onTap: () => onDestinationSelected(i),
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

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final activeIcon = destination.selectedIcon ?? destination.icon;
    final icon       = selected ? activeIcon : destination.icon;

    return Tooltip(
      message: destination.label,
      child: Semantics(
        selected: selected,
        button: true,
        label: destination.label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF48FB1), Color(0xFFEC407A)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(26),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEC407A).withValues(alpha: 55),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedScale(
              scale: selected ? 1.0 : 0.92,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme.merge(
                    data: IconThemeData(
                      size: selected ? 22 : 21,
                      color: selected
                          ? Colors.white
                          : isDark
                              ? Colors.white.withValues(alpha: 150)
                              : const Color(0xFF9E9E9E),
                    ),
                    child: icon,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : isDark
                              ? Colors.white.withValues(alpha: 130)
                              : const Color(0xFF9E9E9E),
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 10.0,
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
