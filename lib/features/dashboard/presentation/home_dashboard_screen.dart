import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/capacity_meter.dart';
import '../../../shared/widgets/priority_badge.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../domain/enums/task_status.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifeTwinAsync = ref.watch(lifeTwinProvider);
    final profileAsync = ref.watch(currentUserProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accentTeal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sync_alt, color: AppColors.accentTeal, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('LIFESYNC', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reload Demo Data',
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              final repo = ref.read(lifeSyncRepositoryProvider);
              final user = await ref.read(currentUserProvider.future);
              if (user != null) {
                await repo.loadDemoDataset(user.id);
                ref.invalidate(lifeTwinProvider);
                ref.invalidate(tasksProvider);
                ref.invalidate(goalsProvider);
                ref.invalidate(activePlanProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo dataset reloaded (180m available vs 200m tasks).')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: lifeTwinAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (snapshot) {
          final profile = profileAsync.value;
          final bool showComebackAlert = snapshot.hasCapacityGap || snapshot.hasOverdue;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(lifeTwinProvider);
              ref.invalidate(tasksProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Welcome & Context
                Text(
                  'Good day, ${profile?.displayName.split(' ').first ?? 'Alex'}',
                  style: AppTypography.displayLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Here is your live Life Twin intelligence overview.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark),
                ),
                const SizedBox(height: 16),

                // 2. COMEBACK MODE BANNER (Supportive, nonjudgmental recovery alert)
                if (showComebackAlert) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentRose.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentRose.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.healing_outlined, color: AppColors.accentRose, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Life Disruption Detected',
                              style: AppTypography.titleMedium.copyWith(color: AppColors.accentRose),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.hasCapacityGap
                              ? 'Your open tasks (${snapshot.totalEstimatedWorkloadMinutes}m) exceed available capacity (${snapshot.availablePlanningMinutes}m) by ${snapshot.capacityGapMinutes} minutes. Let\'s recover gracefully.'
                              : 'You have ${snapshot.overdueTasks.length} overdue tasks waiting. Let\'s reschedule without guilt.',
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentRose,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => context.push('/comeback'),
                          icon: const Icon(Icons.bolt),
                          label: const Text('Enter Comeback Mode'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. CAPACITY METER
                CapacityMeter(
                  totalWorkloadMinutes: snapshot.totalEstimatedWorkloadMinutes,
                  availableMinutes: snapshot.availablePlanningMinutes,
                  capacityGapMinutes: snapshot.capacityGapMinutes,
                ),
                const SizedBox(height: 16),

                // 4. STAT CARDS
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'COMPLETED TODAY',
                        value: '${snapshot.completedTasksCount}',
                        subtitle: '${snapshot.completedTodayMinutes}m focused',
                        icon: Icons.check_circle_outline,
                        accentColor: AppColors.accentEmerald,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'UPCOMING URGENT',
                        value: '${snapshot.upcomingCriticalTasks.length}',
                        subtitle: 'Due within 12h',
                        icon: Icons.alarm,
                        accentColor: AppColors.accentAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. QUICK ACTIONS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/simulator'),
                        icon: const Icon(Icons.science_outlined),
                        label: const Text('What-If Sim'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/planner'),
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: const Text('Adaptive Plan'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 6. TODAY'S TASKS LIST
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Tasks', style: AppTypography.titleLarge),
                    TextButton(
                      onPressed: () => context.push('/tasks'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                tasksAsync.when(
                  loading: () => const LoadingIndicator(message: 'Loading tasks...'),
                  error: (e, _) => Text('Error loading tasks: $e'),
                  data: (tasks) {
                    final openTasks = tasks.where((t) => t.status.isOutstanding).toList();
                    if (openTasks.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('All tasks completed! Enjoy your buffer time.'),
                        ),
                      );
                    }
                    return Column(
                      children: openTasks.map((task) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Checkbox(
                              value: task.status == TaskStatus.completed,
                              onChanged: (val) async {
                                final repo = ref.read(lifeSyncRepositoryProvider);
                                await repo.updateTaskStatus(
                                  task.id,
                                  val == true ? TaskStatus.completed : TaskStatus.pending,
                                );
                                ref.invalidate(lifeTwinProvider);
                                ref.invalidate(tasksProvider);
                              },
                            ),
                            title: Text(task.title, style: AppTypography.titleMedium),
                            subtitle: Text(
                              '${task.estimatedMinutes} mins • ${task.taskType.label}',
                              style: AppTypography.caption.copyWith(color: AppColors.textMutedDark),
                            ),
                            trailing: PriorityBadge(priority: task.priority),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
