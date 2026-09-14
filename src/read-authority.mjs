import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

// The loader's declaration read. It assembles a capability's executable
// authority from the estate's own declared views -- never from the legacy
// sidefx-database diagnostics. The SQL content is a declared read; the
// connection and query runner it executes against is the database primitive.
//
// `resolution` selects how much of the resolution map is retained.
//
//   'closure' (default) reads the selected Scenario's declared downstream
//       closure only. Invocation needs nothing else -- the executable graph and
//       its providers come from the estate's own execution declaration.
//   'requirements' additionally reads the language-resolution map, which costs
//       ~30 s because analysis.v_scenario_language_resolution expands every
//       capability/scenario pair before filtering. Diagnostics and proof paths
//       ask for it deliberately; invocation does not.
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

const RESOLUTION_READ = `
DECLARE @capability_id nvarchar(4000)=JSON_VALUE(@input,'$.capabilityId'),
        @scenario_id nvarchar(4000)=JSON_VALUE(@input,'$.scenarioId'),
        @namespace_id nvarchar(4000)=JSON_VALUE(@input,'$.namespaceId'),
        @target nvarchar(4000)=JSON_VALUE(@input,'$.target');
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
IF @target IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM analysis.v_declared_platform_implementation
    WHERE estate_model_pk=@estate_model_pk AND target_language=@target
) THROW 51000,'TARGET_NOT_DECLARED',1;
SET ROWCOUNT 0;
SELECT * INTO #resolver_map
FROM analysis.v_scenario_language_resolution
WHERE estate_model_pk=@estate_model_pk AND capability_version_pk=@capability_version_pk
  AND selected_scenario_version_pk=@scenario_version_pk
  AND (@target IS NULL OR target_language=@target)
OPTION(RECOMPILE,MAXRECURSION 32767);
SELECT capability_id,scenario_id,downstream_scenario_id,altitude,requirement_kind,
       requirement_id,requirement_use,target_language,provenance_class,
       source_definition_pk,source_pointer,requirement_definition_pk,requirement_definition_digest,
       resolver_id,provider_id,provider_definition_pk,provider_profile_id,profile_definition_pk,
       implementation_id,implementation_export,resolution_candidate_count,
       mechanic_source_digest,registry_source_digest,declared_authority_digest,
       resolution_status,diagnostic,repair_boundary,implementation_evidence_state,conformance_status
FROM #resolver_map
ORDER BY target_language,minimum_depth,downstream_scenario_id,requirement_use,implementation_id;
WITH obligations AS (
    SELECT target_language,downstream_scenario_version_pk,requirement_use,
           MAX(CASE WHEN resolution_status<>'RESOLVED' THEN 1 ELSE 0 END) AS is_open
    FROM #resolver_map GROUP BY target_language,downstream_scenario_version_pk,requirement_use
)
SELECT @capability_id AS capability_id,@scenario_id AS scenario_id,target_language,
       COUNT_BIG(*) AS requirement_count,SUM(CONVERT(bigint,is_open)) AS open_requirement_count,
       CASE WHEN SUM(is_open)=0 THEN 'CAN_ATTEMPT_EMBODIMENT' ELSE 'NOT_OBSERVABLE' END AS readiness,
       'NOT_EVALUATED' AS conformance_status
FROM obligations GROUP BY target_language ORDER BY target_language;
SELECT DISTINCT s.scenario_id AS downstream_scenario_id,cl.minimum_depth,cl.cycle_detected,
       i.input_id,e.event_id,e.responsibility,o.outcome_id,sv.definition_digest AS scenario_definition_digest
FROM analysis.v_scenario_invocation_closure cl
JOIN model.scenario_version sv ON sv.scenario_version_pk=cl.downstream_scenario_version_pk
JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
LEFT JOIN model.scenario_input i ON i.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_event e ON e.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_outcome o ON o.scenario_version_pk=sv.scenario_version_pk
WHERE cl.capability_version_pk=@capability_version_pk AND cl.selected_scenario_version_pk=@scenario_version_pk
ORDER BY cl.minimum_depth,s.scenario_id
OPTION(MAXRECURSION 32767);`;

const MECHANIC_READ = `SELECT definition_json FROM analysis.v_selected_semantic_definition
WHERE estate_model_pk=@estate_model_pk AND object_kind='MECHANIC'`;

export async function readAuthority(databaseRoot, selection, { retainObjects = true, timings, resolution = 'closure' } = {}) {
  const { query } = await import(pathToFileURL(path.join(databaseRoot, 'src/query/run.mjs')));
  const measure = async (name, work) => {
    const start = performance.now();
    try { return await work(); }
    finally { if (timings) timings[name] = performance.now() - start; }
  };
  const read = (name, statement, input) => measure(name, () => query(statement, { input, rowLimit: 100000, retainObjects }));
  const authority = await read('capability-authority', AUTHORITY_READ, selection);
  const root = authority.recordsets[0]?.[0];
  if (!root) throw new Error('CAPABILITY_NOT_FOUND');
  if (selection.scenarioId === undefined && (authority.truncated || authority.recordsets[0].length !== 1)) throw new Error('CAPABILITY_ROOT_SCENARIO_UNRESOLVED');
  const scenarioId = selection.scenarioId ?? root.scenario_id;
  if (scenarioId === undefined) throw new Error('CAPABILITY_ROOT_SCENARIO_UNRESOLVED');
  selection = { ...selection, scenarioId, ...(root.namespace_id === undefined ? {} : { namespaceId: root.namespace_id }) };
  const closure = await read('capability-closure', CLOSURE_READ, selection);
  const resolutions = resolution === 'requirements' ? await read('scenario-resolver-map', RESOLUTION_READ, selection) : null;
  const mechanics = await read('mechanic-definitions', MECHANIC_READ, selection);
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
