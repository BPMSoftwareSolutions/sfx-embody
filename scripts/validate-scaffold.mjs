// Validate a generated capability scaffold from disk, before it is registered.
//
// The gap this closes: a scaffold could be packed and registered without any
// fixture ever exercising it. `resolve-equity-market-price-evidence` was
// registered carrying `"fixtures": []`, so nothing failed and nothing ran.
//
// The scaffold owns its capability authorities, its feature and its fixtures.
// It does not own the pinned platform package, the node mechanic registry or
// the mechanic declarations, which belong to the estate. So this reads an
// authority bundle for the selected capability, replaces every scaffold-owned
// source record with the bytes on disk, and plans and executes from that.
//
//   node scripts/validate-scaffold.mjs <scaffold-dir> [config/database-runtime.json]
//
// Exits non-zero on the first fixture that does not satisfy its assertions.
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { readAuthority } from '../src/read-authority.mjs';
import { planNode } from '../src/materialize-node.mjs';
import { loadMemoryScenario } from '../src/load-memory-scenario.mjs';

const hash = bytes => 'sha256:' + crypto.createHash('sha256').update(bytes).digest('hex');
const json = text => JSON.parse(text.replace(/^﻿/, ''));

const scaffoldRoot = path.resolve(process.argv[2] ?? '');
const configFile = path.resolve(process.argv[3] ?? 'config/database-runtime.json');
const config = json(await fs.readFile(configFile, 'utf8'));
for (const key of ['databaseRoot', 'sdaRoot']) config[key] = path.resolve(path.dirname(configFile), config[key]);

const workspace = json(await fs.readFile(path.join(scaffoldRoot, 'consumer-workspace.authority.json'), 'utf8'));
const capabilityId = workspace.consumerId;

// The scaffold's own files, keyed by the estate source path they stand for. The
// workspace lives at capabilities/<id>/, so a reference that climbs out of that
// directory resolves the same way here as it does in the estate.
const owned = new Map();
const base = 'capabilities/' + capabilityId;
const collect = async (dir, prefix) => {
  for (const entry of await fs.readdir(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) await collect(full, prefix + '/' + entry.name);
    else owned.set(path.posix.normalize(prefix + '/' + entry.name), await fs.readFile(full));
  }
};
await collect(scaffoldRoot, base);
for (const entry of workspace.capabilities) {
  const target = path.posix.normalize(path.posix.join(base, entry.feature));
  owned.set(target, await fs.readFile(path.resolve(scaffoldRoot, entry.feature)));
}

const { config: readDatabaseConfig } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/core.mjs')));
const { connectionString } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/ingest/database.mjs')));
const { connectionEnvironmentVariable } = await readDatabaseConfig();
process.env[connectionEnvironmentVariable] = connectionString(connectionEnvironmentVariable);

const bundle = await readAuthority(config.databaseRoot, { capabilityId, target: 'node' }, { retainObjects: false });
const records = [...bundle.authority.recordsets[1], ...bundle.authority.recordsets[2]];
const replaced = [], added = [];
for (const [sourcePath, bytes] of owned) {
  const record = records.find(r => r.source_path === sourcePath);
  if (!record) { added.push(sourcePath); continue; }
  if (record.content_digest !== hash(bytes)) replaced.push(sourcePath);
  record.content_bytes.base64 = bytes.toString('base64');
  record.content_digest = hash(bytes);
}
const removed = records.filter(r => r.source_path.startsWith(base + '/') && !owned.has(r.source_path)).map(r => r.source_path);
console.log('scaffold      :', path.relative(process.cwd(), scaffoldRoot));
console.log('capability    :', capabilityId);
console.log('files on disk :', owned.size, '| differing from the estate:', replaced.length);
for (const p of replaced) console.log('    differs :', p);
for (const p of added) console.log('    on disk only, not in the estate:', p);
for (const p of removed) console.log('    in the estate, not on disk    :', p);

// The declared closure is derived from the graph the scaffold declares, so a
// scaffold that drops a scenario must not be planned against the estate's older
// closure. Narrow it to the scenarios this scaffold's feature still declares.
const feature = [...owned].find(([p]) => p.endsWith('.feature'))[1].toString('utf8');
const declared = new Set([...feature.matchAll(/@scenario:([^\s]+)/g)].map(m => m[1]));
const closureBefore = bundle.closure.recordsets[0].length;
bundle.closure.recordsets[0] = bundle.closure.recordsets[0].filter(r => declared.has(r.downstream_scenario_id));
console.log('scenarios     :', [...declared].join(', '));
if (bundle.closure.recordsets[0].length !== closureBefore)
  console.log('closure rows  :', closureBefore, '->', bundle.closure.recordsets[0].length, '(estate closure still carries withdrawn scenarios; it agrees again once registered)');

const plan = await planNode({ bundle, sdaRoot: config.sdaRoot });
const bodyFiles = plan.files.filter(f => f.relativePath.includes('/body/')).length;
console.log('planned       :', plan.files.length, 'files (' + bodyFiles + ' body)');

const { satisfies, valueAt } = await import(pathToFileURL(path.join(config.sdaRoot, 'artifacts/tools/dist/consumer-projection/proof/assertion-evaluator.js')));
const { createGovernedEffectContext } = await import(pathToFileURL(path.join(config.sdaRoot, 'languages/typescript/runtimes/node/native-mechanic-primitives.mjs')));
const fixtures = json(plan.files.find(f => f.relativePath.endsWith('/evidence/fixture-authority.json')).content).fixtures;
if (!fixtures.length) { console.error('\nSCAFFOLD_DECLARES_NO_FIXTURES: nothing exercises this capability'); process.exit(1); }

const runtime = await loadMemoryScenario(plan);
let asserted = 0, failed = 0;
for (const fixture of fixtures) {
  const observations = [], executions = [];
  // A fixture that stubs the governed effects keeps the declared composition
  // deterministic without a network exchange. The provider itself is unchanged;
  // only its supplied effect context is a fixture.
  const effectContext = fixture.effectStub ? createGovernedEffectContext({
    credentialReader: () => fixture.effectStub.credential,
    fetch: async () => new Response(fixture.effectStub.response.body, { status: fixture.effectStub.response.status, headers: fixture.effectStub.response.headers })
  }) : undefined;
  const scenario = await runtime.createScenario({ observer: { observe: v => observations.push(v) }, clock: { now: () => new Date().toISOString() }, effectContext });
  const input = structuredClone(fixture.input);
  const result = await scenario.execute(input, { executionId: fixture.fixtureId, rootExecutionId: fixture.fixtureId,
    rootInput: structuredClone(input), ancestry: [plan.selectedScenarioId], collect: v => executions.push(v) });
  const problems = [];
  if (result.disposition !== fixture.expected.disposition)
    problems.push(`disposition ${result.disposition}, expected ${fixture.expected.disposition}`);
  for (const assertion of fixture.expected.outcomeAssertions ?? []) {
    asserted++;
    if (!satisfies(valueAt(result.outcome, assertion.path), assertion)) problems.push(`${assertion.conditionId}: ${assertion.path} = ${JSON.stringify(valueAt(result.outcome, assertion.path))}, expected ${assertion.operator} ${JSON.stringify(assertion.value)}`);
  }
  console.log((problems.length ? '  FAIL  ' : '  ok    ') + fixture.fixtureId
    + (problems.length ? '' : '  -> ' + (result.outcome?.disposition ?? result.disposition)));
  for (const problem of problems) console.log('          ' + problem);
  failed += problems.length ? 1 : 0;
}
console.log(`\nfixtures ${fixtures.length - failed}/${fixtures.length}, assertions ${asserted}, observations recorded`);
if (failed) { console.error('SCAFFOLD_NOT_VALIDATED'); process.exit(1); }
console.log('SCAFFOLD_VALIDATED');
