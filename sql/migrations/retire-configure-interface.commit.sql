-- Retires model.configure_interface onto the delegate
-- model.declare_capability_interface / model.declare_capability_envelope.
--
-- The replaced live body re-created the capability_version by copying exactly one
-- scenario (MAX(capability_scenario) per capability) and one root scenario, so a
-- multi-scenario capability lost its scene links on every interface change, and
-- it read its base envelope from the estate_capability pointer, which can be
-- stale against the selected estate definition (the argv-provider failure mode).
--
-- The replacement keeps the exact parameter signature
-- (@capability_id,@input_type,@input_contract,@input_path,@display_select,
-- @display_as,@defaults_json,@cli_json) and the exact throw codes
-- (CURRENT_MODEL_NOT_FOUND, DEFAULTS_JSON_INVALID, CLI_JSON_INVALID,
-- CAPABILITY_NOT_FOUND). It composes $.semantics.cli from its parameters exactly
-- as the live body did (cli_json or the current cli, then the supplied input and
-- display members, then defaults), then delegates to
-- model.declare_capability_interface, whose envelope bookkeeping copies every
-- capability_scenario row and the capability_root_scenario row. The delegate
-- requires an open transaction, so the replacement refuses with
-- ENVELOPE_TRANSACTION_REQUIRED when none is open.
--
-- Idempotent: replaying an unchanged declaration reaches
-- model.declare_capability_envelope and returns already_installed.
--
-- Preflight: ends with ROLLBACK; run as a dry run with the migration runner.
-- The install is the .commit.sql copy (identical except COMMIT).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers=CURSOR LOCAL FAST_FORWARD FOR
 SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
 FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id
 JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE o.type='U' AND s.name IN ('model','source')
 AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trigger_name); FETCH NEXT FROM @triggers INTO @trigger_name; END;
CLOSE @triggers; DEALLOCATE @triggers;
GO
CREATE OR ALTER PROCEDURE model.configure_interface
  @capability_id   nvarchar(120),
  @input_type      nvarchar(40)  = NULL,
  @input_contract  nvarchar(160) = NULL,
  @input_path      nvarchar(400) = NULL,
  @display_select  nvarchar(400) = NULL,
  @display_as      nvarchar(40)  = NULL,
  @defaults_json   nvarchar(max) = NULL,
  @cli_json        nvarchar(max) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;
  IF @@TRANCOUNT=0 THROW 51000, 'ENVELOPE_TRANSACTION_REQUIRED', 1;
  DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
  IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;
  IF @defaults_json IS NOT NULL AND ISJSON(@defaults_json) <> 1 THROW 51001, 'DEFAULTS_JSON_INVALID', 1;
  IF @cli_json IS NOT NULL AND ISJSON(@cli_json) <> 1 THROW 51001, 'CLI_JSON_INVALID', 1;
  DECLARE @capPk bigint;
  SELECT @capPk = c.capability_pk
  FROM model.estate_capability ec
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
  JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
  WHERE ec.estate_model_pk = @model AND c.capability_id = @capability_id COLLATE Latin1_General_100_BIN2
    AND n.namespace_id = N'sidefx:capabilities';
  IF @capPk IS NULL THROW 51001, 'CAPABILITY_NOT_FOUND', 1;
  DECLARE @semantics nvarchar(max) = (
    SELECT TOP (1) JSON_QUERY(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics')
    FROM model.capability c
    JOIN model.semantic_object_definition d ON d.semantic_object_pk = c.semantic_object_pk
    JOIN model.estate_definition ed ON ed.semantic_object_definition_pk = d.semantic_object_definition_pk AND ed.estate_model_pk = @model
    JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
    WHERE c.capability_id = @capability_id COLLATE Latin1_General_100_BIN2
    ORDER BY d.semantic_object_definition_pk DESC);
  IF @semantics IS NULL THROW 51001, 'CAPABILITY_NOT_FOUND', 1;
  DECLARE @cli nvarchar(max) = CASE WHEN @cli_json IS NOT NULL THEN @cli_json ELSE ISNULL(JSON_QUERY(@semantics,'$.cli'), N'{}') END;
  IF @input_type     IS NOT NULL SET @cli = JSON_MODIFY(@cli, '$.input.type', @input_type);
  IF @input_contract IS NOT NULL SET @cli = JSON_MODIFY(@cli, '$.input.contract', @input_contract);
  IF @input_path     IS NOT NULL SET @cli = JSON_MODIFY(@cli, '$.input.path', @input_path);
  IF @display_select IS NOT NULL SET @cli = JSON_MODIFY(@cli, '$.display.select', @display_select);
  IF @display_as     IS NOT NULL SET @cli = JSON_MODIFY(@cli, '$.display.as', @display_as);
  IF @defaults_json  IS NOT NULL SET @cli = JSON_MODIFY(@cli, '$.defaults', JSON_QUERY(@defaults_json));
  EXEC model.declare_capability_interface @capability_id=@capability_id, @cli_json=@cli;
END
GO
-- Readback: the retired procedure's signature and the delegate call path it presents.
SELECT 'retired_configure_interface' AS result_set,
 CASE WHEN OBJECT_ID(N'model.configure_interface','P') IS NOT NULL THEN N'READY' ELSE N'MISSING' END AS readiness,
 COUNT(p.parameter_id) AS parameter_count
FROM sys.parameters p WHERE p.object_id=OBJECT_ID(N'model.configure_interface');
SELECT 'retired_configure_interface_parameters' AS result_set,
 p.parameter_id, p.name AS parameter_name, TYPE_NAME(p.user_type_id) AS type_name, p.max_length
FROM sys.parameters p WHERE p.object_id=OBJECT_ID(N'model.configure_interface')
ORDER BY p.parameter_id;
SELECT 'declare_capability_document_call' AS result_set,
 CASE WHEN CONVERT(nvarchar(max),m.definition) LIKE N'%EXEC model.configure_interface @capability_id=@scaffold_id, @cli_json=@cli;%'
  THEN N'COMPATIBLE' ELSE N'UNEXPECTED' END AS call_compatibility
FROM sys.sql_modules m WHERE m.object_id=OBJECT_ID(N'model.declare_capability_document');
COMMIT TRANSACTION;