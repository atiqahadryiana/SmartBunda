/// SmartBunda — Appointment Filter Service
///
/// Provides filtering logic for appointments by status.
library smartbunda.appointment_filter_service;

import '../models/appointment.dart';

/// Filter type for appointments.
enum AppointmentFilter {
  all,
  upcoming,
  completed,
  cancelled,
}

/// Extension to convert filter to label.
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

/// Filters appointments by status.
class AppointmentFilterService {
  static List<Appointment> filter(
    List<Appointment> appointments,
    AppointmentFilter filterType,
  ) {
    if (filterType == AppointmentFilter.all) {
      return appointments;
    }

    return appointments.where((appt) {
      switch (filterType) {
        case AppointmentFilter.upcoming:
          return appt.status == 'scheduled';
        case AppointmentFilter.completed:
          return appt.status == 'completed';
        case AppointmentFilter.cancelled:
          return appt.status == 'cancelled';
        case AppointmentFilter.all:
          return true;
      }
    }).toList();
  }

  /// Get appointments for a specific date.
  static List<Appointment> getForDate(
    List<Appointment> appointments,
    DateTime date,
  ) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return appointments.where((appt) {
      final apptDateOnly = DateTime(
        appt.dateTime.year,
        appt.dateTime.month,
        appt.dateTime.day,
      );
      return apptDateOnly == dateOnly;
    }).toList();
  }

  /// Get upcoming appointments (scheduled status).
  static List<Appointment> getUpcoming(List<Appointment> appointments) {
    return appointments.where((appt) {
      return appt.dateTime.isAfter(DateTime.now()) &&
          appt.status == 'scheduled';
    }).toList();
  }

  /// Get next appointment (the earliest upcoming one).
  static Appointment? getNext(List<Appointment> appointments) {
    final upcoming = getUpcoming(appointments);
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.first;
  }
}
