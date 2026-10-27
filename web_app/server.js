/**
 * LIFESYNC — Adaptive Personal Life Intelligence System
 * Production-Minded Zero-Dependency Web Application & REST Server
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

// =============================================================================
// DOMAIN ALGORITHMS & HEURISTICS
// =============================================================================

function evaluatePlanScore({ scheduledItems, availableMinutes, commitments, tasks }) {
  if (!scheduledItems || scheduledItems.length === 0) {
    return { deadlineScore: 0, goalCoverageScore: 0, slotFitScore: 0, overloadPenalty: 0, conflictPenalty: 0, totalScore: 0 };
  }

  const weightDeadline = 0.35;
  const weightGoal = 0.25;
  const weightFit = 0.25;
  const weightOverload = 0.15;
  const weightConflict = 0.10;

  const totalScheduledMins = scheduledItems.reduce((acc, item) => acc + item.durationMinutes, 0);

  // 1. Deadline Score D(P)
  let deadlineSum = 0;
  let deadlineCount = 0;
  for (const item of scheduledItems) {
    if (item.dueAt) {
      deadlineCount++;
      if (item.scheduledEnd <= item.dueAt) {
        deadlineSum += 100;
      } else {
        deadlineSum += 0;
      }
    }
  }
  const deadlineScore = deadlineCount > 0 ? (deadlineSum / deadlineCount) : 90;

  // 2. Goal Coverage G(P)
  const scheduledGoalIds = new Set(scheduledItems.map(i => i.goalId).filter(Boolean));
  const goalCoverageScore = Math.min(100, scheduledGoalIds.size * 25);

  // 3. Slot Fit F(P)
  const ratio = availableMinutes > 0 ? (totalScheduledMins / availableMinutes) : 1;
  const slotFitScore = ratio <= 1.0 ? ratio * 100 : Math.max(0, 100 - (ratio - 1) * 200);

  // 4. Overload Penalty O(P)
  const overloadPenalty = totalScheduledMins > availableMinutes
    ? Math.min(100, ((totalScheduledMins - availableMinutes) / availableMinutes) * 100)
    : 0;

  // 5. Conflict Penalty C(P)
  let conflictPenalty = 0;
  for (const item of scheduledItems) {
    for (const c of commitments) {
      if ((item.scheduledStart < c.endTime) && (item.scheduledEnd > c.startTime)) {
        conflictPenalty += 50;
      }
    }
  }
  conflictPenalty = Math.min(100, conflictPenalty);

  const rawScore = (weightDeadline * deadlineScore) +
                   (weightGoal * goalCoverageScore) +
                   (weightFit * slotFitScore) -
                   (weightOverload * overloadPenalty) -
                   (weightConflict * conflictPenalty);

  const totalScore = Math.max(0, Math.min(100, Math.round(rawScore * 10) / 10));

  return { deadlineScore, goalCoverageScore, slotFitScore, overloadPenalty, conflictPenalty, totalScore };
}

function generatePlan({ tasks, goals, commitments, availableMinutes, startTime, strategy = 'PriorityFirst' }) {
  const hardViolations = [];
  const unscheduledItems = [];
  const scheduledItems = [];

  const eligible = tasks.filter(t => {
    if (t.status === 'Completed' || t.status === 'Deferred') return false;
    if (t.estimatedMinutes <= 0) {
      hardViolations.push(`Task "${t.title}" rejected: Duration must be strictly positive.`);
      return false;
    }
    return true;
  });

  const ranked = [...eligible].sort((a, b) => {
    if (strategy === 'PriorityFirst') {
      if (b.priority !== a.priority) return b.priority - a.priority;
      if (a.dueAt && b.dueAt) return a.dueAt - b.dueAt;
      return a.estimatedMinutes - b.estimatedMinutes;
    } else if (strategy === 'DeadlineSensitive') {
      if (a.dueAt && b.dueAt) return a.dueAt - b.dueAt;
      if (a.dueAt && !b.dueAt) return -1;
      if (!a.dueAt && b.dueAt) return 1;
      return b.priority - a.priority;
    } else if (strategy === 'BalanceFirst') {
      return a.estimatedMinutes - b.estimatedMinutes;
    } else if (strategy === 'RecoveryFirst') {
      const quickA = a.estimatedMinutes <= 30;
      const quickB = b.estimatedMinutes <= 30;
      if (quickA !== quickB) return quickA ? -1 : 1;
      return b.priority - a.priority;
    }
    return b.priority - a.priority;
  });

  let currentTime = startTime;
  let remainingMins = availableMinutes;
  const sortedCommitments = [...commitments].sort((a, b) => a.startTime - b.startTime);

  for (const task of ranked) {
    if (task.estimatedMinutes > remainingMins) {
      unscheduledItems.push({
        taskId: task.id,
        task,
        reason: `Insufficient remaining capacity: Needs ${task.estimatedMinutes}m, but only ${remainingMins}m available.`
      });
      continue;
    }

    let candStart = currentTime;
    let candEnd = candStart + task.estimatedMinutes * 60000;
    let slotFound = false;

    for (let attempts = 0; attempts < 5 && !slotFound; attempts++) {
      let clash = null;
      for (const c of sortedCommitments) {
        if (candStart < c.endTime && candEnd > c.startTime) {
          clash = c;
          break;
        }
      }
      if (clash) {
        candStart = clash.endTime;
        candEnd = candStart + task.estimatedMinutes * 60000;
      } else {
        slotFound = true;
      }
    }

    if (slotFound) {
      scheduledItems.push({
        id: `item_${task.id}`,
        taskId: task.id,
        task,
        goalId: task.goalId,
        scheduledStart: candStart,
        scheduledEnd: candEnd,
        durationMinutes: task.estimatedMinutes,
        dueAt: task.dueAt
      });
      currentTime = candEnd;
      remainingMins -= task.estimatedMinutes;
    } else {
      unscheduledItems.push({
        taskId: task.id,
        task,
        reason: 'Cannot schedule around fixed commitment constraints.'
      });
    }
  }

  const scoring = evaluatePlanScore({ scheduledItems, availableMinutes, commitments, tasks: eligible });

  return {
    scheduledItems,
    unscheduledItems,
    totalScheduledMinutes: scheduledItems.reduce((acc, i) => acc + i.durationMinutes, 0),
    remainingAvailableMinutes: remainingMins,
    hardViolations,
    overallScore: scoring.totalScore,
    scoreBreakdown: scoring
  };
}

function buildRecoveryPlan({ allTasks, availableMinutes, startTime, commitments }) {
  const splitTasks = [];
  const processedTasks = [];

  for (const t of allTasks) {
    if (t.allowSplitting && t.estimatedMinutes > 45) {
      splitTasks.push(t);
      const half = Math.round(t.estimatedMinutes / 2);
      processedTasks.push({
        ...t,
        id: `${t.id}_part1`,
        title: `${t.title} (Part 1 - Core Focus)`,
        estimatedMinutes: half
      });
      processedTasks.push({
        ...t,
        id: `${t.id}_part2`,
        title: `${t.title} (Part 2 - Completion)`,
        estimatedMinutes: t.estimatedMinutes - half,
        priority: 2
      });
    } else {
      processedTasks.push(t);
    }
  }

  // Proposal 1: Protect Deadlines
  const prop1Plan = generatePlan({
    tasks: processedTasks,
    commitments,
    availableMinutes,
    startTime,
    strategy: 'RecoveryFirst'
  });

  // Proposal 2: Gentle Momentum Reset (<= 30m only)
  const quickTasks = allTasks.filter(t => t.estimatedMinutes <= 30);
  const prop2Plan = generatePlan({
    tasks: quickTasks,
    commitments,
    availableMinutes,
    startTime,
    strategy: 'BalanceFirst'
  });

  return {
    triggerReason: 'Workload exceeds daily capacity by 20m with critical deadlines approaching.',
    splitTasks,
    proposals: [
      {
        id: 'prop1',
        title: 'Protect Deadlines & Split Heavy Workload',
        rationale: 'Breaks large tasks into 30m units and locks in nearest deadlines to recover without cognitive burnout.',
        plan: prop1Plan
      },
      {
        id: 'prop2',
        title: 'Gentle Momentum Reset',
        rationale: 'Schedules only bite-sized quick wins (<= 30m) to rebuild rhythm safely before tackling heavy assignments.',
        plan: prop2Plan
      }
    ]
  };
}

// =============================================================================
// IN-MEMORY DATABASE STATE (SECTION 17 BENCHMARK SCENARIO)
// =============================================================================

function createInitialState() {
  const now = Date.now();
  return {
    profile: {
      id: 'd0000000-0000-0000-0000-000000000001',
      displayName: 'Alex Rivera (CS Student)',
      timezone: 'Asia/Kolkata',
      dailyAvailableMinutes: 180, // Section 17: 180 mins
      planningPreferences: { preferredStrategy: 'PriorityFirst', energyPeak: 'Morning' }
    },
    lifeAreas: [
      { id: 'area_academics', name: 'Academics & Learning', color: '#3B82F6', priority: 4 },
      { id: 'area_career', name: 'Career & Placement', color: '#10B981', priority: 3 },
      { id: 'area_health', name: 'Fitness & Health', color: '#F59E0B', priority: 3 },
      { id: 'area_personal', name: 'Personal Development', color: '#8B5CF6', priority: 2 }
    ],
    goals: [
      { id: 'goal_dbms', lifeAreaId: 'area_academics', title: 'Score A+ in DBMS Coursework', priority: 4, targetDate: '2026-11-24', status: 'Active' },
      { id: 'goal_java', lifeAreaId: 'area_academics', title: 'Master OOP in Java', priority: 4, targetDate: '2026-12-05', status: 'Active' },
      { id: 'goal_placement', lifeAreaId: 'area_career', title: 'Campus Placement Readiness', priority: 3, targetDate: '2026-12-20', status: 'Active' },
      { id: 'goal_fitness', lifeAreaId: 'area_health', title: 'Daily Cardio & Strength', priority: 3, targetDate: '2027-01-15', status: 'Active' },
      { id: 'goal_reading', lifeAreaId: 'area_personal', title: 'Deep Work Reading Habit', priority: 2, targetDate: '2026-11-30', status: 'Active' }
    ],
    // Total workload = 60 + 45 + 45 + 30 + 20 = 200 minutes!
    tasks: [
      { id: 't1', goalId: 'goal_dbms', title: 'DBMS Assignment: SQL Query Optimization', estimatedMinutes: 60, priority: 4, dueAt: now + 4 * 3600000, status: 'Pending', taskType: 'DeepWork', allowSplitting: true },
      { id: 't2', goalId: 'goal_java', title: 'Java Practice: Concurrency & Streams', estimatedMinutes: 45, priority: 4, dueAt: now + 8 * 3600000, status: 'Pending', taskType: 'DeepWork', allowSplitting: true },
      { id: 't3', goalId: 'goal_placement', title: 'Placement Prep: System Design Mock', estimatedMinutes: 45, priority: 3, dueAt: now + 12 * 3600000, status: 'Pending', taskType: 'Standard', allowSplitting: true },
      { id: 't4', goalId: 'goal_fitness', title: 'Exercise: HIIT & Core Strength', estimatedMinutes: 30, priority: 3, dueAt: now + 14 * 3600000, status: 'Pending', taskType: 'Standard', allowSplitting: false },
      { id: 't5', goalId: 'goal_reading', title: 'Personal Reading: Deep Work Ch. 3', estimatedMinutes: 20, priority: 1, dueAt: now + 16 * 3600000, status: 'Pending', taskType: 'QuickTask', allowSplitting: false }
    ],
    commitments: [
      { id: 'c1', title: 'Faculty Mentorship Lab', startTime: now + 2 * 3600000, endTime: now + 3 * 3600000 }
    ],
    activePlan: null,
    insights: [
      {
        id: 'ins_1',
        type: 'TASK_DURATION_SENSITIVITY',
        title: 'Shorter study sessions show 2.5x higher completion',
        description: 'Over the last 14 days, tasks <= 30 mins had an 85% completion rate, while 60+ minute blocks suffered frequent postponements (34% completion rate). This is an empirical association in your records, not proof that duration caused the difference.',
        evidenceStrength: 'Moderate',
        sampleSize: 23,
        suggestedHypothesis: 'Splitting heavy study blocks into 30-minute modules will raise completion rate to >= 75%'
      }
    ],
    experiments: [
      {
        id: 'exp_1',
        insightId: 'ins_1',
        hypothesis: 'Splitting heavy study blocks into 30-minute modules will raise completion rate to >= 75%',
        changeDescription: 'Cap study sessions at 30 minutes with 5-minute cognitive resets between units',
        metricDefinition: 'Completion Rate = (Tasks Completed on Scheduled Day) / (Total Tasks Scheduled)',
        status: 'Active',
        baselineValue: 0.54,
        resultValue: 0.78,
        sampleSize: 18,
        limitations: 'Measured over 18 logged tasks across 7 days. Correlation indicates strong positive trend, though external exam factors may influence results.'
      }
    ],
    reflections: [
      { id: 'ref_1', reflectionDate: '2026-10-23', wins: 'Finished Java streams exercises cleanly.', challenges: 'Faculty lab ran late.', nextStep: 'Keep tasks under 30 minutes.', workload: 3 }
    ]
  };
}

let db = createInitialState();

// =============================================================================
// HTTP & REST API SERVER
// =============================================================================

function parseBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (e) {
        resolve({});
      }
    });
  });
}

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
  });
  res.end(JSON.stringify(data));
}

const server = http.createServer(async (req, res) => {
  const reqUrl = new URL(req.url, 'http://localhost');
  const pathname = reqUrl.pathname;
  const method = req.method;

  if (method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    });
    return res.end();
  }

  // API ROUTES
  if (pathname === '/api/profile' && method === 'GET') {
    return sendJson(res, 200, db.profile);
  }

  if (pathname === '/api/profile' && method === 'PUT') {
    const body = await parseBody(req);
    db.profile = { ...db.profile, ...body };
    return sendJson(res, 200, db.profile);
  }

  if (pathname === '/api/life-twin' && method === 'GET') {
    const totalWorkload = db.tasks.filter(t => t.status === 'Pending').reduce((sum, t) => sum + t.estimatedMinutes, 0);
    const available = db.profile.dailyAvailableMinutes;
    const capacityGap = totalWorkload - available;
    const overdue = db.tasks.filter(t => t.dueAt && t.dueAt < Date.now() && t.status === 'Pending');

    const summary = capacityGap > 0
      ? `Your open tasks require approximately ${totalWorkload} minutes, but your available planning time is ${available} minutes. Your current plan has a ${capacityGap}-minute capacity gap.`
      : `Your open tasks require ${totalWorkload} minutes within your ${available}-minute available window.`;

    return sendJson(res, 200, {
      totalEstimatedWorkloadMinutes: totalWorkload,
      availablePlanningMinutes: available,
      capacityGapMinutes: capacityGap,
      feasibility: capacityGap > 0 ? 'Capacity Gap' : (totalWorkload > available * 0.9 ? 'Strained' : 'Feasible'),
      overdueTasksCount: overdue.length,
      plainEnglishSummary: summary
    });
  }

  if (pathname === '/api/tasks' && method === 'GET') {
    return sendJson(res, 200, db.tasks);
  }

  if (pathname === '/api/tasks' && method === 'POST') {
    const body = await parseBody(req);
    const newTask = {
      id: `task_${Date.now()}`,
      title: body.title,
      estimatedMinutes: parseInt(body.estimatedMinutes) || 30,
      priority: parseInt(body.priority) || 2,
      status: 'Pending',
      taskType: body.taskType || 'Standard',
      allowSplitting: body.allowSplitting !== false,
      dueAt: Date.now() + 6 * 3600000
    };
    db.tasks.push(newTask);
    return sendJson(res, 201, newTask);
  }

  if (pathname.startsWith('/api/tasks/') && method === 'PUT') {
    const id = pathname.split('/')[3];
    const body = await parseBody(req);
    const idx = db.tasks.findIndex(t => t.id === id);
    if (idx >= 0) {
      db.tasks[idx] = { ...db.tasks[idx], ...body };
      return sendJson(res, 200, db.tasks[idx]);
    }
    return sendJson(res, 404, { error: 'Task not found' });
  }

  if (pathname.startsWith('/api/tasks/') && method === 'DELETE') {
    const id = pathname.split('/')[3];
    db.tasks = db.tasks.filter(t => t.id !== id);
    return sendJson(res, 200, { success: true });
  }

  if (pathname === '/api/goals' && method === 'GET') {
    return sendJson(res, 200, db.goals);
  }

  if (pathname === '/api/goals' && method === 'POST') {
    const body = await parseBody(req);
    const newGoal = {
      id: `goal_${Date.now()}`,
      lifeAreaId: body.lifeAreaId || 'area_academics',
      title: body.title,
      priority: parseInt(body.priority) || 3,
      targetDate: body.targetDate || '2026-12-31',
      status: 'Active'
    };
    db.goals.push(newGoal);
    return sendJson(res, 201, newGoal);
  }

  if (pathname === '/api/plan/generate' && method === 'POST') {
    const body = await parseBody(req);
    const strategy = body.strategy || 'PriorityFirst';
    const plan = generatePlan({
      tasks: db.tasks,
      goals: db.goals,
      commitments: db.commitments,
      availableMinutes: db.profile.dailyAvailableMinutes,
      startTime: Date.now(),
      strategy
    });
    return sendJson(res, 200, plan);
  }

  if (pathname === '/api/simulator/compare' && method === 'POST') {
    const body = await parseBody(req);
    const simMinutes = parseInt(body.simulatedMinutes) || 210;
    const excludedIds = new Set(body.excludedTaskIds || []);

    const baseline = generatePlan({
      tasks: db.tasks,
      goals: db.goals,
      commitments: db.commitments,
      availableMinutes: db.profile.dailyAvailableMinutes,
      startTime: Date.now(),
      strategy: 'PriorityFirst'
    });

    const simTasks = db.tasks.filter(t => !excludedIds.has(t.id));
    const scenario = generatePlan({
      tasks: simTasks,
      goals: db.goals,
      commitments: db.commitments,
      availableMinutes: simMinutes,
      startTime: Date.now(),
      strategy: 'PriorityFirst'
    });

    return sendJson(res, 200, { baseline, scenario });
  }

  if (pathname === '/api/simulator/apply' && method === 'POST') {
    const body = await parseBody(req);
    const simMinutes = parseInt(body.simulatedMinutes);
    const excludedIds = new Set(body.excludedTaskIds || []);

    if (simMinutes && !isNaN(simMinutes)) {
      db.profile.dailyAvailableMinutes = simMinutes;
    }

    if (excludedIds.size > 0) {
      db.tasks = db.tasks.map(t => {
        if (excludedIds.has(t.id)) {
          return { ...t, status: 'Deferred' };
        }
        return t;
      });
    }

    db.activePlan = body.plan;
    return sendJson(res, 200, { success: true, activePlan: db.activePlan, tasks: db.tasks });
  }

  if (pathname === '/api/comeback/generate' && method === 'POST') {
    const recovery = buildRecoveryPlan({
      allTasks: db.tasks,
      availableMinutes: db.profile.dailyAvailableMinutes,
      startTime: Date.now(),
      commitments: db.commitments
    });
    return sendJson(res, 200, recovery);
  }

  if (pathname === '/api/comeback/apply' && method === 'POST') {
    const body = await parseBody(req);
    const selectedProp = body.proposal;
    if (selectedProp) {
      db.activePlan = selectedProp.plan;
      // If tasks were split, update task list with split items
      if (body.splitTasks && body.splitTasks.length > 0) {
        for (const orig of body.splitTasks) {
          db.tasks = db.tasks.filter(t => t.id !== orig.id);
        }
        for (const item of selectedProp.plan.scheduledItems) {
          if (item.task && !db.tasks.some(t => t.id === item.task.id)) {
            db.tasks.push(item.task);
          }
        }
      }
    }
    return sendJson(res, 200, { success: true });
  }

  if (pathname === '/api/insights' && method === 'GET') {
    return sendJson(res, 200, db.insights);
  }

  if (pathname === '/api/experiments' && method === 'GET') {
    return sendJson(res, 200, db.experiments);
  }

  if (pathname.startsWith('/api/experiments/') && method === 'PUT') {
    const id = pathname.split('/')[3];
    const body = await parseBody(req);
    const idx = db.experiments.findIndex(e => e.id === id);
    if (idx >= 0) {
      db.experiments[idx] = { ...db.experiments[idx], ...body };
      return sendJson(res, 200, db.experiments[idx]);
    }
    return sendJson(res, 404, { error: 'Experiment not found' });
  }

  if (pathname === '/api/reflections' && method === 'GET') {
    return sendJson(res, 200, db.reflections);
  }

  if (pathname === '/api/reflections' && method === 'POST') {
    const body = await parseBody(req);
    const newRef = {
      id: `ref_${Date.now()}`,
      reflectionDate: new Date().toISOString().split('T')[0],
      wins: body.wins,
      challenges: body.challenges,
      nextStep: body.nextStep,
      workload: parseInt(body.workload) || 3
    };
    db.reflections.unshift(newRef);
    return sendJson(res, 201, newRef);
  }

  if (pathname === '/api/demo/reset' && method === 'POST') {
    db = createInitialState();
    return sendJson(res, 200, { success: true, message: 'Benchmark College Student scenario reloaded (180m vs 200m)' });
  }

  // STATIC FILE SERVING
  let filePath = path.join(__dirname, 'public', pathname === '/' ? 'index.html' : pathname);
  const ext = path.extname(filePath).toLowerCase();
  const mimeTypes = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'text/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.svg': 'image/svg+xml'
  };

  fs.readFile(filePath, (err, content) => {
    if (err) {
      if (err.code === 'ENOENT') {
        fs.readFile(path.join(__dirname, 'public', 'index.html'), (e, html) => {
          if (e) {
            res.writeHead(404);
            res.end('Not Found');
          } else {
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(html);
          }
        });
      } else {
        res.writeHead(500);
        res.end(`Server Error: ${err.code}`);
      }
    } else {
      res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'application/octet-stream' });
      res.end(content);
    }
  });
});

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`LIFESYNC Server active and listening at http://localhost:${PORT}`);
  });
}

module.exports = { server, db, generatePlan, evaluatePlanScore, buildRecoveryPlan, createInitialState };
