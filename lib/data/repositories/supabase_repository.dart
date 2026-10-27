import 'package:supabase_flutter/supabase_flutter.dart';
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
import '../../domain/enums/task_status.dart';
import '../../domain/algorithms/planning_engine.dart';
import 'in_memory_repository.dart';

class SupabaseRepository implements IAuthRepository, ILifeSyncRepository {
  final SupabaseClient? client;
  final InMemoryRepository fallbackRepository;

  SupabaseRepository({this.client, required this.fallbackRepository});

  bool get isConnected => client != null && client!.auth.currentUser != null;

  // --- IAuthRepository ---
  @override
  Future<Profile?> getCurrentProfile() async {
    if (!isConnected) return fallbackRepository.getCurrentProfile();
    final user = client!.auth.currentUser!;
    final res = await client!.from('profiles').select().eq('id', user.id).maybeSingle();
    if (res == null) return null;
    return Profile.fromJson(res);
  }

  @override
  Future<Profile> signIn({required String email, required String password}) async {
    if (client == null) return fallbackRepository.signIn(email: email, password: password);
    final response = await client!.auth.signInWithPassword(email: email, password: password);
    final user = response.user!;
    final profileRes = await client!.from('profiles').select().eq('id', user.id).single();
    return Profile.fromJson(profileRes);
  }

  @override
  Future<Profile> signUp({required String email, required String password, required String displayName}) async {
    if (client == null) return fallbackRepository.signUp(email: email, password: password, displayName: displayName);
    final response = await client!.auth.signUp(email: email, password: password);
    final user = response.user!;
    final profile = Profile(
      id: user.id,
      displayName: displayName,
      timezone: 'UTC',
      dailyAvailableMinutes: 180,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await client!.from('profiles').insert(profile.toJson());
    return profile;
  }

  @override
  Future<void> signOut() async {
    if (client == null) return fallbackRepository.signOut();
    await client!.auth.signOut();
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    if (!isConnected) return fallbackRepository.updateProfile(profile);
    await client!.from('profiles').update(profile.toJson()).eq('id', profile.id);
  }

  @override
  Future<void> deleteAccountAndData(String userId) async {
    if (!isConnected) return fallbackRepository.deleteAccountAndData(userId);
    await client!.from('profiles').delete().eq('id', userId);
    await client!.auth.signOut();
  }

  // --- ILifeSyncRepository ---
  @override
  Future<List<LifeArea>> getLifeAreas(String userId) async {
    if (!isConnected) return fallbackRepository.getLifeAreas(userId);
    final res = await client!.from('life_areas').select().eq('user_id', userId).order('priority', ascending: false);
    return (res as List).map((e) => LifeArea.fromJson(e)).toList();
  }

  @override
  Future<void> saveLifeArea(LifeArea area) async {
    if (!isConnected) return fallbackRepository.saveLifeArea(area);
    await client!.from('life_areas').upsert(area.toJson());
  }

  @override
  Future<void> deleteLifeArea(String areaId) async {
    if (!isConnected) return fallbackRepository.deleteLifeArea(areaId);
    await client!.from('life_areas').delete().eq('id', areaId);
  }

  @override
  Future<List<Goal>> getGoals(String userId) async {
    if (!isConnected) return fallbackRepository.getGoals(userId);
    final res = await client!.from('goals').select().eq('user_id', userId).order('priority', ascending: false);
    return (res as List).map((e) => Goal.fromJson(e)).toList();
  }

  @override
  Future<void> saveGoal(Goal goal) async {
    if (!isConnected) return fallbackRepository.saveGoal(goal);
    await client!.from('goals').upsert(goal.toJson());
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    if (!isConnected) return fallbackRepository.deleteGoal(goalId);
    await client!.from('goals').delete().eq('id', goalId);
  }

  @override
  Future<List<Task>> getTasks(String userId) async {
    if (!isConnected) return fallbackRepository.getTasks(userId);
    final res = await client!.from('tasks').select().eq('user_id', userId);
    return (res as List).map((e) => Task.fromJson(e)).toList();
  }

  @override
  Future<void> saveTask(Task task) async {
    if (!isConnected) return fallbackRepository.saveTask(task);
    await client!.from('tasks').upsert(task.toJson());
  }

  @override
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus, {int? actualMinutes}) async {
    if (!isConnected) return fallbackRepository.updateTaskStatus(taskId, newStatus, actualMinutes: actualMinutes);
    await client!.from('tasks').update({
      'status': newStatus.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', taskId);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    if (!isConnected) return fallbackRepository.deleteTask(taskId);
    await client!.from('tasks').delete().eq('id', taskId);
  }

  @override
  Future<List<FixedCommitment>> getFixedCommitments(String userId) async {
    if (!isConnected) return fallbackRepository.getFixedCommitments(userId);
    final res = await client!.from('fixed_commitments').select().eq('user_id', userId).order('start_time');
    return (res as List).map((e) => FixedCommitment.fromJson(e)).toList();
  }

  @override
  Future<void> saveFixedCommitment(FixedCommitment commitment) async {
    if (!isConnected) return fallbackRepository.saveFixedCommitment(commitment);
    await client!.from('fixed_commitments').upsert(commitment.toJson());
  }

  @override
  Future<void> deleteFixedCommitment(String commitmentId) async {
    if (!isConnected) return fallbackRepository.deleteFixedCommitment(commitmentId);
    await client!.from('fixed_commitments').delete().eq('id', commitmentId);
  }

  @override
  Future<PlanResult?> getActivePlan(String userId) async {
    return fallbackRepository.getActivePlan(userId);
  }

  @override
  Future<void> savePlan(PlanResult plan) async {
    await fallbackRepository.savePlan(plan);
  }

  @override
  Future<List<Scenario>> getScenarios(String userId) async {
    return fallbackRepository.getScenarios(userId);
  }

  @override
  Future<void> saveScenario(Scenario scenario) async {
    await fallbackRepository.saveScenario(scenario);
  }

  @override
  Future<void> applyScenario(String scenarioId, PlanResult plan) async {
    await fallbackRepository.applyScenario(scenarioId, plan);
  }

  @override
  Future<List<RecoveryPlan>> getRecoveryPlans(String userId) async {
    return fallbackRepository.getRecoveryPlans(userId);
  }

  @override
  Future<void> saveRecoveryPlan(RecoveryPlan plan) async {
    await fallbackRepository.saveRecoveryPlan(plan);
  }

  @override
  Future<void> applyRecoveryProposal(RecoveryPlan recoveryPlan, RecoveryProposal proposal) async {
    await fallbackRepository.applyRecoveryProposal(recoveryPlan, proposal);
  }

  @override
  Future<List<Insight>> getInsights(String userId) async {
    return fallbackRepository.getInsights(userId);
  }

  @override
  Future<void> saveInsight(Insight insight) async {
    await fallbackRepository.saveInsight(insight);
  }

  @override
  Future<List<Experiment>> getExperiments(String userId) async {
    return fallbackRepository.getExperiments(userId);
  }

  @override
  Future<void> saveExperiment(Experiment experiment) async {
    await fallbackRepository.saveExperiment(experiment);
  }

  @override
  Future<void> updateExperiment(Experiment experiment) async {
    await fallbackRepository.updateExperiment(experiment);
  }

  @override
  Future<List<Reflection>> getReflections(String userId) async {
    if (!isConnected) return fallbackRepository.getReflections(userId);
    final res = await client!.from('reflections').select().eq('user_id', userId).order('reflection_date', ascending: false);
    return (res as List).map((e) => Reflection.fromJson(e)).toList();
  }

  @override
  Future<void> saveReflection(Reflection reflection) async {
    if (!isConnected) return fallbackRepository.saveReflection(reflection);
    await client!.from('reflections').upsert(reflection.toJson());
  }

  @override
  Future<LifeTwinSnapshot> calculateLifeTwinSnapshot(String userId, {int? customAvailableMinutes}) async {
    return fallbackRepository.calculateLifeTwinSnapshot(userId, customAvailableMinutes: customAvailableMinutes);
  }

  @override
  Future<void> loadDemoDataset(String userId) async {
    await fallbackRepository.loadDemoDataset(userId);
  }
}
