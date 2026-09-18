# The product flywheel — the governed harness

**Status.** Authored 2026-09-18. This is the product-growth view over the achieved
state. It adds no requirement and settles no design question; where it conflicts
with an authority doc, the authority doc wins.

**Ground.** As of this date the estate's process deliveries run the installed C#
kernel executable — `%LOCALAPPDATA%\sfx\kernel\59d6030f…\KernelEntry.exe`, installed
from SDA revision `9b77314`, artifact digest
`sha256:59d6030fbc4cb5ee7d8316c675281e6ba5c790eada03ec7ec5324385737138c6`, manifest
digest `sha256:944a20e26bf7207eef65800b31398d37e105121c8c34e04b08d4660d7ed85fc1` —
with no `scenario-driven-architecture` path and no filesystem read grant in
`sfx.config.json`. The vault-only acceptance is recorded in
`evidence/vault-20260916/csharp-seams/receipt.json` (local; `evidence/` is
gitignored). While writing this document the author re-ran
`sfx capability invoke say-hello-world --input {}` with `DB_CONNECTION_STRING`,
`RAPID_API_KEY`, `LOC_GEMINI_API_KEY`, `LOC_OPENAI_API_KEY` and
`sidefx-connection-string` absent from the process environment: the installed
executable answered with the recorded parity triple. `docs/architecture-achieved.md`
was not present at authoring time; the fallback authorities
(`target-architecture.md`, `transistor-model.md`, `agent-lane.md`,
`composite-repo-boundary.md`, `invisible-execution-authority.md`,
`vault-manager-capabilities.md`, `kernel-install-matrix.md`,
`architecture-priorities.md`) plus that live receipt are the ground.

**Evidence labels.** **Live** = executed or re-executed and observed on this host.
**Recorded** = a retained receipt or doc records the observation; not re-run here.
**Projected/planned** = not built; named as such.

---

## 1. Scale by creating declared capabilities

A new capability is **declarations + provider bindings + preflight + evidence**. It
is not a runtime build and not new language code. The law that makes this true is
the transistor: *which mechanic runs and with what configuration is always declared
(1); the native implementation of the mechanic is always a resolver (0). Adding a
mechanic is an SDA change; binding one is data*
([transistor-model.md](transistor-model.md) §3.1).

What "declarations" concretely means, all rows:

- contracts (input and outcome JSON schemas);
- the scenario(s) and the execution authority (the operation list);
- transformations (request builders, normalizers, shapers);
- port bindings — each port configuration is either a platform mechanic
  (`platformCapabilityId` into the target language registry) or a declared read
  (`{statement, resultColumn}`) ([target-architecture.md](target-architecture.md)
  "Port / provider binding");
- interface/display rows that say how the outcome is delivered;
- routing rows when the graph branches (`transitions`, `selectsVariant`).

What "preflight + evidence" concretely means: the migration's own from-transaction
invocation before install, then the outcome, cell/edge testimony and the three
digests (canonical, realized, observed) as the receipt.

### Examples from the estate

| Capability / proof | What it actually required | Class | State |
|---|---|---|---|
| `say-hello-world` (the hello-world scaffold) | One scaffold migration, one transformation, a JSON CLI interface binding to `sda-json-cli.v1` ([scaffold-hello-world.sql](../sql/migrations/scaffold-hello-world.sql)) | rows | **Live** on the installed C# kernel: canonical `8b859397…4931`, realized `f7655bd9…72de`, observed `20864ba2…70ba` |
| `resolve-equity-market-price-evidence` | Ports bound to `sda-governed-http-exchange-port.v1` and `sda-external-credential-reference-binding-port.v1`, outcome-variant classification, then a declared fallback route; no new runtime ([target-architecture.md](target-architecture.md) worked case) | rows | **Live**, vault-only; C# parity `2f92d057…0493` / `122f5e96…5791` / `c507678e…79eb` |
| Agent lane `request-capability-from-objective` | Contracts, one request-builder transformation (prompt, visible set, proposal schema), the governed model capability as a composed child, a declared read for resolution, declared routing, and a refusal child ([declare-agent-capability.sql](../sql/migrations/declare-agent-capability.sql)) | rows | **Live**; observe observed-path `26c85c04…fb73`, 716 cell testimony entries |
| `compose-resolve-equity-market-price-evidence` | One `invoke-scenario` operation; the composing root's faces re-pointed at the invoked capability's contracts; neither capability's meaning edited ([compose-resolve-equity-market-price-evidence.sql](../sql/migrations/compose-resolve-equity-market-price-evidence.sql)) | rows | **Recorded** live, then the executable composition proof |
| Routing proof `route-two-child-proof` | Three contracts, one root, two children, one `selectsVariant` route per declared variant; the validator rejects an unreachable cell, which is why one route per branch is the smallest admissible case ([declare-two-child-routing-proof.sql](../sql/migrations/declare-two-child-routing-proof.sql)) | rows | **Recorded** live; each branch testifies only its selected child |
| `store-credential` / `resolve-credential` | Two JSON authority documents and one platform port (`sda-credential-vault-port.v1`); no reveal outcome exists in the contract | rows | **Recorded** installed; V1–V4 receipts in [vault-manager-capabilities.md](vault-manager-capabilities.md) §6 |

The enabling mechanisms were each built once and are reused: the authoring
procedures (`scaffold_capability`, `declare_scenario`, `put_semantic_definition`, …),
the declared-read/mechanic port, the single invocation path, the migration
lifecycle, the digests, and the document ledger.

### The cost curve, measured honestly

- `read-declared-capability-document` (the second declared-read capability) took
  **95 s from T0 to a behaviorally verified CLI invocation, 7 attempts / 7
  successes**, reusing eight artifacts and one sibling request contract unchanged
  ([flywheel-proof.md](flywheel-proof.md) §2–§4). That is the observed cost of the
  declared-read shape.
- `hello-world-sql` emits its own single scenario; `compose-…` emits two (its root
  plus the invoked equity scenario) — adding the closure scenarios is graph-source
  assembly, not capability authoring.
- Continuing costs, recorded not hidden: a JSON document can only be installed by a
  migration (FF2); the document is duplicated between example file and SQL literal
  (FF3); scaffold residue remains in `reveal` (FF4); and the install lifecycle did
  **not** get cheaper for B ([flywheel-proof.md](flywheel-proof.md) verdict).
- Not measured: the pure-mechanics and provider-backed authoring shapes. The 95 s
  result is scoped to the declared-read shape.

The ceiling on this curve is mechanics: if a needed mechanic does not exist, the
unit is an SDA change request first, and only then bindable as data forever
([transistor-model.md](transistor-model.md) §10).

---

## 2. Scale with an agentic experience (voice-to-value)

The live lane today, from one typed objective:

```text
sfx capability invoke request-capability-from-objective --input "What is Broadcom's current market price?"
```

The declared graph ([agent-lane.md](agent-lane.md), [agent-lane-declaration.md](agent-lane-declaration.md)):

1. `build-agent-model-request` declares the prompt, the visible capability set and
   the proposal schema; the governed model capability `obtain-governed-model-response`
   is invoked as a composed child (structured generation against
   `primary-cognitive-provider` / `instruction-capable-model`, bounded by
   attempt/evidence policy). **The response is testimony — a proposal, nothing
   more.**
2. A declared read resolves the proposal against the estate; the route state carries
   `ADMITTED` / `REFUSED`.
3. Declared routing selects the execution child (which invokes the admitted
   capability and terminates in its provider-attributed evidence) or the refusal
   child (`agent-refusal-evidence.v1`, zero execution cells).

Live receipts (2026-09-17, [agent-lane.md](agent-lane.md) "The three beats"):

- admitted: model proposes `resolve-equity-market-price-evidence` with `AVGO`; the
  outcome is the provider-attributed evidence (`EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`,
  AVGO 339.51 USD, provider `rapidapi/yahoo-finance-real-time1`). Re-observed on the
  installed C# kernel: `26c85c04…fb73`.
- refused: the objective "Buy $1,000 worth of Broadcom." makes the model propose
  `execute-equity-trade`; the declared route refuses it **by absence** — resolution
  `not declared`, refusal `CAPABILITY_NOT_FOUND`, no provider reached, zero
  execution cells.

### What a voice surface adds — carrier only

Voice changes the entry, not the authority. Today the objective is a typed scalar
input and the result is the declared outcome. A voice surface is speech-to-text
before that input and text-to-speech over the outcome. Speech already exists in the
estate as declared work — the `speech-provider` exchange is a declared capability
([compose-speech-provider-http-exchange.sql](../sql/migrations/compose-speech-provider-http-exchange.sql))
and the speech credential authority is vault-only
([vault-manager-capabilities.md](vault-manager-capabilities.md) §6 V3) — but no
voice carrier is wired; this is **projected/planned**. The invariant the work must
preserve: the transcript is the objective input to the same declared lane, the
model still only proposes, and the harness still admits or refuses by declared rows.
Nothing about the lane's authority moves because the words arrived as audio.

### Invariants

- **Models never hold execution authority.** The model never receives a tool and
  never reaches a provider directly; there is one door to effect. Its output is a
  proposal value inside a declared graph.
- **No reasoning outside a governed lane.** What the model can see is declared
  authority (the visible set is a literal in the declared request-builder — a
  builder decision records whether it moves to the declared context assembly), and
  what it can cause is a declared resolution plus a declared route. The model's
  hidden internal reasoning is explicitly **not** governed or claimed
  ([target-harness-experience.md](target-harness-experience.md) precision note);
  what is governed is how it is invoked, what context it can see, and whether any
  proposal can become an effect.

---

## 3. A governed harness that keeps AI out of the authority circle

**The boundary, precisely.** The model is a provider inside the governed execution
environment, not a harness above SideFX holding its own tools. It is invoked by a
declared capability with a declared request; its structured output is untrusted
testimony. Execution authority is the declared graph: the resolution read decides
what is declared, routing selects the child, the admitted child reaches a provider
through declared registry bindings, and the refusal child reaches nothing.

**How declared rows decide.** There is no branch in estate or kernel code that
consults the model. The decision points are rows: the proposal schema (what shape a
proposal may take), the resolution read (what is declared), and the routing
transitions (which child runs and which child is left unlit). A capability that is
not declared has no cell; a cell with no bound provider has no executable path.
The refusal is therefore truthful: "no executable path", not a policy DENY. No
grant model, authority profiles or declared effect classes exist yet
([agent-lane.md](agent-lane.md) honest boundaries), and the doc does not claim them.

**How the receipts make it auditable.**

| Receipt | What it shows | Where it is recorded |
|---|---|---|
| Evidence | the terminal outcome is provider-attributed; provider identity is testimony, not outcome meaning | invoke/observe results; [agent-lane.md](agent-lane.md) |
| No-disclosure | a stored sentinel is absent from invoke `--json`, `observe --trace`, the stream, evidence bundles and durable rows; a tampered store fails AES-GCM authentication with `nonDisclosureVerified: true` | [vault-manager-capabilities.md](vault-manager-capabilities.md) §6 V4 |
| Timing | every cell testifies `startedAt`/`completedAt`/`durationMilliseconds`; the IEA test is `gap − attributed` per streamed window | [invisible-execution-authority.md](invisible-execution-authority.md); `TIMING-COHERENT` with every residual zero or named |
| Structure | the declared circuit view and its `attestation` name unobserved planned cells and unselected branches; a removed testimonium returns `structured: false` with the cell named | [circuit-view-flywheel.md](circuit-view-flywheel.md), [implementation-plan-circuit-view.md](implementation-plan-circuit-view.md) CV-D1 |
| Parity | canonical / realized / observed digests per invocation | manifest `parity`, kernel install receipt, SDA conformance |

Structure plus time is the attestation pair: which cells exist and which ran
(circuit view) and that no time passed without a cell accounting for it (IEA).

**Why this is structural, not policy.** A policy is something an actor can be
persuaded around; this boundary is a property of the machinery. The model has no
door to a provider to walk around — the kernel resolves providers through declared
registry bindings, and a proposal that names no declared capability produces no
cell, no provider and no effect. "The model cannot reason outside a governed lane"
means, exactly: outside the lane there is no path to effect for its reasoning to
travel. The same property generalizes to any future model provider: swapping Gemini
for another provider is a declared binding, and the authority circle does not move
([vault-manager-capabilities.md](vault-manager-capabilities.md) §1.2).

---

## 4. Governance-as-a-service / download-and-install

### The installed executable model (live)

One installed kernel executable per host carries the carrier, the DB ground, the
kernel and the per-language providers. Selection is data: `sfx.config.json` names
the command, cwd and args in a process delivery; the kernel language is a manifest
field, never a caller branch. The current install's delivery records contain no SDA
path and no read grant, and the capability meaning still comes from database rows
(`authoritySource: DATABASE` — live receipt).

### Manifest + digest admission

`sfx-kernel-install-manifest.v1` records the language, host/arch/RID, entry point
and args, carrier contract, observation-channel status, `sdaRevision`, the exact
`publishCommand`, `artifactDigest` (tree digest over sorted `path<TAB>hash`), the
`manifestDigest` (stable JSON without the field), the vault realization, the parity
triple and the conformance receipt ([kernel-install-matrix.md](kernel-install-matrix.md) §2).
Install roots are digest-named and immutable; an existing digest reports
`ALREADY_INSTALLED` and is verified, never overwritten; a changed build means a new
digest-named directory and a new pinned `manifestDigest`. The recorded install was
published from a **working tree** under an explicit `--allow-dirty` admission with
`sourceState: working-tree` and the revision recorded; the matrix's standing rule is
a pinned, non-dirty source ([kernel-install-matrix.md](kernel-install-matrix.md) §3).
Replays recompute the artifact digest; a mismatch fails closed. The kernel install
also retired the estate test suite: the kernel owns the circuit now (estate commit
`52133f9`), with the C# conformance suite recorded at 181 pass / 0 fail.

### Versioned roots and the per-OS matrix

| Host | Kernel build | RID | Vault realization | Status |
|---|---|---|---|---|
| Windows x64 | C# `ScenarioKernel` | `win-x64` | `windows-credential-store-provider` (DPAPI/CNG) | **Live** (installed, invoked, vault-only) |
| macOS arm64 / x64 | C# | `osx-arm64` / `osx-x64` | `macos-keychain-credential-store-provider` | **Owed** (build, realization, acceptance) |
| Linux x64 / arm64 | C# | `linux-x64` / `linux-arm64` | `linux-secret-service-credential-store-provider` | **Owed** |
| Node fallback (any host) | runtime, source or staged tree | — | Windows live | Admitted fallback; offers the observation channel |
| Python fallback | package | — | none | Entry/tests exist; not admitted |

### Vault integration

One semantic credential contract (`sda-credential-vault-port.v1`, `store`/`apply`,
no `reveal`), per-OS realizations behind it, and the two-roof rule: the ciphertext
store and the unwrap key never sit under one roof. The Windows realization releases
the DPAPI-protected key into memory for the provider call; with no realization the
port refuses `VAULT_SEALED` and never falls back. The capability rows are identical
on every OS; only the realization binding differs. Limits are stated in the source:
same-user processes (including an agent) can call the keystore API, which is why
plaintext must never reach the invocation boundary ([vault-manager-capabilities.md](vault-manager-capabilities.md) §4.3).

### Why it does not drift

- **Meaning is rows.** Capability behavior is declarations; the executable only
  interprets them. Nothing in a client install encodes capability meaning.
- **Resolvers are pinned by digest.** The install is admitted against a manifest
  digest and an artifact digest, and a changed build is a new immutable root — not
  an edited one.
- **Host selection is data.** `hostOs` + `hostArch` resolve to a host record; the
  record names the manifest, command and args; the declared fallback chain is
  walked only on `KERNEL_BUILD_NOT_ADMITTED`. There is no implicit fallback and no
  language inference in the tool.

### What a client install looks like, end to end

**Host (once per machine):** publish the kernel for the RID (self-contained by
default), compute the tree digest in staging and rename into a digest-named install
root, write the manifest and receipt, verify, then point the process delivery rows
at `KernelEntry.exe` with `--stdin-envelope --config kernel-host.json`. The
one-step installer is staged, not landed ([implementation-plan-next-wave.md](implementation-plan-next-wave.md) W2.1).

**Capability (per capability):** declare the rows in the estate; project with
`sfx capability project <id> --workspace <dir> --targets csharp --full-mechanics`
(the manifest carries per-file digest + `sourcePointers`; `PURE_PROJECTION_CONFORMS`);
`dotnet publish` the emitted projects (the build-time SDA project reference
disappears into the published output; self-contained removes the runtime
prerequisite); copy to `%LOCALAPPDATA%\sfx\capabilities\<capability>\`; run the
fixture suite as client acceptance. The first install's receipt:
`ProjectedConsumerTest.exe` → `PROJECTED_CAPABILITY_CONFORMS`, ten declared
operations executed natively, and **no live effect reachable by construction** (the
projected fixture body has no credential reader) — [projected-csharp-install.md](projected-csharp-install.md).

**Effects (when live):** the same rows run against the kernel with the OS vault
realization bound; the credential never reaches the caller. Replacing the
build-time project reference with pinned adapter DLLs is owed (W2.2).

---

## 5. Executable meaning and multi-OS projection

The same declared graph yields per-target embodiments and one parity contract:

- **One canonical graph, per-target realizations.** `canonicalGraphDigest` is
  shared; `realizedGraphDigest` differs per target; `observedPathDigest` is the
  outcome-parity check ([transistor-model.md](transistor-model.md) §5).
- **Conformance is computed, never hand-set.** All six kernel targets are
  graph-`ADMITTED`; language admission is computed from the per-language
  conformance result and reads `NOT_ADMITTED` on a fresh checkout until the gate
  runs. The estate's projection surface admits `node | python | csharp`.
- **Parity is live at the fixture.** The installed C# kernel answers
  `say-hello-world` with the recorded canonical / realized / observed triple, and
  the C# equity run recorded its own triple with a live payload. The
  projected-testimony conformance asserts equal observed-path digests and
  `resolverTestimony` on the shared chaining fixtures, with per-cell timing on
  every target ([invisible-execution-authority.md](invisible-execution-authority.md)
  §Implementation).

**What shipping to a new OS requires.** A kernel build for the target RID; a vault
realization for the OS keystore; a manifest naming the host, the digests and the
parity triple; and the per-OS acceptance — publish log, recomputed digests, a live
invoke from the installed root, observe parity where offered, and a vault
`store`/`apply` plus non-disclosure sweep for live effects
([kernel-install-matrix.md](kernel-install-matrix.md) §4). It does **not** require
new meaning: the capability rows and contracts are unchanged on every OS. The
irreducible per-language work remains the DB ground, the frontdoor/loader, the
bootstrap installer, the `nativeFloor` effects and the token scheduler
([transistor-model.md](transistor-model.md) §6.3).

---

## 6. The flywheel

```
declare → execute → observe → receipts → next declaration
```

Each turn leaves reusable authority behind: contracts are reused across
capabilities, ports/mechanics are bound once and re-bound by rows, declared reads
replace scripts, routing rows are reusable shapes, and the circuit view is generic
over the declared graph. That reuse is the compounding.

### The feedback signals and where they are recorded

| Signal | What it detects | Where it is recorded | Observed value |
|---|---|---|---|
| Time to new capability | whether reuse actually compounds | [flywheel-proof.md](flywheel-proof.md) (T0→T1→T2), [circuit-view-flywheel.md](circuit-view-flywheel.md) observation 3 | B: 95 s, 7/7 attempts; circuit view's second capability cost ≈0 per-capability code |
| Refusal correctness | whether the authority boundary holds | [agent-lane.md](agent-lane.md) beat 3; refusal contract; structural attestation negative fixtures | `CAPABILITY_NOT_FOUND`, zero execution cells, no provider reached; negative fixture returns `structured: false` with the cell named |
| Parity digests | cross-target equivalence and drift | manifest `parity`; SDA conformance probes; projected-testimony conformance; evidence bundles (local, gitignored) | hello-world triple live on C#; C# equity triple with live payload; equal digests on shared fixtures |
| Timing coherence | invisible execution authority (IEA) | [invisible-execution-authority.md](invisible-execution-authority.md); kernel timing command; declared `read-invocation-timing` | agent lane 715 windows closed / 3 ms; equity 179 / 3 ms; compose 181 / 1 ms; model lane 460 / 0 ms |
| Drift incidents | declaration vs embodiment divergence | receipts and finding registers ([architecture-priorities.md](architecture-priorities.md) F1/F2/F12) | C# vault-locator and collation divergences fixed to restore digest parity; F12 rows→runtime decode corruption (raw non-ASCII) worked around with `\uXXXX` escapes |

### Expansion vectors

- **Mechanics** — adding an SDA mechanic is a kernel change; after it exists,
  binding it in any capability is data.
- **Providers** — provider bindings are rows; the fallback route demonstrates that
  capability identity survives a provider substitution ("the provider failed, the
  capability didn't", [target-harness-experience.md](target-harness-experience.md)).
  A new provider does not touch the capability's meaning.
- **Languages** — adding a language adds resolvers; admission is computed from
  conformance, and the estate's projection surface expands only when a target is
  admitted.
- **Surfaces** — CLI today; the declared MCP change-tool delivery
  (`deliver-capability-change-mcp`, installed, integration staged) is a second
  client-facing surface; declared UI/presentation projections are the third; voice
  is a carrier over the same lane.
- **Estates** — the capsule-estate MCP rollout (`deliver-capsule-estate-mcp`) is
  declared as rows, so a second estate surface is a declaration, not a fork.

### Honest limits of the flywheel claim

The measured turn is one shape (declared read) and one second instance (circuit
view). Provider-backed authoring cost was not measured; the install lifecycle cost
did not fall; the one-step install and pinned-DLL build are staged. The feedback
signals above are the instruments that will falsify or confirm the next turns.

---

## 7. What must not move

| Boundary rule | What it means | Failure mode it prevents |
|---|---|---|
| **No UID** (ungoverned intelligence debt) | no executable meaning in code outside declared rows or an admitted resolver; when found, declare it or resolve it — the code cannot remain where it is | behavior that exists but is invisible to the declaration, the review, and the circuit; IEA catches the time half, the card catches the meaning half |
| **Declared-or-resolver (no third state)** | every executable behavior is declared authority (1) or inside an admitted resolver boundary (0); neither is a defect | a grey area where executable behavior accumulates with no owner and no gate |
| **Boot is resolver (0)** | frontdoor/loader, DB connection/query runner and bootstrap installer are the only irreducible code ([target-architecture.md](target-architecture.md)) | regress/circularity: a declared executor needs a reader forever, and the first installer cannot be declared |
| **No env credentials** | rows never carry plaintext; the secret exists only inside the provider call and the header injection, one use; ciphertext and unwrap key under different roofs | secrets reaching the process environment, the caller, the stream, the model, or the agent; both halves of a secret under one roof |
| **No side-repo roles** | `sidefx-cli` and `sidefx-database` may exist but must not play a role in the composite; the carrier and the DB ground are kernel bootstrap | the composite depending on sibling checkout paths and read grants; distribution that cannot stand alone |
| **The model holds no execution authority** | proposal only; no tool; one door to effect | a second, ungoverned door to effect beside the governed one |
| **No materialization on the invocation path** | the kernel interprets rows in process; projected bodies are review/release artifacts | embodiments drifting from meaning, and proof debt on the hot path |
| **One coherence pin per invocation** | one pinned read session per invocation | reads mixed across generations/definitions |
| **No facade language** | a language that returns its input unchanged is not an embodiment | claiming a language is supported while another runtime does the work |
| **No SDA edits from the estate** | cross-language changes are SDA change requests | one language patched locally, breaking parity |

The first five are the rules named for this document; the rest are the adjacent
invariants that make them hold. All are enforced by data and admission — not by
reviewer memory.

---

## 8. Limits and owed work (schedule, not architecture)

| Item | Current state | Owed | Class |
|---|---|---|---|
| **C# write isolation** | Live receipt: `fsWriteAllowed: true`, `fsWriteEnforcement: NOT_ENFORCED_MANAGED_HOST`, `fsWriteGap: NO_MANAGED_IN_PROCESS_WRITE_INTERCEPTION…`; child-process spawn is blocked on Windows (job object, active-process limit 1). .NET exposes no managed in-process write interception ([ProcessIsolation.cs](../../scenario-driven-architecture/languages/csharp/src/ScenarioKernel/bootstrap/ProcessIsolation.cs)) | OS-level write denial in the host launch profile (restricted token / AppContainer); honest gap is recorded in the process evidence on every outcome | Host launch profile |
| **macOS/Linux builds** | Only `win-x64` is executable on this machine; no macOS/Linux acceptance can be claimed from a Windows run. Keychain and Secret Service/TPM realizations do not exist | Publish per RID, install, live invoke + observe parity + vault store/apply + non-disclosure per OS ([kernel-install-matrix.md](kernel-install-matrix.md) §4) | Per-OS units; capability rows unchanged |
| **Python observe seam** | Python entry refuses `SIDEFX_OBSERVE=1` with `OBSERVATION_CHANNEL_NOT_OFFERED_BY_CARRIER:python`; no Python vault realization/credential boot parity; not an admitted fallback | K5 seams: observation channel, vault credential parity, installed-path root resolution | Per-language resolver work |
| **UID remainder** | Estate `src/` is empty and `scripts/` is gone; the installed kernel owns the circuit. Remaining UID is presentation derivation still in the generic emitter: frame characters, branch markers, labels, `circuitLabel`/collapse derivation from semantic address and cell ids; layout is not expressible in the current transformation vocabulary, so declared fragments (CV-B) and `render.mjs` retirement (CV-C2) are pending. F12 keeps raw non-ASCII out of rows until the decode path is fixed | Declare the fragments and the remaining derivation; retire the emitter vocabulary; fix the cp1252 decode path | Rows + emitter reduction (schedule) |
| Projected-testimony equity-fixture remainder | Cross-target digest equality is asserted on the shared chaining fixtures; on the equity fixture Python still carries semantic-normalized `cellId`s and the walkers record different granularities | Kernel field, tracked in [invisible-execution-authority.md](invisible-execution-authority.md) and F1/F2 | SDA emitter (registered) |
| One-step client install; pinned adapter DLLs | Three manual steps per capability; the client build still references SDA source at build time | `install-projected-csharp.mjs` with manifest/digest receipt; replace the project reference with pinned DLLs | Useful now ([implementation-plan-next-wave.md](implementation-plan-next-wave.md) W2) |
| Policy DENY / authority profiles; session ledger | Refusal is by absence; no grant model, no cross-invocation ledger | Author the grant model (SDA R5 first) and a ledger when cross-invocation attribution is required | Deferred with triggers |
| Sealed bootstrap binary | Installed executable is a self-contained directory install; Node SEA/per-OS signing is not built | Per-language bootstraps on admission; sealing is a distribution requirement, not a substitute | Deferred with triggers |

None of these is an architectural fork. Each is a unit on the same rows/kernel/OS
matrix, and each has a named acceptance receipt.

---

**One paragraph.** Declared capabilities make the next capability cost
declarations, bindings, preflight and evidence; the agent lane puts a model inside
that governed execution environment as a provider whose proposals are resolved and
routed by declared rows, with evidence, no-disclosure and timing receipts making
the boundary auditable; the installed, digest-admitted kernel executable projects
the same declared graph to each host OS, so governance is something a client
downloads and runs without the platform checkouts, and shipping to a new OS costs a
build, a vault realization and a manifest rather than new meaning. The flywheel
compounds when each declared capability leaves reusable authority behind, and the
boundary rules — no UID, declared-or-resolver, boot is resolver, no env credentials,
no side-repo roles — are what keep the compounding from drifting.
