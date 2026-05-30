import 'package:smartbunda/models/activity_log.dart';
import 'package:smartbunda/models/app_user.dart';

class PendingApproval {
  const PendingApproval({
    required this.email,
    required this.role,
    this.displayName,
    this.mmcNumber,
    this.jlmNumber,
  });

  final String email;
  final UserRole role;
  final String? displayName;
  final String? mmcNumber;
  final String? jlmNumber;
}

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<AppUser> signInWithEmailLink({
    required String email,
  });

  Future<AppUser> register({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
    String? mmcNumber,
    String? jlmNumber,
  });

  Future<void> signOut();
  AppUser? get currentUser;
  Stream<List<AppUser>> watchUsers();
  Stream<List<ActivityLogEntry>> watchActivityLogs();

  Future<AppUser> createUser({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
    bool isActive = true,
    Set<AccessPermission>? permissions,
  });

  Future<void> updateUser({
    required String userId,
    String? displayName,
    UserRole? role,
    bool? isActive,
    Set<AccessPermission>? permissions,
  });

  Future<void> setUserActive({
    required String userId,
    required bool isActive,
  });

  Future<void> updateUserPermissions({
    required String userId,
    required Set<AccessPermission> permissions,
  });

  /// Update a healthcare professional's profile details (display name, MMC
  /// number, specialization, phone). Null fields are left unchanged.
  Future<void> updateProfessionalProfile({
    required String userId,
    String? displayName,
    String? mmcNumber,
    String? specialization,
    String? phone,
  });

  /// Persist per-user settings (theme/locale/notifications + arbitrary keys)
  /// under the user document's `settings` map.
  Future<void> saveUserSettings({
    required String userId,
    required Map<String, dynamic> settings,
  });

  /// Change the signed-in user's password, re-authenticating with the current
  /// password first.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> adminResetPassword({
    required String email,
    required String newPassword,
  });

  Future<String> requestPasswordReset(String email);

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<List<PendingApproval>> pendingApprovals();
  Future<void> approveUser({
    required String email,
    String? password,
    String? displayName,
  });
  Future<void> rejectUser(String email);

  Map<String, dynamic> exportState();
  void restoreState(Map<String, dynamic> data);
}
