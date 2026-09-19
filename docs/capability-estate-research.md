# Capability estate research: what is declared today, and what scale requires

**Status.** Researched 2026-09-19 against the live circuit. Scope: the declared
capability estate as it stands, the gaps that block an agent or a person from
working it at scale, and the capabilities that would close them. Method is in §1;
every count and every failure below came from a live read, not from a document.

Proposed identities in §6 are written `proposed:<identity>` and are **not
declared**. Nothing in this document declares anything.

## 1. Method

| Read | Command | Result |
| --- | --- | --- |
| Full estate | `sfx capability list --json` | exit 0, 16 s, 281 KB, 318 capabilities |
| Discovery | `sfx capability find <query> --json` | exit 0, 4–12 s |
| Circuit | `sfx capability circuit say-hello-world --json` | **exit 4**, `CIRCUIT_VIEW_CELL_TESTIMONY_REQUIRED` |
| Host | `../scenario-driven-architecture` at `ed64315`; kernel `7eec4896…` present and selected in `sfx.config.json`; `sfx` on PATH | all live |

The `list` payload carries, per capability: `capabilityId`, `namespaceId`,
`definitionDigest`, `name`, `mode`, `declaredRootCount`, `declaredRootScenarioId`,
`scenarioCount`, `userStory`, `promise`, `circuitAvailable`. That record is the
authority for §2 and §4.

`evidence/existing-capabilities.txt` (318 rows, local, gitignored) agrees with the
live read on identity and count. It is a convenience, not the authority.

**Not verified here:** no capability was invoked for effect; no migration was
authored, preflighted or installed; no provider was exercised. Everything below is
from declared reads.

## 2. What exists today

**318 declared capabilities**, all in `sidefx:capabilities`. Every one has at least
one declared root (`declaredRootCount == 0` is empty) and at least one scenario —
`scenarioCount` runs 1 to 30, median 1.

For scale: [invocation-latency-2026-09-08.md](invocation-latency-2026-09-08.md)
records 219 capabilities and 824 capability/scenario pairs on 2026-09-08. The
estate added **99 capabilities in 11 days** without a build step. The
declaration-only expansion claim in the README is borne out by the count.

### The families

Grouped by what they do, with counts from the live list.

| Family | Count | Representative identities |
| --- | ---: | --- |
| **SDA ports** (`sda-*.v1/.v2`) — the admitted resolver surface | 38 | `sda-governed-http-exchange-port.v1`, `sda-generic-llm-connector-port.v1`, `sda-external-credential-reference-binding-port.v1` |
| **Projection and presentation** (`project-*`) | 33 | `project-document-presentation`, `project-focus-navigation`, `project-validation-presentation`, `project-openapi-description` |
| **Resolution** (`resolve-*`) | 24 | `resolve-credential`, `resolve-governed-scenario-route`, `resolve-equity-market-price-evidence` |
| **Declared reads** (`read-*`) | 18 | `read-capability-meaning`, `read-declared-authority`, `read-projected-bodies`, `read-invocation-timing` |
| **Conformance and proof** (`prove-*`, `verify-*`, `determine-*`) | 33 | `prove-monotonic-execution-circuit`, `verify-capability-authoring-lineage`, `determine-execution-conformance` |
| **Authoring** (`author-*`, plus context and disposition) | ~15 | `author-one-scenario-candidate`, `assemble-sidefx-capability-authoring-context`, `govern-authoring-convergence`, `generate-executable-capability-scaffold` |
| **Change lifecycle and delivery** | ~11 | `open-capability-change`, `seal-capability-change`, `publish-capability-change`, `observe-capability-change`, `deliver-capability-change-{api,cli,mcp}` |
| **Model / agent lane** | ~14 | `execute-governed-model-invocation`, `govern-model-provider-binding`, `interlock-agent-operation`, `request-capability-from-objective` |
| **Tooling migration** (the UID retirement machinery) | ~10 | `operate-tooling-migration-{run,verify,promote,inventory}`, `audit-controlled-tooling-migration-batch` |
| **Credentials and vault** | 5 | `resolve-credential`, `store-credential`, `bind-external-credential-reference`, `read-credential-non-disclosure` |
| **Admission** (`admit-*`) | 12 | `admit-capability-authority`, `admit-kernel-specification`, `admit-declared-contract` |
| **Domain and demo** | ~10 | `resolve-equity-market-price-evidence`, `hello-world`, `greet-by-name`, `adapt-job-market-intelligence-evidence` |

### The consumer surface

`config/sfx.commands.json` declares two surfaces. `database-invocation` carries
`invoke`, `observe`, `reveal`, `circuit`, `catalogue`, `list`, `find`, `artifact`;
`database-projection` carries `project`. Both `list` and `find` are scenarios of
the single capability `list-capabilities` — discovery is itself declared, which is
the right shape.

**This is a strong estate.** Authoring, proof, projection, the model lane and the
change lifecycle are all declared rather than coded. The gaps below are narrow by
comparison, and most are declaration-only to close.

## 3. What works, measured

- **Whole-estate discovery in 16 seconds.** This is the headline. The 2026-09-08
  record shows `DELIVERY_TIMEOUT` at 120 s with the resolver query costing 120.9 s;
  [database-preparation.md](database-preparation.md) removed that query from
  invocation, and the estate-wide read now completes well inside one delivery
  window. Interactive discovery is viable today.
- **Single-token discovery in 4–12 seconds.** `find equity` returns
  `compose-resolve-equity-market-price-evidence`; `find hello` returns
  `greet-by-name` and siblings; `find market` returns 9 rows.
- **Retained meaning is near-complete.** 313 of 318 carry a `userStory` in
  `{actor, intent, outcome}` form. An agent can pick a capability by intent without
  reading a single document.

## 4. Gaps found live

These were produced by the reads in §1, and are reproducible.

### G1 — Multi-token discovery silently returns nothing

```
sfx capability find market          → completed, 9 rows
sfx capability find "market price"  → completed, outcome: null
sfx capability find market price    → completed, outcome: null
```

`resolve-equity-market-price-evidence` contains both tokens, so an intersection
should be non-empty. Both multi-token forms return `disposition: completed`,
`outcomeVariant: TERMINAL`, `outcome: null` and **exit 0**.

The severity is not the empty result, it is the indistinguishability: a caller
cannot tell "nothing matches your query" from "this surface does not do multi-token
queries". An agent asked to find a capability for a two-word intent — the normal
case — concludes the estate has nothing and proceeds to author a duplicate. This is
the single most scale-hostile behavior found.

### G2 — The circuit view is unavailable for every capability

`circuitAvailable` is `false` for all 318 rows. Probed directly rather than
inferred from the uniform value:

```
sfx capability circuit say-hello-world --json
→ exit 4, CIRCUIT_VIEW_CELL_TESTIMONY_REQUIRED
```

The read requires cell testimony that a static read does not carry. This matches
the tracked state — [architecture-achieved.md](architecture-achieved.md) §9 row 7
records CV-B declared fragments pending and CV-C2 `render.mjs` retirement pending —
so it is a known unit, not a new defect. Recorded here because the consequence is
concrete: the declared `circuit` surface answers for nothing, and the capability
whose execution a person most wants to *see* is exactly the one they cannot.

### G3 — Metadata coverage holes

| Hole | Count | Identities |
| --- | ---: | --- |
| No `userStory` | 5 | `generate-executable-capability-scaffold`, `plan-capability-embodiment`, `provision-capability-artifacts`, `resolve-estate-dependency-closure`, `write-capability-embodiment` |
| `userStory` missing `actor`/`intent`/`outcome` | 8 | (malformed or partial; identities available in the list payload) |
| No `promise` | 13 | |
| `mode` undefined | 16 | `author-canonical-feature`, `detect-hand-authored-code`, `realize-admitted-capability`, `verify-capability-scenario-outcomes`, … |

Five of the story-less capabilities are *authoring and embodiment* capabilities —
the ones an agent most needs to discover by intent. They are invisible to
intent-based `find` precisely where discovery matters most.

Nothing is missing a declared root or a scenario, so this is metadata hygiene, not
structural breakage. `reveal-and-refine-capability-meaning` already exists as the
repair path; what is missing is anything that *notices*.

### G4 — Versioned siblings with no declared supersession

`govern-strategic-decision` and `-v2`; `sda-projected-capability-invocation-port.v1`
and `.v2` — both pairs present with no declared relation between them. Three more
carry a version suffix whose base is absent (`hello-world-2`,
`project-consumer-execution-embodiment-v2`,
`sda-governed-file-system-shaping-port.v2`).

At 318 capabilities and +99 in 11 days, "which one do I call?" is answered today by
reading identities and guessing. That does not survive another hundred.

## 5. Gaps the estate already tracks

Cited, not re-derived, so this document does not restate owed work as discovery:

- **Composition boundary** ([sql/README.md](../sql/README.md)): drop-in composition
  works; **adapter** composition is not expressible, and a child's `rejected`
  disposition fails the parent. This is the ceiling on composing capabilities into
  larger ones — the main structural limit on scaling meaning.
- **§9 owed list** ([architecture-achieved.md](architecture-achieved.md)): C#
  filesystem-write enforcement (`NOT_ENFORCED_MANAGED_HOST`); macOS/Linux kernel
  builds; the Python observe seam. SDA `ed64315` ("Bind declared credential
  operations to the macOS host vault") is movement on the third.
- **Installed but unintegrated** ([implementation-plan-next-wave.md](implementation-plan-next-wave.md)):
  the MCP change surface and the context capabilities are declared and installed,
  awaiting integration — W4. Not new work.

## 6. What to develop

Two groups. Each row names the evidence that motivates it and whether it is
declaration-only. **None of these identities is declared**; the `proposed:` prefix
is deliberate so this document cannot be mistaken for the estate.

### Agent-friendly: close the authoring loop

| # | Proposed | Why, with evidence | Declaration-only? |
| --- | --- | --- | --- |
| A1 | `proposed:find-capability-by-intent` (or repair the `find` scenario) | **G1.** Multi-token intent is the normal agent query. Until it returns an intersection — or a distinguishable "unsupported query" outcome variant — discovery misleads rather than fails | Yes — a scenario and transformation on `list-capabilities` |
| A2 | `proposed:classify-invocation-failure` | The `declare-provider-fallback` skill teaches the diagnosis in prose: `exchangeCount >= 1` means a provider answered and failed; `exchangeCount: 0` means no request was made and a second provider fails identically. That is a decision rule living in a skill file instead of in rows. AGENTS.md's "that is a finding, not a reason to edit the kernel" depends on getting this classification right | Yes |
| A3 | `proposed:record-finding` + `docs/findings/` | AGENTS.md names the finding as the correct outcome of a blocked invocation, and there is nowhere for one to go. Also [agent-harness-hooks.md](agent-harness-hooks.md) §5.3: gating the wrong move without building the right one is just pressure | Partly — the home is a directory, the receipt is rows |
| A4 | `proposed:read-declared-identities` | This research needed the identity list and had to use a gitignored local `.txt` plus a 16 s full-estate read. [agent-harness-hooks.md](agent-harness-hooks.md) §5.1 needs the same dump for the anti-fabrication controls, and it must be a declared read or the control is itself unauthorized | Yes |
| A5 | `proposed:preflight-capability-change` and its receipt | The **authoring** lifecycle is declared (`open`/`seal`/`publish`/`observe-capability-change`), but the **migration** lifecycle — dry run, preflight from the uncommitted transaction — runs on SDA bootstrap scripts that no capability names. The step that protects the estate is the one step with no declared surface | No — needs the bootstrap seam |
| A6 | `proposed:determine-capability-metadata-conformance` | **G3.** `reveal-and-refine-capability-meaning` can repair meaning; nothing notices it is missing. The `determine-*-conformance` family is the established pattern | Yes |

### User-friendly: make the estate legible

| # | Proposed | Why, with evidence | Declaration-only? |
| --- | --- | --- | --- |
| U1 | Complete the circuit view (CV-B fragments) | **G2.** The declared `circuit` surface currently answers for nothing. Seeing a capability execute is the difference between trusting the platform and taking its word | Partly — CV-C2 retires `render.mjs` |
| U2 | `proposed:declare-capability-supersession` | **G4.** Five versioned identities, no declared relation. At the current growth rate this compounds into a naming swamp | Yes |
| U3 | Integrate the presentation layer | 33 `project-*` capabilities are declared and, per W4, awaiting integration. The largest user-facing asset in the estate is built and not yet wired | No new declaration — integration |
| U4 | Adapter composition | §5. Drop-in composition works; adapter composition is the one that lets a capability be reused in a context it was not shaped for. This is the ceiling on reuse, and reuse is what scale means here | No — planner and declared-pipeline work |

### Sequence

1. **A1** — the cheapest fix with the worst current consequence. An agent that
   cannot find what exists will author a duplicate of it.
2. **A4, A6** — make the estate self-describing; both are declared reads.
3. **A2, A3** — turn the two diagnosis rules that live in prose into rows and give
   a finding somewhere to land.
4. **U1, U3** — legibility for people: the circuit view and the presentation layer.
5. **A5, U2** — the lifecycle seam and supersession.
6. **U4** — adapter composition, the deepest and the one that most changes what the
   platform can express.

## 7. The honest summary

The estate is in better shape than the gap list suggests. 318 capabilities with
declared roots, scenarios and retained meaning; 99 added in 11 days with no build
step; whole-estate discovery in 16 seconds where it timed out at 120 s eleven days
ago. The declaration-only expansion claim holds up under a live read.

What is missing is not capability — it is **reflexivity**. The estate can author,
prove, project and execute meaning, and it cannot yet reliably tell you what it
contains (G1), show you one running (G2), notice its own metadata holes (G3), or
say which of two versions is current (G4). Every one of those is a capability the
platform is already shaped to hold, and four of the six agent-side proposals are
declaration-only.

The one item that is not a declaration is the one that matters most for meaning at
scale: adapter composition. Everything else is rows.
