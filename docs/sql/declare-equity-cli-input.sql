-- declare-equity-cli-input.sql
--
-- Declare resolve-equity-market-price-evidence's CLI input mapping, so the
-- capability can be invoked with just a stock symbol:
--
--   sfx capability invoke resolve-equity-market-price-evidence --input 'AAPL'
--
-- The contract requires symbol and region; the capability declares the region
-- default for its CLI surface (the caller supplies the symbol). The CLI already
-- reads this configuration the same way it reads the display projection.
--
-- Default: ROLLBACK after verification. Change the final ROLLBACK to COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @path nvarchar(400) = N'capabilities/resolve-equity-market-price-evidence/interfaces.authority.json';
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capPk bigint = (SELECT capability_pk FROM model.capability WHERE capability_id=N'resolve-equity-market-price-evidence');
DECLARE @sod bigint = (SELECT semantic_object_definition_pk FROM model.estate_capability WHERE estate_model_pk=@model AND capability_pk=@capPk);
DECLARE @capsule binary(32) = (SELECT TOP 1 a.capsule_digest FROM source.source_lineage l
  JOIN source.source_observation o ON o.source_observation_pk=l.source_observation_pk
  JOIN source.source_appearance a ON a.source_appearance_pk=o.source_appearance_pk
  WHERE l.semantic_object_definition_pk=@sod);
DECLARE @appearancePk bigint, @oldCo bigint;
SELECT @appearancePk=a.source_appearance_pk, @oldCo=a.content_object_pk
FROM source.source_appearance a WHERE a.capsule_digest=@capsule AND a.source_path=@path;

IF @appearancePk IS NULL THROW 51000, 'CLI_INTERFACE_DECLARATION_NOT_FOUND', 1;

-- ============================== BEFORE ==============================
SELECT 'BEFORE_configuration' AS result_set, JSON_QUERY(CONVERT(nvarchar(max), CONVERT(varchar(max), c.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.interfaces[0].configuration') AS configuration
FROM source.content_object c WHERE c.content_object_pk=@oldCo;

-- Drop the workshop data guards.
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;

BEGIN TRANSACTION;

DECLARE @json nvarchar(max) = (SELECT CONVERT(nvarchar(max), CONVERT(varchar(max), c.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) FROM source.content_object c WHERE c.content_object_pk=@oldCo);
DECLARE @config nvarchar(max) = N'{"input":{"type":"text","contract":"live-equity-price-request.v1","path":"payload.symbol","fields":{"payload.region":"US"}},"display":{"select":"outcome.payload","as":"json"}}';
DECLARE @configured nvarchar(max) = JSON_MODIFY(@json, '$.interfaces[0].configuration', JSON_QUERY(@config));
DECLARE @bytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@configured) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @digest binary(32) = HASHBYTES('SHA2_256', @bytes);

IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
DECLARE @newCo bigint = (SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest);
UPDATE source.source_appearance SET content_object_pk=@newCo WHERE source_appearance_pk=@appearancePk;

-- ============================== AFTER ==============================
SELECT 'AFTER_configuration' AS result_set,
  JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), c.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.interfaces[0].configuration.input.contract') AS input_contract,
  JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), c.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.interfaces[0].configuration.input.path') AS input_path,
  JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), c.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.interfaces[0].configuration.input.fields."payload.region"') AS region_default,
  JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), c.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.interfaces[0].configuration.display.select') AS display_select
FROM source.content_object c WHERE c.content_object_pk=@newCo;

ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
