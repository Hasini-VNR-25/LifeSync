import '../enums/evidence_strength.dart';
import '../models/insight.dart';
import '../models/task.dart';
import '../models/goal.dart';
import '../models/plan.dart';

class TaskLogRecord {
  final String taskId;
  final String action; // 'COMPLETED', 'POSTPONED', 'SPLIT'
  final int durationMinutes;
  final DateTime occurredAt;
  final bool onTime;

  const TaskLogRecord({
    required this.taskId,
    required this.action,
    required this.durationMinutes,
    required this.occurredAt,
    this.onTime = true,
  });
}

class PatternDetector {
  final int minSampleSize;

  const PatternDetector({this.minSampleSize = 5});

  /// Evaluates recorded logs and plan histories to extract deterministic insights
  List<Insight> detectPatterns({
    required String userId,
    required List<TaskLogRecord> logs,
    required List<Task> tasks,
    required List<Goal> goals,
    required List<PlanResult> recentPlans,
  }) {
    final List<Insight> insights = [];
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    // 1. PATTERN 1: Task Duration Sensitivity (Longer vs Shorter tasks)
    final durationInsight = _detectDurationSensitivity(userId, logs, twoWeeksAgo, now);
    if (durationInsight != null) {
      insights.add(durationInsight);
    }

    // 2. PATTERN 2: Chronic Planning Overload
    final overloadInsight = _detectChronicOverload(userId, recentPlans, twoWeeksAgo, now);
    if (overloadInsight != null) {
      insights.add(overloadInsight);
    }

    // 3. PATTERN 3: Life Area Underallocation
    final underallocationInsight = _detectLifeAreaUnderallocation(userId, goals, recentPlans, twoWeeksAgo, now);
    if (underallocationInsight != null) {
      insights.add(underallocationInsight);
    }

    return insights;
  }

  Insight? _detectDurationSensitivity(
    String userId,
    List<TaskLogRecord> logs,
    DateTime start,
    DateTime end,
  ) {
    final relevantLogs = logs.where((l) => l.occurredAt.isAfter(start) && l.occurredAt.isBefore(end)).toList();

    if (relevantLogs.length < minSampleSize) {
      return Insight(
        id: 'ins_duration_insufficient',
        userId: userId,
        insightType: 'TASK_DURATION_SENSITIVITY',
        title: 'Task Duration Patterns (Gathering Data)',
        description: 'Insufficient sample size (${relevantLogs.length}/$minSampleSize). LIFESYNC requires at least $minSampleSize logged task actions before reporting duration trends.',
        sampleSize: relevantLogs.length,
        observationStart: start,
        observationEnd: end,
        evidenceStrength: EvidenceStrength.preliminary,
        suggestedHypothesis: null,
        status: 'Active',
        createdAt: DateTime.now(),
      );
    }

    final shortTasks = relevantLogs.where((l) => l.durationMinutes <= 30).toList();
    final longTasks = relevantLogs.where((l) => l.durationMinutes >= 45).toList();

    if (shortTasks.isEmpty || longTasks.isEmpty) return null;

    final shortCompleted = shortTasks.where((l) => l.action == 'COMPLETED').length;
    final shortRate = shortCompleted / shortTasks.length;

    final longCompleted = longTasks.where((l) => l.action == 'COMPLETED').length;
    final longRate = longCompleted / longTasks.length;

    if (shortRate > longRate + 0.20) {
      final ratio = longRate > 0 ? (shortRate / longRate).toStringAsFixed(1) : '3.0';
      final strength = relevantLogs.length >= 15 ? EvidenceStrength.strong : EvidenceStrength.moderate;

      return Insight(
        id: 'ins_duration_sensitivity_${start.millisecondsSinceEpoch}',
        userId: userId,
        insightType: 'TASK_DURATION_SENSITIVITY',
        title: 'Shorter sessions show ${ratio}x higher completion in your logs',
        description: 'Over the last 14 days, tasks <= 30 mins were completed at ${(shortRate * 100).round()}% frequency, whereas tasks >= 45 mins were postponed more frequently (completed at ${(longRate * 100).round()}%). This is an empirical association in your records, not proof that duration alone causes delay.',
        evidenceData: {
          'shortTasksCount': shortTasks.length,
          'shortCompletionRate': shortRate,
          'longTasksCount': longTasks.length,
          'longCompletionRate': longRate,
          'sampleSize': relevantLogs.length,
        },
        sampleSize: relevantLogs.length,
        observationStart: start,
        observationEnd: end,
        evidenceStrength: strength,
        suggestedHypothesis: 'Splitting heavy study blocks into 30-minute modules will increase completion rate by at least 15%.',
        suggestedAction: 'Cap future study tasks to 30 minutes with 5-minute buffer breaks.',
        status: 'Active',
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  Insight? _detectChronicOverload(
    String userId,
    List<PlanResult> plans,
    DateTime start,
    DateTime end,
  ) {
    final relevantPlans = plans.where((p) => p.createdAt.isAfter(start)).toList();
    if (relevantPlans.length < minSampleSize) return null;

    int overloadedCount = 0;
    for (final p in relevantPlans) {
      if (p.totalScheduledMinutes > (p.totalScheduledMinutes + p.remainingAvailableMinutes) * 0.95 || p.unscheduledItems.isNotEmpty) {
        overloadedCount++;
      }
    }

    final overloadRatio = overloadedCount / relevantPlans.length;
    if (overloadRatio >= 0.6) {
      return Insight(
        id: 'ins_chronic_overload_${start.millisecondsSinceEpoch}',
        userId: userId,
        insightType: 'CHRONIC_OVERLOAD',
        title: 'Schedules regularly strain available planning capacity',
        description: 'In $overloadedCount out of ${relevantPlans.length} recent planning sessions, your initial workload filled > 95% of available capacity or left overflow tasks unscheduled.',
        evidenceData: {
          'overloadedSessions': overloadedCount,
          'totalSessions': relevantPlans.length,
          'overloadRate': overloadRatio,
        },
        sampleSize: relevantPlans.length,
        observationStart: start,
        observationEnd: end,
        evidenceStrength: relevantPlans.length >= 10 ? EvidenceStrength.strong : EvidenceStrength.moderate,
        suggestedHypothesis: 'Leaving a 20% unallocated buffer will reduce end-of-day postponed tasks.',
        suggestedAction: 'Reserve 30 minutes of open buffer time daily.',
        status: 'Active',
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  Insight? _detectLifeAreaUnderallocation(
    String userId,
    List<Goal> goals,
    List<PlanResult> plans,
    DateTime start,
    DateTime end,
  ) {
    if (plans.isEmpty || goals.isEmpty) return null;

    final highPriorityGoals = goals.where((g) => g.priority >= 3 && g.status == 'Active').toList();
    if (highPriorityGoals.isEmpty) return null;

    final Map<String, int> totalMinutesByArea = {};
    int totalAllMinutes = 0;

    for (final plan in plans) {
      for (final entry in plan.timeAllocationByLifeArea.entries) {
        totalMinutesByArea[entry.key] = (totalMinutesByArea[entry.key] ?? 0) + entry.value;
        totalAllMinutes += entry.value;
      }
    }

    if (totalAllMinutes < 120) return null; // Need sufficient recorded volume

    for (final goal in highPriorityGoals) {
      final areaMins = totalMinutesByArea[goal.lifeAreaId] ?? 0;
      final percentage = (areaMins / totalAllMinutes) * 100;
      if (percentage < 10.0) {
        return Insight(
          id: 'ins_underallocation_${goal.lifeAreaId}',
          userId: userId,
          insightType: 'LIFE_AREA_UNDERALLOCATION',
          title: 'High-priority goal area receives under 10% of planned time',
          description: 'Although "${goal.title}" is designated as High Priority, its life area received only ${percentage.toStringAsFixed(1)}% ($areaMins minutes) of your recorded planning time.',
          evidenceData: {
            'lifeAreaId': goal.lifeAreaId,
            'goalTitle': goal.title,
            'minutesAllocated': areaMins,
            'totalMinutes': totalAllMinutes,
            'percentage': percentage,
          },
          sampleSize: plans.length,
          observationStart: start,
          observationEnd: end,
          evidenceStrength: EvidenceStrength.moderate,
          suggestedHypothesis: 'Scheduling a dedicated 30-minute block for this area 3x/week will restore balance without impacting academic goals.',
          suggestedAction: 'Use Balance-First strategy in What-If Simulator.',
          status: 'Active',
          createdAt: DateTime.now(),
        );
      }
    }

    return null;
  }
}
