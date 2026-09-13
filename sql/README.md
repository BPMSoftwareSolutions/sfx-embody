# SQL: the database-only change lifecycle

Every change to the estate's meaning is a database change. The runtime
(`src/`, and `sidefx-database/sql/diagnostics/`) is a reader of that meaning;
it is not where a capability, scenario, authority, contract, port or
transformation is authored. This directory holds the `.sql` deliverables and
the process that installs and verifies them.

## Layout

| Path | Contents |
| --- | --- |
| `sql/schema/` | Installed, idempotent model objects: assembled declaration views, authoring procedures, selection views. Re-runnable `CREATE OR ALTER`. |
| `sql/migrations/` | One-off data migrations. Each is a single unit of change and the subject of the lifecycle below. |
| `sql/inspect/` | Read-only inspection queries. |
| `scripts/run-migration.mjs` | Runs a migration as authored, without wrapping it in a transaction. |
| `scripts/invoke-from-transaction.mjs` | Applies a migration **uncommitted**, reads/plans/executes a capability, then rolls back. |

The runtime reader queries live in `C:/lab/sidefx-database/sql/diagnostics/`
(`capability-embodiment.sql`, `scenario-closure.sql`, ...). A migration here may
depend on those; a reader change is itself a database change and follows the
same lifecycle.

## The lifecycle

0. **Locate the evidence.** Before editing, establish the working generation
   for the capability: invoke it, and keep the readable bundle
   (`evidence/<capability>/<capability>.bundle.json` or an extracted
   `edited-bundle.json`). A regression is a diff between the current model and
   the generation that worked.
1. **Author one migration.** `sql/migrations/<descriptive-name>.sql`. Make it
   idempotent (refuse or no-op on a second run), drop the `model`/`source`
   guard triggers inside the script, open its own `BEGIN TRANSACTION`, and end
   in `ROLLBACK`. Print result sets that prove the change.
2. **Verify the dry run.** `node scripts/run-migration.mjs sql/migrations/<file>.sql`
   and read the result sets. Nothing is written.
3. **Preflight the invocation from the uncommitted state.**
   ```
   node --experimental-vm-modules scripts/invoke-from-transaction.mjs \
     sql/migrations/<file>.sql <capabilityId> <input.json>
   ```
   The migration is applied but never committed, then the read path plans and
   executes the capability. Inspect `DISPOSITION` and `OUTCOME`. **If it is not
   what the change intends, edit the migration and repeat from step 2.** Never
   commit a migration that has not passed this step.
4. **Install.** Produce a committed copy (replace the final
   `ROLLBACK TRANSACTION;` with `COMMIT TRANSACTION;`) and run
   `node scripts/run-migration.mjs <committed file>`.
5. **Verify the installation through the real surface.**
   `sfx capability invoke <identity> --input ... --json` (and `observe` where a
   stream matters). Exit 0 and the intended disposition, or the change is not
   done.
6. **Commit.** Commit the migration, and any reader change it depends on, only
   after step 5. One migration that passed the preflight is one commit.

### Why each rule exists

- **Preflight before install.** The uncommitted invocation is the only place
  the whole change is exercised (migration + read path + planner + body)
  before it can affect every consumer. It catches the failure class that
  otherwise installs cleanly and breaks at runtime.
- **One transaction, no runner wrapper.** `sidefx-database`'s
  `sql/migrations/run-file.mjs` opens its own transaction. A script's
  `BEGIN TRANSACTION` then nests, its `COMMIT` only decrements `@@TRANCOUNT`,
  and run-file's outer rollback silently discards the install. Use
  `scripts/run-migration.mjs`.
- **Idempotency.** Migrations are replayed against a rolling estate. A second
  run must not mint a duplicate version or double-link a row.
- **Native stderr.** PowerShell 5.1 rewrites a native command's stderr and can
  insert line breaks inside JSON. Capture JSON output through `cmd /c`, not
  `2>`.

### Worked example

`resolve-equity-market-price-evidence` regressed from a five-Port root
pipeline to a single testimony-reading Port plus three child invocations,
and its retained expressions had their binding members alphabetically ordered,
which the Node lowering cannot emit. Comparing the working evidence bundle
against the current model produced three migrations
(`restore-equity-root-authority.sql`, `restore-equity-feature.sql`,
`restore-equity-normalize-expression.sql`). The last was preflighted
uncommitted — `DISPOSITION terminated` — then installed and confirmed through
`sfx capability invoke`.
