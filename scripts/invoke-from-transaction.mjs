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
import { readAuthority } from '../src/read-authority.mjs';
import { withDatabaseReadSession } from '../src/database-read-session.mjs';

const DATABASE_ROOT = 'C:/lab/sidefx-database';
const SDA_ROOT = 'C:/lab/repos/scenario-driven-architecture';
const db = (...p) => path.join(DATABASE_ROOT, ...p);

const experimentFile = process.argv[2];
if (!experimentFile) {
  console.error('usage: node --experimental-vm-modules scripts/invoke-from-transaction.mjs <migration.sql> [capabilityId] [input.json] [estate-cases.json]');
  process.exit(2);
}
const capabilityId = process.argv[3] ?? 'hello-world-sql';
const input = JSON.parse(await fs.readFile(process.argv[4] ?? path.resolve('examples/hello-world-sql.request.json'), 'utf8'));

const { connect, sql } = await import(pathToFileURL(db('src/ingest/database.mjs')).href);
const { pinModel } = await import(pathToFileURL(db('src/query/model-pin.mjs')).href);
const { normalizeSql } = await import(pathToFileURL(db('src/query/run.mjs')).href);
const { config, stable, hash, digest } = await import(pathToFileURL(db('src/core.mjs')).href);
const { queryRowLimit } = await config();

let text = await fs.readFile(experimentFile, 'utf8');
const marker = 'ROLLBACK TRANSACTION;';
const at = text.lastIndexOf(marker);
if (at < 0) throw new Error('NO_ROLLBACK_IN_EXPERIMENT');
text = text.slice(0, at);
const batches = text.split(/^\s*GO\s*$/mi).map(s => s.trim()).filter(Boolean);

const outcome = { experimentFile, capabilityId, input, readPath: null, result: null };
await withDatabaseReadSession({ connect, sql, pinModel, normalizeSql, stable, hash, digest, queryRowLimit }, async (readStatement, sessionEvidence) => {
  // Use the production declaration reader with the uncommitted transaction.
  // No second connection or separately maintained read SQL can bypass this proof.
  const readTransactionAuthority = (root, selection, options) => readAuthority(root, selection,
    { ...options, query: readStatement });
  const bundle = await readTransactionAuthority(DATABASE_ROOT, { capabilityId, target: 'node' }, { retainObjects: false });
  const { authority, closure, mechanics } = bundle;
  if (process.argv[6]) await fs.writeFile(process.argv[6], JSON.stringify(bundle, null, 2) + '\n');
  const selected = authority.recordsets[0][0];
  outcome.readPath = { selected: { capability_id: selected.capability_id, scenario_id: selected.scenario_id, namespace_id: selected.namespace_id },
    authorityRows: authority.rowCounts, closureRows: closure.rowCounts, mechanicRows: mechanics.rowCounts };

  const context = { databaseRoot: DATABASE_ROOT, sdaRoot: SDA_ROOT, estateRoot: path.resolve('.'), readAuthority: readTransactionAuthority, readQuery: readStatement };
  context.deliveryTarget = (await readExecutionDelivery(context)).defaultTarget;
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
  const execution = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'invoke',
    request: { object: 'capability', verb: 'invoke', subject: capabilityId, input } }, context);
  const result = execution.outcome.result;
  outcome.evidence = execution.outcome.evidence;
  outcome.evidence.readSession = sessionEvidence;
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
      // A case may declare executeSubject:false when the point is a command on
      // another operation (a reader capability), not the subject's own carrier.
      const result = test.executeSubject === false ? null
        : await executeEstateCapability({ capabilityId: test.capabilityId, scenarioId: test.scenarioId }, test.input, caseContext);
      outcome.currentCase = { name: test.name, result };
      if (test.verifyDatabaseCommand) {
        const command = test.verifyDatabaseCommand;
        let actual;
        try {
          actual = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1',
            operation: command.request.verb, request: command.request }, caseContext);
        } catch (error) {
          // A case may declare the exact failure the estate state must produce.
          if (command.expectedError === undefined || !String(error.message).includes(command.expectedError)) throw error;
          console.log('DATABASE COMMAND VERIFIED (expected error)', JSON.stringify({ error: command.expectedError }));
          outcome.verification.push({ name: test.name, disposition: 'PASSED' });
          delete outcome.currentCase;
          continue;
        }
        if (command.expectedError !== undefined) {
          // A kernel-interpreted failure returns as a failed disposition inside
          // the reader outcome, so the declared failure is matched where it lands.
          const serialized = JSON.stringify(actual);
          const failed = serialized.includes('"disposition":"failed"') || serialized.includes('"code":"CELL_EXECUTION_FAILED"');
          assert.ok(failed && serialized.includes(command.expectedError),
            test.name + ': expected ' + command.expectedError + ' in ' + serialized.slice(0, 1500));
          console.log('DATABASE COMMAND VERIFIED (expected error)', JSON.stringify({ error: command.expectedError }));
          outcome.verification.push({ name: test.name, disposition: 'PASSED' });
          delete outcome.currentCase;
          continue;
        }
        outcome.currentCase.delivery = actual;
        for (const [field, expected] of Object.entries(command.expected))
          assert.deepEqual(field.split('.').reduce((value, key) => value?.[key], actual), expected, test.name + ': ' + field);
        if (command.requireProviderObservation)
          assert.ok(actual.outcome.observations.some(value => value.phase === 'invokeProvider' && value.status === 'completed'), test.name + ': native provider observation');
        console.log('DATABASE COMMAND VERIFIED', JSON.stringify({ disposition: actual.disposition,
          capabilityId: actual.outcome.capabilityId,
          ...(actual.outcome.result === undefined ? { view: actual.outcome.view }
            : { resultDisposition: actual.outcome.result.disposition }) }));
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
      outcome.verification.push({ name: test.name, disposition: 'PASSED' });
      delete outcome.currentCase;
      console.log('VERIFIED', test.name);
    }
  }
}, { beforePin: async tx => {
  for (const batch of batches) await new sql.Request(tx).batch(batch);
  console.log('EXPERIMENT APPLIED (uncommitted)');
} }).catch(error => {
  outcome.error = { message: error.message, stack: error.stack };
  console.error('INVOKE FAILED:', error.message);
  process.exitCode = 1;
});
console.log('RESULT', JSON.stringify(outcome));
