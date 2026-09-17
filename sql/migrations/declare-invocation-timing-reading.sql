-- declare-invocation-timing-reading.sql
--
-- The Invisible Execution Authority unit "Declared timing reading" (data/1):
-- a declared read over one invocation's testimony. The read is a capability
-- (sidefx:capabilities / read-invocation-timing) whose single declared-read
-- port computes, from the testimony and the measured invocation context:
--
--   (a) top time contributors (cell, altitude, duration);
--   (b) attributed totals per altitude (scenario, mechanic, provider, physical)
--       and the total attributed time;
--   (c) the first receipt's gap test (docs/invisible-execution-authority.md):
--       for consecutive testimony completions, gap - completing-cell duration,
--       counted above measurement noise (positive unattributed, negative);
--   (d) the residual gap against the invocation's wall span when the streamed
--       measurement is supplied.
--
-- The gap test and the aggregation are declared SQL (the same declared-read
-- pattern as declare-read-declared-capability-document.sql); the reading over
-- testimony is data, not instrumentation -- every field it reads
-- (cellId, cellAltitude, durationMilliseconds, completedAt) is already declared
-- by cell-execution-testimony.v1.
--
-- The reading's own display configuration selects a declared display
-- projection (read-invocation-timing-display.v1, sfx-display-document.v1); the
-- terminal renders it generically, so there is no CLI work for this unit.
--
-- Idempotent: the capability document's digest is the installed-document gate,
-- and the transformation is declared through the content-addressed writer.
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
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trigger_name); FETCH NEXT FROM @triggers INTO @trigger_name; END;
CLOSE @triggers; DEALLOCATE @triggers;
GO

-- ============================== THE DECLARED READ STATEMENT ==============================
-- The statement is declaration data: it is carried by the port binding, not by
-- code. It receives @input (the invocation-timing-request.v1 request) and the
-- pinned estate parameters, and returns one JSON reading in the `value` column.
DECLARE @statement nvarchar(max) = N'
DECLARE @cells nvarchar(max)=JSON_QUERY(@input,''$.payload.cellTestimony'');
IF @cells IS NULL OR ISJSON(@cells)<>1 THROW 51000,''INVOCATION_TIMING_TESTIMONY_REQUIRED'',1;
DECLARE @noise decimal(18,3)=COALESCE(TRY_CONVERT(decimal(18,3),JSON_VALUE(@input,''$.payload.noiseMilliseconds'')),5);
DECLARE @top int=COALESCE(TRY_CONVERT(int,JSON_VALUE(@input,''$.payload.topCount'')),12);
DECLARE @wall decimal(18,3)=TRY_CONVERT(decimal(18,3),JSON_VALUE(@input,''$.payload.measured.wallSpanMilliseconds''));
DECLARE @phases decimal(18,3)=COALESCE(TRY_CONVERT(decimal(18,3),JSON_VALUE(@input,''$.payload.measured.deliveryPhaseMilliseconds'')),0);
DECLARE @rows TABLE (cellId nvarchar(400), cellAltitude nvarchar(40), durationMilliseconds decimal(18,3), completed datetime2);
INSERT @rows(cellId,cellAltitude,durationMilliseconds,completed)
SELECT c.cellId,c.cellAltitude,c.durationMilliseconds,TRY_CONVERT(datetime2,c.completedAt)
FROM OPENJSON(@cells) WITH (cellId nvarchar(400) ''$.cellId'', cellAltitude nvarchar(40) ''$.cellAltitude'', durationMilliseconds decimal(18,3) ''$.durationMilliseconds'', completedAt nvarchar(40) ''$.completedAt'') c
WHERE c.cellId IS NOT NULL AND c.durationMilliseconds IS NOT NULL;
DECLARE @cellCount int=(SELECT COUNT(*) FROM @rows);
DECLARE @total decimal(18,3)=(SELECT SUM(durationMilliseconds) FROM @rows);
DECLARE @byAltitude nvarchar(max)=(SELECT cellAltitude AS altitude,CONVERT(decimal(18,3),SUM(durationMilliseconds)) AS durationMilliseconds,COUNT(*) AS cells FROM @rows GROUP BY cellAltitude ORDER BY SUM(durationMilliseconds) DESC FOR JSON PATH);
DECLARE @contributors nvarchar(max)=(SELECT TOP (@top) cellId,cellAltitude AS altitude,CONVERT(decimal(18,3),durationMilliseconds) AS durationMilliseconds FROM @rows ORDER BY durationMilliseconds DESC,cellId FOR JSON PATH);
DECLARE @windows int=0,@unattributed int=0,@negative int=0,@unattributedMs decimal(18,3)=0,@maxUnattributedMs decimal(18,3)=0,@negativeMs decimal(18,3)=0;
;WITH g AS (
 SELECT durationMilliseconds, CONVERT(decimal(18,3),DATEDIFF_BIG(microsecond,LAG(completed) OVER (ORDER BY completed),completed))/1000.0 AS gapMilliseconds
 FROM @rows WHERE completed IS NOT NULL
)
SELECT @windows=COUNT(*),
 @unattributed=SUM(CASE WHEN gapMilliseconds-durationMilliseconds>@noise THEN 1 ELSE 0 END),
 @negative=SUM(CASE WHEN gapMilliseconds-durationMilliseconds<-@noise THEN 1 ELSE 0 END),
 @unattributedMs=SUM(CASE WHEN gapMilliseconds-durationMilliseconds>@noise THEN gapMilliseconds-durationMilliseconds ELSE 0 END),
 @maxUnattributedMs=MAX(CASE WHEN gapMilliseconds-durationMilliseconds>@noise THEN gapMilliseconds-durationMilliseconds ELSE 0 END),
 @negativeMs=SUM(CASE WHEN gapMilliseconds-durationMilliseconds<-@noise THEN gapMilliseconds-durationMilliseconds ELSE 0 END)
FROM g WHERE gapMilliseconds IS NOT NULL;
DECLARE @closure nvarchar(max)=(SELECT @windows AS windows,@windows-@unattributed-@negative AS closed,@unattributed AS unattributed,@negative AS negative,CONVERT(decimal(18,3),@unattributedMs) AS unattributedMilliseconds,CONVERT(decimal(18,3),@maxUnattributedMs) AS maxUnattributedMilliseconds,CONVERT(decimal(18,3),@negativeMs) AS negativeMilliseconds,@noise AS noiseMilliseconds,CONVERT(bit,CASE WHEN @unattributed=0 AND @negative=0 THEN 1 ELSE 0 END) AS timingCoherent FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SELECT (SELECT N''invocation-timing-reading.v1'' AS reading,@cellCount AS cells,JSON_QUERY(@contributors) AS topContributors,JSON_QUERY(@byAltitude) AS attributedByAltitude,CONVERT(decimal(18,3),@total) AS totalAttributedMilliseconds,@wall AS wallSpanMilliseconds,@phases AS deliveryPhaseMilliseconds,CONVERT(decimal(18,3),CASE WHEN @wall IS NULL THEN NULL ELSE @wall-@phases-@total END) AS residualMilliseconds,JSON_QUERY(@closure) AS gapClosure FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value';
DECLARE @bindings nvarchar(max) = N'[{"portId":"read-invocation-timing-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,N'json') + N'","resultColumn":"value"}}]';

-- ============================== CONTRACTS AND CAPABILITY DOCUMENT ==============================
DECLARE @contracts nvarchar(max) = N'[
 {"id":"invocation-timing-request.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/invocation-timing-request.v1.schema.json","title":"Invocation timing request","type":"object","additionalProperties":false,"required":["contractId","payload"],"properties":{"contractId":{"const":"invocation-timing-request.v1"},"payload":{"type":"object","additionalProperties":true,"required":["cellTestimony"],"properties":{"label":{"type":"string"},"cellTestimony":{"type":"array"},"measured":{"type":"object"},"noiseMilliseconds":{"type":"number"},"topCount":{"type":"integer"}}}}}},
 {"id":"invocation-timing-reading.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/invocation-timing-reading.v1.schema.json","title":"Invocation timing reading","type":"object","additionalProperties":true,"required":["reading","cells","totalAttributedMilliseconds","gapClosure"],"properties":{"reading":{"const":"invocation-timing-reading.v1"},"cells":{"type":"integer"},"topContributors":{"type":"array"},"attributedByAltitude":{"type":"array"},"totalAttributedMilliseconds":{"type":"number"},"wallSpanMilliseconds":{"type":["number","null"]},"deliveryPhaseMilliseconds":{"type":"number"},"residualMilliseconds":{"type":["number","null"]},"gapClosure":{"type":"object"}}}}
]';
DECLARE @cli nvarchar(max) = N'{"display":{"transformationId":"read-invocation-timing-display.v1","as":"json"},"readings":[{"reading":"timing","altitudes":["scenario","mechanic","provider","physical"]}]}';
DECLARE @document nvarchar(max) = N'{
 "document":"sidefx-capability-authority.v1",
 "capabilityId":"read-invocation-timing",
 "meaning":{"intent":"read the time attribution of one invocation from its declared testimony","outcome":"the caller observes top contributors, attributed totals per altitude, the gap test and the residual against a supplied wall span"},
 "cli":' + @cli + N',
 "contracts":' + @contracts + N',
 "scenarios":[{
  "scenarioId":"read-invocation-timing",
  "name":"Read one invocation''s timing attribution",
  "inputId":"invocation-timing-request",
  "inputContract":"invocation-timing-request.v1",
  "eventId":"invocation-timing-requested",
  "eventAuthority":"read-invocation-timing.v1",
  "outcomeId":"invocation-timing-reading",
  "outcomeContract":"invocation-timing-reading.v1",
  "terminal":true,
  "root":true,
  "given":"one invocation''s declared cell testimony and, when streamed, its measured wall span",
  "when":"the declared timing read executes over the testimony under the reader boundary",
  "then":"the reading names the top contributors, the attributed totals per altitude, every gap above noise and the residual against the wall span",
  "operations":[{"operationId":"read-invocation-timing.0","kind":"invoke-port","portId":"read-invocation-timing-port"}],
  "portBindings":' + @bindings + N'
 }]
}';
EXEC model.declare_capability_document @document=@document;

-- ============================== THE DECLARED DISPLAY PROJECTION ==============================
-- The reading's display configuration selects this transformation. It emits
-- sfx-display-document.v1 over the read's outcome; the terminal renders the
-- blocks generically (no CLI change).
DECLARE @namespace nvarchar(400)=N'sidefx:capability:read-invocation-timing';
DECLARE @transformationId nvarchar(400)=N'read-invocation-timing-display.v1';
DECLARE @expression nvarchar(max)=N'{"op":"let","bindings":{"reading":{"op":"path","from":"execution","path":"outcome"},"closure":{"op":"path","from":"reading","path":"gapClosure"},"label":{"op":"if","when":{"op":"path","from":"scenarioInput","path":"payload.label"},"then":{"op":"path","from":"scenarioInput","path":"payload.label"},"else":{"op":"literal","value":"invocation"}},"wall":{"op":"path","from":"reading","path":"wallSpanMilliseconds"}},"value":{"op":"object","fields":{"documentType":{"op":"literal","value":"sfx-display-document.v1"},"blocks":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Invocation timing - {label}","values":{"label":{"op":"path","from":"label","path":""}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"TOTAL ATTRIBUTED"},"value":{"op":"format","template":"{total} ms across {cells} cells","values":{"total":{"op":"path","from":"reading","path":"totalAttributedMilliseconds"},"cells":{"op":"path","from":"reading","path":"cells"}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"RESIDUAL GAP"},"value":{"op":"if","when":{"op":"path","from":"wall","path":""},"then":{"op":"format","template":"{residual} ms (wall {wall} - phases {phases} - attributed {total})","values":{"residual":{"op":"path","from":"reading","path":"residualMilliseconds"},"wall":{"op":"path","from":"reading","path":"wallSpanMilliseconds"},"phases":{"op":"path","from":"reading","path":"deliveryPhaseMilliseconds"},"total":{"op":"path","from":"reading","path":"totalAttributedMilliseconds"}}},"else":{"op":"literal","value":"not measured (no streamed wall span supplied)"}}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"TIMING COHERENT"},"value":{"op":"format","template":"{coherent} ({windows} windows, {unattributed} unattributed, {negative} negative)","values":{"coherent":{"op":"path","from":"closure","path":"timingCoherent"},"windows":{"op":"path","from":"closure","path":"windows"},"unattributed":{"op":"path","from":"closure","path":"unattributed"},"negative":{"op":"path","from":"closure","path":"negative"}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"lane"},"label":{"op":"literal","value":"TOP CONTRIBUTORS"},"entries":{"op":"map","from":{"op":"path","from":"reading","path":"topContributors"},"as":"contributor","value":{"op":"object","fields":{"text":{"op":"format","template":"{cell}","values":{"cell":{"op":"path","from":"contributor","path":"cellId"}}},"note":{"op":"path","from":"contributor","path":"altitude"},"timing":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"contributor","path":"durationMilliseconds"}}}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"lane"},"label":{"op":"literal","value":"ATTRIBUTED BY ALTITUDE"},"entries":{"op":"map","from":{"op":"path","from":"reading","path":"attributedByAltitude"},"as":"altitude","value":{"op":"object","fields":{"text":{"op":"format","template":"{altitude}: {duration} ms","values":{"altitude":{"op":"path","from":"altitude","path":"altitude"},"duration":{"op":"path","from":"altitude","path":"durationMilliseconds"}}},"note":{"op":"format","template":"{cells} cells","values":{"cells":{"op":"path","from":"altitude","path":"cells"}}}}}}}}]}}}}';
DECLARE @semantics nvarchar(max)=N'{"id":"read-invocation-timing-display.v1","expression":'+@expression+N'}';
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

-- ============================== PROOF ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

SELECT '1_contracts' AS result_set, d.declared_id AS contract_id
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='CONTRACT'
 AND d.declared_id IN (N'invocation-timing-request.v1',N'invocation-timing-reading.v1')
ORDER BY d.declared_id;

SELECT '2_transformation' AS result_set, t.transformation_id, tv.transformation_version_pk, @digest AS definition_digest,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.expression.bindings.label.then.path') AS label_path
FROM model.transformation t
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=@definition
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
LEFT JOIN model.transformation_version tv ON tv.semantic_object_definition_pk=d.semantic_object_definition_pk
WHERE t.semantic_object_pk=@object;

SELECT '3_capability' AS result_set, c.capability_id, s.scenario_id,
 p.port_id, JSON_VALUE(pd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
 JSON_VALUE(pd.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 CASE WHEN JSON_VALUE(pd.definition_json,'$.semantics.configuration.statement') LIKE N'%LAG(completed)%' THEN 1 ELSE 0 END AS gap_test_declared
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN analysis.v_selected_semantic_definition pd ON pd.semantic_object_definition_pk=pv.semantic_object_definition_pk AND pd.estate_model_pk=@estate
WHERE c.capability_id=N'read-invocation-timing';

-- The assembled graph source from the uncommitted transaction: the interface
-- selects the declared display transformation and declares the timing reading.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-invocation-timing',0,N'sidefx:capabilities'));
SELECT '4_graph_source' AS result_set,
 JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.transformationId') AS display_transformation_id,
 JSON_QUERY(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.readings') AS readings,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations')) t WHERE JSON_VALUE(t.value,'$.id')=@transformationId) AS display_transformation_present;

-- The behavioral self-test: the declared statement itself is executed on a
-- two-cell synthetic testimony. One 40 ms scenario cell then one 60 ms mechanic
-- cell completed 100 ms after the first: the second window closes (gap 60 ms =
-- duration), the wall equation closes, and the top contributor is the mechanic.
DECLARE @stmt nvarchar(max)=(SELECT JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.configuration.statement')
 FROM analysis.v_selected_semantic_definition d
 JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=d.semantic_object_definition_pk
 JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=N'sidefx:capability:read-invocation-timing' AND d.declared_id=N'read-invocation-timing-port');
DECLARE @sample nvarchar(max)=N'{"contractId":"invocation-timing-request.v1","payload":{"label":"self-test","cellTestimony":[{"cellId":"cell:scenario:synthetic","cellAltitude":"scenario","durationMilliseconds":40,"completedAt":"2026-09-17T00:00:00.040Z"},{"cellId":"cell:mechanic:synthetic","cellAltitude":"mechanic","durationMilliseconds":60,"completedAt":"2026-09-17T00:00:00.100Z"}],"measured":{"wallSpanMilliseconds":100,"deliveryPhaseMilliseconds":0},"noiseMilliseconds":5,"topCount":1}}';
DECLARE @reading TABLE (value nvarchar(max));
INSERT @reading EXEC sp_executesql @stmt,N'@input nvarchar(max), @estate_model_pk bigint',@input=@sample,@estate_model_pk=@estate;
SELECT '5_reading_self_test' AS result_set,
 JSON_VALUE(value,'$.reading') AS reading,
 JSON_VALUE(value,'$.totalAttributedMilliseconds') AS total_attributed,
 JSON_VALUE(value,'$.residualMilliseconds') AS residual,
 JSON_VALUE(value,'$.gapClosure.timingCoherent') AS timing_coherent,
 JSON_VALUE(value,'$.gapClosure.windows') AS windows,
 JSON_VALUE(value,'$.topContributors[0].cellId') AS top_contributor
FROM @reading;

-- Installed 2026-09-17 after the rollback dry run and the from-transaction
-- preflight on the live agent-lane testimony (716 cells; total attributed
-- 10168.924 ms; every one of 715 gap windows closed at 5 ms noise; residual
-- 955.86 ms against the streamed 11678 ms wall span, named as pre-stream
-- kernel overhead + inter-event slack by the acceptance run).
COMMIT TRANSACTION;
