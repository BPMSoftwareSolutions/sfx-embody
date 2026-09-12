// Extract any committed capability's invocation bundle from the database to disk.
//
//   node --experimental-vm-modules scripts/extract-bundle.mjs <capabilityId> [out.json] [scenarioId]
//
// Uses the same read path the runtime uses (read-authority.mjs), so the bundle
// has exactly the shape invoke-from-bundle.mjs consumes. Nothing is written to
// the database.
import fs from 'node:fs/promises';
import path from 'node:path';
import { readAuthority } from '../src/read-authority.mjs';

const DATABASE_ROOT = 'C:/lab/sidefx-database';
const capabilityId = process.argv[2];
if (!capabilityId) throw new Error('usage: node scripts/extract-bundle.mjs <capabilityId> [out.json] [scenarioId]');
const out = process.argv[3] ?? `evidence/${capabilityId}/bundle.json`;
const scenarioId = process.argv[4];

const selection = { capabilityId, target: 'node', ...(scenarioId ? { scenarioId } : {}) };
const bundle = await readAuthority(DATABASE_ROOT, selection, { retainObjects: false, timings: {} });
const document = { bundleType: 'sfx-capability-bundle.v1', extractedAt: new Date().toISOString(), databaseRoot: DATABASE_ROOT, ...bundle };
await fs.mkdir(path.dirname(out), { recursive: true });
await fs.writeFile(out, JSON.stringify(document, null, 2) + '\n');
console.log('BUNDLE', out, 'bytes', (await fs.stat(out)).size,
  'authorityRows', bundle.authority.rowCounts, 'closureRows', bundle.closure.rowCounts, 'mechanicRows', bundle.mechanics.rowCounts);
