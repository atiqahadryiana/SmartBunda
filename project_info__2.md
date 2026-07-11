# Smartbunda — CNN / Nutrition Tracker Codebase Overview

## Summary

Smartbunda is a Flutter-based pregnancy nutrition tracker with role-based access control for patients, doctors, nurses, dietitians, and admins. The application combines manual meal logging, a Malaysian food catalog, hydration tracking, and an on-device CNN food scanner that recognizes food images from a Malaysian dataset.

The important architectural detail is that image classification and nutrition lookup are separate concerns. The CNN predicts a food label; nutrition is then resolved from a food database or, in the Python backend, from a nutrition cache/MyFCD lookup. In other words, the model does not directly “know” calories — the app has to map the predicted food to a nutrition source.

## Architecture

### Primary pattern

This is a split architecture:

- **Flutter client app** for the user-facing nutrition tracker
- **Python ML pipeline** for training/exporting the CNN and optionally serving predictions
- **Firebase / Firestore-backed business data** for the broader clinic workflow
- **Riverpod** for dependency injection and state access in Flutter

### Major subsystems

1. **Mobile app shell (`lib/`)**
   - Handles auth, localization, routing, and role-based screens.
   - Uses Riverpod providers to inject repositories and services.

2. **Food logging + AI scan flow**
   - Users can manually log meals or scan a meal image.
   - The scanner uses a local TensorFlow Lite model (`assets/ml/food_cnn.tflite`) plus `assets/ml/labels.json`.

3. **Food catalog / nutrition mapping**
   - The scanner only returns labels/confidence.
   - Nutrition values come from `FoodDatabase` / catalog entries, or from manual entry if the predicted label cannot be matched.

4. **Malaysian food CNN training project (`malaysian-food-dataset/`)**
   - TensorFlow/Keras transfer-learning pipeline.
   - Exports `.keras`, `.tflite`, and `labels.json` artifacts for the Flutter app.

5. **Python recognition + nutrition API (`food-calorie-recognition/`)**
   - Separate FastAPI service that predicts food and looks up nutrition from SQLite/MyFCD cache.
   - This is more “end-to-end” than the Flutter local classifier, but it is not the main runtime path in the Flutter app shown here.

### Technology stack

- **Flutter / Dart** for mobile/web UI
- **Riverpod** for DI/state
- **Firebase Auth, Firestore, Storage** for app data and RBAC
- **TensorFlow / TensorFlow Lite** for CNN training and on-device inference
- **FastAPI** for the Python nutrition recognition API
- **SQLite** for nutrition caching/history in the Python service
- **PIL / OpenCV / imagehash / Bing crawler** in the dataset generation tooling

### Runtime entry points

- Flutter app starts in `lib/main.dart`
- App shell and route table are in `lib/app.dart`
- AI scan UI is driven through `lib/screens/log/meal_log_actions.dart` and the food scanning screens
- CNN training starts in `malaysian-food-dataset/train_cnn.py`
- Backend prediction API starts in `food-calorie-recognition/api/main.py`

## Directory Structure

```text
Smartbunda/
├── lib/                        — Flutter app source
│   ├── app.dart                — MaterialApp, routes, localization
│   ├── main.dart               — Firebase init + ProviderScope bootstrap
│   ├── services/               — repositories + classifier + data access
│   ├── screens/                — login, food logging, dashboards, role modules
│   ├── models/                 — app domain models
│   ├── providers/              — Riverpod providers
│   └── widgets/                — reusable UI pieces
├── assets/
│   ├── foods_my.json           — sample Malaysian food database
│   └── ml/
│       ├── labels.json         — CNN label mapping used by Flutter
│       └── README.md           — asset placement note
├── malaysian-food-dataset/     — CNN training/export pipeline
│   ├── food_cnn.py             — Keras model builder
│   ├── train_cnn.py            — training, fine-tuning, export
│   ├── predict_food.py         — local image inference CLI
│   ├── evaluate_and_promote.py  — accuracy gate for mobile asset promotion
│   ├── dataset_builder.py      — Bing crawler + dedupe + resize utility
│   ├── foods.py                — Malaysian class list
│   └── artifacts/              — generated evaluation outputs
├── food-calorie-recognition/   — FastAPI + SQLite nutrition recognition backend
│   ├── api/main.py             — FastAPI app
│   ├── src/food_calorie/       — predictor, nutrition model, cache DB
│   └── data/                   — nutrition seed data and cache
├── android/                    — Android host project
├── web/                        — Flutter web host project
└── test/                       — unit/widget tests
```

## Key Abstractions

### `FoodImageClassifier`
- **File**: `lib/services/food_image_classifier_native.dart`
- **Responsibility**: Runs on-device TFLite inference for food images.
- **Interface**:
  - `classifyBytes(Uint8List bytes, {int topK = 5})`
  - `dispose()`
- **Lifecycle**: Lazily loads the interpreter and labels once; disposed by Riverpod on provider teardown.
- **Used by**: `foodImageClassifierProvider`, meal scan flow in `meal_log_actions.dart`.
- **Important behavior**: Uses `assets/ml/food_cnn.tflite` and `assets/ml/labels.json`; not available on web.

### `FoodImagePrediction`
- **File**: `lib/services/food_image_classifier_api.dart`
- **Responsibility**: Lightweight prediction result object.
- **Interface**:
  - `label`
  - `confidence`
  - `confidenceLabel`
- **Used by**: Scanner UI and meal suggestion flow.

### `FoodDatabase`
- **File**: `lib/services/food_database.dart`
- **Responsibility**: Loads and mutates food catalog entries from Firestore.
- **Interface**:
  - `loadFoods()`
  - `search(query)`
  - `addFoodItem()`, `updateFoodItem()`, `setFoodItemActive()`, `deleteFoodItem()`
- **Lifecycle**: Caches results in memory until invalidated.
- **Used by**: Food picker UI and scan-to-meal matching.
- **Important behavior**: The classifier alone does not supply nutrition; this repository is what makes matched predictions useful for logging.

### `MealLogActions`
- **File**: `lib/screens/log/meal_log_actions.dart`
- **Responsibility**: Orchestrates all meal logging paths.
- **Interface**:
  - `showAddOptions()`
  - `showAddEntrySheet()`
  - `showFoodPicker()`
  - `captureMeal()`
- **Lifecycle**: UI-driven; creates entries and pushes them to the data store.
- **Used by**: Log screen and food logging hub.
- **Important behavior**: A scan result becomes a saved meal only after label matching, optional food selection, and quantity/meal-time confirmation.

### `FoodPredictor`
- **File**: `food-calorie-recognition/src/food_calorie/predictor.py`
- **Responsibility**: End-to-end image prediction + nutrition lookup for the Python backend.
- **Interface**:
  - `predict_array()`
  - `predict_file()`
- **Lifecycle**: Loads a Keras model and nutrition database at startup.
- **Used by**: FastAPI `/predict` endpoint.
- **Important behavior**: This backend can return nutrition data directly; unlike the Flutter TFLite path, it is an integrated recognition-and-nutrition service.

### `NutritionDatabase`
- **File**: `food-calorie-recognition/src/food_calorie/database.py`
- **Responsibility**: SQLite nutrition cache plus history tracking.
- **Interface**:
  - `get()`, `upsert()`, `record_history()`
  - `recent_history()`, `daily_calories()`
  - JSON/CSV export helpers
- **Used by**: Backend API and nutrition syncing tools.
- **Important behavior**: Stores both nutrition metadata and prediction history, enabling daily calorie summaries.

### `build_food_cnn()`
- **File**: `malaysian-food-dataset/food_cnn.py`
- **Responsibility**: Builds the transfer-learning classifier.
- **Interface**: Returns `(model, backbone)`
- **Lifecycle**: Used by training scripts, not by the mobile app directly.
- **Important behavior**: The exported model expects raw RGB input in the 0–255 range; preprocessing is built into the graph so Flutter does not need custom normalization.

### `train_cnn.py`
- **File**: `malaysian-food-dataset/train_cnn.py`
- **Responsibility**: Trains, fine-tunes, evaluates, and exports the CNN.
- **Interface**: CLI flags for dataset, backbone, epochs, TFLite export, and app asset copy.
- **Lifecycle**: Produces artifacts under `malaysian-food-dataset/artifacts/`.
- **Used by**: Dataset/model maintenance workflow.

## Data Flow

### Flutter scan-to-log flow
1. User opens the food logging flow in `FoodLoggingHubScreen`.
2. `MealLogActions.captureMeal()` uses `image_picker` to capture or select a photo.
3. `FoodImageClassifier.classifyBytes()` loads the TFLite model and labels, decodes the image, resizes to `224x224`, and runs inference.
4. The top predictions are ranked by confidence.
5. `MealLogActions._predictionCandidates()` tries to match predicted labels against `FoodDatabase` entries.
6. If a match exists, the user gets a concrete food suggestion with nutrition already known from the catalog.
7. If no nutrition match exists, the app falls back to a placeholder food item and asks the user to fill in details manually.
8. The final meal entry is saved through the data store and shown in the user’s log.

### Model training / promotion flow
1. `dataset_builder.py` can scrape and clean Malaysian food images.
2. `train_cnn.py` builds a transfer-learning model, trains in two stages, and writes:
   - `food_cnn.keras`
   - `food_cnn.tflite`
   - `labels.json`
3. `evaluate_and_promote.py` checks validation accuracy.
4. Only if the accuracy threshold passes does it copy artifacts into `assets/ml/`.

### Backend prediction flow
1. Client uploads an image to FastAPI `/predict`.
2. `FoodPredictor.predict_file()` reads the image and runs the Keras model.
3. The predicted label is normalized and used to query `NutritionDatabase` / MyFCD cache.
4. The API returns JSON containing food name, confidence, calories, macros, and sodium.
5. History and daily-calorie summaries are stored in SQLite and exposed via `/history` and `/daily-calories`.

## Non-Obvious Behaviors & Design Decisions

- **The CNN is not the nutrition engine.**
  - The Flutter model predicts classes only.
  - Nutrition is resolved later through the food catalog or backend cache.
  - This is why a correct image classifier can still fail to auto-log nutrition if the label cannot be matched.

- **The Flutter scanner is local, but the richer nutrition service is separate.**
  - `food-calorie-recognition/` has a full recognition-plus-nutrition API.
  - The Flutter app currently uses the local TFLite path, not the FastAPI service in the shown code.

- **Web support is intentionally limited.**
  - `food_image_classifier_web.dart` throws an error saying scanning is unavailable on web.
  - This matters because the app README mentions Chrome usage, but image scanning will not work there.

- **Model input is raw RGB values, not normalized floats from Flutter.**
  - The training graph includes preprocessing.
  - The app must pass raw pixel intensities in `0..255` as `float32`.
  - The Dart classifier follows that rule exactly.

- **Labels are version-sensitive assets.**
  - `labels.json` must remain aligned with the exported model.
  - The `evaluate_and_promote.py` script copies labels and TFLite together to avoid mismatches.

- **Nutrition lookup is normalized, not fuzzy in the ML sense.**
  - The Python backend uses `normalize_label()` to stabilize class names.
  - The Flutter meal logger does a simple normalized string comparison and substring fallback.
  - This means naming conventions matter a lot for successful automatic nutrition attachment.

- **The local Flutter path is conservative by design.**
  - If the predicted food cannot be matched to a known catalog item, the app does not invent nutrition.
  - It forces the user into manual completion, which is safer for a tracker app.

- **The classifier has no direct portion estimation.**
  - The backend supports `portion_multiplier`.
  - The Flutter local path still asks the user for quantity/meal size in the meal logging flow.
  - So caloric totals depend on user confirmation, not vision alone.

- **Asset promotion is gated by accuracy.**
  - `evaluate_and_promote.py` refuses to overwrite app assets if validation accuracy is below threshold.
  - That is a deliberate quality-control step before shipping a model to mobile.

## Module Reference

| File | Purpose |
|------|---------|
| `lib/main.dart` | Initializes Firebase, SharedPreferences, and Riverpod; launches the app |
| `lib/app.dart` | MaterialApp setup, localization, routes, theme |
| `lib/services/service_providers.dart` | Provider wiring for auth, data store, classifier, and repositories |
| `lib/services/food_image_classifier_native.dart` | Native TFLite image classifier used by the meal scanner |
| `lib/services/food_image_classifier_api.dart` | Prediction result and exception types |
| `lib/services/food_database.dart` | Firestore-backed food catalog and nutrition item store |
| `lib/screens/log/meal_log_actions.dart` | Scan/manual entry orchestration and meal saving |
| `lib/screens/food_logging_hub_screen.dart` | Entry point for meal log, scanner, hydration log |
| `assets/ml/labels.json` | Class index-to-label mapping for the mobile model |
| `malaysian-food-dataset/food_cnn.py` | Keras transfer-learning classifier definition |
| `malaysian-food-dataset/train_cnn.py` | Training, fine-tuning, TFLite export, mobile asset copy |
| `malaysian-food-dataset/predict_food.py` | CLI inference for a trained model |
| `malaysian-food-dataset/evaluate_and_promote.py` | Validation gate before copying model assets into Flutter |
| `malaysian-food-dataset/dataset_builder.py` | Dataset scraping/cleanup/resizing utility |
| `malaysian-food-dataset/foods.py` | Malaysian food class list used for dataset building |
| `food-calorie-recognition/api/main.py` | FastAPI server for prediction + nutrition lookup |
| `food-calorie-recognition/src/food_calorie/predictor.py` | Backend predictor that combines CNN output with nutrition data |
| `food-calorie-recognition/src/food_calorie/database.py` | SQLite nutrition cache and history store |
| `food-calorie-recognition/src/food_calorie/nutrition.py` | Nutrition data model and API formatting |
| `food-calorie-recognition/src/food_calorie/config.py` | Shared config, image size, and label normalization |

## Suggested Reading Order

1. `lib/services/food_image_classifier_native.dart` — shows exactly how the Flutter app runs the CNN on-device.
2. `lib/screens/log/meal_log_actions.dart` — shows how predictions become meal entries.
3. `lib/services/food_database.dart` — shows how nutrition is actually resolved from the catalog.
4. `malaysian-food-dataset/food_cnn.py` — shows what the model expects and how it was built.
5. `malaysian-food-dataset/train_cnn.py` — shows how the model is trained, tuned, and exported.
6. `food-calorie-recognition/api/main.py` — shows the more complete recognition + nutrition backend path.

## Bottom Line for Your CNN Model

Your Malaysian-food CNN pipeline is present and integrated, but the app does **not** directly turn an image prediction into nutrition by itself. The CNN detects the food label; then the app either:

- matches that label to the food catalog and uses stored nutrition, or
- falls back to manual entry if the label cannot be matched.

If your goal is “upload photo → detect Malaysian food → show calories automatically,” the current codebase is close, but the label-to-nutrition mapping is the critical dependency. The cleaner end-to-end version already exists in `food-calorie-recognition/`, where the classifier and nutrition cache are combined in one service.