import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../domain/models/goal.dart';
import '../../../domain/enums/priority_level.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final areasAsync = ref.watch(lifeAreasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Life Areas'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentTeal,
        foregroundColor: Colors.white,
        onPressed: () => _showAddGoalDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading goals: $e')),
        data: (goals) {
          final areas = areasAsync.value ?? [];
          final areaMap = {for (final a in areas) a.id: a};

          if (goals.isEmpty) {
            return const Center(
              child: Text('No goals created yet. Tap + to define your first goal.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final area = areaMap[goal.lifeAreaId];
              final colorHex = area?.colorHex ?? '#0D9488';
              final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(area?.name ?? 'General', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentTeal.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Priority ${goal.priority}',
                              style: AppTypography.caption.copyWith(color: AppColors.accentTeal, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(goal.title, style: AppTypography.titleMedium),
                      if (goal.description != null && goal.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(goal.description!, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark)),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Target: ${DateFormat('MMM dd, yyyy').format(goal.targetDate)}',
                            style: AppTypography.caption.copyWith(color: AppColors.textMutedDark),
                          ),
                          Text(goal.status, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    int priority = 3;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final areas = ref.watch(lifeAreasProvider).value ?? [];
            String selectedAreaId = areas.isNotEmpty ? areas.first.id : 'area_academics';

            return AlertDialog(
              title: const Text('New Strategic Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Goal Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description / Scope'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: priority,
                      decoration: const InputDecoration(labelText: 'Priority Level'),
                      items: const [
                        DropdownMenuItem(value: 4, child: Text('Critical / Urgent (4)')),
                        DropdownMenuItem(value: 3, child: Text('High Priority (3)')),
                        DropdownMenuItem(value: 2, child: Text('Medium Priority (2)')),
                        DropdownMenuItem(value: 1, child: Text('Low Priority (1)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => priority = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final repo = ref.read(lifeSyncRepositoryProvider);
                    final user = await ref.read(currentUserProvider.future);
                    final now = DateTime.now();

                    final newGoal = Goal(
                      id: 'goal_${now.millisecondsSinceEpoch}',
                      userId: user?.id ?? 'demo_user',
                      lifeAreaId: selectedAreaId,
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      startDate: now,
                      targetDate: now.add(const Duration(days: 60)),
                      priority: priority,
                      createdAt: now,
                      updatedAt: now,
                    );

                    await repo.saveGoal(newGoal);
                    ref.invalidate(goalsProvider);
                    ref.invalidate(lifeTwinProvider);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Save Goal'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
