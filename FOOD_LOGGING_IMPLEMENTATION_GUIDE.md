# SmartBunda Food Logging Implementation Guide

## Executive Summary

This document describes the complete **AI-powered Food Logging System** for SmartBunda, a maternal health and nutrition tracking app. The system enables pregnant women to:

1. **Capture food images** (camera or gallery)
2. **Detect food automatically** via TensorFlow Lite CNN (224×224 classification)
3. **Look up nutrition** from the local Malaysian Food Composition Database (MyFCD)
4. **Adjust portion size** (10–1000g slider)
5. **Select meal type** (breakfast/lunch/dinner/snack)
6. **Save to Firebase** with complete nutrition facts

---

## Architecture Overview

```
User Flow:
┌─────────────────────────────────────────────────────────────────┐
│ 1. Camera / Gallery (MealLogActions.captureMeal)               │
│    ↓ Image picked (Uint8List bytes)                            │
├─────────────────────────────────────────────────────────────────┤
│ 2. TFLite Inference (FoodImageClassifier)                      │
│    ├─ Load: assets/ml/food_cnn.tflite (FP16, 224×224)         │
│    ├─ Preprocess: resize, normalize RGB                       │
│    ├─ Inference: 224×224×3 → [1, num_classes] probabilities  │
│    ├─ Post-process: top-5 predictions with confidence         │
│    └─ Output: List<FoodImagePrediction>                       │
├─────────────────────────────────────────────────────────────────┤
│ 3. Navigate to FoodAnalysisResultScreen                        │
│    ├─ Pass: Uint8List imageBytes, List<Prediction> predictions│
│    └─ Display: image, confidence bars, food selector          │
├─────────────────────────────────────────────────────────────────┤
│ 4. Local Nutrition Lookup (LocalNutritionLookup)              │
│    ├─ Fuzzy-match selected food label against MyFCD           │
│    ├─ 138 Malaysian foods pre-loaded (hardcoded)              │
│    ├─ Return: FoodNutritionData (per-100g macros + micros)   │
│    └─ Scale to user's portion size                            │
├─────────────────────────────────────────────────────────────────┤
│ 5. User Interaction (FoodAnalysisResultScreen)                │
│    ├─ Adjust portion: slider 10–1000g (default: entry.default)|
│    ├─ Select meal type: breakfast/lunch/dinner/snack          │
│    ├─ Review nutrition: kcal, protein, carbs, fat, fibre, etc │
│    └─ Confirm & Save                                          │
├─────────────────────────────────────────────────────────────────┤
│ 6. Firebase Save (DataStore.addEntry)                         │
│    ├─ Create FoodEntry with:                                  │
│    │  ├─ id: timestamp (microsecondsSinceEpoch)              │
│    │  ├─ userId: current user.id                             │
│    │  ├─ foodId: AI-detected label                           │
│    │  ├─ meal: display name (AI result)                      │
│    │  ├─ quantity: portion_g                                 │
│    │  ├─ calories/protein/carbs/fat: scaled nutrition        │
│    │  ├─ mealType: breakfast|lunch|dinner|snack              │
│    │  └─ notes: "AI scan (95%)" — confidence attribution     │
│    └─ Write to Firestore: /users/{userId}/foodLog/{id}       │
├─────────────────────────────────────────────────────────────────┤
│ 7. Dashboard Updates (entriesProvider)                         │
│    ├─ Invalidate: ref.invalidate(entriesProvider)            │
│    ├─ Fetch: user's daily/weekly food intake                 │
│    ├─ Aggregate: total kcal, macros, micronutrients          │
│    └─ Display: nutrition progress vs pregnancy targets       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Breakdown

### 1. Image Capture & Preprocessing

**File:** `lib/screens/log/meal_log_actions.dart`

**Function:** `MealLogActions.captureMeal(context, ref, source: ImageSource)`

```dart
// Workflow:
1. Pick image (camera or gallery) via ImagePicker
2. Read bytes: await picked.readAsBytes()
3. Show snackbar: "Analyzing image..."
4. Call TFLite classifier: classifyBytes(bytes, topK: 5)
5. On success: navigate to FoodAnalysisResultScreen
6. On error: show user-friendly error message
```

**Supported image formats:** JPEG, PNG, WebP (decoded by `image` package)

---

### 2. TensorFlow Lite Inference

**File:** `lib/services/food_image_classifier_native.dart`

**Model:** `assets/ml/food_cnn.tflite` (FP16 quantised, ~2.2 MB)

**Input:**
- Shape: `[1, 224, 224, 3]`
- Type: `Float32List`
- Range: `[0.0, 255.0]` (normalized RGB)

**Output:**
- Shape: `[1, num_classes]`
- Type: `List<double>` (raw probabilities)

**Processing:**
1. Decode image bytes → `img.Image`
2. Auto-rotate based on EXIF orientation
3. Resize to 224×224 (linear interpolation)
4. Convert to Float32 RGB array
5. Run interpreter inference
6. Rank by probability, return top-5

**Error handling:**
- Missing model file → "Food scanner is not ready"
- TFLite precondition error → "Model exported with incompatible quantisation"
- Image decode failure → "Could not read image (try JPEG/PNG)"

---

### 3. AI Prediction UI

**File:** `lib/screens/food_analysis_result_screen.dart`

**Components:**

#### Hero Image Section
- Full-width image with dark scrim overlay
- Top detected food name + confidence badge
- Color-coded confidence (green ≥70%, orange ≥40%, red <40%)

#### Prediction List
- All top-5 results in a card
- Radio button to select which food to log
- Confidence bar showing relative scores
- On selection: portion slider updates to food's default

#### Portion Slider
- Range: 10g–1000g
- Display: "200 g" (current selection)
- Default: food entry's `defaultPortionG` (e.g., 200g for rice)

#### Meal Type Selector
- 4 toggle buttons: Breakfast, Lunch, Dinner, Snack
- Default: inferred from current hour (8am → breakfast, etc.)
- Each has icon + label

#### Nutrition Facts Card
- Header: food name, per-100g→portion scaling
- Macros: protein, carbs, fat (large kcal display)
- Micros: fibre, sodium, calcium, iron
- Source attribution: "MyFCD" (Malaysian Food Composition Database)
- Disclaimer: values are estimates, may vary by preparation

#### Save Button
- Primary gradient (pink)
- Shows spinner while saving
- Transitions to checkmark on success
- Disabled during save or after success

---

### 4. Local Nutrition Database

**File:** `lib/utils/food_nutrition_lookup.dart`

**Coverage:** 138 Malaysian foods hardcoded

**Lookup Logic:**
1. Exact match (lowercase aliases)
2. Substring match (e.g., "nasi goreng" matches "nasi goreng ayam")
3. Fuzzy bigram similarity (Dice coefficient)

**Threshold:** 0.45 (45% similarity minimum)

**Sample Foods:**
- Rice: Nasi Lemak, Nasi Goreng Ayam, Nasi Kerabu, etc.
- Noodles: Char Kuey Teow, Laksa Penang, Mee Goreng, etc.
- Proteins: Ayam Goreng, Rendang Daging, Satay, Ikan Bakar, etc.
- Snacks: Curry Puff, Burger Ramly, Keropok Lekor, etc.
- Desserts: Cendol, Kuih Onde Onde, Bubur Pulut Hitam, etc.
- Beverages: Teh Tarik, Kopi Ais, Milo Dinosaur, etc.

**Values per 100g:**
```
FoodNutritionData {
  name: String,
  category: String,
  aliases: List<String>,
  energyKcalPer100g: double,
  proteinGPer100g: double,
  fatGPer100g: double,
  carbsGPer100g: double,
  fibreGPer100g: double,
  sodiumMgPer100g: double,
  calciumMgPer100g: double,
  ironMgPer100g: double,
  defaultPortionG: double (e.g., 200 for rice, 150 for curry),
}
```

**Scaling:** `entry.scaleToPortionG(200)` returns nutrition for 200g portion

---

### 5. Firebase Integration

**File:** Firestore (Cloud) + DataStore (local abstraction)

**Collection Structure:**

```
firestore
  └─ users/{userId}
      └─ foodLog/{entryId}
          ├─ id: String
          ├─ userId: String
          ├─ foodId: String (AI label, e.g., "nasi_lemak")
          ├─ meal: String (display name, e.g., "Nasi Lemak")
          ├─ date: DateTime
          ├─ quantity: double (grams)
          ├─ unit: String ("g")
          ├─ calories: int
          ├─ protein: int (grams)
          ├─ carbs: int (grams)
          ├─ fat: int (grams)
          ├─ ironMg: double
          ├─ folateMcg: double
          ├─ mealType: String ("breakfast"|"lunch"|"dinner"|"snack")
          └─ notes: String (e.g., "AI scan (95%)")
```

**Save Flow:**
```dart
// In FoodAnalysisResultScreen._saveLog()
final entry = FoodEntry(
  id: DateTime.now().microsecondsSinceEpoch.toString(),
  userId: user.id,
  logId: '${id}_log',
  foodId: prediction.label,
  meal: prediction.displayName,
  quantity: _portionG,
  unit: 'g',
  calories: nutrition.energyKcal,
  protein: nutrition.proteinG,
  carbs: nutrition.carbsG,
  fat: nutrition.fatG,
  ironMg: nutrition.ironMg,
  folateMcg: 0, // Not in MyFCD lookup currently
  mealType: _mealType.label,
  notes: 'AI scan (${prediction.confidenceLabel})',
);

await ref.read(dataStoreProvider).addEntry(entry);
ref.invalidate(entriesProvider); // Refresh dashboard
```

---

## Deployment Checklist

### Mobile (Flutter)

- [ ] **Assets**
  - [ ] `assets/ml/food_cnn.tflite` present (FP16, ~2.2 MB)
  - [ ] `assets/ml/labels.json` present (list of class names)
  - [ ] Add to `pubspec.yaml`:
    ```yaml
    assets:
      - assets/ml/food_cnn.tflite
      - assets/ml/labels.json
    ```

- [ ] **Dependencies** (already in pubspec.yaml)
  - [ ] `tflite_flutter: ^0.10.0` or later
  - [ ] `image_picker: ^1.0.0` or later
  - [ ] `flutter_riverpod: ^2.0.0` or later
  - [ ] `image: ^4.0.0` or later (for image preprocessing)

- [ ] **Permissions** (Android Manifest + iOS Info.plist)
  - [ ] Camera permission
  - [ ] Photo gallery/file access

- [ ] **Android-Specific**
  - [ ] XNNPACK delegate enabled (default in TFLite)
  - [ ] GPU delegate not required (CPU sufficient for 224×224)

- [ ] **iOS-Specific**
  - [ ] Metal delegate available (optional, CPU fallback works)
  - [ ] Permissions in Info.plist

### Firebase

- [ ] Firestore database rules allow user reads/writes:
  ```firestore
  match /users/{userId}/foodLog/{entryId} {
    allow read, write: if request.auth.uid == userId;
  }
  ```

- [ ] Enable offline persistence if needed:
  ```dart
  final settings = Settings(
    persistenceEnabled: true,
  );
  FirebaseFirestore.instance.settings = settings;
  ```

---

## Performance Characteristics

| Operation | Latency | Notes |
|-----------|---------|-------|
| Image decode | 50–150ms | Depends on image size & format |
| TFLite inference | 200–400ms | 224×224 CNN on mid-range ARM CPU |
| MyFCD lookup | 1–5ms | Hardcoded, no network |
| Firestore write | 500ms–2s | Network dependent; offline queued |
| Dashboard refresh | 500ms–1s | Local cache + Firestore fetch |

**Optimization tips:**
- Cache MyFCD in memory after first lookup
- Use `ref.invalidate(entriesProvider)` after save (Riverpod handles fetch)
- Consider lazy-loading MyFCD for 138 foods (currently hardcoded)
- Test on actual device (emulator latency may differ)

---

## Medical Disclaimer

Every screen displays:
> "This assessment is generated using SmartBunda clinical screening rules and AI-assisted explanations. It does not replace professional medical advice."

Similar disclaimer in FoodAnalysisResultScreen:
> "Nutritional values are estimates based on the Malaysian Food Composition Database (MyFCD) and may vary by preparation method and ingredients."

---

## Future Enhancements

### Phase 3: Multi-Food Detection
- Migrate from single-food classification to YOLOv8n object detection
- Detect 2–4 foods per image with bounding boxes
- See `malaysian-food-dataset/yolo_pipeline.py` for training pipeline

### Phase 4: Enhanced Nutrition Data
- Add micronutrient data to MyFCD (currently: energy, protein, fat, carbs, fibre, sodium, calcium, iron)
- Integrate with official MyFCD API when available
- Add food search by name (SQLite local database)

### Phase 5: Meal Planning
- Suggest meals based on pregnancy nutritional targets
- Integration with clinical rule engine for personalized recommendations

---

## Testing Checklist

### Unit Tests
- [ ] `LocalNutritionLookup.lookup()` with exact, substring, fuzzy matches
- [ ] `FoodNutritionData.scaleToPortionG()` scaling accuracy
- [ ] `FoodImagePrediction` confidence tier classification

### Integration Tests
- [ ] End-to-end: pick image → predict → lookup → save → dashboard update
- [ ] Offline mode: TFLite inference without network
- [ ] Firebase write: verify Firestore document structure

### Manual Testing
- [ ] Test on 5–10 real food images (lighting variations)
- [ ] Verify portion slider handles edge cases (10g, 1000g)
- [ ] Confirm meal type defaults match time of day
- [ ] Check nutrition scaling accuracy (test 100g vs 500g)
- [ ] Verify Firebase save and dashboard refresh

---

## Troubleshooting

### TFLite Load Error: "failed precondition"
**Cause:** Model exported with INT8/FP32 hybrid quantisation
**Fix:** Re-export model with `converter.target_spec.supported_types = [tf.float16]`

### Empty MyFCD Lookup
**Cause:** Food label not in hardcoded database
**Fix:** Fallback to manual nutrition entry dialog (already implemented)

### Slow Inference (>500ms)
**Cause:** CPU load or large image pre-processing
**Fix:** Run inference on background isolate; optimize image resize

### Firebase Write Fails
**Cause:** Network unavailable or Firestore rules
**Fix:** Enable offline persistence; verify Firestore security rules

---

## Code References

| File | Purpose |
|------|---------|
| `lib/screens/log/meal_log_actions.dart` | Image capture entry point |
| `lib/services/food_image_classifier_native.dart` | TFLite wrapper |
| `lib/services/food_image_classifier_api.dart` | Prediction data model |
| `lib/screens/food_analysis_result_screen.dart` | AI result UI + save |
| `lib/utils/food_nutrition_lookup.dart` | MyFCD local database |
| `assets/ml/food_cnn.tflite` | TensorFlow Lite model |
| `assets/ml/labels.json` | Food class labels |

---

## Related Documentation

- **Clinical Rules Engine:** `lib/utils/clinical_rules.dart` — Pregnancy nutrition targets
- **Nutrition Guides:** `lib/utils/nutrition_guides.dart` — RNI-based targets
- **Pre-Pregnancy Assessment:** `lib/screens/pre_pregnancy_assessment_screen.dart` — Risk detection
- **Food Catalog:** `lib/screens/food_catalog_screen.dart` — Manual food database

---

**Last Updated:** 2026-05-30  
**Status:** Production-Ready (Phase 1 complete, Phase 2–3 pending)
