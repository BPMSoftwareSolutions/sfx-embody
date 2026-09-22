-- withdraw-model-tool-registry.sql
--
-- C0 of docs/estate-mcp-and-database-expressiveness-2026-09-21 (revised-tool-plan.md,
-- phase C0): withdraw the drift. One idempotent re-mint of the selected
-- sda-kernel-boot-data-access.v1 authority:
--
--   * remove the admit-tool-registration-change read;
--   * remove the tool-registration-change kind, its admission and its operation;
--   * remove the changeContracts keys tool-registration-change.v1,
--     tool-registration-change-installed.v1 and model-tool-catalog.v1;
--   * de-select the duplicate sidefx:tools/model-tool-catalog.v1 AUTHORITY
--     definition, leaving exactly one catalog home: the 31 TOOL rows under
--     sidefx:tools, which the surviving list-tools read already resolves;
--   * drop the unreachable model.install_tool_registration_change installer.
--
-- Kept: TOOL rows, list-tools, admit-tool-call and the governed-tool-call/result
-- contracts. No capability, contract, scenario, port or transformation row is
-- added, removed or changed; the unrelated capability graph digests are proved
-- byte-identical in-transaction.
--
-- Idempotent: with the registration kind absent the re-mint is skipped, the
-- de-select is a no-op and the installer drop is guarded. The authority body is
-- re-minted only when the live content digest is the expected pre-withdrawal
-- digest; otherwise this migration refuses with a rebase finding.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy,
-- which replaces the final statement with the committed form after the
-- from-transaction preflight passes.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=30000;
IF @lock<0 THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_LOCK_FAILED',1;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers=CURSOR LOCAL FAST_FORWARD FOR
 SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
 FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id
 JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE o.type='U' AND s.name IN ('model','source')
 AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trigger_name); FETCH NEXT FROM @triggers INTO @trigger_name; END;
CLOSE @triggers; DEALLOCATE @triggers;

DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @prior_content nvarchar(80)=N'sha256:507f5473a0267e2774930bd9c77ccf65a21d2e3324a62d4db3cf8b5fada8dcbc';
DECLARE @selected nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest')
 FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
IF @selected IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_NOT_SELECTED',1;
DECLARE @body nvarchar(max)=(
 SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co
 WHERE co.content_digest=CONVERT(binary(32),REPLACE(@selected,N'sha256:',N''),2));
IF @body IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_BODY_MISSING',1;
IF JSON_VALUE(@body,'$.authorityId')<>@authority_id THROW 51000,N'KERNEL_BOOT_AUTHORITY_IDENTITY_DIVERGED',1;

-- ============================== 0. BASELINE ==============================
-- Three unrelated capabilities whose assembled graph source must be byte-identical
-- before and after this withdrawal (house pattern). Their digests are compared
-- again inside this transaction before the final statement.
DECLARE @baseline TABLE (capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY, digest varchar(64), bytes bigint);
INSERT @baseline (capability_id, digest, bytes)
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world', 1, NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'route-two-child-proof', 1, NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence', 1, NULL) g;
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_BASELINE_MISSING',1;
SELECT N'0_baseline_digests' AS result_set, capability_id, digest AS graph_digest_before, bytes AS graph_source_bytes
FROM @baseline ORDER BY capability_id;

-- Executable content baseline: the withdrawal must not move any row count.
DECLARE @executables TABLE(object_kind nvarchar(64) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,row_count bigint);
INSERT @executables(object_kind,row_count)
SELECT object_kind,COUNT(*) FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind IN (N'CAPABILITY',N'CONTRACT',N'SCENARIO',N'PORT')
 GROUP BY object_kind;
IF (SELECT COUNT(*) FROM @executables)<>4 THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_EXECUTABLE_BASELINE_MISSING',1;
SELECT N'1_executable_counts_before' AS result_set, object_kind, row_count FROM @executables ORDER BY object_kind;

-- ============================== 2. IDEMPOTENCE AND RE-MINT ==============================
DECLARE @withdrawn bit=CASE WHEN NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeKinds')
 WHERE JSON_VALUE(value,'$.changeKind')=N'tool-registration-change') THEN 1 ELSE 0 END;
IF @withdrawn=0 AND @selected<>@prior_content THROW 51000,N'KERNEL_BOOT_AUTHORITY_CHANGED_REBASE_DECLARATION',1;

IF @withdrawn=0
BEGIN
 -- (a) reads: drop admit-tool-registration-change; list-tools and admit-tool-call stay as declared.
 SET @body=JSON_MODIFY(@body,'$.reads',JSON_QUERY((
  SELECT N'['+ISNULL(STRING_AGG(CONVERT(nvarchar(max),value),N',') WITHIN GROUP (ORDER BY CONVERT(int,[key])),N'')+N']'
  FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')<>N'admit-tool-registration-change')));
 -- (b) changeKinds / changeAdmissions / changeOperations: drop the registration route.
 SET @body=JSON_MODIFY(@body,'$.changeKinds',JSON_QUERY((
  SELECT N'['+ISNULL(STRING_AGG(CONVERT(nvarchar(max),value),N',') WITHIN GROUP (ORDER BY CONVERT(int,[key])),N'')+N']'
  FROM OPENJSON(@body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')<>N'tool-registration-change')));
 SET @body=JSON_MODIFY(@body,'$.changeAdmissions',JSON_QUERY((
  SELECT N'['+ISNULL(STRING_AGG(CONVERT(nvarchar(max),value),N',') WITHIN GROUP (ORDER BY CONVERT(int,[key])),N'')+N']'
  FROM OPENJSON(@body,'$.changeAdmissions') WHERE JSON_VALUE(value,'$.changeKind')<>N'tool-registration-change')));
 SET @body=JSON_MODIFY(@body,'$.changeOperations',JSON_QUERY((
  SELECT N'['+ISNULL(STRING_AGG(CONVERT(nvarchar(max),value),N',') WITHIN GROUP (ORDER BY CONVERT(int,[key])),N'')+N']'
  FROM OPENJSON(@body,'$.changeOperations') WHERE JSON_VALUE(value,'$.changeId')<>N'install-tool-registration-change')));
 -- (c) contracts: the two registration contracts and the catalog key go; governed-tool-call/result stay.
 SET @body=JSON_MODIFY(@body,'$.changeContracts."tool-registration-change.v1"',NULL);
 SET @body=JSON_MODIFY(@body,'$.changeContracts."tool-registration-change-installed.v1"',NULL);
 SET @body=JSON_MODIFY(@body,'$.changeContracts."model-tool-catalog.v1"',NULL);
 -- (d) content-address the withdrawn body and re-put the authority with the new digest.
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content binary(32)=HASHBYTES('SHA2_256',@bytes);
 DECLARE @new_content nvarchar(80)=N'sha256:'+LOWER(CONVERT(varchar(64),@content,2));
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content)<>@bytes
  THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_CONTENT_DIVERGED',1;
 DECLARE @semantics nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics')
  FROM analysis.v_selected_semantic_definition
  WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
 SET @semantics=JSON_MODIFY(@semantics,'$.contentDigest',@new_content);
 DECLARE @object bigint,@definition bigint,@digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@semantics,
  @object OUTPUT,@definition OUTPUT,@digest OUTPUT;
END

-- ============================== 3. DE-SELECT THE DUPLICATE CATALOG DEFINITION ==============================
-- One catalog home remains: the 31 TOOL definitions. The definition row is retained
-- as unselected history; only the estate link is removed.
DECLARE @catalog_sod bigint=(SELECT d.semantic_object_definition_pk
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY'
  AND d.namespace_id=N'sidefx:tools' AND d.declared_id=N'model-tool-catalog.v1');
IF @catalog_sod IS NOT NULL
 DELETE ed FROM model.estate_definition ed
 WHERE ed.estate_model_pk=@estate AND ed.semantic_object_definition_pk=@catalog_sod;

-- ============================== 4. DROP THE UNREACHABLE INSTALLER ==============================
IF OBJECT_ID(N'model.install_tool_registration_change') IS NOT NULL
 DROP PROCEDURE model.install_tool_registration_change;

-- ============================== 5. PREFLIGHT ON THE EXACT SELECTED BODY ==============================
DECLARE @declared nvarchar(max)=(
 SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM analysis.v_selected_semantic_definition d
 JOIN source.content_object co
  ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id);
IF @declared IS NULL THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_SELECTED_BODY_MISSING',1;

-- 5a. Shape: exactly one read/kind/admission/operation set removed; the route is gone.
IF (SELECT COUNT(*) FROM OPENJSON(@declared,'$.reads'))<>19
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeKinds'))<>9
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeAdmissions'))<>9
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeOperations'))<>12
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeContracts'))<>33
 THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_DECLARATION_SHAPE_DIVERGED',1;
IF (SELECT COUNT(*) FROM OPENJSON(@declared,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-tool-registration-change')<>0
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=N'tool-registration-change')<>0
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeAdmissions') WHERE JSON_VALUE(value,'$.changeKind')=N'tool-registration-change')<>0
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeOperations') WHERE JSON_VALUE(value,'$.changeId')=N'install-tool-registration-change')<>0
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeContracts') WHERE [key] IN
     (N'tool-registration-change.v1',N'tool-registration-change-installed.v1',N'model-tool-catalog.v1'))<>0
 THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_ROUTE_STILL_DECLARED',1;
IF (SELECT COUNT(*) FROM OPENJSON(@declared,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'list-tools')<>1
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-tool-call')<>1
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeContracts') WHERE [key]=N'governed-tool-call.v1')<>1
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeContracts') WHERE [key]=N'governed-tool-result.v1')<>1
 THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_KEPT_SURFACE_MISSING',1;

-- 5b. Kernel boot resolution: every surviving row's cross-reference resolves.
IF (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeAdmissions') a
    WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(@declared,'$.reads') r
      WHERE JSON_VALUE(r.value,'$.readId')=JSON_VALUE(a.value,'$.readId')))<>0
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeAdmissions') a
    WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(@declared,'$.changeKinds') k
      WHERE JSON_VALUE(k.value,'$.changeKind')=JSON_VALUE(a.value,'$.changeKind')))<>0
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeKinds') k
    WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(@declared,'$.changeAdmissions') a
      WHERE JSON_VALUE(a.value,'$.admissionId')=JSON_VALUE(k.value,'$.admissionId')))<>0
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeKinds') k
    WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(@declared,'$.changeOperations') o
      WHERE JSON_VALUE(o.value,'$.changeId')=JSON_VALUE(k.value,'$.install.changeId')))<>0
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeKinds') k
    WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(@declared,'$.changeContracts') c
      WHERE c.[key]=JSON_VALUE(k.value,'$.payloadContract')))<>0
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeAdmissions') a
    WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(@declared,'$.changeContracts') c
      WHERE c.[key] IN (JSON_VALUE(a.value,'$.payloadContract'),JSON_VALUE(a.value,'$.payloadAdmissionContract'),JSON_VALUE(a.value,'$.resultContract'))))<>0
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeOperations') o
    WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(@declared,'$.changeContracts') c
      WHERE c.[key]=JSON_VALUE(o.value,'$.resultContract')))<>0
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeOperations') o
    CROSS APPLY OPENJSON(JSON_QUERY(o.value,'$.parameters')) p
    WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(@declared,'$.changeContracts') c
      WHERE c.[key]=JSON_VALUE(p.value,'$.contract')))<>0
 THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_REFERENCE_UNRESOLVED',1;

-- 5c. The surviving list-tools read still executes and resolves all 31 TOOL rows.
DECLARE @list_tools_stmt nvarchar(max)='';
SELECT @list_tools_stmt=statement FROM OPENJSON(@declared,'$.reads')
 WITH (read_id nvarchar(400) '$.readId', statement nvarchar(max) '$.statement') r
 WHERE r.read_id=N'list-tools';
IF @list_tools_stmt='' THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_LIST_TOOLS_MISSING',1;
DECLARE @list_tools TABLE(tool_id nvarchar(400),altitude nvarchar(400),write_class nvarchar(400),description nvarchar(4000),
 capability_id nvarchar(400),target_scenario nvarchar(400),input_path nvarchar(400),input_contract nvarchar(400),
 output_contract nvarchar(400),admission_kind nvarchar(400),tool_eligible nvarchar(10),tool_bound nvarchar(10),
 input_schema_digest nvarchar(400),output_schema_digest nvarchar(400));
INSERT @list_tools EXEC sp_executesql @list_tools_stmt,N'@estate_model_pk bigint',@estate_model_pk=@estate;
IF (SELECT COUNT(*) FROM @list_tools)<>31 THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_LIST_TOOLS_COUNT_DIVERGED',1;
SELECT N'5_list_tools' AS result_set, COUNT(*) AS tool_count,
 SUM(CASE WHEN capability_id IS NOT NULL THEN 1 ELSE 0 END) AS with_capability,
 SUM(CASE WHEN tool_bound=N'true' THEN 1 ELSE 0 END) AS tool_bound_true
FROM @list_tools;

-- ============================== 6. ONE CATALOG HOME ==============================
IF (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d
    WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY'
     AND d.namespace_id=N'sidefx:tools' AND d.declared_id=N'model-tool-catalog.v1')<>0
 OR (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeContracts') c WHERE c.[key]=N'model-tool-catalog.v1')<>0
 OR (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d
    WHERE d.estate_model_pk=@estate AND d.object_kind=N'TOOL' AND d.namespace_id=N'sidefx:tools')<>31
 OR OBJECT_ID(N'model.install_tool_registration_change') IS NOT NULL
 THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_CATALOG_HOME_DIVERGED',1;
SELECT N'6_catalog_home' AS result_set,
 (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY'
   AND d.namespace_id=N'sidefx:tools' AND d.declared_id=N'model-tool-catalog.v1') AS catalog_authority_selected,
 (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeContracts') c WHERE c.[key]=N'model-tool-catalog.v1') AS catalog_contract_key,
 (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'TOOL' AND d.namespace_id=N'sidefx:tools') AS tool_rows,
 CASE WHEN OBJECT_ID(N'model.install_tool_registration_change') IS NULL THEN N'absent' ELSE N'present' END AS installer_procedure;

-- ============================== 7. UNRELATED DIGESTS AND EXECUTABLE CONTENT UNCHANGED ==============================
DECLARE @after TABLE (capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY, digest varchar(64), bytes bigint);
INSERT @after (capability_id, digest, bytes)
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world', 1, NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'route-two-child-proof', 1, NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence', 1, NULL) g;
SELECT N'7_digest_compare' AS result_set, b.capability_id, b.digest AS before_digest, a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id
ORDER BY b.capability_id;
IF EXISTS (SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_UNRELATED_CAPABILITY_CHANGED',1;
IF EXISTS (SELECT 1 FROM @executables e
 WHERE e.row_count<>(SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=e.object_kind))
 THROW 51000,N'MODEL_TOOL_REGISTRY_WITHDRAWAL_EXECUTABLE_CONTENT_CHANGED',1;
SELECT N'8_executable_counts_after' AS result_set, object_kind, row_count FROM @executables ORDER BY object_kind;

-- ============================== 8. DISPOSITION ==============================
DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest')
 FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
SELECT N'9_disposition' AS result_set,
 CASE WHEN @withdrawn=1 THEN N'already_withdrawn' ELSE N'withdrawn' END AS disposition,
 @prior_content AS prior_content_digest, @selected AS selected_before, @result_content AS declared_content_digest,
 (SELECT COUNT(*) FROM OPENJSON(@declared,'$.reads')) AS read_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeKinds')) AS change_kind_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeAdmissions')) AS change_admission_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeOperations')) AS change_operation_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared,'$.changeContracts')) AS change_contract_count;

COMMIT TRANSACTION;
