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

test('preparation is explicit, selects authority and does not accept invocation input', () => {
  const prepare = { deliveryType: 'sfx-command-delivery.v1', operation: 'prepare', request: { object: 'capability', verb: 'prepare', subject: 'example' } };
  assert.equal(validateDatabaseCommand(prepare), prepare.request);
  assert.throws(() => validateDatabaseCommand({ ...prepare, request: { ...prepare.request, input: null } }), /PREPARATION_INPUT_NOT_OFFERED/);
  assert.throws(() => validateDatabaseCommand({ ...prepare, operation: 'invoke' }), /DATABASE_OPERATION_NOT_OFFERED/);
});

const command = (operation, request) => ({ deliveryType: 'sfx-command-delivery.v1', operation, request });

test('listing and finding select the estate, never a single subject', () => {
  const list = command('list', { object: 'capability', verb: 'list' });
  assert.equal(validateDatabaseCommand(list), list.request);
  assert.equal(validateDatabaseCommand(command('list', { object: 'capability', verb: 'list', namespace: 'declared' })).namespace, 'declared');
  assert.throws(() => validateDatabaseCommand(command('list', { object: 'capability', verb: 'list', subject: 'example' })), /DATABASE_COMMAND_REJECTED/);
  assert.throws(() => validateDatabaseCommand(command('list', { object: 'capability', verb: 'list', query: 'example' })), /DATABASE_COMMAND_REJECTED/);
  assert.throws(() => validateDatabaseCommand(command('list', { object: 'capability', verb: 'list', input: {} })), /OPERATION_INPUT_NOT_OFFERED/);

  const find = command('find', { object: 'capability', verb: 'find', query: 'cited evidence' });
  assert.equal(validateDatabaseCommand(find), find.request);
  assert.throws(() => validateDatabaseCommand(command('find', { object: 'capability', verb: 'find' })), /DATABASE_COMMAND_REJECTED/);
  assert.throws(() => validateDatabaseCommand(command('find', { object: 'capability', verb: 'find', query: '' })), /DATABASE_COMMAND_REJECTED/);
  assert.throws(() => validateDatabaseCommand(command('find', { object: 'capability', verb: 'find', query: 'q', subject: 'example' })), /DATABASE_COMMAND_REJECTED/);
});

test('reveal offers only the views the estate declares', () => {
  const reveal = view => command('reveal', { object: 'capability', verb: 'reveal', subject: 'example', ...(view === undefined ? {} : { as: view }) });
  // An unqualified reveal is the capability's canonical story; the delivery, not
  // the caller's spelling, decides that default.
  assert.equal(validateDatabaseCommand(reveal()).as, undefined);
  for (const view of ['meaning', 'circuit']) assert.equal(validateDatabaseCommand(reveal(view)).as, view);
  assert.throws(() => validateDatabaseCommand(reveal('blueprint')), /CAPABILITY_VIEW_NOT_OFFERED/);
  assert.throws(() => validateDatabaseCommand(reveal('')), /DATABASE_COMMAND_REJECTED/);
  // A view may select a declared scenario; invocation may not.
  assert.equal(validateDatabaseCommand(command('reveal', { object: 'capability', verb: 'reveal', subject: 'example', scenario: 'declared-scenario' })).scenario, 'declared-scenario');
  assert.throws(() => validateDatabaseCommand(command('invoke', { object: 'capability', verb: 'invoke', subject: 'example', input: null, as: 'meaning' })), /DATABASE_COMMAND_REJECTED/);
});

test('observation carries invocation unchanged and stays a distinct declared operation', () => {
  const observe = { object: 'capability', verb: 'observe', subject: 'example', input: { contractId: 'example.v1' } };
  assert.equal(validateDatabaseCommand(command('observe', observe)), observe);
  const { input, ...missing } = observe;
  assert.throws(() => validateDatabaseCommand(command('observe', missing)), /CAPABILITY_INPUT_REQUIRED/);
  // The verb and the delivered operation must agree: neither renames the other.
  assert.throws(() => validateDatabaseCommand(command('invoke', observe)), /DATABASE_OPERATION_NOT_OFFERED/);
  assert.throws(() => validateDatabaseCommand(command('observe', { ...observe, verb: 'invoke' })), /DATABASE_OPERATION_NOT_OFFERED/);
});

test('reveal formats the narrated view only, and only as the estate offers', () => {
  const reveal = extra => command('reveal', { object: 'capability', verb: 'reveal', subject: 'example', ...extra });
  // An unqualified reveal picks its own default; the caller never spells it.
  assert.equal(validateDatabaseCommand(reveal({})).format, undefined);
  for (const format of ['text', 'markdown']) assert.equal(validateDatabaseCommand(reveal({ format })).format, format);
  assert.throws(() => validateDatabaseCommand(reveal({ format: 'pdf' })), /CAPABILITY_FORMAT_NOT_OFFERED/);
  assert.throws(() => validateDatabaseCommand(reveal({ format: '' })), /DATABASE_COMMAND_REJECTED/);
  // A retained circuit is delivered as the publication retains it. Asking to
  // format it is refused rather than accepted and quietly ignored.
  assert.throws(() => validateDatabaseCommand(reveal({ as: 'circuit', format: 'markdown' })), /CAPABILITY_FORMAT_NOT_OFFERED/);
  assert.equal(validateDatabaseCommand(reveal({ as: 'meaning', format: 'markdown' })).format, 'markdown');
  // Only an operation declaring a presentation accepts one.
  assert.throws(() => validateDatabaseCommand(command('list', { object: 'capability', verb: 'list', format: 'markdown' })), /DATABASE_COMMAND_REJECTED/);
  assert.throws(() => validateDatabaseCommand(command('invoke', { object: 'capability', verb: 'invoke', subject: 'example', input: null, format: 'markdown' })), /DATABASE_COMMAND_REJECTED/);
});
