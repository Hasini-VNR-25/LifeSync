import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings & Profile'),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Identity Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.accentTeal.withOpacity(0.15),
                        child: Text(
                          profile?.displayName.isNotEmpty == true ? profile!.displayName[0].toUpperCase() : 'A',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.accentTeal),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile?.displayName ?? 'Alex Rivera', style: AppTypography.titleLarge),
                            const SizedBox(height: 2),
                            Text('CS Student • ${profile?.timezone ?? "UTC"}', style: AppTypography.caption.copyWith(color: AppColors.textMutedDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Planning Capacity Preferences
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Planning Capacity & Limits', style: AppTypography.titleMedium),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Daily Available Planning Time'),
                        subtitle: Text('${profile?.dailyAvailableMinutes ?? 180} minutes (${((profile?.dailyAvailableMinutes ?? 180) / 60).toStringAsFixed(1)} hours)'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () {
                            _showEditCapacityDialog(context, ref, profile?.dailyAvailableMinutes ?? 180);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Developer & Demonstration Controls
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Demonstration & Lab Controls', style: AppTypography.titleMedium),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.replay_circle_filled_outlined, color: AppColors.accentTeal),
                        title: const Text('Reset Demo Scenario (Section 17)'),
                        subtitle: const Text('Reload 180m capacity with DBMS, Java, Placement, Exercise, and Reading tasks.'),
                        onTap: () async {
                          final repo = ref.read(lifeSyncRepositoryProvider);
                          await repo.loadDemoDataset(profile?.id ?? 'demo_user');
                          ref.invalidate(lifeTwinProvider);
                          ref.invalidate(tasksProvider);
                          ref.invalidate(goalsProvider);
                          ref.invalidate(activePlanProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Demo scenario loaded successfully.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Account & Data Privacy
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Data Ownership & Account Privacy', style: AppTypography.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'You maintain complete control over your planning data. All scheduling runs deterministically without third-party LLM data exposure.',
                        style: AppTypography.caption.copyWith(color: AppColors.textMutedDark),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_forever_outlined, color: AppColors.accentRose),
                        title: Text('Delete Account & Clear All Data', style: TextStyle(color: AppColors.accentRose)),
                        onTap: () => _confirmAccountDeletion(context, ref, profile?.id ?? 'demo_user'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  void _showEditCapacityDialog(BuildContext context, WidgetRef ref, int currentMins) {
    int updatedMins = currentMins;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Update Daily Available Minutes'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$updatedMins minutes (${(updatedMins / 60).toStringAsFixed(1)} hours)', style: AppTypography.headlineMedium),
                  Slider(
                    value: updatedMins.toDouble(),
                    min: 60,
                    max: 480,
                    divisions: 28,
                    activeColor: AppColors.accentTeal,
                    onChanged: (val) => setDialogState(() => updatedMins = val.toInt()),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final repo = ref.read(authRepositoryProvider);
                    final user = await repo.getCurrentProfile();
                    if (user != null) {
                      await repo.updateProfile(user.copyWith(dailyAvailableMinutes: updatedMins));
                      ref.invalidate(currentUserProvider);
                      ref.invalidate(lifeTwinProvider);
                    }
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmAccountDeletion(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account and Planning History?'),
        content: const Text(
          'This action is irreversible. All goals, tasks, plan snapshots, reflections, and experimental logs will be permanently deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose, foregroundColor: Colors.white),
            onPressed: () async {
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.deleteAccountAndData(userId);
              ref.invalidate(currentUserProvider);
              ref.invalidate(lifeTwinProvider);
              Navigator.of(ctx).pop();
              context.go('/login');
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}
