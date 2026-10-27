class Reflection {
  final String id;
  final String userId;
  final DateTime reflectionDate;
  final String wins;
  final String challenges;
  final String nextStep;
  final int? selfReportedWorkload; // 1 to 5
  final DateTime createdAt;

  const Reflection({
    required this.id,
    required this.userId,
    required this.reflectionDate,
    required this.wins,
    required this.challenges,
    required this.nextStep,
    this.selfReportedWorkload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'reflection_date': reflectionDate.toIso8601String().split('T').first,
    'wins': wins,
    'challenges': challenges,
    'next_step': nextStep,
    'self_reported_workload': selfReportedWorkload,
    'created_at': createdAt.toIso8601String(),
  };

  factory Reflection.fromJson(Map<String, dynamic> json) => Reflection(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    reflectionDate: DateTime.parse(json['reflection_date'] as String),
    wins: json['wins'] as String,
    challenges: json['challenges'] as String,
    nextStep: json['next_step'] as String,
    selfReportedWorkload: json['self_reported_workload'] as int?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
