-- work-order-002-edit-equity.sql
--
-- One edit to the working definition of resolve-equity-market-price-evidence:
-- append "-EDITED" to the normalize transformation's bindingId literal. The edit
-- is uncommitted and the script rolls back by default. Invoke the edited
-- definition before rollback (in-transaction, or via an extracted bundle).
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @CapabilityId nvarchar(120) = N'resolve-equity-market-price-evidence';
DECLARE @path nvarchar(400) = N'capabilities/resolve-equity-market-price-evidence/semantic-transformation.authority.json';
DECLARE @oldBinding nvarchar(200) = N'rapidapi-davethebeast-yahoo-finance166-stock-price.v1';
DECLARE @newBinding nvarchar(200) = N'rapidapi-davethebeast-yahoo-finance166-stock-price.v1-EDITED';
DECLARE @appPk bigint, @capsule binary(32), @oldBytes varbinary(max), @oldText varchar(max),
        @newText varchar(max), @newBytes varbinary(max), @newDigest binary(32), @newCoPk bigint, @appearance binary(32);

BEGIN TRANSACTION;

-- Enable only the two tables this edit touches.
DROP TRIGGER IF EXISTS source.guard_content_object;
DROP TRIGGER IF EXISTS source.guard_source_appearance;

-- 0. Read: the working definition the edit will change.
SELECT '0_READ' AS result_set, c.capability_id, s.scenario_id, i.input_id, e.event_id, o.outcome_id
FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk = ec.capability_pk
JOIN model.capability_version cv ON cv.capability_version_pk = ec.capability_version_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk = cv.capability_version_pk
JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk = cs.scenario_version_pk
LEFT JOIN model.scenario_input i ON i.scenario_version_pk = sv.scenario_version_pk
LEFT JOIN model.scenario_event e ON e.scenario_version_pk = sv.scenario_version_pk
LEFT JOIN model.scenario_outcome o ON o.scenario_version_pk = sv.scenario_version_pk
WHERE ec.estate_model_pk = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1) AND c.capability_id = @CapabilityId;

-- 1. Edit: one substitution in the retained transformation.
SELECT TOP 1 @appPk = a.source_appearance_pk, @capsule = a.capsule_digest, @oldBytes = c.content_bytes
FROM source.source_appearance a JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
WHERE a.source_path = @path AND a.source_class IN ('MANAGED_CAPSULE', 'PROVISIONED_CAPSULE')
ORDER BY a.source_appearance_pk DESC;
IF @appPk IS NULL THROW 51000, 'EQUITY_TRANSFORMATION_NOT_FOUND', 1;
SET @oldText = CONVERT(varchar(max), @oldBytes) COLLATE Latin1_General_100_BIN2_UTF8;
SET @newText = REPLACE(@oldText, @oldBinding, @newBinding);
IF @newText = @oldText THROW 51000, 'EDIT_PATTERN_NOT_FOUND', 1;
SET @newBytes = CONVERT(varbinary(max), @newText COLLATE Latin1_General_100_BIN2_UTF8);
SET @newDigest = HASHBYTES('SHA2_256', @newBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @newDigest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@newDigest, @newBytes, DATALENGTH(@newBytes));
SET @newCoPk = (SELECT content_object_pk FROM source.content_object WHERE content_digest = @newDigest);
SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @newDigest, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
UPDATE source.source_appearance SET content_object_pk = @newCoPk, appearance_digest = @appearance WHERE source_appearance_pk = @appPk;

-- 2. Readback (uncommitted).
SELECT '1_EDIT' AS result_set, @CapabilityId AS capability_id, @oldBinding AS was, @newBinding AS now, LOWER(CONVERT(varchar(64), @newDigest, 2)) AS new_content_digest;

ROLLBACK TRANSACTION;
-- Replace ROLLBACK with COMMIT to keep the edit.
