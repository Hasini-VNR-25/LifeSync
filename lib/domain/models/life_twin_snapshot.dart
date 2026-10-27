import 'task.dart';
import 'goal.dart';
import 'fixed_commitment.dart';

enum FeasibilityState {
  feasible('Feasible Plan', 'Your workload fits comfortably within your available time window.'),
  strained('Strained Capacity', 'Workload consumes over 90% of your available capacity with minimal buffer.'),
  infeasible('Capacity Gap', 'Your planned tasks exceed your daily available minutes. Adaptation needed.');

  final String title;
  final String description;
  const FeasibilityState(this.title, this.description);
}

class LifeTwinSnapshot {
  final int totalEstimatedWorkloadMinutes;
  final int availablePlanningMinutes;
  final int capacityGapMinutes; // workload - available (positive means overflow)
  final FeasibilityState feasibility;
  final List<Task> overdueTasks;
  final List<Task> upcomingCriticalTasks;
  final Map<String, int> plannedMinutesByLifeArea; // areaId -> minutes
  final List<Goal> neglectedGoals;
  final int completedTodayMinutes;
  final int completedTasksCount;
  final int postponedTasksCount;
  final List<FixedCommitment> commitmentsToday;
  final String plainEnglishSummary;
  final DateTime calculatedAt;

  const LifeTwinSnapshot({
    required this.totalEstimatedWorkloadMinutes,
    required this.availablePlanningMinutes,
    required this.capacityGapMinutes,
    required this.feasibility,
    required this.overdueTasks,
    required this.upcomingCriticalTasks,
    required this.plannedMinutesByLifeArea,
    required this.neglectedGoals,
    this.completedTodayMinutes = 0,
    this.completedTasksCount = 0,
    this.postponedTasksCount = 0,
    this.commitmentsToday = const [],
    required this.plainEnglishSummary,
    required this.calculatedAt,
  });

  bool get hasCapacityGap => capacityGapMinutes > 0;
  bool get hasOverdue => overdueTasks.isNotEmpty;
  bool get hasCriticalUpcoming => upcomingCriticalTasks.isNotEmpty;
}
