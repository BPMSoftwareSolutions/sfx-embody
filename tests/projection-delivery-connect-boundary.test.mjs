import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import { createDatabaseConnectBoundary } from '../src/database-connect-boundary.mjs';

const CONNECTION_NAME = 'SFX_TEST_PROJECTION_CONNECTION_STRING';
const CONNECTION_VALUE = 'Server=test;Database=test;User Id=reader;Password=not-retained';

function fakeSql() {
  const calls = { parse: 0, connect: 0 };
  class ConnectionPool {
    static parseConnectionString(value) { calls.parse++; calls.parsedValue = value; return { server: 'test' }; }
    constructor(parsed) { this.parsed = parsed; }
    on() {}
    async connect() { calls.connect++; return this; }
    async close() {}
  }
  return { sql: { ConnectionPool }, calls };
}

// The projection delivery had the same env-copy defect that was removed at the
// invocation delivery: it wrote the connection string into process.env before
// the read session. It now resolves the string in the connect boundary closure.
test('the projection boot resolves at the connect boundary and never copies the string into process.env', async () => {
  const source = await fs.readFile(new URL('../src/projection-delivery.mjs', import.meta.url), 'utf8');
  assert.match(source, /createDatabaseConnectBoundary/);
  assert.equal(/process\.env\s*\[/.test(source), false);
  assert.equal(source.includes('process.env[connectionEnvironmentVariable]'), false);
  assert.match(source, /connectionName: connectionEnvironmentVariable/);
});

test('the projection connect boundary parses and opens without touching process.env', async () => {
  const { sql, calls } = fakeSql();
  const environment = Object.keys(process.env);
  const connect = createDatabaseConnectBoundary({ sql, connectionString: CONNECTION_VALUE,
    connectionName: CONNECTION_NAME, requestTimeoutMs: 600000 });
  assert.equal(calls.parse, 0, 'parsing waits for the connect boundary');
  const pool = await connect();
  assert.equal(calls.parse, 1);
  assert.equal(calls.parsedValue, CONNECTION_VALUE);
  assert.equal(calls.connect, 1);
  assert.equal(pool.parsed.requestTimeout, 600000);
  assert.equal(process.env[CONNECTION_NAME], undefined);
  assert.deepEqual(Object.keys(process.env), environment);
});
