import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/capacity_meter.dart';
import '../../../shared/widgets/stat_card.dart';

class LifeTwinScreen extends ConsumerWidget {
  const LifeTwinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final twinAsync = ref.watch(lifeTwinProvider);
    final lifeAreasAsync = ref.watch(lifeAreasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Twin Intelligence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(lifeTwinProvider),
          ),
        ],
      ),
      body: twinAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading Life Twin: $e')),
        data: (snapshot) {
          final lifeAreas = lifeAreasAsync.value ?? [];
          final areaMap = {for (final a in lifeAreas) a.id: a};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Header explanation
              Text('Continuous Mathematical Model', style: AppTypography.displayLarge),
              const SizedBox(height: 6),
              Text(
                'The Life Twin evaluates your actual recorded commitments against your daily capacity to keep plans realistic.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark),
              ),
              const SizedBox(height: 16),

              // 2. Capacity Meter
              CapacityMeter(
                totalWorkloadMinutes: snapshot.totalEstimatedWorkloadMinutes,
                availableMinutes: snapshot.availablePlanningMinutes,
                capacityGapMinutes: snapshot.capacityGapMinutes,
              ),
              const SizedBox(height: 16),

              // 3. Transparent Plain-English Explanation
              Card(
                color: snapshot.hasCapacityGap
                    ? AppColors.accentRose.withOpacity(0.08)
                    : AppColors.accentTeal.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: snapshot.hasCapacityGap
                        ? AppColors.accentRose.withOpacity(0.3)
                        : AppColors.accentTeal.withOpacity(0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        snapshot.hasCapacityGap ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                        color: snapshot.hasCapacityGap ? AppColors.accentRose : AppColors.accentTeal,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snapshot.feasibility.title,
                              style: AppTypography.titleMedium.copyWith(
                                color: snapshot.hasCapacityGap ? AppColors.accentRose : AppColors.accentTeal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(snapshot.plainEnglishSummary, style: AppTypography.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Distribution by Life Area
              Text('Time Allocation by Life Area', style: AppTypography.titleLarge),
              const SizedBox(height: 10),
              if (snapshot.plannedMinutesByLifeArea.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No active tasks assigned to life areas for today.'),
                  ),
                )
              else
                ...snapshot.plannedMinutesByLifeArea.entries.map((entry) {
                  final area = areaMap[entry.key];
                  final name = area?.name ?? 'General';
                  final colorHex = area?.colorHex ?? '#0D9488';
                  final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                  final mins = entry.value;
                  final percentage = snapshot.totalEstimatedWorkloadMinutes > 0
                      ? (mins / snapshot.totalEstimatedWorkloadMinutes * 100).toStringAsFixed(0)
                      : '0';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
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
                                  Text(name, style: AppTypography.titleMedium),
                                ],
                              ),
                              Text('$mins mins ($percentage%)', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (mins / snapshot.totalEstimatedWorkloadMinutes).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceLightElevated,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),

              // 5. Neglected Goals Alert
              if (snapshot.neglectedGoals.isNotEmpty) ...[
                Text('Goals at Risk of Neglect', style: AppTypography.titleLarge),
                const SizedBox(height: 10),
                ...snapshot.neglectedGoals.map((goal) {
                  return Card(
                    color: AppColors.accentAmber.withOpacity(0.08),
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber, color: AppColors.accentAmber),
                      title: Text(goal.title, style: AppTypography.titleMedium),
                      subtitle: const Text('Designated High Priority, but 0 minutes planned today.'),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],

              // 6. Action Button
              ElevatedButton.icon(
                onPressed: () => context.push('/simulator'),
                icon: const Icon(Icons.alt_route),
                label: const Text('Open What-If Simulator'),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}
