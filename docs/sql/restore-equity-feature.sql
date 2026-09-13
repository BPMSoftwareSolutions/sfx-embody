-- restore-equity-feature.sql
--
-- Restores resolve-equity-market-price-evidence's declared feature to the
-- single-root-Scenario generation that matches its declared five-Port pipeline.
-- The current canonical feature declares four Scenarios, but the selected
-- capability version links only the root, so the planner finds no execution
-- authority for the three unlinked Scenarios and refuses the graph.
--
-- This authors a new parsed feature declaration carrying the working text and
-- its one root Scenario, and binds it CANONICAL for the current capability
-- version. No Scenario, Port, contract or authority is deleted.
--
-- Default: ROLLBACK. Replace with COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END CLOSE @trgCur; DEALLOCATE @trgCur;

DECLARE @capId nvarchar(400) = N'resolve-equity-market-price-evidence';
DECLARE @text nvarchar(max) = N'@capability:resolve-equity-market-price-evidence
@root-scenario:resolve-equity-market-price-evidence
Feature: Resolve provider-neutral equity market-price evidence

  A consumer supplies a canonical symbol and region and receives one canonical
  outcome independent of the selected supplier. The provider binding, native
  request, credential realization, bounded exchange and supplier testimony are
  declared effect authority executed by the platform, never capability code.
  An observed price is attributable provider testimony, not an assertion of
  intrinsic value, investment suitability, or cross-provider equivalence.

  @scenario:resolve-equity-market-price-evidence
  @input:live-equity-price-request
  @input-contract:live-equity-price-request.v1
  @event:equity-market-price-evidence-requested
  @event-authority:resolve-equity-market-price-evidence.v1
  @outcome:equity-market-price-evidence
  @outcome-contract:equity-market-price-evidence.v1
  @outcome-terminal
  Scenario: Resolve an equity price observation through a declared provider binding
    Given a canonical symbol and region and one admitted provider endpoint authority
    When the credential reference is bound, one bounded exchange is observed, and the native testimony is normalized
    Then the canonical evidence retains symbol, region, currency, price, market time, market state, exchange, source attribution, and provider testimony identity
';

BEGIN TRANSACTION;

DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capPk bigint = (SELECT capability_pk FROM model.capability WHERE capability_id=@capId);
DECLARE @featPk bigint = (SELECT feature_pk FROM model.capability WHERE capability_pk=@capPk);
DECLARE @featSo bigint = (SELECT semantic_object_pk FROM model.feature WHERE feature_pk=@featPk);
DECLARE @capVer bigint = (SELECT capability_version_pk FROM model.estate_capability WHERE estate_model_pk=@model AND capability_pk=@capPk);
DECLARE @scnPk bigint = (SELECT scenario_pk FROM model.scenario WHERE capability_pk=@capPk AND scenario_id=@capId);
DECLARE @scnVer bigint = 898;

DECLARE @tb varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@text) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @td binary(32) = HASHBYTES('SHA2_256', @tb);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@td) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@td, @tb, DATALENGTH(@tb));

DECLARE @env nvarchar(max) = N'{"address":{"id":"' + @capId + N'","kind":"FEATURE","namespace":"sidefx:features"},"format":"sidefx-semantic-definition.v1","semantics":{"name":"Resolve provider-neutral equity market-price evidence","description":"A consumer supplies a canonical symbol and region and receives one canonical outcome independent of the selected supplier.","content_digest":"' + LOWER(CONVERT(varchar(64), @td, 2)) + N'","source_path":"features/' + @capId + N'.feature","scenarios":[{"scenarioId":"' + @capId + N'","scenarioVersionPk":' + CONVERT(nvarchar(20), @scnVer) + N'}]}}';
DECLARE @eb varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @ed binary(32) = HASHBYTES('SHA2_256', @eb);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@ed) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@ed, @eb, DATALENGTH(@eb));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@featSo, 'FEATURE', @ed, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@ed));
DECLARE @sod bigint = SCOPE_IDENTITY();
IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@sod) INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @sod);
INSERT model.feature_version (feature_pk, capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, source_profile, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@featPk, @capPk, @featSo, @sod, @ed, @capId, 'parsed-feature-declaration.v1', 'FEATURE', @sod, N'');
DECLARE @newFv bigint = SCOPE_IDENTITY();
INSERT model.feature_scenario (feature_version_pk, scenario_pk, scenario_version_pk, capability_pk, ordinal) VALUES (@newFv, @scnPk, @scnVer, @capPk, 0);
IF EXISTS (SELECT 1 FROM model.estate_capability_feature WHERE estate_model_pk=@model AND capability_pk=@capPk)
  UPDATE model.estate_capability_feature SET capability_version_pk=@capVer, feature_version_pk=@newFv, binding_role='CANONICAL'
  WHERE estate_model_pk=@model AND capability_pk=@capPk;
ELSE
  INSERT model.estate_capability_feature (estate_model_pk, capability_pk, capability_version_pk, feature_version_pk, binding_role) VALUES (@model, @capPk, @capVer, @newFv, 'CANONICAL');

SELECT '1_new_feature_version' AS result_set, @newFv AS feature_version_pk, @capVer AS capability_version_pk, @scnVer AS scenario_version_pk;
SELECT '2_latest_feature_text' AS result_set, capability_id, LEFT(document, 60) AS head
FROM analysis.v_capability_execution_declaration
WHERE capability_id=@capId AND entry_id=N'capability.feature';
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
