SET NOCOUNT ON;
DECLARE @m bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @cap nvarchar(200) = N'resolve-equity-market-price-evidence';
DECLARE @cv bigint = (SELECT ec.capability_version_pk FROM model.estate_capability ec
  JOIN model.capability c ON c.capability_pk=ec.capability_pk
  WHERE ec.estate_model_pk=@m AND c.capability_id=@cap);
DECLARE @sv bigint = (SELECT cs.scenario_version_pk FROM model.capability_scenario cs
  JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
  WHERE cs.capability_version_pk=@cv AND s.scenario_id=@cap);
DECLARE @t datetime2 = SYSUTCDATETIME();

-- H1: recordset 2 verbatim from scenario-resolver-map.sql lines 60-70
SELECT DISTINCT s.scenario_id AS downstream_scenario_id, cl.minimum_depth, cl.cycle_detected,
       i.input_id, e.event_id, e.responsibility, o.outcome_id,
       sv.definition_digest AS scenario_definition_digest
FROM analysis.v_scenario_invocation_closure cl
JOIN model.scenario_version sv ON sv.scenario_version_pk=cl.downstream_scenario_version_pk
JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
LEFT JOIN model.scenario_input i ON i.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_event e ON e.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_outcome o ON o.scenario_version_pk=sv.scenario_version_pk
WHERE cl.capability_version_pk=@cv AND cl.selected_scenario_version_pk=@sv
ORDER BY cl.minimum_depth, s.scenario_id
OPTION(MAXRECURSION 32767);
SELECT DATEDIFF(ms,@t,SYSUTCDATETIME()) AS h1_closure_ms;
