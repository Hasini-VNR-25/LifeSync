import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/loading_indicator.dart';

class InvestigatorScreen extends ConsumerWidget {
  const InvestigatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);
    final experimentsAsync = ref.watch(experimentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Growth Investigator'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Evidence-Backed Behavioral Intelligence', style: AppTypography.displayLarge),
          const SizedBox(height: 4),
          Text(
            'LIFESYNC detects recurring patterns in your actual planning logs and formulates falsifiable experiments.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark),
          ),
          const SizedBox(height: 20),

          // Active Experiments Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Experiments', style: AppTypography.titleLarge),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Falsifiable Tests', style: AppTypography.caption.copyWith(color: AppColors.accentTeal, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          experimentsAsync.when(
            loading: () => const LoadingIndicator(message: 'Loading experiments...'),
            error: (e, _) => Text('Error: $e'),
            data: (experiments) {
              if (experiments.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No active experiments. Explore the insights below to start one.'),
                  ),
                );
              }
              return Column(
                children: experiments.map((exp) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push('/experiment-detail', extra: exp),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentTeal.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('EXPERIMENT', style: AppTypography.caption.copyWith(color: AppColors.accentTeal, fontWeight: FontWeight.w700)),
                                ),
                                Text(exp.status.label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(exp.hypothesis, style: AppTypography.titleMedium),
                            const SizedBox(height: 6),
                            Text(
                              'Change: ${exp.changeDescription}',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark),
                            ),
                            if (exp.result != null) ...[
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Baseline: ${(exp.result!.baselineValue * 100).toStringAsFixed(0)}%'),
                                  Text(
                                    'Result: ${(exp.result!.resultValue * 100).toStringAsFixed(0)}% (+${exp.result!.deltaPercentage.toStringAsFixed(0)}%)',
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentEmerald),
                                  ),
                                  Text('N = ${exp.result!.sampleSize}'),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // Observed Behavioral Patterns & Insights
          Text('Empirical Insights & Patterns', style: AppTypography.titleLarge),
          const SizedBox(height: 10),

          insightsAsync.when(
            loading: () => const LoadingIndicator(message: 'Analyzing logs...'),
            error: (e, _) => Text('Error: $e'),
            data: (insights) {
              if (insights.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Gathering more logs to detect empirical patterns. Check back after a few days of planning.'),
                  ),
                );
              }
              return Column(
                children: insights.map((ins) {
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
                              Text(ins.insightType, style: AppTypography.caption.copyWith(color: AppColors.accentIndigo, fontWeight: FontWeight.w700)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accentIndigo.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(ins.evidenceStrength.label, style: AppTypography.caption.copyWith(color: AppColors.accentIndigo)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(ins.title, style: AppTypography.titleMedium),
                          const SizedBox(height: 6),
                          Text(ins.description, style: AppTypography.bodyMedium),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text('Sample size: N = ${ins.sampleSize}', style: AppTypography.caption.copyWith(color: AppColors.textMutedDark)),
                              const Spacer(),
                              if (ins.suggestedHypothesis != null)
                                TextButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Experiment active for this insight.')),
                                    );
                                  },
                                  icon: const Icon(Icons.science, size: 16),
                                  label: const Text('View Experiment'),
                                ),
                            ],
                          ),
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
