-- change-hello-world-display-heading.sql
--
-- The U1 loop proof (docs/display-projection-migration.md section 6, decision
-- record section 3): change one display fact in rows only and observe the
-- displayed document change with no source edit. This migration changes the
-- declared display transformation's heading template from
--   "Scenario {scenarioId}"  to  "Observed scenario {scenarioId}".
-- Nothing else changes: no capability, scenario, port, contract or interface
-- row is touched, and no file under src/ is edited. Reverted by the next
-- migration so the estate is left on the U1 declaration.
--
-- Idempotent: a second run finds the heading already changed and re-declares
-- nothing.
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
DECLARE @namespace nvarchar(400)=N'sidefx:capability:say-hello-world';
DECLARE @transformationId nvarchar(400)=N'say-hello-world-observe-display.v1';
DECLARE @semantics nvarchar(max);
SELECT @semantics=JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='TRANSFORMATION'
 AND namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND declared_id=@transformationId COLLATE Latin1_General_100_BIN2;
IF @semantics IS NULL THROW 51000,'OBSERVE_DISPLAY_TRANSFORMATION_NOT_DECLARED',1;
DECLARE @heading nvarchar(400)=JSON_VALUE(@semantics,'$.expression.bindings.blocks.from.items[0].fields.text.template');
IF @heading=N'Observed scenario {scenarioId}'
 SELECT '1_heading_change' AS result_set, N'ALREADY_CHANGED' AS action, @heading AS heading_template;
ELSE BEGIN
 SET @semantics=JSON_MODIFY(@semantics,'$.expression.bindings.blocks.from.items[0].fields.text.template',N'Observed scenario {scenarioId}');
 DECLARE @object bigint,@definition bigint,@digest binary(32),@transformation bigint,@version bigint;
 EXEC model.put_semantic_definition 'TRANSFORMATION',@namespace,@transformationId,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 SET @transformation=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@object);
 SET @version=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@definition);
 IF @version IS NULL BEGIN
  INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@transformation,@object,@definition,@digest,'json-expression-tree.v1','TRANSFORMATION',@definition,N'');
  SET @version=SCOPE_IDENTITY();
  EXEC model.normalize_transformation_expression @version;
 END
 SELECT '1_heading_change' AS result_set, N'CHANGED' AS action, @heading AS heading_before,
  JSON_VALUE(@semantics,'$.expression.bindings.blocks.from.items[0].fields.text.template') AS heading_after,
  @version AS transformation_version_pk;
END
-- The assembled graph source from the uncommitted transaction carries the
-- changed expression, not a retained or cached copy.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'say-hello-world',0,N'sidefx:capabilities'));
SELECT '2_graph_source_template' AS result_set,
 JSON_VALUE(t.value,'$.expression.bindings.blocks.from.items[0].fields.text.template') AS heading_template
FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations')) t
WHERE JSON_VALUE(t.value,'$.id')=@transformationId;
COMMIT TRANSACTION;
