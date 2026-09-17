# Grafana execution dashboards — research and staged units

**Status.** Proposed 2026-09-17. Scope: display the estate's execution trace in a
Grafana dashboard, live and historically, without weakening the boundaries that
make the trace trustworthy. Authority:
[display-projection-decision-record.md](display-projection-decision-record.md)
(the display is declared; terminals are emitters),
[invisible-execution-authority.md](invisible-execution-authority.md) (the
timing test), [circuit-view-flywheel.md](circuit-view-flywheel.md) (the generic
view), [transistor-model.md](transistor-model.md) (declared vs resolver), and
`src/observation-filter.mjs` (the telemetry allowlist — the governed field
set). Units are staged in
[implementation-plan-next-wave.md](implementation-plan-next-wave.md) §W6.

## The interface already exists

Two artifacts are ready to feed a dashboard, and both are secret-free by
construction:

1. **The observation stream.** Every invocation streams line-delimited JSON on
   stderr (`SFX_OBSERVATION {…}`): delivery phases; cell testimony with
   `cellExecutionId`/`parentCellExecutionId`, `cellId`, `cellAltitude`,
   `scenarioId`, `startedAt`/`completedAt`/`durationMilliseconds`,
   `outcomeVariant`, `logicalOrder`; edge admissions; the streamed
   `display.entry`; and the bounded `providerEvidence`
   (`reachedStage`, `exchangeCount`, `transportDisposition`, `redactionVerified`,
   `httpStatus` when the kernel bound lands). Inputs, bodies and secrets are
   excluded by the allowlist — safe to ship to any collector.
2. **The receipts.** `evidence/**/*.receipt.json` (timing coherence, circuit
   structure, projected installs) carry the per-run accounting the IEA and
   circuit units produce, and `circuit-view.v1` (installed) is the declared
   node/edge view a graph panel wants.

## Path A — Loki (logs first; hours; no estate/SDA code)

Pipe the stream to a file (`cmd /c "sfx capability observe … > out 2>> observations.jsonl"`),
point Promtail (or Grafana Alloy) at it, and build LogQL panels:

- **Execution timeline**: stream selection by `rootExecutionId`, lines ordered by
  `observedAt`, labels from `cellId`/`cellAltitude`/`scenarioId`.
- **Cell durations and statuses**: `durationMilliseconds` distributions per cell
  and altitude; failure variants highlighted from the declared classification.
- **Provider evidence**: route identity per exchange from `providerEvidence`
  and the provider testimony in the outcome.
- **IEA residual**: attributed vs wall span per run — a log-derived metric that
  flags any invocation whose gaps do not close.

Real-time: Loki tail. This path is infrastructure + dashboard JSON only; the
stream is the interface and stays the transport.

## Path B — OTLP traces to Tempo (the trace-shaped view; one generic exporter)

Cell testimony is already span-shaped. One generic exporter maps it to OTLP:

| Testimony | OTLP span |
|---|---|
| invocation (`rootExecutionId`) | one trace |
| cell (`cellExecutionId`, `parentCellExecutionId`) | span with parent link → the circuit's nesting |
| `cellAltitude`, `scenarioId`, semantic address | span attributes |
| `outcomeVariant` + declared classification | span status |
| `durationMilliseconds` (or started/completed) | span duration |
| `providerEvidence`, provider testimony | attributes on the provider/physical spans |
| edge admissions | span events on the consuming cell |

- Tempo ingests spans as they complete, so the Grafana trace waterfall grows
  **live** during execution; the Node Graph panel can render the declared
  `circuit-view.v1` — the terminal circuit and the dashboard become two
  emitters of the same view model.
- Panels: trace waterfall; circuit graph (nodes/edges); timing coherence
  (attributed vs residual per run, from the same receipt fields); provider
  route and rate-limit evidence once `httpStatus` lands; structural coverage
  (planned vs observed counts from `verify:circuit`).
- **Classification.** The exporter is a generic resolver (boot/harness): the
  testimony→OTLP mapping is presentation vocabulary, one adapter over the
  declared fields, never per capability. If mappings must vary, they belong in
  a declared reading (the telemetry-authority item, D5). No SDA change is
  required: the kernel already emits every field the mapping uses.

## Path C — Grafana-native, no collector (deferred)

The Infinity/JSON datasource reading `circuit-view.v1` and the timing reading
directly needs a read-only HTTP endpoint — the deferred **long-lived delivery
host** plus a declared read. Defer with that trigger; not required for a demo
dashboard. A static file server for exported per-run JSON is the acceptable
middle ground (infrastructure, not the invocation path).

## History

Runs are per-invocation; "last N days" dashboards wait on the
**session/ledger unit** (deferred). Until then, batch-import the retained
receipts into Loki/Tempo/Postgres for past-run panels; the honest label is
"imported receipts", not "live history".

## Model evaluation on multiple provider ports

The eval lane already has its research and its principle
([ml-opportunity/README.md](research/ml-opportunity/README.md)): **models provide
intelligence; capabilities own meaning — and orchestration alone is not an
evaluation oracle.** An eval run is therefore just another governed execution:
the conveyor family (`construct-model-role-conveyor-plan`,
`execute-governed-model-role-conveyor`, `determine-model-role-provider-switch`,
`verify-governed-model-invocation-parity`) runs N bindings under declared
ordering, budgets and switching; each attempt is testimony; acceptance comes
from a declared oracle, never from the model.

What that means for the dashboards:

- **The trace shape is already right.** One eval run = one trace; role stage =
  parent span; provider attempt = child span with provider/model identity,
  latency, attempts, failure class and response hash; switching lineage is the
  span tree. The generic OTLP exporter in Path B maps it with no eval-specific
  code.
- **Panels:** per-model and per-provider latency distributions (from span
  durations), readiness/status and failure classes (from the declared
  classifications), attempt counts and substitution lineage, token usage where
  the profile captures it, and side-by-side comparison for replacement
  decisions — both providers on the same role, policy and partition, per the
  lane's replacement rule. Operational panels (latency, attempts,
  timeout/failure rates, cost) sit beside the scenario-obligation panels;
  aggregate metrics and scenario evidence answer different questions.
- **Evidence contract per attempt** (what the eval receipt carries): model and
  provider identities, adapter/profile revision, attempt ordinal and switch
  reason, `durationMilliseconds`, `attemptCount`, response hash, classification
  and failure class, token usage where captured, and the **oracle outcome** for
  the case under evaluation. Raw prompts stay out of the observation channel
  (the allowlist); the eval's own evidence policy decides whether content is
  retained and where — hashes and identities are the default.
- **Multi-provider ports are data.** Each model/provider is a declared
  authority and binding (the conveyor authority already names
  `primary-cognitive-provider`; the credential port already declares an OpenAI
  reference) with its endpoint/credential rules; adding a port is rows plus a
  provider-connection declaration, not new runtime. Quota and rate-limit
  evidence needs the bounded `httpStatus` (request 11) to be visible in
  dashboards.
- **Honest labels.** An automated judge may assist open-ended generations only
  with its own model, rubric and disagreement rate visible, and never as the
  silent source of truth; fixtures are not a corpus; sample counts accompany
  every percentage; thresholds are set before evaluating candidates, not
  invented afterwards; model output is testimony until the oracle admits it.

## What the demo gains

The recording already shows the terminal circuit; the dashboard shows the same
run as a trace waterfall and graph — the control room the target experience
describes — with the IEA residual and structural verdict as panels. Both are
emitters of rows; neither invents status.

## Staged units (detailed in the next-wave plan, §W6)

| Unit | Shape | Acceptance |
|---|---|---|
| G-A Loki ingest + dashboards | Promtail/Alloy config + dashboard JSON; stream captured per invocation | live panels for a fresh equity and agent-lane run: timeline, durations, statuses, provider route; residual panel matches `verify:timing` |
| G-B OTLP exporter + Tempo | one generic exporter (testimony → spans), compose stack, trace/waterfall/graph panels | one trace per invocation with correct parent-child nesting; spans land while the run executes; node graph equals the terminal circuit for the same run |
| G-C Coherence and coverage panels | dashboard queries over receipt fields and span metrics | attributed/residual and planned/observed shown per run; a deliberately failed invocation shows the failure, not a blank panel |
| G-D Receipt batch import | importer for `evidence/**/*.receipt.json` | past runs visible, labeled imported |
| G-E Eval evidence contract | declared eval receipt per attempt (identities, latency, attempts, switch reason, hashes, classification, failure class, oracle outcome) | one real two-provider eval run yields comparable receipts for both candidates on the same role and partition |
| G-F Eval comparison panels | dashboard over the eval receipts and spans (per-model/provider latency, status, failure classes, switching lineage, side-by-side) | replacement candidate compared against the incumbent with sample counts; a failed candidate shows its failure class, not a blank panel |
| G-G Multi-provider-port declaration | provider authorities/bindings for each evaluated port (rows + provider-connection declaration); `httpStatus` for quota evidence | a second provider port resolves and executes under the same capability meaning; quota evidence visible once request 11 lands |
