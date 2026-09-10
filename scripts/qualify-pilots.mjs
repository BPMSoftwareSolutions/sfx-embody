// Qualification runs the installed sfx command, never an SDK substitute.
// Fixture assertions come from selected authority; additional probes are data.
import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { createHash } from 'node:crypto';
import { spawn, execFileSync } from 'node:child_process';
import assert from 'node:assert/strict';
import { readAuthority } from '../src/read-authority.mjs';

const hash = bytes => 'sha256:' + createHash('sha256').update(bytes).digest('hex');
const json = bytes => JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/, ''));
const writeJson = (file, value) => fs.writeFile(file, JSON.stringify(value, null, 2) + '\n');
const psQuote = value => "'" + value.replaceAll("'", "''") + "'";
const safeId = value => typeof value === 'string' && /^[a-zA-Z0-9][a-zA-Z0-9._-]*$/.test(value);

function command(command, args, options) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { ...options, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
    const stdout = [], stderr = [];
    child.stdout.on('data', chunk => stdout.push(chunk));
    child.stderr.on('data', chunk => stderr.push(chunk));
    child.on('error', reject);
    child.on('close', (exitCode, signal) => resolve({ exitCode, signal, stdout: Buffer.concat(stdout), stderr: Buffer.concat(stderr) }));
  });
}

const configFile = path.resolve(process.argv[2] ?? 'config/hugging-face-pilots.json');
const config = json(await fs.readFile(configFile));
const relative = value => path.resolve(path.dirname(configFile), value);
const projectRoot = relative(config.projectRoot);
const runtimeFile = relative(config.runtimeConfig);
const runtime = json(await fs.readFile(runtimeFile));
for (const key of ['databaseRoot', 'sdaRoot']) runtime[key] = path.resolve(path.dirname(runtimeFile), runtime[key]);
const stamp = new Date().toISOString().replaceAll(':', '-');
const output = path.join(relative(config.outputRoot), stamp);
await fs.mkdir(output, { recursive: true });

const { config: databaseConfig } = await import(pathToFileURL(path.join(runtime.databaseRoot, 'src/core.mjs')));
const { connectionString } = await import(pathToFileURL(path.join(runtime.databaseRoot, 'src/ingest/database.mjs')));
const { query } = await import(pathToFileURL(path.join(runtime.databaseRoot, 'src/query/run.mjs')));
const { connectionEnvironmentVariable } = await databaseConfig();
process.env[connectionEnvironmentVariable] = connectionString(connectionEnvironmentVariable);
const { satisfies, valueAt } = await import(pathToFileURL(path.join(runtime.sdaRoot, 'artifacts/tools/dist/consumer-projection/proof/assertion-evaluator.js')));

const cli = process.platform === 'win32'
  ? (await command('pwsh', ['-NoProfile', '-NonInteractive', '-Command', '(Get-Command sfx -ErrorAction Stop).Source'], { cwd: projectRoot })).stdout.toString('utf8').trim()
  : execFileSync('which', ['sfx'], { encoding: 'utf8' }).trim();
assert(cli, 'SFX_NOT_INSTALLED');
const revision = cwd => execFileSync('git', ['rev-parse', 'HEAD'], { cwd, encoding: 'utf8', windowsHide: true }).trim();
const summary = { observedAt: new Date().toISOString(), commandSurface: 'installed sfx CLI', cli,
  configDigest: hash(await fs.readFile(configFile)), runtimeConfigDigest: hash(await fs.readFile(runtimeFile)),
  projectConfigDigest: hash(await fs.readFile(path.join(projectRoot, 'sfx.config.json'))),
  revisions: { embody: revision(projectRoot), database: revision(runtime.databaseRoot), platform: revision(runtime.sdaRoot) },
  pilots: [], passed: 0, failed: 0, assertions: 0,
  scope: 'Local database-to-memory CLI execution; not remote hosting, UI conformance, external provider invocation or managed admission.' };
console.log('Evidence:', output);

const contractSql = `
WITH selected AS (
  SELECT c.capability_id, ec.capability_version_pk, cs.scenario_version_pk
  FROM model.estate_capability ec
  JOIN model.capability c ON c.capability_pk=ec.capability_pk
  JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  JOIN model.capability_root_scenario r ON r.capability_version_pk=ec.capability_version_pk
  JOIN model.capability_scenario cs ON cs.capability_version_pk=r.capability_version_pk AND cs.scenario_pk=r.scenario_pk
  WHERE ec.estate_model_pk=@estate_model_pk
    AND c.capability_id=JSON_VALUE(@input,'$.capabilityId')
    AND n.namespace_id=JSON_VALUE(@input,'$.namespaceId')
), faces AS (
  SELECT selected.*, 'input' AS direction, i.input_contract_version_pk AS contract_version_pk
  FROM selected JOIN model.scenario_input i ON i.scenario_version_pk=selected.scenario_version_pk
  UNION ALL
  SELECT selected.*, 'outcome' AS direction, o.contract_version_pk
  FROM selected JOIN model.scenario_outcome_contract o ON o.scenario_version_pk=selected.scenario_version_pk
)
SELECT f.*, c.contract_id,
  'sha256:' + LOWER(CONVERT(varchar(64), co.content_digest, 2)) AS schema_digest, co.content_bytes
FROM faces f JOIN model.contract_version cv ON cv.contract_version_pk=f.contract_version_pk
JOIN model.contract c ON c.contract_pk=cv.contract_pk
JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
JOIN source.content_object co ON co.content_object_pk=so.content_object_pk;`;

for (const pilot of config.pilots) {
  assert(safeId(pilot.capabilityId), 'UNSAFE_CAPABILITY_FILE_NAME');
  const directory = path.join(output, pilot.capabilityId);
  await fs.mkdir(directory);
  const selection = { capabilityId: pilot.capabilityId, namespaceId: pilot.namespaceId, target: 'node' };
  const bundle = await readAuthority(runtime.databaseRoot, selection, { retainObjects: false });
  const contracts = await query(contractSql, { input: selection, retainObjects: false });
  assert.equal(contracts.projectionDigest, bundle.authority.projectionDigest, 'AUTHORITY_CHANGED_DURING_CAPTURE');
  assert.equal(contracts.snapshotId, bundle.authority.snapshotId);
  assert.equal(contracts.recordsets[0].length, 2, 'ROOT_CONTRACT_PAIR_UNRESOLVED');
  await writeJson(path.join(directory, 'authority.bundle.json'), bundle);
  await writeJson(path.join(directory, 'contracts.query.json'), contracts);
  const selected = bundle.authority.recordsets[0][0];
  const sourceRecords = bundle.authority.recordsets[1];
  const source = sourcePath => {
    const matches = sourceRecords.filter(r => r.source_path === sourcePath);
    assert(matches.length, 'SOURCE_MISSING:' + sourcePath);
    assert.equal(new Set(matches.map(r => r.content_digest)).size, 1, 'SOURCE_AMBIGUOUS:' + sourcePath);
    const bytes = Buffer.from(matches[0].content_bytes.base64, 'base64');
    assert.equal(hash(bytes), matches[0].content_digest, 'SOURCE_BYTES_CHANGED');
    return { record: matches[0], document: json(bytes) };
  };
  const workspacePath = `capabilities/${pilot.capabilityId}/consumer-workspace.authority.json`;
  const workspace = source(workspacePath).document;
  assert.equal(workspace.capabilities.length, 1, 'PILOT_WORKSPACE_ENTRY_AMBIGUOUS');
  const fixturePath = path.posix.normalize(path.posix.join(path.posix.dirname(workspacePath), workspace.capabilities[0].fixtures));
  const fixtureSource = source(fixturePath);
  assert(fixtureSource.document.fixtures.length, 'NO_RETAINED_FIXTURES');
  const cases = [
    ...fixtureSource.document.fixtures.map(f => ({ ...f, provenance: 'SELECTED_FIXTURE_AUTHORITY' })),
    ...(pilot.probes ?? []).map(f => ({ ...f, provenance: 'LOCAL_INPUT_PROBE' })),
  ];
  assert.equal(new Set(cases.map(f => f.fixtureId)).size, cases.length, 'DUPLICATE_CASE_ID');
  const record = { capabilityId: pilot.capabilityId, selected, snapshotId: bundle.authority.snapshotId,
    projectionDigest: bundle.authority.projectionDigest, viewDefinitionDigest: bundle.authority.viewDefinitionDigest,
    closure: bundle.closure.recordsets[0].map(r => r.downstream_scenario_id),
    fixtures: { sourcePath: fixturePath, digest: fixtureSource.record.content_digest },
    contracts: contracts.recordsets[0].map(({ content_bytes, ...identity }) => identity), cases: [] };
  summary.pilots.push(record);
  for (const fixture of cases) {
    assert(safeId(fixture.fixtureId), 'UNSAFE_FIXTURE_FILE_NAME');
    const prefix = path.join(directory, fixture.fixtureId);
    const inputPath = prefix + '.input.json';
    await writeJson(inputPath, fixture.input);
    const args = ['capability', 'invoke', pilot.capabilityId, '--namespace', pilot.namespaceId, '--input', '@' + inputPath, '--json'];
    const text = 'sfx ' + args.map(psQuote).join(' ');
    const started = performance.now();
    const native = process.platform === 'win32'
      ? await command('pwsh', ['-NoProfile', '-NonInteractive', '-Command', '& ' + text + '; exit $LASTEXITCODE'], { cwd: projectRoot })
      : await command('sfx', args, { cwd: projectRoot });
    const milliseconds = Math.round(performance.now() - started);
    await fs.writeFile(prefix + '.stdout.json', native.stdout);
    await fs.writeFile(prefix + '.stderr.txt', native.stderr);
    const result = { fixtureId: fixture.fixtureId, provenance: fixture.provenance, command: text, cwd: projectRoot,
      exitCode: native.exitCode, signal: native.signal, milliseconds, inputFile: path.basename(inputPath),
      stdoutFile: path.basename(prefix + '.stdout.json'), stderrFile: path.basename(prefix + '.stderr.txt'),
      inputFileDigest: hash(await fs.readFile(inputPath)), stdoutDigest: hash(native.stdout), stderrDigest: hash(native.stderr),
      expected: fixture.expected, assertionCount: 0, status: 'FAILED', problems: [] };
    try {
      assert.equal(native.exitCode, 0, 'CLI_EXIT_NOT_ZERO');
      const actual = json(native.stdout);
      result.kernelDisposition = actual.result.disposition;
      result.domainDisposition = actual.result.outcome?.disposition ?? null;
      result.outcome = actual.result.outcome ?? null;
      result.authorityIdentity = actual.evidence.authorityIdentity;
      assert.equal(actual.capabilityId, pilot.capabilityId);
      assert.equal(actual.scenarioId, selected.scenario_id);
      assert.deepEqual(actual.result.input, fixture.input, 'CANONICAL_INPUT_CHANGED');
      assert.equal(actual.result.disposition, fixture.expected.disposition, 'KERNEL_DISPOSITION_CHANGED');
      assert.equal(actual.evidence.snapshotId, bundle.authority.snapshotId, 'SNAPSHOT_CHANGED');
      assert.equal(actual.evidence.projectionDigest, bundle.authority.projectionDigest, 'AUTHORITY_CHANGED_DURING_EXECUTION');
      assert.equal(actual.evidence.authorityIdentity.scenarioDefinitionDigest, selected.scenario_definition_digest);
      assert.equal(actual.evidence.inputDigest, hash(JSON.stringify(fixture.input)));
      assert.equal(actual.evidence.resultDigest, hash(JSON.stringify(actual.result)));
      assert.equal(actual.evidence.authoritySource, 'DATABASE');
      assert.equal(actual.evidence.bodyStorage, 'MEMORY_ONLY');
      for (const flag of ['fsWriteAllowed', 'expandedBodyReadAllowed', 'databaseCacheReadAllowed']) assert.equal(actual.evidence.process[flag], false);
      for (const q of actual.evidence.queries) {
        assert.equal(q.objectRetention, 'MEMORY_ONLY');
        assert.equal(q.truncated, false);
        assert.equal(q.projectionDigest, bundle.authority.projectionDigest);
        assert.equal(q.viewDefinitionDigest, bundle.authority.viewDefinitionDigest);
      }
      if (fixture.expected.scenarioSequence) assert.deepEqual(actual.executions.map(e => e.scenarioId), fixture.expected.scenarioSequence);
      if (fixture.expected.terminalScenarioId) assert.equal(actual.result.scenarioId, fixture.expected.terminalScenarioId);
      for (const expectation of fixture.expected.outcomeAssertions ?? []) {
        result.assertionCount++;
        if (!satisfies(valueAt(actual.result.outcome, expectation.path), expectation)) result.problems.push(expectation.conditionId);
      }
      record.runtime = { authorityIdentity: actual.evidence.authorityIdentity, modules: actual.evidence.modules,
        externalDependencies: actual.evidence.externalDependencies, process: actual.evidence.process };
      assert.equal(result.problems.length, 0, 'OUTCOME_ASSERTIONS_FAILED');
      result.status = 'PASSED';
      summary.passed++;
    } catch (error) { result.problems.push(error.message); summary.failed++; }
    summary.assertions += result.assertionCount;
    record.cases.push(result);
    await writeJson(prefix + '.receipt.json', result);
    await writeJson(path.join(output, 'qualification.json'), summary);
    console.log(result.status, pilot.capabilityId, fixture.fixtureId, result.kernelDisposition ?? ('exit=' + native.exitCode));
  }
}
await writeJson(path.join(output, 'qualification.json'), summary);
await writeJson(path.join(relative(config.outputRoot), 'latest.json'), { directory: output, summary: path.join(output, 'qualification.json') });
console.log(JSON.stringify({ passed: summary.passed, failed: summary.failed, assertions: summary.assertions, output }));
process.exitCode = summary.failed ? 1 : 0;
