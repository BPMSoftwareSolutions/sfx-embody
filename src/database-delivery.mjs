import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { executeDatabaseCommand, validateDatabaseCommand, createObservationFilter } from './invoke-database-capability.mjs';
import { readAuthority } from './read-authority.mjs';
import { withDatabaseReadSession } from './database-read-session.mjs';
import { createDatabaseConnectBoundary } from './database-connect-boundary.mjs';
import { restrictMemoryProcess } from './restrict-memory-process.mjs';

try {
  const chunks = [];
  let size = 0;
  for await (const chunk of process.stdin) {
    size += chunk.length;
    if (size > 9 * 1024 * 1024) throw new Error('DELIVERY_INPUT_TOO_LARGE');
    chunks.push(chunk);
  }
  const envelope = JSON.parse(Buffer.concat(chunks).toString('utf8'));
  validateDatabaseCommand(envelope);
  const configFile = path.resolve(process.argv[2]);
  const config = JSON.parse(await fs.readFile(configFile, 'utf8'));
  if (config.configurationType !== 'sfx-database-memory-runtime.v1'
    || typeof config.databaseRoot !== 'string' || typeof config.sdaRoot !== 'string') throw new Error('RUNTIME_CONFIGURATION_REJECTED');
  for (const key of ['databaseRoot', 'sdaRoot']) config[key] = path.resolve(path.dirname(configFile), config[key]);
  // Preserve the database reader's existing credential reference. Never retain it
  // in command envelopes or execution evidence. Windows lookup is read-only.
  const { config: readDatabaseConfig, stable, hash, digest } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/core.mjs')));
  const { connectionString, sql } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/ingest/database.mjs')));
  const { connectionEnvironmentVariable, queryRowLimit, requestTimeoutMs } = await readDatabaseConfig();
  // The connection string is resolved before the memory-process restriction can
  // forbid the read-only OS-environment lookup, and lives only in the connect
  // boundary closure. It is never copied into process.env, so the observation
  // stream, declared children and retained evidence cannot carry it.
  const connect = createDatabaseConnectBoundary({ sql,
    connectionString: connectionString(connectionEnvironmentVariable),
    connectionName: connectionEnvironmentVariable, requestTimeoutMs });
  // The frontdoor owns the connection. Inject the query runner and the
  // declaration read for the loader; the loader must not reach into
  // sidefx-database itself.
  const { normalizeSql } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/query/run.mjs')));
  const { pinModel } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/query/model-pin.mjs')));
  const processEvidence = restrictMemoryProcess(config);
  config.spawnDeclared = processEvidence.spawnDeclared;
  const setupTime = performance.now();
  const result = await withDatabaseReadSession({ connect, sql, pinModel, normalizeSql, stable, hash, digest, queryRowLimit },
    async (readQuery, sessionEvidence) => {
      config.readQuery = readQuery;
      config.readAuthority = (root, selection, options) => readAuthority(root, selection, { ...options, query: readQuery });
      // Only declared telemetry leaves the observation channel. The allowlist is
      // declared authority (read-observation-telemetry-authority), read once
      // through the same declared-invocation path; the seam applies it. Inputs,
      // provider bodies and secrets remain in their existing execution/evidence
      // boundaries.
      if (process.env.SIDEFX_OBSERVE === '1') {
        const telemetry = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'invoke',
          request: { object: 'capability', verb: 'invoke', subject: 'read-observation-telemetry-authority',
            input: { contractId: 'observation-telemetry-request.v1' } } }, config);
        const filter = createObservationFilter(telemetry?.outcome?.result?.outcome ?? telemetry?.outcome?.result);
        config.onObservation = observation => {
          process.stderr.write('SFX_OBSERVATION ' + JSON.stringify(filter(observation)) + '\n');
        };
      }
      const result = await executeDatabaseCommand(envelope, config);
      if (result.outcome?.evidence) result.outcome.evidence.readSession = sessionEvidence;
      return result;
    });
  if (result.outcome?.evidence) {
    result.outcome.evidence.timings.processSetup = setupTime;
    result.outcome.evidence.timings.processTotal = performance.now();
    result.outcome.evidence.process = processEvidence;
  }
  process.stdout.write(JSON.stringify(result) + '\n');
} catch (error) {
  const message = error.message ?? 'DATABASE_INVOCATION_FAILED';
  const code = /^[A-Z][A-Z0-9_]+(?=:|$)/.exec(message)?.[0] ?? 'DATABASE_INVOCATION_FAILED';
  process.stdout.write(JSON.stringify({ disposition: 'failed', errorCode: code, error: { code, message } }) + '\n');
  process.exitCode = 4;
}
