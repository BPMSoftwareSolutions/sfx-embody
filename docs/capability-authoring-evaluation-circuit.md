**YES. That’s the flywheel.** The evaluation program and the capability-authoring program should not be separate systems.

The model evaluation should happen **by making the model author real SideFX capability candidates**.

Your existing authoring architecture already says the model should first seek reuse, then composition, then profiling, and only then create new identity; the model-produced feature is explicitly a **reviewable candidate with a model receipt**, while the existing inspection/admission/conformance machinery remains authoritative. 

So the loop becomes:

```text
                    INTENT
                      │
                      ▼
           AUTHORING CONTEXT PACK
     corpus / precedents / laws / schemas /
     mechanics / proof obligations / budget
                      │
                      ▼
              MODEL PROVIDERS
         ┌────────────┼────────────┐
         ▼            ▼            ▼
      Model A      Model B      Model C
         │            │            │
         ▼            ▼            ▼
     Candidate A   Candidate B   Candidate C
         │            │            │
         └────────────┼────────────┘
                      ▼
              ALIGNMENT EVALUATION
                      │
       ┌──────────────┼───────────────┐
       ▼              ▼               ▼
    semantic       architecture      proof
    alignment       alignment       alignment
       │              │               │
       └──────────────┼───────────────┘
                      ▼
               HUMAN / GOVERNED
                   REVIEW
                      │
            ┌─────────┴─────────┐
            ▼                   ▼
         REPAIR               ACCEPT
            │                   │
            └─────────┬─────────┘
                      ▼
                    PROVE
                      ▼
                    ADMIT
                      ▼
                   CAPSULE
                      │
                      ├────────────► capability estate
                      │
                      ▼
             EVALUATION EVIDENCE
                      │
                      ▼
                LEARN / PROMOTE
                      │
          ┌───────────┼─────────────┐
          ▼           ▼             ▼
       precedent   evaluator      deterministic
       memory      improvement      mechanic
          │           │             │
          └───────────┼─────────────┘
                      ▼
              NEXT AUTHORING RUN
```

That is a genuine **closed learning circuit**.

## And “alignment” gets a much more concrete meaning

We are no longer asking:

> “Did the model answer the prompt well?”

We're asking:

> **“Did this model author a capability candidate whose proposed meaning, structure, authority, proof, and novelty remain aligned with the SideFX estate and the user's intent?”**

I would evaluate at least these dimensions:

| Alignment dimension             | Question                                                                              |
| ------------------------------- | ------------------------------------------------------------------------------------- |
| **Intent alignment**            | Did the candidate preserve what the human actually asked to become true?              |
| **Scenario alignment**          | Are the Input → Event → Outcome boundaries coherent?                                  |
| **Semantic-altitude alignment** | Did business meaning remain out of mechanics/provider detail?                         |
| **Estate alignment**            | Did the model reuse existing meaning before inventing new identity?                   |
| **Topology alignment**          | Are fan-out, convergence, dependencies, products, and transitions justified?          |
| **Authority alignment**         | Did candidate meaning stay in declared authority instead of hiding in implementation? |
| **Provider alignment**          | Did the model keep providers subordinate and replaceable?                             |
| **Proof alignment**             | Did it identify the evidence/fixtures needed to prove the proposed effect?            |
| **Novelty alignment**           | Are new contracts/scenarios/vocabulary actually necessary?                            |
| **Admission alignment**         | How far is this candidate from legitimate admission?                                  |

And that last one gives us an incredibly useful concept:

# **Convergence Distance**

Instead of only scoring the candidate “good/bad”:

```text
Candidate A
────────────────────────────
semantic repairs           0
unnecessary identities     1
missing contracts          0
topology repairs           2
proof gaps                 1
human semantic corrections 0

Convergence distance: 4
```

versus:

```text
Candidate B
────────────────────────────
semantic repairs           3
unnecessary identities     8
missing contracts          4
topology repairs           6
proof gaps                 5
human semantic corrections 3

Convergence distance: 29
```

Now we're learning **how much work the provider creates before admission**.

That is probably more valuable than generic “coding benchmark accuracy.”

---

## Here's the really important part: alignment does **not** mean matching one golden blueprint

We already established that the candidate blueprint is a **design hypothesis**, not admitted truth. The model may discover a better topology while authoring; the correct architecture is to observe that divergence, review it, and potentially revise the candidate blueprint rather than force the candidate back into the original hypothesis. 

So:

```text
ALIGNMENT ≠
candidate exactly equals expected answer
```

Instead:

```text
ALIGNMENT =
candidate preserves governing invariants
+
candidate explains legitimate divergence
+
candidate closes the intended effect
+
candidate makes novelty inspectable
```

That's a much better model eval.

Otherwise we accidentally train the models to **imitate the estate** rather than improve it.

---

# Now the model disposition becomes specific to authoring

This is where our earlier “model disposition” idea gets real.

After 100 capability-authoring trials, we might know:

```text
MODEL A — AUTHORING DISPOSITION

Reuse seeking                 VERY HIGH
Unnecessary identity creation LOW
Scenario-boundary discipline  HIGH
Semantic altitude discipline  HIGH
Proof awareness               HIGH
Provider neutrality           HIGH
Topology complexity tendency  LOW
Novelty usefulness            MEDIUM
Human correction burden       LOW
Admission convergence         HIGH
```

Model B:

```text
Reuse seeking                 LOW
Unnecessary identity creation HIGH
Scenario-boundary discipline  MEDIUM
Semantic altitude discipline  LOW
Proof awareness               MEDIUM
Provider neutrality           HIGH
Topology complexity tendency  HIGH
Novelty usefulness            VERY HIGH
Human correction burden       HIGH
Admission convergence         MEDIUM
```

That's fascinating because **B may actually be the model I want in exploratory candidate authoring**, even though A may be the one I trust for routine production authoring.

So model governance becomes role-sensitive:

```text
Model A
→ routine authoring
→ broader autonomous candidate scope

Model B
→ exploratory / adversarial authoring
→ tighter admission review
→ excellent for challenging existing blueprints
```

That's much richer than “Model A scores 92 and Model B scores 87.”

---

# And now governance requirements can come directly from authoring evidence

This finally gives us an empirical way to decide how much authority a model should have inside SideFX.

For example:

```text
AUTHORING GOVERNANCE PROFILE

G0 — Suggestion only
     model proposes language / ideas

G1 — Feature candidate
     model may propose Gherkin
     no authority expansion

G2 — Complete candidate circuit
     model may propose scenarios,
     contracts, topology, fixtures,
     providers, evidence

G3 — Estate-aware author
     may reuse / compose / profile
     across admitted capability estate

G4 — Novel-mechanic candidate author
     may propose missing platform mechanics
     but cannot admit them

G5 — Admission participant
     extremely restricted;
     deterministic gates remain authoritative
```

And **the evaluation evidence determines which profiles a provider is eligible for**.

Not vibes.

Not model branding.

Not “this one feels smart.”

Evidence.

---

# The multi-model evaluation becomes spectacular with the concurrent dispatch work

Take one actual intent:

> “Author a capability that evaluates the financial position of a public company.”

Pin:

```text
Intent
Corpus snapshot
Authoring context
Existing capability precedents
Mechanic catalog
Proof obligations
Token budget
Time budget
```

Then:

```text
                         SAME AUTHORING REQUEST
                                  │
                     concurrent evaluation broadcast
                                  │
             ┌────────────────────┼────────────────────┐
             ▼                    ▼                    ▼
        OPENAI MODEL          GEMINI MODEL         CLAUDE MODEL
             │                    │                    │
             ▼                    ▼                    ▼
        candidate A          candidate B          candidate C
             │                    │                    │
             └────────────────────┼────────────────────┘
                                  ▼
                        SIDEFX ALIGNMENT EVAL
```

And your live UI can show:

```text
OpenAI
  ✓ precedents resolved
  ✓ reused quote capability
  ✓ composed financial statements
  ● authoring DCF scenario
  + proposed 1 new contract

Gemini
  ✓ precedents resolved
  + proposed 3 new scenarios
  ! existing company-profile capability not reused
  ● generating proof fixtures

Claude
  ✓ precedents resolved
  ✓ reused quote capability
  ✓ reused financial statements
  + proposed risk-analysis profile
  ● closing blueprint
```

Now we're simultaneously demonstrating:

**concurrency + observation + model evaluation + capability authoring + governance.**

That's a hell of a SideFX demo.

---

# And then the flywheel closes

The correction data is the gold.

Suppose across 200 runs:

```text
37 candidates incorrectly
invent a new financial quote capability
despite an admitted existing one.
```

Don't keep telling every future model:

> “Remember to reuse the quote capability.”

We learn:

```text
recurring correction
      ↓
why?
      ↓
retrieval/context deficiency identified
      ↓
authoring context improved
      ↓
precedent retrieval strengthened
      ↓
next evaluation batch
```

Or maybe:

```text
29 candidates make the same
new semantic construct
      ↓
review finds the construct legitimate
      ↓
pattern admitted
      ↓
new reusable authority/profile/mechanic
      ↓
future candidates stop inventing it
```

That's your **eventual determinism** loop. The existing convergence work already defines the goal as shrinking the surface where nondeterministic reasoning is necessary and measuring things like deterministic coverage and recurring correction debt. 

So the real flywheel is:

```text
AUTHOR
  ↓
EVALUATE ALIGNMENT
  ↓
CORRECT
  ↓
ADMIT
  ↓
CAPTURE CORRECTION
  ↓
CLASSIFY LEARNING
  ↓
PROMOTE RECURRING KNOWLEDGE
  ↓
IMPROVE AUTHORING CONTEXT /
AUTHORITY / MECHANICS / EVALUATORS
  ↓
AUTHOR AGAIN
```

And that means the two outputs of every model eval are:

```text
1. Did this model author a good capability?

2. What did SideFX learn that should make
   every future model author better capabilities?
```

**That's the compounding mechanism.**

The Semantic Brain was already designed to hand model-authored candidates into existing inspection, admission, projection, conformance, and promotion authority instead of letting the model bypass those gates. 

Now we add the missing thing in the middle:

> **Evaluate the authoring itself as an alignment event.**

That turns capability candidate authoring into both **production** and **training data for the architecture**.
