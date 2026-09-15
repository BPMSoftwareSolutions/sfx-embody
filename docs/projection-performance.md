# Cross-language performance of projected bodies

`scripts/projected-performance.mjs` runs the committed projected bodies of one
canonical capability — node, python and csharp — on the same fixture corpus, in
a separate subprocess per run per target, on one machine, and reports
whole-invocation median/p95 (process startup included), captured execution
testimony, cross-target parity, and per-cell timing **when the testimony carries
it**. It reads only the committed projection: no database, no migration, no
SDA edit, no semantics change.

## What it runs

- Capability: `resolve-equity-market-price-evidence`, projected at
  `embodiments/resolve-equity-market-price-evidence/projected/`.
- Fixture: `equity-qqq-evidence-resolves` (`projected/fixtures/fixtures.json`):
  input `live-equity-price-request.v1` `{symbol: QQQ, region: US}`, expected
  disposition `terminated` and scenario sequence
  `[resolve-equity-market-price-evidence]`. The exchange is live (the request
  resolves the `RAPID_API_KEY` credential from the environment).
- Acceptance per run: process exit 0, `disposition` equals the fixture's
  expected disposition, scenario sequence equals the fixture's, and (when
  `--expect-variant` is given) the outcome variant.
- Parity across targets: one shared `outcomeVariant`, one shared
  `capabilityId`, one shared `canonicalGraphDigest`. `observedPathDigest` is
  recorded per run, not asserted equal: testimony granularity differs per
  target today.

```
node scripts/projected-performance.mjs --runs 3 --out evidence/projected-performance.report.json
```

| option | default | meaning |
| --- | --- | --- |
| `--runs N` | `3` | timed runs per target |
| `--targets a,b,c` | `node,python,csharp` | target subset |
| `--out <json>` | `evidence/projected-performance.report.json` | machine-readable report (gitignored) |
| `--fixture <id>` | first declared fixture | fixture to run |
| `--expect-variant <v>` | unset | additionally require this outcome variant |
| `--projected <dir>` | the equity projection | projected workspace of the same layout |
| `--python <exe>` | `python` | interpreter for the python target |
| `--timeout-ms N` | `600000` | per-process timeout |
| `--omit-results` | off | omit the full per-run result JSON from the report |

Exit codes: `0` parity/disposition admitted, `1` any run failed or parity
diverged, `2` usage. `PER_CELL_TIMING_UNAVAILABLE` and
`OBSERVED_PATH_DIGEST_UNAVAILABLE` are observations, not failures.

## Exact per-target launch commands

Discovered from the generated projects/tests and SDA's acceptance test. The
harness launches exactly these, with `cwd` = estate root and
`SFX_EMBODY_ROOT` set to the estate root for the child (SDA's live projection
tests use that variable to locate the estate; the bodies themselves do not read
it).

**node** — one process, the generated CLI:

```
node embodiments/resolve-equity-market-price-evidence/projected/node/resolve-equity-market-price-evidence-cli.generated.mjs --fixture=equity-qqq-evidence-resolves
```

The CLI prints the full execution result (including `graphExecution` with
`cellTestimony`, `edgeTestimony`, `resolverTestimony`, `observedPathDigest`) as
one JSON line and exits 0 when the fixture disposition matches.

**python** — one process, with the SDA python runtime on `PYTHONPATH`:

```
$env:PYTHONPATH = 'C:\lab\repos\scenario-driven-architecture\languages\python\src'
python embodiments/resolve-equity-market-price-evidence/projected/python/consumer.generated.py --fixture=equity-qqq-evidence-resolves
```

The harness prepends `../scenario-driven-architecture/languages/python/src` to
any existing `PYTHONPATH` and sets `PYTHONIOENCODING=utf-8`; `python` comes from
the PATH (`--python` overrides). No SDA test is used — the generated
`consumer.generated.py` is the CLI and prints the same result shape as node.

**csharp** — build once outside the timed window, then one process per run:

```
dotnet build embodiments/resolve-equity-market-price-evidence/projected/csharp/ProjectedConsumerCli.generated.csproj --nologo -v:q
dotnet embodiments/resolve-equity-market-price-evidence/projected/csharp/bin/Debug/net10.0/ProjectedConsumerCli.dll --fixture=equity-qqq-evidence-resolves
```

The generated csproj references
`..\..\..\..\..\scenario-driven-architecture\languages\csharp\src\ScenarioKernel.Adapters\ScenarioKernel.Adapters.csproj`,
so the SDA checkout must sit beside `sfx-embody` (as it does here). The
preflight build is recorded in the report with its exit code and duration but is
excluded from the timed runs — otherwise `dotnet run`'s MSBuild check would be
charged to every csharp invocation. The equivalent one-command form
`dotnet run --project …\ProjectedConsumerCli.generated.csproj -- --fixture=…`
(the SDA test convention) works too; it is not used for timing for that reason.
The C# body reads its sidecars (`capability-*.json`, `execution-*.json`) from
`AppContext.BaseDirectory`, which is why the built dll is launched rather than
the source directory.

## Reading the report

`performanceReportType: projected-cross-language-performance.v1`.

- `targets.<target>.launch` — the exact command/args/environment used.
- `targets.<target>.preflight` — csharp build (exit code, duration, stderr).
- `targets.<target>.runs[]` — one record per run: `durationMilliseconds`
  (whole invocation, subprocess spawn to exit), `exitCode`, `disposition`,
  `outcomeVariant`, `scenarioSequence`, `observedPathDigest`, testimony counts
  and the observed testimony field names, `stdoutSha256`, `stderr`, and the full
  `result` JSON unless `--omit-results`.
- `targets.<target>.wholeInvocation` — `medianMilliseconds`,
  `p95Milliseconds` (nearest rank), min/max over the timed runs.
- `targets.<target>.perCellTiming` — `AVAILABLE` with per key (cell/edge/pattern
  id) median/p95 when testimony carried timing, otherwise
  `PER_CELL_TIMING_UNAVAILABLE` with the checked fields.
- `identity.<target>` — `capabilityId`, `canonicalGraphDigest`,
  `realizedGraphDigest` read from the target's `capability-carrier.json` and
  `execution-plans/consumer-execution-plan.<target>.v3.json`.
- `parity` — outcome variants per target, the canonical identity comparison, and
  `observedPathDigest.byTargetAndRun`.
- `findings[]` (failures → exit 1), `observations[]` (evidence), `disposition`.

Observed on 2026-09-15 (`--runs 3`). With the live exchange available (exit 0,
`disposition=ADMITTED`):

| target | median | p95 | runs ok | outcome variant | testimony |
| --- | --- | --- | --- | --- | --- |
| node | 613.885 ms | 618.569 ms | 3/3 | `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` | 8 cells, 5 edges, 3 patterns, digest `sha256:ecbe3dea…` |
| python | 707.008 ms | 750.480 ms | 3/3 | `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` | 112 cells, 111 edges, digest absent (`null`) |
| csharp | 619.161 ms | 655.830 ms | 3/3 | `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` | 5 cells, 2 edges, no digest field |

Later re-runs, the exchange answering a provider failure
(`PROVIDER_EXCHANGE_NOT_COMPLETED`): all three targets shared
`EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE` and the harness still admitted (exit
0) — node 477.290/482.568 ms median/p95, python 530.193/568.885 ms, csharp
506.652/608.632 ms. One intermediate run had python resolve while csharp fell
back; the harness exited 1 with `OUTCOME_VARIANT_DIVERGED`, exactly as the
parity check intends. The stable acceptance is the *shared* variant and
disposition, not a particular price or fetch outcome at a given minute.

Shared canonical identity: `capabilityId=resolve-equity-market-price-evidence`,
`canonicalGraphDigest=sha256:6d8e145c32ebc8629dab66e0be7fe88e135968b4bdcd888ee3e266d712b41dbf`
in all three. `realizedGraphDigest` differs per target by design. The fetch
dominates in all three (~500–700 ms), so this corpus measures startup + one live
exchange call, not a CPU-bound loop.

## The per-cell timing gap

The harness reads per-cell durations **only** from `graphExecution` testimony
and never synthesizes, wraps or wall-clocks individual cells. Evidence from the
run above (`observations[0]`):

```
PER_CELL_TIMING_UNAVAILABLE
checkedFields: ["durationMilliseconds","startedAt","completedAt"]
node   cell fields: cellExecutionId cellId disposition logicalOrder outcomeDigest outcomeVariant providerProfileId testimonyType
python cell fields: cellExecutionId cellId disposition logicalOrder outcomeDigest outcomeVariant providerProfileId testimonyType
csharp cell fields: cellAltitude cellExecutionId cellId disposition logicalOrder occurrenceId outcomeDigest outcomeVariant providerProfileId
```

A tree-wide search for the timing field names in the projected bodies returns
zero matches in node, python and csharp. This is a projection-emitter gap, not a
kernel gap: the kernels already stamp timing (node
`SDA:languages/typescript/runtimes/node/semantic-execution-graph/scheduler.js`
builds `startedAt`/`completedAt`/`durationMilliseconds`; python
`SDA:languages/python/src/scenario_kernel/platform/execution_graph.py`; csharp
`SDA:languages/csharp/src/ScenarioKernel.Adapters/Graph/SemanticExecutionGraphScheduler.cs`),
but the projected bodies are standalone generated programs that interpret their
plans directly and do not run through the kernel scheduler, so kernel timing
never reaches their testimony.

**Exact SDA change needed (change request — this estate must not edit SDA).**
The three per-language capability-execution emitters must add timing to the
testimony they generate:

- `SDA:tools/src/consumer-projection/projection/node/capability-execution-emitter.ts`
  — `recordPatternTestimony`, `recordCellTestimony`, `recordEdgeTestimony`;
- `SDA:tools/src/consumer-projection/projection/python/capability-execution-emitter.ts`
  — `_record_cell`, `_record_edge`;
- `SDA:tools/src/consumer-projection/projection/csharp/capability-execution-emitter.ts`
  — `RecordEdge`, `RecordCell` (and pattern recording where present).

Each emitter should capture `startedAt` (ISO or epoch ms) and a monotonic start
around the step, then emit `startedAt`, `completedAt` and
`durationMilliseconds` on the testimony object, using the kernel scheduler's
field names and units (milliseconds) so `sfx capability observe` and this harness
read the same keys. Once the emitters do that, the harness's
`targets.<target>.perCellTiming` becomes `AVAILABLE` with median/p95 per
`cellId`/`edgeId`, with no harness change.

Two secondary emitter gaps surfaced as observations, worth folding into the same
change request:

- python hardcodes `"observedPathDigest": None` in the composed
  `graphExecution` (`consumer-execution.generated.py`); node computes a real
  digest over its testimony.
- csharp's composed `graphExecution` omits `observedPathDigest` and
  `resolverTestimony` entirely; node carries both, python carries the
  `observedPathDigest` key as `null` and no `resolverTestimony`.
- Testimony granularity differs across targets (node 8 cells / python 112 /
  csharp 5), so `observedPathDigest` is not comparable across targets today and
  the harness records it as evidence rather than a parity assertion.

## Live-network variance

The fixture resolves against a live exchange; prices, market time, state and
source attribution vary by fetch time. The harness therefore asserts only the
stable acceptance — disposition, scenario sequence, variant agreement and
canonical identity — and keeps raw prices only inside the captured per-run
`result`. Consequences to expect:

- `observedPathDigest` may differ run to run (node) and differs across targets
  for the granularity reasons above.
- If one target's fetch fails while another's succeeds, its outcome variant
  flips to the provider-unavailable branch and the harness exits 1 with
  `OUTCOME_VARIANT_DIVERGED`; that is a network event, not necessarily a body
  defect. Re-run to confirm.
- `RAPID_API_KEY` must be present for the live branch. Without it the bodies
  fall back and the run is not comparable; pass `--expect-variant` only when
  the live credential is guaranteed.
