SET NOCOUNT ON;
DECLARE @m bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @t datetime2 = SYSUTCDATETIME();
SELECT COUNT_BIG(*) AS node_mechanic_rows FROM analysis.v_declared_mechanic_resolution
WHERE estate_model_pk=@m AND target_language='node';
SELECT DATEDIFF(ms,@t,SYSUTCDATETIME()) AS h2_mechanic_resolution_ms;
