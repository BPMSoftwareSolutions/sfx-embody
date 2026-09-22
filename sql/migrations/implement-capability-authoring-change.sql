-- implement-capability-authoring-change.sql
--
-- Lane 3, item 3: replace the refuse-by-default capability-authoring stub with
-- the real admission predicate and installer body per
-- docs/model-at-each-authoring-altitude-2026-09-21/candidate-admit-pipeline.md
-- B.2 kind 1, C.2 receipt shape, D.2 validation gaps, and
-- docs/estate-mcp-and-database-expressiveness-2026-09-21/crud-operations.md
-- 5.2/7.2, running the entity map's chain with every existing procedure's result
-- set captured (declare_capability_document itself cannot be wrapped, because
-- its own nested INSERT EXEC calls would nest):
--
--   scaffold_capability (when absent) -> declare_contract per contract ->
--     declare_scenario per scenario -> author_capability_meaning ->
--     configure_interface -> CAPABILITY_DOCUMENT ledger, then feature pinning
--     as declared (model.declare_capability_feature), then one AUTHORITY receipt
--     <capabilityId>.authored.v1 under the capability namespace.
--
-- Admission predicate (admit-capability-authoring-change, replaced):
--   contract shape; nested sidefx-capability-authority.v1 document and id match;
--   >=1 scenario; contracts uniquely identified; every operation bound by a
--   portBindings[] entry; every scenario contract reference resolves (in the
--   document or in the selected sidefx:contracts); no secret-shaped keys/values
--   (key-name scan plus deny values ending -key/-token/-secret); the capability
--   id is unowned, or the change is authorized by an ACCEPTED decision/receipt
--   at the exact candidateId+bundleDigest (a revision additionally needs
--   capabilityDocumentDigest on the ACCEPTED decision). Findings answer HELD
--   with the named code; a clean document answers ADMITTED.
--
-- Installer refusals (named): CAPABILITY_AUTHORING_TRANSACTION_REQUIRED,
-- CAPABILITY_AUTHORING_DOCUMENT_REQUIRED, CAPABILITY_AUTHORING_CAPABILITY_REQUIRED,
-- CAPABILITY_AUTHORING_DOCUMENT_MISMATCH, CAPABILITY_AUTHORING_SECRET_SHAPED_MATERIAL,
-- CANDIDATE_ACCEPTANCE_REQUIRED, CANDIDATE_NOT_ACCEPTED,
-- CAPABILITY_AUTHORING_CAPABILITY_OWNED. Replay -> already_installed.
--
-- Boot authority (same selected sda-kernel-boot-data-access.v1): the
-- admit-capability-authoring-change read statement is replaced, and the payload
-- and installed-result contracts are revised (the executor validates results as
-- the recordsets envelope, so the placeholder object result contract could never
-- be returned). The re-mint asserts structural prerequisites rather than an
-- exact prior content digest, because a parallel lane may be re-minting the same
-- authority; replay is detected from the revised contract/read themselves.
--
-- Idempotent: CREATE OR ALTER is re-runnable; the authority is re-minted only
-- while the read does not yet carry the gate; a replay prints already_declared.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=300000;
IF @lock<0 THROW 51000,N'CAPABILITY_AUTHORING_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
CREATE OR ALTER PROCEDURE model.install_capability_authoring_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'CAPABILITY_AUTHORING_TRANSACTION_REQUIRED',1;
 IF @document IS NULL OR ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'capability-authoring-change.v1'
  THROW 51000,'CAPABILITY_AUTHORING_DOCUMENT_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.capabilityId'),N'');
 IF @capability_id IS NULL THROW 51000,'CAPABILITY_AUTHORING_CAPABILITY_REQUIRED',1;
 DECLARE @candidate_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.candidateId'),N'');
 DECLARE @bundle_digest nvarchar(100)=JSON_VALUE(@document,'$.bundleDigest');
 DECLARE @capability_document nvarchar(max)=JSON_QUERY(@document,'$.document');
 IF @capability_document IS NULL OR ISJSON(@capability_document)<>1
  OR JSON_VALUE(@capability_document,'$.document')<>N'sidefx-capability-authority.v1'
  OR JSON_VALUE(@capability_document,'$.capabilityId')<>@capability_id
  THROW 51000,'CAPABILITY_AUTHORING_DOCUMENT_MISMATCH',1;
 -- Secret-shape scan: key-name scan plus a value-suffix scan that catches the
 -- spellings the name-based author-stage denylist misses.
 DECLARE @upper nvarchar(max)=UPPER(@document);
 IF @upper LIKE N'%"APIKEY"%' OR @upper LIKE N'%"API_KEY"%' OR @upper LIKE N'%"PASSWORD"%'
  OR @upper LIKE N'%"SECRET"%' OR @upper LIKE N'%"TOKEN"%' OR @upper LIKE N'%"CLIENTSECRET"%'
  OR @upper LIKE N'%"PRIVATEKEY"%' OR @upper LIKE N'%"ACCESSKEY"%' OR @upper LIKE N'%"BEARER"%'
  OR @upper LIKE N'%-KEY"%' OR @upper LIKE N'%-TOKEN"%' OR @upper LIKE N'%-SECRET"%'
  THROW 51000,'CAPABILITY_AUTHORING_SECRET_SHAPED_MATERIAL',1;
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
 DECLARE @document_digest varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
  CONVERT(varbinary(max),CONVERT(varchar(max),@capability_document COLLATE Latin1_General_100_BIN2_UTF8))),2));
 DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;
 DECLARE @receipt_id nvarchar(400)=@capability_id+N'.authored.v1';
 DECLARE @prior_digest varchar(64)=(SELECT JSON_VALUE(definition_json,'$.semantics.documentDigest')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@receipt_id COLLATE Latin1_General_100_BIN2);
 IF @prior_digest=@document_digest
 BEGIN
  SELECT N'already_installed' AS result_set,@capability_id AS capability_id,@receipt_id AS receipt_id;
  RETURN;
 END
 DECLARE @ledger varchar(64)=(SELECT TOP (1) JSON_VALUE(d.definition_json,'$.semantics.document_digest')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'CAPABILITY_DOCUMENT'
   AND d.namespace_id=N'sidefx:capability-documents' AND d.declared_id=@capability_id COLLATE Latin1_General_100_BIN2);
 IF @ledger IS NOT NULL AND @ledger<>@document_digest
  AND NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
   WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=N'sidefx:candidates'
    AND d.declared_id=@candidate_id+N'.decision.v1'
    AND JSON_VALUE(d.definition_json,'$.semantics.document.decision')=N'ACCEPTED'
    AND JSON_VALUE(d.definition_json,'$.semantics.document.bundleDigest')=@bundle_digest
    AND JSON_VALUE(d.definition_json,'$.semantics.document.capabilityDocumentDigest')=N'sha256:'+@document_digest)
  THROW 51000,'CAPABILITY_AUTHORING_CAPABILITY_OWNED',1;
 -- The JSON authoring surface's chain, in its documented order, run directly so
 -- every nested authoring procedure's result set is captured and the executor
 -- sees exactly the declared recordsets envelope. (model.declare_capability_document
 -- itself cannot wrap its own nested calls without an INSERT EXEC nesting error.)
 DECLARE @scaffold_result TABLE(action nvarchar(50),disposition nvarchar(20),capability_id nvarchar(120),
  capability_pk bigint,capability_version_pk bigint,capability_definition_pk bigint,scenario_pk bigint,
  scenario_version_pk bigint,greeting_template nvarchar(200),input_contract nvarchar(160),outcome_contract nvarchar(160));
 IF NOT EXISTS (SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
  WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capability_id)
  INSERT @scaffold_result EXEC model.scaffold_capability @capability_id=@capability_id,@on_exists=N'ERROR';
 DECLARE @contract_id nvarchar(400),@contract_schema nvarchar(max);
 DECLARE @contract_cursor CURSOR;
 SET @contract_cursor=CURSOR LOCAL FAST_FORWARD FOR
  SELECT JSON_VALUE(value,'$.id'),JSON_QUERY(value,'$.schema') FROM OPENJSON(@capability_document,'$.contracts');
 OPEN @contract_cursor;
 FETCH NEXT FROM @contract_cursor INTO @contract_id,@contract_schema;
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF @contract_id IS NULL OR @contract_schema IS NULL THROW 51000,'CAPABILITY_AUTHORING_CONTRACT_INCOMPLETE',1;
  EXEC model.declare_contract @id=@contract_id,@schema=@contract_schema;
  FETCH NEXT FROM @contract_cursor INTO @contract_id,@contract_schema;
 END
 CLOSE @contract_cursor; DEALLOCATE @contract_cursor;
 DECLARE @scenario_result TABLE(declared_scenario nvarchar(400),scenario_version_pk bigint);
 DECLARE @scenario nvarchar(max),@operations nvarchar(max),@port_bindings nvarchar(max);
 DECLARE @scenario_cursor CURSOR;
 SET @scenario_cursor=CURSOR LOCAL FAST_FORWARD FOR SELECT value FROM OPENJSON(@capability_document,'$.scenarios');
 OPEN @scenario_cursor;
 FETCH NEXT FROM @scenario_cursor INTO @scenario;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @operations=JSON_QUERY(@scenario,'$.operations');
  SET @port_bindings=JSON_QUERY(@scenario,'$.portBindings');
  IF @operations IS NULL THROW 51000,'CAPABILITY_AUTHORING_OPERATIONS_REQUIRED',1;
  IF @port_bindings IS NULL THROW 51000,'CAPABILITY_AUTHORING_PORT_BINDINGS_REQUIRED',1;
  INSERT @scenario_result EXEC model.declare_scenario @capability_id=@capability_id,@scenario=@scenario,
   @operations=@operations,@port_bindings=@port_bindings;
  FETCH NEXT FROM @scenario_cursor INTO @scenario;
 END
 CLOSE @scenario_cursor; DEALLOCATE @scenario_cursor;
 DECLARE @meaning_result TABLE(action nvarchar(50),capability_id nvarchar(400),capability_definition_pk bigint,canonical_feature_version_pk bigint);
 DECLARE @intent nvarchar(max)=JSON_VALUE(@capability_document,'$.meaning.intent');
 DECLARE @outcome nvarchar(max)=JSON_VALUE(@capability_document,'$.meaning.outcome');
 IF @intent IS NOT NULL AND @outcome IS NOT NULL
  INSERT @meaning_result EXEC model.author_capability_meaning @capability_id=@capability_id,@intent=@intent,@outcome=@outcome;
 DECLARE @interface_result TABLE(action nvarchar(50),capability_id nvarchar(120),capability_version_pk bigint,
  definition_after bigint,cli_before nvarchar(max),cli_after nvarchar(max));
 DECLARE @cli nvarchar(max)=JSON_QUERY(@capability_document,'$.cli');
 IF @cli IS NOT NULL
 BEGIN
  DECLARE @capSo bigint,@capSod bigint,@curEnv nvarchar(max);
  SELECT @capSo=c.semantic_object_pk,@capSod=ec.semantic_object_definition_pk
  FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
  WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capability_id;
  IF @capSod IS NULL THROW 51000,'CAPABILITY_AUTHORING_CAPABILITY_MISSING',1;
  SELECT @curEnv=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE d.semantic_object_definition_pk=@capSod;
  DECLARE @cliEnv nvarchar(max)=JSON_MODIFY(@curEnv,'$.semantics.cli',JSON_QUERY(@cli));
  DECLARE @cliDigest binary(32)=HASHBYTES('SHA2_256',
   CONVERT(varbinary(max),CONVERT(varchar(max),(@cliEnv) COLLATE Latin1_General_100_BIN2_UTF8)));
  IF NOT EXISTS (SELECT 1 FROM model.semantic_object_definition WHERE semantic_object_pk=@capSo AND definition_digest=@cliDigest)
   INSERT @interface_result EXEC model.configure_interface @capability_id=@capability_id,@cli_json=@cli;
 END
 DECLARE @capability_ledger nvarchar(max)=(SELECT @capability_id AS capabilityId,@document_digest AS document_digest
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @ledger_object bigint,@ledger_definition bigint,@ledger_digest binary(32);
 EXEC model.put_semantic_definition 'CAPABILITY_DOCUMENT',N'sidefx:capability-documents',@capability_id,@capability_ledger,
  @ledger_object OUTPUT,@ledger_definition OUTPUT,@ledger_digest OUTPUT;
 -- Feature pinning as declared: optional, pins the scenarios the document owns.
 DECLARE @feature_text nvarchar(max)=NULLIF(JSON_VALUE(@document,'$.feature.text'),N'');
 IF @feature_text IS NOT NULL
  EXEC model.declare_capability_feature @capability_id=@capability_id,@feature_text=@feature_text;
 DECLARE @receipt nvarchar(max)=(SELECT JSON_QUERY(@document) AS document,@document_digest AS documentDigest,
  @candidate_id AS candidateId,@bundle_digest AS bundleDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @object bigint,@definition bigint,@definition_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',@namespace,@receipt_id,@receipt,
  @object OUTPUT,@definition OUTPUT,@definition_digest OUTPUT;
 SELECT N'capability_authoring_installed' AS result_set,@capability_id AS capability_id,@receipt_id AS receipt_id;
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

-- Structural prerequisites: the six skeleton kinds, the capability-authoring read
-- and both of its contracts.
DECLARE @required_kinds TABLE(kind nvarchar(200) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @required_kinds(kind) VALUES
 (N'capability-authoring'),(N'contract-change'),(N'scenario-authoring'),
 (N'transformation-change'),(N'execution-authority-change'),(N'feature-binding-change');
IF (SELECT COUNT(*) FROM @required_kinds k WHERE EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeKinds')
 WHERE JSON_VALUE(value,'$.changeKind') COLLATE Latin1_General_100_BIN2=k.kind))<>6
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-capability-authoring-change')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'capability-authoring-change.v1')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'capability-authoring-change-installed.v1')
 THROW 51000,N'KERNEL_BOOT_AUTHORITY_CHANGED_REBASE_DECLARATION',1;

DECLARE @declared bit=CASE WHEN
 EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement')
  WHERE readId=N'admit-capability-authoring-change' AND statement LIKE N'%CANDIDATE_ACCEPTANCE_REQUIRED%')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'capability-authoring-change.v1'
  AND value LIKE N'%"candidateId"%')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'capability-authoring-change-installed.v1'
  AND JSON_VALUE(value,'$.type')=N'array')
 THEN 1 ELSE 0 END;

IF @declared=0
BEGIN
 DECLARE @admit_statement nvarchar(max)=CAST(N'DECLARE @findings TABLE(ordinal int IDENTITY(1,1),code nvarchar(100),field nvarchar(400),message nvarchar(2000));
IF ISJSON(@input)<>1 OR JSON_QUERY(@input) IS NULL
 INSERT @findings(code,field,message) VALUES(N''CAPABILITY_AUTHORING_DOCUMENT_REQUIRED'',NULL,N''the change must be a JSON object'');
ELSE BEGIN
 DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.capabilityId''),N'''');
 DECLARE @candidate_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.candidateId''),N'''');
 DECLARE @bundle_digest nvarchar(100)=JSON_VALUE(@input,''$.bundleDigest'');
 DECLARE @cap_doc nvarchar(max)=JSON_QUERY(@input,''$.document'');
 IF JSON_VALUE(@input,''$.contractId'')<>N''capability-authoring-change.v1''
  INSERT @findings(code,field,message) VALUES(N''CAPABILITY_AUTHORING_CONTRACT_REQUIRED'',N''contractId'',N''contractId must be capability-authoring-change.v1'');
 IF @capability_id IS NULL
  INSERT @findings(code,field,message) VALUES(N''CAPABILITY_AUTHORING_CAPABILITY_REQUIRED'',N''capabilityId'',N''the change must name the capability it authors'');
 IF @cap_doc IS NULL OR ISJSON(@cap_doc)<>1 OR JSON_VALUE(@cap_doc,''$.document'')<>N''sidefx-capability-authority.v1''
  INSERT @findings(code,field,message) VALUES(N''CAPABILITY_AUTHORING_DOCUMENT_REQUIRED'',N''document'',N''document must be a sidefx-capability-authority.v1 object'');
 ELSE BEGIN
  IF JSON_VALUE(@cap_doc,''$.capabilityId'')<>@capability_id
   INSERT @findings(code,field,message) VALUES(N''CAPABILITY_AUTHORING_DOCUMENT_MISMATCH'',N''document.capabilityId'',N''the nested document capabilityId must equal the change capabilityId'');
  IF NOT EXISTS(SELECT 1 FROM OPENJSON(@cap_doc,''$.scenarios''))
   INSERT @findings(code,field,message) VALUES(N''CAPABILITY_AUTHORING_SCENARIO_REQUIRED'',N''document.scenarios'',N''the document must declare at least one scenario'');
  IF (SELECT COUNT(*) FROM OPENJSON(@cap_doc,''$.contracts''))<>(SELECT COUNT(DISTINCT JSON_VALUE(value,''$.id'')) FROM OPENJSON(@cap_doc,''$.contracts''))
   INSERT @findings(code,field,message) VALUES(N''CAPABILITY_AUTHORING_CONTRACT_DUPLICATE'',N''document.contracts'',N''contract ids must be uniquely identified'');
  IF EXISTS(SELECT 1 FROM OPENJSON(@cap_doc,''$.contracts'') WHERE JSON_VALUE(value,''$.id'') IS NULL OR JSON_QUERY(value,''$.schema'') IS NULL)
   INSERT @findings(code,field,message) VALUES(N''CAPABILITY_AUTHORING_CONTRACT_INCOMPLETE'',N''document.contracts'',N''every declared contract needs an id and a schema'');
  IF EXISTS(SELECT 1 FROM OPENJSON(@cap_doc,''$.scenarios'') s
   CROSS APPLY OPENJSON(s.value,''$.operations'') o
   WHERE JSON_VALUE(o.value,''$.portId'') IS NOT NULL
    AND NOT EXISTS(SELECT 1 FROM OPENJSON(s.value,''$.portBindings'') b WHERE JSON_VALUE(b.value,''$.portId'')=JSON_VALUE(o.value,''$.portId'')))
   INSERT @findings(code,field,message) VALUES(N''CAPABILITY_AUTHORING_OPERATION_BINDING_NOT_DECLARED'',N''document.scenarios.operations'',N''every operation must be bound by a portBindings entry'');
  IF EXISTS(SELECT 1 FROM OPENJSON(@cap_doc,''$.scenarios'') s
   CROSS APPLY (VALUES(JSON_VALUE(s.value,''$.inputContract'')),(JSON_VALUE(s.value,''$.outcomeContract''))) c(contract_id)
   WHERE c.contract_id IS NOT NULL
    AND NOT EXISTS(SELECT 1 FROM OPENJSON(@cap_doc,''$.contracts'') d WHERE JSON_VALUE(d.value,''$.id'')=c.contract_id)
    AND NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition x WHERE x.estate_model_pk=@estate_model_pk
     AND x.object_kind=N''CONTRACT'' AND x.namespace_id=N''sidefx:contracts'' AND x.declared_id=c.contract_id COLLATE Latin1_General_100_BIN2))
   INSERT @findings(code,field,message) VALUES(N''CAPABILITY_AUTHORING_CONTRACT_NOT_DECLARED'',N''document.scenarios.contracts'',N''every scenario contract reference must resolve in the document or the selected contracts'');
 END
 DECLARE @upper nvarchar(max)=UPPER(@input);
 IF @upper LIKE N''%"APIKEY"%'' OR @upper LIKE N''%"API_KEY"%'' OR @upper LIKE N''%"PASSWORD"%''
  OR @upper LIKE N''%"SECRET"%'' OR @upper LIKE N''%"TOKEN"%'' OR @upper LIKE N''%"CLIENTSECRET"%''
  OR @upper LIKE N''%"PRIVATEKEY"%'' OR @upper LIKE N''%"ACCESSKEY"%'' OR @upper LIKE N''%"BEARER"%''
  OR @upper LIKE N''%-KEY"%'' OR @upper LIKE N''%-TOKEN"%'' OR @upper LIKE N''%-SECRET"%''
  INSERT @findings(code,field,message) VALUES(N''CAPABILITY_AUTHORING_SECRET_SHAPED_MATERIAL'',NULL,N''the change carries secret-shaped keys or values'');
 IF @candidate_id IS NULL OR @bundle_digest IS NULL
  INSERT @findings(code,field,message) VALUES(N''CANDIDATE_ACCEPTANCE_REQUIRED'',N''candidateId'',N''the change must name the ACCEPTED candidate it installs'');
 ELSE IF NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''AUTHORITY'' AND d.namespace_id=N''sidefx:candidates''
   AND ((d.declared_id=@candidate_id+N''.decision.v1''
         AND JSON_VALUE(d.definition_json,''$.semantics.document.decision'')=N''ACCEPTED''
         AND JSON_VALUE(d.definition_json,''$.semantics.document.bundleDigest'')=@bundle_digest)
     OR (d.declared_id=@candidate_id+N''.receipt.v1''
         AND JSON_VALUE(d.definition_json,''$.semantics.document.review.decision'')=N''ACCEPTED''
         AND JSON_VALUE(d.definition_json,''$.semantics.document.bundleDigest'')=@bundle_digest)))
  INSERT @findings(code,field,message) VALUES(N''CANDIDATE_NOT_ACCEPTED'',N''candidateId'',N''no decision or receipt ACCEPTS this candidate at this bundle digest'');
 IF @cap_doc IS NOT NULL AND ISJSON(@cap_doc)=1 AND @capability_id IS NOT NULL
 BEGIN
  DECLARE @document_digest varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES(''SHA2_256'',
   CONVERT(varbinary(max),CONVERT(varchar(max),@cap_doc COLLATE Latin1_General_100_BIN2_UTF8))),2));
  DECLARE @ledger varchar(64)=(SELECT TOP (1) JSON_VALUE(d.definition_json,''$.semantics.document_digest'')
   FROM analysis.v_selected_semantic_definition d WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''CAPABILITY_DOCUMENT''
    AND d.namespace_id=N''sidefx:capability-documents'' AND d.declared_id=@capability_id COLLATE Latin1_General_100_BIN2);
  IF @ledger IS NOT NULL AND @ledger<>@document_digest
   AND NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
    WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''AUTHORITY'' AND d.namespace_id=N''sidefx:candidates''
     AND d.declared_id=@candidate_id+N''.decision.v1''
     AND JSON_VALUE(d.definition_json,''$.semantics.document.decision'')=N''ACCEPTED''
     AND JSON_VALUE(d.definition_json,''$.semantics.document.bundleDigest'')=@bundle_digest
     AND JSON_VALUE(d.definition_json,''$.semantics.document.capabilityDocumentDigest'')=N''sha256:''+@document_digest)
   INSERT @findings(code,field,message) VALUES(N''CAPABILITY_AUTHORING_CAPABILITY_OWNED'',N''capabilityId'',N''the capability id is owned; an ACCEPTED decision for this exact document digest is required to replace it'');
 END
END
DECLARE @reason nvarchar(max)=ISNULL((SELECT code,field,message FROM @findings ORDER BY ordinal FOR JSON PATH),N''[]'');
SELECT CASE WHEN (SELECT COUNT(*) FROM @findings)=0 THEN N''ADMITTED'' ELSE N''HELD'' END AS disposition,LEFT(@reason,400) AS reason' AS nvarchar(max));
 DECLARE @read_row nvarchar(max)=(SELECT N'admit-capability-authoring-change' AS readId,
  N'Validate a capability-authoring-change.v1 document: contract shape, nested sidefx-capability-authority.v1 document and id match, scenarios, uniquely identified contracts, operation port bindings, contract references, secret-shaped material, capability ownership, and the ACCEPTED candidate decision at the exact bundle digest. Returns exactly one ADMITTED or HELD row; writes nothing.' AS purpose,
  N'observation' AS classification,N'tsql' AS sourceKind,@admit_statement AS statement
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @payload_contract nvarchar(max)=N'{"title":"Capability authoring change","description":"One capability authored from a sidefx-capability-authority.v1 document plus the candidate acceptance that authorizes it and the preflight the kind is verified by.","type":"object","additionalProperties":false,"required":["contractId","candidateId","bundleDigest","capabilityId","document","preflight","route"],"properties":{"contractId":{"const":"capability-authoring-change.v1"},"candidateId":{"type":"string","minLength":1,"maxLength":400},"bundleDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"capabilityId":{"type":"string","minLength":1,"maxLength":400},"document":{"type":"object"},"feature":{"type":"object","additionalProperties":false,"required":["text"],"properties":{"text":{"type":"string","minLength":1,"maxLength":1000000}}},"preflight":{"type":"object","additionalProperties":false,"required":["input"],"properties":{"input":{"type":"object"},"expected":{"type":"object"}}},"route":{"type":"object","additionalProperties":false,"required":["resolvedDisposition"],"properties":{"resolvedDisposition":{"type":"string","minLength":1,"maxLength":100}}}}}';
 DECLARE @installed_contract nvarchar(max)=N'{"title":"Capability authoring change installed","description":"Executor recordsets envelope: capability_authoring_installed for a new install, already_installed for a byte-identical replay.","type":"array","minItems":1,"maxItems":1,"items":{"type":"array","minItems":1,"maxItems":1,"items":{"type":"object","additionalProperties":false,"required":["result_set","capability_id","receipt_id"],"properties":{"result_set":{"enum":["capability_authoring_installed","already_installed"]},"capability_id":{"type":"string","minLength":1,"maxLength":400},"receipt_id":{"type":"string","minLength":1,"maxLength":400}}}}}';
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
  IF JSON_VALUE(@read_entry,'$.readId')=N'admit-capability-authoring-change' SET @read_entry=@read_row;
  SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@read_entry));
  FETCH NEXT FROM read_cursor INTO @read_ordinal,@read_entry;
 END
 CLOSE read_cursor; DEALLOCATE read_cursor;
 IF (SELECT COUNT(*) FROM OPENJSON(@body,'$.reads'))<>@read_count THROW 51000,N'CAPABILITY_AUTHORING_READ_COUNT_CHANGED',1;
 SET @body=JSON_MODIFY(@body,'$.changeContracts."capability-authoring-change.v1"',JSON_QUERY(@payload_contract));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."capability-authoring-change-installed.v1"',JSON_QUERY(@installed_contract));
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
 THROW 51000,N'CAPABILITY_AUTHORING_AUTHORITY_DIGEST_DIVERGED',1;
IF NOT EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.reads') WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement')
 WHERE readId=N'admit-capability-authoring-change' AND statement LIKE N'%CANDIDATE_ACCEPTANCE_REQUIRED%')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.changeContracts') WHERE [key]=N'capability-authoring-change.v1'
  AND value LIKE N'%"candidateId"%')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.changeContracts') WHERE [key]=N'capability-authoring-change-installed.v1'
  AND JSON_VALUE(value,'$.type')=N'array')
 THROW 51000,N'CAPABILITY_AUTHORING_DECLARATION_INCOMPLETE',1;
SELECT N'0_kind_revision' AS result_set,@authority_id AS authority_id,@result_content AS content_digest,
 CASE WHEN @declared=1 THEN N'already_declared' ELSE N'revised' END AS disposition;
GO
-- ============================== AUTHORING PROOF ==============================
-- A scratch capability, a fixture ACCEPTED decision, the real admission read and
-- the real installer, all created and rolled back in this transaction.
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
DECLARE @declared_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@result_content,N'sha256:',N''),2));
DECLARE @admit_statement nvarchar(max)=(SELECT statement FROM OPENJSON(@declared_body,'$.reads')
 WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement')
 WHERE readId=N'admit-capability-authoring-change');
IF @admit_statement IS NULL THROW 51000,N'CAPABILITY_AUTHORING_READ_MISSING',1;
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
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'CAPABILITY_AUTHORING_BASELINE_MISSING',1;

DECLARE @candidate nvarchar(400)=N'lane3-authoring-proof.candidate-1';
DECLARE @bundle nvarchar(100)=N'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
DECLARE @capability_document nvarchar(max)=N'{"document":"sidefx-capability-authority.v1","capabilityId":"lane3-authoring-proof","meaning":{"intent":"prove the capability-authoring installer","outcome":"the scratch capability is authored from one document and a receipt is written"},"contracts":[{"id":"lane3-authoring-proof-request.v1","schema":{"type":"object","additionalProperties":true}},{"id":"lane3-authoring-proof-outcome.v1","schema":{"type":"object","additionalProperties":true}}],"scenarios":[{"scenarioId":"lane3-authoring-proof","name":"Authoring proof root","inputId":"lane3-authoring-proof-request","inputContract":"lane3-authoring-proof-request.v1","eventId":"lane3-authoring-proof-requested","eventAuthority":"lane3-authoring-proof.v1","outcomeId":"lane3-authoring-proof-outcome","outcomeContract":"lane3-authoring-proof-outcome.v1","given":"a scratch capability authored from a JSON document","when":"the declared read runs","then":"a value is returned","terminal":true,"root":true,"operations":[{"operationId":"lane3-authoring-proof.0","kind":"invoke-port","portId":"lane3-authoring-proof-port"}],"portBindings":[{"portId":"lane3-authoring-proof-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"SELECT (SELECT 1 AS value FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value","resultColumn":"value"}}]}]}';
DECLARE @payload nvarchar(max)=(SELECT N'capability-authoring-change.v1' AS contractId,@candidate AS candidateId,@bundle AS bundleDigest,
 N'lane3-authoring-proof' AS capabilityId,JSON_QUERY(@capability_document) AS document,
 JSON_QUERY(N'{"text":"@capability:lane3-authoring-proof\n@root-scenario:lane3-authoring-proof"}') AS feature,
 JSON_QUERY(N'{"input":{"objective":"lane3 authoring proof"},"expected":{"disposition":"terminated"}}') AS preflight,
 JSON_QUERY(N'{"resolvedDisposition":"terminated"}') AS route
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
-- Fixture: an ACCEPTED decision for the candidate and bundle.
DECLARE @decision_id nvarchar(400)=@candidate+N'.decision.v1';
DECLARE @decision nvarchar(max)=(SELECT @candidate AS candidateId,@bundle AS bundleDigest,N'ACCEPTED' AS decision,
 N'lane3-reviewer' AS reviewerAuthorityId,N'2026-09-22T00:00:00Z' AS decidedAt
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @decision_receipt nvarchar(max)=(SELECT JSON_QUERY(@decision) AS document,N'sha256:fixture' AS decisionDigest
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @d_object bigint,@d_definition bigint,@d_digest binary(32);
EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:candidates',@decision_id,@decision_receipt,
 @d_object OUTPUT,@d_definition OUTPUT,@d_digest OUTPUT;

DECLARE @admission TABLE(disposition nvarchar(20),reason nvarchar(400));
-- Whole-file replay: the ledger already selects the authorized revision, so the
-- fresh-install proof is skipped and replaced by the replay proof at the end.
DECLARE @owned nvarchar(max)=JSON_MODIFY(JSON_MODIFY(@payload,'$.document.meaning.outcome',N'a revised outcome'),
 '$.candidateId',N'lane3-authoring-proof.candidate-2');
DECLARE @owned_digest varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),JSON_QUERY(@owned,'$.document') COLLATE Latin1_General_100_BIN2_UTF8))),2));
DECLARE @proof_revised bit=CASE WHEN (SELECT TOP (1) JSON_VALUE(d.definition_json,'$.semantics.document_digest')
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'CAPABILITY_DOCUMENT' AND d.namespace_id=N'sidefx:capability-documents'
  AND d.declared_id=N'lane3-authoring-proof' COLLATE Latin1_General_100_BIN2)=@owned_digest THEN 1 ELSE 0 END;
DECLARE @receipt_definitions int=(SELECT COUNT(*) FROM model.semantic_object_definition d
 JOIN model.semantic_object o ON o.semantic_object_pk=d.semantic_object_pk
 JOIN model.identity_namespace n ON n.namespace_pk=o.namespace_pk
 WHERE n.namespace_id=N'sidefx:capability:lane3-authoring-proof' AND o.declared_id=N'lane3-authoring-proof.authored.v1');
IF @proof_revised=0
BEGIN
 INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@payload,@estate_model_pk=@estate;
 SELECT N'1_admission_admitted' AS result_set,disposition,reason FROM @admission;
 IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'ADMITTED') THROW 51000,N'CAPABILITY_AUTHORING_ADMISSION_FAILED',1;
EXEC model.install_capability_authoring_change @document=@payload;
IF NOT EXISTS(SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
 WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=N'lane3-authoring-proof')
 THROW 51000,N'CAPABILITY_AUTHORING_CAPABILITY_MISSING',1;
IF NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=N'sidefx:capability:lane3-authoring-proof'
  AND d.declared_id=N'lane3-authoring-proof.authored.v1')
 THROW 51000,N'CAPABILITY_AUTHORING_RECEIPT_MISSING',1;
IF NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'CAPABILITY_DOCUMENT' AND d.namespace_id=N'sidefx:capability-documents'
  AND d.declared_id=N'lane3-authoring-proof')
 THROW 51000,N'CAPABILITY_AUTHORING_LEDGER_MISSING',1;
IF NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'FEATURE' AND d.namespace_id=N'sidefx:features'
  AND d.declared_id=N'lane3-authoring-proof')
 THROW 51000,N'CAPABILITY_AUTHORING_FEATURE_MISSING',1;
EXEC model.install_capability_authoring_change @document=@payload;
IF (SELECT COUNT(*) FROM model.semantic_object_definition d
 JOIN model.semantic_object o ON o.semantic_object_pk=d.semantic_object_pk
 JOIN model.identity_namespace n ON n.namespace_pk=o.namespace_pk
 WHERE n.namespace_id=N'sidefx:capability:lane3-authoring-proof' AND o.declared_id=N'lane3-authoring-proof.authored.v1')<>@receipt_definitions
 THROW 51000,N'CAPABILITY_AUTHORING_REPLAY_WROTE',1;

-- Admission refusals are data-level: no acceptance, secret-shaped value, owned id.
DECLARE @no_gate nvarchar(max)=JSON_MODIFY(@payload,'$.candidateId',N'lane3-authoring-proof.no-decision');
DELETE @admission;
INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@no_gate,@estate_model_pk=@estate;
SELECT N'2_no_acceptance' AS result_set,disposition,reason FROM @admission;
IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'HELD' AND reason LIKE N'%CANDIDATE_NOT_ACCEPTED%')
 THROW 51000,N'CAPABILITY_AUTHORING_NO_ACCEPTANCE_PROOF_FAILED',1;
DECLARE @secret_payload nvarchar(max)=JSON_MODIFY(@payload,'$.document.scenarios[0].portBindings[0].configuration.allowedRequestHeaders',
 JSON_QUERY(N'["x-rapidapi-key"]'));
DELETE @admission;
INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@secret_payload,@estate_model_pk=@estate;
SELECT N'3_secret_shaped' AS result_set,disposition,reason FROM @admission;
IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'HELD' AND reason LIKE N'%SECRET_SHAPED_MATERIAL%')
 THROW 51000,N'CAPABILITY_AUTHORING_SECRET_PROOF_FAILED',1;
DECLARE @c2 nvarchar(400)=N'lane3-authoring-proof.candidate-2';
DECLARE @c2_decision_id nvarchar(400)=@c2+N'.decision.v1';
DECLARE @c2_decision nvarchar(max)=(SELECT @c2 AS candidateId,@bundle AS bundleDigest,N'ACCEPTED' AS decision,
 N'lane3-reviewer' AS reviewerAuthorityId,N'2026-09-22T00:00:02Z' AS decidedAt FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @c2_receipt nvarchar(max)=(SELECT JSON_QUERY(@c2_decision) AS document,N'sha256:fixture2' AS decisionDigest
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:candidates',@c2_decision_id,@c2_receipt,
 @d_object OUTPUT,@d_definition OUTPUT,@d_digest OUTPUT;
DELETE @admission;
INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@owned,@estate_model_pk=@estate;
SELECT N'4_owned_refused' AS result_set,disposition,reason FROM @admission;
IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'HELD' AND reason LIKE N'%CAPABILITY_AUTHORING_CAPABILITY_OWNED%')
 THROW 51000,N'CAPABILITY_AUTHORING_OWNED_PROOF_FAILED',1;
-- A revision is authorized when the ACCEPTED decision names this exact document digest.
DECLARE @c2_authorized nvarchar(max)=(SELECT @c2 AS candidateId,@bundle AS bundleDigest,N'ACCEPTED' AS decision,
 N'lane3-reviewer' AS reviewerAuthorityId,N'2026-09-22T00:00:03Z' AS decidedAt,
 N'sha256:'+@owned_digest AS capabilityDocumentDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @c2_authorized_receipt nvarchar(max)=(SELECT JSON_QUERY(@c2_authorized) AS document,N'sha256:fixture3' AS decisionDigest
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:candidates',@c2_decision_id,@c2_authorized_receipt,
 @d_object OUTPUT,@d_definition OUTPUT,@d_digest OUTPUT;
DELETE @admission;
INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@owned,@estate_model_pk=@estate;
SELECT N'5_revision_authorized' AS result_set,disposition,reason FROM @admission;
IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'ADMITTED') THROW 51000,N'CAPABILITY_AUTHORING_REVISION_ACCEPTANCE_FAILED',1;
EXEC model.install_capability_authoring_change @document=@owned;
END
ELSE
BEGIN
 -- The authorized revision is already the selected document: prove its byte-identical
 -- replay and that the superseded original is still refused without authorization.
 INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@owned,@estate_model_pk=@estate;
 SELECT N'1_admission_admitted' AS result_set,disposition,reason FROM @admission;
 IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'ADMITTED') THROW 51000,N'CAPABILITY_AUTHORING_REVISION_ACCEPTANCE_FAILED',1;
 EXEC model.install_capability_authoring_change @document=@owned;
 IF (SELECT COUNT(*) FROM model.semantic_object_definition d
  JOIN model.semantic_object o ON o.semantic_object_pk=d.semantic_object_pk
  JOIN model.identity_namespace n ON n.namespace_pk=o.namespace_pk
  WHERE n.namespace_id=N'sidefx:capability:lane3-authoring-proof' AND o.declared_id=N'lane3-authoring-proof.authored.v1')<>@receipt_definitions
  THROW 51000,N'CAPABILITY_AUTHORING_REPLAY_WROTE',1;
 DELETE @admission;
 INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@payload,@estate_model_pk=@estate;
 SELECT N'2_superseded_owned' AS result_set,disposition,reason FROM @admission;
 IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'HELD' AND reason LIKE N'%CAPABILITY_AUTHORING_CAPABILITY_OWNED%')
  THROW 51000,N'CAPABILITY_AUTHORING_OWNED_PROOF_FAILED',1;
END

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
SELECT N'6_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'CAPABILITY_AUTHORING_UNRELATED_CAPABILITY_CHANGED',1;
GO
-- Installer acceptance refusal (dooms the transaction; the same batch rolls back).
SET XACT_ABORT OFF;
BEGIN TRY
 DECLARE @probe_payload nvarchar(max)=(SELECT N'capability-authoring-change.v1' AS contractId,
  N'lane3-authoring-proof.no-decision' AS candidateId,N'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' AS bundleDigest,
  N'lane3-authoring-proof' AS capabilityId,
  JSON_QUERY(N'{"document":"sidefx-capability-authority.v1","capabilityId":"lane3-authoring-proof","scenarios":[{"scenarioId":"probe"}]}') AS document,
  JSON_QUERY(N'{"input":{"objective":"probe"},"expected":{"disposition":"terminated"}}') AS preflight,
  JSON_QUERY(N'{"resolvedDisposition":"terminated"}') AS route FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC model.install_capability_authoring_change @document=@probe_payload;
 SELECT N'7_acceptance_probe' AS result_set,N'NOT_THROWN' AS disposition;
END TRY
BEGIN CATCH
 SELECT N'7_acceptance_probe' AS result_set,ERROR_MESSAGE() AS disposition,
  CASE WHEN ERROR_MESSAGE()=N'CANDIDATE_NOT_ACCEPTED' THEN N'PASSED' ELSE N'FAILED' END AS probe_result;
END CATCH
ROLLBACK TRANSACTION;
