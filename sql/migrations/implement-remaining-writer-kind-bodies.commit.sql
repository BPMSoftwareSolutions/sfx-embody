-- implement-remaining-writer-kind-bodies.sql
--
-- Lane W4b (remaining kinds): replace the refuse-by-default bodies of the five
-- remaining authoring writer kinds with real admission predicates and installer
-- bodies, per
-- docs/model-at-each-authoring-altitude-2026-09-21/candidate-admit-pipeline.md
-- B.2 kinds 2-6, and the writer-kind fill-in rows of
-- docs/authoring-altitude-model-stubs-2026-09-21/stub-fill-checklist.md 2.1.
-- The capability-authoring kind (kind 1) is already implemented by
-- implement-capability-authoring-change.sql; this file does not touch its read,
-- contracts or procedure. No installs are performed here.
--
-- Kinds and bodies (all reuse existing procedures; every receipt is an AUTHORITY
-- definition under sidefx:capability:<capabilityId>):
--   contract-change            -> model.declare_contract per contract, optional
--                                 scenario face re-points (INPUT/OUTCOME),
--                                 receipt <capabilityId>.contract-change.v1
--   scenario-authoring         -> model.declare_scenario + model.add_example
--                                 fixtures, receipt <scenarioId>.authored.v1
--   transformation-change      -> put_semantic_definition 'TRANSFORMATION' +
--                                 normalize_transformation_expression, optional
--                                 add_mechanic, receipt <transformationId>.authored.v1
--   execution-authority-change -> optional model.declare_scenario carrier, the
--                                 composed-authority mint (execution_authority_version
--                                 + execution_operation + operation_port_invocation /
--                                 operation_scenario_invocation + scenario_event
--                                 re-point), optional model.bind_provider,
--                                 receipt <authorityId>.authored.v1. Naming is the
--                                 skeleton's: the dynamic-dispatch/placement lane
--                                 (implement-model-placement-procedures.sql) owns the
--                                 placement procedures and model.declare_scenario /
--                                 model.bind_provider; this file supplies the body
--                                 only and introduces no new writer names.
--   feature-binding-change     -> model.declare_capability_feature, receipt
--                                 <capabilityId>.feature.v1
--
-- Admission predicates (the admit-*-change reads are replaced): each validates its
-- change contract, answers HELD with named findings on malformed input, and embeds
-- the accepted-candidate gate (CANDIDATE_ACCEPTANCE_REQUIRED / CANDIDATE_NOT_ACCEPTED)
-- exactly as declare-accepted-candidate-gate.sql appended it. Installers assert the
-- same gate (THROW CANDIDATE_ACCEPTANCE_REQUIRED / CANDIDATE_NOT_ACCEPTED), assert
-- the transaction and contractId, are digest-replay idempotent (already_installed),
-- refuse revisions that do not carry the revision marker (or an exact-digest
-- receipt), and write only their declared tables.
--
-- Boot authority (same selected sda-kernel-boot-data-access.v1): the five admission
-- read statements and the ten payload/installed contracts are revised. The re-mint
-- asserts structural prerequisites rather than an exact prior content digest,
-- because the accepted-candidate-gate and capability-authoring lanes may have
-- re-minted the same authority first; replay is detected from the revised reads and
-- contracts themselves.
--
-- Install order (the executor lane owns installs): declare-authoring-writer-kinds-skeleton
-- -> declare-accepted-candidate-gate -> implement-capability-authoring-change ->
-- this file. Replays are safe in any later order because both the re-mint and the
-- CREATE OR ALTER procedures are idempotent.
--
-- Idempotent: CREATE OR ALTER is re-runnable; the authority is re-minted only once;
-- a replay prints already_declared.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=300000;
IF @lock<0 THROW 51000,N'REMAINING_WRITER_KINDS_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
CREATE OR ALTER PROCEDURE model.install_contract_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'CONTRACT_CHANGE_TRANSACTION_REQUIRED',1;
 IF @document IS NULL OR ISJSON(@document)<>1 OR ISNULL(JSON_VALUE(@document,'$.contractId'),N'')<>N'contract-change.v1'
  THROW 51000,'CONTRACT_CHANGE_DOCUMENT_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.capabilityId'),N'');
 IF @capability_id IS NULL THROW 51000,'CONTRACT_CHANGE_CAPABILITY_REQUIRED',1;
 IF NOT EXISTS(SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
  WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capability_id)
  THROW 51000,'CONTRACT_CHANGE_CAPABILITY_NOT_DECLARED',1;
 DECLARE @candidate_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.candidateId'),N'');
 DECLARE @bundle_digest nvarchar(100)=NULLIF(JSON_VALUE(@document,'$.bundleDigest'),N'');
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
 DECLARE @contracts nvarchar(max)=JSON_QUERY(@document,'$.contracts');
 IF @contracts IS NULL OR ISJSON(@contracts)<>1 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@contracts))
  THROW 51000,'CONTRACT_CHANGE_CONTRACTS_REQUIRED',1;
 DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;
 DECLARE @receipt_id nvarchar(400)=@capability_id+N'.contract-change.v1';
 DECLARE @document_digest varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
  CONVERT(varbinary(max),CONVERT(varchar(max),@contracts COLLATE Latin1_General_100_BIN2_UTF8))),2));
 IF EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@receipt_id COLLATE Latin1_General_100_BIN2
   AND JSON_VALUE(d.definition_json,'$.semantics.documentDigest')=@document_digest)
 BEGIN
  SELECT N'already_installed' AS result_set,@capability_id AS capability_id,@receipt_id AS contract_id;
  RETURN;
 END
 DECLARE @id nvarchar(400),@schema nvarchar(max),@first_id nvarchar(400)=NULL;
 DECLARE contract_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT JSON_VALUE(value,'$.id'),JSON_QUERY(value,'$.schema') FROM OPENJSON(@contracts);
 OPEN contract_cursor;
 FETCH NEXT FROM contract_cursor INTO @id,@schema;
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF @id IS NULL OR @schema IS NULL OR ISJSON(@schema)<>1 THROW 51000,'CONTRACT_CHANGE_CONTRACT_INCOMPLETE',1;
  IF @first_id IS NULL SET @first_id=@id;
  EXEC model.declare_contract @id=@id,@schema=@schema;
  FETCH NEXT FROM contract_cursor INTO @id,@schema;
 END
 CLOSE contract_cursor; DEALLOCATE contract_cursor;
 DECLARE @bindings nvarchar(max)=JSON_QUERY(@document,'$.bindings');
 IF @bindings IS NOT NULL AND ISJSON(@bindings)=1
 BEGIN
  DECLARE @b_scenario nvarchar(400),@b_face nvarchar(20),@b_contract nvarchar(400),@b_cv bigint,@b_sv bigint;
  DECLARE binding_cursor CURSOR LOCAL FAST_FORWARD FOR
   SELECT JSON_VALUE(value,'$.scenarioId'),UPPER(JSON_VALUE(value,'$.face')),JSON_VALUE(value,'$.contractId') FROM OPENJSON(@bindings);
  OPEN binding_cursor;
  FETCH NEXT FROM binding_cursor INTO @b_scenario,@b_face,@b_contract;
  WHILE @@FETCH_STATUS=0
  BEGIN
   IF @b_face NOT IN (N'INPUT',N'OUTCOME') THROW 51000,'CONTRACT_CHANGE_FACE_INVALID',1;
   SET @b_cv=NULL;
   SELECT @b_cv=cv.contract_version_pk FROM model.contract ct
    JOIN model.identity_namespace n ON n.namespace_pk=ct.namespace_pk AND n.namespace_id=N'sidefx:contracts'
    JOIN model.contract_version cv ON cv.contract_pk=ct.contract_pk
    JOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=cv.semantic_object_definition_pk AND d.estate_model_pk=@estate
    WHERE ct.contract_id=@b_contract;
   IF @b_cv IS NULL THROW 51000,'CONTRACT_CHANGE_BINDING_UNRESOLVED',1;
   SET @b_sv=NULL;
   SELECT @b_sv=cs.scenario_version_pk FROM model.scenario s
    JOIN model.capability c ON c.capability_pk=s.capability_pk
    JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
    JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
    JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk AND cs.scenario_pk=s.scenario_pk
    WHERE c.capability_id=@capability_id AND s.scenario_id=@b_scenario;
   IF @b_sv IS NULL THROW 51000,'CONTRACT_CHANGE_BINDING_SCENARIO_NOT_FOUND',1;
   IF @b_face=N'INPUT' UPDATE model.scenario_input SET input_contract_version_pk=@b_cv WHERE scenario_version_pk=@b_sv AND ISNULL(input_contract_version_pk,0)<>@b_cv;
   ELSE UPDATE model.scenario_outcome_contract SET contract_version_pk=@b_cv WHERE scenario_version_pk=@b_sv AND ISNULL(contract_version_pk,0)<>@b_cv;
   FETCH NEXT FROM binding_cursor INTO @b_scenario,@b_face,@b_contract;
  END
  CLOSE binding_cursor; DEALLOCATE binding_cursor;
 END
 DECLARE @receipt nvarchar(max)=(SELECT JSON_QUERY(@document) AS document,@document_digest AS documentDigest,
  @candidate_id AS candidateId,@bundle_digest AS bundleDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @object bigint,@definition bigint,@definition_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',@namespace,@receipt_id,@receipt,@object OUTPUT,@definition OUTPUT,@definition_digest OUTPUT;
 SELECT N'contract_change_installed' AS result_set,@capability_id AS capability_id,ISNULL(@first_id,N'') AS contract_id;
END;
GO
CREATE OR ALTER PROCEDURE model.install_scenario_authoring_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'SCENARIO_AUTHORING_TRANSACTION_REQUIRED',1;
 IF @document IS NULL OR ISJSON(@document)<>1 OR ISNULL(JSON_VALUE(@document,'$.contractId'),N'')<>N'scenario-authoring-change.v1'
  THROW 51000,'SCENARIO_AUTHORING_DOCUMENT_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.capabilityId'),N'');
 IF @capability_id IS NULL THROW 51000,'SCENARIO_AUTHORING_CAPABILITY_REQUIRED',1;
 IF NOT EXISTS(SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
  WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capability_id)
  THROW 51000,'SCENARIO_AUTHORING_CAPABILITY_NOT_DECLARED',1;
 DECLARE @candidate_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.candidateId'),N'');
 DECLARE @bundle_digest nvarchar(100)=NULLIF(JSON_VALUE(@document,'$.bundleDigest'),N'');
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
 DECLARE @scenario nvarchar(max)=JSON_QUERY(@document,'$.scenario');
 DECLARE @scenario_id nvarchar(400)=NULLIF(JSON_VALUE(@scenario,'$.scenarioId'),N'');
 IF @scenario IS NULL OR ISJSON(@scenario)<>1 OR @scenario_id IS NULL THROW 51000,'SCENARIO_AUTHORING_SCENARIO_REQUIRED',1;
 DECLARE @operations nvarchar(max)=JSON_QUERY(@document,'$.operations');
 IF @operations IS NULL OR ISJSON(@operations)<>1 THROW 51000,'SCENARIO_AUTHORING_OPERATIONS_REQUIRED',1;
 DECLARE @port_bindings nvarchar(max)=JSON_QUERY(@document,'$.portBindings');
 IF @port_bindings IS NULL OR ISJSON(@port_bindings)<>1 THROW 51000,'SCENARIO_AUTHORING_PORT_BINDINGS_REQUIRED',1;
 DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;
 DECLARE @receipt_id nvarchar(400)=@scenario_id+N'.authored.v1';
 DECLARE @document_digest varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
  CONVERT(varbinary(max),CONVERT(varchar(max),@scenario COLLATE Latin1_General_100_BIN2_UTF8))),2));
 DECLARE @prior_digest varchar(64)=(SELECT JSON_VALUE(definition_json,'$.semantics.documentDigest')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@receipt_id COLLATE Latin1_General_100_BIN2);
 IF @prior_digest=@document_digest
 BEGIN
  SELECT N'already_installed' AS result_set,@capability_id AS capability_id,@scenario_id AS scenario_id;
  RETURN;
 END
 IF ISNULL(JSON_VALUE(@document,'$.revision'),N'false')<>N'true'
  AND (@prior_digest IS NOT NULL OR EXISTS(SELECT 1 FROM model.scenario s JOIN model.capability c ON c.capability_pk=s.capability_pk
   JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
   WHERE c.capability_id=@capability_id AND s.scenario_id=@scenario_id))
  THROW 51000,'SCENARIO_AUTHORING_REVISION_NOT_ADMITTED',1;
 DECLARE @declared TABLE(declared_scenario nvarchar(400),scenario_version_pk bigint);
 INSERT @declared EXEC model.declare_scenario @capability_id=@capability_id,@scenario=@scenario,
  @operations=@operations,@port_bindings=@port_bindings;
 IF NOT EXISTS(SELECT 1 FROM @declared) THROW 51000,'SCENARIO_AUTHORING_NOT_DECLARED',1;
 DECLARE @fixtures nvarchar(max)=JSON_QUERY(@document,'$.fixtures');
 IF @fixtures IS NOT NULL AND ISJSON(@fixtures)=1
 BEGIN
  DECLARE @fixture nvarchar(max),@fixture_id nvarchar(400),@fixture_input nvarchar(max),@fixture_expected nvarchar(max);
  DECLARE @fixture_result TABLE(action nvarchar(50),capability_id nvarchar(120),fixture_id nvarchar(400),definition_after bigint,expected_value nvarchar(max));
  DECLARE fixture_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT value FROM OPENJSON(@fixtures);
  OPEN fixture_cursor;
  FETCH NEXT FROM fixture_cursor INTO @fixture;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @fixture_id=JSON_VALUE(@fixture,'$.fixtureId');
   SET @fixture_input=JSON_QUERY(@fixture,'$.input');
   SET @fixture_expected=JSON_QUERY(@fixture,'$.expected');
   IF @fixture_id IS NULL OR @fixture_input IS NULL OR @fixture_expected IS NULL THROW 51000,'SCENARIO_AUTHORING_FIXTURE_INCOMPLETE',1;
   IF @fixture_id<>@scenario_id AND @fixture_id NOT LIKE @scenario_id+N'.%' THROW 51000,'SCENARIO_AUTHORING_FIXTURE_NOT_OWNED',1;
   INSERT @fixture_result EXEC model.add_example @capability_id=@capability_id,@fixture_id=@fixture_id,
    @input_json=@fixture_input,@expected_json=@fixture_expected;
   FETCH NEXT FROM fixture_cursor INTO @fixture;
  END
  CLOSE fixture_cursor; DEALLOCATE fixture_cursor;
 END
 DECLARE @receipt nvarchar(max)=(SELECT JSON_QUERY(@document) AS document,@document_digest AS documentDigest,
  @candidate_id AS candidateId,@bundle_digest AS bundleDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @object bigint,@definition bigint,@definition_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',@namespace,@receipt_id,@receipt,@object OUTPUT,@definition OUTPUT,@definition_digest OUTPUT;
 SELECT N'scenario_authoring_installed' AS result_set,@capability_id AS capability_id,@scenario_id AS scenario_id;
END;
GO
CREATE OR ALTER PROCEDURE model.install_transformation_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'TRANSFORMATION_CHANGE_TRANSACTION_REQUIRED',1;
 IF @document IS NULL OR ISJSON(@document)<>1 OR ISNULL(JSON_VALUE(@document,'$.contractId'),N'')<>N'transformation-change.v1'
  THROW 51000,'TRANSFORMATION_CHANGE_DOCUMENT_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.capabilityId'),N'');
 IF @capability_id IS NULL THROW 51000,'TRANSFORMATION_CHANGE_CAPABILITY_REQUIRED',1;
 IF NOT EXISTS(SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
  WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capability_id)
  THROW 51000,'TRANSFORMATION_CHANGE_CAPABILITY_NOT_DECLARED',1;
 DECLARE @candidate_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.candidateId'),N'');
 DECLARE @bundle_digest nvarchar(100)=NULLIF(JSON_VALUE(@document,'$.bundleDigest'),N'');
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
 DECLARE @transformation_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.transformationId'),N'');
 IF @transformation_id IS NULL THROW 51000,'TRANSFORMATION_CHANGE_TRANSFORMATION_REQUIRED',1;
 DECLARE @expression nvarchar(max)=JSON_QUERY(@document,'$.expression');
 IF @expression IS NULL OR ISJSON(@expression)<>1 THROW 51000,'TRANSFORMATION_CHANGE_EXPRESSION_REQUIRED',1;
 DECLARE @namespace nvarchar(400)=ISNULL(NULLIF(JSON_VALUE(@document,'$.namespace'),N''),N'sidefx:capability:'+@capability_id);
 DECLARE @receipt_id nvarchar(400)=@transformation_id+N'.authored.v1';
 DECLARE @document_digest varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
  CONVERT(varbinary(max),CONVERT(varchar(max),@expression COLLATE Latin1_General_100_BIN2_UTF8))),2));
 DECLARE @prior_digest varchar(64)=(SELECT JSON_VALUE(definition_json,'$.semantics.documentDigest')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@receipt_id COLLATE Latin1_General_100_BIN2);
 IF @prior_digest=@document_digest
 BEGIN
  SELECT N'already_installed' AS result_set,@transformation_id AS transformation_id,CONVERT(bigint,0) AS transformation_version_pk;
  RETURN;
 END
 IF ISNULL(JSON_VALUE(@document,'$.revision'),N'false')<>N'true'
  AND (@prior_digest IS NOT NULL OR EXISTS(SELECT 1 FROM model.transformation t JOIN model.identity_namespace n ON n.namespace_pk=t.namespace_pk
   WHERE n.namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND t.transformation_id=@transformation_id COLLATE Latin1_General_100_BIN2))
  THROW 51000,'TRANSFORMATION_CHANGE_REVISION_NOT_ADMITTED',1;
 DECLARE @semantics nvarchar(max)=(SELECT @transformation_id AS id,JSON_QUERY(@expression) AS expression FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @object bigint,@definition bigint,@digest binary(32),@transformation bigint,@version bigint;
 EXEC model.put_semantic_definition 'TRANSFORMATION',@namespace,@transformation_id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 SET @transformation=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@object);
 IF @transformation IS NULL
 BEGIN
  INSERT model.transformation(namespace_pk,transformation_id,semantic_object_pk,object_kind)
   SELECT namespace_pk,@transformation_id,@object,'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk=@object;
  SET @transformation=SCOPE_IDENTITY();
 END
 SET @version=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@definition);
 IF @version IS NULL
 BEGIN
  INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
   expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@transformation,@object,@definition,@digest,'json-expression-tree.v1','TRANSFORMATION',@definition,N'');
  SET @version=SCOPE_IDENTITY();
 END
 EXEC model.normalize_transformation_expression @transformation_version_pk=@version;
 DECLARE @mechanic nvarchar(max)=JSON_QUERY(@document,'$.mechanic');
 IF @mechanic IS NOT NULL AND ISJSON(@mechanic)=1
 BEGIN
  DECLARE @mechanic_id nvarchar(400)=NULLIF(JSON_VALUE(@mechanic,'$.mechanicId'),N'');
  DECLARE @output_field nvarchar(400)=NULLIF(JSON_VALUE(@mechanic,'$.outputField'),N'');
  DECLARE @mechanic_mode nvarchar(20)=ISNULL(NULLIF(JSON_VALUE(@mechanic,'$.mode'),N''),N'REUSE');
  IF @mechanic_id IS NULL OR @output_field IS NULL THROW 51000,'TRANSFORMATION_CHANGE_MECHANIC_INCOMPLETE',1;
  DECLARE @mechanic_result TABLE(action nvarchar(50),capability_id nvarchar(120),mechanic_id nvarchar(400),mode nvarchar(20),
   output_field nvarchar(400),execution_position int,operation nvarchar(400),definition_after bigint,transformation_version_pk bigint);
  DECLARE @mechanic_arguments nvarchar(max)=JSON_QUERY(@mechanic,'$.arguments');
  INSERT @mechanic_result EXEC model.add_mechanic @capability_id=@capability_id,@mechanic_id=@mechanic_id,@mode=@mechanic_mode,
   @arguments_json=@mechanic_arguments,@output_field=@output_field;
 END
 DECLARE @receipt nvarchar(max)=(SELECT JSON_QUERY(@document) AS document,@document_digest AS documentDigest,
  @candidate_id AS candidateId,@bundle_digest AS bundleDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC model.put_semantic_definition 'AUTHORITY',@namespace,@receipt_id,@receipt,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 SELECT N'transformation_change_installed' AS result_set,@transformation_id AS transformation_id,@version AS transformation_version_pk;
END;
GO
CREATE OR ALTER PROCEDURE model.install_execution_authority_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'EXECUTION_AUTHORITY_CHANGE_TRANSACTION_REQUIRED',1;
 IF @document IS NULL OR ISJSON(@document)<>1 OR ISNULL(JSON_VALUE(@document,'$.contractId'),N'')<>N'execution-authority-change.v1'
  THROW 51000,'EXECUTION_AUTHORITY_CHANGE_DOCUMENT_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.capabilityId'),N'');
 IF @capability_id IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_CAPABILITY_REQUIRED',1;
 IF NOT EXISTS(SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
  WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capability_id)
  THROW 51000,'EXECUTION_AUTHORITY_CHANGE_CAPABILITY_NOT_DECLARED',1;
 DECLARE @candidate_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.candidateId'),N'');
 DECLARE @bundle_digest nvarchar(100)=NULLIF(JSON_VALUE(@document,'$.bundleDigest'),N'');
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
 DECLARE @authority_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.authorityId'),N'');
 IF @authority_id IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_AUTHORITY_REQUIRED',1;
 DECLARE @owning_scenario_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.owningScenarioId'),N'');
 IF @owning_scenario_id IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_SCENARIO_REQUIRED',1;
 DECLARE @operations nvarchar(max)=JSON_QUERY(@document,'$.operations');
 IF @operations IS NULL OR ISJSON(@operations)<>1 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@operations))
  THROW 51000,'EXECUTION_AUTHORITY_CHANGE_OPERATIONS_REQUIRED',1;
 DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;
 DECLARE @receipt_id nvarchar(400)=@authority_id+N'.authored.v1';
 DECLARE @document_digest varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
  CONVERT(varbinary(max),CONVERT(varchar(max),@operations COLLATE Latin1_General_100_BIN2_UTF8))),2));
 DECLARE @prior_digest varchar(64)=(SELECT JSON_VALUE(definition_json,'$.semantics.documentDigest')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@receipt_id COLLATE Latin1_General_100_BIN2);
 IF @prior_digest=@document_digest
 BEGIN
  SELECT N'already_installed' AS result_set,@authority_id AS authority_id,CONVERT(bigint,0) AS authority_version_pk;
  RETURN;
 END
 DECLARE @authority_preexisted bit=CASE WHEN EXISTS(SELECT 1 FROM model.execution_authority ea
  JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk
  WHERE n.namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND ea.execution_authority_id=@authority_id COLLATE Latin1_General_100_BIN2) THEN 1 ELSE 0 END;
 IF ISNULL(JSON_VALUE(@document,'$.revision'),N'false')<>N'true'
  AND (@prior_digest IS NOT NULL OR @authority_preexisted=1)
  THROW 51000,'EXECUTION_AUTHORITY_CHANGE_REVISION_NOT_ADMITTED',1;
 DECLARE @scenario nvarchar(max)=JSON_QUERY(@document,'$.scenario');
 IF @scenario IS NOT NULL AND ISJSON(@scenario)=1 AND NULLIF(JSON_VALUE(@scenario,'$.scenarioId'),N'') IS NOT NULL
 BEGIN
  DECLARE @scenario_ops nvarchar(max)=JSON_QUERY(@scenario,'$.operations');
  DECLARE @scenario_bindings nvarchar(max)=JSON_QUERY(@scenario,'$.portBindings');
  IF @scenario_ops IS NULL OR ISJSON(@scenario_ops)<>1 THROW 51000,'EXECUTION_AUTHORITY_CHANGE_SCENARIO_OPERATIONS_REQUIRED',1;
  IF @scenario_bindings IS NULL OR ISJSON(@scenario_bindings)<>1 THROW 51000,'EXECUTION_AUTHORITY_CHANGE_SCENARIO_BINDINGS_REQUIRED',1;
  DECLARE @declared TABLE(declared_scenario nvarchar(400),scenario_version_pk bigint);
  INSERT @declared EXEC model.declare_scenario @capability_id=@capability_id,@scenario=@scenario,
   @operations=@scenario_ops,@port_bindings=@scenario_bindings;
  IF NOT EXISTS(SELECT 1 FROM @declared) THROW 51000,'EXECUTION_AUTHORITY_CHANGE_SCENARIO_NOT_DECLARED',1;
 END
 DECLARE @ea_pk bigint,@ea_so bigint;
 SELECT @ea_pk=ea.execution_authority_pk,@ea_so=ea.semantic_object_pk
 FROM model.execution_authority ea JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk
 WHERE n.namespace_id=@namespace AND ea.execution_authority_id=@authority_id;
 IF @ea_pk IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_AUTHORITY_NOT_FOUND',1;
 DECLARE @semantics nvarchar(max)=(SELECT @authority_id AS [authority.id],@owning_scenario_id AS [authority.owningScenarioId],
  JSON_QUERY(@operations) AS [authority.operations] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @envelope nvarchar(max)=N'{"address":{"id":"'+STRING_ESCAPE(@authority_id,'json')+N'","kind":"EXECUTION_AUTHORITY","namespace":"'
  +STRING_ESCAPE(@namespace,'json')+N'"},"format":"sidefx-semantic-definition.v1","semantics":'+@semantics+N'}';
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@envelope COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @digest binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@digest,@bytes,DATALENGTH(@bytes));
 IF NOT EXISTS(SELECT 1 FROM model.semantic_object_definition WHERE semantic_object_pk=@ea_so AND definition_digest=@digest)
  INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk)
   VALUES(@ea_so,'EXECUTION_AUTHORITY',@digest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest));
 DECLARE @auth_sod bigint=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition
  WHERE semantic_object_pk=@ea_so AND definition_digest=@digest);
 IF NOT EXISTS(SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@estate AND semantic_object_definition_pk=@auth_sod)
  INSERT model.estate_definition(estate_model_pk,semantic_object_definition_pk) VALUES(@estate,@auth_sod);
 DECLARE @authority_version bigint=(SELECT MAX(execution_authority_version_pk) FROM model.execution_authority_version
  WHERE execution_authority_pk=@ea_pk AND definition_digest=@digest);
 IF @authority_version IS NULL
 BEGIN
  INSERT model.execution_authority_version(execution_authority_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
   authority_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@ea_pk,@ea_so,@auth_sod,@digest,'execution-authorities.v1','EXECUTION_AUTHORITY',@auth_sod,N'');
  SET @authority_version=SCOPE_IDENTITY();
  INSERT model.execution_operation(execution_authority_version_pk,operation_id,ordinal,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT @authority_version,JSON_VALUE(o.value,'$.operationId'),CONVERT(int,o.[key]),JSON_VALUE(o.value,'$.kind'),@auth_sod,
    N'/semantics/authority/operations/'+o.[key] FROM OPENJSON(@operations) o;
  INSERT model.operation_port_invocation(execution_operation_pk,port_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT eo.execution_operation_pk,pv.port_version_pk,'invoke-port',@auth_sod,eo._canonical_pointer
   FROM model.execution_operation eo
   JOIN OPENJSON(@operations) o ON CONVERT(int,o.[key])=eo.ordinal
   JOIN model.port p ON p.port_id=JSON_VALUE(o.value,'$.portId')
   JOIN model.identity_namespace pn ON pn.namespace_pk=p.namespace_pk AND pn.namespace_id=@namespace
   JOIN model.port_version pv ON pv.port_pk=p.port_pk
    AND pv.port_version_pk=(SELECT MAX(pv2.port_version_pk) FROM model.port_version pv2 WHERE pv2.port_pk=p.port_pk)
   WHERE eo.execution_authority_version_pk=@authority_version AND ISNULL(JSON_VALUE(o.value,'$.kind'),N'')=N'invoke-port';
  INSERT model.operation_scenario_invocation(execution_operation_pk,target_scenario_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT eo.execution_operation_pk,target.scenario_version_pk,'invoke-scenario',@auth_sod,eo._canonical_pointer
   FROM model.execution_operation eo
   JOIN OPENJSON(@operations) o ON CONVERT(int,o.[key])=eo.ordinal
   JOIN model.scenario s ON s.scenario_id=JSON_VALUE(o.value,'$.targetScenarioId')
   JOIN model.capability_scenario target ON target.scenario_pk=s.scenario_pk
   JOIN model.estate_capability tec ON tec.capability_pk=target.capability_pk AND tec.estate_model_pk=@estate
    AND tec.capability_version_pk=target.capability_version_pk
   WHERE eo.execution_authority_version_pk=@authority_version AND ISNULL(JSON_VALUE(o.value,'$.kind'),N'')=N'invoke-scenario';
  IF EXISTS(SELECT 1 FROM model.execution_operation eo
   WHERE eo.execution_authority_version_pk=@authority_version
    AND ((eo.operation_kind=N'invoke-port' AND NOT EXISTS(SELECT 1 FROM model.operation_port_invocation i WHERE i.execution_operation_pk=eo.execution_operation_pk))
     OR (eo.operation_kind=N'invoke-scenario' AND NOT EXISTS(SELECT 1 FROM model.operation_scenario_invocation si WHERE si.execution_operation_pk=eo.execution_operation_pk))
     OR eo.operation_kind NOT IN (N'invoke-port',N'invoke-scenario')))
   THROW 51000,'EXECUTION_AUTHORITY_CHANGE_OPERATION_BINDING_NOT_DECLARED',1;
 END
 DECLARE @owning_version bigint;
 SELECT @owning_version=cs.scenario_version_pk FROM model.scenario s
  JOIN model.capability c ON c.capability_pk=s.capability_pk
  JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
  JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
  JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk AND cs.scenario_pk=s.scenario_pk
  WHERE c.capability_id=@capability_id AND s.scenario_id=@owning_scenario_id;
 IF @owning_version IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_SCENARIO_NOT_FOUND',1;
 UPDATE model.scenario_event SET execution_authority_version_pk=@authority_version WHERE scenario_version_pk=@owning_version;
 DECLARE @provider_bindings nvarchar(max)=JSON_QUERY(@document,'$.providerBindings');
 IF @provider_bindings IS NOT NULL AND ISJSON(@provider_bindings)=1
 BEGIN
  DECLARE @b_mechanic nvarchar(400),@b_provider nvarchar(400),@b_platform nvarchar(400),@b_config nvarchar(max);
  DECLARE @bind_result TABLE(action nvarchar(50),capability_id nvarchar(120),mechanic_id nvarchar(400),provider_id nvarchar(400),
   platform_capability_id nvarchar(400),definition_after bigint,port_version_pk bigint);
  DECLARE provider_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT JSON_VALUE(value,'$.mechanicId'),JSON_VALUE(value,'$.providerId'),
   JSON_VALUE(value,'$.platformCapabilityId'),JSON_QUERY(value,'$.configuration') FROM OPENJSON(@provider_bindings);
  OPEN provider_cursor;
  FETCH NEXT FROM provider_cursor INTO @b_mechanic,@b_provider,@b_platform,@b_config;
  WHILE @@FETCH_STATUS=0
  BEGIN
   IF @b_mechanic IS NULL OR @b_provider IS NULL THROW 51000,'EXECUTION_AUTHORITY_CHANGE_PROVIDER_BINDING_INCOMPLETE',1;
   INSERT @bind_result EXEC model.bind_provider @capability_id=@capability_id,@mechanic_id=@b_mechanic,@provider_id=@b_provider,
    @platform_capability_id=@b_platform,@configuration_json=@b_config;
   FETCH NEXT FROM provider_cursor INTO @b_mechanic,@b_provider,@b_platform,@b_config;
  END
  CLOSE provider_cursor; DEALLOCATE provider_cursor;
 END
 DECLARE @receipt nvarchar(max)=(SELECT JSON_QUERY(@document) AS document,@document_digest AS documentDigest,
  @candidate_id AS candidateId,@bundle_digest AS bundleDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @object bigint,@definition bigint,@definition_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',@namespace,@receipt_id,@receipt,@object OUTPUT,@definition OUTPUT,@definition_digest OUTPUT;
 SELECT N'execution_authority_change_installed' AS result_set,@authority_id AS authority_id,@authority_version AS authority_version_pk;
END;
GO
CREATE OR ALTER PROCEDURE model.install_feature_binding_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'FEATURE_BINDING_TRANSACTION_REQUIRED',1;
 IF @document IS NULL OR ISJSON(@document)<>1 OR ISNULL(JSON_VALUE(@document,'$.contractId'),N'')<>N'feature-binding-change.v1'
  THROW 51000,'FEATURE_BINDING_DOCUMENT_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.capabilityId'),N'');
 IF @capability_id IS NULL THROW 51000,'FEATURE_BINDING_CAPABILITY_REQUIRED',1;
 IF NOT EXISTS(SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
  WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capability_id)
  THROW 51000,'FEATURE_BINDING_CAPABILITY_NOT_DECLARED',1;
 DECLARE @candidate_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.candidateId'),N'');
 DECLARE @bundle_digest nvarchar(100)=NULLIF(JSON_VALUE(@document,'$.bundleDigest'),N'');
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
 DECLARE @feature nvarchar(max)=JSON_QUERY(@document,'$.feature');
 DECLARE @feature_text nvarchar(max)=CASE WHEN @feature IS NOT NULL THEN JSON_VALUE(@feature,'$.text') END;
 IF NULLIF(@feature_text,N'') IS NULL THROW 51000,'FEATURE_BINDING_TEXT_REQUIRED',1;
 DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;
 DECLARE @receipt_id nvarchar(400)=@capability_id+N'.feature.v1';
 DECLARE @document_digest varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
  CONVERT(varbinary(max),CONVERT(varchar(max),@feature_text COLLATE Latin1_General_100_BIN2_UTF8))),2));
 DECLARE @prior_digest varchar(64)=(SELECT JSON_VALUE(definition_json,'$.semantics.documentDigest')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@receipt_id COLLATE Latin1_General_100_BIN2);
 IF @prior_digest=@document_digest
 BEGIN
  SELECT N'already_installed' AS result_set,@capability_id AS capability_id,CONVERT(bigint,0) AS feature_version_pk;
  RETURN;
 END
 IF ISNULL(JSON_VALUE(@document,'$.revision'),N'false')<>N'true'
  AND (@prior_digest IS NOT NULL OR EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
   WHERE d.estate_model_pk=@estate AND d.object_kind=N'FEATURE' AND d.namespace_id=N'sidefx:features'
    AND d.declared_id=@capability_id COLLATE Latin1_General_100_BIN2))
  THROW 51000,'FEATURE_BINDING_REVISION_NOT_ADMITTED',1;
 EXEC model.declare_capability_feature @capability_id=@capability_id,@feature_text=@feature_text;
 DECLARE @feature_version bigint=(SELECT MAX(fv.feature_version_pk) FROM model.feature f
  JOIN model.feature_version fv ON fv.feature_pk=f.feature_pk WHERE f.feature_id=@capability_id);
 DECLARE @receipt nvarchar(max)=(SELECT JSON_QUERY(@document) AS document,@document_digest AS documentDigest,
  @candidate_id AS candidateId,@bundle_digest AS bundleDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @object bigint,@definition bigint,@definition_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',@namespace,@receipt_id,@receipt,@object OUTPUT,@definition OUTPUT,@definition_digest OUTPUT;
 SELECT N'feature_binding_installed' AS result_set,@capability_id AS capability_id,ISNULL(@feature_version,0) AS feature_version_pk;
END;
GO
-- ============================== AUTHORITY REVISION ==============================
-- Same selected sda-kernel-boot-data-access.v1: replace the five remaining
-- admission read statements and their ten payload/installed contracts. The
-- re-mint asserts a structural prerequisite set and detects replay from the
-- revised statement markers and contract members.
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @selected nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
IF @selected IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_NOT_SELECTED',1;
DECLARE @body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@selected,N'sha256:',N''),2));
IF @body IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_BODY_MISSING',1;
IF JSON_VALUE(@body,'$.authorityId')<>@authority_id THROW 51000,N'KERNEL_BOOT_AUTHORITY_IDENTITY_DIVERGED',1;
DECLARE @required_kinds TABLE(kind nvarchar(200) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @required_kinds(kind) VALUES
 (N'capability-authoring'),(N'contract-change'),(N'scenario-authoring'),
 (N'transformation-change'),(N'execution-authority-change'),(N'feature-binding-change');
DECLARE @required_reads TABLE(read_id nvarchar(200) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @required_reads(read_id) VALUES
 (N'admit-contract-change'),(N'admit-scenario-authoring-change'),(N'admit-transformation-change'),
 (N'admit-execution-authority-change'),(N'admit-feature-binding-change');
DECLARE @required_contracts TABLE(contract_id nvarchar(200) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @required_contracts(contract_id) VALUES
 (N'contract-change.v1'),(N'contract-change-installed.v1'),
 (N'scenario-authoring-change.v1'),(N'scenario-authoring-change-installed.v1'),
 (N'transformation-change.v1'),(N'transformation-change-installed.v1'),
 (N'execution-authority-change.v1'),(N'execution-authority-change-installed.v1'),
 (N'feature-binding-change.v1'),(N'feature-binding-change-installed.v1');
IF (SELECT COUNT(*) FROM @required_kinds k WHERE EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=k.kind))<>6
 OR (SELECT COUNT(*) FROM @required_reads r WHERE EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=r.read_id))<>5
 OR (SELECT COUNT(*) FROM @required_contracts c WHERE EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key] COLLATE Latin1_General_100_BIN2 = c.contract_id))<>10
 THROW 51000,N'KERNEL_BOOT_AUTHORITY_CHANGED_REBASE_DECLARATION',1;

DECLARE @admission_head nvarchar(max)=N'DECLARE @findings TABLE(ordinal int IDENTITY(1,1),code nvarchar(100),field nvarchar(400),message nvarchar(2000));
IF ISJSON(@input)<>1 OR JSON_QUERY(@input) IS NULL
 INSERT @findings(code,field,message) VALUES(N''{{P}}_DOCUMENT_REQUIRED'',NULL,N''the change must be a JSON object'');
ELSE BEGIN
';
DECLARE @admission_gate nvarchar(max)=N'DECLARE @candidate_gate_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.candidateId''),N'''');
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
';
DECLARE @admission_tail nvarchar(max)=N'END
DECLARE @reason nvarchar(max)=ISNULL((SELECT code,field,message FROM @findings ORDER BY ordinal FOR JSON PATH),N''[]'');
SELECT CASE WHEN (SELECT COUNT(*) FROM @findings)=0 THEN N''ADMITTED'' ELSE N''HELD'' END AS disposition,LEFT(@reason,400) AS reason';
DECLARE @new_reads TABLE(ordinal int PRIMARY KEY,read_id nvarchar(200) COLLATE Latin1_General_100_BIN2,entry nvarchar(max));
DECLARE @check_contract nvarchar(max)=N'DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.capabilityId''),N'''');
DECLARE @contracts nvarchar(max)=JSON_QUERY(@input,''$.contracts'');
IF ISNULL(JSON_VALUE(@input,''$.contractId''),N'''')<>N''contract-change.v1''
 INSERT @findings(code,field,message) VALUES(N''CONTRACT_CHANGE_CONTRACT_REQUIRED'',N''contractId'',N''contractId must be contract-change.v1'');
IF @capability_id IS NULL
 INSERT @findings(code,field,message) VALUES(N''CONTRACT_CHANGE_CAPABILITY_REQUIRED'',N''capabilityId'',N''the change must name the capability whose contracts it authors'');
ELSE IF NOT EXISTS(SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate_model_pk
 WHERE n.namespace_id=N''sidefx:capabilities'' AND c.capability_id=@capability_id)
 INSERT @findings(code,field,message) VALUES(N''CONTRACT_CHANGE_CAPABILITY_NOT_DECLARED'',N''capabilityId'',N''the capability is not selected in this estate model'');
IF @contracts IS NULL OR ISJSON(@contracts)<>1
 INSERT @findings(code,field,message) VALUES(N''CONTRACT_CHANGE_CONTRACTS_REQUIRED'',N''contracts'',N''the change must declare at least one contract'');
ELSE BEGIN
 IF NOT EXISTS(SELECT 1 FROM OPENJSON(@contracts))
  INSERT @findings(code,field,message) VALUES(N''CONTRACT_CHANGE_CONTRACTS_REQUIRED'',N''contracts'',N''the change must declare at least one contract'');
 IF EXISTS(SELECT 1 FROM OPENJSON(@contracts) c WHERE JSON_VALUE(c.value,''$.id'') IS NULL
  OR JSON_QUERY(c.value,''$.schema'') IS NULL OR LEFT(LTRIM(JSON_QUERY(c.value,''$.schema'')),1)<>N''{'')
  INSERT @findings(code,field,message) VALUES(N''CONTRACT_CHANGE_CONTRACT_INCOMPLETE'',N''contracts'',N''every contract needs an id and an object schema'');
 ELSE BEGIN
  IF EXISTS(SELECT 1 FROM OPENJSON(@contracts) c WHERE JSON_VALUE(JSON_QUERY(c.value,''$.schema''),''$."$id"'') IS NULL)
   INSERT @findings(code,field,message) VALUES(N''CONTRACT_CHANGE_SCHEMA_NOT_SELF_DESCRIBED'',N''contracts.schema'',N''every schema must carry $id'');
  IF EXISTS(SELECT 1 FROM OPENJSON(@contracts) c
   CROSS APPLY OPENJSON(JSON_QUERY(c.value,''$.schema''),''$.required'') r
   WHERE NOT EXISTS(SELECT 1 FROM OPENJSON(JSON_QUERY(c.value,''$.schema''),''$.properties'') p WHERE p.[key]=r.value))
   INSERT @findings(code,field,message) VALUES(N''CONTRACT_CHANGE_SCHEMA_REQUIRED_PROPERTY_MISSING'',N''contracts.schema.required'',N''every required property must exist in properties'');
  IF EXISTS(SELECT 1 FROM (SELECT JSON_VALUE(c.value,''$.id'') AS id,
    HASHBYTES(''SHA2_256'',CONVERT(varbinary(max),CONVERT(varchar(max),JSON_QUERY(c.value,''$.schema'') COLLATE Latin1_General_100_BIN2_UTF8))) AS schema_hash
    FROM OPENJSON(@contracts) c) d GROUP BY d.id HAVING COUNT(DISTINCT d.schema_hash)>1)
   INSERT @findings(code,field,message) VALUES(N''CONTRACT_CHANGE_DUPLICATE_CONTRACT'',N''contracts'',N''the same contract id is declared with two different schemas'');
  IF ISNULL(JSON_VALUE(@input,''$.revision''),N''false'')<>N''true'' AND EXISTS(SELECT 1 FROM OPENJSON(@contracts) c
   JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate_model_pk AND d.object_kind=N''CONTRACT''
    AND d.namespace_id=N''sidefx:contracts'' AND d.declared_id=JSON_VALUE(c.value,''$.id'') COLLATE Latin1_General_100_BIN2
   WHERE ISNULL(JSON_VALUE(d.definition_json,''$.semantics.schema_digest''),N'''')<>LOWER(CONVERT(varchar(64),HASHBYTES(''SHA2_256'',
    CONVERT(varbinary(max),CONVERT(varchar(max),JSON_QUERY(c.value,''$.schema'') COLLATE Latin1_General_100_BIN2_UTF8))),2)))
   INSERT @findings(code,field,message) VALUES(N''CONTRACT_CHANGE_REVISION_NOT_ADMITTED'',N''contracts'',N''an existing contract changes schema without the revision marker'');
 END
END
DECLARE @bindings nvarchar(max)=JSON_QUERY(@input,''$.bindings'');
IF @bindings IS NOT NULL AND ISJSON(@bindings)=1 AND EXISTS(
 SELECT 1 FROM OPENJSON(@bindings) b
 WHERE JSON_VALUE(b.value,''$.scenarioId'') IS NULL OR UPPER(ISNULL(JSON_VALUE(b.value,''$.face''),N'''')) NOT IN (N''INPUT'',N''OUTCOME'')
  OR JSON_VALUE(b.value,''$.contractId'') IS NULL)
 INSERT @findings(code,field,message) VALUES(N''CONTRACT_CHANGE_BINDING_INVALID'',N''bindings'',N''every binding needs scenarioId, face INPUT|OUTCOME and contractId'');';
DECLARE @check_scenario nvarchar(max)=N'DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.capabilityId''),N'''');
DECLARE @scenario nvarchar(max)=JSON_QUERY(@input,''$.scenario'');
DECLARE @scenario_id nvarchar(400)=NULLIF(JSON_VALUE(@scenario,''$.scenarioId''),N'''');
IF ISNULL(JSON_VALUE(@input,''$.contractId''),N'''')<>N''scenario-authoring-change.v1''
 INSERT @findings(code,field,message) VALUES(N''SCENARIO_AUTHORING_CONTRACT_REQUIRED'',N''contractId'',N''contractId must be scenario-authoring-change.v1'');
IF @capability_id IS NULL
 INSERT @findings(code,field,message) VALUES(N''SCENARIO_AUTHORING_CAPABILITY_REQUIRED'',N''capabilityId'',N''the change must name the capability that owns the scenario'');
ELSE IF NOT EXISTS(SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate_model_pk
 WHERE n.namespace_id=N''sidefx:capabilities'' AND c.capability_id=@capability_id)
 INSERT @findings(code,field,message) VALUES(N''SCENARIO_AUTHORING_CAPABILITY_NOT_DECLARED'',N''capabilityId'',N''the capability is not selected in this estate model'');
IF @scenario IS NULL OR ISJSON(@scenario)<>1 OR @scenario_id IS NULL
 INSERT @findings(code,field,message) VALUES(N''SCENARIO_AUTHORING_SCENARIO_REQUIRED'',N''scenario'',N''the change must carry the scenario face document with a scenarioId'');
ELSE BEGIN
 IF ISNULL(JSON_VALUE(@scenario,''$.eventAuthority''),N'''')<>@scenario_id+N''.v1''
  INSERT @findings(code,field,message) VALUES(N''SCENARIO_AUTHORING_EVENT_AUTHORITY_INVALID'',N''scenario.eventAuthority'',N''eventAuthority must be <scenarioId>.v1'');
 IF NULLIF(JSON_VALUE(@scenario,''$.inputContract''),N'''') IS NULL OR NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''CONTRACT'' AND d.namespace_id=N''sidefx:contracts''
   AND d.declared_id=JSON_VALUE(@scenario,''$.inputContract'') COLLATE Latin1_General_100_BIN2)
  INSERT @findings(code,field,message) VALUES(N''SCENARIO_AUTHORING_CONTRACT_NOT_DECLARED'',N''scenario.inputContract'',N''the scenario input contract must be selected'');
 IF NULLIF(JSON_VALUE(@scenario,''$.outcomeContract''),N'''') IS NULL OR NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''CONTRACT'' AND d.namespace_id=N''sidefx:contracts''
   AND d.declared_id=JSON_VALUE(@scenario,''$.outcomeContract'') COLLATE Latin1_General_100_BIN2)
  INSERT @findings(code,field,message) VALUES(N''SCENARIO_AUTHORING_CONTRACT_NOT_DECLARED'',N''scenario.outcomeContract'',N''the scenario outcome contract must be selected'');
 IF ISNULL(JSON_VALUE(@input,''$.revision''),N''false'')<>N''true'' AND EXISTS(
  SELECT 1 FROM model.scenario s JOIN model.capability c ON c.capability_pk=s.capability_pk
  JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N''sidefx:capabilities''
  JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate_model_pk
  WHERE c.capability_id=@capability_id AND s.scenario_id=@scenario_id)
  INSERT @findings(code,field,message) VALUES(N''SCENARIO_AUTHORING_REVISION_NOT_ADMITTED'',N''scenario.scenarioId'',N''the scenario id is already owned; an authorized revision is required'');
END
DECLARE @operations nvarchar(max)=JSON_QUERY(@input,''$.operations'');
IF @operations IS NULL OR ISJSON(@operations)<>1
 INSERT @findings(code,field,message) VALUES(N''SCENARIO_AUTHORING_OPERATIONS_REQUIRED'',N''operations'',N''the change must carry the operation list'');
ELSE BEGIN
 IF EXISTS(SELECT 1 FROM OPENJSON(@operations) o WHERE ISNULL(JSON_VALUE(o.value,''$.kind''),N'''')<>N''invoke-port'')
  INSERT @findings(code,field,message) VALUES(N''SCENARIO_AUTHORING_OPERATION_KIND_UNSUPPORTED'',N''operations'',N''declare_scenario supports invoke-port operations only; invoke-scenario belongs to execution-authority-change'');
 IF EXISTS(SELECT 1 FROM OPENJSON(@operations) o WHERE ISNULL(JSON_VALUE(o.value,''$.kind''),N'''')=N''invoke-port''
  AND (SELECT COUNT(*) FROM OPENJSON(ISNULL(JSON_QUERY(@input,''$.portBindings''),N''[]'')) b
   WHERE JSON_VALUE(b.value,''$.portId'')=JSON_VALUE(o.value,''$.portId''))<>1)
  INSERT @findings(code,field,message) VALUES(N''SCENARIO_AUTHORING_OPERATION_BINDING_NOT_DECLARED'',N''operations'',N''every invoke-port operation needs exactly one portBindings entry'');
END
DECLARE @fixtures nvarchar(max)=JSON_QUERY(@input,''$.fixtures'');
IF @fixtures IS NOT NULL AND ISJSON(@fixtures)=1 AND EXISTS(SELECT 1 FROM OPENJSON(@fixtures) f
 WHERE NOT (JSON_VALUE(f.value,''$.fixtureId'')=@scenario_id OR JSON_VALUE(f.value,''$.fixtureId'') LIKE @scenario_id+N''.%''))
 INSERT @findings(code,field,message) VALUES(N''SCENARIO_AUTHORING_FIXTURE_NOT_OWNED'',N''fixtures'',N''every fixtureId must be the scenarioId or under it'');';
INSERT @new_reads(ordinal,read_id,entry) VALUES
 (1,N'admit-contract-change',(SELECT N'admit-contract-change' AS readId,
   N'Validate a contract-change.v1 document: capability selected, contracts present and uniquely identified, schemas self-described and internally consistent, no schema revision without the revision marker, bindings well formed, and the ACCEPTED candidate gate. Returns exactly one ADMITTED or HELD row; writes nothing.' AS purpose,
   N'observation' AS classification,N'tsql' AS sourceKind,
   REPLACE(@admission_head,N'{{P}}',N'CONTRACT_CHANGE')+@check_contract+@admission_gate+@admission_tail AS statement,
   JSON_QUERY(N'[{"parameter":"estate_model_pk","kind":"pinned-session"}]') AS parameters
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)),
 (2,N'admit-scenario-authoring-change',(SELECT N'admit-scenario-authoring-change' AS readId,
   N'Validate a scenario-authoring-change.v1 document: capability selected, scenario faces present, eventAuthority <scenarioId>.v1, contracts selected, every operation an invoke-port with exactly one binding, fixture ids owned by the scenario, revision authorized, and the ACCEPTED candidate gate. Returns exactly one ADMITTED or HELD row; writes nothing.' AS purpose,
   N'observation' AS classification,N'tsql' AS sourceKind,
   REPLACE(@admission_head,N'{{P}}',N'SCENARIO_AUTHORING')+@check_scenario+@admission_gate+@admission_tail AS statement,
   JSON_QUERY(N'[{"parameter":"estate_model_pk","kind":"pinned-session"}]') AS parameters
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER));
DECLARE @check_transformation nvarchar(max)=N'DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.capabilityId''),N'''');
DECLARE @transformation_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.transformationId''),N'''');
DECLARE @expression nvarchar(max)=JSON_QUERY(@input,''$.expression'');
IF ISNULL(JSON_VALUE(@input,''$.contractId''),N'''')<>N''transformation-change.v1''
 INSERT @findings(code,field,message) VALUES(N''TRANSFORMATION_CHANGE_CONTRACT_REQUIRED'',N''contractId'',N''contractId must be transformation-change.v1'');
IF @capability_id IS NULL
 INSERT @findings(code,field,message) VALUES(N''TRANSFORMATION_CHANGE_CAPABILITY_REQUIRED'',N''capabilityId'',N''the change must name the capability that owns the transformation'');
ELSE IF NOT EXISTS(SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate_model_pk
 WHERE n.namespace_id=N''sidefx:capabilities'' AND c.capability_id=@capability_id)
 INSERT @findings(code,field,message) VALUES(N''TRANSFORMATION_CHANGE_CAPABILITY_NOT_DECLARED'',N''capabilityId'',N''the capability is not selected in this estate model'');
IF @transformation_id IS NULL
 INSERT @findings(code,field,message) VALUES(N''TRANSFORMATION_CHANGE_TRANSFORMATION_REQUIRED'',N''transformationId'',N''the change must name the transformation it authors'');
IF @expression IS NULL OR ISJSON(@expression)<>1 OR LEFT(LTRIM(@expression),1) NOT IN (N''{'',N''['')
 INSERT @findings(code,field,message) VALUES(N''TRANSFORMATION_CHANGE_EXPRESSION_REQUIRED'',N''expression'',N''the change must carry a JSON expression tree'');
ELSE IF LEFT(LTRIM(@expression),1)=N''{'' AND JSON_QUERY(@expression,''$.root'') IS NULL AND JSON_QUERY(@expression,''$.fields'') IS NULL AND JSON_QUERY(@expression,''$.op'') IS NULL
 INSERT @findings(code,field,message) VALUES(N''TRANSFORMATION_CHANGE_EXPRESSION_INVALID'',N''expression'',N''a root object must carry root, fields or op'');
IF @transformation_id IS NOT NULL AND ISNULL(JSON_VALUE(@input,''$.revision''),N''false'')<>N''true'' AND EXISTS(
 SELECT 1 FROM model.transformation t JOIN model.identity_namespace n ON n.namespace_pk=t.namespace_pk
 WHERE n.namespace_id=N''sidefx:capability:''+@capability_id AND t.transformation_id=@transformation_id)
 INSERT @findings(code,field,message) VALUES(N''TRANSFORMATION_CHANGE_REVISION_NOT_ADMITTED'',N''transformationId'',N''the transformation id already exists; an authorized revision is required'');
IF NULLIF(JSON_VALUE(@input,''$.inputContract''),N'''') IS NOT NULL AND NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''CONTRACT'' AND d.namespace_id=N''sidefx:contracts''
  AND d.declared_id=JSON_VALUE(@input,''$.inputContract'') COLLATE Latin1_General_100_BIN2)
 INSERT @findings(code,field,message) VALUES(N''TRANSFORMATION_CHANGE_CONTRACT_NOT_DECLARED'',N''inputContract'',N''the named input contract must be selected'');
IF NULLIF(JSON_VALUE(@input,''$.outcomeContract''),N'''') IS NOT NULL AND NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''CONTRACT'' AND d.namespace_id=N''sidefx:contracts''
  AND d.declared_id=JSON_VALUE(@input,''$.outcomeContract'') COLLATE Latin1_General_100_BIN2)
 INSERT @findings(code,field,message) VALUES(N''TRANSFORMATION_CHANGE_CONTRACT_NOT_DECLARED'',N''outcomeContract'',N''the named outcome contract must be selected'');
DECLARE @mechanic nvarchar(max)=JSON_QUERY(@input,''$.mechanic'');
IF @mechanic IS NOT NULL AND (NULLIF(JSON_VALUE(@mechanic,''$.mechanicId''),N'''') IS NULL OR NULLIF(JSON_VALUE(@mechanic,''$.outputField''),N'''') IS NULL)
 INSERT @findings(code,field,message) VALUES(N''TRANSFORMATION_CHANGE_MECHANIC_INCOMPLETE'',N''mechanic'',N''an attached mechanic needs mechanicId and outputField'');';
DECLARE @check_execution nvarchar(max)=N'DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.capabilityId''),N'''');
DECLARE @authority_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.authorityId''),N'''');
DECLARE @owning_scenario_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.owningScenarioId''),N'''');
DECLARE @operations nvarchar(max)=JSON_QUERY(@input,''$.operations'');
IF ISNULL(JSON_VALUE(@input,''$.contractId''),N'''')<>N''execution-authority-change.v1''
 INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_CONTRACT_REQUIRED'',N''contractId'',N''contractId must be execution-authority-change.v1'');
IF @capability_id IS NULL
 INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_CAPABILITY_REQUIRED'',N''capabilityId'',N''the change must name the capability that owns the authority'');
ELSE IF NOT EXISTS(SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate_model_pk
 WHERE n.namespace_id=N''sidefx:capabilities'' AND c.capability_id=@capability_id)
 INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_CAPABILITY_NOT_DECLARED'',N''capabilityId'',N''the capability is not selected in this estate model'');
IF @authority_id IS NULL
 INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_AUTHORITY_REQUIRED'',N''authorityId'',N''the change must name the execution authority it authors'');
IF @owning_scenario_id IS NULL
 INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_SCENARIO_REQUIRED'',N''owningScenarioId'',N''the change must name the scenario the authority belongs to'');
IF @operations IS NULL OR ISJSON(@operations)<>1 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@operations))
 INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_OPERATIONS_REQUIRED'',N''operations'',N''the change must carry at least one operation'');
ELSE BEGIN
 IF EXISTS(SELECT 1 FROM OPENJSON(@operations) o WHERE ISNULL(JSON_VALUE(o.value,''$.kind''),N'''') NOT IN (N''invoke-port'',N''invoke-scenario''))
  INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_OPERATION_KIND_INVALID'',N''operations'',N''operation kind must be invoke-port or invoke-scenario'');
 IF EXISTS(SELECT 1 FROM OPENJSON(@operations) o WHERE ISNULL(JSON_VALUE(o.value,''$.kind''),N'''')=N''invoke-port''
  AND NOT EXISTS(SELECT 1 FROM model.port p JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
   WHERE n.namespace_id=N''sidefx:capability:''+@capability_id AND p.port_id=JSON_VALUE(o.value,''$.portId''))
  AND (SELECT COUNT(*) FROM (
    SELECT JSON_VALUE(value,''$.portId'') AS port_id FROM OPENJSON(ISNULL(JSON_QUERY(@input,''$.portBindings''),N''[]''))
    UNION ALL
    SELECT JSON_VALUE(value,''$.portId'') FROM OPENJSON(ISNULL(JSON_QUERY(@input,''$.scenario.portBindings''),N''[]''))) b
   WHERE b.port_id=JSON_VALUE(o.value,''$.portId''))=0)
  INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_PORT_NOT_RESOLVED'',N''operations'',N''every invoke-port operation needs a declared port or a binding entry'');
 IF EXISTS(SELECT 1 FROM OPENJSON(@operations) o WHERE ISNULL(JSON_VALUE(o.value,''$.kind''),N'''')=N''invoke-scenario''
  AND NOT EXISTS(SELECT 1 FROM model.scenario s
   JOIN model.capability_scenario cs ON cs.scenario_pk=s.scenario_pk
   JOIN model.estate_capability ec ON ec.capability_pk=s.capability_pk AND ec.estate_model_pk=@estate_model_pk
    AND ec.capability_version_pk=cs.capability_version_pk
   WHERE s.scenario_id=JSON_VALUE(o.value,''$.targetScenarioId'')))
  INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_TARGET_SCENARIO_NOT_DECLARED'',N''operations'',N''every invoke-scenario target must be a selected scenario'');
END
IF EXISTS(SELECT 1 FROM (
  SELECT JSON_VALUE(value,''$.platformCapabilityId'') AS platform_id FROM OPENJSON(ISNULL(JSON_QUERY(@input,''$.portBindings''),N''[]''))
  UNION ALL
  SELECT JSON_VALUE(value,''$.platformCapabilityId'') FROM OPENJSON(ISNULL(JSON_QUERY(@input,''$.scenario.portBindings''),N''[]''))) b
 WHERE NULLIF(b.platform_id,N'''') IS NULL)
 INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_PLATFORM_CAPABILITY_REQUIRED'',N''portBindings'',N''every port binding must name the platform capability it implements'');
IF EXISTS(SELECT 1 FROM (
  SELECT JSON_VALUE(value,''$.platformCapabilityId'') AS platform_id FROM OPENJSON(ISNULL(JSON_QUERY(@input,''$.portBindings''),N''[]''))
  UNION ALL
  SELECT JSON_VALUE(value,''$.platformCapabilityId'') FROM OPENJSON(ISNULL(JSON_QUERY(@input,''$.scenario.portBindings''),N''[]''))) b
 WHERE NULLIF(b.platform_id,N'''') IS NOT NULL AND NOT EXISTS(SELECT 1 FROM model.capability pc
  JOIN model.identity_namespace pn ON pn.namespace_pk=pc.namespace_pk
  WHERE pn.namespace_id=N''sidefx:platform-capabilities'' AND pc.capability_id=b.platform_id))
 INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_PLATFORM_CAPABILITY_NOT_DECLARED'',N''portBindings'',N''every named platform capability must be declared'');
IF @authority_id IS NOT NULL AND ISNULL(JSON_VALUE(@input,''$.revision''),N''false'')<>N''true'' AND EXISTS(
 SELECT 1 FROM model.execution_authority ea JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk
 WHERE n.namespace_id=N''sidefx:capability:''+@capability_id AND ea.execution_authority_id=@authority_id)
 INSERT @findings(code,field,message) VALUES(N''EXECUTION_AUTHORITY_CHANGE_REVISION_NOT_ADMITTED'',N''authorityId'',N''the authority already exists; an authorized revision is required'');';
DECLARE @check_feature nvarchar(max)=N'DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.capabilityId''),N'''');
DECLARE @feature_text nvarchar(max)=JSON_VALUE(@input,''$.feature.text'');
IF ISNULL(JSON_VALUE(@input,''$.contractId''),N'''')<>N''feature-binding-change.v1''
 INSERT @findings(code,field,message) VALUES(N''FEATURE_BINDING_CONTRACT_REQUIRED'',N''contractId'',N''contractId must be feature-binding-change.v1'');
IF @capability_id IS NULL
 INSERT @findings(code,field,message) VALUES(N''FEATURE_BINDING_CAPABILITY_REQUIRED'',N''capabilityId'',N''the change must name the capability whose feature bytes it pins'');
ELSE IF NOT EXISTS(SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate_model_pk
 WHERE n.namespace_id=N''sidefx:capabilities'' AND c.capability_id=@capability_id)
 INSERT @findings(code,field,message) VALUES(N''FEATURE_BINDING_CAPABILITY_NOT_DECLARED'',N''capabilityId'',N''the capability is not selected in this estate model'');
IF NULLIF(@feature_text,N'''') IS NULL
 INSERT @findings(code,field,message) VALUES(N''FEATURE_BINDING_TEXT_REQUIRED'',N''feature.text'',N''the change must carry the feature bytes'');
ELSE BEGIN
 IF CHARINDEX(NCHAR(65533),@feature_text)>0
  INSERT @findings(code,field,message) VALUES(N''FEATURE_BINDING_TEXT_INVALID'',N''feature.text'',N''the feature bytes must decode without replacement characters'');
 DECLARE @tag_line nvarchar(4000),@tag_value nvarchar(400);
 DECLARE feature_tag_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT LTRIM(RTRIM(REPLACE(value,CHAR(13),N''''))) FROM STRING_SPLIT(@feature_text,CHAR(10))
  WHERE LTRIM(RTRIM(REPLACE(value,CHAR(13),N''''))) LIKE N''@%'';
 OPEN feature_tag_cursor;
 FETCH NEXT FROM feature_tag_cursor INTO @tag_line;
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF @tag_line LIKE N''@capability:%''
  BEGIN
   SET @tag_value=LTRIM(RTRIM(SUBSTRING(@tag_line,LEN(N''@capability:'')+1,4000)));
   IF @tag_value<>@capability_id
    INSERT @findings(code,field,message) VALUES(N''FEATURE_BINDING_CAPABILITY_TAG_MISMATCH'',N''feature.text'',N''the @capability tag must equal capabilityId'');
  END
  IF @tag_line LIKE N''@scenario:%''
  BEGIN
   SET @tag_value=LTRIM(RTRIM(SUBSTRING(@tag_line,LEN(N''@scenario:'')+1,4000)));
   IF NOT EXISTS(SELECT 1 FROM model.scenario s JOIN model.capability c ON c.capability_pk=s.capability_pk
    JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N''sidefx:capabilities''
    WHERE c.capability_id=@capability_id AND s.scenario_id=@tag_value)
    INSERT @findings(code,field,message) VALUES(N''FEATURE_BINDING_SCENARIO_NOT_OWNED'',N''feature.text'',N''every @scenario tag must name a scenario the capability owns'');
  END
  FETCH NEXT FROM feature_tag_cursor INTO @tag_line;
 END
 CLOSE feature_tag_cursor; DEALLOCATE feature_tag_cursor;
 IF EXISTS(SELECT 1 FROM OPENJSON(ISNULL(JSON_QUERY(@input,''$.pins''),N''[]'')) p
  WHERE NOT EXISTS(SELECT 1 FROM model.scenario s JOIN model.capability c ON c.capability_pk=s.capability_pk
   JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N''sidefx:capabilities''
   WHERE c.capability_id=@capability_id AND s.scenario_id=JSON_VALUE(p.value,''$.scenarioId'')))
  INSERT @findings(code,field,message) VALUES(N''FEATURE_BINDING_SCENARIO_NOT_OWNED'',N''pins'',N''every pin must name a scenario the capability owns'');
 IF ISNULL(JSON_VALUE(@input,''$.revision''),N''false'')<>N''true'' AND EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''FEATURE'' AND d.namespace_id=N''sidefx:features'' AND d.declared_id=@capability_id)
  AND NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition r
   WHERE r.estate_model_pk=@estate_model_pk AND r.object_kind=N''AUTHORITY'' AND r.namespace_id=N''sidefx:capability:''+@capability_id
    AND r.declared_id=@capability_id+N''.feature.v1''
    AND JSON_VALUE(r.definition_json,''$.semantics.documentDigest'')=LOWER(CONVERT(varchar(64),HASHBYTES(''SHA2_256'',
     CONVERT(varbinary(max),CONVERT(varchar(max),@feature_text COLLATE Latin1_General_100_BIN2_UTF8))),2)))
  INSERT @findings(code,field,message) VALUES(N''FEATURE_BINDING_REVISION_NOT_ADMITTED'',N''feature.text'',N''the capability feature is owned; an authorized revision is required'');
END
';
INSERT @new_reads(ordinal,read_id,entry) VALUES
 (3,N'admit-transformation-change',(SELECT N'admit-transformation-change' AS readId,
   N'Validate a transformation-change.v1 document: capability selected, transformation id named, a JSON expression tree present and rooted, contract references selected when named, mechanic attachment complete, revision authorized, and the ACCEPTED candidate gate. Returns exactly one ADMITTED or HELD row; writes nothing.' AS purpose,
   N'observation' AS classification,N'tsql' AS sourceKind,
   REPLACE(@admission_head,N'{{P}}',N'TRANSFORMATION_CHANGE')+@check_transformation+@admission_gate+@admission_tail AS statement,
   JSON_QUERY(N'[{"parameter":"estate_model_pk","kind":"pinned-session"}]') AS parameters
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)),
 (4,N'admit-execution-authority-change',(SELECT N'admit-execution-authority-change' AS readId,
   N'Validate an execution-authority-change.v1 document: capability selected, authority and owning scenario named, every operation an invoke-port resolved by a declared port or binding, or an invoke-scenario target selected in the estate, every port binding naming a declared platform capability, revision authorized, and the ACCEPTED candidate gate. Returns exactly one ADMITTED or HELD row; writes nothing.' AS purpose,
   N'observation' AS classification,N'tsql' AS sourceKind,
   REPLACE(@admission_head,N'{{P}}',N'EXECUTION_AUTHORITY_CHANGE')+@check_execution+@admission_gate+@admission_tail AS statement,
   JSON_QUERY(N'[{"parameter":"estate_model_pk","kind":"pinned-session"}]') AS parameters
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)),
 (5,N'admit-feature-binding-change',(SELECT N'admit-feature-binding-change' AS readId,
   N'Validate a feature-binding-change.v1 document: capability selected, feature bytes present and decodable, the @capability tag matching, every @scenario tag and pin naming a scenario the capability owns, revision authorized, and the ACCEPTED candidate gate. Returns exactly one ADMITTED or HELD row; writes nothing.' AS purpose,
   N'observation' AS classification,N'tsql' AS sourceKind,
   REPLACE(@admission_head,N'{{P}}',N'FEATURE_BINDING')+@check_feature+@admission_gate+@admission_tail AS statement,
   JSON_QUERY(N'[{"parameter":"estate_model_pk","kind":"pinned-session"}]') AS parameters
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER));
DECLARE @c_payload_contract nvarchar(max)=N'{"title":"Contract change","description":"One or more contracts declared or revised from a JSON Schema, with optional scenario face re-points, authorized by an ACCEPTED candidate.","type":"object","additionalProperties":false,"required":["contractId","candidateId","bundleDigest","capabilityId","contracts","preflight","route"],"properties":{"contractId":{"const":"contract-change.v1"},"candidateId":{"type":"string","minLength":1,"maxLength":400},"bundleDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"capabilityId":{"type":"string","minLength":1,"maxLength":400},"revision":{"type":"boolean"},"contracts":{"type":"array","minItems":1,"items":{"type":"object","additionalProperties":false,"required":["id","schema"],"properties":{"id":{"type":"string","minLength":1,"maxLength":400},"schema":{"type":"object"}}}},"bindings":{"type":"array","items":{"type":"object","additionalProperties":false,"required":["scenarioId","face","contractId"],"properties":{"scenarioId":{"type":"string","minLength":1,"maxLength":400},"face":{"enum":["INPUT","OUTCOME"]},"contractId":{"type":"string","minLength":1,"maxLength":400}}}},"preflight":{"type":"object","additionalProperties":false,"required":["input"],"properties":{"input":{"type":"object"},"expected":{"type":"object"}}},"route":{"type":"object","additionalProperties":false,"required":["resolvedDisposition"],"properties":{"resolvedDisposition":{"type":"string","minLength":1,"maxLength":100}}}}}';
DECLARE @c_installed_contract nvarchar(max)=N'{"title":"Contract change installed","description":"Executor recordsets envelope: contract_change_installed for a new install, already_installed for a digest-identical replay.","type":"array","minItems":1,"maxItems":1,"items":{"type":"array","minItems":1,"maxItems":1,"items":{"type":"object","additionalProperties":false,"required":["result_set","capability_id","contract_id"],"properties":{"result_set":{"enum":["contract_change_installed","already_installed"]},"capability_id":{"type":"string","minLength":1,"maxLength":400},"contract_id":{"type":"string","minLength":1,"maxLength":400}}}}}';
DECLARE @c_payload_scenario nvarchar(max)=N'{"title":"Scenario authoring change","description":"One scenario version with faces, operations and port bindings, optional fixtures, authorized by an ACCEPTED candidate.","type":"object","additionalProperties":false,"required":["contractId","candidateId","bundleDigest","capabilityId","scenario","operations","portBindings","preflight","route"],"properties":{"contractId":{"const":"scenario-authoring-change.v1"},"candidateId":{"type":"string","minLength":1,"maxLength":400},"bundleDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"capabilityId":{"type":"string","minLength":1,"maxLength":400},"revision":{"type":"boolean"},"scenario":{"type":"object"},"operations":{"type":"array"},"portBindings":{"type":"array"},"fixtures":{"type":"array"},"preflight":{"type":"object","additionalProperties":false,"required":["input"],"properties":{"input":{"type":"object"},"expected":{"type":"object"}}},"route":{"type":"object","additionalProperties":false,"required":["resolvedDisposition"],"properties":{"resolvedDisposition":{"type":"string","minLength":1,"maxLength":100}}}}}';
DECLARE @c_installed_scenario nvarchar(max)=N'{"title":"Scenario authoring change installed","description":"Executor recordsets envelope: scenario_authoring_installed for a new install, already_installed for a digest-identical replay.","type":"array","minItems":1,"maxItems":1,"items":{"type":"array","minItems":1,"maxItems":1,"items":{"type":"object","additionalProperties":false,"required":["result_set","capability_id","scenario_id"],"properties":{"result_set":{"enum":["scenario_authoring_installed","already_installed"]},"capability_id":{"type":"string","minLength":1,"maxLength":400},"scenario_id":{"type":"string","minLength":1,"maxLength":400}}}}}';
DECLARE @c_payload_transformation nvarchar(max)=N'{"title":"Transformation change","description":"One transformation expression tree put and normalized, optional mechanic attachment, authorized by an ACCEPTED candidate.","type":"object","additionalProperties":false,"required":["contractId","candidateId","bundleDigest","capabilityId","transformationId","expression","preflight","route"],"properties":{"contractId":{"const":"transformation-change.v1"},"candidateId":{"type":"string","minLength":1,"maxLength":400},"bundleDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"capabilityId":{"type":"string","minLength":1,"maxLength":400},"namespace":{"type":"string","minLength":1,"maxLength":400},"transformationId":{"type":"string","minLength":1,"maxLength":400},"revision":{"type":"boolean"},"expression":{"type":["object","array"]},"inputContract":{"type":"string","minLength":1,"maxLength":400},"outcomeContract":{"type":"string","minLength":1,"maxLength":400},"mechanic":{"type":"object","additionalProperties":false,"required":["mechanicId","outputField"],"properties":{"mechanicId":{"type":"string","minLength":1,"maxLength":400},"outputField":{"type":"string","minLength":1,"maxLength":400},"mode":{"enum":["REUSE","AUTHOR"]},"arguments":{"type":"object"}}},"preflight":{"type":"object","additionalProperties":false,"required":["input"],"properties":{"input":{"type":"object"},"expected":{"type":"object"}}},"route":{"type":"object","additionalProperties":false,"required":["resolvedDisposition"],"properties":{"resolvedDisposition":{"type":"string","minLength":1,"maxLength":100}}}}}';
DECLARE @c_installed_transformation nvarchar(max)=N'{"title":"Transformation change installed","description":"Executor recordsets envelope: transformation_change_installed for a new install, already_installed for a digest-identical replay.","type":"array","minItems":1,"maxItems":1,"items":{"type":"array","minItems":1,"maxItems":1,"items":{"type":"object","additionalProperties":false,"required":["result_set","transformation_id","transformation_version_pk"],"properties":{"result_set":{"enum":["transformation_change_installed","already_installed"]},"transformation_id":{"type":"string","minLength":1,"maxLength":400},"transformation_version_pk":{"type":"integer"}}}}}';
DECLARE @c_payload_execution nvarchar(max)=N'{"title":"Execution authority change","description":"An execution authority version minted from ordered operations and port bindings, with optional scenario carrier and provider bindings, authorized by an ACCEPTED candidate.","type":"object","additionalProperties":false,"required":["contractId","candidateId","bundleDigest","capabilityId","authorityId","owningScenarioId","operations","preflight","route"],"properties":{"contractId":{"const":"execution-authority-change.v1"},"candidateId":{"type":"string","minLength":1,"maxLength":400},"bundleDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"capabilityId":{"type":"string","minLength":1,"maxLength":400},"authorityId":{"type":"string","minLength":1,"maxLength":400},"owningScenarioId":{"type":"string","minLength":1,"maxLength":400},"revision":{"type":"boolean"},"operations":{"type":"array","minItems":1},"portBindings":{"type":"array"},"providerBindings":{"type":"array"},"scenario":{"type":"object"},"preflight":{"type":"object","additionalProperties":false,"required":["input"],"properties":{"input":{"type":"object"},"expected":{"type":"object"}}},"route":{"type":"object","additionalProperties":false,"required":["resolvedDisposition"],"properties":{"resolvedDisposition":{"type":"string","minLength":1,"maxLength":100}}}}}';
DECLARE @c_installed_execution nvarchar(max)=N'{"title":"Execution authority change installed","description":"Executor recordsets envelope: execution_authority_change_installed for a new install, already_installed for a digest-identical replay.","type":"array","minItems":1,"maxItems":1,"items":{"type":"array","minItems":1,"maxItems":1,"items":{"type":"object","additionalProperties":false,"required":["result_set","authority_id","authority_version_pk"],"properties":{"result_set":{"enum":["execution_authority_change_installed","already_installed"]},"authority_id":{"type":"string","minLength":1,"maxLength":400},"authority_version_pk":{"type":"integer"}}}}}';
DECLARE @c_payload_feature nvarchar(max)=N'{"title":"Feature binding change","description":"Feature bytes pinned to the capability and its already-declared scenarios, authorized by an ACCEPTED candidate.","type":"object","additionalProperties":false,"required":["contractId","candidateId","bundleDigest","capabilityId","feature","preflight","route"],"properties":{"contractId":{"const":"feature-binding-change.v1"},"candidateId":{"type":"string","minLength":1,"maxLength":400},"bundleDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"capabilityId":{"type":"string","minLength":1,"maxLength":400},"revision":{"type":"boolean"},"feature":{"type":"object","additionalProperties":false,"required":["text"],"properties":{"text":{"type":"string","minLength":1,"maxLength":1000000}}},"pins":{"type":"array"},"preflight":{"type":"object","additionalProperties":false,"required":["input"],"properties":{"input":{"type":"object"},"expected":{"type":"object"}}},"route":{"type":"object","additionalProperties":false,"required":["resolvedDisposition"],"properties":{"resolvedDisposition":{"type":"string","minLength":1,"maxLength":100}}}}}';
DECLARE @c_installed_feature nvarchar(max)=N'{"title":"Feature binding change installed","description":"Executor recordsets envelope: feature_binding_installed for a new install, already_installed for a digest-identical replay.","type":"array","minItems":1,"maxItems":1,"items":{"type":"array","minItems":1,"maxItems":1,"items":{"type":"object","additionalProperties":false,"required":["result_set","capability_id","feature_version_pk"],"properties":{"result_set":{"enum":["feature_binding_installed","already_installed"]},"capability_id":{"type":"string","minLength":1,"maxLength":400},"feature_version_pk":{"type":"integer"}}}}}"';
DECLARE @markers TABLE(read_id nvarchar(200) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,marker nvarchar(100) COLLATE Latin1_General_100_BIN2);
INSERT @markers(read_id,marker) VALUES
 (N'admit-contract-change',N'CONTRACT_CHANGE_DUPLICATE_CONTRACT'),
 (N'admit-scenario-authoring-change',N'SCENARIO_AUTHORING_EVENT_AUTHORITY_INVALID'),
 (N'admit-transformation-change',N'TRANSFORMATION_CHANGE_EXPRESSION_INVALID'),
 (N'admit-feature-binding-change',N'FEATURE_BINDING_SCENARIO_NOT_OWNED');
-- The execution-authority-change kind is shared with the dynamic-dispatch lane
-- (implement-dynamic-tool-dispatch.sql): a read whose statement already carries a
-- real predicate from either lane is left exactly as it is; this file only
-- supplies the fallback read/contracts when the kind is still refuse-by-default.
DECLARE @execution_real bit=CASE WHEN EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads')
 WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement')
 WHERE readId=N'admit-execution-authority-change'
  AND (statement LIKE N'%EXECUTION_AUTHORITY_CHANGE_PORT_NOT_RESOLVED%'
    OR statement LIKE N'%EXECUTION_AUTHORITY_CHANGE_TARGET_NOT_DECLARED%')) THEN 1 ELSE 0 END;
DECLARE @declared bit=CASE WHEN
 (SELECT COUNT(*) FROM @markers m WHERE EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads')
   WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement')
   WHERE readId=m.read_id AND statement LIKE N'%'+m.marker+N'%'))=4
 AND @execution_real=1
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'contract-change.v1' AND value LIKE N'%"contracts"%')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'scenario-authoring-change.v1' AND value LIKE N'%"fixtures"%')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'transformation-change.v1' AND value LIKE N'%"expression"%')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'execution-authority-change.v1' AND value LIKE N'%"providerBindings"%')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'feature-binding-change.v1' AND value LIKE N'%"pins"%')
 THEN 1 ELSE 0 END;
IF @declared=0
BEGIN
 DECLARE @reads TABLE(ordinal int PRIMARY KEY,entry nvarchar(max));
 INSERT @reads(ordinal,entry) SELECT CONVERT(int,[key]),value FROM OPENJSON(@body,'$.reads');
 DECLARE @read_count int=(SELECT COUNT(*) FROM @reads);
 DECLARE @r_ordinal int,@r_entry nvarchar(max),@r_new nvarchar(max);
 SET @body=JSON_MODIFY(@body,'$.reads',JSON_QUERY(N'[]'));
 DECLARE read_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal,entry FROM @reads ORDER BY ordinal;
 OPEN read_cursor;
 FETCH NEXT FROM read_cursor INTO @r_ordinal,@r_entry;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @r_new=(SELECT entry FROM @new_reads WHERE read_id=JSON_VALUE(@r_entry,'$.readId'));
  IF @r_new IS NOT NULL AND JSON_VALUE(@r_entry,'$.readId')=N'admit-execution-authority-change' AND @execution_real=1 SET @r_new=@r_entry;
  IF @r_new IS NULL SET @r_new=@r_entry;
  SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@r_new));
  FETCH NEXT FROM read_cursor INTO @r_ordinal,@r_entry;
 END
 CLOSE read_cursor; DEALLOCATE read_cursor;
 IF (SELECT COUNT(*) FROM OPENJSON(@body,'$.reads'))<>@read_count THROW 51000,N'REMAINING_WRITER_KINDS_READ_COUNT_CHANGED',1;
 SET @body=JSON_MODIFY(@body,'$.changeContracts."contract-change.v1"',JSON_QUERY(@c_payload_contract));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."contract-change-installed.v1"',JSON_QUERY(@c_installed_contract));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."scenario-authoring-change.v1"',JSON_QUERY(@c_payload_scenario));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."scenario-authoring-change-installed.v1"',JSON_QUERY(@c_installed_scenario));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."transformation-change.v1"',JSON_QUERY(@c_payload_transformation));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."transformation-change-installed.v1"',JSON_QUERY(@c_installed_transformation));
 IF EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'execution-authority-change.v1'
  AND value LIKE N'%Refuse-by-default%')
  SET @body=JSON_MODIFY(@body,'$.changeContracts."execution-authority-change.v1"',JSON_QUERY(@c_payload_execution));
 IF EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'execution-authority-change-installed.v1'
  AND JSON_VALUE(value,'$.type')<>N'array')
  SET @body=JSON_MODIFY(@body,'$.changeContracts."execution-authority-change-installed.v1"',JSON_QUERY(@c_installed_execution));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."feature-binding-change.v1"',JSON_QUERY(@c_payload_feature));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."feature-binding-change-installed.v1"',JSON_QUERY(@c_installed_feature));
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content binary(32)=HASHBYTES('SHA2_256',@bytes);
 DECLARE @new_content nvarchar(80)=N'sha256:'+LOWER(CONVERT(varchar(64),@content,2));
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content)<>@bytes THROW 51000,N'REMAINING_WRITER_KINDS_CONTENT_DIVERGED',1;
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
IF @declared_body IS NULL THROW 51000,N'REMAINING_WRITER_KINDS_BODY_MISSING',1;
IF JSON_VALUE(@declared_body,'$.authorityDigest')<>N'sha256:a34639fce305a43c02c4cc5f072a4e3a98c1f1ba90ffb23739d321a9e21a7db3'
 THROW 51000,N'REMAINING_WRITER_KINDS_AUTHORITY_DIGEST_DIVERGED',1;

IF (SELECT COUNT(*) FROM @markers m WHERE EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.reads')
  WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement')
  WHERE readId=m.read_id AND statement LIKE N'%'+m.marker+N'%'))<>4
 THROW 51000,N'REMAINING_WRITER_KINDS_BASE_READS_INCOMPLETE',1;
IF NOT EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.reads')
  WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement')
  WHERE readId=N'admit-execution-authority-change'
   AND (statement LIKE N'%EXECUTION_AUTHORITY_CHANGE_PORT_NOT_RESOLVED%'
     OR statement LIKE N'%EXECUTION_AUTHORITY_CHANGE_TARGET_NOT_DECLARED%'))
 THROW 51000,N'REMAINING_WRITER_KINDS_EXECUTION_READ_INCOMPLETE',1;
IF (SELECT COUNT(*) FROM @required_contracts c WHERE EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.changeContracts') WHERE [key] COLLATE Latin1_General_100_BIN2 = c.contract_id))<>10
 THROW 51000,N'REMAINING_WRITER_KINDS_CONTRACTS_INCOMPLETE',1;
SELECT N'0_kind_revision' AS result_set,@authority_id AS authority_id,@result_content AS content_digest,
 CASE WHEN @declared=1 THEN N'already_declared' ELSE N'revised' END AS disposition,
 @execution_real AS execution_predicate_present,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads') WITH(statement nvarchar(max) '$.statement') WHERE statement LIKE N'%CANDIDATE_NOT_ACCEPTED%') AS gated_reads;
GO
-- ============================== PROOF ==============================
-- One fixture ACCEPTED candidate decision plus a valid and a malformed probe
-- per kind, all written and rolled back inside this transaction.
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
DECLARE @declared_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@result_content,N'sha256:',N''),2));
DECLARE @admit TABLE(read_id nvarchar(200) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,statement nvarchar(max));
INSERT @admit(read_id,statement) SELECT readId,statement
 FROM OPENJSON(@declared_body,'$.reads') WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement')
 WHERE readId IN (N'admit-contract-change',N'admit-scenario-authoring-change',N'admit-transformation-change',
  N'admit-execution-authority-change',N'admit-feature-binding-change');
IF (SELECT COUNT(*) FROM @admit)<>5 THROW 51000,N'REMAINING_WRITER_KINDS_ADMISSION_READ_MISSING',1;
DECLARE @candidate_id nvarchar(400)=N'lane5-remaining-kinds.candidate-1';
DECLARE @bundle_digest nvarchar(100)=N'sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
DECLARE @decision_id nvarchar(400)=@candidate_id+N'.decision.v1';
DECLARE @decision nvarchar(max)=(SELECT @candidate_id AS candidateId,@bundle_digest AS bundleDigest,N'ACCEPTED' AS decision,
 N'lane5-reviewer' AS reviewerAuthorityId,N'2026-09-22T00:00:00Z' AS decidedAt FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @decision_receipt nvarchar(max)=(SELECT JSON_QUERY(@decision) AS document,N'sha256:lane5-fixture' AS decisionDigest
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @d_object bigint,@d_definition bigint,@d_digest binary(32);
EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:candidates',@decision_id,@decision_receipt,
 @d_object OUTPUT,@d_definition OUTPUT,@d_digest OUTPUT;
DECLARE @baseline TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @baseline(capability_id,digest,bytes)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'route-two-child-proof',1,NULL) g;
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'REMAINING_WRITER_KINDS_BASELINE_MISSING',1;
SELECT N'1_baseline_digests' AS result_set,capability_id,digest AS graph_digest_before,bytes AS graph_source_bytes FROM @baseline ORDER BY capability_id;
DECLARE @valid_contract nvarchar(max)=N'{"contractId":"contract-change.v1","candidateId":"lane5-remaining-kinds.candidate-1","bundleDigest":"sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd","capabilityId":"authoring-altitude-model-stubs","contracts":[{"id":"lane5-contract-proof.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"lane5-contract-proof.v1","type":"object","properties":{"payload":{"type":"object","properties":{"value":{"type":"string"}},"required":["value"]}}}}],"preflight":{"input":{"objective":"lane5 contract proof"},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}';
DECLARE @bad_contract nvarchar(max)=N'{"contractId":"contract-change.v1","candidateId":"lane5-remaining-kinds.candidate-1","bundleDigest":"sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd","capabilityId":"authoring-altitude-model-stubs","contracts":[{"id":"lane5-contract-proof.v1","schema":{"$id":"lane5-contract-proof.v1","type":"object","properties":{"a":{"type":"string"}}}},{"id":"lane5-contract-proof.v1","schema":{"$id":"lane5-contract-proof.v1","type":"object","properties":{"b":{"type":"string"}}}}],"preflight":{"input":{"objective":"lane5 contract proof"},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}';
DECLARE @valid_scenario nvarchar(max)=N'{"contractId":"scenario-authoring-change.v1","candidateId":"lane5-remaining-kinds.candidate-1","bundleDigest":"sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd","capabilityId":"authoring-altitude-model-stubs","revision":true,"scenario":{"scenarioId":"lane5-scenario-proof","name":"Lane 5 scenario proof","inputId":"lane5-scenario-proof-request","inputContract":"authoring-altitude-model-stubs-request.v1","eventId":"lane5-scenario-proof-requested","eventAuthority":"lane5-scenario-proof.v1","outcomeId":"lane5-scenario-proof-outcome","outcomeContract":"altitude-2-capability-meaning-output.v1","given":"a lane 5 proof context","when":"the declared read runs","then":"a value is returned","terminal":true,"root":false},"operations":[{"operationId":"lane5-scenario-proof.0","kind":"invoke-port","portId":"lane5-scenario-proof-port"}],"portBindings":[{"portId":"lane5-scenario-proof-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"altitude-2-capability-meaning-stub-transform.v1"}}],"fixtures":[{"fixtureId":"lane5-scenario-proof.fixture-1","input":{"payload":{"value":"lane5"}},"expected":{"outcomeAssertions":[{"path":"$.payload.value","value":"lane5"}]}}],"preflight":{"input":{"objective":"lane5 scenario proof"},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}';
DECLARE @bad_scenario nvarchar(max)=JSON_MODIFY(@valid_scenario,'$.scenario.eventAuthority',N'lane5-scenario-proof.alt.v1');
DECLARE @valid_transformation nvarchar(max)=N'{"contractId":"transformation-change.v1","candidateId":"lane5-remaining-kinds.candidate-1","bundleDigest":"sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd","capabilityId":"authoring-altitude-model-stubs","transformationId":"lane5-transformation-proof.v1","revision":true,"expression":{"profile":"json-expression-tree.v1","root":{"op":"literal","value":"lane5"}},"inputContract":"authoring-altitude-model-stubs-request.v1","preflight":{"input":{"objective":"lane5 transformation proof"},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}';
DECLARE @bad_transformation nvarchar(max)=N'{"contractId":"transformation-change.v1","candidateId":"lane5-remaining-kinds.candidate-1","bundleDigest":"sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd","capabilityId":"authoring-altitude-model-stubs","transformationId":"lane5-transformation-proof.v1","preflight":{"input":{"objective":"lane5 transformation proof"},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}';
DECLARE @valid_execution nvarchar(max)=N'{"contractId":"execution-authority-change.v1","candidateId":"lane5-remaining-kinds.candidate-1","bundleDigest":"sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd","capabilityId":"authoring-altitude-model-stubs","authorityId":"lane5-authority-proof.v1","revision":true,"owningScenarioId":"lane5-authority-proof","scenario":{"scenarioId":"lane5-authority-proof","name":"Lane 5 authority proof","inputId":"lane5-authority-proof-request","inputContract":"authoring-altitude-model-stubs-request.v1","eventId":"lane5-authority-proof-requested","eventAuthority":"lane5-authority-proof.v1","outcomeId":"lane5-authority-proof-outcome","outcomeContract":"altitude-2-capability-meaning-output.v1","given":"a lane 5 proof context","when":"the authority is minted","then":"the operations are linked","terminal":true,"root":false,"operations":[{"operationId":"lane5-authority-proof.0","kind":"invoke-port","portId":"lane5-authority-proof-port"}],"portBindings":[{"portId":"lane5-authority-proof-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"altitude-2-capability-meaning-stub-transform.v1"}}]},"operations":[{"operationId":"lane5-authority-proof.0","kind":"invoke-port","portId":"lane5-authority-proof-port"},{"operationId":"lane5-authority-proof.1","kind":"invoke-scenario","targetScenarioId":"altitude-2-capability-meaning"}],"preflight":{"input":{"objective":"lane5 authority proof"},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}';
DECLARE @bad_execution nvarchar(max)=JSON_MODIFY(@valid_execution,'$.operations[1].kind',N'invoke-http');
DECLARE @feature_valid_text nvarchar(max)=N'@capability:authoring-altitude-model-stubs'+CHAR(10)+N'@scenario:altitude-2-capability-meaning'+CHAR(10)
 +N'Feature: lane 5 feature binding proof'+CHAR(10)+CHAR(10)+N'  Scenario: lane5'+CHAR(10)+N'    Given a proof'+CHAR(10)+N'    Then the pin lands'+CHAR(10);
DECLARE @feature_bad_text nvarchar(max)=N'@capability:authoring-altitude-model-stubs'+CHAR(10)+N'@scenario:lane5-not-a-scenario'+CHAR(10)
 +N'Feature: lane 5 feature binding proof'+CHAR(10)+CHAR(10)+N'  Scenario: lane5'+CHAR(10)+N'    Given a proof'+CHAR(10)+N'    Then the pin lands'+CHAR(10);
DECLARE @valid_feature nvarchar(max)=N'{"contractId":"feature-binding-change.v1","candidateId":"lane5-remaining-kinds.candidate-1","bundleDigest":"sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd","capabilityId":"authoring-altitude-model-stubs","revision":true,"pins":[{"scenarioId":"altitude-2-capability-meaning"}],"feature":{"text":""},"preflight":{"input":{"objective":"lane5 feature proof"},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}';
SET @valid_feature=JSON_MODIFY(@valid_feature,'$.feature.text',@feature_valid_text);
DECLARE @bad_feature nvarchar(max)=JSON_MODIFY(@valid_feature,'$.feature.text',@feature_bad_text);
DECLARE @probes TABLE(ordinal int PRIMARY KEY,kind nvarchar(200) COLLATE Latin1_General_100_BIN2,read_id nvarchar(200) COLLATE Latin1_General_100_BIN2,
 valid nvarchar(max),malformed nvarchar(max),expected_code nvarchar(100) COLLATE Latin1_General_100_BIN2);
INSERT @probes(ordinal,kind,read_id,valid,malformed,expected_code) VALUES
 (1,N'contract-change',N'admit-contract-change',@valid_contract,@bad_contract,N'CONTRACT_CHANGE_DUPLICATE_CONTRACT'),
 (2,N'scenario-authoring',N'admit-scenario-authoring-change',@valid_scenario,@bad_scenario,N'SCENARIO_AUTHORING_EVENT_AUTHORITY_INVALID'),
 (3,N'transformation-change',N'admit-transformation-change',@valid_transformation,@bad_transformation,N'TRANSFORMATION_CHANGE_EXPRESSION_REQUIRED'),
 (4,N'execution-authority-change',N'admit-execution-authority-change',@valid_execution,@bad_execution,N'EXECUTION_AUTHORITY_CHANGE_OPERATION_KIND_INVALID'),
 (5,N'feature-binding-change',N'admit-feature-binding-change',@valid_feature,@bad_feature,N'FEATURE_BINDING_SCENARIO_NOT_OWNED');
DECLARE @single TABLE(disposition nvarchar(20),reason nvarchar(max));
DECLARE @p_kind nvarchar(200),@p_read nvarchar(200),@p_valid nvarchar(max),@p_bad nvarchar(max),@p_code nvarchar(100),@p_stmt nvarchar(max);
DECLARE @defs_before bigint,@defs_after bigint,@gate_doc nvarchar(max),@fail_msg nvarchar(2048);
DECLARE probe_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT kind,read_id,valid,malformed,expected_code FROM @probes ORDER BY ordinal;
OPEN probe_cursor;
FETCH NEXT FROM probe_cursor INTO @p_kind,@p_read,@p_valid,@p_bad,@p_code;
WHILE @@FETCH_STATUS=0
BEGIN
 SELECT @p_stmt=statement FROM @admit WHERE read_id=@p_read;
 IF @p_stmt IS NULL THROW 51000,N'REMAINING_WRITER_KINDS_READ_MISSING',1;
 DELETE @single;
 INSERT @single EXEC sp_executesql @p_stmt,N'@input nvarchar(max),@estate_model_pk bigint',@input=@p_valid,@estate_model_pk=@estate;
 SELECT N'2_admission' AS result_set,@p_kind AS change_kind,disposition,reason FROM @single;
 IF NOT EXISTS(SELECT 1 FROM @single WHERE disposition=N'ADMITTED')
 BEGIN
  SET @fail_msg=N'REMAINING_WRITER_KINDS_ADMISSION_FAILED: '+ISNULL((SELECT TOP 1 LEFT(ISNULL(reason,N'(none)'),1500) FROM @single),N'(none)');

  THROW 51000,@fail_msg,1;
 END
 IF @p_kind=N'contract-change' EXEC model.install_contract_change @document=@p_valid;
 ELSE IF @p_kind=N'scenario-authoring' EXEC model.install_scenario_authoring_change @document=@p_valid;
 ELSE IF @p_kind=N'transformation-change' EXEC model.install_transformation_change @document=@p_valid;
 ELSE IF @p_kind=N'execution-authority-change' EXEC model.install_execution_authority_change @document=@p_valid;
 ELSE IF @p_kind=N'feature-binding-change' EXEC model.install_feature_binding_change @document=@p_valid;
 SELECT N'3_install' AS result_set,@p_kind AS change_kind,N'executed' AS install_disposition;
 SET @defs_before=(SELECT COUNT(*) FROM model.semantic_object_definition);
 IF @p_kind=N'contract-change' EXEC model.install_contract_change @document=@p_valid;
 ELSE IF @p_kind=N'scenario-authoring' EXEC model.install_scenario_authoring_change @document=@p_valid;
 ELSE IF @p_kind=N'transformation-change' EXEC model.install_transformation_change @document=@p_valid;
 ELSE IF @p_kind=N'execution-authority-change' EXEC model.install_execution_authority_change @document=@p_valid;
 ELSE IF @p_kind=N'feature-binding-change' EXEC model.install_feature_binding_change @document=@p_valid;
 SET @defs_after=(SELECT COUNT(*) FROM model.semantic_object_definition);
 SELECT N'4_replay' AS result_set,@p_kind AS change_kind,
  CASE WHEN @defs_after=@defs_before THEN N'already_installed' ELSE N'REPLAY_WROTE' END AS replay_disposition;
 IF @defs_after<>@defs_before THROW 51000,N'REMAINING_WRITER_KINDS_REPLAY_WROTE',1;
 DELETE @single;
 INSERT @single EXEC sp_executesql @p_stmt,N'@input nvarchar(max),@estate_model_pk bigint',@input=@p_bad,@estate_model_pk=@estate;
 SELECT N'5_malformed' AS result_set,@p_kind AS change_kind,disposition,reason FROM @single;
 IF NOT EXISTS(SELECT 1 FROM @single WHERE disposition=N'HELD' AND reason LIKE N'%'+@p_code+N'%')
  THROW 51000,N'REMAINING_WRITER_KINDS_MALFORMED_PROOF_FAILED',1;
 DELETE @single;
 SET @gate_doc=JSON_MODIFY(@p_valid,'$.candidateId',N'lane5-remaining-kinds.no-decision');
 INSERT @single EXEC sp_executesql @p_stmt,N'@input nvarchar(max),@estate_model_pk bigint',
  @input=@gate_doc,@estate_model_pk=@estate;
 SELECT N'6_gate' AS result_set,@p_kind AS change_kind,disposition,reason FROM @single;
 IF NOT EXISTS(SELECT 1 FROM @single WHERE disposition=N'HELD' AND reason LIKE N'%CANDIDATE_NOT_ACCEPTED%')
  THROW 51000,N'REMAINING_WRITER_KINDS_GATE_PROOF_FAILED',1;
 FETCH NEXT FROM probe_cursor INTO @p_kind,@p_read,@p_valid,@p_bad,@p_code;
END
CLOSE probe_cursor; DEALLOCATE probe_cursor;
DECLARE @effects TABLE(contract_rows int,scenario_rows int,fixture_rows int,transformation_rows int,node_rows int,
 authority_rows int,port_invocation_rows int,scenario_invocation_rows int,feature_version_rows int,receipt_rows int);
INSERT @effects
SELECT
 (SELECT COUNT(*) FROM model.contract ct JOIN model.identity_namespace n ON n.namespace_pk=ct.namespace_pk
   WHERE n.namespace_id=N'sidefx:contracts' AND ct.contract_id=N'lane5-contract-proof.v1'),
 (SELECT COUNT(*) FROM model.scenario s JOIN model.capability c ON c.capability_pk=s.capability_pk
   JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
   WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=N'authoring-altitude-model-stubs' AND s.scenario_id=N'lane5-scenario-proof'),
 (SELECT COUNT(*) FROM model.fixture f WHERE f.fixture_id LIKE N'lane5-scenario-proof.%'),
 (SELECT COUNT(*) FROM model.transformation t JOIN model.identity_namespace n ON n.namespace_pk=t.namespace_pk
   WHERE n.namespace_id=N'sidefx:capability:authoring-altitude-model-stubs' AND t.transformation_id=N'lane5-transformation-proof.v1'),
 (SELECT COUNT(*) FROM model.transformation_expression_node node JOIN model.transformation_version tv ON tv.transformation_version_pk=node.transformation_version_pk
   JOIN model.transformation t ON t.transformation_pk=tv.transformation_pk JOIN model.identity_namespace n ON n.namespace_pk=t.namespace_pk
   WHERE n.namespace_id=N'sidefx:capability:authoring-altitude-model-stubs' AND t.transformation_id=N'lane5-transformation-proof.v1'),
 (SELECT COUNT(*) FROM model.execution_authority ea JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk
   WHERE n.namespace_id=N'sidefx:capability:authoring-altitude-model-stubs' AND ea.execution_authority_id=N'lane5-authority-proof.v1'),
 (SELECT COUNT(*) FROM model.operation_port_invocation i JOIN model.execution_operation eo ON eo.execution_operation_pk=i.execution_operation_pk
   JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
   JOIN model.execution_authority ea ON ea.execution_authority_pk=eav.execution_authority_pk JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk
   WHERE n.namespace_id=N'sidefx:capability:authoring-altitude-model-stubs' AND ea.execution_authority_id=N'lane5-authority-proof.v1'),
 (SELECT COUNT(*) FROM model.operation_scenario_invocation i JOIN model.execution_operation eo ON eo.execution_operation_pk=i.execution_operation_pk
   JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
   JOIN model.execution_authority ea ON ea.execution_authority_pk=eav.execution_authority_pk JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk
   WHERE n.namespace_id=N'sidefx:capability:authoring-altitude-model-stubs' AND ea.execution_authority_id=N'lane5-authority-proof.v1'),
 (SELECT COUNT(*) FROM model.feature f JOIN model.feature_version fv ON fv.feature_pk=f.feature_pk WHERE f.feature_id=N'authoring-altitude-model-stubs'),
 (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY'
   AND d.namespace_id=N'sidefx:capability:authoring-altitude-model-stubs'
   AND d.declared_id IN (N'authoring-altitude-model-stubs.contract-change.v1',N'lane5-scenario-proof.authored.v1',
    N'lane5-transformation-proof.v1.authored.v1',N'lane5-authority-proof.v1.authored.v1',N'authoring-altitude-model-stubs.feature.v1'));
SELECT N'7_row_effects' AS result_set,contract_rows,scenario_rows,fixture_rows,transformation_rows,node_rows,
 authority_rows,port_invocation_rows,scenario_invocation_rows,feature_version_rows,receipt_rows FROM @effects;
IF EXISTS(SELECT 1 FROM @effects WHERE contract_rows<1 OR scenario_rows<1 OR fixture_rows<1 OR transformation_rows<1 OR node_rows<1
 OR authority_rows<1 OR port_invocation_rows<1 OR scenario_invocation_rows<1 OR feature_version_rows<4 OR receipt_rows<4)
 THROW 51000,N'REMAINING_WRITER_KINDS_EFFECT_MISSING',1;
DECLARE @after TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @after(capability_id,digest,bytes)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'route-two-child-proof',1,NULL) g;
SELECT N'8_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'REMAINING_WRITER_KINDS_UNRELATED_CAPABILITY_CHANGED',1;
GO
-- Installer-level accepted-candidate gate probe (dooms the transaction; the CATCH
-- reports, then the same batch rolls back).
SET XACT_ABORT OFF;
BEGIN TRY
 DECLARE @probe_payload nvarchar(max)=N'{"contractId":"contract-change.v1","candidateId":"lane5-remaining-kinds.no-decision","bundleDigest":"sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee","capabilityId":"authoring-altitude-model-stubs","contracts":[{"id":"lane5-gate-probe.v1","schema":{"$id":"lane5-gate-probe.v1","type":"object"}}],"preflight":{"input":{"objective":"gate probe"},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}';
 EXEC model.install_contract_change @document=@probe_payload;
 SELECT N'9_installer_gate_probe' AS result_set,N'NOT_THROWN' AS disposition,N'FAILED' AS probe_result;
END TRY
BEGIN CATCH
 SELECT N'9_installer_gate_probe' AS result_set,ERROR_MESSAGE() AS disposition,
  CASE WHEN ERROR_MESSAGE()=N'CANDIDATE_NOT_ACCEPTED' THEN N'PASSED' ELSE N'FAILED' END AS probe_result;
END CATCH
COMMIT TRANSACTION;
