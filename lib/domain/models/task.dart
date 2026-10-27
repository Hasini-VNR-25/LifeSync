import '../enums/priority_level.dart';
import '../enums/task_status.dart';

class Task {
  final String id;
  final String userId;
  final String? goalId;
  final String title;
  final String? description;
  final int estimatedMinutes;
  final PriorityLevel priority;
  final DateTime? dueAt;
  final TaskStatus status;
  final TaskType taskType;
  final bool allowSplitting;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.userId,
    this.goalId,
    required this.title,
    this.description,
    required this.estimatedMinutes,
    this.priority = PriorityLevel.medium,
    this.dueAt,
    this.status = TaskStatus.pending,
    this.taskType = TaskType.standard,
    this.allowSplitting = true,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(estimatedMinutes > 0, 'Estimated minutes must be positive');

  Task copyWith({
    String? goalId,
    String? title,
    String? description,
    int? estimatedMinutes,
    PriorityLevel? priority,
    DateTime? dueAt,
    TaskStatus? status,
    TaskType? taskType,
    bool? allowSplitting,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      userId: userId,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      description: description ?? this.description,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      priority: priority ?? this.priority,
      dueAt: dueAt ?? this.dueAt,
      status: status ?? this.status,
      taskType: taskType ?? this.taskType,
      allowSplitting: allowSplitting ?? this.allowSplitting,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'goal_id': goalId,
    'title': title,
    'description': description,
    'estimated_minutes': estimatedMinutes,
    'priority': priority.value,
    'due_at': dueAt?.toIso8601String(),
    'status': status.name,
    'task_type': taskType.name,
    'allow_splitting': allowSplitting,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    goalId: json['goal_id'] as String?,
    title: json['title'] as String,
    description: json['description'] as String?,
    estimatedMinutes: json['estimated_minutes'] as int,
    priority: PriorityLevel.fromValue(json['priority'] as int? ?? 2),
    dueAt: json['due_at'] != null ? DateTime.parse(json['due_at'] as String) : null,
    status: TaskStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (json['status'] as String? ?? 'pending').toLowerCase(),
      orElse: () => TaskStatus.pending,
    ),
    taskType: TaskType.values.firstWhere(
      (e) => e.name.toLowerCase() == (json['task_type'] as String? ?? 'standard').toLowerCase(),
      orElse: () => TaskType.standard,
    ),
    allowSplitting: json['allow_splitting'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
