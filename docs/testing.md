# LIFESYNC Verification & Testing Guide

## 1. Testing Strategy

LIFESYNC uses a layered verification strategy to ensure deterministic behavior, hard constraint integrity, and UX reliability:

1. **Deterministic Unit Tests**: Verifies scheduling constraints, multi-objective score calculations, task splitting, and sample-size thresholds.
2. **Widget Tests**: Verifies presentation layer rendering, capacity meters, empty states, and navigation.
3. **Standalone Verification Runner**: An interactive Node.js test runner (`scripts/run_algorithm_verification.js`) that verifies the exact mathematical algorithms directly in the terminal without requiring external SDK installations.

---

## 2. Running Automated Tests

### A. Run Algorithm Verification Suite (Zero-Dependency Node.js Runner)
```powershell
node lifesync/scripts/run_algorithm_verification.js
```

**Verification Results:**
```
================================================================
  LIFESYNC ALGORITHM & HEURISTIC ENGINE VERIFICATION SUITE
================================================================

TEST 1: Verifying Life Twin Capacity Mismatch (180m available vs 200m tasks)...
  -> Workload: 200m | Available: 180m | Gap: +20m overflow [PASS]

TEST 2: Verifying Deterministic Planning Engine Placement...
  -> Scheduled: 180m across 4 tasks [PASS]
  -> Unscheduled: Task "Personal Reading" (Insufficient remaining capacity: Needs 20m, but only 0m available.) [PASS]
  -> Quality Score J(P): 85/100 [PASS]

TEST 3: Verifying Hard Constraint Assertion (Fixed Commitments & Invalid Inputs)...
  -> Fixed Commitment respected: No task overlaps with Faculty Mentorship Lab [PASS]
  -> Non-positive duration rejected: "Task "Zero min task" rejected: Duration must be strictly positive." [PASS]
  -> Completed task excluded from outstanding schedule [PASS]

TEST 4: Verifying What-If Simulator Alternative Plan Comparison...
  -> Baseline: 180m scheduled, 1 unscheduled | Score: 85
  -> Scenario B: 200m scheduled, 0 unscheduled | Score: 83.8
  -> Comparison verified without mutating baseline [PASS]

TEST 5: Verifying Comeback Mode Task Splitting...
  -> Heavy task "DBMS Assignment" split into 30m Part 1 & 30m Part 2 [PASS]
  -> Recovery plan generated with supportive momentum [PASS]

TEST 6: Verifying Personal Growth Investigator Pattern Detection...
  -> Insufficient sample size (N=2/5) reported transparently without hallucinating [PASS]
  -> Empirical insight detected: "Shorter study sessions show 5.0x higher completion" [PASS]
  -> Actionable experiment formulated: "Splitting heavy study blocks into 30m modules will raise completion rate to >= 75%" [PASS]

================================================================
  ALL 6 VERIFICATION TEST SUITES PASSED WITH 100% SUCCESS!
================================================================
```

### B. Run Flutter & Dart Tests (When Flutter SDK is installed)
```powershell
cd lifesync
flutter test
```

---

## 3. Test Coverage Matrix

| Test Suite | File Path | Focus Area |
| :--- | :--- | :--- |
| **Planning Engine** | `test/unit/planning_engine_test.dart` | Hard constraints (overlap, commitments, capacity, duration, completed tasks) |
| **Scoring Model** | `test/unit/scoring_engine_test.dart` | Multi-objective scoring $J(P)$, penalty scaling |
| **Comeback Mode** | `test/unit/recovery_engine_test.dart` | Disruption triggers, task splitting into 30m units, dual recovery proposals |
| **Growth Investigator** | `test/unit/pattern_detector_test.dart` | Sample size enforcement ($N < 5$), duration sensitivity mining |
| **Home Dashboard** | `test/widget/home_dashboard_test.dart` | Life Twin rendering, Capacity Meter, tasks list, bottom navigation |
