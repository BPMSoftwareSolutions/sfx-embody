import test from 'node:test';
import assert from 'node:assert/strict';
import { readExecutionDelivery } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/delivery-read.mjs';
import { withDeclaredGroundRead } from './kernel-declared-authority.fixture.mjs';

test('execution delivery reads its capability, mappings and default target from declarations', async () => {
  const result = { recordsets: [[{ provider_id: 'declared-cli', configuration: JSON.stringify({ capabilityId: 'declared-executor',
    requestExpression: { op: 'path', path: '' }, resultExpression: { op: 'path', path: '' } }) }], [{ default_target: 'csharp' }]] };
  const delivery = await readExecutionDelivery({ readQuery: withDeclaredGroundRead(async () => result) });
  assert.equal(delivery.capabilityId, 'declared-executor');
  assert.equal(delivery.defaultTarget, 'csharp');
  result.recordsets[0].push(result.recordsets[0][0]);
  await assert.rejects(readExecutionDelivery({ readQuery: withDeclaredGroundRead(async () => result) }), /EXECUTION_DELIVERY_NOT_RESOLVED/);
});
