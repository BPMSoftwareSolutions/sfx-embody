Yes — this is **very close to a durable architectural law**, but I found one contradiction that matters precisely because of the insight you just had about eliminating gray areas.

## Review disposition

**APPROVE WITH ONE REQUIRED CONCEPTUAL CORRECTION and several wording tightenings before freezing it.**

The core is strong:

> **Every behavior must ultimately be either declared authority or resolver mechanics.**

That is the real transistor.

The document captures the intended split clearly: declared meaning exists once and remains language-neutral, while native resolver mechanics are re-embodied per supported language. 

And these two corollaries are excellent:

* adding another language adds another resolver embodiment, not another interpretation of capability meaning;
* bootstrap belongs on the resolver side because something native has to read and execute the declarations. 

That is exactly the pressure you were describing.

---

# The one thing I would **not** let survive: `neutral`

This jumped straight off the page:

> `command mapping, declaration SQL, coherence checks, input mapping, result shaping, semantic address / drilldown / observation filter` → **neutral**. 

**No.**

Not if the transistor is genuinely binary.

That word recreates the escape hatch you just said you want to destroy.

If something executable is presently sitting there as “portable logic,” there are only two legitimate dispositions:

```text
Can its behavior be expressed as authority/data?
        │
      YES
        ↓
DECLARED = 1
```

or:

```text
Does its execution irreducibly require
native runtime mechanics?
        │
      YES
        ↓
RESOLVER = 0
```

There should be **no third classification**:

```text
resolver
declared
neutral  ← NO
```

because six months from now:

```text
"it's just portable logic"
        ↓
"it's only a helper"
        ↓
"it's easier in code"
        ↓
business semantics in bootstrap
```

That's exactly how the escape code comes back.

And the document already knows the correct answer: it says the source files containing language-neutral drilldown, observation filtering, and semantic addressing **belong in declared capabilities, not code.** 

So I'd change that table now.

---

# There is a second subtle issue: **projected code**

The opening sentence currently says:

> **Every executable element in the system is in exactly one of two states.** 

But later the document correctly says that executable files can also be **projected artifacts** carrying zero forbidden handwritten mechanics and projection provenance. 

At the physical-file level, that creates an apparent third thing:

```text
resolver code
declared data
projected executable
```

I would **not** solve that by creating a third transistor state.

Instead, tighten what the transistor classifies.

### The bit should classify **authority for executable behavior**, not physical artifacts.

Then:

```text
DECLARED = 1
    │
    │ projection
    ▼
generated executable
```

The generated executable is **not another source of behavior**.

It is an embodiment of `1`.

And:

```text
RESOLVER = 0
    │
    ▼
native execution mechanism
```

So the stronger law becomes:

> **Every executable behavior has exactly one origin: declared authority (1), interpreted through resolver mechanics (0). Projected executables are embodiments of declared authority and never constitute a third source of executable meaning.**

That closes a potential ambiguity beautifully.

---

# Then the transistor is genuinely clean

I would model it this way:

```text
                    EXECUTABLE BEHAVIOR

                           │
                           ▼

                ┌─────────────────────┐
                │ WHAT OWNS THE FACT? │
                └─────────┬───────────┘
                          │

             ┌────────────┴────────────┐
             │                         │
             ▼                         ▼

        DECLARED (1)              RESOLVER (0)

     what should happen          how this runtime
     which mechanic             physically performs
     configuration              the mechanic
     topology
     contracts                  branching
     bindings                   iteration
     provider requirement       serialization
     semantic meaning           mutation
     outcome                    host effects

             │                         │
             └────────────┬────────────┘
                          ▼
                     EXECUTION
```

And the rule underneath it becomes almost brutally simple:

> **If you cannot classify something as 0 or 1, you have found an architectural defect.**

That's the enforcement mindset I think you're after.

---

# I also like your mechanic rule a lot

This may be the strongest sentence in the document:

> **Which mechanic runs and with what configuration is always declared; the native implementation of the mechanic is always a resolver.** 

I would elevate that.

Possibly put it immediately below the transistor definition.

Because it answers things people will otherwise debate endlessly.

Take HTTP:

```text
1 DECLARED

mechanic:
  governed-http-exchange

method:
  GET

endpoint:
  ...

credentialReference:
  market-price-provider
```

versus:

```text
0 RESOLVER

perform HTTP exchange
attach credential internally
serialize request
execute native client
handle native error
return physical result
```

Same with SQL:

```text
1 → declared statement / read semantics
0 → DB driver / socket / protocol execution
```

Same with secrets:

```text
1 → credential reference + permitted purpose
0 → Key Vault / Vault / Secrets Manager native resolution
```

Same with filesystem:

```text
1 → declared artifact operation
0 → actual OS filesystem mechanics
```

**This is wonderfully coherent.**

---

# I would tighten “exactly one copy”

The table says declarations have **exactly one** copy. 

Semantically: yes.

Physically: probably not.

You'll eventually have:

```text
canonical database state
capsule
replica
cache
projection
backup
Git publication
```

So I'd say:

> **Exactly one canonical semantic authority identity, regardless of how many verified physical representations exist.**

Similarly, resolver:

> **One admitted resolver surface per language/runtime profile**

rather than literally one physical copy.

Otherwise deployment replication makes the wording technically false.

---

# One more important refinement to the language corollary

This sentence is directionally excellent:

> Adding a language adds resolvers; it never adds declarations. 

I'd preserve it but slightly refine the failure interpretation.

Because cross-apply may expose this:

```text
Add Rust
  ↓
Rust cannot embody Authority A cleanly
```

Sometimes that means Rust is wrong.

But sometimes Rust exposed a **missing canonical declaration** that Node had been silently assuming.

So:

> **Adding a language must never require a language-specific declaration. If a new language exposes missing meaning, the canonical declaration may be corrected once for every language.**

That's consistent with your cross-apply principle.

Otherwise somebody might read the current wording as:

> “Once declared, canonical authority can never be improved because another embodiment exposed an omission.”

That's not what you mean.

---

# Bootstrap placement looks right

I agree with the architecture in §2.

You have three irreducible bootstrap problems:

* something has to enter the process;
* something has to connect to/read authority;
* something has to establish the first executable environment. 

Those are all on the resolver side.

And your current gap analysis is unusually honest: Node has the full frontdoor/loader path today; other languages have resolver pieces but incomplete registry-loader/bootstrap closure. 

That's good architecture documentation because you're not turning the law into a claim that the estate already satisfies it.

One wording refinement:

I wouldn't define bootstrap as:

> “must have the exact same bootstrap application in every language.”

I'd define it as:

> **Every natively supported runtime must possess an admitted native path from physical entry to canonical authority to its resolver floor without delegating executable semantics to another runtime.**

That leaves implementation freedom while preserving the law.

---

# The enforcement section is exactly where this becomes real

This section is excellent:

1. declare resolver boundaries;
2. scan every executable artifact for forbidden mechanics outside those boundaries;
3. fail a language when required resolver bodies are absent. 

That's the difference between:

> architecture principle

and:

> **architecture physics**.

You don't have to tell an agent:

> “Please remember our resolver rule.”

The estate says:

```text
Executable mechanics detected
        +
outside resolver boundary
        =
REJECT
```

That's architectural pressure.

And I especially like that the review uncovered concrete defects rather than merely confirming the thesis: resolver boundaries aren't declared yet, the repo-wide sterility gate isn't wired, `.go` is missing from the evaluator, and the non-Node bootstrap/registry-loader surfaces remain incomplete. 

Those findings make the document much more credible.

---

# I would rewrite the one-paragraph law

Your current closing paragraph is already good. 

I think this version removes the remaining ambiguity:

> **Every executable behavior in SDA is governed by one binary distinction: resolver (0) or declared authority (1). Declared authority owns what executes, its semantic meaning, topology, bindings, contracts, configuration, and expected outcome; it exists once canonically and is language-neutral. Resolvers own only the irreducible native mechanics required to interpret and physically realize that authority; each supported native runtime therefore owes its own admitted resolver surface and bootstrap path. Projected executables are not a third state—they are reproducible embodiments of declared authority. If executable behavior is neither declared nor inside an admitted resolver boundary, it is an architectural violation.**

Then below that:

> **Declare it or resolve it. There is no third place for executable meaning to live.**

**That's the transistor.**

And I think that's considerably stronger than where we were yesterday, because the architecture now has a binary answer to the question that causes almost every escape hatch:

> *“Where does this code belong?”*

The answer isn't a folder anymore.

It's:

**0 or 1.**
