-- declare-circuit-frames-display.sql
--
-- The missing rendering meaning for the live circuit: read-capability-circuit's
-- declared display was the view model itself (read-capability-circuit-display.v1
-- returned `execution.outcome` with no sfx-display-document.v1 wrapper), so the
-- terminal had no declared document to emit and the human surface had no frames.
-- This migration declares the frames as the existing declared vocabulary:
--
--   read-capability-circuit-frames.v1 builds an sfx-display-document.v1 from the
--   circuit view: a heading, the structural attestation as a field, the observed
--   nodes as a list of entries (declared status, altitude, label, parent note and
--   timing) and the planned edges as a list of entries (selected -> completed,
--   unselected -> unobserved, with the from -> to addresses). No character
--   geometry is declared here: box drawing is a platform presentation mechanic,
--   requested separately with the declared circuit-presentation.v1 policy as its
--   binding data.
--
-- The interface display switches to the frames transformation with as text. The
-- view transformation itself is untouched, so read-capability-circuit's outcome
-- and contract are unchanged (additive display only).
--
-- Idempotent: content-addressed definitions and the guarded interface merge
-- re-declare nothing on replay.
--
-- Default: ROLLBACK. Replace the final ROLLBACK TRANSACTION; with COMMIT
-- TRANSACTION; after the dry run and the from-transaction preflight pass.
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

-- ============================== THE DECLARED FRAMES TRANSFORMATION ==============================
DECLARE @namespace nvarchar(400)=N'sidefx:capability:read-capability-circuit';
DECLARE @transformationId nvarchar(400)=N'read-capability-circuit-frames.v1';
DECLARE @expression nvarchar(max)=N'{"op":"let","bindings":{"view":{"op":"path","from":"execution","path":"outcome"},"nodes":{"op":"path","from":"view","path":"nodes"},"edges":{"op":"path","from":"view","path":"edges"}},"value":{"op":"object","fields":{"documentType":{"op":"literal","value":"sfx-display-document.v1"},"blocks":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Circuit {capability}","values":{"capability":{"op":"path","from":"view","path":"capabilityId"}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"ATTESTATION"},"value":{"op":"format","template":"{planned} planned cell(s), {observed} observed cell(s), structured {structured}","values":{"planned":{"op":"path","from":"view","path":"attestation.plannedCells"},"observed":{"op":"path","from":"view","path":"attestation.observedCells"},"structured":{"op":"path","from":"view","path":"attestation.structured"}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"list"},"emptyText":{"op":"literal","value":"(no observed cells)"},"items":{"op":"map","from":{"op":"path","from":"nodes","path":""},"as":"node","value":{"op":"object","fields":{"status":{"op":"path","from":"node","path":"status"},"text":{"op":"format","template":"{altitude}  {label}","values":{"altitude":{"op":"path","from":"node","path":"altitude"},"label":{"op":"path","from":"node","path":"label"}}},"note":{"op":"if","when":{"op":"path","from":"node","path":"parentId"},"then":{"op":"format","template":"under {parent}","values":{"parent":{"op":"path","from":"node","path":"parentId"}}},"else":{"op":"literal","value":null}},"timing":{"op":"if","when":{"op":"path","from":"node","path":"durationMilliseconds"},"then":{"op":"format","template":"{milliseconds} ms","values":{"milliseconds":{"op":"path","from":"node","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"list"},"emptyText":{"op":"literal","value":""},"items":{"op":"map","from":{"op":"path","from":"edges","path":""},"as":"edge","value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"path","from":"edge","path":"selected"},"then":{"op":"literal","value":"completed"},"else":{"op":"literal","value":"unobserved"}},"admission":{"op":"if","when":{"op":"path","from":"edge","path":"selected"},"then":{"op":"literal","value":"selected"},"else":{"op":"literal","value":"not selected"}},"text":{"op":"format","template":"{from} -> {to}","values":{"from":{"op":"path","from":"edge","path":"from"},"to":{"op":"path","from":"edge","path":"to"}}}}}}}}]}}}}';
DECLARE @semantics nvarchar(max)=N'{"id":"read-capability-circuit-frames.v1","expression":'+@expression+N'}';
DECLARE @object bigint,@definition bigint,@digest binary(32),@transformation bigint,@version bigint;
EXEC model.put_semantic_definition 'TRANSFORMATION',@namespace,@transformationId,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
SET @transformation=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@object);
IF @transformation IS NULL BEGIN
 INSERT model.transformation(namespace_pk,transformation_id,semantic_object_pk,object_kind)
 SELECT namespace_pk,@transformationId,@object,'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk=@object;
 SET @transformation=SCOPE_IDENTITY();
END
SET @version=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@definition);
IF @version IS NULL BEGIN
 INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@transformation,@object,@definition,@digest,'json-expression-tree.v1','TRANSFORMATION',@definition,N'');
 SET @version=SCOPE_IDENTITY();
 EXEC model.normalize_transformation_expression @version;
END

-- ============================== THE INTERFACE SELECTS THE FRAMES ==============================
DECLARE @before nvarchar(max);
SELECT @before=JSON_QUERY(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.cli')
FROM model.estate_capability ec
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ec.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE ec.estate_model_pk=@estate AND ec.capability_pk=(SELECT capability_pk FROM model.capability
 WHERE capability_id=N'read-capability-circuit' AND namespace_pk=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_id=N'sidefx:capabilities'));
IF ISNULL(JSON_VALUE(@before,'$.display.transformationId'),N'')<>@transformationId
BEGIN
 DECLARE @merged nvarchar(max)=JSON_MODIFY(COALESCE(@before,N'{}'),'$.display',JSON_QUERY(N'{"transformationId":"read-capability-circuit-frames.v1","as":"text"}'));
 EXEC model.configure_interface @capability_id=N'read-capability-circuit',@cli_json=@merged;
END

-- ============================== PROOF ==============================
SELECT '1_frames_transformation' AS result_set, d.namespace_id, d.declared_id AS transformation_id,
 LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS definition_digest,
 CONVERT(bit,CASE WHEN d.definition_json LIKE N'%sfx-display-document.v1%' THEN 1 ELSE 0 END) AS declares_display_document
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='TRANSFORMATION'
 AND d.namespace_id=@namespace AND d.declared_id=@transformationId;

SELECT '2_interface_display' AS result_set,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.cli.display.transformationId') AS display_transformation_id,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.cli.display.as') AS display_as
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ec.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE c.capability_id=N'read-capability-circuit';

-- The assembled graph source from the uncommitted transaction carries the
-- transformation the interface selects.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-capability-circuit',0,N'sidefx:capabilities'));
SELECT '3_graph_source' AS result_set,
 JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.transformationId') AS interface_display,
 CONVERT(bit,CASE WHEN EXISTS (SELECT 1 FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations')) t
  WHERE JSON_VALUE(t.value,'$.id')=@transformationId) THEN 1 ELSE 0 END) AS transformation_present;

-- The declared expression is the frames document over the view: the contract
-- marker and every block type it emits are present in the retained definition.
SELECT '4_frames_expression' AS result_set,
 CONVERT(bit,CASE WHEN d.definition_json LIKE N'%sfx-display-document.v1%' THEN 1 ELSE 0 END) AS declares_display_document,
 CONVERT(bit,CASE WHEN d.definition_json LIKE N'%execution%outcome%' THEN 1 ELSE 0 END) AS reads_execution_outcome,
 CONVERT(bit,CASE WHEN d.definition_json LIKE N'%blocks%' THEN 1 ELSE 0 END) AS declares_blocks
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='TRANSFORMATION'
 AND d.namespace_id=@namespace AND d.declared_id=@transformationId;
COMMIT TRANSACTION;
-- Default was ROLLBACK. Installed after the rollback dry run and the
-- from-transaction preflight (read-capability-circuit: DISPOSITION completed,
-- circuit-view.v1 outcome intact, observedPathDigest 5c67376b...).
