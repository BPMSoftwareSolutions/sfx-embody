-- Why scenario-resolver-map.sql costs ~30s on an invocation that executes in 3ms.
--
-- Self-contained: resolves the published model and the capability itself, so it
-- runs as-is in SSMS against the `sidefx` database. Run this file independently. Do not
-- insert GO between blocks -- the DECLAREs are batch-scoped.
--
-- Context. `sfx capability invoke resolve-equity-market-price-evidence` reports:
--     capability-embodiment.sql      1,221 ms
--     scenario-resolver-map.sql     30,440 ms   <-- this
--     mechanic-definitions.sql       1,138 ms
--     executeScenario                    3 ms
--
-- And materialize-node.mjs consumes only three things from those 30 seconds:
--   recordset 0 (187 rows x 29 cols) -> filtered to requirement_kind='MECHANIC',
--        deduped on (implementation_id, implementation_export), asserted to be
--        exactly ONE row. 27 columns never read.          [materialize-node.mjs:115]
--   recordset 1 -> one boolean: readiness = 'CAN_ATTEMPT_EMBODIMENT'.  [:24]
--   recordset 2 -> the 4-row downstream closure.                        [:92]
--
-- Hypothesis to test: the cost is the cross join to all six target languages
-- inside analysis.v_scenario_language_resolution, multiplied over a recursive
-- closure, with the caller discarding five-sixths via .filter(target_language==='node').
-- The query already accepts @target and the reader never passes it.

SET NOCOUNT ON;

DECLARE @m  bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @cap nvarchar(200) = N'resolve-equity-market-price-evidence';

DECLARE @cv bigint = (SELECT ec.capability_version_pk
                      FROM model.estate_capability ec
                      JOIN model.capability c ON c.capability_pk = ec.capability_pk
                      WHERE ec.estate_model_pk = @m AND c.capability_id = @cap);
DECLARE @sv bigint = (SELECT cs.scenario_version_pk
                      FROM model.capability_scenario cs
                      JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
                      WHERE cs.capability_version_pk = @cv AND s.scenario_id = @cap);

SELECT @m AS estate_model_pk, @cv AS capability_version_pk, @sv AS scenario_version_pk;

DECLARE @t datetime2, @ms int, @n bigint;

---------------------------------------------------------------------------
-- 3. What the planner ACTUALLY needs, timed directly.
--    If these three are fast, the 30s is entirely overhead the consumer discards.
---------------------------------------------------------------------------
-- (a) the single native mechanic binding -- materialize-node.mjs:115
SET @t = SYSUTCDATETIME();
SELECT DISTINCT implementation_id, implementation_export
FROM analysis.v_scenario_language_resolution
WHERE estate_model_pk = @m AND capability_version_pk = @cv AND selected_scenario_version_pk = @sv
  AND target_language = N'node' AND requirement_kind = 'MECHANIC';
SET @ms = DATEDIFF(ms, @t, SYSUTCDATETIME());
SELECT '(a) native mechanic binding' AS need, @ms AS ms;
