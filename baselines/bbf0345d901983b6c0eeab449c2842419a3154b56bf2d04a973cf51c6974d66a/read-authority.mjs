import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

// The existing restricted database reader owns snapshot selection and receipts.
export async function readAuthority(databaseRoot, selection) {
  const { query } = await import(pathToFileURL(path.join(databaseRoot, 'src/query/run.mjs')));
  const read = async name => query(await fs.readFile(path.join(databaseRoot, 'sql/diagnostics', name), 'utf8'), { input: selection, rowLimit: 100000 });
  const authority = await read('capability-embodiment.sql');
  const resolutions = await read('scenario-resolver-map.sql');
  const mechanics = await query(`SELECT definition_json FROM analysis.v_selected_semantic_definition
    WHERE estate_model_pk=@estate_model_pk AND object_kind='MECHANIC'`, { rowLimit: 100000 });
  for (const result of [authority, resolutions, mechanics]) {
    if (result.truncated || result.snapshotId !== authority.snapshotId || result.projectionDigest !== authority.projectionDigest)
      throw new Error('DATABASE_AUTHORITY_NOT_COHERENT');
  }
  return { selection, authority, resolutions, mechanics };
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  try {
    const [databaseRoot, selectionFile, outputFile] = process.argv.slice(2);
    const selection = JSON.parse((await fs.readFile(selectionFile, 'utf8')).replace(/^\uFEFF/, ''));
    const bundle = await readAuthority(databaseRoot, selection);
    await fs.writeFile(outputFile, JSON.stringify(bundle, null, 2) + '\n');
    console.log(JSON.stringify({ outputFile, rows: bundle.resolutions.rowCounts, readiness: bundle.resolutions.recordsets[1], mechanicDefinitions: bundle.mechanics.rowCounts }));
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
