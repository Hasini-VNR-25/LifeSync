# LIFESYNC User Guide & Walkthrough

## 1. Product Promise

> "Plan for real life. Adapt when it changes. Learn what works for you."

LIFESYNC is built to help students and busy professionals coordinate competing life domains without unrealistic scheduling, accumulated guilt, or black-box predictions.

---

## 2. Interactive Walkthrough: College Student Demo Scenario

LIFESYNC includes a preloaded college student benchmark scenario (Alex Rivera, CS Student):
- **Available Capacity**: 180 minutes (3.0 hours)
- **Active Tasks**:
  1. DBMS Assignment: SQL Query Optimization — 60m, Critical Priority
  2. Java Practice: Concurrency & Streams — 45m, Critical Priority
  3. Placement Prep: System Design Mock — 45m, High Priority
  4. Exercise: HIIT & Core Strength — 30m, High Priority
  5. Personal Reading: Deep Work Ch. 3 — 20m, Low Priority
- **Total Workload**: $60 + 45 + 45 + 30 + 20 = 200\text{ minutes}$
- **Fixed Commitment**: Faculty Mentorship Lab (1-hour block)

Follow this 8-step journey through the application:

### Step 1: Life Twin Identifies Capacity Mismatch
- Open the **Home Dashboard** or navigate to **Life Twin** (top right icon).
- Observe the **Daily Capacity Balance Meter**:
  - Workload: 200m
  - Available: 180m
  - Overflow: `+20m Capacity Gap`
- Notice the transparent explanation card:
  *"Your open tasks require approximately 200 minutes, but your available planning time is 180 minutes. Your current plan has a 20-minute capacity gap."*

### Step 2: Compare Alternatives in What-If Simulator
- Tap **Open What-If Simulator** (or choose the **Simulate** tab in the bottom bar).
- Notice the **Side-by-Side Comparison**:
  - **Baseline Plan**: Schedules 180 minutes across 4 high-priority tasks; leaves Personal Reading (20m) unscheduled due to the hard capacity limit. Quality Score: 85 pts.
  - **Scenario Exploration**:
    - Move the **Hypothetical Available Time** slider to 210 minutes, OR
    - Uncheck the low-priority Personal Reading task.
  - Observe how Scenario B updates in real-time, showing 0 unscheduled tasks and protected critical deadlines.

### Step 3: Apply the Feasible Plan
- Tap **Apply Scenario** to commit the simulated plan atomically to your active schedule.
- Return to the **Dashboard**; the active schedule now reflects your chosen trade-off.

### Step 4: Disruption Triggers Comeback Mode
- When an unexpected disruption occurs (such as an extended faculty lab or missed tasks), tap **Enter Comeback Mode** on the home screen banner.
- LIFESYNC greets you with supportive, nonjudgmental language:
  *"Your original plan no longer fits the time available. Let's protect your nearest deadline and rebuild a manageable plan."*

### Step 5: Review & Approve Recovery Plan
- Comeback Mode automatically splits the heavy 60-minute DBMS assignment into two manageable 30-minute modules (`Part 1 - Core Focus` and `Part 2 - Completion`).
- Compare the two recovery proposals:
  - **Proposal 1: Protect Deadlines & Split Heavy Workload**
  - **Proposal 2: Gentle Momentum Reset**
- Tap **Approve Recovery Plan** to update your schedule without guilt.

### Step 6: Empirical Pattern Detection in Growth Investigator
- Navigate to the **Insights** tab.
- Observe the empirical pattern detected from recorded task logs:
  - **Title**: *"Shorter study sessions show 2.5x higher completion in your logs"*
  - **Evidence**: Over the last 14 days, tasks $\le 30$ mins had an 85% completion rate, while 60+ minute blocks suffered frequent postponements (34% completion rate).
  - **Sample Size**: $N = 23$ recorded actions.
  - **Evidence Strength**: Moderate.

### Step 7: Launch a Planning Experiment
- Tap on the active trial: *"Splitting heavy study blocks into 30-minute modules will raise completion rate to $\ge 75\%$"*.
- Review the trial parameters:
  - Baseline rate: 54%
  - Trial measurement period: 7 days
  - Metric: Completion Rate $= \frac{\text{Completed Tasks}}{\text{Scheduled Tasks}}$

### Step 8: Review Experimental Outcomes & Adopt
- View the measured outcome: **78% completion rate (+24% gain)** across $N=18$ samples.
- Read the explicit methodological limitations:
  *"Measured over 18 logged tasks across 7 days. Correlation indicates strong positive trend, though external exam factors may influence results."*
- Tap **Adopt Intervention Permanently** to lock this insight into your planning habits.

---

## 3. Managing Data, Settings & Demonstrations

- **Reload Demo Scenario**: Head to **Profile -> System Settings** and tap **Reset Demo Scenario** anytime to reload the clean benchmark scenario.
- **Account Deletion**: Under **Data Ownership & Privacy**, tap **Delete Account & Clear All Data** with a confirmation dialog to wipe all stored records.
