# Smartbunda (prototype)

Flutter prototype for a pregnancy nutrition tracker with role-based access control (patient, doctor, nurse, dietitian, admin). This build uses in-memory services only.

## Project structure
- `lib/main.dart`: wires in-memory services into Riverpod.
- `lib/app.dart`: app shell with auth gate.
- `lib/models/`: data models (`AppUser`, `Profile`, `FoodEntry`, `FoodItem`).
- `lib/services/`: repositories (`AuthRepository`, `DataStore`) and in-memory implementations + food DB loader.
- `lib/providers/`: Riverpod providers for auth, profile, entries.
- `lib/screens/`: Login, Register, Home (role-based tabs and module hubs).
- `assets/foods_my.json`: sample Malaysian food database for manual logging/ML stub.
- `malaysian-food-dataset/`: TensorFlow CNN training pipeline for Malaysian
  food image classification.
## Running
1) Install Flutter (3.16+).  
2) From `Smartbunda/`, run `flutter create .` to generate platform folders, then `flutter pub get`.
3) Configure Firebase (Auth + Firestore + Storage):
   - Run `flutterfire configure` to generate `firebase_options.dart`, or
   - Add `google-services.json` (Android) and update `Firebase.initializeApp` with your options.
4) Run `flutter run -d chrome` or your preferred device.

## Training the food CNN
From `malaysian-food-dataset/`, install `requirements-ml.txt`, then run:

```bash
python train_cnn.py --dataset-dir dataset --epochs 40 --app-assets-dir ../assets/ml
```

This exports `artifacts/food_cnn.keras`, `artifacts/food_cnn.tflite`, and
`artifacts/labels.json`, then copies the mobile model and labels to
`assets/ml/`.

Seeded test logins (in-memory only):
- `admin@example.com` / `password` (Admin)
- `doctor@example.com` / `password` (Doctor)
- `nurse@example.com` / `password` (Nurse)
- `dietitian@example.com` / `password` (Dietitian)
- `patient@example.com` / `password` (Patient)
