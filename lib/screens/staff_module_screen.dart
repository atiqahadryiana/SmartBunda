import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/appointment.dart';
import '../models/food_entry.dart';
import '../models/firestore_doc.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import '../services/appointment_filter_service.dart';
import '../services/service_providers.dart';

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
            const _StaffRecordList(
              title: 'Vital Signs',
              icon: Icons.monitor_heart_outlined,
              rows: [
                _InfoRow('Blood pressure', '118/76 mmHg'),
                _InfoRow('Heart rate', '78 bpm'),
                _InfoRow('Oxygen level', '98%'),
                _InfoRow('Body temperature', '36.8 C'),
                _InfoRow('Blood sugar', '5.2 mmol/L'),
              ],
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE3EE), Color(0xFFE7F6FF), Color(0xFFE8FAF8)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white.withValues(alpha: 220),
            child: Icon(_roleIcon(role), color: const Color(0xFFC24879)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF59677D),
                        height: 1.35,
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
              color: scheme.shadow.withValues(alpha: 12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: scheme.primary.withValues(alpha: 18),
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
              detail: pregnancy?.riskLevel ?? 'not set',
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
        _ConsultationPanel(role: role),
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
                trailing: Wrap(
                  children: [
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.visibility_outlined)),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.download_outlined)),
                  ],
                ),
              ),
            ),
      ],
    );
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

class _ConsultationPanel extends StatelessWidget {
  const _ConsultationPanel({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final actions = switch (role) {
      UserRole.doctor => [
          'Add diagnosis',
          'Prescribe medication',
          'Treatment plan',
          'Consultation notes'
        ],
      UserRole.dietitian => [
          'Create meal plan',
          'Update recommendations',
          'Calorie review',
          'Diet compliance'
        ],
      UserRole.nurse => [
          'Update vital signs',
          'Patient observation',
          'Condition update',
          'Appointment flow'
        ],
      _ => ['Care update'],
    };
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in actions)
                ActionChip(
                  avatar: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text(action),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '$action ready for secure notes integration.'))),
                ),
            ],
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
        color: color.withValues(alpha: 18),
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
