import '../models/food_entry.dart';
import '../models/feedback_entry.dart';
import '../models/hydration_entry.dart';
import '../models/pregnancy.dart';
import '../models/profile.dart';

abstract class DataStore {
  Stream<Profile?> watchProfile(String userId);
  Future<void> saveProfile(Profile profile);
  Stream<Map<String, Profile>> watchAllProfiles();

  Stream<Pregnancy?> watchPregnancy(String patientId);
  Future<void> savePregnancy(Pregnancy pregnancy);
  Stream<Map<String, Pregnancy>> watchAllPregnancies();

  Stream<List<FoodEntry>> watchEntries(String userId);
  Future<void> addEntry(FoodEntry entry);

  Stream<Map<String, List<FoodEntry>>> watchAllEntries(); // for clinician/admin overview

  Stream<List<HydrationEntry>> watchHydrationEntries(String userId);
  Future<void> addHydrationEntry(HydrationEntry entry);

  Stream<List<FeedbackEntry>> watchFeedback(String userId);
  Stream<List<FeedbackEntry>> watchAllFeedback();
  Future<void> addFeedback(FeedbackEntry entry);

  Map<String, dynamic> exportState();
  void restoreState(Map<String, dynamic> data);
}
