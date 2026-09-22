-- declare-candidate-read-and-tool-bindings.sql
--
-- Write-seam skeleton, deliverable 3: make the propose path readable and bind the
-- 31 declared TOOL rows to their authoring-altitude targets, plus a minimal lane
-- route stub. Row only: no capability, contract, scenario, port, transformation
-- or provider row changes.
--
-- Boot authority (selected sda-kernel-boot-data-access.v1):
--   * list-tools is re-declared to resolve the TOOL rows themselves (the P0 read
--     resolved the withdrawn-catalog entries). It now carries each tool binding
--     (capability_id, target_scenario, input_path, binding_kind), the declared
--     tool_eligible flag and the derived tool_bound flag (the bound capability
--     resolves in the selected estate);
--   * candidate.read is declared (it did not exist): it resolves filed
--     capability candidates from the AUTHORITY receipts under sidefx:candidates,
--     with receipt identity, bundle digest, review decision and install facts.
--     Reads only;
--   * select-authoring-tool is declared: a deterministic STUB lane route that,
--     given an objective, returns the matching altitude tool from the bound TOOL
--     rows by keyword (keyword match, ordered; intent.parse is the fallback).
--     It selects, writes nothing and executes no tool.
--
-- TOOL definition surface: every one of the 31 selected TOOL definitions is
-- re-put carrying its prior semantics plus
--   capabilityId, targetScenarioId, inputPath, bindingKind, bindingProfile.
-- The 22 altitude-scoped tools bind to authoring-altitude-model-stubs and their
-- altitude's stub scenario (bindingKind altitude-stub). The 9 shared tools bind
-- to their applicable capability where one exists (inventory.read and
-- capability.search -> list-capabilities; capability.read ->
-- read-capability-meaning), otherwise to the stub root (bindingKind stub-root)
-- so the skeleton has one addressable target per row. All 31 stay toolEligible;
-- no TOOL row is deleted.
--
-- Idempotent: the authority body is re-minted only when candidate.read,
-- select-authoring-tool and the re-pointed list-tools are absent; TOOL re-puts
-- are digest-idempotent; a replay prints already_declared.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=30000;
IF @lock<0 THROW 51000,N'TOOL_BINDINGS_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @prior_content nvarchar(80)=N'sha256:27ba04f4454e635ad1706bb32cc7ddedbba8f79cb42d331d9da141609ec92aaf';
DECLARE @selected nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
IF @selected IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_NOT_SELECTED',1;
DECLARE @body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@selected,N'sha256:',N''),2));
IF @body IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_BODY_MISSING',1;
IF JSON_VALUE(@body,'$.authorityId')<>@authority_id THROW 51000,N'KERNEL_BOOT_AUTHORITY_IDENTITY_DIVERGED',1;

DECLARE @declared bit=CASE WHEN
 EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'candidate.read')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'select-authoring-tool')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'list-tools' AND JSON_VALUE(value,'$.statement') LIKE N'%tool_bound%')
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
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'TOOL_BINDINGS_BASELINE_MISSING',1;

DECLARE @new_list_tools_statement nvarchar(max)=N'SELECT JSON_VALUE(t.definition_json,''$.semantics.toolId'') AS tool_id,
       JSON_VALUE(t.definition_json,''$.semantics.altitude'') AS altitude,
       JSON_VALUE(t.definition_json,''$.semantics.class'') AS write_class,
       JSON_VALUE(t.definition_json,''$.semantics.description'') AS description,
       JSON_VALUE(t.definition_json,''$.semantics.capabilityId'') AS capability_id,
       JSON_VALUE(t.definition_json,''$.semantics.targetScenarioId'') AS target_scenario,
       JSON_VALUE(t.definition_json,''$.semantics.inputPath'') AS input_path,
       JSON_VALUE(t.definition_json,''$.semantics.inputContract'') AS input_contract,
       JSON_VALUE(t.definition_json,''$.semantics.outputContract'') AS output_contract,
       JSON_VALUE(t.definition_json,''$.semantics.admissionKind'') AS admission_kind,
       ISNULL(LOWER(JSON_VALUE(t.definition_json,''$.semantics.toolEligible'')),N''false'') AS tool_eligible,
       CASE WHEN JSON_VALUE(t.definition_json,''$.semantics.capabilityId'') IS NOT NULL
         AND EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition c
           WHERE c.estate_model_pk=t.estate_model_pk AND c.object_kind=N''CAPABILITY''
            AND c.declared_id=JSON_VALUE(t.definition_json,''$.semantics.capabilityId''))
        THEN N''true'' ELSE N''false'' END AS tool_bound,
       JSON_VALUE(ic.definition_json,''$.semantics.schema_digest'') AS input_schema_digest,
       JSON_VALUE(oc.definition_json,''$.semantics.schema_digest'') AS output_schema_digest
FROM analysis.v_selected_semantic_definition t
LEFT JOIN analysis.v_selected_semantic_definition ic
  ON ic.estate_model_pk=t.estate_model_pk AND ic.object_kind=N''CONTRACT''
 AND ic.declared_id=JSON_VALUE(t.definition_json,''$.semantics.inputContract'')
LEFT JOIN analysis.v_selected_semantic_definition oc
  ON oc.estate_model_pk=t.estate_model_pk AND oc.object_kind=N''CONTRACT''
 AND oc.declared_id=JSON_VALUE(t.definition_json,''$.semantics.outputContract'')
WHERE t.estate_model_pk=@estate_model_pk AND t.object_kind=N''TOOL'' AND t.namespace_id=N''sidefx:tools''
ORDER BY tool_id';
DECLARE @candidate_read_statement nvarchar(max)=N'SELECT r.declared_id AS receipt_id,
       JSON_VALUE(r.definition_json,''$.semantics.document.candidateId'') AS candidate_id,
       JSON_VALUE(r.definition_json,''$.semantics.document.bundleDigest'') AS bundle_digest,
       JSON_VALUE(r.definition_json,''$.semantics.document.review.decision'') AS review_decision,
       JSON_VALUE(r.definition_json,''$.semantics.document.install.disposition'') AS install_disposition,
       JSON_VALUE(r.definition_json,''$.semantics.document.alignment.evaluationDigest'') AS alignment_digest,
       JSON_VALUE(r.definition_json,''$.semantics.document.alignment.convergenceDistance'') AS convergence_distance,
       LOWER(CONVERT(varchar(64),r.definition_digest,2)) AS receipt_digest
FROM analysis.v_selected_semantic_definition r
WHERE r.estate_model_pk=@estate_model_pk AND r.object_kind=''AUTHORITY''
 AND r.namespace_id=N''sidefx:candidates''
 AND (@input IS NULL OR JSON_VALUE(@input,''$.candidateId'') IS NULL
      OR r.declared_id=JSON_VALUE(@input,''$.candidateId'')+N''.receipt.v1'')
ORDER BY r.declared_id';
DECLARE @select_tool_statement nvarchar(max)=N'DECLARE @objective nvarchar(400)=CASE WHEN ISJSON(@input)=1 THEN LOWER(ISNULL(JSON_VALUE(@input,''$.objective''),N'''')) ELSE N'''' END;
SELECT TOP 1 N''STUB'' AS route,k.keyword AS matched_keyword,
 JSON_VALUE(t.definition_json,''$.semantics.toolId'') AS tool_id,
 JSON_VALUE(t.definition_json,''$.semantics.capabilityId'') AS capability_id,
 JSON_VALUE(t.definition_json,''$.semantics.targetScenarioId'') AS target_scenario,
 JSON_VALUE(t.definition_json,''$.semantics.inputPath'') AS input_path,
 JSON_VALUE(t.definition_json,''$.semantics.altitude'') AS altitude,
 LOWER(JSON_VALUE(t.definition_json,''$.semantics.bindingProfile'')) AS binding_profile
FROM (VALUES
 (N''alignment'',1,N''alignment.evaluate''),
 (N''convergence'',2,N''alignment.evaluate''),
 (N''evaluate'',3,N''alignment.evaluate''),
 (N''meaning'',4,N''meaning.author''),
 (N''scenario'',5,N''scenario.author''),
 (N''contract'',6,N''contract.author''),
 (N''schema'',7,N''contract.author''),
 (N''semantic'',8,N''semantics.author''),
 (N''transformation'',9,N''ast.author''),
 (N''ast'',10,N''ast.author''),
 (N''authority'',11,N''authority.author''),
 (N''execution'',12,N''authority.author''),
 (N''port'',13,N''port.bind''),
 (N''provider'',14,N''provider.author''),
 (N''overlay'',15,N''overlay.bind''),
 (N''interface'',16,N''interface.author''),
 (N''cli'',17,N''interface.author''),
 (N''fixture'',18,N''fixture.author''),
 (N''proof'',19,N''proof.obligation.author''),
 (N''decision'',20,N''candidate.decide''),
 (N''broadcast'',21,N''alignment.broadcast''),
 (N''feature'',22,N''feature.resolve''),
 (N''intent'',23,N''intent.parse''),
 (N'''',99,N''intent.parse'')
) k(keyword,ordinal,tool_id)
JOIN analysis.v_selected_semantic_definition t
 ON t.estate_model_pk=@estate_model_pk AND t.object_kind=N''TOOL'' AND t.namespace_id=N''sidefx:tools''
 AND JSON_VALUE(t.definition_json,''$.semantics.toolId'')=k.tool_id
WHERE k.ordinal=99 OR CHARINDEX(k.keyword,@objective)>0
ORDER BY k.ordinal';
DECLARE @new_list_tools_row nvarchar(max)=(
 SELECT N'list-tools' AS readId,
  N'List every declared TOOL row under sidefx:tools with its altitude, write class, bound capability and target scenario, contracts, declared eligibility and derived bound flag, resolving each contract to its selected schema digest. The P0 catalog entries are withdrawn; this read resolves the TOOL definitions themselves. Writes nothing.' AS purpose,
  N'observation' AS classification,N'tsql' AS sourceKind,@new_list_tools_statement AS statement,
  JSON_QUERY(N'[{"parameter":"estate_model_pk","kind":"pinned-session"}]') AS parameters,
  JSON_QUERY(N'{"recordsets":[{"index":0,"role":"model-tool-catalog","columns":["tool_id","altitude","write_class","description","capability_id","target_scenario","input_path","input_contract","output_contract","admission_kind","tool_eligible","tool_bound","input_schema_digest","output_schema_digest"]}]}') AS resultMapping
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @candidate_read_row nvarchar(max)=(
 SELECT N'candidate.read' AS readId,
  N'Read filed capability candidates: receipt identity, candidate id, bundle digest, review decision, install disposition and alignment facts from the AUTHORITY receipts under sidefx:candidates. Optionally filter by a candidateId input; writes nothing.' AS purpose,
  N'observation' AS classification,N'tsql' AS sourceKind,@candidate_read_statement AS statement,
  JSON_QUERY(N'[{"parameter":"estate_model_pk","kind":"pinned-session"}]') AS parameters
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @select_tool_row nvarchar(max)=(
 SELECT N'select-authoring-tool' AS readId,
  N'STUB lane route: resolve a deterministic keyword match from the objective to the bound authoring TOOL row (keyword-ordered; intent.parse is the fallback). Returns the matched tool binding with route STUB; selects, writes nothing and executes no tool.' AS purpose,
  N'observation' AS classification,N'tsql' AS sourceKind,@select_tool_statement AS statement
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

IF @declared=0
BEGIN
 DECLARE @read_entries TABLE(ordinal int PRIMARY KEY,entry nvarchar(max));
 INSERT @read_entries(ordinal,entry)
 SELECT CONVERT(int,[key]),value FROM OPENJSON(@body,'$.reads');
 DECLARE @read_ordinal int,@read_entry nvarchar(max);
 DECLARE read_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal,entry FROM @read_entries ORDER BY ordinal;
 OPEN read_cursor;
 FETCH NEXT FROM read_cursor INTO @read_ordinal,@read_entry;
 SET @body=JSON_MODIFY(@body,'$.reads',JSON_QUERY(N'[]'));
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF JSON_VALUE(@read_entry,'$.readId')=N'list-tools' SET @read_entry=@new_list_tools_row;
  SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@read_entry));
  FETCH NEXT FROM read_cursor INTO @read_ordinal,@read_entry;
 END
 CLOSE read_cursor; DEALLOCATE read_cursor;
 SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@candidate_read_row));
 SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@select_tool_row));
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content binary(32)=HASHBYTES('SHA2_256',@bytes);
 DECLARE @new_content nvarchar(80)=N'sha256:'+LOWER(CONVERT(varchar(64),@content,2));
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content)<>@bytes THROW 51000,N'TOOL_BINDINGS_CONTENT_DIVERGED',1;
 DECLARE @authority_semantics nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
  WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
 SET @authority_semantics=JSON_MODIFY(@authority_semantics,'$.contentDigest',@new_content);
 DECLARE @authority_object bigint,@authority_definition bigint,@authority_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@authority_semantics,@authority_object OUTPUT,@authority_definition OUTPUT,@authority_digest OUTPUT;
END

-- Re-put every TOOL definition with its binding; digest-idempotent on replay.
DECLARE @bindings TABLE(tool_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,
 target_capability nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 target_scenario nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 input_path nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
 binding_kind nvarchar(40) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT @bindings(tool_id,target_capability,target_scenario,input_path,binding_kind) VALUES
 (N'intent.parse',N'authoring-altitude-model-stubs',N'authoring-altitude-model-stubs',N'payload',N'altitude-stub'),
 (N'feature.resolve',N'authoring-altitude-model-stubs',N'authoring-altitude-model-stubs',N'payload',N'altitude-stub'),
 (N'feature.pin',N'authoring-altitude-model-stubs',N'authoring-altitude-model-stubs',N'payload',N'altitude-stub'),
 (N'meaning.author',N'authoring-altitude-model-stubs',N'altitude-2-capability-meaning',N'payload',N'altitude-stub'),
 (N'scenario.author',N'authoring-altitude-model-stubs',N'altitude-3-scenario-io',N'payload',N'altitude-stub'),
 (N'contract.author',N'authoring-altitude-model-stubs',N'altitude-4-contracts-schemas',N'payload',N'altitude-stub'),
 (N'contract.validate',N'authoring-altitude-model-stubs',N'altitude-4-contracts-schemas',N'payload',N'altitude-stub'),
 (N'semantics.author',N'authoring-altitude-model-stubs',N'altitude-5-semantic-authority-envelope',N'payload',N'altitude-stub'),
 (N'ast.author',N'authoring-altitude-model-stubs',N'altitude-6-transformation-ast',N'payload',N'altitude-stub'),
 (N'ast.normalize',N'authoring-altitude-model-stubs',N'altitude-6-transformation-ast',N'payload',N'altitude-stub'),
 (N'ast.repair',N'authoring-altitude-model-stubs',N'altitude-6-transformation-ast',N'payload',N'altitude-stub'),
 (N'authority.author',N'authoring-altitude-model-stubs',N'altitude-7-execution-authorities-ports',N'payload',N'altitude-stub'),
 (N'port.bind',N'authoring-altitude-model-stubs',N'altitude-7-execution-authorities-ports',N'payload',N'altitude-stub'),
 (N'overlay.bind',N'authoring-altitude-model-stubs',N'altitude-8-providers-bindings-overlays',N'payload',N'altitude-stub'),
 (N'provider.author',N'authoring-altitude-model-stubs',N'altitude-8-providers-bindings-overlays',N'payload',N'altitude-stub'),
 (N'provider.read',N'authoring-altitude-model-stubs',N'altitude-8-providers-bindings-overlays',N'payload',N'altitude-stub'),
 (N'interface.author',N'authoring-altitude-model-stubs',N'altitude-9-interface-cli-display',N'payload',N'altitude-stub'),
 (N'fixture.author',N'authoring-altitude-model-stubs',N'altitude-10-fixtures-proof',N'payload',N'altitude-stub'),
 (N'proof.obligation.author',N'authoring-altitude-model-stubs',N'altitude-10-fixtures-proof',N'payload',N'altitude-stub'),
 (N'alignment.broadcast',N'authoring-altitude-model-stubs',N'altitude-11-alignment-evaluation',N'payload',N'altitude-stub'),
 (N'alignment.evaluate',N'authoring-altitude-model-stubs',N'altitude-11-alignment-evaluation',N'payload',N'altitude-stub'),
 (N'candidate.decide',N'authoring-altitude-model-stubs',N'altitude-11-alignment-evaluation',N'payload',N'altitude-stub'),
 (N'inventory.read',N'list-capabilities',N'list-capabilities',N'payload',N'capability'),
 (N'capability.search',N'list-capabilities',N'list-capabilities',N'payload.query',N'capability'),
 (N'capability.read',N'read-capability-meaning',N'read-capability-meaning',N'payload',N'capability'),
 (N'contract.read',N'authoring-altitude-model-stubs',N'authoring-altitude-model-stubs',N'payload',N'stub-root'),
 (N'preflight.run',N'authoring-altitude-model-stubs',N'authoring-altitude-model-stubs',N'payload',N'stub-root'),
 (N'candidate.file',N'authoring-altitude-model-stubs',N'authoring-altitude-model-stubs',N'payload',N'stub-root'),
 (N'candidate.read',N'authoring-altitude-model-stubs',N'authoring-altitude-model-stubs',N'payload',N'stub-root'),
 (N'observation.read',N'authoring-altitude-model-stubs',N'authoring-altitude-model-stubs',N'payload',N'stub-root'),
 (N'capability.document.install',N'authoring-altitude-model-stubs',N'authoring-altitude-model-stubs',N'payload',N'stub-root');
IF (SELECT COUNT(*) FROM @bindings)<>31 THROW 51000,N'TOOL_BINDINGS_TABLE_INCOMPLETE',1;
DECLARE @tool_id nvarchar(400),@semantics nvarchar(max);
DECLARE tool_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT tool_id FROM @bindings ORDER BY tool_id;
OPEN tool_cursor;
FETCH NEXT FROM tool_cursor INTO @tool_id;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @semantics=(
  SELECT JSON_VALUE(t.definition_json,'$.semantics.toolId') AS toolId,
   b.target_capability AS capabilityId,
   b.target_scenario AS targetScenarioId,
   b.input_path AS inputPath,
   JSON_VALUE(t.definition_json,'$.semantics.altitude') AS altitude,
   JSON_VALUE(t.definition_json,'$.semantics.class') AS class,
   JSON_VALUE(t.definition_json,'$.semantics.description') AS description,
   JSON_VALUE(t.definition_json,'$.semantics.inputContract') AS inputContract,
   JSON_VALUE(t.definition_json,'$.semantics.outputContract') AS outputContract,
   JSON_VALUE(t.definition_json,'$.semantics.admissionKind') AS admissionKind,
   CONVERT(bit,1) AS toolEligible,
   b.binding_kind AS bindingKind,
   N'write-seam-skeleton.v1' AS bindingProfile
  FROM analysis.v_selected_semantic_definition t, @bindings b
  WHERE t.estate_model_pk=@estate AND t.object_kind=N'TOOL' AND t.namespace_id=N'sidefx:tools'
   AND JSON_VALUE(t.definition_json,'$.semantics.toolId')=b.tool_id AND b.tool_id=@tool_id
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 IF @semantics IS NULL THROW 51000,N'TOOL_BINDINGS_TOOL_MISSING',1;
 DECLARE @tool_object bigint,@tool_definition bigint,@tool_digest binary(32);
 EXEC model.put_semantic_definition 'TOOL',N'sidefx:tools',@tool_id,@semantics,@tool_object OUTPUT,@tool_definition OUTPUT,@tool_digest OUTPUT;
 FETCH NEXT FROM tool_cursor INTO @tool_id;
END
CLOSE tool_cursor; DEALLOCATE tool_cursor;

-- Verify the selected authority body, freshly declared or replayed.
DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
DECLARE @declared_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@result_content,N'sha256:',N''),2));
IF @declared_body IS NULL THROW 51000,N'TOOL_BINDINGS_BODY_MISSING',1;
IF JSON_VALUE(@declared_body,'$.authorityDigest')<>N'sha256:a34639fce305a43c02c4cc5f072a4e3a98c1f1ba90ffb23739d321a9e21a7db3'
 THROW 51000,N'TOOL_BINDINGS_AUTHORITY_DIGEST_DIVERGED',1;
IF (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads') WHERE JSON_VALUE(value,'$.readId') IN (N'list-tools',N'candidate.read',N'select-authoring-tool'))<>3
 OR (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'list-tools' AND JSON_VALUE(value,'$.statement') LIKE N'%tool_bound%')<>1
 THROW 51000,N'TOOL_BINDINGS_DECLARATION_INCOMPLETE',1;

-- Binding proof: all 31 TOOL rows carry the write-seam binding profile, the
-- altitude rows target the 11 stub scenarios and every target resolves.
DECLARE @bound_tools int=(SELECT COUNT(*) FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind=N'TOOL' AND namespace_id=N'sidefx:tools'
  AND JSON_VALUE(definition_json,'$.semantics.bindingProfile')=N'write-seam-skeleton.v1');
DECLARE @altitude_tools int=(SELECT COUNT(*) FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind=N'TOOL' AND namespace_id=N'sidefx:tools'
  AND JSON_VALUE(definition_json,'$.semantics.bindingKind')=N'altitude-stub');
DECLARE @capability_tools int=(SELECT COUNT(*) FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind=N'TOOL' AND namespace_id=N'sidefx:tools'
  AND JSON_VALUE(definition_json,'$.semantics.bindingKind')=N'capability');
DECLARE @stub_root_tools int=(SELECT COUNT(*) FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind=N'TOOL' AND namespace_id=N'sidefx:tools'
  AND JSON_VALUE(definition_json,'$.semantics.bindingKind')=N'stub-root');
DECLARE @unresolved_targets int=(SELECT COUNT(*) FROM analysis.v_selected_semantic_definition t
 WHERE t.estate_model_pk=@estate AND t.object_kind=N'TOOL' AND t.namespace_id=N'sidefx:tools'
  AND JSON_VALUE(t.definition_json,'$.semantics.bindingProfile')=N'write-seam-skeleton.v1'
  AND NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition c
   WHERE c.estate_model_pk=@estate AND c.object_kind=N'CAPABILITY'
    AND c.declared_id=JSON_VALUE(t.definition_json,'$.semantics.capabilityId')));
IF @bound_tools<>31 OR @altitude_tools<>22 OR @capability_tools<>3 OR @stub_root_tools<>6 OR @unresolved_targets<>0
 THROW 51000,N'TOOL_BINDINGS_PROOF_FAILED',1;
DECLARE @stub_scenarios TABLE(scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @stub_scenarios(scenario_id)
SELECT DISTINCT JSON_VALUE(definition_json,'$.semantics.targetScenarioId')
FROM analysis.v_selected_semantic_definition
WHERE estate_model_pk=@estate AND object_kind=N'TOOL' AND namespace_id=N'sidefx:tools'
 AND JSON_VALUE(definition_json,'$.semantics.bindingKind')=N'altitude-stub';
DECLARE @missing_stub_scenarios int=(SELECT COUNT(*) FROM @stub_scenarios s
 WHERE NOT EXISTS(SELECT 1 FROM model.capability c
   JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
   JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
   JOIN model.scenario sc ON sc.scenario_pk=cs.scenario_pk
  WHERE c.capability_id=N'authoring-altitude-model-stubs' AND sc.scenario_id=s.scenario_id));
IF (SELECT COUNT(*) FROM @stub_scenarios)<>11 OR @missing_stub_scenarios<>0 THROW 51000,N'TOOL_BINDINGS_STUB_SCENARIO_PROOF_FAILED',1;
SELECT N'1_binding_summary' AS result_set,@bound_tools AS bound_tools,@altitude_tools AS altitude_stub_tools,
 @capability_tools AS capability_tools,@stub_root_tools AS stub_root_tools,@unresolved_targets AS unresolved_targets,
 (SELECT COUNT(*) FROM @stub_scenarios) AS stub_scenarios;

-- candidate.read proof: the two live receipts resolve; a candidateId filter returns one.
DECLARE @cr TABLE(receipt_id nvarchar(400),candidate_id nvarchar(400),bundle_digest nvarchar(100),review_decision nvarchar(40),
 install_disposition nvarchar(40),alignment_digest nvarchar(100),convergence_distance nvarchar(40),receipt_digest nvarchar(100));
INSERT @cr EXEC sp_executesql @candidate_read_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=NULL,@estate_model_pk=@estate;
SELECT N'2_candidate_read' AS result_set,COUNT(*) AS receipts,
 SUM(CASE WHEN review_decision=N'PENDING' THEN 1 ELSE 0 END) AS pending
FROM @cr;
IF (SELECT COUNT(*) FROM @cr)<>2 THROW 51000,N'TOOL_BINDINGS_CANDIDATE_READ_FAILED',1;
DELETE @cr;
DECLARE @cr_input nvarchar(max)=N'{"candidateId":"resolve-equity-market-price-evidence.candidate-1"}';
INSERT @cr EXEC sp_executesql @candidate_read_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@cr_input,@estate_model_pk=@estate;
SELECT N'2b_candidate_read_filtered' AS result_set,receipt_id,candidate_id,bundle_digest,review_decision FROM @cr;
IF (SELECT COUNT(*) FROM @cr)<>1 THROW 51000,N'TOOL_BINDINGS_CANDIDATE_FILTER_FAILED',1;

-- list-tools proof: 31 rows, 31 bound, targets and contracts resolve.
DECLARE @lt TABLE(tool_id nvarchar(400),altitude nvarchar(50),write_class nvarchar(50),description nvarchar(max),capability_id nvarchar(400),
 target_scenario nvarchar(400),input_path nvarchar(200),input_contract nvarchar(400),output_contract nvarchar(400),admission_kind nvarchar(400),
 tool_eligible nvarchar(10),tool_bound nvarchar(10),input_schema_digest nvarchar(100),output_schema_digest nvarchar(100));
INSERT @lt EXEC sp_executesql @new_list_tools_statement,N'@estate_model_pk bigint',@estate_model_pk=@estate;
SELECT N'3_list_tools' AS result_set,COUNT(*) AS tools,SUM(CASE WHEN capability_id IS NOT NULL THEN 1 ELSE 0 END) AS bound,
 SUM(CASE WHEN tool_bound=N'true' THEN 1 ELSE 0 END) AS targets_resolve,
 SUM(CASE WHEN target_scenario IS NOT NULL THEN 1 ELSE 0 END) AS with_target
FROM @lt;
IF (SELECT COUNT(*) FROM @lt)<>31 OR (SELECT COUNT(*) FROM @lt WHERE capability_id IS NULL)<>0
 OR (SELECT COUNT(*) FROM @lt WHERE tool_bound<>N'true')<>0
 THROW 51000,N'TOOL_BINDINGS_LIST_TOOLS_FAILED',1;

-- select-authoring-tool proof: an authoring objective resolves to its stub tool.
DECLARE @st TABLE(route nvarchar(20),matched_keyword nvarchar(200),tool_id nvarchar(400),capability_id nvarchar(400),
 target_scenario nvarchar(400),input_path nvarchar(200),altitude nvarchar(50),binding_profile nvarchar(100));
DECLARE @st_input nvarchar(max)=N'{"objective":"evaluate alignment convergence for the authored capability candidate"}';
INSERT @st EXEC sp_executesql @select_tool_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@st_input,@estate_model_pk=@estate;
SELECT N'4_select_authoring_tool' AS result_set,* FROM @st;
IF NOT EXISTS(SELECT 1 FROM @st WHERE tool_id=N'alignment.evaluate' AND capability_id=N'authoring-altitude-model-stubs'
 AND route=N'STUB' AND binding_profile=N'write-seam-skeleton.v1')
 THROW 51000,N'TOOL_BINDINGS_LANE_ROUTE_FAILED',1;

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
SELECT N'5_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'TOOL_BINDINGS_UNRELATED_CAPABILITY_CHANGED',1;

SELECT N'6_declared_reads' AS result_set,JSON_VALUE(value,'$.readId') AS read_id,JSON_VALUE(value,'$.classification') AS classification
FROM OPENJSON(@declared_body,'$.reads')
WHERE JSON_VALUE(value,'$.readId') IN (N'list-tools',N'candidate.read',N'select-authoring-tool')
ORDER BY read_id;
SELECT N'7_disposition' AS result_set,@authority_id AS authority_id,@result_content AS content_digest,
 CASE WHEN @declared=1 THEN N'already_declared' WHEN @selected=@prior_content THEN N'redeclared' ELSE N'reconciled' END AS disposition,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads')) AS read_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeKinds')) AS kind_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeOperations')) AS operation_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeContracts')) AS contract_count;
COMMIT TRANSACTION;
