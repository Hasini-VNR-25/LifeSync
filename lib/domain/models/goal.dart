class Goal {
  final String id;
  final String userId;
  final String lifeAreaId;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime targetDate;
  final int priority; // 1 to 4
  final String status; // 'Active', 'Completed', 'Paused', 'Archived'
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.lifeAreaId,
    required this.title,
    this.description,
    required this.startDate,
    required this.targetDate,
    this.priority = 2,
    this.status = 'Active',
    required this.createdAt,
    required this.updatedAt,
  });

  Goal copyWith({
    String? lifeAreaId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? targetDate,
    int? priority,
    String? status,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id,
      userId: userId,
      lifeAreaId: lifeAreaId ?? this.lifeAreaId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'life_area_id': lifeAreaId,
    'title': title,
    'description': description,
    'start_date': startDate.toIso8601String().split('T').first,
    'target_date': targetDate.toIso8601String().split('T').first,
    'priority': priority,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    lifeAreaId: json['life_area_id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    startDate: DateTime.parse(json['start_date'] as String),
    targetDate: DateTime.parse(json['target_date'] as String),
    priority: json['priority'] as int? ?? 2,
    status: json['status'] as String? ?? 'Active',
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
