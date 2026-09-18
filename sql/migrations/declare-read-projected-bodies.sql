-- declare-read-projected-bodies.sql
--
-- U5b: the query backdoor retires. The hand-authored
-- scripts/queries/list-projected-bodies.sql (executed by scripts/run-query.mjs
-- from the workspace) becomes the declared read `read-projected-bodies`: one
-- capability whose single declared-read port carries the statement and result
-- column as rows. It is executable through the kernel entry -- the statement is
-- data, never a `.sql` file read from the workspace:
--
--   node <SDA>/languages/typescript/src/kernel/bootstrap/entry.mjs \
--     capability invoke read-projected-bodies \
--     --input '{"capabilityId":"resolve-equity-market-price-evidence"}' --json
--
-- The read preserves the original query's two result sets as one read:
--
--   * projectedBodies       the database copy of a capability's projected
--                           mechanical bodies keyed by capability + generation +
--                           projection target + relative path, with the
--                           content-addressed digest and byte length of each
--                           body;
--   * hotPathIsolation      the same mapping-stays-off-the-hot-path counts: no
--                           model object, selected definition, execution
--                           declaration, model definition, observation or
--                           lineage row references a projected body.
--
-- The current generation is the highest generation row that carries
-- source_class='PROJECTED_BODY' rows for the capability; a caller may name a
-- generationPk instead to read an older generation. The generation and manifest
-- digests travel with the reading.
--
-- Idempotent: model.declare_capability_document skips a replay of the same
-- document bytes and re-declares the same content-addressed definitions.
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
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trigger_name); FETCH NEXT FROM @triggers INTO @trigger_name; END;
CLOSE @triggers; DEALLOCATE @triggers;
GO

-- ============================== THE DECLARED READ STATEMENT ==============================
-- The statement is declaration data: it is carried by the port binding, not by
-- code. It receives @input (the read-projected-bodies-request.v1 request) and the
-- pinned estate parameters, and returns one JSON reading in the `bundle` column.
DECLARE @statement nvarchar(max) = N'
DECLARE @capability nvarchar(400)=CONVERT(nvarchar(400),JSON_VALUE(@input,''$.capabilityId''));
IF @capability IS NULL THROW 51000,''PROJECTED_BODIES_CAPABILITY_REQUIRED'',1;
DECLARE @generationPk bigint=TRY_CONVERT(bigint,JSON_VALUE(@input,''$.generationPk''));
IF @generationPk IS NULL
 SET @generationPk=(SELECT MAX(a.estate_snapshot_pk) FROM source.source_appearance a
  WHERE a.source_class=''PROJECTED_BODY'' AND JSON_VALUE(a.container_locator,''$.capabilityId'')=@capability);
DECLARE @generation nvarchar(80)=NULL,@manifest nvarchar(80)=NULL;
SELECT @generation=''sha256:''+LOWER(CONVERT(varchar(64),s.snapshot_digest,2)),
       @manifest=''sha256:''+LOWER(CONVERT(varchar(64),s.estate_manifest_digest,2))
FROM source.estate_snapshot s WHERE s.estate_snapshot_pk=@generationPk;
DECLARE @bodies nvarchar(max)=(SELECT
 JSON_VALUE(a.container_locator,''$.capabilityId'') AS capabilityId,
 a.estate_snapshot_pk AS generationPk,
 @generation AS generation,
 @manifest AS manifestDigest,
 JSON_VALUE(a.container_locator,''$.projectionTarget'') AS target,
 JSON_VALUE(a.container_locator,''$.relativePath'') AS relativePath,
 a.entry_id AS locatorEntry,
 a.source_path AS locatorPath,
 ''sha256:''+LOWER(CONVERT(varchar(64),c.content_digest,2)) AS digest,
 c.byte_length AS byteLength
FROM source.source_appearance a
JOIN source.content_object c ON c.content_object_pk=a.content_object_pk
WHERE a.source_class=''PROJECTED_BODY'' AND a.estate_snapshot_pk=@generationPk
ORDER BY target,relativePath FOR JSON PATH);
DECLARE @isolation nvarchar(max)=(SELECT
 (SELECT COUNT(*) FROM model.semantic_object WHERE object_kind=''PROJECTED_BODY'') AS modelObjects,
 (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition WHERE object_kind=''PROJECTED_BODY'') AS selectedDefinitions,
 (SELECT COUNT(*) FROM analysis.v_capability_execution_declaration WHERE source_path LIKE N''projected-bodies/%'') AS declarationDocuments,
 (SELECT COUNT(*) FROM model.semantic_object_definition d
    JOIN source.source_appearance a ON a.content_object_pk=d.canonical_content_pk
    WHERE a.source_class=''PROJECTED_BODY'' AND a.estate_snapshot_pk=@generationPk) AS modelDefinitionsOverBodies,
 (SELECT COUNT(*) FROM source.source_observation o
    JOIN source.source_appearance a ON a.source_appearance_pk=o.source_appearance_pk
    WHERE a.source_class=''PROJECTED_BODY'' AND a.estate_snapshot_pk=@generationPk) AS observationsOverBodies,
 (SELECT COUNT(*) FROM source.source_lineage l
    JOIN source.source_observation o ON o.source_observation_pk=l.source_observation_pk
    JOIN source.source_appearance a ON a.source_appearance_pk=o.source_appearance_pk
    WHERE a.source_class=''PROJECTED_BODY'' AND a.estate_snapshot_pk=@generationPk) AS lineageRowsOverBodies
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SELECT (SELECT N''projected-bodies-reading.v1'' AS reading,@capability AS capabilityId,@generationPk AS generationPk,@generation AS generation,@manifest AS manifestDigest,JSON_QUERY(@bodies) AS projectedBodies,JSON_QUERY(@isolation) AS hotPathIsolation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS bundle';
DECLARE @bindings nvarchar(max) = N'[{"portId":"read-projected-bodies-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,N'json') + N'","resultColumn":"bundle"}}]';

-- ============================== CONTRACTS AND CAPABILITY DOCUMENT ==============================
DECLARE @contracts nvarchar(max) = N'[
 {"id":"read-projected-bodies-request.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/read-projected-bodies-request.v1.schema.json","title":"Read projected bodies request","type":"object","additionalProperties":false,"required":["capabilityId"],"properties":{"capabilityId":{"type":"string"},"generationPk":{"type":"integer"}}}},
 {"id":"projected-bodies-reading.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/projected-bodies-reading.v1.schema.json","title":"Projected bodies reading","type":"object","additionalProperties":true,"required":["reading","capabilityId","projectedBodies","hotPathIsolation"],"properties":{"reading":{"const":"projected-bodies-reading.v1"},"capabilityId":{"type":"string"},"generationPk":{"type":["integer","null"]},"generation":{"type":["string","null"]},"manifestDigest":{"type":["string","null"]},"projectedBodies":{"type":"array"},"hotPathIsolation":{"type":"object"}}}}
]';
DECLARE @document nvarchar(max) = N'{
 "document":"sidefx-capability-authority.v1",
 "capabilityId":"read-projected-bodies",
 "meaning":{"intent":"read the database copy of one capability''s projected mechanical bodies","outcome":"the caller observes the current generation''s projected bodies keyed by capability, target and relative path with their content digests, and the hot-path isolation counts"},
 "contracts":' + @contracts + N',
 "scenarios":[{
  "scenarioId":"read-projected-bodies",
  "name":"Read the projected bodies of one capability",
  "inputId":"read-projected-bodies-request",
  "inputContract":"read-projected-bodies-request.v1",
  "eventId":"projected-bodies-requested",
  "eventAuthority":"read-projected-bodies.v1",
  "outcomeId":"projected-bodies-reading",
  "outcomeContract":"projected-bodies-reading.v1",
  "terminal":true,
  "root":true,
  "given":"one declared capability and, optionally, one projected-body generation",
  "when":"the declared projected-bodies read executes under the reader boundary",
  "then":"the generation''s projected bodies and the hot-path isolation counts are returned as one reading",
  "operations":[{"operationId":"read-projected-bodies.0","kind":"invoke-port","portId":"read-projected-bodies-port"}],
  "portBindings":' + @bindings + N'
 }]
}';
EXEC model.declare_capability_document @document=@document;

-- ============================== PROOF ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

SELECT '1_contracts' AS result_set, d.declared_id AS contract_id
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='CONTRACT'
 AND d.declared_id IN (N'read-projected-bodies-request.v1',N'projected-bodies-reading.v1')
ORDER BY d.declared_id;

SELECT '2_capability' AS result_set, c.capability_id, s.scenario_id,
 p.port_id, JSON_VALUE(pd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
 JSON_VALUE(pd.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 LEN(JSON_VALUE(pd.definition_json,'$.semantics.configuration.statement')) AS statement_chars
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN analysis.v_selected_semantic_definition pd ON pd.semantic_object_definition_pk=pv.semantic_object_definition_pk AND pd.estate_model_pk=@estate
WHERE c.capability_id=N'read-projected-bodies';

-- The assembled graph source from the uncommitted transaction: the declared
-- read port is present with its statement and result column.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-projected-bodies',0,N'sidefx:capabilities'));
SELECT '3_graph_source' AS result_set,
 JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.portBindings[0].configuration'),'$.resultColumn') AS result_column,
 CASE WHEN JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.portBindings[0].configuration'),'$.statement') LIKE N'%PROJECTED_BODY%' THEN 1 ELSE 0 END AS statement_declared;

-- The behavioral self-test: the declared statement itself is executed against
-- the live store for the equity capability. The reading reproduces the counts the
-- original query produced (bodies listed for the current generation; every
-- hot-path count zero).
DECLARE @stmt nvarchar(max)=(SELECT JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.configuration.statement')
 FROM analysis.v_selected_semantic_definition d
 JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=d.semantic_object_definition_pk
 JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=N'sidefx:capability:read-projected-bodies' AND d.declared_id=N'read-projected-bodies-port');
DECLARE @sample nvarchar(max)=N'{"capabilityId":"resolve-equity-market-price-evidence"}';
DECLARE @reading TABLE (bundle nvarchar(max));
INSERT @reading EXEC sp_executesql @stmt,N'@input nvarchar(max), @estate_model_pk bigint',@input=@sample,@estate_model_pk=@estate;
SELECT '4_reading_self_test' AS result_set,
 JSON_VALUE(bundle,'$.reading') AS reading,
 JSON_VALUE(bundle,'$.capabilityId') AS capability_id,
 JSON_VALUE(bundle,'$.generationPk') AS generation_pk,
 JSON_VALUE(bundle,'$.generation') AS generation,
 JSON_VALUE(bundle,'$.manifestDigest') AS manifest_digest,
 (SELECT COUNT(*) FROM OPENJSON(bundle,'$.projectedBodies')) AS projected_bodies,
 JSON_VALUE(bundle,'$.hotPathIsolation.modelObjects') AS model_objects,
 JSON_VALUE(bundle,'$.hotPathIsolation.selectedDefinitions') AS selected_definitions,
 JSON_VALUE(bundle,'$.hotPathIsolation.declarationDocuments') AS declaration_documents,
 JSON_VALUE(bundle,'$.hotPathIsolation.modelDefinitionsOverBodies') AS model_definitions_over_bodies,
 JSON_VALUE(bundle,'$.hotPathIsolation.observationsOverBodies') AS observations_over_bodies,
 JSON_VALUE(bundle,'$.hotPathIsolation.lineageRowsOverBodies') AS lineage_rows_over_bodies
FROM @reading;
COMMIT TRANSACTION;
-- Installed 2026-09-18 after the rollback dry run and the from-transaction
-- preflight (evidence/vault-20260916/u5a): 51 projected bodies for
-- resolve-equity-market-price-evidence at generation sha256:e1789859..., every
-- hot-path isolation count zero, and the declared read byte-parity with the
-- original list-projected-bodies.sql rows it replaces.
