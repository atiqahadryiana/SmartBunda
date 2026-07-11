import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/models/appointment.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/models/firestore_doc.dart';
import 'package:smartbunda/models/pregnancy.dart';
import 'package:smartbunda/models/profile.dart';
import 'package:smartbunda/models/appointment_vitals.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/appointment_filter_service.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/screens/staff/add_clinical_note_screen.dart';
import 'package:smartbunda/screens/staff/record_vitals_sheet.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({
    super.key,
    required this.role,
    required this.onOpenPatients,
    required this.onOpenRecords,
  });

  final UserRole role;
  final VoidCallback onOpenPatients;
  final VoidCallback onOpenRecords;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final appointments = _todayAppointmentsFor(
        role, user, ref.watch(allAppointmentsProvider).valueOrNull ?? const []);
    final users = ref.watch(usersProvider).valueOrNull ?? const <AppUser>[];
    final alerts = _alertsForQueue(appointments);
    final completed = appointments
        .where((item) => item.status.toUpperCase() == 'COMPLETED')
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
      children: [
        _StaffHero(
          title: 'Welcome, ${user?.displayName ?? role.label}',
          subtitle:
              '${role.label} workspace for today\'s consultations and patient reviews.',
          role: role,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StaffMetricCard(
                icon: Icons.today_outlined,
                label: 'Today',
                value: '${appointments.length}',
                detail: 'appointments',
                color: const Color(0xFFC24879),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StaffMetricCard(
                icon: Icons.task_alt_outlined,
                label: 'Progress',
                value: '$completed/${appointments.length}',
                detail: 'completed',
                color: const Color(0xFF23A6A6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _StaffSectionHeader(
          title: 'Active consultation queue',
          actionLabel: 'View all',
          onAction: onOpenPatients,
        ),
        const SizedBox(height: 10),
        if (appointments.isEmpty)
          const _StaffEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No patients scheduled today',
            message: 'Only patients with appointments today appear here.',
          )
        else
          ...appointments.take(4).map(
                (appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TodayPatientCard(
                    appointment: appointment,
                    patient: _userFor(users, appointment.patientId),
                    provider: _userFor(users, appointment.providerId),
                    onOpen: onOpenRecords,
                  ),
                ),
              ),
        const SizedBox(height: 12),
        const _StaffSectionHeader(title: 'Health alerts and reminders'),
        const SizedBox(height: 10),
        _AlertStrip(alerts: alerts),
        const SizedBox(height: 16),
        _QuickStaffActions(role: role, onOpenPatients: onOpenPatients),
      ],
    );
  }
}

class StaffTodayPatientsScreen extends ConsumerStatefulWidget {
  const StaffTodayPatientsScreen({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<StaffTodayPatientsScreen> createState() =>
      _StaffTodayPatientsScreenState();
}

class _StaffTodayPatientsScreenState
    extends ConsumerState<StaffTodayPatientsScreen> {
  final _searchCtrl = TextEditingController();
  AppointmentStatusFilter _statusFilter = AppointmentStatusFilter.all;
  SessionSlotFilter _slotFilter = SessionSlotFilter.all;
  AppointmentTypeFilter _typeFilter = AppointmentTypeFilter.all;
  bool _filtersExpanded = false;

  /// How many filters are set to something other than "All".
  int get _activeFilterCount =>
      (_statusFilter != AppointmentStatusFilter.all ? 1 : 0) +
      (_slotFilter != SessionSlotFilter.all ? 1 : 0) +
      (_typeFilter != AppointmentTypeFilter.all ? 1 : 0);

  void _clearFilters() {
    setState(() {
      _statusFilter = AppointmentStatusFilter.all;
      _slotFilter = SessionSlotFilter.all;
      _typeFilter = AppointmentTypeFilter.all;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final users = ref.watch(usersProvider).valueOrNull ?? const <AppUser>[];
    final allAppointments =
        ref.watch(allAppointmentsProvider).valueOrNull ?? const <Appointment>[];
    final today = _todayAppointmentsFor(widget.role, user, allAppointments);

    // Apply status/slot/type filters, then the free-text search.
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = AppointmentFilterService.applyFilters(
      today,
      status: _statusFilter,
      slot: _slotFilter,
      type: _typeFilter,
    ).where((appointment) {
      if (query.isEmpty) return true;
      final patient = _userFor(users, appointment.patientId);
      return (patient?.displayName ?? patient?.email ?? '')
              .toLowerCase()
              .contains(query) ||
          appointment.type.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
      children: [
        _StaffHero(
          title: 'Today\'s Patients',
          subtitle:
              'Only patients with appointments on ${DateFormat('d MMM yyyy').format(DateTime.now())}.',
          role: widget.role,
        ),
        const SizedBox(height: 16),
        _AppointmentCountHeader(
          total: allAppointments.length,
          today: today.length,
          filtered: filtered.length,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search patient or appointment',
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Collapsible filters — keeps the default view clean. The toggle shows
        // how many filters are active and offers a one-tap Clear.
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _filtersExpanded = !_filtersExpanded),
                icon: Icon(
                  _filtersExpanded
                      ? Icons.expand_less
                      : Icons.tune_outlined,
                  size: 18,
                ),
                label: Text(
                  _activeFilterCount == 0
                      ? 'Filters'
                      : 'Filters ($_activeFilterCount)',
                ),
              ),
            ),
            if (_activeFilterCount > 0) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Clear'),
              ),
            ],
          ],
        ),
        if (_filtersExpanded) ...[
          const SizedBox(height: 12),
          _TypedFilterStrip<AppointmentStatusFilter>(
            label: 'Status',
            values: AppointmentStatusFilter.values,
            selected: _statusFilter,
            labelOf: (value) => value.label,
            onSelected: (value) => setState(() => _statusFilter = value),
          ),
          const SizedBox(height: 8),
          _TypedFilterStrip<SessionSlotFilter>(
            label: 'Session',
            values: SessionSlotFilter.values,
            selected: _slotFilter,
            labelOf: (value) => value.label,
            onSelected: (value) => setState(() => _slotFilter = value),
          ),
          const SizedBox(height: 8),
          _TypedFilterStrip<AppointmentTypeFilter>(
            label: 'Type',
            values: AppointmentTypeFilter.values,
            selected: _typeFilter,
            labelOf: (value) => value.label,
            onSelected: (value) => setState(() => _typeFilter = value),
          ),
        ],
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const _StaffEmptyState(
            icon: Icons.people_alt_outlined,
            title: 'No matching patients today',
            message:
                'Patients without today\'s appointments are hidden by design.',
          )
        else
          for (final appointment in filtered) ...[
            _TodayPatientCard(
              appointment: appointment,
              patient: _userFor(users, appointment.patientId),
              provider: _userFor(users, appointment.providerId),
              onOpen: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StaffPatientRecordDetailScreen(
                    role: widget.role,
                    appointment: appointment,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class StaffHealthRecordsScreen extends ConsumerWidget {
  const StaffHealthRecordsScreen({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final users = ref.watch(usersProvider).valueOrNull ?? const <AppUser>[];
    final appointments = _todayAppointmentsFor(
      role,
      user,
      ref.watch(allAppointmentsProvider).valueOrNull ?? const [],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
      children: [
        _StaffHero(
          title: 'Health Records',
          subtitle: 'Review records only for patients scheduled today.',
          role: role,
        ),
        const SizedBox(height: 16),
        if (appointments.isEmpty)
          const _StaffEmptyState(
            icon: Icons.folder_off_outlined,
            title: 'No records available today',
            message: 'Records appear when a patient has an appointment today.',
          )
        else
          for (final appointment in appointments) ...[
            _RecordAccessCard(
              appointment: appointment,
              patient: _userFor(users, appointment.patientId),
              onOpen: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StaffPatientRecordDetailScreen(
                    role: role,
                    appointment: appointment,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class StaffPatientRecordDetailScreen extends ConsumerWidget {
  const StaffPatientRecordDetailScreen({
    super.key,
    required this.role,
    required this.appointment,
  });

  final UserRole role;
  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider).valueOrNull ?? const <AppUser>[];
    final profiles =
        ref.watch(allProfilesProvider).valueOrNull ?? const <String, Profile>{};
    final pregnancies = ref.watch(allPregnanciesProvider).valueOrNull ??
        const <String, Pregnancy>{};
    final entries = ref.watch(allEntriesProvider).valueOrNull ??
        const <String, List<FoodEntry>>{};
    final reports =
        ref.watch(allReportsProvider).valueOrNull ?? const <FirestoreDoc>[];
    final patient = _userFor(users, appointment.patientId);
    final profile = profiles[appointment.patientId];
    final pregnancy = pregnancies[appointment.patientId];
    final foodLogs = entries[appointment.patientId] ?? const <FoodEntry>[];
    final patientReports = reports
        .where((doc) =>
            doc.data['userId'] == appointment.patientId ||
            doc.data['patientId'] == appointment.patientId)
        .toList();

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(patient?.displayName ?? patient?.email ?? 'Patient Record'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Summary'),
              Tab(text: 'Medical History'),
              Tab(text: 'Vital Signs'),
              Tab(text: 'Nutrition'),
              Tab(text: 'Reports'),
              Tab(text: 'Progress'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StaffRecordSummary(
              role: role,
              appointment: appointment,
              patient: patient,
              profile: profile,
              pregnancy: pregnancy,
            ),
            _StaffRecordList(
              title: 'Medical History',
              icon: Icons.medical_information_outlined,
              rows: [
                _InfoRow(
                    'Diagnoses',
                    _roleText(
                        role, 'Add diagnosis', 'Clinical review required')),
                const _InfoRow('Allergies', 'No allergies reported'),
                const _InfoRow('Medications', 'No medication added'),
                const _InfoRow('Chronic illnesses', 'None reported'),
                _InfoRow('Previous treatments',
                    profile?.conditionNotes ?? 'No treatment notes recorded'),
              ],
            ),
            _StaffVitalSignsTab(
              role: role,
              patient: patient,
              profile: profile,
              pregnancy: pregnancy,
              appointmentId: appointment.id,
            ),
            _StaffNutritionTab(role: role, entries: foodLogs),
            _StaffReportsTab(reports: patientReports),
            _StaffProgressTab(entries: foodLogs),
          ],
        ),
      ),
    );
  }
}

class _StaffHero extends StatelessWidget {
  const _StaffHero({
    required this.title,
    required this.subtitle,
    required this.role,
  });

  final String title;
  final String subtitle;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    // The banner uses a fixed light pastel gradient in every theme, so the
    // text is given explicit dark colours (not the theme's onSurface, which is
    // near-white in dark mode and would vanish against this background).
    const ink = Color(0xFF3A2F33); // high-contrast on the pastel gradient
    const muted = Color(0xFF6B5560);
    const accent = Color(0xFFC24879);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE3EE), Color(0xFFE7F6FF), Color(0xFFE8FAF8)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(_roleIcon(role), color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('👋', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayPatientCard extends StatelessWidget {
  const _TodayPatientCard({
    required this.appointment,
    required this.patient,
    required this.provider,
    required this.onOpen,
  });

  final Appointment appointment;
  final AppUser? patient;
  final AppUser? provider;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.047),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: scheme.primary.withValues(alpha: 0.071),
              child: Text(
                _initials(patient?.displayName ?? patient?.email ?? 'P'),
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient?.displayName ?? patient?.email ?? 'Unknown patient',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('h:mm a').format(appointment.dateTime)} • ${appointment.type}',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Assigned: ${provider?.displayName ?? provider?.email ?? 'Care team'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const _StaffChip(
                          label: 'Stable', color: Color(0xFF23A6A6)),
                      _StaffChip(
                        label: appointment.status,
                        color: _statusColor(appointment.status),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _RecordAccessCard extends StatelessWidget {
  const _RecordAccessCard({
    required this.appointment,
    required this.patient,
    required this.onOpen,
  });

  final Appointment appointment;
  final AppUser? patient;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.folder_shared_outlined),
        title: Text(patient?.displayName ?? patient?.email ?? 'Patient record'),
        subtitle: Text(
          '${appointment.type} • ${DateFormat('h:mm a').format(appointment.dateTime)}',
        ),
        trailing: FilledButton.tonal(
          onPressed: onOpen,
          child: const Text('Open'),
        ),
      ),
    );
  }
}

class _StaffRecordSummary extends StatelessWidget {
  const _StaffRecordSummary({
    required this.role,
    required this.appointment,
    required this.patient,
    required this.profile,
    required this.pregnancy,
  });

  final UserRole role;
  final Appointment appointment;
  final AppUser? patient;
  final Profile? profile;
  final Pregnancy? pregnancy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StaffHero(
          title: patient?.displayName ?? patient?.email ?? 'Patient summary',
          subtitle:
              'Appointment: ${appointment.type} at ${DateFormat('h:mm a').format(appointment.dateTime)}',
          role: role,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _StaffMetricCard(
              icon: Icons.monitor_weight_outlined,
              label: 'Weight',
              value: profile == null
                  ? '--'
                  : profile!.currentWeightKg.toStringAsFixed(1),
              detail: 'kg',
              color: const Color(0xFFC24879),
            ),
            _StaffMetricCard(
              icon: Icons.pregnant_woman_outlined,
              label: 'Pregnancy',
              value: pregnancy == null
                  ? '--'
                  : 'Week ${pregnancy!.gestationalWeek}',
              detail:
                  PregnancyRiskLevel.fromCode(pregnancy?.riskLevel)?.display ??
                      'not set',
              color: const Color(0xFF8A7CF6),
            ),
            const _StaffMetricCard(
              icon: Icons.favorite_outline,
              label: 'Status',
              value: 'Stable',
              detail: 'health indicator',
              color: Color(0xFF23A6A6),
            ),
            _StaffMetricCard(
              icon: Icons.assignment_outlined,
              label: 'Consult',
              value: appointment.status,
              detail: 'queue status',
              color: _statusColor(appointment.status),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ConsultationPanel(
          role: role,
          patient: patient,
          profile: profile,
          pregnancy: pregnancy,
          appointmentId: appointment.id,
        ),
      ],
    );
  }
}

class _StaffRecordList extends StatelessWidget {
  const _StaffRecordList({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StaffHero(
            title: title,
            subtitle: 'Professional review workspace.',
            role: UserRole.doctor),
        const SizedBox(height: 16),
        for (final row in rows)
          Card(
              child: ListTile(
                  title: Text(row.label),
                  subtitle: Text(row.value),
                  leading: Icon(icon))),
      ],
    );
  }
}

class _StaffNutritionTab extends StatelessWidget {
  const _StaffNutritionTab({required this.role, required this.entries});

  final UserRole role;
  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final calories = entries.fold<int>(0, (sum, item) => sum + item.calories);
    final protein = entries.fold<int>(0, (sum, item) => sum + item.protein);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StaffHero(
            title: 'Nutrition History',
            subtitle: 'Food logs, calories, hydration, and recommendations.',
            role: role),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _StaffMetricCard(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Calories',
                    value: '$calories',
                    detail: 'kcal logged',
                    color: const Color(0xFFC24879))),
            const SizedBox(width: 12),
            Expanded(
                child: _StaffMetricCard(
                    icon: Icons.restaurant_outlined,
                    label: 'Protein',
                    value: '$protein',
                    detail: 'g logged',
                    color: const Color(0xFF23A6A6))),
          ],
        ),
        const SizedBox(height: 16),
        _ConsultationPanel(role: role),
        const SizedBox(height: 16),
        for (final entry in entries.take(8))
          Card(
            child: ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: Text(entry.meal),
              subtitle: Text(
                  '${entry.calories} kcal • P ${entry.protein}g • C ${entry.carbs}g • F ${entry.fat}g'),
            ),
          ),
      ],
    );
  }
}

class _StaffReportsTab extends StatelessWidget {
  const _StaffReportsTab({required this.reports});

  final List<FirestoreDoc> reports;

  @override
  Widget build(BuildContext context) {
    final items = reports.isEmpty ? const <FirestoreDoc>[] : reports
      ..sort((a, b) => (b.timestamp ?? DateTime(1900))
          .compareTo(a.timestamp ?? DateTime(1900)));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _StaffHero(
            title: 'Reports',
            subtitle: 'Medical reports, prescriptions, lab results, and PDFs.',
            role: UserRole.doctor),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const _StaffEmptyState(
              icon: Icons.picture_as_pdf_outlined,
              title: 'No reports attached',
              message: 'Uploaded documents will appear here.')
        else
          for (final report in items)
            Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(report.title ?? report.id),
                subtitle: Text(DateFormat('d MMM yyyy')
                    .format(report.timestamp ?? DateTime.now())),
                trailing: IconButton(
                  tooltip: 'View report details',
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () => _showStaffReportDetails(context, report),
                ),
                onTap: () => _showStaffReportDetails(context, report),
              ),
            ),
      ],
    );
  }

  /// Read-only, clinical-style details dialog for a nutrition report document.
  ///
  /// Renders curated, human-readable rows (with units and computed adherence)
  /// instead of dumping every raw Firestore field. The stored `createdAt` and
  /// `generatedAt` are the same instant, so only one "Generated" date is shown,
  /// and internal keys (id, patientId, raw timestamps) are never displayed.
  void _showStaffReportDetails(BuildContext context, FirestoreDoc report) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final data = report.data;

    int? asInt(dynamic v) =>
        v is num ? v.round() : (v is String ? int.tryParse(v) : null);

    final patient = StaffReportFormat.stringValue(data['patientName']) ??
        StaffReportFormat.stringValue(data['patient']);
    final generated = report.timestamp;

    final avgCalories = asInt(data['avgCalories']);
    final calorieTarget = asInt(data['calorieTarget']);
    final avgProtein = asInt(data['avgProtein']);
    final proteinTarget = asInt(data['proteinTarget']);

    String pct(int? value, int? target) {
      if (value == null || target == null || target == 0) return '—';
      return '${(value / target * 100).round()}%';
    }

    final rows = <(String, String)>[
      if (patient != null) ('Patient', patient),
      if (generated != null)
        ('Generated', DateFormat('d MMM yyyy, h:mm a').format(generated)),
      if (avgCalories != null)
        (
          'Avg. daily calories',
          calorieTarget != null
              ? '$avgCalories / $calorieTarget kcal  (${pct(avgCalories, calorieTarget)})'
              : '$avgCalories kcal'
        ),
      if (avgProtein != null)
        (
          'Avg. daily protein',
          proteinTarget != null
              ? '$avgProtein / $proteinTarget g  (${pct(avgProtein, proteinTarget)})'
              : '$avgProtein g'
        ),
    ];

    final hasIntake = avgCalories != null || avgProtein != null;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nutrition Report',
                        style: text.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                    if (report.title != null)
                      Text(report.title!,
                          style: text.bodySmall
                              ?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (label, value) in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(label,
                              style: text.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(value,
                              style: text.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                if (!hasIntake)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'No meals were logged in this reporting period, so '
                      'intake averages are unavailable.',
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Screening summary for clinical reference. Confirm '
                          'against the patient record before acting.',
                          style: text.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).maybePop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Helpers for rendering report documents.
abstract final class StaffReportFormat {
  static String? stringValue(dynamic raw) {
    if (raw is! String) return null;
    final t = raw.trim();
    return t.isEmpty ? null : t;
  }
}

class _StaffProgressTab extends StatelessWidget {
  const _StaffProgressTab({required this.entries});

  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final recent = entries.take(7).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _StaffHero(
            title: 'Progress',
            subtitle:
                'Weight, hydration, nutrition improvements, and care trends.',
            role: UserRole.nurse),
        const SizedBox(height: 16),
        _ProgressBars(entries: recent),
        const SizedBox(height: 16),
        const _StaffEmptyState(
            icon: Icons.insights_outlined,
            title: 'AI health insights ready',
            message: 'Progress signals can connect to secure analytics later.'),
      ],
    );
  }
}

/// Vital Signs tab — shows the patient's REAL recorded vitals (latest summary +
/// per-visit history from AppointmentVitals) and a button to record new ones.
class _StaffVitalSignsTab extends ConsumerWidget {
  const _StaffVitalSignsTab({
    required this.role,
    required this.patient,
    required this.profile,
    required this.pregnancy,
    required this.appointmentId,
  });

  final UserRole role;
  final AppUser? patient;
  final Profile? profile;
  final Pregnancy? pregnancy;
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = patient;
    if (p == null) {
      return const _StaffEmptyState(
        icon: Icons.monitor_heart_outlined,
        title: 'Patient not loaded',
        message: 'Open the patient record again to view vitals.',
      );
    }
    final vitalsAsync = ref.watch(patientVitalsProvider(p.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StaffHero(
          title: 'Vital Signs',
          subtitle: 'Recorded measurements for ${p.displayName ?? p.email}.',
          role: role,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => showRecordVitalsSheet(
              context,
              ref,
              patient: p,
              profile: profile,
              pregnancy: pregnancy,
              appointmentId: appointmentId,
            ),
            icon: const Icon(Icons.add_chart_outlined),
            label: const Text('Record vitals'),
          ),
        ),
        const SizedBox(height: 16),
        vitalsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Could not load vitals: $e'),
          data: (records) {
            if (records.isEmpty) {
              return const _StaffEmptyState(
                icon: Icons.monitor_heart_outlined,
                title: 'No vitals recorded yet',
                message: 'Tap "Record vitals" to add weight, Hb, BP and more '
                    'for this appointment.',
              );
            }
            final latest = records.first;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StaffRecordList(
                  title: 'Latest vitals',
                  icon: Icons.monitor_heart_outlined,
                  rows: [
                    _InfoRow('Weight', _fmt(latest.weightKg, 'kg')),
                    _InfoRow('Hemoglobin', _fmt(latest.hemoglobinGdl, 'g/dL')),
                    _InfoRow('Blood pressure',
                        latest.bloodPressure == null
                            ? '--'
                            : '${latest.bloodPressure} mmHg'),
                    _InfoRow('Fundal height',
                        _fmt(latest.fundalHeightCm, 'cm')),
                    _InfoRow(
                        'Gestational week',
                        latest.gestationalWeek == null
                            ? '--'
                            : 'Week ${latest.gestationalWeek}'),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('History',
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                const SizedBox(height: 8),
                for (final v in records)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_note_outlined),
                      title: Text(_vitalsLine(v)),
                      subtitle: Text(
                        '${DateFormat('d MMM yyyy, h:mm a').format(v.recordedAt)}'
                        ' · ${v.recordedByName}'
                        '${v.notes != null && v.notes!.isNotEmpty ? '\n${v.notes}' : ''}',
                      ),
                      isThreeLine: v.notes != null && v.notes!.isNotEmpty,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  static String _fmt(double? value, String unit) =>
      (value == null) ? '--' : '${value.toStringAsFixed(1)} $unit';

  static String _vitalsLine(AppointmentVitals v) {
    final parts = <String>[
      if (v.weightKg != null) '${v.weightKg!.toStringAsFixed(1)} kg',
      if (v.hemoglobinGdl != null) 'Hb ${v.hemoglobinGdl!.toStringAsFixed(1)}',
      if (v.bloodPressure != null) 'BP ${v.bloodPressure}',
      if (v.fundalHeightCm != null)
        'FH ${v.fundalHeightCm!.toStringAsFixed(1)} cm',
      if (v.gestationalWeek != null) 'Wk ${v.gestationalWeek}',
    ];
    return parts.isEmpty ? 'No measurements' : parts.join(' · ');
  }
}

/// One consultation action. [onTap] null = not yet wired (shows a coming-soon
/// snackbar); non-null = a real, working action.
class _ConsultAction {
  const _ConsultAction(this.label, this.icon, [this.onTap]);
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}

class _ConsultationPanel extends ConsumerWidget {
  const _ConsultationPanel({
    required this.role,
    this.patient,
    this.profile,
    this.pregnancy,
    this.appointmentId,
  });

  final UserRole role;

  /// Patient context. When null (dashboard / generic views) the patient-specific
  /// actions are hidden and only placeholders show.
  final AppUser? patient;
  final Profile? profile;
  final Pregnancy? pregnancy;
  final String? appointmentId;

  bool get _hasPatient => patient != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The two core, fully-wired actions available to ALL staff (incl. nurses):
    // record vitals (weight/Hb/BP…) and add a consultation note.
    void recordVitals() {
      final p = patient;
      if (p == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient record not loaded yet.')),
        );
        return;
      }
      showRecordVitalsSheet(
        context,
        ref,
        patient: p,
        profile: profile,
        pregnancy: pregnancy,
        appointmentId: appointmentId,
      );
    }

    void addNote() {
      final p = patient;
      if (p == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient record not loaded yet.')),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddClinicalNoteScreen(patient: p)),
      );
    }

    // Only real, working actions are shown — no "coming soon" placeholders.
    final actions = <_ConsultAction>[
      _ConsultAction('Record vitals', Icons.monitor_heart_outlined, recordVitals),
      _ConsultAction('Consultation note', Icons.note_add_outlined, addNote),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Consultation workflow',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (_hasPatient)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in actions)
                  ActionChip(
                    avatar: Icon(action.icon, size: 18),
                    label: Text(action.label),
                    onPressed: action.onTap,
                  ),
              ],
            )
          else
            Text(
              'Open a patient from Today\'s Patients or Health Records to '
              'record vitals or add a consultation note.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
        ],
      ),
    );
  }
}

class _QuickStaffActions extends StatelessWidget {
  const _QuickStaffActions({required this.role, required this.onOpenPatients});

  final UserRole role;
  final VoidCallback onOpenPatients;

  @override
  Widget build(BuildContext context) {
    return _ConsultationPanel(role: role);
  }
}

class _AlertStrip extends StatelessWidget {
  const _AlertStrip({required this.alerts});

  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final alert in alerts)
          Card(
            child: ListTile(
              leading: const Icon(Icons.notification_important_outlined),
              title: Text(alert),
              subtitle: const Text('Review during today\'s appointment.'),
            ),
          ),
      ],
    );
  }
}

class _ProgressBars extends StatelessWidget {
  const _ProgressBars({required this.entries});

  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final values = entries.map((entry) => entry.calories).toList();
    return Column(
      children: [
        for (var i = 0; i < 7; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(width: 42, child: Text('Day ${i + 1}')),
                Expanded(
                  child: LinearProgressIndicator(
                    value: i < values.length
                        ? (values[i] / 2400).clamp(0.0, 1.0)
                        : 0,
                    borderRadius: BorderRadius.circular(999),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StaffMetricCard extends StatelessWidget {
  const _StaffMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(label),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
          Text(detail,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _StaffSectionHeader extends StatelessWidget {
  const _StaffSectionHeader(
      {required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900))),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// Horizontal strip of [FilterChip]s bound to an enum value.
class _TypedFilterStrip<T> extends StatelessWidget {
  const _TypedFilterStrip({
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final value in values) ...[
                FilterChip(
                  label: Text(labelOf(value)),
                  selected: selected == value,
                  onSelected: (_) => onSelected(value),
                  showCheckmark: false,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Summary header showing total, today's, and filtered appointment counts.
class _AppointmentCountHeader extends StatelessWidget {
  const _AppointmentCountHeader({
    required this.total,
    required this.today,
    required this.filtered,
  });

  final int total;
  final int today;
  final int filtered;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StaffMetricCard(
            icon: Icons.event_note_outlined,
            label: 'Total',
            value: '$total',
            detail: 'appointments',
            color: const Color(0xFF4F8DF7),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StaffMetricCard(
            icon: Icons.today_outlined,
            label: 'Today',
            value: '$today',
            detail: 'scheduled',
            color: const Color(0xFFC24879),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StaffMetricCard(
            icon: Icons.filter_alt_outlined,
            label: 'Filtered',
            value: '$filtered',
            detail: 'shown',
            color: const Color(0xFF23A6A6),
          ),
        ),
      ],
    );
  }
}

class _StaffChip extends StatelessWidget {
  const _StaffChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.071),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w800)),
    );
  }
}

class _StaffEmptyState extends StatelessWidget {
  const _StaffEmptyState(
      {required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
}

List<Appointment> _todayAppointmentsFor(
  UserRole role,
  AppUser? staff,
  List<Appointment> appointments,
) {
  final now = DateTime.now();
  final today = appointments.where((appointment) {
    final date = appointment.dateTime;
    if (date.year != now.year ||
        date.month != now.month ||
        date.day != now.day) {
      return false;
    }
    if (appointment.status.toUpperCase() == 'CANCELLED') return false;
    if (staff == null) return false;
    if (role == UserRole.nurse) return true;
    return appointment.providerId == staff.id;
  }).toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  return today;
}

AppUser? _userFor(List<AppUser> users, String id) {
  for (final user in users) {
    if (user.id == id) return user;
  }
  return null;
}

List<String> _alertsForQueue(List<Appointment> appointments) {
  if (appointments.isEmpty) return ['No active patient alerts for today.'];
  final late = appointments
      .where((item) => item.dateTime.isBefore(DateTime.now()))
      .length;
  return [
    if (late > 0) '$late consultation slots need follow-up',
    '${appointments.length} patient records ready for review',
    'Confirm vitals and notes before closing each consultation',
  ];
}

IconData _roleIcon(UserRole role) {
  switch (role) {
    case UserRole.doctor:
      return Icons.medical_services_outlined;
    case UserRole.dietitian:
      return Icons.restaurant_menu_outlined;
    case UserRole.nurse:
      return Icons.monitor_heart_outlined;
    default:
      return Icons.health_and_safety_outlined;
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'P';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

String _roleText(UserRole role, String doctorText, String fallback) {
  return role == UserRole.doctor ? doctorText : fallback;
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return const Color(0xFF23A6A6);
    case 'scheduled':
      return const Color(0xFF4F8DF7);
    case 'cancelled':
      return const Color(0xFFE86D9B);
    default:
      return const Color(0xFFF2A93B);
  }
}
