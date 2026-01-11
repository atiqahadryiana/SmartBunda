import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../models/alert_item.dart';
import '../models/app_user.dart';
import '../models/appointment.dart';
import '../models/backup_snapshot.dart';
import '../models/feedback_entry.dart';
import '../models/food_catalog_entry.dart';
import '../models/food_entry.dart';
import '../models/firestore_doc.dart';
import '../models/hydration_entry.dart';
import '../models/nutrition_plan.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';
import '../models/system_settings.dart';
import '../services/service_providers.dart';

final currentUserProvider = Provider<AppUser?>((ref) {
  final auth = ref.watch(authStateProvider);
  final repo = ref.watch(authRepositoryProvider);
  return auth.maybeWhen(data: (user) => user, orElse: () => repo.currentUser);
});

final profileProvider = StreamProvider<Profile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(dataStoreProvider).watchProfile(user.id);
});

final allProfilesProvider = StreamProvider<Map<String, Profile>>((ref) {
  return ref.watch(dataStoreProvider).watchAllProfiles();
});

final pregnancyProvider = StreamProvider<Pregnancy?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(dataStoreProvider).watchPregnancy(user.id);
});

final allPregnanciesProvider = StreamProvider<Map<String, Pregnancy>>((ref) {
  return ref.watch(dataStoreProvider).watchAllPregnancies();
});

final entriesProvider = StreamProvider<List<FoodEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(dataStoreProvider).watchEntries(user.id);
});

final allEntriesProvider = StreamProvider<Map<String, List<FoodEntry>>>((ref) {
  return ref.watch(dataStoreProvider).watchAllEntries();
});

final hydrationEntriesProvider = StreamProvider<List<HydrationEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(dataStoreProvider).watchHydrationEntries(user.id);
});

final feedbackProvider = StreamProvider<List<FeedbackEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(dataStoreProvider).watchFeedback(user.id);
});

final allFeedbackProvider = StreamProvider<List<FeedbackEntry>>((ref) {
  return ref.watch(dataStoreProvider).watchAllFeedback();
});

final activityLogsProvider = StreamProvider<List<ActivityLogEntry>>((ref) {
  return ref.watch(authRepositoryProvider).watchActivityLogs();
});

final appointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(appointmentRepositoryProvider).watchAppointmentsForUser(user.id);
});

final allAppointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  return ref.watch(appointmentRepositoryProvider).watchAllAppointments();
});

final alertsProvider = StreamProvider<List<AlertItem>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(alertRepositoryProvider).watchAlerts(user.id);
});

final allAlertsProvider = StreamProvider<List<AlertItem>>((ref) {
  return ref.watch(alertRepositoryProvider).watchAllAlerts();
});

final plansProvider = StreamProvider<List<NutritionPlan>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(nutritionPlanRepositoryProvider).watchPlans(user.id);
});

final allPlansProvider = StreamProvider<List<NutritionPlan>>((ref) {
  return ref.watch(nutritionPlanRepositoryProvider).watchAllPlans();
});

final foodCatalogProvider = StreamProvider<List<FoodCatalogEntry>>((ref) {
  return ref.watch(foodDatabaseProvider).watchCatalog();
});

final systemSettingsProvider = StreamProvider<SystemSettings>((ref) {
  return ref.watch(systemAdminRepositoryProvider).watchSettings();
});

final backupsProvider = StreamProvider<List<BackupSnapshot>>((ref) {
  return ref.watch(systemAdminRepositoryProvider).watchBackups();
});

final educationContentProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  return ref.watch(contentRepositoryProvider).watchEducationContent();
});

final allEducationContentProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  return ref.watch(contentRepositoryProvider).watchEducationContent(activeOnly: false);
});

final recommendationsProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(contentRepositoryProvider).watchRecommendations(userId: user.id);
});

final allRecommendationsProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  return ref.watch(contentRepositoryProvider).watchRecommendations(activeOnly: false);
});

final notificationsProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(contentRepositoryProvider).watchNotifications(userId: user.id);
});

final allNotificationsProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  return ref.watch(contentRepositoryProvider).watchNotifications(activeOnly: false);
});

final reportsProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(contentRepositoryProvider).watchReports(userId: user.id);
});

final allReportsProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  return ref.watch(contentRepositoryProvider).watchReports();
});
