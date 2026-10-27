import 'package:flutter_test/flutter_test.dart';
import '../../lib/domain/algorithms/scoring_engine.dart';
import '../../lib/domain/models/plan_item.dart';
import '../../lib/domain/models/task.dart';
import '../../lib/domain/models/fixed_commitment.dart';

void main() {
  group('ScoringEngine J(P) Formula Tests', () {
    late ScoringEngine scoring;
    final now = DateTime(2026, 10, 24, 9, 0);

    setUp(() {
      scoring = const ScoringEngine();
    });

    test('Empty scheduled items returns 0 score', () {
      final breakdown = scoring.evaluate(
        scheduledItems: [],
        tasks: [],
        goals: [],
        commitments: [],
        availableMinutes: 180,
      );

      expect(breakdown.totalScore, 0.0);
    });

    test('Feasible on-time plan scores high without penalties', () {
      final task = Task(
        id: 't1',
        userId: 'u1',
        title: 'DBMS Assignment',
        estimatedMinutes: 60,
        dueAt: now.add(const Duration(hours: 4)),
        createdAt: now,
        updatedAt: now,
      );

      final item = PlanItem(
        id: 'item1',
        planId: 'p1',
        taskId: 't1',
        task: task,
        scheduledStart: now,
        scheduledEnd: now.add(const Duration(minutes: 60)),
      );

      final breakdown = scoring.evaluate(
        scheduledItems: [item],
        tasks: [task],
        goals: [],
        commitments: [],
        availableMinutes: 180,
      );

      expect(breakdown.deadlineScore, greaterThanOrEqualTo(80.0));
      expect(breakdown.overloadPenalty, 0.0);
      expect(breakdown.totalScore, greaterThan(0.0));
    });

    test('Overload penalty triggers when scheduled time exceeds capacity', () {
      final task = Task(
        id: 't_huge',
        userId: 'u1',
        title: 'Oversized Block',
        estimatedMinutes: 240, // 240m against 180m available!
        createdAt: now,
        updatedAt: now,
      );

      final item = PlanItem(
        id: 'item_huge',
        planId: 'p2',
        taskId: 't_huge',
        task: task,
        scheduledStart: now,
        scheduledEnd: now.add(const Duration(minutes: 240)),
      );

      final breakdown = scoring.evaluate(
        scheduledItems: [item],
        tasks: [task],
        goals: [],
        commitments: [],
        availableMinutes: 180,
      );

      expect(breakdown.overloadPenalty, greaterThan(0.0));
    });
  });
}
