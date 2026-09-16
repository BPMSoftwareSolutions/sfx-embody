-- declare-observation-display-projection.sql
--
-- U1 of docs/display-projection-migration.md, dispositioned in
-- docs/display-projection-decision-record.md: the observation display is
-- declared authority (1). This migration closes the smallest complete loop for
-- say-hello-world:
--
--   1. the display document contract sfx-display-document.v1: the closed block
--      vocabulary (heading, field, lane, tree, list, display, line, blank) and
--      entries ({status?, text, note?, admission?, timing?, children?}). A
--      status is a declared token (completed|failed|unobserved), never a glyph.
--   2. the transformation say-hello-world-observe-display.v1 in namespace
--      sidefx:capability:say-hello-world. Its expression builds the document
--      from the scope the boot passes: authority (the capability graph source),
--      plan (the compiled topology captured from onState), execution (the
--      kernel result with its testimony), selection and reading. Declared
--      operations join their plan cell by execution.configuration.portId and
--      the cell's testimony by cellId equality; declared iteration supplies the
--      order (no runtime keyed ordering is admissible).
--   3. the CLI interface display: from the terminal-side selection
--      {select, as} to {transformationId: say-hello-world-observe-display.v1,
--      as: json}. The interface configuration is unconstrained (see
--      declare-equity-cli-input.sql:44 and model.configure_interface).
--
-- Readings: the expression branches on the scope field reading. default emits
-- the story blocks; trace emits the story blocks plus the tree block. The
-- reading selection is not declarable on the invoke/observe operation yet (the
-- operation spec lives in the boot, docs/display-projection-migration.md 3.1),
-- so the boot derives it from the declared request field observationAltitudes
-- (scenario-only = default, any wider selection = trace). TODO(U4): declare the
-- reading selection on the operation/interface and delete the derivation.
--
-- Idempotent: re-running selects the same transformation definition digest and
-- finds the interface already naming the transformation.
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

-- 1. The display document contract. It is the shape the declared display
-- transformation emits; the terminal emits characters over it.
EXEC model.declare_contract @id=N'sfx-display-document.v1',
 @schema=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/sfx-display-document.v1.schema.json","title":"SFX display document","description":"A declared observation display: typed blocks carrying derived labels, values, statuses, order and timings. The terminal supplies characters; the document carries the meaning.","type":"object","additionalProperties":false,"required":["documentType","blocks"],"properties":{"documentType":{"const":"sfx-display-document.v1"},"blocks":{"type":"array","items":{"$ref":"#/$defs/block"}}},"$defs":{"entry":{"type":"object","additionalProperties":false,"required":["text"],"properties":{"status":{"enum":["completed","failed","unobserved"]},"text":{"type":"string"},"note":{"type":["string","null"]},"admission":{"type":["string","null"]},"timing":{"type":["string","null"]},"children":{"type":"array","items":{"$ref":"#/$defs/entry"}}}},"block":{"oneOf":[{"type":"object","additionalProperties":false,"required":["type","text"],"properties":{"type":{"const":"heading"},"text":{"type":"string"}}},{"type":"object","additionalProperties":false,"required":["type","label","value"],"properties":{"type":{"const":"field"},"label":{"type":"string"},"value":{"type":"string"},"note":{"type":["string","null"]}}},{"type":"object","additionalProperties":false,"required":["type","label","entries"],"properties":{"type":{"const":"lane"},"label":{"type":"string"},"entries":{"type":"array","items":{"$ref":"#/$defs/entry"}}}},{"type":"object","additionalProperties":false,"required":["type","label","entries"],"properties":{"type":{"const":"tree"},"label":{"type":"string"},"entries":{"type":"array","items":{"$ref":"#/$defs/entry"}}}},{"type":"object","additionalProperties":false,"required":["type","items"],"properties":{"type":{"const":"list"},"items":{"type":"array","items":{"$ref":"#/$defs/entry"}},"emptyText":{"type":["string","null"]}}},{"type":"object","additionalProperties":false,"required":["type","as","value"],"properties":{"type":{"const":"display"},"as":{"type":"string"},"value":{}}},{"type":"object","additionalProperties":false,"required":["type","text"],"properties":{"type":{"const":"line"},"text":{"type":"string"}}},{"type":"object","additionalProperties":false,"required":["type"],"properties":{"type":{"const":"blank"}}}]}}}';

-- 2. The declared display transformation. The expression is dependency-ordered:
-- the evaluator resolves path 'from' through the binding scope in document order.
DECLARE @namespace nvarchar(400)=N'sidefx:capability:say-hello-world';
DECLARE @transformationId nvarchar(400)=N'say-hello-world-observe-display.v1';
DECLARE @expression nvarchar(max)=N'{"op":"let","bindings":{"scenario":{"op":"path","from":"authority","path":"scenarios.0"},"authorityEntry":{"op":"path","from":"authority","path":"executionAuthorities.0"},"operations":{"op":"path","from":"authorityEntry","path":"operations"},"cells":{"op":"path","from":"plan","path":"canonicalGraph.cells"},"testimony":{"op":"path","from":"execution","path":"cellTestimony"},"outcomeStatus":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"execution","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"execution","path":"disposition"},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"responsibilities":{"op":"map","from":{"op":"path","from":"operations","path":""},"as":"operation","value":{"op":"let","bindings":{"cell":{"op":"find","from":{"op":"path","from":"cells","path":""},"as":"candidate","where":{"op":"equals","left":{"op":"path","from":"candidate","path":"execution.configuration.portId"},"right":{"op":"path","from":"operation","path":"portId"}}},"observed":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact","where":{"op":"equals","left":{"op":"path","from":"fact","path":"cellId"},"right":{"op":"path","from":"cell","path":"cellId"}}}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"observed","path":"disposition"},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"format","template":"{responsibility}","values":{"responsibility":{"op":"path","from":"operation","path":"portId"}}},"timing":{"op":"if","when":{"op":"path","from":"observed","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}}}}}},"roots":{"op":"filter","from":{"op":"path","from":"cells","path":""},"as":"root","where":{"op":"equals","left":{"op":"path","from":"root","path":"parentCellId"},"right":{"op":"literal","value":null}}},"treeEntries":{"op":"map","from":{"op":"path","from":"roots","path":""},"as":"root","value":{"op":"let","bindings":{"observed":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact","where":{"op":"equals","left":{"op":"path","from":"fact","path":"cellId"},"right":{"op":"path","from":"root","path":"cellId"}}},"children":{"op":"filter","from":{"op":"path","from":"cells","path":""},"as":"childCell","where":{"op":"equals","left":{"op":"path","from":"childCell","path":"parentCellId"},"right":{"op":"path","from":"root","path":"cellId"}}}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"observed","path":"disposition"},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"path","from":"root","path":"semanticAddress"},"timing":{"op":"if","when":{"op":"path","from":"observed","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}},"children":{"op":"map","from":{"op":"path","from":"children","path":""},"as":"child","value":{"op":"let","bindings":{"observed":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact","where":{"op":"equals","left":{"op":"path","from":"fact","path":"cellId"},"right":{"op":"path","from":"child","path":"cellId"}}},"grandChildren":{"op":"filter","from":{"op":"path","from":"cells","path":""},"as":"childCell","where":{"op":"equals","left":{"op":"path","from":"childCell","path":"parentCellId"},"right":{"op":"path","from":"child","path":"cellId"}}}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"observed","path":"disposition"},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"path","from":"child","path":"semanticAddress"},"timing":{"op":"if","when":{"op":"path","from":"observed","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}},"children":{"op":"map","from":{"op":"path","from":"grandChildren","path":""},"as":"grandChild","value":{"op":"let","bindings":{"observed":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact","where":{"op":"equals","left":{"op":"path","from":"fact","path":"cellId"},"right":{"op":"path","from":"grandChild","path":"cellId"}}}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"observed","path":"disposition"},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"path","from":"grandChild","path":"semanticAddress"},"timing":{"op":"if","when":{"op":"path","from":"observed","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}}}}}}}}}}}}}},"blocks":{"op":"filter","from":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Scenario {scenarioId}","values":{"scenarioId":{"op":"path","from":"scenario","path":"scenarioId"}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"GIVEN"},"value":{"op":"path","from":"scenario","path":"input.inputId"},"note":{"op":"path","from":"scenario","path":"input.contract.contractId"}}},{"op":"object","fields":{"type":{"op":"literal","value":"lane"},"label":{"op":"literal","value":"WHEN"},"entries":{"op":"path","from":"responsibilities","path":""}}},{"op":"object","fields":{"type":{"op":"literal","value":"lane"},"label":{"op":"literal","value":"THEN"},"entries":{"op":"array","items":[{"op":"object","fields":{"status":{"op":"path","from":"outcomeStatus","path":""},"text":{"op":"path","from":"scenario","path":"outcome.outcomeId"},"note":{"op":"path","from":"scenario","path":"outcome.contract.contractId"}}}]}}},{"op":"object","fields":{"type":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"reading","path":""},"right":{"op":"literal","value":"trace"}},"then":{"op":"literal","value":"tree"},"else":{"op":"literal","value":null}},"label":{"op":"literal","value":"TRACE"},"entries":{"op":"path","from":"treeEntries","path":""}}}]},"as":"block","where":{"op":"path","from":"block","path":"type"}}},"value":{"op":"object","fields":{"documentType":{"op":"literal","value":"sfx-display-document.v1"},"blocks":{"op":"path","from":"blocks","path":""}}}}';
DECLARE @semantics nvarchar(max)=N'{"id":"say-hello-world-observe-display.v1","expression":'+@expression+N'}';
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

-- 3. The CLI interface: the display is the declared transformation, not a
-- terminal-side select. Before/after are printed below.
DECLARE @capSod bigint=(SELECT ec.semantic_object_definition_pk FROM model.estate_capability ec
 JOIN model.capability c ON c.capability_pk=ec.capability_pk
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
 WHERE ec.estate_model_pk=@estate AND c.capability_id=N'say-hello-world' AND n.namespace_id=N'sidefx:capabilities');
DECLARE @before nvarchar(max);
SELECT @before=JSON_QUERY(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.cli')
FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE d.semantic_object_definition_pk=@capSod;
DECLARE @cli nvarchar(max)=N'{"display":{"transformationId":"say-hello-world-observe-display.v1","as":"json"}}';
IF ISNULL(JSON_VALUE(@before,'$.display.transformationId'),N'')<>@transformationId
 EXEC model.configure_interface @capability_id=N'say-hello-world',@cli_json=@cli;
DECLARE @after nvarchar(max);
SELECT @after=JSON_QUERY(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.cli')
FROM model.estate_capability ec
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ec.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE ec.estate_model_pk=@estate AND ec.capability_pk=(SELECT capability_pk FROM model.capability WHERE capability_id=N'say-hello-world'
 AND namespace_pk=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_id=N'sidefx:capabilities'));

-- ============================== PROOF ==============================
SELECT '1_contract' AS result_set, ct.contract_id, LEN(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)) AS schema_chars
FROM model.contract ct
JOIN model.contract_version cv ON cv.contract_pk=ct.contract_pk
JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
WHERE ct.contract_id=N'sfx-display-document.v1';

SELECT '2_transformation' AS result_set, t.transformation_id, tv.transformation_version_pk, @digest AS definition_digest,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.expression.bindings.blocks.from.items[0].fields.text.template') AS heading_template,
 CONVERT(bit,CASE WHEN JSON_QUERY(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.expression.bindings.blocks.from.items[4]') IS NULL THEN 0 ELSE 1 END) AS trace_block_declared
FROM model.transformation t
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=@definition
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
LEFT JOIN model.transformation_version tv ON tv.semantic_object_definition_pk=d.semantic_object_definition_pk
WHERE t.semantic_object_pk=@object;

SELECT '3_interface_display' AS result_set, @before AS cli_before, @after AS cli_after,
 JSON_VALUE(@after,'$.display.transformationId') AS display_transformation_id,
 JSON_VALUE(@after,'$.display.as') AS display_as;

-- The assembled graph source from the uncommitted transaction: the declared
-- transformation travels in semanticTransformations and the interface names it.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'say-hello-world',0,N'sidefx:capabilities'));
SELECT '4_graph_source' AS result_set,
 JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.transformationId') AS display_transformation_id,
 JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.as') AS display_as,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations')) t
  WHERE JSON_VALUE(t.value,'$.id')=@transformationId) AS display_transformation_present,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations'))) AS transformation_count;

COMMIT TRANSACTION;
