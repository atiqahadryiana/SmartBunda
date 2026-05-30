import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/models/alert_item.dart';
import 'package:smartbunda/models/appointment.dart';
import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/screens/appointment_calendar_screen.dart';
import 'package:smartbunda/services/appointment_filter_service.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/theme/app_theme.dart';
import 'package:smartbunda/widgets/empty_state.dart';
import 'package:smartbunda/widgets/screen_header.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({
    super.key,
    required this.role,
    this.showAppBar = false,
  });

  final UserRole role;
  final bool showAppBar;

  @override
  ConsumerState<AppointmentsScreen> createState() =>
      _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  AppointmentFilter _selectedFilter = AppointmentFilter.all;
  bool _showCalendarView = false;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final strings = AppStrings.of(context);
    final role = widget.role;
    final showAppBar = widget.showAppBar;
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        appBar: showAppBar ? AppBar(title: Text(strings.t('Appointments'))) : null,
        body: Center(child: Text(strings.t('Please sign in.'))),
      );
    }

    final effectiveRole = role;
    final canSchedule = effectiveRole == UserRole.doctor ||
        effectiveRole == UserRole.dietitian ||
        effectiveRole == UserRole.nurse;
    final appointmentsAsync = effectiveRole == UserRole.patient
        ? ref.watch(appointmentsProvider)
        : ref.watch(allAppointmentsProvider);
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(strings.t('Appointments'))) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: strings.t('Appointments'),
              subtitle: strings.t('Schedule and track upcoming clinic visits.'),
              icon: Icons.event_available,
              action: canSchedule
                  ? FilledButton.icon(
                      onPressed: () => _showCreateDialog(context, ref, user),
                      icon: const Icon(Icons.add),
                      label: Text(strings.t('New')),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: appointmentsAsync.when(
                data: (appointments) {
                  final allUsers = usersAsync.valueOrNull ?? const <AppUser>[];
                  final relevant = _filterAppointments(user, appointments);
                  if (relevant.isEmpty) {
                    return EmptyState(
                      icon: Icons.event_available,
                      title: strings.t('No appointments scheduled'),
                      message: canSchedule
                          ? strings.t('Create a new appointment to reserve a time slot.')
                          : strings.t('Your upcoming appointments will appear here.'),
                      action: canSchedule
                          ? FilledButton.icon(
                              onPressed: () => _showCreateDialog(context, ref, user),
                              icon: const Icon(Icons.add),
                              label: Text(strings.t('Schedule appointment')),
                            )
                          : null,
                    );
                  }
                  relevant.sort((a, b) => a.dateTime.compareTo(b.dateTime));

                  // Find the next upcoming appointment for the patient banner
                  final now = DateTime.now();
                  final upcoming = relevant.where(
                    (a) => a.dateTime.isAfter(now) &&
                        a.status.toUpperCase() != 'CANCELLED',
                  ).toList();
                  final nextAppt = upcoming.isNotEmpty ? upcoming.first : null;

                  return Column(
                    children: [
                      // ── Next Appointment Banner (patients only) ──────────
                      if (user.role == UserRole.patient && nextAppt != null) ...[
                        _NextAppointmentBanner(
                          appointment: nextAppt,
                          providerName: allUsers
                              .firstWhere(
                                (u) => u.id == nextAppt.providerId,
                                orElse: () => user,
                              )
                              .displayName ?? 'Your provider',
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── View Toggle + Filter ──────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _AppointmentFilterBar(
                              strings: strings,
                              selectedFilter: _selectedFilter,
                              onFilterChanged: (filter) {
                                setState(() => _selectedFilter = filter);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              _showCalendarView
                                  ? Icons.list_outlined
                                  : Icons.calendar_month_outlined,
                            ),
                            onPressed: () {
                              setState(() => _showCalendarView = !_showCalendarView);
                            },
                            tooltip:
                                _showCalendarView ? 'List View' : 'Calendar View',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Appointment List / Calendar View ──────────────────
                      Expanded(
                        child: _showCalendarView
                            ? AppointmentCalendarScreen(
                                appointments: relevant,
                              )
                            : _buildAppointmentListView(
                                context,
                                ref,
                                user,
                                strings,
                                allUsers,
                                relevant,
                                nextAppt,
                              ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Appointment> _filterAppointments(AppUser user, List<Appointment> items) {
    if (user.role == UserRole.admin || user.role == UserRole.nurse) return items;
    return items
        .where((appt) => appt.patientId == user.id || appt.providerId == user.id)
        .toList();
  }

  Widget _actions(BuildContext context, WidgetRef ref, AppUser user, Appointment appt) {
    final strings = AppStrings.of(context);
    final canManage = user.role == UserRole.doctor || user.role == UserRole.dietitian;
    if (!canManage) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'complete') {
          await ref.read(appointmentRepositoryProvider).completeAppointment(appt.id);
        } else if (value == 'cancel') {
          await ref.read(appointmentRepositoryProvider).cancelAppointment(appt.id);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'complete', child: Text(strings.t('Mark complete'))),
        PopupMenuItem(value: 'cancel', child: Text(strings.t('Cancel'))),
      ],
    );
  }

  String _title(
    Appointment appt,
    AppUser patient,
    AppUser provider,
    AppUser user,
    AppStrings strings,
  ) {
    if (user.role == UserRole.patient) {
      return strings.withProvider(
        strings.roleLabel(provider.role),
        provider.displayName ?? provider.email,
      );
    }
    return strings.patientLabel(patient.displayName ?? patient.email);
  }

  String _dateLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.month}/${date.day} $hour:$minute';
  }

  String _dateOnlyLabel(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _timeLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  DateTime? _firstAvailableSlot(
    DateTime date,
    List<Appointment> appointments,
    AppUser provider,
  ) {
    final slots = _availableSlots(date, appointments, provider.id);
    return slots.isNotEmpty ? slots.first : null;
  }

  List<DateTime> _availableSlots(
    DateTime date,
    List<Appointment> appointments,
    String providerId,
  ) {
    final slots = <DateTime>[];
    final start = DateTime(date.year, date.month, date.day, 8, 0);
    final end = DateTime(date.year, date.month, date.day, 17, 0);
    final breakStart = DateTime(date.year, date.month, date.day, 12, 30);
    final breakEnd = DateTime(date.year, date.month, date.day, 14, 30);
    final now = DateTime.now();

    var cursor = start;
    while (cursor.isBefore(end)) {
      final inBreak = (cursor.isAtSameMomentAs(breakStart) ||
              cursor.isAfter(breakStart)) &&
          cursor.isBefore(breakEnd);
      final inPast = _isSameDay(cursor, now) && cursor.isBefore(now);
      if (!inBreak && !inPast) {
        final taken = appointments.any((appt) {
          if (appt.providerId != providerId) return false;
          if (appt.status.toUpperCase() == 'CANCELLED') return false;
          return _sameSlot(appt.dateTime, cursor);
        });
        if (!taken) {
          slots.add(cursor);
        }
      }
      cursor = cursor.add(const Duration(minutes: 30));
    }
    return slots;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _sameSlot(DateTime a, DateTime b) {
    if (!_isSameDay(a, b)) return false;
    final diff = a.difference(b).inMinutes.abs();
    return diff < 30;
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final strings = AppStrings.of(context);
    if (user.role != UserRole.doctor &&
        user.role != UserRole.dietitian &&
        user.role != UserRole.nurse) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.t('Only doctors, dietitians, and nurses can schedule.')),
        ),
      );
      return;
    }
    final users = ref.read(usersProvider).valueOrNull ?? const <AppUser>[];
    final patients = users.where((u) => u.role == UserRole.patient).toList();
    final providers = users
        .where((u) => u.role == UserRole.doctor || u.role == UserRole.dietitian)
        .toList();
    final allAppointments =
        ref.read(allAppointmentsProvider).valueOrNull ?? const <Appointment>[];
    if (user.role != UserRole.patient && patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('No patients available yet.'))),
      );
      return;
    }
    if (user.role == UserRole.nurse && providers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('No doctors or dietitians available yet.'))),
      );
      return;
    }

    AppUser? selectedPatient = user.role == UserRole.patient ? user : patients.first;
    AppUser? selectedProvider =
        user.role == UserRole.nurse ? providers.first : user;
    final typeCtrl = TextEditingController(text: strings.t('Nutrition Consultation'));
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final reminderCtrl = TextEditingController();
    var sendReminder = user.role == UserRole.nurse;
    DateTime? selectedSlot = _firstAvailableSlot(
      selectedDate,
      allAppointments,
      (user.role == UserRole.nurse ? selectedProvider : user),
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('Schedule appointment')),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 360,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (user.role != UserRole.patient)
                        DropdownButtonFormField<AppUser>(
                          initialValue: selectedPatient,
                          items: patients
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.displayName ?? p.email),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => selectedPatient = value),
                          decoration: InputDecoration(labelText: strings.t('Patient')),
                          validator: (value) =>
                              value == null ? strings.t('Select a patient') : null,
                        ),
                      if (user.role == UserRole.nurse)
                        DropdownButtonFormField<AppUser>(
                          initialValue: selectedProvider,
                          items: providers
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    '${strings.roleLabel(p.role)} - ${p.displayName ?? p.email}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedProvider = value;
                              if (value != null) {
                                selectedSlot =
                                    _firstAvailableSlot(selectedDate, allAppointments, value);
                              } else {
                                selectedSlot = null;
                              }
                            });
                          },
                          decoration: InputDecoration(labelText: strings.t('Provider')),
                          validator: (value) =>
                              value == null ? strings.t('Select a provider') : null,
                        ),
                      if (user.role == UserRole.patient)
                        DropdownButtonFormField<AppUser>(
                          initialValue: selectedProvider,
                          items: providers
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    '${strings.roleLabel(p.role)} - ${p.displayName ?? p.email}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => selectedProvider = value),
                          decoration: InputDecoration(labelText: strings.t('Provider')),
                          validator: (value) =>
                              value == null ? strings.t('Select a provider') : null,
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: typeCtrl,
                        decoration: InputDecoration(labelText: strings.t('Type')),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              strings.dateLabel(_dateOnlyLabel(selectedDate)),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (pickedDate == null) return;
                              if (!context.mounted) return;
                              setState(() {
                                selectedDate = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                );
                                final provider =
                                    user.role == UserRole.nurse ? selectedProvider : user;
                                if (provider != null) {
                                  selectedSlot = _firstAvailableSlot(
                                    selectedDate,
                                    allAppointments,
                                    provider,
                                  );
                                } else {
                                  selectedSlot = null;
                                }
                              });
                            },
                            child: Text(strings.t('Pick')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final provider =
                              user.role == UserRole.nurse ? selectedProvider : user;
                          final slots = provider == null
                              ? const <DateTime>[]
                              : _availableSlots(selectedDate, allAppointments, provider.id);
                          if (selectedSlot != null &&
                              !slots.any((slot) => _sameSlot(slot, selectedSlot!))) {
                            selectedSlot = slots.isNotEmpty ? slots.first : null;
                          }
                          if (slots.isEmpty) {
                            return Text(strings.t('No available slots for this date.'));
                          }
                          return DropdownButtonFormField<DateTime>(
                            initialValue: selectedSlot,
                            items: slots
                                .map(
                                  (slot) => DropdownMenuItem(
                                    value: slot,
                                    child: Text(_timeLabel(slot)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(() => selectedSlot = value),
                            decoration: InputDecoration(labelText: strings.t('Time slot')),
                            validator: (value) =>
                                value == null ? strings.t('Select a time slot') : null,
                          );
                        },
                      ),
                      if (user.role == UserRole.nurse)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: sendReminder,
                          onChanged: (value) =>
                              setState(() => sendReminder = value ?? false),
                          title: Text(strings.t('Send reminder to patient')),
                        ),
                      if (user.role == UserRole.nurse && sendReminder)
                        TextFormField(
                          controller: reminderCtrl,
                          decoration: InputDecoration(
                            labelText: strings.t('Reminder message (optional)'),
                          ),
                          maxLines: 2,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(strings.t('Cancel')),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              if (selectedSlot == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.t('No available slots for this date.'))),
                );
                return;
              }
              final patient = user.role == UserRole.patient ? user : selectedPatient!;
              final provider = user.role == UserRole.nurse
                  ? selectedProvider!
                  : user.role == UserRole.patient
                      ? selectedProvider!
                      : user;
              final appointment = Appointment(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                patientId: patient.id,
                providerId: provider.id,
                dateTime: selectedSlot!,
                type: typeCtrl.text.trim().isEmpty
                    ? strings.t('Nutrition Consultation')
                    : typeCtrl.text.trim(),
                status: 'SCHEDULED',
              );
              await ref.read(appointmentRepositoryProvider).scheduleAppointment(appointment);
              if (user.role == UserRole.nurse && sendReminder) {
                final providerLabel =
                    '${strings.roleLabel(provider.role)} ${provider.displayName ?? provider.email}';
                final message = reminderCtrl.text.trim().isEmpty
                    ? strings.appointmentScheduled(
                        _dateLabel(selectedDate),
                        providerLabel,
                      )
                    : reminderCtrl.text.trim();
                final alert = AlertItem(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  userId: patient.id,
                  message: message,
                  severity: AlertSeverity.low,
                  type: AlertType.appointment,
                  createdAt: DateTime.now(),
                  status: 'SENT',
                );
                await ref.read(alertRepositoryProvider).addAlert(alert);
              }
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
            child: Text(strings.t('Save')),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentListView(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
    AppStrings strings,
    List<AppUser> allUsers,
    List<Appointment> appointments,
    Appointment? nextAppt,
  ) {
    final filtered =
        AppointmentFilterService.filter(appointments, _selectedFilter);
    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final appt = filtered[index];
        final patient = allUsers.firstWhere(
          (u) => u.id == appt.patientId,
          orElse: () => user,
        );
        final provider = allUsers.firstWhere(
          (u) => u.id == appt.providerId,
          orElse: () => user,
        );
        return _EnhancedAppointmentCard(
          appointment: appt,
          title: _title(appt, patient, provider, user, strings),
          isNext: appt == nextAppt,
          actions: _actions(context, ref, user, appt),
        );
      },
    );
  }
}

// ── Status helpers ────────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return AppTheme.success;
    case 'CANCELLED':
      return AppTheme.errorColor;
    case 'CONFIRMED':
      return AppTheme.healthcareTeal;
    default:
      return AppTheme.warning; // SCHEDULED / UPCOMING
  }
}

IconData _statusIcon(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return Icons.check_circle;
    case 'CANCELLED':
      return Icons.cancel;
    case 'CONFIRMED':
      return Icons.event_available;
    default:
      return Icons.schedule;
  }
}

String _statusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return 'Completed';
    case 'CANCELLED':
      return 'Cancelled';
    case 'CONFIRMED':
      return 'Confirmed';
    default:
      return 'Upcoming';
  }
}

// ── Next Appointment Banner ───────────────────────────────────────────────────

class _NextAppointmentBanner extends StatelessWidget {
  const _NextAppointmentBanner({
    required this.appointment,
    required this.providerName,
  });

  final Appointment appointment;
  final String providerName;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('EEE, d MMM yyyy').format(appointment.dateTime);
    final timeLabel = DateFormat('h:mm a').format(appointment.dateTime);
    final daysLeft = appointment.dateTime
        .difference(DateTime.now())
        .inDays;
    final countdown = daysLeft == 0
        ? 'Today'
        : daysLeft == 1
            ? 'Tomorrow'
            : 'In $daysLeft days';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF8BBD0)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withValues(alpha: 30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.event_available,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Appointment',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.darkPink,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.type,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryText,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateLabel · $timeLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                ),
                Text(
                  'with $providerName',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.darkPink.withValues(alpha: 20),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: AppTheme.darkPink.withValues(alpha: 80)),
            ),
            child: Text(
              countdown,
              style: const TextStyle(
                color: AppTheme.darkPink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appointment Filter Bar ────────────────────────────────────────────────────

class _AppointmentFilterBar extends StatelessWidget {
  const _AppointmentFilterBar({
    required this.strings,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final AppStrings strings;
  final AppointmentFilter selectedFilter;
  final ValueChanged<AppointmentFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    const filters = AppointmentFilter.values;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;
          return GestureDetector(
            onTap: () => onFilterChanged(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.darkPink
                    : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.darkPink
                      : const Color(0xFFF8BBD0),
                ),
              ),
              child: Text(
                filter.label,
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : AppTheme.secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Enhanced Appointment Card ─────────────────────────────────────────────────

class _EnhancedAppointmentCard extends StatelessWidget {
  const _EnhancedAppointmentCard({
    required this.appointment,
    required this.title,
    required this.isNext,
    required this.actions,
  });

  final Appointment appointment;
  final String title;
  final bool isNext;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final color  = _statusColor(appointment.status);
    final icon   = _statusIcon(appointment.status);
    final label  = _statusLabel(appointment.status);
    final date   = DateFormat('EEE, d MMM').format(appointment.dateTime);
    final time   = DateFormat('h:mm a').format(appointment.dateTime);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isNext
              ? AppTheme.primaryPink.withValues(alpha: 120)
              : const Color(0xFFF8BBD0),
          width: isNext ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withValues(alpha: isNext ? 20 : 10),
            blurRadius: isNext ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Date column
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('d').format(appointment.dateTime),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                  ),
                  Text(
                    DateFormat('MMM').format(appointment.dateTime),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 18),
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: color.withValues(alpha: 70)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 11, color: color),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.type,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 13, color: AppTheme.secondaryText),
                      const SizedBox(width: 4),
                      Text(
                        '$date · $time',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.secondaryText,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions,
          ],
        ),
      ),
    );
  }
}
