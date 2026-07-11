import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/activity_log.dart';
import 'package:smartbunda/models/alert_item.dart';
import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/models/appointment.dart';
import 'package:smartbunda/models/assessment_result.dart';
import 'package:smartbunda/models/appointment_vitals.dart';
import 'package:smartbunda/models/clinical_note.dart';
import 'package:smartbunda/models/nutrition_guideline.dart';
import 'package:smartbunda/services/food_recommendation_engine.dart';
import 'package:smartbunda/models/backup_snapshot.dart';
import 'package:smartbunda/models/feedback_entry.dart';
import 'package:smartbunda/models/food_catalog_entry.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/models/food_history_entry.dart';
import 'package:smartbunda/models/firestore_doc.dart';
import 'package:smartbunda/models/hydration_entry.dart';
import 'package:smartbunda/models/nutrition_plan.dart';
import 'package:smartbunda/models/pregnancy.dart';
import 'package:smartbunda/models/profile.dart';
import 'package:smartbunda/models/system_settings.dart';
import 'package:smartbunda/services/auth_repository.dart';
import 'package:smartbunda/services/service_providers.dart';

final currentUserProvider = Provider<AppUser?>((ref) {
  final auth = ref.watch(authStateProvider);
  final repo = ref.watch(authRepositoryProvider);
  return auth.maybeWhen(
    data: (user) => user ?? repo.currentUser,
    orElse: () => repo.currentUser,
  );
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

final foodHistoryProvider = StreamProvider<List<FoodHistoryEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(foodHistoryRepositoryProvider).watchHistory(user.id);
});

final allEntriesProvider = StreamProvider<Map<String, List<FoodEntry>>>((ref) {
  return ref.watch(dataStoreProvider).watchAllEntries();
});

final assessmentResultsProvider =
    StreamProvider<List<AssessmentResult>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref
      .watch(assessmentResultRepositoryProvider)
      .watchForPatient(user.id);
});

/// Clinical notes authored by healthcare professionals for the current
/// patient — surfaced read-only in their Medical Records.
final clinicalNotesProvider = StreamProvider<List<ClinicalNote>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(clinicalNoteRepositoryProvider).watchForPatient(user.id);
});

/// Clinical notes for a specific patient — for the staff authoring/review view.
final patientClinicalNotesProvider =
    StreamProvider.family<List<ClinicalNote>, String>((ref, patientId) {
  return ref.watch(clinicalNoteRepositoryProvider).watchForPatient(patientId);
});

/// ALL patients' assessment results — admin dashboard only.
final allAssessmentResultsProvider =
    StreamProvider<List<AssessmentResult>>((ref) {
  return ref.watch(assessmentResultRepositoryProvider).watchAll();
});

/// ALL patients' clinical notes / consultations — admin dashboard only.
final allClinicalNotesProvider = StreamProvider<List<ClinicalNote>>((ref) {
  return ref.watch(clinicalNoteRepositoryProvider).watchAll();
});

/// Per-appointment vitals (weight, Hb, BP, …) for a specific patient — newest
/// first. Used in the staff client view to show the visit-by-visit trend.
final patientVitalsProvider =
    StreamProvider.family<List<AppointmentVitals>, String>((ref, patientId) {
  return ref
      .watch(appointmentVitalsRepositoryProvider)
      .watchForPatient(patientId);
});

/// The active nutrition guideline (highest-priority recommendation source).
///
/// Reads the admin-activated guideline from Firestore; falls back to the
/// built-in MOH maternal default when none is active or while loading.
final activeGuidelineProvider = Provider<NutritionGuideline>((ref) {
  return ref.watch(_activeGuidelineStreamProvider).valueOrNull ??
      NutritionGuideline.maternalDefault;
});

final _activeGuidelineStreamProvider =
    StreamProvider<NutritionGuideline?>((ref) {
  return ref.watch(nutritionGuidelineRepositoryProvider).watchActive();
});

/// Rotation seed for "Generate another recommendation" — bump to vary the pick
/// among the safe top matches without losing compliance.
final recommendationSeedProvider = StateProvider<int>((ref) => 0);

/// Today's meals only (used for nutrient-gap analysis).
final todaysMealsProvider = Provider<List<FoodEntry>>((ref) {
  final all = ref.watch(entriesProvider).valueOrNull ?? const <FoodEntry>[];
  final now = DateTime.now();
  return all
      .where((e) =>
          e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day)
      .toList();
});

/// The current AI food recommendation, assembled from every priority source.
/// Null when the engine finds no safe candidate.
final foodRecommendationProvider = Provider<FoodRecommendation?>((ref) {
  final engine = ref.watch(foodRecommendationEngineProvider);
  final guideline = ref.watch(activeGuidelineProvider);
  final profile = ref.watch(profileProvider).valueOrNull;
  final pregnancy = ref.watch(pregnancyProvider).valueOrNull;
  final assessments =
      ref.watch(assessmentResultsProvider).valueOrNull ?? const [];
  final meals = ref.watch(todaysMealsProvider);
  final seed = ref.watch(recommendationSeedProvider);

  return engine.recommend(
    guideline: guideline,
    profile: profile,
    pregnancy: pregnancy,
    assessments: assessments,
    todaysMeals: meals,
    rotationSeed: seed,
  );
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

final pendingApprovalsProvider = FutureProvider<List<PendingApproval>>((ref) {
  return ref.watch(authRepositoryProvider).pendingApprovals();
});

final appointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref
      .watch(appointmentRepositoryProvider)
      .watchAppointmentsForUser(user.id);
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
  return ref
      .watch(contentRepositoryProvider)
      .watchEducationContent(activeOnly: false);
});

final recommendationsProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref
      .watch(contentRepositoryProvider)
      .watchRecommendations(userId: user.id);
});

final allRecommendationsProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  return ref
      .watch(contentRepositoryProvider)
      .watchRecommendations(activeOnly: false);
});

final notificationsProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref
      .watch(contentRepositoryProvider)
      .watchNotifications(userId: user.id);
});

final allNotificationsProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  return ref
      .watch(contentRepositoryProvider)
      .watchNotifications(activeOnly: false);
});

final reportsProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(contentRepositoryProvider).watchReports(userId: user.id);
});

final allReportsProvider = StreamProvider<List<FirestoreDoc>>((ref) {
  return ref.watch(contentRepositoryProvider).watchReports();
});
