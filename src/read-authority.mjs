import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

// The existing restricted database reader owns snapshot selection and receipts.
//
// `resolution` selects how the Scenario closure is obtained.
//
//   'closure' (default) reads scenario-closure.sql: the declared downstream
//       Scenarios and their faces. Embodiment planning needs nothing else from
//       the resolver -- the native mechanic binding comes from the pinned
//       mechanic registry already carried in the authority bundle.
//   'requirements' additionally reads scenario-resolver-map.sql, which returns
//       the per-requirement resolution matrix and cross-target readiness. That
//       query costs ~30 s because analysis.v_scenario_embodiment_requirement
//       CROSS APPLYs a multi-statement function over every capability/scenario
//       pair in the estate before filtering to the selected one. Diagnostics and
//       proof paths ask for it deliberately; invocation does not.
export async function readAuthority(databaseRoot, selection, { retainObjects = true, timings, resolution = 'closure' } = {}) {
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
  const closure = await read('scenario-closure.sql');
  const resolutions = resolution === 'requirements' ? await read('scenario-resolver-map.sql') : null;
  const mechanics = await measure('mechanic-definitions.sql', () => query(`SELECT definition_json FROM analysis.v_selected_semantic_definition
    WHERE estate_model_pk=@estate_model_pk AND object_kind='MECHANIC'`, { rowLimit: 100000, retainObjects }));
  // Every retained read must describe the same snapshot, projection and view
  // definitions. A skipped resolver read is simply not among them.
  for (const result of [authority, closure, resolutions, mechanics].filter(Boolean)) {
    if (result.truncated || result.snapshotId !== authority.snapshotId || result.projectionDigest !== authority.projectionDigest
      || result.viewDefinitionDigest !== authority.viewDefinitionDigest)
      throw new Error('DATABASE_AUTHORITY_NOT_COHERENT');
  }
  return { selection, authority, closure, resolutions, mechanics };
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  try {
    const [databaseRoot, selectionFile, outputFile] = process.argv.slice(2);
    const selection = JSON.parse((await fs.readFile(selectionFile, 'utf8')).replace(/^\uFEFF/, ''));
    const bundle = await readAuthority(databaseRoot, selection, { resolution: 'requirements' });
    await fs.writeFile(outputFile, JSON.stringify(bundle, null, 2) + '\n');
    console.log(JSON.stringify({ outputFile, rows: bundle.resolutions.rowCounts, closure: bundle.closure.rowCounts, readiness: bundle.resolutions.recordsets[1], mechanicDefinitions: bundle.mechanics.rowCounts }));
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
