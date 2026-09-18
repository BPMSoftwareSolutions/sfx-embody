import test from 'node:test';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { EventEmitter } from 'node:events';
import { createDatabaseConnectBoundary, connectionString, sql } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/database-connect-boundary.mjs';
import { withDatabaseReadSession, digest, hash, normalizeSql, pinModel, stable } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/database-read-session.mjs';

// The one-shot sidefx-database reader this file compared against is retired
// with the loader; the remaining cases run on the kernel ground.
const enabled = process.env.SFX_DATABASE_INTEGRATION === '1';
const CONNECTION_NAME = 'sidefx-connection-string';

async function database() {
  const sdaRoot = fileURLToPath(new URL('../../scenario-driven-architecture/', import.meta.url));
  const connect = createDatabaseConnectBoundary({ sql, connectionString: connectionString(CONNECTION_NAME),
    connectionName: CONNECTION_NAME, requestTimeoutMs: 600000 });
  return { sdaRoot, connect, sql, normalizeSql, pinModel, stable, hash, digest, queryRowLimit: 1000 };
}

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

test('the kernel session releases a borrowed connection when transaction begin fails', async () => {
  const connection = new EventEmitter();
  let borrowed = false, closed = false, releases = 0;
  connection.beginTransaction = callback => queueMicrotask(() => callback(new Error('begin failed after acquire')));
  connection.rollbackTransaction = callback => queueMicrotask(() => callback());
  const pool = {
    acquire(_, callback) { borrowed = true; queueMicrotask(() => callback(null, connection, {})); },
    release(value) { assert.equal(value, connection); borrowed = false; releases++; },
    async close() { assert.equal(borrowed, false); closed = true; }
  };
  await assert.rejects(withDatabaseReadSession({
    connect: async () => pool, sql,
    pinModel: async () => { throw new Error('a failed begin must never pin'); },
    normalizeSql, stable, hash, digest, queryRowLimit: 1000
  }, () => assert.fail('failed begin must never invoke')), /begin failed after acquire/);
  assert.equal(releases, 1);
  assert.equal(closed, true);
});
