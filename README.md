# sfx-embody

The declared estate. This repository holds **no execution code and no
dependencies** — it is the database authority's authoring surface, the client
configuration, and the evidence record. There is no package manifest, no
lockfile, no vendored tree and no build step. Execution arrives as an installed,
digest-admitted kernel executable, selected as host data.

What lives here:

| Path | Contents |
| --- | --- |
| `sql/` | The database-change authority: installed views and procedures (`sql/schema/`), migrations (`sql/migrations/`), and the change lifecycle (`sql/README.md`) |
| `config/` | Host and invocation configuration (kernel selection, workspace data); no credentials |
| `sfx.config.json` | The process deliveries the CLI drives — they invoke the **installed kernel executable** |
| `docs/` | The architecture, product and decision record (see the document map below) |
| `evidence/` | Local receipts and captures (ignored by Git) |
| `AGENTS.md`, `.opencode/`, `.claude/` | Agent guidance and skills for the change lifecycle |

## How execution works now

The estate declares; the **SDA Kernel executable** resolves and executes. The
installed executable is selected as host data (per-OS builds; C# on Windows),
admitted by manifest and digest, and invoked over the closed
`sfx-command-delivery.v1` envelope protocol.

```powershell
sfx capability invoke say-hello-world --input '{}'
sfx capability invoke resolve-equity-market-price-evidence --display --input AVGO
sfx capability observe request-capability-from-objective --input "What is Broadcom's current market price?" --json
```

The invocation path reads declared authority from the database, resolves
credentials from the **secrets vault** (never the process environment), and
executes through the installed kernel. No `scenario-driven-architecture`
source path, read grant, or build step participates at runtime.

## This repository depends on nothing

The estate declares; it does not import, install or build. The rule is absolute
and the surfaces it closes are named so they cannot creep back:

| Forbidden | Why |
| --- | --- |
| A package manifest, lockfile or `node_modules` | The estate is rows and prose. Nothing here is installed, built or bundled. There is no `package.json` and one must not be added |
| A sibling-repository path — `sidefx-cli`, `sidefx-database`, in any spelling | Neither has a role here: not code, not config, not a resolvable documentation link. Both are retired; see [composite-repo-boundary.md](docs/composite-repo-boundary.md) for the removal record |
| An SDA **checkout** reference | The relationship to SDA is an install, never a source tree |

**The one permitted relationship to SDA is the installed executable.**
`KernelEntry.exe` lives under `%LOCALAPPDATA%\sfx\kernel\<outputDigest>\`, is
admitted by an `sfx-kernel-install-manifest.v1` manifest and digest, is selected
as host data in [sfx.config.json](sfx.config.json), and is invoked over the
closed `sfx-command-delivery.v1` envelope. Selecting an admitted binary is not a
dependency on a source tree. A change that needs SDA source is a cross-language
**request**, not an edit and not a path reference.

**No link in this repository may resolve outside it.** Provenance for external
material is recorded as name plus inspected revision — never as a local path,
which is not reproducible provenance for anyone else anyway. Retired sources are
named in brackets, e.g. `input binding [agentic-harness]`.

The checks are mechanical and must each return nothing:

```
git grep -n "sidefx-cli\|sidefx-database" -- . ':!docs' ':!*.md'
git grep -n "](C:\|](\.\./\.\./sidefx\|](\.\./\.\./agentic\|](\.\./\.\./scenario-driven" -- .
```

**One violation is outstanding and is tracked, not tolerated.** The change
lifecycle still runs `run-migration.mjs` and `invoke-from-transaction.mjs` from
an SDA checkout — the last dependency in the estate. It closes when the migration
lifecycle is reached through the installed kernel like every other execution
([capability-estate-research.md](docs/capability-estate-research.md) §6 A5). It
is named in [AGENTS.md](AGENTS.md) and is not a precedent for anything else.

## The discipline

Everything executable is either **declared (1)** — language-invariant rows —
or an **admitted resolver (0)** in the SDA Kernel. There is no third place.
Boot, the DB ground, the bootstrap installer and the physical carriers are
resolver (0); capability, contracts, scenarios, operations, transformations,
mechanics, bindings and host selection are declared (1). Models reason only
inside a governed declared lane and never hold execution authority.

Read [docs/architecture-achieved.md](docs/architecture-achieved.md) for the
achieved state and the canonical/stale document map, and
[docs/product-flywheel.md](docs/product-flywheel.md) for the compounding loops.

## Document map

| Concern | Canonical document |
| --- | --- |
| Achieved architecture (estate) | `docs/architecture-achieved.md` |
| Achieved kernel architecture (SDA) | `../scenario-driven-architecture/docs/kernel-architecture-achieved.md` |
| The resolver/declared law | `docs/transistor-model.md` |
| Target architecture | `docs/target-architecture.md` |
| Governed model harness / agent lane | `docs/agent-lane.md` |
| Agent harness enforcement (hook register) | `docs/agent-harness-hooks.md` |
| Declared capability estate: shape, gaps, proposals | `docs/capability-estate-research.md` |
| Trust, non-disclosure, timing coherence | `docs/invisible-execution-authority.md`, `docs/vault-manager-capabilities.md` |
| Composite repo boundary | `docs/composite-repo-boundary.md` |
| Kernel install matrix | `docs/kernel-install-matrix.md` |
| Retirement/homing ledgers | `docs/hand-authored-code-retirement*.md`, `docs/sda-capabilities-blast-radius.md`, `docs/sda-tools-uid-homing.md` |
| Database change lifecycle | `sql/README.md`, `AGENTS.md` |

`docs/architecture-achieved.md` carries the explicit **stale-document list**
and what supersedes each entry. Historical material — the materializer era,
retained baselines and generated embodiments — remains in Git history; the
`embodiments/`, `providers/`, `baselines/`, `src/`, `scripts/` and `tests/`
trees no longer exist in this repository.

## Changing the estate

Every change is a `.sql` migration under `sql/migrations/`, authored to open its
own transaction and end in `ROLLBACK`, dry-run, preflighted from the uncommitted
transaction against the live circuit, then installed from a committed copy and
verified with `sfx capability invoke`. The rules and exact commands are in
[sql/README.md](sql/README.md) and [AGENTS.md](AGENTS.md); the lifecycle is
enforced by the SDA Kernel's lifecycle tools, not by estate scripts.

Expansion is declaration-only: a new capability is contracts, scenarios,
operations, transformations, mechanics and provider bindings — rows, preflight,
evidence. No runtime build and no language code are required to add meaning.

## Adding a provider

Inspect what is installed with `sfx provider list` and `sfx provider reveal
<providerId>` — host, endpoints, headers, credential reference and injection
rule, request templates and bindings, all rendered from declared rows.

Add one end to end with a single command:

```powershell
sfx provider add --input '@examples/provider-binding-change.<name>.json'
```

The command runs the declared lifecycle in order: **author** (validates the
native-to-canonical mapping against a sample response and mints the endpoint
digest) → **render** (the declared install mechanic emits the migration — no
hand-written row SQL) → **dry-run** → **in-transaction preflight** →
**install** → **verify** (a live invocation). A held authoring result stops
after author with `installed:false`, writes nothing, and names the exact
findings — no fabricated values. Credentials always resolve from the vault;
never put secrets in the spec or the environment. Provider routing is data, so
adding a fallback extends the declared chain (primary → fallback → …) rather
than changing code.

The full flow, the held no-install guarantee and the N-fallback chain are
recorded in [docs/provider-add-flywheel.md](docs/provider-add-flywheel.md);
the finance15 fallback is the worked example.

## Install or select a kernel

The kernel installer is resolver (0) in the SDA Kernel, implemented per language
(Node, Python, C#). Publishing stages a deterministic artifact set, installs it
to a digest-named immutable root with a `sfx-kernel-install-manifest.v1`
manifest and receipt, and can switch this estate's deliveries to the installed
executable. Per-OS RIDs, install roots, vault realizations and selection rules
are recorded in [docs/kernel-install-matrix.md](docs/kernel-install-matrix.md).

## Known limits (schedule, not architecture)

Named and tracked in `docs/architecture-achieved.md` §9: C# filesystem-write
enforcement requires a launch-profile mechanism (`NOT_ENFORCED_MANAGED_HOST`);
macOS/Linux kernel builds are owed; the Python kernel's observe path awaits its
registry/declared-application seam. None of these change what is declared or
how meaning executes.
