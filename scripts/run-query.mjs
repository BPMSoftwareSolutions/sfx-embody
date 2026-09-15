// Run a database query .sql on ONE connection
//
//   node scripts/run-query.mjs <query.sql>
//
import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const DATABASE_ROOT = process.env.SIDEFX_DATABASE_ROOT ?? 'C:/lab/sidefx-database';
const file = process.argv[2];
if (!file) {
  console.error('usage: node scripts/run-query.mjs <query.sql>');
  process.exit(2);
}

const { connect, sql } = await import(pathToFileURL(path.join(DATABASE_ROOT, 'src/ingest/database.mjs')).href);
const text = await fs.readFile(file, 'utf8');

const pool = await connect();
try {
  const result = await new sql.Request(pool).query(text);
  for (const rs of result.recordsets) {
    if (!rs.length) continue;
    const name = rs[0].result_set ?? rs[0].section ?? `batch 1`;
    console.log('RS', name, 'rows', rs.length);
    for (const row of rs.slice(0, 100)) console.log('  ', JSON.stringify(row));
  }
} catch (e) {
  console.error('QUERY FAILED:', e.message, 'number=' + e.number, 'line=' + e.lineNumber);
  process.exitCode = 1;
} finally {
  await pool.close();
}
process.exit();
