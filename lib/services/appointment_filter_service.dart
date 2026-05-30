/// SmartBunda — Appointment Filter Service
///
/// Filtering logic for the healthcare-professional dashboard. Supports
/// appointment status, session slot (morning/afternoon/evening derived from the
/// appointment hour), and appointment type. Status comparisons are
/// case-insensitive so persisted values such as `SCHEDULED` match.
library smartbunda.appointment_filter_service;

import '../models/appointment.dart';

// ── Legacy simple filter (patient appointments screen) ────────────────────────

/// Coarse filter used by the patient-facing appointments list.
enum AppointmentFilter { all, upcoming, completed, cancelled }

extension AppointmentFilterLabel on AppointmentFilter {
  String get label {
    switch (this) {
      case AppointmentFilter.all:
        return 'All';
      case AppointmentFilter.upcoming:
        return 'Upcoming';
      case AppointmentFilter.completed:
        return 'Completed';
      case AppointmentFilter.cancelled:
        return 'Cancelled';
    }
  }
}

// ── Status filter ─────────────────────────────────────────────────────────────

enum AppointmentStatusFilter {
  all,
  scheduled,
  confirmed,
  completed,
  cancelled,
  noShow,
}

extension AppointmentStatusFilterLabel on AppointmentStatusFilter {
  String get label {
    switch (this) {
      case AppointmentStatusFilter.all:
        return 'All';
      case AppointmentStatusFilter.scheduled:
        return 'Scheduled';
      case AppointmentStatusFilter.confirmed:
        return 'Confirmed';
      case AppointmentStatusFilter.completed:
        return 'Completed';
      case AppointmentStatusFilter.cancelled:
        return 'Cancelled';
      case AppointmentStatusFilter.noShow:
        return 'No Show';
    }
  }

  /// The normalized status token this filter matches (lowercase, no spaces).
  String? get statusToken {
    switch (this) {
      case AppointmentStatusFilter.all:
        return null;
      case AppointmentStatusFilter.scheduled:
        return 'scheduled';
      case AppointmentStatusFilter.confirmed:
        return 'confirmed';
      case AppointmentStatusFilter.completed:
        return 'completed';
      case AppointmentStatusFilter.cancelled:
        return 'cancelled';
      case AppointmentStatusFilter.noShow:
        return 'noshow';
    }
  }
}

// ── Session slot filter ───────────────────────────────────────────────────────

enum SessionSlotFilter { all, morning, afternoon, evening }

extension SessionSlotFilterLabel on SessionSlotFilter {
  String get label {
    switch (this) {
      case SessionSlotFilter.all:
        return 'All slots';
      case SessionSlotFilter.morning:
        return 'Morning';
      case SessionSlotFilter.afternoon:
        return 'Afternoon';
      case SessionSlotFilter.evening:
        return 'Evening';
    }
  }
}

/// Session slot for a given hour: morning (<12), afternoon (12–16), evening (≥17).
SessionSlotFilter slotForHour(int hour) {
  if (hour < 12) return SessionSlotFilter.morning;
  if (hour < 17) return SessionSlotFilter.afternoon;
  return SessionSlotFilter.evening;
}

// ── Appointment type filter ───────────────────────────────────────────────────

enum AppointmentTypeFilter {
  all,
  consultation,
  followUp,
  nutritionReview,
  prePregnancyAssessment,
  pregnancyMonitoring,
}

extension AppointmentTypeFilterLabel on AppointmentTypeFilter {
  String get label {
    switch (this) {
      case AppointmentTypeFilter.all:
        return 'All types';
      case AppointmentTypeFilter.consultation:
        return 'Consultation';
      case AppointmentTypeFilter.followUp:
        return 'Follow Up';
      case AppointmentTypeFilter.nutritionReview:
        return 'Nutrition Review';
      case AppointmentTypeFilter.prePregnancyAssessment:
        return 'Pre-Pregnancy Assessment';
      case AppointmentTypeFilter.pregnancyMonitoring:
        return 'Pregnancy Monitoring';
    }
  }

  /// Normalized substring this filter matches against `appointment.type`.
  String? get typeToken {
    switch (this) {
      case AppointmentTypeFilter.all:
        return null;
      case AppointmentTypeFilter.consultation:
        return 'consultation';
      case AppointmentTypeFilter.followUp:
        return 'follow';
      case AppointmentTypeFilter.nutritionReview:
        return 'nutrition';
      case AppointmentTypeFilter.prePregnancyAssessment:
        return 'pre-pregnancy';
      case AppointmentTypeFilter.pregnancyMonitoring:
        return 'monitoring';
    }
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class AppointmentFilterService {
  static String _norm(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s_]'), '');

  /// Legacy coarse filter (patient appointments screen). Case-insensitive.
  static List<Appointment> filter(
    List<Appointment> appointments,
    AppointmentFilter filterType,
  ) {
    if (filterType == AppointmentFilter.all) return appointments;
    return appointments.where((appt) {
      final status = _norm(appt.status);
      switch (filterType) {
        case AppointmentFilter.upcoming:
          return status == 'scheduled' || status == 'confirmed';
        case AppointmentFilter.completed:
          return status == 'completed';
        case AppointmentFilter.cancelled:
          return status == 'cancelled';
        case AppointmentFilter.all:
          return true;
      }
    }).toList();
  }

  static bool matchesStatus(Appointment appt, AppointmentStatusFilter filter) {
    final token = filter.statusToken;
    if (token == null) return true;
    return _norm(appt.status) == token;
  }

  static bool matchesSlot(Appointment appt, SessionSlotFilter filter) {
    if (filter == SessionSlotFilter.all) return true;
    return slotForHour(appt.dateTime.hour) == filter;
  }

  static bool matchesType(Appointment appt, AppointmentTypeFilter filter) {
    final token = filter.typeToken;
    if (token == null) return true;
    return appt.type.toLowerCase().contains(token);
  }

  /// Apply status, slot, and type filters together. When [date] is supplied,
  /// only appointments on that calendar day are kept.
  static List<Appointment> applyFilters(
    List<Appointment> appointments, {
    AppointmentStatusFilter status = AppointmentStatusFilter.all,
    SessionSlotFilter slot = SessionSlotFilter.all,
    AppointmentTypeFilter type = AppointmentTypeFilter.all,
    DateTime? date,
  }) {
    return appointments.where((appt) {
      if (date != null && !_sameDay(appt.dateTime, date)) return false;
      return matchesStatus(appt, status) &&
          matchesSlot(appt, slot) &&
          matchesType(appt, type);
    }).toList();
  }

  /// Get appointments for a specific date (calendar day).
  static List<Appointment> getForDate(
    List<Appointment> appointments,
    DateTime date,
  ) {
    return appointments.where((appt) => _sameDay(appt.dateTime, date)).toList();
  }

  /// Get upcoming appointments (scheduled, in the future).
  static List<Appointment> getUpcoming(List<Appointment> appointments) {
    final now = DateTime.now();
    return appointments
        .where((appt) =>
            appt.dateTime.isAfter(now) && _norm(appt.status) == 'scheduled')
        .toList();
  }

  /// Get the next appointment (earliest upcoming one).
  static Appointment? getNext(List<Appointment> appointments) {
    final upcoming = getUpcoming(appointments);
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.first;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
