// Extract the exact authority bundle the read path uses from an uncommitted
// rollback experiment, and write it to disk. Nothing is committed.
//
//   node --experimental-vm-modules scripts/extract-inflight-bundle.mjs <experiment.sql> <bundle.json> [capabilityId]
//
// The experiment and the three read-path queries run on one connection inside
// one transaction, so the uncommitted capability rows are visible. The resulting
// bundle is the same shape read-authority.mjs returns and can be consumed by
// invoke-from-bundle.mjs with no database connection.
import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const DATABASE_ROOT = 'C:/lab/sidefx-database';
const db = (...p) => path.join(DATABASE_ROOT, ...p);
const experimentFile = process.argv[2] ?? 'docs/sql/scaffold-hello-world.sql';
const bundleFile = process.argv[3] ?? 'evidence/hello-world-sql/inflight-bundle.json';
const capabilityId = process.argv[4] ?? 'hello-world-sql';

const { connect, sql } = await import(pathToFileURL(db('src/ingest/database.mjs')).href);
const { pinModel } = await import(pathToFileURL(db('src/query/model-pin.mjs')).href);
const { normalizeSql } = await import(pathToFileURL(db('src/query/run.mjs')).href);

let text = await fs.readFile(experimentFile, 'utf8');
const at = text.lastIndexOf('ROLLBACK TRANSACTION;');
if (at < 0) throw new Error('NO_ROLLBACK_IN_EXPERIMENT');
text = text.slice(0, at);
const batches = text.split(/^\s*GO\s*$/mi).map(s => s.trim()).filter(Boolean);

const pool = await connect();
const tx = new sql.Transaction(pool);
try {
  await tx.begin();
  for (const batch of batches) await new sql.Request(tx).batch(batch);
  const pinned = await pinModel(tx);
  const identity = { snapshotId: pinned.snapshot_id, projectionDigest: pinned.projection_id, viewDefinitionDigest: pinned.viewDefinitionDigest, truncated: false };
  const readQuery = async (file, selection) => {
    const statement = await fs.readFile(db('sql/diagnostics', file), 'utf8');
    const result = await new sql.Request(tx)
      .input('estate_model_pk', sql.BigInt, pinned.estate_model_pk)
      .input('snapshot_id', sql.VarChar(71), pinned.snapshot_id)
      .input('projection_id', sql.VarChar(71), pinned.projection_id)
      .input('view_definition_digest', sql.VarChar(71), pinned.viewDefinitionDigest)
      .input('input', sql.NVarChar(sql.MAX), JSON.stringify(selection))
      .query(statement);
    return { ...identity, recordsets: result.recordsets.map(rs => rs.map(normalizeSql)), rowCounts: result.recordsets.map(rs => rs.length) };
  };

  const authority = await readQuery('capability-embodiment.sql', { capabilityId });
  const selected = authority.recordsets[0][0];
  if (!selected) throw new Error('CAPABILITY_NOT_FOUND_ON_THIS_TRANSACTION:' + capabilityId);
  const closure = await readQuery('scenario-closure.sql', { capabilityId, scenarioId: selected.scenario_id });
  const mechanicsRaw = await new sql.Request(tx).query(`SELECT definition_json FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=${Number(pinned.estate_model_pk)} AND object_kind='MECHANIC'`);
  const mechanics = { ...identity, recordsets: [mechanicsRaw.recordset.map(normalizeSql)], rowCounts: [mechanicsRaw.recordset.length] };

  const bundle = { bundleType: 'sfx-inflight-bundle.v1', extractedAt: new Date().toISOString(), experimentFile,
    selection: { capabilityId, target: 'node', scenarioId: selected.scenario_id }, authority, closure, resolutions: null, mechanics,
    pins: { estateModelPk: String(pinned.estate_model_pk), snapshotId: pinned.snapshot_id, projectionDigest: pinned.projection_id } };
  await fs.mkdir(path.dirname(bundleFile), { recursive: true });
  await fs.writeFile(bundleFile, JSON.stringify(bundle, null, 2) + '\n');
  console.log('BUNDLE', bundleFile, 'bytes', (await fs.stat(bundleFile)).size,
    'authorityRows', authority.rowCounts, 'closureRows', closure.rowCounts, 'mechanicRows', mechanics.rowCounts);
} catch (error) {
  console.error('EXTRACT FAILED:', error.message);
  process.exitCode = 1;
} finally {
  try { await tx.rollback(); } catch {}
  try { await pool.close(); } catch {}
}
