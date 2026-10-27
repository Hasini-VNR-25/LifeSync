import 'plan.dart';

class ScenarioChange {
  final String fieldName;
  final dynamic oldValue;
  final dynamic newValue;

  const ScenarioChange({
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
  });

  Map<String, dynamic> toJson() => {
    'field_name': fieldName,
    'old_value': oldValue,
    'new_value': newValue,
  };
}

class Scenario {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? baselinePlanId;
  final String status; // 'Draft', 'Applied', 'Discarded'
  final List<ScenarioChange> changes;
  final PlanResult? candidatePlan;
  final DateTime createdAt;

  const Scenario({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.baselinePlanId,
    this.status = 'Draft',
    this.changes = const [],
    this.candidatePlan,
    required this.createdAt,
  });

  Scenario copyWith({
    String? name,
    String? description,
    String? status,
    List<ScenarioChange>? changes,
    PlanResult? candidatePlan,
  }) {
    return Scenario(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      baselinePlanId: baselinePlanId,
      status: status ?? this.status,
      changes: changes ?? this.changes,
      candidatePlan: candidatePlan ?? this.candidatePlan,
      createdAt: createdAt,
    );
  }
}
