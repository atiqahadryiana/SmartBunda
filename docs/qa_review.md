# SmartBunda — End-to-End QA & Gap Analysis

**Scope:** Functional flows, CRUD, data persistence, business rules, validation,
error handling, edge cases, security, audit, and NFRs — reviewed against the
**actual codebase** (Flutter app + Firebase + TFLite), not an idealised spec.

**Method note:** Findings are grounded in the current source. Where the prompt's
feature list implies functionality that does not exist in code, it is listed as
**Missing**. Severities: **Critical** (patient safety / data loss / security),
**High** (core flow broken or unpersisted), **Medium** (UX/integrity gap),
**Low** (polish).

---

## 0. Architecture reality check (what actually exists)

| Area | Status in code |
|------|----------------|
| Roles | `UserRole {admin, doctor, nurse, patient, dietitian}` |
| **HCP ↔ patient assignment** | **Does NOT exist.** Staff screens read `usersProvider` / `watchAllProfiles()` — every professional sees **all** patients. No `assignedTo` / care-team field. |
| Account deletion | **No delete** in `AuthRepository`; only `setUserActive` (deactivate). |
| HCP recommendations / consultation notes | **Not implemented** (no `createRecommendation`/`addNote`; Consultations collection is design-only). |
| Firebase Storage (food/report images) | **Effectively unused** in `lib/`; food images passed as bytes, never uploaded; `FoodHistory.imageUrl` always null. |
| Push notifications (FCM) | **None.** "Notifications" are Firestore docs only; no `FirebaseMessaging`. |
| Audit fields | Only on `pregnancy`, `nutrition_plan`, `system_settings`, `firestore_doc`. Core entities (`AppUser`, `Profile`, `FoodEntry`, `AlertItem`, `Appointment`, `FoodHistory`) lack `createdBy`/`modifiedBy`/`isDeleted`. |
| Audit log | `AuditLogs` exists for auth events only (login/register/approve/password). No CRUD audit for clinical data. |
| Offline / connectivity | No connectivity detection; failures surface as generic errors. |

---

## 1. Patient Flow Review

**Working:** registration (patient-only), login, forgot-password (email reset),
profile/pregnancy edit (persisted via `dataStore.saveProfile/savePregnancy`),
food scan → IQA → confidence gating → nutrition → save (`FoodEntry` + new
`FoodHistory`), manual food picker, hydration, education + AI assistant, settings
(theme/language/notifications), reports view (no upload).

**Gaps**
- **Meal history editing/deletion (High):** `FoodEntry` can be created but there
  is **no UPDATE or DELETE** for logged meals — a wrong entry is permanent. No
  confirmation/undo.
- **Food image not stored (Medium):** `imageUrl` is never populated, so "revisit
  previous analysis image" is impossible; only text history exists.
- **Notifications are passive (Medium):** patient cannot receive real-time/push
  notifications; relies on opening the app and reading Firestore docs.
- **Recommendation status (Medium):** patients view recommendations but there is
  no read/acknowledged/acted state persisted.
- **Account deletion / data export (High, compliance):** patient cannot delete
  their account or export their health data (GDPR/PDPA-style right).
- **Dead-ends / recovery (Medium):** food analysis low-confidence "Search
  manually" / "Retake" both just `pop()` — they don't actually reopen the picker
  or camera, so the user lands back on the hub with no guided retry.

---

## 2. Healthcare Professional Flow Review

**Working:** login, view all patients, search, view profiles / nutrition records
/ appointments, dashboard filters, professional profile + availability, change
password.

**Gaps**
- **No patient assignment / data isolation (CRITICAL):** any doctor/nurse/
  dietitian can open **any** patient's full clinical record. In a real
  healthcare setting this is a serious confidentiality breach. No "my patients".
- **Create Recommendation — MISSING (High):** the prompt lists it; there is no
  create path, no persistence, no patient notification.
- **Create/Edit/Delete Notes — MISSING (High):** consultation notes don't exist
  in code (Consultations collection is documented but unbuilt).
- **Send Notification — MISSING (High):** no HCP→patient notification creation.
- **Monitor compliance (Medium):** viewing is read-only; no "reviewed" logging,
  no flag/alert creation tied to a patient by the professional.
- **Offline recommendation creation (edge):** N/A until the feature exists, but
  when built it needs offline queueing + conflict handling.

---

## 3. Admin Flow Review

**Working:** login, dashboard, user directory, approvals, create user
(`createUser`), activate/deactivate, permissions, system settings, backups,
food catalog view, analytics, audit-log view (auth events), reports.

**Gaps**
- **User DELETE — MISSING (High):** only deactivate exists. No removal from Auth
  + Firestore, and **no cascade cleanup** of the user's profiles/entries/
  appointments/history → orphaned data.
- **Food DB write reflected in analysis (Medium):** patient nutrition uses the
  **offline** `LocalNutritionLookup` (compiled-in `food_nutrition_lookup.dart`),
  **not** the Firestore `Foods` collection the admin edits — so admin food-DB
  changes do **not** affect patient food analysis. Major source/consistency gap.
- **Article management lifecycle (Medium):** `upsertEducationContent` exists, but
  publish/unpublish/version/`isActive` toggling and "visible to users"
  verification are partial; no scheduled publish, no audit of who edited.
- **Report generation (Medium):** reports are generated client-side (PDF) but not
  persisted as artifacts with ownership/retention.
- **Notification management — MISSING broadcast (Medium):** no admin broadcast/
  targeted-notification create flow with delivery tracking.

---

## 4. Missing Functional Requirements (consolidated)

1. HCP↔patient **assignment** model + "my patients" filtering. *(Critical)*
2. HCP **recommendation** create/read/update/delete + patient delivery. *(High)*
3. HCP **consultation notes** CRUD. *(High)*
4. **Notification delivery** (FCM push or at least unread/read state + badges). *(High)*
5. Patient **meal entry** edit/delete. *(High)*
6. **Account deletion** + cascade cleanup + data export. *(High)*
7. Single **source of truth for food nutrition** (reconcile offline DB vs
   Firestore `Foods`). *(High)*
8. **Image upload to Storage** for food/reports + secure retrieval. *(Medium)*
9. Recommendation **acknowledgement** status. *(Medium)*
10. Article **publish lifecycle** + visibility verification. *(Medium)*

## 5. Missing Non-Functional Requirements

- **Offline support / connectivity detection** (queue writes, cached reads).
- **Performance:** large `watchAll*` streams (all users/profiles/entries) loaded
  wholesale into admin/HCP screens — won't scale; needs pagination/queries.
- **Reliability:** no retry/backoff on Firestore/Storage failures.
- **Backup/recovery:** in-app "backups" are JSON snapshots, not a DR strategy.
- **Accessibility:** verify 4.5:1 contrast in both themes, screen-reader labels,
  ≥48px targets (partially addressed in recent theme work).
- **Data integrity:** no transactional writes where multiple docs must change
  together (e.g. save FoodEntry + FoodHistory are independent best-effort).

## 6–9. Missing CRUD / Save / Update / Delete (by entity)

| Entity | Create | Read | Update | Delete | Note |
|--------|:--:|:--:|:--:|:--:|------|
| FoodEntry (meal) | ✅ | ✅ | ❌ | ❌ | no edit/delete of logged meals |
| FoodHistory | ✅ | ✅ | — | ❌ | no delete; image never saved |
| Recommendation (HCP) | ❌ | ✅ | ❌ | ❌ | create path missing |
| Consultation note | ❌ | ❌ | ❌ | ❌ | not built |
| User account | ✅ | ✅ | ✅ | ❌ | deactivate only; no delete+cascade |
| Profile / Pregnancy | ✅ | ✅ | ✅ | ❌ | no delete; no isDeleted |
| Foods (admin) | ✅ | ✅ | ✅ | ✅ | but not used by patient analysis |
| Article/Education | ✅ | ✅ | ✅ | ✅(doc) | lifecycle/publish gaps |
| Appointment | ✅ | ✅ | ✅ | ✅(cancel) | status case bug fixed earlier |
| Notification | ✅(staff) | ✅ | ❌ | ❌ | no delivery/read state |

## 10. Missing Validation Rules

- Profile: height/weight/Hb **range checks** (reject negative/absurd values);
  DOB not in future; trimester 1–3 only.
- Registration: password policy is enforced; add **duplicate-email** friendly
  handling and email-format edge cases.
- Food portion: clamp 10–1000 g (slider OK) but manual entries unvalidated.
- Image: type/size limits before analysis (IQA handles quality, not file type/
  size caps or corrupt-decode messaging beyond "invalid").
- MMC/specialization/phone: format validation absent.

## 11. Missing Business Rules

- **Authorization:** professional should access **only assigned** patients.
- Patient should **not** be able to silently delete clinical history that a
  clinician relies on (or deletes must be soft + audited).
- Deactivated/deleted users must be **excluded from reports/analytics**
  (currently `watchAll*` includes everyone regardless of status).
- Admin self-lockout prevention (can't deactivate the last admin).
- What happens to a patient's data when their HCP leaves — reassignment rule.

## 12. Missing Error Handling

- **No connectivity layer** → offline actions fail with generic messages; no
  queue/retry. *(High)*
- Firestore **permission-denied** not specifically surfaced (will look like a
  generic failure after the new rules).
- Storage upload failures: N/A today (no uploads) but required once added.
- **Mid-submission interruption** (app killed during save): no idempotency /
  resumable write; possible partial state (FoodEntry saved, history not).
- Session expiration: relies on Firebase auth stream; no explicit "session
  expired, please re-login" UX.

## 13. Missing Security Controls

- **Firestore data isolation for staff (CRITICAL):** rules currently allow any
  `isStaff()` to read all clinical collections. With no assignment model, this is
  over-broad. Recommend assignment-scoped rules.
- **Storage rules:** none meaningful yet (no uploads); must be added before
  enabling image upload, scoped to owner + assigned staff.
- **Users role-escalation:** addressed (rules now pin self-register to patient
  and block self role/permission changes) — verify deployed.
- **PII at rest / in logs:** ensure audit messages don't store sensitive health
  details.
- **No rate limiting** on auth/reset (Firebase provides some; document it).

## 14. Missing Edge Cases

- Blurry/unsupported image → **handled** by new IQA gating. ✅
- App closed during upload/analysis → partial save risk (see §12).
- Logout mid-analysis → in-flight async may `setState` after unmount (guarded in
  new code with `mounted` checks; audit older screens).
- HCP reviews a **deactivated/deleted** patient → no guard; record still opens.
- Admin updates nutrition DB during active use → no effect on patients (see §3).
- Two devices editing same profile → last-write-wins, no conflict detection.
- Empty states: most screens have them; verify history/analytics with 0 data.

## 15. Risk Assessment

| Risk | Likelihood | Impact | Severity |
|------|-----------|--------|----------|
| Any HCP sees any patient (no isolation) | High | High | **Critical** |
| Admin food-DB edits don't affect analysis | High | Med | **High** |
| Meal entries can't be corrected/deleted | High | Med | **High** |
| No account deletion / data export (compliance) | Med | High | **High** |
| No offline handling → data loss on poor network | High | Med | **High** |
| Partial writes (FoodEntry vs FoodHistory) | Med | Med | **Medium** |
| `watchAll*` non-scalable reads | Med | Med | **Medium** |
| Sparse audit fields on clinical data | Med | Med | **Medium** |

---

## Summary table

| User Role | Module | Missing Flow | Missing Save Operation | Severity | Recommendation |
|-----------|--------|--------------|------------------------|----------|----------------|
| HCP | Patient access | "My assigned patients" | `assignedTo` on patient + scoped query | Critical | Add assignment model + Firestore rule isolation |
| HCP | Recommendations | Create/notify | Persist `Recommendation` + notification doc | High | Build CRUD + delivery + ack status |
| HCP | Notes | Create/edit/delete | Persist `Consultations`/notes | High | Build per design doc schema |
| Patient | Meal history | Edit / delete entry | `updateEntry` / `deleteEntry` | High | Add CRUD + confirm + soft-delete |
| Patient | Account | Delete / export | Auth+Firestore cascade delete; export | High | Implement with cleanup + audit |
| Patient | Food analysis | Guided retake / manual on low confidence | (flow only) | Medium | Wire buttons to camera/picker, not pop |
| Patient | Food image | Revisit image | Upload to Storage, save `imageUrl` | Medium | Add Storage upload + secure rule |
| Admin | Food DB | Edits reach patients | Read `Foods` in analysis (not offline-only) | High | Unify nutrition source of truth |
| Admin | Users | Delete user | Auth+Firestore delete + cascade | High | Add delete with related-data cleanup |
| Admin | Articles | Publish lifecycle | `isActive`/publishedAt + audit | Medium | Add publish/unpublish + editor audit |
| All | Notifications | Real delivery | FCM or unread/read state | High | Add delivery + badges |
| All | Reliability | Offline / retry | Queue writes, cache reads | High | Add connectivity layer + retry |
| All | Audit | CRUD audit on clinical data | `createdBy/modifiedBy/updatedAt/isDeleted` | Medium | Standardise audit fields + soft delete |

---

### Top 5 to fix first (real-healthcare priority)
1. **HCP↔patient data isolation** (assignment model + Firestore rules). *Critical.*
2. **Unify food nutrition source** so admin DB edits actually drive analysis. *High.*
3. **Meal entry edit/delete** + soft-delete + audit. *High.*
4. **Account deletion + data export** with cascade cleanup. *High.*
5. **Offline handling + retry** to prevent silent data loss. *High.*
