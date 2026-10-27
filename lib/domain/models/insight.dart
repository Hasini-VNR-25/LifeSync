import '../enums/evidence_strength.dart';

class Insight {
  final String id;
  final String userId;
  final String insightType;
  final String title;
  final String description;
  final Map<String, dynamic> evidenceData;
  final int sampleSize;
  final DateTime observationStart;
  final DateTime observationEnd;
  final EvidenceStrength evidenceStrength;
  final String? suggestedHypothesis;
  final String? suggestedAction;
  final String status; // 'Active', 'Dismissed', 'Investigated'
  final DateTime createdAt;

  const Insight({
    required this.id,
    required this.userId,
    required this.insightType,
    required this.title,
    required this.description,
    this.evidenceData = const {},
    required this.sampleSize,
    required this.observationStart,
    required this.observationEnd,
    required this.evidenceStrength,
    this.suggestedHypothesis,
    this.suggestedAction,
    this.status = 'Active',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'insight_type': insightType,
    'title': title,
    'description': description,
    'evidence_json': evidenceData,
    'sample_size': sampleSize,
    'observation_start': observationStart.toIso8601String(),
    'observation_end': observationEnd.toIso8601String(),
    'evidence_strength': evidenceStrength.name,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };

  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    insightType: json['insight_type'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    evidenceData: json['evidence_json'] as Map<String, dynamic>? ?? const {},
    sampleSize: json['sample_size'] as int,
    observationStart: DateTime.parse(json['observation_start'] as String),
    observationEnd: DateTime.parse(json['observation_end'] as String),
    evidenceStrength: EvidenceStrength.values.firstWhere(
      (e) => e.name.toLowerCase() == (json['evidence_strength'] as String? ?? 'preliminary').toLowerCase(),
      orElse: () => EvidenceStrength.preliminary,
    ),
    suggestedHypothesis: json['suggested_hypothesis'] as String?,
    suggestedAction: json['suggested_action'] as String?,
    status: json['status'] as String? ?? 'Active',
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
