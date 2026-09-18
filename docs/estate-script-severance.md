# Estate execution-script severance: inventory, the smallest move, and remaining edges

**Status.** Recorded 2026-09-18. Scope: sever the estate's execution dependency on
the `sidefx-database` repo so execution resolves through the SDA Kernel ground.
This unit moved one lifecycle function into the kernel, deleted the estate script,
and inventories the rest for the ordered units below. It deliberately does **not**
perform the full U5 rebase.

Authority: [composite-repo-boundary.md](composite-repo-boundary.md) §0/§3/§4
(D-list, U1–U8), [transistor-model.md](transistor-model.md) §1/§4,
[target-architecture.md](target-architecture.md) ("The only code that may
remain"), [hand-authored-code-retirement.md](hand-authored-code-retirement.md)
+ [hand-authored-code-retirement-agent-strategy.md](hand-authored-code-retirement-agent-strategy.md)
(the 28-file classification and wave plan).

---

## 1. Phase 0 outcome — `extract-inflight-bundle` severed and homed

**Before:** `sfx-embody/scripts/extract-inflight-bundle.mjs` (D6 in
[composite-repo-boundary.md](composite-repo-boundary.md) §1.2) hardcoded
`DATABASE_ROOT = 'C:/lab/sidefx-database'` and dynamically imported
`DB:src/ingest/database.mjs`, `DB:src/query/model-pin.mjs`,
`DB:src/query/run.mjs`; it also carried its own legacy `AUTHORITY_READ` /
`CLOSURE_READ` SQL and a `C:/lab/repos/scenario-driven-architecture` constant.

**After (the move):** the lifecycle function is homed on the kernel ground at

- `SDA:languages/typescript/src/kernel/bootstrap/inflight-bundle.mjs`
  (export `extractInflightBundle`, direct CLI entry).

It uses only kernel-bootstrap modules, all in-tree:

| Element | Kernel home |
|---|---|
| driver + connection-string resolution | `database-connect-boundary.mjs` (`sql`, `connectionString`, `createDatabaseConnectBoundary`) |
| pinned read session, model pin, normalization, digests | `database-read-session.mjs` (`withDatabaseReadSession`, `pinModel`, `normalizeSql`, `stable`, `hash`, `digest`) |
| declared declaration reads (no carried SQL) | `authority-read.mjs` + `data-access.mjs` (`capability-authority`, `capability-closure`, `mechanic-definitions`) |
| boot configuration | `runtime-configuration.mjs` (`readKernelBootConfiguration`) |

**What the function became.** The bundle is now extracted through the kernel's
declared data-access reads instead of carried SQL:

| Bundle field | Before (estate script) | After (kernel lifecycle tool) |
|---|---|---|
| `authority` | hand-authored SQL: root row + 12 declaration-document rows (`recordsets [1, 12]`) | declared `capability-authority` root row (`recordsets [1]`), `graph_source` and `documents` (13 docs) folded into the root |
| `closure` | hand-authored SQL (same statement as the declared read) | declared `capability-closure` read (`[1]`) |
| `mechanics` | hand-authored SQL | declared `mechanic-definitions` read (`[193]`) |
| `graphSource` | absent | parsed declared graph source |
| `pins` | `estateModelPk`, `snapshotId`, `projectionDigest` | `snapshotId`, `projectionDigest`, `viewDefinitionDigest` |
| experiment apply | raw pool/transaction | `withDatabaseReadSession` `beforePin` hook; always rolled back |
| invocation | `node scripts/extract-inflight-bundle.mjs <experiment.sql> <bundle.json> [capabilityId]` | `node <SDA>/languages/typescript/src/kernel/bootstrap/inflight-bundle.mjs <experiment.sql> <bundle.json> <capabilityId> [target]` |

**Parity receipt** (live DB, experiment `sql/migrations/declare-provider-authority-rows.sql`,
capability `extract-semantic-carrier-graph`, 2026-09-18):

| Field | Before (estate script) | After (kernel tool) |
|---|---|---|
| `selection` | `{capabilityId, target:'node', scenarioId:'extract-canonical-carrier-graph', namespaceId:'sidefx:capabilities'}` | same (plus `viewDefinitionDigest` in pins) |
| authority row counts | `[1, 12]` | `[1]` + `documents` 13 |
| closure row counts | `[1]` | `[1]` |
| mechanic row counts | `[193]` | `[193]` |
| `snapshotId` | `sha256:1a770ac0…f9e9` | `sha256:1a770ac0…f9e9` |
| `projectionDigest` | `sha256:8aae1f30…fdb0` | `sha256:8aae1f30…fdb0` |

**Estate disposition:** `scripts/extract-inflight-bundle.mjs` deleted. `rg` over
`scripts/` shows no remaining reference to it; no code or test imported it (docs
only), so there was no covering test to update.

**Phase 0 `rg` proof (moved target):**

```
rg -n "sidefx-database|SIDEFX_DATABASE_ROOT" sfx-embody/scripts/  →  no extract-inflight-bundle hit
rg -n "sidefx-database|databaseRoot|SIDEFX_DATABASE_ROOT" SDA:languages/typescript/src/kernel/bootstrap  →  0 hits
```

The second sweep also confirms U1's D16–D20 edges are **closed**: the kernel
bootstrap no longer names a database checkout or `databaseRoot`. The remaining
estate-wide references are inventoried in §5 (they are the U3/U5/U6/U7 scope, not
this unit's).

---

## 1.1 U5c outcome — the remaining execution scripts severed (2026-09-18)

`sfx-embody/scripts/` no longer exists. Every remaining execution script was
deleted after a live declared replacement or an admitted kernel conformance
ground; the inventory rows in §2.1 (and the pre-U5c `run-migration` /
`invoke-from-transaction` / `run-query` rows) are historical.

| Script (deleted) | Replacement / declared ground | Proof |
|---|---|---|
| `publish-projected-bodies.mjs` | none (materialization is eliminated; the projector database-artifact target was reverted in SDA M1, and `read-projected-bodies` is the declared read for the installed generation) | consumer sweep + `sfx capability invoke read-projected-bodies` live receipt (`evidence/vault-20260916/u5a/`) |
| `verify-timing-coherence.mjs` | kernel conformance command `SDA:languages/typescript/src/kernel/bootstrap/timing-coherence.mjs`; the declared `read-invocation-timing` remains the acceptance authority; `npm run verify:timing` runs it | live receipt `evidence/vault-20260916/u5c/timing-coherence.receipt.json` — `TIMING-COHERENT`, windows **715 / 179 / 181 / 460**, every residual zero or named |
| `verify-projected-testimony.mjs` | admitted SDA conformance probe `SDA:conformance/projected-testimony/verify-projected-testimony.mjs`; the kernel-side cross-target conformance is the SDA emitter test (SDA `a696fdd`, `0bff62b`) | `evidence/vault-20260916/u5c/projected-testimony.conformance.json` + the probe's live report |
| `projected-performance.mjs` | admitted SDA conformance harness `SDA:conformance/projected-performance/projected-performance.mjs`; per-cell timing is read from the kernel testimony fields | `evidence/vault-20260916/u5c/projected-performance.report.json` — `ADMITTED`, per-cell timing `AVAILABLE` on node/python/csharp |

The independent oracle (retired from `src/timing-coherence.mjs` at W2.1) is
inlined in the kernel command and its six pure cases are also an admitted kernel
conformance test (`SDA:languages/typescript/runtimes/node/timing-coherence.conformance.test.mjs`);
the estate test imports that home. The projected probes keep `--expect-closed`
semantics; on the committed equity workspace they report `TESTIMONY OPEN`
because the committed bodies predate the emitters — the regenerated projection
closes timing and lands `observedPathDigest`/`resolverTestimony` on every
target. The remaining equity-fixture case is a reported kernel field: python
testimony still carries semantic-normalized `cellId`s, so canonical-cell-id
membership and cross-walker set equality cannot be asserted on that fixture;
cross-target digest equality is asserted on the shared chaining fixtures.

**Proof sweep (U5c):** `git ls-files scripts/` = 0 and no `.mjs` under
`scripts/**` (tests/docs excluded). Estate `npm test` 71 pass / 0 fail /
6 skipped; SDA TypeScript 5/5; live invoke/observe digests unchanged. No estate
script remains.

---

## 2. Inventory — every estate execution script and `src/` execution role

Consumers are repo-wide (`src/`, `scripts/`, `tests/`, `sql/`, config, docs);
dependencies name `DB` = `sidefx-database`, `SDA` = kernel, `estate src`.
Classification key: **KLU** kernel lifecycle unit (home = kernel ground; some
rebase in place), **DCR** declared capability/rows replace it, **DEL** delete now,
**TF** test floor.

### 2.1 `scripts/**`

| File | Purpose | Consumers | Dependencies | Class |
|---|---|---|---|---|
| `run-migration.mjs` | Run one migration `.sql` batch-by-batch on one connection, no outer transaction (verification ROLLBACK / installation COMMIT as authored). Irreducible bootstrap installer. | `AGENTS.md:38,44,63`; `README.md:34`; `sql/README.md:15,36,49,67`; ~12 migration header comments. No tests. | **DB** (D4: `SIDEFX_DATABASE_ROOT` default `C:/lab/sidefx-database`); no estate src; no SDA kernel. | **KLU** — rebase in place on the kernel ground; estate keeps the admitted installer (`composite-repo-boundary.md` §4). |
| `invoke-from-transaction.mjs` | Preflight: apply an experiment uncommitted, read/execute through the loader, assert estate cases, roll back. | `AGENTS.md:40,64`; `README.md:36`; `sql/README.md:16,40`; migration comments. No test imports. | **DB** (D5); estate src (`invoke-database-capability`, `read-execution-delivery`, `read-authority`, `database-read-session`); SDA via the shims. | **KLU** — rebase on kernel ground; the kernel `withDatabaseReadSession` already supplies the `beforePin` hook that applies the experiment. |
| `extract-inflight-bundle.mjs` | Capture the authority bundle from an uncommitted transaction to disk. | docs only (no code/test consumers). | **DB** (D6). | **KLU — moved and deleted** (see §1). |
| `run-query.mjs` | Generic query runner: one `.sql` on one connection. | `scripts/queries/list-projected-bodies.sql:7`; docs (`sda-tools-uid-homing.md:1064`, `scripts-disposition-review.md`). | **DB** (D3: `SIDEFX_DATABASE_ROOT`). | **DCR** — duplicate of the kernel ground's declared-read session; retires when `read-projected-bodies` (SDA request 9) lands. Still on a documented live path. |
| `verify-timing-coherence.mjs` | IEA timing-coherence acceptance; also exports the admitted independent oracle used by tests; writes receipts. | `package.json:15` (`verify:timing`); `tests/timing-coherence.test.mjs:6`; `docs/invisible-execution-authority.md`; `docs/implementation-plan-next-wave.md` (W1/W3). | **DB** (D7: `SIDEFX_DATABASE_ROOT`, `SIDEFX_SDA_ROOT`); estate src (4 modules); writes `evidence/**`. | **TF** — declared receipt/replacement: `read-invocation-timing` (installed) + `evidence/vault-20260916/iea/timing-coherence.receipt.json`. Rebase ground on kernel (U5c); oracle stays as the admitted harness (builder decision 5). |
| `verify-projected-testimony.mjs` | Projected-target testimony parity probe (timing fields, `observedPathDigest`, `resolverTestimony`, canonical cell ids) for F1/F2 closure. | `docs/sda-change-request-projected-testimony.md`; `docs/implementation-plan-next-wave.md` (W3); retirement ledger W3.1. | none of DB/estate src; spawns projected bodies; SDA Python path only. | **TF** — declared replacement: projected-testimony conformance reading (SDA requests 7/8); delete after the `--expect-closed` receipt. |
| `projected-performance.mjs` | Cross-language performance harness for projected bodies (subprocess wall clock, per-cell timing from testimony, report JSON). | `docs/performance-optimization.md`; `docs/projection-performance.md`; `docs/implementation-plan-next-wave.md` (W2). | none of DB/estate src; spawns projected targets; SDA Python path. | **TF** — declared replacement: projected performance reading (per-cell timing from testimony); W2 trigger. |
| `publish-projected-bodies.mjs` | Deterministic generator for the database copy of projected bodies (content-addressed migration). | generated `sql/migrations/publish-projected-bodies-resolve-equity-market-price-evidence.sql:3`; retirement ledger. | none of DB/estate src/SDA kernel (manifest + file bytes only). | **DCR** — retires on SDA request 9 (`read-projected-bodies`), after the dry-run + hot-path-isolation receipt (W3.2). |
| `queries/list-projected-bodies.sql` | Declared-read candidate: list projected bodies and hot-path isolation counts. | `run-query` header; retirement ledger. | `run-query` (DB) to execute; SQL only. | **DCR** — becomes `read-projected-bodies` (SDA request 9). |

**Script counts:** KLU 3 · DCR 3 · TF 3 · DEL 0.

### 2.2 `src/**` execution roles

All nine files are kernel-bound boot code or re-exports; none is declared
authority. Every one is classified **KLU** (home = the kernel; the estate copies
are deleted or reduced by U3/U5).

| File | Role | Consumers | Dependencies | Class |
|---|---|---|---|---|
| `database-delivery.mjs` | Estate frontdoor (stdin envelope, session plumbing, observation filter). `invoke` is already delegated to `SDA:invocation-boot.mjs:81`; every other operation still traverses the estate loader. | `sfx.config.json` delivery `database-memory`; the CLI. | **DB** via `config.databaseRoot` (D1); loader; 4 shims; SDA invocation-boot. | **KLU** — boot; estate file retires with U3 once U2's carrier covers non-invoke operations. |
| `projection-delivery.mjs` | Projection frontdoor (read declared documents, stage workspace, run the SDA projector). | `sfx.config.json` delivery `database-projection`; `tests/projection-delivery-connect-boundary.test.mjs` reads its source. | **DB** via `config.databaseRoot` (D2); kernel shims. | **KLU** — projection is review/publish output, not invocation; retires with U3/U4 (kernel `project` operation). |
| `invoke-database-capability.mjs` | Transitional loader (operation table, envelope validation, estate-provider execution). | `database-delivery`; `scripts/invoke-from-transaction.mjs`; `scripts/verify-timing-coherence.mjs`; 5 tests; declared PROVIDER rows in `sql/migrations` name the module (G7 defect). | SDA runtime `declared-authority-reader.mjs`; estate shims; estate-module rows. | **KLU** — portable meaning re-declared (W4.2/W4.3); file deleted with U3. |
| `read-authority.mjs` | One-line kernel re-export. | `database-delivery`; tests; scripts. | SDA kernel `authority-read.mjs`. | **KLU** — thin re-export; delete with callers (U3). |
| `read-execution-delivery.mjs` | One-line kernel re-export. | `invoke-database-capability`; tests; scripts. | SDA kernel `delivery-read.mjs`. | **KLU** — same. |
| `database-read-session.mjs` | One-line kernel re-export. | `database-delivery`; tests; scripts. | SDA kernel `database-read-session.mjs`. | **KLU** — same. |
| `database-connect-boundary.mjs` | One-line kernel re-export. | `database-delivery`; `projection-delivery`; tests. | SDA kernel `database-connect-boundary.mjs`. | **KLU** — same. |
| `restrict-memory-process.mjs` | One-line kernel re-export. | `database-delivery` only. | SDA kernel `process-restriction.mjs`. | **KLU** — same. |
| `credential-vault-realization.mjs` | Kernel re-export (4 exports). | `invoke-database-capability`; `tests/credential-vault-realization.test.mjs`. | SDA kernel `credential-realization.mjs`. | **KLU** — same. |

**`src/` counts:** KLU 9 · DCR 0 · TF 0 · DEL 0.

### 2.3 Deleted in this unit

| Script | Class before | Disposition |
|---|---|---|
| `scripts/extract-inflight-bundle.mjs` | **KLU** | Function homed in SDA (see §1); estate file deleted. No test changes required. |

---

## 3. Ordered units to finish the severance

Order is chosen so every deletion follows a live declared replacement and a
receipt; nothing here restarts the full U5 as one unit.

1. **U5a — Rebase the two estate lifecycle tools on the kernel ground (in
   place, no relocation).**
   - Files: `scripts/run-migration.mjs`, `scripts/invoke-from-transaction.mjs`;
     `config/database-runtime.json` loses `databaseRoot` (the kernel boot file
     carries only connection env var/timeouts/row limits).
   - Replacement: `SDA:database-connect-boundary.mjs` +
     `database-read-session.mjs` (+ `authority-read.mjs` for the preflight);
     delete `DATABASE_ROOT`/`SIDEFX_DATABASE_ROOT`.
   - Acceptance: one ROLLBACK migration and one preflight transaction green;
     `rg "sidefx-database|SIDEFX_DATABASE_ROOT" sfx-embody/scripts` = 0.
2. **U5b — Retire the query backdoor after its declared read.**
   - Deletion order: land `read-projected-bodies` (SDA request 9) →
     delete `scripts/queries/list-projected-bodies.sql` → delete
     `scripts/run-query.mjs`.
   - Acceptance: the declared read reproduces the hot-path isolation counts
     (W3.2).
3. **U5c — Declared receipts for the verification scripts (delete order).**
   - `scripts/verify-projected-testimony.mjs` after SDA requests 7/8, with the
     `--expect-closed` receipt (W3.1).
   - `scripts/publish-projected-bodies.mjs` after SDA request 9 (W3.2).
   - `scripts/projected-performance.mjs` after the projected performance
     reading/timing fields (W2 trigger), last because it consumes testimony.
   - `scripts/verify-timing-coherence.mjs`: rebase on the kernel ground and
     keep only as the admitted independent oracle inside its named resolver
     boundary; the acceptance authority is `read-invocation-timing`
     (W2.1, builder decision 5).
4. **U3/U5d — Retire the estate frontdoors and re-export shims.**
   - After U2/U4 cover observe/reveal/project: delete `invoke-database-capability`,
     the `database-delivery` non-invoke branch and `projection-delivery`; delete
     the six shims; drop `databaseRoot` from `config/database-runtime.json` and
     `config/regression.cases.json`.
   - Acceptance: `sfx-embody/src/` is empty; every retained acceptance command
     runs through the kernel entry.
5. **U5e — Rebase the tests** D10–D14 (`tests/timing-coherence`,
   `tests/demo-acceptance`, `tests/credential-vault-realization`,
   `tests/database-read-session.integration`, `tests/execution-drilldown`,
   `tests/semantic-address`, `tests/invocation-read`) on the kernel ground.
6. **U6 — Delete the CLI contract files** (`sfx.config.json`,
   `config/sfx.commands.json`), removing C1–C3 and the DB sandbox allowlist.
7. **U7 — Re-point every prescription** (`AGENTS.md`, `README.md`,
   `sql/README.md`, skills, non-historical docs, migration comments).

---

## 4. Live-path status (as of this unit)

| Surface | State |
|---|---|
| `run-migration` | live (documented install path); DB edge open (U5a) |
| `invoke-from-transaction` | live (documented preflight path); DB edge open (U5a) |
| `run-query` | live only as the documented executor of `queries/list-projected-bodies.sql`; DB edge open (U5b) |
| `verify-timing-coherence` | **retired (U5c)**: kernel command + `read-invocation-timing`; `npm run verify:timing` |
| `verify-projected-testimony` | **retired (U5c)**: SDA conformance probe |
| `projected-performance` | **retired (U5c)**: SDA conformance harness |
| `publish-projected-bodies` | **retired (U5c)**: materialization eliminated; declared `read-projected-bodies` |
| `verify-declared-provider-authority` | already deleted in estate `1ea2b9c` (no live file); not in this inventory |
| `extract-inflight-bundle` | **severed**: kernel lifecycle tool; estate file deleted |

---

## 5. Exact remaining edges with owners

`DB` = `sidefx-database`, `CLI` = `sidefx-cli`. Owner = the ordered unit in §3.

### 5.1 `DB` — live code/config/test edges (non-doc, non-evidence)

| # | File:line | What | Owner |
|---|---|---|---|
| 1 | `src/database-delivery.mjs:18-32` | dynamic `DB` imports through `config.databaseRoot` (D1) | U3/U5d |
| 2 | `src/projection-delivery.mjs:137-148` | same imports (D2) | U3/U5d |
| 3 | `scripts/run-migration.mjs:14,21` | `SIDEFX_DATABASE_ROOT` + `DB` connection/runner (D4) | U5a |
| 4 | `scripts/invoke-from-transaction.mjs:20` | hardcoded `DB` root + imports (D5) | U5a |
| 5 | `scripts/run-query.mjs:9` | `SIDEFX_DATABASE_ROOT` + `DB` import (D3) | U5b |
| 6 | ~~`scripts/verify-timing-coherence.mjs:194`~~ | `SIDEFX_DATABASE_ROOT` + `DB` imports (D7) — **closed by U5c** (script deleted; kernel command uses the kernel ground) | U5c |
| 7 | `config/database-runtime.json:3` | `"databaseRoot": "../../../sidefx-database"` (D8) | U5a/U5d |
| 8 | `config/regression.cases.json:2` | `databaseRoot` for tests (D9) | U5e |
| 9 | `tests/timing-coherence.test.mjs:138-159`; `tests/demo-acceptance.test.mjs:23-74`; `tests/credential-vault-realization.test.mjs:224-251`; `tests/database-read-session.integration.test.mjs:12`; `tests/execution-drilldown.test.mjs:134`; `tests/semantic-address.test.mjs:84`; `tests/invocation-read.test.mjs:112` | `DB`-rooted fixtures/placeholders (D10–D14) | U5e |
| 10 | `sfx.config.json:21-25` | sandbox allowlist embedding `../../sidefx-database/{src,config,sql,node_modules,package.json}` (C3/D15) | U6 |

Closed by U1 (no longer present): `SDA:languages/typescript/src/kernel/bootstrap`
D16–D20 (`invocation-boot`, `authority-read`, `runtime-configuration`,
`declared-operation-carrier`, `process-restriction`) — rg returns 0.

### 5.2 `DB` — prescriptive (comments/prose)

| File | Owner |
|---|---|
| `AGENTS.md:27,50` | U7 |
| `README.md:39,93` | U7 |
| `sql/README.md:21-22,63` | U7 |
| `src/database-delivery.mjs:30` (comment) | U3/U5d |
| `scripts/run-migration.mjs:14` (comment) | U5a |
| `sql/migrations/declare-read-retained-publication.sql:6` | U7 |
| `docs/**`, `evidence/**`, `baselines/**` | historical; never rewritten (H) |

### 5.3 `CLI` — live edges (all config; no code edge)

| # | File:line | What | Owner |
|---|---|---|---|
| 1 | `sfx.config.json:1-38` | `sfx-project.v1` delivery contract (C1) | U6 |
| 2 | `config/sfx.commands.json:1-160` | `sfx-command-mapping.v1` operation vocabulary (C2) | U4/U6 |
| 3 | `sfx.config.json:21-25` | fs-read allowlist naming the DB checkout (C3) | U6 |

### 5.4 `CLI` — prescriptive

`AGENTS.md:45,67-69`; `README.md:66`; `sql/README.md:51,84`;
`.opencode/skills/**`, `.claude/skills/**`; the §1.1 doc list of
[composite-repo-boundary.md](composite-repo-boundary.md) — owner U7. Historical
and research bytes (H) are not rewritten.

---

## 6. Verification record (2026-09-18)

- **Estate suite:** `npm test` → 71 pass / 0 fail / 6 skipped (77 tests),
  baseline preserved after the deletion.
- **SDA TypeScript suite:** `npm --prefix languages/typescript test` → 5/5.
- **Live acceptance, digests unchanged:**
  - `sfx capability invoke say-hello-world --input {}` → outcome equal,
    `canonicalGraphDigest sha256:8b859397…4931`, `observedPathDigest
    sha256:20864ba2…70ba`, 6 cell testimony records (before = after).
  - `sfx capability observe request-capability-from-objective --input "What is
    Broadcom's current market price?" --json` → `completed` /
    `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`, `snapshotId
    sha256:1a770ac0…f9e9`, `projectionDigest sha256:8aae1f30…fdb0`,
    `viewDefinitionDigest sha256:f6f8e40a…e78c`, `observedPathDigest
    sha256:26c85c04…fb73` (before = after).
- **Parity of the moved function:** §1 (closure `[1]`, mechanics `[193]`,
  pins equal; authority shape is now the declared root read).
- **`rg` proofs:** moved target clean (`scripts/` and the new kernel file);
  kernel bootstrap clean of `sidefx-database`/`databaseRoot`; remaining estate
  hits enumerated with owners in §5.

No commits were made by this unit; the orchestrator verifies and commits.
