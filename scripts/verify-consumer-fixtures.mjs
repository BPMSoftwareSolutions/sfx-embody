import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { executeEstateCapability } from '../src/invoke-database-capability.mjs';
import { readConsumerEmbodimentPlan } from '../src/resolvers/node/consumer-plan-provider.mjs';
import { executeConsumerPlan } from '../src/resolvers/node/consumer-execution-provider.mjs';
import { planNode } from '../src/materialize-node.mjs';
import { loadMemoryScenario } from '../src/load-memory-scenario.mjs';

const digest = value => 'sha256:' + createHash('sha256').update(JSON.stringify(value)).digest('hex');

export async function readFixtureConsumerPlan(declaration, context) {
  const bindings = await executeEstateCapability({ capabilityId: 'resolve-provider-slot-bindings' }, declaration, context);
  assert.equal(bindings.disposition, 'PROVIDER_SLOTS_BOUND');
  const query = context.readQuery ?? (await import(pathToFileURL(path.join(context.databaseRoot, 'src/query/run.mjs')).href)).query;
  const result = await query(`SELECT definition_json FROM analysis.v_selected_semantic_definition
    WHERE estate_model_pk=@estate_model_pk AND object_kind='PORT'
    AND namespace_id='sidefx:capability:plan-capability-embodiment'`, { input: {} });
  assert.equal(result.recordsets[0].length, 1);
  const providers = JSON.parse(result.recordsets[0][0].definition_json).semantics.configuration.planningProviders;
  const selected = providers.filter(provider => bindings.profiles.some(profile => profile.providerProfileId === provider.providerProfileId));
  assert.equal(selected.length, 1);
  const read = await readConsumerEmbodimentPlan(selected[0].configuration, bindings, context);
  const base = [selected[0].configuration.relativeRoot, declaration.capabilityId, 'scenarios', declaration.scenarioId, declaration.target].join('/');
  return { ...read, bindingPath: base + '/' + selected[0].configuration.files.binding };
}

export async function verifyConsumerFixtures(declaration, test, context) {
  const read = await readFixtureConsumerPlan(declaration, context);
  const baselineBundle = JSON.parse(await fs.readFile(test.baselineBundleFile, 'utf8'));
  const baselinePlan = await planNode({ bundle: baselineBundle, sdaRoot: context.sdaRoot });
  const baseline = await loadMemoryScenario(baselinePlan);
  const { satisfies, valueAt } = await import(pathToFileURL(path.join(context.sdaRoot,
    'artifacts/tools/dist/consumer-projection/proof/assertion-evaluator.js')).href);
  const fixtures = read.fixtureAuthority.fixtures;
  const evidence = [];
  for (const fixture of fixtures) {
    const input = structuredClone(fixture.input);
    const baselineScenario = await baseline.createScenario({ observer: { observe() {} }, clock: { now: () => '2026-09-13T00:00:00.000Z' } });
    const expected = await baselineScenario.execute(structuredClone(input), { executionId: fixture.fixtureId,
      rootExecutionId: fixture.fixtureId, rootInput: structuredClone(input), ancestry: [baselinePlan.selectedScenarioId], collect() {} });
    const observed = await executeConsumerPlan({}, { ...read, scenarioInput: input }, { ...context, rootExecutionId: fixture.fixtureId });
    assert.deepEqual(input, fixture.input, fixture.fixtureId + ': input mutation');
    assert.equal(expected.disposition, fixture.expected.disposition, fixture.fixtureId + ': baseline disposition');
    // A terminal Scenario execution and a completed graph report the same
    // admitted outcome through their respective existing execution protocols.
    assert.equal(observed.result.disposition, expected.disposition === 'terminated' ? 'completed' : expected.disposition,
      fixture.fixtureId + ': native graph disposition');
    assert.deepEqual(observed.result.outcome, expected.outcome, fixture.fixtureId + ': baseline outcome');
    for (const assertion of fixture.expected.outcomeAssertions)
      assert.ok(satisfies(valueAt(observed.result.outcome, assertion.path), assertion), fixture.fixtureId + ': ' + assertion.path);
    evidence.push({ fixtureId: fixture.fixtureId, disposition: fixture.expected.disposition,
      outcomeDigest: digest(observed.result.outcome), observedPathDigest: observed.result.observedPathDigest });
  }
  const verification = { disposition: 'PASSED', capabilityId: declaration.capabilityId, target: declaration.target,
    planDigest: read.result.planDigest, artifactDigest: read.result.artifactDigest, fixtures: evidence };
  if (test.evidenceFile) await fs.writeFile(test.evidenceFile, JSON.stringify(verification, null, 2) + '\n');
  return verification;
}
