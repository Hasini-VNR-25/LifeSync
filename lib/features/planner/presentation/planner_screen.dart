import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/score_breakdown_card.dart';
import '../../../shared/widgets/priority_badge.dart';
import '../../../domain/enums/plan_strategy.dart';
import '../../../domain/models/plan.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  PlanStrategy _selectedStrategy = PlanStrategy.priorityFirst;
  PlanResult? _currentPlan;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final commitmentsAsync = ref.watch(fixedCommitmentsProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Daily Planner'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Heuristic Constraint Planner', style: AppTypography.displayLarge),
          const SizedBox(height: 4),
          Text(
            'Generates deterministic, clash-free schedules respecting fixed commitments, deadlines, and capacity.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark),
          ),
          const SizedBox(height: 16),

          // Strategy Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Planning Strategy', style: AppTypography.titleMedium),
                  const SizedBox(height: 12),
                  ...PlanStrategy.values.map((strat) {
                    return RadioListTile<PlanStrategy>(
                      value: strat,
                      groupValue: _selectedStrategy,
                      activeColor: AppColors.accentTeal,
                      title: Text(strat.title, style: AppTypography.titleMedium),
                      subtitle: Text(strat.description, style: AppTypography.caption),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStrategy = val);
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating
                          ? null
                          : () {
                              final tasks = tasksAsync.value ?? [];
                              final goals = goalsAsync.value ?? [];
                              final commitments = commitmentsAsync.value ?? [];
                              final user = userAsync.value;
                              final planner = ref.read(planningEngineProvider);

                              setState(() => _isGenerating = true);
                              final plan = planner.generatePlan(
                                planId: 'plan_${DateTime.now().millisecondsSinceEpoch}',
                                userId: user?.id ?? 'demo_user',
                                tasks: tasks,
                                goals: goals,
                                commitments: commitments,
                                availableMinutes: user?.dailyAvailableMinutes ?? 180,
                                planningWindowStart: DateTime.now(),
                                strategy: _selectedStrategy,
                                planType: 'Candidate',
                              );
                              setState(() {
                                _currentPlan = plan;
                                _isGenerating = false;
                              });
                            },
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(_isGenerating ? 'Evaluating Constraints...' : 'Generate Adaptive Schedule'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Generated Plan Details
          if (_currentPlan != null) ...[
            ScoreBreakdownCard(
              overallScore: _currentPlan!.overallScore,
              breakdown: _currentPlan!.scoreBreakdown,
            ),
            const SizedBox(height: 16),

            // Summary stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('SCHEDULED', style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Text('${_currentPlan!.scheduledCount} tasks', style: AppTypography.titleMedium),
                      ],
                    ),
                    Column(
                      children: [
                        Text('TOTAL TIME', style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Text('${_currentPlan!.totalScheduledMinutes}m', style: AppTypography.titleMedium),
                      ],
                    ),
                    Column(
                      children: [
                        Text('UNSCHEDULED', style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentPlan!.unscheduledCount} tasks',
                          style: AppTypography.titleMedium.copyWith(
                            color: _currentPlan!.unscheduledCount > 0 ? AppColors.accentRose : AppColors.accentEmerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scheduled Tasks Timeline
            Text('Scheduled Timeline', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            ..._currentPlan!.scheduledItems.map((item) {
              final startStr = DateFormat('hh:mm a').format(item.scheduledStart);
              final endStr = DateFormat('hh:mm a').format(item.scheduledEnd);
              final task = item.task;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accentTeal.withOpacity(0.12),
                    child: const Icon(Icons.schedule, color: AppColors.accentTeal, size: 20),
                  ),
                  title: Text(task?.title ?? 'Task ${item.taskId}', style: AppTypography.titleMedium),
                  subtitle: Text('$startStr - $endStr (${item.durationMinutes}m)'),
                  trailing: task != null ? PriorityBadge(priority: task.priority) : null,
                ),
              );
            }),
            const SizedBox(height: 16),

            // Unscheduled Tasks & Reasons
            if (_currentPlan!.unscheduledItems.isNotEmpty) ...[
              Text('Unscheduled Workload & Infeasibility Reasons', style: AppTypography.titleLarge),
              const SizedBox(height: 8),
              ..._currentPlan!.unscheduledItems.map((item) {
                return Card(
                  color: AppColors.accentRose.withOpacity(0.06),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.block, color: AppColors.accentRose),
                    title: Text(item.task?.title ?? 'Task ${item.taskId}', style: AppTypography.titleMedium),
                    subtitle: Text(item.reason, style: AppTypography.bodyMedium),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Apply as Active Plan Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentEmerald,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final repo = ref.read(lifeSyncRepositoryProvider);
                await repo.savePlan(_currentPlan!.copyWith(status: 'Applied', planType: 'Active'));
                ref.invalidate(activePlanProvider);
                ref.invalidate(lifeTwinProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plan accepted and applied as Active Plan!')),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Apply as Active Plan'),
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }
}
