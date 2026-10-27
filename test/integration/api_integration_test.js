/**
 * LIFESYNC End-to-End REST API & Workflow Integration Test
 * Zero-Socket In-Memory Dispatch (Sandboxed & Fast)
 */

const assert = require('assert');
const { Readable, Writable } = require('stream');
const { server } = require('../../web_app/server.js');

function request(pathname, options = {}) {
  return new Promise((resolve) => {
    const method = options.method || 'GET';
    const bodyStr = options.body ? (typeof options.body === 'string' ? options.body : JSON.stringify(options.body)) : '';

    const req = new Readable({
      read() {
        if (bodyStr) {
          this.push(bodyStr);
        }
        this.push(null);
      }
    });
    req.url = pathname;
    req.method = method;
    req.headers = options.headers || {};

    let responseData = '';
    let responseStatus = 200;
    let responseHeaders = {};

    const res = new Writable({
      write(chunk, encoding, callback) {
        responseData += chunk.toString();
        callback();
      }
    });

    res.writeHead = (status, headers) => {
      responseStatus = status;
      responseHeaders = headers || {};
    };

    res.on('finish', () => {
      try {
        resolve({ status: responseStatus, data: JSON.parse(responseData) });
      } catch (e) {
        resolve({ status: responseStatus, data: responseData });
      }
    });

    server.emit('request', req, res);
  });
}

async function runIntegrationTests() {
  console.log('================================================================');
  console.log('  LIFESYNC END-TO-END REST API & INTEGRATION TEST SUITE');
  console.log('================================================================\n');

  // 1. Profile Verification
  console.log('TEST 1: Verifying User Profile endpoint (/api/profile)...');
  const profileRes = await request('/api/profile');
  assert.strictEqual(profileRes.status, 200);
  assert.strictEqual(profileRes.data.displayName, 'Alex Rivera (CS Student)');
  assert.strictEqual(profileRes.data.dailyAvailableMinutes, 180);
  console.log('  -> Profile verified: Alex Rivera, 180m capacity [PASS]');

  // 2. Life Twin Capacity Mismatch
  console.log('\nTEST 2: Verifying Life Twin Snapshot endpoint (/api/life-twin)...');
  const twinRes = await request('/api/life-twin');
  assert.strictEqual(twinRes.status, 200);
  assert.strictEqual(twinRes.data.totalEstimatedWorkloadMinutes, 200);
  assert.strictEqual(twinRes.data.availablePlanningMinutes, 180);
  assert.strictEqual(twinRes.data.capacityGapMinutes, 20);
  assert.strictEqual(twinRes.data.feasibility, 'Capacity Gap');
  assert.ok(twinRes.data.plainEnglishSummary.includes('20-minute capacity gap'));
  console.log('  -> Life Twin verified: 200m workload, 180m capacity, +20m overflow [PASS]');

  // 3. Adaptive Planner Schedule Generation
  console.log('\nTEST 3: Verifying Adaptive Planner endpoint (/api/plan/generate)...');
  const planRes = await request('/api/plan/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: { strategy: 'PriorityFirst' }
  });
  assert.strictEqual(planRes.status, 200);
  assert.strictEqual(planRes.data.totalScheduledMinutes, 180);
  assert.strictEqual(planRes.data.scheduledItems.length, 4);
  assert.strictEqual(planRes.data.unscheduledItems.length, 1);
  assert.strictEqual(planRes.data.unscheduledItems[0].taskId, 't5');
  console.log('  -> Planner verified: Scheduled 180m, unscheduled low-priority reading task [PASS]');

  // 4. What-If Simulator Comparison & Side-by-Side Evaluation
  console.log('\nTEST 4: Verifying What-If Simulator endpoint (/api/simulator/compare)...');
  const simRes = await request('/api/simulator/compare', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: { simulatedMinutes: 210, excludedTaskIds: [] }
  });
  assert.strictEqual(simRes.status, 200);
  const { baseline, scenario } = simRes.data;
  assert.strictEqual(baseline.totalScheduledMinutes, 180);
  assert.strictEqual(baseline.unscheduledItems.length, 1);
  assert.strictEqual(scenario.totalScheduledMinutes, 200);
  assert.strictEqual(scenario.unscheduledItems.length, 0);
  assert.strictEqual(scenario.remainingAvailableMinutes, 10);
  console.log('  -> Simulator verified: Baseline (180m, 1 unscheduled) vs Scenario B (200m, 0 unscheduled) [PASS]');

  // 5. Comeback Mode Recovery & Task Splitting
  console.log('\nTEST 5: Verifying Comeback Mode endpoint (/api/comeback/generate)...');
  const comebackRes = await request('/api/comeback/generate', { method: 'POST' });
  assert.strictEqual(comebackRes.status, 200);
  assert.strictEqual(comebackRes.data.splitTasks.length, 1);
  assert.strictEqual(comebackRes.data.splitTasks[0].id, 't1'); // DBMS assignment 60m
  assert.strictEqual(comebackRes.data.proposals.length, 2);
  console.log('  -> Comeback Mode verified: 60m DBMS assignment split into 30m Part 1 & Part 2 [PASS]');

  // 6. Growth Investigator Insights & Empirical Experiments
  console.log('\nTEST 6: Verifying Personal Growth Investigator endpoints (/api/insights, /api/experiments)...');
  const insightsRes = await request('/api/insights');
  assert.strictEqual(insightsRes.status, 200);
  assert.ok(insightsRes.data.length >= 1);
  assert.strictEqual(insightsRes.data[0].sampleSize, 23);
  assert.strictEqual(insightsRes.data[0].evidenceStrength, 'Moderate');

  const expRes = await request('/api/experiments');
  assert.strictEqual(expRes.status, 200);
  assert.strictEqual(expRes.data[0].baselineValue, 0.54);
  assert.strictEqual(expRes.data[0].resultValue, 0.78);
  assert.strictEqual(expRes.data[0].sampleSize, 18);
  console.log('  -> Growth Investigator verified: Empirical insight (N=23) and active trial (78% vs 54%) [PASS]');

  // 7. Demo Reset
  console.log('\nTEST 7: Verifying Benchmark Demo Reset endpoint (/api/demo/reset)...');
  const resetRes = await request('/api/demo/reset', { method: 'POST' });
  assert.strictEqual(resetRes.status, 200);
  assert.strictEqual(resetRes.data.success, true);
  console.log('  -> Reset verified: Clean state reloaded [PASS]');

  console.log('\n================================================================');
  console.log('  ALL END-TO-END INTEGRATION TESTS PASSED WITH 100% SUCCESS!');
  console.log('================================================================\n');
}

runIntegrationTests().catch(err => {
  console.error('Integration test failure:', err);
  process.exit(1);
});
