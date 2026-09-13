-- compose-resolve-equity-market-price-evidence.sql
--
-- Declares a capability whose single root operation invokes another capability's
-- root Scenario: compose-resolve-equity-market-price-evidence invokes
-- resolve-equity-market-price-evidence.
--
-- This is the composition proof. The composing capability is created by the
-- authoring surface, its root authority is replaced with one declared
-- invoke-scenario operation, and its root Scenario faces are linked to the
-- invoked capability's declared contracts. Neither capability's meaning is
-- edited; the composition is rows.
--
-- Default: ROLLBACK. Replace with COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
DECLARE @capId nvarchar(400) = N'compose-resolve-equity-market-price-evidence';
DECLARE @target nvarchar(400) = N'resolve-equity-market-price-evidence';
DECLARE @targetScnVer bigint = 898;
DECLARE @targetInCv bigint = 697;
DECLARE @targetOutCv bigint = 698;
DECLARE @targetInId nvarchar(400) = N'live-equity-price-request';
DECLARE @targetInContract nvarchar(400) = N'live-equity-price-request.v1';
DECLARE @targetOutId nvarchar(400) = N'equity-market-price-evidence';
DECLARE @targetOutContract nvarchar(400) = N'equity-market-price-evidence.v1';
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

-- The composing capability is a declared capability, created by the authoring surface.
EXEC model.scaffold_capability @capability_id=@capId, @on_exists=N'REPLACE';

DECLARE @capPk bigint, @capVer bigint, @capSo bigint, @capSod bigint, @scnPk bigint, @scnVer bigint, @eaPk bigint, @eaSo bigint, @featPk bigint, @featSo bigint, @profile nvarchar(400);
SELECT @capPk=c.capability_pk, @capSo=c.semantic_object_pk, @featPk=c.feature_pk FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capId;
SELECT @capVer=capability_version_pk, @capSod=semantic_object_definition_pk FROM model.estate_capability WHERE estate_model_pk=@model AND capability_pk=@capPk;
SELECT @scnPk=rs.scenario_pk, @scnVer=cs.scenario_version_pk FROM model.capability_root_scenario rs JOIN model.capability_scenario cs ON cs.capability_pk=@capPk AND cs.capability_version_pk=@capVer AND cs.scenario_pk=rs.scenario_pk WHERE rs.capability_version_pk=@capVer;
SELECT @eaPk=ea.execution_authority_pk, @eaSo=ea.semantic_object_pk FROM model.execution_authority ea JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk WHERE n.namespace_id=N'sidefx:capability:'+@capId AND ea.execution_authority_id=@capId+N'.v1';
SELECT @featSo=semantic_object_pk FROM model.feature WHERE feature_pk=@featPk;
SET @profile = N'execution-authorities.v1';

-- Root authority: one operation that invokes the target capability's root Scenario.
DECLARE @env nvarchar(max) = N'{"address":{"id":"' + @capId + N'.v1","kind":"EXECUTION_AUTHORITY","namespace":"sidefx:capability:' + @capId + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":{"id":"' + @capId + N'.v1","operations":[{"kind":"invoke-scenario","scenarioId":"' + @target + N'"}],"owningScenarioId":"' + @capId + N'"}}}';
DECLARE @bytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @digest binary(32) = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
IF NOT EXISTS (SELECT 1 FROM model.semantic_object_definition WHERE semantic_object_pk=@eaSo AND definition_digest=@digest)
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@eaSo, 'EXECUTION_AUTHORITY', @digest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest));
DECLARE @authSod bigint = (SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@eaSo AND definition_digest=@digest);
IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@authSod) INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @authSod);
DECLARE @eaVer bigint = (SELECT MAX(execution_authority_version_pk) FROM model.execution_authority_version WHERE execution_authority_pk=@eaPk AND definition_digest=@digest);
IF @eaVer IS NULL
BEGIN
  INSERT model.execution_authority_version (execution_authority_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, authority_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@eaPk, @eaSo, @authSod, @digest, @profile, 'EXECUTION_AUTHORITY', @authSod, N'');
  SET @eaVer = SCOPE_IDENTITY();
  INSERT model.execution_operation (execution_authority_version_pk, operation_id, ordinal, operation_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@eaVer, NULL, 0, 'invoke-scenario', @authSod, N'/semantics/authority/operations/0');
  DECLARE @opPk bigint = SCOPE_IDENTITY();
  INSERT model.operation_scenario_invocation (execution_operation_pk, target_scenario_version_pk, operation_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@opPk, @targetScnVer, 'invoke-scenario', @authSod, N'/semantics/authority/operations/0');
END

-- Root Scenario faces: the invoking capability shares the invoked capability's declared contracts.
UPDATE model.scenario_event SET execution_authority_version_pk=@eaVer WHERE scenario_version_pk=@scnVer;
UPDATE model.scenario_input SET input_contract_version_pk=@targetInCv, contract_reference_state='RESOLVED' WHERE scenario_version_pk=@scnVer;
UPDATE model.scenario_outcome_contract SET contract_version_pk=@targetOutCv WHERE scenario_version_pk=@scnVer;

-- Feature: repoint the root declaration at the shared contracts and the invoking authority.
DECLARE @text nvarchar(max) = N'@capability:' + @capId + N'
@root-scenario:' + @capId + N'
Feature: Compose a declared capability
' + N'
  @scenario:' + @capId + N'
  @input:' + @targetInId + N'
  @input-contract:' + @targetInContract + N'
  @event:' + @capId + N'-requested
  @event-authority:' + @capId + N'.v1
  @outcome:' + @targetOutId + N'
  @outcome-contract:' + @targetOutContract + N'
  @outcome-terminal
  Scenario: Invoke the declared capability and return its outcome
    Given the invoking caller supplies the declared input
    When the declared capability is invoked
    Then the caller observes the declared outcome
';
DECLARE @tb varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@text) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @td binary(32) = HASHBYTES('SHA2_256', @tb);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@td) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@td, @tb, DATALENGTH(@tb));
DECLARE @fenv nvarchar(max) = N'{"address":{"id":"' + @capId + N'","kind":"FEATURE","namespace":"sidefx:features"},"format":"sidefx-semantic-definition.v1","semantics":{"name":"Compose a declared capability","description":"Invokes another declared capability and returns its outcome.","content_digest":"' + LOWER(CONVERT(varchar(64), @td, 2)) + N'","source_path":"features/' + @capId + N'.feature","scenarios":[{"scenarioId":"' + @capId + N'","scenarioVersionPk":' + CONVERT(nvarchar(20), @scnVer) + N'}]}}';
DECLARE @fb varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@fenv) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @fd binary(32) = HASHBYTES('SHA2_256', @fb);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@fd) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@fd, @fb, DATALENGTH(@fb));
IF NOT EXISTS (SELECT 1 FROM model.semantic_object_definition WHERE semantic_object_pk=@featSo AND definition_digest=@fd)
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@featSo, 'FEATURE', @fd, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@fd));
DECLARE @featSod bigint = (SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@featSo AND definition_digest=@fd);
IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@featSod) INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @featSod);
INSERT model.feature_version (feature_pk, capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, source_profile, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@featPk, @capPk, @featSo, @featSod, @fd, @capId, 'parsed-feature-declaration.v1', 'FEATURE', @featSod, N'');
DECLARE @featVer bigint = SCOPE_IDENTITY();
INSERT model.feature_scenario (feature_version_pk, scenario_pk, scenario_version_pk, capability_pk, ordinal) VALUES (@featVer, @scnPk, @scnVer, @capPk, 0);
IF EXISTS (SELECT 1 FROM model.estate_capability_feature WHERE estate_model_pk=@model AND capability_pk=@capPk)
  UPDATE model.estate_capability_feature SET capability_version_pk=@capVer, feature_version_pk=@featVer, binding_role='CANONICAL' WHERE estate_model_pk=@model AND capability_pk=@capPk;
ELSE
  INSERT model.estate_capability_feature (estate_model_pk, capability_pk, capability_version_pk, feature_version_pk, binding_role) VALUES (@model, @capPk, @capVer, @featVer, 'CANONICAL');

SELECT '1_created' AS result_set, @capId AS capability_id, @capVer AS capability_version_pk, @scnVer AS scenario_version_pk, @eaVer AS execution_authority_version_pk;
SELECT '2_root_operation' AS result_set, eo.ordinal, eo.operation_kind, ts.scenario_id AS target_scenario
FROM model.execution_operation eo
JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
JOIN model.scenario_version tsv ON tsv.scenario_version_pk=osi.target_scenario_version_pk
JOIN model.scenario ts ON ts.scenario_pk=tsv.scenario_pk
WHERE eo.execution_authority_version_pk=@eaVer;
SELECT '3_faces' AS result_set, ict.contract_id AS input_contract, oct.contract_id AS outcome_contract
FROM model.scenario_input si
JOIN model.contract_version icv ON icv.contract_version_pk=si.input_contract_version_pk
JOIN model.contract ict ON ict.contract_pk=icv.contract_pk
LEFT JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk=si.scenario_version_pk
LEFT JOIN model.contract_version ocv ON ocv.contract_version_pk=soc.contract_version_pk
LEFT JOIN model.contract oct ON oct.contract_pk=ocv.contract_pk
WHERE si.scenario_version_pk=@scnVer;
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
