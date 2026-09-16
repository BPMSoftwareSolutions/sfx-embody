# Next target experiences — what it would take

Research findings for the experiences we are bringing clarity to. Each item states
the current state, the target, what it takes, and the classification (**data** /
**boot/estate code** / **SDA change request**). Authority:
[target-architecture.md](target-architecture.md), [target-experience.md](target-experience.md),
[embodiment-completeness.md](embodiment-completeness.md) (agents must not edit SDA),
[performance-optimization.md](performance-optimization.md).

**Citation roots.** Unprefixed paths are this repo (`sfx-embody`). `SDA:` resolves
against the scenario-driven-architecture repo (`../scenario-driven-architecture`) —
agents must not edit it. `DB:` resolves against the sidefx-database repo
(`../../sidefx-database`), a third, separate repo. Bare identifiers after `SDA:`
(e.g. `SDA:project:consumer-capability`) name SDA-owned surfaces, not file paths.

## 1. Version-controlled mechanical bodies + cross-language performance comparison

**Target:** version-control the fully projected mechanical bodies of a declared
capability, with (a) a copy in the database *and* in the repo, (b) review as code
(implementation + semantic carries), (c) live execution-performance comparison across
Node / Python / C#.

**Current state.**
- The projection surface is **SDA** (`SDA:tools/src/interfaces/consumer-projection/project.ts`,
  `project:consumer-capability`) → per-target providers emit generated seams
  (`.mjs`/`.py`/`.cs`), bindings, plans, a `projection-manifest.json` — **disk only**
  (`SDA:tools/src/adapters/consumer-projection/node-consumer-projection-artifact-store.ts`
  writes `<workspaceRoot>/projected`). The terminal reaches it as
  `sfx capability project <id> --workspace <dir>` through the estate's
  `database-projection` surface ([capability-command-surface.md](capability-command-surface.md)).
- **No DB copy.** `source.content_object` / `semantic_object_definition` retain
  *declared authority* only; invocation is derived (`bodyStorage: NOT_REQUESTED`).
  `sfx-embody/embodiments/` is legacy **materialize** output — materialize was retired
  in `2fafd6c` and no longer exists under `src/` (see the disposition row below).
- **Carries exist but are dropped on publish.** Per-file `sourcePointers` and the v3
  cell `sourceMap` exist, but the published manifest keeps only
  `{path, executableOrigin, sha256}`.
- **Per-cell timing already exists** in all three kernels (`durationMilliseconds`,
  `startedAt`/`completedAt`): node
  `SDA:languages/typescript/runtimes/node/semantic-execution-graph/scheduler.js`,
  python `SDA:languages/python/src/scenario_kernel/platform/execution_graph.py`,
  csharp `SDA:languages/csharp/src/ScenarioKernel.Adapters/Graph/SemanticExecutionGraphScheduler.cs`.
  No kernel change needed for timing itself.

**What it takes.**
- **Data:** content-address every body in `source.content_object`; map rows keyed by
  `capability + generation + target + relative path` (`source_appearance` with a new
  `source_class='PROJECTED_BODY'`, or a `PROJECTED_BODY` model object). A
  **row-generation key bumped per authoring migration is mandatory** — coherence
  digests do not change on in-place row writes. Keep these rows **off the hot path**
  (never read by `capability_graph_source`, the loader, or `readExecutionDelivery`).
- **Boot/estate code (done):** `sfx capability project <id> --workspace <dir>`
  (`src/projection-delivery.mjs`) assembles the declared documents in one pinned
  read, stages the workspace and writes the repo copy under `<dir>/projected`;
  the projector's `projection-manifest.json` carries the per-file
  `{path, executableOrigin, sha256}` rows. `--full-mechanics` gates publication
  on every canonical provider slot being bound.
- **Boot/estate code:** a cross-language harness — project one canonical capability
  to node+python+csharp, run the same fixture corpus N times on one machine, report
  median/p95 whole-invocation and per-cell time (separate process startup).
- **SDA change request:** include `sourcePointers` in the published manifest and/or a
  per-target `source-map.json`; a projector DB artifact target; uniform timing
  emission if the CLI proof shape is extended.

**The retained body is an artifact for review/versioning/perf, never the invocation
mechanism.**

## 2. Sealed bootstrap binary with attested digest

**Target:** ship the consumer bootstrap as a compiled binary (`.exe`/`.dll`/`.dmg`)
per OS, with an integrity/authorization attestation, so the platform can be
distributed without exposing its implementation.

**Current state.** The bootstrap is a spawned Node process (`src/database-delivery.mjs`)
behind a stdin envelope / stdout result / stderr `SFX_OBSERVATION` protocol, guarded
by `--experimental-permission` + `restrictMemoryProcess`. It **dynamically imports
the DB runner (`sidefx-database/src/...`, a separate repo), the SDA kernel
(`SDA:languages/...`), and estate providers from unprotected disk** — the current read
allowlist includes `../scenario-driven-architecture` (SDA) and `./providers`. The CLI
only spawns; it does not verify a digest.

**What it takes.**
- **Boot/estate code:** a per-OS packaging build. **Node SEA** (`--experimental-sea-config`
  + `postject`) is the closest fit because it preserves Node's permission flags and the
  guard; a native build per OS/arch is required. (pkg/Bun/Deno are marked *tooling —
  validate*; ESM dynamic `import()` of absolute paths and native addons are the risks.)
- **Data:** declare the binary identity/digest (and signature/key reference) exactly
  as provider `implementationRef`/`digest` are declared today; the delivery binding in
  `sfx.config.json` points at the signed binary.
- **SDA/platform change request:** the CLI must verify the pinned digest **before
  spawn** (a binary cannot attest itself; the OS loader or caller must); bundle the SDA
  kernel + per-language providers into a signed platform binary (today they are plain
  readable files — sealing the bootstrap alone leaks them); cross-language sealed
  bootstraps.
- **Terminology:** the right construct is a **signed (attested) digest**, not an
  "encrypted digest" — encryption gives confidentiality, not authenticity.

**Trust boundary:** sealed *implementation* (frontdoor + loader + DB runner + kernel +
providers); open *authority rows and config* (meaning is the product and lives in
rows). The irreducible DB connection/query runner stays code (bundled or a second
signed component), and the frontdoor still owns the connection.

## 3. Migrating backdoor scripts to declared capabilities

**Target:** (A) when a user notices backdoor scripts (e.g. under
`%TEMP%\opencode`), migrate them as declared capabilities; (B) when a recurring AI
script-creation pattern is noticed, generate + project a managed capability so the
agent reuses it instead of writing scripts.

**Current state (as of 2026-09-15).** The temp dir holds ~958 files (~249 `.mjs`),
and **~134 `.mjs` import the DB runner directly** (`DB:src/query/run.mjs`
/ `DB:src/ingest/database.mjs`) — a direct reach around the frontdoor/loader, exactly the
layering violation the target names. Reproduce with:
`Get-ChildItem $env:TEMP\opencode -Recurse -File -Filter *.mjs | Select-String 'src/query/run.mjs|src/ingest/database.mjs' -List`
(counts are volatile evidence — re-stamp the date and command when re-measured). It
exists because one question is one `import` away and the managed path costs a declared
closure + migration. Detectors exist: `detect-hand-authored-code` (observe/classify
only) and `sql/inspect/hand-authored-module-references.sql` (module refs inside
declarations). **Recurrence aggregation does not exist.**

**What it takes.**
- **(A) Data:** author the script's behavior as rows via `model.scaffold_capability`
  (or a bespoke migration). Classify the script with `detect-hand-authored-code` to
  get attributable evidence, then author the *meaning* (never inferred). A thin
  `model.migrate_script_intent_to_capability(@intent_json)` on the existing `@defs`
  chain is the natural deliverable; the script-walking/scraping stays boot/harness.
- **(B) Data:** a declared recurrence read over detection evidence (a `sql/inspect/*`
  view); generate mechanical artifacts via `generate-executable-capability-scaffold`
  (pure, consumes a reviewed blueprint).
- **(B) SDA change request:** on-disk projection is SDA
  (`SDA:publish-projected-capability`, `SDA:project:consumer-capability`, and the
  workspace's **declared governance reference** `no-hand-authored-code.policy.v1.json`
  — referenced from `consumer-workspace.authority.json` as `../../governance/no-hand-authored-code.policy.v1.json`;
  the file is **not present on disk**, so it is a declared, currently-unresolved
  governance reference, not an artifact you can open — which fixes
  `projectedArtifactRoot: "generated"` with do-not-edit markers/receipts). Steer reuse
  with the existing declared reads (`sfx capability list`/`find`, `reveal --as meaning`)
  plus in-repo projected artifacts the agent encounters instead of copying a template.

**No new estate file writes on the invocation path**; the *decision* (what capability
a script becomes) is data. Any script parser is boot/harness or SDA (the admitted
transformation vocabulary cannot pattern-match).

## 4. Vault manager capability (credentials off the front door)

**Target:** stop storing credentials in environment variables; a declared vault-manager
capability resolves credentials from an encrypted vault provider, so (a) credentials
are nowhere near the front door of execution, and (b) the agent has no access to
secrets.

**Current state — where secrets surface.**
- **DB connection string**: `src/database-delivery.mjs:30` writes it into the delivery
  process env (`process.env[connectionEnvironmentVariable] = connectionString(...)`).
- **Effect credential** (e.g. `RAPID_API_KEY`): `credentialReader` defaults to
  `referenceName => process.env[referenceName]` (node
  `SDA:languages/typescript/runtimes/node/native-mechanic-primitives.mjs:22`; python
  `SDA:languages/python/src/scenario_kernel/platform/governed_effect_ports.py`; csharp
  `SDA:languages/csharp/src/ScenarioKernel.Adapters/Graph/GovernedEffectPorts.cs`), and
  the raw value is held in the in-process `credentialBindings` map; the OS provider even
  re-broadcasts it into `process.env`.
- **The safety property already present:** the one-use **opaque binding** — evidence
  exposes only `opaqueBindingId`/`referenceName`/`nonDisclosureVerified`, never the
  value; the CLI/agent never receives the value through the invocation channel.

**What it takes.**
- **SDA change request:** a per-language **vault provider** (node/python/csharp)
  resolving from an encrypted vault (OS keychain/Credential Manager/DPAPI, HashiCorp
  Vault, Azure Key Vault, 1Password, age/sops) that feeds the **existing**
  credential-reference port, preserving the opaque-binding evidence contract. Only
  node has an OS-credential resolver today; python/csharp have none.
- **Data:** the vault provider declaration (kind, locator, auth-method, scope),
  credential **reference names**, injection rules, and authority rules
  (`requestingCapabilityIds`/`endpointAuthorityDigests`/`effectScopes`/`lifetime`),
  plus the binding in `overlayBindings`/`providers`. **Rows never carry values.**
- **Boot defect to remove:** the delivery process must not copy the DB connection
  string into its env — resolve at the connect boundary, hand in a live handle, drop
  the value; and the effect credential's plaintext must exist only inside the vault
  provider's resolve call and the exchange header injection (not in a generic
  `credentialBindings` map, not in env, not in cells/evidence/logs).

**Sealed/unseal boundary:** the vault is sealed at rest until a runtime unseal; the
unseal key cannot come from the vault, and a declared capability cannot resolve it —
the unseal step belongs to the **boot** (irreducible frontdoor). The sealed-binary
work (§2) does not remove the need for an unseal input; the two are orthogonal. (The
"sealed binary" unit is not documented in the corpus; confirm with its owner before
citing it as a dependency.)

## 5. Migrating boot-resident declared logic to declared capabilities

**Target:** move the portable logic that currently sits in the boot into declared
capabilities (a read/transformation over testimony), per `docs/transistor-model.md:170-191`:
`src/execution-drilldown.mjs` (altitude selection, testimony join, planned-vs-observed
overlay), `src/observation-filter.mjs` (telemetry field allowlist), and
`src/semantic-address.mjs` (semantic addressing). Terminal rendering stays in
`sidefx-cli`.

**Why not extend it.** These files carry no host imports — they are declared authority
(1) misplaced in code, the defect §3.2 names. Adding transport fields to the allowlist
or the drilldown to serve the provider-altitude demo grows the defect instead of
migrating it.

**Depends on.** SDA request 7 (`docs/transistor-model.md:488`) is **satisfied for cell
materialization** (SDA `6aa2434`, `171d96f`): the compiler emits provider and physical
cells (equity: 2 + 2) and the runtimes stream them at those altitudes. Remaining: the
bounded `providerEvidence` fields are not yet in the observation allowlist/drilldown;
that passthrough belongs to the declared telemetry/display units (U4), not a kernel
request.

## Classification summary

| # | deliverable | class |
|---|---|---|
| 1 | body rows (`content_object` + generation-keyed mapping), off the hot path | **data** |
| 1 | `sfx-embody/embodiments/` (legacy materialize output; materialize retired `2fafd6c`, gone from `src/`) | **delete** — proof debt, read by no code; if kept, only as an immutable frozen baseline (never on the invocation path) |
| 1 | repo mirror + digest manifest (`sfx capability project`); cross-language timing harness | **boot/estate code** |
| 1 | `sourcePointers` in the published manifest; projector DB target; uniform timing | **SDA request** |
| 2 | per-OS packaging + signing/notarization build | **boot/estate code** |
| 2 | binary digest/attestation + delivery binding rows | **data** |
| 2 | CLI pre-spawn verification + transport; sealing the kernel/providers platform | **SDA/platform request** |
| 3 | script→capability rows; recurrence read; generate via scaffold | **data** |
| 3 | script walking/observation; detection reuse | **boot/harness** (detector is data) |
| 3 | on-disk capability projection/reuse steering | **SDA request** |
| 4 | vault provider per language | **SDA request** |
| 4 | vault declaration, reference names, rules, binding | **data** |
| 4 | remove env exposure (DB string + effect credential); boot unseal step | **boot** |
| 5 | migrate `execution-drilldown.mjs` / `observation-filter.mjs` / `semantic-address.mjs` into declared capabilities (read/transformation over testimony) | **data** |
| 5 | provider/physical altitude cells + bounded redacted testimony | **SDA request** |
| 5 | terminal rendering of drilldown observations | **boot** (stays in sidefx-cli) |

Every item preserves the invariants: one coherence pin per invocation, the isolation
boundary, no materialization on the invocation path, and no SDA edits from this repo
(cross-language → an SDA change request).
