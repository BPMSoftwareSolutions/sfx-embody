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
`docs/transistor-model.md`.

## The prime rule: meaning is authored in the database

Capabilities are changed by rows, in `.sql`, under `sql/`. Do not change a
capability's meaning, wiring, contracts, authorities or transformations by
editing `src/` or `sidefx-database/sql/diagnostics/`. Those are readers.

## The change lifecycle (read `sql/README.md`)

The lifecycle's database ground is the SDA kernel bootstrap: the migration
runner and the from-transaction preflight live at
`../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/`
(`run-migration.mjs`, `invoke-from-transaction.mjs`). No estate script executes
SQL or reads arbitrary `.sql` files.

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

- Never use `sidefx-database/sql/migrations/run-file.mjs` to install: it wraps
  its own transaction and silently discards the script's `COMMIT`.
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
| `npm run verify:estate` | Regression cases. |
| `npm run verify:memory` | Retained-fixture parity. |
| `sfx capability invoke <identity> --input '@file.json' --json` | Real-surface invocation. |
| `sfx capability observe <identity> --input '@file.json'` | Same execution, streamed telemetry. |
| `sfx capability reveal <identity> --as meaning --format markdown` | Render retained meaning. |
