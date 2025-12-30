import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        appBar: showAppBar ? AppBar(title: const Text('Appointments')) : null,
        body: const Center(child: Text('Please sign in.')),
      );
    }

    final appointmentsAsync = role == UserRole.patient
        ? ref.watch(appointmentsProvider)
        : ref.watch(allAppointmentsProvider);
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Appointments')) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'Appointments',
              subtitle: 'Schedule and track upcoming clinic visits.',
              icon: Icons.event_available,
              action: FilledButton.icon(
                onPressed: () => _showCreateDialog(context, ref, user),
                icon: const Icon(Icons.add),
                label: const Text('New'),
              ),
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
                      title: 'No appointments scheduled',
                      message: 'Create a new appointment to reserve a time slot.',
                      action: FilledButton.icon(
                        onPressed: () => _showCreateDialog(context, ref, user),
                        icon: const Icon(Icons.add),
                        label: const Text('Schedule appointment'),
                      ),
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
                          title: Text(_title(appt, patient, provider, user)),
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
    if (user.role == UserRole.admin) return items;
    return items
        .where((appt) => appt.patientId == user.id || appt.providerId == user.id)
        .toList();
  }

  Widget _actions(BuildContext context, WidgetRef ref, AppUser user, Appointment appt) {
    if (user.role == UserRole.patient) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'complete') {
          await ref.read(appointmentRepositoryProvider).completeAppointment(appt.id);
        } else if (value == 'cancel') {
          await ref.read(appointmentRepositoryProvider).cancelAppointment(appt.id);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'complete', child: Text('Mark complete')),
        PopupMenuItem(value: 'cancel', child: Text('Cancel')),
      ],
    );
  }

  String _title(Appointment appt, AppUser patient, AppUser provider, AppUser user) {
    if (user.role == UserRole.patient) {
      return '${provider.role.label} with ${provider.displayName ?? provider.email}';
    }
    return 'Patient: ${patient.displayName ?? patient.email}';
  }

  String _dateLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.month}/${date.day} $hour:$minute';
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final users = ref.read(usersProvider).valueOrNull ?? const <AppUser>[];
    final patients = users.where((u) => u.role == UserRole.patient).toList();
    final providers = users
        .where((u) =>
            u.role == UserRole.doctor ||
            u.role == UserRole.nurse ||
            u.role == UserRole.dietitian)
        .toList();
    if (user.role != UserRole.patient && patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patients available yet.')),
      );
      return;
    }
    if (user.role == UserRole.patient && providers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No providers available yet.')),
      );
      return;
    }

    AppUser? selectedPatient = user.role == UserRole.patient ? user : patients.first;
    AppUser? selectedProvider = user.role == UserRole.patient ? providers.first : user;
    final typeCtrl = TextEditingController(text: 'Nutrition Consultation');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule appointment'),
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
                          decoration: const InputDecoration(labelText: 'Patient'),
                          validator: (value) => value == null ? 'Select a patient' : null,
                        ),
                      if (user.role == UserRole.patient)
                        DropdownButtonFormField<AppUser>(
                          initialValue: selectedProvider,
                          items: providers
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text('${p.role.label} - ${p.displayName ?? p.email}'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => selectedProvider = value),
                          decoration: const InputDecoration(labelText: 'Provider'),
                          validator: (value) => value == null ? 'Select a provider' : null,
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: typeCtrl,
                        decoration: const InputDecoration(labelText: 'Type'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Date: ${_dateLabel(selectedDate)}'),
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
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(selectedDate),
                              );
                              if (pickedTime == null) return;
                              if (!context.mounted) return;
                              setState(() {
                                selectedDate = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            },
                            child: const Text('Pick'),
                          ),
                        ],
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final patient = user.role == UserRole.patient ? user : selectedPatient!;
              final provider = user.role == UserRole.patient ? selectedProvider! : user;
              final appointment = Appointment(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                patientId: patient.id,
                providerId: provider.id,
                dateTime: selectedDate,
                type: typeCtrl.text.trim().isEmpty
                    ? 'Nutrition Consultation'
                    : typeCtrl.text.trim(),
                status: 'SCHEDULED',
              );
              await ref.read(appointmentRepositoryProvider).scheduleAppointment(appointment);
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}


