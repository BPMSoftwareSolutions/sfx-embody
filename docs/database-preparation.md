# Prepared database invocation

The native CLI now reads one prepared capability bundle from SQL, builds its
body in memory, checks that it matches the prepared proof and executes it.
Requirement derivation and binding resolution run only during explicit
preparation. Neither operation writes the capability body to disk.

From the project directory:

```powershell
sfx capability prepare resolve-sidefx-eligible-providers --timeout 600000 --json
sfx capability invoke resolve-sidefx-eligible-providers --input '@examples/provider-resolution.request.json' --json
```

The first command prepares the selected revision and executes its retained
fixtures. The second command uses that preparation; this example is already
prepared in the live database. `@examples/...` supplies the invocation's JSON
input file. It does not identify a capability implementation. Inline JSON and
stdin remain supported by the CLI.

Setup requires database migration 005, applied with
`node src/migration/capability-preparation.mjs` in `C:\lab\sidefx-database`.
The existing project process binding offers both operations without adding
capability-specific routing to the CLI. `--namespace` remains selection data.
Preparation has no invocation input; its tests come from retained authority.
The extended timeout is explicit on preparation only.

## Retained execution identity

`runtime.capability_preparation` retains the selected authority, resolved
requirements and bindings, mechanic declarations, and fixture proof as an
immutable SQL record. It is keyed by the selected model, capability/Scenario
versions, target, SQL definition identity and preparation recipe identity.
The recipe covers provider and reader implementation bytes, query text, Node
version and declared dependencies. The payload has a SQL-enforced SHA-256 check.
No full-estate preparation job or filesystem cache participates.

Preparation reads the three original authority queries and requires coherent
snapshot, projection and SQL definition identities. The Node planner holds
unresolved bindings explicitly. All retained fixtures must pass before the
insert-only writer publishes a preparation. Publication rechecks the database
generation and SQL definitions. Repeating an identical preparation is idempotent,
including when a previously omitted namespace is supplied explicitly.

Invocation performs one restricted query against the current model and prepared
context. It verifies the payload and authority result digests, rebuilds the body
in memory, and checks every Scenario's artifact, source revision, resolver and
physical platform digest against the stored proof before loading it. The result
includes the preparation digest and its proof. Capability execution still uses
the actual Scenario Kernel and unchanged canonical input.

Missing preparation returns `CAPABILITY_PREPARATION_REQUIRED`; a context change
returns `CAPABILITY_PREPARATION_STALE`. Both are native CLI exit 4. They never
start analysis or fall back to an expanded directory. Unknown authority retains
`CAPABILITY_NOT_FOUND`. Invalid invocation input reaches the capability contract
and returns its rejected disposition.

Generation-level invalidation is conservative: a new selected model requires
preparation again even when an unrelated declaration caused the change.
Unresolved bindings and missing/failing fixtures cannot establish a prepared
execution claim. Candidate editing, managed admission and a capsulization
adapter remain separate work. This preparation retains the exact authority and
proof identity that a future capsulization operation must consume.

## Native acceptance on 2026-09-08

The final tested provider-resolution preparation stored 670,888 bytes, passed
four fixtures and 28 outcome assertions, and retained 20 kernel observations in
its proof summary. Its preparation digest is
`sha256:9c1b84fa02afc8efcf0833dd010bf2edc59fbb767cd93a5f65521f6a176c5757`.

The measured prepared invocation took approximately 2.9 seconds from PowerShell
and 2.56 seconds inside the provider process:

| Stage | Milliseconds |
| --- | ---: |
| Prepared SQL lookup and validation | 1289.0 |
| Native body planning | 363.1 |
| Memory module loading | 35.0 |
| Scenario construction | 42.0 |
| Capability execution | 2.0 |

It returned `PROVIDERS_RESOLVED`, considered two bindings and selected one
eligible provider. Its evidence contains one live SQL query, 14 modules loaded
from memory, and denied filesystem writes, expanded-body reads and local
database-cache reads.

The earlier resolver measurement exceeded 120 seconds under shared load. In
these preparation runs the same resolver took 2.3–5.4 seconds. These are observed
wall times, not an isolated performance ratio. The established improvement is
that the resolver is absent from the invocation path.

The [native records](verification/database-preparation-20260908.json) retain
commands, exit codes and complete output streams. Acceptance covers missing
preparation, successful preparation, repeat preparation with an explicit
namespace, invocation, stale recipe rejection, restored invocation, invalid
input and missing authority. The stale-recipe test changes a local query comment
and restores the exact original bytes in `finally`; it does not alter database
authority or resolver definitions.

Validation passed: eight embodiment tests, 22 default database tests (ten optional
integration tests skipped), eight explicitly enabled live query tests, and two
live preparation integration tests. The latter cover concurrent idempotence,
conflict and stale rejection, denied reader writes, payload integrity and trusted
constraints. The existing memory/expanded regression still matches all 17
fixtures and 465 generated body files.

Repeat native checks with `scripts/verify-sfx-preparation.ps1 -Mode Prepare`,
then `PrepareExplicit`, `Invoke`, and `Stale`. `Unprepared` expects the separate
`adapt-job-market-intelligence-evidence` capability to have no preparation.
`scripts/verify-sfx-invocation.ps1`
retains the valid-input, rejected-input and missing-authority cases.
