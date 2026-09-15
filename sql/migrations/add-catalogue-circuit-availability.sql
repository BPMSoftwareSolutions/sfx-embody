-- add-catalogue-circuit-availability.sql
--
-- `catalogue` historically reported whether each capability has a retained
-- circuit catalogue in the current model's latest explicit media publication.
-- `list`, `find` and `catalogue` are served by the declared read
-- `list-capabilities` (declare-list-capabilities.sql), so every listing row
-- must carry `circuitAvailable`: true iff the current model's latest explicit
-- publication lists `<prefix><capabilityId>/catalog.js`, false when the current
-- model retains no publication. Matching, matchedFields, ordering and counts
-- are untouched.
--
-- This migration re-declares only the `list-capabilities-port` definition: it
-- reads the selected semantics, appends a media-availability table variable and
-- its column to the retained statement, then mints and relinks the port version
-- exactly as free-declared-read-ports.sql does. `sidefx_reader` already holds
-- SELECT on media.asset, media.asset_revision and media.blob.
--
-- Idempotent: a second run finds `circuitAvailable` in the selected statement
-- and re-declares nothing.
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
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @ns nvarchar(400)=N'sidefx:capability:list-capabilities' COLLATE Latin1_General_100_BIN2;
DECLARE @port nvarchar(400)=N'list-capabilities-port' COLLATE Latin1_General_100_BIN2;
DECLARE @sem nvarchar(max), @stmt nvarchar(max), @prevver bigint,
 @object2 bigint, @definition2 bigint, @digest2 binary(32), @portpk bigint, @version bigint;
SELECT @sem=JSON_QUERY(d.definition_json,'$.semantics'),
 @stmt=c.statement,
 @prevver=(SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') WITH (statement nvarchar(max) '$.statement') c
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@ns AND d.declared_id=@port;
IF @sem IS NULL THROW 51000,'LIST_CAPABILITIES_PORT_NOT_SELECTED',1;
IF @stmt IS NULL THROW 51000,'LIST_CAPABILITIES_STATEMENT_MISSING',1;
IF CHARINDEX(N'circuitAvailable',@stmt)=0
BEGIN
 IF @prevver IS NULL THROW 51000,'LIST_CAPABILITIES_PORT_VERSION_MISSING',1;
 -- The availability preamble runs once per listing: the latest explicit
 -- publication's catalogue keys are staged so each row is a lookup, not a scan.
 DECLARE @availability nvarchar(max)=N'
DECLARE @circuit_prefix nvarchar(400)=N''/media/library/outputs/estate-topology/'';
DECLARE @circuit_catalogs TABLE (url nvarchar(500) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @circuit_catalogs(url)
SELECT CONVERT(nvarchar(500),[key]) COLLATE Latin1_General_100_BIN2
FROM OPENJSON(COALESCE(JSON_QUERY((
 SELECT TOP 1 CONVERT(nvarchar(max), CONVERT(varchar(max),b.bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM media.asset a
 JOIN media.asset_revision r ON r.asset_id=a.asset_id
 JOIN media.blob b ON b.digest=r.blob_digest
 WHERE a.logical_key=CONCAT(''media-catalog/'',@estate_model_pk,''/website-visual-publication'')
 ORDER BY r.created_at DESC, r.revision_id DESC),''$.artifacts''),N''[]''))
WHERE [key] LIKE @circuit_prefix+N''%/catalog.js'';
';
 DECLARE @with_at int=CHARINDEX(N'WITH declared AS (',@stmt);
 DECLARE @promise_at int=CHARINDEX(N'd.promise,',@stmt);
 IF @with_at=0 OR @promise_at=0 THROW 51000,'LIST_CAPABILITIES_STATEMENT_SHAPE_UNRECOGNIZED',1;
 SET @stmt=STUFF(@stmt,@promise_at+LEN(N'd.promise,'),0,
  N' CONVERT(bit, CASE WHEN EXISTS (SELECT 1 FROM @circuit_catalogs t WHERE t.url=@circuit_prefix+d.capability_id+N''/catalog.js'') THEN 1 ELSE 0 END) AS circuitAvailable,');
 SET @stmt=STUFF(@stmt,@with_at,0,@availability);
 SET @sem=JSON_MODIFY(@sem,'$.configuration.statement',@stmt);
 EXEC model.put_semantic_definition 'PORT',@ns,@port,@sem,@object2 OUTPUT,@definition2 OUTPUT,@digest2 OUTPUT;
 SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object2);
 IF @portpk IS NOT NULL BEGIN
  SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition2);
  IF @version IS NULL BEGIN
   INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@portpk,@object2,@definition2,@digest2,'consumer-interface-authority.v1','PORT',@definition2,N'');
   SET @version=SCOPE_IDENTITY();
  END
  UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
 END
END
-- Proof: the selected statement now stages catalogue keys and reports the bit;
-- the invocation points at that definition's port version.
SELECT 'list_capabilities_circuit_availability' AS result_set, d.declared_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 CONVERT(bit, CASE WHEN c.statement LIKE N'%@circuit_catalogs%' THEN 1 ELSE 0 END) AS availability_source,
 CONVERT(bit, CASE WHEN c.statement LIKE N'%AS circuitAvailable%' THEN 1 ELSE 0 END) AS availability_column,
 LEN(c.statement) AS statement_chars
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') WITH (statement nvarchar(max) '$.statement') c
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@ns AND d.declared_id=@port;
SELECT 'list_capabilities_port_version' AS result_set, opi.execution_operation_pk, opi.port_version_pk,
 pv.semantic_object_definition_pk, @prevver AS previous_port_version_pk
FROM model.operation_port_invocation opi
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
WHERE opi.port_version_pk=(SELECT pv2.port_version_pk FROM model.port_version pv2
 WHERE pv2.semantic_object_definition_pk=(SELECT d.semantic_object_definition_pk
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind='PORT' AND d.namespace_id=@ns AND d.declared_id=@port));
SELECT 'list_capabilities_publication' AS result_set, @estate AS estate_model_pk,
 CONVERT(bit, CASE WHEN EXISTS (
  SELECT 1 FROM media.asset a
  JOIN media.asset_revision r ON r.asset_id=a.asset_id
  JOIN media.blob b ON b.digest=r.blob_digest
  WHERE a.logical_key=CONCAT('media-catalog/',@estate,'/website-visual-publication')) THEN 1 ELSE 0 END) AS publication_present;
COMMIT TRANSACTION;
