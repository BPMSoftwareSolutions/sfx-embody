# sfx-embody

The declared estate. This repository holds **no execution code** — it is the
database authority's authoring surface, the client configuration, and the
evidence record.

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
