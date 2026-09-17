# Demo runbook: the SideFX observe/reveal experience

This runbook drives the short recording of the database capability surface through
the installed `sfx` CLI. Every value shown is read from the selected estate's rows;
nothing is synthesized, no capability is special-cased in the terminal, and no
migration runs during the recording.

Receipts for every command below are captured into
`evidence/demo-<ISO timestamp>/` (`*.stdout.txt`, `*.stderr.txt`, `report.json`).
The machine-readable acceptance over those captures is the declared read
`read-demo-acceptance` (`sql/migrations/declare-read-demo-acceptance.sql`, W1.4);
the hand-authored `scripts/verify-demo.mjs` harness is retired.

## Current state (what the recording can honestly claim)

- **Invocation is a ~2 s delivery.** `invoke` and `observe` read authority once
  inside one pinned session (1 connection, 1 pin, 1 reader switch, 6 queries, no
  child processes, no filesystem writes, no expanded-body reads, no database
  cache) and execute the declared graph in process. Observed wall time for
  `say-hello-world` is about 2.2 s including process startup.
- **Observe is story-first.** The default `observe` stream is the scenario
  altitude: declared faces as GIVEN / WHEN / THEN with responsibilities in
  declared order. `--trace` additionally streams the complete mechanical testimony
  and renders the hierarchical `TRACE` tree after the story. `invoke` is unchanged
  and writes nothing to stderr.
- **Reveal, list and find are declared readers.** `reveal --as meaning`,
  `--format markdown`, `list` and `find` are rows
  (`declare-read-capability-meaning.sql`, `declare-list-capabilities.sql`); the
  terminal contributes labels and ordering only.
- **No media publication exists for the current model.** `sfx capability circuit`
  and `sfx media artifact` are declared readers of the retained snapshot
  publication (`declare-read-retained-publication.sql`); with none retained they
  exit 4 with `CIRCUIT_PUBLICATION_UNAVAILABLE`. That is the honest state, not a
  bug, and it is part of the recording.
- **The principal/identity story (Demo B) is not declared yet.** There is no
  invoking principal, no "secret exposed: NO" statement and no EVIDENCE block in
  authority, so the recording does not show them.
- **Scenario selection rendering (`Selected`) is another unit in flight.** The
  recording uses root capabilities; do not stage per-scenario selection.

## Before recording

The machine-readable acceptance is declared, not scripted: one run's captured
command observations are handed to `read-demo-acceptance` and it returns
`demo-acceptance-receipt.v1` with the twelve declared cases (10 offline + 2
live) and the no-synthesized-values verdict. The retired
`scripts/verify-demo.mjs` harness and its final report are retained as the W1.4
record in `evidence/vault-20260916/retirement/w1.4/`.

Every offline case must come back green; a live case may be declared
unavailable (`LIVE_UNAVAILABLE`, exit non-zero), which is a note, not a
blocker.

Production notes:

- Run `chcp 65001` (UTF-8) in the recording terminal, otherwise the `✓`, `·` and
  `↳` line symbols render as mojibake. The CLI writes UTF-8 bytes either way.
- The invocation beat is dependably ~2 s, and `list`/`find` now read the whole
  declared estate in about the same time (the declared listing read was
  optimized from ~10 s of SQL to ~0.3 s; see
  `sql/migrations/optimize-list-capabilities-read.sql`).
- `sfx capability list --namespace sidefx:capabilities` prints the count the
  estate currently declares (264 at the time of the last recorded receipts). It is
  estate state, never a constant in the script or this document.

## Recording sequence

### 1. List the declared estate (orientation)

```cmd
sfx capability list --namespace sidefx:capabilities
```

Proves: every declared capability is readable from rows, with the user story each
retains and its scenario count. Expected shape:

```text
Capabilities (<n>)
------------------
<capability-id>  sidefx:capabilities  (<n> scenarios)
...
```

### 2. Find the scaffold capability (targeted read)

```cmd
sfx capability find scaffold
```

Proves: matching is owned by the declared read; the terminal only renders rows.
Expected shape: `Capabilities (1)` followed by
`generate-executable-capability-scaffold  sidefx:capabilities  (16 scenarios)`.

### 3. Reveal the canonical story

```cmd
sfx capability reveal resolve-equity-market-price-evidence
```

Proves: the capability's canonical story is assembled from its declared semantic
closure, not paraphrased. Expected shape: `Capability`,
`Namespace`, `Root`, `View`, `Snapshot` identity lines, then
`Canonical feature`, `User story`, `Experience`, `Scenarios (1)`,
`Execution plan (1)`, `Ports (9)`, `Contracts (2)`, including the declared
provider port `observe-equity-price-exchange -> sda-governed-http-exchange-port.v1`.

### 4. Reveal the same story as review-ready Markdown

```cmd
sfx capability reveal resolve-equity-market-price-evidence --format markdown
```

Proves: the same single read, presented as a document. Expected shape: the
identity block, then `## Canonical feature`, `## User story`, `## Experience`,
`## Scenarios (<n>)`, `## Execution plan (<n>)`, `## Ports (<n>)`,
`## Contracts (<n>)`.

### 5. Execute the smallest capability

```cmd
sfx capability invoke say-hello-world --namespace sidefx:capabilities --input @evidence/hugging-face-pilots/2026-09-10T00-23-20.815Z/say-hello-world/returns-the-exact-canonical-greeting-without-domain-input.input.json --json
```

Proves: authority is read, planned and executed in process in about 2 s; the
canonical greeting is `Hello, World!`; nothing is written to stderr. Expected
shape: one JSON document on stdout with `result.disposition` `completed`,
`result.outcome.payload.message` `Hello, World!`, `result.observedPathDigest`,
and `evidence.readSession` reporting 1 connection, 1 pin, 1 reader switch, 6
queries.

### 6. Observe the same execution as a story, then as testimony

```cmd
sfx capability observe say-hello-world --namespace sidefx:capabilities --input @evidence/hugging-face-pilots/2026-09-10T00-23-20.815Z/say-hello-world/returns-the-exact-canonical-greeting-without-domain-input.input.json --trace
```

Proves: `observe` runs the identical execution and tells it at scenario altitude;
`--trace` opens the mechanical record underneath, on the same run. Expected shape
on stdout:

```text
Scenario say-hello-world
GIVEN hello-world-request  (hello-world-request.v1)
WHEN
  ✓ say-hello-world-port  0.058 ms
THEN
  ✓ hello-world-greeting  (hello-world-greeting.v1)

TRACE
✓ scenario say-hello-world  0.039 ms
  ✓ say-hello-world-port  0.058 ms
    ✓ literal payload.message  0.078 ms
    ...
```

and on stderr the semantic stream (representative lines; timestamps, durations
and interleaving vary):

```text
  · 12:20:49.258 literal contractId 1.053 ms
  ↳ 12:20:49.259 literal payload.message admitted 0.042 ms
  ✓ 12:20:49.260 say-hello-world-port 0.058 ms
```

The `✓` lines are responsibilities, the `·` lines are mechanics carrying the
declared expression path they computed, and the `↳` lines are edges with their
admission disposition.

### 7. Resolve providers (domain decision, no network)

```cmd
sfx capability invoke resolve-sidefx-eligible-providers --input @examples/provider-resolution.request.json --json
```

Proves: a second, unrelated capability executes through the same delivery.
Expected shape: `result.disposition` `completed`, `result.outcome.disposition`
`PROVIDERS_RESOLVED`, `result.outcome.eligibleCount` `1`.

### 8. Live equity price (optional, network)

```cmd
sfx capability invoke resolve-equity-market-price-evidence --input QQQ --json
sfx capability observe resolve-equity-market-price-evidence --display --input QQQ
```

Proves: the same surface against a live provider; observe appends the declared
display projection (the canonical product) under THEN. Expected shape: the invoke
outcome carries `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` with `payload.symbol`
`QQQ`, `payload.observedPrice`, `payload.currency`, `payload.marketState`,
`payload.sourceAttribution` and `providerTestimony`. The observe story lists
`observe-equity-price-exchange` with its real provider timing and then the
displayed product JSON. Prices move; never script a specific number.

### 9. The honest failure (state the limitation on camera)

```cmd
sfx capability circuit say-hello-world
sfx media artifact 0000000000000000000000000000000000000000000000000000000000000000
```

Proves: declared readers report an absent publication instead of substituting
one. Expected shape: exit code 4 and, on stderr,
`CIRCUIT_PUBLICATION_UNAVAILABLE` with a JSON error body naming the same code.

## What changed to make this possible

- **Bounded reads and one pinned session.** One invocation reads exactly the
  documents the declared graph needs, in one pinned read session
  (`readSession`: connections 1, pins 1, readerSwitches 1, queries 6; the old
  unbounded `readGraphSource` timing is gone), with no filesystem writes, no
  expanded-body reads, no database cache and no child processes. That is why the
  invocation beat is ~2 s instead of ~57 s.
- **The semantic address join.** `src/semantic-address.mjs` addresses each
  observed cell to declared identity (`SCENARIO_OUTCOME` with its faces,
  `EXECUTION_RESPONSIBILITY` with its declared operation id and ordinal,
  `MECHANIC` with its mechanic id), and `src/execution-drilldown.mjs` builds the
  `story` and the planned-versus-observed `overlay`. The identity is a join
  against rows, not a naming convention; `invoke` carries none of it.
- **Declared reader capabilities.** `reveal`, `list`, `find`, `circuit` and
  `artifact` are declared reads in the database, exposed as rows in
  `config/sfx.commands.json`; the CLI gained no capability-specific branch and the
  Entity Neutrality Law still holds.
- **Story-first observe and TRACE.** The terminal maps the default reading to the
  scenario altitude and `--trace` to the full testimony range, renders the
  declared faces as GIVEN / WHEN / THEN, then the observed tree nested by planned
  parent. It is a reading, not a second execution: invoke and observe return the
  same outcome and `observedPathDigest`.
- **The architecture rule.** Testimony records what happened at mechanical
  resolution; authority explains what it meant at declared resolution; the
  observer joins the two. No prose enters the runtime, and raw testimony is never
  discarded or rewritten.

## Limitations and talking points for the recording

- The current model retains no media publication: `CIRCUIT_PUBLICATION_UNAVAILABLE`
  is the honest state. Say so; do not improvise a workaround.
- Demo B (principal, identity, credential concealment, EVIDENCE block) is a
  declared extension, not installed. The story projection work (`story.label`,
  audience-keyed projections) is proposed authority, not present.
- The observe story renders declared ids and faces; carrying the retained Gherkin
  feature prose into the story is a named next unit.
- Scenario selection rendering (`Selected`) is in flight elsewhere; keep the
  recording on root capabilities.
- One kernel identity note: the scheduler reuses the operation cell's
  `cellExecutionId` for the scenario cell it wraps; the estate keys observed cells
  by declared `cellId` plus execution id. Do not dwell on it on camera.
- Invoke/observe parity is the point: same graph, same outcome, same
  `observedPathDigest`; the story is presentation. The receipts for both are in
  the `evidence/demo-<ISO timestamp>/` directory of the verification run.
