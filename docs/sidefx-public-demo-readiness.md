# Investor demo readiness — blockers, complications, and the defer list

**Purpose.** Team-review research for the investor demo script
([sidefx-public-demo.md](sidefx-public-demo.md)). It records what is real today,
what blocks each scripted beat, what makes the beats complicated, and what can be
deferred without weakening the storyline. It creates no requirements; the
authority stack in [architecture-priorities.md](architecture-priorities.md) still
governs, and the rubric's necessity test ("if omitted, which beat fails?") is the
filter applied below.

**Status date.** 2026-09-15, estate `e4ad16f`, tree clean. Research was read-only:
three parallel agents, no database writes, one provider probe.

## 1. Verdict

**The scripted demo is not achievable next turn as written.** Two of its four
pillars are blocked by non-rendering work:

1. **The model/agent lane cannot execute on the graph path.** The estate declares
   the whole model language, but every model capability fails with
   `SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING: 'invoke-scenario'` — graph-path
   scenario composition is an SDA work item, and the LLM connector is node-only
   with its connector-authority package absent from this checkout.
2. **The live provider credential is quota-exhausted** (`429`, remaining `0`,
   reset `2026-10-06T16:52Z`). Act 1 cannot show a live price until the credential
   is replaced/renewed.

What **is** achievable next turn, honestly: a control-room presentation of the
real governed invocation (from `observe` data), the real refusal path for the
purchase/circumvention beats (`CAPABILITY_NOT_FOUND` — no executable path), a
harness driver that renders only captured receipts, and the model story told as
*declared and revealable, execution pending*.

## 2. What is real today

| Real capability | Evidence |
|---|---|
| Governed invocation: admission, authority resolution, provider-slot resolution, execution testimony, `observedPathDigest`, evidence, story join | `sfx capability observe resolve-equity-market-price-evidence --input @examples\equity-market-price-evidence.request.json --trace/--json`; receipts `evidence/demo-2026-09-15T14-23-18.443Z/` |
| Refusal by absence (the honest deny) | `sfx capability invoke execute-equity-purchase --json` → `CAPABILITY_NOT_FOUND`; same for `generic-http-request` |
| The declared model/agentic language | 27 model capabilities, e.g. `obtain-governed-model-response`, `execute-governed-model-invocation`, `project-model-provider-protocol`, `bind-model-testimony-evidence`; `reveal --as meaning` renders them |
| Typed input mapping | `sfx capability invoke resolve-equity-market-price-evidence --input AAPL --json` exits 0 via the declared CLI input mapping (`embodiments/…/interfaces.authority.json`) |
| Retained live receipts | `evidence/demo-2026-09-15T12-25-03.280Z`, `…12-28-14.353Z` (QQQ 709.18, `Delayed Quote`); post-digest green run 14:21Z (MSFT 498.82, `sha256:10d4386c…`) |
| Demo verifier | `scripts/verify-demo.mjs` — 11 cases, receipts + `report.json`, no synthesized values |

**Correction to a suspected regression.** The declaration-conformance migration's
digest move (`8ad3907…` → `10d4386c…`) did **not** break live equity: the post-migration
run at 14:21Z returned `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` at the new digest. The
current red is the provider quota (`429`, remaining 0). Lane C unit 15 remains
pending, but it is not evidenced as the cause; re-verify after the credential is
renewed or replaced.

## 3. Beat-by-beat assessment

| Beat | Exists today | Gap | Class | Deferrable? |
|---|---|---|---|---|
| Act 1 — direct governed invocation with control-room frame | all data: story responsibilities + dispositions/timings, declared authority id, provider identity, RESULT fields, `observedPathDigest`, timings | terminal frame layout; the demo's invented labels (execution id, evidence id, provider slot, `EXECUTION CLOSED`, 384 ms) have no source; per-responsibility provider identity and effect class are not in story/testimony | rendering + two declared projections | frame yes; data additions yes |
| Act 1 live price | historical receipts | quota-exhausted credential; stale `examples/equity-price.request.json` seam | external | only with a new credential or a recorded/unavailable storyline |
| Act 2 — agent lane (`sfx agent run`) | declared model capabilities (reveal only) | no `agent`/`eval` CLI surface; `invoke-scenario` missing on the graph path; LLM connector node-only; connector-authority package absent; no model transcript exists to replay | SDA (2 requests) + estate authoring | no for execution; yes to stage as declared-only |
| Act 3 — deny + circumvention | refusal-by-absence is real | no `execute-equity-purchase` / `generic-http-request` declared; no grant/effect-class vocabulary; no "providerReached"/"physicalEffect" field | estate authoring (grants) + SDA (principal/grant decision) | yes, restaged as refusal-by-absence (truthful) |
| Act 4 — Agency Exposure Receipt | per-invocation receipts only | no session/agent ledger; no attribution | data (ledger) | yes, a driver-composed receipt from real receipts, labeled |
| Act 5 — comparative eval (models × profiles) | nothing | `eval` surface, profiles, ≥2 wired model adapters | data + boot | yes — trigger: model lane executable |
| Act 6 — ASCII mini-circuit animation | nothing; markdown narrator was retired (`cfcaa44`); no box drawing in the terminal | terminal rendering; meaningful only after the lanes exist | rendering | yes — presentation only |
| ASCII sketches in CLI output | `--format markdown` only changes heading style; no Mermaid fences today (the Mermaid review document was the retired narrator) | a terminal frame renderer | terminal-owned (per `narration-projection-disposition.md`) | frame yes; agent/authority sketches depend on Acts 2–4 |

## 4. Blocker register

| # | Blocker | Evidence | Severity | Resolution |
|---|---|---|---|---|
| B1 | RapidAPI monthly quota exhausted | probe 2026-09-15T22:37Z: `429`, limit 500, remaining 0, reset `2026-10-06T16:52Z`; matches F6 | blocks live Act 1 | replace/renew the credential, or adopt the recorded/unavailable storyline (never invent a price) |
| B2 | Graph path cannot compose scenarios (`invoke-scenario`) | `obtain-governed-model-response`, `observe-governed-http-exchange` both fail `SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING: 'invoke-scenario'`; implemented only in the legacy consumer-plan path (`SDA:…/admitted-consumer-platform.mjs:159`); `SDA:docs/handoff/sda-capability-invocation.md:3` | blocks Acts 2–4 execution | **SDA request R1** |
| B3 | Scheduler effect provider dispatches a two-entry map, not the admitted port catalog | `SDA:…/semantic-execution-graph-effect-provider.mjs:11-14` (credential + HTTP only); `platform-effect-provider.mjs:243-251` (read-file, bounded-process) | blocks the LLM connector and generic-HTTP beats | **SDA request R2** |
| B4 | LLM connector node-only; connector-authority package absent here | `sda-platform-capabilities…json:412-425` `projectionTarget: node`; no python/csharp implementation; `generic-llm-conveyor/config/provider-authority.json` absent from this checkout; `LOC_GEMINI_API_KEY` present | blocks model lane parity and even the node path as checked out | **SDA request R4** + restore the connector package |
| B5 | No agent/authority meaning: no agent object/verb, no grants, no effect classes (`pure/observation/effect` exists, not READ_ONLY/MUTATION), no session ledger, no `providerReached`/`physicalEffect` field | greps of `sql/`, `src/`, SDA schemas; `sfx --help` offers only `capability` + `media`; policy/principal schemas exist only in the enterprise layer | blocks Acts 2–4 as scripted | estate authoring program (minimal row-set below) — or restage |
| B6 | Demo vocabulary mismatch | `sfx invoke … --symbol AAPL` → exit 2 (`Unknown option '--symbol'`); the surface is `sfx capability invoke … --input AAPL`; `observe` is the command that carries story/overlay | screens do not run as written | doc correction (no code) |
| B7 | Demo risk: timing, nondeterminism, concurrency | measured invocation 1.95–3.0 s vs the doc's 384 ms; live model output nondeterministic; shared `sidefx` database and a second worktree (`sfx-embody.worktrees/greeting-response-handler`) | credibility | driver prints measured wall times; freeze window; recorded fallback |

## 5. What makes it complicated

- **Meaning vs presentation.** The convincing frames (authority ALLOW/DENY, effect
  classes, provider-reached, physical-effect-none, agency receipt) are *meaning*,
  not layout. The transistor rule says declared (1) or resolver (0); rendering is
  terminal-owned, but the frames' nouns must come from rows. Two of them
  (per-responsibility provider identity, effect class) are declared projections
  that do not exist yet; the rest need the grant/ledger work.
- **The deny beat is a policy claim.** Today the purchase is refused because no
  capability exists (`CAPABILITY_NOT_FOUND`), not because a grant was evaluated.
  That is honest and strong ("no executable path exists") but different from
  "authority denied"; the script must say the former unless the grant model is
  authored.
- **Two providers, two failure modes.** The model lane's blocker (composition +
  connector) is independent of the provider quota; fixing one does not unblock
  the demo.
- **The held-out connector package.** Even the node LLM path needs the
  `generic-llm-conveyor` sibling checkout; this is an environment prerequisite,
  not repo work.
- **Cross-target parity debt.** The LLM connector has no python/csharp
  implementation, so any agent capability would be node-only — a parity gap to
  schedule, not to hide (transistor-model §6/§9).

## 6. Honesty boundaries for the demo (per the rubric §8)

- **May** show: real governed invocation and testimony; real refusal by absence;
  the declared model/agentic language via `reveal`; retained live receipts
  **labeled** with capture time, snapshot and `observedPathDigest`.
- **May not** show without new work: `sfx agent run` / `sfx eval` as working
  surfaces; a model proposal as executed; a `CAPABILITY_NOT_FOUND` as a policy
  DENY; "provider not reached" for the purchase (the truthful statement is "no
  execution occurred"); READ_ONLY/MUTATION as declared effect classes; an agency
  receipt as database-derived (a driver-composed receipt must say so); the demo's
  384 ms as a measurement.
- Fixture substitution, if ever used, is governed by the rubric: substitute at the
  declared provider seam, record the fixture identity, and state that provider
  conformance and the external effect remain unproven.

## 7. Recommended next-turn scope (the credible cut)

One wave, three units, all honest without B2/B3/B4/B5:

1. **Act 1 control-room frame (terminal rendering).** Add a frame presentation to
   `sidefx-cli/src/render.mjs` for `observe` results, built only from fields that
   exist (`story.scenario.responsibilities[]`, dispositions, timings,
   `eventAuthorityId`, `overlay` admission, `result.outcome`, `providerTestimony`,
   `observedPathDigest`, `evidence.timings`). Real ids and values; measured wall
   time; no invented `exec_*`/`ev_*`/provider-slot labels; ASCII GIVEN/WHEN/THEN
   lanes as terminal presentation. Gated behind a flag so existing outputs and
   tests are untouched.
2. **Refusal beat (driver).** Run the real `execute-equity-purchase` and
   `generic-http-request` refusals and frame them as "no declared capability — no
   executable path"; never print "authority denied".
3. **Demo driver (`scripts/demo-driver.mjs`, boot/harness).** Runs each beat via
   `cmd /c` with UTF-8, captures stdout/stderr/exit/wall time, renders only from
   captured output, supports `--recorded` banners for the retained receipts,
   probes the quota first, and fails when a claimed outcome did not hold (the
   `verify-demo.mjs` discipline). No database meaning, no migrations during
   recording.

Still deferred next turn: agent execution (B2–B5), the session ledger, the
receipt-as-data, comparative eval, profiles, animation, brokerage.

## 8. Defer list with revisit triggers

| Item | Trigger |
|---|---|
| Agent execution lane (Acts 2–4) | SDA R1 + R2 landed, connector package restored, and a model transcript produced — then author the minimal row-set |
| Minimal agent row-set (single-scenario `request-capability-from-objective` binding `sda-generic-llm-connector-port.v1`; driver lane; refusal beats) | after R1/R2; avoid composed scenarios until R1 lands |
| Session/agent ledger and receipt-as-data | when cross-invocation attribution is required beyond a labeled driver composition |
| Authority profiles / effect classes / true policy DENY | when the grant model is authored (SDA R5 decision first) |
| Comparative eval (`sfx eval …`) | model lane executable and ≥2 adapters wired |
| ASCII animation / persistent mini-circuit | after the driver's frames are stable; presentation only |
| Real brokerage/purchase | a declared mutable-effect capability with authority and provider — outside current intent |
| Vault manager, sealed bootstrap, inverse projection, long-lived host | already tracked in `architecture-priorities.md` §3 |

## 9. Decisions the team must make

| # | Decision | Options | Recommendation |
|---|---|---|---|
| D1 | Provider access for Act 1 | renew/replace `RAPID_API_KEY`; or recorded receipt; or live unavailable branch | renew/replace if the live price matters; otherwise recorded + unavailable, both labeled |
| D2 | Agent lane scope for this demo | commit to R1/R2 + connector + estate authoring; or stage as *declared and revealable, execution pending* | stage as declared-only for the investor; commit to the build for the next one |
| D3 | Deny storyline | refusal-by-absence (real today); or author the grant model for a true policy DENY | refusal-by-absence now — it is the stronger architectural claim |
| D4 | Model if the lane is built | Gemini only (wired); OpenAI (adapter needed); Claude (nothing declared) | Gemini first, single attempt, structured response contract |

## 10. Evidence index

- Demo script: [sidefx-public-demo.md](sidefx-public-demo.md) (untracked at review time; committed alongside this assessment).
- Current terminal outputs: `evidence/demo-2026-09-15T14-23-18.443Z/` (observe trace/json, display, reveal).
- Retained live receipts: `evidence/demo-2026-09-15T12-25-03.280Z/`, `…12-28-14.353Z/`.
- Quota: probe receipt 2026-09-15T22:37Z (429, remaining 0, reset `2026-10-06T16:52Z`); F6 in `architecture-priorities.md`.
- Model lane: `sfx capability reveal obtain-governed-model-response --as meaning`; failure receipts in this review; `SDA:docs/handoff/sda-capability-invocation.md`.
- SDA requests: R1 (graph-path `invoke-scenario`), R2 (scheduler dispatch of the admitted port catalog), R4 (LLM connector parity), R5 (principal/grant/effect-class decision, deferrable) — to be filed in the standard format.
