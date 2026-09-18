import test from 'node:test';
import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { createHash } from 'node:crypto';
import { withDatabaseReadSession } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/database-read-session.mjs';

const digest = value => 'sha256:' + createHash('sha256').update(value).digest('hex');
const stable = JSON.stringify;
const hash = value => digest(stable(value));
const pinned = { estate_model_pk: 17, snapshot_id: 'snapshot', projection_id: 'projection', viewDefinitionDigest: 'views' };

function database({ fail, query, rollbackFailure, closeFailure } = {}) {
  const events = [], requests = [];
  let borrowed = false;
  const step = name => { events.push(name); if (fail === name) throw new Error(name); };
  const pool = { async close() { assert.equal(borrowed, false, 'a borrowed connection would hang pool.close'); step('close'); if (closeFailure) throw new Error('close'); } };
  class Transaction extends EventEmitter {
    constructor(connection) { super(); assert.equal(connection, pool); step('transaction'); this.on('rollback', () => { borrowed = false; }); }
    async begin() { borrowed = true; step('begin'); }
    async rollback() { borrowed = false; step('rollback'); if (rollbackFailure) throw new Error('rollback'); this.emit('rollback'); }
  }
  class Request {
    constructor(tx) { this.tx = tx; this.parameters = {}; }
    input(name, type, value) { this.parameters[name] = { type, value }; return this; }
    async batch(statement) { step('reader'); assert.match(statement, /EXECUTE AS USER='sidefx_reader' WITH NO REVERT/); }
    async query(statement) {
      step('query');
      requests.push(this);
      return query ? query(this, statement) : { recordsets: [[{ value: 1 }, { value: 2 }], []] };
    }
  }
  const dependencies = {
    async connect() { step('connect'); return pool; },
    sql: { Transaction, Request, BigInt: 'bigint', VarChar: n => `varchar(${n})`, NVarChar: n => `nvarchar(${n})`, MAX: 'max' },
    async pinModel() { step('pin'); return pinned; },
    normalizeSql: row => ({ ...row, normalized: true }), stable, hash, digest, queryRowLimit: 1
  };
  return { dependencies, events, requests };
}

test('one session pins once, keeps query identities and normalization, and always rolls back', async () => {
  const { dependencies, events, requests } = database();
  let escapedQuery, evidence;
  const result = await withDatabaseReadSession(dependencies, async (read, proof) => {
    escapedQuery = read;
    evidence = proof;
    const first = await read('SELECT @input', { input: { name: "Zo\u00eb'; SELECT 1 --" } });
    const second = await read('SELECT @input', { input: null, rowLimit: 10 });
    assert.deepEqual(first.recordsets, [[{ value: 1, normalized: true }], []]);
    assert.equal(first.truncated, true);
    assert.equal(first.disposition, 'READ_QUERY_TRUNCATED');
    assert.equal(first.resultObjectDigest, hash(first.recordsets));
    assert.equal(first.resultDigest, hash(first.recordsets.map(rows => rows.map(stable).sort())));
    assert.equal(second.truncated, false);
    assert.equal(second.snapshotId, first.snapshotId);
    assert.equal(second.projectionDigest, first.projectionDigest);
    assert.equal(second.viewDefinitionDigest, first.viewDefinitionDigest);
    assert.equal(second.objectRetention, 'MEMORY_ONLY');
    return 'completed';
  });
  assert.equal(result, 'completed');
  assert.deepEqual(events, ['connect', 'transaction', 'begin', 'pin', 'reader', 'query', 'query', 'rollback', 'close']);
  assert.equal(requests[0].tx, requests[1].tx);
  assert.equal(requests[0].parameters.input.value, JSON.stringify({ name: "Zo\u00eb'; SELECT 1 --" }));
  assert.equal(requests[1].parameters.input.value, 'null');
  assert.equal(requests[0].parameters.estate_model_pk.value, 17);
  assert.equal(requests[0].parameters.view_definition_digest.value, 'views');
  assert.deepEqual([evidence.connections, evidence.pins, evidence.readerSwitches, evidence.queries], [1, 1, 1, 2]);
  assert.ok(evidence.totalMs >= evidence.setupMs);
  await assert.rejects(escapedQuery('SELECT 1'), /DATABASE_READ_SESSION_CLOSED/);
});

test('concurrent graph reads are serialized with independent inputs', async () => {
  let active = false;
  const { dependencies, requests } = database({ query: async () => {
    assert.equal(active, false);
    active = true;
    await new Promise(resolve => setImmediate(resolve));
    active = false;
    return { recordsets: [[]] };
  } });
  await withDatabaseReadSession(dependencies, async read => {
    const input = { number: 1 };
    const a = read('first', { input });
    input.number = 2;
    const b = read('second', { input });
    const c = read('omitted');
    await Promise.all([a, b, c]);
  });
  assert.deepEqual(requests.map(r => r.parameters.input.value), ['{"number":1}', '{"number":2}', null]);
});

test('a new invocation opens and pins its own session', async () => {
  const { dependencies, events, requests } = database();
  for (let i = 0; i < 2; i++) await withDatabaseReadSession(dependencies, read => read('SELECT 1'));
  assert.equal(events.filter(e => e === 'connect').length, 2);
  assert.equal(events.filter(e => e === 'pin').length, 2);
  assert.equal(events.filter(e => e === 'close').length, 2);
  assert.notEqual(requests[0].tx, requests[1].tx);
});

test('read sessions reject retention, unpinned inspection and invalid inputs before issuing SQL', async () => {
  const { dependencies, requests } = database();
  await withDatabaseReadSession(dependencies, async read => {
    for (const rowLimit of [0, -1, 1.5, 100001, null]) await assert.rejects(read('SELECT 1', { rowLimit }), /INVALID_QUERY_ROW_LIMIT/);
    await assert.rejects(read('SELECT 1', { retainObjects: 'false' }), /INVALID_QUERY_OBJECT_RETENTION/);
    await assert.rejects(read('SELECT 1', { retainObjects: true }), /DATABASE_READ_SESSION_MEMORY_ONLY/);
    await assert.rejects(read('SELECT 1', { writeReceipt: true }), /DATABASE_READ_SESSION_MEMORY_ONLY/);
    await assert.rejects(read('SELECT 1', { committed: true }), /DATABASE_READ_SESSION_REQUIRES_PIN/);
    await assert.rejects(read(' '), /QUERY_TEXT_REQUIRED/);
    await assert.rejects(read('SELECT @input', { input: () => {} }), /QUERY_INPUT_MUST_BE_JSON/);
  });
  assert.equal(requests.length, 0);
});

for (const phase of ['connect', 'transaction', 'begin', 'pin', 'reader', 'query', 'rollback', 'close']) {
  test(`session cleanup on ${phase} failure`, async () => {
    const { dependencies, events } = database({ fail: phase });
    await assert.rejects(withDatabaseReadSession(dependencies, read => read('SELECT 1')), new RegExp(phase));
    assert.equal(events.filter(e => e === 'close').length, phase === 'connect' ? 0 : 1);
    assert.equal(events.filter(e => e === 'rollback').length, ['connect', 'transaction'].includes(phase) ? 0 : 1);
    assert.ok(!events.includes('commit'));
  });
}

test('invocation failure survives cleanup failures', async () => {
  const { dependencies, events } = database({ rollbackFailure: true, closeFailure: true });
  const original = new Error('provider failed');
  await assert.rejects(withDatabaseReadSession(dependencies, async () => { throw original; }), error => error === original);
  assert.deepEqual(events.slice(-2), ['rollback', 'close']);
});

test('SQL failure never falls back to another connection or issues queued SQL', async () => {
  const { dependencies, events } = database({ fail: 'query' });
  await withDatabaseReadSession(dependencies, async read => {
    const results = await Promise.allSettled([read('first'), read('second')]);
    assert.deepEqual(results.map(r => r.status), ['rejected', 'rejected']);
  });
  assert.equal(events.filter(e => e === 'query').length, 1);
  assert.equal(events.filter(e => e === 'connect').length, 1);
});

test('automatic SQL rollback still closes the dedicated pool', async () => {
  const { dependencies, events } = database({ query: async request => {
    request.tx.emit('rollback', true);
    throw new Error('SQL aborted');
  } });
  await assert.rejects(withDatabaseReadSession(dependencies, read => read('SELECT 1')), /SQL aborted/);
  assert.equal(events.filter(e => e === 'rollback').length, 0);
  assert.equal(events.at(-1), 'close');
});

test('preflight preparation runs on the owned transaction before the production pin and reader switch', async () => {
  const { dependencies, events, requests } = database();
  let prepared;
  await withDatabaseReadSession(dependencies, read => read('SELECT 1'), { beforePin: async tx => {
    prepared = tx;
    events.push('migration');
  } });
  assert.equal(requests[0].tx, prepared);
  assert.deepEqual(events, ['connect', 'transaction', 'begin', 'migration', 'pin', 'reader', 'query', 'rollback', 'close']);
  const failing = database();
  await assert.rejects(withDatabaseReadSession(failing.dependencies, () => assert.fail('must not invoke'), {
    beforePin: async () => { throw new Error('migration failed'); }
  }), /migration failed/);
  assert.deepEqual(failing.events, ['connect', 'transaction', 'begin', 'rollback', 'close']);
});
