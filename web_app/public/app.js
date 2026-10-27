/**
 * LIFESYNC — Clean Minimalist Controller
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
  selectedRecoveryIndex: 0
};

document.addEventListener('DOMContentLoaded', () => {
  initApp();
  setupEvents();
});

async function initApp() {
  await fetchProfile();
  await fetchLifeTwin();
  await fetchTasks();
  await fetchGoals();
  await fetchInsights();
  await fetchExperiments();
}

function setupEvents() {
  // Navigation
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const tab = btn.querySelector('span').textContent.toLowerCase();
      const map = {
        'today': 'dashboard',
        'plan': 'planner',
        'simulate': 'simulator',
        'comeback': 'comeback',
        'insights': 'insights',
        'profile': 'profile'
      };
      switchTab(map[tab] || 'dashboard');
    });
  });

  // Reset Demo
  document.getElementById('resetDemoBtn').addEventListener('click', async () => {
    await fetch('/api/demo/reset', { method: 'POST' });
    showToast('Demo reset to initial 180m benchmark');
    await initApp();
    switchTab('dashboard');
  });

  // Planner
  document.getElementById('generatePlanBtn').addEventListener('click', generatePlan);

  // Simulator Slider
  const slider = document.getElementById('simTimeSlider');
  slider.addEventListener('input', (e) => {
    state.simulatedMinutes = parseInt(e.target.value);
    const hrs = (state.simulatedMinutes / 60).toFixed(1);
    document.getElementById('simTimeLabel').textContent = `${state.simulatedMinutes} mins (${hrs}h)`;
  });

  document.getElementById('runSimBtn').addEventListener('click', runSimulation);

  // Profile / Settings
  document.getElementById('saveCapacityBtn').addEventListener('click', saveCapacity);
  document.getElementById('saveReflectionBtn').addEventListener('click', saveReflection);
}

function switchTab(tabId) {
  state.activeTab = tabId;
  document.querySelectorAll('.tab-view').forEach(v => v.classList.remove('active'));
  const target = document.getElementById(`view-${tabId}`);
  if (target) target.classList.add('active');

  const navOrder = ['dashboard', 'planner', 'simulator', 'comeback', 'insights', 'profile'];
  document.querySelectorAll('.bottom-nav .nav-btn').forEach((btn, i) => {
    btn.classList.toggle('active', i === navOrder.indexOf(tabId));
  });

  if (tabId === 'simulator') {
    renderSimCheckboxes();
    runSimulation();
  } else if (tabId === 'comeback') {
    loadComeback();
  }
}

// --- DATA FETCHING & RENDERING ---

async function fetchProfile() {
  const res = await fetch('/api/profile');
  state.profile = await res.json();
  const firstName = state.profile.displayName.split(' ')[0];
  document.getElementById('userDisplayName').textContent = firstName;
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

  // Badge
  const badge = document.getElementById('capacityBadge');
  badge.textContent = hasOverflow ? `+${gap}m gap` : `${avail - total}m buffer`;
  badge.className = `status-pill ${hasOverflow ? 'pill-rose' : 'pill-teal'}`;

  // Meter
  const bar = document.getElementById('capacityProgressBar');
  const percent = Math.min(100, Math.round((total / avail) * 100));
  bar.style.width = `${percent}%`;
  bar.className = `meter-fill ${hasOverflow ? 'fill-rose' : 'fill-teal'}`;

  // Labels
  document.getElementById('workloadLabel').textContent = `${formatHours(total)} planned`;
  document.getElementById('availableLabel').textContent = `${formatHours(avail)} free`;

  // Explanation
  const text = hasOverflow
    ? `You have ${gap} mins more work than free time today. Consider dropping 1 low priority task.`
    : `Your ${total} mins of tasks fit comfortably in your ${avail}m free window.`;
  document.getElementById('twinExplanationText').textContent = text;

  // Banner
  document.getElementById('comebackBanner').style.display = hasOverflow ? 'flex' : 'none';
}

function formatHours(mins) {
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  return m === 0 ? `${h}h` : `${h}h ${m}m`;
}

async function fetchTasks() {
  const res = await fetch('/api/tasks');
  state.tasks = await res.json();
  renderTasks();
}

function renderTasks() {
  const container = document.getElementById('tasksList');
  container.innerHTML = '';

  const activeTasks = state.tasks.filter(t => t.status !== 'Deferred');
  const deferredTasks = state.tasks.filter(t => t.status === 'Deferred');
  const completed = state.tasks.filter(t => t.status === 'Completed').length;
  
  document.getElementById('completedCountStat').textContent = completed;

  activeTasks.forEach(task => {
    const isDone = task.status === 'Completed';
    const div = document.createElement('div');
    div.className = 'task-item';
    div.innerHTML = `
      <div class="task-left" style="flex: 1;">
        <input type="checkbox" class="task-checkbox" ${isDone ? 'checked' : ''} onchange="toggleTask('${task.id}', this.checked)">
        <div>
          <div class="task-title" style="${isDone ? 'text-decoration: line-through; opacity: 0.5;' : ''}">${task.title}</div>
          <div class="task-meta">${task.estimatedMinutes} mins • Priority: ${task.priority >= 4 ? 'Urgent' : (task.priority === 3 ? 'High' : 'Normal')}</div>
        </div>
      </div>
      <div class="task-actions">
        <span class="status-pill ${task.priority >= 4 ? 'pill-rose' : (task.priority === 3 ? 'pill-amber' : 'pill-slate')}">
          ${task.priority >= 4 ? 'Urgent' : (task.priority === 3 ? 'High' : 'Normal')}
        </span>
        ${!isDone ? `<button class="btn-task-action" onclick="postponeTask('${task.id}')" title="Postpone to tomorrow">⏸</button>` : ''}
        <button class="btn-task-action" onclick="deleteTask('${task.id}')" title="Delete task">✕</button>
      </div>
    `;
    container.appendChild(div);
  });

  // Render Deferred / Postponed section
  const defSec = document.getElementById('deferredTasksSection');
  const defContainer = document.getElementById('deferredTasksList');
  if (deferredTasks.length > 0) {
    defSec.style.display = 'block';
    document.getElementById('deferredCountBadge').textContent = `${deferredTasks.length} postponed`;
    defContainer.innerHTML = '';
    deferredTasks.forEach(task => {
      const div = document.createElement('div');
      div.className = 'task-item';
      div.style.opacity = '0.75';
      div.innerHTML = `
        <div class="task-left" style="flex: 1;">
          <div>
            <div class="task-title">${task.title}</div>
            <div class="task-meta">${task.estimatedMinutes} mins • Deferred to Tomorrow</div>
          </div>
        </div>
        <div class="task-actions">
          <button class="btn-task-action btn-restore" onclick="restoreTask('${task.id}')">Restore to Today</button>
          <button class="btn-task-action" onclick="deleteTask('${task.id}')">✕</button>
        </div>
      `;
      defContainer.appendChild(div);
    });
  } else {
    defSec.style.display = 'none';
  }
}

async function postponeTask(taskId) {
  await fetch(`/api/tasks/${taskId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status: 'Deferred' })
  });
  showToast('Task postponed for later.');
  await fetchLifeTwin();
  await fetchTasks();
}

async function restoreTask(taskId) {
  await fetch(`/api/tasks/${taskId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status: 'Pending' })
  });
  showToast('Task restored to today.');
  await fetchLifeTwin();
  await fetchTasks();
}

async function deleteTask(taskId) {
  if (!confirm('Delete this task?')) return;
  await fetch(`/api/tasks/${taskId}`, { method: 'DELETE' });
  showToast('Task removed.');
  await fetchLifeTwin();
  await fetchTasks();
}

async function toggleTask(taskId, isDone) {
  await fetch(`/api/tasks/${taskId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status: isDone ? 'Completed' : 'Pending' })
  });
  await fetchLifeTwin();
  await fetchTasks();
}

async function fetchGoals() {
  const res = await fetch('/api/goals');
  state.goals = await res.json();
}

// --- PLANNER ---

async function generatePlan() {
  const strategy = document.querySelector('input[name="planStrategy"]:checked').value;
  const res = await fetch('/api/plan/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ strategy })
  });
  const plan = await res.json();

  document.getElementById('planResultContainer').style.display = 'block';
  document.getElementById('overallScoreBadge').textContent = `${Math.round(plan.overallScore)}%`;

  // Timeline
  const timeline = document.getElementById('scheduledTimeline');
  timeline.innerHTML = '';
  plan.scheduledItems.forEach(item => {
    const div = document.createElement('div');
    div.className = 'timeline-item';
    div.innerHTML = `
      <div>
        <div class="font-bold text-sm">${item.task ? item.task.title : item.taskId}</div>
        <div class="text-xs text-subtle">${item.durationMinutes} minutes focused</div>
      </div>
      <span class="status-pill pill-teal">Scheduled</span>
    `;
    timeline.appendChild(div);
  });

  // Unscheduled
  const unschedSec = document.getElementById('unscheduledSection');
  const unschedList = document.getElementById('unscheduledList');
  if (plan.unscheduledItems.length > 0) {
    unschedSec.style.display = 'block';
    unschedList.innerHTML = '';
    plan.unscheduledItems.forEach(u => {
      const div = document.createElement('div');
      div.className = 'flex-between py-1';
      div.innerHTML = `
        <span class="text-xs text-main font-medium">${u.task ? u.task.title : u.taskId}</span>
        <span class="status-pill pill-rose text-xs">${u.task ? u.task.estimatedMinutes : 20}m deferred</span>
      `;
      unschedList.appendChild(div);
    });
  } else {
    unschedSec.style.display = 'none';
  }
}

// --- WHAT-IF SIMULATOR ---

function renderSimCheckboxes() {
  const container = document.getElementById('simTaskCheckboxes');
  container.innerHTML = '';
  state.tasks.forEach(task => {
    if (task.status === 'Completed') return;
    const isExcluded = state.excludedTaskIds.has(task.id) || task.status === 'Deferred';
    const label = document.createElement('label');
    label.className = `strategy-option ${!isExcluded ? 'comp-box-active' : ''}`;
    label.style.marginBottom = '6px';
    label.innerHTML = `
      <input type="checkbox" class="task-checkbox" ${!isExcluded ? 'checked' : ''} onchange="toggleSimTask('${task.id}', this.checked)">
      <div class="strategy-info" style="flex: 1;">
        <div class="flex-between">
          <strong>${task.title}</strong>
          <span class="status-pill ${task.priority >= 4 ? 'pill-rose' : (task.priority === 3 ? 'pill-amber' : 'pill-slate')}">
            ${task.priority >= 4 ? 'Urgent' : (task.priority === 3 ? 'High' : 'Normal')}
          </span>
        </div>
        <span class="text-xs text-subtle">${task.estimatedMinutes} mins • ${task.status === 'Deferred' ? 'Postponed' : 'Included in today'}</span>
      </div>
    `;
    container.appendChild(label);
  });
}

function toggleSimTask(taskId, included) {
  if (included) state.excludedTaskIds.delete(taskId);
  else state.excludedTaskIds.add(taskId);
  renderSimCheckboxes();
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
  const { baseline, scenario } = await res.json();

  document.getElementById('simComparisonContainer').style.display = 'block';

  document.getElementById('baseScheduled').textContent = `${baseline.totalScheduledMinutes}m`;
  document.getElementById('baseUnscheduled').textContent = baseline.unscheduledItems.length > 0
    ? `${baseline.unscheduledItems.length} task left out`
    : `All tasks fit`;

  document.getElementById('scenScheduled').textContent = `${scenario.totalScheduledMinutes}m`;
  document.getElementById('scenUnscheduled').textContent = scenario.unscheduledItems.length > 0
    ? `${scenario.unscheduledItems.length} left out`
    : `All tasks fit! (+${scenario.remainingAvailableMinutes}m free)`;

  const takeaway = scenario.unscheduledItems.length === 0
    ? `Scenario gives you enough time to finish all tasks with ${scenario.remainingAvailableMinutes}m buffer left over.`
    : `Leaves out ${scenario.unscheduledItems.length} task to keep your schedule realistic.`;
  document.getElementById('simExplanationText').textContent = takeaway;

  document.getElementById('applyScenarioBtn').onclick = async () => {
    await fetch('/api/simulator/apply', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        plan: scenario,
        simulatedMinutes: state.simulatedMinutes,
        excludedTaskIds: Array.from(state.excludedTaskIds)
      })
    });
    showToast('Plan applied! Your today dashboard has been updated.');
    await initApp();
    switchTab('dashboard');
  };
}

// --- COMEBACK MODE ---

async function loadComeback() {
  const container = document.getElementById('comebackProposalsContainer');
  container.innerHTML = '<p class="text-xs text-subtle">Generating gentle recovery options...</p>';

  const res = await fetch('/api/comeback/generate', { method: 'POST' });
  state.currentRecovery = await res.json();

  container.innerHTML = `
    <span class="card-eyebrow">CHOOSE HOW TO RECOVER</span>
    <div class="mt-2">
      ${state.currentRecovery.proposals.map((prop, idx) => `
        <div class="card strategy-option ${idx === state.selectedRecoveryIndex ? 'comp-box-active' : ''}" onclick="selectRecovery(${idx})" style="cursor: pointer;">
          <div style="flex: 1;">
            <div class="flex-between">
              <strong>${prop.title}</strong>
              <span class="status-pill pill-teal">${prop.plan.totalScheduledMinutes}m planned</span>
            </div>
            <p class="text-xs text-subtle mt-1">${prop.rationale}</p>
          </div>
        </div>
      `).join('')}
    </div>

    ${state.currentRecovery.splitTasks.length > 0 ? `
      <div class="card mt-3">
        <span class="card-eyebrow">AUTOMATIC TASK BREAKDOWN</span>
        <p class="text-xs text-subtle mt-1">To prevent mental fatigue, large tasks are split into bite-sized units:</p>
        <div class="mt-2">
          ${state.currentRecovery.splitTasks.map(t => `
            <div class="timeline-item">
              <div>
                <strong class="text-xs">${t.title}</strong>
                <div class="text-xs text-subtle">${t.estimatedMinutes}m &rarr; Part 1 (30m) + Part 2 (${t.estimatedMinutes - 30}m)</div>
              </div>
              <span class="status-pill pill-amber">Split</span>
            </div>
          `).join('')}
        </div>
      </div>
    ` : ''}

    <button class="btn btn-teal btn-block mt-3" onclick="applyComeback()">Accept Recovery Plan</button>
  `;
}

function selectRecovery(idx) {
  state.selectedRecoveryIndex = idx;
  loadComeback();
}

async function applyComeback() {
  const chosen = state.currentRecovery.proposals[state.selectedRecoveryIndex];
  await fetch('/api/comeback/apply', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      proposal: chosen,
      splitTasks: state.currentRecovery.splitTasks
    })
  });
  showToast('Recovery plan activated!');
  await initApp();
  switchTab('dashboard');
}

// --- HABIT DETECTIVE (INSIGHTS & EXPERIMENTS) ---

async function fetchInsights() {
  const res = await fetch('/api/insights');
  const insights = await res.json();
  const container = document.getElementById('insightsList');
  container.innerHTML = '';

  insights.forEach(ins => {
    const card = document.createElement('div');
    card.className = 'card mt-2';
    card.innerHTML = `
      <div class="flex-between">
        <span class="status-pill pill-teal">Discovered Pattern</span>
        <span class="text-xs text-subtle font-medium">${ins.sampleSize} tasks analyzed (N=${ins.sampleSize})</span>
      </div>
      <h4 class="mt-2" style="font-size: 14px; font-weight: 700;">${ins.title}</h4>
      <p class="text-xs text-subtle mt-1">${ins.description}</p>
      <div class="status-summary-bar mt-2">
        <span class="text-xs">💡 <strong>Why this appears:</strong> LIFESYNC compared your completion times across 14 days and spotted that shorter blocks have an 85% success rate vs 34% for long ones.</span>
      </div>
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
    card.className = 'card comp-box-active mt-2';
    const gain = Math.round(((exp.resultValue - exp.baselineValue) / exp.baselineValue) * 100);

    card.innerHTML = `
      <div class="flex-between">
        <span class="status-pill pill-teal">Habit A/B Test</span>
        <span class="text-xs font-bold text-teal">Active Experiment</span>
      </div>
      <h4 class="mt-2" style="font-size: 14px; font-weight: 700;">${exp.hypothesis}</h4>
      <p class="text-xs text-subtle mt-1">${exp.changeDescription}</p>
      
      <div class="grid-2 mt-3">
        <div class="card" style="padding: 10px; text-align: center;">
          <span class="text-xs text-subtle font-bold">BEFORE HABIT</span>
          <div class="font-bold text-sm mt-1">${Math.round(exp.baselineValue * 100)}% finished</div>
          <span class="text-xs text-subtle">Past baseline</span>
        </div>
        <div class="card" style="padding: 10px; text-align: center; border-color: var(--accent-teal); background: var(--accent-teal-soft);">
          <span class="text-xs text-teal font-bold">WITH 30m RULE</span>
          <div class="font-bold text-sm text-teal mt-1">${Math.round(exp.resultValue * 100)}% finished</div>
          <span class="text-xs text-teal font-bold">+${gain}% improvement</span>
        </div>
      </div>
      <div class="text-xs text-subtle mt-2">Measured over ${exp.sampleSize} logged tasks across 7 days.</div>
    `;
    container.appendChild(card);
  });
}

// --- PROFILE & SETTINGS ---

async function saveCapacity() {
  const mins = parseInt(document.getElementById('inputDailyMinutes').value) || 180;
  await fetch('/api/profile', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ dailyAvailableMinutes: mins })
  });
  showToast('Daily capacity updated.');
  await fetchLifeTwin();
}

async function saveReflection() {
  const wins = document.getElementById('refWins').value.trim();
  const chal = document.getElementById('refChallenges').value.trim();
  const next = document.getElementById('refNextStep').value.trim();

  if (!wins && !chal && !next) return;

  await fetch('/api/reflections', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ wins, challenges: chal, nextStep: next, workload: 3 })
  });

  document.getElementById('refWins').value = '';
  document.getElementById('refChallenges').value = '';
  document.getElementById('refNextStep').value = '';
  showToast('Reflection logged!');
}

// --- ADD TASK MODAL WITH EXPLICIT PRIORITY SELECTION ---

function openAddTaskModal() {
  document.getElementById('newTaskTitle').value = '';
  document.getElementById('newTaskMins').value = '30';
  document.querySelectorAll('.quick-pill').forEach((btn, i) => btn.classList.toggle('active', i === 1));
  
  // Set default radio (Priority 3 - High)
  const radios = document.querySelectorAll('input[name="newTaskPriority"]');
  radios.forEach(r => {
    r.checked = (r.value === '3');
    r.closest('.priority-option-card').classList.toggle('selected', r.value === '3');
  });

  document.getElementById('addTaskModal').style.display = 'flex';
  document.getElementById('newTaskTitle').focus();
}

function closeAddTaskModal() {
  document.getElementById('addTaskModal').style.display = 'none';
}

function selectDuration(mins, btn) {
  document.getElementById('newTaskMins').value = mins;
  document.querySelectorAll('.quick-pill').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
}

// Priority card selection handler
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.priority-option-card').forEach(card => {
    card.addEventListener('click', () => {
      const radio = card.querySelector('input[type="radio"]');
      if (radio) {
        radio.checked = true;
        document.querySelectorAll('.priority-option-card').forEach(c => c.classList.remove('selected'));
        card.classList.add('selected');
      }
    });
  });
});

async function submitNewTask() {
  const title = document.getElementById('newTaskTitle').value.trim();
  if (!title) {
    alert('Please enter a task name.');
    return;
  }

  const mins = parseInt(document.getElementById('newTaskMins').value);
  if (!mins || mins <= 0) {
    alert('Please enter a valid positive duration in minutes.');
    return;
  }

  const selectedPriorityRadio = document.querySelector('input[name="newTaskPriority"]:checked');
  const priority = selectedPriorityRadio ? parseInt(selectedPriorityRadio.value) : 2;
  const lifeAreaId = document.getElementById('newTaskArea').value;

  await fetch('/api/tasks', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      title,
      estimatedMinutes: mins,
      priority,
      lifeAreaId,
      taskType: mins > 45 ? 'DeepWork' : 'Standard'
    })
  });

  closeAddTaskModal();
  showToast(`Added "${title}" with ${priority >= 4 ? 'Urgent' : (priority === 3 ? 'High' : 'Normal')} priority!`);
  await fetchLifeTwin();
  await fetchTasks();
}

function showToast(msg) {
  const toast = document.createElement('div');
  toast.textContent = msg;
  toast.style.cssText = `
    position: fixed;
    top: 20px;
    left: 50%;
    transform: translateX(-50%);
    background: #0F172A;
    color: white;
    padding: 8px 16px;
    border-radius: 99px;
    font-size: 12px;
    font-weight: 600;
    z-index: 9999;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    animation: fadeIn 0.2s ease;
  `;
  document.body.appendChild(toast);
  setTimeout(() => toast.remove(), 2500);
}
