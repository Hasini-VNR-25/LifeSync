/**
 * LIFESYNC — Interactive Web Client Controller
 */

let state = {
  profile: null,
  tasks: [],
  goals: [],
  twin: null,
  activeTab: 'dashboard',
  simulatedMinutes: 210,
  excludedTaskIds: new Set(),
  currentRecovery: null,
  selectedRecoveryProposalIndex: 0
};

// --- INITIALIZATION ---
document.addEventListener('DOMContentLoaded', () => {
  initApp();
  setupEventListeners();
});

async function initApp() {
  await fetchProfile();
  await fetchLifeTwin();
  await fetchTasks();
  await fetchGoals();
  await fetchInsights();
  await fetchExperiments();
}

function setupEventListeners() {
  // Tab switching
  document.querySelectorAll('.nav-item').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const tabName = btn.querySelector('span').textContent.toLowerCase();
      const tabMap = {
        'home': 'dashboard',
        'plan': 'planner',
        'simulate': 'simulator',
        'comeback': 'comeback',
        'insights': 'insights',
        'profile': 'profile'
      };
      switchTab(tabMap[tabName] || 'dashboard');
    });
  });

  // Reset Demo Scenario button
  document.getElementById('resetDemoBtn').addEventListener('click', async () => {
    const res = await fetch('/api/demo/reset', { method: 'POST' });
    const data = await res.json();
    alert('Benchmark College Student scenario reloaded (180m available vs 200m tasks).');
    await initApp();
    switchTab('dashboard');
  });

  // Planner Generate Button
  document.getElementById('generatePlanBtn').addEventListener('click', generatePlan);

  // Simulator Time Slider & Run
  const simSlider = document.getElementById('simTimeSlider');
  simSlider.addEventListener('input', (e) => {
    state.simulatedMinutes = parseInt(e.target.value);
    document.getElementById('simTimeLabel').textContent = `${state.simulatedMinutes} mins (${(state.simulatedMinutes/60).toFixed(1)}h)`;
  });

  document.getElementById('runSimBtn').addEventListener('click', runSimulation);

  // Save Reflection
  document.getElementById('saveReflectionBtn').addEventListener('click', saveReflection);

  // Save Capacity
  document.getElementById('saveCapacityBtn').addEventListener('click', saveDailyCapacity);
}

// --- TAB ROUTING ---
function switchTab(tabId) {
  state.activeTab = tabId;
  document.querySelectorAll('.tab-view').forEach(v => v.classList.remove('active'));
  const targetView = document.getElementById(`view-${tabId}`);
  if (targetView) targetView.classList.add('active');

  // Update Bottom Nav active indicator
  const navIndices = { 'dashboard': 0, 'planner': 1, 'simulator': 2, 'comeback': 3, 'insights': 4, 'profile': 5 };
  document.querySelectorAll('.bottom-nav .nav-item').forEach((item, idx) => {
    item.classList.toggle('active', idx === navIndices[tabId]);
  });

  // Contextual initializations
  if (tabId === 'simulator') {
    populateSimTaskCheckboxes();
    runSimulation();
  } else if (tabId === 'comeback') {
    loadComebackWorkflow();
  }
}

// --- DATA FETCHING & RENDERING ---

async function fetchProfile() {
  const res = await fetch('/api/profile');
  state.profile = await res.json();
  document.getElementById('userDisplayName').textContent = state.profile.displayName.split(' ')[0];
  document.getElementById('profileName').textContent = state.profile.displayName;
  document.getElementById('inputDailyMinutes').value = state.profile.dailyAvailableMinutes;
}

async function fetchLifeTwin() {
  const res = await fetch('/api/life-twin');
  state.twin = await res.json();

  const total = state.twin.totalEstimatedWorkloadMinutes;
  const avail = state.twin.availablePlanningMinutes;
  const gap = state.twin.capacityGapMinutes;
  const hasOverflow = gap > 0;

  // Render Capacity Meter
  const badge = document.getElementById('capacityBadge');
  badge.textContent = hasOverflow ? `+${gap}m Overflow` : `${avail - total}m Buffer`;
  badge.className = `badge ${hasOverflow ? 'badge-rose' : 'badge-teal'}`;

  const bar = document.getElementById('capacityProgressBar');
  const percent = Math.min(100, (total / avail) * 100);
  bar.style.width = `${percent}%`;
  bar.className = `progress-bar ${hasOverflow ? 'progress-rose' : 'progress-teal'}`;

  document.getElementById('workloadLabel').textContent = `Workload: ${total}m (${(total/60).toFixed(1)}h)`;
  document.getElementById('availableLabel').textContent = `Available: ${avail}m (${(avail/60).toFixed(1)}h)`;
  document.getElementById('twinExplanationText').textContent = state.twin.plainEnglishSummary;

  // Show Comeback Mode Alert if overflow exists
  const banner = document.getElementById('comebackBanner');
  if (hasOverflow) {
    banner.style.display = 'flex';
    document.getElementById('comebackBannerText').textContent = `Your open tasks (${total}m) exceed available capacity (${avail}m) by ${gap} minutes. Let's recover gracefully.`;
  } else {
    banner.style.display = 'none';
  }
}

async function fetchTasks() {
  const res = await fetch('/api/tasks');
  state.tasks = await res.json();
  renderTasksList();
}

function renderTasksList() {
  const container = document.getElementById('tasksList');
  container.innerHTML = '';

  const completedCount = state.tasks.filter(t => t.status === 'Completed').length;
  document.getElementById('completedCountStat').textContent = `${completedCount} tasks`;

  state.tasks.forEach(task => {
    const isDone = task.status === 'Completed';
    const div = document.createElement('div');
    div.className = 'task-item';
    div.innerHTML = `
      <div class="task-left">
        <input type="checkbox" ${isDone ? 'checked' : ''} onchange="toggleTaskStatus('${task.id}', this.checked)">
        <div class="task-info">
          <h4 style="${isDone ? 'text-decoration: line-through; opacity: 0.6;' : ''}">${task.title}</h4>
          <p>${task.estimatedMinutes} mins • ${task.taskType} • Priority ${task.priority}</p>
        </div>
      </div>
      <span class="badge ${task.priority >= 4 ? 'badge-rose' : (task.priority === 3 ? 'badge-amber' : 'badge-teal')}">P${task.priority}</span>
    `;
    container.appendChild(div);
  });
}

async function toggleTaskStatus(taskId, isCompleted) {
  await fetch(`/api/tasks/${taskId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status: isCompleted ? 'Completed' : 'Pending' })
  });
  await fetchLifeTwin();
  await fetchTasks();
}

async function fetchGoals() {
  const res = await fetch('/api/goals');
  state.goals = await res.json();
}

// --- ADAPTIVE PLANNER ---

async function generatePlan() {
  const strategy = document.querySelector('input[name="planStrategy"]:checked').value;
  const res = await fetch('/api/plan/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ strategy })
  });
  const plan = await res.json();

  document.getElementById('planResultContainer').style.display = 'block';
  document.getElementById('overallScoreBadge').textContent = `${plan.overallScore}/100`;

  document.getElementById('scoreD').textContent = plan.scoreBreakdown.deadlineScore.toFixed(0);
  document.getElementById('scoreG').textContent = plan.scoreBreakdown.goalCoverageScore.toFixed(0);
  document.getElementById('scoreF').textContent = plan.scoreBreakdown.slotFitScore.toFixed(0);
  document.getElementById('scoreO').textContent = plan.scoreBreakdown.overloadPenalty.toFixed(0);
  document.getElementById('scoreC').textContent = plan.scoreBreakdown.conflictPenalty.toFixed(0);

  // Scheduled Timeline
  const timeline = document.getElementById('scheduledTimeline');
  timeline.innerHTML = '';
  plan.scheduledItems.forEach(item => {
    const div = document.createElement('div');
    div.className = 'task-item';
    div.innerHTML = `
      <div class="task-info">
        <h4>${item.task ? item.task.title : item.taskId}</h4>
        <p>Duration: ${item.durationMinutes} mins | Start: +${Math.round((item.scheduledStart - Date.now())/60000)}m</p>
      </div>
      <span class="badge badge-teal">Scheduled</span>
    `;
    timeline.appendChild(div);
  });

  // Unscheduled section
  const unschedSec = document.getElementById('unscheduledSection');
  const unschedList = document.getElementById('unscheduledList');
  if (plan.unscheduledItems.length > 0) {
    unschedSec.style.display = 'block';
    unschedList.innerHTML = '';
    plan.unscheduledItems.forEach(u => {
      const div = document.createElement('div');
      div.className = 'task-item';
      div.style.borderColor = 'rgba(244, 63, 94, 0.4)';
      div.innerHTML = `
        <div class="task-info">
          <h4 class="text-rose">${u.task ? u.task.title : u.taskId}</h4>
          <p class="text-sm">${u.reason}</p>
        </div>
        <span class="badge badge-rose">Excluded</span>
      `;
      unschedList.appendChild(div);
    });
  } else {
    unschedSec.style.display = 'none';
  }
}

// --- WHAT-IF SIMULATOR ---

function populateSimTaskCheckboxes() {
  const container = document.getElementById('simTaskCheckboxes');
  container.innerHTML = '';
  state.tasks.forEach(task => {
    const isExcluded = state.excludedTaskIds.has(task.id);
    const label = document.createElement('label');
    label.className = 'radio-card';
    label.style.display = 'flex';
    label.style.alignItems = 'center';
    label.innerHTML = `
      <input type="checkbox" ${!isExcluded ? 'checked' : ''} onchange="toggleSimTask('${task.id}', this.checked)">
      <div style="margin-left: 8px;">
        <strong>${task.title}</strong>
        <p class="caption text-muted">${task.estimatedMinutes}m • Priority ${task.priority}</p>
      </div>
    `;
    container.appendChild(label);
  });
}

function toggleSimTask(taskId, included) {
  if (included) {
    state.excludedTaskIds.delete(taskId);
  } else {
    state.excludedTaskIds.add(taskId);
  }
  runSimulation();
}

async function runSimulation() {
  const res = await fetch('/api/simulator/compare', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      simulatedMinutes: state.simulatedMinutes,
      excludedTaskIds: Array.from(state.excludedTaskIds)
    })
  });
  const data = await res.json();
  const { baseline, scenario } = data;

  document.getElementById('simComparisonContainer').style.display = 'block';

  // Baseline
  document.getElementById('baseScore').textContent = baseline.overallScore.toFixed(0);
  document.getElementById('baseScheduled').textContent = `${baseline.totalScheduledMinutes}m`;
  document.getElementById('baseUnscheduled').textContent = `${baseline.unscheduledItems.length} task (${baseline.unscheduledItems.reduce((acc, u) => acc + u.task.estimatedMinutes, 0)}m)`;
  document.getElementById('baseBuffer').textContent = `${baseline.remainingAvailableMinutes}m`;

  // Scenario B
  document.getElementById('scenScore').textContent = scenario.overallScore.toFixed(0);
  document.getElementById('scenScheduled').textContent = `${scenario.totalScheduledMinutes}m`;
  document.getElementById('scenUnscheduled').textContent = `${scenario.unscheduledItems.length} tasks`;
  document.getElementById('scenBuffer').textContent = `${scenario.remainingAvailableMinutes}m`;

  // Explanation
  const expText = document.getElementById('simExplanationText');
  if (scenario.unscheduledItems.length === 0) {
    expText.textContent = `Scenario B eliminates capacity overflow by expanding time to ${state.simulatedMinutes} minutes. All candidate tasks are accommodated with ${scenario.remainingAvailableMinutes}m of safety buffer.`;
  } else {
    expText.textContent = `Scenario B schedules ${scenario.totalScheduledMinutes} minutes across ${scenario.scheduledItems.length} tasks.`;
  }

  // Setup Apply Button
  document.getElementById('applyScenarioBtn').onclick = async () => {
    await fetch('/api/simulator/apply', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ plan: scenario })
    });
    alert('Scenario B applied atomically to your active schedule!');
    switchTab('dashboard');
  };
}

// --- COMEBACK MODE RECOVERY ---

async function loadComebackWorkflow() {
  const container = document.getElementById('comebackProposalsContainer');
  container.innerHTML = '<p class="caption text-muted">Calculating recovery trade-offs...</p>';

  const res = await fetch('/api/comeback/generate', { method: 'POST' });
  state.currentRecovery = await res.json();

  container.innerHTML = `
    <h3>Recovery Strategy Proposals</h3>
    <div class="mt-2">
      ${state.currentRecovery.proposals.map((prop, idx) => `
        <div class="card radio-card ${idx === state.selectedRecoveryProposalIndex ? 'scenario-card' : ''}" onclick="selectRecoveryProp(${idx})">
          <div style="flex: 1;">
            <div class="card-header-flex">
              <strong>${prop.title}</strong>
              <span class="score-pill" style="font-size: 13px; padding: 2px 8px;">${prop.plan.overallScore.toFixed(0)} pts</span>
            </div>
            <p class="caption text-muted mt-1">${prop.rationale}</p>
            <div class="comp-row mt-2">
              <span>Scheduled: <strong>${prop.plan.scheduledItems.length} tasks (${prop.plan.totalScheduledMinutes}m)</strong></span>
            </div>
          </div>
        </div>
      `).join('')}
    </div>

    ${state.currentRecovery.splitTasks.length > 0 ? `
      <div class="card mt-3">
        <h4>Task Splitting Visualization</h4>
        <p class="caption text-muted">Large blocks (>45m) divided into 30m units to protect cognitive focus:</p>
        <div class="mt-2">
          ${state.currentRecovery.splitTasks.map(t => `
            <div class="task-item">
              <div class="task-info">
                <strong>${t.title}</strong>
                <p>Original: ${t.estimatedMinutes}m -> Split into Part 1 (30m) & Part 2 (${t.estimatedMinutes - 30}m)</p>
              </div>
              <span class="badge badge-amber">Split</span>
            </div>
          `).join('')}
        </div>
      </div>
    ` : ''}

    <button class="btn btn-emerald btn-block mt-4" onclick="approveRecoveryPlan()">Approve & Apply Recovery Plan</button>
  `;
}

function selectRecoveryProp(idx) {
  state.selectedRecoveryProposalIndex = idx;
  loadComebackWorkflow();
}

async function approveRecoveryPlan() {
  const selected = state.currentRecovery.proposals[state.selectedRecoveryProposalIndex];
  await fetch('/api/comeback/apply', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      proposal: selected,
      splitTasks: state.currentRecovery.splitTasks
    })
  });
  alert('Recovery plan approved! Tasks have been updated.');
  await initApp();
  switchTab('dashboard');
}

// --- PERSONAL GROWTH INVESTIGATOR ---

async function fetchInsights() {
  const res = await fetch('/api/insights');
  const insights = await res.json();
  const container = document.getElementById('insightsList');
  container.innerHTML = '';

  insights.forEach(ins => {
    const card = document.createElement('div');
    card.className = 'card mt-2';
    card.innerHTML = `
      <div class="card-header-flex">
        <span class="badge badge-teal">${ins.type}</span>
        <span class="caption text-muted">Evidence: ${ins.evidenceStrength} (N = ${ins.sampleSize})</span>
      </div>
      <h4 class="mt-2">${ins.title}</h4>
      <p class="text-sm mt-1 text-muted">${ins.description}</p>
      <div class="divider my-2"></div>
      <p class="caption"><strong>Actionable Hypothesis:</strong> ${ins.suggestedHypothesis}</p>
    `;
    container.appendChild(card);
  });
}

async function fetchExperiments() {
  const res = await fetch('/api/experiments');
  const experiments = await res.json();
  const container = document.getElementById('experimentsList');
  container.innerHTML = '';

  experiments.forEach(exp => {
    const card = document.createElement('div');
    card.className = 'card scenario-card mt-2';
    const delta = (((exp.resultValue - exp.baselineValue) / exp.baselineValue) * 100).toFixed(0);

    card.innerHTML = `
      <div class="card-header-flex">
        <span class="badge badge-emerald">ACTIVE TRIAL</span>
        <span class="caption font-bold">${exp.status}</span>
      </div>
      <h4 class="mt-2">${exp.hypothesis}</h4>
      <p class="text-sm mt-1 text-muted">${exp.changeDescription}</p>
      <div class="grid-2 mt-3">
        <div class="card comp-card baseline-card">
          <span class="caption">BASELINE RATE</span>
          <div class="font-bold" style="font-size: 18px;">${(exp.baselineValue * 100).toFixed(0)}%</div>
          <span class="caption text-muted">Prior 14 days</span>
        </div>
        <div class="card comp-card" style="border: 1px solid var(--accent-emerald);">
          <span class="caption text-emerald font-bold">TRIAL RATE</span>
          <div class="font-bold text-emerald" style="font-size: 18px;">${(exp.resultValue * 100).toFixed(0)}% (+${delta}%)</div>
          <span class="caption text-muted">N = ${exp.sampleSize} tasks</span>
        </div>
      </div>
      <div class="explanation-box mt-3" style="background: rgba(245, 158, 11, 0.08); border-color: rgba(245, 158, 11, 0.2);">
        <p class="text-sm"><strong>Methodological Limitations:</strong> ${exp.limitations}</p>
      </div>
    `;
    container.appendChild(card);
  });
}

// --- PROFILE & REFLECTIONS ---

async function saveReflection() {
  const wins = document.getElementById('refWins').value.trim();
  const chal = document.getElementById('refChallenges').value.trim();
  const next = document.getElementById('refNextStep').value.trim();

  if (!wins || !chal || !next) {
    alert('Please enter all reflection prompts.');
    return;
  }

  await fetch('/api/reflections', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ wins, challenges: chal, nextStep: next, workload: 3 })
  });

  document.getElementById('refWins').value = '';
  document.getElementById('refChallenges').value = '';
  document.getElementById('refNextStep').value = '';
  alert('Daily reflection logged successfully!');
}

async function saveDailyCapacity() {
  const mins = parseInt(document.getElementById('inputDailyMinutes').value) || 180;
  await fetch('/api/profile', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ dailyAvailableMinutes: mins })
  });
  alert('Daily capacity updated.');
  await fetchLifeTwin();
}

function showAddTaskModal() {
  const title = prompt('Enter Task Title:');
  if (!title) return;
  const mins = prompt('Estimated Minutes (> 0):', '30');
  if (!mins || parseInt(mins) <= 0) return;

  fetch('/api/tasks', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title, estimatedMinutes: parseInt(mins), priority: 3 })
  }).then(() => {
    fetchLifeTwin();
    fetchTasks();
  });
}
