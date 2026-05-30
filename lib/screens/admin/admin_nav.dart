/// SmartBunda — Admin Dashboard navigation model
///
/// Defines the grouped information architecture for the admin console sidebar.
/// Sections are addressed by a stable string [AdminSection] id so the shell and
/// the section dispatch stay decoupled from list ordering.
library smartbunda.admin_nav;

import 'package:flutter/material.dart';

/// Stable identifiers for every admin section.
enum AdminSection {
  overview,
  // User management
  patients,
  professionals,
  administrators,
  // Appointment management
  appointmentList,
  appointmentCalendar,
  // Assessment management
  assessmentList,
  riskAssessments,
  assessmentReports,
  // Consultation management
  consultationRecords,
  consultationNotes,
  // Nutrition management
  nutritionRecords,
  foodDatabase,
  // Reports
  medicalReports,
  generatedReports,
  // Analytics
  systemAnalytics,
  userAnalytics,
  // Settings
  systemSettings,
  profileSettings,
}

class AdminNavItem {
  const AdminNavItem(this.id, this.label, this.icon);

  final AdminSection id;
  final String label;
  final IconData icon;
}

class AdminNavGroup {
  const AdminNavGroup(this.title, this.icon, this.items);

  final String title;
  final IconData icon;
  final List<AdminNavItem> items;
}

/// The full grouped sidebar structure.
const List<AdminNavGroup> adminNavGroups = [
  AdminNavGroup('Dashboard', Icons.dashboard_outlined, [
    AdminNavItem(AdminSection.overview, 'Overview', Icons.space_dashboard_outlined),
  ]),
  AdminNavGroup('User Management', Icons.group_outlined, [
    AdminNavItem(AdminSection.patients, 'Patients', Icons.groups_2_outlined),
    AdminNavItem(AdminSection.professionals, 'Healthcare Professionals',
        Icons.medical_services_outlined),
    AdminNavItem(AdminSection.administrators, 'Administrators',
        Icons.admin_panel_settings_outlined),
  ]),
  AdminNavGroup('Appointment Management', Icons.event_outlined, [
    AdminNavItem(AdminSection.appointmentList, 'Appointment List',
        Icons.list_alt_outlined),
    AdminNavItem(AdminSection.appointmentCalendar, 'Appointment Calendar',
        Icons.calendar_month_outlined),
  ]),
  AdminNavGroup('Assessment Management', Icons.assignment_outlined, [
    AdminNavItem(AdminSection.assessmentList, 'Digital First Assessment',
        Icons.fact_check_outlined),
    AdminNavItem(AdminSection.riskAssessments, 'Risk Assessments',
        Icons.health_and_safety_outlined),
    AdminNavItem(AdminSection.assessmentReports, 'Assessment Reports',
        Icons.summarize_outlined),
  ]),
  AdminNavGroup('Consultation Management', Icons.forum_outlined, [
    AdminNavItem(AdminSection.consultationRecords, 'Consultation Records',
        Icons.medical_information_outlined),
    AdminNavItem(AdminSection.consultationNotes, 'Consultation Notes',
        Icons.note_alt_outlined),
  ]),
  AdminNavGroup('Nutrition Management', Icons.restaurant_outlined, [
    AdminNavItem(AdminSection.nutritionRecords, 'Nutrition Records',
        Icons.set_meal_outlined),
    AdminNavItem(AdminSection.foodDatabase, 'Food Database',
        Icons.menu_book_outlined),
  ]),
  AdminNavGroup('Reports', Icons.description_outlined, [
    AdminNavItem(AdminSection.medicalReports, 'Medical Reports',
        Icons.folder_shared_outlined),
    AdminNavItem(AdminSection.generatedReports, 'Generated Reports',
        Icons.picture_as_pdf_outlined),
  ]),
  AdminNavGroup('Analytics', Icons.insights_outlined, [
    AdminNavItem(AdminSection.systemAnalytics, 'System Analytics',
        Icons.query_stats_outlined),
    AdminNavItem(AdminSection.userAnalytics, 'User Analytics',
        Icons.people_outline),
  ]),
  AdminNavGroup('Settings', Icons.settings_outlined, [
    AdminNavItem(AdminSection.systemSettings, 'System Settings',
        Icons.tune_outlined),
    AdminNavItem(AdminSection.profileSettings, 'Profile Settings',
        Icons.account_circle_outlined),
  ]),
];

/// Flattened item lookup (used by the mobile nav + page titles).
AdminNavItem adminItemFor(AdminSection section) {
  for (final group in adminNavGroups) {
    for (final item in group.items) {
      if (item.id == section) return item;
    }
  }
  return adminNavGroups.first.items.first;
}
