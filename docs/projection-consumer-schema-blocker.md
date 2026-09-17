# Release-path finding: the projection consumer schema rejects declared operation variants

**Status: resolved 2026-09-17.** SDA `fa35b99` admits operation
`outcomeVariants` in both declared shapes; estate `f80c68f` re-projected
successfully (`PURE_PROJECTION_CONFORMS`, csharp/node/python, 227/227 bindings).
Adjacent gate also fixed: empty fixtures document with superseded
`owner_definition_pk` (estate `7fa3d89`). The first C# executable install then
completed — see [projected-csharp-install.md](projected-csharp-install.md).
The original finding is retained below.

**Status (original).** Found 2026-09-17 while attempting the first C# executable
install of `compose-resolve-equity-market-price-evidence` (the
release-flywheel step). Blocked projection to **every** target for the equity
capability.

## What was attempted

```text
sfx capability project compose-resolve-equity-market-price-evidence --workspace <dir> --targets csharp --full-mechanics
sfx capability project resolve-equity-market-price-evidence        --workspace <dir> --targets csharp --full-mechanics
sfx capability project resolve-equity-market-price-evidence        --workspace <dir> --targets node   --full-mechanics
```

All fail `PROJECTION_FAILED`:

```text
Execution authorities failed validation against consumer-execution-authorities.schema.json:
  /executionAuthorities/1/operations/1  must NOT have additional properties
  /executionAuthorities/1/operations/1  must have required property 'scenarioId'
  /executionAuthorities/1/operations/1/kind  must be equal to constant
  …
```

## Cause

`SDA:kernel/schemas/consumer-execution-authorities.schema.json` validates each
authority operation with `additionalProperties: false` and a `oneOf` that
admits only:

```text
{kind:"invoke-port",     portId}       (exact)
{kind:"invoke-scenario", scenarioId}   (exact)
{kind:"…",               projectionId} (exact)
```

The installed equity execution authority carries more than that: verified in the
live model, the root authority envelope contains `"outcomeVariants"` on its
operations (`select 1` from the latest authority definition), introduced when
the fallback route was installed (`add-equity-price-fallback-route.sql` minted
the ten-operation authority with per-operation `outcomeVariants`).

Those fields are **legitimate declared vocabulary**: the graph compiler consumes
`operation.outcomeVariants` (`declaredOutcomeVariants`, `compiler.js:159-161`)
and the runtime selects on the declared variant ids (`completed`, …). The
consumer schema is behind the declaration vocabulary, not the other way around.

## Impact

- No `--full-mechanics` projection succeeds for
  `resolve-equity-market-price-evidence` or any capability whose closure
  includes it (`compose-resolve-equity-market-price-evidence`), on node, python
  or csharp.
- The C# executable installation step (project → build the emitted body →
  place it where a client machine runs it) cannot proceed for these
  capabilities until this is resolved. Earlier projections that succeeded
  predate the fallback authority shape.
- The projection *manifest*/bodies are otherwise fine; this is validation at
  document admission only.

## Options

1. **SDA: admit the declared optional operation fields in the consumer schema**
   (recommended). Allow `outcomeVariants` (and any other declaration extension
   the compiler already consumes) on the operation variants, or validate with
   `additionalProperties: true` plus the required per-kind fields. The kernel
   and the runtime already accept them; the schema is the outlier.
2. **Estate: emit a schema-normalized authority document for projection** in
   `analysis.v_capability_execution_declaration` (strip declaration extensions
   from `execution-authorities.authority.json` only). Not preferred: projected
   bodies would then diverge from the invoked authority, and variant
   classification stops being projected.

## Next steps

1. File/resolve option 1 with SDA (small schema change; the F10-style request
   is the format).
2. Re-run the projection; then the C# install:
   build the emitted body with the installed .NET toolchain, place the
   executable under the client install root (`%LOCALAPPDATA%\sfx\…`), and run it
   with the retained fixtures — the release flywheel's first turn.
3. The fallback authority itself is correct and stays as declared; no migration
   is needed for the runtime.
