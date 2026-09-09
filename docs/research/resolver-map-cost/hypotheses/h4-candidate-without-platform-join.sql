SET NOCOUNT ON;
DECLARE @m bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @cap nvarchar(200) = N'resolve-equity-market-price-evidence';
DECLARE @cv bigint = (SELECT ec.capability_version_pk FROM model.estate_capability ec
  JOIN model.capability c ON c.capability_pk=ec.capability_pk
  WHERE ec.estate_model_pk=@m AND c.capability_id=@cap);
DECLARE @sv bigint = (SELECT cs.scenario_version_pk FROM model.capability_scenario cs
  JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
  WHERE cs.capability_version_pk=@cv AND s.scenario_id=@cap);

-- Candidate replacement: scenario-scoped MECHANIC requirements joined to the
-- node mechanic resolution. No platform-implementation join, no cross-target
-- fan-out, no window function.
DECLARE @t datetime2 = SYSUTCDATETIME();
SELECT DISTINCT nr.implementation_id, nr.implementation_export
FROM analysis.v_scenario_embodiment_requirement r
JOIN analysis.v_declared_mechanic_resolution nr
  ON nr.estate_model_pk = r.estate_model_pk
 AND nr.target_language = N'node'
 AND nr.mechanic_definition_pk = r.requirement_definition_pk
WHERE r.estate_model_pk=@m AND r.capability_version_pk=@cv
  AND r.selected_scenario_version_pk=@sv AND r.requirement_kind='MECHANIC'
OPTION(MAXRECURSION 32767);
SELECT DATEDIFF(ms,@t,SYSUTCDATETIME()) AS candidate_ms;
