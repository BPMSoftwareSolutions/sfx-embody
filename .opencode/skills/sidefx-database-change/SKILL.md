---
name: sidefx-database-change
description: Use when authoring, editing, installing, or verifying a SideFX database migration (.sql under sql/migrations or sql/schema), when changing capability meaning, wiring, contracts, authorities or transformations, or when sfx capability invoke/observe regresses. Covers the evidence-first rollback migration lifecycle and the from-transaction preflight.
---

# SideFX database change

Meaning is authored in the database. Change a capability by writing rows in
`.sql`; never by editing `src/` or `sidefx-database/sql/diagnostics/`. The full
process and rationale are in `sql/README.md`; the repository rules are in
`AGENTS.md`.

## Do this

1. **Evidence first.** Capture the working generation before changing anything:
   `sfx capability invoke <id> --input '@file.json' --json`, and keep the
   readable bundle under `evidence/<capability>/` (or an extracted
   `edited-bundle.json`). A regression is a diff against the generation that
   worked — diff the bundle's documents (feature, execution authorities,
   interfaces, semantic transformations, contracts) against the current model.

2. **Author one migration** in `sql/migrations/`. It must:
   - be idempotent (guard against a second install minting a duplicate),
   - drop the `model`/`source` guard triggers inside the script,
   - open its own `BEGIN TRANSACTION`,
   - end in `ROLLBACK TRANSACTION;`,
   - print result sets that prove the change.

3. **Dry-run it:** `node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/run-migration.mjs sql/migrations/<file>.sql`.

4. **Preflight the invocation from the uncommitted transaction:**
   ```
   node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/invoke-from-transaction.mjs \
     sql/migrations/<file>.sql <capabilityId> <input.json>
   ```
   Read `DISPOSITION` and `OUTCOME`. If they are not what the change intends,
   edit the migration and repeat from step 3. **Do not commit until this
   passes.**

5. **Install:** replace the final `ROLLBACK TRANSACTION;` with
   `COMMIT TRANSACTION;` in a committed copy and run the kernel lifecycle
   runner: `node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/run-migration.mjs <committed file>`.

6. **Verify the installation** through the real surface:
   `sfx capability invoke <identity> --input '@file.json' --json` (and
   `observe` when a stream matters). Exit 0 and the intended disposition.

7. **Commit** the migration (and any reader it depends on) only after step 6,
   one migration per commit.

## Traps

- `sidefx-database/sql/migrations/run-file.mjs` opens its **own** transaction.
  A script's `BEGIN/COMMIT` nests and run-file's outer rollback silently
  discards the install. Use the kernel lifecycle runner
  (`SDA:.../bootstrap/run-migration.mjs`).
- PowerShell 5.1 rewrites a native command's stderr and can insert line breaks
  inside JSON. Capture `--json` through `cmd /c`, not `2>`.
- Read input files without a BOM for the kernel preflight
  (`SDA:.../bootstrap/invoke-from-transaction.mjs`)
  (`JSON.parse` does not strip it); write them with
  `[System.IO.File]::WriteAllText($p, $json, (New-Object System.Text.UTF8Encoding($false)))`.
- The Node lowering emits a `let` expression's bindings in document order and
  resolves `path.from` through the binding scope. Binding members must be
  dependency-ordered in the retained expression; an alphabetical order lowers a
  binding reference as an input path and throws at runtime. Compare against the
  working evidence before deciding the fix.
- On the database surface it is *all rows*. Do not use "capsule", "artifact",
  "retained source" or "projection" vocabulary in a migration.

## Worked example

`resolve-equity-market-price-evidence` regressed from a five-Port root pipeline
(with a one-Scenario feature) to a testimony-reading Port plus three child
invocations, and its retained expressions were alphabetically ordered. Three
migrations restored it: `restore-equity-root-authority.sql`,
`restore-equity-feature.sql`, `restore-equity-normalize-expression.sql`. The
last was preflighted from the uncommitted transaction to
`DISPOSITION terminated`, installed, then confirmed with `sfx capability invoke`.
