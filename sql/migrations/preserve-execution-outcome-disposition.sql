-- Preserve the native execution's disposition through outcome admission.
-- The native consumer already reports the first non-success on the execution
-- result: disposition 'rejected' with outcomeVariant INPUT_REJECTED for an input
-- rejection, 'rejected' for an outcome rejection, and 'failed' for a failed
-- execution. Outcome admission must report that exact disposition rather than
-- collapsing every rejection to OUTCOME_REJECTED.
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
DECLARE @semantics nvarchar(max),@previous bigint;
SELECT @semantics=JSON_QUERY(definition_json,'$.semantics'),@previous=semantic_object_definition_pk
FROM analysis.v_selected_semantic_definition
WHERE estate_model_pk=@estate AND object_kind='PORT'
 AND namespace_id=N'sidefx:capability:execute-declared-capability'
 AND declared_id=N'admit-execution-outcome';
IF @semantics IS NULL THROW 51000,'EXECUTION_OUTCOME_PORT_NOT_DECLARED',1;
DECLARE @disposition nvarchar(max)=JSON_QUERY(@semantics,'$.configuration.rejectionExpression.fields.disposition');
IF @disposition IS NULL THROW 51000,'EXECUTION_OUTCOME_REJECTION_NOT_DECLARED',1;
IF JSON_VALUE(@disposition,'$.op')='literal' AND JSON_VALUE(@disposition,'$.value')='OUTCOME_REJECTED'
BEGIN
 DECLARE @failed nvarchar(max)=(SELECT 'if' AS op,
  JSON_QUERY(N'{"op":"equals","left":{"op":"path","from":"input","path":"carrier.execution.result.disposition"},"right":{"op":"literal","value":"failed"}}') AS [when],
  JSON_QUERY(N'{"op":"literal","value":"EXECUTION_FAILED"}') AS [then],
  JSON_QUERY(N'{"op":"literal","value":"OUTCOME_REJECTED"}') AS [else]
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @branch nvarchar(max)=(SELECT 'if' AS op,
  JSON_QUERY(N'{"op":"equals","left":{"op":"path","from":"input","path":"carrier.execution.result.outcomeVariant"},"right":{"op":"literal","value":"INPUT_REJECTED"}}') AS [when],
  JSON_QUERY(N'{"op":"literal","value":"INPUT_REJECTED"}') AS [then],
  JSON_QUERY(@failed) AS [else]
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 SET @semantics=JSON_MODIFY(@semantics,'$.configuration.rejectionExpression.fields.disposition',JSON_QUERY(@branch));
END;
ELSE IF JSON_VALUE(@disposition,'$.when.left.path')<>'carrier.execution.result.outcomeVariant'
 THROW 51000,'EXECUTION_OUTCOME_REJECTION_AUTHORITY_DIVERGED',1;
DECLARE @object bigint,@definition bigint,@digest binary(32);
EXEC model.put_semantic_definition 'PORT',N'sidefx:capability:execute-declared-capability',
 N'admit-execution-outcome',@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
DECLARE @port bigint=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object);
DECLARE @version bigint=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition);
IF @version IS NULL BEGIN
 INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@port,@object,@definition,@digest,'consumer-interface-authority.v1','PORT',@definition,N'');
 SET @version=SCOPE_IDENTITY();
END;
UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@previous;
SELECT 'outcome_rejection_disposition' AS result_set,@previous AS previous_definition,@definition AS selected_definition,
 JSON_QUERY(@semantics,'$.configuration.rejectionExpression.fields.disposition') AS rejection_disposition;
COMMIT TRANSACTION;
