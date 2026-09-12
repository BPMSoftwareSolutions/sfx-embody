# SQL → CLI Hello World: gap resolution

2026-09-12 · Findings and minimal change set. The end-to-end loop does not run yet;
this records exactly what blocks it, with observed evidence, and the smallest
change that closes each gap.

## Method

Run from `C:/lab/repos/sfx-embody` against the live `sidefx` database
(`bpmsoftwaresolutions`). The existing greeting capability was invoked through the
unchanged CLI to prove the read → plan → execute path is live:

```powershell
sfx capability invoke say-hello-world --input '{"contractId":"hello-world-request.v1","payload":{}}'
```

It returned `disposition: terminated` with outcome
`{"contractId":"hello-world-greeting.v1","payload":{"message":"Hello, World!"}}`
on stdout. So the CLI and runtime are available; the blockers are specific.

## Blocker A — the database working representation is not editable

The candidate SQL scaffold wrote session-local temp tables. A separate CLI
connection cannot see those, and the intended working data lives in tables that
are guarded against change.

Observation (transaction rolled back; no persistent change was made):

```js
UPDATE source.content_object
SET content_digest=@d, content_bytes=@b, byte_length=@n
WHERE content_object_pk=@pk;
```

```
SqlError 51003  IMMUTABLE_INSPECTION_DATA
procName: guard_content_object
```

`source` and `model` carry per-table `guard_*` triggers (`source.guard_content_object`,
`source.guard_source_appearance`, `model.guard_estate_capability`, and siblings).
They reject mutation wholesale, not only deletion. The seed comment in
`docs/research/scaffold-projection-gap/register-equity-capabilities.sql` ("the
model guards only THROW when `deleted` is populated") does not hold for this path.

This is the concrete form of the review's correction: the immutability rule must
apply to **sealed capsule artifacts**, while the working representation stays
mutable. As written, the guards block the workshop.

### Smallest change that closes A

Preferred, and consistent with plan section 1.1 ("narrow it to sealed artifacts or
bypass the playground path; do not weaken seal protection"): add a **mutable
working store** that the runtime reads, separate from the sealed `source`/`model`
tables.

1. `docs/sql/workshop-hello-world.sql` — idempotently creates:
   - `workshop.capability_definition(capability_id PK, root_scenario_id, operation_kind, message, updated_at)`
   - grants `SELECT` to `sidefx_reader`
   - `MERGE` the `hello-world-sql` row with `@Message`, then `COMMIT`.
2. `src/read-workshop-authority.mjs` — reads the committed working row for the
   selected capability and returns a working-definition bundle.
3. `src/invoke-database-capability.mjs` — in the `invoke`/`observe` path, fall
   back to the workshop reader when `readAuthority` reports `CAPABILITY_NOT_FOUND`.
   Return `authoritySource: 'WORKSHOP'`, `workingRepresentation: 'MUTABLE'`,
   `managedAdmission: 'NOT_REQUESTED'`. The sealed estate path is unchanged.
4. `src/read-authority.mjs` is untouched, so sealed-capsule resolution and its
   guards stay exactly as they are.

The alternative — relaxing `guard_content_object` for non-`deleted` updates — is
smaller but edits guarded tables in place and is not recommended while the
mutable store costs no more.

## Blocker B — no standard-output mechanic exists

The pinned Node mechanic registry declares no provider that writes supplied text
to standard output.

Evidence:

- `kernel/semantic-authority/consumer/node-mechanic-registry.authority.v1.json`
  lists every `eventPort`; the `invocation: "effects"` entries are
  `sda-external-credential-reference-binding-port.v1`,
  `sda-governed-http-exchange-port.v1`, and
  `sda-governed-disposable-root-lifecycle-port.v1`. None is a text writer.
- Effect providers resolve to platform modules by name. `src/materialize-node.mjs:139`
  reads `native.implementation_id`, and `:202-205` copies each bound effect
  `providerModule` from `sdaRoot`; `languages/typescript/runtimes/node/` contains
  no standard-output provider.
- The platform worktree is clean at the pinned commit:
  `git rev-parse HEAD` = `716811046f52dd2a67f9ff308a50d755571cbbad`, and
  `git diff`/`ls-files --others` over `tools/src`, `languages/typescript`,
  `package.json` are empty. `src/materialize-node.mjs:51-57` enforces exactly
  that: a dirty or moved platform raises
  `PHYSICAL_PLATFORM_COMMIT_MISMATCH` / `PHYSICAL_PLATFORM_SOURCE_MODIFIED`.

So a registry name match alone is insufficient: the provider must be an admitted
platform module. **SQL cannot supply it from data while the platform is pinned**,
because the registry names bytes that the pin check verifies.

### Smallest change that closes B

1. Add `languages/typescript/runtimes/node/standard-output-provider.mjs` exporting
   `writeStandardOutput(configuration, input, context, effectContext)`, which
   writes the declared message to standard output and returns a receipt
   (`{ text, bytesWritten }`). This is the exact missing operation.
2. Register it in `node-mechanic-registry.authority.v1.json` as an `eventPort`
   with `invocation: "effects"`.
3. Bind a capability port to that `platformCapabilityId`.
4. Because the platform is pinned, commit the platform change and re-admit the
   pinned platform authority through the platform load/migration path (a managed
   change), or run the loop against a deliberately unpinned workshop platform.

## Blocker C — the CLI only surfaces canonical JSON

Even with B resolved, the child's standard output is the transport for one JSON
result, so raw text written inside the capability is not shown on the terminal.

Evidence:

- `sidefx-cli/src/delivery-result.mjs:31-43` requires the delivery stream to begin
  with a JSON object and parses it as the single result.
- `src/database-delivery.mjs:47` writes exactly one JSON object to stdout.

### Smallest change that closes C

Expose the standard-output call at the delivery/CLI boundary rather than inside
the body: either render the outcome's declared message to the caller's stdout in
`sidefx-cli/src/render.mjs`, or forward a declared delivery output stream. Until
then the message is only visible inside the result JSON, which the work order
correctly rejects as the mechanic.

## Why SQL alone does not resolve B

The message text is data and can live in SQL. The stdout **operation**, its
provider module, and its registry entry are platform authority checked against a
pinned commit. There is no data-only path that names an existing stdout
implementation, and the delivery protocol carries JSON only. That is the
implementation evidence the work order asked for.

## Least-work path that closes the loop

Apply the selection rule from the plan (section 2.4). The complete intended loop
is *SQL authors the working definition → CLI executes it → the message is
observed → SQL changes it → repeat*. All three blockers above are on that loop;
none is skippable by choosing 001 vs 002.

- A is required for either work order and is self-contained in `sfx-embody` plus
  one SQL file.
- B and C are required for the Hello World stdout proof; 002's equity loop needs
  only A (its outcome is already observable).

Recommended order: close A first (bounded, testable, no managed migration), prove
the working-data edit → invoke → change → rollback loop on an existing
capability, then close B+C as a managed platform/CLI change for the Hello World
stdout proof.

## Current status

| Check | Observed |
| --- | --- |
| Candidate generation and rollback in SQL | Verified by the prior work order. |
| Existing capability invokes through the CLI | Verified live; greeting appears in stdout JSON. |
| Edited working definition executes | Blocked by A (`IMMUTABLE_INSPECTION_DATA`). |
| Standard-output mechanic executes | Blocked by B (no admitted provider). |
| Message visible as raw stdout | Blocked by C (JSON-only delivery result). |
| Second capability identity | Not reached; depends on A–C. |
