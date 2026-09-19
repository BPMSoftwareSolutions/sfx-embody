# The achieved architecture: the estate as declarations, the installed kernel as the executor

**Status.** Recorded 2026-09-18 at estate `b9d045a` ("Switch the estate to the
installed C# kernel executable"). This is the durable statement of **what now holds**, as distinct
from [target-architecture.md](target-architecture.md) (what the target is) and
[transistor-model.md](transistor-model.md) (the primitive law). Where a later
question about the current shape arises, it is answered here, not re-litigated
per file.

**What "achieved" means here.** A claim is *achieved* only when it is either
(i) a tracked commit, a tracked row/migration, or an installed artifact whose
digest is recorded, or (ii) an observed live run on this host
(Windows x64, .NET SDK 10.0.202). Every other claim is *owed* and is named as
owed in §9. Receipts under `evidence/` are local-only (`.gitignore:4`); commit
messages and this document carry the digests.

**Citation roots.** Unprefixed paths are this repo (`sfx-embody`). `SDA:` names
the scenario-driven-architecture project for citation only — it is not a
dependency of this estate, and the estate's relationship to it is the installed
`KernelEntry.exe`, never a checkout. Agents must not edit `SDA:`; cross-language
changes are requests (see [transistor-model.md](transistor-model.md) §10).

The former `DB:` and `CLI:` roots are **retired**. `sidefx-database` and
`sidefx-cli` have no role in this estate and must not be referenced by any path
spelling; §1.6 records the zero-edge state and
[the dependency law](../AGENTS.md) forbids reintroducing either. Historical
mentions below and in the research record are narrative, not live roots.

**Evidence policy.** The primary receipt for the achieved install is
`evidence/vault-20260916/csharp-seams/` (receipt JSON, install/verify/switch
outputs, live invoke/observe captures, the vault-only environment audit, and the
C# conformance suite output). It is a local working-tree receipt; the equivalent
facts are restated in the commit message of `b9d045a` and in the installed
kernel's own `kernel-install-manifest.json` / `kernel-install-receipt.json`.

---

## 1. The shape

The composite is **declared meaning + a digest-pinned installed executor**:

```
estate (config + SQL migrations + docs + evidence)
        │  sfx.config.json selects the installed kernel executable (host data)
        ▼
installed kernel executable  ──  manifest + digest admitted, per-OS build
        │  reads declared authority over one pinned DB read session
        ▼
declared authority (rows)  ──  database is the meaning store
        │  interpreted in process by
        ▼
per-language resolvers (0) in the SDA kernel  ──  no estate code on the path
        ▲
        └── credentials applied from the OS-backed vault (never in rows/env/talk)
```

### 1.1 The estate is config, SQL, docs and evidence

The execution trees are gone, not relocated: `src/` (commit `af69dfb`), `scripts/`
(`92b79e8`, U5c), `tests/` (`52133f9`), `providers/`, `embodiments/`, `baselines/`
(`6e3d146`, `6c6b960`). The tracked repository is:

| Surface | Contents | Evidence |
|---|---|---|
| `sfx.config.json` | `sfx-project.v1`; two process deliveries, both naming the installed kernel executable | config today; `b9d045a` diff |
| `config/` | `database-runtime.json` (now only `{"configurationType":"sfx-database-memory-runtime.v1"}`), `regression.cases.json` (no `databaseRoot`), `sfx.commands.json` (CLI operation vocabulary) | `52133f9` |
| `sql/schema/` | 6 installed, idempotent model objects (authoring procedures, declaration views, selection views) | `git ls-files sql/schema` |
| `sql/migrations/` | 180+ one-off declaration migrations; each is one unit of change | `git ls-files sql/migrations` |
| `sql/inspect/` | 4 read-only inspection queries, including `hand-authored-module-references.sql` | `git ls-files sql/inspect` |
| `examples/`, `features/`, `scaffolds/`, `build/` | authoring inputs and review artifacts | `git ls-files` |
| `docs/` | this record and the document map in §8 | — |
| `evidence/` | local receipts (gitignored) | `.gitignore:4` |

**No estate execution code.** The tracked executable census is one research
mechanism, not product surface:

```
git ls-files | Where-Object { $_ -match '\.(mjs|js|cjs|ts|tsx|py|cs|java|go|cpp)$' }
→ docs/research/ml-opportunity/collect-evidence.mjs
```

That file is a research/authoring mechanism with no home in the composite
([sda-tools-uid-homing.md](sda-tools-uid-homing.md) §9: move to the Agentic
Harness or delete). `package.json` carries no `scripts` block (`52133f9`).

### 1.2 The executor is an installed kernel executable selected as host data

`sfx.config.json` selects it, with no `scenario-driven-architecture` path and no
read grant in either delivery (`b9d045a`):

```json
"database-memory": {
  "type": "process",
  "command": "C:\\Users\\Sidney Jones\\AppData\\Local\\sfx\\kernel\\59d6030f…\\KernelEntry.exe",
  "cwd":     "C:\\Users\\Sidney Jones\\AppData\\Local\\sfx\\kernel\\59d6030f…",
  "args": ["--stdin-envelope", "--config", "kernel-host.json"]
}
```

The install is admitted by manifest and digest, not by path trust
(`evidence/vault-20260916/csharp-seams/installed.kernel-install-manifest.json`):

| Field | Value |
|---|---|
| `kernelLanguage` / `rid` | `csharp` / `win-x64` |
| `artifactDigest` | `sha256:59d6030fbc4cb5ee7d8316c675281e6ba5c790eada03ec7ec5324385737138c6` |
| `manifestDigest` | `sha256:944a20e26bf7207eef65800b31398d37e105121c8c34e04b08d4660d7ed85fc1` |
| `sdaRevision` / `sourceState` | `9b7731428680d88d094bafa5ae42cafa653e2028` / `working-tree` |
| `carrierContract` | `sfx-command-delivery.v1` (closed envelope on stdin, `--stdin-envelope`) |
| `observationChannel` | `{stream: stderr, prefix: SFX_OBSERVATION, status: OFFERED}` |
| `vaultRealization` | `windows-credential-store-provider` / DPAPI/CNG / `%LOCALAPPDATA%\sfx\vault` / `OBSERVED` |
| `parity` | `say-hello-world`: `20864ba2…`, `8b859397…`, `f7655bd9…` |

`kernel-host.json` beside it is `{"configurationType":"sfx-database-memory-runtime.v1","sdaRoot":"."}`
— the installed tree is the kernel root. The installer is resolver (0):
`KernelEntry.exe install|verify|switch` are its own commands, outside the declared
operation surface (`SDA:languages/csharp/src/ScenarioKernel/bootstrap/KernelEntry.cs:96-101`).
The manifest's `sourceState: "working-tree"` records that the install was admitted
with concurrent writers present; the seam files it was built from were committed
as SDA `9b77314` and `3103eed` immediately after.

### 1.3 Declared authority lives in the database

Every invocation reports `authoritySource: "DATABASE"` (hello and equity captures
under `evidence/vault-20260916/csharp-seams/acceptance.invoke-*.stdout`). The
kernel reads the estate's own views (`analysis.v_capability_graph_source`,
`analysis.v_capability_execution_declaration`) and the declared boot authorities;
the declared graph is `analysis.capability_graph_source` (scenarios,
executionAuthorities, transitions/routing, port bindings), compiled in process.
The authority tables and views are built by `sql/schema/` + `sql/migrations/`.

### 1.4 Resolvers (0) live in the SDA kernel

Six languages declare graph-ADMITTED kernels
(`SDA:conformance/execution-graph/language-graph-v1-conformance.json:6-43`); the
physical entries are `SDA:languages/typescript/src/kernel/bootstrap/entry.mjs`,
`SDA:languages/python/src/scenario_kernel/kernel/bootstrap/entry.py`,
`SDA:languages/csharp/src/ScenarioKernel/bootstrap/KernelEntry.cs` (SDA
`9ff6dc0`). The estate's projection surface admits `node | python | csharp`; the
achieved install on this host is the C# entry (§5). No estate behavior executes
outside those resolvers.

### 1.5 The vault supplies credentials

The five installed credential authorities are `source: "vault"` with a declared
locator ([vault-manager-capabilities.md](vault-manager-capabilities.md) §6 V3,
estate `switch-credential-authorities-to-vault.sql`). The switch acceptance ran
with `DB_CONNECTION_STRING`, `RAPID_API_KEY`, `LOC_OPENAI_API_KEY`,
`LOC_GEMINI_API_KEY` and `sidefx-connection-string` **absent** from the process
environment (`evidence/vault-20260916/csharp-seams/vault-only.env-audit.txt`),
and the equity and agent-lane invocations resolved through the vault.

### 1.6 No `sidefx-cli` / `sidefx-database` role in the composite

- **Code/config edges: zero.** `git grep sidefx-cli -- . ':!docs' :!*.md`
  returns nothing; `git grep sidefx-database -- . ':!docs' :!*.md` returns one
  historical comment (`sql/migrations/declare-read-retained-publication.sql:6`);
  tracked `databaseRoot` references are zero.
- **No runtime dereference of sibling repos.** The K1 provider-authority rows
  retain authority bytes with content digests and record `sourcePath`/`locators`
  as provenance only; the kernel boot read `provider-authority` resolves the
  digest over row content (`sql/migrations/declare-provider-authority-rows.sql`
  header). The K2 migration removes the four invocation-path `bindingRef`s into
  the SDA capabilities tree (`sql/migrations/compose-declared-consumer-bindings.sql`
  header, estate `49ab9a1`). Where DB rows still name per-language module paths in
  `configuration.providers`, the kernel's registry-resolved scheduler-provider map
  is what executes, so no other runtime or module is imported
  (`evidence/vault-20260916/csharp-seams/receipt.json`,
  `noNodeDelegation`).
- **The CLI is a standalone front end, not a composite dependency.** The kernel
  carrier is directly invocable with the same envelope. The delivered
  `sfx.config.json` and `config/sfx.commands.json` are the CLI's project format
  and remain the current host-selection/terminal vocabulary; their deletion (U6)
  is owed, recorded in §9 as the carrier residual.

---

## 2. The transistor discipline applied

The law (verbatim, [transistor-model.md](transistor-model.md) §1): *"declared
authority (1), which specifies executable meaning and configuration; or an
admitted resolver boundary (0), which embodies irreducible native mechanics."*
There is no third state; projected executables are embodiments of declared
authority, not a third source.

### 2.1 The binary, as the estate now holds it

| State | What it is | Where it lives now | Estate evidence |
|---|---|---|---|
| **0 resolver** | hand-authored native mechanics that interpret declarations | per-language SDA kernel (entries, scheduler, providers, effect ports, DB ground, vault realizations); the bootstrap installer | `SDA:languages/**`; install receipts |
| **1 declared** | language-invariant rows/JSON | `sql/schema/`, `sql/migrations/`; read by the kernel at invocation | `authoritySource: DATABASE` |

**Boot is resolver (0).** Builder clarification, recorded verbatim in
[hand-authored-code-retirement.md](hand-authored-code-retirement.md): *"Boot is
resolver (0)"* and the boot class is *"frontdoor/loader, DB query runner,
bootstrap installer (the irreducible three)"* plus *"delivery/workspace config
(`read-workspace-config`) (boot config)"*. The boot now physically lives in the
SDA kernel (M0), not the estate.

### 2.2 The irreducible three and their achieved home

| Irreducible | Proof | Achieved home |
|---|---|---|
| Frontdoor / loader | regress ([target-architecture.md](target-architecture.md):38-45) | per-language kernel entry + declared operation carrier (`SDA:languages/*/…/bootstrap/entry.*`), exposed as the installed executable |
| DB connection / query runner | circularity ([target-architecture.md](target-architecture.md):47-52) | kernel bootstrap connect boundary + pinned read session, in-tree (`SDA:languages/typescript/src/kernel/bootstrap/database-connect-boundary.mjs`, `database-read-session.mjs`) |
| Bootstrap installer | regress ([target-architecture.md](target-architecture.md):54-59) | kernel installer per language (`KernelEntry.exe` install / verify / switch; `kernel-install.mjs`; `kernel_install.py`) + the migration runner (`run-migration.mjs`) |

### 2.3 Eliminated classes (deleted, not ported)

[target-architecture.md](target-architecture.md) Disposition and
[hand-authored-code-retirement.md](hand-authored-code-retirement.md):

- **domain resolvers** (`src/resolvers/node/*.mjs`) → declared capabilities,
  resolved by kernel mechanics; files deleted (`af69dfb`).
- **materialization** (`materialize-node`, `prepare-database-capability`,
  `load-memory-scenario`, `load-consumer-plan`, `read-execution-graph`,
  `reveal-native-expressions`, `embodiment-delivery`) → eliminated; no
  materialization on the invocation path (`6e3d146`).
- **native-body verification** (`verify-node`, `verify-native-projection`,
  `verify-contract-fidelity`) → eliminated with the artifacts (`6c6b960`,
  `52133f9`).
- **UID meaning and verification files** (`execution-drilldown`,
  `semantic-address`, `observation-filter`, timing/projection probes) → declared
  readings/receipts, then deleted (`hand-authored-code-retirement.md`; `92b79e8`;
  probes homed in SDA `conformance/`).
- **one-time units** (scaffold bootstrap, credential transition,
  `publish-projected-bodies`) → deleted with receipts (`fef8738`, `92b79e8`).

### 2.4 The single ground read (proof by circularity, realized)

You cannot read the declaration that declares the reader, so the DB
connection/query primitive is the ground. The achieved ground is one pinned
session per invocation: hello reports `readSession: {connections: 1, pins: 1,
readerSwitches: 1, queries: 8}` and reads the declared authorities
`capability-authority`, `capability-closure`, `mechanic-definitions` over the
kernel boot read (`SDA:languages/typescript/src/kernel/bootstrap/data-access.mjs`,
one fixed statement). The estate-side proof that the sibling-repo ground is gone:
`rg -n "sidefx-database|databaseRoot|SIDEFX_DATABASE_ROOT" SDA:languages/typescript/src/kernel/bootstrap`
= 0 hits ([estate-script-severance.md](estate-script-severance.md) §1), and the
tracked estate has zero `databaseRoot` references.

### 2.5 Authority-as-rows (the three named surfaces)

| Surface | Declared as rows | Migration |
|---|---|---|
| **command vocabulary** | kernel boot data-access + command-operations authorities, retained byte-for-byte under content digests; the carrier resolves its vocabulary through the declared `provider-authority` read | `sql/migrations/declare-kernel-boot-authority-rows.sql` |
| **data access** | every read the kernel boot performs is declared in the data-access authority; runtime executes one fixed statement against those rows | same migration; `SDA:…/bootstrap/data-access.mjs` |
| **provider authorities** | the seven SDA platform provider authorities as estate AUTHORITY rows with byte content digests and recorded provenance | `sql/migrations/declare-provider-authority-rows.sql` (K1, `49ab9a1`) |
| **consumer bindings** | four invocation-path ports re-declared as `configuration.declaredApplication`; zero `bindingRef`s into the SDA capabilities tree on the invocation path | `sql/migrations/compose-declared-consumer-bindings.sql` (K2, `49ab9a1`) |
| **execution delivery** | the delivered operation vocabulary is an `execution-delivery` provider row, not estate code | `sql/migrations/bind-declared-execution-delivery.sql:26` |

### 2.6 UID ledger status (what remains grey, with pointers)

*UID = ungoverned intelligence debt: executable meaning outside declared rows.*

**Estate side: closed as a product surface.** The 28-file inventory
([hand-authored-code-retirement.md](hand-authored-code-retirement.md)) is
retired: `src/`, `scripts/`, `tests/`, `providers/`, `embodiments/`, `baselines/`
are gone. The single tracked executable is the research script named in §1.1.

**SDA tools side: open, with an ordered ledger.**
[sda-tools-uid-homing.md](sda-tools-uid-homing.md) classifies 461 hand-authored
files. M0 (boot homed in the kernel) landed at SDA `9ff6dc0`, `9b77314`,
`3103eed`; M1 (database-artifact materialization target) was reverted in SDA M1
([estate-script-severance.md](estate-script-severance.md) §1.1); M2 (home
the projector) is blocked — `SDA:governance/projector-surface-freeze.policy.v1.json`
records `homing.status: BLOCKED` pending an admitted bootstrap compiler
(ADR-0014). F1/F3/F4/F5/F6/F7 remain: 23 projector/host/enterprise files and 95
test/verification harness files. G1/G2/G5/G10 remain open
([transistor-model.md](transistor-model.md) §7.2, §10).

**Circuit/display side: partially declared.** In
[implementation-plan-circuit-view.md](implementation-plan-circuit-view.md) §"UID
audit": policy constants and glyph/box metrics are now declared
(`read-circuit-presentation`), but declared per-component text fragments (CV-B)
are pending, `circuitLabel`/collapse derivation is deferred to CV-C2, and frame
characters, branch markers and section labels remain emitter vocabulary. The
CLI renderer (`render.mjs`) is outside the composite and is the C2 retirement
target.

---

## 3. The governed model harness

The agent lane is a **declared capability**, `request-capability-from-objective`
(estate `d89b7f9`; `sql/migrations/declare-agent-capability.sql`), with routing
declared in `sql/migrations/emit-declared-routing.sql` and proven by
`sql/migrations/declare-two-child-routing-proof.sql`. The driver
(`src/agent-delivery.mjs`) and its `agent-memory` delivery are deleted; the
composition is rows ([agent-lane.md](agent-lane.md)).

### 3.1 The declared chain

```
objective (typed input)
  → build-agent-model-request        (declared prompt + visible set + proposal schema)
  → obtain-governed-model-response   (composed child; governed model invocation)
  → resolve-proposed-capability      (declared read: proposed {capability, input} vs estate)
  → ADMITTED  → execute the admitted capability (its own provider-attributed evidence)
    REFUSED   → refusal child (agent-refusal-evidence.v1), CAPABILITY_NOT_FOUND, zero cells
```

### 3.2 The three observed beats (2026-09-17 receipts)

```powershell
sfx capability observe resolve-equity-market-price-evidence --display --input AVGO
sfx capability invoke  request-capability-from-objective --input "What is Broadcom's current market price?"
sfx capability invoke  request-capability-from-objective --input 'Buy $1,000 worth of Broadcom.'
```

- Beat 1: outcome `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`; the story streams the
  ten declared operations and the primary-429/fallback-answer testimony.
- Beat 2: the model proposes `resolve-equity-market-price-evidence` with `AVGO`;
  the declared route admits it; terminal outcome is the provider-attributed
  evidence (`rapidapi/yahoo-finance-real-time1`).
- Beat 3: the model proposes `execute-equity-trade`; the declared route refuses
  it **by absence**: `CAPABILITY_NOT_FOUND`, the admitted child runs zero cells,
  no provider is reached, no effect exists.

The installed-kernel re-acceptance (2026-09-18, C# executable) ran the lane
through `observe`: `completed` / `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`,
`observedPathDigest sha256:26c85c04…fb73`, 716 cell testimony entries, live
payload AVGO 354.15 USD (`evidence/vault-20260916/csharp-seams/receipt.json`).

### 3.3 The statement, plainly

**Models never enter the execution authority and cannot reason outside a
governed lane. The model proposes; declared rows decide and execute.** What the
model can see is the declared visible set in `build-agent-model-request`; its
response is untrusted testimony. Resolution is a declared read, execution choice
is declared routing, refusal is the honest absence of a declared execution path
(no grant model exists yet, so no policy DENY is claimed). Outcome meaning and
physical provider testimony are kept distinct: the provider identity
(`rapidapi/yahoo-finance-real-time1`) is testimony; `sourceAttribution`
("Delayed Quote") is semantic payload.

---

## 4. Scaling capability creation

### 4.1 The unit of work

One capability is one coordinated, data-only unit
([sql/README.md](../sql/README.md), [AGENTS.md](../AGENTS.md)):

1. **Evidence first.** Capture the working generation for the capability
   (`evidence/<capability>/…`); a regression is a diff against a generation that
   worked.
2. **Declare contracts, scenarios, operations, transformations, ports and
   provider bindings** in one migration under `sql/migrations/`, authored through
   the installed procedures: `model.scaffold_capability`,
   `model.configure_contract`, `model.configure_interface`,
   `model.add_mechanic` / `model.configure_mechanic`,
   `model.add_provider` / `model.configure_provider` / `model.bind_provider`,
   `model.normalize_transformation_expression`,
   `model.scaffold_estate_provider_capability`,
   `model.scaffold_composed_capability`, `model.author_capability_meaning`
   (`sql/schema/authoring-procedures.sql`); or via the JSON surface
   `model.declare_capability_document` ([json-authoring-surface.md](json-authoring-surface.md)).
   Composition is `invoke-scenario` with mapped contracts, not code.
3. **Dry-run** (no writes):
   `node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/run-migration.mjs sql/migrations/<file>.sql`
4. **Preflight from the uncommitted state:**
   `node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/invoke-from-transaction.mjs sql/migrations/<file>.sql <capabilityId> <input.json>`
   The migration is applied but rolled back; the read path plans and executes.
   Never commit a migration that has not passed this.
5. **Install:** flip the final `ROLLBACK` to `COMMIT` and re-run the migration
   runner; one migration per commit.
6. **Verify through the real surface:**
   `sfx capability invoke <identity> --input … --json` (and `observe` where a
   stream matters); exit 0 and the intended disposition, or it is not done.
7. **Project for review/publish** where a client artifact is wanted:
   `sfx capability project <identity> --workspace <dir> --targets csharp --full-mechanics`
   (served by the Node kernel ground; see §6.3); install per §5.
8. **Retain evidence** under `evidence/` and cite the digests in the commit.

### 4.2 Why it is data-only

- The boot is fixed: the only executable elements are the kernel resolvers, the
  installed installer, and the declared providers behind mechanics
  ([target-architecture.md](target-architecture.md)).
- Adding a mechanic is an SDA change; binding one is data
  ([transistor-model.md](transistor-model.md) §3.1). Adding a language adds
  resolvers, never a language-specific declaration.
- The measured flywheel: capability B (`read-declared-capability-document`) was
  authored from T0 to a verified CLI invocation in **95 seconds, zero failed
  attempts**, reusing A's authoring surface ([flywheel-proof.md](flywheel-proof.md)).
  Scope limit, recorded: proven for the declared-read JSON shape; not proven for
  pure-mechanics or provider-backed capabilities, and install ceremony did not
  get cheaper.

---

## 5. Governance-as-a-service / download-and-install

### 5.1 The install contract

- **Installer commands** (resolver (0)): `KernelEntry.exe install|verify|switch`
  (`SDA:languages/csharp/src/ScenarioKernel/Install/`); per-language equivalents
  exist (`SDA:languages/typescript/src/kernel/install/kernel-install.mjs`,
  `SDA:languages/python/src/scenario_kernel/kernel/install/kernel_install.py`).
- **Manifest** `sfx-kernel-install-manifest.v1` (schema shipped by the
  installer): language, host OS/arch, RID, entry point and args, carrier
  contract, observation channel, SDA revision, publish command, `artifactDigest`
  (SHA-256 over `path<TAB>hash` lines), `manifestDigest` (SHA-256 of the
  manifest with that field removed), vault realization, parity triple,
  conformance receipt ([kernel-install-matrix.md](kernel-install-matrix.md) §2).
- **Admission and pinning**: recompute `artifactDigest`; `manifestDigest` must
  match the value pinned by the host record; the parity triple must equal the
  recorded fixture; the SDA revision must be pinned (dirty source is refused).
  Replays re-run `publishCommand` at `sdaRevision`; a mismatch is
  `KERNEL_BUILD_DIGEST_MISMATCH` and fails closed. **Admitted directories are
  never mutated**; changing an admitted build means a new digest-named directory
  and a new pinned `manifestDigest` ([kernel-install-matrix.md](kernel-install-matrix.md) §3).

### 5.2 The observed install (this host)

`install` emitted `INSTALLED`; `verify` emitted `VERIFIED`; `switch` rewrote the
two estate deliveries to the executable and reported the digests; the live
acceptance passed vault-only (§1.2, §1.5). The install ran with `--allow-dirty`
(`sourceState: working-tree`, concurrent writers admitted), recorded as such in
the manifest and receipt; the admitted artifact is pinned by digest, not by
source cleanliness. Receipts:
`evidence/vault-20260916/csharp-seams/install.csharp.out`,
`verify.csharp.out`, `switch.csharp.out`, `receipt.json`. C# conformance at the
seam revision: `dotnet test …` → **181 pass / 0 fail**
(`conformance.csharp-suite.out`).

### 5.3 Per-OS matrix and selection as data

The build is one declared kernel; only the language build and RID differ
([kernel-install-matrix.md](kernel-install-matrix.md) §1). Data layers: the host
record (`sfx-project.v1` deliveries today, digest-named install root), the
kernel boot config (`kernel-host.json`), and the declared vault realization.
Language is a manifest field, never a caller branch; a host with no admitted
manifest walks the declared fallback chain. Achieved: `win-x64` installed and
live. Owed: macOS arm64/x64 and Linux x64/arm64 publishes, live invokes, observe
parity and vault realizations; see §9.

### 5.4 Why governance cannot drift

- **Meaning is rows.** The executable interprets declared authority; it does not
  contain capability meaning. Changing what a capability does is a migration.
- **The interpreter is versioned by digest.** The installed executable is
  admitted by `artifactDigest` + pinned `manifestDigest` + `sdaRevision`;
  behavior changes only by installing a new digest and re-switching. A replay
  mismatch fails closed.
- **The projection tool surface is frozen.**
  `SDA:governance/projector-surface-freeze.policy.v1.json` pins the consumer
  projector surface (9 files, 4,004 mechanic counts at `0bff62b`) with
  `surfaceListIsClosed: true`; additions/growth are rejected
  (`PROJECTOR_SURFACE_EXPANSION`, `PROJECTOR_MECHANIC_GROWTH`), and declaring
  tooling as a resolver boundary is `PROJECTION_TOOLING_DECLARED_AS_RESOLVER_BOUNDARY`.
- **Intent alignment is declared, not prompted.** Capability meaning, authority,
  contracts, visible sets, credential scopes, endpoint digests and routing are
  rows. A changed intent is a diffable migration, and invocation testimony shows
  which declared cells executed.

---

## 6. Executable meaning and multi-OS projection

### 6.1 One declared graph, digest parity

The declared graph is language-neutral; each target realizes it. The proof
obligation is: same `canonicalGraphDigest`; per-target `realizedGraphDigest`; and
for an identical declared execution, the same `observedPathDigest`
([embodiment-completeness.md](embodiment-completeness.md) §"The proof";
[sda-change-request-projected-testimony.md](sda-change-request-projected-testimony.md)).

Recorded parity facts:

| Fixture | canonical | realized | observed | Where |
|---|---|---|---|---|
| `say-hello-world` | `sha256:8b859397…4931` | `sha256:f7655bd9…72de` | `sha256:20864ba2…70ba` | installed manifest `parity`; captured invoke |
| equity (C#) | `sha256:2f92d057…0493` | `sha256:122f5e96…5791` | `sha256:c507678e…79eb` | `csharp-seams/receipt.json`; live AVGO payload |
| agent lane observe | `sha256:a2f886ef…ef67` | `sha256:61e1b3fa…e1a8` | `sha256:26c85c04…fb73` | observe capture; equals the Node-era digest in [estate-script-severance.md](estate-script-severance.md) §6 |

The `csharpEquityParity` seam receipt records the divergences that had to be
fixed to reach Node parity (vault locators resolved into compiled graph source,
ordered string collation, the `junction:boolean-selection.v1` TRUE/FALSE
variant, canonical CLI input) and their fix; the `PROVIDER_BINDING_DIVERGENCE`
seam records the native C# body that replaced the node-projected invocation
port with no Node runtime imported.

### 6.2 Testimony is the observed-path evidence

Every projected target now stamps `startedAt` / `completedAt` /
`durationMilliseconds` on every cell/edge/pattern record and emits
`observedPathDigest` plus `resolverTestimony` (SDA `a696fdd`, `0bff62b`;
closure probe `SDA:conformance/projected-testimony/verify-projected-testimony.mjs`).
Canonical cell ids, occurrence parity and the digest subject are specified in
[sda-change-request-projected-testimony.md](sda-change-request-projected-testimony.md)
§1. Remaining gap (recorded, not simulated): on the equity fixture, python
testimony still carries semantic-normalized `cellId`s and the walkers record
different cell granularities, so cross-target set equality is asserted on the
shared chaining fixtures instead; see §9.

### 6.3 Projection targets are data; projection is tooling

`capability project` is authoring/publish tooling, not per-language kernel
execution (`SDA:docs/projection-lifecycle-carrier-disposition.md`): the admitted
consumer projector (frozen TypeScript artifact) is served once through the Node
kernel ground; the C# carrier refuses with
`PROJECTION_LIFECYCLE_NOT_OFFERED_BY_CARRIER:csharp` before opening a database
session, and Python refuses with the same code for `python`. No non-TypeScript
kernel reimplements the projector or delegates to another runtime. Workspace
targets (`--targets`) and emitters are declared/selected as data
([capability-command-surface.md](capability-command-surface.md):202-240;
[projected-csharp-install.md](projected-csharp-install.md)).

### 6.4 Projection freeze discipline

Projected artifacts are embodiments of declared authority, never a third source
of meaning ([transistor-model.md](transistor-model.md) §1). The discipline that
keeps them from drifting: the projector surface is closed and frozen (§5.4); a
projected body is review/publish output off the invocation path
(`target-architecture.md` "No materialization"); installed artifacts are
digest-named and immutable (`kernel-install-matrix.md` §3); and re-projection is
a deliberate, recorded act, not a hot-path side effect. Projection status
receipts (e.g. `PURE_PROJECTION_CONFORMS`, canonical digest) are retained with
the generated artifact, not hand-edited.

---

## 7. Trust and evidence

### 7.1 Vault-only credentials

The credential contract is `sda-credential-vault-port.v1` (`store` / `apply`; no
`reveal`): the outcome of resolving a credential is *credential applied to an
authorized provider invocation*. The vault ciphertext lives under
`%LOCALAPPDATA%\sfx\vault`; the unwrap key is released by the OS keystore
(DPAPI/CNG on Windows) and never co-located with the ciphertext — the two-roof
split ([vault-manager-capabilities.md](vault-manager-capabilities.md) §4).
Plaintext exists only inside the provider call and the exchange-header
injection, once, in one process. The installed acceptance for this host ran with
all credential environment variables absent (§1.5).

### 7.2 Non-disclosure receipts

The one-use opaque binding plus `nonDisclosureVerified` is the evidence shape.
V4's sentinel sweep verified the sentinel absent from invoke `--json`, observe
`--trace` and the observation stream, `evidence/`, and the durable objects; the
tampered store failed AES-GCM authentication (`CREDENTIAL_NOT_AVAILABLE`);
receipts under `evidence/vault-20260916/non-disclosure/` at the time
([vault-manager-capabilities.md](vault-manager-capabilities.md) §6 V4).

### 7.3 Timing coherence (IEA)

IEA = streamed gap minus attributed cell/delivery time; a positive unattributed
delta names work with no declared cell ([invisible-execution-authority.md](invisible-execution-authority.md)).
The kernel-homed acceptance (`SDA:languages/typescript/src/kernel/bootstrap/timing-coherence.mjs`)
closed four live cases: agent lane **715** windows / 3 ms unaccounted, equity
**179** / 3 ms, compose **181** / 1 ms, model lane **460** / 0 ms; verdict
`TIMING-COHERENT` (every residual zero or named). The recorded receipt path
(`evidence/vault-20260916/u5c/timing-coherence.receipt.json`) is a local capture
and is no longer present in this working tree; the acceptance command and its
verdict are the retained claim.

### 7.4 Circuit attestation

`read-capability-circuit` computes the structural attestation in its own declared
statement (ancestor closure over planned and observed inputs), with a
branch-aware miss rule and unobserved leaves named through the declared
`parentCellId` chain (estate `b9d4499`, `70f60f2`). Live: agent lane **985
planned / 703 observed, misses 0, structured true**; equity **242 / 180, misses
0, true**; negative fixtures (removed taken-path testimony) return
`structured: false` with the cell named
([implementation-plan-circuit-view.md](implementation-plan-circuit-view.md)
§CV-D1). Structure plus time is the attestation pair: the circuit shows which
declared cells ran; IEA shows nothing else took time.

### 7.5 Receipts discipline

- One migration per commit; `ROLLBACK` dry-run, from-transaction preflight, then
  `COMMIT` and install; proof is a live invocation, never a green in isolation
  ([sql/README.md](../sql/README.md)).
- `evidence/` is gitignored local execution evidence; commit messages and docs
  carry the digests. The achieved-install receipts are
  `evidence/vault-20260916/csharp-seams/`.
- Honesty rule: an accurate "blocked" or "owed" is a deliverable; a green that
  required inventing provider or kernel behavior is a finding, not a fix
  ([embodiment-completeness.md](embodiment-completeness.md)).
- One recorded mismatch to keep visible: the installed manifest's
  `conformanceReceipt` field names
  `evidence/vault-20260916/kernel-install/live-invoke.csharp.receipt.json`,
  which is not present locally; the retained equivalent is
  `evidence/vault-20260916/csharp-seams/`. Treat the manifest's digest fields,
  not the receipt path, as the admission truth.

---

## 8. Document map

### 8.1 Canonical by concern

| Concern | Canonical document |
|---|---|
| The primitive law (0/1, resolver floor, SDA request register) | [transistor-model.md](transistor-model.md) |
| The target end state and disposition standards | [target-architecture.md](target-architecture.md) |
| The composite repo boundary (CLI/DB repos out of the composite) | [composite-repo-boundary.md](composite-repo-boundary.md) (§0 rule, §4 irreducibles) |
| Kernel install matrix, manifest, host selection, per-OS acceptance | [kernel-install-matrix.md](kernel-install-matrix.md) |
| Estate script severance and the kernel-ground moves | [estate-script-severance.md](estate-script-severance.md) |
| Estate authored-code retirement (28-file ledger) | [hand-authored-code-retirement.md](hand-authored-code-retirement.md) |
| SDA tools UID homing ledger | [sda-tools-uid-homing.md](sda-tools-uid-homing.md) |
| SDA capabilities tree disposition (blast radius) | [sda-capabilities-blast-radius.md](sda-capabilities-blast-radius.md) |
| The governed model harness (agent lane) | [agent-lane.md](agent-lane.md) |
| Invisible execution authority (timing test) | [invisible-execution-authority.md](invisible-execution-authority.md) |
| Vault contract, OS realizations, key custody | [vault-manager-capabilities.md](vault-manager-capabilities.md) |
| Display decisions (display is 1) | [display-projection-decision-record.md](display-projection-decision-record.md) |
| Circuit flywheel and plan | [circuit-view-flywheel.md](circuit-view-flywheel.md), [implementation-plan-circuit-view.md](implementation-plan-circuit-view.md) |
| Authoring lifecycle (the unit of work) | [sql/README.md](../sql/README.md), [AGENTS.md](../AGENTS.md) |
| JSON authoring surface | [json-authoring-surface.md](json-authoring-surface.md) |
| Flywheel proof (95 seconds, scope limit) | [flywheel-proof.md](flywheel-proof.md) |
| Embodiment completeness (every mechanic, per language) | [embodiment-completeness.md](embodiment-completeness.md) |
| Decision accounting (rubric) | [sidefx-architecture-decision-rubric.md](sidefx-architecture-decision-rubric.md) |
| Priority ordering (ordering only, status dated) | [architecture-priorities.md](architecture-priorities.md) |
| Current wave plan (active, other writer) | [implementation-plan-next-wave.md](implementation-plan-next-wave.md) |
| Achieved state (this record) | this document |

### 8.2 Stale list (what supersedes each)

| Stale record | Stale because | Superseded by |
|---|---|---|
| `README.md` | describes `src/`, `scripts/`, `tests/`, `embodiments/`, `baselines/`, materialization and `npm test` — all removed | this document §1; [target-architecture.md](target-architecture.md); commits `af69dfb`–`b9d045a` |
| `docs/target-architecture.md:24-25,186-190,198-200` | says the estate/`sidefx-database` "drive the CLI" and "supply the connection and query runner" | [composite-repo-boundary.md](composite-repo-boundary.md) §0/§4; kernel bootstrap ground (`ac89271`, SDA `9b77314`) |
| `docs/transistor-model.md:18-20,289-293,326-358` | `DB:` citation root and "only Node has a bootstrap/loader" (G6) | §1, §5 here; the three physical entries and installers (SDA `9ff6dc0`, `9b77314`, `3103eed`) |
| `docs/composite-repo-boundary.md` status line and U-list | "proposed, not yet landed"; U1-U5/U7 largely landed; U6 open | §1.6 and §9 here; `ac89271`, `af69dfb`, `52133f9`, `b9d045a` |
| `docs/estate-script-severance.md` §2–§5 | inventories/owners predate the deletion of `scripts/` | `92b79e8`; §4 status row in that doc; `git ls-files scripts/` = 0 |
| `docs/kernel-install-matrix.md` §4 table, §6 seams 2-5,7 | win-x64 "owed", C#/Python observe refused, no installer, root resolution open | §5 here; installed C# manifest (observation OFFERED); `52133f9`, `b9d045a`; `receipt.json` |
| `docs/hand-authored-code-retirement.md` + `-agent-strategy.md` | ledger of files that no longer exist | this document §2.6; commits `af69dfb`, `92b79e8`, `6e3d146`, `52133f9` |
| `docs/architecture-priorities.md` §2–§4 (status date 2026-09-15) | counts/status rows predate the install, the severance and U5c | §5, §6, §9 here; [kernel-install-matrix.md](kernel-install-matrix.md) |
| `docs/implementation-strategy.md` lanes and backlog | owns `src/`/`scripts/` files that are deleted | §4, §8.1 here; rules/unit template remain canonical |
| `docs/agent-lane-declaration.md` | transition record ("routes are never emitted") | [agent-lane.md](agent-lane.md); `emit-declared-routing.sql`; `declare-two-child-routing-proof.sql` |
| `docs/next-experiences.md` §1, §4, §5 (state) | `embodiments/` deleted; vault V3/V4 done; `src/` gone | §1.1, §7 here; `6e3d146`; [vault-manager-capabilities.md](vault-manager-capabilities.md) §6 |
| `docs/projected-csharp-install.md` | first-turn precedent using `embodiments/` and a build-time SDA project reference; the kernel executable is now the install | §5 here; [kernel-install-matrix.md](kernel-install-matrix.md); `6e3d146` |
| `docs/sda-change-request-projected-testimony.md` ("Open request") | F1/F2 landed (timing, `observedPathDigest`, `resolverTestimony`); one equity-fixture granularity gap remains | SDA `a696fdd`, `0bff62b`; §6, §9 here |
| `docs/invisible-execution-authority.md` "Estate suite 72 pass" | the estate test suite is deleted | `52133f9`; §7.3 here |
| `docs/vault-manager-capabilities.md` §1.6 | names `src/database-delivery.mjs` env leaks; the file is gone and the no-env path is installed | `6c6b960`; §1.5, §7.1 here |
| `sql/README.md:4,27-29` | says the runtime is `src/` and `sidefx-database` supplies the runner | §1–§2 here; `ac89271`; kernel lifecycle runner |
| `AGENTS.md:3-4,27,31-36,73-77` | "estate … drives the CLI"; `src/`/`sidefx-database` edits; `npm run verify:*` scripts no longer exist | §1, §4 here; `package.json` (no scripts); kernel lifecycle commands remain correct |
| `docs/database-direct-invocation.md`, `docs/database-preparation.md`, `docs/database-mutation-flywheels.md`, `docs/deriving-contract-schemas.md` | invocation-era mechanics and CLI installation prerequisites | §1, §4 here |
| Demo docs (`demo-commands.md`, `demo-runbook.md`, `sidefx-public-demo*.md`) | recording-era scripts; not re-verified against the installed C# kernel | re-verify each command against §1.2 before reuse; [implementation-plan-next-wave.md](implementation-plan-next-wave.md) W1 owns the final pass |

Not stale, retained as historical/evidence: `docs/research/**`,
`docs/verification/**`, `docs/reviews/**`, frozen baselines and captures named in
[composite-repo-boundary.md](composite-repo-boundary.md) §5. This document does
not restructure any of them.

---

## 9. Achieved-state vs owed

Summary: `win-x64` C# invoke/observe is achieved; the estate-side UID is closed;
per-language entries exist; what remains owed is named field by field below.

| # | Item | State | Exact field / evidence |
|---|---|---|---|
| 1 | **Node entry** | achieved in-tree + installed locally (fallback, not selected) | `SDA:languages/typescript/src/kernel/bootstrap/entry.mjs` (SDA `9ff6dc0`); local install `%LOCALAPPDATA%\sfx\kernel\890cf164…` manifest: `kernelLanguage=node`, `artifactDigest=sha256:890cf164…`, `sdaRevision=9ff6dc0b…`, `sourceState=clean`, `observationChannel.status=OFFERED` |
| 2 | **Python entry** | achieved in-tree + installed locally; admitted installed form owed | `entry.py`, `kernel_install.py`; local install `e0346417…`: `observationChannel.status=OFFERED`, `sourceState=clean`; [kernel-install-matrix.md](kernel-install-matrix.md) §4 "no installed form admitted"; owed: host-record admission + a live installed invoke/observe acceptance |
| 3 | **C# entry** | achieved and selected | installed manifest §1.2: `artifactDigest=sha256:59d6030f…`, `manifestDigest=sha256:944a20e2…`, `sdaRevision=9b77314…`, `status=INSTALLED/VERIFIED`; live hello/equity/agent-lane acceptance in `csharp-seams/` |
| 4 | **C# write-isolation gap** | owed; recorded in every C# outcome | `evidence.process`: `fsWriteAllowed=true`, `fsWriteEnforcement="NOT_ENFORCED_MANAGED_HOST"`, `fsWriteGap="NO_MANAGED_IN_PROCESS_WRITE_INTERCEPTION; OS-level write denial requires a restricted-token or AppContainer launch"`; child processes are blocked (`childProcessAllowed=false`, `windows-job-object-active-process-limit`). Python enforces writes off in its audit hook (`fsWriteAllowed=false`, `FILESYSTEM_WRITES_MUST_BE_DISABLED`); Node installs the permission sandbox. Trigger: host launch profile (`SDA:languages/csharp/src/ScenarioKernel/bootstrap/ProcessIsolation.cs` doc comment) |
| 5 | **macOS / Linux builds** | owed | [kernel-install-matrix.md](kernel-install-matrix.md) §1/§4: `osx-arm64`, `osx-x64`, `linux-x64`, `linux-arm64` builds + live invokes + observe parity + vault realizations (`macos-keychain-credential-store-provider`, `linux-secret-service-credential-store-provider`); cross-RID publish is build evidence at most (`KERNEL_RUNTIME_PACK_UNAVAILABLE` if packs missing); no macOS/Linux acceptance is claimed from a Windows run |
| 6 | **Python observe seam** | seam achieved in-tree; installed observe acceptance owed | `entry.py:407,505-507` (`SIDEFX_OBSERVE=1` → `SFX_OBSERVATION`), `observation.py`; local python manifest `observationChannel.status=OFFERED`; owed: a live streamed observe from an admitted Python install (matrix §6.3 is stale on this row) |
| 7 | **UID remainder** | estate closed; SDA open; circuit partially declared | [hand-authored-code-retirement.md](hand-authored-code-retirement.md) retired; one tracked research script `docs/research/ml-opportunity/collect-evidence.mjs`. SDA: [sda-tools-uid-homing.md](sda-tools-uid-homing.md) 461 files, M0 landed, M1 landed, M2 blocked — `SDA:governance/projector-surface-freeze.policy.v1.json:homing.status="BLOCKED"` (baseline 9 files / 4,004 mechanics at `0bff62b`, `surfaceListIsClosed=true`); F1/F3/F4/F5/F6/F7 and G1/G2/G5/G10 open ([transistor-model.md](transistor-model.md) §7.2/§10). Circuit: CV-B declared fragments pending, CV-C2 `render.mjs` retirement pending ([implementation-plan-circuit-view.md](implementation-plan-circuit-view.md) §UID audit/§TUI) |
| 8 | **Carrier residual (U6)** | owed | `sfx.config.json` + `config/sfx.commands.json` are CLI-format host/delivery data (`configurationType=sfx-project.v1`); the kernel entry is directly invocable with `--stdin-envelope`. Deletion is U6 of [composite-repo-boundary.md](composite-repo-boundary.md) §3 |
| 9 | **Equity fixture cross-target testimony** | owed (kernel emitter field) | python testimony on the equity fixture carries semantic-normalized `cellId`s and different walker granularities; set equality asserted on shared chaining fixtures only ([sda-change-request-projected-testimony.md](sda-change-request-projected-testimony.md) §1.4; [invisible-execution-authority.md](invisible-execution-authority.md) "Projected-target acceptance" row) |

**Declare it or resolve it. There is no third place for executable meaning to
live.** The achieved estate has no third place left in it; the remainder lives
in SDA resolvers, declared rows, and the recorded owed list above.
