/// SmartBunda — Admin Dashboard sections
///
/// Each section is a [ConsumerWidget] that reads existing providers and renders
/// a themed [AdminPage]. Sections backed by real data are fully functional;
/// sections awaiting backing collections (assessments, consultations) render
/// polished empty states.
library smartbunda.admin_sections;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/activity_log.dart';
import '../../models/app_user.dart';
import '../../models/appointment.dart';
import '../../models/firestore_doc.dart';
import '../../models/food_catalog_entry.dart';
import '../../models/food_entry.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../services/appointment_filter_service.dart';
import '../../services/service_providers.dart';
import '../../theme/app_theme.dart';
import '../change_password_screen.dart';
import '../settings_screen.dart';
import 'admin_charts.dart';
import 'admin_nav.dart';
import 'admin_ui_kit.dart';

// ════════════════════════════════════════════════════════════════════════════
// OVERVIEW
// ════════════════════════════════════════════════════════════════════════════

class AdminOverviewSection extends ConsumerWidget {
  const AdminOverviewSection({super.key, required this.onNavigate});

  final void Function(AdminSection) onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider).valueOrNull ?? const <AppUser>[];
    final appointments =
        ref.watch(allAppointmentsProvider).valueOrNull ?? const <Appointment>[];
    final reports =
        ref.watch(allReportsProvider).valueOrNull ?? const <FirestoreDoc>[];
    final logs =
        ref.watch(activityLogsProvider).valueOrNull ?? const <ActivityLogEntry>[];

    final patients =
        users.where((u) => u.role == UserRole.patient).length;
    final professionals = users
        .where((u) =>
            u.role == UserRole.doctor ||
            u.role == UserRole.nurse ||
            u.role == UserRole.dietitian)
        .length;
    final today = appointments.where((a) => _isToday(a.dateTime)).length;
    final completedConsults = appointments
        .where((a) => a.status.toLowerCase() == 'completed')
        .length;

    return AdminPage(
      title: 'Dashboard Overview',
      subtitle: 'Operational summary across the SmartBunda platform.',
      children: [
        AdminMetricGrid(metrics: [
          AdminMetric(
            icon: Icons.pregnant_woman_outlined,
            label: 'Total Patients',
            value: '$patients',
            color: AppTheme.darkPink,
          ),
          AdminMetric(
            icon: Icons.medical_services_outlined,
            label: 'Healthcare Professionals',
            value: '$professionals',
            color: AppTheme.info,
          ),
          AdminMetric(
            icon: Icons.event_available_outlined,
            label: "Today's Appointments",
            value: '$today',
            color: AppTheme.healthcareTeal,
          ),
          const AdminMetric(
            icon: Icons.fact_check_outlined,
            label: 'Pending Assessments',
            value: '0',
            detail: 'Awaiting data',
            color: AppTheme.warning,
          ),
          AdminMetric(
            icon: Icons.forum_outlined,
            label: 'Completed Consultations',
            value: '$completedConsults',
            color: AppTheme.success,
          ),
          AdminMetric(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Generated Reports',
            value: '${reports.length}',
            color: AppTheme.accentPink,
          ),
        ]),
        const SizedBox(height: 20),

        // Analytics row
        AdminTwoColumn(
          left: AdminPanel(
            title: 'Appointment Trends',
            subtitle: 'Last 7 days',
            child: AdminLineChart(
              values: _appointmentsPerDay(appointments),
              labels: _last7DayLabels(),
              color: AppTheme.darkPink,
            ),
          ),
          right: AdminPanel(
            title: 'User Role Mix',
            child: AdminDonutChart(data: {
              'Patients': patients,
              'Doctors': _count(users, UserRole.doctor),
              'Dietitians': _count(users, UserRole.dietitian),
              'Nurses': _count(users, UserRole.nurse),
            }),
          ),
        ),
        const SizedBox(height: 20),

        // Quick actions
        AdminPanel(
          title: 'Quick Actions',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AdminPrimaryButton(
                icon: Icons.add_circle_outline,
                label: 'Create Appointment',
                onTap: () => onNavigate(AdminSection.appointmentList),
              ),
              AdminSoftButton(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Generate Report',
                onTap: () => onNavigate(AdminSection.generatedReports),
              ),
              AdminSoftButton(
                icon: Icons.fact_check_outlined,
                label: 'View Assessments',
                onTap: () => onNavigate(AdminSection.assessmentList),
              ),
              AdminSoftButton(
                icon: Icons.manage_accounts_outlined,
                label: 'Manage Users',
                onTap: () => onNavigate(AdminSection.patients),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Recent activity
        AdminPanel(
          title: 'Recent Activities',
          child: logs.isEmpty
              ? Text(
                  'No recent activity recorded yet.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: [
                    for (final log in logs.take(8))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppTheme.primaryPink.withValues(alpha: 36),
                          child: const Icon(Icons.bolt,
                              size: 16, color: AppTheme.darkPink),
                        ),
                        title: Text(log.message,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        trailing: Text(
                          DateFormat('d MMM, HH:mm').format(log.timestamp),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT — Patients
// ════════════════════════════════════════════════════════════════════════════

class AdminPatientsSection extends ConsumerStatefulWidget {
  const AdminPatientsSection({super.key});

  @override
  ConsumerState<AdminPatientsSection> createState() =>
      _AdminPatientsSectionState();
}

class _AdminPatientsSectionState extends ConsumerState<AdminPatientsSection> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider).valueOrNull ?? const <AppUser>[];
    final profiles =
        ref.watch(allProfilesProvider).valueOrNull ?? const <String, Profile>{};
    final appointments =
        ref.watch(allAppointmentsProvider).valueOrNull ?? const <Appointment>[];

    final patients = users
        .where((u) => u.role == UserRole.patient)
        .where((u) => _matches(u, _query))
        .toList();

    return AdminPage(
      title: 'Patients',
      subtitle: 'Manage patient accounts, status, and clinical history.',
      children: [
        AdminSearchField(
          hint: 'Search patients by name or email',
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        AdminTable(
          columns: const [
            'Patient',
            'Age',
            'Pregnancy Status',
            'Last Assessment',
            'Appointment Status',
            'Actions',
          ],
          rows: [
            for (final user in patients)
              _patientRow(context, user, profiles[user.id], appointments),
          ],
        ),
        if (patients.isEmpty) ...[
          const SizedBox(height: 16),
          const AdminEmptyState(
            icon: Icons.groups_2_outlined,
            title: 'No patients found',
            message: 'Patient accounts will appear here once registered.',
          ),
        ],
      ],
    );
  }

  DataRow _patientRow(
    BuildContext context,
    AppUser user,
    Profile? profile,
    List<Appointment> appointments,
  ) {
    final age = profile?.age;
    final pregnant = profile?.medicalConditions.isNotEmpty ?? false;
    final apptStatus = _latestStatus(appointments, user.id);
    return DataRow(cells: [
      DataCell(AdminIdentityCell(
        name: user.displayName ?? user.email,
        subtitle: user.email,
      )),
      DataCell(Text(age?.toString() ?? '--')),
      DataCell(AdminStatusPill(
        label: pregnant ? 'Monitored' : 'General',
        color: pregnant ? AppTheme.darkPink : AppTheme.info,
      )),
      const DataCell(Text('--')),
      DataCell(apptStatus == null
          ? const Text('--')
          : AdminStatusPill(
              label: apptStatus, color: adminStatusColor(apptStatus))),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'View Profile',
            icon: const Icon(Icons.visibility_outlined, size: 18),
            onPressed: () => _showPatientActions(context, user),
          ),
          IconButton(
            tooltip: 'More',
            icon: const Icon(Icons.more_horiz, size: 18),
            onPressed: () => _showPatientActions(context, user),
          ),
        ],
      )),
    ]);
  }

  void _showPatientActions(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(user.displayName ?? user.email),
              subtitle: Text(user.email),
            ),
            const Divider(height: 1),
            const ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('View Profile')),
            const ListTile(
                leading: Icon(Icons.fact_check_outlined),
                title: Text('View Assessments')),
            const ListTile(
                leading: Icon(Icons.folder_shared_outlined),
                title: Text('View Reports')),
            const ListTile(
                leading: Icon(Icons.forum_outlined),
                title: Text('View Consultation History')),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT — Healthcare Professionals
// ════════════════════════════════════════════════════════════════════════════

class AdminProfessionalsSection extends ConsumerStatefulWidget {
  const AdminProfessionalsSection({super.key});

  @override
  ConsumerState<AdminProfessionalsSection> createState() =>
      _AdminProfessionalsSectionState();
}

class _AdminProfessionalsSectionState
    extends ConsumerState<AdminProfessionalsSection> {
  String _query = '';
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider).valueOrNull ?? const <AppUser>[];
    final appointments =
        ref.watch(allAppointmentsProvider).valueOrNull ?? const <Appointment>[];

    final pros = users.where((u) {
      final isPro = u.role == UserRole.doctor ||
          u.role == UserRole.nurse ||
          u.role == UserRole.dietitian;
      if (!isPro) return false;
      if (_roleFilter != 'all' && u.role.name != _roleFilter) return false;
      return _matches(u, _query);
    }).toList();

    return AdminPage(
      title: 'Healthcare Professionals',
      subtitle: 'Doctors, dietitians, and nurses across all clinics.',
      children: [
        Row(
          children: [
            Expanded(
              child: AdminSearchField(
                hint: 'Search by name, email, or specialization',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(width: 12),
            _RoleDropdown(
              value: _roleFilter,
              onChanged: (v) => setState(() => _roleFilter = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdminTable(
          minWidth: 880,
          columns: const [
            'MMC Number',
            'Name',
            'Email',
            'Specialization',
            'Availability',
            'Appointments',
            'Actions',
          ],
          rows: [
            for (final user in pros)
              _proRow(context, user, _countProvider(appointments, user.id)),
          ],
        ),
        if (pros.isEmpty) ...[
          const SizedBox(height: 16),
          const AdminEmptyState(
            icon: Icons.medical_services_outlined,
            title: 'No professionals found',
            message: 'Approved healthcare professionals will appear here.',
          ),
        ],
      ],
    );
  }

  DataRow _proRow(BuildContext context, AppUser user, int apptCount) {
    final available = user.isActive;
    return DataRow(cells: [
      DataCell(Text(user.mmcNumber ?? '--')),
      DataCell(AdminIdentityCell(
        name: user.displayName ?? user.email,
        subtitle: user.role.label,
        color: AppTheme.info,
      )),
      DataCell(Text(user.email)),
      DataCell(Text(user.effectiveSpecialization)),
      DataCell(AdminStatusPill(
        label: available ? 'Available' : 'Unavailable',
        color: available ? AppTheme.success : AppTheme.disabledText,
      )),
      DataCell(Text('$apptCount')),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'View Profile',
            icon: const Icon(Icons.visibility_outlined, size: 18),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'View Schedule',
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            onPressed: () {},
          ),
        ],
      )),
    ]);
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: adminSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: adminBorder(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All roles')),
            DropdownMenuItem(value: 'doctor', child: Text('Doctors')),
            DropdownMenuItem(value: 'dietitian', child: Text('Dietitians')),
            DropdownMenuItem(value: 'nurse', child: Text('Nurses')),
          ],
          onChanged: (v) => onChanged(v ?? 'all'),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT — Administrators
// ════════════════════════════════════════════════════════════════════════════

class AdminAdministratorsSection extends ConsumerWidget {
  const AdminAdministratorsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider).valueOrNull ?? const <AppUser>[];
    final admins = users.where((u) => u.role == UserRole.admin).toList();

    return AdminPage(
      title: 'Administrators',
      subtitle: 'System administrator accounts and access.',
      children: [
        AdminTable(
          minWidth: 600,
          columns: const ['Name', 'Email', 'Status', 'Actions'],
          rows: [
            for (final user in admins)
              DataRow(cells: [
                DataCell(AdminIdentityCell(
                  name: user.displayName ?? user.email,
                  subtitle: 'Administrator',
                  color: AppTheme.accentPink,
                )),
                DataCell(Text(user.email)),
                DataCell(AdminStatusPill(
                  label: user.isActive ? 'Active' : 'Inactive',
                  color: user.isActive
                      ? AppTheme.success
                      : AppTheme.errorColor,
                )),
                DataCell(IconButton(
                  tooltip: 'View',
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  onPressed: () {},
                )),
              ]),
          ],
        ),
        if (admins.isEmpty) ...[
          const SizedBox(height: 16),
          const AdminEmptyState(
            icon: Icons.admin_panel_settings_outlined,
            title: 'No administrators',
            message: 'Administrator accounts will appear here.',
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// APPOINTMENT MANAGEMENT — List
// ════════════════════════════════════════════════════════════════════════════

class AdminAppointmentListSection extends ConsumerStatefulWidget {
  const AdminAppointmentListSection({super.key});

  @override
  ConsumerState<AdminAppointmentListSection> createState() =>
      _AdminAppointmentListSectionState();
}

class _AdminAppointmentListSectionState
    extends ConsumerState<AdminAppointmentListSection> {
  AppointmentStatusFilter _status = AppointmentStatusFilter.all;
  SessionSlotFilter _slot = SessionSlotFilter.all;
  AppointmentTypeFilter _type = AppointmentTypeFilter.all;

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider).valueOrNull ?? const <AppUser>[];
    final appointments =
        ref.watch(allAppointmentsProvider).valueOrNull ?? const <Appointment>[];
    final filtered = AppointmentFilterService.applyFilters(
      appointments,
      status: _status,
      slot: _slot,
      type: _type,
    )..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return AdminPage(
      title: 'Appointment List',
      subtitle: 'All appointments across the platform with filters.',
      children: [
        AdminPanel(
          title: 'Filters',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterRow<AppointmentStatusFilter>(
                label: 'Status',
                values: AppointmentStatusFilter.values,
                selected: _status,
                labelOf: (v) => v.label,
                onSelected: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: 8),
              _FilterRow<SessionSlotFilter>(
                label: 'Session',
                values: SessionSlotFilter.values,
                selected: _slot,
                labelOf: (v) => v.label,
                onSelected: (v) => setState(() => _slot = v),
              ),
              const SizedBox(height: 8),
              _FilterRow<AppointmentTypeFilter>(
                label: 'Type',
                values: AppointmentTypeFilter.values,
                selected: _type,
                labelOf: (v) => v.label,
                onSelected: (v) => setState(() => _type = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminTable(
          minWidth: 820,
          columns: const [
            'Date & Time',
            'Patient',
            'Provider',
            'Type',
            'Status',
          ],
          rows: [
            for (final a in filtered)
              DataRow(cells: [
                DataCell(Text(
                    DateFormat('d MMM yyyy, HH:mm').format(a.dateTime))),
                DataCell(Text(_nameFor(users, a.patientId))),
                DataCell(Text(_nameFor(users, a.providerId))),
                DataCell(Text(a.type)),
                DataCell(AdminStatusPill(
                    label: a.status, color: adminStatusColor(a.status))),
              ]),
          ],
        ),
        if (filtered.isEmpty) ...[
          const SizedBox(height: 16),
          const AdminEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No appointments match',
            message: 'Try adjusting the filters above.',
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// APPOINTMENT MANAGEMENT — Calendar
// ════════════════════════════════════════════════════════════════════════════

class AdminAppointmentCalendarSection extends ConsumerStatefulWidget {
  const AdminAppointmentCalendarSection({super.key});

  @override
  ConsumerState<AdminAppointmentCalendarSection> createState() =>
      _AdminAppointmentCalendarSectionState();
}

class _AdminAppointmentCalendarSectionState
    extends ConsumerState<AdminAppointmentCalendarSection> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider).valueOrNull ?? const <AppUser>[];
    final appointments =
        ref.watch(allAppointmentsProvider).valueOrNull ?? const <Appointment>[];
    final day = _selectedDay ?? _focusedDay;
    final dayAppointments =
        AppointmentFilterService.getForDate(appointments, day)
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return AdminPage(
      title: 'Appointment Calendar',
      subtitle: 'Monthly, weekly, and daily appointment views.',
      children: [
        AdminPanel(
          child: TableCalendar<Appointment>(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _format,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.twoWeeks: 'Weekly',
              CalendarFormat.week: 'Daily',
            },
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            eventLoader: (d) =>
                AppointmentFilterService.getForDate(appointments, d),
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            }),
            onFormatChanged: (f) => setState(() => _format = f),
            onPageChanged: (focused) => _focusedDay = focused,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryPink.withValues(alpha: 120),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.darkPink,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppTheme.accentPink,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonShowsNext: false,
              titleCentered: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AdminPanel(
          title: DateFormat('d MMMM yyyy').format(day),
          subtitle: '${dayAppointments.length} appointment(s)',
          child: dayAppointments.isEmpty
              ? Text(
                  'No appointments on this day.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: [
                    for (final a in dayAppointments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event,
                            color: AppTheme.darkPink),
                        title: Text(_nameFor(users, a.patientId)),
                        subtitle: Text(
                            '${DateFormat('HH:mm').format(a.dateTime)} · ${a.type}'),
                        trailing: AdminStatusPill(
                            label: a.status,
                            color: adminStatusColor(a.status)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ASSESSMENT MANAGEMENT (data pending)
// ════════════════════════════════════════════════════════════════════════════

class AdminAssessmentSection extends StatelessWidget {
  const AdminAssessmentSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.showRiskFilter = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String emptyTitle;
  final String emptyMessage;
  final bool showRiskFilter;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: title,
      subtitle: subtitle,
      children: [
        if (showRiskFilter) ...[
          AdminPanel(
            title: 'Risk Level',
            child: Wrap(
              spacing: 8,
              children: [
                for (final r in const ['All', 'Low Risk', 'Moderate Risk', 'High Risk'])
                  FilterChip(
                    label: Text(r),
                    selected: r == 'All',
                    onSelected: (_) {},
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        AdminEmptyState(
          icon: icon,
          title: emptyTitle,
          message: emptyMessage,
          pending: true,
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CONSULTATION MANAGEMENT (data pending)
// ════════════════════════════════════════════════════════════════════════════

class AdminConsultationSection extends StatelessWidget {
  const AdminConsultationSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emptyMessage,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: title,
      subtitle: subtitle,
      children: [
        AdminEmptyState(
          icon: icon,
          title: 'No consultation data yet',
          message: emptyMessage,
          pending: true,
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// NUTRITION MANAGEMENT — Records
// ════════════════════════════════════════════════════════════════════════════

class AdminNutritionRecordsSection extends ConsumerWidget {
  const AdminNutritionRecordsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesByUser = ref.watch(allEntriesProvider).valueOrNull ??
        const <String, List<FoodEntry>>{};
    final users = ref.watch(usersProvider).valueOrNull ?? const <AppUser>[];
    final allEntries = <FoodEntry>[
      for (final list in entriesByUser.values) ...list,
    ]..sort((a, b) => b.date.compareTo(a.date));
    final totalCalories =
        allEntries.fold<int>(0, (sum, e) => sum + e.calories);

    return AdminPage(
      title: 'Nutrition Records',
      subtitle: 'Food logging activity across all patients.',
      children: [
        AdminMetricGrid(metrics: [
          AdminMetric(
            icon: Icons.restaurant_outlined,
            label: 'Total Entries',
            value: '${allEntries.length}',
            color: AppTheme.darkPink,
          ),
          AdminMetric(
            icon: Icons.people_outline,
            label: 'Active Loggers',
            value: '${entriesByUser.keys.length}',
            color: AppTheme.info,
          ),
          AdminMetric(
            icon: Icons.local_fire_department_outlined,
            label: 'Total Calories',
            value: NumberFormat.compact().format(totalCalories),
            color: AppTheme.warning,
          ),
        ]),
        const SizedBox(height: 20),
        AdminTable(
          minWidth: 700,
          columns: const ['Date', 'Patient', 'Meal', 'Calories', 'Protein'],
          rows: [
            for (final e in allEntries.take(50))
              DataRow(cells: [
                DataCell(Text(DateFormat('d MMM').format(e.date))),
                DataCell(Text(_nameFor(users, e.userId))),
                DataCell(Text(e.meal)),
                DataCell(Text('${e.calories} kcal')),
                DataCell(Text('${e.protein} g')),
              ]),
          ],
        ),
        if (allEntries.isEmpty) ...[
          const SizedBox(height: 16),
          const AdminEmptyState(
            icon: Icons.set_meal_outlined,
            title: 'No nutrition records',
            message: 'Patient food logs will appear here.',
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// NUTRITION MANAGEMENT — Food Database
// ════════════════════════════════════════════════════════════════════════════

class AdminFoodDatabaseSection extends ConsumerStatefulWidget {
  const AdminFoodDatabaseSection({super.key});

  @override
  ConsumerState<AdminFoodDatabaseSection> createState() =>
      _AdminFoodDatabaseSectionState();
}

class _AdminFoodDatabaseSectionState
    extends ConsumerState<AdminFoodDatabaseSection> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(foodCatalogProvider).valueOrNull ??
        const <FoodCatalogEntry>[];
    final filtered = catalog
        .where((e) =>
            _query.isEmpty ||
            e.item.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return AdminPage(
      title: 'Food Database',
      subtitle: 'Malaysian Food Composition Database (MyFCD) entries.',
      children: [
        AdminSearchField(
          hint: 'Search foods',
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        AdminTable(
          minWidth: 760,
          columns: const [
            'Food',
            'Serving',
            'Calories',
            'Protein',
            'Source',
            'Status',
          ],
          rows: [
            for (final e in filtered.take(100))
              DataRow(cells: [
                DataCell(Text(e.item.name)),
                DataCell(Text(e.item.servingSize)),
                DataCell(Text('${e.item.caloriesPerServing} kcal')),
                DataCell(Text('${e.item.proteinG} g')),
                DataCell(AdminStatusPill(
                  label: e.source == FoodCatalogSource.system
                      ? 'System'
                      : 'Custom',
                  color: e.source == FoodCatalogSource.system
                      ? AppTheme.info
                      : AppTheme.darkPink,
                )),
                DataCell(AdminStatusPill(
                  label: e.isActive ? 'Active' : 'Inactive',
                  color: e.isActive
                      ? AppTheme.success
                      : AppTheme.disabledText,
                )),
              ]),
          ],
        ),
        if (filtered.isEmpty) ...[
          const SizedBox(height: 16),
          const AdminEmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No foods found',
            message: 'The food database appears to be empty.',
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// REPORTS — Medical & Generated
// ════════════════════════════════════════════════════════════════════════════

class AdminReportsSection extends ConsumerWidget {
  const AdminReportsSection({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports =
        ref.watch(allReportsProvider).valueOrNull ?? const <FirestoreDoc>[];
    final users = ref.watch(usersProvider).valueOrNull ?? const <AppUser>[];
    final sorted = [...reports]
      ..sort((a, b) =>
          (b.timestamp ?? DateTime(2000)).compareTo(a.timestamp ?? DateTime(2000)));

    return AdminPage(
      title: title,
      subtitle: subtitle,
      children: [
        AdminTable(
          minWidth: 760,
          columns: const [
            'Report Type',
            'Patient',
            'Generated Date',
            'Status',
            'Actions',
          ],
          rows: [
            for (final r in sorted)
              DataRow(cells: [
                DataCell(Text(r.title ?? r.data['reportType']?.toString() ?? 'Report')),
                DataCell(Text(_nameForId(users, r.data['patientId']?.toString() ??
                    r.data['userId']?.toString()))),
                DataCell(Text(r.timestamp == null
                    ? '--'
                    : DateFormat('d MMM yyyy').format(r.timestamp!))),
                DataCell(AdminStatusPill(
                  label: (r.data['status']?.toString() ?? 'Ready'),
                  color: adminStatusColor(
                      r.data['status']?.toString() ?? 'completed'),
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'View Report',
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      onPressed: () {},
                    ),
                    IconButton(
                      tooltip: 'Download PDF',
                      icon: const Icon(Icons.download_outlined, size: 18),
                      onPressed: () {},
                    ),
                    IconButton(
                      tooltip: 'Share Report',
                      icon: const Icon(Icons.share_outlined, size: 18),
                      onPressed: () {},
                    ),
                  ],
                )),
              ]),
          ],
        ),
        if (sorted.isEmpty) ...[
          const SizedBox(height: 16),
          const AdminEmptyState(
            icon: Icons.folder_shared_outlined,
            title: 'No reports yet',
            message: 'Generated and uploaded reports will appear here.',
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ANALYTICS — System
// ════════════════════════════════════════════════════════════════════════════

class AdminSystemAnalyticsSection extends ConsumerWidget {
  const AdminSystemAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments =
        ref.watch(allAppointmentsProvider).valueOrNull ?? const <Appointment>[];
    final entriesByUser = ref.watch(allEntriesProvider).valueOrNull ??
        const <String, List<FoodEntry>>{};

    final completed =
        appointments.where((a) => a.status.toLowerCase() == 'completed').length;
    final scheduled = appointments
        .where((a) => a.status.toLowerCase() == 'scheduled')
        .length;
    final cancelled =
        appointments.where((a) => a.status.toLowerCase() == 'cancelled').length;
    final completionRate = appointments.isEmpty
        ? 0
        : ((completed / appointments.length) * 100).round();

    return AdminPage(
      title: 'System Analytics',
      subtitle: 'Platform-wide healthcare activity metrics.',
      children: [
        AdminMetricGrid(metrics: [
          AdminMetric(
            icon: Icons.event_available_outlined,
            label: 'Appointments Completed',
            value: '$completed',
            color: AppTheme.success,
          ),
          AdminMetric(
            icon: Icons.percent_outlined,
            label: 'Completion Rate',
            value: '$completionRate%',
            color: AppTheme.darkPink,
          ),
          AdminMetric(
            icon: Icons.restaurant_outlined,
            label: 'Food Logging Activity',
            value: '${entriesByUser.keys.length}',
            detail: 'active loggers',
            color: AppTheme.info,
          ),
        ]),
        const SizedBox(height: 20),
        AdminTwoColumn(
          left: AdminPanel(
            title: 'Appointment Trends',
            subtitle: 'Last 7 days',
            child: AdminBarChart(
              values: _appointmentsPerDay(appointments),
              labels: _last7DayLabels(),
              color: AppTheme.darkPink,
            ),
          ),
          right: AdminPanel(
            title: 'Appointment Status Mix',
            child: AdminDonutChart(data: {
              'Completed': completed,
              'Scheduled': scheduled,
              'Cancelled': cancelled,
            }, colors: const [
              AppTheme.success,
              AppTheme.warning,
              AppTheme.errorColor,
            ]),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ANALYTICS — User
// ════════════════════════════════════════════════════════════════════════════

class AdminUserAnalyticsSection extends ConsumerWidget {
  const AdminUserAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider).valueOrNull ?? const <AppUser>[];
    final active = users.where((u) => u.isActive).length;

    return AdminPage(
      title: 'User Analytics',
      subtitle: 'Registrations, activity, and role distribution.',
      children: [
        AdminMetricGrid(metrics: [
          AdminMetric(
            icon: Icons.people_outline,
            label: 'Total Users',
            value: '${users.length}',
            color: AppTheme.darkPink,
          ),
          AdminMetric(
            icon: Icons.verified_user_outlined,
            label: 'Active Users',
            value: '$active',
            color: AppTheme.success,
          ),
          AdminMetric(
            icon: Icons.person_add_alt_outlined,
            label: 'Patients',
            value: '${_count(users, UserRole.patient)}',
            color: AppTheme.info,
          ),
        ]),
        const SizedBox(height: 20),
        AdminTwoColumn(
          left: AdminPanel(
            title: 'Role Distribution',
            child: AdminDonutChart(data: {
              'Patients': _count(users, UserRole.patient),
              'Doctors': _count(users, UserRole.doctor),
              'Dietitians': _count(users, UserRole.dietitian),
              'Nurses': _count(users, UserRole.nurse),
              'Admins': _count(users, UserRole.admin),
            }),
          ),
          right: AdminPanel(
            title: 'Active vs Inactive',
            child: AdminBarChart(
              values: [active, users.length - active],
              labels: const ['Active', 'Inactive'],
              color: AppTheme.info,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SETTINGS — Profile
// ════════════════════════════════════════════════════════════════════════════

class AdminProfileSettingsSection extends ConsumerWidget {
  const AdminProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(currentUserProvider);
    return AdminPage(
      title: 'Profile Settings',
      subtitle: 'Your administrator account and preferences.',
      children: [
        AdminPanel(
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.primaryPink.withValues(alpha: 40),
                child: const Icon(Icons.admin_panel_settings_outlined,
                    color: AppTheme.darkPink, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin?.displayName ?? admin?.email ?? 'Administrator',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(admin?.email ?? '--'),
                    const SizedBox(height: 8),
                    const AdminStatusPill(
                        label: 'Administrator', color: AppTheme.darkPink),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanel(
          title: 'Account',
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Notifications, Language & Theme'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Shared helpers + small widgets
// ════════════════════════════════════════════════════════════════════════════

class _FilterRow<T> extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              FilterChip(
                label: Text(labelOf(v)),
                selected: selected == v,
                showCheckmark: false,
                onSelected: (_) => onSelected(v),
              ),
          ],
        ),
      ],
    );
  }
}

bool _matches(AppUser user, String query) {
  if (query.isEmpty) return true;
  final q = query.toLowerCase();
  return (user.displayName ?? '').toLowerCase().contains(q) ||
      user.email.toLowerCase().contains(q) ||
      (user.specialization ?? '').toLowerCase().contains(q);
}

int _count(List<AppUser> users, UserRole role) =>
    users.where((u) => u.role == role).length;

int _countProvider(List<Appointment> appointments, String providerId) =>
    appointments.where((a) => a.providerId == providerId).length;

String _nameFor(List<AppUser> users, String id) {
  for (final u in users) {
    if (u.id == id) return u.displayName ?? u.email;
  }
  return id;
}

String _nameForId(List<AppUser> users, String? id) {
  if (id == null) return '--';
  return _nameFor(users, id);
}

String? _latestStatus(List<Appointment> appointments, String patientId) {
  final mine = appointments.where((a) => a.patientId == patientId).toList()
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  return mine.isEmpty ? null : mine.first.status;
}

bool _isToday(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

List<int> _appointmentsPerDay(List<Appointment> appointments) {
  final now = DateTime.now();
  return List<int>.generate(7, (i) {
    final day = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: 6 - i));
    return appointments
        .where((a) =>
            a.dateTime.year == day.year &&
            a.dateTime.month == day.month &&
            a.dateTime.day == day.day)
        .length;
  });
}

List<String> _last7DayLabels() {
  final now = DateTime.now();
  return List<String>.generate(7, (i) {
    final day = now.subtract(Duration(days: 6 - i));
    return DateFormat('E').format(day);
  });
}
