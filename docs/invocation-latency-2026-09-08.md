# Database invocation latency

This is the original diagnostic record. [Database preparation](database-preparation.md)
now removes the resolver query from invocation; native `sfx` acceptance completes
in about three seconds using one SQL lookup. The earlier shared-load timings
below are not an isolated before/after benchmark.

The resolver query dominates invocation time. A measured executor run on
2026-09-08 spent 120.912 seconds in `scenario-resolver-map.sql`. Generating the
native body took 0.469 seconds; the capability itself executed in 2.639 ms.

| Measured stage | Milliseconds |
| --- | ---: |
| Capability authority query | 1263.5484 |
| Scenario resolver query | 120912.2218 |
| Mechanic definitions query | 1434.5992 |
| All authority reads | 123611.9849 |
| Native body planning | 468.5947 |
| Memory module loading | 60.0635 |
| Scenario construction | 47.1558 |
| Scenario execution | 2.6388 |
| Executor process total | 125295.3640 |

This trace used fresh SQL reads with object retention disabled, the configured
filesystem restrictions, the existing planner and memory loader, and the
provider-resolution example input. It returned `terminated` and
`PROVIDERS_RESOLVED`. The trace is an executor diagnostic, not a successful native
CLI acceptance run. The preceding exact native command was:

```powershell
sfx capability invoke resolve-sidefx-eligible-providers --input '@examples/provider-resolution.request.json' --json
```

That command returned `DELIVERY_TIMEOUT`, exit 4, after 120327.3609 ms. Its
120-second delivery limit expired before the executor could return a result.
No performance repair or successful invocation within that limit is claimed by
this investigation. Another database reader was observed during profiling, so
these wall times are observations under shared load, not isolated benchmarks.

## Whole-estate hypothesis

The selected model has 219 capabilities, 218 declared roots, and 824
capability/scenario pairs. A read-only batch selected all 218 declared roots for
the Node target, projected all resolver columns into a temporary SQL result,
and would have returned bounded per-capability summaries. It did not complete
within 180 seconds; the diagnostic process exited 124 at 180012.3452 ms. A
follow-up DMV read confirmed that its database request was no longer active.
This is a lower bound on that batch's duration, not a complete estate timing.

The batch's live execution plan showed a planned traversal of 824
capability/scenario pairs before its join to the requested roots. At the sampled
point it was executing `analysis.scenario_embodiment_requirements`.

The single-capability estimated plan has a different shape: it seeks exact
`capability_version_pk = 191` and `scenario_version_pk = 701`, then calls
`scenario_embodiment_requirements` with those selected keys. The selected model
is `estate_model_pk = 3`. The requirements function operator has zero estimated
rebinds. Consequently, the absence of a WHERE clause inside the view is not proof
that the single-capability query executes that function for every estate row.
The outer selection is pushed into key seeks in the inspected scoped plan.

The tested batch does not establish that all capability bundles can be computed
for approximately the cost of one. The next query investigation should inspect
the internal recursive transformation/mechanic joins and their execution counts
and cardinality estimates. Bulk bundle publication and a persistent cache were
not introduced. Any future derived cache needs to be bound to the exact database
generation and resolver definition so authority changes cannot reuse stale
resolution evidence.

## Timing evidence

Successful database invocation results now include `evidence.timings`, with an
explicit millisecond unit, individual query durations, planning, memory loading,
Scenario construction/execution, process setup, and process total. The query
timing collector is optional for other `readAuthority` callers. Timings are
diagnostic data and do not change authority identities or kernel outcomes.

The six local embodiment tests passed. Runtime source changes in this slice add
timing evidence only. The local investigation artifacts are under
`evidence/invocation-latency-20260908/`: the native command/result streams, the
executor trace script, bounded batch SQL/result, the live batch plan, and the
single-capability estimated plan. They remain local under the repository's
evidence retention rules.
