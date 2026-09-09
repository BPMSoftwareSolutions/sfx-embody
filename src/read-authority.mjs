import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

// The existing restricted database reader owns snapshot selection and receipts.
export async function readAuthority(databaseRoot, selection, { retainObjects = true, timings } = {}) {
  const { query } = await import(pathToFileURL(path.join(databaseRoot, 'src/query/run.mjs')));
  const measure = async (name, work) => {
    const start = performance.now();
    try { return await work(); }
    finally { if (timings) timings[name] = performance.now() - start; }
  };
  const read = async name => measure(name, async () => query(await fs.readFile(path.join(databaseRoot, 'sql/diagnostics', name), 'utf8'), { input: selection, rowLimit: 100000, retainObjects }));
  const authority = await read('capability-embodiment.sql');
  if (selection.scenarioId === undefined) {
    if (authority.truncated || authority.recordsets[0].length !== 1) throw new Error('CAPABILITY_ROOT_SCENARIO_UNRESOLVED');
    selection = { ...selection, scenarioId: authority.recordsets[0][0].scenario_id };
  }
  selection = { ...selection, namespaceId: authority.recordsets[0][0].namespace_id };
  const resolutions = await read('scenario-resolver-map.sql');
  const mechanics = await measure('mechanic-definitions.sql', () => query(`SELECT definition_json FROM analysis.v_selected_semantic_definition
    WHERE estate_model_pk=@estate_model_pk AND object_kind='MECHANIC'`, { rowLimit: 100000, retainObjects }));
  for (const result of [authority, resolutions, mechanics]) {
    if (result.truncated || result.snapshotId !== authority.snapshotId || result.projectionDigest !== authority.projectionDigest
      || result.viewDefinitionDigest !== authority.viewDefinitionDigest)
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
