import 'package:flutter_test/flutter_test.dart';
import '../../lib/domain/algorithms/pattern_detector.dart';
import '../../lib/domain/models/task.dart';
import '../../lib/domain/enums/evidence_strength.dart';

void main() {
  group('PatternDetector Growth Investigator Tests', () {
    late PatternDetector detector;
    final now = DateTime(2026, 10, 24, 12, 0);

    setUp(() {
      detector = const PatternDetector(minSampleSize: 5);
    });

    test('Enforces minimum sample size threshold (N < 5)', () {
      final logs = [
        TaskLogRecord(taskId: 't1', action: 'COMPLETED', durationMinutes: 30, occurredAt: now.subtract(const Duration(days: 2))),
        TaskLogRecord(taskId: 't2', action: 'COMPLETED', durationMinutes: 30, occurredAt: now.subtract(const Duration(days: 1))),
      ]; // Only 2 logs, threshold is 5

      final insights = detector.detectPatterns(
        userId: 'u1',
        logs: logs,
        tasks: [],
        goals: [],
        recentPlans: [],
      );

      final durationInsight = insights.firstWhere((i) => i.insightType == 'TASK_DURATION_SENSITIVITY');
      expect(durationInsight.evidenceStrength, EvidenceStrength.preliminary);
      expect(durationInsight.description, contains('Insufficient sample size (2/5)'));
    });

    test('Detects duration sensitivity when sample is sufficient (N >= 5)', () {
      final logs = [
        // 5 short tasks completed
        TaskLogRecord(taskId: 's1', action: 'COMPLETED', durationMinutes: 20, occurredAt: now.subtract(const Duration(days: 3))),
        TaskLogRecord(taskId: 's2', action: 'COMPLETED', durationMinutes: 25, occurredAt: now.subtract(const Duration(days: 3))),
        TaskLogRecord(taskId: 's3', action: 'COMPLETED', durationMinutes: 30, occurredAt: now.subtract(const Duration(days: 2))),
        TaskLogRecord(taskId: 's4', action: 'COMPLETED', durationMinutes: 20, occurredAt: now.subtract(const Duration(days: 1))),
        TaskLogRecord(taskId: 's5', action: 'COMPLETED', durationMinutes: 30, occurredAt: now.subtract(const Duration(days: 1))),
        // 5 long tasks postponed
        TaskLogRecord(taskId: 'l1', action: 'POSTPONED', durationMinutes: 60, occurredAt: now.subtract(const Duration(days: 3))),
        TaskLogRecord(taskId: 'l2', action: 'POSTPONED', durationMinutes: 90, occurredAt: now.subtract(const Duration(days: 2))),
        TaskLogRecord(taskId: 'l3', action: 'POSTPONED', durationMinutes: 60, occurredAt: now.subtract(const Duration(days: 2))),
        TaskLogRecord(taskId: 'l4', action: 'COMPLETED', durationMinutes: 60, occurredAt: now.subtract(const Duration(days: 1))),
        TaskLogRecord(taskId: 'l5', action: 'POSTPONED', durationMinutes: 75, occurredAt: now.subtract(const Duration(days: 1))),
      ];

      final insights = detector.detectPatterns(
        userId: 'u1',
        logs: logs,
        tasks: [],
        goals: [],
        recentPlans: [],
      );

      final durationInsight = insights.firstWhere((i) => i.insightType == 'TASK_DURATION_SENSITIVITY');
      expect(durationInsight.evidenceStrength, isIn([EvidenceStrength.moderate, EvidenceStrength.strong]));
      expect(durationInsight.title, contains('higher completion'));
      expect(durationInsight.suggestedHypothesis, isNotNull);
    });
  });
}
