import '../enums/plan_strategy.dart';
import 'plan_item.dart';

class PlanResult {
  final String id;
  final String userId;
  final String planType; // 'Active', 'Candidate', 'Scenario', 'Recovery'
  final PlanStrategy strategy;
  final List<PlanItem> scheduledItems;
  final List<UnscheduledItem> unscheduledItems;
  final Map<String, int> timeAllocationByLifeArea; // areaId -> minutes
  final int totalScheduledMinutes;
  final int remainingAvailableMinutes;
  final List<String> hardConstraintViolations;
  final List<String> softWarnings;
  final List<DeadlineRisk> deadlineRisks;
  final double overallScore;
  final Map<String, double> scoreBreakdown;
  final String status; // 'Draft', 'Applied', 'Discarded'
  final DateTime createdAt;

  const PlanResult({
    required this.id,
    required this.userId,
    this.planType = 'Active',
    required this.strategy,
    required this.scheduledItems,
    this.unscheduledItems = const [],
    this.timeAllocationByLifeArea = const {},
    required this.totalScheduledMinutes,
    required this.remainingAvailableMinutes,
    this.hardConstraintViolations = const [],
    this.softWarnings = const [],
    this.deadlineRisks = const [],
    required this.overallScore,
    this.scoreBreakdown = const {},
    this.status = 'Draft',
    required this.createdAt,
  });

  bool get isFeasible => hardConstraintViolations.isEmpty;
  int get scheduledCount => scheduledItems.length;
  int get unscheduledCount => unscheduledItems.length;

  PlanResult copyWith({
    String? status,
    String? planType,
  }) {
    return PlanResult(
      id: id,
      userId: userId,
      planType: planType ?? this.planType,
      strategy: strategy,
      scheduledItems: scheduledItems,
      unscheduledItems: unscheduledItems,
      timeAllocationByLifeArea: timeAllocationByLifeArea,
      totalScheduledMinutes: totalScheduledMinutes,
      remainingAvailableMinutes: remainingAvailableMinutes,
      hardConstraintViolations: hardConstraintViolations,
      softWarnings: softWarnings,
      deadlineRisks: deadlineRisks,
      overallScore: overallScore,
      scoreBreakdown: scoreBreakdown,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
