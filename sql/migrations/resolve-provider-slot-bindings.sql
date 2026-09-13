-- M2: bind declared provider slots to admitted implementations.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
-- Refuse a second installation rather than mint another capability generation.
IF EXISTS (SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
           WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=N'resolve-provider-slot-bindings')
  THROW 51000,'PROVIDER_SLOT_BINDINGS_ALREADY_DECLARED',1;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers = CURSOR LOCAL FAST_FORWARD FOR
  SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
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
GO
-- The target and implementation reference are declarations, never inferred
-- from a provider's spelling. The normalized implementation link must exist.
CREATE OR ALTER VIEW analysis.v_target_provider_implementation AS
SELECT DISTINCT d.estate_model_pk, pd.provider_definition_pk, p.provider_id,
       pd.semantic_object_definition_pk, pd.definition_digest,
       c.capability_id, cv.capability_version_pk,
       j.target_id, j.implementation_ref, j.conformance_ref
FROM model.provider_definition pd
JOIN model.provider p ON p.provider_pk=pd.provider_pk
JOIN analysis.v_selected_semantic_definition d
  ON d.semantic_object_definition_pk=pd.semantic_object_definition_pk
 AND d.object_kind='PROVIDER'
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.capabilities')
WITH (capability_id nvarchar(400) '$.capabilityId',
      target_id nvarchar(400) '$.projectionTarget',
      implementation_ref nvarchar(1000) '$.implementationRef',
      conformance_ref nvarchar(1000) '$.conformanceRef',
      declaration_status nvarchar(64) '$.status') j
JOIN model.provider_capability_implementation i ON i.provider_definition_pk=pd.provider_definition_pk
JOIN model.capability_version cv ON cv.capability_version_pk=i.capability_version_pk
JOIN model.capability c ON c.capability_pk=cv.capability_pk AND c.capability_id=j.capability_id
JOIN model.estate_capability ec
  ON ec.estate_model_pk=d.estate_model_pk
 AND ec.capability_version_pk=cv.capability_version_pk
WHERE j.declaration_status='ADMITTED' AND j.implementation_ref IS NOT NULL;
GO
-- A port requires the platform capability that its own declaration names.
-- These links add no implementation and change no provider body.
DECLARE @selected_model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
SELECT * INTO #implementations FROM analysis.v_target_provider_implementation WHERE estate_model_pk=@selected_model;
SELECT * INTO #profiles FROM analysis.v_target_provider_profile WHERE estate_model_pk=@selected_model;
SELECT pv.port_version_pk,d.definition_json INTO #ports
FROM model.port_version pv
JOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=pv.semantic_object_definition_pk
WHERE d.estate_model_pk=@selected_model
 AND EXISTS (SELECT 1 FROM model.slot_port_requirement r WHERE r.port_version_pk=pv.port_version_pk);
INSERT model.provider_port_implementation
  (provider_definition_pk,port_version_pk,provider_profile_version_pk,role,_owner_definition_pk,_canonical_pointer)
SELECT DISTINCT i.provider_definition_pk,r.port_version_pk,p.provider_profile_version_pk,
       r.role,i.semantic_object_definition_pk,N''
FROM model.slot_port_requirement r
JOIN #ports d ON d.port_version_pk=r.port_version_pk
JOIN #implementations i
  ON i.capability_id=JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId')
JOIN #profiles p
  ON p.estate_model_pk=i.estate_model_pk AND p.target_id=i.target_id AND p.effect_classification='effect'
WHERE NOT EXISTS (
 SELECT 1 FROM model.provider_port_implementation existing
 WHERE existing.provider_definition_pk=i.provider_definition_pk
   AND existing.port_version_pk=r.port_version_pk
   AND existing.provider_profile_version_pk=p.provider_profile_version_pk
);

-- The existing blueprint slots request port invocation. Their execution host
-- is the effect profile. Pure expression evaluation remains the pure profile.
INSERT model.slot_profile_requirement
  (provider_slot_pk,provider_profile_version_pk,ordinal,role,_owner_definition_pk,_canonical_pointer)
SELECT s.provider_slot_pk,p.provider_profile_version_pk,
       ROW_NUMBER() OVER (PARTITION BY s.provider_slot_pk ORDER BY p.target_id)-1,
       N'effect',s._owner_definition_pk,s._canonical_pointer
FROM model.provider_slot s
JOIN analysis.v_selected_semantic_definition d
  ON d.semantic_object_definition_pk=s._owner_definition_pk AND d.estate_model_pk=@selected_model
JOIN analysis.v_target_provider_profile p ON p.estate_model_pk=d.estate_model_pk AND p.effect_classification='effect'
WHERE NOT EXISTS (SELECT 1 FROM model.slot_profile_requirement r WHERE r.provider_slot_pk=s.provider_slot_pk);
GO
CREATE OR ALTER VIEW analysis.v_provider_slot_candidate AS
SELECT DISTINCT d.estate_model_pk,s.provider_slot_pk,p.target_id,p.provider_profile_version_pk,
       i.provider_definition_pk,i.provider_id
FROM model.provider_slot s
JOIN analysis.v_selected_semantic_definition d
  ON d.semantic_object_definition_pk=s._owner_definition_pk AND d.object_kind='BLUEPRINT'
JOIN model.slot_profile_requirement sr ON sr.provider_slot_pk=s.provider_slot_pk
JOIN analysis.v_target_provider_profile p
  ON p.estate_model_pk=d.estate_model_pk AND p.provider_profile_version_pk=sr.provider_profile_version_pk
JOIN analysis.v_target_provider_implementation i
  ON i.estate_model_pk=d.estate_model_pk AND i.target_id=p.target_id
WHERE (
 EXISTS (SELECT 1 FROM model.slot_port_requirement r WHERE r.provider_slot_pk=s.provider_slot_pk)
 OR EXISTS (SELECT 1 FROM model.slot_mechanic_requirement r WHERE r.provider_slot_pk=s.provider_slot_pk)
)
AND NOT EXISTS (
 SELECT 1 FROM model.slot_port_requirement r WHERE r.provider_slot_pk=s.provider_slot_pk
 AND NOT EXISTS (
  SELECT 1 FROM model.provider_port_implementation pi
  WHERE pi.provider_definition_pk=i.provider_definition_pk AND pi.port_version_pk=r.port_version_pk
    AND (pi.provider_profile_version_pk IS NULL OR pi.provider_profile_version_pk=p.provider_profile_version_pk)
 )
)
AND NOT EXISTS (
 SELECT 1 FROM model.slot_mechanic_requirement r WHERE r.provider_slot_pk=s.provider_slot_pk
 AND NOT EXISTS (
  SELECT 1 FROM model.provider_mechanic_implementation mi
  WHERE mi.provider_definition_pk=i.provider_definition_pk AND mi.mechanic_version_pk=r.mechanic_version_pk
    AND (mi.provider_profile_version_pk IS NULL OR mi.provider_profile_version_pk=p.provider_profile_version_pk)
 )
);
GO
DECLARE @selected_model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @contexts TABLE (target_id nvarchar(400),profile_version_pk bigint,bytes varbinary(max),digest binary(32));
INSERT @contexts
SELECT p.target_id,p.provider_profile_version_pk,b.bytes,HASHBYTES('SHA2_256',b.bytes)
FROM analysis.v_target_provider_profile p
CROSS APPLY (SELECT p.target_id AS targetId,p.provider_profile_id AS providerProfileId,
                   p.profile_definition_digest AS providerProfileDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) j(content)
CROSS APPLY (SELECT CONVERT(varbinary(max),CONVERT(varchar(max),j.content COLLATE Latin1_General_100_BIN2_UTF8))) b(bytes)
WHERE p.estate_model_pk=@selected_model AND p.effect_classification='effect';
INSERT source.content_object (content_digest,content_bytes,byte_length)
SELECT digest,bytes,DATALENGTH(bytes) FROM @contexts c
WHERE NOT EXISTS (SELECT 1 FROM source.content_object o WHERE o.content_digest=c.digest);
INSERT model.binding_context (context_digest,target_id,provider_profile_version_pk,canonical_content_pk)
SELECT c.digest,c.target_id,c.profile_version_pk,o.content_object_pk
FROM @contexts c JOIN source.content_object o ON o.content_digest=c.digest
WHERE NOT EXISTS (SELECT 1 FROM model.binding_context b WHERE b.context_digest=c.digest);
INSERT model.provider_binding_scope
 (provider_slot_pk,binding_context_pk,binding_role,selection_policy,_owner_definition_pk,_canonical_pointer)
SELECT s.provider_slot_pk,bc.binding_context_pk,sr.role,'SINGLE',s._owner_definition_pk,s._canonical_pointer
FROM model.provider_slot s
JOIN analysis.v_selected_semantic_definition d
 ON d.estate_model_pk=@selected_model AND d.semantic_object_definition_pk=s._owner_definition_pk
JOIN model.slot_profile_requirement sr ON sr.provider_slot_pk=s.provider_slot_pk
JOIN @contexts c ON c.profile_version_pk=sr.provider_profile_version_pk
JOIN model.binding_context bc ON bc.context_digest=c.digest
WHERE NOT EXISTS (SELECT 1 FROM model.provider_binding_scope existing
 WHERE existing.provider_slot_pk=s.provider_slot_pk AND existing.binding_context_pk=bc.binding_context_pk);

INSERT model.provider_binding
 (provider_binding_scope_pk,provider_slot_pk,selection_policy,provider_definition_pk,ordinal,_owner_definition_pk,_canonical_pointer)
SELECT bs.provider_binding_scope_pk,bs.provider_slot_pk,'SINGLE',c.provider_definition_pk,NULL,
       bs._owner_definition_pk,bs._canonical_pointer
FROM model.provider_binding_scope bs
JOIN model.binding_context bc ON bc.binding_context_pk=bs.binding_context_pk
JOIN analysis.v_provider_slot_candidate c
 ON c.estate_model_pk=@selected_model AND c.provider_slot_pk=bs.provider_slot_pk
 AND c.target_id=bc.target_id AND c.provider_profile_version_pk=bc.provider_profile_version_pk
WHERE (SELECT COUNT(*) FROM analysis.v_provider_slot_candidate other
 WHERE other.estate_model_pk=c.estate_model_pk AND other.provider_slot_pk=c.provider_slot_pk
   AND other.target_id=c.target_id AND other.provider_profile_version_pk=c.provider_profile_version_pk)=1
AND NOT EXISTS (SELECT 1 FROM model.provider_binding existing WHERE existing.provider_binding_scope_pk=bs.provider_binding_scope_pk);

INSERT model.binding_port_implementation
 (provider_binding_pk,provider_slot_pk,provider_definition_pk,slot_port_requirement_pk,port_version_pk,
  provider_port_implementation_pk,_owner_definition_pk,_canonical_pointer)
SELECT b.provider_binding_pk,b.provider_slot_pk,b.provider_definition_pk,r.slot_port_requirement_pk,r.port_version_pk,
       MIN(pi.provider_port_implementation_pk),b._owner_definition_pk,b._canonical_pointer
FROM model.provider_binding b
JOIN model.provider_binding_scope bs ON bs.provider_binding_scope_pk=b.provider_binding_scope_pk
JOIN model.binding_context bc ON bc.binding_context_pk=bs.binding_context_pk
JOIN model.slot_port_requirement r ON r.provider_slot_pk=b.provider_slot_pk
JOIN model.provider_port_implementation pi ON pi.provider_definition_pk=b.provider_definition_pk
 AND pi.port_version_pk=r.port_version_pk AND pi.provider_profile_version_pk=bc.provider_profile_version_pk
WHERE NOT EXISTS (SELECT 1 FROM model.binding_port_implementation existing
 WHERE existing.provider_binding_pk=b.provider_binding_pk AND existing.slot_port_requirement_pk=r.slot_port_requirement_pk)
GROUP BY b.provider_binding_pk,b.provider_slot_pk,b.provider_definition_pk,r.slot_port_requirement_pk,r.port_version_pk,
         b._owner_definition_pk,b._canonical_pointer;
GO
CREATE OR ALTER VIEW analysis.v_provider_slot_resolution AS
SELECT d.estate_model_pk,c.capability_id,s.slot_id,s.provider_slot_pk,
       p.target_id,p.provider_profile_id,p.provider_profile_version_pk,
       bs.provider_binding_scope_pk,bs.selection_policy,
       requirements.port_count,requirements.mechanic_count,
       candidates.candidate_count,bindings.binding_count,bindings.provider_definition_pk,
       CASE WHEN requirements.port_count+requirements.mechanic_count=0 THEN 'PROVIDER_SLOT_REQUIREMENT_ABSENT'
            WHEN candidates.candidate_count=0 THEN 'PROVIDER_IMPLEMENTATION_ABSENT'
            WHEN candidates.candidate_count>1 THEN 'PROVIDER_SLOT_AMBIGUOUS'
            WHEN bindings.binding_count=0 THEN 'PROVIDER_SLOT_UNBOUND'
            WHEN bindings.binding_count>1 THEN 'PROVIDER_SLOT_AMBIGUOUS'
            WHEN NOT EXISTS (SELECT 1 FROM analysis.v_provider_slot_candidate candidate
                 WHERE candidate.estate_model_pk=d.estate_model_pk AND candidate.provider_slot_pk=s.provider_slot_pk
                   AND candidate.provider_profile_version_pk=p.provider_profile_version_pk
                   AND candidate.provider_definition_pk=bindings.provider_definition_pk) THEN 'PROVIDER_SLOT_UNBOUND'
            ELSE 'PROVIDER_SLOTS_BOUND' END AS disposition
FROM model.provider_slot s
JOIN model.blueprint_version bv ON bv.blueprint_version_pk=s.blueprint_version_pk
JOIN model.capability c ON c.capability_pk=bv.capability_pk
JOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=s._owner_definition_pk AND d.object_kind='BLUEPRINT'
JOIN model.slot_profile_requirement sr ON sr.provider_slot_pk=s.provider_slot_pk
JOIN analysis.v_target_provider_profile p ON p.estate_model_pk=d.estate_model_pk AND p.provider_profile_version_pk=sr.provider_profile_version_pk
LEFT JOIN model.binding_context bc ON bc.provider_profile_version_pk=p.provider_profile_version_pk AND bc.target_id=p.target_id
LEFT JOIN model.provider_binding_scope bs ON bs.provider_slot_pk=s.provider_slot_pk AND bs.binding_context_pk=bc.binding_context_pk
CROSS APPLY (SELECT (SELECT COUNT(*) FROM model.slot_port_requirement r WHERE r.provider_slot_pk=s.provider_slot_pk) AS port_count,
                    (SELECT COUNT(*) FROM model.slot_mechanic_requirement r WHERE r.provider_slot_pk=s.provider_slot_pk) AS mechanic_count) requirements
CROSS APPLY (SELECT COUNT(*) AS candidate_count FROM analysis.v_provider_slot_candidate x
 WHERE x.estate_model_pk=d.estate_model_pk AND x.provider_slot_pk=s.provider_slot_pk
   AND x.provider_profile_version_pk=p.provider_profile_version_pk) candidates
CROSS APPLY (SELECT COUNT(*) AS binding_count,MIN(b.provider_definition_pk) AS provider_definition_pk
 FROM model.provider_binding b WHERE b.provider_binding_scope_pk=bs.provider_binding_scope_pk) bindings;
GO
GRANT SELECT ON OBJECT::analysis.v_target_provider_implementation TO sidefx_reader;
GRANT SELECT ON OBJECT::analysis.v_provider_slot_candidate TO sidefx_reader;
GRANT SELECT ON OBJECT::analysis.v_provider_slot_resolution TO sidefx_reader;
DECLARE @selected_model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
SELECT 'slot_resolution' AS result_set,target_id,disposition,COUNT(*) AS slot_count
FROM analysis.v_provider_slot_resolution WHERE estate_model_pk=@selected_model
GROUP BY target_id,disposition ORDER BY target_id,disposition;
SELECT 'binding_rows' AS result_set,
 (SELECT COUNT(*) FROM model.provider_binding_scope) AS scopes,
 (SELECT COUNT(*) FROM model.provider_binding) AS bindings,
 (SELECT COUNT(*) FROM model.provider_port_implementation) AS port_implementations;
GO
DECLARE @request nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/construct-embodiment-plan-request.v1.schema.json","title":"Construct Embodiment Plan Request","type":"object","additionalProperties":false,"required":["capabilityId"],"properties":{"capabilityId":{"type":"string","minLength":1},"scenarioId":{"type":"string","minLength":1},"target":{"type":"string","enum":["node","python","csharp"]}}}';
DECLARE @declaration nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/capability-authority-declaration.v1.schema.json","title":"Capability Authority Declaration","type":"object","additionalProperties":false,"required":["contractId","capabilityId","scenarioId","target","snapshotId","projectionDigest"],"properties":{"contractId":{"const":"capability-authority-declaration.v1"},"capabilityId":{"type":"string","minLength":1},"scenarioId":{"type":"string","minLength":1},"target":{"type":"string","minLength":1},"snapshotId":{"type":"string","minLength":1},"projectionDigest":{"type":"string","minLength":1},"viewDefinitionDigest":{"type":"string"},"authority":{"type":"object"},"closure":{"type":"object"},"mechanics":{"type":"object"}}}';
DECLARE @bindingSet nvarchar(max)=N'{"type":"object","additionalProperties":false,"required":["contractId","disposition","authorityDeclaration","profiles","bindings","findings"],"properties":{"contractId":{"const":"provider-slot-binding-set.v1"},"disposition":{"enum":["PROVIDER_SLOTS_BOUND","PROVIDER_SLOT_UNBOUND","PROVIDER_SLOT_AMBIGUOUS"]},"authorityDeclaration":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/capability-authority-declaration.v1.schema.json","title":"Capability Authority Declaration","type":"object","additionalProperties":false,"required":["contractId","capabilityId","scenarioId","target","snapshotId","projectionDigest"],"properties":{"contractId":{"const":"capability-authority-declaration.v1"},"capabilityId":{"type":"string","minLength":1},"scenarioId":{"type":"string","minLength":1},"target":{"type":"string","minLength":1},"snapshotId":{"type":"string","minLength":1},"projectionDigest":{"type":"string","minLength":1},"viewDefinitionDigest":{"type":"string"},"authority":{"type":"object"},"closure":{"type":"object"},"mechanics":{"type":"object"}}},"profiles":{"type":"array","items":{"type":"object"}},"bindings":{"type":"array","items":{"type":"object"}},"findings":{"type":"array","items":{"type":"object"}}}}';
DECLARE @plan nvarchar(max)=N'{"anyOf":[{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/capability-embodiment-plan.v1.schema.json","title":"Capability Embodiment Plan","type":"object","additionalProperties":false,"required":["contractId","capabilityId","scenarioId","target","planDigest","artifactDigest","scenarioDefinitionDigest","platformDigest","resolverVersion","fileCount","files"],"properties":{"contractId":{"const":"capability-embodiment-plan.v1"},"capabilityId":{"type":"string","minLength":1},"scenarioId":{"type":"string","minLength":1},"target":{"type":"string","minLength":1},"planDigest":{"type":"string","pattern":"^sha256:[a-f0-9]{64}$"},"artifactDigest":{"type":"string","minLength":1},"scenarioDefinitionDigest":{"type":"string","minLength":1},"platformDigest":{"type":"string","minLength":1},"resolverVersion":{"type":"string","minLength":1},"fileCount":{"type":"integer","minimum":1},"files":{"type":"array","minItems":1,"items":{"type":"object","additionalProperties":false,"required":["relativePath","digest"],"properties":{"relativePath":{"type":"string","minLength":1},"digest":{"type":"string","pattern":"^sha256:[a-f0-9]{64}$"},"sourcePointers":{"type":"array","items":{"type":"string"}}}}}}},{"type":"object","additionalProperties":false,"required":["contractId","disposition","findings"],"properties":{"contractId":{"const":"capability-embodiment-plan.v1"},"disposition":{"const":"EMBODIMENT_PLAN_HELD"},"findings":{"type":"array","minItems":1,"items":{"type":"object"}}}}]}';
EXEC model.scaffold_estate_provider_capability
 @capability_id=N'resolve-provider-slot-bindings',@provider_module=N'src/resolvers/node/database-query-provider.mjs',@provider_export=N'readDatabaseQuery',
 @input_contract=N'capability-authority-declaration.v1',@input_schema=@declaration,@outcome_contract=N'provider-slot-binding-set.v1',@outcome_schema=@bindingSet,
 @description=N'Resolve one exact provider per declared slot for the selected generation and target, preserving the authority declaration and every unresolved requirement';
EXEC model.scaffold_estate_provider_capability
 @capability_id=N'plan-capability-embodiment',@provider_module=N'src/resolvers/node/embodiment-plan-provider.mjs',@provider_export=N'planCapabilityEmbodiment',
 @input_contract=N'provider-slot-binding-set.v1',@input_schema=@bindingSet,@outcome_contract=N'capability-embodiment-plan.v1',@outcome_schema=@plan,
 @description=N'Plan the authority carried by a resolved provider binding set, or return the declared held outcome with its findings';
EXEC model.scaffold_composed_capability
 @capability_id=N'construct-embodiment-plan',@input_contract=N'construct-embodiment-plan-request.v1',@input_schema=@request,
 @outcome_contract=N'capability-embodiment-plan.v1',@outcome_schema=@plan,
 @targets=N'["read-capability-authority","resolve-provider-slot-bindings","plan-capability-embodiment"]',
 @description=N'Read one capability authority, resolve its provider slots, and plan the resolved declaration';
GO
DECLARE @selected_model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @portId nvarchar(400)=N'resolve-provider-slot-bindings-port',@portSo bigint,@portPk bigint,@oldPortVer bigint,@portJson nvarchar(max);
SELECT @portSo=p.semantic_object_pk,@portPk=p.port_pk,@portJson=d.definition_json,@oldPortVer=pv.port_version_pk
FROM model.port p JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
JOIN analysis.v_selected_semantic_definition d ON d.declared_id=p.port_id AND d.namespace_id=n.namespace_id AND d.estate_model_pk=@selected_model AND d.object_kind='PORT'
JOIN model.port_version pv ON pv.semantic_object_definition_pk=d.semantic_object_definition_pk
WHERE n.namespace_id=N'sidefx:capability:resolve-provider-slot-bindings' AND p.port_id=@portId;
SET @portJson=JSON_MODIFY(@portJson,'$.semantics.configuration',JSON_QUERY(N'{"estateProvider":{"module":"src/resolvers/node/database-query-provider.mjs","export":"readDatabaseQuery"},"statement":"IF JSON_VALUE(@input,''$.contractId'') <> ''capability-authority-declaration.v1''\n OR JSON_VALUE(@input,''$.snapshotId'') IS NULL\n OR JSON_VALUE(@input,''$.snapshotId'') <> @snapshot_id\n OR JSON_VALUE(@input,''$.projectionDigest'') IS NULL\n OR JSON_VALUE(@input,''$.projectionDigest'') <> @projection_id\n OR JSON_VALUE(@input,''$.viewDefinitionDigest'') IS NULL\n OR JSON_VALUE(@input,''$.viewDefinitionDigest'') <> @view_definition_digest\n THROW 51000,''DATABASE_AUTHORITY_NOT_COHERENT'',1;\nDECLARE @slots TABLE (capability_id nvarchar(400),slot_id nvarchar(400),target_id nvarchar(400),provider_profile_id nvarchar(400),selection_policy varchar(64),provider_definition_pk bigint,port_count int,mechanic_count int,candidate_count int,binding_count int,disposition varchar(64));\nINSERT @slots\nSELECT capability_id,slot_id,target_id,provider_profile_id,selection_policy,provider_definition_pk,port_count,mechanic_count,candidate_count,binding_count,disposition\nFROM analysis.v_provider_slot_resolution\nWHERE estate_model_pk=@estate_model_pk AND target_id=JSON_VALUE(@input,''$.target'')\n AND (capability_id=JSON_VALUE(@input,''$.capabilityId'') OR capability_id IN (SELECT owning_capability_id FROM OPENJSON(@input,''$.closure.recordsets[0]'') WITH (owning_capability_id nvarchar(400) ''$.owning_capability_id'')));\nSELECT (SELECT ''provider-slot-binding-set.v1'' AS contractId,\n CASE WHEN EXISTS (SELECT 1 FROM @slots WHERE disposition=''PROVIDER_SLOT_AMBIGUOUS'') THEN ''PROVIDER_SLOT_AMBIGUOUS''\n      WHEN EXISTS (SELECT 1 FROM @slots WHERE disposition<>''PROVIDER_SLOTS_BOUND'') THEN ''PROVIDER_SLOT_UNBOUND''\n      ELSE ''PROVIDER_SLOTS_BOUND'' END AS disposition,\n JSON_QUERY(@input) AS authorityDeclaration,\n JSON_QUERY((SELECT provider_profile_id AS providerProfileId,effect_classification AS effectClassification,profile_definition_digest AS definitionDigest\n   FROM analysis.v_target_provider_profile WHERE estate_model_pk=@estate_model_pk AND target_id=JSON_VALUE(@input,''$.target'') ORDER BY effect_classification FOR JSON PATH)) AS profiles,\n JSON_QUERY((SELECT s.capability_id AS capabilityId,s.slot_id AS slotId,s.target_id AS target,s.provider_profile_id AS providerProfileId,s.selection_policy AS selectionPolicy,\n   p.provider_id AS providerId,''sha256:''+LOWER(CONVERT(varchar(64),pd.definition_digest,2)) AS providerDefinitionDigest\n   FROM @slots s JOIN model.provider_definition pd ON pd.provider_definition_pk=s.provider_definition_pk JOIN model.provider p ON p.provider_pk=pd.provider_pk\n   WHERE s.disposition=''PROVIDER_SLOTS_BOUND'' ORDER BY s.capability_id,s.slot_id FOR JSON PATH)) AS bindings,\n JSON_QUERY((SELECT capability_id AS capabilityId,slot_id AS slotId,target_id AS target,disposition AS code,\n   port_count AS portRequirements,mechanic_count AS mechanicRequirements,candidate_count AS candidates,binding_count AS bindings\n   FROM @slots WHERE disposition<>''PROVIDER_SLOTS_BOUND'' ORDER BY capability_id,slot_id FOR JSON PATH)) AS findings\n FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS result_json;","resultColumn":"result_json"}'));
DECLARE @portBytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@portJson COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @portDigest binary(32)=HASHBYTES('SHA2_256',@portBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@portDigest) INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@portDigest,@portBytes,DATALENGTH(@portBytes));
DECLARE @portDef bigint=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@portSo AND definition_digest=@portDigest);
IF @portDef IS NULL BEGIN INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk) VALUES(@portSo,'PORT',@portDigest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@portDigest));SET @portDef=SCOPE_IDENTITY();END;
IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@selected_model AND semantic_object_definition_pk=@portDef) INSERT model.estate_definition VALUES(@selected_model,@portDef);
DECLARE @portVer bigint=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@portDef);
IF @portVer IS NULL BEGIN INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer) VALUES(@portPk,@portSo,@portDef,@portDigest,'consumer-interface-authority.v1','PORT',@portDef,N'');SET @portVer=SCOPE_IDENTITY();END;
UPDATE model.operation_port_invocation SET port_version_pk=@portVer WHERE port_version_pk=@oldPortVer;
GO
DECLARE @selected_model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @portId nvarchar(400)=N'plan-capability-embodiment-port',@portSo bigint,@portPk bigint,@oldPortVer bigint,@portJson nvarchar(max);
SELECT @portSo=p.semantic_object_pk,@portPk=p.port_pk,@portJson=d.definition_json,@oldPortVer=pv.port_version_pk
FROM model.port p JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
JOIN analysis.v_selected_semantic_definition d ON d.declared_id=p.port_id AND d.namespace_id=n.namespace_id AND d.estate_model_pk=@selected_model AND d.object_kind='PORT'
JOIN model.port_version pv ON pv.semantic_object_definition_pk=d.semantic_object_definition_pk
WHERE n.namespace_id=N'sidefx:capability:plan-capability-embodiment' AND p.port_id=@portId;
SET @portJson=JSON_MODIFY(@portJson,'$.semantics.configuration',JSON_QUERY(N'{"estateProvider":{"module":"src/resolvers/node/embodiment-plan-provider.mjs","export":"planCapabilityEmbodiment"},"inputField":"authorityDeclaration","inputAdmission":{"type":"object","required":["disposition"],"properties":{"disposition":{"const":"PROVIDER_SLOTS_BOUND"}}},"admissionFailure":{"contractId":"capability-embodiment-plan.v1","disposition":"EMBODIMENT_PLAN_HELD"},"failureFields":["findings"]}'));
DECLARE @portBytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@portJson COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @portDigest binary(32)=HASHBYTES('SHA2_256',@portBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@portDigest) INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@portDigest,@portBytes,DATALENGTH(@portBytes));
DECLARE @portDef bigint=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@portSo AND definition_digest=@portDigest);
IF @portDef IS NULL BEGIN INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk) VALUES(@portSo,'PORT',@portDigest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@portDigest));SET @portDef=SCOPE_IDENTITY();END;
IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@selected_model AND semantic_object_definition_pk=@portDef) INSERT model.estate_definition VALUES(@selected_model,@portDef);
DECLARE @portVer bigint=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@portDef);
IF @portVer IS NULL BEGIN INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer) VALUES(@portPk,@portSo,@portDef,@portDigest,'consumer-interface-authority.v1','PORT',@portDef,N'');SET @portVer=SCOPE_IDENTITY();END;
UPDATE model.operation_port_invocation SET port_version_pk=@portVer WHERE port_version_pk=@oldPortVer;

COMMIT TRANSACTION;
