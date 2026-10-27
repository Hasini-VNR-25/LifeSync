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
import '../datasources/demo_seed_data.dart';

class InMemoryRepository implements IAuthRepository, ILifeSyncRepository {
  final PlanningEngine planningEngine;

  Profile? _currentProfile;
  final List<LifeArea> _lifeAreas = [];
  final List<Goal> _goals = [];
  final List<Task> _tasks = [];
  final List<FixedCommitment> _commitments = [];
  final List<PlanResult> _plans = [];
  final List<Scenario> _scenarios = [];
  final List<RecoveryPlan> _recoveryPlans = [];
  final List<Insight> _insights = [];
  final List<Experiment> _experiments = [];
  final List<Reflection> _reflections = [];

  InMemoryRepository({this.planningEngine = const PlanningEngine()}) {
    // Automatically seed demo data on initialization
    _loadInitialSeed();
  }

  void _loadInitialSeed() {
    _currentProfile = DemoSeedData.getProfile();
    final uid = _currentProfile!.id;
    _lifeAreas.addAll(DemoSeedData.getLifeAreas(uid));
    _goals.addAll(DemoSeedData.getGoals(uid));
    _tasks.addAll(DemoSeedData.getTasks(uid));
    _commitments.addAll(DemoSeedData.getFixedCommitments(uid));
    _insights.addAll(DemoSeedData.getInsights(uid));
    _experiments.addAll(DemoSeedData.getExperiments(uid));
  }

  // --- IAuthRepository implementation ---
  @override
  Future<Profile?> getCurrentProfile() async {
    return _currentProfile;
  }

  @override
  Future<Profile> signIn({required String email, required String password}) async {
    _currentProfile ??= DemoSeedData.getProfile();
    return _currentProfile!;
  }

  @override
  Future<Profile> signUp({required String email, required String password, required String displayName}) async {
    _currentProfile = Profile(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      displayName: displayName,
      timezone: 'UTC',
      dailyAvailableMinutes: 180,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _currentProfile!;
  }

  @override
  Future<void> signOut() async {
    _currentProfile = null;
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    _currentProfile = profile;
  }

  @override
  Future<void> deleteAccountAndData(String userId) async {
    _currentProfile = null;
    _lifeAreas.clear();
    _goals.clear();
    _tasks.clear();
    _commitments.clear();
    _plans.clear();
    _scenarios.clear();
    _recoveryPlans.clear();
    _insights.clear();
    _experiments.clear();
    _reflections.clear();
  }

  // --- ILifeSyncRepository implementation ---
  @override
  Future<List<LifeArea>> getLifeAreas(String userId) async {
    return List.unmodifiable(_lifeAreas.where((a) => a.userId == userId));
  }

  @override
  Future<void> saveLifeArea(LifeArea area) async {
    final index = _lifeAreas.indexWhere((a) => a.id == area.id);
    if (index >= 0) {
      _lifeAreas[index] = area;
    } else {
      _lifeAreas.add(area);
    }
  }

  @override
  Future<void> deleteLifeArea(String areaId) async {
    _lifeAreas.removeWhere((a) => a.id == areaId);
  }

  @override
  Future<List<Goal>> getGoals(String userId) async {
    return List.unmodifiable(_goals.where((g) => g.userId == userId));
  }

  @override
  Future<void> saveGoal(Goal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      _goals[index] = goal;
    } else {
      _goals.add(goal);
    }
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    _goals.removeWhere((g) => g.id == goalId);
  }

  @override
  Future<List<Task>> getTasks(String userId) async {
    return List.unmodifiable(_tasks.where((t) => t.userId == userId));
  }

  @override
  Future<void> saveTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    } else {
      _tasks.add(task);
    }
  }

  @override
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus, {int? actualMinutes}) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      _tasks[index] = _tasks[index].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
  }

  @override
  Future<List<FixedCommitment>> getFixedCommitments(String userId) async {
    return List.unmodifiable(_commitments.where((c) => c.userId == userId));
  }

  @override
  Future<void> saveFixedCommitment(FixedCommitment commitment) async {
    final index = _commitments.indexWhere((c) => c.id == commitment.id);
    if (index >= 0) {
      _commitments[index] = commitment;
    } else {
      _commitments.add(commitment);
    }
  }

  @override
  Future<void> deleteFixedCommitment(String commitmentId) async {
    _commitments.removeWhere((c) => c.id == commitmentId);
  }

  @override
  Future<PlanResult?> getActivePlan(String userId) async {
    final active = _plans.where((p) => p.userId == userId && p.status == 'Applied').toList();
    if (active.isNotEmpty) return active.last;
    return _plans.where((p) => p.userId == userId).isNotEmpty ? _plans.where((p) => p.userId == userId).last : null;
  }

  @override
  Future<void> savePlan(PlanResult plan) async {
    _plans.add(plan);
  }

  @override
  Future<List<Scenario>> getScenarios(String userId) async {
    return List.unmodifiable(_scenarios.where((s) => s.userId == userId));
  }

  @override
  Future<void> saveScenario(Scenario scenario) async {
    final index = _scenarios.indexWhere((s) => s.id == scenario.id);
    if (index >= 0) {
      _scenarios[index] = scenario;
    } else {
      _scenarios.add(scenario);
    }
  }

  @override
  Future<void> applyScenario(String scenarioId, PlanResult plan) async {
    // 1. Mark scenario as Applied
    final index = _scenarios.indexWhere((s) => s.id == scenarioId);
    if (index >= 0) {
      _scenarios[index] = _scenarios[index].copyWith(status: 'Applied');
    }
    // 2. Mark plan as Applied and persist as active
    final appliedPlan = plan.copyWith(status: 'Applied', planType: 'Active');
    _plans.add(appliedPlan);
  }

  @override
  Future<List<RecoveryPlan>> getRecoveryPlans(String userId) async {
    return List.unmodifiable(_recoveryPlans.where((r) => r.userId == userId));
  }

  @override
  Future<void> saveRecoveryPlan(RecoveryPlan plan) async {
    _recoveryPlans.add(plan);
  }

  @override
  Future<void> applyRecoveryProposal(RecoveryPlan recoveryPlan, RecoveryProposal proposal) async {
    // Mark recovery plan accepted
    final index = _recoveryPlans.indexWhere((r) => r.id == recoveryPlan.id);
    if (index >= 0) {
      _recoveryPlans[index] = recoveryPlan.copyWith(
        status: 'Accepted',
        selectedProposalId: proposal.id,
        acceptedAt: DateTime.now(),
      );
    }
    // If proposal generated split tasks, replace original tasks
    for (final orig in proposal.splitTasks) {
      _tasks.removeWhere((t) => t.id == orig.id);
    }
    for (final planItem in proposal.plan.scheduledItems) {
      if (planItem.task != null && !_tasks.any((t) => t.id == planItem.task!.id)) {
        _tasks.add(planItem.task!);
      }
    }
    // Save proposal plan as active
    final activeRecoveryPlan = proposal.plan.copyWith(status: 'Applied', planType: 'Active');
    _plans.add(activeRecoveryPlan);
  }

  @override
  Future<List<Insight>> getInsights(String userId) async {
    return List.unmodifiable(_insights.where((i) => i.userId == userId));
  }

  @override
  Future<void> saveInsight(Insight insight) async {
    _insights.add(insight);
  }

  @override
  Future<List<Experiment>> getExperiments(String userId) async {
    return List.unmodifiable(_experiments.where((e) => e.userId == userId));
  }

  @override
  Future<void> saveExperiment(Experiment experiment) async {
    _experiments.add(experiment);
  }

  @override
  Future<void> updateExperiment(Experiment experiment) async {
    final index = _experiments.indexWhere((e) => e.id == experiment.id);
    if (index >= 0) {
      _experiments[index] = experiment;
    }
  }

  @override
  Future<List<Reflection>> getReflections(String userId) async {
    return List.unmodifiable(_reflections.where((r) => r.userId == userId));
  }

  @override
  Future<void> saveReflection(Reflection reflection) async {
    _reflections.add(reflection);
  }

  @override
  Future<LifeTwinSnapshot> calculateLifeTwinSnapshot(String userId, {int? customAvailableMinutes}) async {
    final now = DateTime.now();
    final profile = _currentProfile ?? DemoSeedData.getProfile();
    final availableMins = customAvailableMinutes ?? profile.dailyAvailableMinutes;

    final userTasks = _tasks.where((t) => t.userId == userId).toList();
    final userGoals = _goals.where((g) => g.userId == userId).toList();
    final userCommitments = _commitments.where((c) => c.userId == userId).toList();

    // Workload calculation
    final openTasks = userTasks.where((t) => t.status.isOutstanding).toList();
    final totalWorkload = openTasks.fold<int>(0, (sum, t) => sum + t.estimatedMinutes);
    final capacityGap = totalWorkload - availableMins;

    // Overdue tasks
    final overdue = userTasks.where((t) => t.dueAt != null && t.dueAt!.isBefore(now) && t.status.isOutstanding).toList();

    // Critical upcoming tasks (due within 12 hours)
    final critical = userTasks.where((t) => t.dueAt != null && t.dueAt!.isAfter(now) && t.dueAt!.isBefore(now.add(const Duration(hours: 12))) && t.status.isOutstanding).toList();

    // Completed & Postponed today
    final completedCount = userTasks.where((t) => t.status == TaskStatus.completed).length;
    final postponedCount = userTasks.where((t) => t.status == TaskStatus.postponed).length;
    final completedMins = userTasks.where((t) => t.status == TaskStatus.completed).fold<int>(0, (sum, t) => sum + t.estimatedMinutes);

    // Distribution by life area
    final goalAreaMap = {for (final g in userGoals) g.id: g.lifeAreaId};
    final Map<String, int> areaMinutes = {};
    for (final task in openTasks) {
      if (task.goalId != null && goalAreaMap.containsKey(task.goalId)) {
        final areaId = goalAreaMap[task.goalId]!;
        areaMinutes[areaId] = (areaMinutes[areaId] ?? 0) + task.estimatedMinutes;
      }
    }

    // Neglected goals (high priority goals with 0 minutes planned)
    final neglected = userGoals.where((g) => g.priority >= 3 && g.status == 'Active' && !openTasks.any((t) => t.goalId == g.id)).toList();

    // Feasibility status
    final FeasibilityState feasibility;
    if (capacityGap > 0) {
      feasibility = FeasibilityState.infeasible;
    } else if (totalWorkload > availableMins * 0.9) {
      feasibility = FeasibilityState.strained;
    } else {
      feasibility = FeasibilityState.feasible;
    }

    // Plain English explanation (strictly distinguishing observed facts from estimates)
    final String summary;
    if (capacityGap > 0) {
      summary = 'Your open tasks require approximately $totalWorkload minutes, but your available planning time is $availableMins minutes. Your current plan has a $capacityGap-minute capacity gap.';
    } else {
      summary = 'Your open tasks require $totalWorkload minutes within your $availableMins-minute available window ($availableMins - $totalWorkload = ${availableMins - totalWorkload} minutes buffer).';
    }

    return LifeTwinSnapshot(
      totalEstimatedWorkloadMinutes: totalWorkload,
      availablePlanningMinutes: availableMins,
      capacityGapMinutes: capacityGap,
      feasibility: feasibility,
      overdueTasks: overdue,
      upcomingCriticalTasks: critical,
      plannedMinutesByLifeArea: areaMinutes,
      neglectedGoals: neglected,
      completedTodayMinutes: completedMins,
      completedTasksCount: completedCount,
      postponedTasksCount: postponedCount,
      commitmentsToday: userCommitments,
      plainEnglishSummary: summary,
      calculatedAt: now,
    );
  }

  @override
  Future<void> loadDemoDataset(String userId) async {
    _lifeAreas.clear();
    _goals.clear();
    _tasks.clear();
    _commitments.clear();
    _plans.clear();
    _scenarios.clear();
    _recoveryPlans.clear();
    _insights.clear();
    _experiments.clear();
    _reflections.clear();
    _loadInitialSeed();
  }
}
