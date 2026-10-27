# LIFESYNC Scheduling & Heuristic Algorithms

## 1. The Multi-Objective Scoring Model

LIFESYNC evaluates plan quality using a documented, deterministic multi-objective heuristic function:

$$J(P) = w_d \cdot D(P) + w_g \cdot G(P) + w_f \cdot F(P) - w_o \cdot O(P) - w_c \cdot C(P)$$

### Component Definitions & Normalization

All components are normalized onto a 0–100 scale:

1. **Deadline Satisfaction $D(P)$ (Weight $w_d = 0.35$):**
   Evaluates whether scheduled tasks finish on or before their deadlines.
   $$D(P) = \frac{1}{|T_{\text{deadline}}|} \sum_{t \in T_{\text{deadline}}} \text{Score}(t)$$
   Tasks completing with generous buffer (> 120 mins) score 100. Tighter margins scale down linearly to 70. Tasks completing after their deadline score 0.

2. **Goal & Life Area Coverage $G(P)$ (Weight $w_g = 0.25$):**
   Measures representation of active goals across life areas in the generated plan:
   $$G(P) = \min\left(100, \frac{|G_{\text{scheduled}}|}{|G_{\text{active}}|} \times 100\right)$$

3. **Schedule Fit $F(P)$ (Weight $w_f = 0.25$):**
   Rewards scheduling work that utilizes available capacity without extreme fragmentation or overflow:
   $$F(P) = \begin{cases} \frac{M_{\text{scheduled}}}{M_{\text{available}}} \times 100 & \text{if } M_{\text{scheduled}} \le M_{\text{available}} \\ \max\left(0, 100 - \left(\frac{M_{\text{scheduled}}}{M_{\text{available}}} - 1\right) \times 200\right) & \text{if } M_{\text{scheduled}} > M_{\text{available}} \end{cases}$$

4. **Overload Penalty $O(P)$ (Weight $w_o = 0.15$):**
   Penalizes scheduling work that exceeds the user's defined daily capacity:
   $$O(P) = \min\left(100, \frac{\max(0, M_{\text{scheduled}} - M_{\text{available}})}{M_{\text{available}}} \times 100\right)$$

5. **Conflict Buffer Penalty $C(P)$ (Weight $w_c = 0.10$):**
   Penalizes tasks that abut fixed commitments without a safety buffer (< 5 minutes).

### Overall Score Normalization
The resulting total score is bounded:
$$J(P) \in [0, 100]$$

---

## 2. Hard Constraints vs. Soft Penalties

A fundamental rule in LIFESYNC is that **a high score never excuses an invalid plan**. Hard constraints are evaluated prior to and during slot allocation:

| Constraint | Category | Enforcement Mechanism |
| :--- | :--- | :--- |
| **Duration Positivity** | Hard | Rejects tasks where $\text{duration} \le 0$ |
| **No Overlapping Tasks** | Hard | Sequential placement check ($S_j \ge E_i$) |
| **No Commitment Clashes** | Hard | Jumps past fixed commitment end times |
| **Completed Task Exclusion** | Hard | Filters out tasks where status is `Completed` |
| **Available Window Bounds** | Hard | Restricts start and end times to planning window |
| **Deadline Slack** | Soft Warning | Evaluates $E_i \le \text{DueAt}$; flags risks if tight |
| **Life Area Balance** | Soft Score | Encourages diversity via $G(P)$ weighting |

---

## 3. Candidate Plan Strategies

The engine supports four deterministic strategies:

1. **`PriorityFirst`**:
   Ranks tasks by composite priority score:
   $$\text{RankScore}(t) = \text{Priority}(t) \times 10 + \text{Priority}(\text{Goal}(t))$$
   Ties broken deterministically by (Earliest Deadline, Shortest Duration, Task UUID).

2. **`DeadlineSensitive`**:
   Implements Earliest-Deadline-First (EDF). Tasks with explicit deadlines are sorted ascending by due date. Tasks without deadlines are placed afterward sorted by priority.

3. **`BalanceFirst`**:
   Groups candidate tasks into life area buckets and round-robins across all active buckets to ensure no high-priority domain is neglected.

4. **`RecoveryFirst`**:
   Used by Comeback Mode. Prioritizes quick wins ($\le 30$ mins) to build psychological momentum and locks in immediate deadlines, deferring optional long tasks.

---

## 4. Local Search Improvement Step

After initial greedy slot allocation, the engine executes an improvement pass:
1. Iterates through adjacent task pairs $(T_i, T_{i+1})$.
2. If swapping $T_i$ and $T_{i+1}$ satisfies all hard constraints (no commitment overlap, within window), computes candidate score $J(P')$.
3. If $J(P') > J(P)$, accepts the swap.
4. Stops when no adjacent swap produces a score improvement.

---

## 5. Comeback Mode Recovery Engine

When disruption occurs (e.g. overdue task count $\ge 2$ or available time reduced):
1. **Identifies Heavy Tasks**: Any task with $\text{estimatedMinutes} > 45$ and `allowSplitting = true` is divided into two 30-minute modules (`Part 1 - Core Focus` and `Part 2 - Completion`).
2. **Generates Dual Proposals**:
   - **Proposal 1 ("Protect Deadlines")**: Merges split modules with urgent tasks under `RecoveryFirst` strategy.
   - **Proposal 2 ("Gentle Momentum Reset")**: Schedules strictly bite-sized tasks ($\le 30$m) to rebuild momentum.
3. **Explains Trade-offs**: Employs nonjudgmental language without guilt.

---

## 6. Personal Growth Investigator Pattern Detector

Deterministic pattern mining based on empirical log records:

- **Minimum Sample Size Enforcement**:
  Every pattern requires a minimum sample size ($N \ge 5$ or $N \ge 15$). If observations are fewer than $N_{\text{min}}$, the system explicitly outputs:
  `"Insufficient sample size (N=X/Y). LIFESYNC requires at least Y logged actions before reporting trends."`
- **Correlation vs. Causation Disclosure**:
  Every insight explicitly states that observed differences are statistical associations in user data, not biological or psychological proof of causation.
- **Falsifiable Hypotheses**:
  Insights generate structured, measurable experiment definitions that evaluate baseline completion rates against trial completion rates.
