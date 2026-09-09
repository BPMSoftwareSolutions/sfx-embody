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
