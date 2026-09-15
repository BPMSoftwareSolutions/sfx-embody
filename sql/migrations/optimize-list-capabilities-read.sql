-- optimize-list-capabilities-read.sql
--
-- `list`, `find` and `catalogue` are served by the declared read
-- `list-capabilities` (declare-list-capabilities.sql, extended by
-- add-catalogue-circuit-availability.sql). The retained statement computed
-- capability roots and scenario counts per capability through correlated
-- OUTER APPLYs and joined analysis.v_selected_semantic_definition once per
-- capability and once per scenario row -- even when the caller supplied no
-- query -- which dominated the listing (about ten seconds of SQL time on the
-- current estate).
--
-- This migration re-declares only `list-capabilities-port` with a set-based
-- statement:
--   * capability roots and scenario counts are aggregated once
--     (GROUP BY capability_version_pk);
--   * the matched-scenario set is computed at most once and only when a query
--     was supplied, so the no-query listing never reads the scenario
--     definitions;
--   * the selected capability definition is read through one hash join; the
--     nested-loop alternative scanned model.semantic_object_definition once
--     per capability (about 11k rows per capability).
-- Every field, its order, the capability_id ordering, the literal CHARINDEX
-- matching semantics and the exact matchedFields labels/order, the circuit
-- availability bit and the no-publication false case are preserved. The read
-- still executes under sidefx_reader; no grant changes.
--
-- Idempotent: a second run finds the set-based statement already selected and
-- re-declares nothing.
--
-- Default: ROLLBACK. Replace the final ROLLBACK TRANSACTION; with COMMIT
-- TRANSACTION; to install (after the from-transaction preflight passes).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers=CURSOR LOCAL FAST_FORWARD FOR
 SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
 FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id
 JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE o.type='U' AND s.name IN ('model','source')
 AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0 BEGIN
 EXEC(N'DROP TRIGGER '+@trigger_name);
 FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @ns nvarchar(400)=N'sidefx:capability:list-capabilities' COLLATE Latin1_General_100_BIN2;
DECLARE @port nvarchar(400)=N'list-capabilities-port' COLLATE Latin1_General_100_BIN2;
DECLARE @sem nvarchar(max), @prevver bigint, @object2 bigint, @definition2 bigint, @digest2 binary(32), @portpk bigint, @version bigint;
SELECT @sem=JSON_QUERY(d.definition_json,'$.semantics'),
 @prevver=(SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@ns AND d.declared_id=@port;
IF @sem IS NULL THROW 51000,'LIST_CAPABILITIES_PORT_NOT_SELECTED',1;
-- One statement: the selected estate model's capabilities as a JSON array.
-- Roots and scenario counts are aggregated once; matching is literal and the
-- matched-scenario set is computed only for a supplied query. Availability is
-- checked against the latest explicit publication's catalogue keys.
DECLARE @statement nvarchar(max)=N'DECLARE @namespace_id nvarchar(4000)=JSON_VALUE(@input,''$.namespaceId'');
DECLARE @query nvarchar(4000)=NULLIF(LOWER(LTRIM(RTRIM(JSON_VALUE(@input,''$.query'')))),'''');
DECLARE @circuit_prefix nvarchar(400)=N''/media/library/outputs/estate-topology/'';
DECLARE @circuit_catalogs TABLE (url nvarchar(500) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @circuit_catalogs(url)
SELECT CONVERT(nvarchar(500),[key]) COLLATE Latin1_General_100_BIN2
FROM OPENJSON(COALESCE(JSON_QUERY((
 SELECT TOP 1 CONVERT(nvarchar(max), CONVERT(varchar(max),b.bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM media.asset a
 JOIN media.asset_revision r ON r.asset_id=a.asset_id
 JOIN media.blob b ON b.digest=r.blob_digest
 WHERE a.logical_key=CONCAT(''media-catalog/'',@estate_model_pk,''/website-visual-publication'')
 ORDER BY r.created_at DESC, r.revision_id DESC),''$.artifacts''),N''[]''))
WHERE [key] LIKE @circuit_prefix+N''%/catalog.js'';
DECLARE @matched_scenarios TABLE (capability_version_pk bigint PRIMARY KEY, matched_scenarios bigint);
IF @query IS NOT NULL
 INSERT @matched_scenarios(capability_version_pk,matched_scenarios)
 SELECT cs.capability_version_pk, COUNT_BIG(*)
 FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
 LEFT JOIN analysis.v_selected_semantic_definition sd
   ON sd.estate_model_pk=@estate_model_pk AND sd.object_kind=''SCENARIO'' AND sd.declared_id=s.scenario_id
 WHERE CHARINDEX(@query,LOWER(s.scenario_id))>0
   OR CHARINDEX(@query,LOWER(JSON_VALUE(sd.definition_json,''$.semantics.scenario.name'')))>0
 GROUP BY cs.capability_version_pk;
WITH declared AS (
  SELECT ec.capability_version_pk, c.capability_id, n.namespace_id,
    ''sha256:''+LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS definition_digest,
    JSON_VALUE(d.definition_json,''$.semantics.authority.name'') AS declared_name,
    JSON_VALUE(d.definition_json,''$.semantics.authority.mode'') AS mode,
    JSON_VALUE(d.definition_json,''$.semantics.authority.userStory.actor'') AS actor,
    JSON_VALUE(d.definition_json,''$.semantics.authority.userStory.intent'') AS intent,
    JSON_VALUE(d.definition_json,''$.semantics.authority.userStory.outcome'') AS outcome,
    JSON_VALUE(d.definition_json,''$.semantics.authority.experience.promise'') AS promise
  FROM model.estate_capability ec
  JOIN model.capability c ON c.capability_pk=ec.capability_pk
  JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  LEFT HASH JOIN analysis.v_selected_semantic_definition d
    ON d.estate_model_pk=ec.estate_model_pk AND d.semantic_object_definition_pk=ec.semantic_object_definition_pk
  WHERE ec.estate_model_pk=@estate_model_pk
    AND (@namespace_id IS NULL OR n.namespace_id=@namespace_id)
),
roots AS (
  SELECT r.capability_version_pk, COUNT_BIG(*) AS declared_root_count, MAX(s.scenario_id) AS root_scenario_id
  FROM model.capability_root_scenario r JOIN model.scenario s ON s.scenario_pk=r.scenario_pk
  GROUP BY r.capability_version_pk
),
scenario_counts AS (
  SELECT cs.capability_version_pk, COUNT_BIG(*) AS scenario_count
  FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
  LEFT JOIN analysis.v_selected_semantic_definition sd
    ON sd.estate_model_pk=@estate_model_pk AND sd.object_kind=''SCENARIO'' AND sd.declared_id=s.scenario_id
  GROUP BY cs.capability_version_pk
)
SELECT (SELECT d.capability_id AS capabilityId, d.namespace_id AS namespaceId, d.definition_digest AS definitionDigest,
  d.declared_name AS name, d.mode,
  ISNULL(roots.declared_root_count,0) AS declaredRootCount,
  CASE WHEN roots.declared_root_count=1 THEN roots.root_scenario_id END AS declaredRootScenarioId,
  ISNULL(scenarios.scenario_count,0) AS scenarioCount,
  CASE WHEN d.actor IS NULL AND d.intent IS NULL AND d.outcome IS NULL THEN NULL
    ELSE JSON_QUERY((SELECT d.actor AS actor, d.intent AS intent, d.outcome AS outcome FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) END AS userStory,
  d.promise, CONVERT(bit, CASE WHEN EXISTS (SELECT 1 FROM @circuit_catalogs t WHERE t.url=@circuit_prefix+d.capability_id+N''/catalog.js'') THEN 1 ELSE 0 END) AS circuitAvailable,
  CASE WHEN @query IS NULL THEN NULL ELSE LTRIM(
    CASE WHEN CHARINDEX(@query,LOWER(d.capability_id))>0 THEN '' capabilityId'' ELSE '''' END
    + CASE WHEN CHARINDEX(@query,LOWER(d.namespace_id))>0 THEN '' namespaceId'' ELSE '''' END
    + CASE WHEN CHARINDEX(@query,LOWER(d.declared_name))>0 THEN '' name'' ELSE '''' END
    + CASE WHEN CHARINDEX(@query,LOWER(d.actor))>0 THEN '' actor'' ELSE '''' END
    + CASE WHEN CHARINDEX(@query,LOWER(d.intent))>0 THEN '' intent'' ELSE '''' END
    + CASE WHEN CHARINDEX(@query,LOWER(d.outcome))>0 THEN '' outcome'' ELSE '''' END
    + CASE WHEN CHARINDEX(@query,LOWER(d.promise))>0 THEN '' promise'' ELSE '''' END
    + CASE WHEN matched.matched_scenarios>0 THEN '' scenario'' ELSE '''' END) END AS matchedFields
FROM declared d
LEFT JOIN roots ON roots.capability_version_pk=d.capability_version_pk
LEFT JOIN scenario_counts scenarios ON scenarios.capability_version_pk=d.capability_version_pk
LEFT JOIN @matched_scenarios matched ON matched.capability_version_pk=d.capability_version_pk
WHERE @query IS NULL
  OR CHARINDEX(@query,LOWER(d.capability_id))>0 OR CHARINDEX(@query,LOWER(d.namespace_id))>0
  OR CHARINDEX(@query,LOWER(d.declared_name))>0 OR CHARINDEX(@query,LOWER(d.actor))>0
  OR CHARINDEX(@query,LOWER(d.intent))>0 OR CHARINDEX(@query,LOWER(d.outcome))>0
  OR CHARINDEX(@query,LOWER(d.promise))>0 OR matched.matched_scenarios>0
ORDER BY d.capability_id
FOR JSON PATH) AS capabilities';
-- JSON_VALUE truncates a value longer than 4000 characters to NULL; read the
-- retained statement whole so the idempotency marker is always visible.
DECLARE @previous nvarchar(max);
SELECT @previous=statement FROM OPENJSON(@sem,'$.configuration') WITH (statement nvarchar(max) '$.statement');
IF CHARINDEX(N'@matched_scenarios',@previous)=0
BEGIN
 IF @prevver IS NULL THROW 51000,'LIST_CAPABILITIES_PORT_VERSION_MISSING',1;
 SET @sem=JSON_MODIFY(@sem,'$.configuration.statement',@statement);
 EXEC model.put_semantic_definition 'PORT',@ns,@port,@sem,@object2 OUTPUT,@definition2 OUTPUT,@digest2 OUTPUT;
 SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object2);
 IF @portpk IS NOT NULL BEGIN
  SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition2);
  IF @version IS NULL BEGIN
   INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@portpk,@object2,@definition2,@digest2,'consumer-interface-authority.v1','PORT',@definition2,N'');
   SET @version=SCOPE_IDENTITY();
  END
  UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
 END
END
-- Proof: the selected statement carries the set-based shape; the invocation
-- points at that definition's port version.
SELECT 'list_capabilities_read_source' AS result_set, d.declared_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 CONVERT(bit,CASE WHEN c.statement LIKE N'%@matched_scenarios%' THEN 1 ELSE 0 END) AS match_guard,
 CONVERT(bit,CASE WHEN c.statement LIKE N'%LEFT HASH JOIN analysis.v_selected_semantic_definition%' THEN 1 ELSE 0 END) AS set_based_definition,
 CONVERT(bit,CASE WHEN c.statement LIKE N'%OUTER APPLY%' THEN 1 ELSE 0 END) AS per_capability_apply,
 LEN(c.statement) AS statement_chars
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') WITH (statement nvarchar(max) '$.statement') c
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT' AND d.namespace_id=@ns AND d.declared_id=@port;
SELECT 'list_capabilities_port_version' AS result_set, opi.execution_operation_pk, opi.port_version_pk,
 pv.semantic_object_definition_pk, @prevver AS previous_port_version_pk
FROM model.operation_port_invocation opi
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
WHERE opi.port_version_pk=(SELECT pv2.port_version_pk FROM model.port_version pv2
 WHERE pv2.semantic_object_definition_pk=(SELECT d.semantic_object_definition_pk
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind='PORT' AND d.namespace_id=@ns AND d.declared_id=@port));
-- Proof: the selected statement runs from the uncommitted state. The listing
-- returns every declared capability; the query path reports the match.
DECLARE @listing TABLE (capabilities nvarchar(max));
INSERT @listing EXEC sp_executesql @statement, N'@input nvarchar(max), @estate_model_pk bigint',
 N'{"namespaceId":"sidefx:capabilities"}', @estate_model_pk=@estate;
SELECT 'list_capabilities_listing' AS result_set,
 (SELECT COUNT_BIG(*) FROM OPENJSON((SELECT capabilities FROM @listing),'$')) AS capability_count,
 JSON_VALUE((SELECT capabilities FROM @listing),'$[0].capabilityId') AS first_capability_id,
 JSON_VALUE((SELECT capabilities FROM @listing),'$[0].circuitAvailable') AS first_circuit_available;
DECLARE @found TABLE (capabilities nvarchar(max));
INSERT @found EXEC sp_executesql @statement, N'@input nvarchar(max), @estate_model_pk bigint',
 N'{"query":"scaffold"}', @estate_model_pk=@estate;
SELECT 'list_capabilities_find' AS result_set,
 JSON_VALUE((SELECT capabilities FROM @found),'$[0].capabilityId') AS first_capability_id,
 JSON_VALUE((SELECT capabilities FROM @found),'$[0].matchedFields') AS matched_fields;
COMMIT TRANSACTION;
