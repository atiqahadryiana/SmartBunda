/// SmartBunda — Admin Dashboard (Flutter Web)
///
/// Modern, healthcare-oriented admin console following the SmartBunda design
/// system (pink & white, Material Design 3). A collapsible grouped sidebar
/// drives a string-id based section dispatch; the whole console re-themes with
/// the app via [appThemeModeProvider] (light/dark/system).
library smartbunda.admin_overview_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/providers/theme_provider.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/theme/app_theme.dart';
import 'package:smartbunda/screens/admin/admin_nav.dart';
import 'package:smartbunda/screens/admin/admin_sections.dart';
import 'package:smartbunda/screens/admin/admin_ui_kit.dart';
import 'package:smartbunda/screens/auth/login_screen.dart';
import 'package:smartbunda/screens/admin/system_admin_screen.dart';

class AdminOverviewScreen extends ConsumerStatefulWidget {
  const AdminOverviewScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  ConsumerState<AdminOverviewScreen> createState() =>
      _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends ConsumerState<AdminOverviewScreen> {
  AdminSection _section = AdminSection.overview;
  bool _collapsed = false;

  void _select(AdminSection section) {
    setState(() => _section = section);
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Admin Dashboard'))
          : null,
      drawer: _isCompact(context)
          ? Drawer(
              child: _SidebarBody(
                selected: _section,
                collapsed: false,
                onSelect: (s) {
                  Navigator.of(context).pop();
                  _select(s);
                },
                onToggleCollapse: null,
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          if (compact) {
            return Column(
              children: [
                Builder(
                  builder: (innerContext) => _AdminTopBar(
                    admin: admin,
                    compact: true,
                    onLogout: _logout,
                    onMenu: () => Scaffold.of(innerContext).openDrawer(),
                  ),
                ),
                Expanded(child: _buildSection()),
              ],
            );
          }
          return Row(
            children: [
              _AdminSidebar(
                selected: _section,
                collapsed: _collapsed,
                onSelect: _select,
                onToggleCollapse: () =>
                    setState(() => _collapsed = !_collapsed),
              ),
              Expanded(
                child: Column(
                  children: [
                    _AdminTopBar(
                      admin: admin,
                      compact: false,
                      onLogout: _logout,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildSection(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 980;

  Widget _buildSection() {
    switch (_section) {
      case AdminSection.overview:
        return AdminOverviewSection(onNavigate: _select);
      case AdminSection.patients:
        return const AdminPatientsSection();
      case AdminSection.professionals:
        return const AdminProfessionalsSection();
      case AdminSection.administrators:
        return const AdminAdministratorsSection();
      case AdminSection.appointmentList:
        return const AdminAppointmentListSection();
      case AdminSection.appointmentCalendar:
        return const AdminAppointmentCalendarSection();
      case AdminSection.assessmentList:
        return const AdminAssessmentSection(
          title: 'Digital First Assessment',
          subtitle: 'Submitted assessments, status, and recommendations.',
          icon: Icons.fact_check_outlined,
          emptyTitle: 'No assessments recorded yet',
          emptyMessage:
              'Patient assessments will be listed here once an assessment '
              'archive collection is connected.',
        );
      case AdminSection.riskAssessments:
        return const AdminAssessmentSection(
          title: 'Risk Assessments',
          subtitle: 'Screening outcomes grouped by risk level.',
          icon: Icons.health_and_safety_outlined,
          emptyTitle: 'No risk data yet',
          emptyMessage:
              'Low / Moderate / High risk results will appear here once '
              'assessments are archived.',
          showRiskFilter: true,
        );
      case AdminSection.assessmentReports:
        return const AdminAssessmentSection(
          title: 'Assessment Reports',
          subtitle: 'Generated assessment summaries and exports.',
          icon: Icons.summarize_outlined,
          emptyTitle: 'No assessment reports yet',
          emptyMessage:
              'Exportable assessment reports will be available here.',
        );
      case AdminSection.consultationRecords:
        return const AdminConsultationSection(
          title: 'Consultation Records',
          subtitle: 'Consultations linked to appointments.',
          icon: Icons.medical_information_outlined,
          emptyMessage:
              'Consultation records will appear here once the Consultations '
              'collection is connected (see the redesign design doc).',
        );
      case AdminSection.consultationNotes:
        return const AdminConsultationSection(
          title: 'Consultation Notes',
          subtitle: 'Clinical notes and recommendations.',
          icon: Icons.note_alt_outlined,
          emptyMessage:
              'Consultation notes will appear here once consultations are '
              'recorded.',
        );
      case AdminSection.nutritionRecords:
        return const AdminNutritionRecordsSection();
      case AdminSection.foodDatabase:
        return const AdminFoodDatabaseSection();
      case AdminSection.medicalReports:
        return const AdminReportsSection(
          title: 'Medical Reports',
          subtitle: 'Reports prepared for and shared with patients.',
        );
      case AdminSection.generatedReports:
        return const AdminReportsSection(
          title: 'Generated Reports',
          subtitle: 'System- and professional-generated PDF reports.',
        );
      case AdminSection.systemAnalytics:
        return const AdminSystemAnalyticsSection();
      case AdminSection.userAnalytics:
        return const AdminUserAnalyticsSection();
      case AdminSection.systemSettings:
        return const SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(8, 4, 24, 32),
          child: SystemAdminScreen(
            title: 'System Settings',
            subtitle: 'Platform configuration, backups, and health.',
          ),
        );
      case AdminSection.profileSettings:
        return const AdminProfileSettingsSection();
    }
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _AdminTopBar extends ConsumerWidget {
  const _AdminTopBar({
    required this.admin,
    required this.compact,
    required this.onLogout,
    this.onMenu,
  });

  final AppUser? admin;
  final bool compact;
  final VoidCallback onLogout;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      height: 72,
      margin: EdgeInsets.fromLTRB(compact ? 12 : 0, 16, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: adminSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: adminBorder(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkPink.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (compact)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenu,
            )
          else
            const Icon(Icons.shield_outlined, color: AppTheme.darkPink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMARTBUNDA Admin',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  admin?.email ?? 'Secure administrator session',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const _ThemeToggle(),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Logout',
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeModeProvider);
    return PopupMenuButton<AppThemeMode>(
      tooltip: 'Theme',
      icon: Icon(_iconFor(mode)),
      onSelected: (value) =>
          ref.read(appThemeModeProvider.notifier).setThemeMode(value),
      itemBuilder: (context) => [
        for (final m in AppThemeMode.values)
          PopupMenuItem(
            value: m,
            child: Row(
              children: [
                Icon(_iconFor(m), size: 18),
                const SizedBox(width: 10),
                Text(m.label),
              ],
            ),
          ),
      ],
    );
  }

  IconData _iconFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode_outlined;
      case AppThemeMode.dark:
        return Icons.dark_mode_outlined;
      case AppThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.selected,
    required this.collapsed,
    required this.onSelect,
    required this.onToggleCollapse,
  });

  final AdminSection selected;
  final bool collapsed;
  final ValueChanged<AdminSection> onSelect;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: collapsed ? 86 : 288,
      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      decoration: BoxDecoration(
        color: adminSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: adminBorder(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkPink.withValues(alpha: 0.063),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: _SidebarBody(
        selected: selected,
        collapsed: collapsed,
        onSelect: onSelect,
        onToggleCollapse: onToggleCollapse,
      ),
    );
  }
}

class _SidebarBody extends StatelessWidget {
  const _SidebarBody({
    required this.selected,
    required this.collapsed,
    required this.onSelect,
    required this.onToggleCollapse,
  });

  final AdminSection selected;
  final bool collapsed;
  final ValueChanged<AdminSection> onSelect;
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          collapsed ? 12 : 16, 20, collapsed ? 12 : 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.health_and_safety,
                    color: Colors.white, size: 22),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMARTBUNDA',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Admin Console',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (onToggleCollapse != null)
                IconButton(
                  tooltip: collapsed ? 'Expand' : 'Collapse',
                  onPressed: onToggleCollapse,
                  icon: Icon(
                    collapsed
                        ? Icons.keyboard_double_arrow_right
                        : Icons.keyboard_double_arrow_left,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                for (final group in adminNavGroups)
                  _SidebarGroup(
                    group: group,
                    selected: selected,
                    collapsed: collapsed,
                    onSelect: onSelect,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarGroup extends StatelessWidget {
  const _SidebarGroup({
    required this.group,
    required this.selected,
    required this.collapsed,
    required this.onSelect,
  });

  final AdminNavGroup group;
  final AdminSection selected;
  final bool collapsed;
  final ValueChanged<AdminSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!collapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
            child: Text(
              group.title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          )
        else
          const SizedBox(height: 10),
        for (final item in group.items)
          _SidebarItem(
            item: item,
            selected: selected == item.id,
            collapsed: collapsed,
            onTap: () => onSelect(item.id),
          ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const activeColor = AppTheme.darkPink;
    final tile = Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 0 : 12, vertical: 11),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primaryPink.withValues(alpha: 0.149)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? activeColor.withValues(alpha: 0.353)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisAlignment:
            collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            size: 20,
            color: selected ? activeColor : theme.colorScheme.onSurfaceVariant,
          ),
          if (!collapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected ? activeColor : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: collapsed ? Tooltip(message: item.label, child: tile) : tile,
      ),
    );
  }
}
