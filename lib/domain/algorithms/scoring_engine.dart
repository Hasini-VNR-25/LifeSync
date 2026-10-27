import '../models/plan_item.dart';
import '../models/task.dart';
import '../models/goal.dart';
import '../models/fixed_commitment.dart';

class ScoringBreakdown {
  final double deadlineScore;     // D(P)
  final double goalCoverageScore;  // G(P)
  final double slotFitScore;       // F(P)
  final double overloadPenalty;    // O(P)
  final double conflictPenalty;    // C(P)
  final double totalScore;         // J(P)

  const ScoringBreakdown({
    required this.deadlineScore,
    required this.goalCoverageScore,
    required this.slotFitScore,
    required this.overloadPenalty,
    required this.conflictPenalty,
    required this.totalScore,
  });

  Map<String, double> toMap() => {
    'deadlineSatisfaction': deadlineScore,
    'goalCoverage': goalCoverageScore,
    'timeFit': slotFitScore,
    'overloadPenalty': overloadPenalty,
    'conflictPenalty': conflictPenalty,
    'total': totalScore,
  };
}

class ScoringEngine {
  // Weights: wd, wg, wf, wo, wc
  final double weightDeadline;
  final double weightGoal;
  final double weightFit;
  final double weightOverload;
  final double weightConflict;

  const ScoringEngine({
    this.weightDeadline = 0.35,
    this.weightGoal = 0.25,
    this.weightFit = 0.25,
    this.weightOverload = 0.15,
    this.weightConflict = 0.10,
  });

  ScoringBreakdown evaluate({
    required List<PlanItem> scheduledItems,
    required List<Task> tasks,
    required List<Goal> goals,
    required List<FixedCommitment> commitments,
    required int availableMinutes,
  }) {
    if (scheduledItems.isEmpty) {
      return const ScoringBreakdown(
        deadlineScore: 0.0,
        goalCoverageScore: 0.0,
        slotFitScore: 0.0,
        overloadPenalty: 0.0,
        conflictPenalty: 0.0,
        totalScore: 0.0,
      );
    }

    final taskMap = {for (final t in tasks) t.id: t};
    final goalMap = {for (final g in goals) g.id: g};

    // 1. Deadline Score D(P): 0 - 100
    double deadlineScoreAccum = 0.0;
    int tasksWithDeadlines = 0;

    for (final item in scheduledItems) {
      final task = taskMap[item.taskId];
      if (task != null && task.dueAt != null) {
        tasksWithDeadlines++;
        if (item.scheduledEnd.isBefore(task.dueAt!) || item.scheduledEnd.isAtSameMomentAs(task.dueAt!)) {
          // Completed on or before deadline: full score
          final marginMinutes = task.dueAt!.difference(item.scheduledEnd).inMinutes;
          // Generous margin gets up to 100, tighter margin scales down to 70
          final bufferBonus = (marginMinutes > 120 ? 100.0 : 70.0 + (marginMinutes / 120.0) * 30.0).clamp(0.0, 100.0);
          deadlineScoreAccum += bufferBonus;
        } else {
          // Overdue / violated deadline: zero points
          deadlineScoreAccum += 0.0;
        }
      }
    }
    final double deadlineScore = tasksWithDeadlines > 0
        ? (deadlineScoreAccum / tasksWithDeadlines).clamp(0.0, 100.0)
        : 90.0; // neutral high if no specific deadlines set

    // 2. Goal Coverage G(P): 0 - 100
    // Reward covering active goals and active life areas
    final scheduledGoalIds = <String>{};
    final scheduledLifeAreaIds = <String>{};
    for (final item in scheduledItems) {
      final task = taskMap[item.taskId];
      if (task?.goalId != null) {
        scheduledGoalIds.add(task!.goalId!);
        final goal = goalMap[task.goalId!];
        if (goal != null) {
          scheduledLifeAreaIds.add(goal.lifeAreaId);
        }
      }
    }

    final double goalRatio = goals.isNotEmpty
        ? (scheduledGoalIds.length / goals.length).clamp(0.0, 1.0)
        : 1.0;
    final double goalCoverageScore = (goalRatio * 100.0).clamp(0.0, 100.0);

    // 3. Slot Fit Score F(P): 0 - 100
    // Reward scheduling tasks into available capacity without leaving unusable fragmentation
    final totalScheduledMins = scheduledItems.fold<int>(0, (sum, i) => sum + i.durationMinutes);
    final double utilizationRatio = availableMinutes > 0
        ? (totalScheduledMins / availableMinutes).clamp(0.0, 1.2)
        : 1.0;

    // Ideal utilization is 85% - 95%
    double slotFitScore = 0.0;
    if (utilizationRatio <= 1.0) {
      slotFitScore = (utilizationRatio * 100.0).clamp(0.0, 100.0);
    } else {
      // Over capacity
      slotFitScore = (100.0 - (utilizationRatio - 1.0) * 200.0).clamp(0.0, 100.0);
    }

    // 4. Overload Penalty O(P): 0 - 100
    double overloadPenalty = 0.0;
    if (totalScheduledMins > availableMinutes) {
      final excessMinutes = totalScheduledMins - availableMinutes;
      overloadPenalty = ((excessMinutes / (availableMinutes > 0 ? availableMinutes : 1)) * 100.0).clamp(0.0, 100.0);
    }

    // 5. Conflict Penalty C(P): 0 - 100
    // Penalize tasks that abut or collide with fixed commitments without safety margin (< 5 min buffer)
    double conflictPenalty = 0.0;
    for (final item in scheduledItems) {
      for (final c in commitments) {
        final startDiff = (item.scheduledStart.difference(c.endTime).inMinutes).abs();
        final endDiff = (c.startTime.difference(item.scheduledEnd).inMinutes).abs();
        if (startDiff < 5 || endDiff < 5) {
          conflictPenalty += 15.0;
        }
      }
    }
    conflictPenalty = conflictPenalty.clamp(0.0, 100.0);

    // J(P) = wd * D + wg * G + wf * F - wo * O - wc * C
    double totalRawScore = (weightDeadline * deadlineScore) +
        (weightGoal * goalCoverageScore) +
        (weightFit * slotFitScore) -
        (weightOverload * overloadPenalty) -
        (weightConflict * conflictPenalty);

    final double totalScore = totalRawScore.clamp(0.0, 100.0);

    return ScoringBreakdown(
      deadlineScore: double.parse(deadlineScore.toStringAsFixed(1)),
      goalCoverageScore: double.parse(goalCoverageScore.toStringAsFixed(1)),
      slotFitScore: double.parse(slotFitScore.toStringAsFixed(1)),
      overloadPenalty: double.parse(overloadPenalty.toStringAsFixed(1)),
      conflictPenalty: double.parse(conflictPenalty.toStringAsFixed(1)),
      totalScore: double.parse(totalScore.toStringAsFixed(1)),
    );
  }
}
