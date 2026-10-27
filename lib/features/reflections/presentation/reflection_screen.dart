import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../domain/models/reflection.dart';

class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key});

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  final _winsController = TextEditingController();
  final _challengesController = TextEditingController();
  final _nextStepController = TextEditingController();
  double _workloadRating = 3.0; // 1 to 5

  @override
  Widget build(BuildContext context) {
    final reflectionsAsync = ref.watch(reflectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reflection & Review'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Reflect & Calibrate', style: AppTypography.displayLarge),
          const SizedBox(height: 4),
          Text(
            'Recording observations helps the Personal Growth Investigator discover which scheduling habits serve you best.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark),
          ),
          const SizedBox(height: 16),

          // New Reflection Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today\'s Calibration', style: AppTypography.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _winsController,
                    decoration: const InputDecoration(
                      labelText: 'What worked well today?',
                      hintText: 'e.g., Completed DBMS indexing queries during the morning session.',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _challengesController,
                    decoration: const InputDecoration(
                      labelText: 'What caused friction or disruption?',
                      hintText: 'e.g., Extended faculty meeting cut into placement prep.',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nextStepController,
                    decoration: const InputDecoration(
                      labelText: 'One concrete adjustment for tomorrow',
                      hintText: 'e.g., Break Java concurrency into 25m blocks.',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Text('Perceived Cognitive Workload (1: Low, 5: High)', style: AppTypography.titleMedium),
                  Slider(
                    value: _workloadRating,
                    min: 1.0,
                    max: 5.0,
                    divisions: 4,
                    label: _workloadRating.toInt().toString(),
                    activeColor: AppColors.accentTeal,
                    onChanged: (val) => setState(() => _workloadRating = val),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final wins = _winsController.text.trim();
                        final chal = _challengesController.text.trim();
                        final next = _nextStepController.text.trim();

                        if (wins.isEmpty || chal.isEmpty || next.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill out all reflection prompts.')),
                          );
                          return;
                        }

                        final repo = ref.read(lifeSyncRepositoryProvider);
                        final user = await ref.read(currentUserProvider.future);
                        final now = DateTime.now();

                        final reflection = Reflection(
                          id: 'ref_${now.millisecondsSinceEpoch}',
                          userId: user?.id ?? 'demo_user',
                          reflectionDate: now,
                          wins: wins,
                          challenges: chal,
                          nextStep: next,
                          selfReportedWorkload: _workloadRating.toInt(),
                          createdAt: now,
                        );

                        await repo.saveReflection(reflection);
                        ref.invalidate(reflectionsProvider);
                        _winsController.clear();
                        _challengesController.clear();
                        _nextStepController.clear();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reflection saved to your growth log!')),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Save Reflection'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Previous Reflections History
          Text('Logged Reflections', style: AppTypography.titleLarge),
          const SizedBox(height: 10),

          reflectionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (reflections) {
              if (reflections.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No previous reflections recorded. Complete your first log above.'),
                  ),
                );
              }

              return Column(
                children: reflections.map((refItem) {
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
                              Text(
                                DateFormat('EEEE, MMM dd, yyyy').format(refItem.reflectionDate),
                                style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (refItem.selfReportedWorkload != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentTeal.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Workload: ${refItem.selfReportedWorkload}/5', style: AppTypography.caption),
                                ),
                            ],
                          ),
                          const Divider(height: 16),
                          Text('Wins: ${refItem.wins}', style: AppTypography.bodyMedium),
                          const SizedBox(height: 4),
                          Text('Friction: ${refItem.challenges}', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark)),
                          const SizedBox(height: 4),
                          Text('Next Step: ${refItem.nextStep}', style: AppTypography.bodyMedium.copyWith(color: AppColors.accentTeal, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
