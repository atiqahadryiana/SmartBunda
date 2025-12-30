enum NutritionPlanStatus { active, inactive, pending }

class NutritionTargets {
  NutritionTargets({
    required this.dailyCalories,
    required this.proteinG,
    required this.ironMg,
    required this.folateMcg,
  });

  final int dailyCalories;
  final int proteinG;
  final double ironMg;
  final double folateMcg;

  NutritionTargets copyWith({
    int? dailyCalories,
    int? proteinG,
    double? ironMg,
    double? folateMcg,
  }) {
    return NutritionTargets(
      dailyCalories: dailyCalories ?? this.dailyCalories,
      proteinG: proteinG ?? this.proteinG,
      ironMg: ironMg ?? this.ironMg,
      folateMcg: folateMcg ?? this.folateMcg,
    );
  }
}

class NutritionPlan {
  NutritionPlan({
    required this.id,
    required this.patientId,
    required this.createdBy,
    this.notes,
    this.status = NutritionPlanStatus.active,
    this.startDate,
    this.endDate,
    this.targets,
  });

  final String id;
  final String patientId;
  final String createdBy;
  final NutritionPlanStatus status;
  final String? notes;
  final String? startDate;
  final String? endDate;
  final NutritionTargets? targets;

  NutritionPlan copyWith({
    String? id,
    String? patientId,
    String? createdBy,
    String? notes,
    NutritionPlanStatus? status,
    String? startDate,
    String? endDate,
    NutritionTargets? targets,
  }) {
    return NutritionPlan(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targets: targets ?? this.targets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'createdBy': createdBy,
      'notes': notes,
      'status': status.name,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  factory NutritionPlan.fromJson(
    Map<String, dynamic> json, {
    NutritionTargets? targets,
  }) {
    return NutritionPlan(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      createdBy: json['createdBy'] as String,
      notes: json['notes'] as String?,
      status: _statusFromString(json['status'] as String?),
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      targets: targets,
    );
  }

  static NutritionPlanStatus _statusFromString(String? value) {
    switch (value) {
      case 'inactive':
        return NutritionPlanStatus.inactive;
      case 'pending':
        return NutritionPlanStatus.pending;
      case 'active':
      default:
        return NutritionPlanStatus.active;
    }
  }
}
