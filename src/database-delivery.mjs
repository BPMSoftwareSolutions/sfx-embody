import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { executeDatabaseCommand, validateDatabaseCommand } from './invoke-database-capability.mjs';
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
  const { config: readDatabaseConfig } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/core.mjs')));
  const { connectionString } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/ingest/database.mjs')));
  const { connectionEnvironmentVariable } = await readDatabaseConfig();
  process.env[connectionEnvironmentVariable] = connectionString(connectionEnvironmentVariable);
  const processEvidence = restrictMemoryProcess(config);
  if (process.env.SIDEFX_OBSERVE === '1') {
    config.onObservation = observation => {
      // Only telemetry leaves this channel. Inputs, provider bodies and secrets
      // remain in their existing execution/evidence boundaries.
      const safe = Object.fromEntries(['observationType', 'phase', 'status', 'observedAt',
        'executionId', 'rootExecutionId', 'parentExecutionId', 'scenarioId', 'stepId', 'sequence']
        .filter(key => ['string', 'number'].includes(typeof observation[key]) || observation[key] === null)
        .map(key => [key, observation[key]]));
      process.stderr.write('SFX_OBSERVATION ' + JSON.stringify(safe) + '\n');
    };
  }
  const setupTime = performance.now();
  const result = await executeDatabaseCommand(envelope, config);
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
