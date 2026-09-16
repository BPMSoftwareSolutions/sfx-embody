import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import { createDatabaseConnectBoundary } from '../src/database-connect-boundary.mjs';

const CONNECTION_NAME = 'SFX_TEST_CONNECTION_STRING';
const CONNECTION_VALUE = 'Server=test;Database=test;User Id=reader;Password=not-retained';

function fakeSql({ parseFailure = false, connectFailure = null } = {}) {
  const calls = { parse: 0, connect: 0, close: 0 };
  class ConnectionPool {
    static parseConnectionString(value) {
      calls.parse++;
      calls.parsedValue = value;
      if (parseFailure) throw new Error('parse');
      return { server: 'test' };
    }
    constructor(parsed) { this.parsed = parsed; }
    on() {}
    async connect() {
      calls.connect++;
      if (connectFailure) throw Object.assign(new Error(connectFailure), { code: connectFailure });
      return this;
    }
    async close() { calls.close++; }
  }
  return { sql: { ConnectionPool }, calls };
}

test('the connection boundary parses and opens the pool at connect time without touching process.env', async () => {
  const { sql, calls } = fakeSql();
  const environment = Object.keys(process.env);
  const connect = createDatabaseConnectBoundary({ sql, connectionString: CONNECTION_VALUE,
    connectionName: CONNECTION_NAME, requestTimeoutMs: 600000 });
  assert.equal(calls.parse, 0, 'parsing must wait for the connect boundary');
  const pool = await connect();
  assert.equal(calls.parse, 1);
  assert.equal(calls.parsedValue, CONNECTION_VALUE);
  assert.equal(calls.connect, 1);
  assert.equal(pool.parsed.requestTimeout, 600000);
  assert.deepEqual(pool.parsed.pool, { max: 2, min: 0, idleTimeoutMillis: 10000 });
  assert.equal(process.env[CONNECTION_NAME], undefined);
  assert.deepEqual(Object.keys(process.env), environment);
});

test('an invalid connection string refuses at the boundary and never opens a pool', async () => {
  const { sql, calls } = fakeSql({ parseFailure: true });
  const connect = createDatabaseConnectBoundary({ sql, connectionString: CONNECTION_VALUE,
    connectionName: CONNECTION_NAME, requestTimeoutMs: 1000 });
  await assert.rejects(connect(), /INVALID_OR_MISSING_SQL_CONNECTION_CONFIGURATION:SFX_TEST_CONNECTION_STRING/);
  assert.equal(calls.connect, 0);
  assert.equal(calls.close, 0);
});

test('an absent connection string refuses before any pool exists', async () => {
  const { sql, calls } = fakeSql();
  const connect = createDatabaseConnectBoundary({ sql, connectionString: '',
    connectionName: CONNECTION_NAME, requestTimeoutMs: 1000 });
  await assert.rejects(connect(), /INVALID_OR_MISSING_SQL_CONNECTION_CONFIGURATION:SFX_TEST_CONNECTION_STRING/);
  assert.equal(calls.parse, 0);
});

test('a failed connect closes its own pool and reports the driver code', async () => {
  const { sql, calls } = fakeSql({ connectFailure: 'ELOGIN' });
  const connect = createDatabaseConnectBoundary({ sql, connectionString: CONNECTION_VALUE,
    connectionName: CONNECTION_NAME, requestTimeoutMs: 1000 });
  await assert.rejects(connect(), /DATABASE_CONNECTION_FAILED:ELOGIN/);
  assert.equal(calls.close, 1);
});

test('the delivery boot resolves at the connect boundary and never copies the string into process.env', async () => {
  const source = await fs.readFile(new URL('../src/database-delivery.mjs', import.meta.url), 'utf8');
  assert.match(source, /createDatabaseConnectBoundary/);
  assert.equal(/process\.env\s*\[/.test(source), false);
  assert.equal(source.includes('process.env[connectionEnvironmentVariable]'), false);
});
