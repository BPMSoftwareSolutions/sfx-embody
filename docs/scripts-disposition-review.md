# Scripts disposition review: declaration vs retirement

2026-09-14 · Review

## Scope and method

Read against the decision authority for the end state: `docs/target-architecture.md`.
The review covered the current tree at the time of writing:

- `docs/target-architecture.md` and `docs/implementation-strategy.md`;
- the six remaining files in `src/`;
- the migrations under `sql/migrations/` and `sql/schema/`;
- all 17 scripts in `scripts/`.

Each script was classified against the target's three-question rule, not against
its current wiring or its historical role.

## The decision rule

`target-architecture.md:71-82`:

1. **Is it the boot?** (frontdoor/loader, DB connection/query runner, bootstrap
   installer) → it is code — the only allowed code.
2. **Does it emit, load, write, or verify a native body / materialized plan?**
   → it is **eliminated**; do not port it or declare it.
3. **Otherwise** → it is **meaning**; it becomes rows (a declared read, a
   declared transformation, a provider binding) and is invoked through the
   frontdoor.

Supporting constraints used below:

- No materialization: "no native-body emission, no file writes, no child-process
  execution, no platform-commit pinning" (`target-architecture.md:24-26`).
- A Port's `configuration` MUST be exactly one of a platform mechanic binding or
  a declared data read (`target-architecture.md:148-159`).
- Capability-to-capability invocation is an `invoke-scenario` operation with
  mapped contracts — not a platform port and not estate code
  (`target-architecture.md:168-170`).
- The frontdoor is the terminal, non-declared executor; the chain must ground in
  a non-declared executor (`target-architecture.md:36-43`).

## Disposition of each script

| Script | Concern | Target disposition | Action |
|---|---|---|---|
| `run-migration.mjs` | Opens the DB, runs a migration as authored, no outer tx | **code** (irreducible #3, bootstrap installer) | Keep. Referenced by `AGENTS.md`, `sql/README.md`, the change skill |
| `invoke-from-transaction.mjs` | Preflight: apply uncommitted, invoke through kernel, roll back | **code** (boot/lifecycle frontdoor+loader) | Keep |
| `extract-inflight-bundle.mjs` | Capture authority bundle from an uncommitted tx | **code** (boot/lifecycle evidence) | Keep; ideally fold into the preflight |
| `extract-bundle.mjs` | Read loader authority bundle → disk | **meaning**, but *already declared* as the `read-authority` capability (`declare-read-authority-capability.sql`, `declare-read-authority-data.sql`) | Retire as redundant tooling |
| `read-scenario-round-trip-authority.mjs` | Declared read of one `SCENARIO` definition | **meaning** (SQL read, no transformation) | Only true declaration candidate: author read rows, then retire |
| `build-scaffold-hello-world.mjs` | Generates `sql/migrations/scaffold-hello-world.sql` | Authoring/build tool (writes files — not a capability, not boot) | Retire; the `.sql` artifact is committed |
| `audit-semantic-expression.mjs` | Audits generated native bodies / embodiment plans | **eliminated** (native-body verification) | Delete + drop `audit:source` from `package.json` |
| `audit-lowering-evidence.mjs` | Conformance refs vs a pinned platform commit | **eliminated** (platform-commit pinning / provenance gate) | Delete + drop `audit:lowering` |
| `materialize-consumer-provider-dependencies.mjs` | Writes provider deps under `providers/consumer-execution` | **eliminated** (materialization / file write) | Delete |
| `preserve-baseline.mjs` | Snapshots evidence into `baselines/<digest>` | **eliminated** (retained-fixture parity) | Delete |
| `qualify-pilots.mjs` | Runs installed `sfx`, asserts fixtures, retains evidence | Test/qualification boundary — not boot, and not expressible as written (see below) | Delete as written, or replace with an in-kernel qualification capability |
| `verify-consumer-execution-providers.mjs` | Native provider verification | **eliminated**; imports deleted `src/read-execution-graph.mjs`, `src/resolvers/node/consumer-execution-provider.mjs` | Delete |
| `verify-consumer-first-failure.mjs` | Native-body verification | **eliminated**; imports deleted `src/resolvers/node/consumer-execution-provider.mjs` | Delete |
| `verify-consumer-fixtures.mjs` | Native-body/materialization verification | **eliminated**; imports deleted `consumer-plan-provider`, `consumer-execution-provider`, `materialize-node`, `load-memory-scenario` | Delete |
| `verify-declared-fixtures.mjs` | Native-body verification | **eliminated**; imports deleted `materialize-node`, `load-memory-scenario` | Delete |
| `verify-sfx-invocation.ps1` | CLI acceptance asserting old evidence shape (`bodyStorage`, 14 modules, `expandedBodyReadAllowed`) | **obsolete** (materialization-era evidence) | Delete, or rewrite as a kernel CLI smoke test |
| `verify-sfx-preparation.ps1` | `prepare`/materialization proof (`capability-embodiment.sql`, …) | **eliminated** | Delete |

## Findings

- **Only one script is a genuine declaration candidate.**
  `read-scenario-round-trip-authority.mjs` is a straight declared read.
  `extract-bundle.mjs` is already covered by the declared `read-authority`
  capability, so it retires rather than being declared.
- **The four `verify-consumer-*` and `verify-declared-fixtures` scripts are
  already dead code.** Every import they make resolves to a file that no longer
  exists in `src/` (`src/resolvers/**`, `src/materialize-node.mjs`,
  `src/load-memory-scenario.mjs`, `src/read-execution-graph.mjs`). They also pull
  in `sql/inspect/consumer-execution-providers.sql`, whose only consumer is the
  dead verifier.
- **`src/` is already down to the boot** (6 files); the irreducible three are
  effectively `run-migration.mjs`, the frontdoor `database-delivery.mjs`, and the
  loader read. That makes the lifecycle scripts keepers, not declaration
  candidates — you cannot declare the bootstrap installer.
- **The target forbids porting/declaring the eliminated set.** The rule is
  explicit (`target-architecture.md:77-79`); `audit-*`,
  `materialize-consumer-provider-dependencies`, `preserve-baseline` and the
  `verify-*` are deletions, not rows.

## Is `qualify-pilots.mjs` declarable?

Not as written. The target does not name qualification harnesses, pilots or
tests, so there is no explicit "not declarable" statement; the classification is
derived from the constraints that do apply:

1. **No child-process execution.** The harness runs the installed CLI by
   spawning a shell (`scripts/qualify-pilots.mjs:131-133`) and uses
   `spawn`/`execFileSync` (`:7`, `:17-26`, `:46-48`). The interpreted path may
   not launch processes (`target-architecture.md:24-26`).
2. **No file writes.** It retains inputs, stdout, stderr and receipts to disk
   (`:127`, `:135-136`, `:181-182`). Ports bind only to a platform mechanic or a
   declared data read (`:148-159`); neither primitive writes a file or captures a
   process's streams.
3. **Frontdoor re-entry is not composition.** The only sanctioned
   capability-to-capability call is an `invoke-scenario` operation
   (`:168-170`). A declared capability whose body spawns `sfx` is not
   composition; it is process execution, and the frontdoor is the terminal,
   non-declared executor (`:36-43`).
4. **Its assertions are materialization-era.** It asserts
   `evidence.bodyStorage === 'MEMORY_ONLY'`, `evidence.modules.length === 14`,
   `expandedBodyReadAllowed === false`, `fsWriteAllowed === false`
   (`scripts/qualify-pilots.mjs:158-160`). That evidence shape belongs to the
   body-loading execution the target eliminates (`target-architecture.md:68`).

The semantic core is expressible: fixtures are already retained authority
(`:109-116`), and "invoke a target and admit its outcome" is `invoke-scenario`
plus contract admission. The precedent is `run-pilot-container`, declared as a
capability bound to a platform provider
(`sql/migrations/declare-run-pilot-container-capability.sql:19,24,39`) — but that
binding is `load-memory-scenario.mjs`, which the target eliminates, so the
precedent is itself materialization-era.

Conclusion: the process/evidence boundary is not a capability. The declarable
slice is a **new** capability (fixtures → `invoke-scenario` → contract admission,
no subprocess, no disk), not a port of this harness. Whether that slice is
expressible with the SDA primitives available today is an open question, and the
next thing to check.

## Stale references to fix alongside

- `package.json` still wires `qualify:pilots`, `audit:source` and
  `audit:lowering` (`package.json:15-17`).
- `sql/README.md:19` still says the runtime reads
  `C:/lab/sidefx-database/sql/diagnostics/` — this contradicts the target's
  boot-read rule.
- `docs/capability-command-surface.md` cites `src/narrate-capability-meaning.mjs`
  and claims `list`/`find`/`reveal` work, but `executeDatabaseCommand` in
  `src/invoke-database-capability.mjs` only implements `invoke`/`observe`. The
  reader/presentation capabilities remain Lane E work.

## Net

`run-migration.mjs`, `invoke-from-transaction.mjs` and
`extract-inflight-bundle.mjs` are irreducible code and stay. One reader script is
declarable. The remaining thirteen should be retired on disk without declaring
them, because they are materialization, native-body or provenance concerns that
the kernel supersedes.

**Executed 2026-09-14 (working tree, not yet git-committed).** Twelve of the
eliminated scripts were deleted on disk — `audit-semantic-expression`,
`audit-lowering-evidence`, `materialize-consumer-provider-dependencies`,
`preserve-baseline`, `qualify-pilots`, `verify-consumer-execution-providers`,
`verify-consumer-first-failure`, `verify-consumer-fixtures`,
`verify-declared-fixtures`, `verify-sfx-invocation.ps1`,
`verify-sfx-preparation.ps1`, `extract-bundle` — and the `package.json`
lifecycle entries `qualify:pilots`/`audit:source`/`audit:lowering` were removed.
`build-scaffold-hello-world.mjs` and
`read-scenario-round-trip-authority.mjs` remain, along with the three keepers.
`npm test` passes 8/8.
