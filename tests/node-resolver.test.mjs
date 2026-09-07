import test from 'node:test';
import assert from 'node:assert/strict';
import Ajv2020 from 'ajv/dist/2020.js';
import { NodeConsumerObjectProvider } from '../src/resolvers/node/consumer-object-provider.mjs';

test('nullable type projection preserves admission constraints and original authority', () => {
  const authority = {
    type: 'object', required: ['value'], additionalProperties: false,
    properties: { value: { type: ['string', 'null'], pattern: '^allowed$', enum: ['allowed', null] } }
  };
  const before = structuredClone(authority);
  const view = NodeConsumerObjectProvider.schemaForTypeProjection(authority, 'contracts/example.json');
  const ajv = new Ajv2020({ strict: false });
  const original = ajv.compile(authority), projected = ajv.compile(view.schema);
  for (const value of [null, {}, { value: null }, { value: 'allowed' }, { value: 'wrong' }, { value: 4 }, { value: [] }, { value: 'allowed', extra: true }]) {
    assert.equal(projected(value), original(value), JSON.stringify(value));
  }
  assert.deepEqual(authority, before);
  assert.equal(view.changes.length, 1);
});

test('relative schema references resolve against their declared id', () => {
  const authority = { $id: 'https://example.invalid/contracts/request.json', type: 'object',
    properties: { value: { $ref: 'common.json#/$defs/value' } } };
  const view = NodeConsumerObjectProvider.schemaForTypeProjection(authority, 'retained/request.json');
  assert.equal(view.schema.properties.value.$ref, 'https://example.invalid/contracts/common.json#/$defs/value');
  assert.equal(authority.properties.value.$ref, 'common.json#/$defs/value');
});

test('literal data that resembles schema remains literal data', () => {
  const authority = { type: 'object', properties: { data: { const: {
    type: ['string', 'null'], $ref: 'ordinary-data', $id: 'ordinary-data', op: 'not-a-mechanic'
  } } } };
  const view = NodeConsumerObjectProvider.schemaForTypeProjection(authority, 'contracts/example.json');
  assert.deepEqual(view.schema, authority);
  assert.deepEqual(view.changes, []);
});

test('unsupported unions remain explicit instead of silently broadening the type', () => {
  assert.throws(() => NodeConsumerObjectProvider.schemaForTypeProjection({ type: ['string', 'number', 'null'] }, 'schema.json'), /SCHEMA_TYPE_UNION_NOT_SUPPORTED/);
});
