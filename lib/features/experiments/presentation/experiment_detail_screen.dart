import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/experiment.dart';
import '../../../domain/enums/experiment_status.dart';
import '../../../shared/providers/app_providers.dart';

class ExperimentDetailScreen extends ConsumerWidget {
  final Experiment experiment;

  const ExperimentDetailScreen({super.key, required this.experiment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final result = experiment.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiment Evaluation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('EMPIRICAL TRIAL', style: AppTypography.caption.copyWith(color: AppColors.accentTeal, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text(experiment.status.label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),

          // Hypothesis
          Text(experiment.hypothesis, style: AppTypography.displayLarge),
          const SizedBox(height: 12),

          // Intervention Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Applied Planning Intervention', style: AppTypography.titleMedium),
                  const SizedBox(height: 6),
                  Text(experiment.changeDescription, style: AppTypography.bodyMedium),
                  const Divider(height: 20),
                  Text('Metric Definition', style: AppTypography.titleMedium),
                  const SizedBox(height: 4),
                  Text(experiment.metricDefinition, style: AppTypography.caption.copyWith(color: AppColors.textMutedDark)),
                  const SizedBox(height: 8),
                  Text(
                    'Window: ${dateFormat.format(experiment.experimentStart)} - ${dateFormat.format(experiment.experimentEnd)}',
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quantitative Results & Measurement
          if (result != null) ...[
            Text('Measured Outcomes', style: AppTypography.titleLarge),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: AppColors.surfaceLightElevated,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BASELINE RATE', style: AppTypography.caption),
                          const SizedBox(height: 6),
                          Text('${(result.baselineValue * 100).toStringAsFixed(0)}%', style: AppTypography.headlineMedium),
                          const SizedBox(height: 4),
                          const Text('Prior 14 days', style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: AppColors.accentEmerald.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.accentEmerald),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TRIAL RATE', style: AppTypography.caption.copyWith(color: AppColors.accentEmerald, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('${(result.resultValue * 100).toStringAsFixed(0)}%', style: AppTypography.headlineMedium.copyWith(color: AppColors.accentEmerald)),
                          const SizedBox(height: 4),
                          Text('+${result.deltaPercentage.toStringAsFixed(0)}% gain (N=${result.sampleSize})', style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scientific Limitations Disclosure
            Card(
              color: AppColors.accentAmber.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.accentAmber, size: 20),
                        const SizedBox(width: 8),
                        Text('Methodological Limitations', style: AppTypography.titleMedium.copyWith(color: AppColors.accentAmber)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(result.limitations, style: AppTypography.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Decisions
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final repo = ref.read(lifeSyncRepositoryProvider);
                await repo.updateExperiment(experiment.copyWith(status: ExperimentStatus.adopted));
                ref.invalidate(experimentsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Habit adopted permanently into your daily planning defaults!')),
                );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.verified),
              label: const Text('Adopt Intervention Permanently'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Observing'),
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }
}
