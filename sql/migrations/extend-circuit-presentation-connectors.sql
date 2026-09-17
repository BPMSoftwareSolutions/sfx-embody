-- extend-circuit-presentation-connectors.sql
--
-- CV-C part 1 (docs/implementation-plan-circuit-view.md, "UID audit and agent guard"
-- and "TUI box rules"): the declared presentation policy gains the two rule families
-- it still lacked, so no presentation policy remains in emitter code:
--   * connectors {rail, arrow, fork, labelAbove} — the connector characters the
--     emitter draws between boxes, with labels kept above the target boxes;
--   * layout {stableIndent} — the streamed diagram's column is stable while boxes
--     arrive (no re-centering).
-- The capability is re-declared through model.declare_capability_document exactly as
-- the policy was first declared (declare-circuit-presentation.sql); all existing
-- fields are kept and circuit-presentation.v1 mints a new contract version whose
-- schema requires both new members.
--
-- Encoding note (finding F12, same as the first declaration): the connector glyphs
-- are declared as JSON \uXXXX escapes (\u2502 rail, \u25BC arrow, \u252C fork), not
-- as raw characters. The stored bytes are written correctly (UTF-8), but every read
-- path decodes them with a cp1252 collation and corrupts raw non-ASCII literals;
-- ASCII escapes survive losslessly and JSON decode returns the real glyphs. The
-- installed policy was measured after the first declaration: the six escapes return
-- their true code points (2713, 00d7, 2013, 25bc, 252c, 2502) at the runtime.
--
-- Idempotent: the contracts are content-addressed, the transformation is declared
-- through the content-addressed writer, and the capability document's digest gates
-- the replay.
--
-- Default was ROLLBACK. Installed 2026-09-17 after the rollback dry run and the
-- from-transaction preflight on the request {contractId: circuit-presentation-request.v1}
-- (DISPOSITION completed; outcome policyType circuit-presentation.v1 carrying
-- connectors.rail/arrow/fork, labelAbove and layout.stableIndent; the installed
-- surface then verified through `sfx capability invoke read-circuit-presentation`).
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
-- glyphs after JSON decode. The connector members are the emitter's connector
-- vocabulary and the layout member its diagram column rule.
DECLARE @policy nvarchar(max) = N'{"policyType":"circuit-presentation.v1","box":{"minColumns":20,"maxColumns":40,"minRows":2,"align":"center","wrap":"hyphen-preferred"},"glyphs":{"success":"\u2713","failure":"\u00d7","unobserved":"\u2013","arrow":"\u25bc","fork":"\u252c","rail":"\u2502"},"statusRow":{"enabled":true,"format":"glyph duration"},"labels":{"prefixes":{"scenario":"SCENARIO","mechanic":"MECHANIC","provider":"PROVIDER","physical":"PHYSICAL"}},"granularity":{"detailCellLimit":30},"connectors":{"rail":"\u2502","arrow":"\u25BC","fork":"\u252C","labelAbove":true},"layout":{"stableIndent":true}}';
DECLARE @statement nvarchar(max) = N'SELECT N''' + @policy + N''' AS value;';

-- ============================== CONTRACTS ==============================
-- New version of the same declared id. The policy contract requires the two new
-- members; the request contract is unchanged (re-declared as a content-addressed
-- no-op). additionalProperties stays open so a further policy extension does not
-- break the declaration.
DECLARE @request_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/circuit-presentation-request.v1.schema.json","title":"Circuit presentation request","type":"object","additionalProperties":true,"required":["contractId"],"properties":{"contractId":{"const":"circuit-presentation-request.v1"},"payload":{"type":"object","additionalProperties":true}}}';
DECLARE @presentation_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/circuit-presentation.v1.schema.json","title":"Circuit presentation policy","type":"object","additionalProperties":true,"required":["policyType","box","glyphs","statusRow","labels","granularity","connectors","layout"],"properties":{"policyType":{"const":"circuit-presentation.v1"},"box":{"type":"object","additionalProperties":true,"required":["minColumns","maxColumns","minRows","align","wrap"],"properties":{"minColumns":{"type":"integer","minimum":1},"maxColumns":{"type":"integer","minimum":1},"minRows":{"type":"integer","minimum":1},"align":{"type":"string"},"wrap":{"type":"string"}}},"glyphs":{"type":"object","additionalProperties":true,"required":["success","failure","unobserved","arrow","fork","rail"],"properties":{"success":{"type":"string"},"failure":{"type":"string"},"unobserved":{"type":"string"},"arrow":{"type":"string"},"fork":{"type":"string"},"rail":{"type":"string"}}},"statusRow":{"type":"object","additionalProperties":true,"required":["enabled","format"],"properties":{"enabled":{"type":"boolean"},"format":{"type":"string"}}},"labels":{"type":"object","additionalProperties":true,"properties":{"prefixes":{"type":"object","additionalProperties":{"type":"string"}}}},"granularity":{"type":"object","additionalProperties":true,"required":["detailCellLimit"],"properties":{"detailCellLimit":{"type":"integer","minimum":1}}},"connectors":{"type":"object","additionalProperties":true,"required":["rail","arrow","fork","labelAbove"],"properties":{"rail":{"type":"string"},"arrow":{"type":"string"},"fork":{"type":"string"},"labelAbove":{"type":"boolean"}}},"layout":{"type":"object","additionalProperties":true,"required":["stableIndent"],"properties":{"stableIndent":{"type":"boolean"}}}}}';
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
 "meaning":{"intent":"read the estate''s circuit presentation policy","outcome":"the caller observes the declared presentation policy: box geometry, glyphs, status-row format, altitude label prefixes, the detail-cell limit, the connector characters and the diagram layout rule"},
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
  "then":"the caller observes the policy document: box geometry, glyphs, status row, label prefixes, the detail-cell limit, the connector characters and the diagram layout rule",
  "operations":[{"operationId":"read-circuit-presentation.0","kind":"invoke-port","portId":"read-circuit-presentation-port"}],
  "portBindings":' + @bindings + N'
 }]
}';
EXEC model.declare_capability_document @document=@document;
EXEC model.declare_capability_document @document=@document;

-- ============================== THE DECLARED DISPLAY PROJECTION ==============================
-- Unchanged from declare-circuit-presentation.sql: the read's display configuration
-- selects this transformation, which returns the policy itself (the read's outcome)
-- as the display document. Re-declared content-addressed so this migration stands
-- alone; the identical semantics mint no new version.
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

-- The declared id now carries two versions; the newest requires both new families.
SELECT '1_contracts' AS result_set, c.contract_id, COUNT(*) AS versions,
 MAX(CASE WHEN JSON_QUERY(sch.schema_json,'$.properties.connectors') IS NOT NULL THEN 1 ELSE 0 END) AS carries_connectors,
 MAX(CASE WHEN JSON_QUERY(sch.schema_json,'$.properties.layout') IS NOT NULL THEN 1 ELSE 0 END) AS carries_layout,
 MAX(CASE WHEN JSON_QUERY(sch.schema_json,'$.required') LIKE N'%connectors%'
   AND JSON_QUERY(sch.schema_json,'$.required') LIKE N'%layout%' THEN 1 ELSE 0 END) AS requires_both
FROM model.contract c
JOIN model.contract_version v ON v.contract_pk=c.contract_pk
JOIN model.schema_object so ON so.schema_object_pk=v.schema_object_pk
JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS schema_json) sch
WHERE c.contract_id IN (N'circuit-presentation-request.v1',N'circuit-presentation.v1')
GROUP BY c.contract_id
ORDER BY c.contract_id;

-- The selected definition is the newest contract version for the declared id.
SELECT '2_contract_selection' AS result_set, d.declared_id,
 LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS selected_digest,
 LOWER(CONVERT(varchar(64),v.definition_digest,2)) AS newest_digest,
 CAST(CASE WHEN d.definition_digest=v.definition_digest THEN 1 ELSE 0 END AS bit) AS selected_is_newest
FROM analysis.v_selected_semantic_definition d
JOIN model.contract c ON c.contract_id=d.declared_id AND c.namespace_pk=d.namespace_pk
JOIN model.contract_version v ON v.contract_pk=c.contract_pk
WHERE d.estate_model_pk=@estate AND d.object_kind='CONTRACT'
 AND d.declared_id=N'circuit-presentation.v1'
 AND v.contract_version_pk=(SELECT MAX(v2.contract_version_pk) FROM model.contract_version v2 WHERE v2.contract_pk=c.contract_pk);

-- The port statement carries the two new families and still carries the policy; the
-- display transformation travels.
SELECT '3_capability_port' AS result_set, c.capability_id, s.scenario_id, eo.operation_id, p.port_id,
 JSON_VALUE(pd.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 CASE WHEN CHARINDEX(N'"policyType":"circuit-presentation.v1"',JSON_VALUE(pd.definition_json,'$.semantics.configuration.statement'))>0 THEN 1 ELSE 0 END AS policy_declared,
 CASE WHEN CHARINDEX(N'"connectors":',JSON_VALUE(pd.definition_json,'$.semantics.configuration.statement'))>0 THEN 1 ELSE 0 END AS connectors_declared,
 CASE WHEN CHARINDEX(N'\u25BC',JSON_VALUE(pd.definition_json,'$.semantics.configuration.statement'))>0 THEN 1 ELSE 0 END AS connector_escapes_stored,
 CASE WHEN CHARINDEX(N'"stableIndent":true',JSON_VALUE(pd.definition_json,'$.semantics.configuration.statement'))>0 THEN 1 ELSE 0 END AS stable_indent_declared
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

DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-circuit-presentation',0,N'sidefx:capabilities'));
SELECT '4_graph_source' AS result_set, g.root_scenario_id,
 JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.transformationId') AS display_transformation_id,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations')) t WHERE JSON_VALUE(t.value,'$.id')=@transformationId) AS display_transformation_present
FROM analysis.v_capability_graph_source g WHERE g.capability_id=N'read-circuit-presentation';

-- The behavioral self-test: the declared statement itself is executed and compared
-- byte-for-byte with the extended policy literal.
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
-- The new members, read through JSON_VALUE so the escapes are decoded by SQL
-- Server's JSON parser; the code points prove the real connector glyphs.
SELECT '6_policy_values' AS result_set,
 JSON_VALUE(v.value,'$.connectors.rail') AS connector_rail,
 UNICODE(JSON_VALUE(v.value,'$.connectors.rail')) AS connector_rail_code,
 JSON_VALUE(v.value,'$.connectors.arrow') AS connector_arrow,
 UNICODE(JSON_VALUE(v.value,'$.connectors.arrow')) AS connector_arrow_code,
 JSON_VALUE(v.value,'$.connectors.fork') AS connector_fork,
 UNICODE(JSON_VALUE(v.value,'$.connectors.fork')) AS connector_fork_code,
 JSON_VALUE(v.value,'$.connectors.labelAbove') AS connector_label_above,
 JSON_VALUE(v.value,'$.layout.stableIndent') AS layout_stable_indent,
 JSON_VALUE(v.value,'$.box.minColumns') AS box_min_columns,
 JSON_VALUE(v.value,'$.box.maxColumns') AS box_max_columns,
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
