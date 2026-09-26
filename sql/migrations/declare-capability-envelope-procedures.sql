-- Standard model.* procedures for repeatable capability envelope, interface and
-- port overlay declarations.
--
--   model.declare_capability_envelope @capability_id,@semantics,@expected_definition_pk
--     Applies one CAPABILITY envelope (model.put_semantic_definition 'CAPABILITY',
--     namespace sidefx:capabilities), then bookkeeps the FK-547-safe way: a new
--     capability_version copying the current version row, every capability_scenario
--     row and the capability_root_scenario row copied to the new version, and the
--     current model's estate_capability row repointed to the new version/definition.
--     The current selection is MAX(semantic_object_definition_pk) over the estate's
--     own estate_definition links, never the possibly-stale estate_capability pointer.
--     Re-applying the selected semantics is a no-op result row (already_installed).
--     Requires an open transaction.
--   model.declare_capability_interface @capability_id,@cli_json,@input_type,
--     @input_contract,@input_path,@display_select,@display_as
--     Reads the selected envelope semantics, sets/replaces $.cli and delegates to
--     model.declare_capability_envelope, so the scenario links and root scenario
--     are preserved by the same bookkeeping.
--   model.declare_port_overlay_rule @namespace_id,@port_id,@mechanic_id,
--     @provider_profile_id,@provider_profile_digest,@implementation_ref
--     Resolves the port from base tables, merges one rule into
--     configuration.overlayBindings (creating the array when absent) and applies
--     the configuration through model.replace_port_configuration. An equivalent
--     rule is already_installed; a different binding for the same mechanic is
--     OVERLAY_RULE_PROFILE_CONFLICT.
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
CREATE OR ALTER PROCEDURE model.declare_capability_envelope
 @capability_id nvarchar(400), @semantics nvarchar(max), @expected_definition_pk bigint=NULL
WITH EXECUTE AS OWNER AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT=0 THROW 51000,'ENVELOPE_TRANSACTION_REQUIRED',1;
 IF @semantics IS NULL OR ISJSON(@semantics)<>1 THROW 51000,'ENVELOPE_SEMANTICS_INVALID',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @capability_pk bigint,@semantic_object_pk bigint,@namespace nvarchar(400),@current_version bigint;
 SELECT @capability_pk=c.capability_pk,@semantic_object_pk=c.semantic_object_pk,@namespace=n.namespace_id,
  @current_version=ec.capability_version_pk
 FROM model.capability c
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
 WHERE c.capability_id=@capability_id COLLATE Latin1_General_100_BIN2;
 IF @capability_pk IS NULL THROW 51000,'CAPABILITY_NOT_FOUND',1;
 DECLARE @selected_definition bigint=(
  SELECT MAX(d.semantic_object_definition_pk) FROM model.semantic_object_definition d
  JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk AND ed.estate_model_pk=@estate
  WHERE d.semantic_object_pk=@semantic_object_pk);
 IF @expected_definition_pk IS NOT NULL AND (@selected_definition IS NULL OR @selected_definition<>@expected_definition_pk)
  THROW 51000,'ENVELOPE_SELECTION_MISMATCH',1;
 DECLARE @object bigint,@definition bigint,@digest binary(32);
 EXEC model.put_semantic_definition 'CAPABILITY',@namespace,@capability_id,@semantics,
  @object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 IF @definition=@selected_definition
 BEGIN
  SELECT N'already_installed' AS action,@capability_pk AS capability_pk,@current_version AS version_pk,
   @definition AS definition_pk,LOWER(CONVERT(varchar(64),@digest,2)) AS digest;
  RETURN;
 END
 DECLARE @new_version bigint=(SELECT capability_version_pk FROM model.capability_version
  WHERE capability_pk=@capability_pk AND semantic_object_definition_pk=@definition);
 IF @new_version IS NULL
 BEGIN
  INSERT model.capability_version(capability_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,
   actor,intent,outcome,experience_id,experience_actor,experience_promise,object_kind,_owner_definition_pk,_canonical_pointer)
  SELECT cv.capability_pk,cv.semantic_object_pk,@definition,@digest,cv.name,
   cv.actor,cv.intent,cv.outcome,cv.experience_id,cv.experience_actor,cv.experience_promise,cv.object_kind,@definition,N''
  FROM model.capability_version cv WHERE cv.capability_version_pk=@current_version;
  SET @new_version=SCOPE_IDENTITY();
 END
 INSERT model.capability_scenario(capability_pk,capability_version_pk,scenario_pk,scenario_version_pk,_owner_definition_pk,_canonical_pointer)
 SELECT cs.capability_pk,@new_version,cs.scenario_pk,cs.scenario_version_pk,@definition,cs._canonical_pointer
 FROM model.capability_scenario cs
 WHERE cs.capability_version_pk=@current_version
  AND NOT EXISTS(SELECT 1 FROM model.capability_scenario x
   WHERE x.capability_version_pk=@new_version AND x.scenario_pk=cs.scenario_pk);
 INSERT model.capability_root_scenario(capability_version_pk,scenario_pk,_owner_definition_pk,_canonical_pointer)
 SELECT @new_version,rs.scenario_pk,@definition,rs._canonical_pointer
 FROM model.capability_root_scenario rs
 WHERE rs.capability_version_pk=@current_version
  AND NOT EXISTS(SELECT 1 FROM model.capability_root_scenario x WHERE x.capability_version_pk=@new_version);
 UPDATE model.estate_capability SET capability_version_pk=@new_version,semantic_object_definition_pk=@definition
 WHERE estate_model_pk=@estate AND capability_pk=@capability_pk;
 SELECT N'capability_envelope_declared' AS action,@capability_pk AS capability_pk,@new_version AS version_pk,
  @definition AS definition_pk,LOWER(CONVERT(varchar(64),@digest,2)) AS digest;
END
GO
CREATE OR ALTER PROCEDURE model.declare_capability_interface
 @capability_id nvarchar(400), @cli_json nvarchar(max)=NULL, @input_type nvarchar(40)=NULL,
 @input_contract nvarchar(160)=NULL, @input_path nvarchar(400)=NULL,
 @display_select nvarchar(400)=NULL, @display_as nvarchar(40)=NULL
WITH EXECUTE AS OWNER AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @semantics nvarchar(max)=(
  SELECT TOP (1) JSON_QUERY(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics')
  FROM model.capability c
  JOIN model.semantic_object_definition d ON d.semantic_object_pk=c.semantic_object_pk
  JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk AND ed.estate_model_pk=@estate
  JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE c.capability_id=@capability_id COLLATE Latin1_General_100_BIN2
  ORDER BY d.semantic_object_definition_pk DESC);
 IF @semantics IS NULL THROW 51000,'CAPABILITY_NOT_FOUND',1;
 DECLARE @cli nvarchar(max);
 IF @cli_json IS NOT NULL
 BEGIN
  IF ISJSON(@cli_json)<>1 OR JSON_QUERY(@cli_json) IS NULL THROW 51000,'CLI_JSON_INVALID',1;
  SET @cli=@cli_json;
 END
 ELSE
 BEGIN
  IF @input_type IS NULL AND @input_contract IS NULL AND @input_path IS NULL
   AND @display_select IS NULL AND @display_as IS NULL
   THROW 51000,'CLI_MEMBERS_REQUIRED',1;
  SET @cli=ISNULL(JSON_QUERY(@semantics,'$.cli'),N'{}');
  IF @input_type IS NOT NULL OR @input_contract IS NOT NULL OR @input_path IS NOT NULL
  BEGIN
   IF JSON_QUERY(@cli,'$.input') IS NULL SET @cli=JSON_MODIFY(@cli,'$.input',JSON_QUERY(N'{}'));
   IF @input_type IS NOT NULL SET @cli=JSON_MODIFY(@cli,'$.input.type',@input_type);
   IF @input_contract IS NOT NULL SET @cli=JSON_MODIFY(@cli,'$.input.contract',@input_contract);
   IF @input_path IS NOT NULL SET @cli=JSON_MODIFY(@cli,'$.input.path',@input_path);
  END
  IF @display_select IS NOT NULL OR @display_as IS NOT NULL
  BEGIN
   IF JSON_QUERY(@cli,'$.display') IS NULL SET @cli=JSON_MODIFY(@cli,'$.display',JSON_QUERY(N'{}'));
   IF @display_select IS NOT NULL SET @cli=JSON_MODIFY(@cli,'$.display.select',@display_select);
   IF @display_as IS NOT NULL SET @cli=JSON_MODIFY(@cli,'$.display.as',@display_as);
  END
 END
 SET @semantics=JSON_MODIFY(@semantics,'$.cli',JSON_QUERY(@cli));
 EXEC model.declare_capability_envelope @capability_id=@capability_id,@semantics=@semantics;
END
GO
CREATE OR ALTER PROCEDURE model.declare_port_overlay_rule
 @namespace_id nvarchar(400), @port_id nvarchar(400), @mechanic_id nvarchar(400),
 @provider_profile_id nvarchar(400), @provider_profile_digest nvarchar(400), @implementation_ref nvarchar(400)
WITH EXECUTE AS OWNER AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT=0 THROW 51000,'ENVELOPE_TRANSACTION_REQUIRED',1;
 IF NULLIF(@namespace_id,N'') IS NULL OR NULLIF(@port_id,N'') IS NULL THROW 51000,'PLACEMENT_PORT_NOT_FOUND',1;
 IF NULLIF(@mechanic_id,N'') IS NULL OR NULLIF(@provider_profile_id,N'') IS NULL
  OR NULLIF(@provider_profile_digest,N'') IS NULL OR NULLIF(@implementation_ref,N'') IS NULL
  THROW 51000,'OVERLAY_RULE_MEMBERS_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @port_pk bigint=(SELECT p.port_pk FROM model.port p
  JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
  WHERE n.namespace_id=@namespace_id COLLATE Latin1_General_100_BIN2 AND p.port_id=@port_id COLLATE Latin1_General_100_BIN2);
 IF @port_pk IS NULL THROW 51000,'PLACEMENT_PORT_NOT_FOUND',1;
 DECLARE @semantic_object_pk bigint=(SELECT semantic_object_pk FROM model.port WHERE port_pk=@port_pk);
 DECLARE @sod bigint,@digest binary(32),@semantics nvarchar(max);
 SELECT TOP (1) @sod=d.semantic_object_definition_pk,@digest=d.definition_digest,
  @semantics=JSON_QUERY(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics')
 FROM model.semantic_object_definition d
 JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk AND ed.estate_model_pk=@estate
 JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE d.semantic_object_pk=@semantic_object_pk
 ORDER BY d.semantic_object_definition_pk DESC;
 IF @sod IS NULL THROW 51000,'PLACEMENT_PORT_NOT_FOUND',1;
 DECLARE @port_version_pk bigint=(SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=@sod);
 DECLARE @bindings nvarchar(max)=ISNULL(JSON_QUERY(@semantics,'$.configuration.overlayBindings'),N'[]');
 IF EXISTS(SELECT 1 FROM OPENJSON(@bindings) b
  WHERE JSON_VALUE(b.value,'$.mechanicId')=@mechanic_id COLLATE Latin1_General_100_BIN2
   AND JSON_VALUE(b.value,'$.providerProfileId')=@provider_profile_id COLLATE Latin1_General_100_BIN2
   AND ISNULL(JSON_VALUE(b.value,'$.providerProfileDigest'),N'')=@provider_profile_digest COLLATE Latin1_General_100_BIN2
   AND ISNULL(JSON_VALUE(b.value,'$.implementationRef'),N'')=@implementation_ref COLLATE Latin1_General_100_BIN2)
 BEGIN
  SELECT N'already_installed' AS action,@namespace_id AS namespace_id,@port_id AS port_id,@mechanic_id AS mechanic_id,
   @provider_profile_id AS provider_profile_id,@port_version_pk AS port_version_pk,@sod AS definition_pk;
  RETURN;
 END
 IF EXISTS(SELECT 1 FROM OPENJSON(@bindings) b
  WHERE JSON_VALUE(b.value,'$.mechanicId')=@mechanic_id COLLATE Latin1_General_100_BIN2)
  THROW 51000,'OVERLAY_RULE_PROFILE_CONFLICT',1;
 DECLARE @merged nvarchar(max)=(
  SELECT mechanicId,providerProfileId,providerProfileDigest,implementationRef
  FROM (
   SELECT JSON_VALUE(b.value,'$.mechanicId') AS mechanicId,
    JSON_VALUE(b.value,'$.providerProfileId') AS providerProfileId,
    JSON_VALUE(b.value,'$.providerProfileDigest') AS providerProfileDigest,
    JSON_VALUE(b.value,'$.implementationRef') AS implementationRef,
    0 AS source_rank,CONVERT(bigint,b.[key]) AS sort_key
   FROM OPENJSON(@bindings) b
   UNION ALL
   SELECT @mechanic_id,@provider_profile_id,@provider_profile_digest,@implementation_ref,1,NULL
  ) combined
  ORDER BY source_rank,sort_key,mechanicId
  FOR JSON PATH);
 DECLARE @configuration nvarchar(max)=ISNULL(JSON_QUERY(@semantics,'$.configuration'),N'{}');
 SET @configuration=JSON_MODIFY(@configuration,'$.overlayBindings',JSON_QUERY(@merged));
 DECLARE @replaced TABLE(result_set nvarchar(100),port_id nvarchar(400));
 INSERT @replaced EXEC model.replace_port_configuration @namespace=@namespace_id,@port=@port_id,@configuration_json=@configuration;
 SELECT TOP (1) @sod=d.semantic_object_definition_pk,@digest=d.definition_digest
 FROM model.semantic_object_definition d
 JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk AND ed.estate_model_pk=@estate
 WHERE d.semantic_object_pk=@semantic_object_pk
 ORDER BY d.semantic_object_definition_pk DESC;
 SET @port_version_pk=(SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=@sod);
 SELECT N'port_overlay_rule_declared' AS action,@namespace_id AS namespace_id,@port_id AS port_id,@mechanic_id AS mechanic_id,
  @provider_profile_id AS provider_profile_id,@port_version_pk AS port_version_pk,@sod AS definition_pk;
END
GO
SELECT 'capability_envelope_procedures' AS result_set,
 CASE WHEN OBJECT_ID(N'model.declare_capability_envelope','P') IS NOT NULL
  AND OBJECT_ID(N'model.declare_capability_interface','P') IS NOT NULL
  AND OBJECT_ID(N'model.declare_port_overlay_rule','P') IS NOT NULL
 THEN N'READY' ELSE N'MISSING' END AS readiness;
ROLLBACK TRANSACTION;
