The next flywheel is **not another execution flywheel**. We already have that:

```text
DECLARE
  ↓
EXECUTE
  ↓
OBSERVE
  ↓
RECEIPT
  ↓
NEXT DECLARATION
```

That one proves the machinery compounds. 

The next flywheel should make **usage itself grow the capability estate**.

# Intent → Capability → Learning → More Capability

```text
                    HUMAN / AGENT INTENT
                            │
                            ▼
                 "What do I want to happen?"
                            │
                            ▼
                 RESOLVE CAPABILITY FROM
                       OBJECTIVE
                            │
                ┌───────────┴───────────┐
                │                       │
                ▼                       ▼
             ADMITTED                 ABSENT
                │                       │
                ▼                       ▼
             EXECUTE              REFUSAL / GAP
                │                       │
                ▼                       ▼
            EXPERIENCE            DEMAND SIGNAL
                │                       │
                ▼                       ▼
             EVIDENCE          AUTHOR / COMPOSE /
                │               BIND CAPABILITY
                │                       │
                └──────────┬────────────┘
                           ▼
                    ESTATE IMPROVES
                           │
                           ▼
                    NEXT OBJECTIVE
```

I would call this the **Capability Demand Flywheel**.

And we accidentally already demonstrated the two sides of it.

With:

```text
"What is Broadcom's current market price?"
```

the model proposed an existing capability, the estate admitted it, and SideFX executed it.

With:

```text
"Buy $1,000 worth of Broadcom."
```

the model proposed `execute-equity-trade`, but because that capability was absent, SideFX produced `CAPABILITY_NOT_FOUND`; zero execution cells ran and no provider was reached. 

**Today that refusal is an endpoint.**

The next flywheel turns it into a **product signal**.

---

## The missing-capability signal is gold

Imagine SideFX returning:

```text
OBJECTIVE
Buy $1,000 worth of Broadcom.

PROPOSED CAPABILITY
execute-equity-trade

ESTATE RESOLUTION
NOT DECLARED

EFFECT
NONE

DEMAND OBSERVED
execute-equity-trade requested

DISPOSITION
CAPABILITY GAP
```

Now we've learned something real:

> Somebody wanted an effect the estate cannot currently produce.

That can become the input to the next governed circuit:

```text
Capability Gap
    ↓
Find existing capability?
    ↓
Can existing capabilities compose it?
    ↓
Can existing mechanic/provider bindings satisfy it?
    ↓
Does new capability authority need to be authored?
    ↓
Conform
    ↓
Admit
    ↓
Estate grows
```

Then the next time an equivalent objective appears:

```text
same intent
   ↓
capability exists
   ↓
resolve
   ↓
execute
```

That's compounding at the **product level**, rather than merely the engineering level.

---

# And this is where the Semantic Brain becomes commercially important

The naive implementation would send every gap back to an LLM:

> “Invent something.”

No.

We now have enough accumulated semantic data to narrow first:

```text
UNRESOLVED INTENT
      ↓
SEMANTIC NARROWING
      ↓
Do we already possess...

exact capability?
similar capability?
composable capabilities?
required mechanics?
provider candidates?
contract precedents?
scenario precedents?
      ↓
ONLY THEN
novel authoring if necessary
```

So every admitted capability increases the probability that the **next requested effect can be resolved from existing knowledge instead of invented from scratch**.

That's the compounding curve we've wanted all along.

---

## It actually creates three nested loops

```text
LOOP 1 — EXECUTION
Capability
→ Execute
→ Outcome
→ Evidence


LOOP 2 — ENGINEERING
Declaration
→ Execute
→ Observe
→ Learn
→ Better declaration machinery


LOOP 3 — PRODUCT
Intent
→ Resolve capability
→ Experience / Gap
→ Grow estate
→ More intents become resolvable
```

**Loop 3 is the next flywheel.**

And it's potentially much bigger than the first two because that's when SideFX starts getting more useful simply because people use it.

---

# The metric changes too

We've been measuring things like:

```text
time to create capability
parity
execution testimony
unattributed time
```

Now I'd start measuring one new number:

### **Intent Resolution Rate**

```text
Intent Resolution Rate
=
objectives satisfied by existing admitted estate
───────────────────────────────────────────────
total valid objectives presented
```

Then break the failures down:

```text
EXACT_CAPABILITY_FOUND
COMPOSITION_FOUND
REBIND_REQUIRED
PROVIDER_REQUIRED
MECHANIC_REQUIRED
NEW_CAPABILITY_REQUIRED
NOT_AUTHORIZED
NOT_UNDERSTOOD
```

Now you can literally watch SideFX learn.

Early estate:

```text
100 intents
  ↓
32 immediately resolvable
```

Later:

```text
100 intents
  ↓
71 immediately resolvable
```

Later still:

```text
100 intents
  ↓
91 immediately resolvable
```

Not because the model got smarter.

**Because the organization accumulated executable capability.**

That distinction is enormous.

---

And there's the real SideFX flywheel:

> **Every unresolved intent can reveal capability demand. Every admitted capability increases what the organization can intentionally do. Every execution creates evidence about what it actually can do.**

So I'd put the next product milestone right here:

```text
OBJECTIVE
   ↓
RESOLVE
   ↓
EXECUTE or IDENTIFY GAP
   ↓
LEARN
   ↓
GROW ESTATE
   ↓
RESOLVE MORE OBJECTIVES
```

### **Intent → Capability → Experience → Learning → Capability**

That's the flywheel I'd build next.
