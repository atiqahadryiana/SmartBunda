enum UserRole { admin, doctor, nurse, patient, dietitian }

enum AccessPermission {
  userManagement,
  authentication,
  patientProfiles,
  foodLogging,
  nutritionAnalysis,
  nutritionPlans,
  monitoringAlerts,
  appointments,
  reporting,
  education,
  systemAdministration,
  foodDatabase,
}

extension AccessPermissionLabel on AccessPermission {
  String get label {
    switch (this) {
      case AccessPermission.userManagement:
        return 'User management';
      case AccessPermission.authentication:
        return 'Authentication & security';
      case AccessPermission.patientProfiles:
        return 'Patient profiles';
      case AccessPermission.foodLogging:
        return 'Food logging';
      case AccessPermission.nutritionAnalysis:
        return 'Nutrition analysis';
      case AccessPermission.nutritionPlans:
        return 'Nutrition plans';
      case AccessPermission.monitoringAlerts:
        return 'Monitoring & alerts';
      case AccessPermission.appointments:
        return 'Appointments';
      case AccessPermission.reporting:
        return 'Reporting & analytics';
      case AccessPermission.education:
        return 'Education & content';
      case AccessPermission.systemAdministration:
        return 'System administration';
      case AccessPermission.foodDatabase:
        return 'Food database';
    }
  }
}

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.nurse:
        return 'Nurse';
      case UserRole.patient:
        return 'Patient';
      case UserRole.dietitian:
        return 'Dietitian';
    }
  }
}

class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.isActive = true,
    this.permissions,
    this.mmcNumber,
    this.specialization,
    this.phone,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? displayName;
  final bool isActive;
  final Set<AccessPermission>? permissions;

  /// Malaysian Medical Council registration number (healthcare professionals).
  final String? mmcNumber;

  /// Clinical specialization (healthcare professionals).
  final String? specialization;

  /// Contact phone number.
  final String? phone;

  Set<AccessPermission> get effectivePermissions =>
      permissions ?? defaultPermissionsFor(role);

  bool hasPermission(AccessPermission permission) {
    return effectivePermissions.contains(permission);
  }

  /// Specialization to display — falls back to a role-based default when the
  /// user has not set an explicit value.
  String get effectiveSpecialization {
    final value = specialization?.trim();
    if (value != null && value.isNotEmpty) return value;
    return defaultSpecializationFor(role);
  }

  AppUser copyWith({
    String? id,
    String? email,
    UserRole? role,
    String? displayName,
    bool? isActive,
    Set<AccessPermission>? permissions,
    bool permissionsExplicit = false,
    String? mmcNumber,
    String? specialization,
    String? phone,
  }) {
    final resolvedPermissions =
        permissionsExplicit ? permissions : this.permissions;
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
      permissions: resolvedPermissions,
      mmcNumber: mmcNumber ?? this.mmcNumber,
      specialization: specialization ?? this.specialization,
      phone: phone ?? this.phone,
    );
  }
}

/// Default clinical specialization label derived from the user's role.
/// Mirrors the role-based mapping previously hard-coded in the admin overview.
String defaultSpecializationFor(UserRole role) {
  switch (role) {
    case UserRole.doctor:
      return 'Maternal Health';
    case UserRole.dietitian:
      return 'Pregnancy Nutrition';
    case UserRole.nurse:
      return 'Vital Signs Monitoring';
    case UserRole.admin:
      return 'Administration';
    case UserRole.patient:
      return 'Patient';
  }
}

Set<AccessPermission> defaultPermissionsFor(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return {
        AccessPermission.userManagement,
        AccessPermission.authentication,
        AccessPermission.patientProfiles,
        AccessPermission.foodLogging,
        AccessPermission.nutritionAnalysis,
        AccessPermission.nutritionPlans,
        AccessPermission.monitoringAlerts,
        AccessPermission.appointments,
        AccessPermission.reporting,
        AccessPermission.education,
        AccessPermission.systemAdministration,
        AccessPermission.foodDatabase,
      };
    case UserRole.patient:
      return {
        AccessPermission.authentication,
        AccessPermission.patientProfiles,
        AccessPermission.foodLogging,
        AccessPermission.monitoringAlerts,
        AccessPermission.appointments,
        AccessPermission.reporting,
        AccessPermission.education,
      };
    case UserRole.doctor:
      return {
        AccessPermission.authentication,
        AccessPermission.patientProfiles,
        AccessPermission.nutritionAnalysis,
        AccessPermission.nutritionPlans,
        AccessPermission.monitoringAlerts,
        AccessPermission.appointments,
        AccessPermission.reporting,
      };
    case UserRole.nurse:
      return {
        AccessPermission.authentication,
        AccessPermission.patientProfiles,
        AccessPermission.monitoringAlerts,
        AccessPermission.appointments,
        AccessPermission.reporting,
      };
    case UserRole.dietitian:
      return {
        AccessPermission.authentication,
        AccessPermission.patientProfiles,
        AccessPermission.nutritionAnalysis,
        AccessPermission.nutritionPlans,
        AccessPermission.monitoringAlerts,
        AccessPermission.appointments,
        AccessPermission.reporting,
      };
  }
}
