// Execution-only dependency proof against independently captured installed-CLI runs.
// Reusing their execution IDs permits exact comparison; these are not new service run IDs.
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { loadMemoryScenario } from './load-memory-scenario.mjs';

const hash = bytes => 'sha256:' + createHash('sha256').update(bytes).digest('hex');
const pilots = JSON.parse(await fs.readFile('cases.json', 'utf8'));
const withoutClock = observations => observations.map(({ observedAt, ...value }) => value);
const results = [];
for (const pilot of pilots) {
  const bytes = await fs.readFile(pilot.planFile);
  assert.equal(hash(bytes), pilot.planDigest, 'PACKAGED_PLAN_DIGEST_CHANGED');
  const plan = JSON.parse(bytes);
  const runtime = await loadMemoryScenario(plan);
  assert.deepEqual(runtime.modules, pilot.modules, 'CLI_MODULES_CHANGED');
  for (const fixture of pilot.cases) {
    const executions = [], observations = [];
    const scenario = runtime.createScenario({ observer: { observe: v => observations.push(v) },
      clock: { now: () => '2000-01-01T00:00:00.000Z' } });
    const input = structuredClone(fixture.input);
    const executionId = fixture.expected.result.executionId;
    const result = await scenario.execute(input, { executionId, rootExecutionId: executionId,
      rootInput: structuredClone(input), ancestry: [plan.selectedScenarioId], collect: v => executions.push(v) });
    assert.deepEqual(input, fixture.input, 'INPUT_MUTATED');
    assert.deepEqual(result, fixture.expected.result, fixture.fixtureId + ':RESULT');
    assert.deepEqual(executions, fixture.expected.executions, fixture.fixtureId + ':EXECUTIONS');
    assert.deepEqual(withoutClock(observations), withoutClock(fixture.expected.observations), fixture.fixtureId + ':OBSERVATIONS');
    results.push({ capabilityId: plan.capabilityId, fixtureId: fixture.fixtureId, status: 'PASSED',
      kernelDisposition: result.disposition, domainDisposition: result.outcome?.disposition ?? null });
  }
  const tampered = structuredClone(plan);
  tampered.files[0].content += '\n// changed bytes';
  await assert.rejects(() => loadMemoryScenario(tampered), /MEMORY_RESOURCE_DIGEST_MISMATCH/);
}
console.log(JSON.stringify({ status: 'PASSED', node: process.version, platform: process.platform, architecture: process.arch,
  passed: results.length, integrityRefusals: pilots.length, cases: results,
  scope: 'Packaged native-body execution parity with retained CLI results, executions and observations (excluding observation timestamps). Not the database selection/planning service or production isolation qualification.' }, null, 2));
