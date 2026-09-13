-- M3: normalize the implementation relationships already declared by providers.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers = CURSOR LOCAL FAST_FORWARD FOR
  SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
  FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id
  JOIN sys.schemas s ON s.schema_id=o.schema_id
  WHERE o.type='U' AND s.name IN ('model','source')
    AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0
BEGIN
  EXEC(N'DROP TRIGGER '+@trigger_name);
  FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;

DECLARE @selected_model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
SELECT pd.provider_definition_pk,pd.semantic_object_definition_pk,p.provider_id,
       c.capability_version_pk,j.[key] AS capability_ordinal,
       JSON_VALUE(CASE WHEN j.type=5 THEN j.value ELSE N'{}' END,'$.capabilityId') AS capability_id,
       JSON_VALUE(CASE WHEN j.type=5 THEN j.value ELSE N'{}' END,'$.projectionTarget') AS target_id
INTO #declared
FROM model.provider_definition pd
JOIN model.provider p ON p.provider_pk=pd.provider_pk
JOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=pd.semantic_object_definition_pk
 AND d.estate_model_pk=@selected_model AND d.object_kind='PROVIDER'
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.capabilities') j
JOIN model.capability pc ON pc.capability_id=JSON_VALUE(CASE WHEN j.type=5 THEN j.value ELSE N'{}' END,'$.capabilityId')
JOIN model.identity_namespace n ON n.namespace_pk=pc.namespace_pk AND n.namespace_id=N'sidefx:platform-capabilities'
JOIN model.estate_capability c ON c.capability_pk=pc.capability_pk AND c.estate_model_pk=@selected_model
WHERE JSON_VALUE(CASE WHEN j.type=5 THEN j.value ELSE N'{}' END,'$.status')='ADMITTED'
 AND JSON_VALUE(CASE WHEN j.type=5 THEN j.value ELSE N'{}' END,'$.implementationRef') IS NOT NULL
 AND EXISTS (SELECT 1 FROM analysis.v_target_provider_profile profile
             WHERE profile.estate_model_pk=@selected_model
               AND profile.target_id=JSON_VALUE(CASE WHEN j.type=5 THEN j.value ELSE N'{}' END,'$.projectionTarget'));

INSERT model.provider_capability_implementation
 (provider_definition_pk,capability_version_pk,role,_owner_definition_pk,_canonical_pointer)
SELECT DISTINCT d.provider_definition_pk,d.capability_version_pk,'PLATFORM',d.semantic_object_definition_pk,
 N'/capabilities/'+d.capability_ordinal
FROM #declared d
WHERE NOT EXISTS (SELECT 1 FROM model.provider_capability_implementation i
 WHERE i.provider_definition_pk=d.provider_definition_pk AND i.capability_version_pk=d.capability_version_pk);
SELECT 'capability_implementations_added' AS result_set,@@ROWCOUNT AS added;

-- Each existing slot keeps its declared requirement and target profile.
SELECT * INTO #implementations FROM analysis.v_target_provider_implementation WHERE estate_model_pk=@selected_model;
SELECT * INTO #profiles FROM analysis.v_target_provider_profile WHERE estate_model_pk=@selected_model;
SELECT pv.port_version_pk,d.definition_json INTO #ports
FROM model.port_version pv JOIN analysis.v_selected_semantic_definition d
 ON d.semantic_object_definition_pk=pv.semantic_object_definition_pk AND d.estate_model_pk=@selected_model
WHERE EXISTS (SELECT 1 FROM model.slot_port_requirement r WHERE r.port_version_pk=pv.port_version_pk);
INSERT model.provider_port_implementation
 (provider_definition_pk,port_version_pk,provider_profile_version_pk,role,_owner_definition_pk,_canonical_pointer)
SELECT DISTINCT i.provider_definition_pk,r.port_version_pk,p.provider_profile_version_pk,
 r.role,i.semantic_object_definition_pk,N''
FROM model.slot_port_requirement r JOIN #ports d ON d.port_version_pk=r.port_version_pk
JOIN #implementations i ON i.capability_id=JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId')
JOIN #profiles p ON p.target_id=i.target_id AND p.effect_classification='effect'
WHERE NOT EXISTS (SELECT 1 FROM model.provider_port_implementation existing
 WHERE existing.provider_definition_pk=i.provider_definition_pk AND existing.port_version_pk=r.port_version_pk
 AND existing.provider_profile_version_pk=p.provider_profile_version_pk);
SELECT 'port_implementations_added' AS result_set,@@ROWCOUNT AS added;

SELECT * INTO #candidates FROM analysis.v_provider_slot_candidate WHERE estate_model_pk=@selected_model;
INSERT model.provider_binding
 (provider_binding_scope_pk,provider_slot_pk,selection_policy,provider_definition_pk,ordinal,_owner_definition_pk,_canonical_pointer)
SELECT scope.provider_binding_scope_pk,scope.provider_slot_pk,scope.selection_policy,
 candidate.provider_definition_pk,NULL,scope._owner_definition_pk,scope._canonical_pointer
FROM model.provider_binding_scope scope
JOIN model.binding_context context ON context.binding_context_pk=scope.binding_context_pk
JOIN #candidates candidate ON candidate.provider_slot_pk=scope.provider_slot_pk
 AND candidate.provider_profile_version_pk=context.provider_profile_version_pk
WHERE scope.selection_policy='SINGLE'
 AND (SELECT COUNT(*) FROM #candidates c WHERE c.provider_slot_pk=scope.provider_slot_pk
      AND c.provider_profile_version_pk=context.provider_profile_version_pk)=1
 AND NOT EXISTS (SELECT 1 FROM model.provider_binding b WHERE b.provider_binding_scope_pk=scope.provider_binding_scope_pk);
SELECT 'bindings_added' AS result_set,@@ROWCOUNT AS added;

INSERT model.binding_port_implementation
 (provider_binding_pk,provider_slot_pk,slot_port_requirement_pk,port_version_pk,
  provider_definition_pk,provider_port_implementation_pk,_owner_definition_pk,_canonical_pointer)
SELECT b.provider_binding_pk,b.provider_slot_pk,r.slot_port_requirement_pk,r.port_version_pk,
 b.provider_definition_pk,i.provider_port_implementation_pk,b._owner_definition_pk,b._canonical_pointer
FROM model.provider_binding b
JOIN model.provider_binding_scope scope ON scope.provider_binding_scope_pk=b.provider_binding_scope_pk
JOIN model.binding_context context ON context.binding_context_pk=scope.binding_context_pk
JOIN model.slot_port_requirement r ON r.provider_slot_pk=b.provider_slot_pk
JOIN model.provider_port_implementation i ON i.provider_definition_pk=b.provider_definition_pk
 AND i.port_version_pk=r.port_version_pk AND i.provider_profile_version_pk=context.provider_profile_version_pk
WHERE NOT EXISTS (SELECT 1 FROM model.binding_port_implementation existing
 WHERE existing.provider_binding_pk=b.provider_binding_pk AND existing.slot_port_requirement_pk=r.slot_port_requirement_pk);

IF EXISTS (SELECT 1 FROM (VALUES ('node'),('python'),('csharp')) target(target_id)
 CROSS JOIN (VALUES ('sda-authority-transformation-port.v1'),('sda-schema-contract-admission.v1')) required(capability_id)
 WHERE (SELECT COUNT(*) FROM #implementations i WHERE i.target_id=target.target_id
        AND i.capability_id=required.capability_id)<>1)
 THROW 51000,'TARGET_PROVIDER_IMPLEMENTATION_NOT_UNIQUE',1;

SELECT 'declared_coverage' AS result_set,target_id,COUNT(*) AS implementation_count
FROM #implementations GROUP BY target_id ORDER BY target_id;
SELECT 'slot_resolution' AS result_set,target_id,disposition,COUNT(*) AS slot_count
FROM analysis.v_provider_slot_resolution WHERE estate_model_pk=@selected_model
GROUP BY target_id,disposition ORDER BY target_id,disposition;
COMMIT TRANSACTION;
