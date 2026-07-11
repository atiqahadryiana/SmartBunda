import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:smartbunda/firestore_paths.dart';
import 'package:smartbunda/models/activity_log.dart';
import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/models/system_settings.dart';
import 'package:smartbunda/services/auth_repository.dart';
import 'package:smartbunda/utils/password_policy.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  AppUser? _currentUser;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncExpand((user) => _userStream(user));
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<List<AppUser>> watchUsers() {
    return _firestore.collection(FS.users).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => _appUserFromDoc(doc.id, doc.data()))
          .toList();
    });
  }

  @override
  Stream<List<ActivityLogEntry>> watchActivityLogs() {
    return _firestore
        .collection(FS.auditLogs)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ActivityLogEntry(
          id: doc.id,
          timestamp: _asDate(data['timestamp']) ?? DateTime.now(),
          type: activityTypeFromName(data['type'] as String?),
          message: data['message'] as String? ?? '',
          actorId: data['actorId'] as String?,
          subjectId: data['subjectId'] as String?,
        );
      }).toList();
    });
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user == null) {
      throw Exception('Unable to sign in. Try again.');
    }
    await _ensureUserDoc(user);
    final doc = await _userDoc(user.uid).get();
    final appUser = _appUserFromDoc(doc.id, doc.data());
    try {
      _guardAccess(appUser, doc.data());
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
    _currentUser = appUser;
    await _touchLogin(user.uid);
    await _log(
      ActivityType.login,
      'User logged in',
      actorId: user.uid,
      subjectId: user.uid,
    );
    return appUser;
  }

  @override
  Future<AppUser> signInWithEmailLink({required String email}) async {
    if (email.isEmpty) {
      // Email is kept for parity with passwordless flow.
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Sign-in failed. Please retry.');
    }
    await _ensureUserDoc(user);
    final doc = await _userDoc(user.uid).get();
    final appUser = _appUserFromDoc(doc.id, doc.data());
    try {
      _guardAccess(appUser, doc.data());
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
    _currentUser = appUser;
    await _touchLogin(user.uid);
    await _log(
      ActivityType.login,
      'User logged in via email link',
      actorId: user.uid,
      subjectId: user.uid,
    );
    return appUser;
  }

  bool _googleInitialized = false;

  @override
  bool get isEmailVerified {
    final user = _auth.currentUser;
    if (user == null) return false;
    // Password users must verify; federated (Google) sign-ins are pre-verified.
    if (user.emailVerified) return true;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to verify your email.');
    }
    if (user.emailVerified) return;
    await user.sendEmailVerification();
  }

  @override
  Future<bool> reloadEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final fb.UserCredential cred;
    try {
      cred = kIsWeb ? await _googleSignInWeb() : await _googleSignInMobile();
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'An account already exists with this email using a different '
          'sign-in method. Please sign in with your email and password.',
        );
      }
      rethrow;
    }

    final user = cred.user;
    if (user == null) {
      throw Exception('Google sign-in failed. Please try again.');
    }
    // First-time users get a patient, ACTIVE doc (patient-only guarantee).
    await _ensureUserDoc(user);
    final doc = await _userDoc(user.uid).get();
    final appUser = _appUserFromDoc(doc.id, doc.data());
    try {
      _guardAccess(appUser, doc.data());
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
    _currentUser = appUser;
    await _touchLogin(user.uid);
    await _log(
      ActivityType.login,
      'User logged in via Google',
      actorId: user.uid,
      subjectId: user.uid,
    );
    return appUser;
  }

  /// Web Google sign-in via Firebase's built-in popup flow. Uses the project's
  /// configured web OAuth client (from firebase_options.dart) — no extra client
  /// id needed in index.html.
  Future<fb.UserCredential> _googleSignInWeb() async {
    final provider = fb.GoogleAuthProvider()..addScope('email');
    try {
      return await _auth.signInWithPopup(provider);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') {
        throw Exception('Google sign-in was cancelled.');
      }
      if (e.code == 'popup-blocked') {
        throw Exception(
          'The sign-in popup was blocked. Please allow popups for this site '
          'and try again.',
        );
      }
      rethrow;
    }
  }

  /// Mobile Google sign-in via the native account picker (google_sign_in),
  /// exchanged for a Firebase credential.
  Future<fb.UserCredential> _googleSignInMobile() async {
    final google = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await google.initialize();
      _googleInitialized = true;
    }

    final GoogleSignInAccount account;
    try {
      account = await google.authenticate(scopeHint: const ['email']);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Google sign-in was cancelled.');
      }
      throw Exception('Google sign-in failed. Please try again.');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('Google sign-in failed: missing credentials.');
    }
    final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
    String? mmcNumber,
    String? jlmNumber,
  }) async {
    _validatePassword(password);
    if (role != UserRole.patient) {
      throw Exception(
          'Only patient accounts can be self-registered. Healthcare '
          'professional and admin accounts are created by an administrator.');
    }
    await _loadSettings();
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user == null) {
      throw Exception('Registration failed. Try again.');
    }
    final needsApproval = _requiresApproval(role);
    final status = needsApproval ? 'PENDING' : 'ACTIVE';
    await _upsertUserDoc(
      uid: user.uid,
      email: email,
      role: role,
      displayName: displayName,
      status: status,
      permissions: null,
      mmcNumber: mmcNumber,
      jlmNumber: jlmNumber,
    );
    if (needsApproval) {
      // Log while still authenticated (the AuditLogs rule requires
      // actorId == the writer's uid), then sign out to hold for approval.
      await _log(
        ActivityType.approvalRequested,
        'Approval requested for ${email.trim().toLowerCase()}',
        actorId: user.uid,
      );
      await _auth.signOut();
      throw Exception('Registration submitted. Awaiting admin approval.');
    }
    // Send a verification email so the patient can confirm ownership.
    // Non-fatal: registration still succeeds if the email fails to send.
    try {
      await user.sendEmailVerification();
    } catch (_) {
      // Ignore — the user can resend from the verification prompt.
    }
    final appUser = await _loadUser(user.uid);
    _currentUser = appUser;
    await _log(
      ActivityType.register,
      'User registered',
      actorId: user.uid,
      subjectId: user.uid,
    );
    return appUser;
  }

  @override
  Future<void> signOut() async {
    final actor = _currentUser;
    // Log BEFORE signing out: the AuditLogs rule requires the writer to be
    // authenticated as `actorId`, so a post-signout write would be denied.
    if (actor != null) {
      await _log(
        ActivityType.logout,
        'User logged out',
        actorId: actor.id,
        subjectId: actor.id,
      );
    }
    _currentUser = null;
    await _auth.signOut();
  }

  @override
  Future<AppUser> createUser({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
    bool isActive = true,
    Set<AccessPermission>? permissions,
  }) async {
    _validatePassword(password);
    final secondary = await _secondaryAuth();
    final cred = await secondary.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user == null) {
      throw Exception('Failed to create user.');
    }
    if (displayName != null && displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
    }
    await _upsertUserDoc(
      uid: user.uid,
      email: email,
      role: role,
      displayName: displayName,
      status: isActive ? 'ACTIVE' : 'INACTIVE',
      permissions: permissions,
    );
    await secondary.signOut();
    await _log(
      ActivityType.userCreated,
      'User account created for ${email.trim().toLowerCase()}',
      actorId: _currentUser?.id,
      subjectId: user.uid,
    );
    return await _loadUser(user.uid);
  }

  @override
  Future<void> updateUser({
    required String userId,
    String? displayName,
    UserRole? role,
    bool? isActive,
    Set<AccessPermission>? permissions,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) {
      updates['fullName'] = displayName;
    }
    if (role != null) {
      updates['role'] = role.name.toUpperCase();
    }
    if (isActive != null) {
      updates['status'] = isActive ? 'ACTIVE' : 'INACTIVE';
    }
    if (permissions != null) {
      updates['permissions'] = permissions.map((p) => p.name).toList();
    }
    if (updates.isNotEmpty) {
      await _userDoc(userId).set(updates, SetOptions(merge: true));
    }
    await _log(
      isActive == false
          ? ActivityType.userDeactivated
          : ActivityType.userUpdated,
      'User account updated',
      actorId: _currentUser?.id,
      subjectId: userId,
    );
  }

  @override
  Future<void> setUserActive({
    required String userId,
    required bool isActive,
  }) async {
    await updateUser(userId: userId, isActive: isActive);
  }

  @override
  Future<void> updateUserPermissions({
    required String userId,
    required Set<AccessPermission> permissions,
  }) async {
    await updateUser(userId: userId, permissions: permissions);
  }

  @override
  Future<void> updateProfessionalProfile({
    required String userId,
    String? displayName,
    String? mmcNumber,
    String? specialization,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['fullName'] = displayName.trim();
    if (mmcNumber != null) updates['mmcNumber'] = mmcNumber.trim();
    if (specialization != null) {
      updates['specialization'] = specialization.trim();
    }
    if (phone != null) updates['phone'] = phone.trim();
    if (updates.isEmpty) return;
    await _userDoc(userId).set(updates, SetOptions(merge: true));
    await _log(
      ActivityType.userUpdated,
      'Professional profile updated',
      actorId: _currentUser?.id,
      subjectId: userId,
    );
  }

  @override
  Future<void> saveUserSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    if (settings.isEmpty) return;
    await _userDoc(userId).set(
      {'settings': settings},
      SetOptions(merge: true),
    );
  }

  @override
  Future<Map<String, dynamic>> loadUserSettings(String userId) async {
    final doc = await _userDoc(userId).get();
    final raw = doc.data()?['settings'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _validatePassword(newPassword);
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('You must be signed in to change your password.');
    }
    final credential = fb.EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
    await _log(
      ActivityType.passwordResetCompleted,
      'Password changed',
      actorId: user.uid,
      subjectId: user.uid,
    );
  }

  @override
  Future<void> adminResetPassword({
    required String email,
    required String newPassword,
  }) async {
    if (newPassword.isNotEmpty) {
      // Password updates for other accounts require server-side privileges.
    }
    await _auth.sendPasswordResetEmail(email: email.trim());
    await _log(
      ActivityType.passwordResetAdmin,
      'Admin sent password reset for ${email.trim().toLowerCase()}',
      actorId: _currentUser?.id,
    );
  }

  @override
  Future<void> adminSetUserPassword({
    required String uid,
    required String email,
    required String newPassword,
  }) async {
    _validatePassword(newPassword);
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('adminSetUserPassword');
      await callable.call<Map<String, dynamic>>({
        'uid': uid,
        'email': email.trim(),
        'newPassword': newPassword,
      });
    } on FirebaseFunctionsException catch (e) {
      // Surface the function's own message (permission-denied, not-found, …)
      // rather than a raw plugin error.
      throw Exception(e.message ?? 'Could not set the password (${e.code}).');
    }
    // The function writes its own AuditLogs entry server-side; mirror a local
    // activity log so the admin's own view updates immediately.
    await _log(
      ActivityType.passwordSetAdmin,
      'Admin set a new password for ${email.trim().toLowerCase()}',
      actorId: _currentUser?.id,
    );
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
    await _log(
      ActivityType.passwordResetRequested,
      'Password reset requested for ${email.trim().toLowerCase()}',
      actorId: _currentUser?.id,
    );
    return 'Password reset email sent. Use the code in your email.';
  }

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _validatePassword(newPassword);
    await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
    await _log(
      ActivityType.passwordResetCompleted,
      'Password reset completed for ${email.trim().toLowerCase()}',
      actorId: _currentUser?.id,
    );
  }

  @override
  Future<List<PendingApproval>> pendingApprovals() async {
    final snapshot = await _firestore
        .collection(FS.users)
        .where('status', isEqualTo: 'PENDING')
        .get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          return PendingApproval(
            email: data['email'] as String? ?? '',
            role: _roleFromString(data['role'] as String?),
            displayName: data['fullName'] as String?,
            mmcNumber: data['mmcNumber'] as String?,
            jlmNumber: data['jlmNumber'] as String?,
          );
        })
        .where((approval) => _requiresApproval(approval.role))
        .toList();
  }

  @override
  Future<void> approveUser({
    required String email,
    String? password,
    String? displayName,
  }) async {
    if (password != null && password.isNotEmpty) {
      // Password setting is handled through email reset on the client.
    }
    final query = await _firestore
        .collection(FS.users)
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw Exception('No pending approval for ${email.trim().toLowerCase()}');
    }
    final doc = query.docs.first;
    await doc.reference.set(
      {
        'status': 'ACTIVE',
        if (displayName != null && displayName.isNotEmpty)
          'fullName': displayName,
      },
      SetOptions(merge: true),
    );
    await _log(
      ActivityType.approvalCompleted,
      'Approved ${email.trim().toLowerCase()}',
      actorId: _currentUser?.id,
      subjectId: doc.id,
    );
  }

  @override
  Future<void> rejectUser(String email) async {
    final query = await _firestore
        .collection(FS.users)
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return;
    await query.docs.first.reference.set(
      {'status': 'REJECTED'},
      SetOptions(merge: true),
    );
  }

  @override
  Map<String, dynamic> exportState() => {};

  @override
  void restoreState(Map<String, dynamic> data) {}

  Stream<AppUser?> _userStream(fb.User? user) async* {
    if (user == null) {
      _currentUser = null;
      yield null;
      return;
    }
    await _ensureUserDoc(user);
    yield* _userDoc(user.uid).snapshots().asyncMap((doc) async {
      final appUser = _appUserFromDoc(doc.id, doc.data());
      try {
        _guardAccess(appUser, doc.data());
      } catch (_) {
        await _auth.signOut();
        _currentUser = null;
        return null;
      }
      _currentUser = appUser;
      return appUser;
    });
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection(FS.users).doc(uid);
  }

  Future<void> _ensureUserDoc(fb.User user) async {
    final doc = await _userDoc(user.uid).get();
    if (doc.exists) return;
    await _upsertUserDoc(
      uid: user.uid,
      email: user.email ?? '',
      role: UserRole.patient,
      displayName: user.displayName,
      status: 'ACTIVE',
      permissions: null,
    );
  }

  Future<SystemSettings> _loadSettings() async {
    try {
      final doc = await _firestore
          .collection(FS.systemSettings)
          .doc(FS.globalSettingsDoc)
          .get();
      final data = doc.data();
      if (data != null) {
        return SystemSettings.fromJson(data);
      }
    } catch (_) {
      // Ignore settings load failures.
    }
    return SystemSettings();
  }

  Future<void> _upsertUserDoc({
    required String uid,
    required String email,
    required UserRole role,
    required String status,
    String? displayName,
    Set<AccessPermission>? permissions,
    String? mmcNumber,
    String? jlmNumber,
  }) async {
    await _userDoc(uid).set(
      {
        'email': email.trim().toLowerCase(),
        'fullName': displayName,
        'role': role.name.toUpperCase(),
        'status': status,
        'permissions': permissions?.map((p) => p.name).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        if (mmcNumber != null) 'mmcNumber': mmcNumber,
        if (jlmNumber != null) 'jlmNumber': jlmNumber,
      },
      SetOptions(merge: true),
    );
  }

  Future<AppUser> _loadUser(String uid) async {
    final doc = await _userDoc(uid).get();
    return _appUserFromDoc(uid, doc.data());
  }

  void _guardAccess(AppUser user, Map<String, dynamic>? data) {
    final status =
        _statusFromRaw(data?['status'], data?['isActive'], user.isActive);
    if (status == _UserStatus.pending) {
      throw Exception('Account not approved yet.');
    }
    if (status == _UserStatus.inactive) {
      throw Exception('Account is deactivated. Contact admin.');
    }
    if (!user.hasPermission(AccessPermission.authentication)) {
      throw Exception('Access disabled. Contact admin.');
    }
  }

  _UserStatus _statusFromRaw(
      dynamic status, dynamic isActiveValue, bool fallbackActive) {
    if (status is String) {
      final normalized = status.toLowerCase();
      if (normalized == 'pending') return _UserStatus.pending;
      if (normalized == 'rejected' || normalized == 'inactive') {
        return _UserStatus.inactive;
      }
      return _UserStatus.active;
    }
    if (isActiveValue is bool) {
      return isActiveValue ? _UserStatus.active : _UserStatus.inactive;
    }
    return fallbackActive ? _UserStatus.active : _UserStatus.inactive;
  }

  AppUser _appUserFromDoc(String uid, Map<String, dynamic>? data) {
    final email = (data?['email'] as String?)?.trim().toLowerCase() ?? '';
    final role = _roleFromString(data?['role'] as String?);
    final displayName =
        (data?['fullName'] as String?) ?? (data?['displayName'] as String?);
    final statusRaw = data?['status'];
    final isActive = _isActive(statusRaw, data?['isActive']);
    final permissions = _permissionsFromJson(data?['permissions']);
    return AppUser(
      id: uid,
      email: email,
      role: role,
      displayName: displayName,
      isActive: isActive,
      permissions: permissions,
      mmcNumber: (data?['mmcNumber'] as String?)?.trim(),
      specialization: (data?['specialization'] as String?)?.trim(),
      phone: (data?['phone'] as String?)?.trim(),
    );
  }

  bool _isActive(dynamic status, dynamic isActiveValue) {
    if (status is String) {
      final normalized = status.toLowerCase();
      if (normalized == 'pending' ||
          normalized == 'rejected' ||
          normalized == 'inactive') {
        return false;
      }
      return normalized == 'active';
    }
    if (isActiveValue is bool) {
      return isActiveValue;
    }
    return true;
  }

  UserRole _roleFromString(String? value) {
    final normalized = value?.trim().toLowerCase();
    switch (normalized) {
      case 'admin':
        return UserRole.admin;
      case 'doctor':
        return UserRole.doctor;
      case 'nurse':
        return UserRole.nurse;
      case 'dietitian':
      case 'nutrition':
      case 'nutritionist':
        return UserRole.dietitian;
      case 'patient':
      default:
        return UserRole.patient;
    }
  }

  Set<AccessPermission>? _permissionsFromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is! List) return null;
    return raw
        .whereType<String>()
        .map(_permissionFromString)
        .whereType<AccessPermission>()
        .toSet();
  }

  AccessPermission? _permissionFromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'usermanagement':
        return AccessPermission.userManagement;
      case 'authentication':
        return AccessPermission.authentication;
      case 'patientprofiles':
        return AccessPermission.patientProfiles;
      case 'foodlogging':
        return AccessPermission.foodLogging;
      case 'nutritionanalysis':
        return AccessPermission.nutritionAnalysis;
      case 'nutritionplans':
        return AccessPermission.nutritionPlans;
      case 'monitoringalerts':
        return AccessPermission.monitoringAlerts;
      case 'appointments':
        return AccessPermission.appointments;
      case 'reporting':
        return AccessPermission.reporting;
      case 'education':
        return AccessPermission.education;
      case 'systemadministration':
        return AccessPermission.systemAdministration;
      case 'fooddatabase':
        return AccessPermission.foodDatabase;
    }
    return null;
  }

  bool _requiresApproval(UserRole role) {
    return role == UserRole.doctor ||
        role == UserRole.nurse ||
        role == UserRole.dietitian;
  }

  Future<void> _touchLogin(String uid) {
    return _userDoc(uid).set(
      {'lastLoginAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> _log(
    ActivityType type,
    String message, {
    String? actorId,
    String? subjectId,
  }) async {
    try {
      await _firestore.collection(FS.auditLogs).add({
        'timestamp': FieldValue.serverTimestamp(),
        'type': type.name,
        'message': message,
        'actorId': actorId,
        'subjectId': subjectId,
      });
    } catch (_) {
      // Ignore logging failures to avoid blocking auth flows.
    }
  }

  void _validatePassword(String password) {
    if (!PasswordPolicy.isValid(password)) {
      throw Exception(PasswordPolicy.errorMessage);
    }
  }

  DateTime? _asDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  Future<fb.FirebaseAuth> _secondaryAuth() async {
    const name = 'admin-auth';
    FirebaseApp app;
    try {
      app = Firebase.app(name);
    } catch (_) {
      app = await Firebase.initializeApp(
        name: name,
        options: Firebase.app().options,
      );
    }
    return fb.FirebaseAuth.instanceFor(app: app);
  }
}

enum _UserStatus { active, inactive, pending }
