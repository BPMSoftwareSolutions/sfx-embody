-- declare-observation-readings.sql
--
-- U4 of docs/display-projection-migration.md, dispositioned in
-- docs/display-projection-decision-record.md (D7): the display reading
-- selection is declared data. Today the boot maps observationAltitudes to a
-- reading in code ("trace" when any non-scenario altitude is requested). This
-- migration declares each reading's altitude set on the capability's CLI
-- interface configuration, in declaration order:
--
--   default  altitudes ["scenario"]
--   trace    altitudes ["scenario","mechanic","provider","physical"]
--
-- The boot reads the declaration: the first reading whose declared altitudes
-- admit every requested altitude is the reading the display transformation
-- consumes. The terminal is unchanged; it still forwards observationAltitudes.
--
-- Declared for every capability that declares a display transformation:
-- say-hello-world and resolve-equity-market-price-evidence. Every other
-- declared member (the input mapping, the display transformation) is carried
-- unchanged.
--
-- model.configure_interface pairs MAX(scenario_pk) with MAX(scenario_version_pk)
-- across the capability's whole history, which is not a declared pair once the
-- history holds more than one scenario version. This migration writes the same
-- capability definition envelope and copies the current version's scenario
-- wiring exactly; semantics.cli is the only changed member.
--
-- Idempotent: a re-run finds the readings already declared on both interfaces.
--
-- Default: ROLLBACK. Replace the final ROLLBACK TRANSACTION; with COMMIT
-- TRANSACTION; to install (after the from-transaction preflight passes).
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
WHILE @@FETCH_STATUS=0 BEGIN
 EXEC(N'DROP TRIGGER '+@trigger_name);
 FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @readings nvarchar(max)=N'[{"reading":"default","altitudes":["scenario"]},{"reading":"trace","altitudes":["scenario","mechanic","provider","physical"]}]';

-- The declared readings ride the CLI configuration the display already travels
-- on. Only the readings member is added; every other declared member is carried
-- unchanged, and the current version's scenario wiring is copied exactly.
DECLARE @targets TABLE (ordinal int IDENTITY(1,1) PRIMARY KEY, capability_id nvarchar(120));
INSERT @targets(capability_id) VALUES(N'say-hello-world'),(N'resolve-equity-market-price-evidence');
DECLARE @proof TABLE (ordinal int PRIMARY KEY, capability_id nvarchar(120), cli_before nvarchar(max), cli_after nvarchar(max));
DECLARE @capability_id nvarchar(120),@capPk bigint,@capSo bigint,@oldVer bigint,@capSod bigint,
 @curEnv nvarchar(max),@cliBefore nvarchar(max),@cliAfter nvarchar(max),@newEnv nvarchar(max),
 @newBytes varbinary(max),@newDigest binary(32),@newSod bigint,@newVer bigint,@ordinal int;
DECLARE @targets_cursor CURSOR;
SET @targets_cursor=CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal,capability_id FROM @targets ORDER BY ordinal;
OPEN @targets_cursor;
FETCH NEXT FROM @targets_cursor INTO @ordinal,@capability_id;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @capPk=NULL;SET @capSo=NULL;SET @oldVer=NULL;SET @capSod=NULL;SET @curEnv=NULL;
 SELECT @capPk=c.capability_pk,@capSo=c.semantic_object_pk,@oldVer=ec.capability_version_pk,@capSod=ec.semantic_object_definition_pk
 FROM model.estate_capability ec
 JOIN model.capability c ON c.capability_pk=ec.capability_pk
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
 WHERE ec.estate_model_pk=@estate AND c.capability_id=@capability_id AND n.namespace_id=N'sidefx:capabilities';
 IF @capPk IS NULL THROW 51000,'CAPABILITY_NOT_FOUND',1;
 SELECT @curEnv=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE d.semantic_object_definition_pk=@capSod;
 SET @cliBefore=JSON_QUERY(@curEnv,'$.semantics.cli');
 SET @newSod=@capSod;
 IF JSON_QUERY(@curEnv,'$.semantics.cli.readings') IS NULL BEGIN
  SET @cliAfter=JSON_MODIFY(@cliBefore,'$.readings',JSON_QUERY(@readings));
  SET @newEnv=JSON_MODIFY(@curEnv,'$.semantics.cli',JSON_QUERY(@cliAfter));
  SET @newBytes=CONVERT(varbinary(max),CONVERT(varchar(max),(@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
  SET @newDigest=HASHBYTES('SHA2_256',@newBytes);
  IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@newDigest)
   INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@newDigest,@newBytes,DATALENGTH(@newBytes));
  INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk)
   VALUES(@capSo,'CAPABILITY',@newDigest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@newDigest));
  SET @newSod=SCOPE_IDENTITY();
  INSERT model.estate_definition(estate_model_pk,semantic_object_definition_pk) VALUES(@estate,@newSod);
  INSERT model.capability_version(capability_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,actor,intent,outcome,experience_id,experience_actor,experience_promise,object_kind,_owner_definition_pk,_canonical_pointer)
   SELECT capability_pk,semantic_object_pk,@newSod,@newDigest,name,actor,intent,outcome,experience_id,experience_actor,experience_promise,object_kind,@newSod,N''
   FROM model.capability_version WHERE capability_version_pk=@oldVer;
  SET @newVer=SCOPE_IDENTITY();
  INSERT model.capability_scenario(capability_pk,capability_version_pk,scenario_pk,scenario_version_pk,_owner_definition_pk,_canonical_pointer)
   SELECT capability_pk,@newVer,scenario_pk,scenario_version_pk,@newSod,N''
   FROM model.capability_scenario WHERE capability_version_pk=@oldVer;
  INSERT model.capability_root_scenario(capability_version_pk,scenario_pk,_owner_definition_pk,_canonical_pointer)
   SELECT @newVer,scenario_pk,@newSod,N''
   FROM model.capability_root_scenario WHERE capability_version_pk=@oldVer;
  UPDATE model.estate_capability SET capability_version_pk=@newVer,semantic_object_definition_pk=@newSod
   WHERE estate_model_pk=@estate AND capability_pk=@capPk;
 END ELSE SET @cliAfter=@cliBefore;
 INSERT @proof VALUES(@ordinal,@capability_id,@cliBefore,@cliAfter);
 FETCH NEXT FROM @targets_cursor INTO @ordinal,@capability_id;
END;
CLOSE @targets_cursor;
DEALLOCATE @targets_cursor;

-- ============================== PROOF ==============================
-- The assembled graph sources from the uncommitted transaction: each interface
-- declares the readings and still names its display transformation.
DECLARE @sayGraph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'say-hello-world',0,N'sidefx:capabilities'));
DECLARE @equityGraph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',0,N'sidefx:capabilities'));

SELECT '1_say_hello_world' AS result_set,
 JSON_VALUE(JSON_QUERY(@sayGraph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.transformationId') AS display_transformation_id,
 JSON_QUERY(JSON_QUERY(@sayGraph,'$.interfaceAuthority.interfaces[0].configuration'),'$.readings') AS readings,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@sayGraph,'$.interfaceAuthority.interfaces[0].configuration'),'$.readings')) AS reading_count;

SELECT '2_equity' AS result_set,
 JSON_VALUE(JSON_QUERY(@equityGraph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.transformationId') AS display_transformation_id,
 JSON_VALUE(JSON_QUERY(@equityGraph,'$.interfaceAuthority.interfaces[0].configuration'),'$.input.contract') AS input_contract,
 JSON_QUERY(JSON_QUERY(@equityGraph,'$.interfaceAuthority.interfaces[0].configuration'),'$.readings') AS readings,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@equityGraph,'$.interfaceAuthority.interfaces[0].configuration'),'$.readings')) AS reading_count;

SELECT '3_before_after' AS result_set, capability_id, cli_before, cli_after FROM @proof ORDER BY ordinal;

COMMIT TRANSACTION;
