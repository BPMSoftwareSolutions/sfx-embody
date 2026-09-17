# Demo CLI commands — step by step

Runnable commands for the three beats of the target harness experience
(`C:\source\repos\bpm\intelligence\docs\target-harness-experience-demo.md`),
verified 2026-09-17 (estate `3f2cf59`, CLI `809b38a` + the `--objective`
surface). See [agent-lane.md](agent-lane.md) for the surface and its honest
boundaries.

**Working directory:** the estate root (`C:\lab\repos\sfx-embody`), with `sfx`
on PATH (the junction to the `sidefx-cli` checkout) and a valid
`sfx.config.json` in that directory.

**No JSON files are needed on stage.** The objective is an ordinary option:
`--objective "…"`. (Canonical JSON via `--input @file.json` remains for
automation and is used in the verification variants below.)

**Before the first command.**

- `LOC_GEMINI_API_KEY` is present in the environment (the model lane's declared
  credential reference resolves from it).
- The primary RapidAPI credential is quota-exhausted (`429`). **Do not renew it
  for the demo** — the fallback route answering while the primary is
  rate-limited is the story. The 429 is expected, not a failure.
- Every command here is read-only: no installs, no migrations, no writes.

**Quoting.** PowerShell: double quotes are safe for objectives without `$`;
use single quotes when the objective contains `$` (e.g. `'Buy $1,000 …'`), and
double any apostrophe inside a single-quoted string. Bash: double quotes
throughout.

## Step 0 — confirm the surface (10 seconds, optional)

```text
sfx --help
```

Expected: `Offered by the selected estate` includes `sfx agent invoke` and
`sfx capability observe`.

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
   `marketState POSTPOST` (varies with session), `exchange NMS`,
   `sourceAttribution Delayed Quote`.

The line to say: **"The primary provider is rate-limited underneath that
status; the harness resolved another route and the capability still closed."**

Verification variant (machine-readable, cmd capture):

```text
cmd /c "sfx capability observe resolve-equity-market-price-evidence --display --input AVGO --json > beat1.json 2>&1"
```

Check `result.result.outcome.disposition` is
`EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` and
`result.result.outcome.providerTestimony.providerId` =
`rapidapi/yahoo-finance-real-time1` (the route that answered).

Deeper variant (the ten-op trace, for the "want to see them?" moment):

```text
cmd /c "sfx capability observe resolve-equity-market-price-evidence --input AVGO --trace"
```

## Beat 2 — intelligence proposes, the harness disposes

```text
sfx agent invoke --objective "What is Broadcom's current market price?"
```

Expected frame:

```text
MODEL PROVIDER (agent lane)
provider    gemini (gemini-2.5-pro)
capability  obtain-governed-model-response  MODEL_RESPONSE_OBTAINED
proposal    resolve-equity-market-price-evidence  input AVGO

SIDEFX (resolution lane)
capability  resolve-equity-market-price-evidence  declared

EXECUTION LANE
disposition EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED
symbol AVGO  observedPrice 339.51 USD  …
provider    rapidapi/yahoo-finance-real-time1

AGENCY RECEIPT
requested 1   executed 1   refused 0
providers reached 1 (execution), 1 (model)
```

Check: the proposal is the model's (wording may vary; `input` should be the
ticker), `declared`, the execution disposition, the answering provider, and
`receipt.executed 1`.

`--model gemini` may be added explicitly; this environment admits only that
name (any other value fails `AGENT_MODEL_NOT_ADMITTED`, before any model call).

Verification variant:

```text
cmd /c "sfx agent invoke --objective ""What is Broadcom's current market price?"" --json > beat2.json 2>&1"
```

Check `agentLane.disposition`, `agentLane.proposal`, `resolution.declared`,
`executionLane.disposition`, `executionLane.providerTestimony.providerId`,
`receipt`, and `receiptNote` (the receipt is driver-composed — say so on
stage).

Wall time: typically 15–25 s (model call + authority reads + execution); it is
measured, not scripted.

Optional (the inversion in one command): `sfx capability invoke
obtain-governed-model-response --input
@examples/agent/model-invocation-request.json --json` shows the model being
invoked by a capability and returning `MODEL_RESPONSE_OBTAINED` — the JSON
carrier here is the capability's declared request contract, not demo setup.

## Beat 3 — ask for what SideFX cannot do

```text
sfx agent invoke --objective 'Buy $1,000 worth of Broadcom.'
```

Expected:

```text
MODEL PROVIDER (agent lane)
provider    gemini (gemini-2.5-pro)
capability  obtain-governed-model-response  MODEL_RESPONSE_OBTAINED
proposal    buy-equity  input AVGO      ← the model's own id may differ

SIDEFX (resolution lane)
capability  buy-equity  not declared

NO EXECUTABLE PATH
CAPABILITY_NOT_FOUND
no provider reached; no effect

AGENCY RECEIPT
requested 1   executed 0   refused 1
providers reached 0 (execution), 1 (model)
```

The line to say: **"The model proposed a purchase. There is no executable
path; no provider was reached and no effect occurred."** Do **not** call this
an authority/deny decision — it is refusal by absence (no grant model exists
yet).

## What these commands are not

- There is no `sfx agent run` and no `sfx eval`: the surface is
  `sfx agent invoke --objective "…"` (or `--input @file.json` for automation).
- `--model` admits only `gemini` here; other names are refused before any
  model call.
- There is no `--symbol` option: typed input stays `sfx capability … --input AVGO`.
- `execute-equity-purchase` is not declared; the model's proposed purchase
  capability id is whatever it says (observed: `execute-equity-buy-order`,
  `buy-equity`).

## Variability and recovery

| Symptom | Meaning | Action |
|---|---|---|
| `observedPrice` differs run to run | live market | normal; the receipt carries the values |
| Proposal `input` is a company name, not a ticker | model wording | the outcome will read nulls; re-run |
| `MODEL_RESPONSE_NOT_OBTAINED` / `PROPOSAL_NOT_RECEIVED` | provider rejection (e.g. `MAX_TOKENS`) | the lane reports it honestly; re-run |
| Beat 1 status not `RESOLVED` | primary and fallback both failed | check quota/network; the frame carries the real disposition — never narrate past it |
