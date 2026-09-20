-- Declared capability-authority read. Resolve a scenario's reachable graph,
-- including transitions and nested scenario invocations. Other registered
-- scenarios remain available without becoming unreachable compiler cells.
DECLARE @graphs TABLE(row_id int IDENTITY,capability_id nvarchar(400),scenario_id nvarchar(400),namespace_id nvarchar(400),
 graph_source nvarchar(max),cli_configuration nvarchar(max),documents nvarchar(max));
INSERT @graphs(capability_id,scenario_id,namespace_id,graph_source,cli_configuration,documents)
 SELECT g.capability_id,COALESCE(JSON_VALUE(@input,'$.scenarioId'),g.root_scenario_id),g.namespace_id,g.graph_source,g.cli_configuration,g.documents
 FROM analysis.capability_graph_source(CONVERT(nvarchar(400),JSON_VALUE(@input,'$.capabilityId')),
  CONVERT(bit,JSON_VALUE(@input,'$.includeDocuments')),CONVERT(nvarchar(400),JSON_VALUE(@input,'$.namespaceId'))) g
 WHERE g.estate_model_pk=@estate_model_pk AND (JSON_VALUE(@input,'$.namespaceId') IS NULL OR g.namespace_id=JSON_VALUE(@input,'$.namespaceId'))
 AND (JSON_VALUE(@input,'$.scenarioId') IS NULL OR EXISTS(SELECT 1 FROM OPENJSON(g.graph_source,'$.scenarios')
  WHERE JSON_VALUE(value,'$.scenarioId')=JSON_VALUE(@input,'$.scenarioId')));
DECLARE @edges TABLE(row_id int,source_id nvarchar(400) COLLATE Latin1_General_100_BIN2,target_id nvarchar(400) COLLATE Latin1_General_100_BIN2);
INSERT @edges
 SELECT g.row_id,JSON_VALUE(t.value,'$.from.scenarioId'),JSON_VALUE(t.value,'$.to.scenarioId') FROM @graphs g CROSS APPLY OPENJSON(g.graph_source,'$.transitions') t
 UNION
 SELECT g.row_id,JSON_VALUE(a.value,'$.owningScenarioId'),JSON_VALUE(o.value,'$.scenarioId')
 FROM @graphs g CROSS APPLY OPENJSON(g.graph_source,'$.executionAuthorities') a CROSS APPLY OPENJSON(a.value,'$.operations') o
 WHERE JSON_VALUE(o.value,'$.kind')='invoke-scenario';
DECLARE @reachable TABLE(row_id int,scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2,PRIMARY KEY(row_id,scenario_id));
INSERT @reachable SELECT row_id,scenario_id FROM @graphs;
WHILE 1=1
BEGIN
 INSERT @reachable SELECT DISTINCT e.row_id,e.target_id FROM @edges e JOIN @reachable r ON r.row_id=e.row_id AND r.scenario_id=e.source_id
 WHERE e.target_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM @reachable found WHERE found.row_id=e.row_id AND found.scenario_id=e.target_id);
 IF @@ROWCOUNT=0 BREAK;
END;
UPDATE g SET graph_source=JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(g.graph_source,'$.rootScenarioId',g.scenario_id),
 '$.scenarios',JSON_QUERY(COALESCE((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),s.value),N',') WITHIN GROUP(ORDER BY CONVERT(int,s.[key]))+N']'
  FROM OPENJSON(g.graph_source,'$.scenarios') s JOIN @reachable r ON r.row_id=g.row_id AND r.scenario_id=JSON_VALUE(s.value,'$.scenarioId')),N'[]'))),
 '$.executionAuthorities',JSON_QUERY(COALESCE((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),a.value),N',') WITHIN GROUP(ORDER BY CONVERT(int,a.[key]))+N']'
  FROM OPENJSON(g.graph_source,'$.executionAuthorities') a JOIN @reachable r ON r.row_id=g.row_id AND r.scenario_id=JSON_VALUE(a.value,'$.owningScenarioId')),N'[]'))),
 '$.transitions',JSON_QUERY(COALESCE((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),t.value),N',') WITHIN GROUP(ORDER BY CONVERT(int,t.[key]))+N']'
  FROM OPENJSON(g.graph_source,'$.transitions') t JOIN @reachable r ON r.row_id=g.row_id AND r.scenario_id=JSON_VALUE(t.value,'$.from.scenarioId')),N'[]')))
FROM @graphs g;
SELECT capability_id,scenario_id,namespace_id,graph_source,cli_configuration,documents FROM @graphs ORDER BY row_id;
