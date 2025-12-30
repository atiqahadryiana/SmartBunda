class SystemSettings {
  SystemSettings({
    this.appName = 'SmartBunda',
    this.country = 'Malaysia',
    this.mealLoggingEnabled = true,
    this.defaultReminderHour = 20,
    this.caloriesMin = 1400,
    this.caloriesMax = 2600,
    this.ironMgMin = 27,
    this.folateMcgMin = 600,
    this.proteinGMin = 75,
    this.updatedAt,
  });

  final String appName;
  final String country;
  final bool mealLoggingEnabled;
  final int defaultReminderHour;
  final int caloriesMin;
  final int caloriesMax;
  final int ironMgMin;
  final int folateMcgMin;
  final int proteinGMin;
  final DateTime? updatedAt;

  SystemSettings copyWith({
    String? appName,
    String? country,
    bool? mealLoggingEnabled,
    int? defaultReminderHour,
    int? caloriesMin,
    int? caloriesMax,
    int? ironMgMin,
    int? folateMcgMin,
    int? proteinGMin,
    DateTime? updatedAt,
  }) {
    return SystemSettings(
      appName: appName ?? this.appName,
      country: country ?? this.country,
      mealLoggingEnabled: mealLoggingEnabled ?? this.mealLoggingEnabled,
      defaultReminderHour: defaultReminderHour ?? this.defaultReminderHour,
      caloriesMin: caloriesMin ?? this.caloriesMin,
      caloriesMax: caloriesMax ?? this.caloriesMax,
      ironMgMin: ironMgMin ?? this.ironMgMin,
      folateMcgMin: folateMcgMin ?? this.folateMcgMin,
      proteinGMin: proteinGMin ?? this.proteinGMin,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'country': country,
      'reminder': {
        'mealLoggingEnabled': mealLoggingEnabled,
        'defaultReminderHour': defaultReminderHour,
      },
      'alertThresholds': {
        'caloriesMin': caloriesMin,
        'caloriesMax': caloriesMax,
        'ironMgMin': ironMgMin,
        'folateMcgMin': folateMcgMin,
        'proteinGMin': proteinGMin,
      },
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    final reminder = (json['reminder'] as Map?)?.cast<String, dynamic>() ?? {};
    final thresholds =
        (json['alertThresholds'] as Map?)?.cast<String, dynamic>() ?? {};
    return SystemSettings(
      appName: json['appName'] as String? ?? 'SmartBunda',
      country: json['country'] as String? ?? 'Malaysia',
      mealLoggingEnabled: reminder['mealLoggingEnabled'] as bool? ?? true,
      defaultReminderHour: (reminder['defaultReminderHour'] as num?)?.toInt() ?? 20,
      caloriesMin: (thresholds['caloriesMin'] as num?)?.toInt() ?? 1400,
      caloriesMax: (thresholds['caloriesMax'] as num?)?.toInt() ?? 2600,
      ironMgMin: (thresholds['ironMgMin'] as num?)?.toInt() ?? 27,
      folateMcgMin: (thresholds['folateMcgMin'] as num?)?.toInt() ?? 600,
      proteinGMin: (thresholds['proteinGMin'] as num?)?.toInt() ?? 75,
      updatedAt: _asDate(json['updatedAt']),
    );
  }

  static DateTime? _asDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }
}
