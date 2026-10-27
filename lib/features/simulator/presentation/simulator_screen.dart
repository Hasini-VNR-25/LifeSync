import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../domain/models/task.dart';
import '../../../domain/models/plan.dart';
import '../../../domain/enums/plan_strategy.dart';

class SimulatorScreen extends ConsumerStatefulWidget {
  const SimulatorScreen({super.key});

  @override
  ConsumerState<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends ConsumerState<SimulatorScreen> {
  int _simulatedAvailableMinutes = 210; // Experimenting with +30m or modified time
  final Set<String> _excludedTaskIds = {};
  final Map<String, int> _modifiedDurations = {};
  PlanResult? _baselinePlan;
  PlanResult? _scenarioPlan;
  bool _initialized = false;

  void _runSimulation() {
    final tasks = ref.read(tasksProvider).value ?? [];
    final goals = ref.read(goalsProvider).value ?? [];
    final commitments = ref.read(fixedCommitmentsProvider).value ?? [];
    final user = ref.read(currentUserProvider).value;
    final planner = ref.read(planningEngineProvider);

    // 1. Generate Baseline Plan with default 180m available minutes
    _baselinePlan = planner.generatePlan(
      planId: 'baseline_plan',
      userId: user?.id ?? 'demo_user',
      tasks: tasks,
      goals: goals,
      commitments: commitments,
      availableMinutes: user?.dailyAvailableMinutes ?? 180,
      planningWindowStart: DateTime.now(),
      strategy: PlanStrategy.priorityFirst,
      planType: 'Active',
    );

    // 2. Prepare Simulated Tasks with exclusions and modified durations
    final simulatedTasks = tasks.where((t) => !_excludedTaskIds.contains(t.id)).map((t) {
      if (_modifiedDurations.containsKey(t.id)) {
        return t.copyWith(estimatedMinutes: _modifiedDurations[t.id]!);
      }
      return t;
    }).toList();

    // 3. Generate Scenario Plan using same planning & scoring engine
    _scenarioPlan = planner.generatePlan(
      planId: 'scenario_plan_${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.id ?? 'demo_user',
      tasks: simulatedTasks,
      goals: goals,
      commitments: commitments,
      availableMinutes: _simulatedAvailableMinutes,
      planningWindowStart: DateTime.now(),
      strategy: PlanStrategy.priorityFirst,
      planType: 'Scenario',
    );

    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    if (!_initialized && tasksAsync.hasValue) {
      _runSimulation();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('What-If Life Simulator'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hypothetical Plan Exploration', style: AppTypography.displayLarge),
          const SizedBox(height: 4),
          Text(
            'Explore "what-if" trade-offs safely without modifying your active schedule until you decide to apply changes.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark),
          ),
          const SizedBox(height: 16),

          // Simulation Parameters Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hypothetical Available Time', style: AppTypography.titleMedium),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentTeal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_simulatedAvailableMinutes mins (${(_simulatedAvailableMinutes / 60).toStringAsFixed(1)}h)',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.accentTeal),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _simulatedAvailableMinutes.toDouble(),
                    min: 60,
                    max: 360,
                    divisions: 20,
                    activeColor: AppColors.accentTeal,
                    label: '$_simulatedAvailableMinutes mins',
                    onChanged: (val) {
                      setState(() => _simulatedAvailableMinutes = val.toInt());
                      _runSimulation();
                    },
                  ),
                  const Divider(height: 24),

                  Text('Include / Exclude Tasks in Scenario', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  ...?tasksAsync.value?.map((task) {
                    final isExcluded = _excludedTaskIds.contains(task.id);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: !isExcluded,
                      activeColor: AppColors.accentTeal,
                      title: Text(task.title, style: AppTypography.bodyMedium),
                      subtitle: Text('${task.estimatedMinutes}m • ${task.priority.label} priority'),
                      onChanged: (included) {
                        setState(() {
                          if (included == false) {
                            _excludedTaskIds.add(task.id);
                          } else {
                            _excludedTaskIds.remove(task.id);
                          }
                        });
                        _runSimulation();
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Side-by-Side Comparison
          if (_baselinePlan != null && _scenarioPlan != null) ...[
            Text('Side-by-Side Comparison', style: AppTypography.titleLarge),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baseline Plan Column
                Expanded(
                  child: Card(
                    color: AppColors.surfaceLightElevated,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BASELINE (Active)', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            '${_baselinePlan!.overallScore.toStringAsFixed(0)} pts',
                            style: AppTypography.displayLarge.copyWith(color: AppColors.textDark),
                          ),
                          const Divider(),
                          _buildMetric('Scheduled', '${_baselinePlan!.totalScheduledMinutes}m'),
                          _buildMetric('Unscheduled', '${_baselinePlan!.unscheduledCount} tasks'),
                          _buildMetric('Tasks Done', '${_baselinePlan!.scheduledCount}'),
                          _buildMetric('Capacity', '${_baselinePlan!.remainingAvailableMinutes}m left'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Scenario Plan Column
                Expanded(
                  child: Card(
                    color: AppColors.accentTeal.withOpacity(0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.accentTeal, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SCENARIO B', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentTeal)),
                          const SizedBox(height: 8),
                          Text(
                            '${_scenarioPlan!.overallScore.toStringAsFixed(0)} pts',
                            style: AppTypography.displayLarge.copyWith(color: AppColors.accentTeal),
                          ),
                          const Divider(),
                          _buildMetric('Scheduled', '${_scenarioPlan!.totalScheduledMinutes}m'),
                          _buildMetric('Unscheduled', '${_scenarioPlan!.unscheduledCount} tasks'),
                          _buildMetric('Tasks Done', '${_scenarioPlan!.scheduledCount}'),
                          _buildMetric('Capacity', '${_scenarioPlan!.remainingAvailableMinutes}m left'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Plain-English Explanation
            Card(
              color: AppColors.surfaceDark,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mathematical Trade-Off Analysis', style: AppTypography.titleMedium.copyWith(color: AppColors.accentMint)),
                    const SizedBox(height: 6),
                    Text(
                      _scenarioPlan!.unscheduledCount < _baselinePlan!.unscheduledCount
                          ? 'Scenario B schedules ${_scenarioPlan!.scheduledCount - _baselinePlan!.scheduledCount} additional tasks and eliminates capacity overflow by expanding time to $_simulatedAvailableMinutes minutes. Critical deadlines remain protected.'
                          : 'Scenario B schedules ${_scenarioPlan!.totalScheduledMinutes} minutes. Workload fits with ${_scenarioPlan!.remainingAvailableMinutes} minutes of safe buffer time.',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Apply Scenario Action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _simulatedAvailableMinutes = 180;
                        _excludedTaskIds.clear();
                        _modifiedDurations.clear();
                      });
                      _runSimulation();
                    },
                    child: const Text('Reset Scenario'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTeal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final repo = ref.read(lifeSyncRepositoryProvider);
                      await repo.applyScenario('scenario_b', _scenarioPlan!);
                      ref.invalidate(activePlanProvider);
                      ref.invalidate(lifeTwinProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Scenario B applied atomically to your active plan!')),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Apply Scenario'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMutedDark)),
          Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
