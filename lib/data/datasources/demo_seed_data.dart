import '../../domain/models/profile.dart';
import '../../domain/models/life_area.dart';
import '../../domain/models/goal.dart';
import '../../domain/models/task.dart';
import '../../domain/models/fixed_commitment.dart';
import '../../domain/models/insight.dart';
import '../../domain/models/experiment.dart';
import '../../domain/enums/priority_level.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/enums/evidence_strength.dart';
import '../../domain/enums/experiment_status.dart';

class DemoSeedData {
  static const String demoUserId = 'd0000000-0000-0000-0000-000000000001';

  static Profile getProfile() {
    return Profile(
      id: demoUserId,
      displayName: 'Alex Rivera (CS Student)',
      timezone: 'Asia/Kolkata',
      dailyAvailableMinutes: 180, // Section 17: 180 minutes available
      planningPreferences: const {
        'preferredStrategy': 'PriorityFirst',
        'energyPeak': 'Morning',
        'allowSplitting': true,
      },
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  static List<LifeArea> getLifeAreas(String userId) {
    final now = DateTime.now();
    return [
      LifeArea(
        id: 'area_academics',
        userId: userId,
        name: 'Academics & Learning',
        description: 'Core university coursework and exam preparation',
        colorHex: '#3B82F6',
        priority: 4,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      LifeArea(
        id: 'area_career',
        userId: userId,
        name: 'Career & Placement',
        description: 'Technical interviews and placement readiness',
        colorHex: '#10B981',
        priority: 3,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      LifeArea(
        id: 'area_health',
        userId: userId,
        name: 'Fitness & Health',
        description: 'Cardio, strength, and physical well-being',
        colorHex: '#F59E0B',
        priority: 3,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      LifeArea(
        id: 'area_personal',
        userId: userId,
        name: 'Personal Development',
        description: 'Reading, habits, and mindset',
        colorHex: '#8B5CF6',
        priority: 2,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ];
  }

  static List<Goal> getGoals(String userId) {
    final now = DateTime.now();
    return [
      Goal(
        id: 'goal_dbms',
        userId: userId,
        lifeAreaId: 'area_academics',
        title: 'Score A+ in DBMS Coursework',
        description: 'Master query optimization and relational schema design',
        startDate: now.subtract(const Duration(days: 14)),
        targetDate: now.add(const Duration(days: 30)),
        priority: 4,
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now,
      ),
      Goal(
        id: 'goal_java',
        userId: userId,
        lifeAreaId: 'area_academics',
        title: 'Master OOP & Algorithms in Java',
        description: 'Complete daily LeetCode challenges in Java',
        startDate: now.subtract(const Duration(days: 10)),
        targetDate: now.add(const Duration(days: 45)),
        priority: 4,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      ),
      Goal(
        id: 'goal_placement',
        userId: userId,
        lifeAreaId: 'area_career',
        title: 'Campus Placement Readiness',
        description: 'Complete mock technical rounds and system design fundamentals',
        startDate: now.subtract(const Duration(days: 20)),
        targetDate: now.add(const Duration(days: 60)),
        priority: 3,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
      ),
      Goal(
        id: 'goal_fitness',
        userId: userId,
        lifeAreaId: 'area_health',
        title: 'Daily Calisthenics & Cardio',
        description: 'Maintain 30-min active routine',
        startDate: now.subtract(const Duration(days: 30)),
        targetDate: now.add(const Duration(days: 90)),
        priority: 3,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
      Goal(
        id: 'goal_reading',
        userId: userId,
        lifeAreaId: 'area_personal',
        title: 'Deep Work Habit',
        description: 'Read 20 pages daily',
        startDate: now.subtract(const Duration(days: 5)),
        targetDate: now.add(const Duration(days: 30)),
        priority: 2,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      ),
    ];
  }

  /// The Section 17 Demo Scenario:
  /// Total estimated workload = 60 + 45 + 45 + 30 + 20 = 200 minutes!
  /// Available capacity = 180 minutes!
  /// Capacity Gap = 20 minutes!
  static List<Task> getTasks(String userId) {
    final now = DateTime.now();
    return [
      Task(
        id: 'task_dbms_assign',
        userId: userId,
        goalId: 'goal_dbms',
        title: 'DBMS Assignment: SQL Query Optimization',
        description: 'Index tuning and execution plan analysis',
        estimatedMinutes: 60,
        priority: PriorityLevel.critical,
        dueAt: now.add(const Duration(hours: 4)),
        status: TaskStatus.pending,
        taskType: TaskType.deepWork,
        allowSplitting: true,
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: 'task_java_practice',
        userId: userId,
        goalId: 'goal_java',
        title: 'Java Practice: Concurrency & Streams',
        description: 'Complete 3 medium multi-threading problems',
        estimatedMinutes: 45,
        priority: PriorityLevel.critical,
        dueAt: now.add(const Duration(hours: 8)),
        status: TaskStatus.pending,
        taskType: TaskType.deepWork,
        allowSplitting: true,
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: 'task_placement_prep',
        userId: userId,
        goalId: 'goal_placement',
        title: 'Placement Prep: System Design Fundamentals',
        description: 'Review caching and load balancing concepts',
        estimatedMinutes: 45,
        priority: PriorityLevel.high,
        dueAt: now.add(const Duration(hours: 12)),
        status: TaskStatus.pending,
        taskType: TaskType.standard,
        allowSplitting: true,
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: 'task_exercise',
        userId: userId,
        goalId: 'goal_fitness',
        title: 'Exercise: HIIT & Core Workout',
        description: '30-minute interval training',
        estimatedMinutes: 30,
        priority: PriorityLevel.high,
        dueAt: now.add(const Duration(hours: 14)),
        status: TaskStatus.pending,
        taskType: TaskType.standard,
        allowSplitting: false,
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: 'task_reading',
        userId: userId,
        goalId: 'goal_reading',
        title: 'Personal Reading: Deep Work Ch. 3',
        description: 'Read about bimodal and rhythmic scheduling',
        estimatedMinutes: 20,
        priority: PriorityLevel.low,
        dueAt: now.add(const Duration(hours: 16)),
        status: TaskStatus.pending,
        taskType: TaskType.quickTask,
        allowSplitting: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  static List<FixedCommitment> getFixedCommitments(String userId) {
    final now = DateTime.now();
    return [
      FixedCommitment(
        id: 'comm_mentorship',
        userId: userId,
        title: 'Faculty Mentorship & Project Review',
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 3)),
        createdAt: now,
      ),
    ];
  }

  static List<Insight> getInsights(String userId) {
    final now = DateTime.now();
    return [
      Insight(
        id: 'insight_study_sessions',
        userId: userId,
        insightType: 'TASK_DURATION_SENSITIVITY',
        title: 'Shorter study sessions show 2.5x higher completion',
        description: 'Over the last two weeks, tasks <= 30 minutes had an 85% completion rate, while 60+ minute blocks suffered frequent postponements (34% completion rate).',
        evidenceData: const {
          'shortTaskCompletionRate': 0.85,
          'longTaskCompletionRate': 0.34,
          'postponementRatio': 2.5,
          'samples': 23,
        },
        sampleSize: 23,
        observationStart: now.subtract(const Duration(days: 14)),
        observationEnd: now,
        evidenceStrength: EvidenceStrength.moderate,
        suggestedHypothesis: 'Splitting heavy study blocks into 30-minute modules will raise completion rate to >= 75%.',
        suggestedAction: 'Cap future study tasks to 30 minutes with 5-minute buffer breaks.',
        status: 'Active',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<Experiment> getExperiments(String userId) {
    final now = DateTime.now();
    return [
      Experiment(
        id: 'exp_split_study',
        userId: userId,
        insightId: 'insight_study_sessions',
        hypothesis: 'Splitting heavy study blocks into 30-minute modules will raise completion rate to >= 75%',
        changeDescription: 'Cap study sessions at 30 minutes with 5-minute cognitive resets between units',
        metricDefinition: 'Completion Rate = (Tasks Completed on Scheduled Day) / (Total Tasks Scheduled)',
        baselinePeriodStart: now.subtract(const Duration(days: 14)),
        baselinePeriodEnd: now,
        experimentStart: now,
        experimentEnd: now.add(const Duration(days: 7)),
        status: ExperimentStatus.active,
        result: ExperimentResultData(
          metricName: 'Completion Rate',
          baselineValue: 0.54,
          resultValue: 0.78,
          sampleSize: 18,
          limitations: 'Measured over 18 logged tasks across 7 days. Correlation indicates strong positive trend, though external exam factors may influence results.',
          calculatedAt: now,
        ),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
