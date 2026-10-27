import 'package:flutter_test/flutter_test.dart';
import '../../lib/domain/algorithms/planning_engine.dart';
import '../../lib/domain/algorithms/scoring_engine.dart';
import '../../lib/domain/enums/plan_strategy.dart';
import '../../lib/domain/enums/priority_level.dart';
import '../../lib/domain/enums/task_status.dart';
import '../../lib/domain/models/task.dart';
import '../../lib/domain/models/goal.dart';
import '../../lib/domain/models/fixed_commitment.dart';

void main() {
  group('PlanningEngine Deterministic Tests', () {
    late PlanningEngine planner;
    final now = DateTime(2026, 10, 24, 9, 0); // 9:00 AM

    setUp(() {
      planner = const PlanningEngine(scoringEngine: ScoringEngine());
    });

    test('Hard Constraint: Completed tasks must never be scheduled', () {
      final tasks = [
        Task(
          id: 't_completed',
          userId: 'u1',
          title: 'Already Finished Task',
          estimatedMinutes: 30,
          status: TaskStatus.completed,
          createdAt: now,
          updatedAt: now,
        ),
        Task(
          id: 't_pending',
          userId: 'u1',
          title: 'Outstanding Task',
          estimatedMinutes: 45,
          status: TaskStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final plan = planner.generatePlan(
        planId: 'p1',
        userId: 'u1',
        tasks: tasks,
        goals: [],
        commitments: [],
        availableMinutes: 180,
        planningWindowStart: now,
      );

      expect(plan.scheduledItems.length, 1);
      expect(plan.scheduledItems.first.taskId, 't_pending');
      expect(plan.scheduledItems.any((i) => i.taskId == 't_completed'), isFalse);
    });

    test('Hard Constraint: Tasks must never overlap fixed commitments', () {
      final commitment = FixedCommitment(
        id: 'c1',
        userId: 'u1',
        title: 'Mentorship Lab',
        startTime: now.add(const Duration(minutes: 60)), // 10:00 AM
        endTime: now.add(const Duration(minutes: 120)),   // 11:00 AM
        createdAt: now,
      );

      final tasks = [
        Task(
          id: 't1',
          userId: 'u1',
          title: 'Study Session 1',
          estimatedMinutes: 60, // 9:00 - 10:00 AM
          createdAt: now,
          updatedAt: now,
        ),
        Task(
          id: 't2',
          userId: 'u1',
          title: 'Study Session 2',
          estimatedMinutes: 60, // Must jump to 11:00 AM - 12:00 PM!
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final plan = planner.generatePlan(
        planId: 'p2',
        userId: 'u1',
        tasks: tasks,
        goals: [],
        commitments: [commitment],
        availableMinutes: 180,
        planningWindowStart: now,
      );

      expect(plan.scheduledItems.length, 2);
      expect(plan.scheduledItems[0].scheduledStart, now);
      expect(plan.scheduledItems[0].scheduledEnd, now.add(const Duration(minutes: 60)));

      // Task 2 must start at or after 11:00 AM, skipping the commitment window
      expect(plan.scheduledItems[1].scheduledStart.isAtSameMomentAs(commitment.endTime) ||
             plan.scheduledItems[1].scheduledStart.isAfter(commitment.endTime), isTrue);
      expect(plan.hardConstraintViolations, isEmpty);
    });

    test('Capacity Overflow: Unscheduled tasks contain structured reason', () {
      final tasks = [
        Task(
          id: 't_heavy_1',
          userId: 'u1',
          title: 'DBMS Assignment',
          estimatedMinutes: 120,
          priority: PriorityLevel.critical,
          createdAt: now,
          updatedAt: now,
        ),
        Task(
          id: 't_heavy_2',
          userId: 'u1',
          title: 'Java Concurrency',
          estimatedMinutes: 90, // 120 + 90 = 210m against 180m available!
          priority: PriorityLevel.medium,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final plan = planner.generatePlan(
        planId: 'p3',
        userId: 'u1',
        tasks: tasks,
        goals: [],
        commitments: [],
        availableMinutes: 180,
        planningWindowStart: now,
      );

      expect(plan.scheduledItems.length, 1);
      expect(plan.unscheduledItems.length, 1);
      expect(plan.unscheduledItems.first.taskId, 't_heavy_2');
      expect(plan.unscheduledItems.first.reason, contains('Insufficient remaining capacity'));
    });

    test('Strategy: Deadline-Sensitive prioritizes earliest due date', () {
      final tasks = [
        Task(
          id: 't_later_due',
          userId: 'u1',
          title: 'High Priority but later due',
          estimatedMinutes: 30,
          priority: PriorityLevel.critical,
          dueAt: now.add(const Duration(hours: 10)),
          createdAt: now,
          updatedAt: now,
        ),
        Task(
          id: 't_urgent_due',
          userId: 'u1',
          title: 'Medium Priority but urgent due',
          estimatedMinutes: 30,
          priority: PriorityLevel.medium,
          dueAt: now.add(const Duration(hours: 2)),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final plan = planner.generatePlan(
        planId: 'p4',
        userId: 'u1',
        tasks: tasks,
        goals: [],
        commitments: [],
        availableMinutes: 180,
        planningWindowStart: now,
        strategy: PlanStrategy.deadlineSensitive,
      );

      expect(plan.scheduledItems.first.taskId, 't_urgent_due');
    });
  });
}
