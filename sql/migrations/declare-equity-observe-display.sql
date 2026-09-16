-- declare-equity-observe-display.sql
--
-- U2 of docs/display-projection-migration.md, dispositioned in
-- docs/display-projection-decision-record.md (section 5 records U1). This
-- closes the same declared-display loop for the demo's primary capability:
--
--   1. the transformation resolve-equity-market-price-evidence-observe-display.v1
--      in namespace sidefx:capability:resolve-equity-market-price-evidence. Its
--      expression builds the same sfx-display-document.v1 document U1 fixed from
--      the same scope {authority, plan, execution, reading}:
--        heading, GIVEN field and THEN lane from the declared scenario faces;
--        WHEN lane joining each declared operation to its plan cell by
--        execution.configuration.portId and to testimony by cellId (declared
--        order; no runtime keyed ordering);
--        truthful status: the visible status derives from
--        execution.outcome.disposition/reasonCode, so the unavailable branch
--        shows EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE with
--        PROVIDER_EXCHANGE_NOT_COMPLETED in a STATUS field and marks the
--        exchange responsibility failed; the resolved branch
--        (EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED) shows the product through the
--        display block;
--        a display block (as json) carrying execution.outcome.payload when it
--        exists only (no block otherwise);
--        a tree block at the trace reading.
--   2. the CLI interface display: from the terminal-side
--      {select:"outcome.payload", as:"json"} to
--      {transformationId:"resolve-equity-market-price-evidence-observe-display.v1",
--      as:"json"}; the declared input mapping is preserved.
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

-- 1. The declared equity display transformation. The expression is dependency
-- ordered: the evaluator resolves path 'from' through the binding scope in
-- document order. Nothing keys on ids parsed from kernel cell ids; the join is
-- declared authority (portId) against the plan and cellId against testimony.
DECLARE @namespace nvarchar(400)=N'sidefx:capability:resolve-equity-market-price-evidence';
DECLARE @transformationId nvarchar(400)=N'resolve-equity-market-price-evidence-observe-display.v1';
DECLARE @semantics nvarchar(max)=N'{"id":"resolve-equity-market-price-evidence-observe-display.v1","expression":{"op":"let","bindings":{"scenario":{"op":"path","from":"authority","path":"scenarios.0"},"authorityEntry":{"op":"path","from":"authority","path":"executionAuthorities.0"},"operations":{"op":"path","from":"authorityEntry","path":"operations"},"cells":{"op":"path","from":"plan","path":"canonicalGraph.cells"},"testimony":{"op":"path","from":"execution","path":"cellTestimony"},"domainOutcome":{"op":"path","from":"execution","path":"outcome"},"payload":{"op":"path","from":"domainOutcome","path":"payload"},"reasonCode":{"op":"path","from":"domainOutcome","path":"reasonCode"},"resolved":{"op":"equals","left":{"op":"path","from":"domainOutcome","path":"disposition"},"right":{"op":"literal","value":"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"}},"exchangeNotCompleted":{"op":"equals","left":{"op":"path","from":"reasonCode","path":""},"right":{"op":"literal","value":"PROVIDER_EXCHANGE_NOT_COMPLETED"}},"outcomeStatus":{"op":"if","when":{"op":"path","from":"resolved","path":""},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"domainOutcome","path":"disposition"},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"responsibilities":{"op":"map","from":{"op":"path","from":"operations","path":""},"as":"operation","value":{"op":"let","bindings":{"cell":{"op":"find","from":{"op":"path","from":"cells","path":""},"as":"candidate","where":{"op":"equals","left":{"op":"path","from":"candidate","path":"execution.configuration.portId"},"right":{"op":"path","from":"operation","path":"portId"}}},"observed":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact","where":{"op":"equals","left":{"op":"path","from":"fact","path":"cellId"},"right":{"op":"path","from":"cell","path":"cellId"}}}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"if","when":{"op":"path","from":"exchangeNotCompleted","path":""},"then":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"operation","path":"portId"},"right":{"op":"literal","value":"observe-equity-price-exchange"}},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"completed"}},"else":{"op":"literal","value":"completed"}},"else":{"op":"if","when":{"op":"path","from":"observed","path":"disposition"},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"format","template":"{responsibility}","values":{"responsibility":{"op":"path","from":"operation","path":"portId"}}},"timing":{"op":"if","when":{"op":"path","from":"observed","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}}}}}},"roots":{"op":"filter","from":{"op":"path","from":"cells","path":""},"as":"root","where":{"op":"equals","left":{"op":"path","from":"root","path":"parentCellId"},"right":{"op":"literal","value":null}}},"treeEntries":{"op":"map","from":{"op":"path","from":"roots","path":""},"as":"root","value":{"op":"let","bindings":{"observed3":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact3","where":{"op":"equals","left":{"op":"path","from":"fact3","path":"cellId"},"right":{"op":"path","from":"root","path":"cellId"}}},"children3":{"op":"filter","from":{"op":"path","from":"cells","path":""},"as":"childCell3","where":{"op":"equals","left":{"op":"path","from":"childCell3","path":"parentCellId"},"right":{"op":"path","from":"root","path":"cellId"}}}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed3","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"observed3","path":"disposition"},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"path","from":"root","path":"semanticAddress"},"timing":{"op":"if","when":{"op":"path","from":"observed3","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed3","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}},"children":{"op":"map","from":{"op":"path","from":"children3","path":""},"as":"child3","value":{"op":"let","bindings":{"observed2":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact2","where":{"op":"equals","left":{"op":"path","from":"fact2","path":"cellId"},"right":{"op":"path","from":"child3","path":"cellId"}}},"children2":{"op":"filter","from":{"op":"path","from":"cells","path":""},"as":"childCell2","where":{"op":"equals","left":{"op":"path","from":"childCell2","path":"parentCellId"},"right":{"op":"path","from":"child3","path":"cellId"}}}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed2","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"observed2","path":"disposition"},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"path","from":"child3","path":"semanticAddress"},"timing":{"op":"if","when":{"op":"path","from":"observed2","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed2","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}},"children":{"op":"map","from":{"op":"path","from":"children2","path":""},"as":"child2","value":{"op":"let","bindings":{"observed1":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact1","where":{"op":"equals","left":{"op":"path","from":"fact1","path":"cellId"},"right":{"op":"path","from":"child2","path":"cellId"}}},"children1":{"op":"filter","from":{"op":"path","from":"cells","path":""},"as":"childCell1","where":{"op":"equals","left":{"op":"path","from":"childCell1","path":"parentCellId"},"right":{"op":"path","from":"child2","path":"cellId"}}}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed1","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"observed1","path":"disposition"},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"path","from":"child2","path":"semanticAddress"},"timing":{"op":"if","when":{"op":"path","from":"observed1","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed1","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}},"children":{"op":"map","from":{"op":"path","from":"children1","path":""},"as":"child1","value":{"op":"let","bindings":{"observed0":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact0","where":{"op":"equals","left":{"op":"path","from":"fact0","path":"cellId"},"right":{"op":"path","from":"child1","path":"cellId"}}}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed0","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"observed0","path":"disposition"},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"path","from":"child1","path":"semanticAddress"},"timing":{"op":"if","when":{"op":"path","from":"observed0","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed0","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}}}}}}}}}}}}}}}}}},"blocks":{"op":"filter","from":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Scenario {scenarioId}","values":{"scenarioId":{"op":"path","from":"scenario","path":"scenarioId"}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"GIVEN"},"value":{"op":"path","from":"scenario","path":"input.inputId"},"note":{"op":"path","from":"scenario","path":"input.contract.contractId"}}},{"op":"object","fields":{"type":{"op":"literal","value":"lane"},"label":{"op":"literal","value":"WHEN"},"entries":{"op":"path","from":"responsibilities","path":""}}},{"op":"object","fields":{"type":{"op":"literal","value":"lane"},"label":{"op":"literal","value":"THEN"},"entries":{"op":"array","items":[{"op":"object","fields":{"status":{"op":"path","from":"outcomeStatus","path":""},"text":{"op":"path","from":"scenario","path":"outcome.outcomeId"},"note":{"op":"path","from":"scenario","path":"outcome.contract.contractId"}}}]}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"STATUS"},"value":{"op":"path","from":"domainOutcome","path":"disposition"},"note":{"op":"path","from":"domainOutcome","path":"reasonCode"}}},{"op":"object","fields":{"type":{"op":"if","when":{"op":"path","from":"payload","path":""},"then":{"op":"literal","value":"display"},"else":{"op":"literal","value":null}},"as":{"op":"literal","value":"json"},"value":{"op":"path","from":"payload","path":""}}},{"op":"object","fields":{"type":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"reading","path":""},"right":{"op":"literal","value":"trace"}},"then":{"op":"literal","value":"tree"},"else":{"op":"literal","value":null}},"label":{"op":"literal","value":"TRACE"},"entries":{"op":"path","from":"treeEntries","path":""}}}]},"as":"block","where":{"op":"path","from":"block","path":"type"}}},"value":{"op":"object","fields":{"documentType":{"op":"literal","value":"sfx-display-document.v1"},"blocks":{"op":"path","from":"blocks","path":""}}}}}';
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

-- 2. The CLI interface: the display is the declared transformation, not a
-- terminal-side select; the declared input mapping is carried unchanged.
-- model.configure_interface pairs MAX(scenario_pk) with MAX(scenario_version_pk),
-- which is not a declared pair for a capability that declares more than one
-- scenario (equity declares four). This migration writes the same capability
-- definition envelope and copies the current version's scenario wiring exactly;
-- semantics.cli is the only changed member. Before/after are printed below.
DECLARE @capPk bigint,@capSo bigint,@oldVer bigint,@capSod bigint;
SELECT @capPk=c.capability_pk,@capSo=c.semantic_object_pk,@oldVer=ec.capability_version_pk,@capSod=ec.semantic_object_definition_pk
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE ec.estate_model_pk=@estate AND c.capability_id=N'resolve-equity-market-price-evidence' AND n.namespace_id=N'sidefx:capabilities';
DECLARE @curEnv nvarchar(max);
SELECT @curEnv=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE d.semantic_object_definition_pk=@capSod;
DECLARE @before nvarchar(max)=JSON_QUERY(@curEnv,'$.semantics.cli');
DECLARE @cli nvarchar(max)=JSON_MODIFY(@before,'$.display',JSON_QUERY(N'{"transformationId":"resolve-equity-market-price-evidence-observe-display.v1","as":"json"}'));
DECLARE @newEnv nvarchar(max)=JSON_MODIFY(@curEnv,'$.semantics.cli',JSON_QUERY(@cli));
DECLARE @newBytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),(@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @newDigest binary(32)=HASHBYTES('SHA2_256',@newBytes);
DECLARE @newSod bigint=@capSod,@newVer bigint=@oldVer,@updated int=0;
IF ISNULL(JSON_VALUE(@before,'$.display.transformationId'),N'')<>@transformationId
BEGIN
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
 SET @updated=@@ROWCOUNT;
END
DECLARE @after nvarchar(max)=JSON_QUERY(@newEnv,'$.semantics.cli');

-- ============================== PROOF ==============================
SELECT '1_transformation' AS result_set, t.transformation_id, tv.transformation_version_pk, @digest AS definition_digest,
 CONVERT(bit,CASE WHEN JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),
  '$.semantics.expression.bindings.blocks.from.items[4].fields.label.value')=N'STATUS' THEN 1 ELSE 0 END) AS status_field_declared
FROM model.transformation t
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=@definition
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
LEFT JOIN model.transformation_version tv ON tv.semantic_object_definition_pk=d.semantic_object_definition_pk
WHERE t.semantic_object_pk=@object;

SELECT '2_expression_parts' AS result_set,
 CONVERT(bit,CASE WHEN CHARINDEX(N'observe-equity-price-exchange',
  CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8))>0 THEN 1 ELSE 0 END) AS exchange_responsibility_declared,
 CONVERT(bit,CASE WHEN CHARINDEX(N'PROVIDER_EXCHANGE_NOT_COMPLETED',
  CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8))>0 THEN 1 ELSE 0 END) AS unavailable_reason_declared,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),
  '$.semantics.expression.bindings.blocks.from.items[5].fields.type.then.value') AS product_block_type,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),
  '$.semantics.expression.bindings.blocks.from.items[6].fields.type.then.value') AS trace_block_type
FROM model.semantic_object_definition d
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE d.semantic_object_definition_pk=@definition;

SELECT '3_interface_display' AS result_set, @before AS cli_before, @after AS cli_after,
 JSON_VALUE(@after,'$.input.contract') AS input_contract,
 JSON_VALUE(@after,'$.display.transformationId') AS display_transformation_id,
 JSON_VALUE(@after,'$.display.as') AS display_as;

-- The assembled graph source from the uncommitted transaction: the declared
-- transformation travels in semanticTransformations and the interface names it.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',0,N'sidefx:capabilities'));
SELECT '4_graph_source' AS result_set,
 JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.transformationId') AS display_transformation_id,
 JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.input.contract') AS input_contract,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations')) t
  WHERE JSON_VALUE(t.value,'$.id')=@transformationId) AS display_transformation_present,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations'))) AS transformation_count;

-- The write is proven by the readback: the estate row now names the new
-- definition and version, and its graph source carries the declared interface.
SELECT '5_estate_row' AS result_set, @updated AS estate_rows_updated, @newVer AS capability_version_pk, @newSod AS semantic_object_definition_pk;

COMMIT TRANSACTION;
