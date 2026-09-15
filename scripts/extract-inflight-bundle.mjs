// Extract the exact authority bundle the read path uses from an uncommitted
// rollback experiment, and write it to disk. Nothing is committed.
//
//   node --experimental-vm-modules scripts/extract-inflight-bundle.mjs <experiment.sql> <bundle.json> [capabilityId]
//
// The experiment and the estate's declared views run on one connection inside
// one transaction, so the uncommitted capability rows are visible. The resulting
// bundle is the same shape read-authority.mjs returns and is retained as the
// working-generation evidence for a change (edited-bundle.json). Nothing is
// committed.
import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const DATABASE_ROOT = 'C:/lab/sidefx-database';
const db = (...p) => path.join(DATABASE_ROOT, ...p);

// The transaction-bound declaration read. It mirrors the loader's own read in
// src/read-authority.mjs -- the estate's own declared views under sql/ -- but
// runs on the experiment's transaction so uncommitted rows are the authority.
// sidefx-database supplies the connection and query runner only; nothing here
// reads SQL out of it (docs/target-architecture.md, "Location of migrations and
// reads").
const AUTHORITY_READ = `
SELECT TOP 1 g.capability_id,
       g.root_scenario_id AS scenario_id,
       n.namespace_id
FROM analysis.v_capability_graph_source g
LEFT JOIN model.capability c ON c.capability_id = g.capability_id
LEFT JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
WHERE g.capability_id = CONVERT(nvarchar(400), JSON_VALUE(@input, '$.capabilityId'))
  AND (JSON_VALUE(@input, '$.namespaceId') IS NULL OR n.namespace_id = JSON_VALUE(@input, '$.namespaceId'))
ORDER BY n.namespace_id;

SELECT d.source_path, d.entry_id,
       CONVERT(varbinary(max), CONVERT(varchar(max), d.document) COLLATE Latin1_General_100_BIN2_UTF8) AS content_bytes
FROM analysis.v_capability_execution_declaration d
WHERE d.capability_id = CONVERT(nvarchar(400), JSON_VALUE(@input, '$.capabilityId'))
ORDER BY d.source_path, d.entry_id;`;

const CLOSURE_READ = `
DECLARE @capability_id nvarchar(4000)=JSON_VALUE(@input,'$.capabilityId'),
        @scenario_id nvarchar(4000)=JSON_VALUE(@input,'$.scenarioId'),
        @namespace_id nvarchar(4000)=JSON_VALUE(@input,'$.namespaceId');
DECLARE @matches bigint,@capability_version_pk bigint,@scenario_version_pk bigint;
SELECT @matches=COUNT_BIG(*),@capability_version_pk=MAX(ec.capability_version_pk)
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE ec.estate_model_pk=@estate_model_pk AND c.capability_id=@capability_id
  AND (@namespace_id IS NULL OR n.namespace_id=@namespace_id);
IF @matches=0 THROW 51000,'CAPABILITY_NOT_FOUND',1;
IF @matches<>1 THROW 51000,'CAPABILITY_NAMESPACE_AMBIGUOUS',1;
SELECT @matches=COUNT_BIG(*),@scenario_version_pk=MAX(cs.scenario_version_pk)
FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
WHERE cs.capability_version_pk=@capability_version_pk AND s.scenario_id=@scenario_id;
IF @matches=0 THROW 51000,'SCENARIO_NOT_IN_CAPABILITY',1;
IF @matches<>1 THROW 51000,'SCENARIO_NAMESPACE_AMBIGUOUS',1;
SELECT DISTINCT s.scenario_id AS downstream_scenario_id,cl.minimum_depth,cl.cycle_detected,
       sc.capability_id AS owning_capability_id,
       i.input_id,e.event_id,e.responsibility,o.outcome_id,sv.definition_digest AS scenario_definition_digest
FROM analysis.v_scenario_invocation_closure cl
JOIN model.scenario_version sv ON sv.scenario_version_pk=cl.downstream_scenario_version_pk
JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
JOIN model.capability sc ON sc.capability_pk=s.capability_pk
LEFT JOIN model.scenario_input i ON i.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_event e ON e.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_outcome o ON o.scenario_version_pk=sv.scenario_version_pk
WHERE cl.capability_version_pk=@capability_version_pk AND cl.selected_scenario_version_pk=@scenario_version_pk
ORDER BY cl.minimum_depth,s.scenario_id
OPTION(MAXRECURSION 32767);`;
const experimentFile = process.argv[2] ?? 'sql/migrations/scaffold-hello-world.sql';
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
  const readStatement = async (statement, { input: selection } = {}) => {
    const result = await new sql.Request(tx)
      .input('estate_model_pk', sql.BigInt, pinned.estate_model_pk)
      .input('snapshot_id', sql.VarChar(71), pinned.snapshot_id)
      .input('projection_id', sql.VarChar(71), pinned.projection_id)
      .input('view_definition_digest', sql.VarChar(71), pinned.viewDefinitionDigest)
      .input('input', sql.NVarChar(sql.MAX), JSON.stringify(selection ?? null))
      .query(statement);
    return { ...identity, recordsets: result.recordsets.map(rs => rs.map(normalizeSql)), rowCounts: result.recordsets.map(rs => rs.length) };
  };

  const authority = await readStatement(AUTHORITY_READ, { input: { capabilityId } });
  const selected = authority.recordsets[0]?.[0];
  if (!selected) throw new Error('CAPABILITY_NOT_FOUND_ON_THIS_TRANSACTION:' + capabilityId);
  const selection = { capabilityId, target: 'node', scenarioId: selected.scenario_id,
    ...(selected.namespace_id === undefined ? {} : { namespaceId: selected.namespace_id }) };
  const closure = await readStatement(CLOSURE_READ, { input: selection });
  const mechanicsRaw = await new sql.Request(tx).query(`SELECT definition_json FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=${Number(pinned.estate_model_pk)} AND object_kind='MECHANIC'`);
  const mechanics = { ...identity, recordsets: [mechanicsRaw.recordset.map(normalizeSql)], rowCounts: [mechanicsRaw.recordset.length] };

  const bundle = { bundleType: 'sfx-inflight-bundle.v1', extractedAt: new Date().toISOString(), experimentFile,
    selection, authority, closure, resolutions: null, mechanics,
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

