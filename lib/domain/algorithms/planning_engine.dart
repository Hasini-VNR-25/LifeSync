import '../enums/plan_strategy.dart';
import '../enums/task_status.dart';
import '../models/task.dart';
import '../models/goal.dart';
import '../models/fixed_commitment.dart';
import '../models/plan.dart';
import '../models/plan_item.dart';
import 'scoring_engine.dart';

class PlanningEngine {
  final ScoringEngine scoringEngine;

  const PlanningEngine({this.scoringEngine = const ScoringEngine()});

  /// Generates a deterministic, constraint-validated plan.
  PlanResult generatePlan({
    required String planId,
    required String userId,
    required List<Task> tasks,
    required List<Goal> goals,
    required List<FixedCommitment> commitments,
    required int availableMinutes,
    required DateTime planningWindowStart,
    PlanStrategy strategy = PlanStrategy.priorityFirst,
    String planType = 'Candidate',
  }) {
    final List<String> hardViolations = [];
    final List<String> softWarnings = [];
    final List<DeadlineRisk> deadlineRisks = [];
    final Map<String, int> lifeAreaAllocation = {};
    final goalMap = {for (final g in goals) g.id: g};

    // 1. HARD CONSTRAINT CHECK: Completed tasks must never be scheduled
    final eligibleTasks = tasks.where((t) {
      if (t.status == TaskStatus.completed) {
        return false;
      }
      if (t.estimatedMinutes <= 0) {
        hardViolations.add('Task "${t.title}" rejected: Duration must be strictly positive (> 0).');
        return false;
      }
      return true;
    }).toList();

    // 2. Rank candidate tasks deterministically based on chosen strategy
    final rankedTasks = _rankTasks(eligibleTasks, goalMap, strategy);

    // 3. Prepare free time slots avoiding fixed commitments
    final planningWindowEnd = planningWindowStart.add(Duration(minutes: availableMinutes));
    final sortedCommitments = List<FixedCommitment>.from(commitments)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // 4. Greedy placement loop
    final List<PlanItem> scheduledItems = [];
    final List<UnscheduledItem> unscheduledItems = [];
    DateTime currentTime = planningWindowStart;
    int remainingMinutes = availableMinutes;

    for (final task in rankedTasks) {
      if (task.estimatedMinutes > remainingMinutes) {
        unscheduledItems.add(UnscheduledItem(
          taskId: task.id,
          task: task,
          reason: 'Insufficient remaining capacity: Needs ${task.estimatedMinutes}m, but only ${remainingMinutes}m available.',
        ));
        continue;
      }

      // Find next feasible start time that avoids fixed commitments
      DateTime candidateStart = currentTime;
      DateTime candidateEnd = candidateStart.add(Duration(minutes: task.estimatedMinutes));
      bool slotFound = false;

      while (!slotFound && candidateEnd.isBefore(planningWindowEnd) || candidateEnd.isAtSameMomentAs(planningWindowEnd)) {
        // Check overlap with fixed commitments
        FixedCommitment? clashingCommitment;
        for (final c in sortedCommitments) {
          if (c.overlaps(candidateStart, candidateEnd)) {
            clashingCommitment = c;
            break;
          }
        }

        if (clashingCommitment != null) {
          // Advance past the clashing commitment
          candidateStart = clashingCommitment.endTime;
          candidateEnd = candidateStart.add(Duration(minutes: task.estimatedMinutes));
        } else {
          slotFound = true;
        }
      }

      if (slotFound && (candidateEnd.isBefore(planningWindowEnd) || candidateEnd.isAtSameMomentAs(planningWindowEnd))) {
        final planItem = PlanItem(
          id: 'item_${task.id}_${scheduledItems.length}',
          planId: planId,
          taskId: task.id,
          task: task,
          scheduledStart: candidateStart,
          scheduledEnd: candidateEnd,
          status: 'Scheduled',
        );

        scheduledItems.add(planItem);
        currentTime = candidateEnd;
        remainingMinutes -= task.estimatedMinutes;

        // Record life area minutes
        if (task.goalId != null && goalMap.containsKey(task.goalId)) {
          final areaId = goalMap[task.goalId]!.lifeAreaId;
          lifeAreaAllocation[areaId] = (lifeAreaAllocation[areaId] ?? 0) + task.estimatedMinutes;
        }

        // Check deadline margin
        if (task.dueAt != null) {
          final slack = task.dueAt!.difference(candidateEnd).inMinutes;
          final risk = DeadlineRisk(
            taskId: task.id,
            taskTitle: task.title,
            scheduledEnd: candidateEnd,
            deadline: task.dueAt!,
            slackMinutes: slack,
          );
          deadlineRisks.add(risk);

          if (risk.isViolated) {
            softWarnings.add('Task "${task.title}" completes after deadline by ${slack.abs()} minutes.');
          } else if (risk.isTight) {
            softWarnings.add('Task "${task.title}" is tight against deadline ($slack minutes buffer).');
          }
        }
      } else {
        unscheduledItems.add(UnscheduledItem(
          taskId: task.id,
          task: task,
          reason: 'Cannot schedule within remaining free blocks due to commitment constraints.',
        ));
      }
    }

    // 5. Local Search Optimization: evaluate single adjacent task swaps to optimize J(P)
    final optimizedScheduledItems = _applyLocalSearch(
      initialItems: scheduledItems,
      commitments: sortedCommitments,
      tasks: eligibleTasks,
      goals: goals,
      availableMinutes: availableMinutes,
    );

    // 6. Hard constraint verification on final schedule
    _verifyHardConstraints(
      items: optimizedScheduledItems,
      commitments: sortedCommitments,
      windowStart: planningWindowStart,
      windowEnd: planningWindowEnd,
      hardViolations: hardViolations,
    );

    // 7. Calculate score using unified scoring engine
    final totalScheduledMinutes = optimizedScheduledItems.fold<int>(0, (sum, i) => sum + i.durationMinutes);
    final scoringBreakdown = scoringEngine.evaluate(
      scheduledItems: optimizedScheduledItems,
      tasks: eligibleTasks,
      goals: goals,
      commitments: sortedCommitments,
      availableMinutes: availableMinutes,
    );

    return PlanResult(
      id: planId,
      userId: userId,
      planType: planType,
      strategy: strategy,
      scheduledItems: optimizedScheduledItems,
      unscheduledItems: unscheduledItems,
      timeAllocationByLifeArea: lifeAreaAllocation,
      totalScheduledMinutes: totalScheduledMinutes,
      remainingAvailableMinutes: remainingMinutes,
      hardConstraintViolations: hardViolations,
      softWarnings: softWarnings,
      deadlineRisks: deadlineRisks,
      overallScore: scoringBreakdown.totalScore,
      scoreBreakdown: scoringBreakdown.toMap(),
      status: 'Draft',
      createdAt: DateTime.now(),
    );
  }

  /// Deterministic ranking of candidate tasks according to strategy
  List<Task> _rankTasks(List<Task> tasks, Map<String, Goal> goalMap, PlanStrategy strategy) {
    final list = List<Task>.from(tasks);

    switch (strategy) {
      case PlanStrategy.priorityFirst:
        list.sort((a, b) {
          final goalA = a.goalId != null ? goalMap[a.goalId]?.priority ?? 2 : 2;
          final goalB = b.goalId != null ? goalMap[b.goalId]?.priority ?? 2 : 2;
          final scoreA = a.priority.value * 10 + goalA;
          final scoreB = b.priority.value * 10 + goalB;
          if (scoreA != scoreB) return scoreB.compareTo(scoreA); // higher first
          // Stable tie-breakers: deadline asc, duration asc, id
          if (a.dueAt != null && b.dueAt != null) {
            final dueCmp = a.dueAt!.compareTo(b.dueAt!);
            if (dueCmp != 0) return dueCmp;
          }
          if (a.estimatedMinutes != b.estimatedMinutes) {
            return a.estimatedMinutes.compareTo(b.estimatedMinutes);
          }
          return a.id.compareTo(b.id);
        });
        break;

      case PlanStrategy.deadlineSensitive:
        list.sort((a, b) {
          if (a.dueAt != null && b.dueAt != null) {
            final dueCmp = a.dueAt!.compareTo(b.dueAt!);
            if (dueCmp != 0) return dueCmp;
          } else if (a.dueAt != null && b.dueAt == null) {
            return -1; // tasks with deadlines come first
          } else if (a.dueAt == null && b.dueAt != null) {
            return 1;
          }
          if (a.priority.value != b.priority.value) {
            return b.priority.value.compareTo(a.priority.value);
          }
          return a.estimatedMinutes.compareTo(b.estimatedMinutes);
        });
        break;

      case PlanStrategy.balanceFirst:
        // Group by life area and round-robin
        final Map<String, List<Task>> areaBuckets = {};
        for (final t in list) {
          final areaKey = t.goalId != null ? goalMap[t.goalId]?.lifeAreaId ?? 'general' : 'general';
          areaBuckets.putIfAbsent(areaKey, () => []).add(t);
        }
        for (final bucket in areaBuckets.values) {
          bucket.sort((a, b) => b.priority.value.compareTo(a.priority.value));
        }

        final List<Task> balanced = [];
        bool addedAny = true;
        while (addedAny) {
          addedAny = false;
          for (final key in areaBuckets.keys) {
            final bucket = areaBuckets[key]!;
            if (bucket.isNotEmpty) {
              balanced.add(bucket.removeAt(0));
              addedAny = true;
            }
          }
        }
        return balanced;

      case PlanStrategy.recoveryFirst:
        // Favor shorter tasks (<= 30 mins) first for momentum, then urgent tasks
        list.sort((a, b) {
          final isQuickA = a.estimatedMinutes <= 30;
          final isQuickB = b.estimatedMinutes <= 30;
          if (isQuickA != isQuickB) return isQuickA ? -1 : 1;
          if (a.priority.value != b.priority.value) {
            return b.priority.value.compareTo(a.priority.value);
          }
          return a.estimatedMinutes.compareTo(b.estimatedMinutes);
        });
        break;
    }

    return list;
  }

  /// Local search: checks if swapping adjacent tasks improves score without violating constraints
  List<PlanItem> _applyLocalSearch({
    required List<PlanItem> initialItems,
    required List<FixedCommitment> commitments,
    required List<Task> tasks,
    required List<Goal> goals,
    required int availableMinutes,
  }) {
    if (initialItems.length < 2) return initialItems;

    List<PlanItem> currentItems = List.from(initialItems);
    double bestScore = scoringEngine.evaluate(
      scheduledItems: currentItems,
      tasks: tasks,
      goals: goals,
      commitments: commitments,
      availableMinutes: availableMinutes,
    ).totalScore;

    for (int i = 0; i < currentItems.length - 1; i++) {
      final a = currentItems[i];
      final b = currentItems[i + 1];

      // Test swapped timing if duration matches or can fit
      if (a.durationMinutes == b.durationMinutes) {
        final swappedA = PlanItem(
          id: a.id,
          planId: a.planId,
          taskId: a.taskId,
          task: a.task,
          scheduledStart: b.scheduledStart,
          scheduledEnd: b.scheduledStart.add(Duration(minutes: a.durationMinutes)),
        );
        final swappedB = PlanItem(
          id: b.id,
          planId: b.planId,
          taskId: b.taskId,
          task: b.task,
          scheduledStart: a.scheduledStart,
          scheduledEnd: a.scheduledStart.add(Duration(minutes: b.durationMinutes)),
        );

        final candidateList = List<PlanItem>.from(currentItems);
        candidateList[i] = swappedB;
        candidateList[i + 1] = swappedA;

        final candidateScore = scoringEngine.evaluate(
          scheduledItems: candidateList,
          tasks: tasks,
          goals: goals,
          commitments: commitments,
          availableMinutes: availableMinutes,
        ).totalScore;

        if (candidateScore > bestScore) {
          bestScore = candidateScore;
          currentItems = candidateList;
        }
      }
    }

    return currentItems;
  }

  /// Explicit hard constraint assertion
  void _verifyHardConstraints({
    required List<PlanItem> items,
    required List<FixedCommitment> commitments,
    required DateTime windowStart,
    required DateTime windowEnd,
    required List<String> hardViolations,
  }) {
    // 1. Check overlap among tasks
    for (int i = 0; i < items.length; i++) {
      for (int j = i + 1; j < items.length; j++) {
        if (items[i].overlaps(items[j])) {
          hardViolations.add('Hard Constraint Error: Task "${items[i].task?.title ?? items[i].taskId}" overlaps with "${items[j].task?.title ?? items[j].taskId}".');
        }
      }
      // 2. Check overlap with fixed commitments
      for (final c in commitments) {
        if (c.overlaps(items[i].scheduledStart, items[i].scheduledEnd)) {
          hardViolations.add('Hard Constraint Error: Task "${items[i].task?.title ?? items[i].taskId}" overlaps with fixed commitment "${c.title}".');
        }
      }
      // 3. Check outside window
      if (items[i].scheduledStart.isBefore(windowStart) || items[i].scheduledEnd.isAfter(windowEnd)) {
        hardViolations.add('Hard Constraint Error: Task "${items[i].task?.title ?? items[i].taskId}" scheduled outside available planning window.');
      }
    }
  }
}
