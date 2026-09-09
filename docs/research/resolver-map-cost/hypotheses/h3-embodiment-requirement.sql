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
SELECT COUNT_BIG(*) AS requirement_rows FROM analysis.v_scenario_embodiment_requirement
WHERE estate_model_pk=@m AND capability_version_pk=@cv AND selected_scenario_version_pk=@sv
OPTION(MAXRECURSION 32767);
SELECT DATEDIFF(ms,@t,SYSUTCDATETIME()) AS h3_embodiment_requirement_ms;
