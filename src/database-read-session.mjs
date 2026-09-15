// One invocation owns one pinned, impersonated connection. Never reuse it across
// invocations: NO REVERT survives rollback, so its dedicated pool must be closed.
export async function withDatabaseReadSession({ connect, sql, pinModel, normalizeSql, stable, hash, digest, queryRowLimit }, invoke, { beforePin } = {}) {
  const started = performance.now();
  const evidence = { connections: 0, pins: 0, readerSwitches: 0, queries: 0 };
  const pool = await connect();
  evidence.connections++;
  let tx, beginning = false, begun = false, accepting = false, failure, result, queryFailure;
  let pending = Promise.resolve();
  try {
    tx = new sql.Transaction(pool);
    tx.on('rollback', () => { begun = false; });
    beginning = true;
    await tx.begin();
    beginning = false;
    begun = true;
    // Bootstrap preflight applies its rollback migration before the same pin and
    // reader boundary that production uses. The delivery supplies no such hook.
    await beforePin?.(tx);
    const pinned = await pinModel(tx);
    evidence.pins++;
    await new sql.Request(tx).batch("EXECUTE AS USER='sidefx_reader' WITH NO REVERT; SET LOCK_TIMEOUT 30000;");
    evidence.readerSwitches++;
    evidence.setupMs = performance.now() - started;
    accepting = true;
    const readQuery = async (statement, { input, rowLimit = queryRowLimit, retainObjects = false, writeReceipt = false, committed = false } = {}) => {
      if (!accepting) throw new Error('DATABASE_READ_SESSION_CLOSED');
      if (typeof retainObjects !== 'boolean') throw new Error('INVALID_QUERY_OBJECT_RETENTION');
      if (retainObjects || writeReceipt) throw new Error('DATABASE_READ_SESSION_MEMORY_ONLY');
      if (committed) throw new Error('DATABASE_READ_SESSION_REQUIRES_PIN');
      if (typeof statement !== 'string' || !statement.trim()) throw new Error('QUERY_TEXT_REQUIRED');
      if (!Number.isSafeInteger(rowLimit) || rowLimit < 1 || rowLimit > 100000) throw new Error('INVALID_QUERY_ROW_LIMIT');
      const inputText = input === undefined ? null : JSON.stringify(input);
      if (input !== undefined && typeof inputText !== 'string') throw new Error('QUERY_INPUT_MUST_BE_JSON');
      // SQL transactions permit only one active request. Bind each input before
      // queuing so concurrent graph cells cannot overwrite each other's parameters.
      const work = pending.then(async () => {
        if (queryFailure) throw queryFailure;
        if (!begun) throw new Error('DATABASE_READ_SESSION_CLOSED');
        evidence.queries++;
        const raw = await new sql.Request(tx)
          .input('estate_model_pk', sql.BigInt, pinned.estate_model_pk)
          .input('snapshot_id', sql.VarChar(71), pinned.snapshot_id)
          .input('projection_id', sql.VarChar(71), pinned.projection_id)
          .input('view_definition_digest', sql.VarChar(71), pinned.viewDefinitionDigest)
          .input('input', sql.NVarChar(sql.MAX), inputText).query(statement);
        // Limit retention, not SQL's intermediate computation (never SET ROWCOUNT).
        const truncated = raw.recordsets.some(rows => rows.length > rowLimit);
        const recordsets = raw.recordsets.map(rows => rows.slice(0, rowLimit).map(normalizeSql));
        return { snapshotId: pinned.snapshot_id, projectionDigest: pinned.projection_id,
          viewDefinitionDigest: pinned.viewDefinitionDigest, queryDigest: digest(Buffer.from(statement)),
          resultDigest: hash(recordsets.map(rows => rows.map(stable).sort())),
          resultObjectDigest: hash(recordsets), resultCanonicalization: 'sorted-multiset-per-recordset.v1',
          objectRetention: 'MEMORY_ONLY', rowLimit, truncated, rowCounts: recordsets.map(rows => rows.length),
          disposition: truncated ? 'READ_QUERY_TRUNCATED' : 'READ_QUERY_COMPLETE',
          ...(inputText === null ? {} : { inputDigest: hash(JSON.parse(inputText)) }), recordsets };
      });
      pending = work.then(() => {}, error => { queryFailure ??= error; });
      return work;
    };
    result = await invoke(readQuery, evidence);
  } catch (error) {
    failure = error;
  } finally {
    accepting = false;
    await pending;
    // A failed begin may still hold a borrowed driver connection; rollback also
    // releases that connection before pool.close waits for outstanding borrowers.
    if (begun || beginning) {
      try { await tx.rollback(); } catch (error) { failure ??= error; }
    }
    try { await pool.close(); } catch (error) { failure ??= error; }
    evidence.totalMs = performance.now() - started;
  }
  if (failure) throw failure;
  return result;
}
