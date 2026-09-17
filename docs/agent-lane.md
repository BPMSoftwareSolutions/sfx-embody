# The agent lane — model inside the governed execution environment

**Status.** Landed and verified live 2026-09-17 (estate `3f2cf59`, CLI `809b38a`).
This realizes the target harness experience: the model is a **provider inside
the governed execution environment**, not a harness above SideFX holding its own
tools. SideFX does not govern the model's hidden reasoning; it governs how the
model is invoked, what capabilities it can see, and whether any proposal can
become an effect.

## The surface

```text
sfx agent invoke --objective "What is Broadcom's current market price?"
```

The objective is an ordinary option — no JSON file on stage. `--model NAME` may
name the model explicitly (this environment admits `gemini` only). Canonical
JSON via `--input @file.json` remains for automation and additionally accepts
`visibleCapabilities` and `maximumOutputTokens`. The visible capability list is
what the harness lets the model see; when no visible capability can satisfy the
objective, the model may propose the capability the objective would require —
the harness then decides whether it resolves.

## What it composes

One `agent invoke` is two governed invocations, both through the unchanged
estate delivery:

1. **Model lane (a provider inside governance).** The capability
   `obtain-governed-model-response` is invoked with a
   `governed-model-invocation-request.v1`: structured generation against
   `primary-cognitive-provider` / `instruction-capable-model`, bounded by
   attempt/evidence policy. The generic LLM connector resolves the provider and
   invokes Gemini; credentials stay outside scenario facts and evidence. The
   response is untrusted testimony — a proposal, nothing more.
2. **Resolution and effect lane.** The harness resolves the proposed capability
   against the declared estate (`find`), then either invokes it through the same
   governed delivery or refuses **by absence**. Model, provider and route
   identities never own the meaning; the capability does.

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
sfx agent invoke --objective "What is Broadcom's current market price?"
```

```text
MODEL PROVIDER (agent lane)
provider    gemini (gemini-2.5-pro)
capability  obtain-governed-model-response  MODEL_RESPONSE_OBTAINED
proposal    resolve-equity-market-price-evidence  input AVGO

SIDEFX (resolution lane)
capability  resolve-equity-market-price-evidence  declared

EXECUTION LANE
disposition EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED
symbol AVGO  observedPrice 339.51 USD  marketState POSTPOST  exchange NMS
provider    rapidapi/yahoo-finance-real-time1

AGENCY RECEIPT
requested 1   executed 1   refused 0
providers reached 1 (execution), 1 (model)
```

**Beat 3 — ask for what SideFX cannot do.**

```text
sfx agent invoke --objective 'Buy $1,000 worth of Broadcom.'
```

(The single quotes are PowerShell's, so `$1,000` is not interpolated.)

Gemini proposes `execute-equity-buy-order` (its own naming); the harness
resolves it as not declared:

```text
SIDEFX (resolution lane)
capability  execute-equity-buy-order  not declared

NO EXECUTABLE PATH
CAPABILITY_NOT_FOUND
no provider reached; no effect
```

## Honest boundaries (as delivered)

- **The agency receipt is driver-composed** from the two real receipts and says
  so; there is no session/agent ledger yet. It is not a database-derived
  artifact.
- **Refusal is by absence**, not a policy DENY: no grant model, authority
  profiles or declared effect classes exist yet. "No executable path" is the
  truthful claim.
- **The proposal is the model's** — `execute-equity-buy-order`, not a scripted
  string. The harness result is independent of the model's wording.
- **Provider identity is testimony, not outcome meaning.** The execution lane
  prints `rapidapi/yahoo-finance-real-time1` from real provider testimony; the
  semantic outcome keeps `sourceAttribution` ("Delayed Quote"). Outcome meaning
  ≠ physical provider testimony.
- **Wall time is measured** (~18 s for the two invocations including the model
  call and two authority reads), never a scripted figure.
- **B4 resolved in this environment:** the `generic-llm-conveyor` connector
  package is present and the node path is live-proven. B2/B3 (graph-path
  scenario composition / effect-port catalog) are sidestepped honestly at the
  harness level: the composition is two deliveries, not `invoke-scenario`
  inside one graph.

## Remaining (with triggers)

| Item | Trigger |
|---|---|
| Beat 1 provider line in the **declared** display (the "one tiny detail": `EXECUTION TESTIMONY / provider …` in the observe frame) | before recording; a display-transformation change, not terminal code |
| Session/agent ledger and receipt-as-data | when cross-invocation attribution must be database-derived |
| Authority profiles / true policy DENY | when the grant model is authored (SDA R5 decision first) |
| Comparative eval (`sfx eval …`, models × profiles) | a second wired adapter |
| Test-suite question | answered: the estate's three non-passes are DB-gated **skips**, not failures; none touches the demo path |
