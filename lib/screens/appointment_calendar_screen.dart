/// SmartBunda — Appointment Calendar Screen
///
/// Displays appointments in calendar view with monthly/weekly toggle
/// and appointment selection functionality.
library smartbunda.appointment_calendar_screen;

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:smartbunda/models/appointment.dart';
import 'package:smartbunda/services/appointment_filter_service.dart';
import 'package:smartbunda/theme/app_theme.dart';

class AppointmentCalendarScreen extends StatefulWidget {
  const AppointmentCalendarScreen({
    super.key,
    required this.appointments,
  });

  final List<Appointment> appointments;

  @override
  State<AppointmentCalendarScreen> createState() =>
      _AppointmentCalendarScreenState();
}

class _AppointmentCalendarScreenState extends State<AppointmentCalendarScreen> {
  late DateTime _selectedDate;
  late PageController _pageController;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Appointment> _getAppointmentsForDate(DateTime date) {
    return AppointmentFilterService.getForDate(widget.appointments, date);
  }


  @override
  Widget build(BuildContext context) {
    final appointmentsForSelectedDate = _getAppointmentsForDate(_selectedDate);

    return Column(
      children: [
        // ── Calendar View ──────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceElevated,
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFF8BBD0),
              ),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: TableCalendar<Appointment>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDate,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getAppointmentsForDate,
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0xFFF8BBD0)),
                ),
              ),
              formatButtonTextStyle: TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppTheme.darkPink,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              todayDecoration: BoxDecoration(
                color: Color(0xFFEC407A),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppTheme.primaryPink,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              defaultTextStyle: TextStyle(
                color: AppTheme.primaryText,
              ),
              weekendTextStyle: TextStyle(
                color: AppTheme.secondaryText,
              ),
              outsideTextStyle: TextStyle(
                color: AppTheme.disabledText,
              ),
              cellMargin: EdgeInsets.all(6),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekendStyle: TextStyle(color: AppTheme.secondaryText),
              weekdayStyle: TextStyle(color: AppTheme.primaryText),
            ),
          ),
        ),

        // ── Appointments for Selected Date ──────────────────────────────────
        Expanded(
          child: appointmentsForSelectedDate.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: AppTheme.secondaryText.withValues(alpha: 180),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No appointments',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No appointments scheduled for this date',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.secondaryText,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: appointmentsForSelectedDate.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final appointment = appointmentsForSelectedDate[index];
                    return _AppointmentDateCard(appointment: appointment);
                  },
                ),
        ),
      ],
    );
  }
}

// ── Appointment Card for Calendar Date ────────────────────────────────────────

class _AppointmentDateCard extends StatelessWidget {
  const _AppointmentDateCard({required this.appointment});

  final Appointment appointment;

  Color get _statusColor {
    switch (appointment.status) {
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.errorColor;
      case 'scheduled':
      default:
        return AppTheme.info;
    }
  }

  String get _statusLabel {
    switch (appointment.status) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'scheduled':
      default:
        return 'Scheduled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(appointment.dateTime);
    final statusColor = _statusColor;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8BBD0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_available_outlined,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.type,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.providerId,
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
                    color: statusColor.withValues(alpha: 20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 60)),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: AppTheme.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
