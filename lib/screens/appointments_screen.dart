import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../models/alert_item.dart';
import '../models/appointment.dart';
import '../models/app_user.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/screen_header.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({
    super.key,
    required this.role,
    this.showAppBar = false,
  });

  final UserRole role;
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
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
                  return ListView.separated(
                    itemCount: relevant.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final appt = relevant[index];
                      final patient =
                          allUsers.firstWhere((u) => u.id == appt.patientId, orElse: () => user);
                      final provider = allUsers.firstWhere(
                        (u) => u.id == appt.providerId,
                        orElse: () => user,
                      );
                      return Card(
                        child: ListTile(
                          title: Text(_title(appt, patient, provider, user, strings)),
                          subtitle: Text(
                            '${appt.type} | ${_dateLabel(appt.dateTime)} | ${appt.status}',
                          ),
                          trailing: _actions(context, ref, user, appt),
                        ),
                      );
                    },
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
}
