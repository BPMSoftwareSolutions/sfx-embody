-- declare-observation-projection.sql
--
-- Retirement W4.1 (docs/hand-authored-code-retirement-agent-strategy.md):
-- the observation/drilldown meaning moves out of src/execution-drilldown.mjs and
-- src/semantic-address.mjs into declared authority. The kernel now emits
-- per-event semanticAddress and display.entry on cell and edge testimony (SDA
-- a696fdd, execution-display-entry.schema.json), so:
--
--   * the streamed observations are the declared testimony itself: the sink
--     selects the requested altitudes from the declared readings and forwards
--     the kernel's declared entry, semantic address, timing and evidence; no id
--     is parsed in boot;
--   * this declared read builds the planned-versus-observed overlay and the
--     observed story from the compiled plan, the declared execution authority
--     rows and the testimony. Cells join their declared operation by the
--     authority pointer the plan carries (sourcePointers:
--     executionAuthorities/<scenario>/operations/<index>); fragments inherit the
--     enclosing operation through the declared parentCellId chain; scenario
--     faces come from the declared scenario rows; responsibility ordinals are
--     the declared operation order. No cell id is parsed.
--
-- Recorded reduction (reported by the unit, no workaround taken): fragment cells
-- declare no member path (their semanticAddress/sourcePointers carry the raw
-- JSON pointer only) and kernel-native junction cells declare no mechanicId, so
-- the overlay's additive semanticAddress for those cells omits mechanicPath and
-- the junction mechanicId. The streamed entries (declared display.entry) and the
-- story are unaffected.
--
-- Idempotent: the capability document's digest is the installed-document gate,
-- the contracts are content addressed, and the readings are only added where no
-- readings member exists.
--
-- Authored with the installation disposition after the rollback dry run and the
-- from-transaction preflights passed (evidence/vault-20260916/retirement/w4.1).
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
-- code. It receives @input (the observation-projection-request.v1 request) and
-- returns one JSON observation-projection.v1 value in the value column.
DECLARE @statement nvarchar(max) = N'SET NOCOUNT ON;
DECLARE @payload nvarchar(max)=JSON_QUERY(@input,''$.payload'');
IF @payload IS NULL THROW 51000,''OBSERVATION_PROJECTION_PAYLOAD_REQUIRED'',1;
DECLARE @plan_cells nvarchar(max)=ISNULL(JSON_QUERY(@payload,''$.plan.canonicalGraph.cells''),N''[]'');
DECLARE @plan_edges nvarchar(max)=ISNULL(JSON_QUERY(@payload,''$.plan.canonicalGraph.edges''),N''[]'');
DECLARE @cells_input nvarchar(max)=ISNULL(JSON_QUERY(@payload,''$.cellTestimony''),N''[]'');
DECLARE @edges_input nvarchar(max)=ISNULL(JSON_QUERY(@payload,''$.edgeTestimony''),N''[]'');
DECLARE @scenarios_input nvarchar(max)=JSON_QUERY(@payload,''$.scenarios'');
DECLARE @authorities_input nvarchar(max)=JSON_QUERY(@payload,''$.executionAuthorities'');
IF @scenarios_input IS NULL OR @authorities_input IS NULL THROW 51000,''OBSERVATION_PROJECTION_AUTHORITY_REQUIRED'',1;
DECLARE @scenario_id nvarchar(400)=NULLIF(JSON_VALUE(@payload,''$.scenarioId''),N'''');
DECLARE @graph_id nvarchar(400)=NULLIF(JSON_VALUE(@payload,''$.graphId''),N'''');
DECLARE @canonical_digest nvarchar(300)=NULLIF(JSON_VALUE(@payload,''$.canonicalGraphDigest''),N'''');
DECLARE @observed_digest nvarchar(300)=NULLIF(JSON_VALUE(@payload,''$.observedPathDigest''),N'''');

-- ============================== DECLARED AUTHORITY ROWS ==============================
-- The scenario faces and ordered operations the semantic addresses join against.
DECLARE @scenarioFaces TABLE (scenarioId nvarchar(400) PRIMARY KEY, inputId nvarchar(400), inputContractId nvarchar(400),
 eventId nvarchar(400), eventAuthorityId nvarchar(400), outcomeId nvarchar(400), outcomeContractId nvarchar(400));
INSERT @scenarioFaces
SELECT f.scenarioId,f.inputId,f.inputContractId,f.eventId,f.eventAuthorityId,f.outcomeId,f.outcomeContractId
FROM OPENJSON(@scenarios_input) WITH (scenarioId nvarchar(400) ''$.scenarioId'', inputId nvarchar(400) ''$.input.inputId'',
 inputContractId nvarchar(400) ''$.input.contract.contractId'', eventId nvarchar(400) ''$.event.eventId'',
 eventAuthorityId nvarchar(400) ''$.event.executionAuthorityId'', outcomeId nvarchar(400) ''$.outcome.outcomeId'',
 outcomeContractId nvarchar(400) ''$.outcome.contract.contractId'') f
WHERE f.scenarioId IS NOT NULL;

DECLARE @operations TABLE (rowId int IDENTITY(1,1) PRIMARY KEY, authorityId nvarchar(400), owningScenarioId nvarchar(400), authorityOrder int, operationIndex int,
 ordinal int, kind nvarchar(80), portId nvarchar(400), scenarioId nvarchar(400));
INSERT @operations(authorityId,owningScenarioId,authorityOrder,operationIndex,ordinal,kind,portId,scenarioId)
SELECT auth.id,auth.owningScenarioId,CONVERT(int,a.[key])+1,CONVERT(int,o.[key])+1,CONVERT(int,o.[key])+1,op.kind,op.portId,op.scenarioId
FROM OPENJSON(@authorities_input) a
CROSS APPLY OPENJSON(a.value) WITH (id nvarchar(400) ''$.id'', owningScenarioId nvarchar(400) ''$.owningScenarioId'',
 operations nvarchar(max) ''$.operations'' AS JSON) auth
CROSS APPLY OPENJSON(auth.operations) o
CROSS APPLY OPENJSON(o.value) WITH (kind nvarchar(80) ''$.kind'', portId nvarchar(400) ''$.portId'',
 scenarioId nvarchar(400) ''$.scenarioId'') op
WHERE auth.owningScenarioId IS NOT NULL;
-- The scenario''s declared authority is its last declaration, as the semantic
-- index reads it: a scenario re-declared across composed capabilities keeps the
-- last authority''s ordered operations.
DELETE o FROM @operations o
WHERE EXISTS (SELECT 1 FROM @operations later WHERE later.owningScenarioId=o.owningScenarioId
 AND later.authorityOrder>o.authorityOrder);
DECLARE @parents TABLE (scenarioId nvarchar(400) PRIMARY KEY, parentScenarioId nvarchar(400));
INSERT @parents
SELECT scenarioId,parentScenarioId FROM (
 SELECT o.scenarioId,o.owningScenarioId AS parentScenarioId,
  ROW_NUMBER() OVER (PARTITION BY o.scenarioId ORDER BY o.authorityOrder DESC,o.operationIndex DESC) rn
 FROM @operations o WHERE o.kind=N''invoke-scenario'' AND o.scenarioId IS NOT NULL
) parents WHERE rn=1;

-- ============================== THE COMPILED PLAN ==============================
-- The plan is the declared authority the testimony joins against by
-- semanticAddress. Its configuration names the operation each cell executes.
DECLARE @planned TABLE (
 ordinal int IDENTITY(1,1) PRIMARY KEY,
 sourceIndex int,
 cellId nvarchar(400) NOT NULL UNIQUE,
 altitude nvarchar(40),
 parentCellId nvarchar(400),
 addressString nvarchar(max),
 inputContractId nvarchar(400),
 outcomeContractId nvarchar(400),
 executionAuthorityId nvarchar(400),
 authorityDigest nvarchar(300),
 executionKind nvarchar(80),
 configKind nvarchar(80),
 configPortId nvarchar(400),
 configScenarioId nvarchar(400),
 configOp nvarchar(80),
 sourcePointer nvarchar(max),
 operationCellId nvarchar(400) NULL,
 scenarioId nvarchar(400) NULL,
 responsibilityId nvarchar(400) NULL,
 responsibilityKind nvarchar(80) NULL,
 responsibilityOrdinal int NULL,
 parentScenarioId nvarchar(400) NULL,
 addressJson nvarchar(max) NULL
);
INSERT @planned(sourceIndex,cellId,altitude,parentCellId,addressString,inputContractId,outcomeContractId,executionAuthorityId,
 authorityDigest,executionKind,configKind,configPortId,configScenarioId,configOp,sourcePointer)
SELECT CONVERT(int,j.[key]),c.cellId,c.altitude,c.parentCellId,c.addressString,c.inputContractId,c.outcomeContractId,c.executionAuthorityId,
 c.authorityDigest,c.executionKind,c.configKind,c.configPortId,c.configScenarioId,c.configOp,c.sourcePointer
FROM OPENJSON(@plan_cells) j CROSS APPLY OPENJSON(j.value) WITH (
 cellId nvarchar(400) ''$.cellId'', altitude nvarchar(40) ''$.altitude'', parentCellId nvarchar(400) ''$.parentCellId'',
 addressString nvarchar(max) ''$.semanticAddress'', inputContractId nvarchar(400) ''$.input.contractId'',
 outcomeContractId nvarchar(400) ''$.outcome.contractId'', executionAuthorityId nvarchar(400) ''$.execution.authorityId'',
 authorityDigest nvarchar(300) ''$.execution.authorityDigest'', executionKind nvarchar(80) ''$.execution.kind'',
 configKind nvarchar(80) ''$.execution.configuration.kind'', configPortId nvarchar(400) ''$.execution.configuration.portId'',
 configScenarioId nvarchar(400) ''$.execution.configuration.scenarioId'', configOp nvarchar(80) ''$.execution.configuration.op'',
 sourcePointer nvarchar(max) ''$.sourcePointers[0]'') c
ORDER BY CONVERT(int,j.[key]);

-- The declared mechanic identity: the plan''s required-provider slots name the
-- mechanic each mechanic cell executes; the expression node names it where no
-- slot exists. (A kernel-native junction cell declares neither.)
DECLARE @mechanicIds TABLE (cellId nvarchar(400) PRIMARY KEY, mechanicId nvarchar(200));
INSERT @mechanicIds(cellId,mechanicId)
SELECT m.cellId,m.mechanicId
FROM OPENJSON(JSON_QUERY(@payload,''$.plan.canonicalGraph.requiredProviderSlots'')) s
CROSS APPLY OPENJSON(s.value) WITH (cellId nvarchar(400) ''$.cellId'', mechanicId nvarchar(200) ''$.mechanicId'') m
WHERE m.cellId IS NOT NULL AND m.mechanicId IS NOT NULL;
UPDATE p SET configOp=m.mechanicId FROM @planned p JOIN @mechanicIds m ON m.cellId=p.cellId WHERE p.configOp IS NULL;

-- The nearest enclosing operation cell and scenario cell: the declared
-- parentCellId chain, walked transitively. No cell id is parsed.
DECLARE @operationOwner TABLE (cellId nvarchar(400) PRIMARY KEY, operationCellId nvarchar(400));
;WITH climb AS (
 SELECT p.cellId AS origin, p.cellId AS currentCellId, p.parentCellId, 0 AS depth,
  CASE WHEN p.altitude=N''mechanic'' AND p.configKind IS NOT NULL THEN p.cellId END AS operationCellId
 FROM @planned p
 UNION ALL
 SELECT c.origin, p.cellId, p.parentCellId, c.depth+1,
  CASE WHEN c.operationCellId IS NULL AND p.altitude=N''mechanic'' AND p.configKind IS NOT NULL THEN p.cellId ELSE c.operationCellId END
 FROM climb c JOIN @planned p ON p.cellId=c.parentCellId
 WHERE c.operationCellId IS NULL AND c.depth<64
)
INSERT @operationOwner(cellId,operationCellId)
SELECT origin,MAX(operationCellId) FROM climb WHERE operationCellId IS NOT NULL GROUP BY origin;
UPDATE p SET operationCellId=o.operationCellId FROM @planned p JOIN @operationOwner o ON o.cellId=p.cellId;
DECLARE @scenarioOwner TABLE (cellId nvarchar(400) PRIMARY KEY, scenarioCellId nvarchar(400));
;WITH climbScenario AS (
 SELECT p.cellId AS origin, p.cellId AS currentCellId, p.parentCellId, 0 AS depth,
  CASE WHEN p.altitude=N''scenario'' THEN p.cellId END AS scenarioCellId
 FROM @planned p
 UNION ALL
 SELECT c.origin, p.cellId, p.parentCellId, c.depth+1,
  CASE WHEN c.scenarioCellId IS NULL AND p.altitude=N''scenario'' THEN p.cellId ELSE c.scenarioCellId END
 FROM climbScenario c JOIN @planned p ON p.cellId=c.parentCellId
 WHERE c.scenarioCellId IS NULL AND c.depth<64
)
INSERT @scenarioOwner(cellId,scenarioCellId)
SELECT origin,MAX(scenarioCellId) FROM climbScenario WHERE scenarioCellId IS NOT NULL GROUP BY origin;
UPDATE p SET scenarioId=a.owningScenarioId
FROM @planned p JOIN @scenarioOwner s ON s.cellId=p.cellId JOIN @planned sc ON sc.cellId=s.scenarioCellId
 JOIN OPENJSON(@authorities_input) WITH (id nvarchar(400) ''$.id'', owningScenarioId nvarchar(400) ''$.owningScenarioId'') a
 ON a.id=sc.executionAuthorityId;

-- The declared join: operation cells pair with their declared operation inside
-- their own scenario''s authority by the declared authority pointer the plan
-- carries (`sourcePointers`: executionAuthorities/<scenario>/operations/<index>),
-- which is the operation row''s declared identity. Fragments inherit the
-- enclosing operation through the parent chain. A scenario may declare the same
-- operation more than once; the pointer keeps each occurrence distinct without
-- parsing any cell id.
DECLARE @operationCells TABLE (operationRowId int, cellId nvarchar(400) PRIMARY KEY);
INSERT @operationCells(operationRowId,cellId)
SELECT o.rowId,p.cellId
FROM @planned p JOIN @operations o
 ON p.sourcePointer=N''executionAuthorities/''+o.owningScenarioId+N''/operations/''+CONVERT(nvarchar(10),o.operationIndex-1)
WHERE p.altitude=N''mechanic'' AND p.configKind IS NOT NULL;
UPDATE p SET responsibilityId=COALESCE(o.portId,o.scenarioId),
 responsibilityKind=o.kind, responsibilityOrdinal=o.ordinal
FROM @planned p JOIN @operationCells oc ON oc.cellId=p.cellId JOIN @operations o ON o.rowId=oc.operationRowId;
UPDATE p SET scenarioId=op.scenarioId, responsibilityId=op.responsibilityId, responsibilityKind=op.responsibilityKind,
 responsibilityOrdinal=op.responsibilityOrdinal
FROM @planned p JOIN @planned op ON op.cellId=p.operationCellId
WHERE p.altitude=N''mechanic'' AND p.configKind IS NULL;
UPDATE p SET parentScenarioId=parents.parentScenarioId
FROM @planned p JOIN @parents parents ON parents.scenarioId=p.scenarioId;

-- The structured semantic address per declared altitude.
UPDATE p SET addressJson=(SELECT p.scenarioId AS scenarioId,p.parentScenarioId AS parentScenarioId,
 N''SCENARIO_OUTCOME'' AS semanticRole,
 (SELECT inputId FROM @scenarioFaces f WHERE f.scenarioId=p.scenarioId) AS inputId,
 (SELECT eventId FROM @scenarioFaces f WHERE f.scenarioId=p.scenarioId) AS eventId,
 (SELECT outcomeId FROM @scenarioFaces f WHERE f.scenarioId=p.scenarioId) AS outcomeId,
 (SELECT outcomeContractId FROM @scenarioFaces f WHERE f.scenarioId=p.scenarioId) AS outcomeContractId
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)
FROM @planned p WHERE p.altitude=N''scenario'';
UPDATE p SET addressJson=(SELECT p.scenarioId AS scenarioId,p.parentScenarioId AS parentScenarioId,
 N''EXECUTION_RESPONSIBILITY'' AS semanticRole,p.responsibilityId AS responsibilityId,
 p.responsibilityKind AS responsibilityKind,p.responsibilityOrdinal AS responsibilityOrdinal,
 CAST(NULL AS nvarchar(400)) AS inputId,CAST(NULL AS nvarchar(400)) AS eventId,
 CAST(NULL AS nvarchar(400)) AS outcomeId,CAST(NULL AS nvarchar(400)) AS outcomeContractId
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)
FROM @planned p WHERE p.altitude=N''mechanic'' AND p.configKind IS NOT NULL;
UPDATE p SET addressJson=(SELECT p.scenarioId AS scenarioId,p.parentScenarioId AS parentScenarioId,
 N''MECHANIC'' AS semanticRole,p.responsibilityId AS responsibilityId,p.responsibilityKind AS responsibilityKind,
 p.responsibilityOrdinal AS responsibilityOrdinal,CAST(NULL AS nvarchar(400)) AS inputId,
 CAST(NULL AS nvarchar(400)) AS eventId,CAST(NULL AS nvarchar(400)) AS outcomeId,
 CAST(NULL AS nvarchar(400)) AS outcomeContractId,p.configOp AS mechanicId,CAST(NULL AS nvarchar(400)) AS mechanicPath
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)
FROM @planned p WHERE p.altitude=N''mechanic'' AND p.configKind IS NULL;

-- ============================== OBSERVED TESTIMONY ==============================
DECLARE @cells TABLE (
 arrayIndex int,cellId nvarchar(400),cellAltitude nvarchar(40),addressString nvarchar(max),
 disposition nvarchar(40),outcomeVariant nvarchar(120),outcomeContractId nvarchar(400),
 cellExecutionId nvarchar(400),parentCellExecutionId nvarchar(400),selectedEdgeIds nvarchar(max),
 logicalOrder int,startedAt nvarchar(60),completedAt nvarchar(60),durationMilliseconds decimal(18,3));
INSERT @cells(arrayIndex,cellId,cellAltitude,addressString,disposition,outcomeVariant,outcomeContractId,cellExecutionId,parentCellExecutionId,selectedEdgeIds,logicalOrder,startedAt,completedAt,durationMilliseconds)
SELECT CONVERT(int,j.[key]),c.cellId,c.cellAltitude,c.addressString,c.disposition,c.outcomeVariant,c.outcomeContractId,
 c.cellExecutionId,c.parentCellExecutionId,c.selectedEdgeIds,c.logicalOrder,c.startedAt,c.completedAt,c.durationMilliseconds
FROM OPENJSON(@cells_input) j CROSS APPLY OPENJSON(j.value) WITH (
 cellId nvarchar(400) ''$.cellId'',cellAltitude nvarchar(40) ''$.cellAltitude'',addressString nvarchar(max) ''$.semanticAddress'',
 disposition nvarchar(40) ''$.disposition'',outcomeVariant nvarchar(120) ''$.outcomeVariant'',
 outcomeContractId nvarchar(400) ''$.outcomeContractId'',cellExecutionId nvarchar(400) ''$.cellExecutionId'',
 parentCellExecutionId nvarchar(400) ''$.parentCellExecutionId'',selectedEdgeIds nvarchar(max) ''$.selectedEdgeIds'' AS JSON,
 logicalOrder int ''$.logicalOrder'',startedAt nvarchar(60) ''$.startedAt'',completedAt nvarchar(60) ''$.completedAt'',
 durationMilliseconds decimal(18,3) ''$.durationMilliseconds'') c
ORDER BY CONVERT(int,j.[key]);
DECLARE @edges TABLE (
 arrayIndex int,edgeId nvarchar(400),addressString nvarchar(max),destinationCellId nvarchar(400),
 sourceCellExecutionId nvarchar(400),admissionDisposition nvarchar(40),logicalOrder int,
 startedAt nvarchar(60),completedAt nvarchar(60),durationMilliseconds decimal(18,3));
INSERT @edges(arrayIndex,edgeId,addressString,destinationCellId,sourceCellExecutionId,admissionDisposition,logicalOrder,startedAt,completedAt,durationMilliseconds)
SELECT CONVERT(int,j.[key]),e.edgeId,e.addressString,e.destinationCellId,e.sourceCellExecutionId,e.admissionDisposition,
 e.logicalOrder,e.startedAt,e.completedAt,e.durationMilliseconds
FROM OPENJSON(@edges_input) j CROSS APPLY OPENJSON(j.value) WITH (
 edgeId nvarchar(400) ''$.edgeId'',addressString nvarchar(max) ''$.semanticAddress'',destinationCellId nvarchar(400) ''$.destinationCellId'',
 sourceCellExecutionId nvarchar(400) ''$.sourceCellExecutionId'',admissionDisposition nvarchar(40) ''$.admissionDisposition'',
 logicalOrder int ''$.logicalOrder'',startedAt nvarchar(60) ''$.startedAt'',completedAt nvarchar(60) ''$.completedAt'',
 durationMilliseconds decimal(18,3) ''$.durationMilliseconds'') e
ORDER BY CONVERT(int,j.[key]);
DECLARE @plannedEdges TABLE (
 ordinal int IDENTITY(1,1) PRIMARY KEY,
 sourceIndex int,
 edgeId nvarchar(400),kind nvarchar(80),fromJson nvarchar(max),toJson nvarchar(max),
 selectsVariant nvarchar(120),destinationCellId nvarchar(400),destinationAddressJson nvarchar(max));
INSERT @plannedEdges(sourceIndex,edgeId,kind,fromJson,toJson,selectsVariant,destinationCellId,destinationAddressJson)
SELECT CONVERT(int,j.[key]),e.edgeId,e.kind,e.fromJson,e.toJson,e.selectsVariant,
 COALESCE(JSON_VALUE(e.toJson,''$.cellId''),e.toJson),p.addressJson
FROM OPENJSON(@plan_edges) j CROSS APPLY OPENJSON(j.value) WITH (
 edgeId nvarchar(400) ''$.edgeId'',kind nvarchar(80) ''$.kind'',fromJson nvarchar(max) ''$.from'' AS JSON,
 toJson nvarchar(max) ''$.to'' AS JSON,selectsVariant nvarchar(120) ''$.selectsVariant'') e
LEFT JOIN @planned p ON p.cellId=COALESCE(JSON_VALUE(e.toJson,''$.cellId''),e.toJson)
ORDER BY CONVERT(int,j.[key]);
DECLARE @firstCell TABLE (addressString nvarchar(max),cellId nvarchar(400),disposition nvarchar(40),
 outcomeVariant nvarchar(120),outcomeContractId nvarchar(400),durationMilliseconds decimal(18,3),logicalOrder int,arrayIndex int);
INSERT @firstCell
SELECT addressString,cellId,disposition,outcomeVariant,outcomeContractId,durationMilliseconds,logicalOrder,arrayIndex
FROM (SELECT *,ROW_NUMBER() OVER (PARTITION BY cellId ORDER BY arrayIndex) rn FROM @cells) x WHERE rn=1;

-- ============================== OVERLAY ==============================
DECLARE @overlay_cells nvarchar(max)=N''[''+ISNULL((
 SELECT STRING_AGG(rowJson,N'','') WITHIN GROUP (ORDER BY ord)
 FROM (
  SELECT ((SELECT p.cellId AS cellId,p.altitude AS altitude,p.parentCellId AS parentCellId,
    JSON_QUERY(p.addressJson) AS semanticAddress,
    JSON_QUERY((SELECT p.inputContractId AS inputContractId,p.outcomeContractId AS outcomeContractId,
      p.executionAuthorityId AS executionAuthorityId,p.authorityDigest AS authorityDigest
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS planned,
    JSON_QUERY(ISNULL((SELECT c.cellExecutionId AS cellExecutionId,c.disposition AS disposition,c.outcomeVariant AS outcomeVariant,
      JSON_QUERY(c.selectedEdgeIds) AS selectedEdgeIds,c.outcomeContractId AS outcomeContractId,
      c.logicalOrder AS logicalOrder,c.startedAt AS startedAt,c.completedAt AS completedAt,
      c.durationMilliseconds AS durationMilliseconds
     FROM @cells c WHERE c.cellId=p.cellId ORDER BY c.arrayIndex
     FOR JSON PATH,INCLUDE_NULL_VALUES),N''[]'')) AS observed
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS rowJson,p.sourceIndex AS ord
  FROM @planned p
 ) plannedrows
),N'''')+N'']'';
DECLARE @observed_only_cells nvarchar(max)=N''[''+ISNULL((
 SELECT STRING_AGG(rowJson,N'','') WITHIN GROUP (ORDER BY ord)
 FROM (
  SELECT ((SELECT c.cellId AS cellId,c.cellAltitude AS altitude,CAST(NULL AS nvarchar(400)) AS parentCellId,
    CAST(NULL AS nvarchar(max)) AS semanticAddress,CAST(NULL AS nvarchar(max)) AS planned,
    JSON_QUERY(ISNULL((SELECT o.cellExecutionId AS cellExecutionId,o.disposition AS disposition,o.outcomeVariant AS outcomeVariant,
      JSON_QUERY(o.selectedEdgeIds) AS selectedEdgeIds,o.outcomeContractId AS outcomeContractId,
      o.logicalOrder AS logicalOrder,o.startedAt AS startedAt,o.completedAt AS completedAt,
      o.durationMilliseconds AS durationMilliseconds
     FROM @cells o WHERE o.cellId=c.cellId ORDER BY o.arrayIndex
     FOR JSON PATH,INCLUDE_NULL_VALUES),N''[]'')) AS observed
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS rowJson,c.arrayIndex AS ord
  FROM (SELECT c.cellId,c.cellAltitude,c.arrayIndex FROM @cells c
    WHERE NOT EXISTS (SELECT 1 FROM @planned p WHERE p.cellId=c.cellId)
    AND c.arrayIndex=(SELECT MIN(c2.arrayIndex) FROM @cells c2 WHERE c2.cellId=c.cellId)) c
 ) observedrows
),N'''')+N'']'';
DECLARE @overlay_edges nvarchar(max)=N''[''+ISNULL((
 SELECT STRING_AGG(rowJson,N'','') WITHIN GROUP (ORDER BY ord)
 FROM (
  SELECT ((SELECT e.edgeId AS edgeId,e.kind AS kind,JSON_QUERY(e.destinationAddressJson) AS semanticAddress,
    JSON_QUERY((SELECT JSON_QUERY(e.fromJson) AS [from],JSON_QUERY(e.toJson) AS [to],e.selectsVariant AS selectsVariant
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS planned,
    JSON_QUERY(ISNULL((SELECT t.sourceCellExecutionId AS sourceCellExecutionId,t.destinationCellId AS destinationCellId,
      t.admissionDisposition AS admissionDisposition,t.logicalOrder AS logicalOrder,t.startedAt AS startedAt,
      t.completedAt AS completedAt,t.durationMilliseconds AS durationMilliseconds
     FROM @edges t WHERE t.edgeId=e.edgeId ORDER BY t.arrayIndex
     FOR JSON PATH,INCLUDE_NULL_VALUES),N''[]'')) AS observed
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS rowJson,e.sourceIndex AS ord
  FROM @plannedEdges e
 ) plannedrows
),N'''')+N'']'';
DECLARE @observed_only_edges nvarchar(max)=N''[''+ISNULL((
 SELECT STRING_AGG(rowJson,N'','') WITHIN GROUP (ORDER BY ord)
 FROM (
  SELECT ((SELECT t.edgeId AS edgeId,CAST(NULL AS nvarchar(80)) AS kind,JSON_QUERY(p.addressJson) AS semanticAddress,
    CAST(NULL AS nvarchar(max)) AS planned,
    JSON_QUERY(ISNULL((SELECT o.sourceCellExecutionId AS sourceCellExecutionId,o.destinationCellId AS destinationCellId,
      o.admissionDisposition AS admissionDisposition,o.logicalOrder AS logicalOrder,o.startedAt AS startedAt,
      o.completedAt AS completedAt,o.durationMilliseconds AS durationMilliseconds
     FROM @edges o WHERE o.edgeId=t.edgeId ORDER BY o.arrayIndex
     FOR JSON PATH,INCLUDE_NULL_VALUES),N''[]'')) AS observed
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS rowJson,t.arrayIndex AS ord
  FROM (SELECT t.edgeId,t.destinationCellId,t.arrayIndex FROM @edges t
    WHERE NOT EXISTS (SELECT 1 FROM @plannedEdges p WHERE p.edgeId=t.edgeId)
    AND t.arrayIndex=(SELECT MIN(t2.arrayIndex) FROM @edges t2 WHERE t2.edgeId=t.edgeId)) t
  LEFT JOIN @planned p ON p.cellId=t.destinationCellId
 ) observedrows
),N'''')+N'']'';
DECLARE @counts nvarchar(max)=(SELECT
 (SELECT COUNT(*) FROM @planned) AS plannedCells,
 (SELECT COUNT(*) FROM (SELECT DISTINCT cellId,cellExecutionId FROM @cells) x) AS observedCells,
 (SELECT COUNT(*) FROM @plannedEdges) AS plannedEdges,
 (SELECT COUNT(*) FROM (SELECT DISTINCT edgeId,logicalOrder FROM @edges) x) AS observedEdges
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
DECLARE @overlay nvarchar(max)=(
 SELECT @graph_id AS graphId,@canonical_digest AS canonicalGraphDigest,@observed_digest AS observedPathDigest,
  JSON_QUERY(@overlay_cells+@observed_only_cells) AS cells,
  JSON_QUERY(@overlay_edges+@observed_only_edges) AS edges,
  JSON_QUERY(@counts) AS counts
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);

-- ============================== STORY ==============================
DECLARE @responsibility TABLE (ordinal int IDENTITY(1,1) PRIMARY KEY,scenarioId nvarchar(400),
 parentScenarioId nvarchar(400),semanticRole nvarchar(40),responsibilityId nvarchar(400),
 responsibilityKind nvarchar(80),responsibilityOrdinal int,inputId nvarchar(400),eventId nvarchar(400),
 outcomeId nvarchar(400),outcomeContractId nvarchar(400),disposition nvarchar(40),
 outcomeVariant nvarchar(120),durationMilliseconds decimal(18,3),logicalOrder int);
INSERT @responsibility(scenarioId,parentScenarioId,semanticRole,responsibilityId,responsibilityKind,responsibilityOrdinal,
 inputId,eventId,outcomeId,outcomeContractId,disposition,outcomeVariant,durationMilliseconds,logicalOrder)
SELECT o.owningScenarioId,parents.parentScenarioId,N''EXECUTION_RESPONSIBILITY'',COALESCE(o.portId,o.scenarioId),
 o.kind,o.ordinal,NULL,NULL,NULL,t.outcomeContractId,t.disposition,t.outcomeVariant,t.durationMilliseconds,t.logicalOrder
FROM @operations o
JOIN @operationCells oc ON oc.operationRowId=o.rowId
JOIN @firstCell t ON t.cellId=oc.cellId
LEFT JOIN @parents parents ON parents.scenarioId=o.owningScenarioId;
DECLARE @scenarioOrder TABLE (scenarioId nvarchar(400) PRIMARY KEY,firstOrder int);
INSERT @scenarioOrder SELECT scenarioId,MIN(logicalOrder) FROM @responsibility GROUP BY scenarioId;
DECLARE @rootScenarioId nvarchar(400)=@scenario_id;
IF @rootScenarioId IS NULL OR NOT EXISTS(SELECT 1 FROM @scenarioOrder WHERE scenarioId=@rootScenarioId)
 SET @rootScenarioId=(SELECT TOP 1 scenarioId FROM @scenarioOrder ORDER BY firstOrder);
DECLARE @responsibilities_json nvarchar(max)=N''{"scenarioId":{"op":"none"}}'';
DECLARE @story_root nvarchar(max)=(SELECT f.scenarioId AS scenarioId,parents.parentScenarioId AS parentScenarioId,
  f.inputId AS inputId,f.inputContractId AS inputContractId,f.eventId AS eventId,f.eventAuthorityId AS eventAuthorityId,
  f.outcomeId AS outcomeId,f.outcomeContractId AS outcomeContractId,
  JSON_QUERY((SELECT r.scenarioId AS scenarioId,r.parentScenarioId AS parentScenarioId,
    r.semanticRole AS semanticRole,r.responsibilityId AS responsibilityId,r.responsibilityKind AS responsibilityKind,
    r.responsibilityOrdinal AS responsibilityOrdinal,r.inputId AS inputId,r.eventId AS eventId,r.outcomeId AS outcomeId,
    r.outcomeContractId AS outcomeContractId,r.disposition AS disposition,r.outcomeVariant AS outcomeVariant,
    r.durationMilliseconds AS durationMilliseconds
   FROM @responsibility r WHERE r.scenarioId=f.scenarioId ORDER BY r.responsibilityOrdinal
   FOR JSON PATH,INCLUDE_NULL_VALUES)) AS responsibilities
 FROM @scenarioFaces f LEFT JOIN @parents parents ON parents.scenarioId=f.scenarioId
 WHERE f.scenarioId=ISNULL(@rootScenarioId,N'''')
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
IF @story_root IS NULL SET @story_root=(SELECT (SELECT f.scenarioId AS scenarioId,parents.parentScenarioId AS parentScenarioId,
  f.inputId AS inputId,f.inputContractId AS inputContractId,f.eventId AS eventId,f.eventAuthorityId AS eventAuthorityId,
  f.outcomeId AS outcomeId,f.outcomeContractId AS outcomeContractId,JSON_QUERY(N''[]'') AS responsibilities
 FROM @scenarioFaces f LEFT JOIN @parents parents ON parents.scenarioId=f.scenarioId
 WHERE f.scenarioId=@scenario_id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES));
DECLARE @composed nvarchar(max)=(SELECT f.scenarioId AS scenarioId,parents.parentScenarioId AS parentScenarioId,
  f.inputId AS inputId,f.inputContractId AS inputContractId,f.eventId AS eventId,f.eventAuthorityId AS eventAuthorityId,
  f.outcomeId AS outcomeId,f.outcomeContractId AS outcomeContractId,
  JSON_QUERY((SELECT r.scenarioId AS scenarioId,r.parentScenarioId AS parentScenarioId,
    r.semanticRole AS semanticRole,r.responsibilityId AS responsibilityId,r.responsibilityKind AS responsibilityKind,
    r.responsibilityOrdinal AS responsibilityOrdinal,r.inputId AS inputId,r.eventId AS eventId,r.outcomeId AS outcomeId,
    r.outcomeContractId AS outcomeContractId,r.disposition AS disposition,r.outcomeVariant AS outcomeVariant,
    r.durationMilliseconds AS durationMilliseconds
   FROM @responsibility r WHERE r.scenarioId=f.scenarioId ORDER BY r.responsibilityOrdinal
   FOR JSON PATH,INCLUDE_NULL_VALUES)) AS responsibilities
 FROM @scenarioOrder s JOIN @scenarioFaces f ON f.scenarioId=s.scenarioId
 LEFT JOIN @parents parents ON parents.scenarioId=s.scenarioId
 WHERE s.scenarioId<>ISNULL(@rootScenarioId,N'''')
 ORDER BY s.firstOrder
 FOR JSON PATH,INCLUDE_NULL_VALUES);
DECLARE @story nvarchar(max)=CASE WHEN @composed IS NULL
 THEN (SELECT JSON_QUERY(@story_root) AS scenario,@observed_digest AS observedPathDigest
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)
 ELSE (SELECT JSON_QUERY(@story_root) AS scenario,JSON_QUERY(@composed) AS composedScenarios,@observed_digest AS observedPathDigest
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) END;

SELECT (SELECT N''observation-projection.v1'' AS projectionType,JSON_QUERY(@overlay) AS overlay,JSON_QUERY(@story) AS story
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) AS value;';
DECLARE @bindings nvarchar(max) = N'[{"portId":"read-observation-projection-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,N'json') + N'","resultColumn":"value"}}]';

-- ============================== CONTRACTS AND CAPABILITY DOCUMENT ==============================
DECLARE @document nvarchar(max) = N'{"document":"sidefx-capability-authority.v1","capabilityId":"read-observation-projection","meaning":{"intent":"read the declared observation projection of one invocation","outcome":"the caller observes the planned-versus-observed overlay and the observed story, joined from declared authority rows and the kernel testimony semantic addresses"},"contracts":[{"id":"observation-projection-request.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/observation-projection-request.v1.schema.json","title":"Observation projection request","type":"object","additionalProperties":false,"required":["contractId","payload"],"properties":{"contractId":{"const":"observation-projection-request.v1"},"payload":{"type":"object","additionalProperties":true}}}},{"id":"observation-projection.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/observation-projection.v1.schema.json","title":"Observation projection","type":"object","additionalProperties":true,"required":["projectionType","overlay","story"],"properties":{"projectionType":{"const":"observation-projection.v1"},"overlay":{"type":"object"},"story":{"type":"object"}}}}],"scenarios":[{"scenarioId":"read-observation-projection","name":"Read the observation projection","inputId":"observation-projection-request","inputContract":"observation-projection-request.v1","eventId":"observation-projection-requested","eventAuthority":"read-observation-projection.v1","outcomeId":"observation-projection","outcomeContract":"observation-projection.v1","terminal":true,"root":true,"given":"one invocation''s compiled plan, declared execution authority and kernel testimony","when":"the declared projection read executes under the reader boundary","then":"the reading names the planned and observed cells and edges with their declared semantic addresses and the observed story","operations":[{"operationId":"read-observation-projection.0","kind":"invoke-port","portId":"read-observation-projection-port"}],"portBindings":[{"portId":"read-observation-projection-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"SET NOCOUNT ON;\nDECLARE @payload nvarchar(max)=JSON_QUERY(@input,''$.payload'');\nIF @payload IS NULL THROW 51000,''OBSERVATION_PROJECTION_PAYLOAD_REQUIRED'',1;\nDECLARE @plan_cells nvarchar(max)=ISNULL(JSON_QUERY(@payload,''$.plan.canonicalGraph.cells''),N''[]'');\nDECLARE @plan_edges nvarchar(max)=ISNULL(JSON_QUERY(@payload,''$.plan.canonicalGraph.edges''),N''[]'');\nDECLARE @cells_input nvarchar(max)=ISNULL(JSON_QUERY(@payload,''$.cellTestimony''),N''[]'');\nDECLARE @edges_input nvarchar(max)=ISNULL(JSON_QUERY(@payload,''$.edgeTestimony''),N''[]'');\nDECLARE @scenarios_input nvarchar(max)=JSON_QUERY(@payload,''$.scenarios'');\nDECLARE @authorities_input nvarchar(max)=JSON_QUERY(@payload,''$.executionAuthorities'');\nIF @scenarios_input IS NULL OR @authorities_input IS NULL THROW 51000,''OBSERVATION_PROJECTION_AUTHORITY_REQUIRED'',1;\nDECLARE @scenario_id nvarchar(400)=NULLIF(JSON_VALUE(@payload,''$.scenarioId''),N'''');\nDECLARE @graph_id nvarchar(400)=NULLIF(JSON_VALUE(@payload,''$.graphId''),N'''');\nDECLARE @canonical_digest nvarchar(300)=NULLIF(JSON_VALUE(@payload,''$.canonicalGraphDigest''),N'''');\nDECLARE @observed_digest nvarchar(300)=NULLIF(JSON_VALUE(@payload,''$.observedPathDigest''),N'''');\n\n-- ============================== DECLARED AUTHORITY ROWS ==============================\n-- The scenario faces and ordered operations the semantic addresses join against.\nDECLARE @scenarioFaces TABLE (scenarioId nvarchar(400) PRIMARY KEY, inputId nvarchar(400), inputContractId nvarchar(400),\n eventId nvarchar(400), eventAuthorityId nvarchar(400), outcomeId nvarchar(400), outcomeContractId nvarchar(400));\nINSERT @scenarioFaces\nSELECT f.scenarioId,f.inputId,f.inputContractId,f.eventId,f.eventAuthorityId,f.outcomeId,f.outcomeContractId\nFROM OPENJSON(@scenarios_input) WITH (scenarioId nvarchar(400) ''$.scenarioId'', inputId nvarchar(400) ''$.input.inputId'',\n inputContractId nvarchar(400) ''$.input.contract.contractId'', eventId nvarchar(400) ''$.event.eventId'',\n eventAuthorityId nvarchar(400) ''$.event.executionAuthorityId'', outcomeId nvarchar(400) ''$.outcome.outcomeId'',\n outcomeContractId nvarchar(400) ''$.outcome.contract.contractId'') f\nWHERE f.scenarioId IS NOT NULL;\n\nDECLARE @operations TABLE (rowId int IDENTITY(1,1) PRIMARY KEY, authorityId nvarchar(400), owningScenarioId nvarchar(400), authorityOrder int, operationIndex int,\n ordinal int, kind nvarchar(80), portId nvarchar(400), scenarioId nvarchar(400));\nINSERT @operations(authorityId,owningScenarioId,authorityOrder,operationIndex,ordinal,kind,portId,scenarioId)\nSELECT auth.id,auth.owningScenarioId,CONVERT(int,a.[key])+1,CONVERT(int,o.[key])+1,CONVERT(int,o.[key])+1,op.kind,op.portId,op.scenarioId\nFROM OPENJSON(@authorities_input) a\nCROSS APPLY OPENJSON(a.value) WITH (id nvarchar(400) ''$.id'', owningScenarioId nvarchar(400) ''$.owningScenarioId'',\n operations nvarchar(max) ''$.operations'' AS JSON) auth\nCROSS APPLY OPENJSON(auth.operations) o\nCROSS APPLY OPENJSON(o.value) WITH (kind nvarchar(80) ''$.kind'', portId nvarchar(400) ''$.portId'',\n scenarioId nvarchar(400) ''$.scenarioId'') op\nWHERE auth.owningScenarioId IS NOT NULL;\n-- The scenario''s declared authority is its last declaration, as the semantic\n-- index reads it: a scenario re-declared across composed capabilities keeps the\n-- last authority''s ordered operations.\nDELETE o FROM @operations o\nWHERE EXISTS (SELECT 1 FROM @operations later WHERE later.owningScenarioId=o.owningScenarioId\n AND later.authorityOrder>o.authorityOrder);\nDECLARE @parents TABLE (scenarioId nvarchar(400) PRIMARY KEY, parentScenarioId nvarchar(400));\nINSERT @parents\nSELECT scenarioId,parentScenarioId FROM (\n SELECT o.scenarioId,o.owningScenarioId AS parentScenarioId,\n  ROW_NUMBER() OVER (PARTITION BY o.scenarioId ORDER BY o.authorityOrder DESC,o.operationIndex DESC) rn\n FROM @operations o WHERE o.kind=N''invoke-scenario'' AND o.scenarioId IS NOT NULL\n) parents WHERE rn=1;\n\n-- ============================== THE COMPILED PLAN ==============================\n-- The plan is the declared authority the testimony joins against by\n-- semanticAddress. Its configuration names the operation each cell executes.\nDECLARE @planned TABLE (\n ordinal int IDENTITY(1,1) PRIMARY KEY,\n sourceIndex int,\n cellId nvarchar(400) NOT NULL UNIQUE,\n altitude nvarchar(40),\n parentCellId nvarchar(400),\n addressString nvarchar(max),\n inputContractId nvarchar(400),\n outcomeContractId nvarchar(400),\n executionAuthorityId nvarchar(400),\n authorityDigest nvarchar(300),\n executionKind nvarchar(80),\n configKind nvarchar(80),\n configPortId nvarchar(400),\n configScenarioId nvarchar(400),\n configOp nvarchar(80),\n sourcePointer nvarchar(max),\n operationCellId nvarchar(400) NULL,\n scenarioId nvarchar(400) NULL,\n responsibilityId nvarchar(400) NULL,\n responsibilityKind nvarchar(80) NULL,\n responsibilityOrdinal int NULL,\n parentScenarioId nvarchar(400) NULL,\n addressJson nvarchar(max) NULL\n);\nINSERT @planned(sourceIndex,cellId,altitude,parentCellId,addressString,inputContractId,outcomeContractId,executionAuthorityId,\n authorityDigest,executionKind,configKind,configPortId,configScenarioId,configOp,sourcePointer)\nSELECT CONVERT(int,j.[key]),c.cellId,c.altitude,c.parentCellId,c.addressString,c.inputContractId,c.outcomeContractId,c.executionAuthorityId,\n c.authorityDigest,c.executionKind,c.configKind,c.configPortId,c.configScenarioId,c.configOp,c.sourcePointer\nFROM OPENJSON(@plan_cells) j CROSS APPLY OPENJSON(j.value) WITH (\n cellId nvarchar(400) ''$.cellId'', altitude nvarchar(40) ''$.altitude'', parentCellId nvarchar(400) ''$.parentCellId'',\n addressString nvarchar(max) ''$.semanticAddress'', inputContractId nvarchar(400) ''$.input.contractId'',\n outcomeContractId nvarchar(400) ''$.outcome.contractId'', executionAuthorityId nvarchar(400) ''$.execution.authorityId'',\n authorityDigest nvarchar(300) ''$.execution.authorityDigest'', executionKind nvarchar(80) ''$.execution.kind'',\n configKind nvarchar(80) ''$.execution.configuration.kind'', configPortId nvarchar(400) ''$.execution.configuration.portId'',\n configScenarioId nvarchar(400) ''$.execution.configuration.scenarioId'', configOp nvarchar(80) ''$.execution.configuration.op'',\n sourcePointer nvarchar(max) ''$.sourcePointers[0]'') c\nORDER BY CONVERT(int,j.[key]);\n\n-- The declared mechanic identity: the plan''s required-provider slots name the\n-- mechanic each mechanic cell executes; the expression node names it where no\n-- slot exists. (A kernel-native junction cell declares neither.)\nDECLARE @mechanicIds TABLE (cellId nvarchar(400) PRIMARY KEY, mechanicId nvarchar(200));\nINSERT @mechanicIds(cellId,mechanicId)\nSELECT m.cellId,m.mechanicId\nFROM OPENJSON(JSON_QUERY(@payload,''$.plan.canonicalGraph.requiredProviderSlots'')) s\nCROSS APPLY OPENJSON(s.value) WITH (cellId nvarchar(400) ''$.cellId'', mechanicId nvarchar(200) ''$.mechanicId'') m\nWHERE m.cellId IS NOT NULL AND m.mechanicId IS NOT NULL;\nUPDATE p SET configOp=m.mechanicId FROM @planned p JOIN @mechanicIds m ON m.cellId=p.cellId WHERE p.configOp IS NULL;\n\n-- The nearest enclosing operation cell and scenario cell: the declared\n-- parentCellId chain, walked transitively. No cell id is parsed.\nDECLARE @operationOwner TABLE (cellId nvarchar(400) PRIMARY KEY, operationCellId nvarchar(400));\n;WITH climb AS (\n SELECT p.cellId AS origin, p.cellId AS currentCellId, p.parentCellId, 0 AS depth,\n  CASE WHEN p.altitude=N''mechanic'' AND p.configKind IS NOT NULL THEN p.cellId END AS operationCellId\n FROM @planned p\n UNION ALL\n SELECT c.origin, p.cellId, p.parentCellId, c.depth+1,\n  CASE WHEN c.operationCellId IS NULL AND p.altitude=N''mechanic'' AND p.configKind IS NOT NULL THEN p.cellId ELSE c.operationCellId END\n FROM climb c JOIN @planned p ON p.cellId=c.parentCellId\n WHERE c.operationCellId IS NULL AND c.depth<64\n)\nINSERT @operationOwner(cellId,operationCellId)\nSELECT origin,MAX(operationCellId) FROM climb WHERE operationCellId IS NOT NULL GROUP BY origin;\nUPDATE p SET operationCellId=o.operationCellId FROM @planned p JOIN @operationOwner o ON o.cellId=p.cellId;\nDECLARE @scenarioOwner TABLE (cellId nvarchar(400) PRIMARY KEY, scenarioCellId nvarchar(400));\n;WITH climbScenario AS (\n SELECT p.cellId AS origin, p.cellId AS currentCellId, p.parentCellId, 0 AS depth,\n  CASE WHEN p.altitude=N''scenario'' THEN p.cellId END AS scenarioCellId\n FROM @planned p\n UNION ALL\n SELECT c.origin, p.cellId, p.parentCellId, c.depth+1,\n  CASE WHEN c.scenarioCellId IS NULL AND p.altitude=N''scenario'' THEN p.cellId ELSE c.scenarioCellId END\n FROM climbScenario c JOIN @planned p ON p.cellId=c.parentCellId\n WHERE c.scenarioCellId IS NULL AND c.depth<64\n)\nINSERT @scenarioOwner(cellId,scenarioCellId)\nSELECT origin,MAX(scenarioCellId) FROM climbScenario WHERE scenarioCellId IS NOT NULL GROUP BY origin;\nUPDATE p SET scenarioId=a.owningScenarioId\nFROM @planned p JOIN @scenarioOwner s ON s.cellId=p.cellId JOIN @planned sc ON sc.cellId=s.scenarioCellId\n JOIN OPENJSON(@authorities_input) WITH (id nvarchar(400) ''$.id'', owningScenarioId nvarchar(400) ''$.owningScenarioId'') a\n ON a.id=sc.executionAuthorityId;\n\n-- The declared join: operation cells pair with their declared operation inside\n-- their own scenario''s authority by the declared authority pointer the plan\n-- carries (`sourcePointers`: executionAuthorities/<scenario>/operations/<index>),\n-- which is the operation row''s declared identity. Fragments inherit the\n-- enclosing operation through the parent chain. A scenario may declare the same\n-- operation more than once; the pointer keeps each occurrence distinct without\n-- parsing any cell id.\nDECLARE @operationCells TABLE (operationRowId int, cellId nvarchar(400) PRIMARY KEY);\nINSERT @operationCells(operationRowId,cellId)\nSELECT o.rowId,p.cellId\nFROM @planned p JOIN @operations o\n ON p.sourcePointer=N''executionAuthorities/''+o.owningScenarioId+N''/operations/''+CONVERT(nvarchar(10),o.operationIndex-1)\nWHERE p.altitude=N''mechanic'' AND p.configKind IS NOT NULL;\nUPDATE p SET responsibilityId=COALESCE(o.portId,o.scenarioId),\n responsibilityKind=o.kind, responsibilityOrdinal=o.ordinal\nFROM @planned p JOIN @operationCells oc ON oc.cellId=p.cellId JOIN @operations o ON o.rowId=oc.operationRowId;\nUPDATE p SET scenarioId=op.scenarioId, responsibilityId=op.responsibilityId, responsibilityKind=op.responsibilityKind,\n responsibilityOrdinal=op.responsibilityOrdinal\nFROM @planned p JOIN @planned op ON op.cellId=p.operationCellId\nWHERE p.altitude=N''mechanic'' AND p.configKind IS NULL;\nUPDATE p SET parentScenarioId=parents.parentScenarioId\nFROM @planned p JOIN @parents parents ON parents.scenarioId=p.scenarioId;\n\n-- The structured semantic address per declared altitude.\nUPDATE p SET addressJson=(SELECT p.scenarioId AS scenarioId,p.parentScenarioId AS parentScenarioId,\n N''SCENARIO_OUTCOME'' AS semanticRole,\n (SELECT inputId FROM @scenarioFaces f WHERE f.scenarioId=p.scenarioId) AS inputId,\n (SELECT eventId FROM @scenarioFaces f WHERE f.scenarioId=p.scenarioId) AS eventId,\n (SELECT outcomeId FROM @scenarioFaces f WHERE f.scenarioId=p.scenarioId) AS outcomeId,\n (SELECT outcomeContractId FROM @scenarioFaces f WHERE f.scenarioId=p.scenarioId) AS outcomeContractId\n FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)\nFROM @planned p WHERE p.altitude=N''scenario'';\nUPDATE p SET addressJson=(SELECT p.scenarioId AS scenarioId,p.parentScenarioId AS parentScenarioId,\n N''EXECUTION_RESPONSIBILITY'' AS semanticRole,p.responsibilityId AS responsibilityId,\n p.responsibilityKind AS responsibilityKind,p.responsibilityOrdinal AS responsibilityOrdinal,\n CAST(NULL AS nvarchar(400)) AS inputId,CAST(NULL AS nvarchar(400)) AS eventId,\n CAST(NULL AS nvarchar(400)) AS outcomeId,CAST(NULL AS nvarchar(400)) AS outcomeContractId\n FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)\nFROM @planned p WHERE p.altitude=N''mechanic'' AND p.configKind IS NOT NULL;\nUPDATE p SET addressJson=(SELECT p.scenarioId AS scenarioId,p.parentScenarioId AS parentScenarioId,\n N''MECHANIC'' AS semanticRole,p.responsibilityId AS responsibilityId,p.responsibilityKind AS responsibilityKind,\n p.responsibilityOrdinal AS responsibilityOrdinal,CAST(NULL AS nvarchar(400)) AS inputId,\n CAST(NULL AS nvarchar(400)) AS eventId,CAST(NULL AS nvarchar(400)) AS outcomeId,\n CAST(NULL AS nvarchar(400)) AS outcomeContractId,p.configOp AS mechanicId,CAST(NULL AS nvarchar(400)) AS mechanicPath\n FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)\nFROM @planned p WHERE p.altitude=N''mechanic'' AND p.configKind IS NULL;\n\n-- ============================== OBSERVED TESTIMONY ==============================\nDECLARE @cells TABLE (\n arrayIndex int,cellId nvarchar(400),cellAltitude nvarchar(40),addressString nvarchar(max),\n disposition nvarchar(40),outcomeVariant nvarchar(120),outcomeContractId nvarchar(400),\n cellExecutionId nvarchar(400),parentCellExecutionId nvarchar(400),selectedEdgeIds nvarchar(max),\n logicalOrder int,startedAt nvarchar(60),completedAt nvarchar(60),durationMilliseconds decimal(18,3));\nINSERT @cells(arrayIndex,cellId,cellAltitude,addressString,disposition,outcomeVariant,outcomeContractId,cellExecutionId,parentCellExecutionId,selectedEdgeIds,logicalOrder,startedAt,completedAt,durationMilliseconds)\nSELECT CONVERT(int,j.[key]),c.cellId,c.cellAltitude,c.addressString,c.disposition,c.outcomeVariant,c.outcomeContractId,\n c.cellExecutionId,c.parentCellExecutionId,c.selectedEdgeIds,c.logicalOrder,c.startedAt,c.completedAt,c.durationMilliseconds\nFROM OPENJSON(@cells_input) j CROSS APPLY OPENJSON(j.value) WITH (\n cellId nvarchar(400) ''$.cellId'',cellAltitude nvarchar(40) ''$.cellAltitude'',addressString nvarchar(max) ''$.semanticAddress'',\n disposition nvarchar(40) ''$.disposition'',outcomeVariant nvarchar(120) ''$.outcomeVariant'',\n outcomeContractId nvarchar(400) ''$.outcomeContractId'',cellExecutionId nvarchar(400) ''$.cellExecutionId'',\n parentCellExecutionId nvarchar(400) ''$.parentCellExecutionId'',selectedEdgeIds nvarchar(max) ''$.selectedEdgeIds'' AS JSON,\n logicalOrder int ''$.logicalOrder'',startedAt nvarchar(60) ''$.startedAt'',completedAt nvarchar(60) ''$.completedAt'',\n durationMilliseconds decimal(18,3) ''$.durationMilliseconds'') c\nORDER BY CONVERT(int,j.[key]);\nDECLARE @edges TABLE (\n arrayIndex int,edgeId nvarchar(400),addressString nvarchar(max),destinationCellId nvarchar(400),\n sourceCellExecutionId nvarchar(400),admissionDisposition nvarchar(40),logicalOrder int,\n startedAt nvarchar(60),completedAt nvarchar(60),durationMilliseconds decimal(18,3));\nINSERT @edges(arrayIndex,edgeId,addressString,destinationCellId,sourceCellExecutionId,admissionDisposition,logicalOrder,startedAt,completedAt,durationMilliseconds)\nSELECT CONVERT(int,j.[key]),e.edgeId,e.addressString,e.destinationCellId,e.sourceCellExecutionId,e.admissionDisposition,\n e.logicalOrder,e.startedAt,e.completedAt,e.durationMilliseconds\nFROM OPENJSON(@edges_input) j CROSS APPLY OPENJSON(j.value) WITH (\n edgeId nvarchar(400) ''$.edgeId'',addressString nvarchar(max) ''$.semanticAddress'',destinationCellId nvarchar(400) ''$.destinationCellId'',\n sourceCellExecutionId nvarchar(400) ''$.sourceCellExecutionId'',admissionDisposition nvarchar(40) ''$.admissionDisposition'',\n logicalOrder int ''$.logicalOrder'',startedAt nvarchar(60) ''$.startedAt'',completedAt nvarchar(60) ''$.completedAt'',\n durationMilliseconds decimal(18,3) ''$.durationMilliseconds'') e\nORDER BY CONVERT(int,j.[key]);\nDECLARE @plannedEdges TABLE (\n ordinal int IDENTITY(1,1) PRIMARY KEY,\n sourceIndex int,\n edgeId nvarchar(400),kind nvarchar(80),fromJson nvarchar(max),toJson nvarchar(max),\n selectsVariant nvarchar(120),destinationCellId nvarchar(400),destinationAddressJson nvarchar(max));\nINSERT @plannedEdges(sourceIndex,edgeId,kind,fromJson,toJson,selectsVariant,destinationCellId,destinationAddressJson)\nSELECT CONVERT(int,j.[key]),e.edgeId,e.kind,e.fromJson,e.toJson,e.selectsVariant,\n COALESCE(JSON_VALUE(e.toJson,''$.cellId''),e.toJson),p.addressJson\nFROM OPENJSON(@plan_edges) j CROSS APPLY OPENJSON(j.value) WITH (\n edgeId nvarchar(400) ''$.edgeId'',kind nvarchar(80) ''$.kind'',fromJson nvarchar(max) ''$.from'' AS JSON,\n toJson nvarchar(max) ''$.to'' AS JSON,selectsVariant nvarchar(120) ''$.selectsVariant'') e\nLEFT JOIN @planned p ON p.cellId=COALESCE(JSON_VALUE(e.toJson,''$.cellId''),e.toJson)\nORDER BY CONVERT(int,j.[key]);\nDECLARE @firstCell TABLE (addressString nvarchar(max),cellId nvarchar(400),disposition nvarchar(40),\n outcomeVariant nvarchar(120),outcomeContractId nvarchar(400),durationMilliseconds decimal(18,3),logicalOrder int,arrayIndex int);\nINSERT @firstCell\nSELECT addressString,cellId,disposition,outcomeVariant,outcomeContractId,durationMilliseconds,logicalOrder,arrayIndex\nFROM (SELECT *,ROW_NUMBER() OVER (PARTITION BY cellId ORDER BY arrayIndex) rn FROM @cells) x WHERE rn=1;\n\n-- ============================== OVERLAY ==============================\nDECLARE @overlay_cells nvarchar(max)=N''[''+ISNULL((\n SELECT STRING_AGG(rowJson,N'','') WITHIN GROUP (ORDER BY ord)\n FROM (\n  SELECT ((SELECT p.cellId AS cellId,p.altitude AS altitude,p.parentCellId AS parentCellId,\n    JSON_QUERY(p.addressJson) AS semanticAddress,\n    JSON_QUERY((SELECT p.inputContractId AS inputContractId,p.outcomeContractId AS outcomeContractId,\n      p.executionAuthorityId AS executionAuthorityId,p.authorityDigest AS authorityDigest\n     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS planned,\n    JSON_QUERY(ISNULL((SELECT c.cellExecutionId AS cellExecutionId,c.disposition AS disposition,c.outcomeVariant AS outcomeVariant,\n      JSON_QUERY(c.selectedEdgeIds) AS selectedEdgeIds,c.outcomeContractId AS outcomeContractId,\n      c.logicalOrder AS logicalOrder,c.startedAt AS startedAt,c.completedAt AS completedAt,\n      c.durationMilliseconds AS durationMilliseconds\n     FROM @cells c WHERE c.cellId=p.cellId ORDER BY c.arrayIndex\n     FOR JSON PATH,INCLUDE_NULL_VALUES),N''[]'')) AS observed\n   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS rowJson,p.sourceIndex AS ord\n  FROM @planned p\n ) plannedrows\n),N'''')+N'']'';\nDECLARE @observed_only_cells nvarchar(max)=N''[''+ISNULL((\n SELECT STRING_AGG(rowJson,N'','') WITHIN GROUP (ORDER BY ord)\n FROM (\n  SELECT ((SELECT c.cellId AS cellId,c.cellAltitude AS altitude,CAST(NULL AS nvarchar(400)) AS parentCellId,\n    CAST(NULL AS nvarchar(max)) AS semanticAddress,CAST(NULL AS nvarchar(max)) AS planned,\n    JSON_QUERY(ISNULL((SELECT o.cellExecutionId AS cellExecutionId,o.disposition AS disposition,o.outcomeVariant AS outcomeVariant,\n      JSON_QUERY(o.selectedEdgeIds) AS selectedEdgeIds,o.outcomeContractId AS outcomeContractId,\n      o.logicalOrder AS logicalOrder,o.startedAt AS startedAt,o.completedAt AS completedAt,\n      o.durationMilliseconds AS durationMilliseconds\n     FROM @cells o WHERE o.cellId=c.cellId ORDER BY o.arrayIndex\n     FOR JSON PATH,INCLUDE_NULL_VALUES),N''[]'')) AS observed\n   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS rowJson,c.arrayIndex AS ord\n  FROM (SELECT c.cellId,c.cellAltitude,c.arrayIndex FROM @cells c\n    WHERE NOT EXISTS (SELECT 1 FROM @planned p WHERE p.cellId=c.cellId)\n    AND c.arrayIndex=(SELECT MIN(c2.arrayIndex) FROM @cells c2 WHERE c2.cellId=c.cellId)) c\n ) observedrows\n),N'''')+N'']'';\nDECLARE @overlay_edges nvarchar(max)=N''[''+ISNULL((\n SELECT STRING_AGG(rowJson,N'','') WITHIN GROUP (ORDER BY ord)\n FROM (\n  SELECT ((SELECT e.edgeId AS edgeId,e.kind AS kind,JSON_QUERY(e.destinationAddressJson) AS semanticAddress,\n    JSON_QUERY((SELECT JSON_QUERY(e.fromJson) AS [from],JSON_QUERY(e.toJson) AS [to],e.selectsVariant AS selectsVariant\n     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS planned,\n    JSON_QUERY(ISNULL((SELECT t.sourceCellExecutionId AS sourceCellExecutionId,t.destinationCellId AS destinationCellId,\n      t.admissionDisposition AS admissionDisposition,t.logicalOrder AS logicalOrder,t.startedAt AS startedAt,\n      t.completedAt AS completedAt,t.durationMilliseconds AS durationMilliseconds\n     FROM @edges t WHERE t.edgeId=e.edgeId ORDER BY t.arrayIndex\n     FOR JSON PATH,INCLUDE_NULL_VALUES),N''[]'')) AS observed\n   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS rowJson,e.sourceIndex AS ord\n  FROM @plannedEdges e\n ) plannedrows\n),N'''')+N'']'';\nDECLARE @observed_only_edges nvarchar(max)=N''[''+ISNULL((\n SELECT STRING_AGG(rowJson,N'','') WITHIN GROUP (ORDER BY ord)\n FROM (\n  SELECT ((SELECT t.edgeId AS edgeId,CAST(NULL AS nvarchar(80)) AS kind,JSON_QUERY(p.addressJson) AS semanticAddress,\n    CAST(NULL AS nvarchar(max)) AS planned,\n    JSON_QUERY(ISNULL((SELECT o.sourceCellExecutionId AS sourceCellExecutionId,o.destinationCellId AS destinationCellId,\n      o.admissionDisposition AS admissionDisposition,o.logicalOrder AS logicalOrder,o.startedAt AS startedAt,\n      o.completedAt AS completedAt,o.durationMilliseconds AS durationMilliseconds\n     FROM @edges o WHERE o.edgeId=t.edgeId ORDER BY o.arrayIndex\n     FOR JSON PATH,INCLUDE_NULL_VALUES),N''[]'')) AS observed\n   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS rowJson,t.arrayIndex AS ord\n  FROM (SELECT t.edgeId,t.destinationCellId,t.arrayIndex FROM @edges t\n    WHERE NOT EXISTS (SELECT 1 FROM @plannedEdges p WHERE p.edgeId=t.edgeId)\n    AND t.arrayIndex=(SELECT MIN(t2.arrayIndex) FROM @edges t2 WHERE t2.edgeId=t.edgeId)) t\n  LEFT JOIN @planned p ON p.cellId=t.destinationCellId\n ) observedrows\n),N'''')+N'']'';\nDECLARE @counts nvarchar(max)=(SELECT\n (SELECT COUNT(*) FROM @planned) AS plannedCells,\n (SELECT COUNT(*) FROM (SELECT DISTINCT cellId,cellExecutionId FROM @cells) x) AS observedCells,\n (SELECT COUNT(*) FROM @plannedEdges) AS plannedEdges,\n (SELECT COUNT(*) FROM (SELECT DISTINCT edgeId,logicalOrder FROM @edges) x) AS observedEdges\n FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);\nDECLARE @overlay nvarchar(max)=(\n SELECT @graph_id AS graphId,@canonical_digest AS canonicalGraphDigest,@observed_digest AS observedPathDigest,\n  JSON_QUERY(@overlay_cells+@observed_only_cells) AS cells,\n  JSON_QUERY(@overlay_edges+@observed_only_edges) AS edges,\n  JSON_QUERY(@counts) AS counts\n FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);\n\n-- ============================== STORY ==============================\nDECLARE @responsibility TABLE (ordinal int IDENTITY(1,1) PRIMARY KEY,scenarioId nvarchar(400),\n parentScenarioId nvarchar(400),semanticRole nvarchar(40),responsibilityId nvarchar(400),\n responsibilityKind nvarchar(80),responsibilityOrdinal int,inputId nvarchar(400),eventId nvarchar(400),\n outcomeId nvarchar(400),outcomeContractId nvarchar(400),disposition nvarchar(40),\n outcomeVariant nvarchar(120),durationMilliseconds decimal(18,3),logicalOrder int);\nINSERT @responsibility(scenarioId,parentScenarioId,semanticRole,responsibilityId,responsibilityKind,responsibilityOrdinal,\n inputId,eventId,outcomeId,outcomeContractId,disposition,outcomeVariant,durationMilliseconds,logicalOrder)\nSELECT o.owningScenarioId,parents.parentScenarioId,N''EXECUTION_RESPONSIBILITY'',COALESCE(o.portId,o.scenarioId),\n o.kind,o.ordinal,NULL,NULL,NULL,t.outcomeContractId,t.disposition,t.outcomeVariant,t.durationMilliseconds,t.logicalOrder\nFROM @operations o\nJOIN @operationCells oc ON oc.operationRowId=o.rowId\nJOIN @firstCell t ON t.cellId=oc.cellId\nLEFT JOIN @parents parents ON parents.scenarioId=o.owningScenarioId;\nDECLARE @scenarioOrder TABLE (scenarioId nvarchar(400) PRIMARY KEY,firstOrder int);\nINSERT @scenarioOrder SELECT scenarioId,MIN(logicalOrder) FROM @responsibility GROUP BY scenarioId;\nDECLARE @rootScenarioId nvarchar(400)=@scenario_id;\nIF @rootScenarioId IS NULL OR NOT EXISTS(SELECT 1 FROM @scenarioOrder WHERE scenarioId=@rootScenarioId)\n SET @rootScenarioId=(SELECT TOP 1 scenarioId FROM @scenarioOrder ORDER BY firstOrder);\nDECLARE @responsibilities_json nvarchar(max)=N''{\"scenarioId\":{\"op\":\"none\"}}'';\nDECLARE @story_root nvarchar(max)=(SELECT f.scenarioId AS scenarioId,parents.parentScenarioId AS parentScenarioId,\n  f.inputId AS inputId,f.inputContractId AS inputContractId,f.eventId AS eventId,f.eventAuthorityId AS eventAuthorityId,\n  f.outcomeId AS outcomeId,f.outcomeContractId AS outcomeContractId,\n  JSON_QUERY((SELECT r.scenarioId AS scenarioId,r.parentScenarioId AS parentScenarioId,\n    r.semanticRole AS semanticRole,r.responsibilityId AS responsibilityId,r.responsibilityKind AS responsibilityKind,\n    r.responsibilityOrdinal AS responsibilityOrdinal,r.inputId AS inputId,r.eventId AS eventId,r.outcomeId AS outcomeId,\n    r.outcomeContractId AS outcomeContractId,r.disposition AS disposition,r.outcomeVariant AS outcomeVariant,\n    r.durationMilliseconds AS durationMilliseconds\n   FROM @responsibility r WHERE r.scenarioId=f.scenarioId ORDER BY r.responsibilityOrdinal\n   FOR JSON PATH,INCLUDE_NULL_VALUES)) AS responsibilities\n FROM @scenarioFaces f LEFT JOIN @parents parents ON parents.scenarioId=f.scenarioId\n WHERE f.scenarioId=ISNULL(@rootScenarioId,N'''')\n FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);\nIF @story_root IS NULL SET @story_root=(SELECT (SELECT f.scenarioId AS scenarioId,parents.parentScenarioId AS parentScenarioId,\n  f.inputId AS inputId,f.inputContractId AS inputContractId,f.eventId AS eventId,f.eventAuthorityId AS eventAuthorityId,\n  f.outcomeId AS outcomeId,f.outcomeContractId AS outcomeContractId,JSON_QUERY(N''[]'') AS responsibilities\n FROM @scenarioFaces f LEFT JOIN @parents parents ON parents.scenarioId=f.scenarioId\n WHERE f.scenarioId=@scenario_id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES));\nDECLARE @composed nvarchar(max)=(SELECT f.scenarioId AS scenarioId,parents.parentScenarioId AS parentScenarioId,\n  f.inputId AS inputId,f.inputContractId AS inputContractId,f.eventId AS eventId,f.eventAuthorityId AS eventAuthorityId,\n  f.outcomeId AS outcomeId,f.outcomeContractId AS outcomeContractId,\n  JSON_QUERY((SELECT r.scenarioId AS scenarioId,r.parentScenarioId AS parentScenarioId,\n    r.semanticRole AS semanticRole,r.responsibilityId AS responsibilityId,r.responsibilityKind AS responsibilityKind,\n    r.responsibilityOrdinal AS responsibilityOrdinal,r.inputId AS inputId,r.eventId AS eventId,r.outcomeId AS outcomeId,\n    r.outcomeContractId AS outcomeContractId,r.disposition AS disposition,r.outcomeVariant AS outcomeVariant,\n    r.durationMilliseconds AS durationMilliseconds\n   FROM @responsibility r WHERE r.scenarioId=f.scenarioId ORDER BY r.responsibilityOrdinal\n   FOR JSON PATH,INCLUDE_NULL_VALUES)) AS responsibilities\n FROM @scenarioOrder s JOIN @scenarioFaces f ON f.scenarioId=s.scenarioId\n LEFT JOIN @parents parents ON parents.scenarioId=s.scenarioId\n WHERE s.scenarioId<>ISNULL(@rootScenarioId,N'''')\n ORDER BY s.firstOrder\n FOR JSON PATH,INCLUDE_NULL_VALUES);\nDECLARE @story nvarchar(max)=CASE WHEN @composed IS NULL\n THEN (SELECT JSON_QUERY(@story_root) AS scenario,@observed_digest AS observedPathDigest\n  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)\n ELSE (SELECT JSON_QUERY(@story_root) AS scenario,JSON_QUERY(@composed) AS composedScenarios,@observed_digest AS observedPathDigest\n  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) END;\n\nSELECT (SELECT N''observation-projection.v1'' AS projectionType,JSON_QUERY(@overlay) AS overlay,JSON_QUERY(@story) AS story\n FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) AS value;","resultColumn":"value"}}]}]}';
EXEC model.declare_capability_document @document=@document;

-- ============================== DECLARED READINGS FOR THE REMAINING OBSERVE SURFACES ==============================
-- The altitude vocabulary is the declared readings' altitude union. The observe
-- surfaces that predate U4 (the agent lane and the composed equity lane) declare
-- the same default/trace readings; the readings member is only added where the
-- interface has none, and every other declared member is carried unchanged.
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @readings nvarchar(max)=N'[{"reading":"default","altitudes":["scenario"]},{"reading":"trace","altitudes":["scenario","mechanic","provider","physical"]}]';
DECLARE @targets TABLE (ordinal int IDENTITY(1,1) PRIMARY KEY, capability_id nvarchar(120));
INSERT @targets(capability_id) VALUES(N'request-capability-from-objective'),(N'compose-resolve-equity-market-price-evidence');
DECLARE @proof TABLE (ordinal int PRIMARY KEY, capability_id nvarchar(120), cli_before nvarchar(max), cli_after nvarchar(max));
DECLARE @capability_id nvarchar(120),@capPk bigint,@capSo bigint,@oldVer bigint,@capSod bigint,
 @curEnv nvarchar(max),@cliBefore nvarchar(max),@cliAfter nvarchar(max),@newEnv nvarchar(max),
 @newBytes varbinary(max),@newDigest binary(32),@newSod bigint,@newVer bigint,@ordinal int;
DECLARE @targets_cursor CURSOR;
SET @targets_cursor=CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal,capability_id FROM @targets ORDER BY ordinal;
OPEN @targets_cursor;
FETCH NEXT FROM @targets_cursor INTO @ordinal,@capability_id;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @capPk=NULL;SET @capSo=NULL;SET @oldVer=NULL;SET @capSod=NULL;SET @curEnv=NULL;
 SELECT @capPk=c.capability_pk,@capSo=c.semantic_object_pk,@oldVer=ec.capability_version_pk,@capSod=ec.semantic_object_definition_pk
 FROM model.estate_capability ec
 JOIN model.capability c ON c.capability_pk=ec.capability_pk
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
 WHERE ec.estate_model_pk=@estate AND c.capability_id=@capability_id AND n.namespace_id=N'sidefx:capabilities';
 IF @capPk IS NULL THROW 51000,'CAPABILITY_NOT_FOUND',1;
 SELECT @curEnv=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE d.semantic_object_definition_pk=@capSod;
 SET @cliBefore=JSON_QUERY(@curEnv,'$.semantics.cli');
 SET @newSod=@capSod;
 IF @cliBefore IS NOT NULL AND JSON_QUERY(@curEnv,'$.semantics.cli.readings') IS NULL BEGIN
  SET @cliAfter=JSON_MODIFY(@cliBefore,'$.readings',JSON_QUERY(@readings));
  SET @newEnv=JSON_MODIFY(@curEnv,'$.semantics.cli',JSON_QUERY(@cliAfter));
  SET @newBytes=CONVERT(varbinary(max),CONVERT(varchar(max),(@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
  SET @newDigest=HASHBYTES('SHA2_256',@newBytes);
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
 END ELSE SET @cliAfter=@cliBefore;
 INSERT @proof VALUES(@ordinal,@capability_id,@cliBefore,@cliAfter);
 FETCH NEXT FROM @targets_cursor INTO @ordinal,@capability_id;
END;
CLOSE @targets_cursor;
DEALLOCATE @targets_cursor;

-- ============================== EXTENDED OBSERVATION TELEMETRY AUTHORITY ==============================
-- The stream now publishes the kernel's declared testimony vocabulary (the new
-- semanticAddress and display.entry among it). The allowlist stays the declared
-- authority the delivery seam applies; this re-declaration adds the testimony
-- field names the kernel emits. Inputs, provider bodies and secrets are still
-- not among the declared fields.
DECLARE @telemetry_statement nvarchar(max) = N'SELECT (SELECT N''observation-telemetry-authority.v1'' AS authorityType,
 JSON_QUERY(N''["observationType","testimonyType","phase","status","observedAt","executionId","cellExecutionId","rootExecutionId","parentCellExecutionId","sourceCellExecutionId","scenarioId","stepId","sequence","logicalOrder","cellId","cellAltitude","edgeId","durationMilliseconds","startedAt","completedAt","semanticRole","responsibilityId","responsibilityKind","responsibilityOrdinal","mechanicId","mechanicPath","childScenarioId","parentScenarioId","inputId","eventId","outcomeId","outcomeContractId","sourceCellId","destinationCellId","admissionDisposition","semanticAddress","outcomeClassification","disposition","outcomeVariant","iterationId","occurrenceId","providerProfileId"]'') AS observationFields,
 JSON_QUERY(N''["status","text","note","admission","timing"]'') AS entryFields,
 JSON_QUERY(N''{"providerEvidence":["reachedStage","exchangeCount","transportDisposition","redactionVerified","httpStatus"],"display":["entry"]}'') AS objectFields
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value';
DECLARE @telemetry_bindings nvarchar(max) = N'[{"portId":"read-observation-telemetry-authority-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@telemetry_statement,N'json') + N'","resultColumn":"value"}}]';
DECLARE @telemetry_contracts nvarchar(max) = N'[
 {"id":"observation-telemetry-request.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/observation-telemetry-request.v1.schema.json","title":"Observation telemetry request","type":"object","additionalProperties":false,"required":["contractId"],"properties":{"contractId":{"const":"observation-telemetry-request.v1"}}}},
 {"id":"observation-telemetry-authority.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/observation-telemetry-authority.v1.schema.json","title":"Observation telemetry authority","type":"object","additionalProperties":false,"required":["authorityType","observationFields","entryFields","objectFields"],"properties":{"authorityType":{"const":"observation-telemetry-authority.v1"},"observationFields":{"type":"array","items":{"type":"string"}},"entryFields":{"type":"array","items":{"type":"string"}},"objectFields":{"type":"object","additionalProperties":false,"required":["providerEvidence","display"],"properties":{"providerEvidence":{"type":"array","items":{"type":"string"}},"display":{"type":"array","items":{"type":"string"}}}}}}}
]';
DECLARE @telemetry_document nvarchar(max) = N'{
 "document":"sidefx-capability-authority.v1",
 "capabilityId":"read-observation-telemetry-authority",
 "meaning":{"intent":"read the declared observation-channel telemetry authority","outcome":"the caller observes the declared scalar fields, entry fields and bounded object fields the observation channel may publish"},
 "contracts":' + @telemetry_contracts + N',
 "scenarios":[{
  "scenarioId":"read-observation-telemetry-authority",
  "name":"Read the observation telemetry authority",
  "inputId":"observation-telemetry-request",
  "inputContract":"observation-telemetry-request.v1",
  "eventId":"observation-telemetry-authority-requested",
  "eventAuthority":"read-observation-telemetry-authority.v1",
  "outcomeId":"observation-telemetry-authority",
  "outcomeContract":"observation-telemetry-authority.v1",
  "terminal":true,
  "root":true,
  "given":"the current model",
  "when":"the declared telemetry-authority read executes under the reader boundary",
  "then":"the reading names the scalar testimony fields, the display Entry fields and the bounded provider-evidence fields the observation channel may publish",
  "operations":[{"operationId":"read-observation-telemetry-authority.0","kind":"invoke-port","portId":"read-observation-telemetry-authority-port"}],
  "portBindings":' + @telemetry_bindings + N'
 }]
}';
EXEC model.declare_capability_document @document=@telemetry_document;

-- ============================== PROOF ==============================
SELECT '1_contracts' AS result_set, d.declared_id AS contract_id
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='CONTRACT'
 AND d.declared_id IN (N'observation-projection-request.v1',N'observation-projection.v1')
ORDER BY d.declared_id;

SELECT '2_capability' AS result_set, c.capability_id, s.scenario_id,
 p.port_id, JSON_VALUE(pd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
 JSON_VALUE(pd.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 (SELECT LEN(o.value) FROM OPENJSON(pd.definition_json,'$.semantics.configuration') o WHERE o.[key]=N'statement') AS statement_chars,
 (SELECT CASE WHEN o.value LIKE N'%parentCellId%' THEN 1 ELSE 0 END FROM OPENJSON(pd.definition_json,'$.semantics.configuration') o WHERE o.[key]=N'statement') AS parent_chain_declared
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
WHERE c.capability_id=N'read-observation-projection';

-- The assembled graph source from the uncommitted transaction: the read is
-- reachable through the estate view and carries its declared statement.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-observation-projection',0,N'sidefx:capabilities'));
SELECT '3_graph_source' AS result_set,
 JSON_VALUE(@graph,'$.capabilityId') AS capability_id,
 JSON_VALUE(@graph,'$.rootScenarioId') AS root_scenario_id,
 (SELECT COUNT(*) FROM OPENJSON(@graph,'$.executionAuthorities') a CROSS APPLY OPENJSON(JSON_QUERY(a.value,'$.operations')) o
  WHERE JSON_VALUE(o.value,'$.operationId')=N'read-observation-projection.0') AS operations_declared;

-- The behavioral self-test: two declared cells (scenario and one operation), one
-- scenario row, one operation row, two testimony entries. The projection must
-- name the planned cell, join the testimony by the declared semantic address,
-- and build the story responsibility with its declared ordinal.
DECLARE @stmt nvarchar(max)=(SELECT o.value
 FROM analysis.v_selected_semantic_definition d
 JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=d.semantic_object_definition_pk
 JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
 CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') o
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=N'sidefx:capability:read-observation-projection' AND d.declared_id=N'read-observation-projection-port'
  AND o.[key]=N'statement');
DECLARE @sample nvarchar(max)=N'{"contractId":"observation-projection-request.v1","payload":{"capabilityId":"self-test","scenarioId":"root","graphId":"graph:self-test","canonicalGraphDigest":"sha256:plan","observedPathDigest":"sha256:path","scenarios":[{"scenarioId":"root","input":{"inputId":"root-input","contract":{"contractId":"root-input.v1"}},"event":{"eventId":"root-event","executionAuthorityId":"root.v1"},"outcome":{"outcomeId":"root-outcome","contract":{"contractId":"root-outcome.v1"}}}],"executionAuthorities":[{"id":"root.v1","owningScenarioId":"root","operations":[{"kind":"invoke-port","portId":"root-port"}]}],"plan":{"canonicalGraph":{"graphId":"graph:self-test","edges":[],"cells":[{"cellId":"cell:scenario:root","semanticAddress":"self-test/scenario/root","altitude":"scenario","parentCellId":null,"input":{"contractId":"root-input.v1"},"outcome":{"contractId":"root-outcome.v1"},"execution":{"kind":"scenario","authorityId":"root.v1","authorityDigest":"sha256:a"}},{"cellId":"cell:mechanic:root.operation.1","semanticAddress":"self-test/scenario/root/operation/root.operation.1","altitude":"mechanic","parentCellId":"cell:scenario:root","input":{"contractId":"root-input.v1"},"outcome":{"contractId":"root-outcome.v1"},"execution":{"kind":"mechanic","authorityId":"operation:root-port","authorityDigest":"sha256:b","configuration":{"kind":"invoke-port","portId":"root-port"}},"sourcePointers":["executionAuthorities/root/operations/0"]}]}},"cellTestimony":[{"testimonyType":"cell-execution-testimony.v1","cellId":"cell:mechanic:root.operation.1","cellAltitude":"mechanic","semanticAddress":"self-test/scenario/root/operation/root.operation.1","cellExecutionId":"exec:1","disposition":"completed","outcomeVariant":"SUCCESS","outcomeContractId":"root-outcome.v1","selectedEdgeIds":[],"logicalOrder":0,"startedAt":"2026-09-17T00:00:00.000Z","completedAt":"2026-09-17T00:00:00.005Z","durationMilliseconds":5}],"edgeTestimony":[]}}';
DECLARE @projection TABLE (value nvarchar(max));
INSERT @projection EXEC sp_executesql @stmt,N'@input nvarchar(max), @estate_model_pk bigint',@input=@sample,@estate_model_pk=@estate;
SELECT '4_projection_self_test' AS result_set,
 JSON_VALUE(value,'$.projectionType') AS projection_type,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.overlay.cells'))) AS overlay_cells,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.overlay.cells'),'$') c
  CROSS APPLY OPENJSON(JSON_QUERY(c.value,'$.observed')) o) AS overlay_observed,
 JSON_VALUE(value,'$.story.scenario.scenarioId') AS story_scenario,
 JSON_VALUE(value,'$.story.scenario.inputId') AS story_input,
 JSON_VALUE(value,'$.story.scenario.responsibilities[0].responsibilityId') AS story_responsibility,
 JSON_VALUE(value,'$.story.scenario.responsibilities[0].responsibilityOrdinal') AS story_ordinal,
 JSON_VALUE(value,'$.story.scenario.responsibilities[0].disposition') AS story_disposition
FROM @projection;

SELECT '5_readings' AS result_set, capability_id, cli_before, cli_after FROM @proof ORDER BY ordinal;

DECLARE @agentGraph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'request-capability-from-objective',0,N'sidefx:capabilities'));
DECLARE @composeGraph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'compose-resolve-equity-market-price-evidence',0,N'sidefx:capabilities'));
SELECT '6_observe_readings' AS result_set,
 JSON_QUERY(JSON_QUERY(@agentGraph,'$.interfaceAuthority.interfaces[0].configuration'),'$.readings') AS agent_lane_readings,
 JSON_QUERY(JSON_QUERY(@composeGraph,'$.interfaceAuthority.interfaces[0].configuration'),'$.readings') AS compose_readings;

-- The extended telemetry authority self-test: the declared statement itself is
-- executed and must carry the testimony vocabulary the kernel emits.
DECLARE @telemetry_stmt nvarchar(max)=(SELECT o.value
 FROM analysis.v_selected_semantic_definition d
 JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=d.semantic_object_definition_pk
 JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
 CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') o
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=N'sidefx:capability:read-observation-telemetry-authority'
  AND d.declared_id=N'read-observation-telemetry-authority-port' AND o.[key]=N'statement');
DECLARE @telemetry TABLE (value nvarchar(max));
INSERT @telemetry EXEC sp_executesql @telemetry_stmt;
SELECT '7_telemetry_authority' AS result_set,
 JSON_VALUE(value,'$.authorityType') AS authority_type,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.observationFields'))) AS observation_fields,
 CASE WHEN value LIKE N'%testimonyType%' AND value LIKE N'%semanticAddress%' THEN 1 ELSE 0 END AS carries_testimony_vocabulary
FROM @telemetry;

-- Installed after the rollback dry run and the from-transaction preflight on the
-- live captures (agent lane 985 planned / 703 observed, equity 242/180, story
-- equal to the retired code, streamed altitudes 716/180).
COMMIT TRANSACTION;
