-- project-authoring-tool-selection.sql
--
-- Lane 3, item 2: replace the deterministic select-authoring-tool stub with the
-- declared projection path, reusing the relevance-read pattern of
-- declare-agent-relevance-filter.sql (analysis.v_capability_keyword_index +
-- analysis.capability_relevance + a read statement that consumes the declared
-- filter output). The objective now selects a TOOL row by its declared tool-id
-- tokens, altitude and bound capability, and only among eligible, resolvable
-- tools; an objective with no matching tool answers REFUSED/TOOL_NOT_REGISTERED.
--
--   analysis.v_tool_keyword_index  -- declared keyword rows per TOOL: any
--     $.semantics.keywords plus tokens derived from toolId, altitude and the
--     bound capabilityId. Writes nothing.
--   analysis.tool_relevance(@objective) -- tokenizes the objective with the same
--     platform mechanics as capability_relevance, matches the index, and returns
--     {objective, tokens, matchedTools, eligibleTools, eligibleToolCount,
--      eligibleCapabilities}. Eligible = declared toolEligible true and the bound
--     capability resolves in the selected estate.
--
-- Boot authority (same selected sda-kernel-boot-data-access.v1): the
-- select-authoring-tool read entry is replaced (same readId, observation,
-- tsql). No kind, admission, operation or contract row changes. The re-mint
-- asserts structural prerequisites rather than an exact prior content digest,
-- because a parallel lane may be re-minting the same authority; replay is
-- detected from the new statement itself.
--
-- Idempotent: the view/function are CREATE OR ALTER; the read row is replaced
-- only when its statement does not yet consume analysis.tool_relevance; a replay
-- prints already_declared.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=300000;
IF @lock<0 THROW 51000,N'TOOL_PROJECTION_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
CREATE OR ALTER VIEW analysis.v_tool_keyword_index AS
WITH tools AS (
 SELECT t.declared_id COLLATE Latin1_General_100_BIN2 AS tool_id, t.definition_json
 FROM analysis.v_selected_semantic_definition t
 WHERE t.estate_model_pk = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1)
  AND t.object_kind = N'TOOL' AND t.namespace_id = N'sidefx:tools'
)
SELECT tool_id, LOWER(TRIM(kw.value)) COLLATE Latin1_General_100_BIN2 AS keyword, N'declared-keyword' AS keyword_source
FROM tools CROSS APPLY OPENJSON(definition_json, '$.semantics.keywords') kw
WHERE LEN(TRIM(kw.value)) >= 2
UNION
SELECT tool_id, LOWER(TRIM(tok.value)) COLLATE Latin1_General_100_BIN2, N'derived-tool-id'
FROM tools CROSS APPLY STRING_SPLIT(JSON_VALUE(definition_json, '$.semantics.toolId'), N'.') tok
WHERE LEN(TRIM(tok.value)) >= 2
UNION
SELECT tool_id, LOWER(TRIM(tok.value)) COLLATE Latin1_General_100_BIN2, N'derived-altitude'
FROM tools CROSS APPLY STRING_SPLIT(ISNULL(JSON_VALUE(definition_json, '$.semantics.altitude'), N''), N'-') tok
WHERE LEN(TRIM(tok.value)) >= 2
UNION
SELECT tool_id, LOWER(TRIM(tok.value)) COLLATE Latin1_General_100_BIN2, N'derived-capability-id'
FROM tools CROSS APPLY STRING_SPLIT(ISNULL(JSON_VALUE(definition_json, '$.semantics.capabilityId'), N''), N'-') tok
WHERE LEN(TRIM(tok.value)) >= 2;
GO
CREATE OR ALTER FUNCTION analysis.tool_relevance(@objective nvarchar(max))
RETURNS nvarchar(max)
AS
BEGIN
 DECLARE @text nvarchar(max) = LOWER(ISNULL(@objective, N''));
 DECLARE @index int = 1, @character nchar(1);
 WHILE @index <= LEN(@text)
 BEGIN
  SET @character = SUBSTRING(@text, @index, 1);
  IF @character NOT LIKE N'[a-z0-9]' SET @text = STUFF(@text, @index, 1, N' ');
  SET @index = @index + 1;
 END
 DECLARE @tokens TABLE (token nvarchar(200) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
 INSERT @tokens (token)
 SELECT DISTINCT CASE WHEN LEN(value) > 3 AND RIGHT(value, 1) = N's' THEN LEFT(value, LEN(value) - 1) ELSE value END
 FROM STRING_SPLIT(@text, N' ') WHERE LEN(value) >= 2;
 DECLARE @matches TABLE (tool_id nvarchar(400) COLLATE Latin1_General_100_BIN2, keyword nvarchar(200) COLLATE Latin1_General_100_BIN2);
 INSERT @matches (tool_id, keyword)
 SELECT DISTINCT idx.tool_id, idx.keyword
 FROM analysis.v_tool_keyword_index idx
 JOIN @tokens token
  ON token.token = CASE WHEN LEN(idx.keyword) > 3 AND RIGHT(idx.keyword, 1) = N's' THEN LEFT(idx.keyword, LEN(idx.keyword) - 1) ELSE idx.keyword END;
 DECLARE @all TABLE (tool_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY, match_count int, matched_keywords nvarchar(max));
 INSERT @all (tool_id, match_count, matched_keywords)
 SELECT m.tool_id, COUNT(*),
  ISNULL(N'[' + STRING_AGG(N'"' + STRING_ESCAPE(m.keyword, 'json') + N'"', N',') WITHIN GROUP (ORDER BY m.keyword) + N']', N'[]')
 FROM @matches m GROUP BY m.tool_id;
 DECLARE @tools TABLE (tool_id nvarchar(400), capability_id nvarchar(400), target_scenario nvarchar(400), input_path nvarchar(200),
  altitude nvarchar(50), match_count int, matched_keywords nvarchar(max), binding_profile nvarchar(100), eligible bit);
 INSERT @tools (tool_id, capability_id, target_scenario, input_path, altitude, match_count, matched_keywords, binding_profile, eligible)
 SELECT a.tool_id, JSON_VALUE(t.definition_json, '$.semantics.capabilityId'), JSON_VALUE(t.definition_json, '$.semantics.targetScenarioId'),
  JSON_VALUE(t.definition_json, '$.semantics.inputPath'), JSON_VALUE(t.definition_json, '$.semantics.altitude'),
  a.match_count, a.matched_keywords, LOWER(JSON_VALUE(t.definition_json, '$.semantics.bindingProfile')),
  CASE WHEN ISNULL(LOWER(JSON_VALUE(t.definition_json, '$.semantics.toolEligible')), N'false') = N'true'
   AND EXISTS (SELECT 1 FROM analysis.v_selected_semantic_definition c
    WHERE c.estate_model_pk = t.estate_model_pk AND c.object_kind = N'CAPABILITY'
     AND c.declared_id = JSON_VALUE(t.definition_json, '$.semantics.capabilityId')) THEN 1 ELSE 0 END
 FROM @all a
 JOIN analysis.v_selected_semantic_definition t
  ON t.estate_model_pk = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1)
  AND t.object_kind = N'TOOL' AND t.namespace_id = N'sidefx:tools'
  AND t.declared_id = a.tool_id COLLATE Latin1_General_100_BIN2;
 DECLARE @tokens_json nvarchar(max) = ISNULL(N'[' + (SELECT STRING_AGG(N'"' + STRING_ESCAPE(token, 'json') + N'"', N',') WITHIN GROUP (ORDER BY token) FROM @tokens) + N']', N'[]');
 DECLARE @matched_json nvarchar(max) = (
  SELECT tool_id AS toolId, capability_id AS capabilityId, target_scenario AS targetScenarioId, input_path AS inputPath,
   altitude, match_count AS matchCount, JSON_QUERY(matched_keywords) AS matchedKeywords, binding_profile AS bindingProfile
  FROM @tools ORDER BY match_count DESC, tool_id FOR JSON PATH);
 DECLARE @eligible_json nvarchar(max) = (
  SELECT tool_id AS toolId, capability_id AS capabilityId, target_scenario AS targetScenarioId, input_path AS inputPath,
   altitude, match_count AS matchCount, JSON_QUERY(matched_keywords) AS matchedKeywords, binding_profile AS bindingProfile
  FROM @tools WHERE eligible = 1 ORDER BY match_count DESC, tool_id FOR JSON PATH);
 DECLARE @capabilities_json nvarchar(max) = ISNULL(N'[' + (SELECT STRING_AGG(N'"' + STRING_ESCAPE(capability_id, 'json') + N'"', N',') WITHIN GROUP (ORDER BY capability_id)
  FROM (SELECT DISTINCT capability_id FROM @tools WHERE eligible = 1) e) + N']', N'[]');
 RETURN (
  SELECT @objective AS objective, JSON_QUERY(@tokens_json) AS tokens,
   JSON_QUERY(ISNULL(@matched_json, N'[]')) AS matchedTools,
   JSON_QUERY(ISNULL(@eligible_json, N'[]')) AS eligibleTools,
   (SELECT COUNT(*) FROM @tools WHERE eligible = 1) AS eligibleToolCount,
   JSON_QUERY(@capabilities_json) AS eligibleCapabilities
  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
END;
GO
-- The declared read executes under sidefx_reader.
GRANT EXECUTE ON OBJECT::analysis.tool_relevance TO sidefx_reader;
GRANT SELECT ON OBJECT::analysis.v_tool_keyword_index TO sidefx_reader;
-- ============================== AUTHORITY READ REPLACEMENT ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @selected nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
IF @selected IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_NOT_SELECTED',1;
DECLARE @body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@selected,N'sha256:',N''),2));
IF @body IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_BODY_MISSING',1;
IF JSON_VALUE(@body,'$.authorityId')<>@authority_id THROW 51000,N'KERNEL_BOOT_AUTHORITY_IDENTITY_DIVERGED',1;
IF NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'select-authoring-tool')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'list-tools')
 THROW 51000,N'KERNEL_BOOT_AUTHORITY_CHANGED_REBASE_DECLARATION',1;
IF (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition t
 WHERE t.estate_model_pk=@estate AND t.object_kind=N'TOOL' AND t.namespace_id=N'sidefx:tools')=0
 THROW 51000,N'TOOL_PROJECTION_NO_TOOLS_DECLARED',1;

DECLARE @declared bit=CASE WHEN EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads')
 WHERE JSON_VALUE(value,'$.readId')=N'select-authoring-tool' AND JSON_VALUE(value,'$.statement') LIKE N'%analysis.tool_relevance%')
 THEN 1 ELSE 0 END;

IF @declared=0
BEGIN
 DECLARE @statement nvarchar(max)=N'DECLARE @objective nvarchar(max)=CASE WHEN ISJSON(@input)=1 THEN ISNULL(JSON_VALUE(@input,''$.objective''),N'''') ELSE N'''' END;
DECLARE @relevance nvarchar(max)=analysis.tool_relevance(@objective);
DECLARE @eligible nvarchar(max)=ISNULL(JSON_QUERY(@relevance,''$.eligibleTools''),N''[]'');
DECLARE @tools TABLE(tool_id nvarchar(400),capability_id nvarchar(400),target_scenario nvarchar(400),input_path nvarchar(200),altitude nvarchar(50),match_count int,matched_keywords nvarchar(max),binding_profile nvarchar(100));
INSERT @tools(tool_id,capability_id,target_scenario,input_path,altitude,match_count,matched_keywords,binding_profile)
SELECT toolId,capabilityId,targetScenarioId,inputPath,altitude,matchCount,JSON_QUERY(matchedKeywords),bindingProfile
FROM OPENJSON(@eligible) WITH(toolId nvarchar(400) ''$.toolId'',capabilityId nvarchar(400) ''$.capabilityId'',
 targetScenarioId nvarchar(400) ''$.targetScenarioId'',inputPath nvarchar(200) ''$.inputPath'',altitude nvarchar(50) ''$.altitude'',
 matchCount int ''$.matchCount'',matchedKeywords nvarchar(max) ''$.matchedKeywords'' AS JSON,bindingProfile nvarchar(100) ''$.bindingProfile'');
DECLARE @tool_id nvarchar(400)=(SELECT TOP (1) tool_id FROM @tools ORDER BY match_count DESC,tool_id);
IF @tool_id IS NULL
 SELECT N''REFUSED'' AS route,N''TOOL_NOT_REGISTERED'' AS refusal_code,NULL AS tool_id,NULL AS capability_id,NULL AS target_scenario,NULL AS input_path,NULL AS altitude,NULL AS matched_keywords,NULL AS binding_profile,JSON_QUERY(@relevance) AS relevance;
ELSE
 SELECT N''ADMITTED'' AS route,NULL AS refusal_code,t.tool_id,t.capability_id,t.target_scenario,t.input_path,t.altitude,
  JSON_QUERY(t.matched_keywords) AS matched_keywords,t.binding_profile,JSON_QUERY(@relevance) AS relevance
 FROM @tools t WHERE t.tool_id=@tool_id;';
 DECLARE @read_row nvarchar(max)=(SELECT N'select-authoring-tool' AS readId,
  N'Declared lane projection: tokenize the objective with analysis.tool_relevance (the relevance-read pattern), select the matching eligible TOOL row by tool-id tokens, altitude and bound capability, and return ADMITTED with its binding or REFUSED with TOOL_NOT_REGISTERED. Selects only; writes nothing and executes no tool.' AS purpose,
  N'observation' AS classification,N'tsql' AS sourceKind,@statement AS statement
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @reads TABLE(ordinal int PRIMARY KEY,entry nvarchar(max));
 INSERT @reads(ordinal,entry) SELECT CONVERT(int,[key]),value FROM OPENJSON(@body,'$.reads');
 DECLARE @read_ordinal int,@read_entry nvarchar(max);
 DECLARE @read_count int=(SELECT COUNT(*) FROM @reads);
 DECLARE read_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal,entry FROM @reads ORDER BY ordinal;
 OPEN read_cursor;
 FETCH NEXT FROM read_cursor INTO @read_ordinal,@read_entry;
 SET @body=JSON_MODIFY(@body,'$.reads',JSON_QUERY(N'[]'));
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF JSON_VALUE(@read_entry,'$.readId')=N'select-authoring-tool' SET @read_entry=@read_row;
  SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@read_entry));
  FETCH NEXT FROM read_cursor INTO @read_ordinal,@read_entry;
 END
 CLOSE read_cursor; DEALLOCATE read_cursor;
 IF (SELECT COUNT(*) FROM OPENJSON(@body,'$.reads'))<>@read_count THROW 51000,N'TOOL_PROJECTION_READ_COUNT_CHANGED',1;
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
 THROW 51000,N'TOOL_PROJECTION_AUTHORITY_DIGEST_DIVERGED',1;
IF (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'select-authoring-tool'
 AND JSON_VALUE(value,'$.statement') LIKE N'%analysis.tool_relevance%')<>1
 THROW 51000,N'TOOL_PROJECTION_DECLARATION_INCOMPLETE',1;
SELECT N'0_projection_authority' AS result_set,@authority_id AS authority_id,@result_content AS content_digest,
 CASE WHEN @declared=1 THEN N'already_declared' ELSE N'replaced' END AS disposition,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads')) AS read_count;
GO
-- ============================== PROJECTION PROOF ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
DECLARE @declared_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@result_content,N'sha256:',N''),2));
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
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'TOOL_PROJECTION_BASELINE_MISSING',1;

SELECT N'1_index_summary' AS result_set,COUNT(DISTINCT tool_id) AS indexed_tools,COUNT(*) AS keyword_rows,
 (SELECT COUNT(*) FROM analysis.v_tool_keyword_index WHERE keyword_source=N'declared-keyword') AS declared_keywords
FROM analysis.v_tool_keyword_index;
IF (SELECT COUNT(DISTINCT tool_id) FROM analysis.v_tool_keyword_index)<>31
 THROW 51000,N'TOOL_PROJECTION_INDEX_INCOMPLETE',1;

DECLARE @statement nvarchar(max)=(SELECT JSON_VALUE(value,'$.statement') FROM OPENJSON(@declared_body,'$.reads')
 WHERE JSON_VALUE(value,'$.readId')=N'select-authoring-tool');
IF @statement IS NULL THROW 51000,N'TOOL_PROJECTION_STATEMENT_MISSING',1;
DECLARE @result TABLE(route nvarchar(20),refusal_code nvarchar(100),tool_id nvarchar(400),capability_id nvarchar(400),
 target_scenario nvarchar(400),input_path nvarchar(200),altitude nvarchar(50),matched_keywords nvarchar(max),
 binding_profile nvarchar(100),relevance nvarchar(max));
DECLARE @objective nvarchar(max)=N'author the contract schemas for the authored capability';
DECLARE @input_json nvarchar(max)=(SELECT @objective AS objective FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @result EXEC sp_executesql @statement,N'@input nvarchar(max),@estate_model_pk bigint',
 @input=@input_json,@estate_model_pk=@estate;
SELECT N'2_contract_objective' AS result_set,route,refusal_code,tool_id,capability_id,altitude,matched_keywords,binding_profile FROM @result;
IF NOT EXISTS(SELECT 1 FROM @result WHERE route=N'ADMITTED' AND tool_id=N'contract.author')
 THROW 51000,N'TOOL_PROJECTION_CONTRACT_OBJECTIVE_FAILED',1;
DELETE @result;
SET @objective=N'work at altitude 11 on alignment convergence for the candidate';
SET @input_json=(SELECT @objective AS objective FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @result EXEC sp_executesql @statement,N'@input nvarchar(max),@estate_model_pk bigint',
 @input=@input_json,@estate_model_pk=@estate;
SELECT N'3_altitude_objective' AS result_set,route,refusal_code,tool_id,capability_id,altitude,matched_keywords,binding_profile FROM @result;
IF NOT EXISTS(SELECT 1 FROM @result WHERE route=N'ADMITTED' AND altitude=N'altitude-11' AND matched_keywords LIKE N'%11%' AND matched_keywords LIKE N'%alignment%')
 THROW 51000,N'TOOL_PROJECTION_ALTITUDE_OBJECTIVE_FAILED',1;
DELETE @result;
SET @objective=N'zzzz qqqq wwww';
SET @input_json=(SELECT @objective AS objective FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @result EXEC sp_executesql @statement,N'@input nvarchar(max),@estate_model_pk bigint',
 @input=@input_json,@estate_model_pk=@estate;
SELECT N'4_unknown_objective' AS result_set,route,refusal_code,tool_id,relevance FROM @result;
IF NOT EXISTS(SELECT 1 FROM @result WHERE route=N'REFUSED' AND refusal_code=N'TOOL_NOT_REGISTERED' AND tool_id IS NULL)
 THROW 51000,N'TOOL_PROJECTION_UNKNOWN_OBJECTIVE_FAILED',1;

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
SELECT N'5_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'TOOL_PROJECTION_UNRELATED_CAPABILITY_CHANGED',1;
ROLLBACK TRANSACTION;
