import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { loadConsumerPlan } from '../src/load-consumer-plan.mjs';
import { readExecutionDelivery } from '../src/read-execution-delivery.mjs';

const hash = bytes => 'sha256:' + createHash('sha256').update(bytes).digest('hex');
const bytes = value => Buffer.from(JSON.stringify(value));

test('consumer plan loading checks every declared byte and the plan named by its binding', async () => {
  const plan = bytes({ canonicalGraph: { graphId: 'declared' } });
  const files = new Map([
    ['body/plan.json', plan], ['evidence/fixtures.json', bytes({ fixtures: [] })],
    ['evidence/conformance.json', bytes({ disposition: 'CANDIDATE' })],
    ['body/binding.json', bytes({ executionPlan: 'plan.json', executionPlanDigest: hash(plan),
      fixtures: '../evidence/fixtures.json', mechanicalSterility: '../evidence/conformance.json',
      executionAuthority: { target: 'selected' }, providerBindings: [] })]
  ]);
  const manifest = { files: [...files].map(([relativePath, content]) => ({ relativePath, digest: hash(content) })) };
  const loaded = await loadConsumerPlan(manifest, 'body/binding.json', name => files.get(name));
  assert.equal(loaded.plan.canonicalGraph.graphId, 'declared');
  assert.equal(loaded.conformance.disposition, 'CANDIDATE');
  files.set('evidence/fixtures.json', bytes({ fixtures: [{ input: 'replaced' }] }));
  await assert.rejects(loadConsumerPlan(manifest, 'body/binding.json', name => files.get(name)), /EMBODIMENT_WRITE_DIGEST_MISMATCH/);
  files.set('evidence/fixtures.json', bytes({ fixtures: [] }));
  const binding = JSON.parse(files.get('body/binding.json'));
  binding.executionPlan = '../../outside.json';
  files.set('body/binding.json', bytes(binding));
  manifest.files.find(file => file.relativePath === 'body/binding.json').digest = hash(bytes(binding));
  await assert.rejects(loadConsumerPlan(manifest, 'body/binding.json', name => files.get(name)), /EMBODIMENT_FILE_NOT_DECLARED/);
});

test('execution delivery reads its capability, mappings and default target from declarations', async () => {
  const result = { recordsets: [[{ provider_id: 'declared-cli', configuration: JSON.stringify({ capabilityId: 'declared-executor',
    requestExpression: { op: 'path', path: '' }, resultExpression: { op: 'path', path: '' } }) }], [{ default_target: 'csharp' }]] };
  const delivery = await readExecutionDelivery({ readQuery: async () => result });
  assert.equal(delivery.capabilityId, 'declared-executor');
  assert.equal(delivery.defaultTarget, 'csharp');
  result.recordsets[0].push(result.recordsets[0][0]);
  await assert.rejects(readExecutionDelivery({ readQuery: async () => result }), /EXECUTION_DELIVERY_NOT_RESOLVED/);
});
