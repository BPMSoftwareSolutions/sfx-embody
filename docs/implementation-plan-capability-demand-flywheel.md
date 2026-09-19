# Implementation plan — the Capability Demand Flywheel

**Status.** Authored 2026-09-19. This is research and plan only: nothing is
declared, installed, or filed. No migration, row, contract, capability or SDA
change exists because of this document. The plan proposes; the team disposes
(§8).

**Authority.** The flywheel target is
`docs/Intent → Capability → Learning → More Capability.md` (written 2026-09-19;
untracked at authoring time — committed alongside this plan so reviewers can
read it). Grounding authorities: [architecture-achieved.md](architecture-achieved.md)
(what holds), [capability-estate-research.md](capability-estate-research.md)
(live estate research, 2026-09-19), [sql/README.md](../sql/README.md) (change
lifecycle), [transistor-model.md](transistor-model.md) (declared 1 vs resolver
0), [implementation-plan-next-wave.md](implementation-plan-next-wave.md)
(W1–W5 dispositions), [implementation-plan-circuit-view.md](implementation-plan-circuit-view.md)
(this plan's format, and the agent guard restated in §12).

**Binding constraint (user, 2026-09-19).** `sidefx-cli` and `sidefx-database`
are no longer in the runtime loop. Verified, not assumed: neither checkout
exists on this host (`Test-Path` false for `C:\lab\repos\sidefx-cli` and
`C:\lab\sidefx-database`), and the `sfx` shim on PATH is a dangling junction
(`MODULE_NOT_FOUND` before reaching the kernel). Every unit below is estate
rows, a declared capability, the installed kernel, the vault, or an SDA
**request** — never a CLI or DB-repo change, and in no case a new CLI verb.

**Ground pin.** Research ran against this host; a later kernel or estate
invalidates the *timings*, not the shape of the findings.

| Field | Value |
| --- | --- |
| Installed kernel | `%LOCALAPPDATA%\sfx\kernel\f3ae79b1…\KernelEntry.exe` |
| `artifactDigest` | `sha256:f3ae79b106db307a78d03db1189c3b2dd60779312e7a3de8211cc55ae9141b39` |
| `manifestDigest` | `sha256:81873b45ddbfd4b76a6526c3f318a4711bebcff2b56ca74afd4ad0864fc48acf` |
| SDA revision | `925587b` + working-tree changes later committed as `3edf004` (`sourceState: working-tree`) |
| Estate HEAD | `ef7d110` ("Remove the estate npm footprint") |
| RID / language | `win-x64` / `csharp` |
| Terminal | `sfx` not executable here (dangling junction); live reads used `<entry> capability … --json` through `cmd /c` |

**Evidence labels.** **Live** = executed and observed in this research;
**Recorded** = retained receipt or doc; **Projected** = not built, named as
such. Every count and failure below came from a live read, a live run, or a
cited row — never from prose restated as fact.

---

## 1. The flywheel, and the half that is missing

The flywheel target doc states it plainly: the first two loops already exist —
execution (capability → outcome → evidence) and engineering (declaration →
observe → learn → better declaration machinery). The next loop is the
**product** loop:

```text
INTENT → RESOLVE CAPABILITY FROM OBJECTIVE → ADMITTED: EXECUTE → EXPERIENCE → EVIDENCE
                                          → ABSENT:  GAP → DEMAND SIGNAL → GROW ESTATE → MORE INTENTS RESOLVE
```

Today the admitted half is **Live**: `request-capability-from-objective`
("What is Broadcom's current market price?") admits
`resolve-equity-market-price-evidence`, executes it, and returns evidence
(`docs/agent-lane.md`; observed path `sha256:26c85c04…`). The absent half is
the product half: an unresolved objective is a **terminal refusal** — the
estate learns nothing once the caller's terminal closes. The estate's own
research names the same hole from the other side
([capability-estate-research.md](capability-estate-research.md) §7): the estate
cannot reliably tell you what it contains (G1), show you one running (G2),
notice its own metadata holes (G3), or say which version is current (G4).
The Capability Demand Flywheel is the reflexive loop that closes both.

## 2. Current state: the demand pathway today

### 2.1 What the refusal lane actually produces [Live]

`request-capability-from-objective` is declared in
[declare-agent-capability.sql](../sql/migrations/declare-agent-capability.sql)
(`:37-44` contracts, `:56` prompt, `:91-112` decision/refusal shape, `:156-178`
routing, `:211-212` input mapping). Live refusal run 2026-09-19T13:57:58Z
(objective: *Buy $1,000 worth of Broadcom.*):

- outcome `agent-refusal-evidence.v1` =
  `{capability, model{disposition,provider,model,proposal{capability,input}},
  resolution{capability, declared:false}, refusal:"CAPABILITY_NOT_FOUND",
  diagnostic{…model evidence…}}`;
- **zero** provider/physical cells, `executions: []`, `observations: []` — no
  effect, exactly as required;
- the proposed identity travels (`execute-equity-trade`, input `AVGO`);
- the **objective text is nowhere in the output** (zero occurrences of
  "Broadcom" or "Buy $1,000 worth" in the captured JSON);
- `diagnostic` is a temporary field (`docs/agent-lane.md:113-115`; removal is
  W1 in [implementation-plan-next-wave.md](implementation-plan-next-wave.md));
- **nothing is retained**: the invocation session is read-only and always rolls
  back (`SDA:…/DatabaseReadSession.cs:40-47,192-201,307-326`), the process
  profile showed `fsWriteAllowed:false` (`windows-low-integrity-token`), and no
  row, file, or media holds the refusal. Only the caller's `--json` capture
  survives — and there was none before this research.

### 2.2 Where the signal dies (three reductions)

1. **The resolution read reduces the estate to one boolean.**
   `resolve-proposed-capability` (`declare-agent-capability.sql:166`) asks only
   `EXISTS(… declared_id = proposed)`. No objective echo, no similarity, no
   composition, no binding/mechanic query — every miss is informationally
   identical at that point.
2. **The route drops the truth it has.** `decide-agent-route` consumes the
   `declared` bit and the model evidence, but the objective
   (`root.payload.objective`) and the computed `declared` value never reach the
   refusal child.
3. **The refusal shaper hard-codes.** `resolution.declared` is the literal
   `false` (`:109`) and `refusal` the literal `"CAPABILITY_NOT_FOUND"`
   (`:110`), so even a declared-but-unroutable proposal is misreported as
   absent, and the refusal is terminal with no retention.

### 2.3 Taxonomy computability today

The flywheel's failure classes versus what the estate can honestly answer today:

| Class | Computable now? | Source |
| --- | --- | --- |
| EXACT_CAPABILITY_FOUND | **Live** (unlabeled) | route ADMITTED (hard-coded equality today) |
| NEW_CAPABILITY_REQUIRED (as ABSENT) | **Live** (unlabeled) | refusal `resolution.declared:false` |
| NOT_UNDERSTOOD | Partial (Projected run) | null/malformed proposal → same refusal today |
| COMPOSITION_FOUND | No — no composition search read exists | requires §2.5 unit CD-C5 |
| REBIND_REQUIRED | No — data exists (`portBindings`, `analysis.v_declared_platform_implementation`), no read | CD-C4 |
| PROVIDER_REQUIRED | Recorded data exists (`resolve-sidefx-eligible-providers`) | CD-C4/CD-E3 |
| MECHANIC_REQUIRED | Recorded data exists (mechanic registry + provider-mechanic rows) | CD-C4 |
| NOT_AUTHORIZED | **Not exercisable** — no grant model exists; refusal is by absence, not policy DENY (`docs/agent-lane.md`) | depends on the SDA authority-profile line (product-flywheel SDA R5) |

Honesty rule (binding for this plan): a class may be emitted only when its
source read exists **and** the receipt names it. Overclaiming a class is UID
wearing a taxonomy label.

### 2.4 There is no retention in the runtime loop

Write-surface inventory for the installed kernel ([Live], code-read):

| Surface | Mechanism | Reachable from a declared capability? |
| --- | --- | --- |
| DB rows | read-only pinned session (`sidefx_reader`, always ROLLBACK; rejects write receipts) | **No** |
| Vault store | `sda-credential-vault-port.v1` (`InvocationBoot.cs:195-205`) | Yes, but secret-shaped; wrong home for demand text |
| HTTP effect | `sda-governed-http-exchange-port.v1`, credential-reference port | Yes; external effect, not retention |
| File artifact | `sda-filesystem-artifact-store.v1` (registry `csharp-mechanic-registry.authority.v1.json:179-184`) | **No CLI-graph provider**; only the UI host reaches it; no read-back port |
| Media/publication | read only (`read-retained-publication` under `sidefx_reader`) | Read only; nothing in the loop writes media |
| Evidence directory | `evidence/` (gitignored, caller-owned) | Established receipt practice; **host**, not runtime |

Finding: the only in-loop durable write is the vault. Demand retention is
therefore a **caller/host** practice first, and a declared port second (§6).
This is the same decision the rate-limit research already made
([rate-limit-evidence-store.md](rate-limit-evidence-store.md): receiver-side
receipts, selection as a declared transformation, receipt rows deferred with a
trigger), and the same shape as the estate's existing evidence-first lifecycle.

### 2.5 Discovery and narrowing assets, and the gaps

| Narrowing stage | Served today by | Gap |
| --- | --- | --- |
| Exact capability | `list-capabilities` (`declare-list-capabilities.sql:42-98`); exact reads `read-capability-meaning`, `read-declared-authority`, `read-scenario-authority`, `read-declared-capability-document` | none for exact ids |
| Similar capability | `find` scenario of the same read (literal substring, `matchedFields`) | **G1: multi-token returns `outcome:null`, exit 0** (Live re-verified: `find "market price"` and `find market price` null; `find market` 9 rows) — indistinguishable from "no match"; the most scale-hostile behavior found |
| Composition candidates | `analysis.v_scenario_invocation_closure` rows; `compose-*` precedent + `emit-composed-closure-scenarios.sql` | no inverse read ("who invokes Z"); adapter composition not expressible (`sql/README.md:92-103`) |
| Required mechanics | per-capability `read-capability-meaning` exposes operations/port bindings | no inventory read; family request contracts are open/empty |
| Provider candidates | `resolve-provider-slot-bindings`, `resolve-sidefx-eligible-providers` (caller-supplied bindings) | no "which providers satisfy mechanic M" read |
| Contract precedents | per-capability `contractAuthorities`; `count-declared-contracts` (Live: 816) | no declared contract inventory (id + digest + owner) |
| Scenario precedents | `read-scenario-authority` (exact id); frozen brain corpus for semantic search | no declared scenario inventory; semantic search runs over a **frozen 108-unit seed that "cannot refresh"** (`classify-sidefx-semantic-corpus-sources`, [Live] reveal) — not the live 318/952 estate |
| Estate → brain recall | `sda-semantic-vector-index.v1` (integer-trigram overlap), `retrieve-sidefx-semantic-candidates`, `resolve-sidefx-capability-precedents` (four precedent classes, no similarity scalar) | corpus is caller-supplied/frozen; `assemble-sidefx-capability-authoring-context` is a **packer, not a retriever** (Live reveal, 237 KB) |

The live estate itself: **318 capabilities**, 952 scenario memberships, 816
contracts, `circuitAvailable:false` on every row (metadata now superseded by
the live circuit — SDA `925587b`/`3edf004` + estate `ee8e0b4`; G2's fix path is
the circuit plan's CV lanes). Five authoring/embodiment capabilities have no
`userStory` at all (G3) — they are invisible to intent-based `find` exactly
where discovery matters most.

### 2.6 The growth pipeline as declared, and its two change systems

The declared pipeline (all rows, cited in the research appendix §11): objective
→ find → compose → author authority (`model.declare_capability_document`,
`sql/schema/authoring-procedures.sql:*`) → scaffold (`generate-executable-capability-scaffold`,
pure derivation; root expression and schemas still hand-authored) →
converge/refine → **migration lifecycle** → proof (`verify-capability-scenario-outcomes`,
`verify-capability-authoring-lineage`, `verify-admitted-capability-lifecycle`,
`determine-execution-conformance`) → admission (`admit-capability-authority`,
pure transformation with a declared APPROVE/HOLD line) → declared change
lifecycle (`open`/`seal`/`publish`/`observe-capability-change`, MCP delivery).

Two seams matter:

- **There are two change systems.** The declared open/seal/publish/observe
  lifecycle is capsule-estate shaped and its effect ports were retired as
  dangling refs (`compose-declared-projection-chain-bindings.sql:203344-203396`),
  so it fails closed; the migration lifecycle (SDA bootstrap
  `run-migration.mjs` / `invoke-from-transaction.mjs` / `inflight-bundle.mjs`,
  all confirmed present) is the thing that actually installs rows — and **no
  capability names it** (A5 in [capability-estate-research.md](capability-estate-research.md)).
- **Nothing consumes a gap.** No declared capability takes an objective or a
  refusal receipt as input; there is no transform from
  `agent-refusal-evidence.v1` to a change-open or authoring request.

The smallest proven end-to-end loop is the declared-read shape: one JSON
document → one migration calling `model.declare_capability_document` → dry-run
→ preflight → COMMIT → live invoke — **95 s T0→verified, 7/7 attempts**
([flywheel-proof.md](flywheel-proof.md) §2–§4), still live today
(`read-declared-capability-document` returned `documentInstalled:true`,
digest `sha256:6dace374…`, ~1.4 s).

### 2.7 What a resolution rate needs

The metric (§5) needs one record per valid objective carrying: objective,
proposal, resolution class, route, terminal outcome, estate snapshot, time.
Today: objective is caller-only; proposal exists only on the refusal branch;
class unlabeled; estate snapshot is on every invocation
(`evidence.snapshotId`/`projectionDigest`); history is nowhere (read-only
session; `evidence/` local-only). Two of five data points exist.

## 3. Target shape (first turn)

The smallest honest turn of Loop 3, requiring no kernel change:

```text
objective ──► request-capability-from-objective (unchanged effect path)
                    │ admitted                      │ absent
                    ▼                               ▼
             existing evidence            CLASSIFIED GAP RECEIPT (EFFECT NONE)
             (unchanged)                  objective + proposal + class + snapshot
                                                    │  caller retains under evidence/demand/
                                                    ▼
                                          classify / dedupe (declared transformation)
                                                    ▼
                                          narrowing reads answer what exists
                                          (find, identity, contract, port/mechanic, composition)
                                                    ▼
                                          growth through the migration lifecycle
                                          (gap → authoring request → declarations → admit → install)
                                                    ▼
                                          next equivalent objective resolves from the estate
```

What this turn deliberately does **not** do: write rows on the invocation path
(no in-loop write port exists; the refusal stays strictly zero-effect); name
classes whose source reads do not exist; route on receipts; auto-author a
capability; or depend on the `sfx` terminal.

## 4. Lanes and units

Class vocabulary: **rows** = declared change in this estate; **host** =
practice/tooling outside the kernel; **kernel-SDA** = requires an SDA change
(filed as a request, §6); **doc/process** = lifecycle and record.

### CD-A — The honest classified gap

| # | Unit | Change (authority) | Class | Depends | Proof |
| --- | --- | --- | --- | --- | --- |
| CD-A1 | Carry the resolution truth and the objective into the refusal | `decide-agent-route` expression adds `declared` (from `input.declared`) and `objective` (from `root.payload.objective`); `shape-agent-refusal-evidence` emits both; `agent-refusal-evidence.v1` declares them | rows | — | from-transaction preflight of the refusal objective: receipt carries the real `declared` and the objective; admitted objective unchanged (equity evidence, zero provider cells on the refusal) |
| CD-A2 | Declare the resolution-class vocabulary; emit only provable classes | contract enum + shaper: `EXACT`, `ABSENT`, `NOT_UNDERSTOOD` now; hold COMPOSITION/REBIND/PROVIDER/MECHANIC until CD-C serves them; NOT_AUTHORIZED stays unemitted until authority profiles exist | rows | CD-A1; decision D3 | refusal objective → `ABSENT`; malformed-proposal fixture → `NOT_UNDERSTOOD`; admitted objective → `EXACT` (or unlabeled admitted evidence); every emitted class names its source read |
| CD-A3 | Declared gap-classifier read over existing relations | extend the resolve read to answer, read-only: declared-set exact; composition candidates (CD-C5); mechanic/provider coverage (CD-C4) — returning classes with the evidence rows that justify each | rows (kernel request only if a needed relation is not queryable) | CD-A2, CD-C4, CD-C5; decision D4 | known positives per class preflight as classified, not guessed; no class emitted without its cited rows |
| CD-A4 | Generalize admission beyond the hard-coded equity lane | visible set, admission predicate (drop the equality at `:94`), generic `executionRequest` builder from the proposed capability's declared interface (today `:98` hard-codes `live-equity-price-request.v1`) | rows unless a generic propose→invoke exceeds the declared transformation vocabulary | CD-C1, CD-C2, CD-C7; decisions D7/D8 | a second locally declared capability passes the lane; the purchase objective still refuses with `ABSENT` |

### CD-B — Demand retention

| # | Unit | Change (authority) | Class | Depends | Proof |
| --- | --- | --- | --- | --- | --- |
| CD-B1 | Declare `capability-demand-receipt.v1` and shape the receipt | contract + transformation emitting `{objective (or digest), proposedCapability, resolutionClass, snapshotId, projectionDigest, observedAt}`; caller retains the refusal's `--json` under `evidence/demand/` (documented step; no estate script — the UID ledger is closed) | rows + host practice | CD-A2; decisions D1/D2/D5 | one refusal produces one receipt file with snapshot/projection digests; refusal remains zero-effect |
| CD-B2 | Classify and dedupe the receipt set | declared transformation over `{receipts[], now}` (the rate-limit shape) → backlog reading: counts by class, first/last seen, keyed by decision D2 | rows | CD-B1; decision D2 | two receipts for the same demand dedupe to one backlog row; classes sum to receipts |
| CD-B3 | Governed append/durable port for an in-loop demand ledger | SDA request (§6 R1) → then `record-capability-demand` + `read-capability-demand` rows binding the port (own write session, dedicated grant, append-only, idempotency key) | kernel-SDA + rows | §6 R1 accepted; CD-B1 | invoke the recorder; declared read returns the row; replay with the same key yields one row |
| CD-B4 | Backlog read surface | host listing over `evidence/demand/` first; declared read once rows exist; later MCP/dashboard (§6 R1's read pair, CD-E4) | host → rows | CD-B2 | the backlog answers "what was asked that we cannot do" with cited receipts |

### CD-C — Semantic narrowing (the estate answering for itself)

| # | Unit | Change (authority) | Class | Depends | Proof |
| --- | --- | --- | --- | --- | --- |
| CD-C1 | Multi-token/intersection find + distinguishable outcomes | `list-capabilities` read/query + result: tokenize and require all tokens across the same match set, or return explicit `NO_MATCH` / `QUERY_UNSUPPORTED` variants with findings (G1; A1 of the estate research) | rows | — | `find "market price"` returns the intersection (2–3 true rows); `find market` stays 9; no-match is distinguishable from unsupported; exit disposition honest |
| CD-C2 | Declared identity dump read | `read-declared-identities`: capabilityId, namespaceId, definitionDigest, name, userStory, rootScenarioId, scenarioCount, digests; deterministic order (A4; feeds harness H12/H13) | rows | — | count equals 318 and ids equal `list`; digest recomputes; no gitignored `.txt` needed |
| CD-C3 | Declared contract inventory read | contractId + schema digest + owning capability; optional substring match | rows | — | row count equals `count-declared-contracts` (Live: 816); digests recompute |
| CD-C4 | Declared port/mechanic inventory and inverse reads | exposed ports/mechanics per capability and "who binds platform capability P", over existing views (`model.operation_port_invocation`, `analysis.v_provider_slot_resolution`) | rows | — | for the equity capability the result equals the live `read-capability-meaning` port bindings; cross-check sample against `resolve-provider-slot-bindings` |
| CD-C5 | Declared composition inverse | "which capabilities invoke scenario Z" / closure edges with owners, over `analysis.v_scenario_invocation_closure` | rows | — | returns `compose-resolve-equity-market-price-evidence` for the equity scenario; counts match the closure-emission evidence (1 vs 2 scenarios) |
| CD-C6 | Estate→brain corpus projection | project the live estate's identity/lexical/relationship rows into the brain's corpus shapes (`identityEntries`, `lexicalEntries`, `relationships`, `catalogObjects`), replacing the frozen 108/109 seed as the live-estate index; refresh policy is decision D10 | rows; SDA request only if the corpus source must be rows | CD-C2, CD-C3, CD-C5 | the same precedent query answers over live estate identities; channels match `find` on known cases; vector channel disableable |
| CD-C7 | Narrowing composition | chain CD-C1 → C2 → C6 → precedent/retrieval reads → authoring disposition (REUSE→COMPOSE→PROFILE→AUTHOR_NEW) → context pack via `assemble-sidefx-capability-authoring-context` with declared purposes | rows composition | CD-C1..C6; decisions D9/D10 | each of the seven narrowing questions yields a classified precedent item or a typed `NOT_FOUND`/`INSUFFICIENT_AUTHORITY`; no similarity scalar invented |

### CD-D — From gap to admitted capability

| # | Unit | Change (authority) | Class | Depends | Proof |
| --- | --- | --- | --- | --- | --- |
| CD-D1 | Gap→change intake transform | a declared transform converting a classified receipt into an authoring request / change-open request (nothing consumes a gap today); the receipt stays an outcome record, never a routing input | rows | CD-A3, CD-B1; decision D8 | a retained refusal yields one authoring request naming the gap class and proposed identity |
| CD-D2 | Authoring wrapper | from gap + narrowing inventory, produce a `sidefx-capability-authority.v1` document and schema candidates, reusing the scaffold generator, convergence reads, and the document surface | rows + host | CD-C7, CD-D3 | the hello-world-class capability is re-derived from a gap in one documented pass; the workflow's outputs are reviewed, not auto-installed |
| CD-D3 | Schema derivation/oracle | derive candidate schemas from the root transformation and diff against admitted contract authorities; the inversion risk is stated in [deriving-contract-schemas.md](deriving-contract-schemas.md):295-326 | rows/tooling | CD-D2 | a missing contract is proposed with a diff against the admitted catalog; no silent schema invention |
| CD-D4 | Admission→install linkage | make the `admit-capability-authority` receipt (its `authorizedNextAction: SEAL`) accompany or drive the migration install; declared review line (who reviews is decision D7) | rows + process | CD-D5, decision D7 | an admission receipt and its installed migration resolve to each other by digest |
| CD-D5 | Preflight receipt and gates (A5) | SDA request (§6 R2): a kernel-ground lifecycle command emitting `{migration digest, capability, disposition, outcome digest, timestamp}`; consumed by the harness H1/H2 gates and CD-D4 | kernel-SDA + rows | §6 R2 | the preflight receipt is machine-readable and a fresh clone fails closed without it |
| CD-D6 | MCP change surface for this estate (W4 integration) | wire or explicitly defer the registered open/seal/publish/observe MCP tools; today the tools register but their routing/effect ports were retired, so they fail closed | rows (kernel request if a port must return) | decision D12 | one governed no-op change round-trips through MCP, or the surface is recorded as deferred with a trigger |
| CD-D7 | Adapter composition | SDA request (§6 R3): input-slice/merge around `invoke-scenario` so a child can be reused outside the shape it was authored for (drop-in only today; a child's `rejected` fails the parent) | kernel-SDA | §6 R3; decision D8 | a child with an adapter mapping executes under a parent it was not shaped for, with declared mapping rows |
| CD-D8 | Authoring pipeline repair | the rows the research found broken or stale: `author-one-scenario-candidate` model port retired (fails closed), `carry-consumer-authority-context` binding cleared, `plan/write-capability-embodiment` names deleted `src/` modules (target-architecture data defect) | rows | — | each repaired capability preflights to its declared disposition; the deleted-module names are gone from rows |

### CD-E — Intent Resolution Rate

| # | Unit | Change (authority) | Class | Depends | Proof |
| --- | --- | --- | --- | --- | --- |
| CD-E1 | `read-intent-resolution` declared reading | caller supplies run receipts; SQL owns meaning; reports `valid`, `resolved`, `satisfied`, `rate`, `byClass`, `uncertified` (pattern: `declare-invocation-timing-reading.sql`, `declare-read-demo-acceptance.sql`); unprovable classes are `UNCERTIFIED`, never guessed | rows | CD-A2, CD-B1; decision D11 | fixture of ≥2 runs (one admitted, one refusal) yields the declared per-class counts; invoked via `capability invoke read-intent-resolution --input @file --json` — no CLI change |
| CD-E2 | Admitted-branch resolution record | the admitted branch today drops the model proposal; emit a compact resolution record (or retain the harness capture) so exact-vs-composition is certifiable | rows (or host capture) | CD-E1 | an admitted run's record carries proposal + route + terminal evidence digest; the reading certifies its class instead of `UNCERTIFIED` |
| CD-E3 | Provider coverage reading | ports → providers → mechanics coverage joined with availability (data exists: `v_declared_platform_implementation`, mechanic registry, eligibility capability; ties to rate-limit U1/U2 probes) | rows | CD-C4; rate-limit U1 | the reading names, per capability, which required ports/mechanics have admitted providers on the target |
| CD-E4 | Delivery surfaces (later) | MCP tool precedent (`deliver-capability-change-mcp`); dashboard Path C or batch-imported receipts labeled *imported*, never *live history*; history/session-ledger is an SDA request when a consumer cannot receive receipts as input | rows + host + kernel-SDA | CD-B3, CD-E1 | a person can watch the rate move without a code change to any terminal |

### CD-F — Enablers this plan sequences but does not own

| # | Unit | Why here | Owner / track |
| --- | --- | --- | --- |
| CD-F1 | Long-lived delivery host (carrier residual) | ~450 ms .NET start + ~2 s fixed floor per invocation ([capability-estate-research.md](capability-estate-research.md) §3) makes a narrowing chain cost seconds; the host is the difference between a 3 s and sub-second loop | [architecture-achieved.md](architecture-achieved.md) §9 row 8; deferred in [architecture-priorities.md](architecture-priorities.md) with trigger |
| CD-F2 | Terminal and command-surface hygiene | `sfx` is broken on this host and the estate npm footprint was removed (`ef7d110`), so `AGENTS.md`'s `sfx`/`npm run verify:*` rows are stale; demo/runbook commands need a working terminal or the kernel-entry equivalent | doc/host; out of composite (the CLI repo is gone) |
| CD-F3 | Harness hooks prerequisites | H1–H14 are registered, not installed; this plan reuses H12/H13 (identity dump = CD-C2), H1/H2 (preflight receipt = CD-D5), and A3 (`docs/findings/` home + `record-finding`) | [agent-harness-hooks.md](agent-harness-hooks.md) |
| CD-F4 | Circuit completion (CV-B fragments, CV-C2) | growth is only legible if a person can see a capability run; the circuit plan's remaining lanes serve this plan's visibility | [implementation-plan-circuit-view.md](implementation-plan-circuit-view.md) |
| CD-F5 | Metadata hygiene and supersession (G3/G4) | narrowing misses the authoring capabilities because five have no `userStory`; versioned siblings have no declared supersession — discovery poisoned exactly where growth starts | estate-research A6/U2 |

## 5. Intent Resolution Rate

```text
Intent Resolution Rate = satisfied objectives / valid objectives   (window, estate snapshot)
```

- **Denominator — valid objectives.** `request-capability-from-objective`
  receipts whose input conformed to `agent-objective-request.v1` and produced a
  terminal disposition. Lane/model failures stay in (`NOT_UNDERSTOOD`);
  input-contract failures never entered the lane and do not.
- **Numerator — satisfied.** Route admitted a declared capability **and** the
  terminal outcome is that capability's success evidence. Report two counts —
  `resolved` (admitted) and `satisfied` (admitted + terminal success) — so a
  provider failure never reads as an estate gap.
- **Breakdown** by the §2.3 classes, with `UNCERTIFIED` for anything not
  provable from declared joins today.
- **Receipt unit** (proposed, CD-B1): `{objective or digest, proposed
  capability, class, snapshotId, projectionDigest, observedAt, host?}`.
- **Computability today** (Live): EXACT and ABSENT are computable once CD-A2
  labels them; NOT_UNDERSTOOD is one governed fixture away; the other five
  classes are Projected and must stay `UNCERTIFIED` until their reads exist.
- **Surfacing**: `capability invoke read-intent-resolution --input @file --json`
  through the installed kernel — the same pattern already proven for
  `read-invocation-timing` (Live: `invocation-timing-reading.v1` returned over
  the list run's own testimony).

## 6. SDA change requests this plan requires (to file on approval)

Format per [embodiment-completeness.md](embodiment-completeness.md): primitive /
why kernel / affected languages / data that binds it / evidence. None filed yet.

**R1 — A governed append/durable port for demand retention.** Primitive: an
admitted append of one bounded receipt row, keyed by a declared idempotency
field, under its own write session and dedicated grant — never widening the
pinned read session. Why kernel: the invocation path is read-only by law; no
estate row can open a write seam. Data: the `capability-demand-receipt.v1`
shape (CD-B1), `estate_model_pk`/snapshot scope. Evidence: the refusal lane and
its zero-effect receipt [Live]; the rate-limit research's deferred receipt-row
trigger; the vault port as the in-loop write precedent. Paired declared read:
`read-capability-demand`.

**R2 — Preflight receipt seam (A5).** Primitive: the dry-run/preflight
capability-change steps emit a machine-readable receipt `{migration digest,
capability, disposition, outcome digest, timestamp}` to a declared location.
Why kernel: those steps are SDA bootstrap code (`run-migration.mjs`,
`invoke-from-transaction.mjs`, `inflight-bundle.mjs` — all present) that no
capability names; the estate cannot declare its way to them. Data: the
lifecycle in [sql/README.md](../sql/README.md). Evidence: the harness H1/H2
gates and admission linkage depend on a receipt that does not exist.

**R3 — Adapter composition mapping.** Primitive: an operation-level
input-slice/merge around `invoke-scenario`, so a child can be invoked under a
parent it was not shaped for. Why kernel: the composition planner is resolver
(0); drop-in composition works and adapter composition is not expressible, and
a child's `rejected` currently fails the parent. Data: the composition finding
and the closure-emission precedent. Evidence: [cross-capability-composition-finding.md](cross-capability-composition-finding.md),
[sql/README.md](../sql/README.md):92-103.

**Dependency, not a new request:** `NOT_AUTHORIZED` depends on the authority
profiles already named as SDA R5 in [product-flywheel.md](product-flywheel.md):399.
Until it lands, the class stays `UNCERTIFIED`.

## 7. Sequencing and dispositions

| Disposition | Units | Why now |
| --- | --- | --- |
| **Needed now (the first turn)** | CD-A1, CD-A2, CD-B1, CD-C1, CD-C2 | Fix the lie (`declared:false` is literal), stop losing objectives, make the *normal* agent query (two tokens) work, and give the estate its own identity dump. All rows/host; no kernel change; each proves in one preflight |
| **Useful now** | CD-B2, CD-C3, CD-C4, CD-C5, CD-E1, CD-E2, CD-D1, CD-D2, CD-D8, CD-F5 | The narrowing answers and the first metric read; the growth intake; repairs already owed |
| **Defer with trigger** | CD-B3 (a consumer that cannot receive receipts as input), CD-C6 (a precedent query against live estate ids is requested), CD-C7 (narrowing reads landed + D9 decided), CD-D3 (first schema missing from the catalog), CD-D4/CD-D5 (growth volume or H1/H2 installation), CD-D6 (W4 integration decision), CD-D7 (first reuse blocked by shape), CD-E3 (rate-limit U1), CD-E4 (a watched surface is requested), CD-F1 (team decision on the measured ~2.4 s floor) | |

Commit unit template for whatever lands (from
[implementation-strategy.md](implementation-strategy.md):226-234):
`lane / unit / standard / change / proof`.

## 8. Open decisions for the team

| # | Decision | Options | Recommendation |
| --- | --- | --- | --- |
| D1 | Who writes the demand receipt | caller-retained evidence; in-invocation write; DB ledger | **Caller-retained first** (zero effect, zero kernel change); ledger on the §6 R1 trigger |
| D2 | What identifies a demand | content digest; `(objectiveDigest, proposedCapability, snapshotId)`; raw objective | key on digest of a canonical tuple; the model's proposal id is unstable (`execute-equity-trade` vs `buy-equity` already observed) |
| D3 | Taxonomy vocabulary home | declared enum in the refusal contract; doc-only | **declared enum**; emit only provable classes |
| D4 | Classification authority | exact-only; closure/provider/mechanic reads; model-assisted | reads only; a model may propose, never classify |
| D5 | Retention location, horizon, redaction | `evidence/demand/`; kernel host; DB; external collector | `evidence/demand/` with a stated horizon; verbatim objective confined there; digest in any wider surface |
| D6 | Backlog read surface and audience | local listing; declared read; dashboard | declared read once rows exist (CD-B4) |
| D7 | Who authorizes growth | `admit-capability-authority` mandatory before install; preflight remains the gate | make admission the review line (CD-D4); preflight remains the technical gate |
| D8 | Which change system owns growth | migration lifecycle (accepted process); declared open/seal/publish (ports retired) | keep the migration lifecycle this turn; revisit when R2 lands or MCP is wired |
| D9 | Ranking and thresholds | no ranking; declared policy ranking; provider ordering | no new scalar; expose class + evidence (the brain's deliberate stance) |
| D10 | Frozen corpus vs live estate | re-freeze cadence; live projection (CD-C6); both | live projection with the frozen seed as evidence of record |
| D11 | Metric window, scope, validity, strictness | rolling window; per snapshot; per host; per estate; resolved vs satisfied | per estate snapshot, both counts, rolling window |
| D12 | MCP wiring for this estate | wire now; defer with trigger | defer until CD-D4 gives it something governed to carry |

## 9. Admissibility and anti-drift rules

Binding rules for every unit above:

1. **Receipts never route.** A demand receipt or backlog reading is an outcome
   record; it never selects, authorizes, or triggers execution. Classification
   emits readings, not routes.
2. **No auto-authoring.** No invocation writes a capability; growth remains the
   migration lifecycle (or the declared change lifecycle once wired). The
   flywheel proposes; the team disposes.
3. **Refusal stays refusal-by-absence.** Never rename `CAPABILITY_NOT_FOUND`
   into a policy DENY, and never emit `NOT_AUTHORIZED` before authority
   profiles exist.
4. **No class without its source read.** A taxonomy label backed by nothing is
   UID wearing a label.
5. **No new CLI verbs, no CLI dependency.** Read surfaces are declared
   capabilities invoked through the kernel's existing operations; the terminal
   is optional and currently absent.
6. **No `sidefx-cli` / `sidefx-database` changes; no SDA edits.** Kernel gaps
   are requests (§6) in the transistor-model §10 format.
7. **No materialization vocabulary on the database surface.** No "capsule",
   "artifact", "retained source", "projection"; rows only.
8. **Evidence first; one migration per commit.** Guard-trigger drop, own
   `BEGIN TRANSACTION`, final `ROLLBACK` for dry-run/preflight, flip to
   `COMMIT` only after the from-transaction invocation passes; a live
   invocation with the intended disposition is the proof; an honest
   blocked/owed is a deliverable.
9. **`--json` through `cmd /c`**; PowerShell 5.1 corrupts native stderr.
10. **Do not duplicate tracked work.** W1–W5, the CV lanes, A1–A6/U1–U4 and the
    harness hooks have owners; this plan sequences them, and every unit above
    says which debt it repays.

## 10. Risks and honest limits

- **Retention is host practice until §6 R1 lands.** Demand accumulates in
  `evidence/demand/` (gitignored), so a fresh clone sees no history by design;
  the ledger is a named request, not a promise.
- **Five of eight classes are `UNCERTIFIED` today.** The metric starts small
  and honest.
- **G1 is a duplicate factory.** Until CD-C1 lands, every two-token agent query
  reads as "nothing exists" — the estate's own research calls this the single
  most scale-hostile behavior found.
- **The `sfx` terminal is gone on this host**, and the estate npm footprint was
  removed (`ef7d110`); every proof in this plan runs through the kernel entry
  or SDA bootstrap commands. `AGENTS.md` command rows are stale until CD-F2.
- **Costs**: ~2.4 s fixed floor per invocation; a staged narrowing chain
  multiplies it (CD-F1, or fold narrowing into one composed capability).
- **Adapter composition is the reuse ceiling** (CD-D7); without it, a gap can
  only be answered by drop-in composition or new authority.
- **Proposal instability** (the model proposed `execute-equity-trade` here, and
  `execute-equity-buy-order` / `buy-equity` in recorded runs) makes dedupe a
  real design choice (D2), not a formality.
- **Concurrency.** The estate is worked by parallel writers; the two untracked
  migrations and research captures in the tree today are not this plan's to
  touch.

## 11. Research provenance

Six parallel research lanes ran 2026-09-19 against the ground pin above; every
citation in this plan traces to one of them. Captures and scratch are under
`C:\Users\SIDNEY~1\AppData\Local\Temp\opencode\` (the refusal receipt run, the
find probes, the reading probe). Nothing was written to either repo; no
migration was authored; no provider was exercised beyond the zero-effect
refusal.

| Lane | What it established |
| --- | --- |
| Refusal path | the receipt's exact shape, the three reductions, zero retention, taxonomy computability |
| Demand retention | the write-surface inventory, five retention options, the recommended first path |
| Semantic narrowing | the stage-by-stage asset map, G1 re-verified live, the frozen corpus, the packer-not-retriever finding |
| Growth pipeline | the declared pipeline table, the two change systems, the retired ports, the 95 s/7-of-7 loop, A5 |
| Metric and readings | the Intent Resolution Rate spec, the reading design, the data availability map |
| Runtime-loop constraints | the ground, the exact lifecycle commands, `sfx`/checkouts absent, the owed-unit map and plan format |

Author verification re-ran the load-bearing claims: the shaper literals
(`declare-agent-capability.sql:109-110`), the route literal (`:93`), the
hard-coded execution request (`:98`), the presence of the three SDA bootstrap
tools, and the absence of both sibling checkouts.

## 12. Agent guard for this plan

1. Before writing any row or transformation, name the declared authority it
   reads; if the choice is not declared, it is UID — declare it or record a
   unit, never code it.
2. No capability-specific strings, status/priority logic, or policy constants
   in transformations or emitters; classification is declared authority.
3. A receipt is an outcome record; it can never become a routing input, an
   authorization, or a trigger.
4. Cancelled or interrupted work is reverted before anything else; cancelled
   work never lands.
5. Commit messages state the classification of every change (declared-row
   consumption / transport / host practice) and the unit id where one exists.
