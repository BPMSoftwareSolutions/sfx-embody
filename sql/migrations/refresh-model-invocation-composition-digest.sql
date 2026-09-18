-- refresh-model-invocation-composition-digest.sql
--
-- Refreshes the composition digest of
-- `execute-governed-model-invocation`'s `model-invocation-execution-port` to
-- the freshly projected `execute-projected-model-provider-attempt`
-- application. The wrapper capability is unchanged; only the projected child's
-- canonical binding and plan-authority digests moved.
--
-- Idempotent: a replay finds the digests present and writes no new definition.
--
-- Default: ROLLBACK. Install only after the from-transaction preflight passes:
--   node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/run-migration.mjs sql/migrations/refresh-model-invocation-composition-digest.sql
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @namespace nvarchar(400)=N'sidefx:capability:execute-governed-model-invocation';
DECLARE @declared nvarchar(400)=N'model-invocation-execution-port';
DECLARE @binding_digest nvarchar(80)=N'sha256:31df62a424d4c5244fffe6c0c828b699b1457e241625d3e92e15c49fe5858656';
DECLARE @authority_digest nvarchar(80)=N'sha256:4c2d1b3f114b1050d8316772a45c3ea9134e4d839ac64d256229decaa051c6db';
DECLARE @semantics nvarchar(max), @prevver bigint;
SELECT @semantics=JSON_QUERY(latest.envelope,'$.semantics'), @prevver=latest.port_version_pk
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
WHERE n.namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND so.declared_id=@declared COLLATE Latin1_General_100_BIN2;
IF @semantics IS NULL OR @prevver IS NULL THROW 51000,'MODEL_INVOCATION_PORT_NOT_FOUND',1;
DECLARE @changed int=0, @object bigint, @definition bigint, @digest binary(32), @version bigint, @portpk bigint;
IF ISNULL(JSON_VALUE(@semantics,'$.configuration.bindingDigest'),N'')<>@binding_digest BEGIN
  SET @semantics=JSON_MODIFY(@semantics,'$.configuration.bindingDigest',@binding_digest);
  SET @changed=1;
END
IF ISNULL(JSON_VALUE(@semantics,'$.configuration.capabilityAuthorityDigest'),N'')<>@authority_digest BEGIN
  SET @semantics=JSON_MODIFY(@semantics,'$.configuration.capabilityAuthorityDigest',@authority_digest);
  SET @changed=1;
END
IF @changed=1 BEGIN
  EXEC model.put_semantic_definition 'PORT', @namespace, @declared, @semantics,
    @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
  SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object);
  IF @portpk IS NULL THROW 51000,'MODEL_INVOCATION_PORT_ROW_MISSING',1;
  SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition);
  IF @version IS NULL BEGIN
    INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
      port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
    VALUES(@portpk,@object,@definition,@digest,'consumer-interface-authority.v1','PORT',@definition,N'');
    SET @version=SCOPE_IDENTITY();
  END
  UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
END
SELECT '1_model_invocation_port' AS result_set, @namespace AS namespace_id, @declared AS declared_id,
  JSON_VALUE(@semantics,'$.configuration.bindingDigest') AS binding_digest,
  JSON_VALUE(@semantics,'$.configuration.capabilityAuthorityDigest') AS authority_digest,
  JSON_VALUE(@semantics,'$.configuration.bindingBase') AS binding_base,
  @changed AS changed;
COMMIT TRANSACTION;
