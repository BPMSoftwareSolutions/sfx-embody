import fs from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { fileURLToPath, pathToFileURL } from 'node:url';
import assert from 'node:assert/strict';
import { readAuthority } from './read-authority.mjs';
import { planNode } from './materialize-node.mjs';
import { loadMemoryScenario } from './load-memory-scenario.mjs';

const hash = value => 'sha256:' + createHash('sha256').update(value).digest('hex');
export const preparationApi = async databaseRoot => import(pathToFileURL(path.join(databaseRoot, 'src/runtime/preparation.mjs')));

// Conservative identity of the preparation/execution adapter and query recipe.
// The selected database generation covers declaration dependencies; plan proof
// separately covers the exact installed platform bytes used for compilation.
export async function preparationRecipe({ databaseRoot, sdaRoot }) {
  const sources = [];
  const collect = async (root, prefix) => {
    for (const entry of (await fs.readdir(root, { withFileTypes: true })).sort((a, b) => a.name < b.name ? -1 : 1)) {
      const file = path.join(root, entry.name), name = prefix + '/' + entry.name;
      if (entry.isDirectory()) await collect(file, name);
      else if (entry.name.endsWith('.mjs')) sources.push([name, hash(await fs.readFile(file))]);
    }
  };
  await collect(fileURLToPath(new URL('.', import.meta.url)), 'provider');
  for (const dir of ['src/query', 'src/runtime']) await collect(path.join(databaseRoot, dir), 'database/' + dir);
  for (const relative of ['src/core.mjs', 'src/ingest/database.mjs', 'sql/diagnostics/capability-embodiment.sql',
    'sql/diagnostics/scenario-resolver-map.sql', 'sql/runtime/select-capability.sql', 'sql/runtime/read-preparation.sql'])
    sources.push(['database/' + relative, hash(await fs.readFile(path.join(databaseRoot, relative)))]);
  sources.push(['assertion-evaluator', hash(await fs.readFile(path.join(sdaRoot, 'artifacts/tools/dist/consumer-projection/proof/assertion-evaluator.js')))]);
  const { dependencies } = JSON.parse(await fs.readFile(new URL('../package.json', import.meta.url), 'utf8'));
  return hash(JSON.stringify({ format: 'sfx-preparation-recipe.v1', sources, dependencies, node: process.version, platform: process.platform, arch: process.arch }));
}

export function planArtifacts(plan) {
  return plan.receipts.map(({ plan: item, receipt }) => ({ scenarioId: item.scenarioId,
    ...Object.fromEntries(['scenarioDefinitionDigest', 'pinnedPlatformCommit', 'platformDigest', 'resolverVersion', 'artifactDigest'].map(key => [key, receipt[key]]))
  })).sort((a, b) => a.scenarioId < b.scenarioId ? -1 : 1);
}

export async function proveMemoryPlan(plan, sdaRoot) {
  const entry = plan.receipts.find(r => r.plan.scenarioId === plan.selectedScenarioId);
  const fixtures = JSON.parse(plan.files.find(f => f.relativePath === entry.base + '/evidence/fixture-authority.json').content).fixtures;
  if (!fixtures?.length) throw new Error('PREPARATION_FIXTURES_REQUIRED');
  const runtime = await loadMemoryScenario(plan);
  const { satisfies, valueAt } = await import(pathToFileURL(path.join(sdaRoot, 'artifacts/tools/dist/consumer-projection/proof/assertion-evaluator.js')));
  const results = [];
  for (const fixture of fixtures) {
    try {
      const executions = [], observations = [];
      // Stable test clock, as opposed to invocation's actual observation clock.
      const scenario = runtime.createScenario({ observer: { observe: value => observations.push(value) }, clock: { now: () => '2000-01-01T00:00:00.000Z' } });
      const input = structuredClone(fixture.input);
      const result = await scenario.execute(input, { executionId: fixture.fixtureId, rootExecutionId: fixture.fixtureId,
        rootInput: structuredClone(input), ancestry: [plan.selectedScenarioId], collect: value => executions.push(value) });
      assert.deepEqual(input, fixture.input);
      assert.equal(result.disposition, fixture.expected.disposition);
      assert.equal(result.scenarioId, fixture.expected.terminalScenarioId);
      assert.deepEqual(executions.filter(e => e.parentExecutionId === null).map(e => e.scenarioId), fixture.expected.scenarioSequence);
      for (const assertion of fixture.expected.outcomeAssertions) assert(satisfies(valueAt(result.outcome, assertion.path), assertion));
      for (const execution of executions) assert.deepEqual(observations.filter(o => o.executionId === execution.executionId).map(o => [o.sequence, o.status]), [0, 1, 2, 3, 4].map(i => [i, 'observed']));
      results.push({ fixtureId: fixture.fixtureId, assertionCount: fixture.expected.outcomeAssertions.length,
        observationCount: observations.length, inputDigest: hash(JSON.stringify(fixture.input)), outcomeDigest: hash(JSON.stringify(result.outcome)), disposition: result.disposition });
    } catch (error) { throw new Error('PREPARATION_FIXTURE_FAILED:' + fixture.fixtureId + ': ' + error.message); }
  }
  return { status: 'PASSED', scope: 'DATABASE_RETAINED_FIXTURES', fixtureCount: results.length,
    assertionCount: results.reduce((n, r) => n + r.assertionCount, 0), observationCount: results.reduce((n, r) => n + r.observationCount, 0),
    artifacts: planArtifacts(plan), fixtures: results };
}

export async function prepareDatabaseCapability(selection, config, measure, timings) {
  const recipeDigest = await preparationRecipe(config);
  const bundle = await measure('readAuthority', () => readAuthority(config.databaseRoot, selection, { retainObjects: false, timings: timings.queries }));
  const plan = await measure('planNativeBody', () => planNode({ bundle, sdaRoot: config.sdaRoot }));
  const proof = await measure('proveRetainedFixtures', () => proveMemoryPlan(plan, config.sdaRoot));
  // Do not publish if the local implementation changed during a long derivation.
  if (await preparationRecipe(config) !== recipeDigest) throw new Error('PREPARATION_RECIPE_CHANGED');
  const { storePreparation, preparationFormat } = await preparationApi(config.databaseRoot);
  const stored = await measure('storePreparation', () => storePreparation({ preparationType: preparationFormat, recipeDigest, bundle, proof }));
  return { disposition: 'terminated', outcome: { capabilityId: plan.capabilityId, scenarioId: plan.selectedScenarioId,
    disposition: 'CAPABILITY_PREPARED', ...stored, proof,
    evidence: { timings, authoritySource: 'DATABASE', preparationStorage: 'DATABASE', bodyStorage: 'MEMORY_ONLY',
      managedAdmission: 'NOT_REQUESTED', providerStatus: 'CANDIDATE_PHYSICAL_PROVIDER', recipeDigest,
      snapshotId: bundle.authority.snapshotId, projectionDigest: bundle.authority.projectionDigest,
      queries: [bundle.authority, bundle.resolutions, bundle.mechanics].map(({ recordsets, ...identity }) => identity) } } };
}
