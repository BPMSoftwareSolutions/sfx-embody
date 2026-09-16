# declare-provider-fallback skill validation

**Scope.** `.claude/skills/declare-provider-fallback/SKILL.md` and its template,
validated against the live model and the SDA runtime on 2026-09-16 (estate
`4e0c154`). Method: reference audit, code inspection, and one-off direct provider
calls that exercised the skill's central mechanism without the kernel. Those calls
were validation instrumentation only — no probe script is retained in the repo.
The checking behavior is **declared authority**: when the fallback work proceeds
it is authored as a declared capability (deterministic guard and no-binding
fixtures), not as boot code.

## Verdict

**Validated — the skill is accurate, safe, and its decision gate is correct.**
Every cited reference resolves; its central claim (a guarded request performs no
transport) is confirmed empirically; and its first rule correctly blocks a
fallback for the estate's *current* equity failure, which is a kernel artifact
(`exchangeCount: 0`), not a provider failure. Four nits and one plan-level
blocker are recorded below; none invalidates the skill.

## 1. Reference audit

| Skill claim | Verified |
|---|---|
| `declare-scenario.sql:68` is `model.declare_scenario` | yes; also the file's `:148` is `SCENARIO_OPERATION_BINDING_NOT_DECLARED` |
| `guard-equity-response-decoding.sql:22` is the expression-authoring pattern | yes (`model.normalize_transformation_expression`) |
| `invoke-from-transaction.mjs:65` carries `invocationIdentity`/`endpointAuthorityDigest` | yes |
| `declare-equity-provider-slot-requirements.sql:49` asserts the operation count | yes (`EQUITY_WORKING_EXECUTION_DIVERGED`, `<>5`) |
| The declared vocabulary in §5 (`routeOrder`, `fallbackEligibleFailureClasses`, `attemptBudget`, `bindings[]`, `preferredBindingId`, `failureClass`, `attemptsUsed`) | the scaffolded `select-equity-market-price-provider` authority; the skill correctly says re-derive from the declaration rather than restate |
| The F10 pointer (§1) | `docs/sda-change-request-effect-altitude-execution.md` exists; its signature matches the estate run exactly |

## 2. Mechanism verification (one-off call receipts)

Direct provider calls with the real equity configuration, no kernel in the path.
Method disposition: the same checks are declarable — a capability whose operations
invoke the credential and exchange ports with declared inputs and fixtures — and
that is where they belong; no executable probe is added to this repo.

| Case | Result |
|---|---|
| Guarded/empty request (route should not run) | `rejected-endpoint`, `reachedStage: endpoint-admission`, `exchangeCount: 0`, `httpStatus: 0`, 0 ms — **no transport** |
| Valid request without a live one-use binding | `rejected-credential`, `reachedStage: credential-binding`, `exchangeCount: 0` |
| Valid request with a live binding | `retained-non-success`, `reachedStage: response-complete`, `exchangeCount: 1`, `transportDisposition: completed`, **`httpStatus: 429`**, 323 ms |

So the skill's rule holds precisely: **`exchangeCount >= 1` with a provider-side
rejection → fallback warranted; `exchangeCount: 0` → not the provider.** The 429
case also produces the exact evidence a rate-limit record needs, and the current
estate failure (`exchangeCount: 0`) is confirmed as the F10 artifact.

## 3. Nits (skill)

1. **§2 "its own credential reference name" is wrong for same-account RapidAPI.**
   The same secret (`RAPID_API_KEY`) grants every host under the account; what
   differs is the credential *authority entry* — the fallback endpoint digest,
   scope, and requesting capability. Declaring a new reference name would imply a
   second secret or require a duplicate env var. Suggested wording: "its own
   credential authority admitted for the fallback endpoint digest (the reference
   name may stay `RAPID_API_KEY` when the same secret grants the route)".
2. **§1's readable evidence list overstates today's telemetry.** The bounded
   provider evidence that passes the observation filter is
   `reachedStage`, `exchangeCount`, `transportDisposition`, `redactionVerified`.
   `disposition` and `httpStatus` are *not* streamed; `httpStatus` is the
   rate-limit signal. Reading them requires `--json` today, or the allowlist must
   gain `httpStatus` (bounded scalar; recommended — it is also what a rate-limit
   register needs).
3. **A skipped route reads as failed.** The guard's pre-network rejection is a
   declared `rejected-endpoint` *failure* variant: the skipped fallback's cells
   stream as `failed` even when the route was deliberately not attempted. The
   final selection is correct, but the display should distinguish "route skipped"
   from "route failed" (a declared skipped/`not-attempted` surface), or the
   audience reads a failure that never happened.

## 4. The proposed fallback + rate-limit cycling

Adding `yahoo-finance15` and `yahoo-finance-real-time1` as fallback price
providers and cycling them on 30-day rate-limit evidence.

**What the skill already covers.** The route shape (ports, operations,
selection carrying provider identity, classified variants, slot-inventory
re-declaration) and the three-case preflight. Two extra routes at +2 operations
each (+4 total; the request builders can be reused or added per route) — the
`<>5` assertion must be re-declared in the same change, exactly as the skill's
traps say.

**What blocks it today (in order):**

1. **F10 — the exchange never runs on the estate path.** `exchangeCount: 0`; a
   fallback would fail identically until
   `docs/sda-change-request-effect-altitude-execution.md` lands. Owner: SDA.
2. **Quote operations supplied; entitlement and endpoint authorities unproven —
   updated 2026-09-16.** The price-capable operations are
   `GET /api/v1/markets/quote?ticker=…&type=STOCKS` on
   `yahoo-finance15.p.rapidapi.com` and
   `GET /market/get-quotes?region=…&symbols=…` on
   `yahoo-finance-real-time1.p.rapidapi.com` — same RapidAPI account, so the same
   `RAPID_API_KEY` authority, each route with its own endpoint digest. Neither is
   declared in the harness provider operations yet, and neither has ever been
   observed: the earlier replacement candidate `rapidapi/apidojo/yh-finance`
   reached `yh-finance.p.rapidapi.com` and returned **403
   `NOT_SUBSCRIBED_TO_API`**
   (`agentic-harness/provisioning/rapidapi-finance-provider-swap-live-exchanges.evidence.receipt.json`),
   and the two hosts' only declared operations so far are `market-news` and
   `stock-options` with `admission: NOT_CLAIMED`. Before any route is authored,
   the harness must declare the two quote operations, compile their operation
   descriptors for the endpoint authorities and digests, and observe each
   exchange (entitlement, normalized response class, price-field mapping). The
   estate does not compute a digest and will not fabricate one. Owner: harness
   (you) for declaration and observation; estate follows with the routes per the
   skill.
3. **The rate-limit signal is not surfaced.** `httpStatus: 429` is real in the
   evidence but not streamed; the bounded allowlist omits it. Owner: estate
   (one bounded scalar; pairs with nit 2).
4. **No durable run-evidence store.** The invocation path is read-only
   (`bodyStorage: NOT_REQUESTED`; `evidence/` is disk). "Evidence runs in the
   database" is a **declared capability**: a probe capability per provider,
   invocable through the unchanged CLI, its outcome classified and retained by the
   estate's evidence/publication path. Only the cadence of those runs is
   boot-side, and it is a scheduled invocation, not new executable logic. The
   invocation path must not gain a write. Owner: estate, authored as rows when
   the fallback work proceeds.

**Expressible once unblocked.** Each route is rows (skill §2); a skipped route
performs no transport (verified); the selection chooses the answering route's
evidence and its provider identity; the scenario variants name and classify each
result (`…_RATE_LIMITED` as failure, "all routes exhausted" distinct from
"primary unavailable"). The 30-day cycling is a declared selection over the
evidence store, choosing the preferred route order per invocation — data, not
code — provided items 3–4 exist.

**Suggested sequence.** (1) F10 lands (SDA). (2) Decide the evidence store and
add `httpStatus` to bounded provider evidence (estate). (3) Declare price
endpoint authorities for the two hosts (harness/user). (4) Author the two routes
per the skill with the three-case preflight. (5) Add the evidence run recorder
and the 30-day selection read; verify a real cycle: primary 429 → fallback
answers → the rate-limited provider is deprioritized for thirty days.

## 5. Evidence

- One-off provider-call receipts, 2026-09-16: guarded request → `rejected-endpoint`
  / `exchangeCount: 0`; no live binding → `rejected-credential` /
  `exchangeCount: 0`; live route → `response-complete` / `exchangeCount: 1` /
  `httpStatus: 429`. Instrumentation only; not committed as a script.
- Estate receipt for the current failure: `sfx capability observe
  resolve-equity-market-price-evidence --input AVGO --json` (`exchangeCount: 0`).
- Provider catalog: `agentic-harness/authority/cli/provider-catalog.json` and
  `authority/provider-connections/http-provider.operations.json`.
