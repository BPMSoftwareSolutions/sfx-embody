// Planning stays on the trusted SideFX side. The resulting execution-only package
// contains no SQL connection, sibling checkout, CLI installation or provider secret.
import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { planNode } from '../src/materialize-node.mjs';

const hash = bytes => 'sha256:' + createHash('sha256').update(bytes).digest('hex');
const readJson = async file => JSON.parse(await fs.readFile(file, 'utf8'));
const writeJson = async (file, value) => fs.writeFile(file, JSON.stringify(value, null, 2) + '\n');
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const configFile = path.resolve(process.argv[2] ?? path.join(root, 'config/hugging-face-pilots.json'));
const config = await readJson(configFile);
const runtimeFile = path.resolve(path.dirname(configFile), config.runtimeConfig);
const runtime = await readJson(runtimeFile);
const sdaRoot = path.resolve(path.dirname(runtimeFile), runtime.sdaRoot);
const pointer = await readJson(path.resolve(path.dirname(configFile), config.outputRoot, 'latest.json'));
const summaryBytes = await fs.readFile(pointer.summary);
const summary = JSON.parse(summaryBytes);
assert.equal(summary.failed, 0, 'QUALIFICATION_HAS_FAILURES');
assert(summary.passed > 0, 'QUALIFICATION_EMPTY');
const output = path.join(pointer.directory, 'container-' + new Date().toISOString().replaceAll(':', '-'));
await fs.mkdir(path.join(output, 'plans'), { recursive: true });
for (const name of ['Dockerfile', 'package.json', 'package-lock.json', 'run.mjs']) {
  await fs.copyFile(path.join(root, 'scripts/pilot-container', name), path.join(output, name));
}
await fs.copyFile(path.join(root, 'src/load-memory-scenario.mjs'), path.join(output, 'load-memory-scenario.mjs'));
const pilots = [];
for (const pilot of summary.pilots) {
  assert(/^[a-zA-Z0-9][a-zA-Z0-9._-]*$/.test(pilot.capabilityId), 'INVALID_CAPABILITY_FILE_NAME');
  const directory = path.join(pointer.directory, pilot.capabilityId);
  const bundle = await readJson(path.join(directory, 'authority.bundle.json'));
  assert.equal(bundle.authority.snapshotId, pilot.snapshotId);
  assert.equal(bundle.authority.projectionDigest, pilot.projectionDigest);
  const plan = await planNode({ bundle, sdaRoot });
  const entry = plan.receipts.find(r => r.plan.scenarioId === plan.selectedScenarioId);
  for (const [key, value] of Object.entries(pilot.runtime.authorityIdentity)) assert.equal(entry.receipt[key], value, 'CLI_AUTHORITY_CHANGED:' + key);
  // Carry only the native-body closure and the loader's entry-point selection.
  const packaged = { capabilityId: plan.capabilityId, selectedScenarioId: plan.selectedScenarioId,
    files: plan.files.filter(f => f.relativePath.includes('/body/')),
    receipts: plan.receipts.map(r => ({ base: r.base, plan: { scenarioId: r.plan.scenarioId } })) };
  const planFile = 'plans/' + pilot.capabilityId + '.json';
  await writeJson(path.join(output, planFile), packaged);
  const cases = [];
  for (const fixture of pilot.cases) {
    assert.equal(fixture.status, 'PASSED');
    const inputBytes = await fs.readFile(path.join(directory, fixture.inputFile));
    const stdoutBytes = await fs.readFile(path.join(directory, fixture.stdoutFile));
    assert.equal(hash(inputBytes), fixture.inputFileDigest, 'CLI_INPUT_CHANGED');
    assert.equal(hash(stdoutBytes), fixture.stdoutDigest, 'CLI_OUTPUT_CHANGED');
    const actual = JSON.parse(stdoutBytes);
    cases.push({ fixtureId: fixture.fixtureId, input: JSON.parse(inputBytes),
      expected: { result: actual.result, executions: actual.executions, observations: actual.observations } });
  }
  pilots.push({ capabilityId: pilot.capabilityId, authorityIdentity: pilot.runtime.authorityIdentity,
    snapshotId: pilot.snapshotId, projectionDigest: pilot.projectionDigest, modules: pilot.runtime.modules,
    planFile, planDigest: hash(await fs.readFile(path.join(output, planFile))), bodyFiles: packaged.files.length, cases });
}
await writeJson(path.join(output, 'cases.json'), pilots);
const files = ['Dockerfile', 'package.json', 'package-lock.json', 'run.mjs', 'load-memory-scenario.mjs', 'cases.json', ...pilots.map(p => p.planFile)];
const manifest = { sourceQualification: pointer.summary, sourceQualificationDigest: hash(summaryBytes),
  files: await Promise.all(files.map(async file => ({ file, digest: hash(await fs.readFile(path.join(output, file))) }))),
  pilots: pilots.map(({ cases, modules, ...pilot }) => ({ ...pilot, cases: cases.length, modules: modules.length })) };
await writeJson(path.join(output, 'package-manifest.json'), manifest);
await writeJson(path.join(pointer.directory, 'container-latest.json'), { directory: output });
console.log(JSON.stringify({ directory: output, pilots: pilots.length, cases: pilots.reduce((n, p) => n + p.cases.length, 0) }));
