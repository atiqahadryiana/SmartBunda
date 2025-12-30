import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/activity_log.dart';
import '../models/app_user.dart';
import 'auth_repository.dart';

class _AuthRecord {
  _AuthRecord({
    required this.user,
    required this.passwordHash,
    required this.salt,
  });

  AppUser user;
  String passwordHash;
  String salt;
}

class _PendingApproval {
  _PendingApproval({
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.role,
    required this.requestedAt,
    this.displayName,
    this.mmcNumber,
    this.jlmNumber,
  });

  final String email;
  final String passwordHash;
  final String salt;
  final UserRole role;
  final DateTime requestedAt;
  final String? displayName;
  final String? mmcNumber;
  final String? jlmNumber;
}

class _ResetToken {
  _ResetToken({
    required this.code,
    required this.expiresAt,
  });

  final String code;
  final DateTime expiresAt;
}

class InMemoryAuthRepository implements AuthRepository {
  final Map<String, _AuthRecord> _recordsById = {};
  final Map<String, String> _idByEmail = {};
  final Map<String, _PendingApproval> _pendingApprovals = {};
  final Map<String, _ResetToken> _resetTokensByEmail = {};
  final List<ActivityLogEntry> _activityLogs = [];
  final _rand = Random.secure();
  AppUser? _currentUser;
  late final StreamController<AppUser?> _authController;
  late final StreamController<List<AppUser>> _usersController;
  late final StreamController<List<ActivityLogEntry>> _activityController;

  InMemoryAuthRepository() {
    _authController = StreamController<AppUser?>.broadcast(
      onListen: () => _authController.add(_currentUser),
    );
    _usersController = StreamController<List<AppUser>>.broadcast(
      onListen: _emitUsers,
    );
    _activityController = StreamController<List<ActivityLogEntry>>.broadcast(
      onListen: _emitActivity,
    );
    // Seed with sample accounts for each role.
    _seedUser(
      AppUser(
        id: _id(),
        email: 'admin@example.com',
        role: UserRole.admin,
        displayName: 'Admin',
      ),
    );
    _seedUser(
      AppUser(
        id: _id(),
        email: 'doctor@example.com',
        role: UserRole.doctor,
        displayName: 'Dr. Daniel',
      ),
    );
    _seedUser(
      AppUser(
        id: _id(),
        email: 'nurse@example.com',
        role: UserRole.nurse,
        displayName: 'Nurse Nia',
      ),
    );
    _seedUser(
      AppUser(
        id: _id(),
        email: 'dietitian@example.com',
        role: UserRole.dietitian,
        displayName: 'Dietitian Dara',
      ),
    );
    _seedUser(
      AppUser(
        id: _id(),
        email: 'patient@example.com',
        role: UserRole.patient,
        displayName: 'Patient Pia',
      ),
    );
    _emitUsers();
    _authController.add(null); // emit initial signed-out state
  }

  @override
  Stream<AppUser?> authStateChanges() => _authController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<List<AppUser>> watchUsers() => _usersController.stream;

  @override
  Stream<List<ActivityLogEntry>> watchActivityLogs() => _activityController.stream;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = _normalizeEmail(email);
    final id = _idByEmail[normalized];
    if (id == null) {
      throw Exception('Invalid credentials');
    }
    final record = _recordsById[id];
    if (record == null || !_verifyPassword(record, password)) {
      throw Exception('Invalid credentials');
    }
    if (!record.user.isActive) {
      throw Exception('Account is deactivated. Contact admin.');
    }
    if (!record.user.hasPermission(AccessPermission.authentication)) {
      throw Exception('Access disabled. Contact admin.');
    }
    _currentUser = record.user;
    _authController.add(_currentUser);
    _log(
      ActivityType.login,
      'User logged in',
      actorId: record.user.id,
      subjectId: record.user.id,
    );
    return record.user;
  }

  @override
  Future<AppUser> signInWithEmailLink({required String email}) async {
    final normalized = _normalizeEmail(email);
    if (_pendingApprovals.containsKey(normalized)) {
      throw Exception('Account not approved yet.');
    }
    final id = _idByEmail[normalized];
    AppUser user;
    if (id == null) {
      user = AppUser(
        id: _id(),
        email: normalized,
        role: UserRole.patient,
        displayName: normalized.split('@').first,
      );
      _addUserRecord(user, _resetCode());
      _emitUsers();
      _log(
        ActivityType.register,
        'User registered via email link',
        actorId: user.id,
        subjectId: user.id,
      );
    } else {
      final record = _recordsById[id];
      if (record == null) {
        throw Exception('User not found');
      }
      if (!record.user.isActive) {
        throw Exception('Account is deactivated. Contact admin.');
      }
      if (!record.user.hasPermission(AccessPermission.authentication)) {
        throw Exception('Access disabled. Contact admin.');
      }
      user = record.user;
    }
    _currentUser = user;
    _authController.add(_currentUser);
    _log(
      ActivityType.login,
      'User logged in via email link',
      actorId: user.id,
      subjectId: user.id,
    );
    return user;
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
    final normalized = _normalizeEmail(email);
    if (_idByEmail.containsKey(normalized)) {
      throw Exception('Email already in use');
    }
    _validatePassword(password);
    if (_needsApproval(role)) {
      final salt = _newSalt();
      _pendingApprovals[normalized] = _PendingApproval(
        email: normalized,
        passwordHash: _hashPassword(password, salt),
        salt: salt,
        role: role,
        displayName: displayName,
        mmcNumber: mmcNumber,
        jlmNumber: jlmNumber,
        requestedAt: DateTime.now(),
      );
      _log(
        ActivityType.approvalRequested,
        'Approval requested for $normalized',
        actorId: _currentUser?.id,
      );
      throw Exception('Registration submitted. Awaiting admin approval.');
    }
    final user = AppUser(
      id: _id(),
      email: normalized,
      role: role,
      displayName: displayName,
    );
    _addUserRecord(user, password);
    _currentUser = user;
    _authController.add(_currentUser);
    _emitUsers();
    _log(ActivityType.register, 'User registered', actorId: user.id, subjectId: user.id);
    return user;
  }

  @override
  Future<void> signOut() async {
    final actor = _currentUser;
    _currentUser = null;
    _authController.add(null);
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {
      // Ignore Firebase sign-out errors when auth isn't initialized.
    }
    if (actor != null) {
      _log(
        ActivityType.logout,
        'User logged out',
        actorId: actor.id,
        subjectId: actor.id,
      );
    }
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
    final normalized = _normalizeEmail(email);
    if (_idByEmail.containsKey(normalized)) {
      throw Exception('Email already in use');
    }
    _validatePassword(password);
    final user = AppUser(
      id: _id(),
      email: normalized,
      role: role,
      displayName: displayName,
      isActive: isActive,
      permissions: permissions,
    );
    _addUserRecord(user, password);
    _emitUsers();
    _log(
      ActivityType.userCreated,
      'User account created for $normalized',
      actorId: _currentUser?.id,
      subjectId: user.id,
    );
    return user;
  }

  @override
  Future<void> updateUser({
    required String userId,
    String? displayName,
    UserRole? role,
    bool? isActive,
    Set<AccessPermission>? permissions,
  }) async {
    final record = _recordsById[userId];
    if (record == null) {
      throw Exception('User not found');
    }
    final updated = record.user.copyWith(
      displayName: displayName,
      role: role,
      isActive: isActive,
      permissions: permissions,
      permissionsExplicit: permissions != null,
    );
    record.user = updated;
    _emitUsers();
    if (_currentUser?.id == userId) {
      if (updated.isActive && updated.hasPermission(AccessPermission.authentication)) {
        _currentUser = updated;
        _authController.add(_currentUser);
      } else {
        _currentUser = null;
        _authController.add(null);
      }
    }
    if (isActive == false) {
      _log(
        ActivityType.userDeactivated,
        'User deactivated',
        actorId: _currentUser?.id,
        subjectId: userId,
      );
    } else {
      _log(
        ActivityType.userUpdated,
        'User account updated',
        actorId: _currentUser?.id,
        subjectId: userId,
      );
    }
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
  Future<void> adminResetPassword({
    required String email,
    required String newPassword,
  }) async {
    _validatePassword(newPassword);
    final normalized = _normalizeEmail(email);
    final id = _idByEmail[normalized];
    final record = id == null ? null : _recordsById[id];
    if (record == null) {
      throw Exception('User not found');
    }
    _setPassword(record, newPassword);
    _log(
      ActivityType.passwordResetAdmin,
      'Admin reset password for $normalized',
      actorId: _currentUser?.id,
      subjectId: record.user.id,
    );
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    final normalized = _normalizeEmail(email);
    if (!_idByEmail.containsKey(normalized)) {
      throw Exception('No account found for that email');
    }
    final code = _resetCode();
    _resetTokensByEmail[normalized] = _ResetToken(
      code: code,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
    _log(
      ActivityType.passwordResetRequested,
      'Password reset requested for $normalized',
      actorId: _currentUser?.id,
    );
    return code;
  }

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _validatePassword(newPassword);
    final normalized = _normalizeEmail(email);
    final token = _resetTokensByEmail[normalized];
    if (token == null ||
        token.code != code ||
        DateTime.now().isAfter(token.expiresAt)) {
      throw Exception('Invalid or expired reset code');
    }
    final id = _idByEmail[normalized];
    final record = id == null ? null : _recordsById[id];
    if (record == null) {
      throw Exception('User not found');
    }
    _setPassword(record, newPassword);
    _resetTokensByEmail.remove(normalized);
    _log(
      ActivityType.passwordResetCompleted,
      'Password reset completed for $normalized',
      actorId: record.user.id,
      subjectId: record.user.id,
    );
  }

  @override
  Future<List<PendingApproval>> pendingApprovals() async =>
      _pendingApprovals.values
          .map(
            (pending) => PendingApproval(
              email: pending.email,
              role: pending.role,
              displayName: pending.displayName,
              mmcNumber: pending.mmcNumber,
              jlmNumber: pending.jlmNumber,
            ),
          )
          .toList(growable: false);

  @override
  Future<void> approveUser({
    required String email,
    String? password,
    String? displayName,
  }) async {
    final normalized = _normalizeEmail(email);
    final pending = _pendingApprovals.remove(normalized);
    if (pending == null) {
      throw Exception('No pending approval for $normalized');
    }
    final role = pending.role;
    final user = AppUser(
      id: _id(),
      email: normalized,
      role: role,
      displayName: displayName ??
          pending.displayName ??
          (role == UserRole.dietitian ? 'Dietitian' : role.label),
    );
    if (password != null && password.isNotEmpty) {
      _addUserRecord(user, password);
    } else {
      _addUserRecordWithHash(user, pending.passwordHash, pending.salt);
    }
    _emitUsers();
    _log(
      ActivityType.approvalCompleted,
      'Approved $normalized',
      actorId: _currentUser?.id,
      subjectId: user.id,
    );
  }

  @override
  Future<void> rejectUser(String email) async {
    _pendingApprovals.remove(_normalizeEmail(email));
  }

  @override
  Map<String, dynamic> exportState() {
    return {
      'users': _recordsById.values
          .map(
            (record) => {
              'id': record.user.id,
              'email': record.user.email,
              'role': record.user.role.name,
              'displayName': record.user.displayName,
              'isActive': record.user.isActive,
              'permissions': record.user.permissions?.map((p) => p.name).toList(),
              'passwordHash': record.passwordHash,
              'salt': record.salt,
            },
          )
          .toList(),
      'pendingApprovals': _pendingApprovals.values
          .map(
            (pending) => {
              'email': pending.email,
              'passwordHash': pending.passwordHash,
              'salt': pending.salt,
              'role': pending.role.name,
              'displayName': pending.displayName,
              'mmcNumber': pending.mmcNumber,
              'jlmNumber': pending.jlmNumber,
              'requestedAt': pending.requestedAt.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  @override
  void restoreState(Map<String, dynamic> data) {
    _recordsById.clear();
    _idByEmail.clear();
    _pendingApprovals.clear();
    _resetTokensByEmail.clear();
    _activityLogs.clear();
    _currentUser = null;
    _authController.add(null);

    final rawUsers = data['users'];
    if (rawUsers is List) {
      for (final raw in rawUsers.whereType<Map>()) {
        final json = raw.cast<String, dynamic>();
        final user = AppUser(
          id: json['id'] as String,
          email: json['email'] as String,
          role: _roleFromString(json['role'] as String?),
          displayName: json['displayName'] as String?,
          isActive: json['isActive'] as bool? ?? true,
          permissions: _permissionsFromJson(json['permissions']),
        );
        _recordsById[user.id] = _AuthRecord(
          user: user,
          passwordHash: json['passwordHash'] as String,
          salt: json['salt'] as String,
        );
        _idByEmail[user.email] = user.id;
      }
    }

    final rawPending = data['pendingApprovals'];
    if (rawPending is List) {
      for (final raw in rawPending.whereType<Map>()) {
        final json = raw.cast<String, dynamic>();
        final email = json['email'] as String;
        _pendingApprovals[email] = _PendingApproval(
          email: email,
          passwordHash: json['passwordHash'] as String,
          salt: json['salt'] as String,
          role: _roleFromString(json['role'] as String?),
          displayName: json['displayName'] as String?,
          mmcNumber: json['mmcNumber'] as String?,
          jlmNumber: json['jlmNumber'] as String?,
          requestedAt: DateTime.parse(json['requestedAt'] as String),
        );
      }
    }

    _emitUsers();
    _emitActivity();
  }

  void _seedUser(AppUser user) {
    _addUserRecord(user, 'password');
  }

  void _addUserRecord(AppUser user, String password) {
    final salt = _newSalt();
    final record = _AuthRecord(
      user: user,
      passwordHash: _hashPassword(password, salt),
      salt: salt,
    );
    _recordsById[user.id] = record;
    _idByEmail[user.email] = user.id;
  }

  void _addUserRecordWithHash(AppUser user, String hash, String salt) {
    _recordsById[user.id] = _AuthRecord(
      user: user,
      passwordHash: hash,
      salt: salt,
    );
    _idByEmail[user.email] = user.id;
  }

  void _setPassword(_AuthRecord record, String password) {
    final salt = _newSalt();
    record.salt = salt;
    record.passwordHash = _hashPassword(password, salt);
  }

  bool _verifyPassword(_AuthRecord record, String password) {
    return record.passwordHash == _hashPassword(password, record.salt);
  }

  void _emitUsers() {
    _usersController.add(_recordsById.values.map((r) => r.user).toList());
  }

  void _emitActivity() {
    _activityController.add(List.unmodifiable(_activityLogs));
  }

  void _log(
    ActivityType type,
    String message, {
    String? actorId,
    String? subjectId,
  }) {
    _activityLogs.add(
      ActivityLogEntry(
        id: _id(),
        timestamp: DateTime.now(),
        type: type,
        message: message,
        actorId: actorId,
        subjectId: subjectId,
      ),
    );
    _emitActivity();
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  void _validatePassword(String password) {
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
  }

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  String _newSalt() {
    final bytes = List<int>.generate(16, (_) => _rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _resetCode() => (_rand.nextInt(900000) + 100000).toString();

  String _id() => (_rand.nextInt(900000) + 100000).toString();

  bool _needsApproval(UserRole role) {
    return role == UserRole.doctor ||
        role == UserRole.nurse ||
        role == UserRole.dietitian;
  }

  UserRole _roleFromString(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'doctor':
        return UserRole.doctor;
      case 'nurse':
        return UserRole.nurse;
      case 'dietitian':
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
    switch (value) {
      case 'userManagement':
        return AccessPermission.userManagement;
      case 'authentication':
        return AccessPermission.authentication;
      case 'patientProfiles':
        return AccessPermission.patientProfiles;
      case 'foodLogging':
        return AccessPermission.foodLogging;
      case 'nutritionAnalysis':
        return AccessPermission.nutritionAnalysis;
      case 'nutritionPlans':
        return AccessPermission.nutritionPlans;
      case 'monitoringAlerts':
        return AccessPermission.monitoringAlerts;
      case 'appointments':
        return AccessPermission.appointments;
      case 'reporting':
        return AccessPermission.reporting;
      case 'education':
        return AccessPermission.education;
      case 'systemAdministration':
        return AccessPermission.systemAdministration;
      case 'foodDatabase':
        return AccessPermission.foodDatabase;
    }
    return null;
  }

  void dispose() {
    _authController.close();
    _usersController.close();
    _activityController.close();
  }
}
