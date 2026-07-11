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
  passwordSetAdmin,
}

/// Parse a stored activity-type string back into an [ActivityType].
///
/// Logs persist the type as `type.name` (camelCase, e.g. "approvalRequested"),
/// so matching is done case-insensitively against the enum's names. Unknown or
/// empty values fall back to [ActivityType.login]. Centralised here so every
/// reader stays in sync with the enum — a hand-maintained switch previously
/// lowercased the input and compared it to camelCase literals that could never
/// match, mislabelling most entries as logins.
ActivityType activityTypeFromName(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return ActivityType.login;
  }
  for (final type in ActivityType.values) {
    if (type.name.toLowerCase() == normalized) return type;
  }
  return ActivityType.login;
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
        return 'Admin sent reset link';
      case ActivityType.passwordSetAdmin:
        return 'Admin set password';
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
