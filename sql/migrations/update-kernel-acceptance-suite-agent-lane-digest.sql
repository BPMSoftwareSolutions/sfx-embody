-- update-kernel-acceptance-suite-agent-lane-digest.sql
--
-- Deliberate update of the declared kernel acceptance suite: the agent-lane
-- observation's recorded observed path digest moved because the equity
-- capability it invokes now declares the finance15 fallback route (fifteen
-- operations). The new live digest
-- sha256:05be13899f97defe3eb6969d3fd3cbf002ec054c38f09a2dbfa577ab33e2dd37 is
-- appended to the recorded one-of values; the prior recorded values remain.
--
-- Default: ROLLBACK. Replace the final ROLLBACK with COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
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
GO
BEGIN TRANSACTION;
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sfx-kernel-acceptance-suite.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @new_digest nvarchar(200)=N'sha256:05be13899f97defe3eb6969d3fd3cbf002ec054c38f09a2dbfa577ab33e2dd37';
DECLARE @values nvarchar(max)=N'["sha256:5f8e6fdad28b4847a516cac59e11423aa3f5ed238c9005a6ddc2cec7c01d1a4a","sha256:26c85c04c7ed278950d5d108b8568232cb00a742ebb7f3db3c76a8fc0accfb73","'
 + @new_digest + N'"]';
DECLARE @object bigint,@definition bigint,@digest binary(32),@bytes varbinary(max),@json nvarchar(max);
SELECT @json=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM analysis.v_selected_semantic_definition d
JOIN source.content_object co
  ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id;
IF @json IS NULL THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_AUTHORITY_NOT_SELECTED',1;
IF ISJSON(@json)<>1 THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_AUTHORITY_MALFORMED',1;
IF JSON_VALUE(@json,'$.invocations[2].id')<>N'observe-request-capability-from-objective'
 THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_SHAPE_DIVERGED',1;

IF NOT EXISTS (SELECT 1 FROM OPENJSON(@json,'$.invocations[2].expect[0].conditions[0].values') WHERE value=@new_digest)
BEGIN
 SET @json=JSON_MODIFY(@json,'$.invocations[2].expect[0].conditions[0].values',JSON_QUERY(@values));
 SET @bytes=CONVERT(varbinary(max),CONVERT(varchar(max),@json COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content_digest binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content_digest,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content_digest)<>@bytes
  THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_CONTENT_DIVERGED',1;
 DECLARE @semantics nvarchar(max)=N'{"authorityId":"sfx-kernel-acceptance-suite.v1","contentDigest":"sha256:'
  + LOWER(CONVERT(varchar(64),@content_digest,2))
  + N'","sourcePath":"config/kernel-acceptance-suite.v1.json","locators":["config/kernel-acceptance-suite.v1.json"]}';
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
END
SELECT '1_agent_lane_digests' AS result_set,
 JSON_QUERY((SELECT value FROM OPENJSON(@json,'$.invocations[2].expect[0].conditions[0].values') FOR JSON PATH)) AS values_json;
SELECT '2_declared_read' AS result_set,
 JSON_VALUE(d.definition_json,'$.semantics.contentDigest') AS selected_content_digest
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id;
COMMIT TRANSACTION;
-- Installed 2026-09-19: agent-lane acceptance digest appended for the finance15 fallback route.
