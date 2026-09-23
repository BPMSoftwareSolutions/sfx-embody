-- efficient-queries.sql
--
-- The estate's probing path: atomic, inline, index-bound reads for every
-- operation the runtime invocation resolution, provider add/update, authoring
-- capability operations and the two remaining fixes need. One new schema
-- `probe`; every object is an inline TVF (RETURNS TABLE AS RETURN SELECT ...),
-- parameterized and TOP/lateral-bounded. No table, cache or materialized
-- document is created: every row is derived from declarations the model already
-- owns (`docs/efficient-query-tooling-plan-2026-09-22.md`).
--
-- Bounded family inventory (17 atomic + 2 batch probes):
--   runtime:  current_model_pin, capability, root_scenario, invocation_closure,
--             authority_operations, port_definition, scenario_faces, reach_transformations
--   provider: provider_author, platform_capability, blueprint, route_state,
--             relink_probe, install_admission
--   authoring: candidate_receipts, tool_registry, accepted_gate, placement_state
--             (decision_receipt folded into accepted_gate), capability_manifest
--   batch:    read_authority_fingerprint, provider_blueprint_declaration
--
-- Mechanical gates (checked by sql/tools/verify-query-columns.mjs): every
-- (schema, table, column) exists in tables_columns.csv; no reference to the four
-- heavy objects (capability_graph_source, capability_execution_declaration,
-- v_capability_execution_declaration, v_capability_graph_source) or to
-- v_selected_semantic_definition; every function body is TOP-bounded; no
-- SELECT * and no LIKE-prefix scan on an identity column.
--
-- Default: ROLLBACK. To install, replace the final ROLLBACK with COMMIT and
-- re-run (the .commit.sql copy). Replay is idempotent: CREATE OR ALTER.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET LOCK_TIMEOUT 30000;
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name=N'probe') EXEC(N'CREATE SCHEMA probe');
BEGIN TRANSACTION;
GO
CREATE OR ALTER FUNCTION probe.current_model_pin()
RETURNS TABLE AS RETURN
SELECT TOP (1) cm.estate_model_pk, cm.singleton_id
FROM source.current_model cm
WHERE cm.singleton_id=1;
GO
CREATE OR ALTER FUNCTION probe.capability(@estate_model_pk bigint, @capability_id nvarchar(400))
RETURNS TABLE AS RETURN
SELECT TOP (1) c.capability_pk, c.capability_id, ec.capability_version_pk,
 ec.semantic_object_definition_pk AS capability_sod, cv.definition_digest AS capability_definition_digest,
 cv.name AS capability_name, ec.estate_model_pk
FROM model.identity_namespace n
JOIN model.capability c ON c.namespace_pk=n.namespace_pk AND c.capability_id=@capability_id
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate_model_pk
JOIN model.capability_version cv ON cv.capability_version_pk=ec.capability_version_pk
WHERE n.namespace_id=N'sidefx:capabilities' AND n.namespace_kind=N'CAPABILITY';
GO
CREATE OR ALTER FUNCTION probe.root_scenario(@capability_version_pk bigint)
RETURNS TABLE AS RETURN
SELECT TOP (1) rs.scenario_pk, s.scenario_id, cs.scenario_version_pk
FROM model.capability_root_scenario rs
JOIN model.scenario s ON s.scenario_pk=rs.scenario_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk=rs.capability_version_pk AND cs.scenario_pk=rs.scenario_pk
WHERE rs.capability_version_pk=@capability_version_pk;
GO
CREATE OR ALTER FUNCTION probe.invocation_closure(@capability_version_pk bigint, @selected_scenario_version_pk bigint)
RETURNS TABLE AS RETURN
SELECT TOP (50) cl.estate_model_pk, cl.capability_version_pk, cl.selected_scenario_version_pk,
 cl.downstream_scenario_version_pk, cl.minimum_depth, cl.cycle_detected
FROM analysis.v_scenario_invocation_closure cl
WHERE cl.capability_version_pk=@capability_version_pk
 AND cl.selected_scenario_version_pk=@selected_scenario_version_pk;
GO
CREATE OR ALTER FUNCTION probe.authority_operations(@capability_version_pk bigint)
RETURNS TABLE AS RETURN
SELECT TOP (100) eo.execution_operation_pk, eo.ordinal, eo.operation_id, eo.operation_kind,
 opi.port_version_pk, osi.target_scenario_version_pk, se.scenario_version_pk,
 eav.execution_authority_version_pk, eav.definition_digest AS authority_definition_digest
FROM model.capability_scenario cs
JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
LEFT JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
LEFT JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
WHERE cs.capability_version_pk=@capability_version_pk
ORDER BY se.scenario_version_pk, eo.ordinal;
GO
CREATE OR ALTER FUNCTION probe.port_definition(@semantic_object_pk bigint)
RETURNS TABLE AS RETURN
SELECT TOP (1) sod.semantic_object_definition_pk, sod.definition_digest, sod.canonical_content_pk,
 co.content_object_pk, co.byte_length, sod.object_kind
FROM model.semantic_object_definition sod
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
WHERE sod.semantic_object_pk=@semantic_object_pk
ORDER BY sod.semantic_object_definition_pk DESC;
GO
CREATE OR ALTER FUNCTION probe.scenario_faces(@capability_version_pk bigint)
RETURNS TABLE AS RETURN
SELECT TOP (50) cs.scenario_version_pk, s.scenario_id, i.input_id, i.input_contract_version_pk,
 o.outcome_id, o.terminal, o.terminal_disposition,
 soc.contract_version_pk, c.contract_id, so.schema_object_pk, so.content_object_pk, so.content_digest
FROM model.capability_scenario cs
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
LEFT JOIN model.scenario_input i ON i.scenario_version_pk=cs.scenario_version_pk
LEFT JOIN model.scenario_outcome o ON o.scenario_version_pk=cs.scenario_version_pk
LEFT JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk=cs.scenario_version_pk
LEFT JOIN model.contract_version cv ON cv.contract_version_pk=soc.contract_version_pk
LEFT JOIN model.contract c ON c.contract_pk=cv.contract_pk
LEFT JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
WHERE cs.capability_version_pk=@capability_version_pk
ORDER BY s.scenario_id, o.outcome_id;
GO
CREATE OR ALTER FUNCTION probe.reach_transformations(@estate_model_pk bigint, @capability_id nvarchar(400))
RETURNS TABLE AS RETURN
SELECT TOP (50) t.transformation_pk, t.transformation_id, sod.semantic_object_definition_pk,
 sod.definition_digest, co.content_object_pk, co.byte_length
FROM model.identity_namespace n
JOIN model.transformation t ON t.namespace_pk=n.namespace_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_pk=t.semantic_object_pk
JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=sod.semantic_object_definition_pk AND ed.estate_model_pk=@estate_model_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
WHERE n.namespace_id=N'sidefx:capability:'+@capability_id
 AND sod.semantic_object_definition_pk=(SELECT MAX(sod2.semantic_object_definition_pk)
  FROM model.semantic_object_definition sod2
  JOIN model.estate_definition ed2 ON ed2.semantic_object_definition_pk=sod2.semantic_object_definition_pk AND ed2.estate_model_pk=@estate_model_pk
  WHERE sod2.semantic_object_pk=t.semantic_object_pk)
ORDER BY t.transformation_id;
GO
CREATE OR ALTER FUNCTION probe.provider_author(@estate_model_pk bigint, @namespace_id nvarchar(400), @provider_id nvarchar(400))
RETURNS TABLE AS RETURN
SELECT TOP (1) p.provider_pk, p.provider_id, pd.provider_definition_pk, pd.definition_digest,
 pd.name AS provider_definition_name, co.content_object_pk, co.byte_length
FROM model.identity_namespace n
JOIN model.provider p ON p.namespace_pk=n.namespace_pk AND p.provider_id=@provider_id
JOIN model.provider_definition pd ON pd.provider_pk=p.provider_pk
JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=pd.semantic_object_definition_pk AND ed.estate_model_pk=@estate_model_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pd.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
WHERE n.namespace_id=@namespace_id AND n.namespace_kind=N'PROVIDER'
ORDER BY pd.provider_definition_pk DESC;
GO
CREATE OR ALTER FUNCTION probe.platform_capability(@estate_model_pk bigint, @capability_id nvarchar(400))
RETURNS TABLE AS RETURN
SELECT TOP (1) c.capability_pk, c.capability_id, ec.capability_version_pk, ec.semantic_object_definition_pk AS capability_sod,
 cv.definition_digest AS capability_definition_digest
FROM model.identity_namespace n
JOIN model.capability c ON c.namespace_pk=n.namespace_pk AND c.capability_id=@capability_id
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate_model_pk
JOIN model.capability_version cv ON cv.capability_version_pk=ec.capability_version_pk
WHERE n.namespace_id=N'sidefx:platform-capabilities';
GO
CREATE OR ALTER FUNCTION probe.blueprint(@estate_model_pk bigint, @namespace_id nvarchar(400), @blueprint_id nvarchar(400))
RETURNS TABLE AS RETURN
SELECT TOP (50) b.blueprint_pk, b.blueprint_id, bv.blueprint_version_pk, bv.definition_digest AS blueprint_definition_digest,
 bv.capability_pk, bv.capability_version_pk, bv.carrier_profile, bv.source_disposition,
 bn.blueprint_node_pk, bn.node_id, bn.node_kind, bn.altitude, bn.projection_ordinal,
 bn.semantic_object_definition_pk AS node_port_definition_pk, bn.expected_semantic_kind,
 ps.provider_slot_pk, ps.slot_id, spr.slot_port_requirement_pk, spr.port_version_pk,
 spr.ordinal AS requirement_ordinal, spr.role
FROM model.identity_namespace n
JOIN model.blueprint b ON b.namespace_pk=n.namespace_pk AND b.blueprint_id=@blueprint_id
JOIN model.blueprint_version bv ON bv.blueprint_pk=b.blueprint_pk
JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=bv.semantic_object_definition_pk AND ed.estate_model_pk=@estate_model_pk
LEFT JOIN model.blueprint_node bn ON bn.blueprint_version_pk=bv.blueprint_version_pk
LEFT JOIN model.provider_slot ps ON ps.owner_node_pk=bn.blueprint_node_pk
LEFT JOIN model.slot_port_requirement spr ON spr.provider_slot_pk=ps.provider_slot_pk
WHERE n.namespace_id=@namespace_id AND n.namespace_kind=N'BLUEPRINT'
 AND bv.blueprint_version_pk=(SELECT MAX(bv2.blueprint_version_pk)
  FROM model.blueprint_version bv2
  JOIN model.estate_definition ed2 ON ed2.semantic_object_definition_pk=bv2.semantic_object_definition_pk AND ed2.estate_model_pk=@estate_model_pk
  WHERE bv2.blueprint_pk=b.blueprint_pk)
ORDER BY bn.projection_ordinal;
GO
CREATE OR ALTER FUNCTION probe.route_state(@blueprint_version_pk bigint)
RETURNS TABLE AS RETURN
SELECT TOP (30) ps.provider_slot_pk, ps.slot_id, sc.provider_binding_scope_pk, sc.binding_context_pk,
 sc.binding_role, sc.selection_policy AS scope_selection_policy,
 b.provider_binding_pk, b.provider_definition_pk, b.ordinal AS binding_ordinal, b.selection_policy AS binding_selection_policy
FROM model.provider_slot ps
JOIN model.provider_binding_scope sc ON sc.provider_slot_pk=ps.provider_slot_pk
LEFT JOIN model.provider_binding b ON b.provider_binding_scope_pk=sc.provider_binding_scope_pk
WHERE ps.blueprint_version_pk=@blueprint_version_pk
ORDER BY ps.slot_id, b.ordinal;
GO
CREATE OR ALTER FUNCTION probe.relink_probe(@port_pk bigint)
RETURNS TABLE AS RETURN
SELECT TOP (10) pv.port_version_pk, pv.definition_digest AS port_definition_digest,
 opi.execution_operation_pk, eo.ordinal, eo.operation_kind, eav.execution_authority_version_pk
FROM model.port_version pv
LEFT JOIN model.operation_port_invocation opi ON opi.port_version_pk=pv.port_version_pk
LEFT JOIN model.execution_operation eo ON eo.execution_operation_pk=opi.execution_operation_pk
LEFT JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
WHERE pv.port_pk=@port_pk
ORDER BY pv.port_version_pk DESC;
GO
CREATE OR ALTER FUNCTION probe.install_admission(@estate_model_pk bigint, @port_version_pk bigint)
RETURNS TABLE AS RETURN
SELECT TOP (50) pv.port_version_pk, pv.definition_digest AS port_definition_digest, p.port_pk, p.port_id,
 JSON_VALUE(dt.document_text,'$.semantics.platformCapabilityId') AS platform_capability_id,
 sod.semantic_object_definition_pk, sod.canonical_content_pk, co.content_digest, co.byte_length
FROM model.port_version pv
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document_text) dt
WHERE pv.port_version_pk=@port_version_pk;
GO
CREATE OR ALTER FUNCTION probe.candidate_receipts(@estate_model_pk bigint, @namespace_id nvarchar(400))
RETURNS TABLE AS RETURN
SELECT TOP (20) s.declared_id AS receipt_id, sod.semantic_object_definition_pk,
 dt.document_text,
 JSON_VALUE(dt.document_text,'$.semantics.document.candidateId') AS candidate_id,
 JSON_VALUE(dt.document_text,'$.semantics.document.bundleDigest') AS bundle_digest,
 JSON_VALUE(dt.document_text,'$.semantics.document.review.decision') AS review_decision,
 JSON_VALUE(dt.document_text,'$.semantics.document.decision') AS decision,
 'sha256:'+LOWER(CONVERT(varchar(64),sod.definition_digest,2)) AS receipt_digest
FROM model.identity_namespace n
JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk AND s.object_kind='AUTHORITY'
JOIN model.semantic_object_definition sod ON sod.semantic_object_pk=s.semantic_object_pk
JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=sod.semantic_object_definition_pk AND ed.estate_model_pk=@estate_model_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document_text) dt
WHERE n.namespace_id=@namespace_id
 AND sod.semantic_object_definition_pk=(SELECT MAX(sod2.semantic_object_definition_pk)
  FROM model.semantic_object_definition sod2
  JOIN model.estate_definition ed2 ON ed2.semantic_object_definition_pk=sod2.semantic_object_definition_pk AND ed2.estate_model_pk=@estate_model_pk
  WHERE sod2.semantic_object_pk=s.semantic_object_pk)
ORDER BY sod.semantic_object_definition_pk DESC;
GO
CREATE OR ALTER FUNCTION probe.tool_registry(@estate_model_pk bigint, @namespace_id nvarchar(400))
RETURNS TABLE AS RETURN
SELECT TOP (40) s.declared_id AS tool_id, sod.semantic_object_definition_pk,
 dt.document_text,
 JSON_VALUE(dt.document_text,'$.semantics.toolId') AS document_tool_id,
 JSON_VALUE(dt.document_text,'$.semantics.capabilityId') AS capability_id,
 JSON_VALUE(dt.document_text,'$.semantics.targetScenarioId') AS target_scenario_id,
 JSON_VALUE(dt.document_text,'$.semantics.effectClassification') AS effect_classification,
 'sha256:'+LOWER(CONVERT(varchar(64),sod.definition_digest,2)) AS tool_digest
FROM model.identity_namespace n
JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk AND s.object_kind='TOOL'
JOIN model.semantic_object_definition sod ON sod.semantic_object_pk=s.semantic_object_pk
JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=sod.semantic_object_definition_pk AND ed.estate_model_pk=@estate_model_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document_text) dt
WHERE n.namespace_id=@namespace_id
 AND sod.semantic_object_definition_pk=(SELECT MAX(sod2.semantic_object_definition_pk)
  FROM model.semantic_object_definition sod2
  JOIN model.estate_definition ed2 ON ed2.semantic_object_definition_pk=sod2.semantic_object_definition_pk AND ed2.estate_model_pk=@estate_model_pk
  WHERE sod2.semantic_object_pk=s.semantic_object_pk)
ORDER BY s.declared_id;
GO
CREATE OR ALTER FUNCTION probe.accepted_gate(@estate_model_pk bigint, @namespace_id nvarchar(400), @candidate_id nvarchar(400), @bundle_digest nvarchar(200))
RETURNS TABLE AS RETURN
SELECT TOP (5) s.declared_id AS receipt_id, sod.semantic_object_definition_pk,
 CASE WHEN JSON_VALUE(dt.document_text,'$.semantics.document.decision')=N'ACCEPTED'
   OR JSON_VALUE(dt.document_text,'$.semantics.document.review.decision')=N'ACCEPTED' THEN N'ADMITTED' ELSE N'HELD' END AS disposition,
 JSON_VALUE(dt.document_text,'$.semantics.document.candidateId') AS candidate_id,
 JSON_VALUE(dt.document_text,'$.semantics.document.bundleDigest') AS bundle_digest,
 JSON_VALUE(dt.document_text,'$.semantics.document.decision') AS decision,
 JSON_VALUE(dt.document_text,'$.semantics.document.review.decision') AS review_decision,
 'sha256:'+LOWER(CONVERT(varchar(64),sod.definition_digest,2)) AS receipt_digest
FROM model.identity_namespace n
JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk AND s.object_kind='AUTHORITY'
JOIN model.semantic_object_definition sod ON sod.semantic_object_pk=s.semantic_object_pk
JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=sod.semantic_object_definition_pk AND ed.estate_model_pk=@estate_model_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document_text) dt
WHERE n.namespace_id=@namespace_id
 AND s.declared_id IN (@candidate_id+N'.decision.v1', @candidate_id+N'.receipt.v1')
 AND JSON_VALUE(dt.document_text,'$.semantics.document.bundleDigest')=@bundle_digest
ORDER BY sod.semantic_object_definition_pk DESC;
GO
CREATE OR ALTER FUNCTION probe.placement_state(@estate_model_pk bigint, @namespace_id nvarchar(400), @port_id nvarchar(400))
RETURNS TABLE AS RETURN
SELECT TOP (10) p.port_pk, p.port_id, pv.port_version_pk, pv.definition_digest AS port_definition_digest,
 JSON_VALUE(dt.document_text,'$.semantics.platformCapabilityId') AS platform_capability_id,
 opi.execution_operation_pk, eo.ordinal, eo.operation_kind, eav.execution_authority_version_pk
FROM model.identity_namespace n
JOIN model.port p ON p.namespace_pk=n.namespace_pk AND p.port_id=@port_id
JOIN model.port_version pv ON pv.port_pk=p.port_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document_text) dt
LEFT JOIN model.operation_port_invocation opi ON opi.port_version_pk=pv.port_version_pk
LEFT JOIN model.execution_operation eo ON eo.execution_operation_pk=opi.execution_operation_pk
LEFT JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
WHERE n.namespace_id=@namespace_id
 AND pv.port_version_pk=(SELECT MAX(pv2.port_version_pk) FROM model.port_version pv2 WHERE pv2.port_pk=p.port_pk)
ORDER BY pv.port_version_pk DESC, eo.ordinal;
GO
CREATE OR ALTER FUNCTION probe.capability_manifest(@estate_model_pk bigint, @capability_id nvarchar(400))
RETURNS TABLE AS RETURN
SELECT TOP (80) m.entry_kind, m.entry_id, m.entry_ordinal, m.definition_digest, m.port_id,
 m.port_version_pk, m.target_scenario_version_pk, m.platform_capability_id
FROM (
 SELECT N'authority-operation' AS entry_kind, eo.operation_id AS entry_id, eo.ordinal AS entry_ordinal,
  eav.definition_digest AS definition_digest, p.port_id, opi.port_version_pk, osi.target_scenario_version_pk,
  JSON_VALUE(dt.document_text,'$.semantics.platformCapabilityId') AS platform_capability_id
 FROM model.capability c
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate_model_pk
 JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
 JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
 JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
 JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
 LEFT JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
 LEFT JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
 LEFT JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
 LEFT JOIN model.port p ON p.port_pk=pv.port_pk
 LEFT JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
 LEFT JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
 CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document_text) dt
 WHERE n.namespace_id=N'sidefx:capabilities' AND n.namespace_kind=N'CAPABILITY' AND c.capability_id=@capability_id
) m
ORDER BY m.entry_kind, m.entry_ordinal;
GO
CREATE OR ALTER FUNCTION probe.read_authority_fingerprint(@estate_model_pk bigint, @capability_id nvarchar(400))
RETURNS TABLE AS RETURN
WITH cap AS (
 SELECT TOP (1) c.capability_pk, c.capability_id, ec.capability_version_pk, ec.semantic_object_definition_pk AS capability_sod,
  cv.definition_digest AS capability_definition_digest
 FROM model.identity_namespace n
 JOIN model.capability c ON c.namespace_pk=n.namespace_pk AND c.capability_id=@capability_id
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate_model_pk
 JOIN model.capability_version cv ON cv.capability_version_pk=ec.capability_version_pk
 WHERE n.namespace_id=N'sidefx:capabilities' AND n.namespace_kind=N'CAPABILITY'
), root AS (
 SELECT TOP (1) rs.scenario_pk, s.scenario_id, cs.scenario_version_pk
 FROM cap
 JOIN model.capability_root_scenario rs ON rs.capability_version_pk=cap.capability_version_pk
 JOIN model.scenario s ON s.scenario_pk=rs.scenario_pk
 JOIN model.capability_scenario cs ON cs.capability_version_pk=rs.capability_version_pk AND cs.scenario_pk=rs.scenario_pk
), closure AS (
 SELECT TOP (50) cl.downstream_scenario_version_pk, cl.minimum_depth, cl.cycle_detected
 FROM cap
 JOIN analysis.v_scenario_invocation_closure cl ON cl.capability_version_pk=cap.capability_version_pk
  AND cl.selected_scenario_version_pk=(SELECT TOP (1) scenario_version_pk FROM root)
), ops AS (
 SELECT TOP (100) eo.execution_operation_pk, eo.ordinal, eo.operation_id, eo.operation_kind,
  eav.execution_authority_version_pk, eav.definition_digest AS authority_definition_digest,
  opi.port_version_pk, osi.target_scenario_version_pk
 FROM cap
 JOIN model.capability_scenario cs ON cs.capability_version_pk=cap.capability_version_pk
 JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
 JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
 JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
 LEFT JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
 LEFT JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
)
SELECT N'capability' AS probe_set, 1 AS ordinal, cap.capability_id, cap.capability_pk, cap.capability_version_pk,
 cap.capability_sod, cap.capability_definition_digest, NULL AS scenario_pk, NULL AS scenario_id, NULL AS scenario_version_pk,
 NULL AS downstream_scenario_version_pk, NULL AS minimum_depth, NULL AS cycle_detected,
 NULL AS execution_authority_version_pk, NULL AS execution_operation_pk, NULL AS operation_ordinal, NULL AS operation_id,
 NULL AS operation_kind, NULL AS port_version_pk, NULL AS target_scenario_version_pk
FROM cap
UNION ALL
SELECT N'root-scenario', 2, cap.capability_id, cap.capability_pk, cap.capability_version_pk,
 cap.capability_sod, cap.capability_definition_digest, root.scenario_pk, root.scenario_id, root.scenario_version_pk,
 NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM cap CROSS JOIN root
UNION ALL
SELECT N'closure', 3, cap.capability_id, cap.capability_pk, cap.capability_version_pk,
 cap.capability_sod, cap.capability_definition_digest, root.scenario_pk, root.scenario_id, root.scenario_version_pk,
 closure.downstream_scenario_version_pk, closure.minimum_depth, closure.cycle_detected,
 NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM cap CROSS JOIN root CROSS JOIN closure
UNION ALL
SELECT N'operation', 4, cap.capability_id, cap.capability_pk, cap.capability_version_pk,
 cap.capability_sod, cap.capability_definition_digest, root.scenario_pk, root.scenario_id, root.scenario_version_pk,
 NULL, NULL, NULL, ops.execution_authority_version_pk, ops.execution_operation_pk, ops.ordinal, ops.operation_id,
 ops.operation_kind, ops.port_version_pk, ops.target_scenario_version_pk
FROM cap CROSS JOIN root CROSS JOIN ops;
GO
CREATE OR ALTER FUNCTION probe.provider_blueprint_declaration(@estate_model_pk bigint, @capability_id nvarchar(400), @namespace_id nvarchar(400))
RETURNS TABLE AS RETURN
WITH cap AS (
 SELECT TOP (1) c.capability_pk, c.capability_id, ec.capability_version_pk, ec.semantic_object_definition_pk AS capability_sod,
  cv.definition_digest AS capability_definition_digest
 FROM model.identity_namespace n
 JOIN model.capability c ON c.namespace_pk=n.namespace_pk AND c.capability_id=@capability_id
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate_model_pk
 JOIN model.capability_version cv ON cv.capability_version_pk=ec.capability_version_pk
 WHERE n.namespace_id=N'sidefx:capabilities' AND n.namespace_kind=N'CAPABILITY'
), bp AS (
 SELECT TOP (1) b.blueprint_pk, b.blueprint_id, bv.blueprint_version_pk, bv.definition_digest AS blueprint_definition_digest,
  bv.capability_pk, bv.capability_version_pk
 FROM model.identity_namespace n
 JOIN model.blueprint b ON b.namespace_pk=n.namespace_pk AND b.blueprint_id=@capability_id+N'-blueprint.v1'
 JOIN model.blueprint_version bv ON bv.blueprint_pk=b.blueprint_pk
 JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=bv.semantic_object_definition_pk AND ed.estate_model_pk=@estate_model_pk
 WHERE n.namespace_id=@namespace_id AND n.namespace_kind=N'BLUEPRINT'
 ORDER BY bv.blueprint_version_pk DESC
), ops AS (
 SELECT TOP (100) eo.execution_operation_pk, eo.ordinal, eo.operation_id, eo.operation_kind,
  opi.port_version_pk, p.port_pk, p.port_id, pv.semantic_object_definition_pk AS port_definition_pk,
  pv.definition_digest AS port_definition_digest,
  JSON_VALUE(dt.document_text,'$.semantics.platformCapabilityId') AS platform_capability_id
 FROM model.capability_scenario cs
 JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
 JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
 JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
 LEFT JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
 LEFT JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
 LEFT JOIN model.port p ON p.port_pk=pv.port_pk
 LEFT JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
 LEFT JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
 CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document_text) dt
 WHERE cs.capability_version_pk=(SELECT TOP (1) capability_version_pk FROM cap)
), nodes AS (
 SELECT TOP (50) bn.blueprint_node_pk, bn.node_id, bn.node_kind, bn.altitude, bn.projection_ordinal,
  ps.provider_slot_pk, ps.slot_id, spr.slot_port_requirement_pk, spr.port_version_pk,
  spr.ordinal AS requirement_ordinal, spr.role
 FROM bp
 LEFT JOIN model.blueprint_node bn ON bn.blueprint_version_pk=bp.blueprint_version_pk
 LEFT JOIN model.provider_slot ps ON ps.owner_node_pk=bn.blueprint_node_pk
 LEFT JOIN model.slot_port_requirement spr ON spr.provider_slot_pk=ps.provider_slot_pk
)
SELECT N'blueprint' AS probe_set, 1 AS ordinal, bp.blueprint_pk, bp.blueprint_id, bp.blueprint_version_pk,
 bp.blueprint_definition_digest, cap.capability_id, cap.capability_version_pk, cap.capability_definition_digest,
 NULL AS execution_operation_pk, NULL AS operation_ordinal, NULL AS operation_id, NULL AS operation_kind,
 NULL AS port_pk, NULL AS port_id, NULL AS port_version_pk, NULL AS port_definition_digest, NULL AS platform_capability_id,
 NULL AS blueprint_node_pk, NULL AS node_id, NULL AS node_kind, NULL AS altitude, NULL AS projection_ordinal,
 NULL AS provider_slot_pk, NULL AS slot_id, NULL AS slot_port_requirement_pk, NULL AS requirement_ordinal, NULL AS requirement_role
FROM bp CROSS JOIN cap
UNION ALL
SELECT N'capability-version', 2, NULL, NULL, NULL, NULL, cap.capability_id, cap.capability_version_pk, cap.capability_definition_digest,
 NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM cap
UNION ALL
-- The operation rows are the declaration inputs: they resolve even while the
-- blueprint is absent (the state the fixture declaration starts from).
SELECT N'operation', 3, NULL, NULL, NULL, NULL,
 cap.capability_id, cap.capability_version_pk, cap.capability_definition_digest,
 ops.execution_operation_pk, ops.ordinal, ops.operation_id, ops.operation_kind,
 ops.port_pk, ops.port_id, ops.port_version_pk, ops.port_definition_digest, ops.platform_capability_id,
 NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM cap CROSS JOIN ops
UNION ALL
SELECT N'node', 4, bp.blueprint_pk, bp.blueprint_id, bp.blueprint_version_pk, bp.blueprint_definition_digest,
 cap.capability_id, cap.capability_version_pk, cap.capability_definition_digest,
 NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
 nodes.blueprint_node_pk, nodes.node_id, nodes.node_kind, nodes.altitude, nodes.projection_ordinal,
 nodes.provider_slot_pk, nodes.slot_id, nodes.slot_port_requirement_pk, nodes.requirement_ordinal, nodes.role
FROM bp CROSS JOIN cap CROSS JOIN nodes;
GO
-- ============================== SELF-TEST AND ACCEPTANCE TIMINGS ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @t datetime2, @ms int;
DECLARE @pin_estate bigint, @cap_version bigint, @cap_digest binary(32), @step_ms int;
SET @t=SYSDATETIME();
SELECT TOP (1) @pin_estate=estate_model_pk FROM probe.current_model_pin();
SET @ms=DATEDIFF(ms,@t,SYSDATETIME());
SELECT N'1_probe_inventory' AS result_set, COUNT(*) AS probe_functions
FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id
WHERE s.name=N'probe' AND o.type IN (N'IF',N'TF');
SET @t=SYSDATETIME();
SELECT TOP (1) @cap_version=capability_version_pk, @cap_digest=capability_definition_digest
FROM probe.capability(@pin_estate, N'say-hello-world');
SET @step_ms=DATEDIFF(ms,@t,SYSDATETIME());
SELECT N'2_capability' AS result_set, N'say-hello-world' AS subject, @cap_version AS capability_version_pk,
 'sha256:'+LOWER(CONVERT(varchar(64),@cap_digest,2)) AS capability_definition_digest, @step_ms AS ms;
SET @t=SYSDATETIME();
SELECT TOP (1) @cap_version=pn.capability_version_pk
FROM probe.provider_blueprint_declaration(@pin_estate, N'resolve-equity-market-price-evidence', N'sidefx:blueprints') pn
WHERE pn.probe_set=N'capability-version';
SET @step_ms=DATEDIFF(ms,@t,SYSDATETIME());
SELECT N'3_blueprint_declaration' AS result_set, N'resolve-equity-market-price-evidence' AS subject, @step_ms AS ms;
SET @t=SYSDATETIME();
SELECT TOP (1) @cap_version=capability_version_pk, @cap_digest=capability_definition_digest
FROM probe.read_authority_fingerprint(@pin_estate, N'authoring-altitude-model-stubs')
WHERE probe_set=N'capability';
SET @step_ms=DATEDIFF(ms,@t,SYSDATETIME());
SELECT N'4_read_authority_fingerprint' AS result_set, N'authoring-altitude-model-stubs' AS subject, @step_ms AS ms,
 'sha256:'+LOWER(CONVERT(varchar(64),@cap_digest,2)) AS capability_definition_digest;
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
