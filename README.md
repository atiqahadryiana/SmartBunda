# SmartBunda 🌸

SmartBunda is a Flutter-based maternal nutrition and care management application designed for pregnant mothers and healthcare teams in Malaysia. It combines food logging, Malaysian food nutrition data, AI-assisted food recognition, appointment workflows, vitals tracking, clinical notes, role-based dashboards, and Firebase-backed administration tools.

## 📌 Overview

The project supports multiple user roles across a shared maternal care workflow:

- 🤰 **Patients** can manage profiles, log meals, review nutrition insights, track hydration, view recommendations, manage appointments, and access care materials.
- 🩺 **Nurses** can monitor patients, record vitals, add clinical notes, and support appointment follow-up.
- 🥗 **Nutritionists** can review client nutrition data, manage recommendations, and inspect food logs.
- 🛡️ **Administrators** can manage system content, user activity, nutrition guidelines, and platform configuration.

SmartBunda is built as a cross-platform Flutter app with Android and web support, using Firebase for authentication, Firestore data storage, Cloud Functions, Storage, and hosting.

## ✨ Key Features

- 🔐 Role-based access for patient, nurse, nutritionist, and admin workflows
- 🔑 Firebase Authentication with email/password and Google sign-in support
- ☁️ Firestore-backed patient profiles, appointments, activity logs, food history, vitals, assessments, and clinical notes
- 🇲🇾 Malaysian food catalog backed by local app assets and MyFCD-style nutrition data
- 📷 Food image analysis flow with on-device YOLO/TFLite support and cloud vision fallbacks
- 🧠 Nutrition recommendation engine with audit tracking
- 📅 Appointment calendar and professional availability management
- 📝 Patient assessment flow with result storage
- 📄 PDF report generation and sharing support
- 🔔 Local notifications for meal reminders
- 🌐 Responsive Flutter web deployment configuration through Firebase Hosting
- ⚙️ Cloud Functions package for privileged backend operations

## 🧰 Tech Stack

- 📱 **Application:** Flutter, Dart, Material UI
- 🧭 **State management:** Riverpod
- 🔥 **Backend:** Firebase Authentication, Cloud Firestore, Firebase Storage, Cloud Functions
- 🤖 **AI and vision:** Firebase AI, YOLO/TFLite classifier integration, image quality checks
- 📊 **Reports:** `pdf`, `printing`, `share_plus`
- 📈 **Charts and calendar:** `fl_chart`, `table_calendar`
- 🚀 **Deployment:** Firebase Hosting and Firebase Functions

## 🗂️ Repository Structure

```text
.
|-- android/                    # Android platform project
|-- assets/                     # App assets, logo, food data, optional ML assets
|-- functions/                  # Firebase Cloud Functions TypeScript project
|-- lib/
|   |-- models/                 # Domain models
|   |-- providers/              # Riverpod providers
|   |-- screens/                # Role-based app screens
|   |-- services/               # Repositories, Firebase services, AI/vision services
|   |-- theme/                  # App theme and shared UI primitives
|   `-- widgets/                # Shared widgets
|-- malaysian-food-dataset/     # Food model training and dataset utilities
|-- scripts/                    # Data seeding and utility scripts
|-- test/                       # Flutter tests
|-- tools/                      # Project tooling scripts
|-- web/                        # Flutter web platform project
|-- firebase.json               # Firebase Hosting, Firestore, and Functions config
|-- firestore.rules             # Firestore security rules
|-- firestore.indexes.json      # Firestore indexes
`-- pubspec.yaml                # Flutter dependencies and assets
```

## ✅ Prerequisites

- 📦 Flutter SDK compatible with Dart `>=3.4.0 <4.0.0`
- 🔥 Firebase CLI
- 🟢 Node.js 20 for Cloud Functions
- 🤖 Android Studio or Android SDK for Android builds
- ☁️ A configured Firebase project with Authentication, Firestore, Storage, Functions, and Hosting enabled

## 🚀 Getting Started

1. Install Flutter dependencies:

```bash
flutter pub get
```

2. Configure Firebase for Flutter:

```bash
flutterfire configure
```

3. Confirm the Android Firebase config exists:

```text
android/app/google-services.json
```

4. Install Cloud Functions dependencies:

```bash
cd functions
npm install
cd ..
```

5. Run the app:

```bash
flutter run -d chrome
```

For Android:

```bash
flutter run -d android
```

## 🔥 Firebase Configuration

The repository includes Firebase configuration files for hosting, Firestore rules, indexes, and functions:

- `firebase.json`
- `firestore.rules`
- `firestore.indexes.json`
- `functions/`

Private credentials must remain local. Do not commit service account keys, API secrets, local environment files, or generated build output.

## 🛠️ Useful Commands

Analyze the Flutter project:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Build Android APK:

```bash
flutter build apk --release
```

Build Flutter web:

```bash
flutter build web --release
```

Build Cloud Functions:

```bash
npm --prefix functions run build
```

Deploy Firebase Hosting:

```bash
firebase deploy --only hosting
```

Deploy Firestore rules and indexes:

```bash
firebase deploy --only firestore
```

Deploy Cloud Functions:

```bash
firebase deploy --only functions
```

## 🍽️ Food Recognition Assets

The app can use optional on-device ML assets from `assets/ml/`. If the TFLite model or labels are unavailable, the food scanning flow is designed to fall back to cloud-based food vision services where configured.

Large datasets and generated model artifacts should not be committed directly. Keep raw datasets, archives, and generated training outputs outside version control or use an appropriate artifact storage workflow.

## 🔒 Security Notes

- 🚫 Never commit `serviceAccount.json` or other Firebase Admin SDK private keys.
- 🔑 Keep local API keys in ignored local config files.
- 🧾 Review Firestore rules before deployment.
- 🛡️ Restrict privileged administrative operations to Cloud Functions or server-side code.

## 📍 Project Status

SmartBunda is an academic final-year project implementation with production-oriented structure and Firebase integration. The current codebase is suitable for demonstration, testing, and continued feature development toward a maternal care and nutrition management platform.
