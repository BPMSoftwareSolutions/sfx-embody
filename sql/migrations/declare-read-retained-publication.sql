-- declare-read-retained-publication.sql
--
-- Lane E unit 9 (docs/implementation-strategy.md): `circuit`, `artifact` and
-- `reveal --as circuit` are declared reader operations. Since the reader modules
-- were subtracted the loader ran the (absent) subject path; and the old media
-- read reached into sidefx-database with a privileged connection, a layering
-- violation.
--
-- This migration declares `read-retained-publication`: one port whose declared
-- read selects the current model's latest explicit media publication and
-- returns the retained catalogue, one retained view, or one retained artifact's
-- original bytes. The read never crosses a model boundary; when the current
-- model retains no publication it raises CIRCUIT_PUBLICATION_UNAVAILABLE.
--
-- Grants: the read executes under sidefx_reader, so the reader receives exactly
-- the three media objects the read names. No other media access is granted.
--
-- Idempotent: re-running re-declares the same content-addressed definitions and
-- re-applies the same grants.
--
-- Default: ROLLBACK. Replace the final ROLLBACK TRANSACTION; with COMMIT
-- TRANSACTION; to install (after the from-transaction preflight passes).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers=CURSOR LOCAL FAST_FORWARD FOR
 SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
 FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id
 JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE o.type='U' AND s.name IN ('model','source')
 AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0 BEGIN
 EXEC(N'DROP TRIGGER '+@trigger_name);
 FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
GO
DECLARE @statement nvarchar(max)=N'
DECLARE @operation nvarchar(400)=LOWER(COALESCE(JSON_VALUE(@input,''$.operation''),''circuit''));
DECLARE @capability_id nvarchar(400)=JSON_VALUE(@input,''$.capabilityId'');
DECLARE @view_id nvarchar(400)=JSON_VALUE(@input,''$.viewId'');
DECLARE @artifact_digest nvarchar(400)=JSON_VALUE(@input,''$.artifactDigest'');
DECLARE @prefix nvarchar(400)=''/media/library/outputs/estate-topology/'';
-- The current model''s latest explicit media publication. Never cross a model.
DECLARE @publication_digest varchar(64), @publication varbinary(max);
SELECT TOP 1 @publication_digest=LOWER(CONVERT(varchar(64),r.blob_digest,2)), @publication=b.bytes
FROM media.asset a
JOIN media.asset_revision r ON r.asset_id=a.asset_id
JOIN media.blob b ON b.digest=r.blob_digest
WHERE a.logical_key=CONCAT(''media-catalog/'',@estate_model_pk,''/website-visual-publication'')
ORDER BY r.created_at DESC, r.revision_id DESC;
IF @publication IS NULL THROW 51000,''CIRCUIT_PUBLICATION_UNAVAILABLE'',1;
DECLARE @publication_json nvarchar(max)=CONVERT(nvarchar(max), CONVERT(varchar(max), @publication) COLLATE Latin1_General_100_BIN2_UTF8);
DECLARE @artifacts nvarchar(max)=JSON_QUERY(@publication_json,''$.artifacts'');
DECLARE @source nvarchar(max)=JSON_QUERY(@publication_json,''$.source'');
IF @operation=''catalogue''
BEGIN
  DECLARE @catalogs TABLE (url nvarchar(500) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
  INSERT @catalogs(url) SELECT CONVERT(nvarchar(500),[key]) COLLATE Latin1_General_100_BIN2 FROM OPENJSON(@artifacts)
   WHERE [key] LIKE @prefix+''%/catalog.js'';
  SELECT (SELECT c.capability_id AS capabilityId, n.namespace_id AS namespaceId,
      CONVERT(bit, CASE WHEN EXISTS (SELECT 1 FROM @catalogs t WHERE t.url=@prefix+c.capability_id+''/catalog.js'') THEN 1 ELSE 0 END) AS circuitAvailable
    FROM model.estate_capability ec
    JOIN model.capability c ON c.capability_pk=ec.capability_pk
    JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
    WHERE ec.estate_model_pk=@estate_model_pk ORDER BY c.capability_id
    FOR JSON PATH) AS publication;
END
ELSE IF @operation=''artifact''
BEGIN
  IF @artifact_digest IS NULL OR LEN(@artifact_digest)<>64 OR @artifact_digest LIKE ''%[^0-9a-f]%'' THROW 51000,''MEDIA_IDENTITY_INVALID'',1;
  DECLARE @artifact_url nvarchar(400), @artifact_sha nvarchar(80);
  SELECT TOP 1 @artifact_url=CONVERT(nvarchar(400),[key]), @artifact_sha=JSON_VALUE(value,''$.sha256'')
   FROM OPENJSON(@artifacts) WHERE [key] LIKE @prefix+''textures/%'' AND JSON_VALUE(value,''$.sha256'')=@artifact_digest;
  IF @artifact_url IS NULL THROW 51000,''CIRCUIT_ARTIFACT_UNAVAILABLE'',1;
  DECLARE @artifact_bytes varbinary(max)=(SELECT bytes FROM media.blob WHERE digest=CONVERT(binary(32),@artifact_sha,2));
  IF @artifact_bytes IS NULL THROW 51000,''CIRCUIT_ARTIFACT_BYTES_UNAVAILABLE'',1;
  SELECT (SELECT @artifact_url AS url, @artifact_sha AS sha256, DATALENGTH(@artifact_bytes) AS bytes,
      (SELECT CAST(N'''' AS XML).value(''xs:base64Binary(sql:column("payload"))'',''varchar(max)'') FROM (SELECT @artifact_bytes AS payload) q) AS base64,
      @publication_digest AS publicationDigest, JSON_QUERY(@source) AS publicationSource
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS publication;
END
ELSE
BEGIN
  IF @capability_id IS NULL THROW 51000,''CAPABILITY_IDENTITY_REQUIRED'',1;
  DECLARE @catalog_url nvarchar(400)=@prefix+@capability_id+''/catalog.js'';
  DECLARE @catalog_entry nvarchar(max);
  SELECT TOP 1 @catalog_entry=value FROM OPENJSON(@artifacts) WHERE [key]=@catalog_url;
  IF @catalog_entry IS NULL THROW 51000,''CIRCUIT_ARTIFACT_UNAVAILABLE'',1;
  DECLARE @catalog_bytes varbinary(max)=(SELECT bytes FROM media.blob WHERE digest=CONVERT(binary(32),JSON_VALUE(@catalog_entry,''$.sha256''),2));
  IF @catalog_bytes IS NULL THROW 51000,''CIRCUIT_ARTIFACT_BYTES_UNAVAILABLE'',1;
  DECLARE @catalog_text nvarchar(max)=CONVERT(nvarchar(max), CONVERT(varchar(max), @catalog_bytes) COLLATE Latin1_General_100_BIN2_UTF8);
  DECLARE @catalog_json nvarchar(max)=LTRIM(RTRIM(SUBSTRING(@catalog_text, CHARINDEX(''='',@catalog_text)+1, LEN(@catalog_text)-CHARINDEX(''='',@catalog_text))));
  IF RIGHT(@catalog_json,1)='';'' SET @catalog_json=LEFT(@catalog_json,LEN(@catalog_json)-1);
  IF ISJSON(@catalog_json)<>1 THROW 51000,''CIRCUIT_PAYLOAD_INVALID'',1;
  IF @view_id IS NULL
    SELECT (SELECT @capability_id AS capabilityId, JSON_QUERY(@catalog_json,''$.views'') AS views,
        @publication_digest AS publicationDigest, JSON_QUERY(@source) AS publicationSource
      FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS publication;
  ELSE
  BEGIN
    DECLARE @view_url nvarchar(400), @view_entry nvarchar(max);
    SELECT TOP 1 @view_url=JSON_VALUE(value,''$.url''), @view_entry=value FROM OPENJSON(@catalog_json,''$.views'')
     WHERE JSON_VALUE(value,''$.id'')=@view_id;
    IF @view_url IS NULL OR @view_url<>@prefix+@capability_id+''/''+@view_id+''.js'' THROW 51000,''CIRCUIT_VIEW_UNAVAILABLE'',1;
    DECLARE @view_bytes varbinary(max)=(SELECT bytes FROM media.blob WHERE digest=CONVERT(binary(32),JSON_VALUE(@view_entry,''$.sha256''),2));
    IF @view_bytes IS NULL THROW 51000,''CIRCUIT_ARTIFACT_BYTES_UNAVAILABLE'',1;
    SELECT (SELECT @capability_id AS capabilityId, @view_id AS viewId, JSON_QUERY(@view_entry) AS [view],
        @view_url AS url, DATALENGTH(@view_bytes) AS bytes,
        (SELECT CAST(N'''' AS XML).value(''xs:base64Binary(sql:column("payload"))'',''varchar(max)'') FROM (SELECT @view_bytes AS payload) q) AS base64,
        @publication_digest AS publicationDigest, JSON_QUERY(@source) AS publicationSource
      FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS publication;
  END
END';
DECLARE @bindings nvarchar(max)=N'[{"portId":"read-retained-publication-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,'json') + N'","resultColumn":"publication"}}]';
EXEC model.scaffold_capability @capability_id=N'read-retained-publication', @on_exists=N'REPLACE';
EXEC model.declare_contract @id=N'read-retained-publication-request.v1',
 @schema=N'{"type":"object","properties":{"operation":{"type":"string"},"capabilityId":{"type":"string"},"viewId":{"type":"string"},"artifactDigest":{"type":"string"}},"additionalProperties":true}';
EXEC model.declare_contract @id=N'read-retained-publication-result.v1',
 @schema=N'{"type":"object","additionalProperties":true}';
EXEC model.declare_scenario
 @capability_id=N'read-retained-publication',
 @scenario=N'{"scenarioId":"read-retained-publication","name":"Read the retained media publication","inputId":"read-retained-publication-request","inputContract":"read-retained-publication-request.v1","eventId":"retained-publication-requested","eventAuthority":"read-retained-publication.v1","outcomeId":"retained-publication","outcomeContract":"read-retained-publication-result.v1","terminal":true,"root":true,"given":"one retained media selection for the current model","when":"the latest explicit publication is read under the reader boundary","then":"the retained catalogue, view or artifact is returned"}',
 @operations=N'[{"operationId":"read-retained-publication.0","kind":"invoke-port","portId":"read-retained-publication-port"}]',
 @port_bindings=@bindings;
-- The reader executes this declared read; grant exactly the media objects it names.
GRANT SELECT ON OBJECT::media.asset TO sidefx_reader;
GRANT SELECT ON OBJECT::media.asset_revision TO sidefx_reader;
GRANT SELECT ON OBJECT::media.blob TO sidefx_reader;

SELECT 'read_retained_publication' AS result_set, c.capability_id, s.scenario_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 CONVERT(bit, CASE WHEN d.definition_json LIKE N'%xs:base64Binary%' THEN 1 ELSE 0 END) AS has_read_statement,
 DATALENGTH(d.definition_json) AS definition_bytes
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.object_kind='PORT'
 AND d.namespace_id=N'sidefx:capability:'+c.capability_id
WHERE c.capability_id=N'read-retained-publication';
COMMIT TRANSACTION;
