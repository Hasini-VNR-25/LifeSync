# LIFESYNC — Adaptive Personal Life Intelligence System

[![Verification Suite](https://img.shields.io/badge/Algorithms-100%25%20Verified-teal)](lifesync/scripts/run_algorithm_verification.js)
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Supabase%20RLS-orange)](supabase/migrations/20261024000001_lifesync_schema.sql)

> **"Plan for real life. Adapt when it changes. Learn what works for you."**

LIFESYNC is a full-featured, production-minded personal life intelligence application built from scratch for students and young professionals. Instead of acting as an ordinary task list, LIFESYNC unifies **Life Twin modeling**, **What-If simulation**, **Comeback Mode recovery**, and **Personal Growth empirical investigation** around a shared deterministic scheduling and scoring engine.

---

## 1. Primary Differentiator & Capabilities

```
+-----------------------------------------------------------------------------------+
|                                     LIFESYNC                                      |
+---------------------+---------------------+------------------+--------------------+
|     LIFE TWIN       |  WHAT-IF SIMULATOR  |  COMEBACK MODE   | GROWTH INVESTIGATOR|
|  - 200m workload vs |  - Compare side-by- |  - Supportive,   |  - Empirical log   |
|    180m capacity    |    side candidate   |    nonjudgmental |    pattern mining  |
|  - Transparent gap  |    scenarios        |  - Splits heavy  |  - N >= 5 sample   |
|    explanations     |  - Multi-objective  |    tasks (30m)   |    thresholds      |
|  - Life area balance|    J(P) scoring     |  - Dual recovery |  - Falsifiable     |
|  - Neglected goals  |  - Atomic apply     |    proposals     |    experiments     |
+---------------------+---------------------+------------------+--------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|                          SHARED PLANNING & SCORING ENGINE                         |
|   - Deterministic Greedy Scheduler + Local Search Swaps                           |
|   - Hard Constraints: No task overlaps, no commitment clash, positive duration    |
|   - Unified Multi-Objective Scoring: J(P) = wd*D + wg*G + wf*F - wo*O - wc*C     |
+-----------------------------------------------------------------------------------+
```

---

## 2. Technology Stack

- **Mobile Application**: Flutter, Dart, Material 3, Riverpod (State Management & DI), GoRouter (Navigation), Google Fonts, Intl, fl_chart.
- **Backend & Database**: PostgreSQL through Supabase, UUID PKs, strict CHECK constraints, Row Level Security (RLS) on all user-owned tables.
- **Architecture**: Feature-oriented layered architecture (Presentation, Application Logic, Domain Algorithms, Data Repositories).
- **Execution & Testing**: Runs 100% offline and locally out of the box with zero external dependencies; includes automated Node.js algorithm verification suite and Flutter unit/widget tests.

---

## 3. Directory Layout

```
lifesync/
├── lib/
│   ├── main.dart                          # Application entry point & ProviderScope
│   ├── app.dart                           # MaterialApp with Material 3 theming
│   ├── core/
│   │   ├── routing/app_router.dart        # GoRouter shell & modal navigation
│   │   ├── theme/                         # Slate navy, teal, mint & typography
│   │   └── utils/                         # Date helpers and formatters
│   ├── domain/
│   │   ├── algorithms/
│   │   │   ├── planning_engine.dart       # Deterministic greedy + local search scheduler
│   │   │   ├── scoring_engine.dart        # Multi-objective heuristic formula J(P)
│   │   │   ├── recovery_engine.dart       # Comeback Mode task-splitter & recovery
│   │   │   ├── pattern_detector.dart      # Empirical log pattern miner (sample sizes)
│   │   │   └── experiment_evaluator.dart  # Baseline vs trial outcome measurement
│   │   ├── models/                        # Immutable domain entities
│   │   └── enums/                         # Typed enums (PlanStrategy, TaskStatus, etc.)
│   ├── data/
│   │   ├── datasources/demo_seed_data.dart # Section 17 Student Demo Benchmark (180m vs 200m)
│   │   └── repositories/
│   │       ├── in_memory_repository.dart  # Instant offline interactive repository
│   │       └── supabase_repository.dart   # PostgreSQL cloud sync with RLS
│   ├── features/                          # Feature presentation modules
│   │   ├── dashboard/                     # Life Overview, Capacity Balance, Urgent tasks
│   │   ├── life_twin/                     # Continuous mathematical model & gap alerts
│   │   ├── planner/                       # Heuristic planner (4 strategies, J(P) score)
│   │   ├── simulator/                     # What-If simulator (side-by-side trade-offs)
│   │   ├── comeback/                      # Supportive recovery workflow & approval
│   │   ├── investigator/                  # Behavioral insights & active trials
│   │   ├── experiments/                   # Experiment evaluation & delta calculation
│   │   ├── goals/                         # Goal management & life area grouping
│   │   ├── tasks/                         # Task backlog, completion & postponement
│   │   ├── reflections/                   # Daily calibration (wins, friction, workload)
│   │   └── settings/                      # Preferences, demo reset, data deletion
│   └── shared/                            # CapacityMeter, ScoreBreakdownCard, StatCard
├── test/
│   ├── unit/                              # Planning, scoring, recovery & pattern tests
│   └── widget/                            # Dashboard & UI widget tests
├── scripts/
│   └── run_algorithm_verification.js      # Zero-dependency terminal verification runner
├── supabase/
│   ├── migrations/                        # PostgreSQL schema, indexes & RLS policies
│   └── seed.sql                           # Student benchmark seed SQL
└── docs/                                  # Comprehensive architectural documentation
    ├── architecture.md
    ├── database.md
    ├── algorithms.md
    ├── testing.md
    └── user_guide.md
```

---

## 4. Quick Start & Execution

### Option A: Launch Interactive Web Application (Instant, Zero External Dependencies)
LIFESYNC includes an interactive application powered by the same deterministic domain algorithms, REST API, and Material 3 design system:
```powershell
cd lifesync
node web_app/server.js
```
Then open `http://localhost:3000` in your web browser, or double-click `start_lifesync.bat`.

### Option B: Run Automated Verification Suites (Terminal)
Verify all 6 core algorithm test suites and end-to-end integration workflows:
```powershell
node lifesync/scripts/run_algorithm_verification.js
node lifesync/test/integration/api_integration_test.js
```

### Option C: Run Flutter Mobile Application
When the Flutter SDK is installed in your PATH:
```powershell
cd lifesync
flutter pub get
flutter test
flutter run
```

---

## 5. Demonstration Walkthrough (Section 17 College Student Benchmark)

1. **Launch App**: Opens instantly with Alex Rivera's CS Student scenario preloaded.
2. **Life Twin Overview**: Observe the **Daily Capacity Balance Meter** showing 200m workload against 180m available capacity (`+20m Capacity Gap`).
3. **What-If Life Simulator**: Tap **Simulate** to compare the baseline (180m, Personal Reading unscheduled) against **Scenario B** (slider expanded to 210m, scheduling all work with 10m buffer).
4. **Apply Scenario**: Tap **Apply Scenario** to commit the plan atomically to your active schedule.
5. **Comeback Mode**: Tap **Enter Comeback Mode** when disrupted. The 60m DBMS assignment is automatically split into 30m Part 1 & Part 2. Compare dual proposals and tap **Approve Recovery Plan**.
6. **Growth Investigator**: Open **Insights** to review empirical pattern detection ($N=23$ logs showing 2.5x higher completion for tasks $\le 30$ mins) and review the active 30m study experiment outcome (+24% gain).

---

## 6. Supabase Cloud Configuration (Optional)

To connect to your own Supabase project:
1. Create a Supabase project at [supabase.com](https://supabase.com).
2. Execute the migration file in Supabase SQL Editor:
   `supabase/migrations/20261024000001_lifesync_schema.sql`
3. Execute the seed script:
   `supabase/seed.sql`
4. Copy `.env.example` to `.env` and fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

---

## 7. Known Limitations & Roadmap

- **Version 1 Scope**: Completely deterministic, zero external AI calls, zero privacy leaks.
- **Future Roadmap**:
  - Optional local offline LLM integration for natural language reflection synthesis.
  - Native calendar bi-directional sync (Google Calendar / Apple Calendar).
  - Background audio timers with gentle chimes for focused 30-minute study sprints.
