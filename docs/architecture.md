# LIFESYNC System Architecture

## 1. Architectural Philosophy

**LIFESYNC — Adaptive Personal Life Intelligence System** is engineered using a clean, feature-oriented layered architecture. Its primary objective is to help students and professionals coordinate competing life domains (academics, placement prep, fitness, relationships) through deterministic, transparent constraint satisfaction rather than opaque AI black boxes.

```
+-------------------------------------------------------------------------+
|                           PRESENTATION LAYER                            |
|  (Flutter Material 3, Riverpod ViewModels, GoRouter Navigation Shell)   |
|   - Dashboard        - Life Twin          - Adaptive Planner           |
|   - What-If Simulator - Comeback Mode     - Personal Growth Investigator|
+-------------------------------------------------------------------------+
                                   |
                                   v
+-------------------------------------------------------------------------+
|                            DOMAIN LAYER                                 |
|  (Entities, Value Objects, Pure Dart Deterministic Algorithms)          |
|   - PlanningEngine   (Greedy Heuristic + Local Search Swaps)           |
|   - ScoringEngine    (Multi-Objective J(P) Evaluation)                  |
|   - RecoveryEngine   (Task Splitting + Momentum Recovery Proposals)     |
|   - PatternDetector  (Empirical Minimum Sample Size Pattern Miner)      |
|   - ExperimentEvaluator (Falsifiable Hypothesis Delta Tracker)          |
+-------------------------------------------------------------------------+
                                   |
                                   v
+-------------------------------------------------------------------------+
|                             DATA LAYER                                  |
|  (Repository Pattern with Offline-First In-Memory & Cloud Supabase)     |
|   - InMemoryRepository (Zero-latency instant offline demonstration)     |
|   - SupabaseRepository (PostgreSQL + RLS security policies)            |
|   - DemoSeedData (Section 17 College Student Benchmark Scenario)        |
+-------------------------------------------------------------------------+
```

## 2. Directory Layout & Layer Responsibilities

- **`lib/core/`**:
  - `theme/`: Material 3 design system (slate navy palette `#0F172A`, teal accent `#0D9488`, mint `#2DD4BF`, rose `#F43F5E`).
  - `routing/`: GoRouter navigation with shell-based bottom navigation and contextual modals.
  - `config/`: Environment configuration and Supabase keys.
  - `errors/`: Domain failures and structured exception mapping.
- **`lib/domain/`**:
  - `models/`: Immutable domain models (`Task`, `Goal`, `LifeArea`, `PlanResult`, `Scenario`, `RecoveryPlan`, `Insight`, `Experiment`, `LifeTwinSnapshot`).
  - `enums/`: Typed domain enumerations (`PlanStrategy`, `PriorityLevel`, `TaskStatus`, `EvidenceStrength`).
  - `algorithms/`: Pure deterministic scheduling, multi-objective scoring, comeback mode recovery, and pattern mining engines. Completely decoupled from UI and persistence.
  - `repositories/`: Abstract repository contracts (`IAuthRepository`, `ILifeSyncRepository`).
- **`lib/data/`**:
  - `repositories/`: `InMemoryRepository` (provides complete offline functionality and zero-dependency testing) and `SupabaseRepository` (PostgreSQL remote sync).
  - `datasources/`: `DemoSeedData` containing the College Student 180m vs 200m scenario.
- **`lib/features/`**:
  - `dashboard/`: Life Overview, Capacity Balance, Today's Timeline, Comeback alerts.
  - `life_twin/`: Continuous mathematical model, capacity gaps, neglected goals, life area progress.
  - `planner/`: Adaptive daily planner with strategy switcher (Priority-First, Deadline-Sensitive, Balance-First, Recovery-First).
  - `simulator/`: What-If life simulator with side-by-side scenario comparison and atomic apply.
  - `comeback/`: Supportive nonjudgmental disruption recovery with automatic task splitting.
  - `investigator/`: Evidence-backed behavioral insights and falsifiable hypothesis trials.
  - `experiments/`: Experiment tracking, delta percentage calculations, and methodological disclosures.
  - `reflections/`: Daily calibration logging (wins, challenges, next step, perceived workload).
  - `settings/`: Profile configuration, capacity preferences, demo dataset reset, and data deletion.
- **`lib/shared/`**:
  - `widgets/`: Reusable widgets (`CapacityMeter`, `ScoreBreakdownCard`, `PriorityBadge`, `StatCard`).
  - `providers/`: Riverpod providers for dependency injection and state reactivity.

## 3. Four Core Capabilities & Shared Planning Engine

All four standout capabilities share the exact same domain data models and deterministic planning engine:

1. **Life Twin**: Continuously calculates total open workload against available minutes, detecting capacity gaps before planning failures occur.
2. **What-If Life Simulator**: Clones active plan state into isolated named scenarios, runs the planning engine with user perturbations, evaluates plans under the same $J(P)$ score, and applies changes atomically upon confirmation.
3. **Comeback Mode**: Triggers when plans are disrupted, splits heavy tasks into 30m focused modules, and runs the planning engine under a `Recovery-First` strategy.
4. **Personal Growth Investigator**: Analyzes real user logs to discover behavioral patterns (e.g. task duration vs postponement) and measures intervention outcomes.

## 4. Future AI Architecture Path

While Version 1 is 100% deterministic and operates without external AI dependencies, the architecture includes dedicated service boundaries for future LLM integration (e.g. natural language reflection summarization or goal breakdown). Any future AI suggestions must be validated by the deterministic `PlanningEngine` before presentation to the user.
