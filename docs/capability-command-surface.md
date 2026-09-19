# The database capability command surface

`sfx capability invoke` is no longer alone. The database-invocation surface now
offers a complete set of operations over the same SQL authority, with no local
disk involvement and no second source of truth:

| Command | Reads | Returns |
| --- | --- | --- |
| `sfx capability list` | `model.estate_capability` and the selected `CAPABILITY` definitions | every declared capability with the user story it retains |
| `sfx capability find <query>` | the same, matched in SQL | matching capabilities, each reporting which fields matched |
| `sfx capability reveal <id> --as meaning` | the capability's declared semantic closure | its canonical story in human language |
| `sfx capability reveal <id> --as meaning --scenario <scenario>` | the same read, with the selected scenario validated against the capability's members and invocation closure | the same story, reporting Root and Selected distinctly, with the selected scenario's declared faces |
| `sfx capability reveal <id> --as meaning --format markdown` | the same read | the same story as review-ready Markdown with declared-relationship diagrams |
| `sfx capability reveal <id> --as circuit` | the retained snapshot media publication | its retained blueprint catalogue or view |
| `sfx capability invoke <id> --input …` | authority, planned and executed in memory | the kernel result and its evidence |
| `sfx capability observe <id> --input …` | exactly what `invoke` reads | the same result, plus live execution telemetry |
| `sfx capability project <id> --workspace <dir>` | the capability's declared documents, assembled in one pinned read | the per-target mechanical bodies, execution plans and conformance evidence under `<dir>/projected` |

`prepare` was subtracted with its materialization mechanism: it is not offered,
so `sfx capability prepare` is refused as an unknown operation rather than
reaching a path nothing declares. The reader operations above are declared reads
and are verified live.

Every operation is a row in [config/sfx.commands.json](../config/sfx.commands.json).
The database-invocation operations are rows in the `operations` table of
[src/invoke-database-capability.mjs](../src/invoke-database-capability.mjs);
`project` is the separate `database-projection` surface served by
[src/projection-delivery.mjs](../src/projection-delivery.mjs), a
publication/harness boundary that no invocation, reader or graph source consults.
Neither the CLI nor the delivery gained a capability-specific dispatch branch, so
the Entity Neutrality Law still holds: `sfx <object> <operation> [identity]` —
entity identities and vendors belong in canonical data, never in new commands or
dispatch branches. The rule is restated here because its former home
(`sidefx-cli`) is retired and no link may resolve outside this repository.

## Nothing is synthesized

`list`, `find` and `catalogue` are served by the declared `list-capabilities`
read ([sql/migrations/declare-list-capabilities.sql](../sql/migrations/declare-list-capabilities.sql)):
one port whose declared read returns the selected estate's capabilities as JSON
rows under the reader boundary. The read owns the matching and the reported
`matchedFields`; the terminal renders the rows.

`circuit`, `reveal --as circuit` and `media artifact` are served by the declared
`read-retained-publication` read
([sql/migrations/declare-read-retained-publication.sql](../sql/migrations/declare-read-retained-publication.sql)):
the current model's latest explicit media publication is read under the reader
boundary and the retained catalogue, one retained view, or one retained
artifact's original bytes is returned. The read never crosses a model boundary,
and a model with no retained publication reports `CIRCUIT_PUBLICATION_UNAVAILABLE`
rather than a substitute. `catalogue` is the declared listing read and its rows
now carry `circuitAvailable`, true only when the current model's retained
publication lists the capability's catalogue (`add-catalogue-circuit-availability.sql`).
`prepare` is not re-declared and is not offered: its materialization mechanism
was eliminated, so the command is refused as an unknown operation.

Every value these commands print is read from the selected estate model. Where
the authority declares nothing, the output says so — it never substitutes a
default, an example, a paraphrase or an inferred sentence. That is visible in the
estate as it stands: of the 220 declared capabilities, 216 retain a user story
and 4 do not, and `generate-executable-capability-scaffold` retains no user story,
no experience and no observable conditions at all. It renders as:

```
User story
----------
The estate declares no user story for this capability. (not declared)
```

`reveal --as meaning` is itself a declared reader operation:
[`read-capability-meaning`](../sql/migrations/declare-read-capability-meaning.sql)
is a capability whose one port is a declared read of the subject's assembled
declaration set. The terminal contributes section labels and ordering only. The
prose itself is authority: the Given/When/Then steps are the retained feature,
and the intent, outcome and promise are the retained `userStory` and `experience`
values.

## What `reveal --as meaning` reads

Every value is a declared relationship, never a naming convention:

- the capability document carries the name, `userStory` and `experience`
  (observable conditions included);
- the feature document carries the authored Gherkin;
- the graph source carries the scenarios with their input / event / outcome
  faces, the execution authorities and their ordered operations, the port
  bindings with their platform capabilities, and the contract authorities.

The declared read returns them together under the reader boundary, so the story
and the snapshot identity travel in one read. A caller-selected scenario is
honored by the same read: `selectedScenarioId` and `selectedScenario` (the
scenario's owning capability and its declared input/event/outcome faces with
their contracts) are returned beside the declared root, and a scenario that is
neither a declared member of the capability nor in its declared invocation
closure is refused with `SCENARIO_NOT_IN_CAPABILITY` rather than silently read as
the root.

## Observation

`observe` is not a second execution path. It runs the identical code `invoke`
runs, and additionally streams the telemetry the delivery already produces.

The telemetry pipe was already built and SDK-tested end to end; the CLI simply
never turned it on. `sfx` now passes `onObservation` when the mapping marks an
operation `"observation": true`, so the delivery is started with
`SIDEFX_OBSERVE=1` and its `SFX_OBSERVATION` lines are rendered as they arrive.

Telemetry is diagnostics. It goes to stderr, never to the result on stdout, it
carries no input, provider body or secret, and it cannot change the outcome —
`invoke` still writes exactly zero bytes to stderr.

```
  . 09:26:41.571 delivery-phase readAuthority started
  . 09:26:44.914 delivery-phase readAuthority completed
  . 09:26:45.348 delivery-phase executeScenario started
  . 09:26:45.349 scenario-execution-observation.v1 resolve-sidefx-eligible-providers #0 observed
  . 09:26:45.350 delivery-phase executeScenario completed
```

With `--json`, each line is `{"observation":{…}}` on stderr while the result
stays machine-readable on stdout.

### Execution performance drilldown

`observe` also streams the kernel's execution testimony and returns the planned
topology against what executed. The kernel emits one testimony per cell and per
edge it interprets; the estate forwards its `onTestimony` sink, and each titled
`cell-execution-testimony.v1` / `edge-execution-testimony.v1` observation carries
`cellId` / `edgeId`, `cellAltitude` and the timing fields (`durationMilliseconds`,
`startedAt`, `completedAt`). Nothing about the execution changes: the same graph,
outcome and `observedPathDigest` are produced.

The selection is the declared request field `observationAltitudes`, surfaced as
the repeatable CLI option `--observation-altitude NAME` over the four semantic
cell altitudes (`scenario`, `mechanic`, `provider`, `physical`). Cells at a
selected altitude stream; every edge is streamed when all four altitudes are
selected, otherwise an edge streams when it enters a cell at a selected altitude.
Observe is story-first: when no altitude is named the terminal requests the
scenario altitude, and `--trace` requests the whole range. The operation is a row
in [config/sfx.commands.json](../config/sfx.commands.json)
(`"observationAltitudes": true`) and a row in the `operations` table, exactly
like the other options.

The observe result gains two fields that invoke never carries: `observedPathDigest`
(also in `evidence.observedPathDigest`) and `overlay`. The overlay joins each
planned `canonicalGraph` cell and edge with the observed testimony — disposition,
`outcomeVariant`, `selectedEdgeIds`, per-execution timings — and counts planned
against observed topology. `invoke` output is unchanged.

The kernel's per-cell timing and live testimony sink landed in SDA; `observe`
streams from the sink when the kernel provides it and absorbs the returned
`cellTestimony` / `edgeTestimony` when it does not, so the overlay, timing and
digest are populated either way.

### Semantic projection

Testimony is mechanical by itself; `observe` also carries the declared semantic
address of each executed cell. The estate joins testimony to the selected
capability's own declaration: the scenario cell addresses to `SCENARIO_OUTCOME`
with the declared `inputId` / `eventId` / `outcomeId`; each operation cell to its
declared responsibility (`responsibilityId` — the declared Port or child
Scenario — in `responsibilityOrdinal` order); each expression cell to its
`mechanicId`. The address is data from rows; no prose enters the runtime.

The terminal renders the address on the live stream (a responsibility as `✓`, an
edge as `↳`, a mechanic as `·`), then renders the observed story for the result:
declared faces as GIVEN / WHEN / THEN, responsibilities in declared order with
their testimony timing and disposition, composed child scenarios under the
parent, and the capability's declared `--display` projection when asked for.
`invoke` carries none of it.

```
  ↳ 01:30:51.287 scenario resolve-equity-market-price-evidence 0.012 ms
  ✓ 01:30:51.287 scenario resolve-equity-market-price-evidence 0.05 ms

Scenario resolve-equity-market-price-evidence
GIVEN live-equity-price-request  (live-equity-price-request.v1)
WHEN
  ✓ build-equity-price-binding-request  0.057 ms
  ✓ bind-equity-price-provider-credential  0.465 ms
  ✓ build-equity-price-exchange-request  0.073 ms
  ✓ observe-equity-price-exchange  321.157 ms
  ✓ normalize-equity-price-evidence  0.153 ms
THEN
  ✓ equity-market-price-evidence  (equity-market-price-evidence.v1)
```

`--trace` streams the complete testimony in those declared terms: each mechanic
line carries the declared expression path it computed (`literal requestUrl.symbol`)
and each edge its admission disposition, and the observed tree — the same overlay
nested by planned parent — renders after the story. The `--json` result carries
`story` and each overlay row carries `semanticAddress`; `observedPathDigest` is
unchanged.

One kernel identity note: the scheduler reuses the operation cell's
`cellExecutionId` for the scenario cell it wraps. The estate keys observed cells
by declared `cellId` plus execution id, so both summaries survive; a unique
scenario-cell execution id is an SDA change request.

The presentation contract, the authority-side story projections and the demo
approach are fixed in
[execution-story-projection.md](execution-story-projection.md).

## Projection

`sfx capability project` is the publication surface for the mechanical bodies.
One pinned read assembles the capability's declared documents; the delivery
stages them into `--workspace`; the admitted consumer projector runs over the
workspace and writes the generated seams, execution plans, conformance queries,
fixtures and evidence under `<workspace>/projected`. The projection targets
default to the workspace's declared targets and can be narrowed with
`--targets node,python,csharp`. `--full-mechanics` selects the per-language
capability execution emitters: each target's compiled plan is realized as
target-native code (every cell bound to a real module or compiled operation, no
compatibility provider, no runtime expression interpretation), with per-file
`digest` + `sourcePointers` in the manifest. Without the flag the projection
writes the seam bodies and plans as review output.

The report names the out-directory, each target's `canonicalGraphDigest` and
`realizedGraphDigest`, the bound/required mechanics, the file count and the
projection conformance disposition. The staged documents and the generated bodies
are ordinary workspace files: they are version-controlled for review and
comparison, and nothing in the invocation path reads them — the retained body is
an artifact, never the invocation mechanism.

```
$ sfx capability project resolve-equity-market-price-evidence \
    --workspace embodiments/resolve-equity-market-price-evidence
Projected resolve-equity-market-price-evidence -> …\embodiments\resolve-equity-market-price-evidence\projected
  csharp   canonical sha256:6d8e145c…  bindings 137/137
  node     canonical sha256:6d8e145c…  bindings 137/137
  python   canonical sha256:6d8e145c…  bindings 137/137
PURE_PROJECTION_CONFORMS; 12 declared document(s), 32 file(s)

$ sfx capability project resolve-equity-market-price-evidence \
    --workspace embodiments/resolve-equity-market-price-evidence --full-mechanics
Projected resolve-equity-market-price-evidence -> …\embodiments\resolve-equity-market-price-evidence\projected
  csharp   canonical sha256:6d8e145c…  bindings 137/137  emitted
  node     canonical sha256:6d8e145c…  bindings 137/137  emitted
  python   canonical sha256:6d8e145c…  bindings 137/137  emitted
EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED; every slot a real module or compiled operation
```

Two SDA-side watch items. The generated bodies import the SDA runtime through
paths relative to the generation workspace depth, so a body moved to another
depth resolves only from where it was generated; the manifest binds each file to
declared authority with `sourcePointers`, not to a portable specifier. And
codegen-mode patterns are rendered locally by the tools emitters (sync renderers
cannot invoke Python/C# at projection time): node output is byte-identical to the
registered resolver's `emit`, while python/C# are semantically verified, not
byte-compared. The manifest digests bind the emitted bytes as rendered, so before
any projected body becomes a digest-bound release artifact, the registered
resolver emission must be byte-compared or the renderer provenance pinned.

## Markdown documentation

`--format markdown` presents the same single read as a document a product owner
or architect can review: a review summary, Mermaid diagrams of the circuit and
its execution order, heading structure, tables, Gherkin in fenced blocks, and
ASCII sketches of declared relationships.

The document opens with what a reviewer must decide on:

1. **Review summary** — every point where the declared circuit does not join up,
   where two retained definitions disagree, and where meaning is not declared.
2. **Capability circuit** — a Mermaid flowchart of the whole circuit, with the
   declared execution order on the edges and every gap drawn in red.
3. **Execution order** — a Mermaid sequence diagram of the declared operation
   order for the scenario read.

Only then does it descend into scenarios, execution plan, transformations and
mechanics. `--format` is declared by the mapping (`"format": true`)
and offered by the delivery (`text`, `markdown`), so it is refused where it does
not apply rather than accepted and ignored — including on `--as circuit`, which
is delivered exactly as the publication retains it.

The diagrams draw only declared relationships. The scenario closure tree is built
from the scenario invocations the model declares as relationships
(`model.operation_scenario_invocation`), never from an ordering guessed out of
closure depth, and any closure scenario no declared edge reaches is listed
separately instead of being attached to the root.

## Reviewable by inspection

An architect should be able to look at the document and say "the flow is wrong"
or "the mechanics are missing meaning" without reading the whole estate. Three
things carry that:

**The review summary states declared facts, never verdicts.** Each line says what
the model declares — a count, an absence, or two declarations that disagree —
and leaves the judgement to the reviewer. Observations are grouped as *structure*
(the circuit does not join up), *divergence* (one declared id, definitions that
disagree) and *meaning* (the authority declares none here), and each carries a
stable code such as `PROVIDER_WITHOUT_MECHANIC` or `SCENARIO_INVOCATION_UNRESOLVED`.

**The diagrams draw gaps as gaps.** A scenario no execution authority owns, a
platform capability no provider implements, a provider that declares no mechanic,
a port with no definition, and an invocation the closure does not resolve are all
drawn in red or dashed, inside the circuit, where they break the eye.

**A check only fires where the estate itself disagrees.** A port carrying no
transformation is reported only when the same platform capability is configured
with one elsewhere in the estate — the document says, for example, "while 12 of
the 13 ports the estate declares on `sda-authority-transformation-port.v1` do".
A platform capability the estate never configures with a transformation (a
governed HTTP exchange, a credential binding) is not reported at all. Without
that comparison the report cried wolf on four ports of
`deliver-capability-change-api` that are configured exactly as every other port
on their platform capability is.

Across a 25-capability sample, 15 capabilities produce no observation at all and
the rest produce between 1 and 4. The summary discriminates; it does not flag
everything.

## What the documentation exposed

Rendering real authority immediately surfaced conditions worth a reviewer's
attention. None of these are rendering artifacts; all are retained estate state.

**One declared id can have several retained definitions, and they can disagree.**
The selected model retains 9,155 definitions across 8,524 distinct declared ids.
275 of those ids carry more than one definition, one of them 13. The renderer
never merges them into a union — each is shown with its digest, and where they
differ the count of distinct operation sets is stated.

`resolve-equity-market-price-evidence.v1` is the clearest case. Six retained
definitions declare three different operation sets:

| Definitions | Declared operations |
| --- | --- |
| 3 | the port, plus three `invoke-scenario` operations |
| 2 | the port alone |
| 1 | five entirely different ports |

**An execution authority can declare an invocation the model does not resolve.**
Those three `invoke-scenario` operations name scenarios that are not in the
declared closure, because the closure view admits only targets whose definitions
are in the selected estate model. Both statements are retained authority and they
disagree, so the document reports the disagreement under *Declared scenario
invocations not in the closure* rather than silently dropping either side.

**A scenario definition is not always an authored specification.**
`resolve-equity-market-price-evidence` retains a definition that declares the
scenario's face — event, input, outcome — with no Gherkin. An earlier draft of
this renderer reported that as "the estate retains no scenario definition", which
was wrong: a definition is retained, of a different declared profile. It is now
reported as what it is.

## What was exercised

Against snapshot
`sha256:1a770ac0795d10665a88166f8d8c968dc5b2d030fdfab2b837aa6071d135f9e9`,
through the installed `sfx` CLI and this project's `database-memory` process
binding:

| Command | Result |
| --- | --- |
| `sfx --help` | exit 0; all 9 operations offered, 0 missing |
| `sfx capability list` | exit 0; 220 capabilities |
| `sfx capability list --namespace sidefx:capabilities` | exit 0; 220 capabilities |
| `sfx capability list --namespace does-not-exist` | exit 0; 0 capabilities, `(none)` |
| `sfx capability find scaffold` | exit 0; 1 result, matched `capabilityId, name, scenario` |
| `sfx capability find cited evidence` | exit 0; 1 result, matched `outcome` |
| `sfx capability find` | exit 2; usage |
| `sfx capability reveal resolve-sidefx-eligible-providers` | exit 0; full canonical story |
| `sfx capability reveal … --as circuit` | exit 0; retained publication and views |
| `sfx capability reveal … --as nonsense` | exit 4; `CAPABILITY_VIEW_NOT_OFFERED` |
| `sfx capability reveal generate-executable-capability-scaffold --scenario replay-scaffold-generation` | exit 0; distinct `Root` and `Selected` |
| `sfx capability observe resolve-sidefx-eligible-providers --input '@examples/provider-resolution.request.json'` | exit 0; live telemetry on stderr, result on stdout |
| `sfx capability invoke …` (same input) | exit 0; 0 bytes on stderr |
| `sfx capability reveal resolve-equity-market-price-evidence --as meaning --format markdown` | exit 0; 378-line document, 10 observations |
| `sfx capability reveal generate-executable-capability-scaffold --format markdown` | exit 0; 881 lines, 16-scenario graph from 15 declared invocations |
| 25-capability sample, diagrams structurally validated | every node an edge names is declared, every block closes, every sequence participant is declared; 15 of 25 produce no observation |
| `sfx capability reveal … --format markdown --as circuit` | exit 4; `CAPABILITY_FORMAT_NOT_OFFERED` |
| `sfx capability reveal … --format pdf` | exit 4; `CAPABILITY_FORMAT_NOT_OFFERED` |
| `sfx capability list --format markdown` | exit 2; `OPTION_NOT_APPLICABLE` |
| `sfx capability invoke … --format markdown` | exit 2; `OPTION_NOT_APPLICABLE` |

Telemetry was confirmed to stream rather than buffer: `readAuthority started`
arrived 3.2 seconds before `readAuthority completed` in wall-clock terms.

`npm test` passes 16/16 here and 17/17 in `sidefx-cli`, including that
repository's entity-neutrality suite.
