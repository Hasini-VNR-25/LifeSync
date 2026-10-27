import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/enums/priority_level.dart';

class PriorityBadge extends StatelessWidget {
  final PriorityLevel priority;

  const PriorityBadge({super.key, required this.priority});

  Color _getColor() {
    switch (priority) {
      case PriorityLevel.critical:
        return AppColors.accentRose;
      case PriorityLevel.high:
        return AppColors.accentAmber;
      case PriorityLevel.medium:
        return AppColors.accentTeal;
      case PriorityLevel.low:
        return AppColors.textMutedDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority.label,
        style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
