import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/widgets/empty_state.dart';
import 'package:smartbunda/widgets/require_sign_in.dart';
import 'package:smartbunda/widgets/screen_header.dart';

class NurseOverviewScreen extends ConsumerStatefulWidget {
  const NurseOverviewScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  ConsumerState<NurseOverviewScreen> createState() => _NurseOverviewScreenState();
}

class _NurseOverviewScreenState extends ConsumerState<NurseOverviewScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(allAppointmentsProvider);
    final usersAsync = ref.watch(usersProvider);

    return RequireSignIn(
      title: 'Overview',
      showAppBar: widget.showAppBar,
      message: 'Please sign in to view appointments.',
      child: Scaffold(
        appBar: widget.showAppBar ? AppBar(title: const Text('Overview')) : null,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: appointmentsAsync.when(
            data: (appointments) {
              final users = usersAsync.valueOrNull ?? const <AppUser>[];
              final userById = {for (final u in users) u.id: u};
              final todayAppointments = appointments
                  .where((appt) => _isSameDay(appt.dateTime, _selectedDate))
                  .toList()
                ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

              return ListView(
                children: [
                  const ScreenHeader(
                    title: 'Overview',
                    subtitle: 'Appointments scheduled for the selected date.',
                    icon: Icons.dashboard_outlined,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Date: ${_dateLabel(_selectedDate)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked == null) return;
                          setState(() => _selectedDate = picked);
                        },
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: const Text('Pick date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (todayAppointments.isEmpty)
                    const EmptyState(
                      icon: Icons.event_busy,
                      title: 'No appointments',
                      message: 'No patient appointments scheduled for this date.',
                    )
                  else
                    ...todayAppointments.map((appt) {
                      final patient = userById[appt.patientId];
                      final provider = userById[appt.providerId];
                      final patientName =
                          patient?.displayName ?? patient?.email ?? appt.patientId;
                      final providerName =
                          provider?.displayName ?? provider?.email ?? appt.providerId;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.event_available),
                          title: Text(patientName),
                          subtitle: Text(
                            '${_timeLabel(appt.dateTime)} | ${provider?.role.label ?? 'Provider'} $providerName',
                          ),
                          trailing: Text(appt.status),
                        ),
                      );
                    }),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateLabel(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  String _timeLabel(DateTime date) => DateFormat('HH:mm').format(date);
}
