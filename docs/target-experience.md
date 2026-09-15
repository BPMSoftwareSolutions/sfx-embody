# Target experience and decision timing

This document states the architecture we actually want, the primary experience we
are gearing up for, and — using
[sidefx-architecture-decision-rubric.md](sidefx-architecture-decision-rubric.md) —
which past decisions were *premature* (right idea, wrong timing) rather than wrong,
so they are demoted instead of re-litigated.

Authority stack: [target-architecture.md](target-architecture.md) (what),
[embodiment-completeness.md](embodiment-completeness.md) (mechanics in code, per
target; agents must not edit SDA), [implementation-strategy.md](implementation-strategy.md)
(who/how), [performance-optimization.md](performance-optimization.md) (cost).

## The architecture we want

1. **SDA language kernel/projector**, with multi-language conformance. The kernel is
   language-neutral authority (schemas, semantic authority, contracts, a shared
   conformance corpus). The projector compiles a capability's declared facts into a
   canonical execution graph, then projects per-target bindings/plans. Conformance
   is **digest parity**: node/python/csharp share `canonicalGraphDigest` and produce
   the same outcome digest, differing only in the per-target `realizedGraphDigest`.
2. **Executable capabilities as data**, projectable to different surfaces:
   - **database** — capabilities as normalized rows, projected back into compiler
     input by `analysis.v_capability_execution_declaration` and
     `analysis.v_capability_graph_source`;
   - **code embodiments** — per-target `application-binding` + execution plan +
     generated code (`project:consumer-capability`);
   - **workspaces** — `consumer-workspace-authority.v1`;
   - **inverted projection** — DB → capability declaration JSON. **Not implemented.**
     Only bridges exist (row→compiler JSON via `v_capability_graph_source`, retained
     document re-emission via `v_capability_execution_declaration`, human rendering
     via `reveal`). This is a gap, not a mechanism.
3. **SDA consumer with bootstrap** (`sfx-embody`): the database authority (rows), the
   boot (frontdoor, loader, DB connection/query runner, bootstrap installer), and the
   CLI.

## The primary experience

1. **Author and manage deterministic capabilities (the estate) through SQL or JSON —
   complete flexibility.** Today: SQL-only; JSON is a payload inside SQL procedures
   (scenario/operations/port-bindings/semantics). No authoring command; no JSON
   document installs authority. Gap: a JSON authoring surface that emits the same
   normalized rows while preserving idempotency, content-addressed digests,
   current-definition selection, and the rollback preflight.
2. **One single deterministic invocation path for all capabilities (CLI, API, UI).**
   Today: the CLI path is genuinely single — `invoke` and `observe` run the *same*
   code (`observe` only sets `SIDEFX_OBSERVE=1`), through bounded capability reads
   on one pinned reader session, into the declared `run-declared-graph`
   (compile → execute). No per-capability dispatch; resolution is data. The first
   [invocation optimization](performance-optimization.md) is installed: greeting
   delivery is about 2 seconds rather than 57 seconds, without changing its graph
   or outcome digest. Remaining: API/UI do not share the loader; residual
   `estateProvider`/`src/resolvers/*` bindings and missing overlay entries are data
   defects. Stale delivery removal is separate subtraction work.
3. **Presentation-layer capabilities (WPF, JavaFX, vanilla HTML, React) that project
   to multiple presentations.** SDA owns the presentation seam: a versioned
   `sda-ui-presentation-ir` protocol, `resolve-declared-ui-presentation` →
   `compile-semantic-presentation` → `plan-ui-embodiment` → `materialize-ui-embodiment`,
   a `sda-ui-embodiment-capabilities` catalog (WPF/React/HTML/JavaFX/C++ AppKit
   ADMITTED; SwiftUI/Compose/Avalonia DECLARED), and reference projections
   (`examples/generic-capability/ui.authority.json` → react/html/csharp/javafx/…).
   The presentation authorities are **semantic** (element kind/role/content/state/
   event/mechanic/lineage) — no control/framework/layout decision in authority; the
   framework rendering is an output projection. The *dishonest* form
   (`project-presentation-capabilities` frozen hand-authored oracles:
   `V3PlanEmbodiment.cs`, `v3-plan-embodiment.mjs`) is the migration oracle. The
   estate has **no UI-authority store or presentation pipeline** today. The **first
   login-flow capability** is: a login **capability** row-set (contracts, scenario,
   execution authority) plus its declared **UI authority** rows (experience /
   interaction / presentation profile), projected per target — no framework decision
   in the rows.
4. **Invoke live and see execution telemetry, choosing semantic altitudes to observe
   — "execution performance drilldown" (EPD).** Today: `observe` streams only
   `delivery-phase` timings (readExecutionDelivery, readAuthority,
   executeDeclaredGraph) plus process and read-session timings in evidence. The
   graph read is now part of readAuthority, not a second query. The kernel returns *testimony*,
   not a stream: `cellTestimony` / `edgeTestimony` / `observedPathDigest`, not passed
   to an observer. Semantic **cell altitudes** are `scenario`, `mechanic`, `provider`,
   `physical` (operations are the estate's execution-authority operation list, not an
   altitude). Telemetry authority and observation bindings exist. Gap: per-cell
   timing requires the kernel to put timing in testimony (**SDA change request**);
   altitude-selectable streaming, planned-vs-observed overlay, and surfacing
   `observedPathDigest` are the EPD work.

## Decision timing — what was premature (rubric §9)

The rubric's operational test: *"If this decision is omitted from this slice, which
intended behavior or applicable requirement fails, and why?"* — and "future
extensibility", "consistency" and "best practice" do **not** demonstrate a current
dependency. Its dispositions are Needed now / Useful now / Defer / Outside / Builder
decision; the six-event SQL→CLI loop is the measure (`:240-266`). Applied:

| decision | rubric verdict | timing |
|---|---|---|
| Filtered declaration read (`v_capability_graph_source`, the declaration view) | omission fails the invocation → **needed now** | keep; fix the unfiltered assembly (filter before aggregation) |
| One coherence pin per invocation (`snapshotId`/`projectionDigest`/`viewDefinitionDigest`, `EXECUTE AS`, `DATABASE_AUTHORITY_NOT_COHERENT`) | source-of-truth property → **needed now** | keep; collapse the *per-query* re-pin into one session |
| Isolation boundary (`restrictMemoryProcess`, permission model) | required storage-proof control → **needed now** | keep |
| Kernel interpretation of the declared graph | the target rule → **needed now** | keep |
| Native-body materialization as the invocation mechanism | omission fails nothing once the kernel interprets → **not needed on this loop** | remove; keep only the evidence the first demonstration produced |
| Platform-commit pinning + native-body verification/parity | contribution 1 (future cross-apply), not the loop → **defer / too early** | revisit at the second target |
| Estate-wide JSON assembly before the capability filter | changes only time, not any event → **not needed** | fix now (performance plan #1/#2) |
| Per-`query()` pool + pin + `EXECUTE AS` (8×) | reuse not made → **not needed** | one read session |
| Transportable/inherited document bundle read every invoke | inherited shape has no authority by presence → **defer / too early** | invocation reads only what it consumes; keep the bundle for preflight |
| Per-invoke process spawn/re-import | defer once the loop is green → **too early** | long-lived delivery (**SDA/CLI change request**) |
| Outward projection + inverse native-AST reader | consumer choice, not an invocation prerequisite → **defer / not needed** | revisit only on a measured recurring need |

**The timing principle.** None of these was wrong as a *demonstration*; several were
wrong as a *durable commitment*. The first DB→memory execution was exactly the
rubric's first executable demonstration at an unresolved boundary — correct to
build, and it produced real evidence. The error was promoting the demonstration's
machinery to the standing invocation shape before the SQL→CLI loop had closed. The
rubric anticipated the pattern: *"the initial decision does not require designing
the eventual full architecture"* (`:23`), and publication *"was never intrinsically
necessary to the flywheel; it was the cost of the guards"* (`:288`). The disposition
is **demotion, not refutation** — keep the evidence, let the smallest path that
closes the six events govern.

## The architecture principle vs its realization

The durable law is **authority-as-data**: everything above the boot is *declared
capability authority/data, not handwritten application behavior*. 

The relational model is the strongest realization of that authority today and should
be preserved aggressively — but **authority-as-SQL-rows is a realization decision**,
not the principle itself. (The target requires SQL *or* JSON authoring, which is
itself evidence of the distinction.) This protects against repeating the mistake this
research just exposed: taking today's effective mechanism and silently promoting it
into tomorrow's architectural necessity. SQL Server is a store; it is not SideFX's
ontology.

## The subtraction phase

The next architecture phase is **subtraction**, not another subsystem:

The diagram records the research baseline. Its invocation-read subtraction is now
installed; measured results and remaining costs are in
[performance-optimization.md](performance-optimization.md).

```
        RESEARCH BASELINE                    TARGET
SQL authority                       SQL / JSON authority
  → views                             → bounded capability read
  → bundles                           → one coherence session
  → pins                              → canonical graph
  → materialization                   → kernel
  → resolver seams                    → outcome
  → native bodies
  → verification
  → kernel
  → outcome
```

Geometry to restore: `capability identity → resolve bounded closure → read only
required authority → compile graph → execute`. The violation to avoid is
`database → reconstitute universe → find capability → execute` — the capability
boundary is violated at the persistence layer when the estate is assembled before
the capability filter is applied.

The governing constraint (rubric): *start with the least functionality necessary to
carry Input → Event → Outcome to a credible observable result; consequential
additions must justify themselves against a present dependency, requirement, or
demonstrated benefit.* Not "how completely can we solve the eventual platform?" but
**"what is the smallest complete capability-delivery circuit that creates another
useful cycle?"**

## Three buckets

| Keep hard | Strip from the hot path | Revisit when pressure appears |
|---|---|---|
| canonical capability facts | estate-wide assembly | native projection |
| kernel graph interpretation | native-body materialization | cross-target parity machinery |
| one invocation coherence pin | per-query coherence pin | long-lived delivery host |
| isolation boundary | retained bundle on every invoke | full JSON workspace reconstruction |
| capability-scoped read | duplicate graph/declaration reads | additional UI targets |
| generic invocation | stale `materialize` delivery | sophisticated offline bundles |
| actual outcome/failure | residual resolver seams | generalized authoring frameworks |

This is **demotion, not refutation**: keep the evidence those mechanisms produced;
stop forcing the live system to pay for the experiments.

**Proof debt** is the category to remember — machinery built to answer an
architectural uncertainty remains after the uncertainty is resolved. Materialization
was right for the first demonstration; retaining it on the invocation path was proof
debt. Preserve the law; delete the ceremony that accumulated around proving it.

## Where database pressure is actually valuable: the authoring flywheel

The database's value is making the common semantic mutations stupidly easy and
deterministic — the authoring procedures (`scaffold_capability`, `add_scenario`,
`add_mechanic`, `add_provider`, `configure_contract`, `bind_provider`,
`configure_provider`, `author_capability_meaning`, `inspect_capability`, …):

```
scaffold capability → add scenario → add mechanic → add provider if required
  → configure contract → bind → invoke
change one fact → invoke again → see changed outcome
```

Every new stored procedure must answer: **which recurring authoring action does this
remove friction from?** If it can't, don't build it yet. The database provides
*facts*; the kernel/projector provides *interpretation*; providers provide
*mechanics*.

## The flywheel proof

One working demonstration proves the interaction works — **not** the flywheel. The
flywheel is established only when learning/reuse from one useful example reduces the
effort of the next:

```
author A → invoke A → observe A
author B → invoke B → observe B
```

   **Was B materially easier because we built A?**

If not, the loop is not yet a flywheel. The next pressure is not "can this
architecture exist?" (proven) but **"can it make the next capability cheaper,
faster, clearer, and less architecturally expensive than the previous one?"**

## Next-iteration flywheel

The loop we are gearing up for: the product developer authors deterministic
capabilities (rows, via SQL today / JSON next), invokes any of them through one
deterministic path (CLI, then API/UI), watches execution telemetry at chosen semantic
altitudes (EPD), and authors presentation-layer capabilities that project to WPF,
JavaFX, HTML, and React — where the framework is never in the authority and the
login flow is the first such capability. Every executable mechanic is embodied in
code per language; the law above the boot is declared authority-as-data, not
handwritten application behavior; no agent edits the SDA repo — cross-language
changes are SDA change requests.
