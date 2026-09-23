-- extend-circuit-presentation-materials.sql
--
-- D3 / docs/observation-altitudes-implementation-plan-2026-09-23.md phases 2-3,
-- docs/observation-altitudes-review.md finding 1 and its fix: the declared
-- `circuit-presentation.v1` policy (the `read-circuit-presentation` declared
-- read) gains the material maps the platform has been guessing and the grain it
-- has been mirroring. This is the estate half only; the SDA and website halves
-- are other lanes.
--
-- New members (full policy literal re-declared through
-- model.declare_capability_document, exactly as extend-circuit-presentation-
-- connectors.sql re-declared it):
--   * materials.boundary    -- the scenario cell's three roles: input (its input
--                              port contract), event (its execution authorityId)
--                              and outcome (its outcome port contract), each
--                              mapped to a material token;
--   * materials.byAuthority  -- exact `execution.authorityId` -> token for every
--                              non-scenario authority in the current estate;
--   * materials.byEdgeKind   -- exact edge kind -> token;
--   * granularity.node       -- "operation" beside the retained detailCellLimit
--                              (the terminal renderer keeps reading the count).
-- No map falls back to another, and nothing is matched by substring or prefix:
-- an identity or kind not in the maps renders UNRESOLVED at the platform.
--
-- AuthorityId vocabulary (verified in the SDA compiler, SemanticExecutionGraph-
-- Compiler.cs): operation cells `operation:<platformCapabilityId>` (line 186),
-- provider cells `provider:<mechanicId>` (line 256), physical cells
-- `physical:<primitiveProfileId>` (line 257), expression cells
-- `mechanic:<op>.v1` (line 671), junctions
-- `junction:boolean-selection.v1` (line 760); the scenario cell's authorityId is
-- its event's execution authority (line 117) and is boundary material here.
-- Material tokens are the platform's existing vocabulary in sfx-platform
-- components/circuit/scl-theme.ts MATERIAL_STYLES keys.
--
-- Every key was enumerated from the current estate by read-only queries (each
-- transaction ending in ROLLBACK), never invented:
--   * operation: 32 invoke-port platform capability ids (1,305 bindings), 488
--     invoke-scenario operations and 3 project-state operations across the
--     current capability versions. The compiler's effect ports are the fixed set
--     {sda-external-credential-reference-binding-port.v1,
--      sda-governed-http-exchange-port.v1, sda-credential-vault-port.v1}; all
--     three are invoked, none declares configuration.primitiveProfileId, so the
--     physical authorities are the compiler's fallback
--     `physical:<platformCapabilityId>`. The credential binding and the governed
--     HTTP exchange therefore get DIFFERENT materials: provider-port vs provider
--     (trace README section 7: transformation -> execution step, credential
--     binding -> provider port, governed HTTP exchange -> provider port with a
--     bound provider and a physical effect; the exchange operation itself is the
--     provider effect, so it does not share the credential socket's token).
--   * provider/physical: the three effect ports above (provider cells and their
--     realized physical cells).
--   * mechanic: 31 distinct transformation operators (30 emitted ops plus
--     `identity`); the control op `if` compiles to
--     `junction:boolean-selection.v1` plus `mechanic:identity.v1` and never
--     carries a `mechanic:if.v1` cell.
--   * junction: `junction:boolean-selection.v1`.
--   * edge kinds: declared routing topologyKinds broadcast (2), failure (2),
--     join (2), selection (20); the compiler also emits sequence, return and
--     recurrence edges.
--
-- Declared gaps (deliberately unmapped: the platform renders UNRESOLVED, never a
-- guess):
--   * `mechanic:if.v1` -- not an emitted cell authority (see above);
--   * for-each body authorities and mechanic-registry event ports carrying
--     `invocation: effects` -- not declared in the current estate;
--   * edge kinds `cancellation` and `testimony` -- canonical engine vocabulary,
--     not declared in the current estate.
--
-- Encoding note (finding F12, as in the first declaration): the connector glyphs
-- stay JSON \uXXXX escapes; the read path decodes with a cp1252 collation, which
-- corrupts raw non-ASCII literals, while escapes survive losslessly.
--
-- Idempotent and content-addressed: the contracts, capability document, port and
-- display transformation are re-declared through the content-addressed writers;
-- a replay answers UNCHANGED and mints nothing.
--
-- Default was ROLLBACK; the install is the committed copy
-- sql/migrations/extend-circuit-presentation-materials.commit.sql.
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
-- The statement is declaration data: carried by the port binding, not by code.
-- It receives @input (circuit-presentation-request.v1) and returns one JSON
-- circuit-presentation.v1 value in the value column. The policy is authority, so
-- the statement is the policy literal. All existing members are kept byte for
-- byte; `granularity` gains `node` and `materials` is new. The three material
-- maps are exact-key: no fallback between them and nothing matched by substring
-- or prefix.
-- The opening literal is cast to nvarchar(max): a concatenation of non-max
-- literals caps at 4000 characters and would silently truncate this policy.
DECLARE @policy nvarchar(max)=
 CONVERT(nvarchar(max),N'{"policyType":"circuit-presentation.v1",')
+N'"box":{"minColumns":20,"maxColumns":40,"minRows":2,"align":"center","wrap":"hyphen-preferred"},'
+N'"glyphs":{"success":"\u2713","failure":"\u00d7","unobserved":"\u2013","arrow":"\u25bc","fork":"\u252c","rail":"\u2502"},'
+N'"statusRow":{"enabled":true,"format":"glyph duration"},'
+N'"labels":{"prefixes":{"scenario":"SCENARIO","mechanic":"MECHANIC","provider":"PROVIDER","physical":"PHYSICAL"}},'
+N'"granularity":{"detailCellLimit":30,"node":"operation"},'
+N'"connectors":{"rail":"\u2502","arrow":"\u25BC","fork":"\u252C","labelAbove":true},'
+N'"layout":{"stableIndent":true},'
+N'"materials":{'
-- The scenario boundary roles: Input (input port contract), Event (execution
-- authorityId), Outcome (outcome port contract). These are the only tokens the
-- scenario cell's three faces read.
+N'"boundary":{"input":"input","event":"event","outcome":"outcome"},'
-- The canonical non-scenario authorityId vocabulary of the current estate
-- (enumerated 2026-09-23; see the header for the queries and the gaps).
+N'"byAuthority":{'
+N'"operation:invoke-scenario":"event",'
+N'"operation:project-state":"event",'
+N'"operation:sda-authority-transformation-port.v1":"event",'
+N'"operation:sda-bounded-base64-byte-digest-port.v1":"event",'
+N'"operation:sda-canonical-capability-feature-resolution-port.v1":"event",'
+N'"operation:sda-credential-vault-port.v1":"provider-port",'
+N'"operation:sda-declarative-value-port.v1":"event",'
+N'"operation:sda-embodiment-plan-port.v1":"event",'
+N'"operation:sda-external-credential-reference-binding-port.v1":"provider-port",'
+N'"operation:sda-filesystem-artifact-store.v1":"event",'
+N'"operation:sda-generic-llm-connector-port.v1":"event",'
+N'"operation:sda-governed-disposable-root-lifecycle-port.v1":"event",'
+N'"operation:sda-governed-external-root-batch-materialization-port.v1":"event",'
+N'"operation:sda-governed-external-root-consumer-projection-port.v1":"event",'
+N'"operation:sda-governed-external-root-observation-port.v1":"event",'
+N'"operation:sda-governed-external-root-projected-application-execution-port.v1":"event",'
+N'"operation:sda-governed-file-system-shaping-port.v2":"event",'
+N'"operation:sda-governed-http-exchange-port.v1":"provider",'
+N'"operation:sda-governed-repository-observation-port.v1":"event",'
+N'"operation:sda-governed-serial-execution-port.v1":"event",'
+N'"operation:sda-governed-target-execution-observation-port.v1":"event",'
+N'"operation:sda-governed-tooling-binding-transaction-port.v1":"event",'
+N'"operation:sda-json-authority-ingestion-port.v1":"event",'
+N'"operation:sda-managed-language-module-invocation-port.v1":"event",'
+N'"operation:sda-node-consumer-runtime.v1":"event",'
+N'"operation:sda-projected-capability-invocation-port.v2":"event",'
+N'"operation:sda-proof-binding-evaluation-port.v1":"event",'
+N'"operation:sda-scenario-semantic-carrier-evaluation-port.v1":"event",'
+N'"operation:sda-scenario-semantic-carrier-extraction-port.v1":"event",'
+N'"operation:sda-scenario-semantic-carrier-validation-port.v1":"event",'
+N'"operation:sda-schema-contract-admission.v1":"event",'
+N'"operation:sda-semantic-execution-graph-compilation-port.v1":"event",'
+N'"operation:sda-semantic-execution-graph-execution-port.v1":"event",'
+N'"operation:sda-semantic-vector-index.v1":"event",'
+N'"provider:sda-credential-vault-port.v1":"provider-port",'
+N'"provider:sda-external-credential-reference-binding-port.v1":"provider-port",'
+N'"provider:sda-governed-http-exchange-port.v1":"provider-port",'
+N'"physical:sda-credential-vault-port.v1":"provider",'
+N'"physical:sda-external-credential-reference-binding-port.v1":"provider",'
+N'"physical:sda-governed-http-exchange-port.v1":"provider",'
+N'"mechanic:array.v1":"event",'
+N'"mechanic:base64-decode-utf8.v1":"event",'
+N'"mechanic:canonicalize.v1":"event",'
+N'"mechanic:directed-graph-closure.v1":"event",'
+N'"mechanic:equals.v1":"event",'
+N'"mechanic:every.v1":"event",'
+N'"mechanic:filter.v1":"event",'
+N'"mechanic:find.v1":"event",'
+N'"mechanic:flat-map.v1":"event",'
+N'"mechanic:format.v1":"event",'
+N'"mechanic:greater-than.v1":"event",'
+N'"mechanic:identity.v1":"event",'
+N'"mechanic:includes.v1":"event",'
+N'"mechanic:intersects.v1":"event",'
+N'"mechanic:join.v1":"event",'
+N'"mechanic:json-stringify.v1":"event",'
+N'"mechanic:length.v1":"event",'
+N'"mechanic:let.v1":"event",'
+N'"mechanic:literal.v1":"event",'
+N'"mechanic:lower-case.v1":"event",'
+N'"mechanic:map.v1":"event",'
+N'"mechanic:merge.v1":"event",'
+N'"mechanic:object.v1":"event",'
+N'"mechanic:object-values.v1":"event",'
+N'"mechanic:parse-json.v1":"event",'
+N'"mechanic:path.v1":"event",'
+N'"mechanic:sha256.v1":"event",'
+N'"mechanic:some.v1":"event",'
+N'"mechanic:trim.v1":"event",'
+N'"mechanic:try-parse-json.v1":"event",'
+N'"mechanic:unique.v1":"event",'
+N'"junction:boolean-selection.v1":"branch"'
+N'},'
-- The compiler's edge kind vocabulary as it is declared in the current estate:
-- declared topologyKinds plus the generated sequence/return/recurrence edges.
+N'"byEdgeKind":{"sequence":"event","selection":"branch","broadcast":"fan-out","join":"convergence","recurrence":"branch","return":"outcome","failure":"rejection"}'
+N'}}';
DECLARE @statement nvarchar(max) = N'SELECT N''' + @policy + N''' AS value;';

-- ============================== CONTRACTS ==============================
-- New version of the same declared id. The policy contract now also requires
-- `materials` (with boundary/byAuthority/byEdgeKind) and `granularity.node`; the
-- request contract is unchanged (re-declared as a content-addressed no-op).
-- additionalProperties stays open so a further policy extension does not break
-- the declaration.
DECLARE @request_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/circuit-presentation-request.v1.schema.json","title":"Circuit presentation request","type":"object","additionalProperties":true,"required":["contractId"],"properties":{"contractId":{"const":"circuit-presentation-request.v1"},"payload":{"type":"object","additionalProperties":true}}}';
DECLARE @presentation_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/circuit-presentation.v1.schema.json","title":"Circuit presentation policy","type":"object","additionalProperties":true,"required":["policyType","box","glyphs","statusRow","labels","granularity","connectors","layout","materials"],"properties":{"policyType":{"const":"circuit-presentation.v1"},"box":{"type":"object","additionalProperties":true,"required":["minColumns","maxColumns","minRows","align","wrap"],"properties":{"minColumns":{"type":"integer","minimum":1},"maxColumns":{"type":"integer","minimum":1},"minRows":{"type":"integer","minimum":1},"align":{"type":"string"},"wrap":{"type":"string"}}},"glyphs":{"type":"object","additionalProperties":true,"required":["success","failure","unobserved","arrow","fork","rail"],"properties":{"success":{"type":"string"},"failure":{"type":"string"},"unobserved":{"type":"string"},"arrow":{"type":"string"},"fork":{"type":"string"},"rail":{"type":"string"}}},"statusRow":{"type":"object","additionalProperties":true,"required":["enabled","format"],"properties":{"enabled":{"type":"boolean"},"format":{"type":"string"}}},"labels":{"type":"object","additionalProperties":true,"properties":{"prefixes":{"type":"object","additionalProperties":{"type":"string"}}}},"granularity":{"type":"object","additionalProperties":true,"required":["detailCellLimit","node"],"properties":{"detailCellLimit":{"type":"integer","minimum":1},"node":{"type":"string"}}},"connectors":{"type":"object","additionalProperties":true,"required":["rail","arrow","fork","labelAbove"],"properties":{"rail":{"type":"string"},"arrow":{"type":"string"},"fork":{"type":"string"},"labelAbove":{"type":"boolean"}}},"layout":{"type":"object","additionalProperties":true,"required":["stableIndent"],"properties":{"stableIndent":{"type":"boolean"}}},"materials":{"type":"object","additionalProperties":true,"required":["boundary","byAuthority","byEdgeKind"],"properties":{"boundary":{"type":"object","additionalProperties":{"type":"string"},"required":["input","event","outcome"]},"byAuthority":{"type":"object","additionalProperties":{"type":"string"}},"byEdgeKind":{"type":"object","additionalProperties":{"type":"string"}}}}}}';
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
 "meaning":{"intent":"read the estate''s circuit presentation policy","outcome":"the caller observes the declared presentation policy: box geometry, glyphs, status-row format, altitude label prefixes, the grain (detail-cell limit and node), the connector characters, the diagram layout rule and the material maps for the scenario boundary, the authorities and the edge kinds"},
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
  "then":"the caller observes the policy document: box geometry, glyphs, status row, label prefixes, the grain, the connector characters, the diagram layout rule and the boundary/byAuthority/byEdgeKind material maps",
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

-- The declared id now carries a third version; the newest requires both new
-- families and the node grain.
SELECT '1_contracts' AS result_set, c.contract_id, COUNT(*) AS versions,
 MAX(CASE WHEN JSON_QUERY(sch.schema_json,'$.properties.materials') IS NOT NULL THEN 1 ELSE 0 END) AS carries_materials,
 MAX(CASE WHEN JSON_QUERY(sch.schema_json,'$.required') LIKE N'%materials%' THEN 1 ELSE 0 END) AS requires_materials,
 MAX(CASE WHEN JSON_QUERY(sch.schema_json,'$.properties.granularity.properties.node') IS NOT NULL THEN 1 ELSE 0 END) AS carries_node,
 MAX(CASE WHEN JSON_QUERY(sch.schema_json,'$.properties.granularity.required') LIKE N'%node%' THEN 1 ELSE 0 END) AS requires_node
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

-- The port statement carries the new families and the node grain; the display
-- transformation travels. The statement is read decoded (OPENJSON WITH
-- nvarchar(max)), so the checks see the real policy, not its JSON escapes.
SELECT '3_capability_port' AS result_set, c.capability_id, s.scenario_id, eo.operation_id, p.port_id,
 JSON_VALUE(pd.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 CASE WHEN CHARINDEX(N'"policyType":"circuit-presentation.v1"',js.statement)>0 THEN 1 ELSE 0 END AS policy_declared,
 CASE WHEN CHARINDEX(N'"materials":',js.statement)>0 THEN 1 ELSE 0 END AS materials_declared,
 CASE WHEN CHARINDEX(N'"boundary":',js.statement)>0 THEN 1 ELSE 0 END AS boundary_declared,
 CASE WHEN CHARINDEX(N'"byAuthority":',js.statement)>0 THEN 1 ELSE 0 END AS byauthority_declared,
 CASE WHEN CHARINDEX(N'"byEdgeKind":',js.statement)>0 THEN 1 ELSE 0 END AS byedgekind_declared,
 CASE WHEN CHARINDEX(N'"node":"operation"',js.statement)>0 THEN 1 ELSE 0 END AS node_grain_declared
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
CROSS APPLY (SELECT s.statement FROM OPENJSON(pd.definition_json,'$.semantics.configuration')
 WITH (statement nvarchar(max) '$.statement') s) js
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
IF NOT EXISTS(SELECT 1 FROM @policy_table v WHERE v.value=@policy COLLATE Latin1_General_100_BIN2)
 THROW 51000,N'CIRCUIT_MATERIALS_POLICY_EXACT_FAILED',1;

-- The new members, read through JSON_VALUE so the escapes are decoded by SQL
-- Server's JSON parser. The credential binding and the HTTP exchange must get
-- different materials (implementation plan phase 2 acceptance).
SELECT '6_policy_values' AS result_set,
 JSON_VALUE(v.value,'$.materials.boundary.input') AS boundary_input,
 JSON_VALUE(v.value,'$.materials.boundary.event') AS boundary_event,
 JSON_VALUE(v.value,'$.materials.boundary.outcome') AS boundary_outcome,
 JSON_VALUE(v.value,'$.materials.byAuthority."operation:sda-external-credential-reference-binding-port.v1"') AS credential_binding_material,
 JSON_VALUE(v.value,'$.materials.byAuthority."operation:sda-governed-http-exchange-port.v1"') AS http_exchange_material,
 CASE WHEN JSON_VALUE(v.value,'$.materials.byAuthority."operation:sda-external-credential-reference-binding-port.v1"')
   <> JSON_VALUE(v.value,'$.materials.byAuthority."operation:sda-governed-http-exchange-port.v1"') THEN 1 ELSE 0 END AS credential_exchange_differ,
 JSON_VALUE(v.value,'$.materials.byAuthority."operation:sda-authority-transformation-port.v1"') AS transformation_material,
 JSON_VALUE(v.value,'$.materials.byAuthority."operation:invoke-scenario"') AS scenario_invocation_material,
 JSON_VALUE(v.value,'$.materials.byAuthority."operation:project-state"') AS project_state_material,
 JSON_VALUE(v.value,'$.materials.byAuthority."provider:sda-governed-http-exchange-port.v1"') AS exchange_provider_material,
 JSON_VALUE(v.value,'$.materials.byAuthority."physical:sda-governed-http-exchange-port.v1"') AS exchange_physical_material,
 JSON_VALUE(v.value,'$.materials.byAuthority."mechanic:literal.v1"') AS literal_material,
 JSON_VALUE(v.value,'$.materials.byAuthority."junction:boolean-selection.v1"') AS junction_material,
 JSON_VALUE(v.value,'$.materials.byEdgeKind.sequence') AS edge_sequence,
 JSON_VALUE(v.value,'$.materials.byEdgeKind.selection') AS edge_selection,
 JSON_VALUE(v.value,'$.materials.byEdgeKind.broadcast') AS edge_broadcast,
 JSON_VALUE(v.value,'$.materials.byEdgeKind.join') AS edge_join,
 JSON_VALUE(v.value,'$.materials.byEdgeKind.recurrence') AS edge_recurrence,
 JSON_VALUE(v.value,'$.materials.byEdgeKind.return') AS edge_return,
 JSON_VALUE(v.value,'$.materials.byEdgeKind.failure') AS edge_failure,
 JSON_VALUE(v.value,'$.granularity.node') AS granularity_node,
 JSON_VALUE(v.value,'$.granularity.detailCellLimit') AS detail_cell_limit
FROM @policy_table v;
IF (SELECT JSON_VALUE(v.value,'$.materials.byAuthority."operation:sda-external-credential-reference-binding-port.v1"')
      FROM @policy_table v)
 = (SELECT JSON_VALUE(v.value,'$.materials.byAuthority."operation:sda-governed-http-exchange-port.v1"')
      FROM @policy_table v)
 THROW 51000,N'CIRCUIT_MATERIALS_CREDENTIAL_EXCHANGE_NOT_DISTINCT',1;

-- The maps decode, with exactly the enumerated key counts: boundary 3,
-- byAuthority 72 (34 operation + 3 provider + 3 physical + 31 mechanic +
-- 1 junction), byEdgeKind 7.
SELECT '6b_map_counts' AS result_set,
 (SELECT COUNT(*) FROM @policy_table v CROSS APPLY OPENJSON(JSON_QUERY(v.value,'$.materials.boundary')) j) AS boundary_keys,
 (SELECT COUNT(*) FROM @policy_table v CROSS APPLY OPENJSON(JSON_QUERY(v.value,'$.materials.byAuthority')) j) AS byauthority_keys,
 (SELECT COUNT(*) FROM @policy_table v CROSS APPLY OPENJSON(JSON_QUERY(v.value,'$.materials.byEdgeKind')) j) AS byedgekind_keys;

-- Every token in every map is a key of the platform's material vocabulary
-- (sfx-platform components/circuit/scl-theme.ts MATERIAL_STYLES); a token
-- outside the vocabulary is a declaration error.
DECLARE @tokens TABLE(token nvarchar(40) PRIMARY KEY);
INSERT @tokens(token) VALUES
 (N'input'),(N'event'),(N'outcome'),(N'provider-port'),(N'provider'),(N'validation'),
 (N'evidence'),(N'human-approval'),(N'authority'),(N'branch'),(N'fan-out'),
 (N'convergence'),(N'decision'),(N'termination'),(N'rejection');
SELECT '6c_unknown_tokens' AS result_set, COUNT(*) AS unknown_tokens,
 ISNULL(STRING_AGG(CONVERT(nvarchar(max),m.token),N','),N'') AS token_list
FROM (
 SELECT j.value AS token FROM @policy_table v CROSS APPLY OPENJSON(JSON_QUERY(v.value,'$.materials.boundary')) j
 UNION ALL
 SELECT j.value FROM @policy_table v CROSS APPLY OPENJSON(JSON_QUERY(v.value,'$.materials.byAuthority')) j
 UNION ALL
 SELECT j.value FROM @policy_table v CROSS APPLY OPENJSON(JSON_QUERY(v.value,'$.materials.byEdgeKind')) j
) m LEFT JOIN @tokens t ON t.token=m.token
WHERE t.token IS NULL;
IF EXISTS(
 SELECT 1 FROM (
  SELECT j.value AS token FROM @policy_table v CROSS APPLY OPENJSON(JSON_QUERY(v.value,'$.materials.boundary')) j
  UNION ALL
  SELECT j.value FROM @policy_table v CROSS APPLY OPENJSON(JSON_QUERY(v.value,'$.materials.byAuthority')) j
  UNION ALL
  SELECT j.value FROM @policy_table v CROSS APPLY OPENJSON(JSON_QUERY(v.value,'$.materials.byEdgeKind')) j
 ) m LEFT JOIN @tokens t ON t.token=m.token WHERE t.token IS NULL)
 THROW 51000,N'CIRCUIT_MATERIALS_TOKEN_UNKNOWN',1;

-- Every byAuthority key uses a canonical authorityId prefix. The prefix test
-- here is a proof, not a mapping: the maps themselves are exact-key.
SELECT '6d_authority_prefixes' AS result_set,
 SUM(CASE WHEN j.[key] LIKE N'operation:%' THEN 1 ELSE 0 END) AS operation_keys,
 SUM(CASE WHEN j.[key] LIKE N'provider:%' THEN 1 ELSE 0 END) AS provider_keys,
 SUM(CASE WHEN j.[key] LIKE N'physical:%' THEN 1 ELSE 0 END) AS physical_keys,
 SUM(CASE WHEN j.[key] LIKE N'mechanic:%' THEN 1 ELSE 0 END) AS mechanic_keys,
 SUM(CASE WHEN j.[key] LIKE N'junction:%' THEN 1 ELSE 0 END) AS junction_keys,
 SUM(CASE WHEN j.[key] NOT LIKE N'operation:%' AND j.[key] NOT LIKE N'provider:%'
   AND j.[key] NOT LIKE N'physical:%' AND j.[key] NOT LIKE N'mechanic:%'
   AND j.[key] NOT LIKE N'junction:%' THEN 1 ELSE 0 END) AS noncanonical_keys
FROM @policy_table v CROSS APPLY OPENJSON(JSON_QUERY(v.value,'$.materials.byAuthority')) j;
IF EXISTS(
 SELECT 1 FROM @policy_table v CROSS APPLY OPENJSON(JSON_QUERY(v.value,'$.materials.byAuthority')) j
 WHERE j.[key] NOT LIKE N'operation:%' AND j.[key] NOT LIKE N'provider:%'
   AND j.[key] NOT LIKE N'physical:%' AND j.[key] NOT LIKE N'mechanic:%'
   AND j.[key] NOT LIKE N'junction:%')
 THROW 51000,N'CIRCUIT_MATERIALS_AUTHORITY_PREFIX_NONCANONICAL',1;

-- One current definition per declared id: the replay above minted no duplicate
-- capability document, port or transformation.
SELECT '7_current_definitions' AS result_set, d.namespace_id, d.object_kind, d.declared_id, COUNT(*) AS current_definitions
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate
 AND (d.namespace_id=N'sidefx:capability:read-circuit-presentation'
  OR (d.namespace_id=N'sidefx:capability-documents' AND d.declared_id=N'read-circuit-presentation'))
GROUP BY d.namespace_id,d.object_kind,d.declared_id
ORDER BY d.namespace_id,d.object_kind,d.declared_id;

ROLLBACK TRANSACTION;
