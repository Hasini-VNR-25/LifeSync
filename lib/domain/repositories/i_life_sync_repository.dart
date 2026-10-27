import '../models/life_area.dart';
import '../models/goal.dart';
import '../models/task.dart';
import '../models/fixed_commitment.dart';
import '../models/plan.dart';
import '../models/scenario.dart';
import '../models/recovery_plan.dart';
import '../models/insight.dart';
import '../models/experiment.dart';
import '../models/reflection.dart';
import '../models/life_twin_snapshot.dart';
import '../enums/task_status.dart';

abstract class ILifeSyncRepository {
  // Life Areas
  Future<List<LifeArea>> getLifeAreas(String userId);
  Future<void> saveLifeArea(LifeArea area);
  Future<void> deleteLifeArea(String areaId);

  // Goals
  Future<List<Goal>> getGoals(String userId);
  Future<void> saveGoal(Goal goal);
  Future<void> deleteGoal(String goalId);

  // Tasks
  Future<List<Task>> getTasks(String userId);
  Future<void> saveTask(Task task);
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus, {int? actualMinutes});
  Future<void> deleteTask(String taskId);

  // Commitments
  Future<List<FixedCommitment>> getFixedCommitments(String userId);
  Future<void> saveFixedCommitment(FixedCommitment commitment);
  Future<void> deleteFixedCommitment(String commitmentId);

  // Plans & Scheduling
  Future<PlanResult?> getActivePlan(String userId);
  Future<void> savePlan(PlanResult plan);

  // Scenarios (What-If Simulator)
  Future<List<Scenario>> getScenarios(String userId);
  Future<void> saveScenario(Scenario scenario);
  Future<void> applyScenario(String scenarioId, PlanResult plan);

  // Comeback Recovery
  Future<List<RecoveryPlan>> getRecoveryPlans(String userId);
  Future<void> saveRecoveryPlan(RecoveryPlan plan);
  Future<void> applyRecoveryProposal(RecoveryPlan recoveryPlan, RecoveryProposal proposal);

  // Insights & Patterns
  Future<List<Insight>> getInsights(String userId);
  Future<void> saveInsight(Insight insight);

  // Experiments
  Future<List<Experiment>> getExperiments(String userId);
  Future<void> saveExperiment(Experiment experiment);
  Future<void> updateExperiment(Experiment experiment);

  // Reflections
  Future<List<Reflection>> getReflections(String userId);
  Future<void> saveReflection(Reflection reflection);

  // Life Twin
  Future<LifeTwinSnapshot> calculateLifeTwinSnapshot(String userId, {int? customAvailableMinutes});

  // Demo Dataset
  Future<void> loadDemoDataset(String userId);
}
