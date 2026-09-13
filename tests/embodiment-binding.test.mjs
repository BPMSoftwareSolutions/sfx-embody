import test from 'node:test';
import assert from 'node:assert/strict';
import { readDatabaseQuery } from '../src/resolvers/node/database-query-provider.mjs';
import { planCapabilityEmbodiment } from '../src/resolvers/node/embodiment-plan-provider.mjs';
import { readCapabilityAuthority } from '../src/resolvers/node/authority-read-provider.mjs';

test('the authority reader selects the declared default target', async () => {
  const result = await readCapabilityAuthority({ defaultTarget: 'python' }, { capabilityId: 'read-authorized-file' }, {
    readAuthority: async (_root, selection) => {
      assert.equal(selection.target, 'python');
      return { authority: { recordsets: [[{ scenario_id: 'read-authorized-file' }], [], [], [
        { target_id: 'python', effect_classification: 'pure' },
        { target_id: 'python', effect_classification: 'effect' },
      ]] }, closure: {}, mechanics: {} };
    },
  });
  assert.equal(result.target, 'python');
});

test('a missing profile cannot use another target\'s implementation', async () => {
  await assert.rejects(readCapabilityAuthority({ profileAbsent: 'PROFILE_PROVIDER_ABSENT' }, {
    capabilityId: 'read-authorized-file', target: 'python',
  }, { readAuthority: async () => ({ authority: { recordsets: [[], [], [], [
    { target_id: 'node', effect_classification: 'pure' },
    { target_id: 'node', effect_classification: 'effect' },
  ]] } }) }), /PROFILE_PROVIDER_ABSENT:python:pure:0/);
});

test('declared database reads use the supplied transaction and retain no objects', async () => {
  const input = { snapshotId: 'selected-generation' };
  const configuration = { statement: 'SELECT @input AS result_json', resultColumn: 'result_json' };
  const result = await readDatabaseQuery(configuration, input, { readQuery: async (statement, options) => {
    assert.equal(statement, configuration.statement);
    assert.deepEqual(options, { input, rowLimit: 1, retainObjects: false });
    return { truncated: false, recordsets: [[{ result_json: JSON.stringify(input) }]] };
  } });
  assert.deepEqual(result, input);
});

test('an incomplete or ambiguous query result cannot become a declaration', async () => {
  for (const result of [
    { truncated: true, recordsets: [[{ result_json: '{}' }]] },
    { truncated: false, recordsets: [[]] },
    { truncated: false, recordsets: [[{ result_json: '{}' }, { result_json: '{}' }]] },
  ]) {
    await assert.rejects(readDatabaseQuery({ statement: 'SELECT 1', resultColumn: 'result_json' }, {}, {
      readQuery: async () => result,
    }), /DATABASE_AUTHORITY_NOT_COHERENT/);
  }
});

test('the declared admission failure preserves findings and prevents body planning', async () => {
  const input = { disposition: 'PROVIDER_SLOT_UNBOUND', findings: [{ code: 'PROVIDER_IMPLEMENTATION_ABSENT', slotId: 'observe-authorized-file' }] };
  const original = structuredClone(input);
  const result = await planCapabilityEmbodiment({
    inputField: 'authorityDeclaration',
    inputAdmission: { type: 'object', required: ['disposition'], properties: { disposition: { const: 'PROVIDER_SLOTS_BOUND' } } },
    admissionFailure: { contractId: 'capability-embodiment-plan.v1', disposition: 'EMBODIMENT_PLAN_HELD' },
    failureFields: ['findings'],
  }, input, {});
  assert.deepEqual(result, { contractId: 'capability-embodiment-plan.v1', disposition: 'EMBODIMENT_PLAN_HELD', findings: input.findings });
  assert.deepEqual(input, original);
});
