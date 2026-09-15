import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import { EventEmitter } from 'node:events';
import { withDatabaseReadSession } from '../src/database-read-session.mjs';

const enabled = process.env.SFX_DATABASE_INTEGRATION === '1';

async function database() {
  const file = new URL('../config/database-runtime.json', import.meta.url);
  const runtime = JSON.parse(await fs.readFile(file, 'utf8'));
  const root = new URL(runtime.databaseRoot.replaceAll('\\', '/') + '/', file);
  const core = await import(new URL('src/core.mjs', root));
  const { connect, sql, connectionString } = await import(new URL('src/ingest/database.mjs', root));
  const { query, normalizeSql } = await import(new URL('src/query/run.mjs', root));
  const { pinModel } = await import(new URL('src/query/model-pin.mjs', root));
  const { connectionEnvironmentVariable, queryRowLimit } = await core.config();
  process.env[connectionEnvironmentVariable] = connectionString(connectionEnvironmentVariable);
  return { connect, sql, query, normalizeSql, pinModel, ...core, queryRowLimit };
}

test('SQL session results match the one-shot reader, including Unicode, digests and post-computation limits', { skip: !enabled }, async () => {
  const dependencies = await database();
  const statement = `DECLARE @numbers TABLE(n int);
    INSERT @numbers VALUES(3),(1),(2);
    SELECT n, @input AS input_json, CONVERT(datetime2,'2026-09-14T12:00:00') AS at,
      CONVERT(varbinary(max),0x00FF80) AS bytes, CONVERT(bigint,9007199254740993) AS big
    FROM @numbers ORDER BY n;
    SELECT COUNT(*) AS complete_count FROM @numbers;`;
  const options = { input: { name: "Zo\u00eb \u80fd\u529b'; SELECT 1 --" }, rowLimit: 1, retainObjects: false };
  const expected = await dependencies.query(statement, options);
  const actual = await withDatabaseReadSession(dependencies, read => read(statement, options));
  assert.deepEqual(actual, expected);
  assert.equal(actual.recordsets[1][0].complete_count, 3);
  assert.equal(actual.truncated, true);
});

test('SQL reader principal and shared model lock last for the whole session, then release', { skip: !enabled }, async () => {
  const dependencies = await database();
  const { connect, sql } = dependencies;
  const contender = await connect();
  const exclusiveLock = async () => {
    const tx = new sql.Transaction(contender);
    await tx.begin();
    try {
      const result = await new sql.Request(tx).query(`DECLARE @result int;
        EXEC @result=sys.sp_getapplock @Resource='sidefx:model-write', @LockMode='Exclusive', @LockOwner='Transaction', @LockTimeout=0;
        SELECT @result AS lock_result;`);
      return result.recordset[0].lock_result;
    } finally { await tx.rollback(); }
  };
  try {
    await withDatabaseReadSession(dependencies, async read => {
      const statement = `SELECT USER_NAME() AS principal, @@SPID AS session_id,
        HAS_PERMS_BY_NAME('model.capability','OBJECT','INSERT') AS can_insert,
        HAS_PERMS_BY_NAME('model.capability','OBJECT','UPDATE') AS can_update,
        HAS_PERMS_BY_NAME('model.capability','OBJECT','DELETE') AS can_delete;`;
      const first = (await read(statement)).recordsets[0][0];
      assert.equal(first.principal, 'sidefx_reader');
      assert.deepEqual([first.can_insert, first.can_update, first.can_delete], [0, 0, 0]);
      assert.equal(await exclusiveLock(), -1);
      const second = (await read(statement)).recordsets[0][0];
      assert.deepEqual(second, first);
      assert.equal(await exclusiveLock(), -1);
    });
    assert.ok(await exclusiveLock() >= 0);
    await assert.rejects(withDatabaseReadSession(dependencies, read => read('REVERT; SELECT USER_NAME() AS principal;')));
    assert.ok(await exclusiveLock() >= 0);
  } finally { await contender.close(); }
});

test('the installed SQL driver releases a borrowed connection when transaction begin fails', { skip: !enabled }, async () => {
  const dependencies = await database();
  const connection = new EventEmitter();
  let borrowed = false, closed = false, releases = 0;
  connection.beginTransaction = callback => queueMicrotask(() => callback(new Error('begin failed after acquire')));
  connection.rollbackTransaction = callback => queueMicrotask(() => callback());
  const pool = {
    acquire(_, callback) { borrowed = true; queueMicrotask(() => callback(null, connection, {})); },
    release(value) { assert.equal(value, connection); borrowed = false; releases++; },
    async close() { assert.equal(borrowed, false); closed = true; }
  };
  await assert.rejects(withDatabaseReadSession({ ...dependencies, connect: async () => pool },
    () => assert.fail('failed begin must never invoke')), /begin failed after acquire/);
  assert.equal(releases, 1);
  assert.equal(closed, true);
});
