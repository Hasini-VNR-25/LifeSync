import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_life_sync_repository.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/life_area.dart';
import '../../domain/models/goal.dart';
import '../../domain/models/task.dart';
import '../../domain/models/fixed_commitment.dart';
import '../../domain/models/plan.dart';
import '../../domain/models/scenario.dart';
import '../../domain/models/recovery_plan.dart';
import '../../domain/models/insight.dart';
import '../../domain/models/experiment.dart';
import '../../domain/models/reflection.dart';
import '../../domain/models/life_twin_snapshot.dart';
import '../../domain/algorithms/planning_engine.dart';
import '../../domain/algorithms/scoring_engine.dart';
import '../../domain/algorithms/recovery_engine.dart';
import '../../domain/algorithms/pattern_detector.dart';
import '../../domain/algorithms/experiment_evaluator.dart';
import '../../data/repositories/in_memory_repository.dart';
import '../../data/datasources/demo_seed_data.dart';

// Algorithm Singletons
final scoringEngineProvider = Provider<ScoringEngine>((ref) => const ScoringEngine());

final planningEngineProvider = Provider<PlanningEngine>((ref) {
  final scoring = ref.watch(scoringEngineProvider);
  return PlanningEngine(scoringEngine: scoring);
});

final recoveryEngineProvider = Provider<RecoveryEngine>((ref) {
  final planner = ref.watch(planningEngineProvider);
  return RecoveryEngine(planningEngine: planner);
});

final patternDetectorProvider = Provider<PatternDetector>((ref) => const PatternDetector());
final experimentEvaluatorProvider = Provider<ExperimentEvaluator>((ref) => const ExperimentEvaluator());

// Core In-Memory / Supabase Repository instance
final inMemoryRepoInstance = InMemoryRepository();

final authRepositoryProvider = Provider<IAuthRepository>((ref) => inMemoryRepoInstance);
final lifeSyncRepositoryProvider = Provider<ILifeSyncRepository>((ref) => inMemoryRepoInstance);

// State Notifier / Future Providers
final currentUserProvider = FutureProvider<Profile?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getCurrentProfile();
});

final lifeTwinProvider = FutureProvider<LifeTwinSnapshot>((ref) async {
  final repo = ref.watch(lifeSyncRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  final uid = user?.id ?? DemoSeedData.demoUserId;
  return repo.calculateLifeTwinSnapshot(uid);
});

final tasksProvider = FutureProvider<List<Task>>((ref) async {
  final repo = ref.watch(lifeSyncRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  final uid = user?.id ?? DemoSeedData.demoUserId;
  return repo.getTasks(uid);
});

final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  final repo = ref.watch(lifeSyncRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  final uid = user?.id ?? DemoSeedData.demoUserId;
  return repo.getGoals(uid);
});

final lifeAreasProvider = FutureProvider<List<LifeArea>>((ref) async {
  final repo = ref.watch(lifeSyncRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  final uid = user?.id ?? DemoSeedData.demoUserId;
  return repo.getLifeAreas(uid);
});

final fixedCommitmentsProvider = FutureProvider<List<FixedCommitment>>((ref) async {
  final repo = ref.watch(lifeSyncRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  final uid = user?.id ?? DemoSeedData.demoUserId;
  return repo.getFixedCommitments(uid);
});

final activePlanProvider = FutureProvider<PlanResult?>((ref) async {
  final repo = ref.watch(lifeSyncRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  final uid = user?.id ?? DemoSeedData.demoUserId;
  return repo.getActivePlan(uid);
});

final scenariosProvider = FutureProvider<List<Scenario>>((ref) async {
  final repo = ref.watch(lifeSyncRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  final uid = user?.id ?? DemoSeedData.demoUserId;
  return repo.getScenarios(uid);
});

final recoveryPlansProvider = FutureProvider<List<RecoveryPlan>>((ref) async {
  final repo = ref.watch(lifeSyncRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  final uid = user?.id ?? DemoSeedData.demoUserId;
  return repo.getRecoveryPlans(uid);
});

final insightsProvider = FutureProvider<List<Insight>>((ref) async {
  final repo = ref.watch(lifeSyncRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  final uid = user?.id ?? DemoSeedData.demoUserId;
  return repo.getInsights(uid);
});

final experimentsProvider = FutureProvider<List<Experiment>>((ref) async {
  final repo = ref.watch(lifeSyncRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  final uid = user?.id ?? DemoSeedData.demoUserId;
  return repo.getExperiments(uid);
});

final reflectionsProvider = FutureProvider<List<Reflection>>((ref) async {
  final repo = ref.watch(lifeSyncRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  final uid = user?.id ?? DemoSeedData.demoUserId;
  return repo.getReflections(uid);
});
