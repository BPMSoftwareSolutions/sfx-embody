# The agent lane — model inside the governed execution environment

**Status.** Declared and installed 2026-09-17: the lane is the capability
`request-capability-from-objective` (estate `d89b7f9`), with `root` binding to
the executing scenario's input (SDA `8d5b7a0`). The labeled driver
(`src/agent-delivery.mjs`) and its `agent-memory` delivery are **deleted**; the
composition is rows. This realizes the target harness experience: the model is
a **provider inside the governed execution environment**, not a harness above
SideFX holding its own tools. SideFX does not govern the model's hidden
reasoning; it governs how the model is invoked, what capabilities it can see,
and whether any proposal can become an effect.

## The surface

```text
sfx capability invoke request-capability-from-objective --input "What is Broadcom's current market price?"
```

The objective is a typed input — no JSON file on stage. The visible capability
list is declared in the capability's request-builder transformation (what the
model can see is authority, not prompt convention); when no visible capability
can satisfy the objective, the model may propose the capability the objective
would require — the declared route then decides whether it resolves.

## What it composes (declared)

One invocation runs the declared graph:

1. **Decision chain (a child scenario).** `build-agent-model-request` declares
   the prompt, the visible set and the proposal schema; the governed model
   capability `obtain-governed-model-response` is invoked as a composed child
   (structured generation against `primary-cognitive-provider` /
   `instruction-capable-model`, bounded by attempt/evidence policy). The
   response is untrusted testimony — a proposal, nothing more.
2. **Declared resolution and routing.** A declared read resolves the proposed
   capability against the estate; the route state carries `ADMITTED`/`REFUSED`.
   Declared routing selects the execution child (which invokes the admitted
   capability and terminates in its provider-attributed evidence) or the
   refusal child (`agent-refusal-evidence.v1`, no execution cells).

The model never receives a tool and never reaches a provider directly. There is
one door to effect.

## The three beats (verified receipts, 2026-09-17)

**Beat 1 — capability without an agent.**

```text
sfx capability observe resolve-equity-market-price-evidence --display --input AVGO
```

The story streams the ten declared operations (both routes), the outcome is
`EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` (AVGO 339.51 USD, POSTPOST, NMS,
`sourceAttribution` "Delayed Quote"), and the primary route's 429 with the
fallback route answering is already visible in the testimony.

**Beat 2 — intelligence proposes, the harness executes.**

```text
sfx capability invoke request-capability-from-objective --input "What is Broadcom's current market price?"
```

The model proposes `resolve-equity-market-price-evidence` with `AVGO`; the
declared route admits it, the execution child runs the equity capability, and
the terminal outcome is the provider-attributed evidence:

```text
disposition EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED
symbol AVGO  observedPrice 339.51 USD  marketState PREPRE  exchange NMS
provider    rapidapi/yahoo-finance-real-time1
```

The model lane is the decision chain in the story/trace
(`sfx capability observe request-capability-from-objective --input "…"`).

**Beat 3 — ask for what SideFX cannot do.**

```text
sfx capability invoke request-capability-from-objective --input 'Buy $1,000 worth of Broadcom.'
```

(The single quotes are PowerShell's, so `$1,000` is not interpolated.)

Gemini proposes `execute-equity-trade` (its own naming); the declared route
refuses it by absence and the refusal child shapes the receipt — the admitted
child runs zero cells:

```text
contractId  agent-refusal-evidence.v1
model       gemini (gemini-2.5-pro)  MODEL_RESPONSE_OBTAINED
proposal    execute-equity-trade  input AVGO
resolution  not declared
refusal     CAPABILITY_NOT_FOUND       (no provider reached; no effect)
```

## Honest boundaries (as delivered)

- **No driver, no composed receipt.** The outcome is the declared graph's: the
  admitted branch terminates in the invoked capability's own evidence; the
  refusal branch is `agent-refusal-evidence.v1` shaped by a declared
  transformation. There is no session/agent ledger yet, and none is implied.
- **Refusal is by absence**, not a policy DENY: no grant model, authority
  profiles or declared effect classes exist yet. "No executable path" is the
  truthful claim.
- **The proposal is the model's** — observed as `execute-equity-trade`, not a
  scripted string. The harness result is independent of the model's wording.
- **Provider identity is testimony, not outcome meaning.** The execution
  branch returns the provider-attributed evidence
  (`rapidapi/yahoo-finance-real-time1`); the semantic payload keeps
  `sourceAttribution` ("Delayed Quote"). Outcome meaning ≠ physical provider
  testimony.
- **Wall time is measured** per invocation, never a scripted figure.
- **The refusal receipt's `diagnostic` field is temporary** (the full model
  outcome, kept for the final verification runs); remove it from
  `shape-agent-refusal-evidence` before recording.
- **B4 resolved in this environment:** the `generic-llm-conveyor` connector
  package is present and the node path is live-proven. Cross-capability
  composition is now the declared path: the graph-source assembly emits the
  invocation closure's scenarios (estate `1c11d74`) and `root` binds to the
  executing scenario's input (SDA `8d5b7a0`).

## Remaining (with triggers)

| Item | Trigger |
|---|---|
| Beat 1 provider line in the **declared** display (the "one tiny detail": `EXECUTION TESTIMONY / provider …` in the observe frame) | before recording; a display-transformation change, not terminal code |
| Session/agent ledger and receipt-as-data | when cross-invocation attribution must be database-derived |
| Authority profiles / true policy DENY | when the grant model is authored (SDA R5 decision first) |
| Comparative eval (`sfx eval …`, models × profiles) | a second wired adapter |
| Test-suite question | answered: the estate's three non-passes are DB-gated **skips**, not failures; none touches the demo path |
