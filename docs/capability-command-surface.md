# The database capability command surface

`sfx capability invoke` is no longer alone. The database-invocation surface now
offers a complete set of operations over the same SQL authority, with no local
disk involvement and no second source of truth:

| Command | Reads | Returns |
| --- | --- | --- |
| `sfx capability list` | `model.estate_capability` and the selected `CAPABILITY` definitions | every declared capability with the user story it retains |
| `sfx capability find <query>` | the same, matched in SQL | matching capabilities, each reporting which fields matched |
| `sfx capability reveal <id> --as meaning` | the capability's declared semantic closure | its canonical story in human language |
| `sfx capability reveal <id> --as meaning --format markdown` | the same read | the same story as review-ready Markdown with declared-relationship diagrams |
| `sfx capability reveal <id> --as circuit` | the retained snapshot media publication | its retained blueprint catalogue or view |
| `sfx capability invoke <id> --input …` | authority, planned and executed in memory | the kernel result and its evidence |
| `sfx capability observe <id> --input …` | exactly what `invoke` reads | the same result, plus live execution telemetry |

`prepare`, `circuit`, `catalogue` and `media artifact` are unchanged.

Every operation is a row in [config/sfx.commands.json](../config/sfx.commands.json)
and a row in the `operations` table of
[src/invoke-database-capability.mjs](../src/invoke-database-capability.mjs).
Neither the CLI nor the delivery gained a capability-specific dispatch branch, so
the [Entity Neutrality Law](../../sidefx-cli/docs/command-model.md) still holds:
`sfx <object> <operation> [identity]`.

## Nothing is synthesized

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

The narrator in [src/narrate-capability-meaning.mjs](../src/narrate-capability-meaning.mjs)
contributes section labels and ordering only. The prose itself is authority: the
Given/When/Then steps are the retained scenario steps, and the intent, outcome
and promise are the retained `userStory` and `experience` values.

## The declared chain `reveal --as meaning` walks

Each hop is an explicit relationship in the model, not a naming convention:

```
capability -> root scenario -> declared closure -> execution authority
  -> port -> platform capability -> provider -> mechanic
```

Observable conditions attach to the capability by `owner_definition_digest`.
Ports resolve to mechanics through `provider_capability_implementation` and
`provider_mechanic_implementation`; a port's `platformCapabilityId` is *not* a
mechanic id, and no such equivalence is assumed. The whole read is one query, so
every recordset shares one snapshot and projection identity.

The declared root scenario and the scenario actually read are reported as
distinct facts. `reveal <id> --scenario <other>` prints both `Root` and
`Selected` rather than relabelling the selection as the root.

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

## Markdown documentation

`--format markdown` presents the same single read as a document a team can
review: heading structure, tables, Gherkin in fenced blocks, and ASCII sketches
of declared relationships. `--format` is declared by the mapping (`"format": true`)
and offered by the delivery (`text`, `markdown`), so it is refused where it does
not apply rather than accepted and ignored — including on `--as circuit`, which
is delivered exactly as the publication retains it.

The diagrams draw only declared relationships. The scenario closure tree is built
from the scenario invocations the model declares as relationships
(`model.operation_scenario_invocation`), never from an ordering guessed out of
closure depth, and any closure scenario no declared edge reaches is listed
separately instead of being attached to the root.

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
| `sfx capability reveal resolve-equity-market-price-evidence --as meaning --format markdown` | exit 0; 173-line document |
| `sfx capability reveal generate-executable-capability-scaffold --format markdown` | exit 0; 633 lines, 16-scenario tree from 15 declared invocations |
| `sfx capability reveal … --format markdown --as circuit` | exit 4; `CAPABILITY_FORMAT_NOT_OFFERED` |
| `sfx capability reveal … --format pdf` | exit 4; `CAPABILITY_FORMAT_NOT_OFFERED` |
| `sfx capability list --format markdown` | exit 2; `OPTION_NOT_APPLICABLE` |
| `sfx capability invoke … --format markdown` | exit 2; `OPTION_NOT_APPLICABLE` |

Telemetry was confirmed to stream rather than buffer: `readAuthority started`
arrived 3.2 seconds before `readAuthority completed` in wall-clock terms.

`npm test` passes 12/12 here and 17/17 in `sidefx-cli`, including that
repository's entity-neutrality suite.
