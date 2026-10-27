import 'task.dart';

class PlanItem {
  final String id;
  final String planId;
  final String taskId;
  final Task? task;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String status; // 'Scheduled', 'Completed', 'Skipped', 'Missed'

  const PlanItem({
    required this.id,
    required this.planId,
    required this.taskId,
    this.task,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.status = 'Scheduled',
  }) : assert(scheduledEnd.isAfter(scheduledStart), 'Scheduled end must be after scheduled start');

  int get durationMinutes => scheduledEnd.difference(scheduledStart).inMinutes;

  bool overlaps(PlanItem other) {
    return scheduledStart.isBefore(other.scheduledEnd) && scheduledEnd.isAfter(other.scheduledStart);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'plan_id': planId,
    'task_id': taskId,
    'scheduled_start': scheduledStart.toIso8601String(),
    'scheduled_end': scheduledEnd.toIso8601String(),
    'status': status,
  };

  factory PlanItem.fromJson(Map<String, dynamic> json, {Task? task}) => PlanItem(
    id: json['id'] as String,
    planId: json['plan_id'] as String,
    taskId: json['task_id'] as String,
    task: task,
    scheduledStart: DateTime.parse(json['scheduled_start'] as String),
    scheduledEnd: DateTime.parse(json['scheduled_end'] as String),
    status: json['status'] as String? ?? 'Scheduled',
  );
}

class UnscheduledItem {
  final String taskId;
  final Task? task;
  final String reason;

  const UnscheduledItem({
    required this.taskId,
    this.task,
    required this.reason,
  });
}

class DeadlineRisk {
  final String taskId;
  final String taskTitle;
  final DateTime scheduledEnd;
  final DateTime deadline;
  final int slackMinutes;

  const DeadlineRisk({
    required this.taskId,
    required this.taskTitle,
    required this.scheduledEnd,
    required this.deadline,
    required this.slackMinutes,
  });

  bool get isViolated => slackMinutes < 0;
  bool get isTight => slackMinutes >= 0 && slackMinutes <= 30;
}
