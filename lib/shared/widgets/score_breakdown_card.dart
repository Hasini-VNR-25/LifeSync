import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ScoreBreakdownCard extends StatelessWidget {
  final double overallScore;
  final Map<String, double> breakdown;

  const ScoreBreakdownCard({
    super.key,
    required this.overallScore,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan Quality Score J(P)', style: AppTypography.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Multi-objective heuristic evaluation',
                      style: AppTypography.caption.copyWith(color: AppColors.textMutedDark),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${overallScore.toStringAsFixed(1)}/100',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.accentTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildMetricRow('Deadline Satisfaction D(P)', breakdown['deadlineSatisfaction'] ?? 0, '+35% wt', AppColors.accentEmerald),
            _buildMetricRow('Goal & Area Coverage G(P)', breakdown['goalCoverage'] ?? 0, '+25% wt', AppColors.accentTeal),
            _buildMetricRow('Schedule Fit F(P)', breakdown['timeFit'] ?? 0, '+25% wt', AppColors.accentIndigo),
            if ((breakdown['overloadPenalty'] ?? 0) > 0)
              _buildMetricRow('Overload Penalty O(P)', breakdown['overloadPenalty'] ?? 0, '-15% wt', AppColors.accentRose, isPenalty: true),
            if ((breakdown['conflictPenalty'] ?? 0) > 0)
              _buildMetricRow('Commitment Clashes C(P)', breakdown['conflictPenalty'] ?? 0, '-10% wt', AppColors.accentAmber, isPenalty: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, double value, String weight, Color color, {bool isPenalty = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label, style: AppTypography.bodyMedium),
            ],
          ),
          Row(
            children: [
              Text(
                weight,
                style: AppTypography.caption.copyWith(color: AppColors.textMutedDark),
              ),
              const SizedBox(width: 8),
              Text(
                '${isPenalty ? "-" : ""}${value.toStringAsFixed(0)}',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPenalty ? AppColors.accentRose : AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
