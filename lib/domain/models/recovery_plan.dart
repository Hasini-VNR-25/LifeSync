import 'plan.dart';
import 'task.dart';

class RecoveryProposal {
  final String id;
  final String title;
  final String rationale;
  final PlanResult plan;
  final List<Task> splitTasks;
  final List<Task> deferredTasks;

  const RecoveryProposal({
    required this.id,
    required this.title,
    required this.rationale,
    required this.plan,
    this.splitTasks = const [],
    this.deferredTasks = const [],
  });
}

class RecoveryPlan {
  final String id;
  final String userId;
  final String triggerReason;
  final int overdueTaskCount;
  final int capacityReductionMinutes;
  final List<RecoveryProposal> proposals;
  final String? selectedProposalId;
  final String status; // 'Proposed', 'Accepted', 'Rejected', 'Edited'
  final DateTime createdAt;
  final DateTime? acceptedAt;

  const RecoveryPlan({
    required this.id,
    required this.userId,
    required this.triggerReason,
    required this.overdueTaskCount,
    this.capacityReductionMinutes = 0,
    required this.proposals,
    this.selectedProposalId,
    this.status = 'Proposed',
    required this.createdAt,
    this.acceptedAt,
  });

  RecoveryPlan copyWith({
    String? selectedProposalId,
    String? status,
    DateTime? acceptedAt,
  }) {
    return RecoveryPlan(
      id: id,
      userId: userId,
      triggerReason: triggerReason,
      overdueTaskCount: overdueTaskCount,
      capacityReductionMinutes: capacityReductionMinutes,
      proposals: proposals,
      selectedProposalId: selectedProposalId ?? this.selectedProposalId,
      status: status ?? this.status,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}
