import test from 'node:test';
import assert from 'node:assert/strict';
import { validateDatabaseCommand } from '../src/invoke-database-capability.mjs';

const envelope = request => ({ deliveryType: 'sfx-command-delivery.v1', operation: 'invoke', request });
const request = { object: 'capability', verb: 'invoke', subject: 'example', input: { contractId: 'example.v1', domain: 'é能力' } };

test('the database boundary preserves canonical input, type and explicit namespace', () => {
  const value = { ...request, namespace: 'declared-namespace' };
  assert.equal(validateDatabaseCommand(envelope(value)), value);
  assert.equal(validateDatabaseCommand(envelope({ ...request, input: null })).input, null);
});

test('the database boundary cannot reinterpret a different entity or unknown command fields', () => {
  assert.throws(() => validateDatabaseCommand(envelope({ ...request, object: 'capsule' })), /DATABASE_OPERATION_NOT_OFFERED/);
  assert.throws(() => validateDatabaseCommand(envelope({ ...request, scenario: 'guessed-root' })), /DATABASE_COMMAND_REJECTED/);
  assert.throws(() => validateDatabaseCommand(envelope({ ...request, namespace: '' })), /DATABASE_COMMAND_REJECTED/);
  const { input, ...missing } = request;
  assert.throws(() => validateDatabaseCommand(envelope(missing)), /CAPABILITY_INPUT_REQUIRED/);
  assert.throws(() => validateDatabaseCommand({ ...envelope(request), fallback: 'disk' }), /DELIVERY_PROTOCOL_REJECTED/);
});
