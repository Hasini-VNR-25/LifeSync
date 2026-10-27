import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class CapacityMeter extends StatelessWidget {
  final int totalWorkloadMinutes;
  final int availableMinutes;
  final int capacityGapMinutes;

  const CapacityMeter({
    super.key,
    required this.totalWorkloadMinutes,
    required this.availableMinutes,
    required this.capacityGapMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = availableMinutes > 0 ? (totalWorkloadMinutes / availableMinutes).clamp(0.0, 1.5) : 1.0;
    final bool hasOverflow = capacityGapMinutes > 0;

    final Color barColor = hasOverflow
        ? AppColors.accentRose
        : (ratio > 0.85 ? AppColors.accentAmber : AppColors.accentTeal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasOverflow ? AppColors.accentRose.withOpacity(0.4) : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Capacity Balance', style: AppTypography.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasOverflow ? AppColors.accentRose.withOpacity(0.12) : AppColors.accentTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasOverflow ? '+${capacityGapMinutes}m Overflow' : '${availableMinutes - totalWorkloadMinutes}m Buffer',
                  style: AppTypography.labelMedium.copyWith(
                    color: hasOverflow ? AppColors.accentRose : AppColors.accentTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (ratio / 1.5).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: AppColors.surfaceLightElevated,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Workload: ${totalWorkloadMinutes}m (${(totalWorkloadMinutes / 60).toStringAsFixed(1)}h)',
                style: AppTypography.caption.copyWith(color: AppColors.textMutedDark),
              ),
              Text(
                'Available: ${availableMinutes}m (${(availableMinutes / 60).toStringAsFixed(1)}h)',
                style: AppTypography.caption.copyWith(color: AppColors.textMutedDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
