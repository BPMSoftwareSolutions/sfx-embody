-- declare-read-capability-circuit.sql
--
-- CV-A1/A2: the circuit view model as estate rows (docs/implementation-plan-circuit-view.md,
-- docs/circuit-view-flywheel.md). One declared read, read-capability-circuit, receives
-- one invocation's declared cell and edge testimony plus the capability identity and
-- returns circuit-view.v1: nodes and edges at semantic altitude, with every status taken
-- verbatim from testimony.
--
-- The derivation is declared SQL on the port statement, the same declared-read pattern
-- as declare-invocation-timing-reading.sql. It receives @input (circuit-view-request.v1)
-- and @estate_model_pk and returns one JSON reading in the value column. No kernel
-- behavior is added; every field it reads (cellId, cellAltitude, parentCellExecutionId,
-- disposition, outcomeClassification, durationMilliseconds, completedAt, logicalOrder,
-- and edgeId, sourceCellExecutionId, destinationCellId, admissionDisposition) is already
-- declared by cell-execution-testimony.v1 and edge-execution-testimony.v1.
--
-- Granularity rule (nearest enclosing cell). A testimony cell id is
-- cell:<altitude>:<scenario-or-operation-path>[:<sub-path>...]; the semantic component is
-- cell:<altitude>:<first tail segment>. Every expression, binding, field and selection
-- cell collapses into its enclosing operation; selection sub-cells never become nodes.
--   * one node per distinct semantic component, kind scenario|responsibility|provider|
--     physical (mechanic collapses to responsibility), altitude verbatim;
--   * status = outcomeClassification when present else disposition, never derived; a
--     component with no testimony row has no node at all (the unobserved box is the
--     declared graph's job, not this read's);
--   * durationMilliseconds and observedAt (completedAt else startedAt) are the
--     component's own testimony verbatim;
--   * parentId is structural: provider and physical under their operation, an operation
--     under its scenario when the scenario ran, a scenario under the invoking operation
--     its own testimony names when that operation belongs to another scenario;
--   * one edge per distinct observed admission between semantic components, endpoints
--     collapsed by the same rule, self-loops and duplicates removed, edgeId and
--     logicalOrder from the first testimony entry that yields the pair; selected is
--     admissionDisposition = admitted; selectsVariant is null (edge-execution-testimony
--     records no routing variant);
--   * both arrays ordered by the testimony's logicalOrder.
--
-- The read's own display configuration selects a declared display transformation
-- (read-capability-circuit-display.v1); the transformation returns the view model as the
-- display document, so the terminal prints the declared view verbatim.
--
-- Idempotent: the contracts are content-addressed, the transformation is declared
-- through the content-addressed writer, and the capability document's digest is the
-- installed-document gate. The document is installed twice in this script to prove the
-- replay is a no-op.
--
-- Default was ROLLBACK. Installed 2026-09-17 after the rollback dry run and the
-- from-transaction preflights on the live equity testimony (AVGO: 19 nodes, 18 edges)
-- and the live agent-lane testimony (request-capability-from-objective: 54 nodes,
-- 53 edges; 9 scenario components including the invoke-scenario children; statuses
-- verbatim, 4 failures carried through).
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
-- The statement is declaration data: it is carried by the port binding, not by code. It
-- receives @input (the circuit-view-request.v1 request) and the pinned estate parameters,
-- and returns one JSON circuit-view.v1 value in the value column.
DECLARE @statement nvarchar(max) = N'
DECLARE @cells_input nvarchar(max)=JSON_QUERY(@input,''$.payload.cellTestimony'');
DECLARE @edges_input nvarchar(max)=JSON_QUERY(@input,''$.payload.edgeTestimony'');
IF @cells_input IS NULL OR ISJSON(@cells_input)<>1 THROW 51000,''CIRCUIT_VIEW_CELL_TESTIMONY_REQUIRED'',1;
IF @edges_input IS NULL OR ISJSON(@edges_input)<>1 THROW 51000,''CIRCUIT_VIEW_EDGE_TESTIMONY_REQUIRED'',1;
DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.payload.capabilityId''),N'''');
IF @capability_id IS NULL THROW 51000,''CIRCUIT_VIEW_CAPABILITY_ID_REQUIRED'',1;
DECLARE @nodes TABLE(
 cellId nvarchar(400),
 kind nvarchar(40),
 altitude nvarchar(40),
 label nvarchar(400),
 scenarioName nvarchar(300),
 seg3 nvarchar(400),
 parentTopId nvarchar(400),
 status nvarchar(80),
 durationMilliseconds decimal(18,3),
 observedAt nvarchar(40),
 logicalOrder int
);
;WITH open_cells AS (
 SELECT c.cellId,c.cellAltitude,c.parentCellExecutionId,c.disposition,c.outcomeClassification,
  TRY_CONVERT(decimal(18,3),c.durationMilliseconds) AS durationMilliseconds,
  COALESCE(c.completedAt,c.startedAt) AS observedAt,
  c.logicalOrder
 FROM OPENJSON(@cells_input) WITH (
  cellId nvarchar(400) ''$.cellId'',
  cellAltitude nvarchar(40) ''$.cellAltitude'',
  parentCellExecutionId nvarchar(600) ''$.parentCellExecutionId'',
  disposition nvarchar(80) ''$.disposition'',
  outcomeClassification nvarchar(80) ''$.outcomeClassification'',
  durationMilliseconds nvarchar(64) ''$.durationMilliseconds'',
  completedAt nvarchar(40) ''$.completedAt'',
  startedAt nvarchar(40) ''$.startedAt'',
  logicalOrder int ''$.logicalOrder''
 ) c
 WHERE c.cellId LIKE N''cell:%''
),
head AS (SELECT *,CHARINDEX('':'',cellId,6) AS headColon FROM open_cells),
body AS (SELECT *,SUBSTRING(cellId,6,headColon-6) AS altitude,SUBSTRING(cellId,headColon+1,400) AS tail FROM head WHERE headColon>0),
tail AS (SELECT *,CHARINDEX('':'',tail) AS tailColon FROM body),
shaped AS (SELECT *,CASE WHEN tailColon=0 THEN tail ELSE LEFT(tail,tailColon-1) END AS seg3 FROM tail),
cell_rows AS (
 SELECT *,N''cell:''+altitude+N'':''+seg3 AS topId,
  CASE WHEN seg3 LIKE N''%.operation.%'' THEN LEFT(seg3,CHARINDEX(N''.operation.'',seg3)-1) ELSE seg3 END AS scenarioName
 FROM shaped
),
ranked AS (
 SELECT *,ROW_NUMBER() OVER (PARTITION BY topId ORDER BY CASE WHEN cellId=topId THEN 0 ELSE 1 END,logicalOrder,cellId) AS rn
 FROM cell_rows
),
parents AS (SELECT cellId,parentCellExecutionId FROM ranked WHERE rn=1 AND parentCellExecutionId IS NOT NULL),
parent_ref AS (
 SELECT cellId,
  CASE WHEN CHARINDEX(N'':cell:'',parentCellExecutionId)>0
   THEN SUBSTRING(parentCellExecutionId,CHARINDEX(N'':cell:'',parentCellExecutionId)+1,600)
   ELSE parentCellExecutionId END AS cellRef
 FROM parents
),
parent_head AS (SELECT *,CHARINDEX('':'',cellRef,6) AS headColon FROM parent_ref),
parent_body AS (SELECT *,SUBSTRING(cellRef,6,headColon-6) AS altitude,SUBSTRING(cellRef,headColon+1,400) AS tail FROM parent_head WHERE headColon>0),
parent_tail AS (SELECT *,CHARINDEX('':'',tail) AS tailColon FROM parent_body),
parent_top AS (
 SELECT cellId,N''cell:''+altitude+N'':''+CASE WHEN tailColon=0 THEN tail ELSE LEFT(tail,tailColon-1) END AS parentTopId
 FROM parent_tail
)
INSERT @nodes(cellId,kind,altitude,label,scenarioName,seg3,parentTopId,status,durationMilliseconds,observedAt,logicalOrder)
SELECT r.topId,
 CASE WHEN r.cellAltitude=N''mechanic'' THEN N''responsibility'' ELSE r.cellAltitude END,
 r.cellAltitude,r.seg3,r.scenarioName,r.seg3,p.parentTopId,
 COALESCE(r.outcomeClassification,r.disposition),r.durationMilliseconds,r.observedAt,r.logicalOrder
FROM ranked r LEFT JOIN parent_top p ON p.cellId=r.cellId
WHERE r.rn=1;
DECLARE @nodes_json nvarchar(max)=(
 SELECT n.cellId AS cellId,n.kind AS kind,n.altitude AS altitude,n.label AS label,
  CASE
   WHEN n.kind=N''scenario'' THEN (SELECT CASE WHEN p.scenarioName<>n.scenarioName THEN p.cellId ELSE NULL END FROM @nodes p WHERE p.cellId=n.parentTopId)
   WHEN n.kind=N''responsibility'' THEN (SELECT s.cellId FROM @nodes s WHERE s.cellId=N''cell:scenario:''+n.scenarioName)
   ELSE COALESCE(
    (SELECT m.cellId FROM @nodes m WHERE m.cellId=N''cell:mechanic:''+n.seg3),
    (SELECT s2.cellId FROM @nodes s2 WHERE s2.cellId=N''cell:scenario:''+n.scenarioName))
  END AS parentId,
  n.status AS status,
  n.durationMilliseconds AS durationMilliseconds,
  n.observedAt AS observedAt,
  n.logicalOrder AS logicalOrder
 FROM @nodes n
 ORDER BY n.logicalOrder,n.cellId
 FOR JSON PATH,INCLUDE_NULL_VALUES);
DECLARE @edges TABLE(edgeId nvarchar(600),kind nvarchar(40),fromId nvarchar(400),toId nvarchar(400),selected bit,selectsVariant nvarchar(100),logicalOrder int);
;WITH open_edges AS (
 SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS edgeRow,e.edgeId,e.sourceCellExecutionId,e.destinationCellId,e.admissionDisposition,
  TRY_CONVERT(int,e.logicalOrder) AS logicalOrder
 FROM OPENJSON(@edges_input) WITH (
  edgeId nvarchar(600) ''$.edgeId'',
  sourceCellExecutionId nvarchar(600) ''$.sourceCellExecutionId'',
  destinationCellId nvarchar(600) ''$.destinationCellId'',
  admissionDisposition nvarchar(40) ''$.admissionDisposition'',
  logicalOrder int ''$.logicalOrder''
 ) e
 WHERE e.edgeId IS NOT NULL
),
sides AS (
 SELECT edgeRow,edgeId,admissionDisposition,logicalOrder,N''from'' AS side,
  CASE WHEN CHARINDEX(N'':cell:'',sourceCellExecutionId)>0
   THEN SUBSTRING(sourceCellExecutionId,CHARINDEX(N'':cell:'',sourceCellExecutionId)+1,600)
   ELSE sourceCellExecutionId END AS cellRef
 FROM open_edges
 UNION ALL
 SELECT edgeRow,edgeId,admissionDisposition,logicalOrder,N''to'',destinationCellId
 FROM open_edges WHERE destinationCellId LIKE N''cell:%''
),
head AS (SELECT *,CHARINDEX('':'',cellRef,6) AS headColon FROM sides WHERE cellRef IS NOT NULL),
body AS (SELECT *,SUBSTRING(cellRef,6,headColon-6) AS altitude,SUBSTRING(cellRef,headColon+1,400) AS tail FROM head WHERE headColon>0),
tail AS (SELECT *,CHARINDEX('':'',tail) AS tailColon FROM body),
collapsed AS (
 SELECT edgeRow,edgeId,admissionDisposition,logicalOrder,side,
  N''cell:''+altitude+N'':''+CASE WHEN tailColon=0 THEN tail ELSE LEFT(tail,tailColon-1) END AS topId
 FROM tail
),
pairs AS (
 SELECT edgeRow,MAX(edgeId) AS edgeId,MAX(admissionDisposition) AS admissionDisposition,MIN(logicalOrder) AS logicalOrder,
  MAX(CASE WHEN side=N''from'' THEN topId END) AS fromId,
  MAX(CASE WHEN side=N''to'' THEN topId END) AS toId
 FROM collapsed GROUP BY edgeRow
),
ranked_edges AS (
 SELECT p.*,ROW_NUMBER() OVER (PARTITION BY p.fromId,p.toId,CAST(CASE WHEN p.admissionDisposition=N''admitted'' THEN 1 ELSE 0 END AS bit) ORDER BY p.logicalOrder,p.edgeId) AS rn
 FROM pairs p
 WHERE p.fromId IS NOT NULL AND p.toId IS NOT NULL AND p.fromId<>p.toId
  AND EXISTS (SELECT 1 FROM @nodes n WHERE n.cellId=p.fromId)
  AND EXISTS (SELECT 1 FROM @nodes n WHERE n.cellId=p.toId)
)
INSERT @edges(edgeId,kind,fromId,toId,selected,selectsVariant,logicalOrder)
SELECT edgeId,N''sequence'',fromId,toId,CAST(CASE WHEN admissionDisposition=N''admitted'' THEN 1 ELSE 0 END AS bit),CAST(NULL AS nvarchar(100)),logicalOrder
FROM ranked_edges WHERE rn=1;
DECLARE @edges_json nvarchar(max)=(
 SELECT e.edgeId AS edgeId,e.kind AS kind,e.fromId AS [from],e.toId AS [to],e.selected AS selected,e.selectsVariant AS selectsVariant,e.logicalOrder AS logicalOrder
 FROM @edges e
 ORDER BY e.logicalOrder,e.edgeId
 FOR JSON PATH,INCLUDE_NULL_VALUES);
SELECT (SELECT N''circuit-view.v1'' AS contractId,@capability_id AS capabilityId,N''nearest-enclosing-cell.v1'' AS granularity,
 JSON_QUERY(@nodes_json) AS nodes,JSON_QUERY(@edges_json) AS edges
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;
';

-- ============================== CONTRACTS ==============================
-- Permissive by design: the request and the view carry testimony shapes the statement
-- reads, and additionalProperties stays open so testimony evolution does not break a
-- declaration. The capability document below declares the same bytes, so the document
-- path's contract step is a content-addressed no-op.
DECLARE @request_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/circuit-view-request.v1.schema.json","title":"Circuit view request","type":"object","additionalProperties":true,"required":["contractId","payload"],"properties":{"contractId":{"const":"circuit-view-request.v1"},"payload":{"type":"object","additionalProperties":true,"required":["capabilityId","cellTestimony","edgeTestimony"],"properties":{"capabilityId":{"type":"string","minLength":1},"cellTestimony":{"type":"array"},"edgeTestimony":{"type":"array"},"granularity":{"type":"string"}}}}}';
DECLARE @view_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/circuit-view.v1.schema.json","title":"Circuit view","type":"object","additionalProperties":true,"required":["contractId","capabilityId","nodes","edges"],"properties":{"contractId":{"const":"circuit-view.v1"},"capabilityId":{"type":"string"},"granularity":{"type":"string"},"nodes":{"type":"array","items":{"type":"object","additionalProperties":true,"properties":{"cellId":{"type":"string"},"kind":{"type":"string"},"altitude":{"type":"string"},"label":{"type":["string","null"]},"parentId":{"type":["string","null"]},"status":{"type":["string","null"]},"durationMilliseconds":{"type":["number","null"]},"observedAt":{"type":["string","null"]},"logicalOrder":{"type":["integer","null"]}}}},"edges":{"type":"array","items":{"type":"object","additionalProperties":true,"properties":{"edgeId":{"type":"string"},"kind":{"type":"string"},"from":{"type":["string","null"]},"to":{"type":["string","null"]},"selected":{"type":"boolean"},"selectsVariant":{"type":["string","null"]},"logicalOrder":{"type":["integer","null"]}}}}}}';
EXEC model.declare_contract @id=N'circuit-view-request.v1', @schema=@request_schema;
EXEC model.declare_contract @id=N'circuit-view.v1', @schema=@view_schema;

-- ============================== CAPABILITY DOCUMENT ==============================
DECLARE @contracts nvarchar(max) = N'[{"id":"circuit-view-request.v1","schema":' + @request_schema + N'},{"id":"circuit-view.v1","schema":' + @view_schema + N'}]';
DECLARE @bindings nvarchar(max) = N'[{"portId":"read-capability-circuit-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,N'json') + N'","resultColumn":"value"}}]';
DECLARE @cli nvarchar(max) = N'{"display":{"transformationId":"read-capability-circuit-display.v1","as":"json"}}';
DECLARE @document nvarchar(max) = N'{
 "document":"sidefx-capability-authority.v1",
 "capabilityId":"read-capability-circuit",
 "meaning":{"intent":"read one invocation''s circuit from its declared testimony","outcome":"the caller observes the semantic circuit: one node per component with its verbatim status, duration and observation time, and one edge per observed admission between components"},
 "cli":' + @cli + N',
 "contracts":' + @contracts + N',
 "scenarios":[{
  "scenarioId":"read-capability-circuit",
  "name":"Read one invocation circuit from its declared testimony",
  "inputId":"circuit-view-request",
  "inputContract":"circuit-view-request.v1",
  "eventId":"circuit-view-requested",
  "eventAuthority":"read-capability-circuit.v1",
  "outcomeId":"circuit-view",
  "outcomeContract":"circuit-view.v1",
  "terminal":true,
  "root":true,
  "given":"one invocation of a declared capability: its cell and edge testimony and the capability identity",
  "when":"the declared circuit read executes over the testimony under the reader boundary",
  "then":"the caller observes the semantic circuit: nodes with statuses verbatim from testimony and edges between observed components",
  "operations":[{"operationId":"read-capability-circuit.0","kind":"invoke-port","portId":"read-capability-circuit-port"}],
  "portBindings":' + @bindings + N'
 }]
}';
EXEC model.declare_capability_document @document=@document;
EXEC model.declare_capability_document @document=@document;

-- ============================== THE DECLARED DISPLAY TRANSFORMATION ==============================
-- The read's display configuration selects this transformation. It returns the view model
-- itself as the display document, so the declared bytes are the circuit view.
DECLARE @namespace nvarchar(400)=N'sidefx:capability:read-capability-circuit';
DECLARE @transformationId nvarchar(400)=N'read-capability-circuit-display.v1';
DECLARE @expression nvarchar(max)=N'{"op":"let","bindings":{"view":{"op":"path","from":"execution","path":"outcome"}},"value":{"op":"path","from":"view","path":""}}';
DECLARE @semantics nvarchar(max)=N'{"id":"read-capability-circuit-display.v1","expression":'+@expression+N'}';
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

SELECT '1_contracts' AS result_set, d.declared_id AS contract_id, COUNT(*) AS current_definitions
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='CONTRACT'
 AND d.declared_id IN (N'circuit-view-request.v1',N'circuit-view.v1')
GROUP BY d.declared_id
ORDER BY d.declared_id;

SELECT '2_capability' AS result_set, c.capability_id, s.scenario_id, eo.operation_id, eo.operation_kind,
 p.port_id, JSON_VALUE(pd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
 JSON_VALUE(pd.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 CASE WHEN CHARINDEX(N'CIRCUIT_VIEW_CELL_TESTIMONY_REQUIRED',JSON_QUERY(pd.definition_json,'$.semantics.configuration'))>0 THEN 1 ELSE 0 END AS testimony_declared
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
WHERE c.capability_id=N'read-capability-circuit';

SELECT '3_display_transformation' AS result_set, t.transformation_id, tv.transformation_version_pk, @digest AS definition_digest,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.expression.value.from') AS selects_from,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.expression.value.path') AS selects_path
FROM model.transformation t
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=@definition
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
LEFT JOIN model.transformation_version tv ON tv.semantic_object_definition_pk=d.semantic_object_definition_pk
WHERE t.semantic_object_pk=@object;

-- The assembled graph source from the uncommitted transaction: the interface selects the
-- declared display transformation and the transformation travels with the capability.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-capability-circuit',0,N'sidefx:capabilities'));
SELECT '4_graph_source' AS result_set, g.root_scenario_id,
 JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.transformationId') AS display_transformation_id,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations')) t WHERE JSON_VALUE(t.value,'$.id')=@transformationId) AS display_transformation_present
FROM analysis.v_capability_graph_source g WHERE g.capability_id=N'read-capability-circuit';

-- The behavioral self-test: the declared statement itself is executed on a synthetic
-- testimony with a scenario, an operation, its expression sub-cell, a provider and a
-- physical cell, plus a dependency edge (collapses into the operation and is dropped) and
-- spanning edges. Expected: 4 nodes, 3 edges, statuses verbatim (success/failure kept as
-- classification, completed kept as disposition), the failure on the provider node.
DECLARE @stmt nvarchar(max);
SELECT @stmt=js.statement
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') WITH (statement nvarchar(max) '$.statement') js
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=N'sidefx:capability:read-capability-circuit' AND d.declared_id=N'read-capability-circuit-port';
DECLARE @sample nvarchar(max)=N'{"contractId":"circuit-view-request.v1","payload":{"capabilityId":"self-test","cellTestimony":[{"cellId":"cell:scenario:demo","cellAltitude":"scenario","disposition":"completed","outcomeClassification":"success","durationMilliseconds":5,"completedAt":"2026-09-17T00:00:00.005Z","logicalOrder":0},{"cellId":"cell:mechanic:demo.operation.1:expression.fields.x","cellAltitude":"mechanic","disposition":"completed","durationMilliseconds":1,"completedAt":"2026-09-17T00:00:00.008Z","logicalOrder":5},{"cellId":"cell:mechanic:demo.operation.1","cellAltitude":"mechanic","disposition":"completed","durationMilliseconds":3,"completedAt":"2026-09-17T00:00:00.011Z","logicalOrder":7},{"cellId":"cell:provider:demo.operation.1","cellAltitude":"provider","disposition":"completed","outcomeClassification":"failure","durationMilliseconds":2,"completedAt":"2026-09-17T00:00:00.013Z","logicalOrder":9},{"cellId":"cell:physical:demo.operation.1","cellAltitude":"physical","disposition":"completed","outcomeClassification":"success","durationMilliseconds":2,"completedAt":"2026-09-17T00:00:00.015Z","logicalOrder":11}],"edgeTestimony":[{"edgeId":"cell:mechanic:demo.operation.1:expression:dependency:1","sourceCellExecutionId":"execution:graph:demo:cell:mechanic:demo.operation.1:expression.fields.x:1","destinationCellId":"cell:mechanic:demo.operation.1","admissionDisposition":"admitted","logicalOrder":6},{"edgeId":"edge:sequence:demo:1","sourceCellExecutionId":"execution:graph:demo:cell:mechanic:demo.operation.1:1","destinationCellId":"cell:provider:demo.operation.1","admissionDisposition":"admitted","logicalOrder":8},{"edgeId":"edge:descent:demo.operation.1","sourceCellExecutionId":"execution:graph:demo:cell:provider:demo.operation.1:1","destinationCellId":"cell:physical:demo.operation.1","admissionDisposition":"admitted","logicalOrder":10},{"edgeId":"edge:return:demo","sourceCellExecutionId":"execution:graph:demo:cell:physical:demo.operation.1:1","destinationCellId":"cell:scenario:demo","admissionDisposition":"admitted","logicalOrder":12}]}}';
DECLARE @view TABLE (value nvarchar(max));
INSERT @view EXEC sp_executesql @stmt,N'@input nvarchar(max), @estate_model_pk bigint',@input=@sample,@estate_model_pk=@estate;
SELECT '5_view_self_test' AS result_set,
 JSON_VALUE(value,'$.contractId') AS contract_id,
 JSON_VALUE(value,'$.capabilityId') AS capability_id,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.nodes'))) AS nodes,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.edges'))) AS edges,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.nodes')) n WHERE JSON_VALUE(n.value,'$.parentId') IS NOT NULL) AS parented,
 (SELECT TOP 1 JSON_VALUE(n.value,'$.status') FROM OPENJSON(JSON_QUERY(value,'$.nodes')) n ORDER BY TRY_CONVERT(int,JSON_VALUE(n.value,'$.logicalOrder'))) AS first_status,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.nodes')) n WHERE JSON_VALUE(n.value,'$.status')=N'failure') AS failure_nodes,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.edges')) e WHERE JSON_VALUE(e.value,'$.selected')=N'true') AS selected_edges
FROM @view;

-- One current definition per declared id: the replay above minted no duplicate
-- capability document, port or transformation.
SELECT '6_current_definitions' AS result_set, d.namespace_id, d.object_kind, d.declared_id, COUNT(*) AS current_definitions
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate
 AND (d.namespace_id=N'sidefx:capability:read-capability-circuit'
  OR (d.namespace_id=N'sidefx:capability-documents' AND d.declared_id=N'read-capability-circuit'))
GROUP BY d.namespace_id,d.object_kind,d.declared_id
ORDER BY d.namespace_id,d.object_kind,d.declared_id;

COMMIT TRANSACTION;
