// The database connect boundary. The connection string is parsed and pooled
// here, at connect time, and never copied into process.env: no observation,
// spawned child or retained evidence can read it, and a failed connect closes
// its own pool before the error leaves the boundary.
export function createDatabaseConnectBoundary({ sql, connectionString, connectionName, requestTimeoutMs }) {
  if (typeof connectionString !== 'string' || connectionString.length === 0) {
    return async () => { throw new Error('INVALID_OR_MISSING_SQL_CONNECTION_CONFIGURATION:' + connectionName); };
  }
  return async function connect() {
    let parsed;
    try { parsed = sql.ConnectionPool.parseConnectionString(connectionString); }
    catch { throw new Error('INVALID_OR_MISSING_SQL_CONNECTION_CONFIGURATION:' + connectionName); }
    parsed.requestTimeout = requestTimeoutMs;
    parsed.pool = { max: 2, min: 0, idleTimeoutMillis: 10000 };
    const pool = new sql.ConnectionPool(parsed);
    pool.on('error', () => {});
    try { return await pool.connect(); }
    catch (error) {
      await pool.close().catch(() => {});
      throw new Error('DATABASE_CONNECTION_FAILED:' + (error.code ?? 'UNKNOWN'));
    }
  };
}
