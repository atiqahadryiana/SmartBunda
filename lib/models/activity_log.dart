enum ActivityType {
  login,
  logout,
  register,
  approvalRequested,
  approvalCompleted,
  userCreated,
  userUpdated,
  userDeactivated,
  passwordResetRequested,
  passwordResetCompleted,
  passwordResetAdmin,
}

extension ActivityTypeLabel on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.login:
        return 'Login';
      case ActivityType.logout:
        return 'Logout';
      case ActivityType.register:
        return 'Registration';
      case ActivityType.approvalRequested:
        return 'Approval requested';
      case ActivityType.approvalCompleted:
        return 'Approval completed';
      case ActivityType.userCreated:
        return 'User created';
      case ActivityType.userUpdated:
        return 'User updated';
      case ActivityType.userDeactivated:
        return 'User deactivated';
      case ActivityType.passwordResetRequested:
        return 'Password reset requested';
      case ActivityType.passwordResetCompleted:
        return 'Password reset completed';
      case ActivityType.passwordResetAdmin:
        return 'Admin password reset';
    }
  }
}

class ActivityLogEntry {
  ActivityLogEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.message,
    this.actorId,
    this.subjectId,
  });

  final String id;
  final DateTime timestamp;
  final ActivityType type;
  final String message;
  final String? actorId;
  final String? subjectId;
}
