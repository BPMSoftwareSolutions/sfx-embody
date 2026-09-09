-- Why scenario-resolver-map.sql costs ~30s on an invocation that executes in 3ms.
--
-- Self-contained: resolves the published model and the capability itself, so it
-- runs as-is in SSMS against the `sidefx` database. Run the whole file. Do not
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
-- Hypothesis originally tested here -- REFUTED, kept for the record: that the
-- cost was the cross join to all six target languages inside
-- analysis.v_scenario_language_resolution, multiplied over a recursive closure,
-- with the caller discarding five-sixths via .filter(target_language==='node').
--
-- The premise was wrong. The reader does pass the target: the selection built in
-- src/invoke-database-capability.mjs already carries target: 'node'. Measured
-- with and without it, the invocation produced an identical inputDigest and
-- 30,440 ms vs 31,979 ms -- no effect.
--
-- The cost is analysis.v_scenario_embodiment_requirement, which CROSS APPLYs a
-- multi-statement table function across every (capability, scenario) pair in the
-- estate before the caller's predicate filters to one. See findings.md.

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
-- 1. Per-layer cost and row count, bottom of the chain upward.
--    Each layer is timed separately so the expensive one is unambiguous.
---------------------------------------------------------------------------
SET @t = SYSUTCDATETIME();
SELECT @n = COUNT_BIG(*) FROM analysis.v_scenario_invocation_closure
 WHERE estate_model_pk = @m AND capability_version_pk = @cv AND selected_scenario_version_pk = @sv;
SET @ms = DATEDIFF(ms, @t, SYSUTCDATETIME());
SELECT '1. v_scenario_invocation_closure (this scenario)' AS layer, @n AS rows_, @ms AS ms;

SET @t = SYSUTCDATETIME();
SELECT @n = COUNT_BIG(*) FROM analysis.v_scenario_invocation_closure WHERE estate_model_pk = @m;
SET @ms = DATEDIFF(ms, @t, SYSUTCDATETIME());
SELECT '2. v_scenario_invocation_closure (whole model)' AS layer, @n AS rows_, @ms AS ms;

SET @t = SYSUTCDATETIME();
SELECT @n = COUNT_BIG(*) FROM analysis.v_scenario_embodiment_requirement
 WHERE estate_model_pk = @m AND capability_version_pk = @cv AND selected_scenario_version_pk = @sv;
SET @ms = DATEDIFF(ms, @t, SYSUTCDATETIME());
SELECT '3. v_scenario_embodiment_requirement (filtered)' AS layer, @n AS rows_, @ms AS ms;

SET @t = SYSUTCDATETIME();
SELECT @n = COUNT_BIG(*) FROM analysis.v_declared_platform_implementation WHERE estate_model_pk = @m;
SET @ms = DATEDIFF(ms, @t, SYSUTCDATETIME());
SELECT '4. v_declared_platform_implementation (whole model)' AS layer, @n AS rows_, @ms AS ms;

SET @t = SYSUTCDATETIME();
SELECT @n = COUNT_BIG(*) FROM analysis.v_declared_mechanic_resolution WHERE estate_model_pk = @m;
SET @ms = DATEDIFF(ms, @t, SYSUTCDATETIME());
SELECT '5. v_declared_mechanic_resolution (whole model)' AS layer, @n AS rows_, @ms AS ms;

SET @t = SYSUTCDATETIME();
SELECT @n = COUNT_BIG(*) FROM analysis.v_scenario_language_resolution
 WHERE estate_model_pk = @m AND capability_version_pk = @cv AND selected_scenario_version_pk = @sv;
SET @ms = DATEDIFF(ms, @t, SYSUTCDATETIME());
SELECT '6. v_scenario_language_resolution (filtered, ALL targets)' AS layer, @n AS rows_, @ms AS ms;


---------------------------------------------------------------------------
-- 2. THE MAIN QUESTION: does filtering to one target language help?
--    The view cross joins every requirement to all six declared targets. If the
--    optimizer cannot push target_language down, adding it changes nothing and
--    the fix is structural rather than a parameter.
---------------------------------------------------------------------------
SET @t = SYSUTCDATETIME();
SELECT @n = COUNT_BIG(*) FROM analysis.v_scenario_language_resolution
 WHERE estate_model_pk = @m AND capability_version_pk = @cv AND selected_scenario_version_pk = @sv
   AND target_language = N'node';
SET @ms = DATEDIFF(ms, @t, SYSUTCDATETIME());
SELECT 'node only' AS variant, @n AS rows_, @ms AS ms;

SELECT target_language, COUNT_BIG(*) AS rows_
FROM analysis.v_scenario_language_resolution
WHERE estate_model_pk = @m AND capability_version_pk = @cv AND selected_scenario_version_pk = @sv
GROUP BY target_language ORDER BY target_language;


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

-- (b) the readiness boolean -- materialize-node.mjs:24
SET @t = SYSUTCDATETIME();
SELECT CASE WHEN SUM(CASE WHEN resolution_status <> 'RESOLVED' THEN 1 ELSE 0 END) = 0
            THEN 'CAN_ATTEMPT_EMBODIMENT' ELSE 'NOT_OBSERVABLE' END AS readiness,
       COUNT_BIG(*) AS requirement_count
FROM analysis.v_scenario_language_resolution
WHERE estate_model_pk = @m AND capability_version_pk = @cv AND selected_scenario_version_pk = @sv
  AND target_language = N'node';
SET @ms = DATEDIFF(ms, @t, SYSUTCDATETIME());
SELECT '(b) readiness' AS need, @ms AS ms;

-- (c) the downstream closure -- materialize-node.mjs:92
--     Note this one already bypasses the resolution chain entirely.
SET @t = SYSUTCDATETIME();
SELECT DISTINCT s.scenario_id, cl.minimum_depth, cl.cycle_detected,
       i.input_id, e.event_id, o.outcome_id
FROM analysis.v_scenario_invocation_closure cl
JOIN model.scenario_version sv ON sv.scenario_version_pk = cl.downstream_scenario_version_pk
JOIN model.scenario s ON s.scenario_pk = sv.scenario_pk
LEFT JOIN model.scenario_input i ON i.scenario_version_pk = sv.scenario_version_pk
LEFT JOIN model.scenario_event e ON e.scenario_version_pk = sv.scenario_version_pk
LEFT JOIN model.scenario_outcome o ON o.scenario_version_pk = sv.scenario_version_pk
WHERE cl.capability_version_pk = @cv AND cl.selected_scenario_version_pk = @sv
ORDER BY cl.minimum_depth, s.scenario_id
OPTION(MAXRECURSION 32767);
SET @ms = DATEDIFF(ms, @t, SYSUTCDATETIME());
SELECT '(c) downstream closure' AS need, @ms AS ms;


---------------------------------------------------------------------------
-- 4. Comparison against a capability that has always worked, to separate
--    "this capability is unusual" from "the view is slow for everyone".
---------------------------------------------------------------------------
DECLARE @cv2 bigint = (SELECT ec.capability_version_pk
                       FROM model.estate_capability ec
                       JOIN model.capability c ON c.capability_pk = ec.capability_pk
                       WHERE ec.estate_model_pk = @m AND c.capability_id = N'resolve-sidefx-eligible-providers');
DECLARE @sv2 bigint = (SELECT cs.scenario_version_pk
                       FROM model.capability_scenario cs
                       JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
                       WHERE cs.capability_version_pk = @cv2 AND s.scenario_id = N'resolve-sidefx-eligible-providers');

SET @t = SYSUTCDATETIME();
SELECT @n = COUNT_BIG(*) FROM analysis.v_scenario_language_resolution
 WHERE estate_model_pk = @m AND capability_version_pk = @cv2 AND selected_scenario_version_pk = @sv2;
SET @ms = DATEDIFF(ms, @t, SYSUTCDATETIME());
SELECT 'resolve-sidefx-eligible-providers (all targets)' AS baseline, @n AS rows_, @ms AS ms;


---------------------------------------------------------------------------
-- 5. Indexes available to the chain's base tables. A recursive closure over
--    unindexed join columns is the usual cause of this shape.
---------------------------------------------------------------------------
SELECT OBJECT_SCHEMA_NAME(i.object_id) + '.' + OBJECT_NAME(i.object_id) AS tbl,
       i.name AS index_name, i.type_desc, i.is_unique,
       STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ',')
         WITHIN GROUP (ORDER BY ic.key_ordinal) AS key_columns
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
WHERE i.object_id IN (OBJECT_ID('model.execution_operation'),
                      OBJECT_ID('model.operation_scenario_invocation'),
                      OBJECT_ID('model.operation_port_invocation'),
                      OBJECT_ID('model.operation_mechanic'),
                      OBJECT_ID('model.capability_scenario'),
                      OBJECT_ID('model.scenario_event'),
                      OBJECT_ID('model.provider_mechanic_implementation'),
                      OBJECT_ID('model.provider_capability_implementation'))
GROUP BY i.object_id, i.name, i.type_desc, i.is_unique
ORDER BY tbl, index_name;


---------------------------------------------------------------------------
-- WHAT TO CONCLUDE
--
--   If (2) "node only" is ~1/6 of (6): the cross join dominates, and passing
--   @target from read-authority.mjs is a one-line fix. scenario-resolver-map.sql
--   already accepts @target and filters on it; the reader sends only
--   capabilityId/scenarioId.
--
--   If "node only" is no faster: the optimizer cannot push the predicate through
--   the COUNT_BIG(*) OVER (PARTITION BY ...) window, and the fix is structural --
--   filter target_language inside the view, or split the three needs into three
--   targeted queries.
--
--   If (2) whole-model closure dominates (1): the recursion, not the fan-out, is
--   the cost, and (5) should show a missing index on the recursive join column.
--
--   If (3a)+(3b)+(3c) together are far below (6): the planner is paying for 187
--   rows x 29 columns to read two columns and a boolean, and the query should be
--   split regardless of what the optimizer does.
--
-- Capture an actual execution plan for the (6) statement alongside these numbers;
-- the timings say which layer, the plan says why.
---------------------------------------------------------------------------
