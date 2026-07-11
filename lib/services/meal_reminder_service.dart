/// SmartBunda — meal-log reminder notifications.
///
/// Schedules three repeating daily local notifications (breakfast 08:00,
/// lunch 13:00, dinner 20:00) nudging pregnant mothers to log their nutrition.
/// The notifications appear in the phone's notification bar even when the app
/// is closed, via the OS scheduler.
///
/// Because the schedule fires while the app may be closed (so no Dart "did they
/// log it?" check can run at fire time), suppression is reconciled whenever the
/// app is opened: [reconcileForToday] cancels today's pending reminder for any
/// meal slot that has already been logged, then the daily schedule resumes the
/// next day. Mobile-only — a no-op on web.
library smartbunda.meal_reminder_service;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// One meal slot that gets a daily reminder.
class _MealSlot {
  const _MealSlot({
    required this.id,
    required this.mealType,
    required this.hour,
    required this.title,
    required this.body,
  });

  /// Stable notification id (also used to cancel a single slot).
  final int id;

  /// Matches [FoodEntry.mealType] so we can tell if this slot was logged.
  final String mealType;
  final int hour;
  final String title;
  final String body;
}

class MealReminderService {
  MealReminderService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _channelId = 'meal_log_reminders';
  static const String _channelName = 'Meal log reminders';
  static const String _channelDescription =
      'Reminders to log your meals if you have not yet today.';

  static const List<_MealSlot> _slots = [
    _MealSlot(
      id: 8001,
      mealType: 'breakfast',
      hour: 8,
      title: 'Log your breakfast 🍳',
      body: "Don't forget to record what you ate this morning.",
    ),
    _MealSlot(
      id: 8002,
      mealType: 'lunch',
      hour: 13,
      title: 'Log your lunch 🥗',
      body: 'Keep your nutrition on track — add your lunch.',
    ),
    _MealSlot(
      id: 8003,
      mealType: 'dinner',
      hour: 20,
      title: 'Log your dinner 🍽️',
      body: "Round off your day — log tonight's meal.",
    ),
  ];

  /// Initialises the plugin, timezone data, and requests notification
  /// permission. Safe to call multiple times.
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    tz.initializeTimeZones();

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Runtime permission (Android 13+ / iOS).
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  /// (Re)schedules the three daily reminders. Each fires every day at its slot
  /// time and repeats.
  Future<void> scheduleDailyReminders() async {
    if (kIsWeb) return;
    await initialize();
    for (final slot in _slots) {
      await _scheduleSlot(slot);
    }
  }

  /// Cancels today's pending reminder for any meal slot already logged today,
  /// so a mother who has logged breakfast doesn't get nagged about it. The
  /// reminder is re-scheduled for tomorrow by [scheduleDailyReminders] / the
  /// next app open. [loggedMealTypesToday] is the set of `mealType` strings
  /// already logged for the current day.
  Future<void> reconcileForToday(Set<String> loggedMealTypesToday) async {
    if (kIsWeb) return;
    await initialize();
    for (final slot in _slots) {
      // If this slot is already logged today, push its next fire to tomorrow
      // so the mother isn't nagged about a meal she's recorded. Otherwise keep
      // the normal daily schedule (next fire today if still ahead).
      final logged = loggedMealTypesToday.contains(slot.mealType);
      await _scheduleSlot(slot, skipToday: logged);
    }
  }

  /// Cancels all meal reminders (e.g. on logout or if the user disables them).
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    for (final slot in _slots) {
      await _plugin.cancel(slot.id);
    }
  }

  Future<void> _scheduleSlot(_MealSlot slot, {bool skipToday = false}) async {
    final when = _nextInstanceOfHour(slot.hour, skipToday: skipToday);
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      slot.id,
      slot.title,
      slot.body,
      when,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Repeat every day at the same wall-clock time.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// The next [tz.TZDateTime] at [hour]:00 local time. When [skipToday] is set
  /// (the slot is already logged today) the first fire is pushed to tomorrow.
  tz.TZDateTime _nextInstanceOfHour(int hour, {bool skipToday = false}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (skipToday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
