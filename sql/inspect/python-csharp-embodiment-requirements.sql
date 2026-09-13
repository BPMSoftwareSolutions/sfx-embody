-- Read the selected capability's actual invoked ports before claiming coverage.
-- Counts describe declared implementation links, not executable-body conformance.
DECLARE @capability_id nvarchar(400)=COALESCE(JSON_VALUE(@input,'$.capabilityId'),N'resolve-equity-market-price-evidence');
DECLARE @implementations TABLE (capability_id nvarchar(400),target_id nvarchar(400),provider_id nvarchar(400),implementation_ref nvarchar(1000));
INSERT @implementations
SELECT capability_id,target_id,provider_id,implementation_ref
FROM analysis.v_target_provider_implementation WHERE estate_model_pk=@estate_model_pk;
DECLARE @profiles TABLE (target_id nvarchar(400),provider_profile_id nvarchar(400));
INSERT @profiles
SELECT target_id,provider_profile_id FROM analysis.v_target_provider_profile
WHERE estate_model_pk=@estate_model_pk AND effect_classification='effect';
DECLARE @ports TABLE (scenario_id nvarchar(400),ordinal int,port_id nvarchar(400),platform_capability_id nvarchar(400));
INSERT @ports
SELECT s.scenario_id,op.ordinal,p.port_id,JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId')
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
JOIN model.capability_root_scenario root ON root.capability_version_pk=ec.capability_version_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk AND cs.scenario_pk=root.scenario_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_event e ON e.scenario_version_pk=cs.scenario_version_pk
JOIN model.execution_operation op ON op.execution_authority_version_pk=e.execution_authority_version_pk
JOIN model.operation_port_invocation invocation ON invocation.execution_operation_pk=op.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=invocation.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.semantic_object_definition_pk=pv.semantic_object_definition_pk
WHERE ec.estate_model_pk=@estate_model_pk AND c.capability_id=@capability_id;

SELECT @capability_id AS capability_id,ports.scenario_id,ports.ordinal,ports.port_id,ports.platform_capability_id,
       profiles.target_id,profiles.provider_profile_id,coverage.implementation_count,
       CASE coverage.implementation_count WHEN 0 THEN 'PROVIDER_IMPLEMENTATION_ABSENT'
            WHEN 1 THEN 'PROVIDER_BINDING_SELECTED' ELSE 'PROVIDER_IMPLEMENTATION_AMBIGUOUS' END AS disposition
FROM @ports ports CROSS JOIN @profiles profiles
CROSS APPLY (SELECT COUNT(DISTINCT i.provider_id) AS implementation_count FROM @implementations i
 WHERE i.capability_id=ports.platform_capability_id AND i.target_id=profiles.target_id) coverage
ORDER BY ports.ordinal,profiles.target_id;

SELECT DISTINCT ports.platform_capability_id,i.target_id,i.provider_id,i.implementation_ref
FROM @ports ports JOIN @implementations i ON i.capability_id=ports.platform_capability_id
ORDER BY ports.platform_capability_id,i.target_id,i.provider_id;

SELECT @capability_id AS capability_id,COUNT(*) AS declared_provider_slots
FROM model.provider_slot s JOIN model.blueprint_version v ON v.blueprint_version_pk=s.blueprint_version_pk
JOIN model.capability c ON c.capability_pk=v.capability_pk
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate_model_pk AND d.semantic_object_definition_pk=v.semantic_object_definition_pk
WHERE c.capability_id=@capability_id;
