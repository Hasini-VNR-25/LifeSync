import '../enums/plan_strategy.dart';
import '../enums/priority_level.dart';
import '../models/task.dart';
import '../models/goal.dart';
import '../models/fixed_commitment.dart';
import '../models/recovery_plan.dart';
import 'planning_engine.dart';

class RecoveryEngine {
  final PlanningEngine planningEngine;

  const RecoveryEngine({required this.planningEngine});

  /// Evaluates whether Comeback Mode should be automatically suggested.
  bool shouldTriggerRecovery({
    required List<Task> tasks,
    required int availableMinutesToday,
    required int scheduledMinutesToday,
    int overdueThreshold = 2,
  }) {
    final overdueCount = tasks.where((t) => t.dueAt != null && t.dueAt!.isBefore(DateTime.now()) && t.status.isOutstanding).length;
    if (overdueCount >= overdueThreshold) return true;
    if (scheduledMinutesToday > (availableMinutesToday + 30)) return true;
    return false;
  }

  /// Generates structured recovery proposals with task splitting and trade-off explanations.
  RecoveryPlan buildRecoveryPlan({
    required String recoveryPlanId,
    required String userId,
    required String triggerReason,
    required List<Task> allTasks,
    required List<Goal> goals,
    required List<FixedCommitment> commitments,
    required int availableMinutes,
    required DateTime recoveryWindowStart,
    int capacityReductionMinutes = 0,
  }) {
    final now = DateTime.now();
    final overdueTasks = allTasks.where((t) => t.dueAt != null && t.dueAt!.isBefore(now) && t.status.isOutstanding).toList();

    // 1. Task Splitting: Split heavy eligible tasks (> 45 mins) into manageable 30-minute bites
    final List<Task> splitCandidateTasks = [];
    final List<Task> splitGeneratedTasks = [];
    final List<Task> nonSplitTasks = [];

    for (final task in allTasks.where((t) => t.status.isOutstanding)) {
      if (task.allowSplitting && task.estimatedMinutes > 45) {
        splitCandidateTasks.add(task);
        final halfMinutes = (task.estimatedMinutes / 2).round();
        splitGeneratedTasks.add(Task(
          id: '${task.id}_part1',
          userId: task.userId,
          goalId: task.goalId,
          title: '${task.title} (Part 1 - Core Focus)',
          description: task.description,
          estimatedMinutes: halfMinutes,
          priority: task.priority,
          dueAt: task.dueAt,
          taskType: task.taskType,
          allowSplitting: false,
          createdAt: now,
          updatedAt: now,
        ));
        splitGeneratedTasks.add(Task(
          id: '${task.id}_part2',
          userId: task.userId,
          goalId: task.goalId,
          title: '${task.title} (Part 2 - Completion)',
          description: task.description,
          estimatedMinutes: task.estimatedMinutes - halfMinutes,
          priority: PriorityLevel.medium,
          dueAt: task.dueAt?.add(const Duration(days: 1)),
          taskType: task.taskType,
          allowSplitting: false,
          createdAt: now,
          updatedAt: now,
        ));
      } else {
        nonSplitTasks.add(task);
      }
    }

    // 2. Proposal 1: "Protect Deadlines & Urgent Work"
    // Merges first halves of split tasks with critical items using RecoveryFirst strategy
    final proposal1Tasks = [...nonSplitTasks, ...splitGeneratedTasks];
    final plan1 = planningEngine.generatePlan(
      planId: '${recoveryPlanId}_prop1',
      userId: userId,
      tasks: proposal1Tasks,
      goals: goals,
      commitments: commitments,
      availableMinutes: availableMinutes,
      planningWindowStart: recoveryWindowStart,
      strategy: PlanStrategy.recoveryFirst,
      planType: 'Recovery',
    );

    final proposal1 = RecoveryProposal(
      id: 'prop_deadline_protect',
      title: 'Protect Deadlines & Split Heavy Workload',
      rationale: 'Breaks large tasks into 30m units and locks in nearest deadlines so you can recover without cognitive exhaustion.',
      plan: plan1,
      splitTasks: splitCandidateTasks,
      deferredTasks: allTasks.where((t) => t.priority == PriorityLevel.low).toList(),
    );

    // 3. Proposal 2: "Momentum Reset"
    // Focuses strictly on quick, high-certainty wins (<= 30m) to rebuild planning momentum
    final quickWinTasks = allTasks.where((t) => t.status.isOutstanding && t.estimatedMinutes <= 30).toList();
    final plan2 = planningEngine.generatePlan(
      planId: '${recoveryPlanId}_prop2',
      userId: userId,
      tasks: quickWinTasks,
      goals: goals,
      commitments: commitments,
      availableMinutes: availableMinutes,
      planningWindowStart: recoveryWindowStart,
      strategy: PlanStrategy.balanceFirst,
      planType: 'Recovery',
    );

    final proposal2 = RecoveryProposal(
      id: 'prop_momentum_reset',
      title: 'Gentle Momentum Reset',
      rationale: 'Schedules only bite-sized tasks to get you back in rhythm comfortably before tackling heavy assignments.',
      plan: plan2,
      splitTasks: const [],
      deferredTasks: allTasks.where((t) => t.estimatedMinutes > 30).toList(),
    );

    return RecoveryPlan(
      id: recoveryPlanId,
      userId: userId,
      triggerReason: triggerReason,
      overdueTaskCount: overdueTasks.length,
      capacityReductionMinutes: capacityReductionMinutes,
      proposals: [proposal1, proposal2],
      selectedProposalId: proposal1.id,
      status: 'Proposed',
      createdAt: now,
    );
  }
}
