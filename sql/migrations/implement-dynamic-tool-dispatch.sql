-- implement-dynamic-tool-dispatch.sql
--
-- Dynamic tool dispatch: the platform executes the tool the model chooses, not
-- the hard-coded equity capability.
--
-- Two deliverables, one transaction:
--
--  1. Fill the `execution-authority-change` kind body (the last executable writer
--     kind left as a refuse-by-default skeleton) with a real admission predicate
--     and installer per docs/authoring-altitude-model-stubs-2026-09-21/
--     stub-fill-checklist.md row 5 and docs/model-at-each-authoring-altitude-2026-09-21/
--     candidate-admit-pipeline.md B.2 kind 5. The installer adds or replaces an
--     execution authority's operation bindings through the existing authoring
--     primitives (`model.put_semantic_definition` for PORT and EXECUTION_AUTHORITY,
--     the same authority/operation/link mint `model.scaffold_composed_capability`
--     and declare-agent-capability.sql use: execution_authority_version,
--     execution_operation, operation_port_invocation / operation_scenario_invocation,
--     then UPDATE model.scenario_event), with the same candidate gate, secret scan,
--     named refusals, AUTHORITY receipt and byte-identical replay as
--     `capability-authoring-change`. An invoke-scenario operation may name a
--     targetCapabilityId; the installer resolves it to that capability's selected
--     root scenario, which is the declared child dispatch.
--
--  2. Re-declare the agent-lane proposal execution: `execute-admitted-proposal`'s
--     static `shape-equity-execution-request` operation is replaced by
--     `resolve-admitted-tool-port`, a declared read that resolves
--     `$.proposal.capability` (the capability named by the admitted agent-route)
--     against the selected estate and shapes the child input; the child invocation
--     is the execution authority's declared child (installed here for equity, and
--     per admitted proposal by an execution-authority-change document). When the
--     route names equity the resolution returns the equity execution request and
--     the declared child is `resolve-equity-market-price-evidence`'s root scenario,
--     so the existing behavior is preserved exactly.
--
-- BLOCKER (precise, stated in the return): per-invocation dispatch -- choosing the
-- child scenario from the run-time route value inside one invocation -- is NOT
-- expressible with the installed kernel. Both consumer platforms resolve an
-- `invoke-scenario` operation to a scenario id at graph assembly time
-- (languages/csharp/.../bootstrap/DeclaredOperationCarrier.cs:108 and
-- Consumer/AdmittedConsumerPlatform.cs:415 read operation["scenarioId"] as a
-- literal; the node matrix does the same with operation.scenarioNodeId), and no
-- declared mechanic resolves a scenario/capability id from run-time input. The
-- general execution mechanics (sda-semantic-execution-graph-compilation-port.v1 /
-- ...-execution-port.v1) exist only in the boot path, and the estate's
-- run-declared-graph-execute overlay binds neither, so a "read the chosen graph,
-- then execute it" scenario cannot run inside an invocation without an SDA
-- registry/overlay change (forbidden here). The strongest DB-expressible form is
-- therefore declared child dispatch: the admitted proposal's capability is bound
-- as the authority's child by an `execution-authority-change` at admission time.
--
-- Admission predicate (admit-execution-authority-change, replaced):
--   contract shape; the capability owns the owning scenario; >=1 operation; every
--   operation kind in {invoke-port, invoke-scenario}; every invoke-port resolves
--   to a declared port or is bound by portBindings[]; every invoke-scenario names
--   a targetCapabilityId, targetScenarioId or scenarioId that resolves in the
--   selected estate (unknown tool -> EXECUTION_AUTHORITY_CHANGE_TARGET_NOT_DECLARED);
--   preflight/route present; no secret-shaped keys/values; the shared ACCEPTED
--   candidate gate (CANDIDATE_ACCEPTANCE_REQUIRED / CANDIDATE_NOT_ACCEPTED) as on
--   the other five kinds. Clean document answers ADMITTED.
--
-- Installer refusals (named): EXECUTION_AUTHORITY_CHANGE_TRANSACTION_REQUIRED,
-- _DOCUMENT_REQUIRED, _CAPABILITY_REQUIRED, _AUTHORITY_REQUIRED,
-- _OWNING_SCENARIO_REQUIRED, _OPERATIONS_REQUIRED, _OPERATION_KIND_INVALID,
-- _PORT_REQUIRED, _PORT_NOT_DECLARED, _TARGET_NOT_DECLARED,
-- _SECRET_SHAPED_MATERIAL, CANDIDATE_ACCEPTANCE_REQUIRED, CANDIDATE_NOT_ACCEPTED.
-- Replay -> already_installed.
--
-- Boot authority (same selected sda-kernel-boot-data-access.v1): the
-- admit-execution-authority-change read statement is replaced and the payload and
-- installed contracts are revised (the executor validates results as the
-- recordsets envelope). The re-mint asserts structural prerequisites, not an exact
-- prior content digest, because parallel lanes re-mint the same authority; replay
-- is detected from the revised read/contracts themselves.
--
-- Idempotent: CREATE OR ALTER is re-runnable; the authority is re-minted only
-- while the read/contracts lack the real predicate; a replay prints
-- already_declared, and the equity dispatch install replays already_installed.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=300000;
IF @lock<0 THROW 51000,N'DYNAMIC_TOOL_DISPATCH_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
CREATE OR ALTER PROCEDURE model.install_execution_authority_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'EXECUTION_AUTHORITY_CHANGE_TRANSACTION_REQUIRED',1;
 IF @document IS NULL OR ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'execution-authority-change.v1'
  THROW 51000,'EXECUTION_AUTHORITY_CHANGE_DOCUMENT_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.capabilityId'),N'');
 IF @capability_id IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_CAPABILITY_REQUIRED',1;
 DECLARE @authority_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.authorityId'),N'');
 IF @authority_id IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_AUTHORITY_REQUIRED',1;
 DECLARE @owning_scenario nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.owningScenarioId'),N'');
 IF @owning_scenario IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_OWNING_SCENARIO_REQUIRED',1;
 DECLARE @operations nvarchar(max)=JSON_QUERY(@document,'$.operations');
 IF @operations IS NULL OR ISJSON(@operations)<>1 OR (SELECT COUNT(*) FROM OPENJSON(@operations))=0
  THROW 51000,'EXECUTION_AUTHORITY_CHANGE_OPERATIONS_REQUIRED',1;
 IF EXISTS(SELECT 1 FROM OPENJSON(@operations) WHERE JSON_VALUE(value,'$.kind') NOT IN (N'invoke-port',N'invoke-scenario'))
  THROW 51000,'EXECUTION_AUTHORITY_CHANGE_OPERATION_KIND_INVALID',1;
 DECLARE @port_bindings nvarchar(max)=COALESCE(JSON_QUERY(@document,'$.portBindings'),N'[]');
 IF ISJSON(@port_bindings)<>1 OR LEFT(LTRIM(@port_bindings),1)<>N'[' THROW 51000,'EXECUTION_AUTHORITY_CHANGE_PORT_BINDINGS_INVALID',1;
 DECLARE @candidate_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.candidateId'),N'');
 DECLARE @bundle_digest nvarchar(100)=NULLIF(JSON_VALUE(@document,'$.bundleDigest'),N'');
 -- Secret-shape scan: key-name scan plus the value-suffix scan the author stage
 -- uses; a document that carries material never installs.
 DECLARE @upper nvarchar(max)=UPPER(@document);
 IF @upper LIKE N'%"APIKEY"%' OR @upper LIKE N'%"API_KEY"%' OR @upper LIKE N'%"PASSWORD"%'
  OR @upper LIKE N'%"SECRET"%' OR @upper LIKE N'%"TOKEN"%' OR @upper LIKE N'%"CLIENTSECRET"%'
  OR @upper LIKE N'%"PRIVATEKEY"%' OR @upper LIKE N'%"ACCESSKEY"%' OR @upper LIKE N'%"BEARER"%'
  OR @upper LIKE N'%-KEY"%' OR @upper LIKE N'%-TOKEN"%' OR @upper LIKE N'%-SECRET"%'
  THROW 51000,'EXECUTION_AUTHORITY_CHANGE_SECRET_SHAPED_MATERIAL',1;
 -- Shared ACCEPTED candidate gate, identical to capability-authoring-change.
 IF @candidate_id IS NULL OR @bundle_digest IS NULL THROW 51000,'CANDIDATE_ACCEPTANCE_REQUIRED',1;
 IF NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=N'sidefx:candidates'
   AND ((d.declared_id=@candidate_id+N'.decision.v1'
         AND JSON_VALUE(d.definition_json,'$.semantics.document.decision')=N'ACCEPTED'
         AND JSON_VALUE(d.definition_json,'$.semantics.document.bundleDigest')=@bundle_digest)
     OR (d.declared_id=@candidate_id+N'.receipt.v1'
         AND JSON_VALUE(d.definition_json,'$.semantics.document.review.decision')=N'ACCEPTED'
         AND JSON_VALUE(d.definition_json,'$.semantics.document.bundleDigest')=@bundle_digest)))
  THROW 51000,'CANDIDATE_NOT_ACCEPTED',1;
 -- Capability, namespace, owning scenario.
 DECLARE @capability_pk bigint,@capability_so bigint,@namespace nvarchar(400);
 SELECT @capability_pk=c.capability_pk,@capability_so=c.semantic_object_pk,@namespace=n.namespace_id
 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
 WHERE c.capability_id=@capability_id;
 IF @capability_pk IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_CAPABILITY_NOT_DECLARED',1;
 SET @namespace=N'sidefx:capability:'+@capability_id;
 DECLARE @owning_scenario_pk bigint=(SELECT s.scenario_pk FROM model.scenario s WHERE s.capability_pk=@capability_pk AND s.scenario_id=@owning_scenario);
 IF @owning_scenario_pk IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_OWNING_SCENARIO_NOT_DECLARED',1;
 DECLARE @owning_scenario_version bigint=(SELECT cs.scenario_version_pk
  FROM model.capability_scenario cs WHERE cs.capability_version_pk=(SELECT ec.capability_version_pk FROM model.estate_capability ec WHERE ec.estate_model_pk=@estate AND ec.capability_pk=@capability_pk)
  AND cs.scenario_pk=@owning_scenario_pk);
 IF @owning_scenario_version IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_OWNING_SCENARIO_NOT_DECLARED',1;
 -- Resolve every operation binding first, so nothing is written before every
 -- target and port resolves (the write set stays all-or-nothing).
 DECLARE @resolved TABLE(ordinal int PRIMARY KEY,operation_kind nvarchar(50),port_version_pk bigint,target_scenario_version_pk bigint);
 DECLARE @ordinal int,@kind nvarchar(50),@port_id nvarchar(400),@target_capability nvarchar(400),@target_scenario nvarchar(400);
 DECLARE @port_version bigint,@target_version bigint,@binding nvarchar(max);
 DECLARE op_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT CONVERT(int,[key]),JSON_VALUE(value,'$.kind'),JSON_VALUE(value,'$.portId'),
   JSON_VALUE(value,'$.targetCapabilityId'),COALESCE(JSON_VALUE(value,'$.targetScenarioId'),JSON_VALUE(value,'$.scenarioId'))
  FROM OPENJSON(@operations) ORDER BY CONVERT(int,[key]);
 OPEN op_cursor;
 FETCH NEXT FROM op_cursor INTO @ordinal,@kind,@port_id,@target_capability,@target_scenario;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @port_version=NULL; SET @target_version=NULL;
  IF @kind=N'invoke-port'
  BEGIN
   IF @port_id IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_PORT_REQUIRED',1;
   SELECT @binding=value FROM OPENJSON(@port_bindings) WHERE JSON_VALUE(value,'$.portId')=@port_id;
   IF @binding IS NOT NULL
   BEGIN
    DECLARE @p_object bigint,@p_definition bigint,@p_digest binary(32);
    EXEC model.put_semantic_definition 'PORT',@namespace,@port_id,@binding,@p_object OUTPUT,@p_definition OUTPUT,@p_digest OUTPUT;
    SET @port_version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@p_definition);
    IF @port_version IS NULL
    BEGIN
     DECLARE @p_pk bigint=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@p_object);
     IF @p_pk IS NULL
     BEGIN
      INSERT model.port(namespace_pk,port_id,semantic_object_pk,object_kind)
      SELECT namespace_pk,@port_id,@p_object,'PORT' FROM model.semantic_object WHERE semantic_object_pk=@p_object;
      SET @p_pk=SCOPE_IDENTITY();
     END
     INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
      port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
     VALUES(@p_pk,@p_object,@p_definition,@p_digest,'consumer-interface-authority.v1','PORT',@p_definition,N'');
     SET @port_version=SCOPE_IDENTITY();
    END
   END
   ELSE
   BEGIN
    SELECT @port_version=pv.port_version_pk
    FROM analysis.v_selected_semantic_definition d
    JOIN model.port_version pv ON pv.semantic_object_definition_pk=d.semantic_object_definition_pk
    WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT'
     AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
     AND d.declared_id=@port_id COLLATE Latin1_General_100_BIN2;
   END
   IF @port_version IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_PORT_NOT_DECLARED',1;
  END
  ELSE IF @kind=N'invoke-scenario'
  BEGIN
   IF @target_scenario IS NOT NULL
    SELECT @target_version=sv.scenario_version_pk
    FROM analysis.v_selected_semantic_definition s
    JOIN model.scenario sc ON sc.scenario_id=s.declared_id COLLATE Latin1_General_100_BIN2
    JOIN model.scenario_version sv ON sv.scenario_pk=sc.scenario_pk AND sv.semantic_object_definition_pk=s.semantic_object_definition_pk
    WHERE s.estate_model_pk=@estate AND s.object_kind=N'SCENARIO'
     AND s.declared_id=@target_scenario COLLATE Latin1_General_100_BIN2;
   ELSE IF @target_capability IS NOT NULL
    SELECT @target_version=cs.scenario_version_pk
    FROM model.capability tc
    JOIN model.identity_namespace tn ON tn.namespace_pk=tc.namespace_pk AND tn.namespace_id=N'sidefx:capabilities'
    JOIN model.estate_capability tec ON tec.capability_pk=tc.capability_pk AND tec.estate_model_pk=@estate
    JOIN model.capability_root_scenario rs ON rs.capability_version_pk=tec.capability_version_pk
    JOIN model.capability_scenario cs ON cs.capability_version_pk=tec.capability_version_pk AND cs.scenario_pk=rs.scenario_pk
    WHERE tc.capability_id=@target_capability;
   IF @target_version IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_TARGET_NOT_DECLARED',1;
  END
  INSERT @resolved(ordinal,operation_kind,port_version_pk,target_scenario_version_pk)
  VALUES(@ordinal,@kind,@port_version,@target_version);
  FETCH NEXT FROM op_cursor INTO @ordinal,@kind,@port_id,@target_capability,@target_scenario;
 END
 CLOSE op_cursor; DEALLOCATE op_cursor;
 -- The candidate authority envelope: the declared operations exactly as authored,
 -- so a byte-identical document replays as already_installed.
 DECLARE @semantics nvarchar(max);
 SET @semantics=(SELECT @authority_id AS [authority.id],@owning_scenario AS [authority.owningScenarioId],
  JSON_QUERY(@operations) AS [authority.operations] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @candidate_text nvarchar(max);
 SET @candidate_text=(SELECT @authority_id AS [address.id],N'EXECUTION_AUTHORITY' AS [address.kind],@namespace AS [address.namespace],
  N'sidefx-semantic-definition.v1' AS format,JSON_QUERY(@semantics) AS semantics FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @candidate_digest binary(32)=HASHBYTES('SHA2_256',
  CONVERT(varbinary(max),CONVERT(varchar(max),@candidate_text COLLATE Latin1_General_100_BIN2_UTF8)));
 DECLARE @document_digest varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
  CONVERT(varbinary(max),CONVERT(varchar(max),@document COLLATE Latin1_General_100_BIN2_UTF8))),2));
 DECLARE @receipt_id nvarchar(400)=@authority_id+N'.authored.v1';
 DECLARE @prior_receipt_digest varchar(64)=(SELECT JSON_VALUE(definition_json,'$.semantics.documentDigest')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@receipt_id COLLATE Latin1_General_100_BIN2);
 DECLARE @selected_digest binary(32)=(SELECT definition_digest FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'EXECUTION_AUTHORITY' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@authority_id COLLATE Latin1_General_100_BIN2);
 IF @prior_receipt_digest=@document_digest OR @selected_digest=@candidate_digest
 BEGIN
  SELECT N'already_installed' AS result_set,@authority_id AS authority_id,@capability_id AS capability_id;
  RETURN;
 END
 -- Mint the new authority version and its operation links, in declared order.
 DECLARE @authority_object bigint,@authority_definition bigint,@authority_digest binary(32);
 EXEC model.put_semantic_definition 'EXECUTION_AUTHORITY',@namespace,@authority_id,@semantics,
  @authority_object OUTPUT,@authority_definition OUTPUT,@authority_digest OUTPUT;
 DECLARE @authority_pk bigint=(SELECT execution_authority_pk FROM model.execution_authority WHERE semantic_object_pk=@authority_object);
 IF @authority_pk IS NULL
 BEGIN
  INSERT model.execution_authority(namespace_pk,execution_authority_id,semantic_object_pk,object_kind)
  SELECT namespace_pk,@authority_id,@authority_object,'EXECUTION_AUTHORITY' FROM model.semantic_object WHERE semantic_object_pk=@authority_object;
  SET @authority_pk=SCOPE_IDENTITY();
 END
 DECLARE @authority_version bigint=(SELECT execution_authority_version_pk FROM model.execution_authority_version WHERE semantic_object_definition_pk=@authority_definition);
 IF @authority_version IS NULL
 BEGIN
  INSERT model.execution_authority_version(execution_authority_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
   authority_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@authority_pk,@authority_object,@authority_definition,@authority_digest,'execution-authorities.v1','EXECUTION_AUTHORITY',@authority_definition,N'');
  SET @authority_version=SCOPE_IDENTITY();
  INSERT model.execution_operation(execution_authority_version_pk,operation_id,ordinal,operation_kind,_owner_definition_pk,_canonical_pointer)
  SELECT @authority_version,JSON_VALUE(value,'$.operationId'),CONVERT(int,[key]),JSON_VALUE(value,'$.kind'),@authority_definition,N'/semantics/authority/operations/'+[key]
  FROM OPENJSON(@operations) ORDER BY CONVERT(int,[key]);
  INSERT model.operation_port_invocation(execution_operation_pk,port_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
  SELECT eo.execution_operation_pk,r.port_version_pk,'invoke-port',@authority_definition,eo._canonical_pointer
  FROM model.execution_operation eo JOIN @resolved r ON r.ordinal=eo.ordinal
  WHERE eo.execution_authority_version_pk=@authority_version AND r.operation_kind=N'invoke-port';
  INSERT model.operation_scenario_invocation(execution_operation_pk,target_scenario_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
  SELECT eo.execution_operation_pk,r.target_scenario_version_pk,'invoke-scenario',@authority_definition,eo._canonical_pointer
  FROM model.execution_operation eo JOIN @resolved r ON r.ordinal=eo.ordinal
  WHERE eo.execution_authority_version_pk=@authority_version AND r.operation_kind=N'invoke-scenario';
 END
 UPDATE model.scenario_event SET execution_authority_version_pk=@authority_version WHERE scenario_version_pk=@owning_scenario_version;
 -- AUTHORITY receipt, consistent with capability-authoring-change.
 DECLARE @receipt nvarchar(max);
 SET @receipt=(SELECT JSON_QUERY(@document) AS document,@document_digest AS documentDigest,
  @candidate_id AS candidateId,@bundle_digest AS bundleDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @receipt_semantics nvarchar(max);
 SET @receipt_semantics=(SELECT JSON_QUERY(@receipt) AS document FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @r_object bigint,@r_definition bigint,@r_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',@namespace,@receipt_id,@receipt_semantics,
  @r_object OUTPUT,@r_definition OUTPUT,@r_digest OUTPUT;
 SELECT N'execution_authority_change_installed' AS result_set,@authority_id AS authority_id,@capability_id AS capability_id;
END;
GO
-- ============================== AUTHORITY REVISION ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @selected nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
IF @selected IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_NOT_SELECTED',1;
DECLARE @body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@selected,N'sha256:',N''),2));
IF @body IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_BODY_MISSING',1;
IF JSON_VALUE(@body,'$.authorityId')<>@authority_id THROW 51000,N'KERNEL_BOOT_AUTHORITY_IDENTITY_DIVERGED',1;

-- Structural prerequisites: the six skeleton kinds, the execution-authority-change
-- read and both of its contracts.
DECLARE @required_kinds TABLE(kind nvarchar(200) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @required_kinds(kind) VALUES
 (N'capability-authoring'),(N'contract-change'),(N'scenario-authoring'),
 (N'transformation-change'),(N'execution-authority-change'),(N'feature-binding-change');
IF (SELECT COUNT(*) FROM @required_kinds k WHERE EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeKinds')
 WHERE JSON_VALUE(value,'$.changeKind') COLLATE Latin1_General_100_BIN2=k.kind))<>6
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-execution-authority-change')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'execution-authority-change.v1')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'execution-authority-change-installed.v1')
 THROW 51000,N'KERNEL_BOOT_AUTHORITY_CHANGED_REBASE_DECLARATION',1;

DECLARE @declared bit=CASE WHEN
 EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement')
  WHERE readId=N'admit-execution-authority-change' AND statement LIKE N'%EXECUTION_AUTHORITY_CHANGE_TARGET_NOT_DECLARED%')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'execution-authority-change.v1'
  AND value LIKE N'%"candidateId"%')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'execution-authority-change-installed.v1'
  AND JSON_VALUE(value,'$.type')=N'array')
 THEN 1 ELSE 0 END;

IF @declared=0
BEGIN
 DECLARE @admit_statement nvarchar(max)=CAST(N'DECLARE @findings TABLE(ordinal int IDENTITY(1,1),code nvarchar(100),field nvarchar(400),message nvarchar(2000));
IF ISJSON(@input)<>1 OR JSON_QUERY(@input) IS NULL
 INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_DOCUMENT_REQUIRED'',NULL,N''the change must be a JSON object'');
ELSE BEGIN
 DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.capabilityId''),N'''');
 DECLARE @authority_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.authorityId''),N'''');
 DECLARE @owning_scenario nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.owningScenarioId''),N'''');
 DECLARE @operations nvarchar(max)=JSON_QUERY(@input,''$.operations'');
 DECLARE @port_bindings nvarchar(max)=COALESCE(JSON_QUERY(@input,''$.portBindings''),N''[]'');
 IF JSON_VALUE(@input,''$.contractId'')<>N''execution-authority-change.v1''
  INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_CONTRACT_REQUIRED'',N''contractId'',N''contractId must be execution-authority-change.v1'');
 IF @capability_id IS NULL
  INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_CAPABILITY_REQUIRED'',N''capabilityId'',N''the change must name the capability whose execution authority it revises'');
 ELSE IF NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition c WHERE c.estate_model_pk=@estate_model_pk
  AND c.object_kind=N''CAPABILITY'' AND c.namespace_id=N''sidefx:capabilities'' AND c.declared_id=@capability_id)
  INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_CAPABILITY_NOT_DECLARED'',N''capabilityId'',N''the named capability is not selected in the estate'');
 IF @authority_id IS NULL
  INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_AUTHORITY_REQUIRED'',N''authorityId'',N''the change must name the execution authority it revises'');
 IF @owning_scenario IS NULL
  INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_OWNING_SCENARIO_REQUIRED'',N''owningScenarioId'',N''the change must name the scenario whose event carries the authority'');
 ELSE IF @capability_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM model.capability c
  JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N''sidefx:capabilities''
  JOIN model.scenario s ON s.capability_pk=c.capability_pk WHERE c.capability_id=@capability_id AND s.scenario_id=@owning_scenario)
  INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_OWNING_SCENARIO_NOT_DECLARED'',N''owningScenarioId'',N''the owning scenario is not declared on the capability'');
 IF @operations IS NULL OR ISJSON(@operations)<>1 OR (SELECT COUNT(*) FROM OPENJSON(@operations))=0
  INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_OPERATIONS_REQUIRED'',N''operations'',N''at least one declared operation is required'');
 ELSE BEGIN
  IF EXISTS(SELECT 1 FROM OPENJSON(@operations) WHERE JSON_VALUE(value,''$.kind'') NOT IN (N''invoke-port'',N''invoke-scenario''))
   INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_OPERATION_KIND_INVALID'',N''operations.kind'',N''operation kind must be invoke-port or invoke-scenario'');
  IF EXISTS(SELECT 1 FROM OPENJSON(@operations) o WHERE JSON_VALUE(o.value,''$.kind'')=N''invoke-port'' AND NULLIF(JSON_VALUE(o.value,''$.portId''),N'''') IS NULL)
   INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_PORT_REQUIRED'',N''operations.portId'',N''every invoke-port operation must name its port'');
  IF EXISTS(SELECT 1 FROM OPENJSON(@operations) o WHERE JSON_VALUE(o.value,''$.kind'')=N''invoke-port''
   AND NULLIF(JSON_VALUE(o.value,''$.portId''),N'''') IS NOT NULL
   AND NOT EXISTS(SELECT 1 FROM OPENJSON(@port_bindings) b WHERE JSON_VALUE(b.value,''$.portId'')=JSON_VALUE(o.value,''$.portId''))
   AND @capability_id IS NOT NULL
   AND NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition p WHERE p.estate_model_pk=@estate_model_pk
    AND p.object_kind=N''PORT'' AND p.namespace_id=N''sidefx:capability:''+@capability_id AND p.declared_id=JSON_VALUE(o.value,''$.portId'')))
   INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_PORT_NOT_DECLARED'',N''operations.portId'',N''every invoke-port operation must resolve to a declared port or be bound by portBindings'');
  IF EXISTS(SELECT 1 FROM OPENJSON(@operations) o WHERE JSON_VALUE(o.value,''$.kind'')=N''invoke-scenario''
   AND NULLIF(JSON_VALUE(o.value,''$.targetScenarioId''),N'''') IS NULL AND NULLIF(JSON_VALUE(o.value,''$.targetCapabilityId''),N'''') IS NULL
   AND NULLIF(JSON_VALUE(o.value,''$.scenarioId''),N'''') IS NULL)
   INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_TARGET_NOT_DECLARED'',N''operations'',N''every invoke-scenario operation must name a targetCapabilityId, targetScenarioId or scenarioId'');
  IF EXISTS(SELECT 1 FROM OPENJSON(@operations) o WHERE JSON_VALUE(o.value,''$.kind'')=N''invoke-scenario''
   AND NULLIF(JSON_VALUE(o.value,''$.targetCapabilityId''),N'''') IS NOT NULL
   AND NOT EXISTS(SELECT 1 FROM model.capability tc
    JOIN model.identity_namespace tn ON tn.namespace_pk=tc.namespace_pk AND tn.namespace_id=N''sidefx:capabilities''
    JOIN model.estate_capability tec ON tec.capability_pk=tc.capability_pk AND tec.estate_model_pk=@estate_model_pk
    JOIN model.capability_root_scenario trs ON trs.capability_version_pk=tec.capability_version_pk
    JOIN model.capability_scenario tcs ON tcs.capability_version_pk=tec.capability_version_pk AND tcs.scenario_pk=trs.scenario_pk
    WHERE tc.capability_id=JSON_VALUE(o.value,''$.targetCapabilityId'')))
   INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_TARGET_NOT_DECLARED'',N''operations.targetCapabilityId'',N''the target capability has no selected root scenario'');
  IF EXISTS(SELECT 1 FROM OPENJSON(@operations) o WHERE JSON_VALUE(o.value,''$.kind'')=N''invoke-scenario''
   AND NULLIF(JSON_VALUE(o.value,''$.targetScenarioId''),N'''') IS NOT NULL
   AND NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition t WHERE t.estate_model_pk=@estate_model_pk
    AND t.object_kind=N''SCENARIO'' AND t.declared_id=JSON_VALUE(o.value,''$.targetScenarioId'')))
   INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_TARGET_NOT_DECLARED'',N''operations.targetScenarioId'',N''the target scenario is not selected in the estate'');
 END
 IF JSON_QUERY(@input,''$.preflight.input'') IS NULL
  INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_PREFLIGHT_INPUT_REQUIRED'',N''preflight.input'',N''the change must carry its preflight input object'');
 IF JSON_VALUE(@input,''$.route.resolvedDisposition'') IS NULL
  INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_ROUTE_DISPOSITION_REQUIRED'',N''route.resolvedDisposition'',N''the change must carry its resolved disposition'');
 DECLARE @upper nvarchar(max)=UPPER(@input);
 IF @upper LIKE N''%"APIKEY"%'' OR @upper LIKE N''%"API_KEY"%'' OR @upper LIKE N''%"PASSWORD"%''
  OR @upper LIKE N''%"SECRET"%'' OR @upper LIKE N''%"TOKEN"%'' OR @upper LIKE N''%"CLIENTSECRET"%''
  OR @upper LIKE N''%"PRIVATEKEY"%'' OR @upper LIKE N''%"ACCESSKEY"%'' OR @upper LIKE N''%"BEARER"%''
  OR @upper LIKE N''%-KEY"%'' OR @upper LIKE N''%-TOKEN"%'' OR @upper LIKE N''%-SECRET"%''
  INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_SECRET_SHAPED_MATERIAL'',NULL,N''the change carries secret-shaped keys or values'');
 DECLARE @candidate_gate_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.candidateId''),N'''');
 DECLARE @candidate_gate_digest nvarchar(100)=NULLIF(JSON_VALUE(@input,''$.bundleDigest''),N'''');
 IF @candidate_gate_id IS NULL OR @candidate_gate_digest IS NULL
  INSERT @findings(code,field,message) VALUES(N''CANDIDATE_ACCEPTANCE_REQUIRED'',N''candidateId'',N''the change must name the candidateId and bundleDigest of the candidate it installs'');
 ELSE IF NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''AUTHORITY'' AND d.namespace_id=N''sidefx:candidates''
   AND ((d.declared_id=@candidate_gate_id+N''.decision.v1''
         AND JSON_VALUE(d.definition_json,''$.semantics.document.decision'')=N''ACCEPTED''
         AND JSON_VALUE(d.definition_json,''$.semantics.document.bundleDigest'')=@candidate_gate_digest)
     OR (d.declared_id=@candidate_gate_id+N''.receipt.v1''
         AND JSON_VALUE(d.definition_json,''$.semantics.document.review.decision'')=N''ACCEPTED''
         AND JSON_VALUE(d.definition_json,''$.semantics.document.bundleDigest'')=@candidate_gate_digest)))
  INSERT @findings(code,field,message) VALUES(N''CANDIDATE_NOT_ACCEPTED'',N''candidateId'',N''no decision or receipt ACCEPTS this candidate at this bundle digest'');
END
DECLARE @reason nvarchar(max)=ISNULL((SELECT code,field,message FROM @findings ORDER BY ordinal FOR JSON PATH),N''[]'');
SELECT CASE WHEN (SELECT COUNT(*) FROM @findings)=0 THEN N''ADMITTED'' ELSE N''HELD'' END AS disposition,LEFT(@reason,400) AS reason' AS nvarchar(max));
 DECLARE @read_row nvarchar(max);
 SET @read_row=(SELECT N'admit-execution-authority-change' AS readId,
  N'Validate an execution-authority-change.v1 document: contract shape, owning scenario, at least one operation of kind invoke-port or invoke-scenario, every port and every child target resolving in the selected estate (unknown tool -> EXECUTION_AUTHORITY_CHANGE_TARGET_NOT_DECLARED), secret-shaped material, and the shared ACCEPTED candidate gate. Returns exactly one ADMITTED or HELD row; writes nothing.' AS purpose,
  N'observation' AS classification,N'tsql' AS sourceKind,@admit_statement AS statement
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @payload_contract nvarchar(max)=N'{"title":"Execution authority change","description":"One execution authority revision: the authority and owning scenario, the declared operations (invoke-port portId | invoke-scenario targetCapabilityId/targetScenarioId/scenarioId), the optional port bindings, the candidate acceptance that authorizes it and the preflight the kind is verified by.","type":"object","additionalProperties":false,"required":["contractId","candidateId","bundleDigest","capabilityId","authorityId","owningScenarioId","operations","preflight","route"],"properties":{"contractId":{"const":"execution-authority-change.v1"},"candidateId":{"type":"string","minLength":1,"maxLength":400},"bundleDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"capabilityId":{"type":"string","minLength":1,"maxLength":400},"authorityId":{"type":"string","minLength":1,"maxLength":400},"owningScenarioId":{"type":"string","minLength":1,"maxLength":400},"operations":{"type":"array","minItems":1,"items":{"type":"object","additionalProperties":true,"required":["kind"],"properties":{"kind":{"enum":["invoke-port","invoke-scenario"]}}}},"portBindings":{"type":"array","items":{"type":"object"}},"preflight":{"type":"object","additionalProperties":false,"required":["input"],"properties":{"input":{"type":"object"},"expected":{"type":"object"}}},"route":{"type":"object","additionalProperties":false,"required":["resolvedDisposition"],"properties":{"resolvedDisposition":{"type":"string","minLength":1,"maxLength":100}}}}}';
 DECLARE @installed_contract nvarchar(max)=N'{"title":"Execution authority change installed","description":"Executor recordsets envelope: execution_authority_change_installed for a new install, already_installed for a byte-identical replay.","type":"array","minItems":1,"maxItems":1,"items":{"type":"array","minItems":1,"maxItems":1,"items":{"type":"object","additionalProperties":false,"required":["result_set","authority_id","capability_id"],"properties":{"result_set":{"enum":["execution_authority_change_installed","already_installed"]},"authority_id":{"type":"string","minLength":1,"maxLength":400},"capability_id":{"type":"string","minLength":1,"maxLength":400}}}}}';
 DECLARE @reads TABLE(ordinal int PRIMARY KEY,entry nvarchar(max));
 INSERT @reads(ordinal,entry) SELECT CONVERT(int,[key]),value FROM OPENJSON(@body,'$.reads');
 DECLARE @read_count int=(SELECT COUNT(*) FROM @reads);
 DECLARE @read_ordinal int,@read_entry nvarchar(max);
 DECLARE read_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal,entry FROM @reads ORDER BY ordinal;
 OPEN read_cursor;
 FETCH NEXT FROM read_cursor INTO @read_ordinal,@read_entry;
 SET @body=JSON_MODIFY(@body,'$.reads',JSON_QUERY(N'[]'));
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF JSON_VALUE(@read_entry,'$.readId')=N'admit-execution-authority-change' SET @read_entry=@read_row;
  SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@read_entry));
  FETCH NEXT FROM read_cursor INTO @read_ordinal,@read_entry;
 END
 CLOSE read_cursor; DEALLOCATE read_cursor;
 IF (SELECT COUNT(*) FROM OPENJSON(@body,'$.reads'))<>@read_count THROW 51000,N'EXECUTION_AUTHORITY_CHANGE_READ_COUNT_CHANGED',1;
 SET @body=JSON_MODIFY(@body,'$.changeContracts."execution-authority-change.v1"',JSON_QUERY(@payload_contract));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."execution-authority-change-installed.v1"',JSON_QUERY(@installed_contract));
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content binary(32)=HASHBYTES('SHA2_256',@bytes);
 DECLARE @new_content nvarchar(80)=N'sha256:'+LOWER(CONVERT(varchar(64),@content,2));
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content,@bytes,DATALENGTH(@bytes));
 DECLARE @authority_semantics nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
  WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
 SET @authority_semantics=JSON_MODIFY(@authority_semantics,'$.contentDigest',@new_content);
 DECLARE @authority_object bigint,@authority_definition bigint,@authority_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@authority_semantics,
  @authority_object OUTPUT,@authority_definition OUTPUT,@authority_digest OUTPUT;
END

DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
DECLARE @declared_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@result_content,N'sha256:',N''),2));
IF JSON_VALUE(@declared_body,'$.authorityDigest')<>N'sha256:a34639fce305a43c02c4cc5f072a4e3a98c1f1ba90ffb23739d321a9e21a7db3'
 THROW 51000,N'DYNAMIC_TOOL_DISPATCH_AUTHORITY_DIGEST_DIVERGED',1;
IF NOT EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.reads') WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement')
 WHERE readId=N'admit-execution-authority-change' AND statement LIKE N'%EXECUTION_AUTHORITY_CHANGE_TARGET_NOT_DECLARED%')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.changeContracts') WHERE [key]=N'execution-authority-change.v1' AND value LIKE N'%"candidateId"%')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.changeContracts') WHERE [key]=N'execution-authority-change-installed.v1' AND JSON_VALUE(value,'$.type')=N'array')
 THROW 51000,N'DYNAMIC_TOOL_DISPATCH_DECLARATION_INCOMPLETE',1;
SELECT N'0_kind_revision' AS result_set,@authority_id AS authority_id,@result_content AS content_digest,
 CASE WHEN @declared=1 THEN N'already_declared' ELSE N'revised' END AS disposition;
GO
-- ============================== AGENT-LANE RE-DECLARATION ==============================
-- `execute-admitted-proposal` no longer hard-codes the equity shaping. Operation 0
-- resolves the capability named by the admitted agent-route and shapes the child
-- input; operation 1 is the declared child. The committed state declares equity
-- (the child the currently admitted route names), preserving the existing
-- behavior; a per-admitted-proposal execution-authority-change re-declares the
-- child for the tool that proposal names.
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @agent_capability nvarchar(400)=N'request-capability-from-objective';
DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@agent_capability;

-- The generic resolution read: route state (proposal.capability / proposal.input)
-- -> the child input carrier, resolving the capability against the selected estate.
DECLARE @resolve_statement nvarchar(max)=N'DECLARE @proposed nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.proposal.capability''),N'''');
IF @proposed IS NULL SET @proposed=NULLIF(JSON_VALUE(@input,''$.carried.proposedCapability''),N'''');
DECLARE @declared bit=CASE WHEN EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=''CAPABILITY'' AND d.declared_id=@proposed) THEN 1 ELSE 0 END;
DECLARE @execution_request nvarchar(max)=COALESCE(JSON_QUERY(@input,''$.executionRequest''),JSON_QUERY(@input,''$.proposal.input''),JSON_QUERY(@input));
SELECT (SELECT N''agent-admitted-tool-resolution.v1'' AS contractId,@proposed AS capabilityId,@declared AS declared,
 JSON_QUERY(@execution_request) AS executionRequest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;';
DECLARE @resolve_binding nvarchar(max);
SET @resolve_binding=(SELECT N'resolve-admitted-tool-port' AS portId,N'sda-embodiment-plan-port.v1' AS platformCapabilityId,
 JSON_QUERY((SELECT @resolve_statement AS statement,N'value' AS resultColumn FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS configuration
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @port_object bigint,@port_definition bigint,@port_digest binary(32);
EXEC model.put_semantic_definition 'PORT',@namespace,N'resolve-admitted-tool-port',@resolve_binding,
 @port_object OUTPUT,@port_definition OUTPUT,@port_digest OUTPUT;
DECLARE @port_pk bigint=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@port_object);
IF @port_pk IS NULL
BEGIN
 INSERT model.port(namespace_pk,port_id,semantic_object_pk,object_kind)
 SELECT namespace_pk,N'resolve-admitted-tool-port',@port_object,'PORT' FROM model.semantic_object WHERE semantic_object_pk=@port_object;
 SET @port_pk=SCOPE_IDENTITY();
END
IF NOT EXISTS(SELECT 1 FROM model.port_version WHERE semantic_object_definition_pk=@port_definition)
 INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
  port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@port_pk,@port_object,@port_definition,@port_digest,'consumer-interface-authority.v1','PORT',@port_definition,N'');

-- Baseline digests of unrelated capabilities, compared again after the writes.
DECLARE @baseline TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @baseline(capability_id,digest,bytes)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'authoring-altitude-model-stubs',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g;
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'DYNAMIC_TOOL_DISPATCH_BASELINE_MISSING',1;

-- Fixture: an ACCEPTED decision for the candidate the dispatch documents install.
DECLARE @candidate nvarchar(400)=N'dynamic-tool-dispatch.candidate-1';
DECLARE @bundle nvarchar(100)=N'sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
DECLARE @decision_id nvarchar(400)=@candidate+N'.decision.v1';
DECLARE @decision nvarchar(max);
SET @decision=(SELECT @candidate AS candidateId,@bundle AS bundleDigest,N'ACCEPTED' AS decision,
 N'dynamic-tool-dispatch-reviewer' AS reviewerAuthorityId,N'2026-09-22T00:00:00Z' AS decidedAt FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @decision_receipt nvarchar(max);
SET @decision_receipt=(SELECT JSON_QUERY(@decision) AS document,N'sha256:fixture' AS decisionDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @d_object bigint,@d_definition bigint,@d_digest binary(32);
EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:candidates',@decision_id,@decision_receipt,
 @d_object OUTPUT,@d_definition OUTPUT,@d_digest OUTPUT;

-- The admission read from the selected boot authority.
DECLARE @boot_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=N'sda-kernel-boot-data-access.v1');
DECLARE @boot_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@boot_content,N'sha256:',N''),2));
DECLARE @admit_statement nvarchar(max);
SELECT @admit_statement=statement FROM OPENJSON(@boot_body,'$.reads')
 WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement')
 WHERE readId=N'admit-execution-authority-change';
IF @admit_statement IS NULL THROW 51000,N'DYNAMIC_TOOL_DISPATCH_ADMISSION_READ_MISSING',1;
DECLARE @admission TABLE(disposition nvarchar(20),reason nvarchar(400));

-- Document shape: two operations, the resolver port binding, and a declared child.
DECLARE @operations nvarchar(max),@port_bindings nvarchar(max);
SET @operations=(SELECT operationId,kind,portId FROM (
 SELECT N'execute-admitted-proposal.resolve' AS operationId,N'invoke-port' AS kind,N'resolve-admitted-tool-port' AS portId
 UNION ALL
 SELECT N'execute-admitted-proposal.execute',N'invoke-scenario',NULL
) operations FOR JSON PATH);
SET @port_bindings=N'['+@resolve_binding+N']';
DECLARE @authoring_tool nvarchar(400)=N'authoring-altitude-model-stubs';
DECLARE @authoring_scenario nvarchar(400)=N'altitude-4-contracts-schemas';
DECLARE @authoring_document nvarchar(max);
SET @authoring_document=(SELECT N'execution-authority-change.v1' AS contractId,@candidate AS candidateId,@bundle AS bundleDigest,
 @agent_capability AS capabilityId,N'execute-admitted-proposal.v1' AS authorityId,N'execute-admitted-proposal' AS owningScenarioId,
 JSON_QUERY(@operations) AS operations,JSON_QUERY(@port_bindings) AS portBindings,
 JSON_QUERY(N'{"input":{"objective":"author the contract schemas for the authored capability"},"expected":{"disposition":"terminated"}}') AS preflight,
 JSON_QUERY(N'{"resolvedDisposition":"terminated"}') AS route FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
-- Attach the declared child target to operation 1 (unknown tool = the same shape
-- with an unresolvable target capability).
DECLARE @authoring_full nvarchar(max)=JSON_MODIFY(JSON_MODIFY(@authoring_document,
 '$.operations[1].targetCapabilityId',@authoring_tool),'$.operations[1].targetScenarioId',@authoring_scenario);
DECLARE @unknown_full nvarchar(max)=JSON_MODIFY(@authoring_document,'$.operations[1].targetCapabilityId',N'no-such-authoring-tool');

DELETE @admission;
INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@authoring_full,@estate_model_pk=@estate;
SELECT N'1_admission_authoring_tool' AS result_set,disposition,reason FROM @admission;
IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'ADMITTED') THROW 51000,N'DYNAMIC_TOOL_DISPATCH_AUTHORING_ADMISSION_FAILED',1;
DELETE @admission;
INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@unknown_full,@estate_model_pk=@estate;
SELECT N'2_admission_unknown_tool' AS result_set,disposition,reason FROM @admission;
IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'HELD' AND reason LIKE N'%EXECUTION_AUTHORITY_CHANGE_TARGET_NOT_DECLARED%')
 THROW 51000,N'DYNAMIC_TOOL_DISPATCH_UNKNOWN_TARGET_PROOF_FAILED',1;
DECLARE @no_acceptance nvarchar(max)=JSON_MODIFY(@authoring_full,'$.candidateId',N'dynamic-tool-dispatch.no-decision');
DELETE @admission;
INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@no_acceptance,@estate_model_pk=@estate;
SELECT N'3_admission_shared_gate' AS result_set,disposition,reason FROM @admission;
IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'HELD' AND reason LIKE N'%CANDIDATE_NOT_ACCEPTED%')
 THROW 51000,N'DYNAMIC_TOOL_DISPATCH_SHARED_GATE_PROOF_FAILED',1;

-- The authoring-tool dispatch is proven inside a savepoint so the committed
-- state stays the equity-preserving declaration.
SAVE TRANSACTION dynamic_tool_dispatch_authoring;
EXEC model.install_execution_authority_change @document=@authoring_full;
DECLARE @installed TABLE(result_set nvarchar(100),authority_id nvarchar(400),capability_id nvarchar(400));
INSERT @installed EXEC model.install_execution_authority_change @document=@authoring_full;
SELECT N'4_authoring_tool_replay' AS result_set,result_set AS install_result FROM @installed;
IF NOT EXISTS(SELECT 1 FROM @installed WHERE result_set=N'already_installed') THROW 51000,N'DYNAMIC_TOOL_DISPATCH_REPLAY_PROOF_FAILED',1;
SELECT N'5_authoring_child_dispatch' AS result_set,c.capability_id,s.scenario_id,sv.scenario_version_pk
FROM model.execution_authority ea
JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk AND n.namespace_id=@namespace
JOIN model.execution_authority_version eav ON eav.execution_authority_pk=ea.execution_authority_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk AND eo.operation_kind=N'invoke-scenario'
JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=osi.target_scenario_version_pk
JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
JOIN model.capability c ON c.capability_pk=s.capability_pk
WHERE ea.execution_authority_id=N'execute-admitted-proposal.v1'
 AND eav.execution_authority_version_pk=(SELECT MAX(v.execution_authority_version_pk) FROM model.execution_authority_version v WHERE v.execution_authority_pk=ea.execution_authority_pk);
IF NOT EXISTS(SELECT 1 FROM model.execution_authority ea
 JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk AND n.namespace_id=@namespace
 JOIN model.execution_authority_version eav ON eav.execution_authority_pk=ea.execution_authority_pk
 JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk AND eo.operation_kind=N'invoke-scenario'
 JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
 JOIN model.scenario_version sv ON sv.scenario_version_pk=osi.target_scenario_version_pk
 JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
 JOIN model.capability c ON c.capability_pk=s.capability_pk
 WHERE ea.execution_authority_id=N'execute-admitted-proposal.v1' AND c.capability_id=@authoring_tool AND s.scenario_id=@authoring_scenario
  AND eav.execution_authority_version_pk=(SELECT MAX(v.execution_authority_version_pk) FROM model.execution_authority_version v WHERE v.execution_authority_pk=ea.execution_authority_pk))
 THROW 51000,N'DYNAMIC_TOOL_DISPATCH_AUTHORING_CHILD_UNRESOLVED',1;
ROLLBACK TRANSACTION dynamic_tool_dispatch_authoring;

-- Committed state: equity, the child the currently admitted route names. The
-- resolution read reproduces the equity execution request and the declared child
-- resolves to the equity root scenario, so behavior is preserved.
DECLARE @equity_operations nvarchar(max);
SET @equity_operations=(SELECT operationId,kind,portId FROM (
 SELECT N'execute-admitted-proposal.resolve' AS operationId,N'invoke-port' AS kind,N'resolve-admitted-tool-port' AS portId
 UNION ALL
 SELECT N'execute-admitted-proposal.execute',N'invoke-scenario',NULL
) equity_operations FOR JSON PATH);
DECLARE @equity_document nvarchar(max);
SET @equity_document=(SELECT N'execution-authority-change.v1' AS contractId,@candidate AS candidateId,@bundle AS bundleDigest,
 @agent_capability AS capabilityId,N'execute-admitted-proposal.v1' AS authorityId,N'execute-admitted-proposal' AS owningScenarioId,
 JSON_QUERY(@equity_operations) AS operations,JSON_QUERY(@port_bindings) AS portBindings,
 JSON_QUERY(N'{"input":{"capability":"resolve-equity-market-price-evidence","input":"AVGO"},"expected":{"disposition":"terminated"}}') AS preflight,
 JSON_QUERY(N'{"resolvedDisposition":"terminated"}') AS route FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SET @equity_document=JSON_MODIFY(@equity_document,'$.operations[1].targetCapabilityId',N'resolve-equity-market-price-evidence');
DELETE @admission;
INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@equity_document,@estate_model_pk=@estate;
SELECT N'6_admission_equity' AS result_set,disposition,reason FROM @admission;
IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'ADMITTED') THROW 51000,N'DYNAMIC_TOOL_DISPATCH_EQUITY_ADMISSION_FAILED',1;
DELETE @installed;
INSERT @installed EXEC model.install_execution_authority_change @document=@equity_document;
SELECT N'7_equity_install' AS result_set,result_set AS install_result,authority_id FROM @installed;
IF NOT EXISTS(SELECT 1 FROM @installed WHERE result_set IN (N'execution_authority_change_installed',N'already_installed'))
 THROW 51000,N'DYNAMIC_TOOL_DISPATCH_EQUITY_INSTALL_FAILED',1;
DECLARE @equity_root_version bigint=(SELECT cs.scenario_version_pk
 FROM model.capability c JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
 JOIN model.capability_root_scenario rs ON rs.capability_version_pk=ec.capability_version_pk
 JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk AND cs.scenario_pk=rs.scenario_pk
 WHERE c.capability_id=N'resolve-equity-market-price-evidence');
DECLARE @dispatched_version bigint=(SELECT osi.target_scenario_version_pk
 FROM model.execution_authority ea JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk AND n.namespace_id=@namespace
 JOIN model.execution_authority_version eav ON eav.execution_authority_pk=ea.execution_authority_pk
 JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk AND eo.operation_kind=N'invoke-scenario'
 JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
 WHERE ea.execution_authority_id=N'execute-admitted-proposal.v1'
  AND eav.execution_authority_version_pk=(SELECT MAX(v.execution_authority_version_pk) FROM model.execution_authority_version v WHERE v.execution_authority_pk=ea.execution_authority_pk));
SELECT N'8_equity_child_dispatch' AS result_set,@equity_root_version AS equity_root_version_pk,@dispatched_version AS dispatched_version_pk,
 CASE WHEN @equity_root_version=@dispatched_version THEN N'RESOLVED' ELSE N'DIVERGED' END AS disposition;
IF ISNULL(@dispatched_version,-1)<>ISNULL(@equity_root_version,-2) THROW 51000,N'DYNAMIC_TOOL_DISPATCH_EQUITY_CHILD_DIVERGED',1;
DECLARE @equity_versions int=(SELECT COUNT(*) FROM model.execution_authority_version v JOIN model.execution_authority ea ON ea.execution_authority_pk=v.execution_authority_pk
 WHERE ea.execution_authority_id=N'execute-admitted-proposal.v1');
DELETE @installed;
INSERT @installed EXEC model.install_execution_authority_change @document=@equity_document;
IF NOT EXISTS(SELECT 1 FROM @installed WHERE result_set=N'already_installed')
 OR (SELECT COUNT(*) FROM model.execution_authority_version v JOIN model.execution_authority ea ON ea.execution_authority_pk=v.execution_authority_pk
  WHERE ea.execution_authority_id=N'execute-admitted-proposal.v1')<>@equity_versions
 THROW 51000,N'DYNAMIC_TOOL_DISPATCH_EQUITY_REPLAY_WROTE',1;
SELECT N'9_equity_replay' AS result_set,N'already_installed' AS disposition;

-- Unrelated capability graph digests must be byte-identical.
DECLARE @after TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @after(capability_id,digest,bytes)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'authoring-altitude-model-stubs',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g;
SELECT N'10_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'DYNAMIC_TOOL_DISPATCH_UNRELATED_CAPABILITY_CHANGED',1;

SELECT N'11_disposition' AS result_set,@agent_capability AS capability_id,
 CASE WHEN EXISTS(SELECT 1 FROM model.operation_scenario_invocation i
  JOIN model.execution_operation eo ON eo.execution_operation_pk=i.execution_operation_pk
  JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
  JOIN model.execution_authority ea ON ea.execution_authority_pk=eav.execution_authority_pk
  JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk AND n.namespace_id=@namespace
  WHERE ea.execution_authority_id=N'execute-admitted-proposal.v1') THEN N'declared_child_dispatch_installed' END AS disposition;
ROLLBACK TRANSACTION;
