# Declared LLM-provider STUBS at every authoring altitude

**Date:** 2026-09-22. **Surface:** `authoring-altitude-model-stubs` in the selected
estate model. **Question:** can an LLM-provider stub be declared at every authoring
altitude as database rows and resolve and execute? **Result:** yes — declared,
installed, replayed idempotently, invoked through the installed kernel (exit 0), and
all 11 stub scenarios/ports testify in the observation lane. No blocker remains.

## 1. What was declared

One new capability `authoring-altitude-model-stubs` carries 11 STUB scenarios, one per
altitude. Every scenario declares exactly one STUB port bound to
`sda-authority-transformation-port.v1`; its transformation emits one canned
altitude-shaped output literal and nothing else. The altitude outputs chain by contract
equality — altitude N's declared output contract is altitude N+1's declared input
contract — and the root runs its own stub first and then invokes altitudes 2..11 in
order, so one invocation executes all 11 stubs. This is the estate's working drop-in
composition pattern (contract equality on every `invoke-scenario` edge and on the
trailing invoke), the constraint that makes the graph scheduler admit the composition
without a synthesized invoke-return binding.

| # | altitude (tool ref) | scenario | stub port | output contract |
| ---: | --- | --- | --- | --- |
| 1 | feature parse (`feature.resolve`) | `authoring-altitude-model-stubs` (root) | `authoring-altitude-model-stubs-port` | `altitude-1-feature-parse-output.v1` |
| 2 | capability meaning (`meaning.author`) | `altitude-2-capability-meaning` | `…-stub-port` | `altitude-2-capability-meaning-output.v1` |
| 3 | scenario I/E/O (`scenario.author`) | `altitude-3-scenario-io` | `…-stub-port` | `altitude-3-scenario-io-output.v1` |
| 4 | contracts/schemas (`contract.author`) | `altitude-4-contracts-schemas` | `…-stub-port` | `altitude-4-contracts-schemas-output.v1` |
| 5 | semantic authority envelope (`semantics.author`) | `altitude-5-semantic-authority-envelope` | `…-stub-port` | `altitude-5-semantic-authority-envelope-output.v1` |
| 6 | transformation AST (`ast.author`) | `altitude-6-transformation-ast` | `…-stub-port` | `altitude-6-transformation-ast-output.v1` |
| 7 | execution authorities/ports (`authority.author`) | `altitude-7-execution-authorities-ports` | `…-stub-port` | `altitude-7-execution-authorities-ports-output.v1` |
| 8 | providers/bindings/overlays (`provider.author`) | `altitude-8-providers-bindings-overlays` | `…-stub-port` | `altitude-8-providers-bindings-overlays-output.v1` |
| 9 | interface/CLI display (`interface.author`) | `altitude-9-interface-cli-display` | `…-stub-port` | `altitude-9-interface-cli-display-output.v1` |
| 10 | fixtures/proof (`fixture.author`) | `altitude-10-fixtures-proof` | `…-stub-port` | `altitude-10-fixtures-proof-output.v1` |
| 11 | alignment evaluation (`alignment.evaluate`) | `altitude-11-alignment-evaluation` | `…-stub-port` | `altitude-11-alignment-evaluation-output.v1` |

Counts: **11 scenarios, 11 STUB ports, 11 transformations, 11 execution authorities,
12 contracts** (one shared request `authoring-altitude-model-stubs-request.v1` plus one
output per altitude). The request has no required members, so `{}` is the smallest
declared input. Output schema shapes are minimal and derived from
`docs/llm-authoring-tools-2026-09-21/tool-to-altitude.v1.json` and
`tool-registry-and-write-sql.md`; each canned object names its `shapeSource`
(`tool-to-altitude.v1.json#<toolId>`). The root's declared outcome is the LAST
altitude's output contract, because the root's trailing operation is the invoke of
altitude 11.

Everything is authored with existing procedures only: `model.declare_contract`,
`model.scaffold_capability`, `model.put_semantic_definition`,
`model.normalize_transformation_expression`, `model.declare_scenario`,
`model.declare_capability_feature`, plus the composed-authority mint pattern of
`declare-run-declared-graph-capability.sql`, `declare-two-child-routing-proof.sql`
and `declare-agent-capability.sql`. No existing capability, contract, scenario, port,
transformation, authority or provider row was modified. Port and scenario declarations
carry explicit `STUB` markers in names, feature text and comments.

## 2. Dry-run (ROLLBACK) and idempotence

```
node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/run-migration.mjs sql/migrations/declare-authoring-altitude-model-stubs.sql
```

Evidence: `evidence/dry-run.txt`. The transaction prints: 3 baseline graph digests,
11 declared stubs with their input/outcome contracts and ports, 12 contracts, 11 stub
ports (`platformCapabilityId` = `sda-authority-transformation-port.v1`), 11 graph
authorities, 11 resolved graph scenarios, the before/after digest comparison, and the
disposition.

- Unrelated capabilities unchanged, before vs after **inside the transaction**:
  - `say-hello-world` `bb67e421…` → `bb67e421…` UNCHANGED (22,582 bytes)
  - `route-two-child-proof` `5bebead6…` → `5bebead6…` UNCHANGED (13,864 bytes)
  - `resolve-equity-market-price-evidence` `7ea23f4f…` → `7ea23f4f…` UNCHANGED (123,410 bytes)
- Declaration graph digest: `a7d4d6984a37a19561c7e445fd78d16532cd61654c8f5677df7bdf32bd12fa80`.
- Root authority: 11 operations, 10 `invoke-scenario`; disposition `declared`.

From-transaction preflight before install
(`invoke-from-transaction.mjs <dry-run file> authoring-altitude-model-stubs <input>`),
input `{}`: `DISPOSITION completed`; outcome = altitude-11's canned output; 122 cells
executed; 11 closure scenarios; evidence `evidence/preflight.txt`.

Install (`evidence/install.txt`) and replay (`evidence/replay.txt`) of the committed
copy (`COMMIT TRANSACTION`) print the same graph digest and replay as
`"disposition":"already_declared"` with an identical digest — the declaration gate
skips everything on a second run.

## 3. Invocation through the installed kernel

```
sfx capability invoke  authoring-altitude-model-stubs --input {} --json
sfx capability observe authoring-altitude-model-stubs --input {} --json
sfx capability observe authoring-altitude-model-stubs --input {} --json --trace
```

- `invoke`: exit 0, stdout 438 bytes, stderr empty — stdout is exactly the altitude-11
  canned output: `{"contractId":"altitude-11-alignment-evaluation-output.v1","altitude":11,
  "altitudeId":"altitude-11-alignment-evaluation",…,"canned":{…}}`. Evidence:
  `evidence/invoke.stdout.txt`, `evidence/invoke.stderr.txt`.
- `observe`: exit 0, stdout identical (438 bytes), stderr empty. Evidence:
  `evidence/observe.stdout.txt`, `evidence/observe.stderr.txt`.
- Lane: the observability sink at `http://localhost:8787/events?run=last` replayed for
  the observe run (SSE, HTTP 200). Filtered to this capability:
  `evidence/sse.events.trace.ndjson` → `evidence/sse.stub-testimony.trace.ndjson`.
  **122 distinct cells testify**, including all **11 scenario cells**
  (`cell:scenario:altitude-*`, disposition `completed`, each naming its in/out
  contracts) and all **11 stub operation/port cells**
  (`cell:mechanic:altitude-*.operation.1`, disposition `completed`), plus the root's
  11 operations and every transformation expression cell. No `failed`/`HELD` event in
  the filtered lane. Summary: `evidence/sse.trace.summary.txt`.

Sample lane lines (from `evidence/sse.stub-testimony.ndjson`):

```
data: {… "cls":"cell","text":"cell-execution-testimony.v1 cell=cell:scenario:altitude-2-capability-meaning address=authoring-altitude-model-stubs/scenario/altitude-2-capability-meaning disp=completed in=altitude-1-feature-parse-output.v1 payload(613B) out=altitude-2-capability-meaning-output.v1 payload(613B) …" …}
data: {… "cls":"cell","text":"cell-execution-testimony.v1 cell=cell:scenario:altitude-11-alignment-evaluation … in=altitude-10-fixtures-proof-output.v1 … out=altitude-11-alignment-evaluation-output.v1 …" …}
```

## 4. Inspection SQL (validated)

`evidence/inspection.sql` (read-only, run through the migration runner), output
`evidence/inspection.txt`:

- `i1_stub_altitudes` — 11 rows: each altitude with its scenario, input contract,
  outcome contract, terminal flag, stub port (`sda-authority-transformation-port.v1`),
  transformation id, authority id and port definition digest.
- `i2_graph_source_counts` — from `analysis.capability_graph_source(...)`, the
  kernel declared-read/compilation input: **11 scenarios, 11 authorities, 11 port
  bindings, 11 transformations, 12 contract authorities**, root
  `authoring-altitude-model-stubs`, digest `a7d4d698…` (identical to the dry-run and
  install runs).
- `i3_graph_scenario_resolution` — all 11 scenarios resolve with non-null input and
  outcome contracts and their event authority.
- `i4_root_authority_operations` — root: 11 operations, 10 `invoke-scenario`.
- `i5_declared_read_documents` — 22 assembled documents, including every one of the 12
  contract schemas, the contract catalog, capability, execution-authorities,
  interfaces and consumer-workspace documents.

## 5. Blockers

Two authoring defects were found and fixed during the dry-run/preflight loop; neither
is an estate blocker:

1. **Invoke-return binding.** With the root's declared outcome set to altitude 1's
   output, the trailing `invoke-scenario` (altitude 11) entered with altitude 10's
   carrier and exited with altitude 11's, so the compiler synthesized
   `binding:invoke-return:cell:mechanic:authoring-altitude-model-stubs.operation.11`
   and the scheduler refused with `UNDECLARED_EDGE_BINDING_MECHANIC`. Fix: declare the
   root outcome as the last altitude's output contract — the same contract-equality
   rule the estate's working compositions use. No kernel change, no binding fabricated.
2. **Stale shell identity.** The composed-authority mint ran before the capability's
   `capability_pk` was re-read after `model.scaffold_capability`, so the root's
   scenario-invocation links and event link were not written. Fix: re-read the pk after
   the shell. Also, the shell's default request/greeting contracts collided with the
   shared request contract id, producing a second contract version; the shell now
   declares placeholder contract ids.

Final state: **no blocker** — declared, resolved, installed, replayed, invoked and
observed end to end. Nothing about any altitude prevented declaration or execution.

## 6. Files

| Path | Role |
| --- | --- |
| `sql/migrations/declare-authoring-altitude-model-stubs.sql` | Dry-run copy (ends `ROLLBACK TRANSACTION`) |
| `sql/migrations/declare-authoring-altitude-model-stubs.commit.sql` | Install copy (ends `COMMIT TRANSACTION`) |
| `docs/authoring-altitude-model-stubs-2026-09-21/analysis.md` | This record |
| `docs/authoring-altitude-model-stubs-2026-09-21/evidence/` | Captures (local receipts; `.gitignore` ignores `evidence/` at every depth by estate convention) |

Evidence inventory: `dry-run.txt`, `preflight.txt`, `install.txt`, `replay.txt`,
`invoke.input.json`, `invoke.stdout.txt`, `invoke.stderr.txt`, `observe.stdout.txt`,
`observe.stderr.txt`, `observe.trace.stdout.txt`, `observe.trace.stderr.txt`,
`sse.events.ndjson`, `sse.events.trace.ndjson`, `sse.stub-testimony.ndjson`,
`sse.stub-testimony.trace.ndjson`, `sse.summary.txt`, `sse.trace.summary.txt`,
`inspection.sql`, `inspection.txt`.

No commits were made.
