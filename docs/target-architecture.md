# Target architecture: the row-driven estate and its reader kernel

This is the durable statement of the end state. Design decisions, retention
questions, and "do we still need X?" are answered against this document rather
than re-litigated per module. It is consistent with
[sidefx-architecture-decision-rubric.md](sidefx-architecture-decision-rubric.md)
and [research/platform-mechanic-honesty.md](research/platform-mechanic-honesty.md).

## The rule

- **All meaning is database rows.** Capability, feature, contracts,
  scenarios/execution authorities, operations, ports, transformations,
  mechanics, provider bindings, targets — authored in `.sql`, versioned as
  semantic definitions. A capability changes by changing rows.
- **The language kernel resolves language, and only language.** Each target
  language (node, python, csharp; java/go pending) reads the declared execution
  graph and *interprets* it. The kernel holds no domain logic. The rubric line:
  *"kernels resolve language and everything else comes from data."*
- **Providers are declared.** A port resolves through a row to a real
  implementation — a platform mechanic provided per language, or a declared data
  read. No `src/resolvers/*.mjs` on the invocation path.
- **The estate is a reader.** `sfx-embody` / `sidefx-database` read authority and
  drive the CLI. Editing `src/` must never change what a capability means.
- **No materialization.** No native-body emission, no file writes, no
  child-process execution, no platform-commit pinning. The kernel interprets the
  graph in process.

The loop it buys: *author/change rows → the CLI invokes → the kernel interprets
the declared graph → observe → change rows.* Nothing sits between the database
and the kernel but declared providers.

## The only code that may remain

Exactly three mechanics are irreducible. Everything else is a row or is deleted.

### 1. The frontdoor / loader — not declarable (proof by regress)
To execute a declared capability you need something that reads its declaration
from the database and runs it. Assume that something is itself declared. Then
executing *it* needs another reader-and-runner, also declared, and so on — the
chain never grounds out and there is no first executor. The loop can only start
if the regress terminates in an executor that is **not** a declared capability.
That terminal executor is the frontdoor/loader. (`database-delivery.mjs`,
`config/sfx.commands.json`, the reduced invocation entry.)

### 2. The database connection / query runner — not declarable (proof by circularity)
Declarations are rows; any executor must read them. If the read were declared,
you could not discover that declaration without already being able to read the
database — circular. The connection/query primitive is the ground the
declarations stand on. (`read-authority`'s role as the loader's declaration read
belongs here; its SQL content is a declared read, its execution is this runner.)

### 3. The bootstrap installer — not declarable at bootstrap (proof by regress)
A migration installs the rows that define capabilities. If the installer were
declared, its own declaration would have to be installed first, by an installer
that already exists. The first installer cannot be declared. (Once it exists, an
individual migration may be invoked as a capability through the frontdoor; this
bars only the bootstrap.)

## Disposition

| Concern | Disposition |
|---|---|
| domain resolvers (`src/resolvers/node/*.mjs`) | **declared capability** — served by kernel mechanics (`compileSemanticExecutionGraph`, `executeSemanticExecutionGraph`, `sda-semantic-value-graph-provider`, `sda-declared-read-graph-provider`, `sda-schema-contract-admission`) or declared reads |
| reader/projection operations (`read-capability-meaning`, `read-circuit-media`) | **declared capability** (SQL read + transformation) |
| presentation (`narrate-*`, `diagram-*`) | **declared capability** (templates/transformations over authority); if not expressible, a platform presentation mechanic — never estate code |
| frontdoor/loader, DB query runner, bootstrap installer | **code** (the irreducible three) |
| delivery/workspace config (`read-workspace-config`) | **code** (boot config) |
| materialization (`materialize-node`, `prepare-database-capability`, `load-memory-scenario`, `load-consumer-plan`, `read-execution-graph`, `reveal-native-expressions`, `embodiment-delivery`) | **eliminated** — nothing is emitted/loaded/written once the kernel interprets |
| native-body verification (`verification/verify-node`, `verify-native-projection`, `verify-contract-fidelity`) | **eliminated** — verifies artifacts that no longer exist |

## How to decide a new case

Ask, in order:

1. **Is it the boot?** (frontdoor/loader, DB connection/query runner, bootstrap
   installer.) → it is code — the only allowed code.
2. **Does it emit, load, write, or verify a native body / materialized plan?**
   → it is **eliminated**; do not port it or declare it. This is what the kernel
   supersedes.
3. **Otherwise** → it is **meaning**; it becomes rows (a declared read, a
   declared transformation, a provider binding) and is invoked through the
   frontdoor.

## Non-reasons to retain code

None of these justify keeping a module, capability, or guard:

- "it makes an invocation pass" — a change that only makes a green appear is a
  finding, not a fix;
- materialization, native bodies, or file writes;
- platform-commit pinning or build-time provenance gates;
- parity against retained native-body fixtures;
- "we might need it later" / ease of the current implementation.

If a capability is blocked by a domain concern that only the estate runtime could
implement, that is a finding to resolve in rows (or, cross-language, in SDA) —
never by editing `src/`.

## Execution protocol

See [implementation-strategy.md](implementation-strategy.md) for the parallel
lane plan (who executes which unit). This protocol governs each unit.

The target is fixed. Work proceeds toward it; direction is never requested. The
standards above decide every case, so there is nothing to ask.

**A unit of work** is a set of coordinated changes that must land together plus
its proof. Example: a migration declaring the read rows, the boot read switch,
and the reduced loader are one unit — landing any subset alone would leave the
tree broken, so they land as one unit, not three that each stop for approval.

**For every unit:**
1. State the concern and the standard that governs it (port binding, location,
   disposition — all defined above).
2. Land the coordinated change in one pass.
3. Prove it: `sfx capability invoke <identity> ...` (and the delete test where a
   module is being removed). Expected outcome or documented expected failure.
4. Keep the tree green between units. One migration per commit.
5. Record nothing extra — the doc is the authority.

**Do not stop for:** direction, scope confirmation, "should I restore this",
naming, uncertainty about which standard applies, or the size of a unit. If the
standard applies, apply it. If several files must change together, change them
together and prove the result.

**The only permitted escalation is a kernel change request.** Surface one only
when the target requires a primitive the kernel must interpret in every language
— a new operation kind, expression, or contract construct the kernels execute.
State it as: the primitive, why it must be kernel (cross-language interpretation,
not data selection), and the data that will bind it. A domain concern that only
the estate runtime could implement is **not** an escalation — it is a re-declaration.

**Invocation is the unit's proof.** A unit that changes how a capability resolves
is done when the CLI invokes that capability through the kernel and returns the
expected outcome — not when a file is deleted, a row is written, or a green
appears in isolation.

## Boundary

- **Cross-language impact → SDA** (the platform, per language).
- **Everything else → the database** (rows).

## Standards

These are binding. A violation is a data defect, fixed by re-declaration — never by
restoring deleted code or adding estate code.

### Port / provider binding
A Port's `configuration` MUST be exactly one of:

1. a **platform mechanic binding** — `platformCapabilityId` names a mechanic
   declared in the target language registry (with any declared configuration); or
2. a **declared data read** — `{ "statement": <sql>, "resultColumn": <name> }`.

A Port MUST NOT carry `configuration.providerId` naming a module, and MUST NOT
carry `configuration.estateProvider`. Any binding that names `src/resolvers/*`,
`materialize-node`, or any estate module is a **data defect**. This is the single
rule that makes "the resolved missing module" always a re-declaration, never a
restore.

### Invocation
Invocation is: the boot reads the capability's declared authority from rows and
hands it to the kernel; the kernel compiles the execution graph and interprets it,
resolving each cell's provider through the declared overlay (`overlayBindings`)
plus the declared `providers` set. No per-port estate-provider import; no
materialize-and-run. The carrier is a loop over declared operations, nothing more.

### Composition
Capability-to-capability invocation is an `invoke-scenario` execution operation
with mapped contracts — not a platform port and not estate code.

### Platform mechanics
Every `mechanicId` a compiled graph requires MUST have:

- an `overlayBindings` entry (`mechanicId → providerProfileId`, digest,
  implementationRef), and
- a `providers` entry (`providerProfileId → module/export[/factory]`) naming the
  SDA **per-language** implementation.

Adding a platform mechanic is a kernel/platform change; binding one is data.

### Location of migrations and reads
All schema, migrations, and read SQL live in **`sfx-embody/sql/`** and are
authored as `.sql` here. Nothing reads `sidefx-database/sql/` — not diagnostics,
not migrations. The runtime's declaration read is the estate's own declared
source (`analysis.v_capability_graph_source` / `analysis.v_capability_execution_declaration`),
built by these migrations, not a legacy diagnostic. `sidefx-database` supplies
the connection and query runner only.

### Layering — who provides what
Dependencies flow one direction, and no layer reaches around another:

- **Frontdoor** (`database-delivery.mjs`) owns the database connection and the
  query runner. It injects them into the context it hands to the loader
  (`readQuery`, `readAuthority`). It is the only component that knows where
  `sidefx-database` is.
- **Loader** (`invoke-database-capability.mjs`) consumes only what the context
  supplies. It MUST NOT import from `sidefx-database`, build paths into it, or
  open its own connection.
- **Kernel** receives the declared authority/graph and interprets it. It holds no
  database.

A component that needs the database and reaches for it directly (e.g. importing
`databaseRoot/src/query/run.mjs`) is a **layering violation**. The fix is always
to have the providing layer inject it — never to import it around the boundary.
Concretely: `database-delivery.mjs` supplies `readQuery` and `readAuthority`;
`invoke-database-capability.mjs` uses `context.readQuery` / `context.readAuthority`
and nothing else.

### Decision rule for any "X is broken / missing"
1. **Boot?** (frontdoor/loader, DB connection/query runner, bootstrap installer) →
   code. Only the boot may be code.
2. **Materialization?** (emits/loads/writes/verifies a native body) → eliminated.
3. **Otherwise** → **data**: re-declare the port/operation/provider per these
   standards. Do not restore deleted code. Do not add estate code.

### Worked case: `resolve-equity-market-price-evidence`
A port resolving to `authority-read-provider.mjs` violates the port standard. The
fix is data:

1. re-declare that port to a platform mechanic or a declared read, so the rows
   contain no reference to deleted code; and
2. ensure the mechanics its graph uses have overlay/provider entries
   (`sda-governed-http-exchange-port.v1`,
   `sda-external-credential-reference-binding-port.v1`).

Invocation then flows through the kernel. No module is restored.
