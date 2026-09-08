import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import { planNode } from '../src/materialize-node.mjs';
import { loadMemoryScenario } from '../src/load-memory-scenario.mjs';
import { readWorkspaceConfig } from '../src/read-workspace-config.mjs';

const config = await readWorkspaceConfig(process.argv[2]);
const { satisfies, valueAt } = await import(pathToFileURL(path.join(config.sdaRoot, 'artifacts/tools/dist/consumer-projection/proof/assertion-evaluator.js')));
const cases = [];
for (const request of config.cases) {
  const bundle = JSON.parse(await fs.readFile(request.bundleFile, 'utf8'));
  const plan = await planNode({ bundle, sdaRoot: config.sdaRoot });
  const body = plan.files.filter(f => f.relativePath.includes('/body/'));
  for (const file of body) {
    const observed = 'sha256:' + crypto.createHash('sha256').update(await fs.readFile(file.relativePath)).digest('hex');
    assert.equal(observed, file.digest, file.relativePath);
  }
  const entry = plan.receipts.find(r => r.plan.scenarioId === plan.selectedScenarioId);
  const disk = await import(pathToFileURL(path.resolve(entry.base, 'body/composition.mjs')));
  const memory = await loadMemoryScenario(plan);
  const fixtures = JSON.parse(plan.files.find(f => f.relativePath === entry.base + '/evidence/fixture-authority.json').content).fixtures;
  let outcomeAssertions = 0, kernelObservations = 0;
  const run = async (runtime, fixture) => {
    const observations = [], executions = [];
    const scenario = runtime.createScenario({ observer: { observe: v => observations.push(v) }, clock: { now: () => new Date().toISOString() } });
    const input = structuredClone(fixture.input);
    const actual = await scenario.execute(input, { executionId: fixture.fixtureId, rootExecutionId: fixture.fixtureId,
      rootInput: structuredClone(input), ancestry: [plan.selectedScenarioId], collect: v => executions.push(v) });
    assert.deepEqual(input, fixture.input);
    return { actual, executions, observations: observations.map(({ observedAt, ...o }) => o) };
  };
  for (const fixture of fixtures) {
    const actual = await run(memory, fixture), expected = await run(disk, fixture);
    assert.deepEqual(actual, expected, fixture.fixtureId);
    assert.equal(actual.actual.disposition, fixture.expected.disposition);
    for (const assertion of fixture.expected.outcomeAssertions) {
      assert(satisfies(valueAt(actual.actual.outcome, assertion.path), assertion));
      outcomeAssertions++;
    }
    kernelObservations += actual.observations.length;
  }
  const invalid = { fixtureId: 'invalid-input', input: null };
  const rejected = await run(memory, invalid);
  assert.deepEqual(rejected, await run(disk, invalid));
  assert.equal(rejected.actual.disposition, 'rejected');
  cases.push({ capabilityId: plan.capabilityId, fixtures: fixtures.length, outcomeAssertions, kernelObservations,
    identicalBodyFiles: body.length, invalidInputParity: true, disposition: 'PASSED' });
}
console.log(JSON.stringify({ disposition: 'PASSED',
  scope: 'Retained database bundles: unchanged native bytes and complete disk/memory execution parity across configured capabilities. The separate live restricted-process proof covers the provider resolver.', cases }, null, 2));
