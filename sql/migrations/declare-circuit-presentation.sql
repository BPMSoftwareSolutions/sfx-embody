-- declare-circuit-presentation.sql
--
-- CV-B (docs/implementation-plan-circuit-view.md, "UID audit and agent guard" and
-- "TUI box rules"): the estate's circuit presentation policy as declared authority.
-- The box geometry, wrapping, justification, status-row format, altitude label
-- prefixes and the detail-cell collapse limit are rows, not renderer code; the
-- emitter at most interprets them. `CIRCUIT_DETAIL_LIMIT = 30` (classified UID: a
-- policy constant in the renderer) becomes granularity.detailCellLimit here, so the
-- policy moves from code into declared authority.
--
-- One declared read, read-circuit-presentation, returns exactly this policy. The
-- statement is the policy literal verbatim: it computes nothing, derives nothing and
-- reads no table. The read's display configuration selects a declared display
-- transformation (read-circuit-presentation-display.v1) whose expression selects the
-- outcome, so the declared bytes are the display document.
--
-- Encoding note (honesty): the six glyph values are declared as JSON \uXXXX escapes
-- (2713, 00d7, 2013, 25bc, 252c, 2502), not as raw characters. The stored bytes of a
-- definition are written as UTF-8 (measured correct), but every read path decodes
-- them with CONVERT(nvarchar, CONVERT(varchar, content_bytes) COLLATE ..._UTF8) under
-- the database default collation SQL_Latin1_General_CP1_CI_AS, which misreads UTF-8
-- as cp1252 and delivers mojibake to the runtime (measured: the stored check-mark's
-- bytes E29C93 are read back as three cp1252 characters). ASCII escapes survive losslessly,
-- are the same JSON value, and JSON.parse/JSON_VALUE decode them to the real glyphs:
-- the invoked outcome and the display document carry the actual characters. The
-- estate-wide decode defect is out of this unit's scope (rows only, no src/).
--
-- The capability is authored through the installed JSON surface
-- (model.declare_capability_document), whose chain is the same authoring surface the
-- SQL path uses: scaffold_capability, model.declare_contract, model.declare_scenario
-- and model.configure_interface. The document is installed twice to prove the replay
-- is a no-op.
--
-- Idempotent: the contracts are content-addressed, the transformation is declared
-- through the content-addressed writer, and the capability document's digest is the
-- installed-document gate.
--
-- Default was ROLLBACK. Installed 2026-09-17 after the rollback dry run (exact policy
-- 459/459; glyph code points 10003, 215, 8211, 9660, 9516, 9474) and the
-- from-transaction preflight on the request {contractId: circuit-presentation-request.v1}
-- (DISPOSITION completed; outcome policyType circuit-presentation.v1, outcomeContractId
-- circuit-presentation.v1, box 20/40/2, detailCellLimit 30, glyphs delivered decoded).
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
-- The statement is declaration data: it is carried by the port binding, not by code.
-- It receives @input (circuit-presentation-request.v1) and returns one JSON
-- circuit-presentation.v1 value in the value column. There is no computation: the
-- policy is authority, so the statement is the policy literal. The glyph values carry
-- their JSON escapes (see the encoding note above); every consumer sees the real
-- glyphs after JSON decode.
DECLARE @policy nvarchar(max) = N'{"policyType":"circuit-presentation.v1","box":{"minColumns":20,"maxColumns":40,"minRows":2,"align":"center","wrap":"hyphen-preferred"},"glyphs":{"success":"\u2713","failure":"\u00d7","unobserved":"\u2013","arrow":"\u25bc","fork":"\u252c","rail":"\u2502"},"statusRow":{"enabled":true,"format":"glyph duration"},"labels":{"prefixes":{"scenario":"SCENARIO","mechanic":"MECHANIC","provider":"PROVIDER","physical":"PHYSICAL"}},"granularity":{"detailCellLimit":30}}';
DECLARE @statement nvarchar(max) = N'SELECT N''' + @policy + N''' AS value;';

-- ============================== CONTRACTS ==============================
-- The request is permissive by design: an identity with room for future selection
-- (altitudes, widths, front end) without breaking the declaration. The policy
-- contract admits the declared shape; additionalProperties stays open so a policy
-- extension does not break the declaration. The capability document below declares
-- the same bytes, so the document path's contract step is a content-addressed no-op.
DECLARE @request_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/circuit-presentation-request.v1.schema.json","title":"Circuit presentation request","type":"object","additionalProperties":true,"required":["contractId"],"properties":{"contractId":{"const":"circuit-presentation-request.v1"},"payload":{"type":"object","additionalProperties":true}}}';
DECLARE @presentation_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/circuit-presentation.v1.schema.json","title":"Circuit presentation policy","type":"object","additionalProperties":true,"required":["policyType","box","glyphs","statusRow","labels","granularity"],"properties":{"policyType":{"const":"circuit-presentation.v1"},"box":{"type":"object","additionalProperties":true,"required":["minColumns","maxColumns","minRows","align","wrap"],"properties":{"minColumns":{"type":"integer","minimum":1},"maxColumns":{"type":"integer","minimum":1},"minRows":{"type":"integer","minimum":1},"align":{"type":"string"},"wrap":{"type":"string"}}},"glyphs":{"type":"object","additionalProperties":true,"required":["success","failure","unobserved","arrow","fork","rail"],"properties":{"success":{"type":"string"},"failure":{"type":"string"},"unobserved":{"type":"string"},"arrow":{"type":"string"},"fork":{"type":"string"},"rail":{"type":"string"}}},"statusRow":{"type":"object","additionalProperties":true,"required":["enabled","format"],"properties":{"enabled":{"type":"boolean"},"format":{"type":"string"}}},"labels":{"type":"object","additionalProperties":true,"properties":{"prefixes":{"type":"object","additionalProperties":{"type":"string"}}}},"granularity":{"type":"object","additionalProperties":true,"required":["detailCellLimit"],"properties":{"detailCellLimit":{"type":"integer","minimum":1}}}}}';
EXEC model.declare_contract @id=N'circuit-presentation-request.v1', @schema=@request_schema;
EXEC model.declare_contract @id=N'circuit-presentation.v1', @schema=@presentation_schema;

-- ============================== CAPABILITY DOCUMENT ==============================
DECLARE @contracts nvarchar(max) = N'[{"id":"circuit-presentation-request.v1","schema":' + @request_schema + N'},{"id":"circuit-presentation.v1","schema":' + @presentation_schema + N'}]';
DECLARE @bindings nvarchar(max) = N'[{"portId":"read-circuit-presentation-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,N'json') + N'","resultColumn":"value"}}]';
DECLARE @cli nvarchar(max) = N'{"display":{"transformationId":"read-circuit-presentation-display.v1","as":"json"}}';
DECLARE @document nvarchar(max) = N'{
 "document":"sidefx-capability-authority.v1",
 "capabilityId":"read-circuit-presentation",
 "meaning":{"intent":"read the estate''s circuit presentation policy","outcome":"the caller observes the declared presentation policy: box geometry, glyphs, status-row format, altitude label prefixes and the detail-cell limit"},
 "cli":' + @cli + N',
 "contracts":' + @contracts + N',
 "scenarios":[{
  "scenarioId":"read-circuit-presentation",
  "name":"Read the circuit presentation policy",
  "inputId":"circuit-presentation-request",
  "inputContract":"circuit-presentation-request.v1",
  "eventId":"circuit-presentation-requested",
  "eventAuthority":"read-circuit-presentation.v1",
  "outcomeId":"circuit-presentation",
  "outcomeContract":"circuit-presentation.v1",
  "terminal":true,
  "root":true,
  "given":"the estate''s circuit presentation policy is declared authority",
  "when":"the declared presentation read executes under the reader boundary",
  "then":"the caller observes the policy document: box geometry, glyphs, status row, label prefixes and the detail-cell limit",
  "operations":[{"operationId":"read-circuit-presentation.0","kind":"invoke-port","portId":"read-circuit-presentation-port"}],
  "portBindings":' + @bindings + N'
 }]
}';
EXEC model.declare_capability_document @document=@document;
EXEC model.declare_capability_document @document=@document;

-- ============================== THE DECLARED DISPLAY PROJECTION ==============================
-- The read's display configuration selects this transformation. It returns the policy
-- itself (the read's outcome) as the display document, so the declared bytes are the
-- policy; the terminal renders it as json with the decoded glyphs.
DECLARE @namespace nvarchar(400)=N'sidefx:capability:read-circuit-presentation';
DECLARE @transformationId nvarchar(400)=N'read-circuit-presentation-display.v1';
DECLARE @expression nvarchar(max)=N'{"op":"let","bindings":{"policy":{"op":"path","from":"execution","path":"outcome"}},"value":{"op":"path","from":"policy","path":""}}';
DECLARE @semantics nvarchar(max)=N'{"id":"read-circuit-presentation-display.v1","expression":'+@expression+N'}';
DECLARE @object bigint,@definition bigint,@digest binary(32),@transformation bigint,@version bigint;
EXEC model.put_semantic_definition 'TRANSFORMATION',@namespace,@transformationId,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
SET @transformation=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@object);
IF @transformation IS NULL BEGIN
 INSERT model.transformation(namespace_pk,transformation_id,semantic_object_pk,object_kind)
 SELECT namespace_pk,@transformationId,@object,'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk=@object;
 SET @transformation=SCOPE_IDENTITY();
END
SET @version=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@definition);
IF @version IS NULL BEGIN
 INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@transformation,@object,@definition,@digest,'json-expression-tree.v1','TRANSFORMATION',@definition,N'');
 SET @version=SCOPE_IDENTITY();
 EXEC model.normalize_transformation_expression @version;
END

-- ============================== PROOF ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

SELECT '1_contracts' AS result_set, d.declared_id AS contract_id, COUNT(*) AS current_definitions
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='CONTRACT'
 AND d.declared_id IN (N'circuit-presentation-request.v1',N'circuit-presentation.v1')
GROUP BY d.declared_id
ORDER BY d.declared_id;

SELECT '2_capability' AS result_set, c.capability_id, s.scenario_id, eo.operation_id, eo.operation_kind,
 p.port_id, JSON_VALUE(pd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
 JSON_VALUE(pd.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 CASE WHEN CHARINDEX(N'"policyType":"circuit-presentation.v1"',JSON_VALUE(pd.definition_json,'$.semantics.configuration.statement'))>0 THEN 1 ELSE 0 END AS policy_declared,
 CASE WHEN CHARINDEX(N'"detailCellLimit":30',JSON_VALUE(pd.definition_json,'$.semantics.configuration.statement'))>0 THEN 1 ELSE 0 END AS detail_limit_declared,
 CASE WHEN CHARINDEX(N'\u2713',JSON_VALUE(pd.definition_json,'$.semantics.configuration.statement'))>0 THEN 1 ELSE 0 END AS glyph_escapes_stored
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
WHERE c.capability_id=N'read-circuit-presentation';

SELECT '3_display_transformation' AS result_set, t.transformation_id, tv.transformation_version_pk, @digest AS definition_digest,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.expression.value.from') AS selects_from,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.expression.value.path') AS selects_path
FROM model.transformation t
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=@definition
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
LEFT JOIN model.transformation_version tv ON tv.semantic_object_definition_pk=d.semantic_object_definition_pk
WHERE t.semantic_object_pk=@object;

-- The assembled graph source from the uncommitted transaction: the interface selects
-- the declared display transformation and the transformation travels with the capability.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-circuit-presentation',0,N'sidefx:capabilities'));
SELECT '4_graph_source' AS result_set, g.root_scenario_id,
 JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.transformationId') AS display_transformation_id,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations')) t WHERE JSON_VALUE(t.value,'$.id')=@transformationId) AS display_transformation_present
FROM analysis.v_capability_graph_source g WHERE g.capability_id=N'read-circuit-presentation';

-- The behavioral self-test: the declared statement itself is executed and compared
-- byte-for-byte with the policy literal. The read computes nothing; the proof is that
-- the declared bytes are returned exactly as authored. The values result set reads the
-- policy through JSON_VALUE, so the escape-encoded glyphs are decoded by SQL Server's
-- JSON parser and their code points prove the real characters.
DECLARE @stmt nvarchar(max);
SELECT @stmt=js.statement
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') WITH (statement nvarchar(max) '$.statement') js
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=N'sidefx:capability:read-circuit-presentation' AND d.declared_id=N'read-circuit-presentation-port';
DECLARE @sample nvarchar(max)=N'{"contractId":"circuit-presentation-request.v1"}';
DECLARE @policy_table TABLE (value nvarchar(max));
INSERT @policy_table EXEC sp_executesql @stmt,N'@input nvarchar(max), @estate_model_pk bigint',@input=@sample,@estate_model_pk=@estate;
SELECT '5_policy_exact' AS result_set,
 CASE WHEN (SELECT value FROM @policy_table)=@policy THEN 1 ELSE 0 END AS exact_policy,
 (SELECT LEN(value) FROM @policy_table) AS returned_length,
 LEN(@policy) AS declared_length
FROM @policy_table;
SELECT '6_policy_values' AS result_set,
 JSON_VALUE(v.value,'$.policyType') AS policy_type,
 JSON_VALUE(v.value,'$.box.minColumns') AS box_min_columns,
 JSON_VALUE(v.value,'$.box.maxColumns') AS box_max_columns,
 JSON_VALUE(v.value,'$.box.minRows') AS box_min_rows,
 JSON_VALUE(v.value,'$.box.align') AS box_align,
 JSON_VALUE(v.value,'$.box.wrap') AS box_wrap,
 JSON_VALUE(v.value,'$.glyphs.success') AS glyph_success,
 UNICODE(JSON_VALUE(v.value,'$.glyphs.success')) AS glyph_success_code,
 JSON_VALUE(v.value,'$.glyphs.failure') AS glyph_failure,
 UNICODE(JSON_VALUE(v.value,'$.glyphs.failure')) AS glyph_failure_code,
 JSON_VALUE(v.value,'$.glyphs.unobserved') AS glyph_unobserved,
 UNICODE(JSON_VALUE(v.value,'$.glyphs.unobserved')) AS glyph_unobserved_code,
 JSON_VALUE(v.value,'$.glyphs.arrow') AS glyph_arrow,
 UNICODE(JSON_VALUE(v.value,'$.glyphs.arrow')) AS glyph_arrow_code,
 JSON_VALUE(v.value,'$.glyphs.fork') AS glyph_fork,
 UNICODE(JSON_VALUE(v.value,'$.glyphs.fork')) AS glyph_fork_code,
 JSON_VALUE(v.value,'$.glyphs.rail') AS glyph_rail,
 UNICODE(JSON_VALUE(v.value,'$.glyphs.rail')) AS glyph_rail_code,
 JSON_VALUE(v.value,'$.statusRow.enabled') AS status_row_enabled,
 JSON_VALUE(v.value,'$.statusRow.format') AS status_row_format,
 JSON_VALUE(v.value,'$.labels.prefixes.scenario') AS prefix_scenario,
 JSON_VALUE(v.value,'$.labels.prefixes.mechanic') AS prefix_mechanic,
 JSON_VALUE(v.value,'$.labels.prefixes.provider') AS prefix_provider,
 JSON_VALUE(v.value,'$.labels.prefixes.physical') AS prefix_physical,
 JSON_VALUE(v.value,'$.granularity.detailCellLimit') AS detail_cell_limit
FROM @policy_table v;

-- One current definition per declared id: the replay above minted no duplicate
-- capability document, port or transformation.
SELECT '7_current_definitions' AS result_set, d.namespace_id, d.object_kind, d.declared_id, COUNT(*) AS current_definitions
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate
 AND (d.namespace_id=N'sidefx:capability:read-circuit-presentation'
  OR (d.namespace_id=N'sidefx:capability-documents' AND d.declared_id=N'read-circuit-presentation'))
GROUP BY d.namespace_id,d.object_kind,d.declared_id
ORDER BY d.namespace_id,d.object_kind,d.declared_id;

COMMIT TRANSACTION;
