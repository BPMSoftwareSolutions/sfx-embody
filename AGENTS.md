# AGENTS.md

`sfx-embody` reads database authority and drives the CLI; the SDA kernel
interprets each declared capability's execution graph in process. Meaning lives
in rows, the kernel resolves language, providers are declared, and nothing is
materialized. The target end state, the irreducible code, and the disposition of
every concern are specified in `docs/target-architecture.md` - design and
retention questions are answered there, not re-litigated per module. Parallel
execution of the remaining work is planned in `docs/implementation-strategy.md`.
The binding requirement that every executable mechanic be embodied in the
embodiment (per target) is specified in `docs/embodiment-completeness.md`. The
invocation cost model and its optimization plan are in
`docs/performance-optimization.md`. The architecture we are gearing up for, the
primary experience, and which past decisions were premature ("wrong timing, not
wrong") are in `docs/target-experience.md`. The next target experiences we are
bringing clarity to (versioned projected bodies + cross-language perf, sealed
bootstrap binary, backdoor-script migration, vault manager) are in
`docs/next-experiences.md`. The smallest primitive of the whole architecture - the
resolver (0, per-language code) versus declared authority (1, language-neutral
data), and why a multi-language runtime entails a multi-language bootstrap - is in
`docs/transistor-model.md`. The harness controls that would enforce this file
mechanically - rather than by an agent's compliance with it - are registered in
`docs/agent-harness-hooks.md`; none are installed.

## The prime rule: meaning is authored in the database

Capabilities are changed by rows, in `.sql`, under `sql/`. Do not change a
capability's meaning, wiring, contracts, authorities or transformations by
editing any file. There is no estate source tree to edit: `src/`, `scripts/` and
`tests/` do not exist, and no sibling repository is a reader of this one.

## The dependency law: this repository depends on nothing

`sfx-embody` declares. It has **no dependencies** — no package manager, no
sibling-repository source path, no build step, no vendored tree.

- **No npm footprint.** There is no `package.json`, no lockfile and no
  `node_modules`. Do not add one. Nothing here is installed, built or bundled.
- **No sibling-repository dependency.** `sidefx-cli` and `sidefx-database` have
  no role in this estate — not as code, not as config, not as a resolvable
  documentation link. Do not reintroduce either, by any path spelling.
- **The one relationship to SDA is an install, not a checkout.** The estate
  reaches the kernel as `KernelEntry.exe` — an **installed executable** under
  `%LOCALAPPDATA%\sfx\kernel\<outputDigest>\`, admitted by
  `sfx-kernel-install-manifest.v1` and digest, selected as host data in
  `sfx.config.json`, and invoked over the closed `sfx-command-delivery.v1`
  envelope. Selecting an admitted binary is not a dependency on a source tree.
  No `scenario-driven-architecture` checkout, source path, read grant or build
  step participates at runtime. If a change requires the SDA source, it is a
  cross-language **request**, not an edit and not a path reference.

The check is the estate's own, and it must return nothing:

```
git grep -n "sidefx-cli\|sidefx-database" -- . ':!docs' ':!*.md'
```

**One violation remains, and it is owed, not permitted.** The change lifecycle
below still invokes `run-migration.mjs` and `invoke-from-transaction.mjs` from an
SDA **checkout** — the one thing this law forbids. It is the last dependency in
the estate. It closes when the migration lifecycle is reached through the
installed `KernelEntry.exe` like every other execution
(`docs/capability-estate-research.md` §6 A5). Until then it is named here rather
than hidden, and it is not a precedent for any other checkout reference.

## The change lifecycle (read `sql/README.md`)

The lifecycle's database ground is the SDA kernel bootstrap: the migration
runner and the from-transaction preflight live at
`../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/`
(`run-migration.mjs`, `invoke-from-transaction.mjs`). No estate script executes
SQL or reads arbitrary `.sql` files. Verification is a declared reading/receipt
or an admitted SDA conformance tool; no estate execution script remains.

1. **Evidence first.** Establish the working generation for the capability: a
   readable bundle under `evidence/<capability>/` or an extracted
   `edited-bundle.json`. A regression is a diff against the generation that
   worked.
2. **Author one migration** in `sql/migrations/`: idempotent, drops the
   `model`/`source` guard triggers inside the script, opens its own
   `BEGIN TRANSACTION`, ends in `ROLLBACK`, prints result sets.
3. **Dry-run:** `node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/run-migration.mjs sql/migrations/<file>.sql`.
4. **Preflight the invocation from the uncommitted state:**
   `node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/invoke-from-transaction.mjs sql/migrations/<file>.sql <capabilityId> <input.json>`.
   If the disposition is wrong, edit the migration and repeat from 3. Never
   commit before this passes.
5. **Install:** flip the final `ROLLBACK TRANSACTION;` to `COMMIT TRANSACTION;`
   and run `node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/run-migration.mjs <committed file>`.
6. **Verify the installation:** `sfx capability invoke <identity> --input ... --json`.
7. **Commit** only after 6, one migration per commit.

## Non-negotiables

- Never add a dependency. No package manager, no lockfile, no sibling-repository
  path, no build step. See the dependency law above.
- Never install through a runner that opens its own transaction. A migration
  authors its own `BEGIN TRANSACTION`; an outer wrapper makes that nest, reduces
  the script's `COMMIT` to a `@@TRANCOUNT` decrement, and silently discards the
  install. Use the lifecycle runner named below and nothing else.
- Capture `--json` through `cmd /c`; PowerShell 5.1 corrupts native stderr.
- On the database surface it is *all rows*. No "capsule", "artifact",
  "retained source" or "projection" vocabulary in migrations.
- Do not invent provider or kernel behavior to make an invocation pass. If a
  capability is blocked by a domain concern that only the Node runtime
  implements, that is a finding, not a reason to edit the kernel.

## Commands

| Command | Purpose |
| --- | --- |
| `node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/run-migration.mjs <file.sql>` | Run a migration as authored (no outer transaction). |
| `node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/invoke-from-transaction.mjs <file.sql> <capabilityId> [input.json]` | Preflight: apply uncommitted, invoke, roll back. |
| `sfx capability invoke read-projected-bodies --input '{"capabilityId":"<id>"}' --json` | Read a capability's projected bodies and hot-path isolation counts (declared read; replaces `run-query`). |
| `sfx capability list` / `find <query>` | Discover what the estate declares, with each capability's retained user story. |
| `sfx capability invoke <identity> --input '@file.json' --json` | Real-surface invocation. |
| `sfx capability observe <identity> --input '@file.json'` | Same execution, streamed telemetry. |
| `sfx capability reveal <identity> --as meaning --format markdown` | Render retained meaning. |

The first two rows are the owed violation named in the dependency law: they run
from an SDA checkout rather than the installed `KernelEntry.exe`. Every other row
goes through the installed kernel.

**Verification.** The estate has no `npm` surface, so the former
`npm run verify:*` commands no longer exist. Timing coherence, projected
testimony and projected performance are SDA-side conformance tools and are run
from there, against their own receipts; the declared acceptance authority in this
estate is `read-invocation-timing` and the receipts under `evidence/`. Do not
reintroduce a package manifest to make a verification runnable from here.
