import 'package:flutter_test/flutter_test.dart';
import '../../lib/domain/algorithms/recovery_engine.dart';
import '../../lib/domain/algorithms/planning_engine.dart';
import '../../lib/domain/algorithms/scoring_engine.dart';
import '../../lib/domain/models/task.dart';
import '../../lib/domain/enums/priority_level.dart';
import '../../lib/domain/enums/task_status.dart';

void main() {
  group('RecoveryEngine Comeback Mode Tests', () {
    late RecoveryEngine recoveryEngine;
    final now = DateTime(2026, 10, 24, 14, 0);

    setUp(() {
      const planner = PlanningEngine(scoringEngine: ScoringEngine());
      recoveryEngine = RecoveryEngine(planningEngine: planner);
    });

    test('Trigger condition: Activates when overdue tasks exceed threshold', () {
      final tasks = [
        Task(
          id: 't_overdue_1',
          userId: 'u1',
          title: 'Missed Assignment 1',
          estimatedMinutes: 30,
          dueAt: now.subtract(const Duration(hours: 2)),
          status: TaskStatus.pending,
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now,
        ),
        Task(
          id: 't_overdue_2',
          userId: 'u1',
          title: 'Missed Assignment 2',
          estimatedMinutes: 45,
          dueAt: now.subtract(const Duration(hours: 1)),
          status: TaskStatus.pending,
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now,
        ),
      ];

      final shouldTrigger = recoveryEngine.shouldTriggerRecovery(
        tasks: tasks,
        availableMinutesToday: 180,
        scheduledMinutesToday: 120,
        overdueThreshold: 2,
      );

      expect(shouldTrigger, isTrue);
    });

    test('Task Splitting: Divides heavy tasks (>45m) into manageable units', () {
      final tasks = [
        Task(
          id: 't_heavy_dbms',
          userId: 'u1',
          title: 'DBMS Assignment Heavy',
          estimatedMinutes: 60,
          priority: PriorityLevel.critical,
          dueAt: now.add(const Duration(hours: 4)),
          allowSplitting: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final recoveryPlan = recoveryEngine.buildRecoveryPlan(
        recoveryPlanId: 'rec_test',
        userId: 'u1',
        triggerReason: 'Overdue backlog recovery',
        allTasks: tasks,
        goals: [],
        commitments: [],
        availableMinutes: 180,
        recoveryWindowStart: now,
      );

      expect(recoveryPlan.proposals.length, 2);
      final prop1 = recoveryPlan.proposals.first;
      expect(prop1.splitTasks.length, 1);
      expect(prop1.splitTasks.first.id, 't_heavy_dbms');
      expect(prop1.plan.scheduledItems.any((i) => i.task?.title.contains('Part 1') == true), isTrue);
    });
  });
}
