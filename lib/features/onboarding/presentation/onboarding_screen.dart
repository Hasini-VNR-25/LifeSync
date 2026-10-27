import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../domain/enums/plan_strategy.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final Set<String> _selectedAreas = {'Academics & Learning', 'Career & Placement', 'Fitness & Health'};
  int _dailyAvailableMinutes = 180;
  PlanStrategy _preferredStrategy = PlanStrategy.priorityFirst;

  final List<String> _availableLifeAreas = [
    'Academics & Learning',
    'Career & Placement',
    'Fitness & Health',
    'Personal Development',
    'Hobbies & Relationships',
    'Daily Responsibilities',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalize LIFESYNC'),
        actions: [
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: AppColors.surfaceLightElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: _buildStepContent(),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),

                  ElevatedButton(
                    onPressed: () async {
                      if (_currentStep < 2) {
                        setState(() => _currentStep++);
                      } else {
                        final authRepo = ref.read(authRepositoryProvider);
                        final user = await authRepo.getCurrentProfile();
                        if (user != null) {
                          await authRepo.updateProfile(user.copyWith(
                            dailyAvailableMinutes: _dailyAvailableMinutes,
                            planningPreferences: {
                              'preferredStrategy': _preferredStrategy.name,
                              'areas': _selectedAreas.toList(),
                            },
                          ));
                          ref.invalidate(currentUserProvider);
                          ref.invalidate(lifeTwinProvider);
                        }
                        context.go('/dashboard');
                      }
                    },
                    child: Text(_currentStep == 2 ? 'Complete Setup' : 'Next Step'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return ListView(
          children: [
            Text('1. Choose Active Life Areas', style: AppTypography.displayLarge),
            const SizedBox(height: 6),
            Text(
              'Select areas you want to balance. LIFESYNC ensures your schedule reflects your broader life priorities.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark),
            ),
            const SizedBox(height: 20),
            ..._availableLifeAreas.map((area) {
              final isChecked = _selectedAreas.contains(area);
              return CheckboxListTile(
                value: isChecked,
                activeColor: AppColors.accentTeal,
                title: Text(area, style: AppTypography.titleMedium),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedAreas.add(area);
                    } else {
                      _selectedAreas.remove(area);
                    }
                  });
                },
              );
            }),
          ],
        );

      case 1:
        return ListView(
          children: [
            Text('2. Daily Planning Capacity', style: AppTypography.displayLarge),
            const SizedBox(height: 6),
            Text(
              'How many minutes can you realistically dedicate to focused tasks each day, excluding sleep and classes?',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark),
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                '$_dailyAvailableMinutes minutes',
                style: AppTypography.displayLarge.copyWith(color: AppColors.accentTeal),
              ),
            ),
            Center(
              child: Text(
                '${(_dailyAvailableMinutes / 60).toStringAsFixed(1)} hours of focused time',
                style: AppTypography.caption.copyWith(color: AppColors.textMutedDark),
              ),
            ),
            const SizedBox(height: 20),
            Slider(
              value: _dailyAvailableMinutes.toDouble(),
              min: 60,
              max: 360,
              divisions: 20,
              activeColor: AppColors.accentTeal,
              onChanged: (val) => setState(() => _dailyAvailableMinutes = val.toInt()),
            ),
          ],
        );

      case 2:
      default:
        return ListView(
          children: [
            Text('3. Preferred Planning Style', style: AppTypography.displayLarge),
            const SizedBox(height: 6),
            Text(
              'Choose your default scheduling heuristic. You can always change this in the planner.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark),
            ),
            const SizedBox(height: 20),
            ...PlanStrategy.values.map((strat) {
              return RadioListTile<PlanStrategy>(
                value: strat,
                groupValue: _preferredStrategy,
                activeColor: AppColors.accentTeal,
                title: Text(strat.title, style: AppTypography.titleMedium),
                subtitle: Text(strat.description, style: AppTypography.caption),
                onChanged: (val) {
                  if (val != null) setState(() => _preferredStrategy = val);
                },
              );
            }),
          ],
        );
    }
  }
}
