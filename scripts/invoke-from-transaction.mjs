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
import { isEstateDelivery, executeEstateCapability, executeSelectedDeclaration, executeDatabaseCommand } from '../src/invoke-database-capability.mjs';
import { readExecutionDelivery } from '../src/read-execution-delivery.mjs';

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
  const authorityReads = new Map();
  const selectionKey = selection => JSON.stringify(Object.entries(selection).filter(([, value]) => value !== undefined).sort(([a], [b]) => a.localeCompare(b)));
  const readTransactionAuthority = async (_databaseRoot, selection) => {
    const key = selectionKey(selection);
    if (authorityReads.has(key)) return structuredClone(authorityReads.get(key));
    const authority = await readQuery('capability-embodiment.sql', selection);
    const selected = authority.recordsets[0][0];
    if (!selected) throw new Error('CAPABILITY_NOT_FOUND_ON_THIS_TRANSACTION:' + selection.capabilityId);
    const closure = await readQuery('scenario-closure.sql', { ...selection, scenarioId: selected.scenario_id });
    const bundle = { selection: { ...selection, scenarioId: selected.scenario_id }, authority, closure, resolutions: null, mechanics };
    authorityReads.set(key, bundle);
    authorityReads.set(selectionKey(bundle.selection), bundle);
    return structuredClone(bundle);
  };
  const bundle = await readTransactionAuthority(DATABASE_ROOT, { capabilityId, target: 'node' });
  const { authority, closure } = bundle;
  if (process.argv[6]) await fs.writeFile(process.argv[6], JSON.stringify(bundle, null, 2) + '\n');
  const selected = authority.recordsets[0][0];
  outcome.readPath = { selected, authorityRows: authority.rowCounts, closureRows: closure.rowCounts, mechanicRows: mechanics.rowCounts };

  const context = { databaseRoot: DATABASE_ROOT, sdaRoot: SDA_ROOT, estateRoot: path.resolve('.'), readAuthority: readTransactionAuthority, readQuery: readStatement };
  if (process.env.SFX_PREFLIGHT_PHYSICAL_TRACE === '1') {
    context.collectProviderExecution = ({ cellId, input, outcome }) => {
      const payload = input?.payload ?? input;
      console.log('PROVIDER EXECUTION', JSON.stringify({ cellId, contractId: outcome?.contractId,
        disposition: outcome?.disposition, reachedStage: outcome?.reachedStage,
        invocationIdentity: payload?.invocationIdentity, endpointAuthorityDigest: payload?.endpointAuthorityDigest,
        credentialInjectionRuleId: payload?.credentialInjectionRuleId,
        opaqueBindingPresent: typeof payload?.opaqueCredentialBinding?.bindingId === 'string' }));
    };
    context.effectContextOverrides = {
      credentialReader: referenceName => {
        const value = process.env[referenceName];
        console.log('PHYSICAL EFFECT', JSON.stringify({ operation: 'credential-reference', available: typeof value === 'string' && value.length > 0 }));
        return value;
      },
      fetch: async (...args) => {
        try {
          const response = await globalThis.fetch(...args);
          console.log('PHYSICAL EFFECT', JSON.stringify({ operation: 'http-exchange', status: response.status }));
          return response;
        } catch (error) {
          console.log('PHYSICAL EFFECT', JSON.stringify({ operation: 'http-exchange', errorCode: error.cause?.code ?? error.code ?? error.name }));
          throw error;
        }
      }
    };
  }
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
      const caseContext = test.outputRoot ? { ...context, outputRoot: path.resolve(test.outputRoot) } : context;
      const result = await executeEstateCapability({ capabilityId: test.capabilityId, scenarioId: test.scenarioId }, test.input, caseContext);
      outcome.currentCase = { name: test.name, result };
      if (test.verifyDatabaseCommand) {
        const command = test.verifyDatabaseCommand;
        const actual = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1',
          operation: command.request.verb, request: command.request }, caseContext);
        outcome.currentCase.delivery = actual;
        for (const [field, expected] of Object.entries(command.expected))
          assert.deepEqual(field.split('.').reduce((value, key) => value?.[key], actual), expected, test.name + ': ' + field);
        if (command.requireProviderObservation)
          assert.ok(actual.outcome.observations.some(value => value.phase === 'invokeProvider' && value.status === 'completed'), test.name + ': native provider observation');
        console.log('DATABASE COMMAND VERIFIED', JSON.stringify({ disposition: actual.disposition,
          capabilityId: actual.outcome.capabilityId, resultDisposition: actual.outcome.result.disposition }));
      }
      if (test.verifyExecutionDelivery) {
        const delivery = await readExecutionDelivery(caseContext);
        const actual = await executeSelectedDeclaration(delivery, { capabilityId: result.capabilityId, target: delivery.defaultTarget },
          result.authority.recordsets[0][0], test.verifyExecutionDelivery.input, caseContext);
        for (const [field, expected] of Object.entries(test.verifyExecutionDelivery.expected))
          assert.deepEqual(field.split('.').reduce((value, key) => value?.[key], actual), expected, test.name + ': ' + field);
        console.log('EXECUTION DELIVERY VERIFIED', JSON.stringify({ disposition: actual.disposition, result: actual.result }));
      }
      for (const [field, expected] of Object.entries(test.expected)) {
        const actual = field.split('.').reduce((value, key) => value?.[key], result);
        assert.deepEqual(actual, expected, test.name + ': ' + field);
      }
      for (const field of test.absent ?? [])
        assert.equal(field.split('.').reduce((value, key) => value?.[key], result), undefined, test.name + ': ' + field);
      if (test.verifyWrittenFiles) {
        assert.ok(result.written?.length > 0, test.name + ': written files');
        for (const file of result.written) {
          const bytes = await fs.readFile(path.resolve(result.outputRoot, file.relativePath));
          assert.equal('sha256:' + createHash('sha256').update(bytes).digest('hex'), file.digest,
            test.name + ': ' + file.relativePath);
        }
      }
      for (const file of test.absentFiles ?? [])
        await assert.rejects(fs.stat(path.resolve(caseContext.outputRoot ?? caseContext.estateRoot, file)), { code: 'ENOENT' }, test.name + ': ' + file);
      for (const file of test.retainedFiles ?? [])
        assert.equal(await fs.readFile(path.resolve(caseContext.outputRoot ?? caseContext.estateRoot, file.relativePath), 'utf8'), file.content, test.name + ': ' + file.relativePath);
      if (test.verifyNativeProviders) {
        const { verifyConsumerExecutionProviders } = await import('./verify-consumer-execution-providers.mjs');
        const verification = await verifyConsumerExecutionProviders(result, test.verifyNativeProviders, caseContext);
        console.log('NATIVE PROVIDERS VERIFIED', JSON.stringify(verification));
      }
      if (test.verifyConsumerFixtures) {
        const { verifyConsumerFixtures } = await import('./verify-consumer-fixtures.mjs');
        const verification = await verifyConsumerFixtures(result, test.verifyConsumerFixtures, caseContext);
        console.log('CONSUMER FIXTURES VERIFIED', JSON.stringify(verification));
      }
      if (test.verifyDeclaredFixtures) {
        const { verifyDeclaredFixtures } = await import('./verify-declared-fixtures.mjs');
        const verification = await verifyDeclaredFixtures(result, test.verifyDeclaredFixtures, caseContext);
        console.log('DECLARED FIXTURES VERIFIED', JSON.stringify(verification));
      }
      if (test.verifyConsumerFirstFailure) {
        const { verifyConsumerFirstFailure } = await import('./verify-consumer-first-failure.mjs');
        const verification = await verifyConsumerFirstFailure(result, test.verifyConsumerFirstFailure, caseContext);
        console.log('FIRST FAILURE VERIFIED', JSON.stringify(verification));
      }
      outcome.verification.push({ name: test.name, disposition: 'PASSED' });
      delete outcome.currentCase;
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
