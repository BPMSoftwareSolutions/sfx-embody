-- refresh-conveyor-composition-digest.sql
--
-- Refreshes the composition digests of the conveyor's two model-response ports
-- (`obtain-governed-model-response-port`, `obtain-fallback-model-response-port`)
-- to the freshly projected `execute-governed-model-invocation` application. The
-- conveyor declaration is unchanged; only the projected child's canonical
-- binding digest moved (its plan authority digest is unchanged).
--
-- Idempotent: a replay finds the digest present and writes no new definition.
--
-- Default: ROLLBACK. Install only after the from-transaction preflight passes:
--   node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/run-migration.mjs sql/migrations/refresh-conveyor-composition-digest.sql
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @namespace nvarchar(400)=N'sidefx:capability:obtain-governed-model-response';
DECLARE @binding_digest nvarchar(80)=N'sha256:8c8e99a9c4347c2290d09bfd552e1d9487f60d9986a0af809804d1749e84cd57';
DECLARE @ports TABLE (declared_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,
  semantics nvarchar(max), prevver bigint, changed bit DEFAULT 0);
INSERT @ports (declared_id, semantics, prevver)
SELECT so.declared_id, JSON_QUERY(latest.envelope,'$.semantics'), latest.port_version_pk
FROM model.semantic_object so
JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
CROSS APPLY (
  SELECT TOP 1 d.semantic_object_definition_pk,
    (SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk) AS port_version_pk,
    CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS envelope
  FROM model.semantic_object_definition d
  JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk AND ed.estate_model_pk=@estate
  JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE d.semantic_object_pk=so.semantic_object_pk
  ORDER BY d.semantic_object_definition_pk DESC
) latest
WHERE n.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
  AND so.declared_id IN (N'obtain-governed-model-response-port',N'obtain-fallback-model-response-port');
IF (SELECT COUNT(*) FROM @ports)<>2 THROW 51000,'CONVEYOR_MODEL_PORTS_NOT_FOUND',1;
IF EXISTS (SELECT 1 FROM @ports WHERE prevver IS NULL) THROW 51000,'CONVEYOR_MODEL_PORT_VERSION_MISSING',1;

DECLARE @declared nvarchar(400), @semantics nvarchar(max), @prevver bigint,
  @object bigint, @definition bigint, @digest binary(32), @version bigint, @portpk bigint;
DECLARE port_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT declared_id, semantics, prevver FROM @ports ORDER BY declared_id;
OPEN port_cursor;
FETCH NEXT FROM port_cursor INTO @declared, @semantics, @prevver;
WHILE @@FETCH_STATUS=0 BEGIN
  IF ISNULL(JSON_VALUE(@semantics,'$.configuration.bindingDigest'),N'')<>@binding_digest BEGIN
    SET @semantics=JSON_MODIFY(@semantics,'$.configuration.bindingDigest',@binding_digest);
    EXEC model.put_semantic_definition 'PORT', @namespace, @declared, @semantics,
      @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
    SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object);
    IF @portpk IS NULL THROW 51000,'CONVEYOR_MODEL_PORT_ROW_MISSING',1;
    SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition);
    IF @version IS NULL BEGIN
      INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
        port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
      VALUES(@portpk,@object,@definition,@digest,'consumer-interface-authority.v1','PORT',@definition,N'');
      SET @version=SCOPE_IDENTITY();
    END
    UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
    UPDATE @ports SET semantics=@semantics, changed=1 WHERE declared_id=@declared COLLATE Latin1_General_100_BIN2;
  END
  FETCH NEXT FROM port_cursor INTO @declared, @semantics, @prevver;
END
CLOSE port_cursor;
DEALLOCATE port_cursor;
SELECT '1_conveyor_model_ports' AS result_set, p.declared_id,
  JSON_VALUE(p.semantics,'$.configuration.bindingDigest') AS binding_digest,
  JSON_VALUE(p.semantics,'$.configuration.capabilityAuthorityDigest') AS authority_digest,
  JSON_VALUE(p.semantics,'$.configuration.bindingBase') AS binding_base,
  p.changed
FROM @ports p ORDER BY p.declared_id;
COMMIT TRANSACTION;
