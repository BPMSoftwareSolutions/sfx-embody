-- declare-authoring-writer-kinds-skeleton.sql
--
-- Write-seam skeleton, deliverable 1: declare the six authoring writer change
-- kinds in the selected sda-kernel-boot-data-access.v1 authority as
-- refuse-by-default rows. Nothing installs content in this wave.
--
-- For each kind K in (capability-authoring, contract-change, scenario-authoring,
-- transformation-change, execution-authority-change, feature-binding-change) this
-- migration declares:
--   * a changeKinds row: changeKind K, payloadContract K-change.v1, admissionId
--     K-admission.v1, install {changeId install-K-change, parameterName document},
--     and the bounded capability-invocation verification recipe used by the live
--     provider-binding kind (capabilityPath capabilityId, preflight input/expected,
--     route.resolvedDisposition);
--   * a changeAdmissions row with lifecycle ADMITTED, one granted procedure
--     model.install_<K>_change, the model-write-guards suspension set, the
--     observation admission read admit-K-change and result change-admitted.v1.
--     The policy is admitted so the kind is reachable; the read still refuses;
--   * a changeOperations row (classification effect, serializable, guard restore);
--   * an observation admission read admit-K-change that validates the document
--     against its closed changeContract and, on a valid document, returns HELD
--     with the named reason <K>_NOT_IMPLEMENTED. Invalid documents are HELD with
--     field-named validation findings instead. It writes nothing;
--   * a closed payload changeContract K-change.v1 and its result contract
--     K-change-installed.v1.
--
-- The installer procedures model.install_<K>_change are created here and refuse
-- with <K>_NOT_IMPLEMENTED after the transaction/document preconditions; they
-- write nothing. No capability, contract, scenario, port, transformation,
-- provider, TOOL or candidate row is touched.
--
-- Idempotent: the authority body is re-minted only when the six kinds, six reads
-- and twelve contracts are absent; a replay prints already_declared and writes
-- nothing (put_semantic_definition is digest-idempotent; CREATE OR ALTER is
-- re-runnable).
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=30000;
IF @lock<0 THROW 51000,N'AUTHORING_WRITER_KINDS_LOCK_FAILED',1;
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
 IF ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'capability-authoring-change.v1'
  THROW 51000,'CAPABILITY_AUTHORING_DOCUMENT_REQUIRED',1;
 THROW 51000,'CAPABILITY_AUTHORING_NOT_IMPLEMENTED',1;
END;
GO
CREATE OR ALTER PROCEDURE model.install_contract_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'CONTRACT_CHANGE_TRANSACTION_REQUIRED',1;
 IF ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'contract-change.v1'
  THROW 51000,'CONTRACT_CHANGE_DOCUMENT_REQUIRED',1;
 THROW 51000,'CONTRACT_CHANGE_NOT_IMPLEMENTED',1;
END;
GO
CREATE OR ALTER PROCEDURE model.install_scenario_authoring_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'SCENARIO_AUTHORING_TRANSACTION_REQUIRED',1;
 IF ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'scenario-authoring-change.v1'
  THROW 51000,'SCENARIO_AUTHORING_DOCUMENT_REQUIRED',1;
 THROW 51000,'SCENARIO_AUTHORING_NOT_IMPLEMENTED',1;
END;
GO
CREATE OR ALTER PROCEDURE model.install_transformation_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'TRANSFORMATION_CHANGE_TRANSACTION_REQUIRED',1;
 IF ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'transformation-change.v1'
  THROW 51000,'TRANSFORMATION_CHANGE_DOCUMENT_REQUIRED',1;
 THROW 51000,'TRANSFORMATION_CHANGE_NOT_IMPLEMENTED',1;
END;
GO
CREATE OR ALTER PROCEDURE model.install_execution_authority_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'EXECUTION_AUTHORITY_CHANGE_TRANSACTION_REQUIRED',1;
 IF ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'execution-authority-change.v1'
  THROW 51000,'EXECUTION_AUTHORITY_CHANGE_DOCUMENT_REQUIRED',1;
 THROW 51000,'EXECUTION_AUTHORITY_CHANGE_NOT_IMPLEMENTED',1;
END;
GO
CREATE OR ALTER PROCEDURE model.install_feature_binding_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'FEATURE_BINDING_CHANGE_TRANSACTION_REQUIRED',1;
 IF ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'feature-binding-change.v1'
  THROW 51000,'FEATURE_BINDING_CHANGE_DOCUMENT_REQUIRED',1;
 THROW 51000,'FEATURE_BINDING_CHANGE_NOT_IMPLEMENTED',1;
END;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @prior_content nvarchar(80)=N'sha256:d1e731252977992a331696fbf21ee53f59844cddcef5bf2ca41a737d32c7abc7';
DECLARE @selected nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
IF @selected IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_NOT_SELECTED',1;
DECLARE @body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@selected,N'sha256:',N''),2));
IF @body IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_BODY_MISSING',1;
IF JSON_VALUE(@body,'$.authorityId')<>@authority_id THROW 51000,N'KERNEL_BOOT_AUTHORITY_IDENTITY_DIVERGED',1;

DECLARE @kinds TABLE(ordinal int NOT NULL PRIMARY KEY,
 change_kind nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
 prefix nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
 payload_contract nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
 base_id nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
 procedure_name nvarchar(300) COLLATE Latin1_General_100_BIN2 NOT NULL,
 installed_contract nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT @kinds(ordinal,change_kind,prefix,payload_contract,base_id,procedure_name,installed_contract) VALUES
 (1,N'capability-authoring',N'CAPABILITY_AUTHORING',N'capability-authoring-change.v1',N'capability-authoring-change',N'model.install_capability_authoring_change',N'capability-authoring-change-installed.v1'),
 (2,N'contract-change',N'CONTRACT_CHANGE',N'contract-change.v1',N'contract-change',N'model.install_contract_change',N'contract-change-installed.v1'),
 (3,N'scenario-authoring',N'SCENARIO_AUTHORING',N'scenario-authoring-change.v1',N'scenario-authoring-change',N'model.install_scenario_authoring_change',N'scenario-authoring-change-installed.v1'),
 (4,N'transformation-change',N'TRANSFORMATION_CHANGE',N'transformation-change.v1',N'transformation-change',N'model.install_transformation_change',N'transformation-change-installed.v1'),
 (5,N'execution-authority-change',N'EXECUTION_AUTHORITY_CHANGE',N'execution-authority-change.v1',N'execution-authority-change',N'model.install_execution_authority_change',N'execution-authority-change-installed.v1'),
 (6,N'feature-binding-change',N'FEATURE_BINDING_CHANGE',N'feature-binding-change.v1',N'feature-binding-change',N'model.install_feature_binding_change',N'feature-binding-change-installed.v1');
IF (SELECT COUNT(*) FROM @kinds)<>6 THROW 51000,N'AUTHORING_WRITER_KINDS_TABLE_INCOMPLETE',1;

DECLARE @declared bit=CASE WHEN
 (SELECT COUNT(*) FROM @kinds k WHERE EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=k.change_kind))=6
 AND (SELECT COUNT(*) FROM @kinds k WHERE EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-'+k.base_id))=6
 AND (SELECT COUNT(*) FROM OPENJSON(@body,'$.changeContracts') WHERE [key] IN (
  N'capability-authoring-change.v1',N'capability-authoring-change-installed.v1',
  N'contract-change.v1',N'contract-change-installed.v1',
  N'scenario-authoring-change.v1',N'scenario-authoring-change-installed.v1',
  N'transformation-change.v1',N'transformation-change-installed.v1',
  N'execution-authority-change.v1',N'execution-authority-change-installed.v1',
  N'feature-binding-change.v1',N'feature-binding-change-installed.v1'))=12
 THEN 1 ELSE 0 END;
IF @declared=0 AND @selected<>@prior_content THROW 51000,N'KERNEL_BOOT_AUTHORITY_CHANGED_REBASE_DECLARATION',1;

-- Baseline assembled graph digests of three unrelated capabilities, compared again
-- after the declaration inside this transaction.
DECLARE @baseline TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @baseline(capability_id,digest,bytes)
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'authoring-altitude-model-stubs',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g;
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'AUTHORING_WRITER_KINDS_BASELINE_MISSING',1;
SELECT N'0_baseline_digests' AS result_set,capability_id,digest AS graph_digest_before,bytes AS graph_source_bytes FROM @baseline ORDER BY capability_id;

-- Shared admission read body. {{K}} is the changeKind, {{P}} the finding-code prefix.
DECLARE @admission_template nvarchar(max)=N'DECLARE @findings TABLE(ordinal int IDENTITY(1,1),code nvarchar(100),field nvarchar(400),message nvarchar(2000));
IF ISJSON(@input)<>1
 INSERT @findings(code,field,message) VALUES(N''{{P}}_DOCUMENT_REQUIRED'',NULL,N''the document must be a JSON {{C}}'');
ELSE BEGIN
 DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.capabilityId''),N'''');
 IF JSON_VALUE(@input,''$.contractId'')<>N''{{C}}''
  INSERT @findings(code,field,message) VALUES(N''{{P}}_CONTRACT_REQUIRED'',N''contractId'',N''contractId must be {{C}}'');
 IF @capability_id IS NULL
  INSERT @findings(code,field,message) VALUES(N''{{P}}_CAPABILITY_REQUIRED'',N''capabilityId'',N''the document must name the capability it authors'');
 IF JSON_QUERY(@input,''$.preflight.input'') IS NULL
  INSERT @findings(code,field,message) VALUES(N''{{P}}_PREFLIGHT_INPUT_REQUIRED'',N''preflight.input'',N''the document must carry its preflight input object'');
 IF JSON_VALUE(@input,''$.route.resolvedDisposition'') IS NULL
  INSERT @findings(code,field,message) VALUES(N''{{P}}_ROUTE_DISPOSITION_REQUIRED'',N''route.resolvedDisposition'',N''the document must carry its resolved disposition'');
 IF (SELECT COUNT(*) FROM @findings)=0
  INSERT @findings(code,field,message) VALUES(N''{{P}}_NOT_IMPLEMENTED'',NULL,N''the {{K}} installer is a declared skeleton in the write-seam wave; no writer is implemented and nothing is installed'');
END
DECLARE @reason nvarchar(max)=ISNULL((SELECT code,field,message FROM @findings ORDER BY ordinal FOR JSON PATH),N''[]'');
SELECT CASE WHEN (SELECT COUNT(*) FROM @findings)=0 THEN N''ADMITTED'' ELSE N''HELD'' END AS disposition,@reason AS reason';

IF @declared=0
BEGIN
 DECLARE @k_ordinal int,@change_kind nvarchar(200),@prefix nvarchar(100),@payload_contract_id nvarchar(200),@base_id nvarchar(200),
  @procedure_name nvarchar(300),@installed_contract_id nvarchar(200);
 DECLARE @admit_stmt nvarchar(max),@admit_read nvarchar(max),@kind_row nvarchar(max),@admission_row nvarchar(max),
  @operation_row nvarchar(max),@payload_contract_body nvarchar(max),@installed_contract_body nvarchar(max);
 DECLARE kind_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal,change_kind,prefix,payload_contract,base_id,procedure_name,installed_contract FROM @kinds ORDER BY ordinal;
 OPEN kind_cursor;
 FETCH NEXT FROM kind_cursor INTO @k_ordinal,@change_kind,@prefix,@payload_contract_id,@base_id,@procedure_name,@installed_contract_id;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @admit_stmt=REPLACE(REPLACE(REPLACE(@admission_template,N'{{K}}',@change_kind),N'{{P}}',@prefix),N'{{C}}',@payload_contract_id);
  SET @kind_row=(SELECT @change_kind AS changeKind,@payload_contract_id AS payloadContract,
   @base_id+N'-admission.v1' AS admissionId,
   JSON_QUERY(N'{"changeId":"install-'+@base_id+N'","parameterName":"document"}') AS install,
   JSON_QUERY(N'{"kind":"capability-invocation","capabilityPath":"capabilityId","inputPath":"preflight.input","expectedPath":"preflight.expected","dispositionPath":"route.resolvedDisposition"}') AS verification
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @admission_row=(SELECT @base_id+N'-admission.v1' AS admissionId,N'ADMITTED' AS lifecycle,@change_kind AS changeKind,
   @payload_contract_id AS payloadContract,@payload_contract_id AS payloadAdmissionContract,
   N'install-'+@base_id AS changeId,N'document' AS parameterName,
   N'admit-'+@base_id AS readId,N'change-admitted.v1' AS resultContract,
   JSON_QUERY(N'{"executeProcedure":{"sourceKind":"tsql","name":"'+@procedure_name+N'"},"suspendGuardSets":["model-write-guards"]}') AS privileges
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @operation_row=(SELECT N'install-'+@base_id AS changeId,N'tsql' AS sourceKind,N'effect' AS classification,
   JSON_QUERY(N'{"kind":"procedure","name":"'+@procedure_name+N'"}') AS operation,
   JSON_QUERY(N'[{"name":"document","contract":"'+@payload_contract_id+N'","binding":"parameter","encoding":"json"}]') AS parameters,
   @installed_contract_id AS resultContract,
   JSON_QUERY(N'{"transaction":"required","isolation":"serializable"}') AS scope,
   JSON_QUERY(N'[{"declaredGuardSuspension":"model-write-guards","restoreRequired":true}]') AS preconditions
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @payload_contract_body=(SELECT N'Skeleton '+@change_kind+N' change' AS title,
   N'Refuse-by-default skeleton payload for the '+@change_kind+N' kind: a document that validates against this closed shape is HELD with '+@prefix+N'_NOT_IMPLEMENTED. No writer is implemented in the write-seam wave.' AS description,
   N'object' AS [type],CONVERT(bit,0) AS additionalProperties,
   JSON_QUERY(N'["contractId","capabilityId","preflight","route"]') AS [required],
   JSON_QUERY(N'{"contractId":{"const":"'+@payload_contract_id+N'"},"capabilityId":{"type":"string","minLength":1,"maxLength":400},"preflight":{"type":"object","additionalProperties":false,"required":["input"],"properties":{"input":{"type":"object"},"expected":{"type":"object"}}},"route":{"type":"object","additionalProperties":false,"required":["resolvedDisposition"],"properties":{"resolvedDisposition":{"type":"string","minLength":1,"maxLength":100}}}}') AS properties
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @installed_contract_body=(SELECT N'Skeleton '+@change_kind+N' installed result' AS title,
   N'Refuse-by-default result contract for the '+@change_kind+N' kind: the skeleton installer raises '+@prefix+N'_NOT_IMPLEMENTED before any write and never returns this shape.' AS description,
   N'object' AS [type],CONVERT(bit,0) AS additionalProperties,
   JSON_QUERY(N'["result_set","reason"]') AS [required],
   JSON_QUERY(N'{"result_set":{"const":"'+@change_kind+N'_not_implemented"},"reason":{"type":"string","minLength":1,"maxLength":400}}') AS properties
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @admit_read=(SELECT N'admit-'+@base_id AS readId,
   N'Validate a '+@payload_contract_id+N' document against its closed skeleton contract; a valid document returns HELD with '+@prefix+N'_NOT_IMPLEMENTED because this wave declares the kind only and installs no writer. Invalid documents are HELD with field-named findings. Writes nothing.' AS purpose,
   N'observation' AS classification,N'tsql' AS sourceKind,@admit_stmt AS statement
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@admit_read));
  SET @body=JSON_MODIFY(@body,'append $.changeKinds',JSON_QUERY(@kind_row));
  SET @body=JSON_MODIFY(@body,'append $.changeAdmissions',JSON_QUERY(@admission_row));
  SET @body=JSON_MODIFY(@body,'append $.changeOperations',JSON_QUERY(@operation_row));
  SET @body=JSON_MODIFY(@body,'$.changeContracts."'+@payload_contract_id+N'"',JSON_QUERY(@payload_contract_body));
  SET @body=JSON_MODIFY(@body,'$.changeContracts."'+@installed_contract_id+N'"',JSON_QUERY(@installed_contract_body));
  FETCH NEXT FROM kind_cursor INTO @k_ordinal,@change_kind,@prefix,@payload_contract_id,@base_id,@procedure_name,@installed_contract_id;
 END
 CLOSE kind_cursor; DEALLOCATE kind_cursor;
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content binary(32)=HASHBYTES('SHA2_256',@bytes);
 DECLARE @new_content nvarchar(80)=N'sha256:'+LOWER(CONVERT(varchar(64),@content,2));
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content)<>@bytes THROW 51000,N'AUTHORING_WRITER_KINDS_CONTENT_DIVERGED',1;
 DECLARE @authority_semantics nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
  WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
 SET @authority_semantics=JSON_MODIFY(@authority_semantics,'$.contentDigest',@new_content);
 DECLARE @authority_object bigint,@authority_definition bigint,@authority_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@authority_semantics,@authority_object OUTPUT,@authority_definition OUTPUT,@authority_digest OUTPUT;
END

-- Verify the selected body, freshly declared or replayed.
DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
DECLARE @declared_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@result_content,N'sha256:',N''),2));
IF @declared_body IS NULL THROW 51000,N'AUTHORING_WRITER_KINDS_BODY_MISSING',1;
IF JSON_VALUE(@declared_body,'$.authorityDigest')<>N'sha256:a34639fce305a43c02c4cc5f072a4e3a98c1f1ba90ffb23739d321a9e21a7db3'
 THROW 51000,N'AUTHORING_WRITER_KINDS_AUTHORITY_DIGEST_DIVERGED',1;
IF (SELECT COUNT(*) FROM @kinds k WHERE EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=k.change_kind))<>6
 OR (SELECT COUNT(*) FROM @kinds k WHERE EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-'+k.base_id))<>6
 OR (SELECT COUNT(*) FROM @kinds k WHERE EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.changeAdmissions') WHERE JSON_VALUE(value,'$.readId')=N'admit-'+k.base_id))<>6
 OR (SELECT COUNT(*) FROM @kinds k WHERE EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.changeOperations') WHERE JSON_VALUE(value,'$.changeId')=N'install-'+k.base_id))<>6
 OR (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeContracts') WHERE [key] IN (
  N'capability-authoring-change.v1',N'capability-authoring-change-installed.v1',
  N'contract-change.v1',N'contract-change-installed.v1',
  N'scenario-authoring-change.v1',N'scenario-authoring-change-installed.v1',
  N'transformation-change.v1',N'transformation-change-installed.v1',
  N'execution-authority-change.v1',N'execution-authority-change-installed.v1',
  N'feature-binding-change.v1',N'feature-binding-change-installed.v1'))<>12
 THROW 51000,N'AUTHORING_WRITER_KINDS_DECLARATION_INCOMPLETE',1;

-- Admission proof: every kind, given a valid document, must answer HELD with its
-- named NOT_IMPLEMENTED reason; an invalid document must answer HELD with the
-- field-named validation finding and never ADMITTED.
DECLARE @admission_proof TABLE(change_kind nvarchar(200) COLLATE Latin1_General_100_BIN2,disposition nvarchar(20),reason nvarchar(max));
DECLARE @single TABLE(disposition nvarchar(20),reason nvarchar(max));
DECLARE @p_change_kind nvarchar(200),@p_prefix nvarchar(100),@p_payload_contract nvarchar(200),@p_base_id nvarchar(200),@p_stmt nvarchar(max),@p_valid nvarchar(max);
DECLARE proof_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT change_kind,prefix,payload_contract,base_id FROM @kinds ORDER BY ordinal;
OPEN proof_cursor;
FETCH NEXT FROM proof_cursor INTO @p_change_kind,@p_prefix,@p_payload_contract,@p_base_id;
WHILE @@FETCH_STATUS=0
BEGIN
 SELECT @p_stmt=JSON_VALUE(value,'$.statement') FROM OPENJSON(@declared_body,'$.reads')
  WHERE JSON_VALUE(value,'$.readId')=N'admit-'+@p_base_id;
 IF @p_stmt IS NULL THROW 51000,N'AUTHORING_WRITER_KINDS_ADMISSION_READ_MISSING',1;
 SET @p_valid=(SELECT @p_payload_contract AS contractId,N'authoring-altitude-model-stubs' AS capabilityId,
  JSON_QUERY(N'{"input":{"objective":"write-seam skeleton probe"},"expected":{"disposition":"terminated"}}') AS preflight,
  JSON_QUERY(N'{"resolvedDisposition":"terminated"}') AS route
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DELETE @single;
 INSERT @single EXEC sp_executesql @p_stmt,N'@input nvarchar(max),@estate_model_pk bigint',@input=@p_valid,@estate_model_pk=@estate;
 SELECT N'2_admission_held' AS result_set,@p_change_kind AS change_kind,disposition,reason FROM @single;
 INSERT @admission_proof(change_kind,disposition,reason) SELECT @p_change_kind,disposition,reason FROM @single;
 FETCH NEXT FROM proof_cursor INTO @p_change_kind,@p_prefix,@p_payload_contract,@p_base_id;
END
CLOSE proof_cursor; DEALLOCATE proof_cursor;
IF (SELECT COUNT(*) FROM @admission_proof)<>6
 OR (SELECT COUNT(*) FROM @admission_proof WHERE disposition=N'HELD' AND reason LIKE N'%NOT_IMPLEMENTED%')<>6
 THROW 51000,N'AUTHORING_WRITER_KINDS_ADMISSION_PROOF_FAILED',1;
SELECT @p_stmt=JSON_VALUE(value,'$.statement') FROM OPENJSON(@declared_body,'$.reads')
 WHERE JSON_VALUE(value,'$.readId')=N'admit-capability-authoring-change';
DECLARE @p_invalid nvarchar(max)=N'{"contractId":"wrong-change.v1","capabilityId":"authoring-altitude-model-stubs","preflight":{"input":{}},"route":{"resolvedDisposition":"terminated"}}';
DELETE @single;
INSERT @single EXEC sp_executesql @p_stmt,N'@input nvarchar(max),@estate_model_pk bigint',@input=@p_invalid,@estate_model_pk=@estate;
SELECT N'2b_admission_invalid_held' AS result_set,N'capability-authoring' AS change_kind,disposition,reason FROM @single;
IF NOT EXISTS(SELECT 1 FROM @single WHERE disposition=N'HELD' AND reason LIKE N'%CONTRACT_REQUIRED%')
 THROW 51000,N'AUTHORING_WRITER_KINDS_INVALID_PROOF_FAILED',1;
IF OBJECT_ID(N'model.install_capability_authoring_change') IS NULL OR OBJECT_ID(N'model.install_contract_change') IS NULL
 OR OBJECT_ID(N'model.install_scenario_authoring_change') IS NULL OR OBJECT_ID(N'model.install_transformation_change') IS NULL
 OR OBJECT_ID(N'model.install_execution_authority_change') IS NULL OR OBJECT_ID(N'model.install_feature_binding_change') IS NULL
 THROW 51000,N'AUTHORING_WRITER_KINDS_INSTALLER_MISSING',1;

-- Unrelated graph digests must be byte-identical.
DECLARE @after TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @after(capability_id,digest,bytes)
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'authoring-altitude-model-stubs',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g;
SELECT N'3_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'AUTHORING_WRITER_KINDS_UNRELATED_CAPABILITY_CHANGED',1;

SELECT N'4_kind_declaration' AS result_set,JSON_VALUE(value,'$.changeKind') AS change_kind,
 JSON_VALUE(value,'$.payloadContract') AS payload_contract,JSON_VALUE(value,'$.install.changeId') AS install_change_id
FROM OPENJSON(@declared_body,'$.changeKinds')
WHERE JSON_VALUE(value,'$.changeKind') IN (SELECT change_kind FROM @kinds)
ORDER BY change_kind;
SELECT N'5_disposition' AS result_set,@authority_id AS authority_id,@result_content AS content_digest,
 CASE WHEN @declared=1 THEN N'already_declared' WHEN @selected=@prior_content THEN N'redeclared' ELSE N'reconciled' END AS disposition,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads')) AS read_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeKinds')) AS kind_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeAdmissions')) AS admission_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeOperations')) AS operation_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeContracts')) AS contract_count;
ROLLBACK TRANSACTION;
