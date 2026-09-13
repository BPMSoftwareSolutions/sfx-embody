import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import assert from 'node:assert/strict';
import { planNode } from '../src/materialize-node.mjs';
import { loadMemoryScenario } from '../src/load-memory-scenario.mjs';

function fixturesFrom(bundle) {
  const record = bundle.authority.recordsets.flat().find(row => row.source_path?.endsWith('/fixtures.authority.json'));
  assert.ok(record, 'Declared fixture authority is required');
  return JSON.parse(Buffer.from(record.content_bytes.base64, 'base64')).fixtures;
}

export async function verifyDeclaredFixtures(declaration, test, context) {
  const baseline = JSON.parse(await fs.readFile(test.baselineBundleFile, 'utf8'));
  const originals = fixturesFrom(baseline), fixtures = fixturesFrom(declaration);
  assert.equal(fixtures.length, originals.length, 'Retained fixture count');
  const plan = await planNode({ bundle: { ...declaration, selection: {
    capabilityId: declaration.capabilityId, scenarioId: declaration.scenarioId, target: declaration.target
  } }, sdaRoot: context.sdaRoot });
  const runtime = await loadMemoryScenario(plan);
  const { satisfies, valueAt } = await import(pathToFileURL(path.join(context.sdaRoot,
    'artifacts/tools/dist/consumer-projection/proof/assertion-evaluator.js')).href);
  const evidence = [];
  for (const fixture of fixtures) {
    const original = originals.find(value => value.fixtureId === fixture.fixtureId);
    assert.deepEqual(fixture, original, fixture.fixtureId + ': retained fixture');
    assert.equal(JSON.stringify(fixture.input), JSON.stringify(original.input), fixture.fixtureId + ': input member order');
    const input = structuredClone(fixture.input);
    const scenario = await runtime.createScenario({ observer: { observe() {} }, clock: { now: () => '2026-09-13T00:00:00.000Z' } });
    const result = await scenario.execute(input, { executionId: fixture.fixtureId, rootExecutionId: fixture.fixtureId,
      rootInput: structuredClone(input), ancestry: [plan.selectedScenarioId], collect() {} });
    assert.deepEqual(input, fixture.input, fixture.fixtureId + ': input mutation');
    assert.equal(result.disposition, fixture.expected.disposition, fixture.fixtureId + ': disposition');
    for (const assertion of fixture.expected.outcomeAssertions)
      assert.ok(satisfies(valueAt(result.outcome, assertion.path), assertion), fixture.fixtureId + ': ' + assertion.path);
    evidence.push({ fixtureId: fixture.fixtureId, disposition: result.disposition, outcome: result.outcome });
  }
  const verification = { disposition: 'PASSED', capabilityId: declaration.capabilityId, fixtures: evidence };
  if (test.evidenceFile) await fs.writeFile(test.evidenceFile, JSON.stringify(verification, null, 2) + '\n');
  return verification;
}
