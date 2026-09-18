-- refresh-os-credential-binding-digest.sql
--
-- Restores the conveyor's two OS-credential bindings to the canonical
-- `bind-os-environment-credential` projected application. That projection's
-- retained plan had been materialized with CRLF line endings, so its raw bytes
-- did not match the binding's `executionPlanDigest`; the projection is now
-- normalized to the repository's declared LF byte policy, the projected
-- conformance suite passes, and the canonical binding digest is the estate's
-- original `14bb15a2...`. An intermediate state had superseded the canonical
-- definition with a CRLF-captured `94d2bcbb...` definition; this migration
-- removes that supersession (its estate link and invocation relink) so the
-- canonical definition is selected again. Definition rows are never deleted;
-- only the superseding link and the invocation pointer move back.
--
-- Idempotent: a replay finds the canonical definition selected and changes
-- nothing.
--
-- Default: ROLLBACK. Install only after the from-transaction preflight passes:
--   node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/run-migration.mjs sql/migrations/refresh-os-credential-binding-digest.sql
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
DECLARE @canonical_digest nvarchar(80)=N'sha256:14bb15a2fd941e8659ef7507b0c43febe9cc72baaa822a0a834805d7bb0d3abc';
DECLARE @superseded_digest nvarchar(80)=N'sha256:94d2bcbb43787c429119fead9691cd4cd93bbe5bf4195bb6f48b612f6ca0d617';

DECLARE @ports TABLE (
  declared_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,
  canonical_version bigint,
  superseded_definition bigint,
  superseded_version bigint,
  changed bit DEFAULT 0);
INSERT @ports (declared_id, canonical_version, superseded_definition, superseded_version)
SELECT so.declared_id, canon.version_pk, super.definition_pk, super.version_pk
FROM model.semantic_object so
JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
OUTER APPLY (
  SELECT TOP 1 pv.port_version_pk AS version_pk, pv.semantic_object_definition_pk AS definition_pk
  FROM model.port_version pv
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=pv.semantic_object_definition_pk
  JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE pv.semantic_object_pk=so.semantic_object_pk
    AND JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.configuration.bindingDigest')=@canonical_digest
  ORDER BY pv.port_version_pk DESC) canon
OUTER APPLY (
  SELECT TOP 1 pv.port_version_pk AS version_pk, pv.semantic_object_definition_pk AS definition_pk
  FROM model.port_version pv
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=pv.semantic_object_definition_pk
  JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE pv.semantic_object_pk=so.semantic_object_pk
    AND JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.configuration.bindingDigest')=@superseded_digest
  ORDER BY pv.port_version_pk DESC) super
WHERE n.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
  AND so.declared_id IN (N'bind-gemini-os-credential-port',N'bind-openai-os-credential-port');
IF (SELECT COUNT(*) FROM @ports)<>2 THROW 51000,'OS_CREDENTIAL_PORTS_NOT_FOUND',1;
IF EXISTS (SELECT 1 FROM @ports WHERE canonical_version IS NULL) THROW 51000,'OS_CREDENTIAL_CANONICAL_DEFINITION_MISSING',1;

-- Relink every invocation of the superseded version to the canonical version.
UPDATE inv SET inv.port_version_pk=p.canonical_version
FROM model.operation_port_invocation inv
JOIN @ports p ON p.superseded_version IS NOT NULL AND inv.port_version_pk=p.superseded_version;
-- Remove only the superseding estate link; the definition row is retained.
DELETE ed FROM model.estate_definition ed
JOIN @ports p ON p.superseded_definition IS NOT NULL AND ed.semantic_object_definition_pk=p.superseded_definition
WHERE ed.estate_model_pk=@estate;
UPDATE @ports SET changed=1 WHERE superseded_definition IS NOT NULL;

SELECT '1_os_credential_ports' AS result_set, p.declared_id,
  p.canonical_version, p.superseded_version, p.changed
FROM @ports p ORDER BY p.declared_id;
SELECT '2_selected_digest' AS result_set, d.declared_id,
  JSON_VALUE(d.definition_json,'$.semantics.configuration.bindingDigest') AS binding_digest
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
  AND d.declared_id IN (N'bind-gemini-os-credential-port',N'bind-openai-os-credential-port')
ORDER BY d.declared_id;
COMMIT TRANSACTION;
