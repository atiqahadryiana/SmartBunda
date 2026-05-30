import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/models/alert_item.dart';
import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/models/appointment.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/models/firestore_doc.dart';
import 'package:smartbunda/models/system_settings.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/widgets/empty_state.dart';
import 'package:smartbunda/widgets/require_sign_in.dart';
import 'package:smartbunda/widgets/screen_header.dart';

class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({
    super.key,
    required this.role,
    this.showAppBar = false,
  });

  final UserRole role;
  final bool showAppBar;

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  bool _didAutoRefresh = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final user = ref.watch(currentUserProvider);
    final effectiveRole = user?.role ?? widget.role;
    final settingsAsync = ref.watch(systemSettingsProvider);
    return RequireSignIn(
      title: strings.t('Monitoring & alerts'),
      showAppBar: widget.showAppBar,
      message: strings.t('Please sign in to view monitoring alerts.'),
      child: Builder(
        builder: (context) {
          if (user == null) {
            return const SizedBox.shrink();
          }
          if (effectiveRole == UserRole.patient) {
            final entriesAsync = ref.watch(entriesProvider);
            final appointmentsAsync = ref.watch(appointmentsProvider);
            final alertsAsync = ref.watch(alertsProvider);
            final notificationsAsync = ref.watch(notificationsProvider);

            return Scaffold(
              appBar: widget.showAppBar
                  ? AppBar(title: Text(strings.t('Monitoring & alerts')))
                  : null,
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: settingsAsync.when(
                  data: (settings) {
                    final entries = entriesAsync.valueOrNull ?? const <FoodEntry>[];
                    final appointments = appointmentsAsync.valueOrNull ?? const <Appointment>[];
                    if (!_didAutoRefresh && entriesAsync.hasValue) {
                      _didAutoRefresh = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _refreshPatientAlerts(user, entries, appointments, settings, strings);
                      });
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ScreenHeader(
                          title: strings.t('Monitoring'),
                          subtitle: strings.t(
                            'Review alerts and reminders based on your recent logs.',
                          ),
                          icon: Icons.monitor_heart_outlined,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: () =>
                                  _refreshPatientAlerts(user, entries, appointments, settings, strings),
                              icon: const Icon(Icons.refresh),
                              label: Text(strings.t('Refresh')),
                            ),
                            const SizedBox(width: 12),
                            Text(strings.todayWithDate(_todayLabel())),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: alertsAsync.when(
                            data: (alerts) {
                              return notificationsAsync.when(
                                data: (notifications) {
                                  final sortedAlerts = List<AlertItem>.from(alerts)
                                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                                  final sortedNotifications =
                                      List<FirestoreDoc>.from(notifications);
                                  return ListView(
                                    children: [
                                      Text(
                                        strings.t('Alerts'),
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      if (sortedAlerts.isEmpty)
                                        EmptyState(
                                          icon: Icons.notifications_none_outlined,
                                          title: strings.t('No alerts'),
                                          message: strings.t('You are all caught up for now.'),
                                        )
                                      else
                                        ...sortedAlerts.map((alert) {
                                          final isRead = alert.status.toUpperCase() == 'READ';
                                          return Card(
                                            child: ListTile(
                                              leading: Icon(_iconForSeverity(alert.severity)),
                                              title: Text(alert.message),
                                              trailing: isRead
                                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                                  : TextButton(
                                                      onPressed: () => ref
                                                          .read(alertRepositoryProvider)
                                                          .acknowledge(alert.id),
                                                      child: Text(strings.t('Mark read')),
                                                    ),
                                            ),
                                          );
                                        }),
                                      const SizedBox(height: 16),
                                      Text(
                                        strings.t('Notifications'),
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      if (sortedNotifications.isEmpty)
                                        Text(strings.t('No notifications yet.'))
                                      else
                                        ...sortedNotifications.map(
                                          (doc) => Card(
                                            child: ListTile(
                                              leading: const Icon(Icons.notifications_none_outlined),
                                              title: Text(_docTitle(doc)),
                                              subtitle: doc.subtitle != null
                                                  ? Text(doc.subtitle!)
                                                  : null,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (e, _) => Center(child: Text('Error: $e')),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Center(child: Text('Error: $e')),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            );
          }

          final allEntriesAsync = ref.watch(allEntriesProvider);
          final allAppointmentsAsync = ref.watch(allAppointmentsProvider);
          final usersAsync = ref.watch(usersProvider);

          return Scaffold(
            appBar: widget.showAppBar
                ? AppBar(title: Text(strings.t('Monitoring & alerts')))
                : null,
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: settingsAsync.when(
                data: (settings) {
                  final entriesByUser = allEntriesAsync.valueOrNull ?? {};
                  final appointments = allAppointmentsAsync.valueOrNull ?? const <Appointment>[];
                  final users = usersAsync.valueOrNull ?? const <AppUser>[];
                  final patients = users.where((u) => u.role == UserRole.patient).toList();

                  final alertsByPatient = <String, List<AlertItem>>{};
                  for (final patient in patients) {
                    final alerts = _buildAlertsForUser(
                      patient,
                      entriesByUser[patient.id] ?? const <FoodEntry>[],
                      appointments,
                      settings,
                      strings,
                    );
                    if (alerts.isNotEmpty) {
                      alertsByPatient[patient.id] = alerts;
                    }
                  }

                  if (alertsByPatient.isEmpty) {
                    return EmptyState(
                      icon: Icons.notifications_none_outlined,
                      title: strings.t('No critical alerts'),
                      message: strings.t('All patients look stable right now.'),
                    );
                  }

                  return ListView(
                    children: [
                      ScreenHeader(
                        title: strings.t('Monitoring'),
                        subtitle: strings.t('Review alerts for patients who need attention.'),
                        icon: Icons.monitor_heart_outlined,
                      ),
                      const SizedBox(height: 16),
                      ...alertsByPatient.entries.map((entry) {
                        final patient = patients.firstWhere((p) => p.id == entry.key);
                        return Card(
                          child: ExpansionTile(
                            leading: const Icon(Icons.monitor_heart_outlined),
                            title: Text(patient.displayName ?? patient.email),
                            subtitle: Text(strings.notificationsCount(entry.value.length)),
                            children: entry.value
                                .map(
                                  (alert) => ListTile(
                                    leading: Icon(_iconForSeverity(alert.severity)),
                                    title: Text(alert.message),
                                  ),
                                )
                                .toList(),
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
          );
        },
      ),
    );
  }

  void _refreshPatientAlerts(
    AppUser user,
    List<FoodEntry> entries,
    List<Appointment> appointments,
    SystemSettings settings,
    AppStrings strings,
  ) {
    final alerts = _buildAlertsForUser(user, entries, appointments, settings, strings);
    ref.read(alertRepositoryProvider).replaceAlerts(user.id, alerts);
  }

  List<AlertItem> _buildAlertsForUser(
    AppUser user,
    List<FoodEntry> entries,
    List<Appointment> appointments,
    SystemSettings settings,
    AppStrings strings,
  ) {
    final todayEntries = entries.where(_isToday).toList();
    final totals = _totals(todayEntries);
    final alerts = <AlertItem>[];
    final now = DateTime.now();

    if (settings.mealLoggingEnabled &&
        todayEntries.isEmpty &&
        now.hour >= settings.defaultReminderHour) {
      alerts.add(
        AlertItem(
          id: _alertId(user.id, AlertType.reminder, 'meal-${now.day}'),
          userId: user.id,
          message: strings.noMealsLoggedToday,
          severity: AlertSeverity.low,
          type: AlertType.reminder,
          createdAt: now,
          status: 'SENT',
        ),
      );
    }

    if (totals.calories > 0 && totals.calories < settings.caloriesMin) {
      alerts.add(
        AlertItem(
          id: _alertId(user.id, AlertType.deficiencyAlert, 'low-calorie-${now.day}'),
          userId: user.id,
          message: strings.caloriesBelowMinimum(settings.caloriesMin),
          severity: AlertSeverity.medium,
          type: AlertType.deficiencyAlert,
          createdAt: now,
          status: 'SENT',
        ),
      );
    }

    if (totals.calories > settings.caloriesMax) {
      alerts.add(
        AlertItem(
          id: _alertId(user.id, AlertType.deficiencyAlert, 'high-calorie-${now.day}'),
          userId: user.id,
          message: strings.caloriesAboveMaximum(settings.caloriesMax),
          severity: AlertSeverity.medium,
          type: AlertType.deficiencyAlert,
          createdAt: now,
          status: 'SENT',
        ),
      );
    }

    if (totals.protein > 0 && totals.protein < settings.proteinGMin) {
      alerts.add(
        AlertItem(
          id: _alertId(user.id, AlertType.deficiencyAlert, 'low-protein-${now.day}'),
          userId: user.id,
          message: strings.proteinBelowTarget(settings.proteinGMin),
          severity: AlertSeverity.medium,
          type: AlertType.deficiencyAlert,
          createdAt: now,
          status: 'SENT',
        ),
      );
    }

    if (totals.ironMg > 0 && totals.ironMg < settings.ironMgMin) {
      alerts.add(
        AlertItem(
          id: _alertId(user.id, AlertType.deficiencyAlert, 'low-iron-${now.day}'),
          userId: user.id,
          message: strings.ironBelowTarget(settings.ironMgMin),
          severity: AlertSeverity.medium,
          type: AlertType.deficiencyAlert,
          createdAt: now,
          status: 'SENT',
        ),
      );
    }

    if (totals.folateMcg > 0 && totals.folateMcg < settings.folateMcgMin) {
      alerts.add(
        AlertItem(
          id: _alertId(user.id, AlertType.deficiencyAlert, 'low-folate-${now.day}'),
          userId: user.id,
          message: strings.folateBelowTarget(settings.folateMcgMin),
          severity: AlertSeverity.medium,
          type: AlertType.deficiencyAlert,
          createdAt: now,
          status: 'SENT',
        ),
      );
    }

    final upcoming = appointments.where((appt) {
      if (appt.patientId != user.id && appt.providerId != user.id) return false;
      if (appt.status.toUpperCase() != 'SCHEDULED') return false;
      final diff = appt.dateTime.difference(now);
      return diff.inHours >= 0 && diff.inHours <= 24;
    }).toList();

    for (final appt in upcoming) {
      alerts.add(
        AlertItem(
          id: _alertId(user.id, AlertType.appointment, appt.id),
          userId: user.id,
          message: strings.upcomingAppointment(
            '${appt.dateTime.month}/${appt.dateTime.day}',
            _timeLabel(appt.dateTime),
          ),
          severity: AlertSeverity.low,
          type: AlertType.appointment,
          createdAt: now,
          status: 'SENT',
        ),
      );
    }

    return alerts;
  }

  bool _isToday(FoodEntry entry) {
    final now = DateTime.now();
    return entry.date.year == now.year &&
        entry.date.month == now.month &&
        entry.date.day == now.day;
  }

  _Totals _totals(List<FoodEntry> entries) {
    var calories = 0;
    var protein = 0;
    double iron = 0;
    double folate = 0;
    for (final entry in entries) {
      calories += entry.calories;
      protein += entry.protein;
      iron += entry.ironMg;
      folate += entry.folateMcg;
    }
    return _Totals(
      calories: calories,
      protein: protein,
      ironMg: iron,
      folateMcg: folate,
    );
  }

  String _alertId(String userId, AlertType type, String key) {
    return '$userId-${type.name}-$key';
  }

  IconData _iconForSeverity(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Icons.info_outline;
      case AlertSeverity.medium:
        return Icons.warning_amber_outlined;
      case AlertSeverity.high:
        return Icons.error_outline;
    }
  }

  String _timeLabel(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _todayLabel() {
    final now = DateTime.now();
    return '${now.month}/${now.day}';
  }

  String _docTitle(FirestoreDoc doc) {
    final data = doc.data;
    final text = _stringOrNull(data['title']) ??
        _stringOrNull(data['message']) ??
        _stringOrNull(data['name']) ??
        doc.title ??
        doc.id;
    return text;
  }

  String? _stringOrNull(dynamic raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _Totals {
  _Totals({
    required this.calories,
    required this.protein,
    required this.ironMg,
    required this.folateMcg,
  });

  final int calories;
  final int protein;
  final double ironMg;
  final double folateMcg;
}
