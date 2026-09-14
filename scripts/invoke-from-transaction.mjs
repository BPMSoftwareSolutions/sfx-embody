// Invoke a capability from an uncommitted rollback experiment.
//
//   node --experimental-vm-modules scripts/invoke-from-transaction.mjs <experiment.sql> [capabilityId] [input.json] [estate-cases.json]
//
// The experiment runs on one connection inside one transaction. The same
// connection then runs the estate's declared reads, so the uncommitted rows are
// visible. The capability's declared graph is handed to the kernel, which
// interprets it in process, and the outcome is printed. The transaction is
// rolled back at the end -- nothing is committed.
import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';
import { executeEstateCapability, executeSelectedDeclaration, executeDatabaseCommand } from '../src/invoke-database-capability.mjs';
import { readExecutionDelivery } from '../src/read-execution-delivery.mjs';

const DATABASE_ROOT = 'C:/lab/sidefx-database';
const SDA_ROOT = 'C:/lab/repos/scenario-driven-architecture';
const db = (...p) => path.join(DATABASE_ROOT, ...p);

// The transaction-bound declaration read. It mirrors the loader's own read in
// src/read-authority.mjs -- the estate's declared views, never the legacy
// sidefx-database diagnostics -- but runs on the experiment's transaction so
// uncommitted rows are the authority.
const AUTHORITY_READ = `
SELECT TOP 1 g.capability_id,
       g.root_scenario_id AS scenario_id,
       n.namespace_id
FROM analysis.v_capability_graph_source g
LEFT JOIN model.capability c ON c.capability_id = g.capability_id
LEFT JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
WHERE g.capability_id = CONVERT(nvarchar(400), JSON_VALUE(@input, '$.capabilityId'))
  AND (JSON_VALUE(@input, '$.namespaceId') IS NULL OR n.namespace_id = JSON_VALUE(@input, '$.namespaceId'))
ORDER BY n.namespace_id;

SELECT d.source_path, d.entry_id,
       CONVERT(varbinary(max), CONVERT(varchar(max), d.document) COLLATE Latin1_General_100_BIN2_UTF8) AS content_bytes
FROM analysis.v_capability_execution_declaration d
WHERE d.capability_id = CONVERT(nvarchar(400), JSON_VALUE(@input, '$.capabilityId'))
ORDER BY d.source_path, d.entry_id;`;

const CLOSURE_READ = `
DECLARE @capability_id nvarchar(4000)=JSON_VALUE(@input,'$.capabilityId'),
        @scenario_id nvarchar(4000)=JSON_VALUE(@input,'$.scenarioId'),
        @namespace_id nvarchar(4000)=JSON_VALUE(@input,'$.namespaceId');
DECLARE @matches bigint,@capability_version_pk bigint,@scenario_version_pk bigint;
SELECT @matches=COUNT_BIG(*),@capability_version_pk=MAX(ec.capability_version_pk)
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE ec.estate_model_pk=@estate_model_pk AND c.capability_id=@capability_id
  AND (@namespace_id IS NULL OR n.namespace_id=@namespace_id);
IF @matches=0 THROW 51000,'CAPABILITY_NOT_FOUND',1;
IF @matches<>1 THROW 51000,'CAPABILITY_NAMESPACE_AMBIGUOUS',1;
SELECT @matches=COUNT_BIG(*),@scenario_version_pk=MAX(cs.scenario_version_pk)
FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
WHERE cs.capability_version_pk=@capability_version_pk AND s.scenario_id=@scenario_id;
IF @matches=0 THROW 51000,'SCENARIO_NOT_IN_CAPABILITY',1;
IF @matches<>1 THROW 51000,'SCENARIO_NAMESPACE_AMBIGUOUS',1;
SELECT DISTINCT s.scenario_id AS downstream_scenario_id,cl.minimum_depth,cl.cycle_detected,
       sc.capability_id AS owning_capability_id,
       i.input_id,e.event_id,e.responsibility,o.outcome_id,sv.definition_digest AS scenario_definition_digest
FROM analysis.v_scenario_invocation_closure cl
JOIN model.scenario_version sv ON sv.scenario_version_pk=cl.downstream_scenario_version_pk
JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
JOIN model.capability sc ON sc.capability_pk=s.capability_pk
LEFT JOIN model.scenario_input i ON i.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_event e ON e.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_outcome o ON o.scenario_version_pk=sv.scenario_version_pk
WHERE cl.capability_version_pk=@capability_version_pk AND cl.selected_scenario_version_pk=@scenario_version_pk
ORDER BY cl.minimum_depth,s.scenario_id
OPTION(MAXRECURSION 32767);`;

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
  const readStatement = async (statement, { input: selection } = {}) => {
    const request = new sql.Request(tx)
      .input('estate_model_pk', sql.BigInt, pinned.estate_model_pk)
      .input('snapshot_id', sql.VarChar(71), pinned.snapshot_id)
      .input('projection_id', sql.VarChar(71), pinned.projection_id)
      .input('view_definition_digest', sql.VarChar(71), pinned.viewDefinitionDigest)
      .input('input', sql.NVarChar(sql.MAX), JSON.stringify(selection ?? null));
    const result = await request.query(statement);
    return { ...identity, recordsets: result.recordsets.map(rs => rs.map(normalizeSql)), rowCounts: result.recordsets.map(rs => rs.length) };
  };

  const mechanicsRaw = await new sql.Request(tx).query(`SELECT definition_json FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=${Number(pinned.estate_model_pk)} AND object_kind='MECHANIC'`);
  const mechanics = { ...identity, recordsets: [mechanicsRaw.recordset.map(normalizeSql)], rowCounts: [mechanicsRaw.recordset.length] };
  // Every nested read stays on the same transaction, including reads performed
  // by estate providers. Using a second connection would test installed rows.
  const authorityReads = new Map();
  const selectionKey = selection => JSON.stringify(Object.entries(selection).filter(([, value]) => value !== undefined).sort(([a], [b]) => a.localeCompare(b)));
  const readTransactionAuthority = async (_databaseRoot, selection) => {
    const key = selectionKey(selection);
    if (authorityReads.has(key)) return structuredClone(authorityReads.get(key));
    const authority = await readStatement(AUTHORITY_READ, { input: selection });
    const root = authority.recordsets[0]?.[0];
    if (!root) throw new Error('CAPABILITY_NOT_FOUND_ON_THIS_TRANSACTION:' + selection.capabilityId);
    const resolved = { ...selection, scenarioId: selection.scenarioId ?? root.scenario_id,
      ...(root.namespace_id === undefined ? {} : { namespaceId: root.namespace_id }) };
    const closure = await readStatement(CLOSURE_READ, { input: resolved });
    const bundle = { selection: resolved, authority, closure, resolutions: null, mechanics };
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
  // Invocation reads the capability's declared graph from the estate view and
  // hands it to the kernel through the same run-declared-graph capability the
  // loader uses. Every read stays on this transaction, so the uncommitted rows
  // are the authority. Delivery selection names the target the applied rows
  // declare; a capability with no declared target is unchanged.
  const delivery = await readExecutionDelivery(context);
  context.deliveryTarget = delivery.defaultTarget;
  const graphRead = await readStatement(
    "SELECT graph_source FROM analysis.v_capability_graph_source WHERE capability_id = CONVERT(nvarchar(400), JSON_VALUE(@input,'$.capabilityId'))",
    { input: { capabilityId } });
  if (!graphRead.recordsets[0]?.length) throw new Error('DECLARED_GRAPH_SOURCE_MISSING:' + capabilityId);
  const graphSource = JSON.parse(graphRead.recordsets[0][0].graph_source);
  graphSource.input = input;
  const result = await executeEstateCapability({ capabilityId: 'run-declared-graph' }, graphSource, context);
  outcome.result = result;
  console.log('DISPOSITION', result.disposition ?? result.contractId);
  console.log('OUTCOME', JSON.stringify(result));
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
