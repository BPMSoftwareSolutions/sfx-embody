-- Inspection: authoring-altitude-model-stubs
-- Lists the 11 declared STUB altitudes with their contracts, stub ports, transformations
-- and execution authorities, and proves the assembled graph source the kernel's
-- declared-read/compilation path serves includes all 11.
SET NOCOUNT ON;
DECLARE @capability_id nvarchar(400)=N'authoring-altitude-model-stubs';
DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @stubs TABLE (
 ordinal int NOT NULL PRIMARY KEY,
 altitude_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 port_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 transformation_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 authority_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT @stubs VALUES
 (1,N'altitude-1-feature-parse',N'authoring-altitude-model-stubs',N'authoring-altitude-model-stubs-port',N'authoring-altitude-model-stubs-transform.v1',N'authoring-altitude-model-stubs.v1'),
 (2,N'altitude-2-capability-meaning',N'altitude-2-capability-meaning',N'altitude-2-capability-meaning-stub-port',N'altitude-2-capability-meaning-stub-transform.v1',N'altitude-2-capability-meaning.v1'),
 (3,N'altitude-3-scenario-io',N'altitude-3-scenario-io',N'altitude-3-scenario-io-stub-port',N'altitude-3-scenario-io-stub-transform.v1',N'altitude-3-scenario-io.v1'),
 (4,N'altitude-4-contracts-schemas',N'altitude-4-contracts-schemas',N'altitude-4-contracts-schemas-stub-port',N'altitude-4-contracts-schemas-stub-transform.v1',N'altitude-4-contracts-schemas.v1'),
 (5,N'altitude-5-semantic-authority-envelope',N'altitude-5-semantic-authority-envelope',N'altitude-5-semantic-authority-envelope-stub-port',N'altitude-5-semantic-authority-envelope-stub-transform.v1',N'altitude-5-semantic-authority-envelope.v1'),
 (6,N'altitude-6-transformation-ast',N'altitude-6-transformation-ast',N'altitude-6-transformation-ast-stub-port',N'altitude-6-transformation-ast-stub-transform.v1',N'altitude-6-transformation-ast.v1'),
 (7,N'altitude-7-execution-authorities-ports',N'altitude-7-execution-authorities-ports',N'altitude-7-execution-authorities-ports-stub-port',N'altitude-7-execution-authorities-ports-stub-transform.v1',N'altitude-7-execution-authorities-ports.v1'),
 (8,N'altitude-8-providers-bindings-overlays',N'altitude-8-providers-bindings-overlays',N'altitude-8-providers-bindings-overlays-stub-port',N'altitude-8-providers-bindings-overlays-stub-transform.v1',N'altitude-8-providers-bindings-overlays.v1'),
 (9,N'altitude-9-interface-cli-display',N'altitude-9-interface-cli-display',N'altitude-9-interface-cli-display-stub-port',N'altitude-9-interface-cli-display-stub-transform.v1',N'altitude-9-interface-cli-display.v1'),
 (10,N'altitude-10-fixtures-proof',N'altitude-10-fixtures-proof',N'altitude-10-fixtures-proof-stub-port',N'altitude-10-fixtures-proof-stub-transform.v1',N'altitude-10-fixtures-proof.v1'),
 (11,N'altitude-11-alignment-evaluation',N'altitude-11-alignment-evaluation',N'altitude-11-alignment-evaluation-stub-port',N'altitude-11-alignment-evaluation-stub-transform.v1',N'altitude-11-alignment-evaluation.v1');

SELECT N'i1_stub_altitudes' AS result_set, a.ordinal, a.altitude_id,
 cti.contract_id AS input_contract, cto.contract_id AS outcome_contract,
 CONVERT(bit,so.terminal) AS terminal, a.port_id,
 JSON_VALUE(pd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
 a.transformation_id, a.authority_id, LOWER(CONVERT(varchar(64),pv.definition_digest,2)) AS port_definition_digest
FROM @stubs a
JOIN model.capability c ON c.capability_id=@capability_id
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=a.scenario_id
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
LEFT JOIN model.scenario_input si ON si.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.contract_version cvi ON cvi.contract_version_pk=si.input_contract_version_pk
LEFT JOIN model.contract cti ON cti.contract_pk=cvi.contract_pk
LEFT JOIN model.scenario_outcome so ON so.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.contract_version cvo ON cvo.contract_version_pk=soc.contract_version_pk
LEFT JOIN model.contract cto ON cto.contract_pk=cvo.contract_pk
JOIN model.port p ON p.port_id=a.port_id AND p.namespace_pk=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='PORT' AND namespace_id=@namespace)
JOIN model.port_version pv ON pv.port_pk=p.port_pk
JOIN analysis.v_selected_semantic_definition pd ON pd.semantic_object_definition_pk=pv.semantic_object_definition_pk AND pd.estate_model_pk=@estate
WHERE pv.port_version_pk=(SELECT MAX(pv2.port_version_pk) FROM model.port_version pv2 WHERE pv2.port_pk=p.port_pk)
ORDER BY a.ordinal;

SELECT N'i2_graph_source_counts' AS result_set,
 (SELECT COUNT(*) FROM OPENJSON(g.graph_source,'$.scenarios')) AS scenarios,
 (SELECT COUNT(*) FROM OPENJSON(g.graph_source,'$.executionAuthorities')) AS authorities,
 (SELECT COUNT(*) FROM OPENJSON(g.graph_source,'$.interfaceAuthority.portBindings')) AS port_bindings,
 (SELECT COUNT(*) FROM OPENJSON(g.graph_source,'$.semanticTransformations')) AS transformations,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(g.graph_source,'$.contractAuthorities.contracts'))) AS graph_contract_authorities,
 g.root_scenario_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)) AS graph_source_digest
FROM analysis.capability_graph_source(@capability_id,1,NULL) g;

SELECT N'i3_graph_scenario_resolution' AS result_set, JSON_VALUE(s.value,'$.scenarioId') AS scenario_id,
 JSON_VALUE(s.value,'$.input.contract.contractId') AS input_contract,
 JSON_VALUE(s.value,'$.outcome.contract.contractId') AS outcome_contract,
 JSON_VALUE(s.value,'$.event.executionAuthorityId') AS event_authority,
 CONVERT(bit,JSON_VALUE(s.value,'$.outcome.terminal')) AS terminal
FROM analysis.capability_graph_source(@capability_id,1,NULL) g
CROSS APPLY OPENJSON(g.graph_source,'$.scenarios') s
ORDER BY JSON_VALUE(s.value,'$.scenarioId');

SELECT N'i4_root_authority_operations' AS result_set, JSON_VALUE(au.value,'$.owningScenarioId') AS scenario_id,
 COUNT(*) AS operation_count,
 SUM(CASE WHEN JSON_VALUE(op.value,'$.kind')='invoke-scenario' THEN 1 ELSE 0 END) AS invoke_scenario_count
FROM analysis.capability_graph_source(@capability_id,1,NULL) g
CROSS APPLY OPENJSON(g.graph_source,'$.executionAuthorities') au
CROSS APPLY OPENJSON(au.value,'$.operations') op
WHERE JSON_VALUE(au.value,'$.owningScenarioId')=@capability_id
GROUP BY JSON_VALUE(au.value,'$.owningScenarioId');

SELECT N'i5_declared_read_documents' AS result_set, d.entry_id, DATALENGTH(d.document) AS document_bytes
FROM analysis.capability_execution_declaration(@capability_id, NULL, 1) d
ORDER BY d.entry_id;
