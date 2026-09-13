// Invoke a capability from an uncommitted rollback experiment.
//
//   node --experimental-vm-modules scripts/invoke-from-transaction.mjs <experiment.sql> [capabilityId] [input.json] [estate-cases.json]
//
// The experiment runs on one connection inside one transaction. The same
// connection then runs the read-path queries, so the uncommitted rows are
// visible. The native body is planned and executed in-process and the outcome is
// printed. The transaction is rolled back at the end -- nothing is committed.
import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';
import { planNode } from '../src/materialize-node.mjs';
import { loadMemoryScenario } from '../src/load-memory-scenario.mjs';
import { isEstateDelivery, executeEstateCapability } from '../src/invoke-database-capability.mjs';

const DATABASE_ROOT = 'C:/lab/sidefx-database';
const SDA_ROOT = 'C:/lab/repos/scenario-driven-architecture';
const db = (...p) => path.join(DATABASE_ROOT, ...p);

const experimentFile = process.argv[2] ?? db('sql/experiments/remove-overhead-and-scaffold-hello-world.sql');
const capabilityId = process.argv[3] ?? 'hello-world-sql';
const input = JSON.parse(await fs.readFile(process.argv[4] ?? path.resolve('examples/hello-world-sql.request.json'), 'utf8'));

const { connect, sql } = await import(pathToFileURL(db('src/ingest/database.mjs')).href);
const { pinModel } = await import(pathToFileURL(db('src/query/model-pin.mjs')).href);
const { normalizeSql } = await import(pathToFileURL(db('src/query/run.mjs')).href);

let text = await fs.readFile(experimentFile, 'utf8');
const marker = 'ROLLBACK TRANSACTION;';
const at = text.lastIndexOf(marker);
if (at < 0) throw new Error('NO_ROLLBACK_IN_EXPERIMENT');
text = text.slice(0, at);
const batches = text.split(/^\s*GO\s*$/mi).map(s => s.trim()).filter(Boolean);

const pool = await connect();
const tx = new sql.Transaction(pool);
const outcome = { experimentFile, capabilityId, input, readPath: null, result: null };
try {
  await tx.begin();
  for (const batch of batches) await new sql.Request(tx).batch(batch);
  console.log('EXPERIMENT APPLIED (uncommitted)');

  const pinned = await pinModel(tx);
  const identity = { snapshotId: pinned.snapshot_id, projectionDigest: pinned.projection_id, viewDefinitionDigest: pinned.viewDefinitionDigest, truncated: false };
  const readStatement = async (statement, { input: selection }) => {
    const request = new sql.Request(tx)
      .input('estate_model_pk', sql.BigInt, pinned.estate_model_pk)
      .input('snapshot_id', sql.VarChar(71), pinned.snapshot_id)
      .input('projection_id', sql.VarChar(71), pinned.projection_id)
      .input('view_definition_digest', sql.VarChar(71), pinned.viewDefinitionDigest)
      .input('input', sql.NVarChar(sql.MAX), JSON.stringify(selection));
    const result = await request.query(statement);
    return { ...identity, recordsets: result.recordsets.map(rs => rs.map(normalizeSql)), rowCounts: result.recordsets.map(rs => rs.length) };
  };
  const readQuery = async (file, selection) => readStatement(await fs.readFile(db('sql/diagnostics', file), 'utf8'), { input: selection });

  const mechanicsRaw = await new sql.Request(tx).query(`SELECT definition_json FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=${Number(pinned.estate_model_pk)} AND object_kind='MECHANIC'`);
  const mechanics = { ...identity, recordsets: [mechanicsRaw.recordset.map(normalizeSql)], rowCounts: [mechanicsRaw.recordset.length] };
  // Every nested read stays on the same transaction, including reads performed
  // by estate providers. Using a second connection would test installed rows.
  const readTransactionAuthority = async (_databaseRoot, selection) => {
    const authority = await readQuery('capability-embodiment.sql', selection);
    const selected = authority.recordsets[0][0];
    if (!selected) throw new Error('CAPABILITY_NOT_FOUND_ON_THIS_TRANSACTION:' + selection.capabilityId);
    const closure = await readQuery('scenario-closure.sql', { ...selection, scenarioId: selected.scenario_id });
    return { selection: { ...selection, scenarioId: selected.scenario_id }, authority, closure, resolutions: null, mechanics };
  };
  const bundle = await readTransactionAuthority(DATABASE_ROOT, { capabilityId, target: 'node' });
  const { authority, closure } = bundle;
  if (process.argv[6]) await fs.writeFile(process.argv[6], JSON.stringify(bundle, null, 2) + '\n');
  const selected = authority.recordsets[0][0];
  outcome.readPath = { selected, authorityRows: authority.rowCounts, closureRows: closure.rowCounts, mechanicRows: mechanics.rowCounts };

  const context = { databaseRoot: DATABASE_ROOT, sdaRoot: SDA_ROOT, estateRoot: path.resolve('.'), readAuthority: readTransactionAuthority, readQuery: readStatement };
  if (await isEstateDelivery(bundle, context)) {
    const result = await executeEstateCapability({ capabilityId }, input, context);
    outcome.result = result;
    console.log('DISPOSITION', result.disposition ?? result.contractId);
    console.log('OUTCOME', JSON.stringify(result));
  } else {
    const plan = await planNode({ bundle, sdaRoot: SDA_ROOT });
    console.log('PLANNED', plan.files.length, 'files; scenario', plan.selectedScenarioId);
    const runtime = await loadMemoryScenario(plan);
    const executions = [];
    const scenario = await runtime.createScenario({ observer: { observe() {} }, clock: { now: () => new Date().toISOString() } });
    const result = await scenario.execute(input, { executionId: 'invoke-from-transaction', rootExecutionId: 'invoke-from-transaction',
      rootInput: structuredClone(input), ancestry: [plan.selectedScenarioId], collect: v => executions.push(v) });
    outcome.result = result;
    console.log('DISPOSITION', result.disposition);
    console.log('OUTCOME', JSON.stringify(result.outcome));
  }
  // Optional estate cases share this transaction and therefore cannot pass by
  // accidentally reading an installed generation on another connection.
  if (process.argv[5]) {
    const cases = JSON.parse(await fs.readFile(process.argv[5], 'utf8'));
    outcome.verification = [];
    for (const test of cases) {
      const result = await executeEstateCapability({ capabilityId: test.capabilityId, scenarioId: test.scenarioId }, test.input, context);
      for (const [field, expected] of Object.entries(test.expected)) {
        const actual = field.split('.').reduce((value, key) => value?.[key], result);
        assert.deepEqual(actual, expected, test.name + ': ' + field);
      }
      if (test.verifyWrittenFiles) {
        assert.ok(result.written?.length > 0, test.name + ': written files');
        for (const file of result.written) {
          const bytes = await fs.readFile(path.resolve(result.outputRoot, file.relativePath));
          assert.equal('sha256:' + createHash('sha256').update(bytes).digest('hex'), file.digest,
            test.name + ': ' + file.relativePath);
        }
      }
      if (test.verifyNativeProviders) {
        const { verifyConsumerExecutionProviders } = await import('./verify-consumer-execution-providers.mjs');
        const verification = await verifyConsumerExecutionProviders(result, test.verifyNativeProviders, context);
        console.log('NATIVE PROVIDERS VERIFIED', JSON.stringify(verification));
      }
      outcome.verification.push({ name: test.name, disposition: 'PASSED' });
      console.log('VERIFIED', test.name);
    }
  }
} catch (error) {
  outcome.error = { message: error.message, stack: error.stack };
  console.error('INVOKE FAILED:', error.message);
  process.exitCode = 1;
} finally {
  try { await tx.rollback(); } catch {}
  try { await pool.close(); } catch {}
}
console.log('RESULT', JSON.stringify(outcome));
