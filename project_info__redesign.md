# SmartBunda — Usability & Workflow Redesign (Design Deliverables)

This document accompanies the code changes delivered in the usability redesign.
It covers the screen hierarchy, the consultation-workflow database design (ERD +
Firestore structure), the improved Digital First Assessment flow, the deferred
chat module design, and Material Design 3 recommendations.

---

## 1. What changed (code) vs. what is designed (this doc)

| Area | Status |
|------|--------|
| 1. Remove "Management, Counselling & Referral" box | ✅ Implemented |
| 2. Revise Digital First Assessment (strict keep-list wizard) | ✅ Implemented |
| 3. Patient Settings page (language, appearance, notifications, legal) | ✅ Implemented |
| 4. Remove patient report upload | ✅ Implemented |
| 5. Fix chat button errors | 📐 Designed (deferred build — see §6) |
| 6. Consultation workflow database design | 📐 Designed (this doc, §4) |
| 7. Healthcare-professional dashboard filters | ✅ Implemented |
| 8. Healthcare-professional profile redesign | ✅ Implemented |
| 9. Pre-pregnancy assessment improvements | ✅ Implemented (same screen as #2) |
| Dark mode wired app-wide (Light/Dark/System) | ✅ Implemented |

---

## 2. Updated screen hierarchy

```
SmartbundaApp (MaterialApp)
├── SplashGate → Login / Register / GetStarted
│
├── PATIENT (role: patient)
│   ├── Home (PatientDashboardScreen)
│   │   ├── → PrePregnancyAssessmentScreen  ← rebuilt: 6-step wizard + results
│   │   └── → EducationScreen (AI assistant demo box)
│   ├── Scan (FoodScanScreen → FoodAnalysisResultScreen)
│   ├── History (HealthRecordScreen)         ← upload removed; view/download/share only
│   └── Profile (ProfileScreen)
│       ├── → EditProfileScreen
│       └── → SettingsScreen                 ← NEW
│           ├── Language (EN / BM)
│           ├── Appearance (Light / Dark / System)
│           ├── Notifications (on/off)
│           └── Legal: Privacy / Terms / Help / About (InfoPageScreen)
│
├── HEALTHCARE PROFESSIONAL (doctor / nurse / dietitian)
│   ├── Dashboard (StaffDashboardScreen)
│   ├── Today's Patients (StaffTodayPatientsScreen)  ← NEW filters + count header
│   │   └── Filters: Status · Session slot · Type ; Header: Total / Today / Filtered
│   ├── Health Records (StaffHealthRecordsScreen)
│   ├── Appointments (AppointmentsScreen)
│   └── Profile (ProfileScreen → ProfessionalProfileScreen)   ← NEW
│       ├── Professional Information (Name, MMC, Email, Phone, Specialization) [editable]
│       ├── Account Settings → SettingsScreen + ChangePasswordScreen
│       ├── Professional Settings → ProfessionalAvailabilityScreen   ← NEW
│       └── Security → ChangePasswordScreen, 2FA toggle, Logout
│
└── ADMIN (role: admin)
    └── AdminOverviewScreen (unchanged)
```

New files: `settings_screen.dart`, `legal/info_page_screen.dart`,
`professional_profile_screen.dart`, `change_password_screen.dart`,
`professional_availability_screen.dart`, `providers/theme_provider.dart`,
`models/assessment_input.dart`.

---

## 3. Improved Digital First Assessment flow

A 6-step Material Design 3 wizard with a progress indicator, replacing the old
single long form. Strict keep-list — only risk-relevant fields are collected.

```
Step 1 Personal      → Age, Height, Weight, BMI (auto)
Step 2 Pregnancy     → Planning pregnancy, Currently pregnant, Trimester (1/2/3)
Step 3 Medical       → Diabetes, Epilepsy, CKD, Prev. complications, PPH history
Step 4 Lifestyle     → Caffeine (mg), Smoking, Alcohol, Activity (low/mod/high)
Step 5 Nutrition     → Calcium, Iron, Iodine intake
Step 6 Laboratory    → Hemoglobin (g/dL)
        ↓
Results  → Overall risk · AI Health Summary · Detected Risks ·
           Clinical Recommendations · Nutritional Requirements · Disclaimer
```

- Inputs map to `AssessmentInput` (`lib/models/assessment_input.dart`), which
  builds a `ClinicalInput` for `ClinicalRuleEngine.evaluate()`.
- `currentlyPregnant` + `trimester` set the `ClinicalContext`
  (prePregnancy / trimesterOne/Two/Three).
- Two new engine inputs were added: `ironMgPerDay` and `activityLevel`, with
  rules SB-GEN-01 (low dietary iron) and SB-GEN-02 (sedentary lifestyle).
- **Removed sections:** the 8-step workflow card, the legacy text engine, and the
  entire "Management, Counselling and Referral Plan" card.
- **Trade-off:** blood pressure inputs were removed per the strict keep-list, so
  the engine's BP-driven hypertension/preeclampsia rules no longer fire. All
  other rules (anaemia, BMI, NTD, diabetes, CKD, caffeine, calcium, iodine, iron,
  activity) are unaffected. Re-introduce a BP step if BP-based screening is
  required later.

---

## 4. Consultation workflow — database design

### 4.1 Entity Relationship Diagram (ERD)

```
┌───────────────┐
│     Users     │  (auth + role; one row per account)
│───────────────│
│ PK userId     │
│    role       │
│    name       │
│    email      │
│    phone      │
└──────┬────────┘
       │ 1
       │
   ┌───┴───────────────────────────────┐
   │ 1                                  │ 1
┌──┴────────────┐              ┌────────┴────────────────┐
│   Patients    │              │ HealthcareProfessionals │
│───────────────│              │─────────────────────────│
│ PK patientId  │              │ PK professionalId       │
│ FK userId     │              │ FK userId               │
│ pregnancyStat │              │    MMCNumber            │
│ trimester     │              │    specialization       │
└──┬─────────┬──┘              └──────────┬──────────────┘
   │ 1       │ 1                          │ 1
   │         │                            │
   │         │      ┌─────────────────────┴───┐
   │         │      │      Appointments        │
   │         │      │──────────────────────────│
   │         └─────►│ PK appointmentId         │◄──────┐
   │   (patientId)  │ FK patientId             │       │
   │                │ FK professionalId        │       │
   │                │    appointmentDate       │       │
   │                │    sessionSlot           │       │
   │                │    appointmentType       │       │
   │                │    status                │       │
   │                └──────────┬───────────────┘       │
   │                           │ 1                      │
   │                           │                        │
   │                    ┌──────┴───────────┐            │
   │                    │  Consultations   │            │
   │                    │──────────────────│            │
   │                    │ PK consultationId│            │
   │                    │ FK appointmentId │────────────┘
   │                    │    notes         │
   │                    │    recommendations
   │                    │    createdAt     │
   │                    └──────────────────┘
   │ 1
   │       ┌───────────────────┐         ┌──────────────────┐
   ├──────►│      Reports      │         │   ChatMessages   │
   │       │───────────────────│         │──────────────────│
   │       │ PK reportId       │         │ PK messageId     │
   │       │ FK patientId      │         │ FK senderId      │
   │       │ FK professionalId │         │ FK receiverId    │
   │       │    reportType     │         │    content       │
   │       │    reportUrl      │         │    timestamp     │
   │       └───────────────────┘         └──────────────────┘
```

### 4.2 Relationship summary

| Relationship | Cardinality |
|--------------|-------------|
| Users → Patients | 1 : 0..1 (a patient account has one patient profile) |
| Users → HealthcareProfessionals | 1 : 0..1 |
| Patient → Appointments | 1 : N |
| Professional → Appointments | 1 : N |
| Appointment → Consultation | 1 : 0..1 |
| Patient → Reports | 1 : N |
| Professional → Reports | 1 : N (author) |
| User ↔ User (ChatMessages) | N : N via sender/receiver |

### 4.3 Firestore collection structure

The schema reconciles the requested tables with the existing `FS` paths in
`lib/firestore_paths.dart`. Existing collections are reused where they already
cover a requested table.

```
Users/{userId}
  email, fullName, role (ADMIN|DOCTOR|NURSE|PATIENT|DIETITIAN),
  status (ACTIVE|PENDING|INACTIVE|REJECTED), phone,
  mmcNumber, jlmNumber, specialization,            ← professionals
  permissions[], createdAt, lastLoginAt,
  settings: { themeMode, locale, notificationsEnabled,   ← NEW (this redesign)
              availability: { Monday:[Morning,Afternoon], ... },
              defaultAppointmentType }

PatientProfiles/{userId}            (existing — the "Patients" table)
  dob, heightCm, currentWeightKg, bloodType, hemoglobinGdl,
  abdominalCircumferenceCm, medicalConditions[], conditionNotes

Pregnancies/{pregnancyId}           (existing — pregnancyStatus/trimester)
  patientId, gestationalWeek, trimester, edd, riskLevel, updatedAt

Appointments/{appointmentId}        (existing — extend with fields below)
  patientId, providerId, dateTime, type, status
  + sessionSlot (Morning|Afternoon|Evening)        ← recommended explicit field
                                                     (currently derived from hour)

Consultations/{consultationId}      ← NEW collection (consultation notes)
  appointmentId, patientId, professionalId,
  notes, recommendations, createdAt

Reports/{reportId}                  (existing)
  patientId, professionalId, reportType, reportUrl, reportDate

ChatMessages/{messageId}            ← NEW collection (see §6)
  conversationId, senderId, receiverId, content, timestamp, readAt
```

Indexes to add: `Appointments` composite on `(providerId, dateTime)` and
`(patientId, dateTime)`; `ChatMessages` on `(conversationId, timestamp)`.

---

## 5. Consultation workflow architecture

```
1. Patient books      → Appointment created (status SCHEDULED, sessionSlot, type)
2. Professional view  → Today's Patients dashboard filters by status/slot/type
3. Confirm            → status → CONFIRMED
4. Consultation       → Consultation doc created (notes, recommendations)
5. Outcome            → status → COMPLETED | CANCELLED | NO_SHOW
6. Follow-up          → optional new Appointment (type Follow Up) +
                        Report generated by professional (Reports collection)
```

Status lifecycle: `SCHEDULED → CONFIRMED → COMPLETED` with side exits to
`CANCELLED` / `NO_SHOW`. All status comparisons in the app are case-insensitive
(`AppointmentFilterService`), so persisted `SCHEDULED`/`scheduled` both match —
this fixes a latent bug where the old filter compared lowercase only.

---

## 6. Chat module — design (deferred build)

There is currently **no real chat feature**; only a demo box embedded in
`EducationScreen` with hardcoded keyword replies, no persistence, and no
navigation entry. Recommended build for a real patient ↔ professional chat:

**Data**
- `ChatMessages/{messageId}`: `conversationId`, `senderId`, `receiverId`,
  `content`, `timestamp`, `readAt`.
- Conversation id = deterministic `min(uidA,uidB)_max(uidA,uidB)` so the pair
  always resolves to one thread.

**Code**
- `lib/models/chat_message.dart` (model) + `lib/services/chat_repository.dart`
  (Firestore + in-memory impls behind a provider, matching the existing
  repository pattern).
- `chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>`
  watching `ChatMessages` where `conversationId == id` ordered by `timestamp`.
- `lib/screens/chat_screen.dart`: message list + composer; send writes a doc.
- Nav entry: add a "Messages" tab (patient + professional) in `home_screen.dart`,
  gated by a new `AccessPermission.messaging` (or reuse `monitoringAlerts`).

**Fixes for the existing demo box (if kept short-term)**
- Wrap `_generateResponse`/send in try/catch with a visible error state.
- Give it a real entry point (button) instead of being buried in Education.
- Disable the send button while empty; show a "demo only" badge.

**Security rules (sketch)**
```
match /ChatMessages/{id} {
  allow read, create: if request.auth.uid in
    [resource.data.senderId, resource.data.receiverId];
}
```

---

## 7. Material Design 3 recommendations

- **Theme:** `ThemeMode` is now driven by `appThemeModeProvider`
  (Light/Dark/System), persisted in SharedPreferences and mirrored to
  `Users/{uid}.settings`. `app.dart` no longer hardcodes light mode.
- **Color:** keep the pink/white identity — Primary `#F48FB1`, Dark `#EC407A`,
  Accent `#FF5C8A`. Ensure ≥ 4.5:1 contrast for body text in both themes; audit
  any remaining hardcoded `Color(0xFF…)` literals so they resolve from the
  `ColorScheme` in dark mode.
- **Components:** prefer `SegmentedButton`, `FilterChip`, `SwitchListTile`,
  `RadioGroup` (the non-deprecated radio API on Flutter ≥ 3.32), and `Card` with
  grouped `ListTile`s — all used in the new Settings/assessment/profile screens.
- **Touch targets:** all interactive rows are ≥ 48 px; wizard nav buttons use
  16 px vertical padding.
- **Accessibility:** icon-only buttons carry tooltips; the assessment progress is
  announced as "Step n of 6" with a percentage; color is never the only signal
  (risk severity also shows a text label).
- **Motion:** wizard page transitions use 250 ms `easeInOut`; keep
  micro-interactions in the 150–300 ms range.

---

## 8. Follow-ups / next phase

1. Build the real chat module per §6.
2. Add an explicit `sessionSlot` field on `Appointment` writes (currently derived
   from the hour at read time) and the `Consultations` collection wiring.
3. Implement real 2FA (the profile toggle is a persisted placeholder).
4. Dark-mode color audit across older screens that use literal colors.
5. Optionally re-introduce a Blood Pressure step in the assessment to re-enable
   BP-based screening rules.
