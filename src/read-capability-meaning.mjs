import path from 'node:path';
import { pathToFileURL } from 'node:url';

// Every value below is read from the selected estate model. This module composes
// no meaning of its own: absent authority stays absent (null / empty), and no
// default, example or placeholder is ever substituted for a missing declaration.
//
// The declared chain, each hop an explicit relationship in the model:
//   capability -> root scenario -> declared closure -> execution authority
//     -> port -> platform capability -> provider -> mechanic
// Observable conditions attach to the capability by owner_definition_digest.
//
// One query, so every recordset shares one snapshot and projection identity.
const MEANING_SQL = `
DECLARE @capability_id nvarchar(4000)=JSON_VALUE(@input,'$.capabilityId'),
        @namespace_id nvarchar(4000)=JSON_VALUE(@input,'$.namespaceId'),
        @scenario_id nvarchar(4000)=JSON_VALUE(@input,'$.scenarioId');
IF NULLIF(@capability_id,'') IS NULL THROW 51000,'CAPABILITY_REQUIRED',1;

DECLARE @matches bigint,@capability_version_pk bigint,@capability_definition_pk bigint;
SELECT @matches=COUNT_BIG(*),@capability_version_pk=MAX(ec.capability_version_pk),
       @capability_definition_pk=MAX(ec.semantic_object_definition_pk)
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE ec.estate_model_pk=@estate_model_pk AND c.capability_id=@capability_id
  AND (@namespace_id IS NULL OR n.namespace_id=@namespace_id);
IF @matches=0 THROW 51000,'CAPABILITY_NOT_FOUND',1;
IF @matches<>1 THROW 51000,'CAPABILITY_NAMESPACE_AMBIGUOUS',1;

-- The declared normalized root, never inferred from the capability's spelling.
-- It is read whether or not a scenario was selected, so the reported root stays
-- the root even when the caller selected a different scenario to read.
DECLARE @declared_root nvarchar(400),@declared_root_count bigint;
SELECT @declared_root_count=COUNT_BIG(*),@declared_root=MAX(s.scenario_id)
FROM model.capability_root_scenario r JOIN model.scenario s ON s.scenario_pk=r.scenario_pk
WHERE r.capability_version_pk=@capability_version_pk;
IF @scenario_id IS NULL
BEGIN
    IF @declared_root_count<>1 THROW 51000,'CAPABILITY_ROOT_SCENARIO_UNRESOLVED',1;
    SET @scenario_id=@declared_root;
END;

DECLARE @scenario_version_pk bigint;
SELECT @matches=COUNT_BIG(*),@scenario_version_pk=MAX(cs.scenario_version_pk)
FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
WHERE cs.capability_version_pk=@capability_version_pk AND s.scenario_id=@scenario_id;
IF @matches=0 THROW 51000,'SCENARIO_NOT_IN_CAPABILITY',1;
IF @matches<>1 THROW 51000,'SCENARIO_NAMESPACE_AMBIGUOUS',1;

DECLARE @capability_digest varchar(64);
SELECT @capability_digest=LOWER(CONVERT(varchar(64),d.definition_digest,2))
FROM model.semantic_object_definition d WHERE d.semantic_object_definition_pk=@capability_definition_pk;

-- 0: the capability's own declared meaning.
SELECT d.declared_id AS capabilityId,d.namespace_id AS namespaceId,
       CASE WHEN @declared_root_count=1 THEN @declared_root END AS declaredRootScenarioId,
       @declared_root_count AS declaredRootCount,@scenario_id AS selectedScenarioId,
       'sha256:'+@capability_digest AS definitionDigest,d.definition_json AS definitionJson
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate_model_pk AND d.semantic_object_definition_pk=@capability_definition_pk;

DECLARE @closure TABLE(scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,
                       minimum_depth int,cycle_detected bit);
INSERT @closure(scenario_id,minimum_depth,cycle_detected)
SELECT s.scenario_id,MIN(cl.minimum_depth),MAX(CONVERT(tinyint,cl.cycle_detected))
FROM analysis.v_scenario_invocation_closure cl
JOIN model.scenario_version sv ON sv.scenario_version_pk=cl.downstream_scenario_version_pk
JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
WHERE cl.capability_version_pk=@capability_version_pk AND cl.selected_scenario_version_pk=@scenario_version_pk
GROUP BY s.scenario_id OPTION(MAXRECURSION 32767);

-- 1: each scenario in the declared closure, with its authored specification.
SELECT c.scenario_id AS scenarioId,c.minimum_depth AS minimumDepth,c.cycle_detected AS cycleDetected,
       d.definition_json AS definitionJson
FROM @closure c
LEFT JOIN analysis.v_selected_semantic_definition d
  ON d.estate_model_pk=@estate_model_pk AND d.object_kind='SCENARIO'
 AND d.declared_id=c.scenario_id COLLATE Latin1_General_100_BIN2
ORDER BY c.minimum_depth,c.scenario_id;

DECLARE @authorities TABLE(authority_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
                           owning_scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
                           definition_json nvarchar(max));
INSERT @authorities(authority_id,owning_scenario_id,definition_json)
SELECT d.declared_id,JSON_VALUE(d.definition_json,'$.semantics.authority.owningScenarioId'),d.definition_json
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind='EXECUTION_AUTHORITY'
  AND JSON_VALUE(d.definition_json,'$.semantics.authority.owningScenarioId') COLLATE Latin1_General_100_BIN2
      IN (SELECT scenario_id FROM @closure);

-- 2: the execution authority each scenario declares, with its operations.
SELECT authority_id AS authorityId,owning_scenario_id AS owningScenarioId,definition_json AS definitionJson
FROM @authorities ORDER BY owning_scenario_id,authority_id;

DECLARE @ports TABLE(port_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @ports(port_id)
SELECT DISTINCT JSON_VALUE(op.value,'$.portId') COLLATE Latin1_General_100_BIN2
FROM @authorities a CROSS APPLY OPENJSON(a.definition_json,'$.semantics.authority.operations') op
WHERE JSON_VALUE(op.value,'$.portId') IS NOT NULL;

DECLARE @port_definitions TABLE(port_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
                                platform_capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
                                transformation_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
                                definition_json nvarchar(max));
INSERT @port_definitions(port_id,platform_capability_id,transformation_id,definition_json)
SELECT d.declared_id,JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId'),
       JSON_VALUE(d.definition_json,'$.semantics.configuration.transformationId'),d.definition_json
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind='PORT'
  AND d.declared_id IN (SELECT port_id FROM @ports);

-- 3: the ports those operations invoke.
SELECT port_id AS portId,platform_capability_id AS platformCapabilityId,
       transformation_id AS transformationId,definition_json AS definitionJson
FROM @port_definitions ORDER BY port_id;

-- 4: the transformation each port is configured with.
SELECT d.declared_id AS transformationId,d.definition_json AS definitionJson
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind='TRANSFORMATION'
  AND d.declared_id IN (SELECT transformation_id FROM @port_definitions WHERE transformation_id IS NOT NULL)
ORDER BY d.declared_id;

-- 5: the observable conditions declared against this capability definition.
SELECT d.declared_id AS conditionId,d.definition_json AS definitionJson
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind='OBSERVABLE_CONDITION'
  AND JSON_VALUE(d.definition_json,'$.semantics.owner_definition_digest')=@capability_digest
ORDER BY d.declared_id;

-- 6: providers declaring an implementation of those ports' platform capabilities,
--    and the mechanics those providers declare.
SELECT DISTINCT pdf.platform_capability_id AS platformCapabilityId,p.provider_id AS providerId,
       m.mechanic_id AS mechanicId,mv.definition_profile AS definitionProfile
FROM @port_definitions pdf
JOIN model.capability cap ON cap.capability_id=pdf.platform_capability_id
JOIN model.capability_version cv ON cv.capability_pk=cap.capability_pk
JOIN model.provider_capability_implementation pci ON pci.capability_version_pk=cv.capability_version_pk
JOIN model.provider_definition pd ON pd.provider_definition_pk=pci.provider_definition_pk
JOIN model.provider p ON p.provider_pk=pd.provider_pk
JOIN model.estate_definition ed ON ed.estate_model_pk=@estate_model_pk
 AND ed.semantic_object_definition_pk=pd.semantic_object_definition_pk
LEFT JOIN model.provider_mechanic_implementation pmi ON pmi.provider_definition_pk=pd.provider_definition_pk
LEFT JOIN model.mechanic_version mv ON mv.mechanic_version_pk=pmi.mechanic_version_pk
LEFT JOIN model.mechanic m ON m.mechanic_pk=mv.mechanic_pk
ORDER BY pdf.platform_capability_id,p.provider_id,m.mechanic_id;
`;

const parse = value => {
  if (typeof value !== 'string' || !value.length) return null;
  try { return JSON.parse(value); } catch { return null; }
};
// A declared empty string is not a declaration. It is reported as absent rather
// than rendered as an empty sentence.
const text = value => (typeof value === 'string' && value.trim().length ? value : null);

export async function readCapabilityMeaning(databaseRoot, selection, { timings } = {}) {
  const { query } = await import(pathToFileURL(path.join(databaseRoot, 'src/query/run.mjs')));
  const start = performance.now();
  const read = await query(MEANING_SQL, { input: selection, rowLimit: 100000, retainObjects: false });
  if (timings) timings['capability-meaning.sql'] = performance.now() - start;
  if (read.truncated) throw new Error('DATABASE_AUTHORITY_NOT_COHERENT');
  const [capabilities, scenarios, authorities, ports, transformations, conditions, mechanics] = read.recordsets;
  if (!capabilities?.length) throw new Error('CAPABILITY_MEANING_UNAVAILABLE');

  const declared = parse(capabilities[0].definitionJson)?.semantics?.authority ?? null;
  return {
    snapshotId: read.snapshotId,
    projectionDigest: read.projectionDigest,
    viewDefinitionDigest: read.viewDefinitionDigest,
    capability: {
      capabilityId: capabilities[0].capabilityId,
      namespaceId: capabilities[0].namespaceId,
      declaredRootScenarioId: capabilities[0].declaredRootScenarioId,
      declaredRootCount: Number(capabilities[0].declaredRootCount ?? 0),
      selectedScenarioId: capabilities[0].selectedScenarioId,
      definitionDigest: capabilities[0].definitionDigest,
      mode: declared?.mode ?? null,
      name: text(declared?.name),
      userStory: declared?.userStory ?? null,
      experience: declared?.experience ?? null,
    },
    scenarios: scenarios.map(row => {
      const scenario = parse(row.definitionJson)?.semantics?.scenario ?? null;
      return {
        scenarioId: row.scenarioId,
        minimumDepth: row.minimumDepth,
        cycleDetected: Boolean(row.cycleDetected),
        declared: scenario !== null,
        keyword: text(scenario?.keyword),
        name: text(scenario?.name),
        description: text(scenario?.description),
        steps: Array.isArray(scenario?.steps) ? scenario.steps : [],
        tags: Array.isArray(scenario?.tags) ? scenario.tags.map(tag => tag?.name).filter(Boolean) : [],
        examples: Array.isArray(scenario?.examples) ? scenario.examples : [],
      };
    }),
    executionAuthorities: authorities.map(row => ({
      authorityId: row.authorityId,
      owningScenarioId: row.owningScenarioId,
      operations: parse(row.definitionJson)?.semantics?.authority?.operations ?? [],
    })),
    ports: ports.map(row => ({
      portId: row.portId,
      platformCapabilityId: row.platformCapabilityId,
      transformationId: row.transformationId,
      configuration: parse(row.definitionJson)?.semantics?.configuration ?? null,
    })),
    transformations: transformations.map(row => ({
      transformationId: row.transformationId,
      expression: parse(row.definitionJson)?.semantics?.expression ?? null,
    })),
    observableConditions: conditions.map(row => ({ conditionId: row.conditionId })),
    mechanics: mechanics.filter(row => row.mechanicId !== null).map(row => ({
      platformCapabilityId: row.platformCapabilityId,
      providerId: row.providerId,
      mechanicId: row.mechanicId,
      definitionProfile: row.definitionProfile,
    })),
    providers: [...new Set(mechanics.map(row => row.providerId))].sort(),
  };
}
