import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/services/alert_repository.dart';
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
import 'package:smartbunda/services/food_image_classifier.dart';
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

final foodImageClassifierProvider = Provider<FoodImageClassifier>((ref) {
  final classifier = FoodImageClassifier();
  ref.onDispose(classifier.dispose);
  return classifier;
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
