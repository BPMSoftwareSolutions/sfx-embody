# The composite repo boundary: removing `sidefx-cli` and `sidefx-database` from the composite

2026-09-17 · Read-only audit + durable strategy. Status: proposed, not yet landed.

This document is the durable disposition of the two sibling repositories relative
to the composite. It answers, once, the question "does the CLI or the database
repo still have a role here?" The answer is no. It is binding in the same sense
as [target-architecture.md](target-architecture.md): a later question about these
repos is answered here, not re-litigated per file.

## 0. The rule

**The composite is the estate + the SDA kernel + the database itself (the
declaration store). Both repos may exist, but they must not play a role in the
composite.**

- **Any transport a user needs belongs to the kernel's resolver surface** — the
  per-language bootstrap entry (frontdoor) that owns physical entry, arguments,
  streams, telemetry, exit disposition, and the declared operation carrier.
- **The DB ground belongs to the kernel bootstrap** — connection resolution,
  driver, pinned read session, query runner, and model pin are kernel bootstrap
  code, not a reach into a sibling checkout.
- The **database itself** (the SQL Server instance, its rows, its connection
  string in the environment, its snapshot/content store) is not either repo; it
  stays. Only the repositories' *code and prescriptive docs* lose their role.

The two repos then become what they should always have been: the CLI a
standalone terminal/SDK surface, the database repo standalone inspection
tooling, neither required by a composite invocation.

Authority chain: [target-architecture.md](target-architecture.md) (irreducible
three, layering), [transistor-model.md](transistor-model.md) (resolver (0) vs
declared (1); the bootstrap is resolver code, per language),
[implementation-strategy.md](implementation-strategy.md) (lane plan).

**Builder ruling that supersedes current prose.** `docs/target-architecture.md:24-25`
("the estate is a reader; `sfx-embody` / `sidefx-database` … drive the CLI") and
`:189-190` ("`sidefx-database` supplies the connection and query runner only") and
`docs/transistor-model.md:18-19` (identical claim) describe the current state, not
the target. Under the rule above, the DB connection/query runner is an
irreducible mechanic whose home is the **kernel bootstrap**, and the carrier is
kernel resolver-surface code. Those lines are updated by U0.

---

## 1. Dependency map

Classification key: **T** transport carrier (argument/stream protocol),
**M** meaning (semantics decided there), **Q** query runner / connection ground,
**A** authoring convenience (docs, skills, lifecycle instructions), **H**
historical evidence (retained proof, frozen baselines, research artifacts).

Citation root `sfx-embody` unless prefixed `SDA:` (`C:\lab\repos\scenario-driven-architecture`)
or `CLI:` (`C:\lab\repos\sidefx-cli`) or `DB:` (`C:\lab\sidefx-database` — note:
not under `C:\lab\repos`). Sweep excludes `node_modules`, `.git`, `evidence`,
`baselines`, `build`, `embodiments`, `package-lock.json`; the excluded sets are H.

### 1.1 The estate → `sidefx-cli`

**Runtime contract edges (config the CLI consumes).**

| # | file:line | what | class |
|---|---|---|---|
| C1 | `sfx.config.json:1-38` | The estate ships the CLI's `sfx-project.v1` project file. It declares the two process deliveries (`database-memory` → `node --experimental-permission src/database-delivery.mjs config/database-runtime.json`; `database-projection` → `src/projection-delivery.mjs`), their cwd and args. Read only by CLI `loadConfiguration` (`CLI:src/configuration.mjs:11-44`). | T |
| C2 | `config/sfx.commands.json:1-160` | The estate ships the CLI's `sfx-command-mapping.v1` mapping (surfaces `:3-23`; commands `:34-159`; `project` `:130-143`). Read only by CLI `loadCommandMapping` (`CLI:src/commands.mjs:17+`). | T |
| C3 | `sfx.config.json:21-25` | fs-read allowlist embedding `../../sidefx-database/{src,config,sql,node_modules,package.json}` in the spawned delivery's sandbox. Names the sibling repo in the composite boot itself. | Q/T |

**Documentation and instruction edges (prescriptive).** All are A unless noted.
Each file:lines.

| file | lines | what |
|---|---|---|
| `README.md` | 66 | "install the current `sidefx-cli` … first"; :39 "the `sidefx-database-change` skill" |
| `AGENTS.md` | 45, 67-69 | lifecycle step 6 and command table prescribe `sfx capability invoke/observe/reveal` |
| `sql/README.md` | 51, 84 | install verification through the real `sfx` surface |
| `.opencode/skills/sidefx-database-change/SKILL.md` | 2, 3, 9, 16, 45, 53, 77 | migration lifecycle and traps prescribe `sfx capability invoke/observe` and name `sidefx-database/sql/migrations/run-file.mjs` |
| `.claude/skills/declare-provider-fallback/SKILL.md` | 20-21, 227 | `cmd /c "sfx capability observe/invoke …"`; `:227` names `sidefx-database/sql/migrations/run-file.mjs` |
| `docs/target-architecture.md` | 118, 120 | proof of a unit is `sfx capability invoke <identity>` |
| `docs/implementation-strategy.md` | 31, 70, 122-136, 250 | proof, presentation disposition, "Projection is a native CLI command", kernel path claims |
| `docs/next-experiences.md` | 29, 52, 137, 206, 226, 239 | projection and reader surfaces through `sfx`; terminal rendering "stays in sidefx-cli" |
| `docs/capability-command-surface.md` | 3-20, 31, 204, 225-233, 357-380 | the whole CLI surface inventory, acceptance matrix, "command mapping consumes …" |
| `docs/demo-commands.md` | 10, 38, 43, 62, 73, 79, 99, 105, 113, 136-137 | demo script: junction on PATH, `sfx capability` commands |
| `docs/demo-runbook.md` | 30, 62, 71, 87, 97, 110, 121, 134, 172, 182-183, 197 | runbook commands |
| `docs/agent-lane.md` | 16, 49, 60, 74, 79 | lane commands |
| `docs/agent-lane-declaration.md` | 119-120, 132 | invocation examples |
| `docs/database-direct-invocation.md` | 3, 116, 120-131, 136-139, 155-158, 170-176 | "invoke through sfx"; explicit process binding: "The CLI forwards … `sfx-command-delivery.v1`. The independent database provider … owns SQL reads" |
| `docs/database-preparation.md` | 3, 6, 14, 26 | `sfx capability invoke/prepare` |
| `docs/database-mutation-flywheels.md` | 124, 131-134, 185 | CLI flags/render ownership table |
| `docs/cli-estate-parity-2026-09-08.md` | 10, 15, 37 | CLI parity evidence and link to CLI repo |
| `docs/display-observation-conformance-plan.md` | 4, 16, 26, 36, 49-51 | owner "estate + SDA (kernel) + sidefx-cli"; renderer defect sites in CLI |
| `docs/display-projection-migration.md` | 77, 97, 186, 210 | CLI triplication of operation spec; `SFX_OBSERVATION`; CLI inventory |
| `docs/display-projection-decision-record.md` | 120 | `sfx capability observe say-hello-world` |
| `docs/execution-story-projection.md` | 78, 157, 161, 242, 251, 257, 330 | story surface through the terminal |
| `docs/narration-projection-disposition.md` | 33, 99 | rendering is "terminal presentation" in `CLI:src/render.mjs` |
| `docs/architecture-priorities.md` | 58, 157, 169 | projection command; display code in `CLI:src/render.mjs`; invoke proof |
| `docs/implementation-plan-circuit-view.md` | 9, 115 | circuit view moves `padCenter` into `CLI:src/render.mjs` |
| `docs/vault-manager-capabilities.md` | 171, 397, 422 | CLI stdin channel (`--input -`); secret prompt owned by CLI |
| `docs/embodiment-completeness.md` | 152, 195 | estate path invoked through `sfx` |
| `docs/embodiment-as-capability.md` | 63, 96 | `sfx capability invoke/materialize` |
| `docs/sidefx-public-demo-readiness.md` | 28, 48-51, 83, 115-119, 133, 184 | demo acceptance through the CLI; renderer built from CLI fields |
| `docs/invisible-execution-authority.md` | 31 | observe at the CLI |
| `docs/performance-optimization.md` | 3, 171 | goal is `sfx capability invoke|observe` latency |
| `docs/grafana-execution-dashboards.md` | 21, 36 | `SFX_OBSERVATION` stream and piping |
| `docs/flywheel-proof.md` | 89-90, 110-111, 120-122, 234-263, 299-304, 357-361, 431-433 | CLI invocation evidence (some H) |
| `docs/bounded-execution-closure.md` | 5 | invoke behavior |
| `docs/deriving-contract-schemas.md` | 83, 98, 116 | `sfx capability invoke` incl. absolute `C:\nvm4w\nodejs\node_modules\sidefx-cli\bin\sfx.mjs` |
| `docs/scaffold-invocation-rapidapi.md` | 18, 114, 145 | CLI invocation |
| `docs/projected-csharp-install.md` | 29 | `sfx capability project` |
| `docs/projection-consumer-schema-blocker.md` | 19-21 | projection through CLI |
| `docs/projection-performance.md` | 183 | CLI observe field units |
| `docs/sda-change-request-effect-altitude-execution.md` | 93-94 | `cmd /c "sfx capability observe … --trace"` |
| `docs/sda-change-request-projected-testimony.md` | 116, 188, 255, 275 | CLI observe/project as acceptance |
| `docs/sda-change-request-bounded-provider-evidence-http-status.md` | 66 | CLI observe |
| `docs/target-harness-experience.md` | 190, 402 | `sfx capability observe` |
| `docs/declare-provider-fallback-validation.md` | 175 | CLI invoke |
| `docs/rate-limit-evidence-store.md` | 67 | probe through CLI vocabulary |
| `docs/verification/**`, `docs/research/**` | inventory | retained evidence and research; class **H** — not rewritten |
| `sql/migrations/*.sql` comments | `declare-equity-cli-input.sql:6`, `declare-read-capability-meaning.sql:4`, `extend-circuit-presentation-connectors.sql:31`, `proof-authoring-procedures.sql:18,26,38`, `select-scenario-in-declared-meaning.sql:3` | comments prescribe a verification command; authoring convenience **A** |
| `docs/research/hugging-face-platform/pilot-qualification.json` | 7 | `"cli": "C:\\nvm4w\\nodejs\\sfx.ps1"` — absolute installed-CLI path (A/H) |
| `docs/research/hugging-face-platform/pilot-qualification.md:11` | "install … the current `sidefx-cli`" | A/H |
| `docs/research/hugging-face-platform/README.md:7,38`, `source-map.json:25,106`, `verification.json:114` | CLI repo inspection records | H |
| `docs/research/sql-cli-work-order-001/README.md:34`, `gap-resolution.md:121,129` | CLI stdout consumption contract | A/H |
| `docs/research/target-architecture/Resolver vs Declared … Findings.md:3,220,532` and `Findings.v2.md:273,316-317,385,438-443,474,509,539,543,613,695` | research maps of CLI internals | H |
| `docs/canonical-feature-migration-gap.md`, `docs/scaffold-generation-operationalization-plan*.md` | cross-links to DB repo (see §1.2) | A/H |

**Code edges:** none. The estate has no `import` of any `sidefx-cli` file, no
`package.json` dependency on it, and no spawned `sfx` process anywhere in live
`src/`, `scripts/` or `tests/`. Every coupling is the config contract (C1-C3)
plus prescription (A). The one absolute bin path is in a research doc
(`docs/deriving-contract-schemas.md:116`).

### 1.2 The estate → `sidefx-database`

**Runtime/code edges.** These are the violating edges; each resolves the repo by
path at runtime.

| # | file:line | what | class |
|---|---|---|---|
| D1 | `src/database-delivery.mjs:22-32` | imports `DB:src/core.mjs` (`:18`), `DB:src/ingest/database.mjs` (`:19`), `DB:src/query/run.mjs` (`:31`), `DB:src/query/model-pin.mjs` (`:32`); `:20-27` reads `connectionEnvironmentVariable`, resolves the connection string through the DB repo, builds the connect boundary. | Q |
| D2 | `src/projection-delivery.mjs:137-148` | same four imports (`:137,138,147,148`); `:144-146` connect boundary. | Q |
| D3 | `scripts/run-query.mjs:9,16` | `SIDEFX_DATABASE_ROOT` + import `DB:src/ingest/database.mjs`; raw `sql.Request` | Q |
| D4 | `scripts/run-migration.mjs:21,28` | same ground; `:14-16` warns off the DB repo's `run-file.mjs` | Q |
| D5 | `scripts/invoke-from-transaction.mjs:20,22,44-48` | DB root hardcoded `C:/lab/sidefx-database`; imports ingest/model-pin/run/core | Q |
| D6 | `scripts/extract-inflight-bundle.mjs:15,16,76-78` | same | Q |
| D7 | `scripts/verify-timing-coherence.mjs:194,320-323` | same; `:195` `SIDEFX_SDA_ROOT` | Q |
| D8 | `config/database-runtime.json:3` | `"databaseRoot": "../../../sidefx-database"`; consumed by D1, D2, and the SDA kernel boot (`SDA:…/runtime-configuration.mjs:9-11`) | Q |
| D9 | `config/regression.cases.json:2` | `databaseRoot` for tests | Q/A |
| D10 | `tests/timing-coherence.test.mjs:138-143,146,157,159` | imports core/ingest/run/model-pin via `runtime.databaseRoot` | Q/A |
| D11 | `tests/demo-acceptance.test.mjs:23-28,31,72,74` | same | Q/A |
| D12 | `tests/credential-vault-realization.test.mjs:224-229,232,249,251` | same | Q/A |
| D13 | `tests/database-read-session.integration.test.mjs:12` | DB root from runtime config | Q/A |
| D14 | `tests/execution-drilldown.test.mjs:134`, `tests/semantic-address.test.mjs:84`, `tests/invocation-read.test.mjs:112` | `databaseRoot: 'unused'` placeholders into estate loader | A |
| D15 | `sfx.config.json:21-25` | sandbox allowlist (counted as C3) | Q/T |
| D16 | `SDA:languages/typescript/src/kernel/bootstrap/invocation-boot.mjs:80-88` | the kernel boot's own DB ground: imports `DB:src/core.mjs`, `DB:src/ingest/database.mjs`, `DB:src/query/run.mjs`, `DB:src/query/model-pin.mjs`; `:132,135` thread `databaseRoot` through the execution context | Q |
| D17 | `SDA:languages/typescript/src/kernel/bootstrap/authority-read.mjs:24-27` | fallback `import(DB:src/query/run.mjs)` when no query is supplied | Q |
| D18 | `SDA:languages/typescript/src/kernel/bootstrap/runtime-configuration.mjs:9-11` | boot config requires and resolves `databaseRoot` | Q |
| D19 | `SDA:languages/typescript/src/kernel/bootstrap/declared-operation-carrier.mjs:57` | `context.readAuthority(context.databaseRoot, …)` | Q |
| D20 | `SDA:languages/typescript/src/kernel/bootstrap/process-restriction.mjs:10-13` | forbids fs reads under `<databaseRoot>/data` | Q |

**Instruction/doc edges** (A unless noted).

| file | lines | what |
|---|---|---|
| `AGENTS.md` | 27, 50 | "never edit `sidefx-database/sql/diagnostics`"; "never use `sidefx-database/sql/migrations/run-file.mjs`" |
| `sql/README.md` | 21-22, 63 | "Nothing reads `sidefx-database/sql/` …; `sidefx-database` supplies the connection and query runner only"; runner wrapper warning |
| `README.md` | 39, 93 | skill name; "default layout … sidefx-database alongside repos/ … owns … connection configuration (`sidefx-connection-string`)" |
| `.opencode/skills/sidefx-database-change/SKILL.md` | 2, 9, 53 | skill name and run-file warning |
| `.claude/skills/declare-provider-fallback/SKILL.md` | 227 | run-file warning |
| `docs/target-architecture.md` | 24, 186, 189, 198, 200 | estate is a reader with `sidefx-database`; "supplies the connection and query runner only"; layering: frontdoor "is the only component that knows where `sidefx-database` is" |
| `docs/transistor-model.md` | 18-19, 20, 291-293, 350, 476 | citation root; boot chain; G6 bootstrap gap; sda-bootstrap |
| `docs/next-experiences.md` | 12-13, 77 | `DB:` citation root; sealed bootstrap "dynamically imports the DB runner (`sidefx-database/src/...`, a separate repo)" |
| `docs/implementation-strategy.md` | 50, 61, 251 | "Replace the residual `sidefx-database/sql/diagnostics` read"; "removes the last `sidefx-database/sql` reach" |
| `docs/database-direct-invocation.md` | 103 | links `C:/lab/sidefx-database/sql/diagnostics/capability-embodiment.sql` |
| `docs/deriving-contract-schemas.md` | 35, 38 | `cd C:\lab\sidefx-database` setup |
| `docs/vault-manager-agent-strategy.md` | 133 | `sidefx-database` connection needed for preflight/install |
| `docs/scripts-disposition-review.md` | 129 | stale `C:/lab/sidefx-database/sql/diagnostics/` reference |
| `docs/canonical-feature-migration-gap.md` | 215, 343, 448, 649 | DB repo registration/projection core and migration paths |
| `docs/scaffold-generation-operationalization-plan.md` | 129, 443, 445 | DB `src/migration/{catalog,schema,views}.mjs`, `src/register/capability.mjs` |
| `docs/scaffold-generation-operationalization-plan-review.md` | 232, 248 | DB `src/query/run.mjs` link, DB README immutability |
| `docs/scaffold-invocation-rapidapi.md` | 138 | DB registration lane |
| `docs/sql` comments | `sql/migrations/declare-read-retained-publication.sql:6` | historical note "read reached into sidefx-database" |
| `docs/research/**` | `canonical-feature-migration/{audit.mjs:7-12,88,91, review-20260911.json:4}`, `scaffold-projection-gap/{build-contract-fix.mjs:21, inventory_org.sql:5}`, `scenario-experiences/{read-inventory.mjs:7-8, README.md:389,425}`, `hugging-face-platform/*`, `sda-cross-apply-authority-gap/README.md:162,173`, `sql-cli-work-order-001/scaffold-comparison.md:6`, `target-architecture/target-experience-research-findings.md:118`, `target-architecture/Resolver vs Declared*.md` | research tooling and research findings; class **H/A** |
| `baselines/…/regression.cases.json:2` | frozen baseline | **H** |

**Code edges:** the four DB modules imported in D1/D2/D16 are the whole runtime
coupling. `SDA` and the estate also carry one-line re-export shims of the kernel
bootstrap (`src/read-authority.mjs:1`, `src/read-execution-delivery.mjs:1`,
`src/database-read-session.mjs:1`, `src/database-connect-boundary.mjs:1`,
`src/restrict-memory-process.mjs:1`) — these reach the kernel, not the DB repo.

### 1.3 SDA → `sidefx-cli` / `sidefx-database`

- **`SDA:docs/transistor-model.md:290`** — describes the chain
  `sidefx-cli → spawn → src/database-delivery.mjs → src/invoke-database-capability.mjs → SDA node kernel`.
  Descriptive, must be updated when U2/U3 land.
- **`SDA:docs/transistor-model.md:18-19`** — `DB:` citation root says the DB
  repo "supplies the connection and query runner only". Superseded by U0/U1.
- **No code edge by name.** SDA has no import, dependency, or spawn of
  `sidefx-cli` and no literal `sidefx-database` path. The DB repo enters SDA
  only through the boot config's `databaseRoot` and the dynamic imports at
  D16-D19. That is the whole SDA-side violation.

### 1.4 Couplings that do not exist (keep it that way)

- No `package.json` in the estate or SDA depends on `sidefx-cli` or
  `sidefx-database` (`sfx-embody/package.json:17-22`;
  `scenario-driven-architecture/package.json:66-81`).
- No estate or SDA file spawns `sfx`; the only child processes are the kernel's
  declared, bounded providers and the projection/perf harnesses.
- `sda-bootstrap` is installed only as a CLI-side assumption
  (`CLI:src/delivery.mjs:10,19-31`); the estate has no `node_modules/sda-bootstrap`.
- The estate's `src/` is already mostly kernel re-exports; the only real code is
  the frontdoor (`database-delivery.mjs`), the transitional loader
  (`invoke-database-capability.mjs`), the projection frontdoor
  (`projection-delivery.mjs`), and the re-export shims.

---

## 2. Judgment per edge

| Edge | Violates the rule? | Correct home |
|---|---|---|
| C1 `sfx.config.json` | Yes — the composite's physical entry is declared in the CLI's project format | Kernel per-language bootstrap entry (U2); the file is deleted (U6) |
| C2 `config/sfx.commands.json` | Yes — operation vocabulary/wraps are carrier meaning carried for the CLI | Declared `execution-delivery` rows (the estate already declares `execute-declared-capability` in `sql/migrations/bind-declared-execution-delivery.sql:26`); carrier loop in the kernel bootstrap (U2/U4) |
| C3 sandbox allowlist of DB repo | Yes — names the sibling repo in the composite's own boot | Deleted with C1; the kernel's own ground is in-tree (U1) |
| CLI doc prescriptions (A) | Yes as acceptance instructions; a doc that makes CLI installation a precondition gives the repo a role | Kernel entry is the documented surface; CLI becomes optional/standalone (U7) |
| Rendering/presentation refs (`CLI:src/render.mjs`, circuit/diagram) | No — presentation is a surface concern, and the declared display projection is data; the CLI may render it as a standalone surface. But the composite must not *require* it | Stays outside the composite; declared display/format selection goes through the kernel carrier (U2) |
| D1-D2 (frontdoor and projection delivery DB imports) | Yes — Q | Kernel bootstrap ground (U1); estate frontdoors deleted (U3) |
| D3-D7 (lifecycle scripts) | Yes — Q. These are boot/lifecycle code, so the scripts may stay, but their ground is the DB repo | Rebase on the kernel ground (U5) |
| D8-D9 (`databaseRoot`) | Yes — the boot config points at a repo | Remove the key; kernel boot config carries only connection env var name/timeouts/row limits (U1/U5) |
| D10-D14 (tests) | Yes — Q via a repo path | Rebase on the kernel ground (U5) |
| D16-D20 (SDA kernel boot DB reach) | Yes — Q. This is the most important edge: the kernel's irreducible ground is delegated to a sibling checkout | In-tree kernel ground (U1) |
| D1 `:20-27` connection-string lookup | Yes — Q. The string resolution (env / Windows User / Machine) is the ground's own job | Kernel ground implements it per OS/language (U1) |
| DB doc references (A/H) | Not a runtime violation; but `README.md:87-94` and `sql/diagnostics` references claim a composite consumer that will not exist | Corrected/marked historical in U7/U8; frozen evidence untouched (H) |
| Research scripts (`audit.mjs`, `read-inventory.mjs`, `build-contract-fix.mjs`) | No composite role | Out-of-composite: delete or leave as research (they must not be in any acceptance path) |
| Frozen baselines, evidence, `build/`, `embodiments/`, package-lock | No — historical bytes | Never rewritten |

The single sentence: **every edge that the composite's boot, invocation,
projection, lifecycle, or acceptance exercises resolves either the CLI's carrier
or the DB repo's ground and is therefore a violation; every edge that is only
historical text is not.**

---

## 3. Strategy — ordered units

Each unit is agent-ready: scope, replacement, acceptance, verification. Units
U1/U2 are **SDA changes** (the estate's protocol: agents do not edit SDA; these
are kernel change requests in the [transistor-model.md](transistor-model.md) §10
format). U0 and U3-U8 are estate units. Land in order; U2 depends on U1 for a
clean ground, U4 on U2, U5-U7 on U4.

### U0 — Freeze the boundary and correct the governing prose

- **Scope:** this document; `docs/target-architecture.md:24-25,186-190,198-200`;
  `docs/transistor-model.md:18-19`; `AGENTS.md:3-4,27`; `sql/README.md:18-23`.
- **Replacement:** state the rule of §0; change "the estate is a reader and drives
  the CLI" to "the estate declares meaning; the kernel bootstrap owns the carrier
  and the DB ground"; change "`sidefx-database` supplies the connection and query
  runner only" to "the kernel bootstrap owns the connection/query runner; the DB
  repo is standalone tooling".
- **Acceptance:** no governing doc assigns a composite role to either repo.
- **Verification:** grep for the two phrases; this doc is the citation.

### U1 — Kernel bootstrap owns the DB ground (SDA change request)

- **Primitive:** an in-tree Node ground at
  `SDA:languages/typescript/src/kernel/bootstrap/` — `mssql` driver import;
  connection-string resolution (`process.env[name]`, then Windows User/Machine
  lookup, error if absent); `pinModel(tx)` (the read currently at
  `DB:src/query/model-pin.mjs:6-11`); `normalizeSql` (the function currently at
  `DB:src/query/run.mjs:5-12`); `stable`/`hash`/`digest` (or declare them as the
  session already receives them); boot config read (connection env var name,
  `queryRowLimit`, `requestTimeoutMs` — currently `DB:config/harness.json:3,7-8`).
- **Why kernel:** the ground is one of the irreducibles (proof by circularity,
  `target-architecture.md:47-52`); it must exist in every supported language and
  cannot be the declaration store's repo.
- **Languages:** node first (the only admitted bootstrap,
  `docs/transistor-model.md:350`); python/csharp when their bootstraps are owed.
- **Data that binds it:** the connection environment variable name; the pinned
  read session's model-pin statements (already kernel code,
  `SDA:…/database-read-session.mjs:20-56` — it only needs `connect`, `sql`,
  `pinModel`, `normalizeSql`, `stable`, `hash`, `digest` in-tree).
- **Replacement scope in SDA:** `invocation-boot.mjs:80-88` and `:132,135`;
  `authority-read.mjs:24-27`; `runtime-configuration.mjs:9-11`;
  `declared-operation-carrier.mjs:57`; `process-restriction.mjs:10-13`. Delete
  the `databaseRoot` config key and the `readAuthority(databaseRoot, …)`
  argument; `readAuthority` already takes only injected `query`/`dataAccess`.
- **Acceptance:** `invokeDeclaredCapability` completes for a declared capability
  with no path into any `sidefx-database` checkout; the pinned read session still
  reports the same `snapshotId`/`projectionDigest`/`viewDefinitionDigest`.
- **Verification:** `rg -n "sidefx-database|databaseRoot" SDA:languages/typescript/src/kernel/bootstrap`
  returns no import/path; the estate's retained invoke acceptance
  (`docs/verification/database-cli-20260908.json`) reproduces against the
  in-tree ground.

### U2 — Kernel resolver surface owns the physical carrier (SDA change request)

- **Primitive:** a per-language bootstrap entry (Node first) that owns the whole
  physical carrier: argv grammar and options; typed input carriers (`--input`
  JSON / `@file` / `-` stdin, `--input-type`); the closed request envelope
  (`sfx-command-delivery.v1` may be retained as the wire protocol); stdout
  canonical result; stderr diagnostics and the observation carrier
  (`SIDEFX_OBSERVE=1` → `SFX_OBSERVATION <json>` lines) behind the declared
  telemetry allowlist; timeout, interrupt, exit-code map
  (`terminated|completed` → 0, delivery/integrity → 4, usage → 2, not-offered →
  3); operation dispatch from declared rows, not from a shipped mapping file.
- **Why kernel:** "any transport a user needs belongs to the kernel's resolver
  surface" (this ruling); the bootstrap is resolver (0) code and owes a native
  path from physical entry to canonical authority per supported language
  (`docs/transistor-model.md:81-85,308-312`).
- **Data that binds it:** the estate's declared `execution-delivery` provider row
  (`sql/migrations/bind-declared-execution-delivery.sql:26`), plus one declared
  row per offered operation (`list`, `find`, `reveal`, `circuit`, `catalogue`,
  `artifact`, `project`) with its reader capability and option set — superseding
  `config/sfx.commands.json`.
- **Replacement source (to port):** `CLI:src/delivery.mjs:33-54,56-105`
  (spawn/stdio/timeout/observation framing), `CLI:src/cli.mjs:74-134,136-224`
  (argv grammar, input carriers, render dispatch), `CLI:src/index.mjs:38-89`
  (envelope construction, disposition mapping), `CLI:src/configuration.mjs`
  (project binding — dropped), `src/database-delivery.mjs:66-88` and
  `src/invoke-database-capability.mjs:183-259,291-514` (estate envelope
  validation and operation table).
- **Acceptance:** from the estate workspace,
  `<kernel-entry> invoke <identity> --input '@x.json' --json` returns the same
  canonical result/stream as today's `sfx capability invoke`; the entry works
  with no `sfx.config.json`, no `config/sfx.commands.json`, and no installed
  `sidefx-cli`; presentation options the terminal owned (`--json`, `--trace`,
  `--display`, `--format`) are either declared carrier options or absent.
- **Verification:** byte-compare stdout/exit codes for the retained acceptance
  commands (`docs/verification/database-cli-20260908.json`,
  `docs/research/sql-cli-work-order-001/verification.json`);
  `docs/flywheel-proof.md` command set; observation-line parity for one observe
  run.

### U3 — Retire the estate frontdoor and loader

- **Scope:** `src/database-delivery.mjs`, `src/projection-delivery.mjs`,
  `src/invoke-database-capability.mjs`, and, once U2 covers their callers, the
  re-export shims `src/read-authority.mjs`, `src/read-execution-delivery.mjs`,
  `src/database-read-session.mjs`, `src/database-connect-boundary.mjs`,
  `src/restrict-memory-process.mjs`, `src/credential-vault-realization.mjs`.
- **Replacement:** the U2 kernel entry. `invoke` already routes to the kernel
  (`src/database-delivery.mjs:79-81`); reader/observe/reveal/projection paths
  follow once U2's declared operation dispatch lands.
- **Acceptance:** estate `src/` is either empty or kernel re-exports; no estate
  file imports the DB repo; `sfx.config.json` has no consumer (deleted in U6).
- **Verification:** delete test — every retained acceptance command runs through
  the kernel entry; `npm test` green after the test rebase (U5).

### U4 — Declare the full operation surface for the kernel carrier

- **Scope:** estate `sql/migrations/` only. Reader operations are already
  declared capabilities (`implementation-strategy.md:68-70`): `list-capabilities`
  (`declare-list-capabilities.sql`), `read-capability-meaning`
  (`declare-read-capability-meaning.sql` + `select-scenario-in-declared-meaning.sql`),
  `read-retained-publication` (`declare-read-retained-publication.sql`). Add the
  operation rows that the CLI mapping used to carry (`config/sfx.commands.json`)
  to the declared delivery, and remove `prepare`/`materialize` if any remain.
- **Acceptance:** the kernel carrier offers every live operation from rows; no
  operation vocabulary exists in `config/sfx.commands.json`.
- **Verification:** `sql/inspect/hand-authored-module-references.sql` reports no
  module references; each operation returns its declared read's result.

### U5 — Rebase lifecycle scripts and tests on the kernel ground

- **Scope:** `scripts/run-query.mjs`, `scripts/run-migration.mjs`,
  `scripts/invoke-from-transaction.mjs`, `scripts/extract-inflight-bundle.mjs`,
  `scripts/verify-timing-coherence.mjs`, `tests/timing-coherence.test.mjs`,
  `tests/demo-acceptance.test.mjs`, `tests/credential-vault-realization.test.mjs`,
  `tests/database-read-session.integration.test.mjs`,
  `tests/execution-drilldown.test.mjs`, `tests/semantic-address.test.mjs`,
  `tests/invocation-read.test.mjs`, `config/database-runtime.json`,
  `config/regression.cases.json`.
- **Replacement:** import the U1 in-tree ground and the kernel's
  `withDatabaseReadSession`; delete `DATABASE_ROOT`/`SIDEFX_DATABASE_ROOT` and
  `SIDEFX_SDA_ROOT`; `config/database-runtime.json` becomes the kernel boot file
  (`sdaRoot` + connection env var name/timeouts/row limits) and drops
  `databaseRoot`; `config/regression.cases.json` drops `databaseRoot`.
- **Acceptance:** no estate script/test/import names a DB repo path; migration
  dry-run, preflight transaction, and timing receipt run green.
- **Verification:** `npm test`; one rollback migration followed by an install;
  `npm run verify:timing`.

### U6 — Delete the CLI contract files from the composite

- **Scope:** `sfx.config.json` (whole file), `config/sfx.commands.json` (whole
  file), and any residual `SIDEFX_ESTATE` / `SIDEFX_HOME` / `SFX_PREFLIGHT_*`
  references.
- **Acceptance:** no composite file binds a CLI process, mapping, estate root, or
  read allowlist; the kernel entry is the only composite surface.
- **Verification:** grep `sfx.config.json|sfx.commands.json|SIDEFX_ESTATE` outside
  historical classes = 0.

### U7 — Re-point every prescription at the kernel entry

- **Scope:** `AGENTS.md`, `sql/README.md`, `.opencode/skills/**`,
  `.claude/skills/**`, `docs/target-architecture.md`,
  `docs/implementation-strategy.md`, `docs/next-experiences.md`,
  `docs/database-direct-invocation.md`, `docs/database-preparation.md`,
  `docs/demo-command*.md`, `docs/capability-command-surface.md`, all remaining
  non-historical docs from §1.1, and the CLI-mention comments in
  `sql/migrations/*.sql`.
- **Replacement:** the kernel entry command (from U2) in every verification and
  lifecycle instruction; a note that `sidefx-cli` is an optional standalone
  surface and `sidefx-database` standalone tooling; the `--display`/presentation
  flow described as the declared display projection delivered by the kernel, with
  terminal rendering explicitly optional.
- **Acceptance:** no non-historical composite doc requires installing or
  configuring `sidefx-cli`, and none points the reader at `sidefx-database` for
  a composite read.
- **Verification:** re-run the §1.1/§1.2 sweep; every remaining hit must carry an
  H classification.

### U8 — Decouple the two repos' own surfaces

- **`sidefx-cli` (read-only from this audit):** keep grammar, SDK and
  `src/render.mjs` as a standalone terminal. Remove or mark historical the
  `sfx-embody` acceptance section (`CLI:docs/process-delivery.md:88-109`) and the
  estate-specific claims in `CLI:README.md:10-13`. A user who wants the CLI can
  point its *own* local process binding at the kernel entry; that binding is not
  shipped or prescribed by the composite.
- **`sidefx-database` (read-only from this audit):** keep its standalone
  inspection/ingest/migrate tooling and `sql/diagnostics/` for its own purposes.
  Correct `DB:README.md:87-94` (the "independent `sfx-embody` provider consumes
  this query" claim) when the composite stops doing so.
- **Acceptance:** deleting or renaming either checkout does not change any
  composite invocation outcome.
- **Verification:** move both checkouts aside and run the U2 entry end to end.

---

## 4. The irreducible ground and where it lives

Per [target-architecture.md](target-architecture.md) exactly three mechanics are
irreducible. Under this ruling their home is fixed:

| Irreducible | Proof | Home after this strategy |
|---|---|---|
| **Frontdoor / loader** | regress, `target-architecture.md:38-45` | **Kernel bootstrap, per language** (`SDA:languages/typescript/src/kernel/bootstrap/invocation-boot.mjs` + `declared-operation-carrier.mjs`), exposed through the U2 physical entry. Not the estate, not the CLI. |
| **DB connection / query runner** | circularity, `target-architecture.md:47-52` | **Kernel bootstrap** (U1), in-tree: driver, connection resolution, pinned session, query runner, model pin. The **SQL Server database itself and its connection string** remain external config/declaration store — not either repo. |
| **Bootstrap installer** | regress, `target-architecture.md:54-59` | **Estate lifecycle script** using the kernel ground (U5): `scripts/run-migration.mjs` stays; the migration `.sql` stays estate authority. A per-language kernel installer primitive follows U1 when a language is admitted. |

Everything else on these edges is either declared data (rows) or the carrier
(the U2 entry). There is no fourth place.

---

## 5. What can stay

- **`sidefx-cli` — standalone terminal surface.** Its grammar, SDK, renderer,
  provider catalog and standalone process bindings are its own product. It must
  not be referenced by composite config, scripts, tests, or acceptance
  instructions, and it must not be an installation prerequisite.
- **`sidefx-database` — standalone tooling.** Its inspection database, loaders,
  migrations, diagnostics and `npm run query` remain for its own operation. It
  must not be imported, path-addressed, or config-pointed by the composite.
- **`sda-bootstrap`** is neither repo; if the composite later ships a packaged
  bootstrap it is kernel platform packaging (transistor-model §6), not a role for
  the CLI.
- **Historical bytes stay untouched:** `baselines/**`, `evidence/**`, `build/**`,
  `embodiments/**`, `docs/verification/**`, `docs/research/**`, and
  `package-lock.json` keep their old paths as retained evidence. They are never a
  compliance surface.

## 6. Builder decisions recorded here

1. The DB connection/query runner is an irreducible mechanic and its home is the
   kernel bootstrap. `target-architecture.md:189-190` and
   `transistor-model.md:18-19` are superseded.
2. The physical carrier (entry, argv, streams, telemetry, exit map) is kernel
   resolver-surface code, per language. The CLI is not the composite's carrier.
3. `sfx.config.json` and `config/sfx.commands.json` are CLI-format files; the
   composite deletes them, and the operation vocabulary lives in declared rows.
4. The two repos are not edited or deleted by this strategy; their own standalone
   tooling remains, with the composite coupling removed.
5. Historical/research bytes are not rewritten; the rule applies to live code,
   config, tests, and prescriptive docs.

## 7. Audit evidence (re-runnable)

Read-only sweep, 2026-09-17. Commands and expected counts (excluding
`node_modules`, `.git`, `evidence`, `baselines`, `build`, `embodiments`,
`package-lock.json`):

- `sidefx-cli` in `sfx-embody` → 57 hits, all §1.1 (none in live code).
- `sidefx-database` in `sfx-embody` → 83 hits, D1-D19 + docs.
- `sfx (capability|provider|estate|scenario|execution|capsule)` in `sfx-embody`
  → >200 hits across the §1.1 doc list and SQL comments.
- `SIDEFX_` in `sfx-embody` → 12 hits: `scripts/run-query.mjs:9`,
  `scripts/run-migration.mjs:21`, `scripts/verify-timing-coherence.mjs:194-195`,
  `src/database-delivery.mjs:45`, plus doc/evidence mentions.
- `sidefx[-_]cli|sidefx[-_]database` in `scenario-driven-architecture` → only
  `docs/transistor-model.md:18-19,290`; the DB reach is by `databaseRoot`
  (D16-D20).
- `databaseRoot` in `SDA:languages/typescript/src/kernel/bootstrap` →
  `authority-read.mjs:24,27`, `declared-operation-carrier.mjs:57`,
  `invocation-boot.mjs:80-88,132,135`, `process-restriction.mjs:10-13`,
  `runtime-configuration.mjs:9-11`.

No commits were made; the audit changed no file except this document.
