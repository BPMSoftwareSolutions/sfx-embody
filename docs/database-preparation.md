# Optional database preparation, direct invocation

`sfx capability invoke` is now direct: it resolves the selected authority,
plans the native body and executes it in memory on every call. It never reads
a stored preparation, never checks a preparation recipe and never runs retained
fixtures. `sfx capability prepare` remains available as an optional operation
that resolves and proves one revision and retains that proof in SQL; invocation
does not consume it, and nothing else in this repository does either. The
retained proof stays available for a future capsulization consumer.

From the project directory:

```powershell
sfx capability invoke resolve-sidefx-eligible-providers --input '@examples/provider-resolution.request.json' --json
```

The command reads the capability and declared root Scenario from SQL, plans the
native body in memory, executes it, and returns the kernel result and
authority/storage evidence. Any selected capability can be invoked this way;
there is no preparation prerequisite. `@examples/...` supplies the invocation's
JSON input file. Inline JSON and stdin remain supported by the CLI.

The optional preparation command is unchanged in behavior:

```powershell
sfx capability prepare resolve-sidefx-eligible-providers --timeout 600000 --json
```

It derives the preparation recipe, resolves authority, proves the retained
fixtures and stores an immutable preparation record in SQL. Repeating an
identical preparation is idempotent. The extended timeout is explicit on
preparation only; direct invocation uses the CLI default.

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

Invocation performs the same three restricted queries as preparation, against
the current model, and rebuilds the body in memory. The result carries the
authority query identities, snapshot and projection digests, the planned
artifact identities, and the module/resource access evidence. Capability
execution still uses the actual Scenario Kernel and unchanged canonical input.

Unknown authority retains `CAPABILITY_NOT_FOUND` (exit 4); there is no
bootstrap or disk fallback. Invalid invocation input reaches the capability
contract and returns its rejected disposition (exit 0). A capability whose own
admitted transformation fails reports `CAPABILITY_EXECUTION_FAILED`, exactly
as the canonical evaluator would.

## Native acceptance on 2026-09-09

Direct invocation of `resolve-sidefx-eligible-providers` completed in about six
seconds from PowerShell (4.5 seconds of live authority resolution, 0.4 seconds
of body planning) and returned `PROVIDERS_RESOLVED`: two considered bindings,
one eligible provider. Its evidence contains the three live SQL queries
(capability-embodiment, scenario-resolver-map, mechanic-definitions), 14
modules loaded from memory, and denied filesystem writes, expanded-body reads
and local database-cache reads. No preparation is read or verified anywhere on
the path.

The earlier resolver measurement exceeded 120 seconds under shared load; the
direct runs above resolve in 2.3–7.7 seconds per query stage. These are observed
wall times, not an isolated performance ratio.

The optional preparation record behaves as before: the current provider-resolution
preparation stores 670,888 bytes, passes four fixtures and 28 outcome assertions,
and retains 20 kernel observations in its proof summary. Its preparation digest is
`sha256:4cb9c0f38150c88f160ec61e4e88d40bf33483b7bb398d79ef2433f45d17ec62`;
the recipe deliberately covers the provider implementation bytes, so any
embodiment change produces a new digest.

The [native records](verification/database-preparation-20260908.json) retain
commands, exit codes and complete output streams. The current acceptance runs
are retained under `evidence/direct-invocation-20260909/`. Validation passed:
eight embodiment tests, the full estate verification (17/17 fixtures, 320
kernel observations, five negative checks across ten scenario bodies), memory
parity across all retained bundles, and the native sfx invocation checks,
including a capability with no preparation at all.

Repeat native checks with `scripts/verify-sfx-preparation.ps1 -Mode Prepare`,
`PrepareExplicit` (optional preparation), `Invoke` (direct invocation evidence)
and `AnyCapability` (a capability with no preparation invokes directly).
`scripts/verify-sfx-invocation.ps1` retains the valid-input, rejected-input and
missing-authority cases.
