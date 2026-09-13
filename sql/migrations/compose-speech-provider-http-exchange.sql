-- compose-speech-provider-http-exchange.sql
--
-- Declares speech-provider's governed HTTP exchange as a cross-capability
-- invocation of observe-governed-http-exchange's root Scenario, replacing the
-- direct sda-governed-http-exchange-port.v1 effect binding at ordinal 3.
--
-- Nothing new is invented: the target Scenario, its contracts, its Ports and its
-- Transformations already exist in the model. This migration only mints a new
-- version of speech-provider's root execution authority whose third operation
-- targets another capability's Scenario, and records the matching normalized
-- operation row. The invocation closure walks the target capability; the
-- assembled declaration carries its feature, Ports and Transformations.
--
-- Default: ROLLBACK after verification. Replace the final ROLLBACK with COMMIT
-- to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @scnVer bigint = 755;
DECLARE @eaPk bigint = 754;
DECLARE @eaSo bigint = 7886;
DECLARE @targetScnVer bigint = 419;
DECLARE @capNs nvarchar(400) = N'sidefx:capability:speech-provider';
DECLARE @authorityId nvarchar(400) = N'speech-provider-exchange.v3';
DECLARE @manifestHex varchar(64) = N'ebfa2f14215fa987fbbf2bda6171097a91efdaf7b961befed9a7aa77275cbe70';
DECLARE @profile nvarchar(400);
SELECT @profile = authority_profile FROM model.execution_authority_version WHERE execution_authority_version_pk=@eaPk;

IF @profile IS NULL THROW 51000,'SPEECH_AUTHORITY_NOT_FOUND',1;

-- The new declared authority: identical to the current one except the third
-- operation invokes the target capability's root Scenario instead of binding the
-- platform HTTP effect port directly.
DECLARE @env nvarchar(max) = N'{"address":{"id":"' + @authorityId + N'","kind":"EXECUTION_AUTHORITY","namespace":"' + @capNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":{"id":"' + @authorityId + N'","operations":['
  + N'{"kind":"invoke-port","portId":"speech-audio-request-adapter-port"},'
  + N'{"kind":"invoke-port","portId":"bind-speech-provider-credential-port"},'
  + N'{"kind":"invoke-port","portId":"bind-governed-http-request-port"},'
  + N'{"kind":"invoke-scenario","scenarioId":"observe-governed-http-exchange"},'
  + N'{"kind":"invoke-port","portId":"normalize-speech-audio-observation-port"}'
  + N'],"owningScenarioId":"speech-provider-exchange"},"authority_manifest_digest":"' + @manifestHex + N'"}}';
DECLARE @bytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @digest binary(32) = HASHBYTES('SHA2_256', @bytes);

IF EXISTS (SELECT 1 FROM model.execution_authority_version WHERE execution_authority_pk=@eaPk AND definition_digest=@digest)
  THROW 51000,'SPEECH_COMPOSITION_ALREADY_INSTALLED',1;

IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
  VALUES (@eaSo, 'EXECUTION_AUTHORITY', @digest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest));
DECLARE @sod bigint = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @sod);
INSERT model.execution_authority_version (execution_authority_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, authority_profile, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@eaPk, @eaSo, @sod, @digest, @profile, 'EXECUTION_AUTHORITY', @sod, N'');
DECLARE @newEaVer bigint = SCOPE_IDENTITY();
UPDATE model.scenario_event SET execution_authority_version_pk=@newEaVer WHERE scenario_version_pk=@scnVer AND event_id=N'speech-provider-exchange';

-- Normalized operations for the new authority version: copy the port
-- invocations from the prior version by ordinal, and declare one cross-capability
-- scenario invocation.
INSERT model.execution_operation (execution_authority_version_pk, operation_id, ordinal, operation_kind, _owner_definition_pk, _canonical_pointer)
  VALUES
   (@newEaVer, NULL, 0, 'invoke-port', @sod, N'/semantics/authority/operations/0'),
   (@newEaVer, NULL, 1, 'invoke-port', @sod, N'/semantics/authority/operations/1'),
   (@newEaVer, NULL, 2, 'invoke-port', @sod, N'/semantics/authority/operations/2'),
   (@newEaVer, NULL, 3, 'invoke-scenario', @sod, N'/semantics/authority/operations/3'),
   (@newEaVer, NULL, 4, 'invoke-port', @sod, N'/semantics/authority/operations/4');
INSERT model.operation_port_invocation (execution_operation_pk, port_version_pk, operation_kind, _owner_definition_pk, _canonical_pointer)
  SELECT newEo.execution_operation_pk, oldPI.port_version_pk, 'invoke-port', @sod, newEo._canonical_pointer
  FROM model.execution_operation oldEo
  JOIN model.operation_port_invocation oldPI ON oldPI.execution_operation_pk=oldEo.execution_operation_pk
  JOIN model.execution_operation newEo ON newEo.execution_authority_version_pk=@newEaVer AND newEo.ordinal=oldEo.ordinal
  WHERE oldEo.execution_authority_version_pk=@eaPk AND oldEo.ordinal IN (0,1,2,4);
INSERT model.operation_scenario_invocation (execution_operation_pk, target_scenario_version_pk, operation_kind, _owner_definition_pk, _canonical_pointer)
  SELECT eo.execution_operation_pk, @targetScnVer, 'invoke-scenario', @sod, eo._canonical_pointer
  FROM model.execution_operation eo
  WHERE eo.execution_authority_version_pk=@newEaVer AND eo.ordinal=3;

SELECT '1_new_speech_authority' AS result_set, eav.execution_authority_version_pk, eo.ordinal, eo.operation_kind,
       p.port_id, ts.scenario_id AS target_scenario
FROM model.execution_operation eo
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
LEFT JOIN model.operation_port_invocation pi ON pi.execution_operation_pk=eo.execution_operation_pk
LEFT JOIN model.port_version pv ON pv.port_version_pk=pi.port_version_pk
LEFT JOIN model.port p ON p.port_pk=pv.port_pk
LEFT JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
LEFT JOIN model.scenario_version tsv ON tsv.scenario_version_pk=osi.target_scenario_version_pk
LEFT JOIN model.scenario ts ON ts.scenario_pk=tsv.scenario_pk
WHERE eo.execution_authority_version_pk=@newEaVer
ORDER BY eo.ordinal;

SELECT '2_speech_closure' AS result_set, s.scenario_id AS downstream_scenario, cl.minimum_depth,
       dc.capability_id AS owning_capability
FROM analysis.v_scenario_invocation_closure cl
JOIN model.scenario_version sv ON sv.scenario_version_pk=cl.downstream_scenario_version_pk
JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
JOIN model.capability dc ON dc.capability_pk=s.capability_pk
WHERE cl.capability_version_pk=203 AND cl.selected_scenario_version_pk=755
ORDER BY cl.minimum_depth, s.scenario_id;
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
