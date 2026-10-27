import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/priority_badge.dart';
import '../../../domain/models/task.dart';
import '../../../domain/enums/priority_level.dart';
import '../../../domain/enums/task_status.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _filter = 'All'; // 'All', 'Open', 'Completed'

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Backlog'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentTeal,
        foregroundColor: Colors.white,
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tasks) {
          final filtered = tasks.where((t) {
            if (_filter == 'Open') return t.status.isOutstanding;
            if (_filter == 'Completed') return t.status == TaskStatus.completed;
            return true;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: ['All', 'Open', 'Completed'].map((tab) {
                    final isSelected = _filter == tab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tab),
                        selected: isSelected,
                        selectedColor: AppColors.accentTeal.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.accentTeal : AppColors.textDark,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _filter = tab);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No tasks found in this view.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final task = filtered[index];
                          final bool isDone = task.status == TaskStatus.completed;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Checkbox(
                                value: isDone,
                                onChanged: (val) async {
                                  final repo = ref.read(lifeSyncRepositoryProvider);
                                  await repo.updateTaskStatus(
                                    task.id,
                                    val == true ? TaskStatus.completed : TaskStatus.pending,
                                  );
                                  ref.invalidate(tasksProvider);
                                  ref.invalidate(lifeTwinProvider);
                                },
                              ),
                              title: Text(
                                task.title,
                                style: AppTypography.titleMedium.copyWith(
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                  color: isDone ? AppColors.textMutedDark : AppColors.textDark,
                                ),
                              ),
                              subtitle: Text(
                                '${task.estimatedMinutes} mins • ${task.taskType.label}${task.dueAt != null ? " • Due: " + DateFormat("hh:mm a").format(task.dueAt!) : ""}',
                                style: AppTypography.caption,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PriorityBadge(priority: task.priority),
                                  PopupMenuButton<String>(
                                    onSelected: (action) async {
                                      final repo = ref.read(lifeSyncRepositoryProvider);
                                      if (action == 'postpone') {
                                        await repo.updateTaskStatus(task.id, TaskStatus.postponed);
                                      } else if (action == 'delete') {
                                        await repo.deleteTask(task.id);
                                      }
                                      ref.invalidate(tasksProvider);
                                      ref.invalidate(lifeTwinProvider);
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'postpone', child: Text('Postpone Task')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete Task')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final durationController = TextEditingController(text: '30');
    PriorityLevel selectedPriority = PriorityLevel.medium;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Task Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Estimated Minutes (> 0)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PriorityLevel>(
                      value: selectedPriority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: PriorityLevel.values.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedPriority = val);
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
                    final title = titleController.text.trim();
                    final mins = int.tryParse(durationController.text.trim()) ?? 0;
                    if (title.isEmpty || mins <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid title and positive duration (> 0).')),
                      );
                      return;
                    }

                    final repo = ref.read(lifeSyncRepositoryProvider);
                    final user = await ref.read(currentUserProvider.future);
                    final now = DateTime.now();

                    final newTask = Task(
                      id: 'task_${now.millisecondsSinceEpoch}',
                      userId: user?.id ?? 'demo_user',
                      title: title,
                      estimatedMinutes: mins,
                      priority: selectedPriority,
                      dueAt: now.add(const Duration(hours: 6)),
                      status: TaskStatus.pending,
                      taskType: mins <= 20 ? TaskType.quickTask : TaskType.standard,
                      allowSplitting: true,
                      createdAt: now,
                      updatedAt: now,
                    );

                    await repo.saveTask(newTask);
                    ref.invalidate(tasksProvider);
                    ref.invalidate(lifeTwinProvider);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Add Task'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
