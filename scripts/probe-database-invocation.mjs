import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
import childProcess from 'node:child_process';
import { syncBuiltinESMExports } from 'node:module';
import { pathToFileURL } from 'node:url';
import { readAuthority } from '../src/read-authority.mjs';
import { planNode, writeNodePlan } from '../src/materialize-node.mjs';
import { loadMemoryScenario } from '../src/load-memory-scenario.mjs';
import { readWorkspaceConfig } from '../src/read-workspace-config.mjs';

// Investigation/proof entry, not a managed CLI capability binding. In memory
// mode run under Node's filesystem write restriction. Only stdout leaves it.
const [configFile, capabilityId, mode = 'memory', expandedRoot] = process.argv.slice(2);
try {
  assert(['memory', 'expanded'].includes(mode), 'MODE_REQUIRED');
  const config = await readWorkspaceConfig(configFile);
  const selections = await Promise.all(config.cases.map(async c => JSON.parse(await fsp.readFile(c.selectionFile, 'utf8'))));
  const selection = selections.find(s => s.capabilityId === capabilityId);
  assert(selection, 'SELECTED_CAPABILITY_NOT_CONFIGURED');
  const childCalls = [];
  if (mode === 'memory') {
    assert.equal(process.permission?.has('fs.write'), false, 'FILESYSTEM_WRITES_MUST_BE_DISABLED');
    assert.equal(process.permission.has('fs.read', path.resolve('embodiments')), false, 'EXPANDED_BODY_READS_MUST_BE_DISABLED');
    assert.equal(process.permission.has('fs.read', path.join(config.databaseRoot, 'data')), false, 'DATABASE_CACHE_READS_MUST_BE_DISABLED');
    const execFileSync = childProcess.execFileSync;
    const permitted = [
      ['rev-parse', 'HEAD'],
      ['diff', '--name-only', null, '--', 'tools/src', 'languages/typescript', 'package.json'],
      ['ls-files', '--others', '--exclude-standard', '--', 'tools/src', 'languages/typescript', 'package.json']
    ];
    childProcess.execFileSync = (file, args, options) => {
      assert.equal(file, 'git', 'ONLY_PLATFORM_GIT_READS_ALLOWED');
      assert.equal(path.resolve(options.cwd), path.resolve(config.sdaRoot));
      assert(permitted.some(pattern => pattern.length === args.length && pattern.every((value, i) => value === null ? /^[0-9a-f]{40}$/.test(args[i]) : value === args[i])), 'CHILD_COMMAND_UNBOUND');
      childCalls.push({ executable: file, args, cwd: options.cwd });
      return execFileSync(file, args, options);
    };
    for (const key of ['exec', 'execSync', 'execFile', 'spawn', 'spawnSync', 'fork']) {
      childProcess[key] = () => { throw new Error('CHILD_PROCESS_UNBOUND:' + key); };
    }
    syncBuiltinESMExports();
  }
  console.error(JSON.stringify({ stage: 'read-database', capabilityId, mode }));
  const bundle = await readAuthority(config.databaseRoot, selection, { retainObjects: false });
  for (const result of [bundle.authority, bundle.resolutions, bundle.mechanics]) assert.equal(result.objectRetention, 'MEMORY_ONLY');
  console.error(JSON.stringify({ stage: 'plan-native-body', capabilityId, mode }));
  const plan = await planNode({ bundle, sdaRoot: config.sdaRoot });
  const entry = plan.receipts.find(r => r.plan.scenarioId === selection.scenarioId);
  const fixtureAuthority = JSON.parse(plan.files.find(f => f.relativePath === entry.base + '/evidence/fixture-authority.json').content);
  let runtime;
  if (mode === 'expanded') {
    assert(expandedRoot, 'EXPANDED_ROOT_REQUIRED');
    await writeNodePlan({ plan, outputRoot: path.resolve(expandedRoot) });
    runtime = await import(pathToFileURL(path.resolve(expandedRoot, entry.base, 'body/composition.mjs')));
  } else {
    runtime = await loadMemoryScenario(plan);
  }
  const { satisfies, valueAt } = await import(pathToFileURL(path.join(config.sdaRoot, 'artifacts/tools/dist/consumer-projection/proof/assertion-evaluator.js')));
  const results = [];
  for (const fixture of fixtureAuthority.fixtures) {
    const observations = [], executions = [];
    const scenario = runtime.createScenario({ observer: { observe: value => observations.push(value) }, clock: { now: () => new Date().toISOString() } });
    const input = structuredClone(fixture.input);
    const result = await scenario.execute(input, { executionId: fixture.fixtureId, rootExecutionId: fixture.fixtureId,
      rootInput: structuredClone(input), ancestry: [selection.scenarioId], collect: value => executions.push(value) });
    assert.deepEqual(input, fixture.input);
    assert.equal(result.disposition, fixture.expected.disposition);
    assert.equal(result.scenarioId, fixture.expected.terminalScenarioId);
    assert.deepEqual(executions.filter(e => e.parentExecutionId === null).map(e => e.scenarioId), fixture.expected.scenarioSequence);
    const assertions = fixture.expected.outcomeAssertions.map(a => ({ ...a, actual: valueAt(result.outcome, a.path), passed: satisfies(valueAt(result.outcome, a.path), a) }));
    assert(assertions.every(a => a.passed), 'FIXTURE_OUTCOME_DIVERGED:' + fixture.fixtureId);
    for (const execution of executions) assert.deepEqual(observations.filter(o => o.executionId === execution.executionId).map(o => [o.sequence, o.status]), [0, 1, 2, 3, 4].map(i => [i, 'observed']));
    results.push({ fixtureId: fixture.fixtureId, result, assertions, executions, observations });
  }
  const negativeObservations = [];
  const invalid = runtime.createScenario({ observer: { observe: o => negativeObservations.push(o) }, clock: { now: () => new Date().toISOString() } });
  const rejected = await invalid.execute(null, { executionId: 'invalid-input', rootExecutionId: 'invalid-input', rootInput: null });
  assert.equal(rejected.disposition, 'rejected');
  let writeDenied = null, expandedReadDenied = null;
  if (mode === 'memory') {
    assert.throws(() => fs.writeFileSync(path.resolve('forbidden-capability-write.txt'), 'denied'), error => { writeDenied = error.code; return error.code === 'ERR_ACCESS_DENIED'; });
    assert.throws(() => fs.readFileSync(path.resolve('embodiments', capabilityId, 'scenarios', selection.scenarioId, 'node/body/scenario.mjs')), error => { expandedReadDenied = error.code; return error.code === 'ERR_ACCESS_DENIED'; });
    const corrupt = structuredClone(plan);
    corrupt.files.find(f => f.relativePath.endsWith('/body/scenario.mjs')).content += '\n// tampered';
    await assert.rejects(loadMemoryScenario(corrupt), /MEMORY_RESOURCE_DIGEST_MISMATCH/);
    const missing = { ...plan, files: plan.files.filter(f => !f.relativePath.endsWith('/body/scenario.mjs')) };
    await assert.rejects(loadMemoryScenario(missing), /MEMORY_RESOURCE_UNAVAILABLE/);
  }
  console.log(JSON.stringify({ disposition: 'PASSED', mode, capabilityId, scenarioId: selection.scenarioId,
    snapshotId: bundle.authority.snapshotId, projectionDigest: bundle.authority.projectionDigest,
    authorityIdentity: Object.fromEntries(['scenarioDefinitionDigest', 'pinnedPlatformCommit', 'platformDigest', 'resolverVersion', 'artifactDigest'].map(key => [key, entry.receipt[key]])),
    queryEvidence: [bundle.authority, bundle.resolutions, bundle.mechanics].map(({ recordsets, ...evidence }) => evidence),
    sourceScope: { retainedCapabilitySources: bundle.authority.recordsets[1].length, retainedPlatformSources: bundle.authority.recordsets[2].length },
    bodyFiles: plan.files.filter(f => f.relativePath.includes('/body/')).map(({ content, ...file }) => file),
    fixtureCount: results.length, assertionCount: results.reduce((n, r) => n + r.assertions.length, 0),
    kernelObservationCount: results.reduce((n, r) => n + r.observations.length, 0), results,
    negativeInput: { result: rejected, observations: negativeObservations },
    memoryEvidence: mode === 'memory' ? { fsWriteAllowed: process.permission.has('fs.write'), expandedBodyReadAllowed: false,
      databaseCacheReadAllowed: false, writeDenied, expandedReadDenied, tamperedSourceRejected: true, missingSourceRejected: true,
      childCalls, modules: runtime.modules, accesses: runtime.accesses, externalDependencies: runtime.externalDependencies } : null,
    scope: 'INVESTIGATION_ONLY: selected database authority, candidate Node body/load provider, retained fixture inputs; not managed admission or universal coverage.'
  }, null, 2));
} catch (error) {
  console.error(JSON.stringify({ disposition: 'FAILED', mode, capabilityId, error: error.message, code: error.code ?? null }));
  process.exitCode = 1;
}
