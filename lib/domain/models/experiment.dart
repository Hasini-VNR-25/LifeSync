import '../enums/experiment_status.dart';

class ExperimentResultData {
  final String metricName;
  final double baselineValue;
  final double resultValue;
  final int sampleSize;
  final String limitations;
  final DateTime calculatedAt;

  const ExperimentResultData({
    required this.metricName,
    required this.baselineValue,
    required this.resultValue,
    required this.sampleSize,
    required this.limitations,
    required this.calculatedAt,
  });

  double get deltaPercentage {
    if (baselineValue == 0) return 0;
    return ((resultValue - baselineValue) / baselineValue) * 100;
  }

  bool get isPositiveChange => resultValue > baselineValue;
}

class Experiment {
  final String id;
  final String userId;
  final String? insightId;
  final String hypothesis;
  final String changeDescription;
  final String metricDefinition;
  final DateTime baselinePeriodStart;
  final DateTime baselinePeriodEnd;
  final DateTime experimentStart;
  final DateTime experimentEnd;
  final ExperimentStatus status;
  final ExperimentResultData? result;
  final DateTime createdAt;

  const Experiment({
    required this.id,
    required this.userId,
    this.insightId,
    required this.hypothesis,
    required this.changeDescription,
    required this.metricDefinition,
    required this.baselinePeriodStart,
    required this.baselinePeriodEnd,
    required this.experimentStart,
    required this.experimentEnd,
    this.status = ExperimentStatus.active,
    this.result,
    required this.createdAt,
  });

  bool get isConcluded => status == ExperimentStatus.completed || status == ExperimentStatus.adopted;

  Experiment copyWith({
    ExperimentStatus? status,
    ExperimentResultData? result,
  }) {
    return Experiment(
      id: id,
      userId: userId,
      insightId: insightId,
      hypothesis: hypothesis,
      changeDescription: changeDescription,
      metricDefinition: metricDefinition,
      baselinePeriodStart: baselinePeriodStart,
      baselinePeriodEnd: baselinePeriodEnd,
      experimentStart: experimentStart,
      experimentEnd: experimentEnd,
      status: status ?? this.status,
      result: result ?? this.result,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'insight_id': insightId,
    'hypothesis': hypothesis,
    'change_description': changeDescription,
    'metric_definition': metricDefinition,
    'baseline_period_start': baselinePeriodStart.toIso8601String(),
    'baseline_period_end': baselinePeriodEnd.toIso8601String(),
    'experiment_start': experimentStart.toIso8601String(),
    'experiment_end': experimentEnd.toIso8601String(),
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory Experiment.fromJson(Map<String, dynamic> json, {ExperimentResultData? result}) => Experiment(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    insightId: json['insight_id'] as String?,
    hypothesis: json['hypothesis'] as String,
    changeDescription: json['change_description'] as String,
    metricDefinition: json['metric_definition'] as String,
    baselinePeriodStart: DateTime.parse(json['baseline_period_start'] as String),
    baselinePeriodEnd: DateTime.parse(json['baseline_period_end'] as String),
    experimentStart: DateTime.parse(json['experiment_start'] as String),
    experimentEnd: DateTime.parse(json['experiment_end'] as String),
    status: ExperimentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (json['status'] as String? ?? 'active').toLowerCase(),
      orElse: () => ExperimentStatus.active,
    ),
    result: result,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
