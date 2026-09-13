-- Read the selected profiles, native execution boundary and bound ports.
SELECT * FROM analysis.v_target_provider_profile
WHERE estate_model_pk=@estate_model_pk AND target_id=JSON_VALUE(@input,'$.target') ORDER BY effect_classification;

SELECT d.declared_id AS provider_id,JSON_QUERY(d.definition_json,'$.semantics.executionAuthority') AS execution_authority
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind='PROVIDER'
 AND JSON_VALUE(d.definition_json,'$.semantics.executionAuthority.target')=JSON_VALUE(@input,'$.target');

SELECT resolution.slot_id,resolution.disposition,p.port_id,i.provider_id,i.implementation_ref,
 'sha256:'+LOWER(CONVERT(varchar(64),i.definition_digest,2)) AS provider_definition_digest,JSON_VALUE(entry.value,'$.hostProvider') AS host_provider,
 JSON_VALUE(entry.value,'$.hostImplementationRef') AS host_implementation_ref,
 JSON_VALUE(entry.value,'$.hostImplementationDigest') AS host_implementation_digest,
 JSON_VALUE(entry.value,'$.hostProviderExport') AS host_provider_export
FROM analysis.v_provider_slot_resolution resolution
JOIN model.slot_port_requirement r ON r.provider_slot_pk=resolution.provider_slot_pk
JOIN model.port_version pv ON pv.port_version_pk=r.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN analysis.v_selected_semantic_definition pd ON pd.semantic_object_definition_pk=pv.semantic_object_definition_pk AND pd.estate_model_pk=@estate_model_pk
JOIN analysis.v_target_provider_implementation i ON i.provider_definition_pk=resolution.provider_definition_pk
 AND i.target_id=resolution.target_id AND i.estate_model_pk=@estate_model_pk
 AND i.capability_id=JSON_VALUE(pd.definition_json,'$.semantics.platformCapabilityId')
JOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=i.semantic_object_definition_pk AND d.estate_model_pk=@estate_model_pk
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.capabilities') entry
WHERE resolution.estate_model_pk=@estate_model_pk
 AND (resolution.capability_id=JSON_VALUE(@input,'$.capabilityId')
   OR resolution.capability_id IN (SELECT owning_capability_id
     FROM OPENJSON(@input,'$.closure.recordsets[0]')
       WITH (owning_capability_id nvarchar(400) '$.owning_capability_id')))
 AND resolution.target_id=JSON_VALUE(@input,'$.target')
 AND JSON_VALUE(entry.value,'$.projectionTarget')=resolution.target_id
 AND JSON_VALUE(entry.value,'$.capabilityId')=i.capability_id
ORDER BY resolution.slot_id;

SELECT m.mechanic_id,p.effect_classification,COALESCE(JSON_VALUE(d.definition_json,'$.semantics.executionAuthority.runtime.sourceDigest'),
 p.provider_module_root+'/'+p.provider_module) AS implementation_ref
FROM analysis.v_target_provider_profile p
JOIN model.provider_mechanic_implementation i ON i.provider_profile_version_pk=p.provider_profile_version_pk
JOIN model.mechanic_version mv ON mv.mechanic_version_pk=i.mechanic_version_pk
JOIN model.mechanic m ON m.mechanic_pk=mv.mechanic_pk
JOIN model.provider_definition pd ON pd.provider_definition_pk=i.provider_definition_pk
JOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=pd.semantic_object_definition_pk AND d.estate_model_pk=@estate_model_pk
WHERE p.estate_model_pk=@estate_model_pk AND p.target_id=JSON_VALUE(@input,'$.target')
ORDER BY m.mechanic_id;
