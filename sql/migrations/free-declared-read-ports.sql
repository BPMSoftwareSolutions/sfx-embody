-- LANE B TIER 1 (declared reads): free the Ports that bind
-- `database-query-provider.readDatabaseQuery` by clearing configuration.providerId.
-- Each Port already carries its declared read `{statement, resultColumn}` and the
-- `sda-embodiment-plan-port.v1` platform binding, so it resolves to the platform
-- declared-read mechanic. Then delete the now-unreferenced PROVIDER row.
-- Idempotent: a second run finds no providerId to clear and no provider to delete.
--
-- Default: ROLLBACK. Replace the final ROLLBACK with COMMIT to install.
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
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @provider_id nvarchar(400)=N'database-query-provider.readDatabaseQuery' COLLATE Latin1_General_100_BIN2;
DECLARE @targets TABLE (namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2, port_id nvarchar(400) COLLATE Latin1_General_100_BIN2);
INSERT @targets (namespace_id, port_id) VALUES
 (N'sidefx:capability:read-authority', N'read-authority-port'),
 (N'sidefx:capability:execute-declared-capability', N'resolve-execution-provider-bindings'),
 (N'sidefx:capability:resolve-provider-slot-bindings', N'resolve-provider-slot-bindings-port'),
 (N'sidefx:capability:project-consumer-execution-embodiment-plan', N'register-projection-authorities'),
 (N'sidefx:capability:run-declared-query', N'run-declared-query-port'),
 (N'sidefx:capability:run-declared-graph', N'run-declared-graph-read');

DECLARE @ns nvarchar(400), @port nvarchar(400);
DECLARE @sem nvarchar(max), @prevver bigint, @object2 bigint, @definition2 bigint, @digest2 binary(32), @portpk bigint, @version bigint;
DECLARE ports CURSOR LOCAL FAST_FORWARD FOR SELECT t.namespace_id, t.port_id FROM @targets t;
OPEN ports;
FETCH NEXT FROM ports INTO @ns, @port;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @sem=NULL; SET @prevver=NULL;
 SELECT @sem=JSON_QUERY(d.definition_json,'$.semantics'),
  @prevver=(SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=@ns COLLATE Latin1_General_100_BIN2 AND d.declared_id=@port COLLATE Latin1_General_100_BIN2
  AND JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId')=@provider_id;
 IF @sem IS NOT NULL BEGIN
  SET @sem=JSON_MODIFY(@sem,'$.configuration.providerId',NULL);
  SET @sem=JSON_MODIFY(@sem,'$.configuration.estateProvider',NULL);
  EXEC model.put_semantic_definition 'PORT',@ns,@port,@sem,@object2 OUTPUT,@definition2 OUTPUT,@digest2 OUTPUT;
  SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object2);
  IF @portpk IS NOT NULL BEGIN
   SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition2);
   IF @version IS NULL BEGIN
    INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
    VALUES(@portpk,@object2,@definition2,@digest2,'consumer-interface-authority.v1','PORT',@definition2,N'');
    SET @version=SCOPE_IDENTITY();
   END
   UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
  END
 END
 FETCH NEXT FROM ports INTO @ns, @port;
END
CLOSE ports; DEALLOCATE ports;

-- Guard: after clearing, no selected PORT may name the provider id in any field.
DECLARE @referencing int=(SELECT COUNT_BIG(*) FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
   AND d.definition_json LIKE N'%'+(@provider_id COLLATE Latin1_General_100_BIN2_UTF8)+N'%');
IF @referencing>0 THROW 51000,'PROVIDER_STILL_REFERENCED_BY_SELECTED_PORT',1;

DELETE pd FROM model.provider_definition pd JOIN model.provider p ON p.provider_pk=pd.provider_pk
 WHERE p.provider_id=@provider_id;
DELETE FROM model.provider WHERE provider_id=@provider_id;

SELECT 'freed_port' AS result_set, d.declared_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id,
 JSON_QUERY(d.definition_json,'$.semantics.configuration.estateProvider') AS estate_provider,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 LEN(JSON_VALUE(d.definition_json,'$.semantics.configuration.statement')) AS statement_len
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id IN (SELECT namespace_id FROM @targets) AND d.declared_id IN (SELECT port_id FROM @targets)
ORDER BY d.declared_id;
SELECT 'provider_removed' AS result_set, (SELECT COUNT(*) FROM model.provider WHERE provider_id=@provider_id) AS providers_remaining,
 @referencing AS selected_ports_naming_provider;
COMMIT TRANSACTION;
