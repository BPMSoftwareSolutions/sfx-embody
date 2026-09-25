-- Lane 2 of 4: DECLARED MECHANIC for argv (read-argv), attached to the capability.
-- Rollback file: run as a dry run with the migration runner.
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
DECLARE @object bigint,@definition bigint,@digest binary(32);
EXEC model.put_semantic_definition 'MECHANIC',N'sidefx:mechanics',N'read-argv',
 N'{"authorityId":"cell-execution-protocol.v1","mechanic":{"mechanicId":"read-argv","meaning":"Read the process arguments through the declared host boundary.","effectClassification":"observation","inputContractId":"mechanic:read-argv:input.v1","outcomeContractId":"mechanic:read-argv:outcome.v1","sourceProfiles":["platform-effect-provider.v1"],"nativeFloor":true,"authoringForm":{"expressedAs":"semantic-transformation-expression.v1","operation":"read-argv","required":[],"optional":[],"arguments":{},"authoringNote":"Reads the process arguments through the declared host boundary."}}}',
 @object OUTPUT,@definition OUTPUT,@digest OUTPUT;
DECLARE @mechanic bigint=(SELECT mechanic_pk FROM model.mechanic WHERE semantic_object_pk=@object);
IF @mechanic IS NULL BEGIN
 INSERT model.mechanic(namespace_pk,mechanic_id,semantic_object_pk,object_kind)
 SELECT namespace_pk,N'read-argv',@object,'MECHANIC' FROM model.semantic_object WHERE semantic_object_pk=@object;
 SET @mechanic=SCOPE_IDENTITY();
END;
IF NOT EXISTS(SELECT 1 FROM model.mechanic_version WHERE semantic_object_definition_pk=@definition)
 INSERT model.mechanic_version(mechanic_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,mechanic_kind,definition_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@mechanic,@object,@definition,@digest,N'Read the process arguments through the declared host boundary.','observation','cell-execution-protocol.v1','MECHANIC',@definition,N'');
GO
EXEC model.scaffold_capability @capability_id=N'argv-provider', @on_exists=N'REPLACE';
EXEC model.add_mechanic
 @capability_id=N'argv-provider',
 @mechanic_id=N'read-argv',
 @mode=N'REUSE',
 @arguments_json=NULL,
 @output_field=N'arguments',
 @position=NULL;
GO
SELECT 'argv_read_mechanic' AS result_set, m.mechanic_id, mv.mechanic_kind, mv.definition_profile
FROM model.mechanic m JOIN model.mechanic_version mv ON mv.mechanic_pk=m.mechanic_pk
WHERE m.mechanic_id=N'read-argv';
ROLLBACK TRANSACTION;
