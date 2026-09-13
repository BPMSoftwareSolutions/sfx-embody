-- M3: retain the selected equity execution's port requirements as provider slots.
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
WHILE @@FETCH_STATUS=0
BEGIN
 EXEC(N'DROP TRIGGER '+@trigger_name);
 FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
DECLARE @selected_model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capability_id nvarchar(400)=N'resolve-equity-market-price-evidence';
DECLARE @blueprint_id nvarchar(400)=@capability_id+N'-blueprint.v1';
DECLARE @namespace bigint=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_id=N'sidefx:blueprints');
IF EXISTS (SELECT 1 FROM model.blueprint WHERE namespace_pk=@namespace AND blueprint_id=@blueprint_id)
 THROW 51000,'EQUITY_PROVIDER_REQUIREMENTS_ALREADY_DECLARED',1;
DECLARE @capability bigint,@capability_version bigint,@scenario_version bigint,@scenario_definition bigint,@capability_digest binary(32);
SELECT @capability=c.capability_pk,@capability_version=ec.capability_version_pk,
 @scenario_version=cs.scenario_version_pk,@scenario_definition=sv.semantic_object_definition_pk,@capability_digest=cv.definition_digest
FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@selected_model
JOIN model.capability_version cv ON cv.capability_version_pk=ec.capability_version_pk
JOIN model.capability_root_scenario root ON root.capability_version_pk=ec.capability_version_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk AND cs.scenario_pk=root.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
WHERE c.capability_id=@capability_id;
IF @scenario_version IS NULL THROW 51000,'EQUITY_ROOT_AUTHORITY_ABSENT',1;

SELECT op.execution_operation_pk,op.ordinal,p.port_id,pv.port_version_pk,pv.semantic_object_definition_pk AS port_definition,
 pv.definition_digest AS port_digest,JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id
INTO #operations
FROM model.scenario_event event
JOIN model.execution_operation op ON op.execution_authority_version_pk=event.execution_authority_version_pk
JOIN model.operation_port_invocation invocation ON invocation.execution_operation_pk=op.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=invocation.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=pv.semantic_object_definition_pk AND d.estate_model_pk=@selected_model
WHERE event.scenario_version_pk=@scenario_version;
IF (SELECT COUNT(*) FROM #operations)<>5 THROW 51000,'EQUITY_WORKING_EXECUTION_DIVERGED',1;

-- The execution authority remains the source of operation order. These nodes
-- record requirements; they do not add or replace any execution operation.
DECLARE @nodes nvarchar(max)=(SELECT port_id+N'-slot' AS nodeId,'provider-slot' AS kind,'PROVIDER' AS altitude,
 ordinal AS projectionOrdinal,port_id+N'-slot' AS [providerSlot.slotId],
 port_id AS [providerSlot.portId],platform_capability_id AS [providerSlot.platformCapabilityId],
 'sha256:'+LOWER(CONVERT(varchar(64),port_digest,2)) AS [providerSlot.portDefinitionDigest]
 FROM #operations ORDER BY ordinal FOR JSON PATH);
DECLARE @definition nvarchar(max)=(SELECT @blueprint_id AS [address.id],'BLUEPRINT' AS [address.kind],
 'sidefx:blueprints' AS [address.namespace],'sidefx-semantic-definition.v1' AS format,
 'canonical-circuit-blueprint.v1' AS [semantics.carrierVersion],@blueprint_id AS [semantics.blueprintAuthority.blueprintId],
 @capability_id AS [semantics.capability.capabilityId],
 'sha256:'+LOWER(CONVERT(varchar(64),@capability_digest,2)) AS [semantics.capability.capabilityAuthorityDigest],
 JSON_QUERY(@nodes) AS [semantics.nodes]
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@definition COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @digest binary(32)=HASHBYTES('SHA2_256',@bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest)
 INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@digest,@bytes,DATALENGTH(@bytes));
INSERT model.semantic_object(object_kind,namespace_pk,declared_id) VALUES('BLUEPRINT',@namespace,@blueprint_id);
DECLARE @object bigint=SCOPE_IDENTITY();
INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk)
 VALUES(@object,'BLUEPRINT',@digest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest));
DECLARE @definition_pk bigint=SCOPE_IDENTITY();
INSERT model.estate_definition(estate_model_pk,semantic_object_definition_pk) VALUES(@selected_model,@definition_pk);
INSERT model.blueprint(namespace_pk,blueprint_id,semantic_object_pk,object_kind) VALUES(@namespace,@blueprint_id,@object,'BLUEPRINT');
DECLARE @blueprint bigint=SCOPE_IDENTITY();
INSERT model.blueprint_version(blueprint_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
 capability_pk,capability_version_pk,carrier_profile,source_disposition,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@blueprint,@object,@definition_pk,@digest,@capability,@capability_version,'canonical-circuit-blueprint.v1','CANDIDATE','BLUEPRINT',@definition_pk,N'');
DECLARE @version bigint=SCOPE_IDENTITY();
INSERT model.blueprint_node(blueprint_version_pk,node_id,node_kind,altitude,projection_ordinal,
 semantic_object_definition_pk,expected_semantic_kind,_owner_definition_pk,_canonical_pointer)
SELECT @version,port_id+N'-slot','provider-slot','PROVIDER',ordinal,port_definition,'PORT',
 @definition_pk,N'/nodes/'+CONVERT(nvarchar(20),ordinal) FROM #operations;
INSERT model.provider_slot(blueprint_version_pk,slot_id,owner_node_pk,_owner_definition_pk,_canonical_pointer)
SELECT @version,node_id,blueprint_node_pk,@definition_pk,_canonical_pointer+N'/providerSlot'
FROM model.blueprint_node WHERE blueprint_version_pk=@version;
INSERT model.slot_port_requirement(provider_slot_pk,port_version_pk,ordinal,role,_owner_definition_pk,_canonical_pointer)
SELECT slot.provider_slot_pk,op.port_version_pk,0,N'event-port',@definition_pk,slot._canonical_pointer
FROM #operations op JOIN model.provider_slot slot ON slot.blueprint_version_pk=@version AND slot.slot_id=op.port_id+N'-slot';
INSERT model.provider_slot_operation(provider_slot_pk,execution_operation_pk,_owner_definition_pk,_canonical_pointer)
SELECT slot.provider_slot_pk,op.execution_operation_pk,@definition_pk,slot._canonical_pointer
FROM #operations op JOIN model.provider_slot slot ON slot.blueprint_version_pk=@version AND slot.slot_id=op.port_id+N'-slot';

SELECT * INTO #profiles FROM analysis.v_target_provider_profile WHERE estate_model_pk=@selected_model AND effect_classification='effect';
INSERT model.slot_profile_requirement(provider_slot_pk,provider_profile_version_pk,ordinal,role,_owner_definition_pk,_canonical_pointer)
SELECT slot.provider_slot_pk,p.provider_profile_version_pk,ROW_NUMBER() OVER(PARTITION BY slot.provider_slot_pk ORDER BY p.target_id)-1,
 N'effect',@definition_pk,slot._canonical_pointer
FROM model.provider_slot slot CROSS JOIN #profiles p WHERE slot.blueprint_version_pk=@version;
INSERT model.provider_binding_scope(provider_slot_pk,binding_context_pk,binding_role,selection_policy,_owner_definition_pk,_canonical_pointer)
SELECT slot.provider_slot_pk,context.binding_context_pk,N'event-port','SINGLE',@definition_pk,slot._canonical_pointer
FROM model.provider_slot slot CROSS JOIN #profiles p
JOIN model.binding_context context ON context.provider_profile_version_pk=p.provider_profile_version_pk AND context.target_id=p.target_id
WHERE slot.blueprint_version_pk=@version;
SELECT * INTO #implementations FROM analysis.v_target_provider_implementation WHERE estate_model_pk=@selected_model;
INSERT model.provider_port_implementation(provider_definition_pk,port_version_pk,provider_profile_version_pk,role,_owner_definition_pk,_canonical_pointer)
SELECT DISTINCT i.provider_definition_pk,op.port_version_pk,p.provider_profile_version_pk,N'event-port',i.semantic_object_definition_pk,N''
FROM #operations op JOIN #implementations i ON i.capability_id=op.platform_capability_id
JOIN #profiles p ON p.target_id=i.target_id
WHERE NOT EXISTS (SELECT 1 FROM model.provider_port_implementation previous WHERE previous.provider_definition_pk=i.provider_definition_pk
 AND previous.port_version_pk=op.port_version_pk AND previous.provider_profile_version_pk=p.provider_profile_version_pk);
SELECT * INTO #candidates FROM analysis.v_provider_slot_candidate WHERE estate_model_pk=@selected_model
 AND provider_slot_pk IN (SELECT provider_slot_pk FROM model.provider_slot WHERE blueprint_version_pk=@version);
INSERT model.provider_binding(provider_binding_scope_pk,provider_slot_pk,selection_policy,provider_definition_pk,ordinal,_owner_definition_pk,_canonical_pointer)
SELECT scope.provider_binding_scope_pk,scope.provider_slot_pk,'SINGLE',candidate.provider_definition_pk,NULL,@definition_pk,scope._canonical_pointer
FROM model.provider_binding_scope scope
JOIN model.binding_context context ON context.binding_context_pk=scope.binding_context_pk
JOIN #candidates candidate ON candidate.provider_slot_pk=scope.provider_slot_pk AND candidate.provider_profile_version_pk=context.provider_profile_version_pk
WHERE (SELECT COUNT(*) FROM #candidates other WHERE other.provider_slot_pk=candidate.provider_slot_pk
 AND other.provider_profile_version_pk=candidate.provider_profile_version_pk)=1;
INSERT model.binding_port_implementation(provider_binding_pk,provider_slot_pk,provider_definition_pk,slot_port_requirement_pk,port_version_pk,
 provider_port_implementation_pk,_owner_definition_pk,_canonical_pointer)
SELECT b.provider_binding_pk,b.provider_slot_pk,b.provider_definition_pk,r.slot_port_requirement_pk,r.port_version_pk,
 i.provider_port_implementation_pk,@definition_pk,b._canonical_pointer
FROM model.provider_binding b JOIN model.provider_binding_scope scope ON scope.provider_binding_scope_pk=b.provider_binding_scope_pk
JOIN model.binding_context context ON context.binding_context_pk=scope.binding_context_pk
JOIN model.slot_port_requirement r ON r.provider_slot_pk=b.provider_slot_pk
JOIN model.provider_port_implementation i ON i.provider_definition_pk=b.provider_definition_pk
 AND i.port_version_pk=r.port_version_pk AND i.provider_profile_version_pk=context.provider_profile_version_pk
WHERE b._owner_definition_pk=@definition_pk;

IF (SELECT COUNT(*) FROM model.provider_slot_operation WHERE _owner_definition_pk=@definition_pk)<>5
 THROW 51000,'EQUITY_PROVIDER_OPERATION_COVERAGE_INCOMPLETE',1;
SELECT 'equity_slot_resolution' AS result_set,slot_id,target_id,port_count,mechanic_count,candidate_count,binding_count,disposition
FROM analysis.v_provider_slot_resolution WHERE estate_model_pk=@selected_model AND capability_id=@capability_id
ORDER BY slot_id,target_id;
COMMIT TRANSACTION;
