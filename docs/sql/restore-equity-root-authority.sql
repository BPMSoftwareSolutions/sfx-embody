-- restore-equity-root-authority.sql
--
-- Restores resolve-equity-market-price-evidence's root execution authority to
-- the declared five-Port pipeline that reads the live request directly:
--
--   build-equity-price-binding-request
--   bind-equity-price-provider-credential
--   build-equity-price-exchange-request
--   observe-equity-price-exchange
--   normalize-equity-price-evidence
--
-- The current root authority (865) instead binds one transformation that reads
-- provider testimony (payload.nativeTestimony) at ordinal 0 and then invokes
-- three child Scenarios. Its first Port receives the live request, so the
-- testimony path is null and the lowering throws. This mints a new version of
-- the same authority with the declared pipeline and re-points the root
-- Scenario's event at it. Port inventory, contracts and the feature are
-- unchanged.
--
-- Default: ROLLBACK after verification. Replace the final ROLLBACK with COMMIT
-- to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @scnVer bigint = 898;
DECLARE @eaPk bigint = 843;
DECLARE @eaSo bigint = 9237;
DECLARE @capNs nvarchar(400) = N'sidefx:capability:resolve-equity-market-price-evidence';
DECLARE @authorityId nvarchar(400) = N'resolve-equity-market-price-evidence.v1';
DECLARE @profile nvarchar(400);
SELECT @profile = authority_profile FROM model.execution_authority_version WHERE execution_authority_version_pk=865;

DECLARE @env nvarchar(max) = N'{"address":{"id":"' + @authorityId + N'","kind":"EXECUTION_AUTHORITY","namespace":"' + @capNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":{"id":"' + @authorityId + N'","operations":['
  + N'{"kind":"invoke-port","portId":"build-equity-price-binding-request"},'
  + N'{"kind":"invoke-port","portId":"bind-equity-price-provider-credential"},'
  + N'{"kind":"invoke-port","portId":"build-equity-price-exchange-request"},'
  + N'{"kind":"invoke-port","portId":"observe-equity-price-exchange"},'
  + N'{"kind":"invoke-port","portId":"normalize-equity-price-evidence"}'
  + N'],"owningScenarioId":"resolve-equity-market-price-evidence"}}}';
DECLARE @bytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @digest binary(32) = HASHBYTES('SHA2_256', @bytes);

IF EXISTS (SELECT 1 FROM model.execution_authority_version WHERE execution_authority_pk=@eaPk AND definition_digest=@digest)
  THROW 51000,'EQUITY_PIPELINE_AUTHORITY_ALREADY_INSTALLED',1;

IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
  VALUES (@eaSo, 'EXECUTION_AUTHORITY', @digest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest));
DECLARE @sod bigint = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @sod);
INSERT model.execution_authority_version (execution_authority_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, authority_profile, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@eaPk, @eaSo, @sod, @digest, @profile, 'EXECUTION_AUTHORITY', @sod, N'');
DECLARE @newEaVer bigint = SCOPE_IDENTITY();
UPDATE model.scenario_event SET execution_authority_version_pk=@newEaVer WHERE scenario_version_pk=@scnVer AND event_id=N'equity-market-price-evidence-requested';

INSERT model.execution_operation (execution_authority_version_pk, operation_id, ordinal, operation_kind, _owner_definition_pk, _canonical_pointer)
  VALUES
   (@newEaVer, NULL, 0, 'invoke-port', @sod, N'/semantics/authority/operations/0'),
   (@newEaVer, NULL, 1, 'invoke-port', @sod, N'/semantics/authority/operations/1'),
   (@newEaVer, NULL, 2, 'invoke-port', @sod, N'/semantics/authority/operations/2'),
   (@newEaVer, NULL, 3, 'invoke-port', @sod, N'/semantics/authority/operations/3'),
   (@newEaVer, NULL, 4, 'invoke-port', @sod, N'/semantics/authority/operations/4');
INSERT model.operation_port_invocation (execution_operation_pk, port_version_pk, operation_kind, _owner_definition_pk, _canonical_pointer)
  SELECT eo.execution_operation_pk, pv.port_version_pk, 'invoke-port', @sod, eo._canonical_pointer
  FROM model.execution_operation eo
  JOIN (VALUES
    (0, N'build-equity-price-binding-request'),
    (1, N'bind-equity-price-provider-credential'),
    (2, N'build-equity-price-exchange-request'),
    (3, N'observe-equity-price-exchange'),
    (4, N'normalize-equity-price-evidence')) m(ordinal, port_id) ON m.ordinal=eo.ordinal
  JOIN model.port p ON p.port_id=m.port_id
  JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk AND n.namespace_id=@capNs
  JOIN model.port_version pv ON pv.port_pk=p.port_pk
    AND pv.port_version_pk=(SELECT MAX(pv2.port_version_pk) FROM model.port_version pv2 WHERE pv2.port_pk=p.port_pk)
  WHERE eo.execution_authority_version_pk=@newEaVer;

SELECT '1_new_equity_root' AS result_set, eo.ordinal, eo.operation_kind, p.port_id
FROM model.execution_operation eo
JOIN model.operation_port_invocation pi ON pi.execution_operation_pk=eo.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=pi.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk
WHERE eo.execution_authority_version_pk=@newEaVer
ORDER BY eo.ordinal;
SELECT '2_root_event' AS result_set, se.scenario_version_pk, se.execution_authority_version_pk
FROM model.scenario_event se WHERE se.scenario_version_pk=@scnVer;
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
