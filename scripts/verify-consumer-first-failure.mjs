import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { readFixtureConsumerPlan } from './verify-consumer-fixtures.mjs';
import { executeConsumerPlan } from '../src/resolvers/node/consumer-execution-provider.mjs';

// Negative conformance inputs run the selected native provider. The observed
// execution then enters the outcome-admission Port selected in this transaction.
// No fixture supplies a claimed execution result or alters installed authority.
export async function verifyConsumerFirstFailure(declaration, test, context) {
  const read = await readFixtureConsumerPlan(declaration, context);
  const query = context.readQuery ?? (await import(pathToFileURL(path.join(context.databaseRoot, 'src/query/run.mjs')).href)).query;
  const records = await query(`SELECT definition_json FROM analysis.v_selected_semantic_definition
    WHERE estate_model_pk=@estate_model_pk AND object_kind='PORT'
      AND namespace_id='sidefx:capability:execute-declared-capability' AND declared_id='admit-execution-outcome'`, { input: {}, retainObjects: false });
  assert.equal(records.recordsets[0].length, 1);
  const configuration = JSON.parse(records.recordsets[0][0].definition_json).semantics.configuration;
  const provider = await import(pathToFileURL(path.resolve(context.estateRoot, configuration.estateProvider.module)).href);
  const scenario = read.plan.canonicalGraph.cells.find(cell => cell.cellId === read.plan.canonicalGraph.rootCellId);
  const frame = { plan: read.plan, scenario, scenarioInput: test.scenarioInput, executionAuthority: read.executionAuthority,
    providerBindings: read.providerBindings, authorityIdentity: read.result };
  const cases = [
    { name: 'native input rejection', frame: { ...frame, scenarioInput: {} }, expected: 'INPUT_REJECTED', native: 'rejected' },
    { name: 'native outcome rejection', frame: structuredClone(frame), expected: 'OUTCOME_REJECTED', native: 'rejected' },
    { name: 'bound provider export absent', frame: structuredClone(frame), expected: 'EXECUTION_FAILED', native: 'failed' }
  ];
  const contract = cases[1].frame.plan.contractCatalog.contracts[scenario.outcome.contractId];
  contract.schema = { $id: contract.schema.$id, $schema: contract.schema.$schema, not: {} };
  contract.schemaDigest = createHash('sha256').update(JSON.stringify(contract.schema)).digest('hex');
  assert.ok(cases[2].frame.providerBindings.length);
  cases[2].frame.providerBindings[0].providerExport = 'missingExportForConformance';
  const evidence = [];
  for (const candidate of cases) {
    const execution = await executeConsumerPlan({}, candidate.frame, { ...context, effectContextOverrides: { credentialReader: () => undefined } });
    assert.equal(execution.result.disposition, candidate.native, candidate.name);
    const observed = await provider[configuration.estateProvider.export](configuration, { ...candidate.frame, execution }, context);
    evidence.push({ name: candidate.name, execution, observed });
    if (test.evidenceFile) await fs.writeFile(test.evidenceFile, JSON.stringify({ target: declaration.target, cases: evidence }, null, 2) + '\n');
    assert.equal(observed.disposition, candidate.expected, candidate.name);
    assert.deepEqual(observed.execution, execution, candidate.name + ': preserve the exact native execution');
    assert.deepEqual(observed.authorityIdentity, frame.authorityIdentity, candidate.name + ': preserve authority identity');
  }
  return { target: declaration.target, cases: evidence.map(({ name, observed }) => ({ name, disposition: observed.disposition })) };
}
