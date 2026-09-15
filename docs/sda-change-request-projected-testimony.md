# SDA change request: projected-body testimony timing and cross-target parity (F1/F2)

**Status.** Open request, authored by the estate (reader side) on 2026-09-15.
`scenario-driven-architecture` is read-only for this repo; nothing here is an
edit to SDA.

**Why this request exists.** `docs/architecture-priorities.md` §3 carries F1
(every projected body records cell/edge/resolver testimony with digests and
logical order but **no timing fields**) and F2 (the three targets' testimony is
not parity: python `observedPathDigest: null`, csharp omits
`observedPathDigest` and `resolverTestimony`, and the observed cell sets differ
8 / 112 / 5 on the resolved branch in `docs/projection-performance.md`; 8 / 111 /
5 on today's F6 provider-unavailable branch). The fix belongs to the SDA
projection emitters (the generated bodies are owned artifacts; the estate must
not hand-edit them), so this is the formal request plus
`scripts/verify-projected-testimony.mjs`, the probe that must flip from
`TESTIMONY OPEN` to `TESTIMONY CLOSED`.

## 1. Primitive

**Stamp every generated cell / edge / pattern testimony record with the kernel
schedulers' timing fields — same names, same units, same capture points — and
bring the three projection targets to testimony parity.**

### 1.1 Timing fields (names and semantics copied from the schedulers)

Every generated cell-execution, edge-execution and pattern(resolver)-execution
testimony object gains exactly these fields:

| field | node (kernel scheduler) | python (kernel scheduler) | csharp (kernel scheduler) |
| --- | --- | --- | --- |
| `startedAt` | `new Date().toISOString()` (`languages/typescript/runtimes/node/semantic-execution-graph/scheduler.js:61`, sampled at `:122` cells / `:175` edges, stamped at `:223` / `:359`) | `datetime.now(timezone.utc).isoformat()` (`languages/python/src/scenario_kernel/platform/execution_graph.py:31-32`, `:85`; values at `:152`, `:207`, `:247`) | `DateTimeOffset.UtcNow`, formatted `yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'` (`languages/csharp/src/ScenarioKernel.Adapters/Graph/SemanticExecutionGraphScheduler.cs:99`, `:155`, `:244`, `FormatTimestamp` `:389-390`) |
| `completedAt` | same wall clock, sampled after the step (`scheduler.js:223`, `:359`) | same, after the step (`execution_graph.py:153`, `:208`, `:248`) | same, after the step (`Scheduler.cs:382-385`) |
| `durationMilliseconds` | `Math.round((performance.now() - startedMono) * 1000) / 1000` (`scheduler.js:62`, `:250-251`, stamped `:224`, `:359`) | `time.perf_counter()` delta (`execution_graph.py:86`, `:154`, `:209`, `:249`) | `(completedMono - startedMono) * 1000.0 / Stopwatch.Frequency` (`Scheduler.cs:100`, `:386`) |

Capture points must match the kernel's: start is sampled before the cell work
(before the pattern resolver / operation dispatch) and before edge binding /
join projection and routing; completion after the work and after the edge
admission decision. Timing is per record, on every record — cells, edges and
resolver/pattern records.

**Missing timing is a hard refusal or an explicit absence — never a fabricated
or default value.** If a generated body cannot obtain a clock it must either
fail the execution or omit the field keys entirely (explicit absence); it must
not emit `0`, `null`, a constant, or a value copied from the whole-invocation
clock. The probe validates: finite non-negative `durationMilliseconds`,
parseable `startedAt`/`completedAt`, `completedAt >= startedAt`, and no record
missing any of the three fields.

### 1.2 `observedPathDigest`

Every target's `graphExecution.observedPathDigest` is present and a non-null
`sha256` string, computed with the kernel schedulers' subject and semantics,
ordered by `logicalOrder`:

- cells: `{ cellId, occurrenceId, iterationId (null when absent), outcomeVariant, disposition }`
  (node `languages/typescript/runtimes/node/semantic-execution-graph/topology-verifier.js:3-7`
  `observedPathDigest`; python `execution_graph.py:283-293`; csharp
  `Scheduler.cs:320-345`);
- edges: `{ edgeId, iterationId (null when absent), admissionDisposition }`.

For an identical declared-fixture execution (all targets reach the same
`outcomeVariant`) the three digests are **equal**. Aligning this requires the
same occurrence convention in all three generated bodies: occurrence is 1-based
and `occurrenceId` equals `cellExecutionId` equals
`<rootExecutionId>:<cellId>:<occurrence>` as in `scheduler.js:119-121`, with the
same root execution id convention (the carrier's `capabilityId`).

The node generated body today computes a *different* digest subject
(`{cells:[{cellId,cellExecutionId}], edges:[edgeId]}` — see §3); that dialect
must be replaced, not preserved, or the three targets can never agree.

### 1.3 `resolverTestimony` present in all targets

Every target's `graphExecution` carries `resolverTestimony` as an array — the
pattern/resolver executions actually performed, with the same record shape the
node body already emits (`testimonyType`, `patternType`, `patternId`,
`groupId` when present, `logicalOrder`) plus the timing fields of §1.1. An
explicit empty array `[]` is acceptable when no pattern executed; omitting the
key is not. For an identical declared-fixture execution the resolver record
counts agree across targets (a target that records pattern executions while
another explicitly records none is a parity gap).

### 1.4 Testimony addresses the same canonical cell ids

Comparison criterion (this is what the probe enforces; counts alone are not
enough):

1. **Canonical reference.** For target `T`, let
   `C_T = { cell.cellId | cell ∈ canonicalGraph.cells }` from
   `execution-plans/consumer-execution-plan.<T>.v3.json`. The canonical graph is
   language-neutral: all three plans must declare the same
   `canonicalGraphDigest` and the same `C_T`.
2. **Membership.** Every `cellId` observed in target `T`'s `cellTestimony`
   belongs to `C_T`. No semantic-normalized carrier key, no route alias.
3. **Set equality, not count equality.** For an identical declared-fixture
   execution (all targets share `outcomeVariant`), the observed cell-id sets are
   equal: `O_node = O_python = O_csharp`. Granularity differences (8 / 111 / 5
   today) are the defect; the recorded altitude is one record per canonical cell
   actually executed, as the kernel scheduler does (every cell a token visits,
   including expression/decomposition entries).
4. **Occurrence parity.** For each shared `cellId`, the number of records and
   their relative order (`logicalOrder`) agree across targets. The shared
   `observedPathDigest` is the end-to-end proof of this; the probe reports
   per-cell occurrence mismatches when sets match but counts do not.

Python additionally records **normalized** ids today (e.g.
`...expression.fields.credentialreference` vs canonical
`...expression.fields.credentialReference` — all 70 foreign unique ids on the
current fixture are semantic-id normalized forms). Testimony must carry the
canonical `cellId`.

## 2. Why kernel

- The testimony shape is the kernel's observable contract, not a projection
  choice: `sfx capability observe`, the estate's planned-vs-observed overlay and
  `scripts/projected-performance.mjs` read the same keys from every target.
  Cross-language comparison is only meaningful if all three speak the kernel's
  field names and digest semantics.
- Field names and units cannot be "selected as data": the testifying code is
  generated per language, so the emitters are the only place the behavior can
  exist (per `docs/embodiment-completeness.md`). A database row cannot make a
  generated program write a field it never writes.
- The generated bodies are **not** the kernel scheduler: they are standalone
  carrier walkers that invoke pattern resolvers / compiled operations /
  declared ports directly. The kernel timing code
  (`GraphTokenScheduler`, `SemanticExecutionGraphScheduler`, python
  `ExecutionGraphScheduler`) never runs on the projected path, so its timing
  never reaches projected testimony. The emitters must reproduce the kernel's
  names and semantics — inventing new names would break every existing reader.

## 3. Exact SDA files / functions to change (line evidence)

All paths below are relative to `C:\lab\repos\scenario-driven-architecture`.

| # | file | function / site | current state | gap |
| --- | --- | --- | --- | --- |
| 1 | `tools/src/consumer-projection/projection/node/capability-execution-emitter.ts` | `recordPatternTestimony` `734-742` | emits `testimonyType, patternType, patternId, groupId?, logicalOrder` | no timing |
| 2 | same | `recordCellTestimony` `744-758` | emits `cellId, cellExecutionId, providerProfileId, outcomeVariant, disposition, outcomeDigest, logicalOrder` | no timing; no `occurrenceId`/`iterationId` |
| 3 | same | `recordEdgeTestimony` `760-774` | emits `edgeId("route:"+from+"->"+to), sourceCellId, destinationCellId, edgeKind?, groupId?, joinSlotId?, selectsVariant?, bindingAuthorityId?, admissionDisposition, logicalOrder` | no timing |
| 4 | same | `observedPathDigest` `1157-1162` | `{cells:[{cellId,cellExecutionId}], edges:[edgeId]}` | not the kernel subject of §1.2 |
| 5 | same | composed `graphExecution` `1241-1249` | has `resolverTestimony` `1247`, `observedPathDigest` `1248` | digest subject must change to kernel shape |
| 6 | `tools/src/consumer-projection/projection/python/capability-execution-emitter.ts` | `_record_cell` `542-557` | emits `testimonyType, cellId, cellExecutionId, providerProfileId, outcomeVariant, disposition, outcomeDigest, logicalOrder`; id is the carrier key (`_semantic_id` applied; `execution-operations.json` carries normalized ids, e.g. `...credentialreference`) | no timing; normalized ids; occurrence 0-based |
| 7 | same | `_record_edge` `560-576` | emits carrier route fields + `admissionDisposition, logicalOrder` | no timing |
| 8 | same | pattern execution (`_resolve_pattern` `1294`, `resolver(...)` `~920`) | no pattern testimony array exists (`_CELL_TESTIMONY`/`_EDGE_TESTIMONY` only, `504-505`) | no `resolverTestimony`, no pattern timing |
| 9 | same | composed `graphExecution` `1133-1140` | `"observedPathDigest": None` `1139`; no `resolverTestimony` | digest missing; resolver testimony missing |
| 10 | `tools/src/consumer-projection/projection/csharp/capability-execution-emitter.ts` | `RecordEdge` `1233-1241` | emits `edgeId, admissionDisposition, logicalOrder` | no timing |
| 11 | same | `RecordCell` `1397-1413` | emits `cellId, cellAltitude, cellExecutionId, occurrenceId, outcomeVariant, outcomeDigest, disposition, providerProfileId, logicalOrder` | no timing |
| 12 | same | pattern execution (`ExecutionPatternResolvers.*` dispatch `~360`) | no pattern testimony list or recorder exists | no `resolverTestimony`, no pattern timing |
| 13 | same | `Compose` `1459-1478` | `graphExecution` `1469-1476` has `cellTestimony`/`edgeTestimony` only | no `observedPathDigest`, no `resolverTestimony` |

**Generated-body counterparts** (estate-owned artifacts regenerated from the
emitters; listed to show exactly where the runtime records testimony today —
they execute resolvers directly and never construct the kernel scheduler):

| target | file | testimony sites |
| --- | --- | --- |
| node | `embodiments/resolve-equity-market-price-evidence/projected/node/capability-execution.generated.mjs` | `recordPatternTestimony` `258`, `recordCellTestimony` `268`, `recordEdgeTestimony` `284`; digest `681-686`; `graphExecution` `765-773` |
| python | `embodiments/.../projected/python/consumer-execution.generated.py` | `_record_cell` `120`, `_record_edge` `138`; `graphExecution` `710-717` (`observedPathDigest: None` `716`) |
| csharp | `embodiments/.../projected/csharp/Program.generated.cs` | `RecordEdge` `881-889`, `RecordCell` `1045-1061`; `Compose` `1107-1126` |

Tree-wide search receipt: zero occurrences of `durationMilliseconds`,
`startedAt` or `completedAt` across the three generated bodies (`.mjs`, `.py`,
`.cs` under the projected workspace).

## 4. Affected languages

node, python, csharp — the three admitted consumer-projection targets (all three
emitters and their regenerated bodies). No java/go consumer target exists today
(`ConsumerProjectionTarget = "node" | "csharp" | "python"`,
`tools/src/consumer-projection/model/consumer-workspace-facts.ts:3`).

## 5. Data that binds it

- Capability `resolve-equity-market-price-evidence`; projected workspace
  `embodiments/resolve-equity-market-price-evidence/projected/`.
- Fixture `equity-qqq-evidence-resolves` (`projected/fixtures/fixtures.json`):
  input `live-equity-price-request.v1` `{symbol: QQQ, region: US}`, expected
  disposition `terminated`. F6 means the live exchange may fall back to
  `EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE`; acceptance must not require a
  successful exchange.
- Generated carriers/patterns:
  `capability-carrier.json`, `execution-patterns.json`,
  `execution-operations.json`, and
  `execution-plans/consumer-execution-plan.{node,python,csharp}.v3.json`
  (`canonicalGraph.cells` — 149 cells, `canonicalGraphDigest`
  `sha256:6d8e145c…` shared by all three).
- Regeneration: `sfx capability project resolve-equity-market-price-evidence
  --workspace embodiments/resolve-equity-market-price-evidence --full-mechanics`.
- Estate acceptance probe: `scripts/verify-projected-testimony.mjs`.

## 6. Evidence — the gaps as re-verified 2026-09-15

Commands (estate root; python with the SDA python `src` on `PYTHONPATH`; csharp
prebuilt dll launched from `bin/Debug/net10.0`):

```
node embodiments/resolve-equity-market-price-evidence/projected/node/resolve-equity-market-price-evidence-cli.generated.mjs --fixture=equity-qqq-evidence-resolves
python embodiments/resolve-equity-market-price-evidence/projected/python/consumer.generated.py --fixture=equity-qqq-evidence-resolves
dotnet embodiments/resolve-equity-market-price-evidence/projected/csharp/bin/Debug/net10.0/ProjectedConsumerCli.dll --fixture=equity-qqq-evidence-resolves
node scripts/verify-projected-testimony.mjs
```

Observed (all three: exit 0, `disposition=terminated`,
`outcomeVariant=EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE` — F6 fallback branch,
so acceptance does not depend on the exchange):

| target | cells | edges | patterns | observedPathDigest | cell fields | edge fields |
| --- | --- | --- | --- | --- | --- | --- |
| node | 8 | 5 | 3 (`resolverTestimony`) | `sha256:ecbe3dea…` | `testimonyType, cellId, cellExecutionId, providerProfileId, outcomeVariant, disposition, outcomeDigest, logicalOrder` | `testimonyType, edgeId, sourceCellId, destinationCellId, edgeKind, admissionDisposition, logicalOrder` |
| python | 111 (110 unique) | 110 | absent | key present, value `null` | same shape, ids normalized | same shape |
| csharp | 5 | 2 | absent | key absent | `cellId, cellAltitude, cellExecutionId, occurrenceId, outcomeVariant, outcomeDigest, disposition, providerProfileId, logicalOrder` | `edgeId, admissionDisposition, logicalOrder` |

No timing field appears in any of the three. The probe's current report
(excerpt, exit 1):

```
projected testimony verification - equity-qqq-evidence-resolves
  canonicalPlanCells 149
  node     exit 0  variant EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE  cells 8 (8 unique)  edges 5  resolverTestimony 3  observedPathDigest sha256:ecbe3deab8fa893...
          cell    timing incomplete (durationMilliseconds absent on 8/8 records; startedAt absent on 8/8 records; completedAt absent on 8/8 records)
          edge    timing incomplete (durationMilliseconds absent on 5/5 records; startedAt absent on 5/5 records; completedAt absent on 5/5 records)
          pattern timing incomplete (durationMilliseconds absent on 3/3 records; startedAt absent on 3/3 records; completedAt absent on 3/3 records)
  python   exit 0  variant EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE  cells 111 (110 unique)  edges 110  resolverTestimony MISSING  observedPathDigest MISSING
  csharp   exit 0  variant EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE  cells 5 (5 unique)  edges 2  resolverTestimony MISSING  observedPathDigest MISSING
  parity  variant shared EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE
          node/python     cell sets differ (left-only 0, right-only 102)
          node/csharp     cell sets differ (left-only 3, right-only 0)
          python/csharp   cell sets differ (left-only 105, right-only 0)
          observedPathDigest unverifiable
  gaps
    node: TIMING_FIELDS_MISSING - durationMilliseconds absent on 8/8 records; startedAt absent on 8/8 records; completedAt absent on 8/8 records
    node: TIMING_FIELDS_MISSING - durationMilliseconds absent on 5/5 records; startedAt absent on 5/5 records; completedAt absent on 5/5 records
    node: TIMING_FIELDS_MISSING - durationMilliseconds absent on 3/3 records; startedAt absent on 3/3 records; completedAt absent on 3/3 records
    python: TIMING_FIELDS_MISSING - durationMilliseconds absent on 111/111 records; startedAt absent on 111/111 records; completedAt absent on 111/111 records
    python: TIMING_FIELDS_MISSING - durationMilliseconds absent on 110/110 records; startedAt absent on 110/110 records; completedAt absent on 110/110 records
    python: OBSERVED_PATH_DIGEST_MISSING - observedPathDigest is present but null
    python: RESOLVER_TESTIMONY_MISSING - graphExecution.resolverTestimony key is absent
    python: CELL_ID_NOT_CANONICAL - 70 observed cellId(s) are not canonicalGraph.cells ids; 70 are semantic-id normalized forms of canonical ids (e.g. cell:mechanic:resolve-equity-market-price-evidence.operation.1:expression.fields.credentialreference)
    csharp: TIMING_FIELDS_MISSING - durationMilliseconds absent on 5/5 records; startedAt absent on 5/5 records; completedAt absent on 5/5 records
    csharp: TIMING_FIELDS_MISSING - durationMilliseconds absent on 2/2 records; startedAt absent on 2/2 records; completedAt absent on 2/2 records
    csharp: OBSERVED_PATH_DIGEST_MISSING - observedPathDigest key is absent
    csharp: RESOLVER_TESTIMONY_MISSING - graphExecution.resolverTestimony key is absent
    parity: OBSERVED_CELL_SET_NOT_SHARED - node vs python: node-only 0; python-only 102 (...)
    parity: OBSERVED_CELL_SET_NOT_SHARED - node vs csharp: node-only 3 (...expression cells...); csharp-only 0
    parity: OBSERVED_CELL_SET_NOT_SHARED - python vs csharp: python-only 105 (...)
    parity: RESOLVER_TESTIMONY_COUNT_NOT_SHARED - node=3, python=0, csharp=0
    parity: OBSERVED_PATH_DIGEST_PARITY_UNVERIFIABLE - python, csharp expose no digest to compare
TESTIMONY OPEN
```

## 7. Acceptance

After the emitters change and the estate regenerates
(`sfx capability project … --full-mechanics`):

```
node scripts/verify-projected-testimony.mjs --expect-closed
```

prints `TESTIMONY CLOSED` and exits 0 — for the F6 provider-unavailable fallback
(today's reachable branch) and, when the exchange is available, for the resolved
execution. Concretely, per target: timing complete on every cell/edge/pattern
record with valid values; `observedPathDigest` present, non-null, equal across
targets; `resolverTestimony` present; every observed cell id canonical; observed
cell-id sets and per-cell occurrence counts equal across targets. Until then the
probe exits 1 with `TESTIMONY OPEN` and the exact missing pieces; it never
retries the exchange and never synthesizes a timing value.

## 8. Notes and open points

- **Digest subject choice.** The probe compares digests as opaque strings, so any
  shared canonical subject closes the parity check; the kernel's
  `topology-verifier`/scheduler subject is the recommended target because
  `sfx capability observe` already speaks it. What cannot stand is three
  dialects (node's `cellExecutionId`-only subject, python's `None`, csharp's
  absence).
- **Altitude.** Node's 8-cell and csharp's 5-cell observations are not a
  smaller true path: the kernel scheduler records every visited canonical cell,
  including expression-level entries, and python's coverage is closest to that.
  The emitters should converge on the kernel altitude rather than on each
  other's subset.
- **Edge addresses.** Generated testimony currently carries carrier route keys
  (`route:<from>-><to>`) rather than `canonicalGraph.edges[].edgeId`. The cell
  criterion is what F1/F2 requires; digest parity remains possible if all
  targets use the same route-key convention. Flagged for awareness, not
  demanded here.
- **F6.** The declared RapidAPI credential is rate-limited to zero, so closure
  must be demonstrable on the `EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE` branch;
  a later resolved-branch run is desirable but environment-dependent.
- **F3 interaction.** Python/C# codegen patterns are rendered by the tools
  emitters and semantically verified only; any new pattern-timing code in those
  emitters is subject to the same provenance caveat before digest-bound release.
