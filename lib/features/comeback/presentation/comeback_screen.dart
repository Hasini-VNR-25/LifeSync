import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../domain/models/recovery_plan.dart';

class ComebackScreen extends ConsumerStatefulWidget {
  const ComebackScreen({super.key});

  @override
  ConsumerState<ComebackScreen> createState() => _ComebackScreenState();
}

class _ComebackScreenState extends ConsumerState<ComebackScreen> {
  RecoveryPlan? _recoveryPlan;
  int _selectedProposalIndex = 0;
  bool _initialized = false;

  void _generateRecovery() {
    final tasks = ref.read(tasksProvider).value ?? [];
    final goals = ref.read(goalsProvider).value ?? [];
    final commitments = ref.read(fixedCommitmentsProvider).value ?? [];
    final user = ref.read(currentUserProvider).value;
    final recoveryEngine = ref.read(recoveryEngineProvider);

    final plan = recoveryEngine.buildRecoveryPlan(
      recoveryPlanId: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.id ?? 'demo_user',
      triggerReason: 'Workload exceeds daily capacity by 20 minutes with critical deadlines approaching.',
      allTasks: tasks,
      goals: goals,
      commitments: commitments,
      availableMinutes: user?.dailyAvailableMinutes ?? 180,
      recoveryWindowStart: DateTime.now(),
    );

    setState(() {
      _recoveryPlan = plan;
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    if (!_initialized && tasksAsync.hasValue) {
      _generateRecovery();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comeback Recovery Mode'),
      ),
      body: _recoveryPlan == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Supportive Hero Banner
                Card(
                  color: AppColors.accentRose.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.accentRose.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite_border, color: AppColors.accentRose),
                            const SizedBox(width: 8),
                            Text('Supportive Recovery Workflow', style: AppTypography.titleMedium.copyWith(color: AppColors.accentRose)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your original plan no longer fits the time available. Let\'s protect your nearest deadline and rebuild a manageable plan without cognitive overwhelm.',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Recovery Strategy Options Tabs
                Text('Select Recovery Strategy', style: AppTypography.titleLarge),
                const SizedBox(height: 10),
                ...List.generate(_recoveryPlan!.proposals.length, (idx) {
                  final prop = _recoveryPlan!.proposals[idx];
                  final isSelected = _selectedProposalIndex == idx;

                  return Card(
                    color: isSelected ? AppColors.accentTeal.withOpacity(0.08) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? AppColors.accentTeal : AppColors.borderLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _selectedProposalIndex = idx),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(prop.title, style: AppTypography.titleMedium),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: AppColors.accentTeal)
                                else
                                  const Icon(Icons.radio_button_unchecked, color: AppColors.textMutedDark),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(prop.rationale, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark)),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Scheduled: ${prop.plan.scheduledCount} tasks (${prop.plan.totalScheduledMinutes}m)'),
                                Text(
                                  'Score: ${prop.plan.overallScore.toStringAsFixed(0)} pts',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentTeal),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Splitting & Rescheduling Details
                final currentProp = _recoveryPlan!.proposals[_selectedProposalIndex];
                if (currentProp.splitTasks.isNotEmpty) ...[
                  Text('Automatic Task Splitting', style: AppTypography.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'To protect focus, heavy tasks were divided into 30-minute modules:',
                    style: AppTypography.caption.copyWith(color: AppColors.textMutedDark),
                  ),
                  const SizedBox(height: 8),
                  ...currentProp.splitTasks.map((t) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.call_split, color: AppColors.accentAmber),
                        title: Text(t.title, style: AppTypography.titleMedium),
                        subtitle: Text('Original: ${t.estimatedMinutes}m -> Split into Part 1 (30m) & Part 2 (${t.estimatedMinutes - 30}m)'),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    final repo = ref.read(lifeSyncRepositoryProvider);
                    await repo.applyRecoveryProposal(_recoveryPlan!, currentProp);
                    ref.invalidate(activePlanProvider);
                    ref.invalidate(lifeTwinProvider);
                    ref.invalidate(tasksProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Recovery plan approved and applied!')),
                    );
                    context.go('/dashboard');
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Approve Recovery Plan'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel & Keep Current Schedule'),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }
}
