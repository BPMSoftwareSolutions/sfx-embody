# Narration and diagram projection: disposition

Unit 10 of [implementation-strategy.md](implementation-strategy.md) (Lane E) asks for
a decision, not a mechanism: declare `narrate-*`/`diagram-*` as
templates/transformations, or request a presentation mechanic. This document fixes
the disposition against [target-architecture.md](target-architecture.md) (the rule
and the decision order), [target-experience.md](target-experience.md) (items 2-4 and
principle vs realization), and
[execution-story-projection.md](execution-story-projection.md) (the story contract).
No migration is required.

## Verdict

`narrate-*` and `diagram-*` are **not estate capabilities**. Narration is a reading,
a selection over declared authority, and a rendering. The reading and the selection
are already declared rows; the rendering is presentation — terminal code for the
CLI, the SDA presentation seam for UI targets. No estate module is restored and no
kernel presentation mechanic is requested today.

Decision rule (`target-architecture.md:73-84`): it is not the boot, and nothing is
emitted, loaded, written or verified. Its semantic content is meaning and is
declared; the layout is not meaning — it is the surface's presentation of the read,
which the estate does not own. The five retired modules were exactly that:
headings, tables and diagram layout over values read from the estate
(`docs/strategy/src-mechanics-to-database-capabilities.md:46`).

### Disposition per concern

| Concern | Disposition | Where it lives |
|---|---|---|
| The reading | **declared capability** — already done | `read-capability-meaning`, `list-capabilities`, `read-retained-publication`; `src/invoke-database-capability.mjs:156-170` routes an operation to its reader, `:262-307` executes that reader through the frontdoor |
| The selection of what to show | **declared data** — the fields the read returns | meaning documents/feature/`userStory`/`experience`/`graphSource`, the observe `story`, the retained publication; the request's `view`/`format`/`scenario` select among them |
| The rendering (CLI) | **terminal presentation**, not estate code | `C:\lab\repos\sidefx-cli\src\render.mjs` — labels, ordering, heading shape, diagram layout; it reshapes nothing (`render.mjs:8-9`) |
| The rendering (UI targets) | **SDA presentation seam** | `resolve-declared-ui-presentation` → `compile-semantic-presentation` → `plan-ui-embodiment` → `materialize-ui-embodiment` (`target-experience.md:57-73`); the estate itself has no UI-authority store |
| Server-side rendering for a non-terminal target | a **declared projection capability** (read + transformation) if expressible; a **kernel presentation mechanic** if it must be interpreted in every language | see triggers |

The presentation row of the target-architecture disposition table (`:67`) is
satisfied by this decomposition: reading and selection are declared, and rendering
is never estate code. A template is a declared transformation when a consumer
requires it, not something declared speculatively.

## The honest invariant

No prose enters the runtime. Every value printed for a field traces to a declared
read or to kernel testimony, and where authority declares nothing the output says
so (`render.mjs:94-96`; `capability-command-surface.md:30-49,51-62`). The terminal
contributes labels, ordering and layout only (`render.mjs:8-9,36-37`); a value it
cannot derive is not inferred, renamed or defaulted.

A new audience — security, executive, demo — is a **declared data change**: the
`story.label` / `story.projections` rows on execution operations
(`execution-story-projection.md:169-199`). The runtime never composes language and
no renderer is forked per audience; the current observe story renders declared ids,
and declared projections are a named unit, not an improvisation.

## What is installed today

| Invocation | Declared read | Terminal rendering |
|---|---|---|
| `reveal <id> --as meaning` | `read-capability-meaning` (`sql/migrations/declare-read-capability-meaning.sql`; scenario selection `select-scenario-in-declared-meaning.sql`) | `meaningLines` `render.mjs:102-170` |
| `reveal <id> --as meaning --format markdown` | the same read; the estate only admits the format (`src/invoke-database-capability.mjs:196-199`) | the same function; heading style only (`render.mjs:108-110`). The review-document/Mermaid shape in `capability-command-surface.md:199-260` was the retired estate narrator (`narrate-capability-markdown.mjs`, deleted `cfcaa44`); it is layout over the same read and is not installed in the terminal |
| `list` / `find` / `catalogue` | `list-capabilities` (`sql/migrations/declare-list-capabilities.sql`) | `capabilityLine` `render.mjs:48-59` |
| `circuit` / `artifact` / `reveal --as circuit` | `read-retained-publication` (`sql/migrations/declare-read-retained-publication.sql`) | delivered as the publication retains it; `pretty(payload)` `render.mjs:223` |
| `observe` story | the same invocation read plus testimony; `src/execution-drilldown.mjs` builds `story`/overlay | `storyLines` `render.mjs:74-92` |
| `observe` live testimony / `--trace` | testimony plus declared `semanticAddress` | `semanticLine`/`renderObservation` `render.mjs:23-46`; `traceLines` `render.mjs:175-202` |

All of it is a projection: `observedPathDigest` and the outcome are identical to
`invoke` (`execution-story-projection.md:107-108`).

## What would trigger revisiting

1. **A non-CLI consumer needs the same story or diagram** (API, UI, another
   language host). If the rendering is selection over declared data, declare a
   projection capability — a declared read plus a transformation, formats as
   declared selection — and no kernel change follows. If it must be interpreted in
   every language rather than selected as data, it is a kernel change request.
2. **A template requirement not expressible as declared selection** — layout or
   iteration the pure mechanic set cannot evaluate. Then the request, per
   `target-architecture.md:128-133` and `embodiment-completeness.md:24-37`, is:
   primitive = the presentation/rendering step (an operation kind or platform
   mechanic composing declared selection into a declared format); why kernel =
   cross-language interpretation, not data selection; languages =
   node/python/csharp, java/go where applicable; data that binds it = the declared
   view/format and the read fields; evidence = the consumer's required output.
3. **A UI target arrives** (the login flow). The target is SDA's presentation seam,
   not estate renderers; the estate's part is declared authority rows.

Until one of these holds, declaring `narrate-*`/`diagram-*` as capabilities, or
requesting a presentation mechanic, would be ceremony the smallest closed loop does
not pay for.

## Lane 10 status recommendation

**done-with-disposition.** The unit's question is closed by decomposition: the
reading and the selection are already declared rows and the rendering is
terminal/SDA presentation, so no migration follows. The change to
`docs/implementation-strategy.md` is the status cell alone:

`done-with-disposition: no estate capability — reading/selection declared rows, rendering terminal (sidefx-cli render.mjs) + SDA presentation seam; revisit on a non-CLI consumer or an inexpressible template (docs/narration-projection-disposition.md)`
