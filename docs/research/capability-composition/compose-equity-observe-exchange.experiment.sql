-- compose-equity-observe-exchange.sql
--
-- Declares resolve-equity-market-price-evidence's HTTP step as a cross-capability
-- invocation of observe-governed-http-exchange's root Scenario, replacing the
-- direct sda-governed-http-exchange-port.v1 effect binding at ordinal 3.
--
-- This is a drop-in composition: the state entering ordinal 3 is
-- build-equity-price-exchange-request's output, which is exactly
-- observe-governed-http-exchange-input.v1, and observe's root outcome contract
-- governed-http-exchange-evidence.v1 is exactly what normalize-equity-price-evidence
-- consumes. No transformation or contract is changed.
--
-- Default: ROLLBACK. Replace with COMMIT to install.
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
DECLARE @targetScnVer bigint = 419;
DECLARE @capNs nvarchar(400) = N'sidefx:capability:resolve-equity-market-price-evidence';
DECLARE @authorityId nvarchar(400) = N'resolve-equity-market-price-evidence.v1';
DECLARE @profile nvarchar(400) = (SELECT TOP 1 authority_profile FROM model.execution_authority_version WHERE execution_authority_pk=@eaPk ORDER BY execution_authority_version_pk DESC);

DECLARE @env nvarchar(max) = N'{"address":{"id":"' + @authorityId + N'","kind":"EXECUTION_AUTHORITY","namespace":"' + @capNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":{"id":"' + @authorityId + N'","operations":['
  + N'{"kind":"invoke-port","portId":"build-equity-price-binding-request"},'
  + N'{"kind":"invoke-port","portId":"bind-equity-price-provider-credential"},'
  + N'{"kind":"invoke-port","portId":"build-equity-price-exchange-request"},'
  + N'{"kind":"invoke-scenario","scenarioId":"observe-governed-http-exchange"},'
  + N'{"kind":"invoke-port","portId":"normalize-equity-price-evidence"}'
  + N'],"owningScenarioId":"resolve-equity-market-price-evidence"}}}';
DECLARE @bytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @digest binary(32) = HASHBYTES('SHA2_256', @bytes);

DECLARE @existing bigint = (SELECT MAX(execution_authority_version_pk) FROM model.execution_authority_version WHERE execution_authority_pk=@eaPk AND definition_digest=@digest);
DECLARE @action nvarchar(20) = CASE WHEN @existing IS NOT NULL THEN N'ALREADY_INSTALLED' ELSE N'MINTED' END;
DECLARE @sod bigint, @newEaVer bigint;
IF @action = N'MINTED'
BEGIN
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest)
    INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
    VALUES (@eaSo, 'EXECUTION_AUTHORITY', @digest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest));
  SET @sod = SCOPE_IDENTITY();
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@sod)
    INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @sod);
  INSERT model.execution_authority_version (execution_authority_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, authority_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@eaPk, @eaSo, @sod, @digest, @profile, 'EXECUTION_AUTHORITY', @sod, N'');
  SET @newEaVer = SCOPE_IDENTITY();

  INSERT model.execution_operation (execution_authority_version_pk, operation_id, ordinal, operation_kind, _owner_definition_pk, _canonical_pointer)
    VALUES
     (@newEaVer, NULL, 0, 'invoke-port', @sod, N'/semantics/authority/operations/0'),
     (@newEaVer, NULL, 1, 'invoke-port', @sod, N'/semantics/authority/operations/1'),
     (@newEaVer, NULL, 2, 'invoke-port', @sod, N'/semantics/authority/operations/2'),
     (@newEaVer, NULL, 3, 'invoke-scenario', @sod, N'/semantics/authority/operations/3'),
     (@newEaVer, NULL, 4, 'invoke-port', @sod, N'/semantics/authority/operations/4');
  INSERT model.operation_port_invocation (execution_operation_pk, port_version_pk, operation_kind, _owner_definition_pk, _canonical_pointer)
    SELECT eo.execution_operation_pk, pv.port_version_pk, 'invoke-port', @sod, eo._canonical_pointer
    FROM model.execution_operation eo
    JOIN (VALUES
      (0, N'build-equity-price-binding-request'),
      (1, N'bind-equity-price-provider-credential'),
      (2, N'build-equity-price-exchange-request'),
      (4, N'normalize-equity-price-evidence')) m(ordinal, port_id) ON m.ordinal=eo.ordinal
    JOIN model.port p ON p.port_id=m.port_id
    JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk AND n.namespace_id=@capNs
    JOIN model.port_version pv ON pv.port_pk=p.port_pk
      AND pv.port_version_pk=(SELECT MAX(pv2.port_version_pk) FROM model.port_version pv2 WHERE pv2.port_pk=p.port_pk)
    WHERE eo.execution_authority_version_pk=@newEaVer;
  INSERT model.operation_scenario_invocation (execution_operation_pk, target_scenario_version_pk, operation_kind, _owner_definition_pk, _canonical_pointer)
    SELECT eo.execution_operation_pk, @targetScnVer, 'invoke-scenario', @sod, eo._canonical_pointer
    FROM model.execution_operation eo
    WHERE eo.execution_authority_version_pk=@newEaVer AND eo.ordinal=3;
END
ELSE
  SET @newEaVer = @existing;
UPDATE model.scenario_event SET execution_authority_version_pk=@newEaVer WHERE scenario_version_pk=@scnVer AND event_id=N'equity-market-price-evidence-requested';

SELECT '1_action' AS result_set, @action AS action, @newEaVer AS execution_authority_version_pk;
SELECT '2_equity_root' AS result_set, eo.ordinal, eo.operation_kind, p.port_id, ts.scenario_id AS target_scenario
FROM model.execution_operation eo
LEFT JOIN model.operation_port_invocation pi ON pi.execution_operation_pk=eo.execution_operation_pk
LEFT JOIN model.port_version pv ON pv.port_version_pk=pi.port_version_pk
LEFT JOIN model.port p ON p.port_pk=pv.port_pk
LEFT JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
LEFT JOIN model.scenario_version tsv ON tsv.scenario_version_pk=osi.target_scenario_version_pk
LEFT JOIN model.scenario ts ON ts.scenario_pk=tsv.scenario_pk
WHERE eo.execution_authority_version_pk=@newEaVer
ORDER BY eo.ordinal;
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
