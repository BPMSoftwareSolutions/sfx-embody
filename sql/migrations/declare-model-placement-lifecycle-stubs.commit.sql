-- declare-model-placement-lifecycle-stubs.sql
--
-- Write-seam skeleton, deliverable 2: declare the three model-placement
-- lifecycle writers as refuse-by-default stubs, addressable as boot-authority
-- operations, with the signatures and named refusal code from
-- docs/model-at-each-authoring-altitude-2026-09-21/altitude-model-placement-sql.md
-- §2 (top three missing SQL writers):
--
--   model.install_model_placement_change @document nvarchar(max)
--   model.replace_port_configuration @namespace nvarchar(400),@port nvarchar(400),@configuration_json nvarchar(max)
--   model.retire_model_placement @namespace nvarchar(400),@port nvarchar(400),@disposition nvarchar(100)
--
-- Every body asserts the serializable single-transaction scope and its parameter
-- preconditions, then raises PLACEMENT_WRITER_NOT_IMPLEMENTED. No write of any
-- kind occurs; no port, port_version, operation link, slot, provider or
-- definition row is touched.
--
-- Boot authority: three changeOperations rows (install-model-placement-change,
-- replace-port-configuration, retire-model-placement) with their granted
-- procedure, JSON parameter bindings, serializable scope and guard-restore
-- precondition, plus the closed payload/result contracts they name. No
-- changeKinds or changeAdmissions rows are added: the operations are declared
-- so a future kind can grant them by changeId without another authority re-mint.
--
-- Idempotent: the authority body is re-minted only when the three operations and
-- eight contracts are absent; a replay prints already_declared and writes
-- nothing.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=30000;
IF @lock<0 THROW 51000,N'PLACEMENT_WRITERS_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
CREATE OR ALTER PROCEDURE model.install_model_placement_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'PLACEMENT_TRANSACTION_REQUIRED',1;
 IF ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'model-placement-change.v1'
  THROW 51000,'PLACEMENT_DOCUMENT_REQUIRED',1;
 THROW 51000,'PLACEMENT_WRITER_NOT_IMPLEMENTED',1;
END;
GO
CREATE OR ALTER PROCEDURE model.replace_port_configuration @namespace nvarchar(400),@port nvarchar(400),@configuration_json nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'PLACEMENT_TRANSACTION_REQUIRED',1;
 IF NULLIF(@namespace,N'') IS NULL OR NULLIF(@port,N'') IS NULL THROW 51000,'PLACEMENT_PORT_IDENTITY_REQUIRED',1;
 IF ISJSON(@configuration_json)<>1 THROW 51000,'PLACEMENT_CONFIGURATION_REQUIRED',1;
 THROW 51000,'PLACEMENT_WRITER_NOT_IMPLEMENTED',1;
END;
GO
CREATE OR ALTER PROCEDURE model.retire_model_placement @namespace nvarchar(400),@port nvarchar(400),@disposition nvarchar(100)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'PLACEMENT_TRANSACTION_REQUIRED',1;
 IF NULLIF(@namespace,N'') IS NULL OR NULLIF(@port,N'') IS NULL THROW 51000,'PLACEMENT_PORT_IDENTITY_REQUIRED',1;
 IF NULLIF(@disposition,N'') IS NULL THROW 51000,'PLACEMENT_DISPOSITION_REQUIRED',1;
 THROW 51000,'PLACEMENT_WRITER_NOT_IMPLEMENTED',1;
END;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @prior_content nvarchar(80)=N'sha256:ee4ff4219ea1994b4833017ddc7231f1d29ad56edea31c73d330b053a75ca502';
DECLARE @selected nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
IF @selected IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_NOT_SELECTED',1;
DECLARE @body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@selected,N'sha256:',N''),2));
IF @body IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_BODY_MISSING',1;
IF JSON_VALUE(@body,'$.authorityId')<>@authority_id THROW 51000,N'KERNEL_BOOT_AUTHORITY_IDENTITY_DIVERGED',1;

DECLARE @placement_contracts TABLE(contract_id nvarchar(200) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @placement_contracts(contract_id) VALUES
 (N'model-placement-change.v1'),(N'model-placement-change-installed.v1'),
 (N'placement-namespace.v1'),(N'placement-port-id.v1'),(N'placement-port-configuration.v1'),
 (N'placement-disposition.v1'),(N'port-configuration-replaced.v1'),(N'model-placement-retired.v1');
DECLARE @declared bit=CASE WHEN
 (SELECT COUNT(*) FROM OPENJSON(@body,'$.changeOperations') WHERE JSON_VALUE(value,'$.changeId') IN (N'install-model-placement-change',N'replace-port-configuration',N'retire-model-placement'))=3
 AND (SELECT COUNT(*) FROM @placement_contracts c WHERE EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key] COLLATE Latin1_General_100_BIN2=c.contract_id))=8
 THEN 1 ELSE 0 END;
IF @declared=0 AND @selected<>@prior_content THROW 51000,N'KERNEL_BOOT_AUTHORITY_CHANGED_REBASE_DECLARATION',1;

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
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'PLACEMENT_WRITERS_BASELINE_MISSING',1;

IF @declared=0
BEGIN
 DECLARE @op_install nvarchar(max)=(SELECT N'install-model-placement-change' AS changeId,N'tsql' AS sourceKind,N'effect' AS classification,
  JSON_QUERY(N'{"kind":"procedure","name":"model.install_model_placement_change"}') AS operation,
  JSON_QUERY(N'[{"name":"document","contract":"model-placement-change.v1","binding":"parameter","encoding":"json"}]') AS parameters,
  N'model-placement-change-installed.v1' AS resultContract,
  JSON_QUERY(N'{"transaction":"required","isolation":"serializable"}') AS scope,
  JSON_QUERY(N'[{"declaredGuardSuspension":"model-write-guards","restoreRequired":true}]') AS preconditions
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @op_replace nvarchar(max)=(SELECT N'replace-port-configuration' AS changeId,N'tsql' AS sourceKind,N'effect' AS classification,
  JSON_QUERY(N'{"kind":"procedure","name":"model.replace_port_configuration"}') AS operation,
  JSON_QUERY(N'[{"name":"namespace","contract":"placement-namespace.v1","binding":"parameter","encoding":"json"},{"name":"port","contract":"placement-port-id.v1","binding":"parameter","encoding":"json"},{"name":"configuration_json","contract":"placement-port-configuration.v1","binding":"parameter","encoding":"json"}]') AS parameters,
  N'port-configuration-replaced.v1' AS resultContract,
  JSON_QUERY(N'{"transaction":"required","isolation":"serializable"}') AS scope,
  JSON_QUERY(N'[{"declaredGuardSuspension":"model-write-guards","restoreRequired":true}]') AS preconditions
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @op_retire nvarchar(max)=(SELECT N'retire-model-placement' AS changeId,N'tsql' AS sourceKind,N'effect' AS classification,
  JSON_QUERY(N'{"kind":"procedure","name":"model.retire_model_placement"}') AS operation,
  JSON_QUERY(N'[{"name":"namespace","contract":"placement-namespace.v1","binding":"parameter","encoding":"json"},{"name":"port","contract":"placement-port-id.v1","binding":"parameter","encoding":"json"},{"name":"disposition","contract":"placement-disposition.v1","binding":"parameter","encoding":"json"}]') AS parameters,
  N'model-placement-retired.v1' AS resultContract,
  JSON_QUERY(N'{"transaction":"required","isolation":"serializable"}') AS scope,
  JSON_QUERY(N'[{"declaredGuardSuspension":"model-write-guards","restoreRequired":true}]') AS preconditions
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @c_placement_change nvarchar(max)=N'{"title":"Model placement change (skeleton)","description":"Refuse-by-default skeleton payload for the model-placement writer: the three placement writers raise PLACEMENT_WRITER_NOT_IMPLEMENTED and write nothing in this wave.","type":"object","additionalProperties":false,"required":["contractId","portId","platformCapabilityId","capabilityId","configuration"],"properties":{"contractId":{"const":"model-placement-change.v1"},"portId":{"type":"string","minLength":1,"maxLength":400},"platformCapabilityId":{"enum":["sda-generic-llm-connector-port.v1","sda-governed-http-exchange-port.v1","sda-projected-capability-invocation-port.v2","sda-authority-transformation-port.v1"]},"capabilityId":{"type":"string","minLength":1,"maxLength":400},"configuration":{"type":"object"}}}';
 DECLARE @c_placement_installed nvarchar(max)=N'{"title":"Model placement change installed (skeleton)","description":"Refuse-by-default result contract: the skeleton writer never returns this shape and raises PLACEMENT_WRITER_NOT_IMPLEMENTED first.","type":"object","additionalProperties":false,"required":["result_set","port_id"],"properties":{"result_set":{"enum":["model_placement_installed","already_installed","placement_writer_not_implemented"]},"port_id":{"type":"string","minLength":1,"maxLength":400}}}';
 DECLARE @c_namespace nvarchar(max)=N'{"title":"Placement namespace","description":"The port namespace identity a placement writer addresses (namespace_id, kind-qualified).","type":"string","minLength":1,"maxLength":400}';
 DECLARE @c_port_id nvarchar(max)=N'{"title":"Placement port id","description":"The declared port identity a placement writer addresses.","type":"string","minLength":1,"maxLength":400}';
 DECLARE @c_configuration nvarchar(max)=N'{"title":"Placement port configuration","description":"The replacement port configuration object a placement writer would install.","type":"object"}';
 DECLARE @c_disposition nvarchar(max)=N'{"title":"Placement disposition","description":"The retirement disposition a placement writer would apply.","type":"string","minLength":1,"maxLength":100}';
 DECLARE @c_replaced nvarchar(max)=N'{"title":"Port configuration replaced (skeleton)","description":"Refuse-by-default result contract: the skeleton writer never returns this shape and raises PLACEMENT_WRITER_NOT_IMPLEMENTED first.","type":"object","additionalProperties":false,"required":["result_set","port_id"],"properties":{"result_set":{"enum":["port_configuration_replaced","placement_writer_not_implemented"]},"port_id":{"type":"string","minLength":1,"maxLength":400}}}';
 DECLARE @c_retired nvarchar(max)=N'{"title":"Model placement retired (skeleton)","description":"Refuse-by-default result contract: the skeleton writer never returns this shape and raises PLACEMENT_WRITER_NOT_IMPLEMENTED first.","type":"object","additionalProperties":false,"required":["result_set","port_id"],"properties":{"result_set":{"enum":["model_placement_retired","placement_writer_not_implemented"]},"port_id":{"type":"string","minLength":1,"maxLength":400}}}';
 SET @body=JSON_MODIFY(@body,'append $.changeOperations',JSON_QUERY(@op_install));
 SET @body=JSON_MODIFY(@body,'append $.changeOperations',JSON_QUERY(@op_replace));
 SET @body=JSON_MODIFY(@body,'append $.changeOperations',JSON_QUERY(@op_retire));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."model-placement-change.v1"',JSON_QUERY(@c_placement_change));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."model-placement-change-installed.v1"',JSON_QUERY(@c_placement_installed));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."placement-namespace.v1"',JSON_QUERY(@c_namespace));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."placement-port-id.v1"',JSON_QUERY(@c_port_id));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."placement-port-configuration.v1"',JSON_QUERY(@c_configuration));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."placement-disposition.v1"',JSON_QUERY(@c_disposition));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."port-configuration-replaced.v1"',JSON_QUERY(@c_replaced));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."model-placement-retired.v1"',JSON_QUERY(@c_retired));
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content binary(32)=HASHBYTES('SHA2_256',@bytes);
 DECLARE @new_content nvarchar(80)=N'sha256:'+LOWER(CONVERT(varchar(64),@content,2));
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content)<>@bytes THROW 51000,N'PLACEMENT_WRITERS_CONTENT_DIVERGED',1;
 DECLARE @authority_semantics nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
  WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
 SET @authority_semantics=JSON_MODIFY(@authority_semantics,'$.contentDigest',@new_content);
 DECLARE @authority_object bigint,@authority_definition bigint,@authority_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@authority_semantics,@authority_object OUTPUT,@authority_definition OUTPUT,@authority_digest OUTPUT;
END

DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
DECLARE @declared_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@result_content,N'sha256:',N''),2));
IF @declared_body IS NULL THROW 51000,N'PLACEMENT_WRITERS_BODY_MISSING',1;
IF JSON_VALUE(@declared_body,'$.authorityDigest')<>N'sha256:a34639fce305a43c02c4cc5f072a4e3a98c1f1ba90ffb23739d321a9e21a7db3'
 THROW 51000,N'PLACEMENT_WRITERS_AUTHORITY_DIGEST_DIVERGED',1;
IF (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeOperations') WHERE JSON_VALUE(value,'$.changeId') IN (N'install-model-placement-change',N'replace-port-configuration',N'retire-model-placement'))<>3
 OR (SELECT COUNT(*) FROM @placement_contracts c WHERE EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.changeContracts') WHERE [key] COLLATE Latin1_General_100_BIN2=c.contract_id))<>8
 THROW 51000,N'PLACEMENT_WRITERS_DECLARATION_INCOMPLETE',1;
IF OBJECT_ID(N'model.install_model_placement_change') IS NULL OR OBJECT_ID(N'model.replace_port_configuration') IS NULL
 OR OBJECT_ID(N'model.retire_model_placement') IS NULL
 THROW 51000,N'PLACEMENT_WRITERS_PROCEDURE_MISSING',1;

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
SELECT N'2_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'PLACEMENT_WRITERS_UNRELATED_CAPABILITY_CHANGED',1;

SELECT N'3_placement_operations' AS result_set,JSON_VALUE(value,'$.changeId') AS change_id,
 JSON_VALUE(value,'$.operation.name') AS procedure_name,JSON_VALUE(value,'$.resultContract') AS result_contract
FROM OPENJSON(@declared_body,'$.changeOperations')
WHERE JSON_VALUE(value,'$.changeId') IN (N'install-model-placement-change',N'replace-port-configuration',N'retire-model-placement')
ORDER BY change_id;
SELECT N'4_procedure_signature' AS result_set,p.SPECIFIC_NAME AS procedure_name,p.PARAMETER_NAME AS parameter_name,
 p.DATA_TYPE AS data_type,p.PARAMETER_MODE AS parameter_mode
FROM INFORMATION_SCHEMA.PARAMETERS p
WHERE p.SPECIFIC_SCHEMA=N'model' AND p.SPECIFIC_NAME IN (N'install_model_placement_change',N'replace_port_configuration',N'retire_model_placement')
ORDER BY p.SPECIFIC_NAME,p.ORDINAL_POSITION;
SELECT N'5_disposition' AS result_set,@authority_id AS authority_id,@result_content AS content_digest,
 CASE WHEN @declared=1 THEN N'already_declared' WHEN @selected=@prior_content THEN N'redeclared' ELSE N'reconciled' END AS disposition,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeOperations')) AS operation_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeContracts')) AS contract_count;
COMMIT TRANSACTION;
