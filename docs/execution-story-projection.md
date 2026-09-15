# Execution story: story on top, proof underneath

This document fixes the observation presentation for the demo and for durable
architecture: how execution testimony becomes a scenario story without inventing
meaning, and how the mechanical record stays available underneath.

Authority: [target-experience.md](target-experience.md) (primary experience 4),
[capability-command-surface.md](capability-command-surface.md) (the observe
surface), [target-architecture.md](target-architecture.md) (the kernel does not
hold domain meaning), [embodiment-completeness.md](embodiment-completeness.md)
(mechanics are code, per language).

## The rule

> **Execution is recorded at mechanical resolution but narrated at scenario
> resolution.** Keep raw testimony exactly as rich as it is; make the
> presentation a semantic narrator over that testimony.

Two simultaneous truths, neither replacing the other:

```text
HUMAN OBSERVATION (scenario resolution)      EXECUTION TESTIMONY (mechanical resolution)
──────────────────────────────────────       ──────────────────────────────────────────

GIVEN   a canonical request admitted         cell  cell:mechanic:...operation.1
WHEN    provider authorized                  cell  cell:mechanic:...operation.1:expression
        request prepared                     edge  edge:return:...
        market observed                      cell  mechanic:literal.v1
        evidence normalized                  ...
THEN    canonical evidence exists            digest sha256:...
```

The mechanical record is **forensic evidence**. It is never discarded, never
rewritten, and never the default reading.

## The projection chain

```text
canonical authority
        ↓
semantic identity
        ↓
execution testimony
        ↓
story projection
```

- **canonical authority** — declared rows: scenario faces (`inputId`, `eventId`,
  `outcomeId`), execution authorities and their ordered operations, the declared
  feature prose, and (next) per-responsibility story projections. This is the
  only place meaning is authored.
- **semantic identity** — the declared address of an executed cell. The estate
  joins testimony to authority in `src/semantic-address.mjs`:
  `SCENARIO_OUTCOME` with the declared faces, `EXECUTION_RESPONSIBILITY` with the
  declared operation id and ordinal, `MECHANIC` with the declared mechanic id.
- **execution testimony** — what the kernel actually did: one testimony per cell
  and edge with timing, disposition, variant and digests. Kernel authority; the
  estate does not alter it.
- **story projection** — the observer join: the observe result carries `story`
  (declared faces, responsibilities in declared order with testimony timing,
  composed child scenarios) and `overlay` (planned versus observed path), while
  the terminal renders them. `observedPathDigest` remains the path proof.

No prose enters the runtime. Every story statement must trace to a declared
identity or an observed testimony value.

## What is installed

Estate (`sfx-embody`):

- `src/semantic-address.mjs` builds the declared index and addresses each cell.
- `src/execution-drilldown.mjs` streams the address on every observation, places
  `semanticAddress` on every overlay row, and builds `story`.
- `src/observation-filter.mjs` allowlists only telemetry and declared identity;
  no input, provider body or secret leaves the channel.
- `invoke` carries none of it: no `story`, no `overlay`, no testimony stream.

Terminal (`sidefx-cli`):

- observe is story-first: the default stream is the scenario altitude, and
  `--trace` opens the complete mechanical testimony; `--observation-altitude`
  scopes either;
- live lines render semantically — `✓` responsibility, `↳` the admission edge
  into a cell, `·` a mechanic;
- the non-JSON observe result renders the story: declared faces as
  GIVEN / WHEN / THEN, responsibilities in declared order, composed child
  scenarios under the parent, and the declared `--display` projection appended
  when asked for;
- `--json` is canonical and unchanged in shape apart from `story` and
  `semanticAddress`.

Live transcript (installed, `resolve-equity-market-price-evidence`, QQQ):

```text
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

`observedPathDigest` and the kernel outcome are identical to a plain `invoke`;
the story is a projection, not a second execution.

### The trace reading

Testimony at full resolution must still make sense. A mechanic cell prints the
mechanic and the declared expression path it computed; an edge prints the
admission into its destination; a responsibility and a scenario print their
declared identity. Nothing repeats without a declared position.

```text
  · 02:19:07.180 literal credentialReference 0.683 ms
  ↳ 02:19:07.180 array effectLineage admitted 0.031 ms
  ✓ 02:19:07.182 build-equity-price-binding-request 0.173 ms
  ✓ 02:19:07.182 bind-equity-price-provider-credential 0.547 ms
  ✓ 02:19:07.486 observe-equity-price-exchange 300.066 ms
  ✓ 02:19:07.494 normalize-equity-price-evidence 0.133 ms
```

With `--trace`, the result also renders the observed tree: the same overlay the
story joins, nested by planned parent and ordered by testimony time. This is the
mechanical depth the story collapses.

```text
TRACE
✓ scenario resolve-equity-market-price-evidence  0.038 ms
  ✓ build-equity-price-binding-request  0.173 ms
    ✓ literal credentialReference  0.683 ms
    ✓ array effectLineage  0.08 ms
    ✓ object  0.12 ms
  ✓ bind-equity-price-provider-credential  0.547 ms
  ✓ build-equity-price-exchange-request  0.086 ms
    ✓ path requestUrl.symbol  0.022 ms
    ✓ format requestUrl  0.232 ms
    ✓ object  0.114 ms
  ✓ observe-equity-price-exchange  300.066 ms
  ✓ normalize-equity-price-evidence  0.133 ms
    ✓ try-parse-json parsed  0.053 ms
    ✓ boolean-selection bodyText:selection  0.097 ms
    …
```

`observedPathDigest` is identical for invoke and observe in the same generation
(verified live: `sha256:365445c7f45acc507d5b3b7f634f60156f19dd19d11e96a0d1db27176785d012`
for both), so the trace is a reading, not a second execution.

## The presentation contract (installed)

| invocation | reading |
|---|---|
| `sfx capability observe <id> [--input …]` | the semantic story: declared faces, responsibilities in declared order, the terminal `THEN`. Mechanical testimony is **not** streamed by default; only the scenario altitude and the edges entering it stream live. |
| `… --display` | the story plus the capability's declared display projection (products) under THEN. |
| `… --trace` | additionally streams the complete testimony live (`scenario`, `mechanic`, `provider`, `physical`). Every mechanic line carries the declared expression path it computed, every edge its admission disposition; after the story the terminal renders the hierarchical `TRACE` tree. `--observation-altitude NAME` scopes which cell altitudes stream and takes precedence. |
| `… --json` | canonical result: `story`, `overlay`, `semanticAddress` per row, `observedPathDigest`; observation lines are JSON on stderr. |
| `sfx capability invoke <id>` | unchanged, and carries none of the above. |

The inversion is installed in the terminal: the request still carries the
declared `observationAltitudes` field, and the terminal maps its default reading
to the scenario altitude and `--trace` to the full range. The estate's own
default (no selection) is unchanged, so API/UI consumers keep the complete
stream when they ask for one.

## Story projections belong to authority (next declared extension)

The terminal currently renders declared **ids**. The target renders declared
**statements**: the same semantic event at several audiences, authored as rows,
never invented in the runtime.

```text
execution id        bind-equity-price-provider-credential

MACHINE             bind-equity-price-provider-credential
ENGINEER            Bind equity-price provider credential
SECURITY            Provider credential authority established;
                    the secret remained inside the provider boundary.
EXECUTIVE / DEMO    Authorized market-data access established.
```

Proposed declared shape, to be authored through migrations like every other
semantic fact:

```text
execution operation
  operationId        bind-equity-price-provider-credential
  story.label        Bind equity-price provider credential
  story.projections  { security: …, executive: …, … }
```

The scenario's GIVEN / WHEN / THEN prose already exists in the capability's
declared feature (`capability.feature`, the Gherkin the estate retains). The
story projection should read that declared prose rather than paraphrase it; the
current observe read skips unneeded documents for speed, so carrying the declared
feature into the observe story is a named unit, not an improvisation.

## Preserve the nesting

The story is a tree, not a flat list. A composed Scenario appears under the
responsibility that invoked it; a mechanic appears under the responsibility that
executed it. The estate already carries `responsibilityOrdinal` and
`composedScenarios`; the terminal renders depth at the selected reading.

```text
Scenario
Resolve Equity Market Price Evidence

├── GIVEN
│   └── Live equity price request
│
├── WHEN
│   ├── Resolve provider authorization
│   │   ├── build binding request
│   │   └── bind credential
│   │
│   ├── Prepare market observation
│   │   └── build exchange request
│   │
│   ├── Observe market
│   │   └── provider effect
│   │
│   └── Establish canonical evidence
│       └── normalize response
│
└── THEN
    └── Equity market price evidence
```

This is the property that makes later concerns land in the right place: identity,
credential authority, provider authorization and agent authority appear **inside
the scenario that required them**, not as unrelated security logs.

## The demo

### Demo A — evidence story (live today)

```text
sfx capability observe resolve-equity-market-price-evidence --display --input AVGO
```

Shows the declared faces, the five responsibilities with real timings
(`observe-equity-price-exchange` is the isolated provider effect), and the
canonical products from the declared display projection. The full mechanical
testimony is one flag away:

```text
sfx capability observe resolve-equity-market-price-evidence --trace
```

or scoped to the provider mechanics:

```text
sfx capability observe resolve-equity-market-price-evidence --observation-altitude mechanic
```

### Demo B — the AI-governance story (target)

```text
Scenario
Resolve Equity Market Price Evidence

GIVEN
  AVGO price evidence is requested
  by agent:research-agent-17

WHEN
  market price evidence is resolved

  ✓ Principal authorized
  ✓ Capability authority admitted
  ✓ Market-data provider selected
  ✓ Credential authority resolved
    Secret exposed to agent: NO

  ✓ Provider request executed
  ✓ Response admitted
  ✓ Evidence normalized

THEN
  Current market-price evidence
  is available

EVIDENCE
  capability        resolve-equity-market-price-evidence
  principal         research-agent-17
  provider          …
  credential        concealed
  external effect   authorized
  result digest     sha256:…
```

Honesty about today: the scenario faces, the named responsibilities, the
provider effect with timing, the products and the observed path digest are live.
The principal identity, the "secret exposed: NO" statement and the EVIDENCE
block require declared responsibility projections and declared identity/evidence
context (units below). The demo animates nothing and invents no prose; it shows
what the declaration says and what the kernel did.

## Approach — units

Each unit is coordinated changes plus its proof: a live `observe` whose story
matches its declared authority, with the same outcome and `observedPathDigest`
as `invoke`.

1. **Story-first observe (presentation inversion) — installed.** The terminal
   requests the scenario altitude by default, `--trace` the full range, and
   `--observation-altitude` scopes it. The estate request field, the story and the
   `--json` result are unchanged; no kernel change.
2. **Declared responsibility projections.** Author `story.label` and
   audience-keyed `story.projections` on execution operations; the estate carries
   them on the responsibility address and the terminal renders the selected
   audience. The runtime never composes language.
3. **Declared scenario prose.** Carry the capability's retained feature text into
   the observe story so GIVEN / WHEN / THEN read the authored Gherkin.
4. **Identity and evidence context.** Declare the invoking principal and the
   evidence block (principal, provider, credential concealment, external effect
   authorization, result digest) through declared authority and observation
   bindings; the demo reads them.

Non-goals: no prose in `src/`; no demo-specific animation or fixture; no second
source of truth beside authority + testimony; raw testimony is never discarded or
rewritten; `--json` stays canonical.

## Verification

- `sfx capability invoke|observe` produce the same graph, outcome and
  `observedPathDigest` (the semantic work is presentation).
- The observation channel carries only allowlisted telemetry and declared
  identity; `invoke` writes nothing extra.
- Estate `npm test` covers the address join, story ordering, composed scenarios,
  the shared scenario/operation execution id, and observe/invoke separation.
- Terminal `npm test` covers semantic line rendering, edge rendering, the story
  layout and the display append.
- Live receipts: the greeting and equity transcripts in this document were
  produced through the installed `sfx` CLI against the current estate model.

One kernel identity note carried here as a finding: the scheduler reuses the
operation cell's `cellExecutionId` for the scenario cell it wraps. The estate
keys observed cells by declared `cellId` plus execution id so both summaries
survive; a unique scenario-cell execution id is an SDA change request, not an
estate edit.
