// Run a database migration .sql on ONE connection, batch-by-batch (split on GO),
// WITHOUT wrapping it in an outer transaction. The migration owns its own
// BEGIN TRANSACTION / ROLLBACK|COMMIT exactly as authored.
//
//   node scripts/run-migration.mjs sql/migrations/<file>.sql
//
// This is the runner for both phases of the database change lifecycle
// (sql/README.md):
//
//   verification  - the file ends in ROLLBACK; read the printed result sets.
//   installation  - the file ends in COMMIT (a committed copy); the effects
//                   persist and the same result sets are printed.
//
// Do NOT use sidefx-database's sql/migrations/run-file.mjs for installs: it
// opens its own transaction, so a script's BEGIN/COMMIT nests and the outer
// rollback silently discards the change.
import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const DATABASE_ROOT = process.env.SIDEFX_DATABASE_ROOT ?? 'C:/lab/sidefx-database';
const file = process.argv[2];
if (!file) {
  console.error('usage: node scripts/run-migration.mjs <migration.sql>');
  process.exit(2);
}

const { connect, sql } = await import(pathToFileURL(path.join(DATABASE_ROOT, 'src/ingest/database.mjs')).href);
const text = await fs.readFile(file, 'utf8');
const batches = text.split(/^\s*GO\s*$/mi).map(s => s.trim()).filter(Boolean);
const disposition = /COMMIT TRANSACTION\s*;/i.test(text) ? 'COMMIT' : (/ROLLBACK TRANSACTION\s*;/i.test(text) ? 'ROLLBACK' : 'NONE');

const pool = await connect();
try {
  let index = 0;
  for (const batch of batches) {
    index++;
    const result = await new sql.Request(pool).batch(batch);
    for (const rs of result.recordsets) {
      if (!rs.length) continue;
      const name = rs[0].result_set ?? rs[0].section ?? `batch ${index}`;
      console.log('RS', name, 'rows', rs.length);
      for (const row of rs.slice(0, 20)) console.log('  ', JSON.stringify(row));
    }
  }
  console.log(`MIGRATION ${disposition} COMPLETE (${file})`);
} catch (e) {
  console.error('MIGRATION FAILED:', e.message, 'number=' + e.number, 'line=' + e.lineNumber);
  process.exitCode = 1;
} finally {
  await pool.close();
}
process.exit();
