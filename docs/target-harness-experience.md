**Whoa is right.** This materially improves the demo.

The biggest change is that the old readiness blocker—*“live provider credential is quota-exhausted, so Act 1 cannot show a live price”*—is no longer controlling the slice. That was explicitly B1 in the review. 

And what replaced it is actually **better than simply refreshing the API key**.

You now have a live capability that can encounter a degraded provider path, resolve another provider, and still establish the **same declared outcome**.

## What you just proved

Your scenario is still:

```text
resolve-equity-market-price-evidence
```

The capability identity did **not** become:

```text
resolve-price-from-yahoo-provider-166
```

or:

```text
resolve-price-from-real-time1
```

Instead:

```text
             CAPABILITY INTENT

     Resolve equity market price evidence
                     │
                     ▼
              declared circuit
                     │
          ┌──────────┴──────────┐
          │                     │
     PRIMARY ROUTE         FALLBACK ROUTE
          │                     │
      HTTP 429                BOUND
          │                     │
          X                     ▼
                           provider executes
                                │
                                ▼
                         price evidence
                                │
                       ┌────────┘
                       ▼
                SELECT ROUTE
                       │
                       ▼
                 SAME OUTCOME
```

That is **provider independence made visible**.

And that is a much stronger SideFX demonstration than:

> “Here is an API call that works.”

---

# The raw CLI is already telling a hell of a story

Look at what you have now:

```text
GIVEN live-equity-price-request

WHEN
  ✓ build-equity-price-binding-request
  ✓ bind-equity-price-provider-credential
  ✓ build-equity-price-exchange-request
  ✓ observe-equity-price-exchange

  ✓ normalize-equity-price-evidence

  ✓ build-fallback-price-binding-request
  ✓ bind-fallback-price-provider-credential
  ✓ build-fallback-price-exchange-request
  ✓ observe-fallback-price-exchange

  ✓ select-equity-price-route

THEN
  ✓ equity-market-price-evidence

STATUS EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED
```

That is almost a **live executable circuit diagram already**.

The audience doesn't need to understand every operation. What matters is:

```text
INPUT
  ↓
resolve provider
  ↓
provider unavailable / constrained
  ↓
resolve alternative
  ↓
execute
  ↓
select admitted evidence
  ↓
OUTCOME
```

And the outcome remains:

```text
EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED
```

That continuity is the point.

---

# For Bill's demo, this gives us a beautiful second lesson

We already had:

### Lesson 1 — Intelligence ≠ authority

```text
Model proposes
      ↓
SideFX execution boundary
      ↓
executable / not executable
```

Now you have another:

### Lesson 2 — Capability ≠ provider

```text
Capability
    │
    ├── Provider A
    │       429
    │
    └── Provider B
            ✓

        ↓

Same outcome
```

Those two principles together are *really* strong:

```text
MODEL ≠ CAPABILITY

and

CAPABILITY ≠ PROVIDER
```

Or even more compactly:

```text
INTELLIGENCE
     ≠
AUTHORITY
     ≠
CAPABILITY
     ≠
PROVIDER
```

SideFX is holding those boundaries apart.

---

# I would not show all ten operations initially

For the September 24 meeting, the detailed trace is **proof underneath the story**, not the story itself.

Bill first sees:

```text
$ sfx capability observe \
    resolve-equity-market-price-evidence \
    --display \
    --input AVGO
```

Then something like:

```text
SIDEFX — GOVERNED CAPABILITY EXECUTION
════════════════════════════════════════════════

GIVEN
  Live equity price requested
  Symbol: AVGO

WHEN
  Resolve equity market price evidence

  Primary provider
      ↓
  rate limited
      ↓
  fallback provider resolved
      ↓
  provider executed
      ↓
  evidence selected

THEN
  EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED

  Symbol        AVGO
  Price         339.51 USD
  Market        POST
  Exchange      NMS
  Attribution   Delayed Quote
```

Then you can say:

> “There are ten governed operations underneath that. Want to see them?”

And hit the detailed view.

That is a much better executive experience.

---

# And there's an important demo moment here

Imagine deliberately showing the primary provider fail.

```text
PRIMARY PROVIDER
────────────────────────
HTTP 429
quota exhausted

             │
             ▼

SIDEFX

failure observed
not outcome

             │
             ▼

FALLBACK PROVIDER
────────────────────────
rapidapi/yahoo-finance-real-time1

BOUND
EXECUTED

             │
             ▼

OUTCOME
────────────────────────
EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED
```

Then say:

> **“The provider failed. The capability didn't.”**

That's a very strong sentence.

Because now Bill is seeing something that maps straight into enterprise continuity.

His site is talking about organizations preserving judgment and continuity when individuals or circumstances change.

You're showing the same architectural property lower down:

> **The responsibility survives the supplier.**

---

# The rubric says: don't let the remaining rate-limit work slow this demo

This part is important.

You mentioned these remain:

* surface `httpStatus` in bounded provider evidence;
* declared probe capability;
* 30-day selection read.

Those sound valuable for the **provider-management flywheel**.

But apply the rubric literally:

> *If this decision is omitted from this slice, which intended behavior fails?* 

For the Bill demo?

### `httpStatus` evidence

**Useful now**, maybe close to needed if you want to visibly and truthfully say:

```text
PRIMARY → HTTP 429
```

If the current execution testimony already contains an attributable failure disposition that the renderer can use, don't block on another field.

If the only place `429` exists is buried outside the bounded evidence you're presenting, then surfacing it may earn its way into this slice because it makes the failover claim inspectable.

### Declared probe capability

**Defer.**

It doesn't change the September 24 experience.

Trigger:

> when automated provider-health resolution becomes part of the product rather than demonstration setup.

### 30-day selection read

**Defer.**

That's operating intelligence / optimization.

Very valuable eventually.

Not necessary to show:

```text
provider constrained
→ alternate provider
→ same capability closes
```

The rubric explicitly distinguishes **Needed now**, **Useful now**, and **Defer**, and tells us not to let future extensibility establish current necessity. 

---

# Same with `48/51`

Don't let:

```text
48 / 51
```

automatically become:

```text
demo blocked
```

We need to classify the three red tests.

The question is not:

> “Is the entire repository green?”

It's:

> **“Does any one of those three failures invalidate the exact execution path or claim we intend to demonstrate?”**

If yes:

```text
NEEDED NOW
```

Fix it.

If not:

```text
record finding
defer
demo proceeds
```

That is exactly the architecture-decision discipline you've been trying to establish.

---

# The one-slice demo just got cleaner

I now see the Bill demo as **three beats**, not six.

## Beat 1 — Capability without an agent

```text
$ sfx capability observe \
    resolve-equity-market-price-evidence \
    --display \
    --input AVGO
```

Show:

```text
GIVEN → WHEN → THEN

primary route constrained
fallback route executes

EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED
```

Message:

> **“This is the harness executing a governed capability. No agent is necessary.”**

---

## Beat 2 — Put intelligence in front

Gemini receives:

```text
"What is Broadcom's current market price?"
```

Returns only:

```text
{
  capability: "resolve-equity-market-price-evidence",
  input: "AVGO"
}
```

Then:

```text
MODEL
  │
  │ proposes
  ▼
SIDEFX
  │
  │ executes
  ▼
CAPABILITY
  │
  ▼
PROVIDER
  │
  ▼
EVIDENCE
```

Message:

> **“The model supplies intelligence. It doesn't inherit execution authority.”**

---

## Beat 3 — Ask it for something SideFX cannot do

```text
"Buy $1,000 worth of Broadcom."
```

Gemini proposes:

```text
execute-equity-purchase
```

SideFX:

```text
CAPABILITY_NOT_FOUND

NO EXECUTABLE PATH
NO EXECUTION
```

Then finish with:

```text
                 SIDEFX

        Intelligence can propose.

        Capability determines
        what can become effect.

        Provider determines
        how admitted work is realized.

        Evidence tells us
        what actually happened.
```

That's enough.

---

# And now your provider fallback strengthens the agent story too

This creates a gorgeous layering:

```text
                    MODEL 
                      │
                      │ proposes intent
                      ▼
                ┌───────────┐
                │  SIDEFX   │
                └─────┬─────┘
                      │
               capability exists?
                      │
                 YES  │  NO
                  │   │   X
                  ▼   │ NO EFFECT
              CAPABILITY
                  │
             provider resolution
                  │
          ┌───────┴────────┐
          ▼                ▼
      Provider A       Provider B
          │                │
        429                ✓
          │                │
          └───────┬────────┘
                  ▼
               OUTCOME
                  │
                  ▼
               EVIDENCE
```

Look at how many things are **not allowed to own the meaning**:

* Gemini doesn't own it.
* Yahoo doesn't own it.
* RapidAPI doesn't own it.
* the fallback route doesn't own it.
* the CLI doesn't own it.

The capability survives all of them.

That is SideFX in one picture.

---

## One tiny detail I'd improve before recording

Your visible `THEN` result currently contains:

```text
"sourceAttribution": "Delayed Quote"
```

while your preflight evidence knows the provider was:

```text
rapidapi/yahoo-finance-real-time1
```

If the provider identity is already in real execution testimony, I would surface it in the **control-room rendering**—not necessarily inside the semantic outcome contract.

For example:

```text
OUTCOME
  sourceAttribution    Delayed Quote

EXECUTION TESTIMONY
  provider             rapidapi/yahoo-finance-real-time1
```

That distinction is actually better than stuffing provider identity into business outcome data.

It reinforces:

```text
OUTCOME MEANING
≠
PHYSICAL PROVIDER TESTIMONY
```
---

However, the sketch with the AI agent/model above needs to show **one critical inversion**:

> The model is **inside the governed execution environment as a provider**, not sitting above SideFX holding its own tools.

And one precision: SideFX doesn't control the model's hidden internal reasoning. It governs **how the model is invoked, what context/capabilities it can see, and whether any proposal can become an effect**.

## The cleanest sketch

```text
                         HUMAN
                           │
                           │ intent / objective
                           ▼
                ┌─────────────────────┐
                │       SIDEFX        │
                │   HARNESS / ENTRY   │
                └──────────┬──────────┘
                           │
                           │ resolve capability
                           ▼
                ┌─────────────────────┐
                │ GOVERNED MODEL      │
                │ INVOCATION          │
                │     CAPABILITY      │
                └──────────┬──────────┘
                           │
                           │ invoke provider
                           ▼
                ┌─────────────────────┐
                │   MODEL PROVIDER    │
                │ Gemini / GPT / etc. │
                └──────────┬──────────┘
                           │
                           │ proposal / reasoning result
                           ▼
                ┌─────────────────────┐
                │       SIDEFX        │
                │                     │
                │  resolve requested  │
                │     capability      │
                └──────────┬──────────┘
                           │
                  ┌────────┴────────┐
                  │                 │
           EXECUTABLE PATH      NO PATH /
                  │             NOT ADMITTED
                  ▼                 │
        ┌──────────────────┐       X
        │   CAPABILITY     │    NO EFFECT
        │    EXECUTION     │
        └────────┬─────────┘
                 │
                 │ resolve provider
                 ▼
        ┌──────────────────┐
        │ PHYSICAL / API   │
        │    PROVIDER      │
        └────────┬─────────┘
                 │
                 ▼
               EFFECT
                 │
                 ▼
              EVIDENCE
                 │
                 └──────────────► SIDEFX
{
  "symbol": "AVGO",
  "region": "US",
  "currency": "USD",
  "observedPrice": 339.51,
  "observedMarketTime": 1789588801,
  "marketState": "PRE",
  "exchange": "NMS",
  "sourceAttribution": "Delayed Quote"
}
```

That is the architecture.

---

## The important loop

The model never gets:

```text
MODEL
 ├── Yahoo tool
 ├── brokerage tool
 ├── filesystem tool
 ├── HTTP tool
 └── whatever else
```

Instead it gets something conceptually like:

```text
MODEL
  │
  │ can observe available capability identities
  │
  │ can propose:
  ▼
"invoke capability X
 with input Y"
```

Then SideFX decides whether that request can actually resolve.

So the agentic loop becomes:

```text
             ┌──────────────────────────────────┐
             │                                  │
             ▼                                  │
          SIDEFX                                │
             │                                  │
             │ invoke model capability          │
             ▼                                  │
       MODEL PROVIDER                           │
             │                                  │
             │ proposes next bounded action     │
             ▼                                  │
          SIDEFX                                │
             │                                  │
             │ resolve / admit / execute        │
             ▼                                  │
       CAPABILITY                               │
             │                                  │
             ▼                                  │
          OUTCOME                               │
             │                                  │
             │ becomes observation/context      │
             └──────────────────────────────────┘
```

**SideFX owns the loop boundary.**

The model participates in the loop.

The model does not own the loop.

---

# The agent is therefore this composition

This is probably the conceptual diagram we were missing:

```text
┌───────────────────────────────────────────────────────────────┐
│                       SIDEFX HARNESS                          │
│                                                               │
│  Objective                                                    │
│      │                                                        │
│      ▼                                                        │
│  ┌─────────────────────────┐                                  │
│  │ Governed Model          │                                  │
│  │ Invocation Capability   │                                  │
│  └────────────┬────────────┘                                  │
│               │                                               │
│               ▼                                               │
│        ┌──────────────┐                                       │
│        │ Model        │                                       │
│        │ Provider     │                                       │
│        └──────┬───────┘                                       │
│               │ proposal                                      │
│               ▼                                               │
│  ┌─────────────────────────┐                                  │
│  │ Capability Resolution   │                                  │
│  │ + Authority             │                                  │
│  └────────────┬────────────┘                                  │
│               │                                               │
│         ┌─────┴─────┐                                         │
│         ▼           ▼                                         │
│      EXECUTE      REFUSE                                      │
│         │                                                     │
│         ▼                                                     │
│    Provider                                                   │
│         │                                                     │
│         ▼                                                     │
│      Effect                                                   │
│         │                                                     │
│         ▼                                                     │
│     Evidence                                                  │
│         │                                                     │
│         └────────────► next governed observation              │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

The **agent emerges from the composition**.

You don't necessarily need a separate magical thing called an agent runtime.

Conceptually:

```text
AGENT
=
Model
+
Objective
+
Observation
+
Capability visibility
+
Iterative invocation
```

But each of those sits inside the SideFX boundary.

---

# Compare it to the weak architecture

This makes the distinction very obvious.

### Weak version

```text
HUMAN
  │
  ▼
AGENT HARNESS
  │
  ├── MODEL
  ├── TOOLS
  ├── MEMORY
  └── EXECUTION LOOP
          │
          ▼
        SIDEFX
          │
          ▼
     some governed
      capabilities
```

Problem:

```text
SideFX governs
only the things
the agent chooses
to send through SideFX.
```

The agent may still have another door.

```text
             AGENT
            /     \
           /       \
      SIDEFX      DIRECT TOOL
        │             │
        ▼             ▼
    GOVERNED       UNGOVERNED
```

That defeats the strong claim.

---

# Strong version

```text
                    HUMAN
                      │
                      ▼
        ╔══════════════════════════╗
        ║          SIDEFX          ║
        ║                          ║
        ║          MODEL           ║
        ║            │             ║
        ║         proposes         ║
        ║            │             ║
        ║            ▼             ║
        ║       CAPABILITY         ║
        ║        RESOLUTION        ║
        ║            │             ║
        ║      ┌─────┴─────┐       ║
        ║      ▼           ▼       ║
        ║   EXECUTE      REFUSE    ║
        ║      │                   ║
        ║      ▼                   ║
        ║   PROVIDER               ║
        ║      │                   ║
        ║      ▼                   ║
        ║    EFFECT                ║
        ║      │                   ║
        ║      ▼                   ║
        ║   EVIDENCE               ║
        ╚══════════════════════════╝
```

There is **one door to effect**.

That's the important property.

---

# And your Yahoo capability fits perfectly

Now substitute the actual demo:

```text
HUMAN
 │
 │ "What is Broadcom trading at?"
 ▼
SIDEFX
 │
 ├─ invoke governed-model-response
 │
 ▼
GEMINI
 │
 │ proposes
 ▼
resolve-equity-market-price-evidence
 │
 ▼
SIDEFX
 │
 │ capability exists
 │ authority resolves
 ▼
EQUITY PRICE CAPABILITY
 │
 ├── primary Yahoo route ──► 429
 │
 └── fallback route ───────► real-time1
                                │
                                ▼
                              PRICE
                                │
                                ▼
                             EVIDENCE
                                │
                                ▼
                              SIDEFX
                                │
                                ▼
                              HUMAN
```

And on the next turn:

```text
HUMAN
 │
 │ "Buy $1,000 of Broadcom."
 ▼
SIDEFX
 │
 ▼
GEMINI
 │
 │ proposes
 ▼
execute-equity-purchase
 │
 ▼
SIDEFX
 │
 X
CAPABILITY_NOT_FOUND

NO EXECUTABLE PATH
NO PROVIDER
NO EFFECT
```

Now the whole demo is coherent.

---

## The sentence underneath the architecture

I think this is the cleanest formulation:

> **The model is allowed to reason broadly, but it can only act through capabilities that SideFX can resolve and execute.**

Or even tighter:

> **The model proposes. SideFX disposes. Providers perform. Evidence returns.**

And architecturally:

```text
INTELLIGENCE
      ↓
   PROPOSAL
      ↓
   SIDEFX
      ↓
  AUTHORITY
      ↓
 CAPABILITY
      ↓
  PROVIDER
      ↓
   EFFECT
      ↓
  EVIDENCE
```

That's the sketch I'd build the whole demo around.
