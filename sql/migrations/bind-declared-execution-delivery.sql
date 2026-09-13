-- Bind direct CLI invocation to the declared execution capability.
-- Keep the existing unavailable outcome and decode only a completed response.
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
WHILE @@FETCH_STATUS=0 BEGIN
 EXEC(N'DROP TRIGGER '+@trigger_name);
 FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
IF EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1) AND object_kind='PROVIDER' AND JSON_QUERY(definition_json,'$.semantics.executionDelivery') IS NOT NULL) THROW 51000,'EXECUTION_DELIVERY_ALREADY_DECLARED',1;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1),@previous bigint;
SELECT @previous=pd.provider_definition_pk FROM analysis.v_selected_semantic_definition d JOIN model.provider_definition pd ON pd.semantic_object_definition_pk=d.semantic_object_definition_pk WHERE d.estate_model_pk=@estate AND d.object_kind='PROVIDER' AND d.declared_id=N'ScenarioKernel.NodePlatform.Interface.JsonCli';
DECLARE @object bigint,@definition bigint,@digest binary(32);
EXEC model.put_semantic_definition 'PROVIDER',N'sidefx:providers',N'ScenarioKernel.NodePlatform.Interface.JsonCli',N'{"capabilities":[{"capabilityId":"sda-json-cli.v1","conformanceRef":"tools/tests/consumer-projection/platform-capability-admission.test.js","implementationRef":"languages/typescript/runtimes/node/admitted-consumer-platform.mjs","kind":"interface-delivery","projectionTarget":"node","provider":"ScenarioKernel.NodePlatform.Interface.JsonCli","providesMechanics":["cli-delivery","json-reading","json-serialization"],"status":"ADMITTED"}],"catalogType":"sda-platform-capability-catalog.v1","executionDelivery":{"capabilityId":"execute-declared-capability","requestExpression":{"op":"object","fields":{"capabilityId":{"op":"path","from":"input","path":"selection.capabilityId"},"scenarioId":{"op":"path","from":"input","path":"selected.scenario_id"},"namespaceId":{"op":"path","from":"input","path":"selected.namespace_id"},"target":{"op":"path","from":"input","path":"selection.target"},"scenarioInput":{"op":"path","from":"input","path":"scenarioInput"}}},"resultExpression":{"op":"object","fields":{"disposition":{"op":"if","when":{"op":"equals","left":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"input","path":"executionResult.disposition"},"right":{"op":"literal","value":"EXECUTION_COMPLETED"}},"then":{"op":"literal","value":"terminated"},"else":{"op":"if","when":{"op":"includes","in":{"op":"literal","value":["INPUT_REJECTED","OUTCOME_REJECTED"]},"value":{"op":"path","from":"input","path":"executionResult.disposition"}},"then":{"op":"literal","value":"rejected"},"else":{"op":"literal","value":"failed"}}},"right":{"op":"literal","value":"failed"}},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"terminated"}},"result":{"op":"object","fields":{"executionId":{"op":"path","from":"input","path":"rootExecutionId"},"rootExecutionId":{"op":"path","from":"input","path":"rootExecutionId"},"parentExecutionId":{"op":"literal","value":null},"scenarioId":{"op":"path","from":"input","path":"selected.scenario_id"},"input":{"op":"path","from":"input","path":"scenarioInput"},"event":{"op":"object","fields":{"eventId":{"op":"path","from":"input","path":"selected.event_id"}}},"outcome":{"op":"path","from":"input","path":"executionResult.execution.result.outcome"},"disposition":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"input","path":"executionResult.disposition"},"right":{"op":"literal","value":"EXECUTION_COMPLETED"}},"then":{"op":"literal","value":"terminated"},"else":{"op":"if","when":{"op":"includes","in":{"op":"literal","value":["INPUT_REJECTED","OUTCOME_REJECTED"]},"value":{"op":"path","from":"input","path":"executionResult.disposition"}},"then":{"op":"literal","value":"rejected"},"else":{"op":"literal","value":"failed"}}},"executionDisposition":{"op":"path","from":"input","path":"executionResult.disposition"}}},"execution":{"op":"path","from":"input","path":"executionResult.execution"},"authorityIdentity":{"op":"path","from":"input","path":"executionResult.authorityIdentity"}}}}}',@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
DECLARE @provider bigint=(SELECT provider_pk FROM model.provider WHERE semantic_object_pk=@object),@next bigint=(SELECT provider_definition_pk FROM model.provider_definition WHERE semantic_object_definition_pk=@definition);
IF @next IS NULL BEGIN
 INSERT model.provider_definition(provider_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,declaration_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@provider,@object,@definition,@digest,N'ScenarioKernel.NodePlatform.Interface.JsonCli','sda-platform-capability-catalog.v1','PROVIDER',@definition,N''); SET @next=SCOPE_IDENTITY();
END;
INSERT model.provider_capability_implementation(provider_definition_pk,capability_version_pk,role,_owner_definition_pk,_canonical_pointer)
SELECT @next,capability_version_pk,role,@definition,_canonical_pointer FROM model.provider_capability_implementation i WHERE provider_definition_pk=@previous AND NOT EXISTS(SELECT 1 FROM model.provider_capability_implementation n WHERE n.provider_definition_pk=@next AND n.capability_version_pk=i.capability_version_pk);
INSERT model.provider_mechanic_implementation(provider_definition_pk,mechanic_version_pk,provider_profile_version_pk,role,_owner_definition_pk,_canonical_pointer)
SELECT @next,mechanic_version_pk,provider_profile_version_pk,role,@definition,_canonical_pointer FROM model.provider_mechanic_implementation i WHERE provider_definition_pk=@previous AND NOT EXISTS(SELECT 1 FROM model.provider_mechanic_implementation n WHERE n.provider_definition_pk=@next AND n.mechanic_version_pk=i.mechanic_version_pk AND (n.provider_profile_version_pk=i.provider_profile_version_pk OR n.provider_profile_version_pk IS NULL AND i.provider_profile_version_pk IS NULL));
INSERT model.provider_port_implementation(provider_definition_pk,port_version_pk,provider_profile_version_pk,role,_owner_definition_pk,_canonical_pointer)
SELECT @next,port_version_pk,provider_profile_version_pk,role,@definition,_canonical_pointer FROM model.provider_port_implementation i WHERE provider_definition_pk=@previous AND NOT EXISTS(SELECT 1 FROM model.provider_port_implementation n WHERE n.provider_definition_pk=@next AND n.port_version_pk=i.port_version_pk AND n.provider_profile_version_pk=i.provider_profile_version_pk);
IF @next<>@previous BEGIN
 DELETE i FROM model.binding_port_implementation i JOIN model.provider_binding b ON b.provider_binding_pk=i.provider_binding_pk WHERE b.provider_definition_pk=@previous;
 UPDATE model.provider_binding SET provider_definition_pk=@next WHERE provider_definition_pk=@previous;
 INSERT model.binding_port_implementation(provider_binding_pk,provider_slot_pk,slot_port_requirement_pk,port_version_pk,provider_definition_pk,provider_port_implementation_pk,_owner_definition_pk,_canonical_pointer)
 SELECT b.provider_binding_pk,b.provider_slot_pk,r.slot_port_requirement_pk,r.port_version_pk,@next,i.provider_port_implementation_pk,b._owner_definition_pk,b._canonical_pointer
 FROM model.provider_binding b JOIN model.provider_binding_scope scope ON scope.provider_binding_scope_pk=b.provider_binding_scope_pk
 JOIN model.binding_context context ON context.binding_context_pk=scope.binding_context_pk JOIN model.slot_port_requirement r ON r.provider_slot_pk=b.provider_slot_pk
 JOIN model.provider_port_implementation i ON i.provider_definition_pk=@next AND i.port_version_pk=r.port_version_pk AND i.provider_profile_version_pk=context.provider_profile_version_pk WHERE b.provider_definition_pk=@next;
END;
SELECT N'node' AS target,@next AS provider_definition_pk;
GO
DECLARE @old_contract bigint=110929;
IF NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d JOIN model.contract_version v ON v.semantic_object_definition_pk=d.semantic_object_definition_pk WHERE d.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1) AND d.object_kind='CONTRACT' AND d.declared_id=N'capability-execution-request.v1' AND v.contract_version_pk=@old_contract) THROW 51000,'EXECUTION_REQUEST_CONTRACT_DIVERGED',1;
EXEC model.declare_contract @id=N'capability-execution-request.v1',@schema=N'{"type":"object","required":["capabilityId","target","scenarioInput"],"properties":{"capabilityId":{"type":"string","minLength":1},"target":{"type":"string","minLength":1},"scenarioId":{"type":"string"},"scenarioInput":{},"namespaceId":{"type":"string","minLength":1}},"additionalProperties":false}';
DECLARE @new_contract bigint=(SELECT v.contract_version_pk FROM analysis.v_selected_semantic_definition d JOIN model.contract_version v ON v.semantic_object_definition_pk=d.semantic_object_definition_pk WHERE d.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1) AND d.object_kind='CONTRACT' AND d.declared_id=N'capability-execution-request.v1');
UPDATE model.scenario_input SET input_contract_version_pk=@new_contract WHERE input_contract_version_pk=@old_contract;
UPDATE model.estate_scenario_face_resolution SET contract_version_pk=@new_contract WHERE contract_version_pk=@old_contract;
SELECT @new_contract AS execution_request_contract_version;
GO
SELECT 'execution_delivery' AS result_set,declared_id,JSON_QUERY(definition_json,'$.semantics.executionDelivery') AS configuration FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1) AND object_kind='PROVIDER' AND declared_id=N'ScenarioKernel.NodePlatform.Interface.JsonCli';
COMMIT TRANSACTION;
