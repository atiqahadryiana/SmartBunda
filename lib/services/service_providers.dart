import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/config/ai_config.dart';
import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/services/ai_assistant_service.dart';
import 'package:smartbunda/services/alert_repository.dart';
import 'package:smartbunda/services/assessment_result_repository.dart';
import 'package:smartbunda/services/appointment_vitals_repository.dart';
import 'package:smartbunda/services/clinical_note_repository.dart';
import 'package:smartbunda/services/food_history_repository.dart';
import 'package:smartbunda/services/food_recommendation_engine.dart';
import 'package:smartbunda/services/meal_reminder_service.dart';
import 'package:smartbunda/services/nutrition_guideline_repository.dart';
import 'package:smartbunda/services/recommendation_audit_repository.dart';
import 'package:smartbunda/services/appointment_repository.dart';
import 'package:smartbunda/services/auth_repository.dart';
import 'package:smartbunda/services/data_store.dart';
import 'package:smartbunda/services/firebase_auth_repository.dart';
import 'package:smartbunda/services/firestore_alert_repository.dart';
import 'package:smartbunda/services/firestore_appointment_repository.dart';
import 'package:smartbunda/services/firestore_content_repository.dart';
import 'package:smartbunda/services/firestore_data_store.dart';
import 'package:smartbunda/services/firestore_nutrition_plan_repository.dart';
import 'package:smartbunda/services/food_catalog_repository.dart';
import 'package:smartbunda/services/food_database.dart';
import 'package:smartbunda/services/firebase_ai_vision_service.dart';
import 'package:smartbunda/services/food_vision_service.dart';
import 'package:smartbunda/services/ollama_vision_service.dart';
import 'package:smartbunda/services/yolo_food_classifier_service.dart';
import 'package:smartbunda/services/nutrition_plan_repository.dart';
import 'package:smartbunda/services/system_admin_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final dataStoreProvider = Provider<DataStore>((ref) {
  return FirestoreDataStore();
});

final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final usersProvider = StreamProvider<List<AppUser>>(
  (ref) => ref.watch(authRepositoryProvider).watchUsers(),
);

final nutritionPlanRepositoryProvider = Provider<NutritionPlanRepository>((ref) {
  return FirestoreNutritionPlanRepository();
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return FirestoreAppointmentRepository();
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return FirestoreAlertRepository();
});

final foodDatabaseProvider = Provider<FoodCatalogRepository>((ref) {
  final repo = FoodCatalogRepository(FoodDatabase());
  ref.onDispose(repo.dispose);
  return repo;
});

/// Firebase AI Logic (Gemini Developer API) food scanner — PRIMARY scan path
/// (uses [AiConfig.geminiVisionModel], e.g. gemini-3.5-flash).
final firebaseAiVisionServiceProvider =
    Provider<FirebaseAiVisionService>((ref) {
  return FirebaseAiVisionService();
});

/// Firebase AI Logic scanner on a SECOND Gemini model
/// ([AiConfig.geminiVisionModelFallback], e.g. gemini-2.5-flash). Used right
/// after the primary so a free-tier quota error on the primary retries on a
/// model with a separate quota.
final firebaseAiVisionFallbackProvider =
    Provider<FirebaseAiVisionService>((ref) {
  return FirebaseAiVisionService(
    modelName: AiConfig.geminiVisionModelFallback,
  );
});

/// Firebase AI Logic scanner on a THIRD Gemini model
/// ([AiConfig.geminiVisionModelLite], e.g. gemini-2.5-flash-lite). The last
/// Gemini Flash tier the scanner tries before falling back to manual entry.
final firebaseAiVisionLiteProvider =
    Provider<FirebaseAiVisionService>((ref) {
  return FirebaseAiVisionService(
    modelName: AiConfig.geminiVisionModelLite,
  );
});

/// On-device YOLOv8n-cls food classifier — the FIRST stage of the meal-scanner
/// chain (the "smart split"). When its top prediction clears
/// [AiConfig.yoloConfidenceThreshold] the scan resolves instantly, offline and
/// free; otherwise the chain escalates to the Gemini scanners. Degrades to
/// unready (and is skipped) when the model asset hasn't been shipped yet.
final yoloFoodClassifierProvider =
    Provider<YoloFoodClassifierService>((ref) {
  final service = YoloFoodClassifierService();
  ref.onDispose(service.dispose);
  return service;
});

/// OpenRouter vision food scanner — retained for the AI assistant / other
/// callers; no longer part of the meal-scanner chain (now all Gemini Flash).
final foodVisionServiceProvider = Provider<FoodVisionService>((ref) {
  final service = FoodVisionService();
  ref.onDispose(service.dispose);
  return service;
});

/// Ollama Cloud food scanner — used as the fallback when the OpenRouter
/// scanner fails.
final ollamaVisionServiceProvider = Provider<OllamaVisionService>((ref) {
  final service = OllamaVisionService();
  ref.onDispose(service.dispose);
  return service;
});

final aiAssistantProvider = Provider<AiAssistantService>((ref) {
  final service = AiAssistantService();
  ref.onDispose(service.dispose);
  return service;
});

final foodHistoryRepositoryProvider = Provider<FoodHistoryRepository>((ref) {
  return FoodHistoryRepository();
});

/// Schedules local "log your meal" reminder notifications (breakfast/lunch/
/// dinner). Single instance for the app.
final mealReminderServiceProvider = Provider<MealReminderService>((ref) {
  return MealReminderService();
});

final assessmentResultRepositoryProvider =
    Provider<AssessmentResultRepository>((ref) {
  return AssessmentResultRepository();
});

final foodRecommendationEngineProvider =
    Provider<FoodRecommendationEngine>((ref) {
  return const FoodRecommendationEngine();
});

final recommendationAuditRepositoryProvider =
    Provider<RecommendationAuditRepository>((ref) {
  return RecommendationAuditRepository();
});

final clinicalNoteRepositoryProvider =
    Provider<ClinicalNoteRepository>((ref) {
  return ClinicalNoteRepository();
});

final appointmentVitalsRepositoryProvider =
    Provider<AppointmentVitalsRepository>((ref) {
  return AppointmentVitalsRepository();
});

final nutritionGuidelineRepositoryProvider =
    Provider<NutritionGuidelineRepository>((ref) {
  return NutritionGuidelineRepository();
});

final contentRepositoryProvider = Provider<FirestoreContentRepository>((ref) {
  return FirestoreContentRepository();
});

final systemAdminRepositoryProvider = Provider<SystemAdminRepository>((ref) {
  final repo = SystemAdminRepository(
    authRepository: ref.read(authRepositoryProvider),
    dataStore: ref.read(dataStoreProvider),
    planRepository: ref.read(nutritionPlanRepositoryProvider),
    appointmentRepository: ref.read(appointmentRepositoryProvider),
    alertRepository: ref.read(alertRepositoryProvider),
    foodCatalogRepository: ref.read(foodDatabaseProvider),
    firestore: FirebaseFirestore.instance,
  );
  ref.onDispose(repo.dispose);
  return repo;
});
