-- extend-circuit-attestation.sql
--
-- CV-D1 (re-specified, docs/implementation-plan-circuit-view.md): the structural
-- attestation is declared authority, not code. The classification script
-- (scripts/verify-circuit-structure.mjs, added c01e777, removed 7965689) is not
-- recreated; its rule moves into the declared read. This migration re-declares
-- read-capability-circuit so that:
--   * circuit-view-request.v1 gains optional plannedCells and plannedEdges (the
--     compiled plan as the overlay exposes it: {cellId,parentCellId,altitude} and
--     {edgeId,planned:{from:{cellId},to:{cellId},selectsVariant},observed:[...]});
--   * circuit-view.v1 gains attestation
--     {structured,plannedCells,observedCells,unmatchedObserved,onTakenPathUnobserved,
--      misses:[{cellId,altitude}],unselectedPlanned:[{cellId,altitude,classification}],
--      unmatchedObservedCells:[{cellId}]};
--   * the declared read statement computes that attestation over the JSON inputs;
--     nodes, edges and the declared display projection are unchanged (additive).
--
-- The declared rule:
--   * observedCells = distinct cellId among cellTestimony rows at scenario,
--     mechanic, provider or physical altitude;
--   * unmatchedObservedCells = observed cellIds that equal no planned cell and do
--     not reduce or climb to one by the ancestor closure (trailing
--     :expression/:selection, interior :expression/:selection token, one trailing
--     .segment, or the declared parentCellId link, repeatedly);
--   * unmatchedPlanned = planned cellIds with no testimony entry;
--   * onObservedPath = the observed path entered the cell's subtree (an observed
--     cell reduces or climbs to it) OR an observed cell sits at-or-above it (it
--     reduces or climbs to an observed cell). The deleted script's rule ("a
--     semantic non-fragment cell on the observed path without testimony is the
--     failure") needs the subtree direction: within one altitude the only observed
--     ancestors of a cell are its :expression/:selection fragments, and those are
--     exactly the cells the miss rule excludes. The task's observed-ancestor clause
--     is kept as the second disjunct; the operation-removed fixture is the first.
--     Gap closed (recorded in b9d4499, fixed 2026-09-17): the closure now also
--     follows the declared parentCellId chain through the planned cells, so a
--     non-fragment leaf with no observed same-altitude relative (e.g. a provider
--     cell whose own testimony vanished) is named when its declaring operation is
--     observed; the id hierarchy remains the fallback where no declared parent
--     exists. Before the fix the provider-removed fixture returned structured true
--     with the provider only in unselectedPlanned (uninvoked-declared-subtree);
--     after it returns structured false with the provider named in misses. Live
--     values are unchanged (below).
--   * misses = unmatched planned cells whose cellId contains no :expression/:selection
--     and that are onObservedPath; these are the failures;
--   * unselectedPlanned = the remaining unmatched planned cells, classified
--     unselected-branch-fragment when an observed ancestor exists else
--     uninvoked-declared-subtree;
--   * structured = (unmatchedObserved = 0) AND (misses = 0).
--
-- Contract versioning follows model.declare_contract: the same declared id with
-- new schema bytes mints a new contract_version; the selected definition is the
-- highest semantic_object_definition_pk (analysis.v_selected_semantic_definition),
-- so the new versions supersede without overwriting.
--
-- Expected live values (the deleted script's receipt, evidence/vault-20260916/iea/
-- circuit-structure.receipt.json): agent lane planned 985 / observed 703 / misses 0 /
-- structured true (267 unselected-branch-fragment, 15 uninvoked-declared-subtree);
-- equity 242/180/0/true (62 unselected-branch-fragment). The operation-removed
-- negative fixture removes one taken-path operation cell's testimony and expects
-- structured false with that cell named in misses. The gap fixture removes a
-- non-fragment provider leaf's testimony (no observed same-altitude relative) and
-- expects structured false with the provider named in misses.
--
-- Default was ROLLBACK. First installed 2026-09-17 after the rollback dry run and
-- the from-transaction preflights on the live captures: agent lane 985 planned / 703
-- observed / 0 misses / structured true; equity 242/180/0/true; the operation-removed
-- fixtures return structured false with that cell named in misses. Re-installed
-- 2026-09-17 with the gap closed: the provider-removed fixture captured against the
-- first install (structured true, provider in unselectedPlanned as
-- uninvoked-declared-subtree) returns structured false with the provider named in
-- misses; the live values above are unchanged. The declared meaning's outcome now
-- states the naming basis (the declared parentCellId chain when no observed
-- same-altitude relative names the cell); the re-declaration therefore carries new
-- meaning bytes, which is also what the platform's author step requires to re-mint
-- the capability version (a meaning definition already held by an older version
-- cannot be re-pointed).
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
-- The statement is declaration data: it is carried by the port binding, not by code.
-- It receives @input (the circuit-view-request.v1 request) and the pinned estate
-- parameters, and returns one JSON circuit-view.v1 value in the value column.
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
-- The structural attestation: the compiled plan (plannedCells: the overlay''s planned
-- cells, each {cellId,parentCellId,altitude}) against the qualifying testimony.
-- observedCells is the distinct cellId at scenario/mechanic/provider/physical altitude.
-- The ancestor closure reduces each id by stripping a trailing :expression/:selection,
-- an interior :expression/:selection token, or one trailing .segment, repeatedly, and
-- follows the declared parentCellId link through the planned cells, transitively; the
-- id hierarchy remains the fallback where no declared parent exists. A planned cell is
-- on the observed path when the observed path entered its subtree (an observed cell
-- reduces or climbs to it) or an observed cell sits at-or-above it (it reduces or climbs
-- to an observed cell). The declared parent link is what names a non-fragment leaf with
-- no observed same-altitude relative: a provider cell whose own testimony vanished still
-- climbs to its observed declaring operation, where the id hierarchy alone could not
-- relate the two altitudes. An unselected branch whose declaring ancestry never
-- testified stays unlit and is classified as before; the recorded first-turn values
-- (985/703 and 242/180, misses 0, structured true) are unchanged. A miss is an unmatched
-- non-fragment planned cell on that path; the rest are named and classified
-- unselected-branch-fragment (observed ancestor) or uninvoked-declared-subtree.
DECLARE @planned_input nvarchar(max)=JSON_QUERY(@input,''$.payload.plannedCells'');
IF @planned_input IS NULL SET @planned_input=N''[]'';
IF ISJSON(@planned_input)<>1 THROW 51000,''CIRCUIT_VIEW_PLANNED_CELLS_INVALID'',1;
DECLARE @observed TABLE(cellId nvarchar(400) NOT NULL PRIMARY KEY,altitude nvarchar(40));
INSERT @observed(cellId,altitude)
SELECT c.cellId,MIN(c.cellAltitude)
FROM OPENJSON(@cells_input) WITH (cellId nvarchar(400) ''$.cellId'',cellAltitude nvarchar(40) ''$.cellAltitude'') c
WHERE c.cellAltitude IN (N''scenario'',N''mechanic'',N''provider'',N''physical'')
GROUP BY c.cellId;
DECLARE @planned TABLE(cellId nvarchar(400) NOT NULL PRIMARY KEY,altitude nvarchar(40),parentCellId nvarchar(400));
INSERT @planned(cellId,altitude,parentCellId)
SELECT p.cellId,MIN(p.altitude),MIN(p.parentCellId)
FROM OPENJSON(@planned_input) WITH (cellId nvarchar(400) ''$.cellId'',altitude nvarchar(40) ''$.altitude'',parentCellId nvarchar(400) ''$.parentCellId'') p
WHERE p.cellId IS NOT NULL
GROUP BY p.cellId;
DECLARE @planned_parent TABLE(cellId nvarchar(400) NOT NULL PRIMARY KEY,parentCellId nvarchar(400) NOT NULL);
INSERT @planned_parent(cellId,parentCellId)
SELECT p.cellId,p.parentCellId FROM @planned p
WHERE p.parentCellId IS NOT NULL AND p.parentCellId<>p.cellId;
DECLARE @anc TABLE(originId nvarchar(400) NOT NULL,candidate nvarchar(400) NOT NULL,PRIMARY KEY NONCLUSTERED(originId,candidate));
INSERT @anc(originId,candidate)
SELECT cellId,cellId FROM @planned
UNION
SELECT cellId,cellId FROM @observed;
DECLARE @added int=1;
WHILE @added>0
BEGIN
 INSERT @anc(originId,candidate)
 SELECT DISTINCT a.originId,v.candidate
 FROM @anc a
 OUTER APPLY (SELECT pp.parentCellId FROM @planned_parent pp WHERE pp.cellId=a.candidate) d
 CROSS APPLY (VALUES
  (CASE WHEN RIGHT(a.candidate,10)=N'':selection'' THEN LEFT(a.candidate,LEN(a.candidate)-10) END),
  (CASE WHEN RIGHT(a.candidate,11)=N'':expression'' THEN LEFT(a.candidate,LEN(a.candidate)-11) END),
  (CASE WHEN CHARINDEX(N''.'',REVERSE(a.candidate))>1 AND CHARINDEX(N'':'',SUBSTRING(a.candidate,LEN(a.candidate)-CHARINDEX(N''.'',REVERSE(a.candidate))+2,400))=0
    THEN LEFT(a.candidate,LEN(a.candidate)-CHARINDEX(N''.'',REVERSE(a.candidate))) END),
  (CASE WHEN PATINDEX(N''%:expression[.:]%'',a.candidate)>0
    THEN LEFT(a.candidate,PATINDEX(N''%:expression[.:]%'',a.candidate)-1)+SUBSTRING(a.candidate,PATINDEX(N''%:expression[.:]%'',a.candidate)+11,400) END),
  (CASE WHEN PATINDEX(N''%:selection[.:]%'',a.candidate)>0
    THEN LEFT(a.candidate,PATINDEX(N''%:selection[.:]%'',a.candidate)-1)+SUBSTRING(a.candidate,PATINDEX(N''%:selection[.:]%'',a.candidate)+10,400) END),
  (d.parentCellId)
 ) v(candidate)
 WHERE v.candidate IS NOT NULL AND LEN(v.candidate)>0 AND v.candidate<>a.candidate
  AND NOT EXISTS(SELECT 1 FROM @anc x WHERE x.originId=a.originId AND x.candidate=v.candidate);
 SET @added=@@ROWCOUNT;
END
DECLARE @unmatched_observed TABLE(cellId nvarchar(400) NOT NULL PRIMARY KEY,altitude nvarchar(40));
INSERT @unmatched_observed(cellId,altitude)
SELECT o.cellId,o.altitude FROM @observed o
WHERE NOT EXISTS(SELECT 1 FROM @anc a JOIN @planned p ON p.cellId=a.candidate WHERE a.originId=o.cellId);
DECLARE @unmatched_planned TABLE(cellId nvarchar(400) NOT NULL PRIMARY KEY,altitude nvarchar(40),onObservedPath bit);
INSERT @unmatched_planned(cellId,altitude,onObservedPath)
SELECT p.cellId,p.altitude,
 CAST(CASE WHEN EXISTS(SELECT 1 FROM @anc a JOIN @observed o ON o.cellId=a.candidate WHERE a.originId=p.cellId AND a.candidate<>p.cellId)
   OR EXISTS(SELECT 1 FROM @anc a JOIN @observed o ON o.cellId=a.originId WHERE a.candidate=p.cellId AND a.originId<>p.cellId)
  THEN 1 ELSE 0 END AS bit)
FROM @planned p
WHERE NOT EXISTS(SELECT 1 FROM @observed o WHERE o.cellId=p.cellId);
DECLARE @misses_json nvarchar(max)=(
 SELECT m.cellId AS cellId,m.altitude AS altitude
 FROM @unmatched_planned m
 WHERE m.onObservedPath=1 AND m.cellId NOT LIKE N''%:expression%'' AND m.cellId NOT LIKE N''%:selection%''
 ORDER BY m.cellId
 FOR JSON PATH,INCLUDE_NULL_VALUES);
DECLARE @unselected_json nvarchar(max)=(
 SELECT u.cellId AS cellId,u.altitude AS altitude,
  CASE WHEN EXISTS(SELECT 1 FROM @anc a JOIN @observed o ON o.cellId=a.candidate WHERE a.originId=u.cellId AND a.candidate<>u.cellId)
   THEN N''unselected-branch-fragment'' ELSE N''uninvoked-declared-subtree'' END AS classification
 FROM @unmatched_planned u
 WHERE NOT (u.onObservedPath=1 AND u.cellId NOT LIKE N''%:expression%'' AND u.cellId NOT LIKE N''%:selection%'')
 ORDER BY u.cellId
 FOR JSON PATH,INCLUDE_NULL_VALUES);
DECLARE @unmatched_observed_json nvarchar(max)=(
 SELECT o.cellId AS cellId FROM @unmatched_observed o ORDER BY o.cellId
 FOR JSON PATH,INCLUDE_NULL_VALUES);
DECLARE @attestation_json nvarchar(max)=(
 SELECT CAST(CASE WHEN (SELECT COUNT(*) FROM @unmatched_observed)=0
   AND (SELECT COUNT(*) FROM @unmatched_planned WHERE onObservedPath=1 AND cellId NOT LIKE N''%:expression%'' AND cellId NOT LIKE N''%:selection%'')=0
  THEN 1 ELSE 0 END AS bit) AS structured,
  (SELECT COUNT(*) FROM @planned) AS plannedCells,
  (SELECT COUNT(*) FROM @observed) AS observedCells,
  (SELECT COUNT(*) FROM @unmatched_observed) AS unmatchedObserved,
  (SELECT COUNT(*) FROM @unmatched_planned WHERE onObservedPath=1 AND cellId NOT LIKE N''%:expression%'' AND cellId NOT LIKE N''%:selection%'') AS onTakenPathUnobserved,
  JSON_QUERY(COALESCE(@misses_json,N''[]'')) AS misses,
  JSON_QUERY(COALESCE(@unselected_json,N''[]'')) AS unselectedPlanned,
  JSON_QUERY(COALESCE(@unmatched_observed_json,N''[]'')) AS unmatchedObservedCells
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SELECT (SELECT N''circuit-view.v1'' AS contractId,@capability_id AS capabilityId,N''nearest-enclosing-cell.v1'' AS granularity,
 JSON_QUERY(@nodes_json) AS nodes,JSON_QUERY(@edges_json) AS edges,JSON_QUERY(@attestation_json) AS attestation
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;
';

-- ============================== CONTRACTS ==============================
-- New versions of the same declared ids. Permissive as before: the request and the
-- view carry shapes the statement reads, additionalProperties stays open so evidence
-- evolution does not break the declaration. attestation joins the view's required
-- members because the declared read always computes it.
DECLARE @request_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/circuit-view-request.v1.schema.json","title":"Circuit view request","type":"object","additionalProperties":true,"required":["contractId","payload"],"properties":{"contractId":{"const":"circuit-view-request.v1"},"payload":{"type":"object","additionalProperties":true,"required":["capabilityId","cellTestimony","edgeTestimony"],"properties":{"capabilityId":{"type":"string","minLength":1},"cellTestimony":{"type":"array"},"edgeTestimony":{"type":"array"},"granularity":{"type":"string"},"plannedCells":{"type":"array"},"plannedEdges":{"type":"array"}}}}}';
DECLARE @view_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/circuit-view.v1.schema.json","title":"Circuit view","type":"object","additionalProperties":true,"required":["contractId","capabilityId","nodes","edges","attestation"],"properties":{"contractId":{"const":"circuit-view.v1"},"capabilityId":{"type":"string"},"granularity":{"type":"string"},"nodes":{"type":"array","items":{"type":"object","additionalProperties":true,"properties":{"cellId":{"type":"string"},"kind":{"type":"string"},"altitude":{"type":"string"},"label":{"type":["string","null"]},"parentId":{"type":["string","null"]},"status":{"type":["string","null"]},"durationMilliseconds":{"type":["number","null"]},"observedAt":{"type":["string","null"]},"logicalOrder":{"type":["integer","null"]}}}},"edges":{"type":"array","items":{"type":"object","additionalProperties":true,"properties":{"edgeId":{"type":"string"},"kind":{"type":"string"},"from":{"type":["string","null"]},"to":{"type":["string","null"]},"selected":{"type":"boolean"},"selectsVariant":{"type":["string","null"]},"logicalOrder":{"type":["integer","null"]}}}},"attestation":{"type":"object","additionalProperties":true,"properties":{"structured":{"type":"boolean"},"plannedCells":{"type":"integer"},"observedCells":{"type":"integer"},"unmatchedObserved":{"type":"integer"},"onTakenPathUnobserved":{"type":"integer"},"misses":{"type":"array","items":{"type":"object","additionalProperties":true,"properties":{"cellId":{"type":"string"},"altitude":{"type":["string","null"]}}}},"unselectedPlanned":{"type":"array","items":{"type":"object","additionalProperties":true,"properties":{"cellId":{"type":"string"},"altitude":{"type":["string","null"]},"classification":{"type":"string"}}}},"unmatchedObservedCells":{"type":"array","items":{"type":"object","additionalProperties":true,"properties":{"cellId":{"type":"string"}}}}}}}}';
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
  "meaning":{"intent":"read one invocation''s circuit and its structural attestation from its declared testimony and compiled plan","outcome":"the caller observes the semantic circuit and the attestation: every observed cell maps to the plan, and every planned cell without testimony is named as an on-taken-path miss, an unselected branch fragment or an uninvoked declared subtree, resolved through the declared parentCellId chain when no observed same-altitude relative names it"},
 "cli":' + @cli + N',
 "contracts":' + @contracts + N',
 "scenarios":[{
  "scenarioId":"read-capability-circuit",
  "name":"Read one invocation circuit from its declared testimony and compiled plan",
  "inputId":"circuit-view-request",
  "inputContract":"circuit-view-request.v1",
  "eventId":"circuit-view-requested",
  "eventAuthority":"read-capability-circuit.v1",
  "outcomeId":"circuit-view",
  "outcomeContract":"circuit-view.v1",
  "terminal":true,
  "root":true,
  "given":"one invocation of a declared capability: its cell and edge testimony, its compiled plan and the capability identity",
  "when":"the declared circuit read executes over the testimony and the plan under the reader boundary",
  "then":"the caller observes the semantic circuit and the structural attestation: nodes with statuses verbatim from testimony, edges between observed components, and the named planned-unobserved relation",
  "operations":[{"operationId":"read-capability-circuit.0","kind":"invoke-port","portId":"read-capability-circuit-port"}],
  "portBindings":' + @bindings + N'
 }]
}';
EXEC model.declare_capability_document @document=@document;
EXEC model.declare_capability_document @document=@document;

-- ============================== THE DECLARED DISPLAY TRANSFORMATION ==============================
-- Unchanged from declare-read-capability-circuit.sql: the read's display configuration
-- selects this transformation and it returns the view model (attestation included) as
-- the display document. Re-declared content-addressed so this migration stands alone.
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

-- The two declared ids now carry two versions each; the newest carries the new fields.
SELECT '1_contracts' AS result_set, c.contract_id, COUNT(*) AS versions,
 MAX(CASE WHEN JSON_QUERY(sch.schema_json,'$.properties.payload.properties.plannedCells') IS NOT NULL THEN 1 ELSE 0 END) AS carries_planned_cells,
 MAX(CASE WHEN JSON_QUERY(sch.schema_json,'$.properties.attestation') IS NOT NULL THEN 1 ELSE 0 END) AS carries_attestation
FROM model.contract c
JOIN model.contract_version v ON v.contract_pk=c.contract_pk
JOIN model.schema_object so ON so.schema_object_pk=v.schema_object_pk
JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS schema_json) sch
WHERE c.contract_id IN (N'circuit-view-request.v1',N'circuit-view.v1')
GROUP BY c.contract_id
ORDER BY c.contract_id;

-- The selected definition is the newest contract version for each declared id.
SELECT '2_contract_selection' AS result_set, d.declared_id,
 LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS selected_digest,
 LOWER(CONVERT(varchar(64),v.definition_digest,2)) AS newest_digest,
 CAST(CASE WHEN d.definition_digest=v.definition_digest THEN 1 ELSE 0 END AS bit) AS selected_is_newest
FROM analysis.v_selected_semantic_definition d
JOIN model.contract c ON c.contract_id=d.declared_id AND c.namespace_pk=d.namespace_pk
JOIN model.contract_version v ON v.contract_pk=c.contract_pk
WHERE d.estate_model_pk=@estate AND d.object_kind='CONTRACT'
 AND d.declared_id IN (N'circuit-view-request.v1',N'circuit-view.v1')
 AND v.contract_version_pk=(SELECT MAX(v2.contract_version_pk) FROM model.contract_version v2 WHERE v2.contract_pk=c.contract_pk);

-- The port statement carries the attestation computation; the display transformation travels.
SELECT '3_capability_port' AS result_set, c.capability_id, s.scenario_id, eo.operation_id, p.port_id,
 JSON_VALUE(pd.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 CASE WHEN CHARINDEX(N'CIRCUIT_VIEW_PLANNED_CELLS_INVALID',JSON_QUERY(pd.definition_json,'$.semantics.configuration'))>0 THEN 1 ELSE 0 END AS attestation_declared,
 CASE WHEN CHARINDEX(N'unselected-branch-fragment',JSON_QUERY(pd.definition_json,'$.semantics.configuration'))>0 THEN 1 ELSE 0 END AS classification_declared
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

DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-capability-circuit',0,N'sidefx:capabilities'));
SELECT '4_graph_source' AS result_set, g.root_scenario_id,
 JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.transformationId') AS display_transformation_id,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations')) t WHERE JSON_VALUE(t.value,'$.id')=@transformationId) AS display_transformation_present
FROM analysis.v_capability_graph_source g WHERE g.capability_id=N'read-capability-circuit';

-- The behavioral self-tests: the declared statement itself is executed three times.
-- The sample carries a scenario, an operation, an expression root and a field
-- sub-cell, a provider and a physical cell, one planned-but-never-selected fragment
-- and one planned operation on a route that was never invoked. Positive: structured
-- true, 7 planned / 5 observed / 0 misses, 1 unselected-branch-fragment + 1
-- uninvoked. Negative: the operation cell's testimony is removed; the observed path
-- still entered its subtree, so it is named in misses and structured is false. Gap
-- negative: the provider leaf's testimony is removed (it has no observed
-- same-altitude relative); the declared parent chain names it, so it is named in
-- misses and structured is false. Against the pre-fix statement this third fixture
-- returned structured true with the provider in unselectedPlanned as
-- uninvoked-declared-subtree (the recorded gap).
DECLARE @stmt nvarchar(max);
SELECT @stmt=js.statement
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') WITH (statement nvarchar(max) '$.statement') js
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=N'sidefx:capability:read-capability-circuit' AND d.declared_id=N'read-capability-circuit-port';
DECLARE @sample_positive nvarchar(max)=N'{"contractId":"circuit-view-request.v1","payload":{"capabilityId":"attestation-self-test","cellTestimony":[{"cellId":"cell:scenario:demo","cellAltitude":"scenario","disposition":"completed","outcomeClassification":"success","durationMilliseconds":5,"completedAt":"2026-09-17T00:00:00.005Z","logicalOrder":0},{"cellId":"cell:mechanic:demo.operation.1:expression.fields.x","cellAltitude":"mechanic","disposition":"completed","durationMilliseconds":1,"completedAt":"2026-09-17T00:00:00.008Z","logicalOrder":5},{"cellId":"cell:mechanic:demo.operation.1","cellAltitude":"mechanic","disposition":"completed","durationMilliseconds":3,"completedAt":"2026-09-17T00:00:00.011Z","logicalOrder":7},{"cellId":"cell:provider:demo.operation.1","cellAltitude":"provider","disposition":"completed","outcomeClassification":"failure","durationMilliseconds":2,"completedAt":"2026-09-17T00:00:00.013Z","logicalOrder":9},{"cellId":"cell:physical:demo.operation.1","cellAltitude":"physical","disposition":"completed","outcomeClassification":"success","durationMilliseconds":2,"completedAt":"2026-09-17T00:00:00.015Z","logicalOrder":11}],"edgeTestimony":[{"edgeId":"edge:sequence:demo:1","sourceCellExecutionId":"execution:graph:demo:cell:mechanic:demo.operation.1:1","destinationCellId":"cell:provider:demo.operation.1","admissionDisposition":"admitted","logicalOrder":8},{"edgeId":"edge:descent:demo.operation.1","sourceCellExecutionId":"execution:graph:demo:cell:provider:demo.operation.1:1","destinationCellId":"cell:physical:demo.operation.1","admissionDisposition":"admitted","logicalOrder":10}],"plannedCells":[{"cellId":"cell:scenario:demo","parentCellId":null,"altitude":"scenario"},{"cellId":"cell:mechanic:demo.operation.1","parentCellId":"cell:scenario:demo","altitude":"mechanic"},{"cellId":"cell:mechanic:demo.operation.1:expression","parentCellId":"cell:mechanic:demo.operation.1","altitude":"mechanic"},{"cellId":"cell:mechanic:demo.operation.1:expression.fields.x","parentCellId":"cell:mechanic:demo.operation.1","altitude":"mechanic"},{"cellId":"cell:provider:demo.operation.1","parentCellId":"cell:mechanic:demo.operation.1","altitude":"provider"},{"cellId":"cell:physical:demo.operation.1","parentCellId":"cell:provider:demo.operation.1","altitude":"physical"},{"cellId":"cell:mechanic:other.operation.9","parentCellId":"cell:scenario:other","altitude":"mechanic"}],"plannedEdges":[]}}';
DECLARE @sample_gap nvarchar(max)=N'{"contractId":"circuit-view-request.v1","payload":{"capabilityId":"attestation-self-test","cellTestimony":[{"cellId":"cell:scenario:demo","cellAltitude":"scenario","disposition":"completed","outcomeClassification":"success","durationMilliseconds":5,"completedAt":"2026-09-17T00:00:00.005Z","logicalOrder":0},{"cellId":"cell:mechanic:demo.operation.1:expression.fields.x","cellAltitude":"mechanic","disposition":"completed","durationMilliseconds":1,"completedAt":"2026-09-17T00:00:00.008Z","logicalOrder":5},{"cellId":"cell:mechanic:demo.operation.1","cellAltitude":"mechanic","disposition":"completed","durationMilliseconds":3,"completedAt":"2026-09-17T00:00:00.011Z","logicalOrder":7},{"cellId":"cell:physical:demo.operation.1","cellAltitude":"physical","disposition":"completed","outcomeClassification":"success","durationMilliseconds":2,"completedAt":"2026-09-17T00:00:00.015Z","logicalOrder":11}],"edgeTestimony":[{"edgeId":"edge:sequence:demo:1","sourceCellExecutionId":"execution:graph:demo:cell:mechanic:demo.operation.1:1","destinationCellId":"cell:provider:demo.operation.1","admissionDisposition":"admitted","logicalOrder":8},{"edgeId":"edge:descent:demo.operation.1","sourceCellExecutionId":"execution:graph:demo:cell:provider:demo.operation.1:1","destinationCellId":"cell:physical:demo.operation.1","admissionDisposition":"admitted","logicalOrder":10}],"plannedCells":[{"cellId":"cell:scenario:demo","parentCellId":null,"altitude":"scenario"},{"cellId":"cell:mechanic:demo.operation.1","parentCellId":"cell:scenario:demo","altitude":"mechanic"},{"cellId":"cell:mechanic:demo.operation.1:expression","parentCellId":"cell:mechanic:demo.operation.1","altitude":"mechanic"},{"cellId":"cell:mechanic:demo.operation.1:expression.fields.x","parentCellId":"cell:mechanic:demo.operation.1","altitude":"mechanic"},{"cellId":"cell:provider:demo.operation.1","parentCellId":"cell:mechanic:demo.operation.1","altitude":"provider"},{"cellId":"cell:physical:demo.operation.1","parentCellId":"cell:provider:demo.operation.1","altitude":"physical"},{"cellId":"cell:mechanic:other.operation.9","parentCellId":"cell:scenario:other","altitude":"mechanic"}],"plannedEdges":[]}}';
DECLARE @sample_negative nvarchar(max)=N'{"contractId":"circuit-view-request.v1","payload":{"capabilityId":"attestation-self-test","cellTestimony":[{"cellId":"cell:scenario:demo","cellAltitude":"scenario","disposition":"completed","outcomeClassification":"success","durationMilliseconds":5,"completedAt":"2026-09-17T00:00:00.005Z","logicalOrder":0},{"cellId":"cell:mechanic:demo.operation.1:expression.fields.x","cellAltitude":"mechanic","disposition":"completed","durationMilliseconds":1,"completedAt":"2026-09-17T00:00:00.008Z","logicalOrder":5},{"cellId":"cell:provider:demo.operation.1","cellAltitude":"provider","disposition":"completed","outcomeClassification":"failure","durationMilliseconds":2,"completedAt":"2026-09-17T00:00:00.013Z","logicalOrder":9},{"cellId":"cell:physical:demo.operation.1","cellAltitude":"physical","disposition":"completed","outcomeClassification":"success","durationMilliseconds":2,"completedAt":"2026-09-17T00:00:00.015Z","logicalOrder":11}],"edgeTestimony":[{"edgeId":"edge:sequence:demo:1","sourceCellExecutionId":"execution:graph:demo:cell:mechanic:demo.operation.1:1","destinationCellId":"cell:provider:demo.operation.1","admissionDisposition":"admitted","logicalOrder":8},{"edgeId":"edge:descent:demo.operation.1","sourceCellExecutionId":"execution:graph:demo:cell:provider:demo.operation.1:1","destinationCellId":"cell:physical:demo.operation.1","admissionDisposition":"admitted","logicalOrder":10}],"plannedCells":[{"cellId":"cell:scenario:demo","parentCellId":null,"altitude":"scenario"},{"cellId":"cell:mechanic:demo.operation.1","parentCellId":"cell:scenario:demo","altitude":"mechanic"},{"cellId":"cell:mechanic:demo.operation.1:expression","parentCellId":"cell:mechanic:demo.operation.1","altitude":"mechanic"},{"cellId":"cell:mechanic:demo.operation.1:expression.fields.x","parentCellId":"cell:mechanic:demo.operation.1","altitude":"mechanic"},{"cellId":"cell:provider:demo.operation.1","parentCellId":"cell:mechanic:demo.operation.1","altitude":"provider"},{"cellId":"cell:physical:demo.operation.1","parentCellId":"cell:provider:demo.operation.1","altitude":"physical"},{"cellId":"cell:mechanic:other.operation.9","parentCellId":"cell:scenario:other","altitude":"mechanic"}],"plannedEdges":[]}}';
DECLARE @view TABLE (value nvarchar(max));
INSERT @view EXEC sp_executesql @stmt,N'@input nvarchar(max), @estate_model_pk bigint',@input=@sample_positive,@estate_model_pk=@estate;
SELECT '5_view_self_test_positive' AS result_set,
 JSON_VALUE(value,'$.contractId') AS contract_id,
 JSON_VALUE(value,'$.attestation.structured') AS structured,
 JSON_VALUE(value,'$.attestation.plannedCells') AS planned_cells,
 JSON_VALUE(value,'$.attestation.observedCells') AS observed_cells,
 JSON_VALUE(value,'$.attestation.unmatchedObserved') AS unmatched_observed,
 JSON_VALUE(value,'$.attestation.onTakenPathUnobserved') AS on_taken_path_unobserved,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.attestation.misses'))) AS misses,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.attestation.unselectedPlanned')) u WHERE JSON_VALUE(u.value,'$.classification')=N'unselected-branch-fragment') AS unselected_branch_fragment,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.attestation.unselectedPlanned')) u WHERE JSON_VALUE(u.value,'$.classification')=N'uninvoked-declared-subtree') AS uninvoked_declared_subtree,
 JSON_QUERY(value,'$.attestation') AS attestation
FROM @view;
DELETE @view;
INSERT @view EXEC sp_executesql @stmt,N'@input nvarchar(max), @estate_model_pk bigint',@input=@sample_negative,@estate_model_pk=@estate;
SELECT '6_view_self_test_negative' AS result_set,
 JSON_VALUE(value,'$.attestation.structured') AS structured,
 JSON_VALUE(value,'$.attestation.onTakenPathUnobserved') AS on_taken_path_unobserved,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.attestation.misses'))) AS misses,
 (SELECT TOP 1 JSON_VALUE(m.value,'$.cellId') FROM OPENJSON(JSON_QUERY(value,'$.attestation.misses')) m) AS first_miss,
 JSON_QUERY(value,'$.attestation') AS attestation
FROM @view;

DELETE @view;
INSERT @view EXEC sp_executesql @stmt,N'@input nvarchar(max), @estate_model_pk bigint',@input=@sample_gap,@estate_model_pk=@estate;
SELECT '6b_view_self_test_gap_negative' AS result_set,
 JSON_VALUE(value,'$.attestation.structured') AS structured,
 JSON_VALUE(value,'$.attestation.onTakenPathUnobserved') AS on_taken_path_unobserved,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.attestation.misses'))) AS misses,
 (SELECT TOP 1 JSON_VALUE(m.value,'$.cellId') FROM OPENJSON(JSON_QUERY(value,'$.attestation.misses')) m) AS first_miss,
 JSON_QUERY(value,'$.attestation') AS attestation
FROM @view;

-- One current definition per declared id: the replay above minted no duplicate
-- capability document, port or transformation.
SELECT '7_current_definitions' AS result_set, d.namespace_id, d.object_kind, d.declared_id, COUNT(*) AS current_definitions
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate
 AND (d.namespace_id=N'sidefx:capability:read-capability-circuit'
  OR (d.namespace_id=N'sidefx:capability-documents' AND d.declared_id=N'read-capability-circuit'))
GROUP BY d.namespace_id,d.object_kind,d.declared_id
ORDER BY d.namespace_id,d.object_kind,d.declared_id;

COMMIT TRANSACTION;
