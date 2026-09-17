# Demo CLI commands — step by step

Runnable commands for the three beats of the target harness experience
(`C:\source\repos\bpm\intelligence\docs\target-harness-experience-demo.md`),
verified 2026-09-17 on the declared surfaces: the agent lane is the capability
`request-capability-from-objective` (estate `d89b7f9`), no driver and no agent
command. See [agent-lane.md](agent-lane.md) for the design and boundaries.

**Working directory:** the estate root (`C:\lab\repos\sfx-embody`), with `sfx`
on PATH (the junction to the `sidefx-cli` checkout) and a valid
`sfx.config.json` in that directory.

**No JSON files are needed on stage.** The objective is a typed input.
(Canonical JSON via `--input @file.json` remains for automation and is used in
the verification variants below.)

**Before the first command.**

- `LOC_GEMINI_API_KEY` is present per the vault/credential declaration in the
  selected estate (the model lane's declared credential reference resolves).
- The primary RapidAPI credential may be quota-exhausted (`429`). **Do not
  renew it for the demo** — the fallback route answering while the primary is
  rate-limited is the story.
- Every command here is read-only: no installs, no migrations, no writes.

**Quoting.** PowerShell: double quotes are safe for objectives without `$`;
use single quotes when the objective contains `$` (e.g. `'Buy $1,000 …'`), and
double any apostrophe inside a single-quoted string. Bash: double quotes
throughout.

## Step 0 — confirm the surface (10 seconds, optional)

```text
sfx --help
```

Expected: `Offered by the selected estate` includes
`sfx capability observe` and `sfx capability invoke`.

## Beat 1 — the harness executes a governed capability, no agent

```text
sfx capability observe resolve-equity-market-price-evidence --display --input AVGO
```

Point at, in order:

1. `GIVEN live-equity-price-request` — the admitted input.
2. `WHEN` — the ten declared operations, both routes: the primary five
   (binding request → credential → exchange request → exchange → normalize)
   then the fallback five (… → select route).
3. `STATUS EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`.
4. The outcome: `symbol AVGO`, `observedPrice 339.51` (varies), `currency USD`,
   `marketState`, `exchange NMS`, `sourceAttribution Delayed Quote`.

The line to say: **"The primary provider is rate-limited underneath that
status; the harness resolved another route and the capability still closed."**

Verification variant (machine-readable, cmd capture):

```text
cmd /c "sfx capability observe resolve-equity-market-price-evidence --display --input AVGO --json > beat1.json 2>&1"
```

Check `result.outcome.disposition` is
`EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` and
`result.outcome.providerTestimony.providerId` =
`rapidapi/yahoo-finance-real-time1` (the route that answered).

Deeper variant (the ten-op trace, for the "want to see them?" moment):

```text
cmd /c "sfx capability observe resolve-equity-market-price-evidence --input AVGO --trace"
```

## Beat 2 — intelligence proposes, the harness disposes

```text
sfx capability invoke request-capability-from-objective --input "What is Broadcom's current market price?"
```

Expected: the declared graph runs the decision chain (the model capability
proposes `resolve-equity-market-price-evidence` with input `AVGO`), the route
admits it, and the terminal outcome is the provider-attributed evidence:

```text
disposition EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED
symbol AVGO  observedPrice 339.51 USD  currency USD  exchange NMS
provider    rapidapi/yahoo-finance-real-time1
```

Check: the outcome contract is `equity-market-price-evidence.v1`, the payload
carries the symbol and price, and the provider testimony names the route that
answered.

The model lane is visible as the decision-chain cells:

```text
cmd /c "sfx capability observe request-capability-from-objective --input "What is Broadcom's current market price?" --trace"
```

Verification variant (machine-readable):

```text
cmd /c "sfx capability invoke request-capability-from-objective --input "What is Broadcom's current market price?" --json > beat2.json 2>&1"
```

Wall time is measured per invocation, never scripted.

## Beat 3 — ask for what SideFX cannot do

```text
sfx capability invoke request-capability-from-objective --input 'Buy $1,000 worth of Broadcom.'
```

Expected (the model's own naming may differ; observed `execute-equity-trade`):

```text
contractId  agent-refusal-evidence.v1
model       gemini (gemini-2.5-pro)  MODEL_RESPONSE_OBTAINED
proposal    execute-equity-trade  input AVGO
resolution  not declared
refusal     CAPABILITY_NOT_FOUND
```

The admitted child runs zero cells and no provider is reached.

The line to say: **"The model proposed a purchase. There is no executable
path; no provider was reached and no effect occurred."** Do **not** call this
an authority/deny decision — it is refusal by absence (no grant model exists
yet).

## What these commands are not

- There is no `sfx agent` command and no `sfx eval`: the lane is the declared
  capability, invoked through the unchanged `sfx capability` surface.
- There is no `--symbol` option: typed input is `sfx capability … --input AVGO`.
- The proposed purchase capability id is whatever the model says (observed
  `execute-equity-trade`, `execute-equity-buy-order`, `buy-equity`).

## Variability and recovery

| Symptom | Meaning | Action |
|---|---|---|
| `observedPrice` differs run to run | live market | normal; the receipt carries the values |
| Beat 2 outcome `PROVIDER_UNAVAILABLE` | model provider rejected/empty | re-run; the lane reports the real disposition |
| Refusal proposal differs in wording | model naming | the harness result is independent of it |
| Beat 1 status not `RESOLVED` | primary and fallback both failed | check quota/network; the frame carries the real disposition — never narrate past it |
