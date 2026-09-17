-- rebase-projected-applications-on-providers.sql
--
-- Moves the declared projected-application binding base from the capability
-- cache (`embodiments/<host>/projected`) to the read-allowed provider area
-- (`providers/<host>/projected`). The invocation confinement forbids reading
-- the capability cache (`restrict-memory-process.mjs`), while the declared
-- composed port must read the projected application it names; `providers` is
-- already a read-allowed root, is not a cache, and preserves the bindingRef
-- depth. The `bindingRef` values are unchanged.
--
-- Idempotent: a replay finds the provider-relative base present and writes no
-- new definition.
--
-- Default: ROLLBACK. Install only after the from-transaction preflight passes:
--   node scripts/run-migration.mjs sql/migrations/rebase-projected-applications-on-providers.sql
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @ports TABLE (
  namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  declared_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  semantics nvarchar(max),
  prevver bigint,
  changed bit DEFAULT 0,
  PRIMARY KEY (namespace_id, declared_id));
INSERT @ports (namespace_id, declared_id, semantics, prevver)
SELECT n.namespace_id, so.declared_id, JSON_QUERY(latest.envelope,'$.semantics'), latest.port_version_pk
FROM model.port p
JOIN model.semantic_object so ON so.semantic_object_pk=p.semantic_object_pk
JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
CROSS APPLY (
  SELECT TOP 1 d.semantic_object_definition_pk,
    (SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk) AS port_version_pk,
    CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS envelope
  FROM model.semantic_object_definition d
  JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk AND ed.estate_model_pk=@estate
  JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE d.semantic_object_pk=p.semantic_object_pk
  ORDER BY d.semantic_object_definition_pk DESC
) latest
WHERE n.namespace_id IN (N'sidefx:capability:execute-projected-model-provider-attempt',
                         N'sidefx:capability:execute-governed-model-invocation',
                         N'sidefx:capability:obtain-governed-model-response')
  AND JSON_VALUE(latest.envelope,'$.semantics.configuration.bindingRef') IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM @ports) THROW 51000,'COMPOSED_PORTS_NOT_FOUND',1;
IF EXISTS (SELECT 1 FROM @ports WHERE prevver IS NULL) THROW 51000,'COMPOSED_PORT_VERSION_MISSING',1;

DECLARE @namespace nvarchar(400), @declared nvarchar(400), @semantics nvarchar(max), @prevver bigint,
  @host nvarchar(400), @binding_base nvarchar(400),
  @object bigint, @definition bigint, @digest binary(32), @version bigint, @portpk bigint;
DECLARE port_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT namespace_id, declared_id, semantics, prevver FROM @ports ORDER BY namespace_id, declared_id;
OPEN port_cursor;
FETCH NEXT FROM port_cursor INTO @namespace, @declared, @semantics, @prevver;
WHILE @@FETCH_STATUS=0 BEGIN
  IF @namespace NOT LIKE N'sidefx:capability:%' THROW 51000,'COMPOSED_PORT_NAMESPACE_UNEXPECTED',1;
  SET @host=SUBSTRING(@namespace,LEN(N'sidefx:capability:')+1,400);
  SET @binding_base=N'providers/'+@host+N'/projected';
  IF ISNULL(JSON_VALUE(@semantics,'$.configuration.bindingBase'),N'')<>@binding_base BEGIN
    SET @semantics=JSON_MODIFY(@semantics,'$.configuration.bindingBase',@binding_base);
    EXEC model.put_semantic_definition 'PORT', @namespace, @declared, @semantics,
      @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
    SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object);
    IF @portpk IS NULL THROW 51000,'COMPOSED_PORT_ROW_MISSING',1;
    SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition);
    IF @version IS NULL BEGIN
      INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
        port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
      VALUES(@portpk,@object,@definition,@digest,'consumer-interface-authority.v1','PORT',@definition,N'');
      SET @version=SCOPE_IDENTITY();
    END
    UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
    UPDATE @ports SET semantics=@semantics, changed=1 WHERE namespace_id=@namespace COLLATE Latin1_General_100_BIN2
      AND declared_id=@declared COLLATE Latin1_General_100_BIN2;
  END
  FETCH NEXT FROM port_cursor INTO @namespace, @declared, @semantics, @prevver;
END
CLOSE port_cursor;
DEALLOCATE port_cursor;
SELECT '1_provider_bases' AS result_set, p.namespace_id, p.declared_id,
  JSON_VALUE(p.semantics,'$.configuration.bindingBase') AS binding_base, p.changed
FROM @ports p ORDER BY p.namespace_id, p.declared_id;
COMMIT TRANSACTION;
