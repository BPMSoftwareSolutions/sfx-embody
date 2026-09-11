import path from 'node:path';
import { pathToFileURL } from 'node:url';

// Listing and finding read the selected estate model. Both report only what the
// model declares: a capability with no retained user story is listed with null
// fields rather than a manufactured summary, and a root scenario is reported only
// when the model declares exactly one.
//
// `find` matches DB-side over the declared identity and the declared meaning, and
// reports which of those fields actually matched, so a result is always traceable
// to the authority that produced it.
const LIST_SQL = `
DECLARE @namespace_id nvarchar(4000)=JSON_VALUE(@input,'$.namespaceId');
DECLARE @query nvarchar(4000)=JSON_VALUE(@input,'$.query');
IF @query IS NOT NULL AND LEN(LTRIM(RTRIM(@query)))=0 THROW 51000,'CAPABILITY_QUERY_REQUIRED',1;
-- Escape the caller's text so it is matched literally, never as a LIKE pattern.
DECLARE @pattern nvarchar(4000)='%'+REPLACE(REPLACE(REPLACE(LOWER(@query),'[','[[]'),'%','[%]'),'_','[_]')+'%';

WITH declared AS (
    SELECT ec.capability_version_pk,c.capability_id,n.namespace_id,
           'sha256:'+LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS definition_digest,
           JSON_VALUE(d.definition_json,'$.semantics.authority.name') AS declared_name,
           JSON_VALUE(d.definition_json,'$.semantics.authority.mode') AS mode,
           JSON_VALUE(d.definition_json,'$.semantics.authority.userStory.actor') AS actor,
           JSON_VALUE(d.definition_json,'$.semantics.authority.userStory.intent') AS intent,
           JSON_VALUE(d.definition_json,'$.semantics.authority.userStory.outcome') AS outcome,
           JSON_VALUE(d.definition_json,'$.semantics.authority.experience.promise') AS promise
    FROM model.estate_capability ec
    JOIN model.capability c ON c.capability_pk=ec.capability_pk
    JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
    LEFT JOIN analysis.v_selected_semantic_definition d
      ON d.estate_model_pk=ec.estate_model_pk
     AND d.semantic_object_definition_pk=ec.semantic_object_definition_pk
    WHERE ec.estate_model_pk=@estate_model_pk
      AND (@namespace_id IS NULL OR n.namespace_id=@namespace_id)
)
SELECT d.capability_id AS capabilityId,d.namespace_id AS namespaceId,d.definition_digest AS definitionDigest,
       d.declared_name AS declaredName,d.mode,d.actor,d.intent,d.outcome,d.promise,
       CASE WHEN roots.declared_roots=1 THEN roots.scenario_id END AS declaredRootScenarioId,
       roots.declared_roots AS declaredRootCount,
       scenarios.scenario_count AS scenarioCount,
       CASE WHEN @query IS NULL THEN NULL ELSE LTRIM(CONCAT(
           CASE WHEN LOWER(d.capability_id) COLLATE Latin1_General_100_CI_AS LIKE @pattern THEN ' capabilityId' ELSE '' END,
           CASE WHEN LOWER(d.namespace_id) COLLATE Latin1_General_100_CI_AS LIKE @pattern THEN ' namespaceId' ELSE '' END,
           CASE WHEN LOWER(d.declared_name) COLLATE Latin1_General_100_CI_AS LIKE @pattern THEN ' name' ELSE '' END,
           CASE WHEN LOWER(d.actor) COLLATE Latin1_General_100_CI_AS LIKE @pattern THEN ' actor' ELSE '' END,
           CASE WHEN LOWER(d.intent) COLLATE Latin1_General_100_CI_AS LIKE @pattern THEN ' intent' ELSE '' END,
           CASE WHEN LOWER(d.outcome) COLLATE Latin1_General_100_CI_AS LIKE @pattern THEN ' outcome' ELSE '' END,
           CASE WHEN LOWER(d.promise) COLLATE Latin1_General_100_CI_AS LIKE @pattern THEN ' promise' ELSE '' END,
           CASE WHEN scenarios.matched_scenarios>0 THEN ' scenario' ELSE '' END)) END AS matchedFields
FROM declared d
OUTER APPLY (
    SELECT COUNT_BIG(*) AS declared_roots,MAX(s.scenario_id) AS scenario_id
    FROM model.capability_root_scenario r
    JOIN model.scenario s ON s.scenario_pk=r.scenario_pk
    WHERE r.capability_version_pk=d.capability_version_pk
) roots
OUTER APPLY (
    SELECT COUNT_BIG(*) AS scenario_count,
           SUM(CASE WHEN @query IS NOT NULL AND (
                 LOWER(s.scenario_id) COLLATE Latin1_General_100_CI_AS LIKE @pattern
              OR LOWER(JSON_VALUE(sd.definition_json,'$.semantics.scenario.name')) COLLATE Latin1_General_100_CI_AS LIKE @pattern
               ) THEN 1 ELSE 0 END) AS matched_scenarios
    FROM model.capability_scenario cs
    JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
    LEFT JOIN analysis.v_selected_semantic_definition sd
      ON sd.estate_model_pk=@estate_model_pk AND sd.object_kind='SCENARIO'
     AND sd.declared_id=s.scenario_id
    WHERE cs.capability_version_pk=d.capability_version_pk
) scenarios
WHERE @query IS NULL OR (
       LOWER(d.capability_id) COLLATE Latin1_General_100_CI_AS LIKE @pattern
    OR LOWER(d.namespace_id) COLLATE Latin1_General_100_CI_AS LIKE @pattern
    OR LOWER(d.declared_name) COLLATE Latin1_General_100_CI_AS LIKE @pattern
    OR LOWER(d.actor) COLLATE Latin1_General_100_CI_AS LIKE @pattern
    OR LOWER(d.intent) COLLATE Latin1_General_100_CI_AS LIKE @pattern
    OR LOWER(d.outcome) COLLATE Latin1_General_100_CI_AS LIKE @pattern
    OR LOWER(d.promise) COLLATE Latin1_General_100_CI_AS LIKE @pattern
    OR scenarios.matched_scenarios>0)
ORDER BY d.capability_id;
`;

export async function listCapabilities(databaseRoot, selection, { timings } = {}) {
  const { query } = await import(pathToFileURL(path.join(databaseRoot, 'src/query/run.mjs')));
  const start = performance.now();
  const read = await query(LIST_SQL, { input: selection, rowLimit: 100000, retainObjects: false });
  if (timings) timings['capability-list.sql'] = performance.now() - start;
  if (read.truncated) throw new Error('DATABASE_AUTHORITY_NOT_COHERENT');
  return {
    snapshotId: read.snapshotId,
    projectionDigest: read.projectionDigest,
    viewDefinitionDigest: read.viewDefinitionDigest,
    ...(selection.query === undefined ? {} : { query: selection.query }),
    ...(selection.namespaceId === undefined ? {} : { namespaceId: selection.namespaceId }),
    count: read.recordsets[0].length,
    capabilities: read.recordsets[0].map(row => ({
      capabilityId: row.capabilityId,
      namespaceId: row.namespaceId,
      definitionDigest: row.definitionDigest,
      name: row.declaredName,
      mode: row.mode,
      declaredRootScenarioId: row.declaredRootScenarioId,
      declaredRootCount: Number(row.declaredRootCount ?? 0),
      scenarioCount: Number(row.scenarioCount ?? 0),
      userStory: row.actor === null && row.intent === null && row.outcome === null
        ? null : { actor: row.actor, intent: row.intent, outcome: row.outcome },
      promise: row.promise,
      ...(row.matchedFields === null || row.matchedFields === undefined
        ? {} : { matchedFields: row.matchedFields.split(' ').filter(Boolean) }),
    })),
  };
}
