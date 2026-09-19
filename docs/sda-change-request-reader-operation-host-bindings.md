# SDA change request — reader operations must execute under the invocation path's host bindings

Format per [embodiment-completeness.md](embodiment-completeness.md): primitive /
why kernel / affected languages / data that binds it / evidence. Filed from the
estate; agents do not edit SDA.

## Summary

On the installed win-x64 C# kernel every **reader operation** of the declared
command surface fails with the collapsed code `DECLARED_READ_FAILED`:
`capability list`, `capability find`, `capability reveal`, `capability
catalogue`, `capability circuit`, `media artifact`. The same declared reads
execute correctly through `capability invoke` on the same installed kernel:
`sfx capability invoke list-capabilities --input {} --json` completes and
returns the catalogue while `sfx capability list --json` fails.

Root cause, by source comparison: the C# carrier's reader path builds a bare
`CarrierContext` without the host bindings the invocation path adopts, so the
declared read's SQL port has no `ReadQuery` delegate to dispatch through.

| Path | Context it executes with |
|---|---|
| C# reader (`CommandCarrier.cs:192-194`) | `new CarrierContext { SdaRoot, DataAccess }` — **no `Host`** |
| C# invocation (`InvocationBoot.cs:205-230`) | `KernelHostBindings { Metadata, ReadQuery = ReadDeclared, InvokePlatformEffect, ObservationSink }` and `Mechanics` |
| Python reader (`command_carrier.py:210`) | `CarrierContext(sda_root=…, data_access=…, host={"readQuery": read_query})` |
| TypeScript reader (`command-carrier.mjs:248,361`) | the same `config` as invocation, carrying `readQuery` and `readAuthority` |

The second defect is diagnostic: `CommandCarrier.cs:199-203` resolves the
failure message from the failed outcome's message fields and falls back to the
generic `DECLARED_READ_FAILED`, so the read's own failure cause never leaves the
kernel (the TypeScript carrier already falls back to a serialized outcome
message, `command-carrier.mjs:361-368`).

## Primitive

A reader operation's declared graph must execute under the same admitted host
bindings as an invocation of the same declared read. The host `ReadQuery`
delegate — the pinned read session's query seam — is execution authority, not an
invocation-only option: a kernel that runs a declared read without it fails
closed with a cause-bearing error, never with a generic code that hides the
read's own failure.

## Why kernel

Host bindings are constructed in the kernel carrier (`CommandCarrier` /
`InvocationBoot` in C#, and their Python/TypeScript counterparts). No estate row
can supply a missing host delegate, and the invocation path is read-only.

## Affected languages

csharp (observed on the installed win-x64 kernel `59d6030f…`, published from SDA
`9b773142…`, `sourceState: working-tree`). python and typescript already bind
`readQuery` on the reader path (citations in the table); keep that parity when
the context construction is unified.

## Data that binds it

- `sda-node-command-operations.v1` — the declared operation vocabulary, 8
  operations: `invoke`, `observe`, `circuit`, `reveal`, `catalogue`, `list`,
  `find`, `artifact`. Every operation except `invoke`/`observe` is served by the
  reader path.
- The declared readers the authority names, e.g. `list-capabilities`
  (`sql/migrations/declare-list-capabilities.sql`) and `read-retained-publication`
  (`sql/migrations/declare-read-retained-publication.sql`); both execute
  correctly when invoked directly and fail when the reader operation selects
  them.

## Evidence

Live, 2026-09-19 (host Windows x64), captured through `cmd /c` from
`C:\lab\repos\sfx-embody`:

```
sfx capability list --json
  → {"error":{"code":"DECLARED_READ_FAILED","message":"DECLARED_READ_FAILED", …}}
sfx capability find read-retained-publication --json
  → DECLARED_READ_FAILED
sfx capability reveal say-hello-world --as meaning --json
  → DECLARED_READ_FAILED
sfx capability catalogue --json
  → DECLARED_READ_FAILED
sfx capability circuit resolve-equity-market-price-evidence --json
  → DECLARED_READ_FAILED
```

No CLI involvement: the kernel entry itself, from its install root,

```
KernelEntry.exe capability list --json
  → {"error":{"code":"DECLARED_READ_FAILED","message":"DECLARED_READ_FAILED"}}
```

The same declared read through the invocation path succeeds:

```
sfx capability invoke list-capabilities --input {} --json
  → disposition completed; the full catalogue and testimony returned
    (evidence.executeDeclaredGraph ≈ 11.1 s; the read itself is slow but sound)
```

Also verified in the same session: `sfx capability invoke say-hello-world
--input {} --json` completes, so the execution path is intact; only the reader
operation path fails.

## Requested change

1. Build the reader path's `CarrierContext` with the host bindings the
   invocation path adopts (at minimum `ReadQuery`, mirroring
   `command_carrier.py:210`), or route both paths through one context factory so
   the seam cannot drift again.
2. Surface the failed read's cause: when the reader graph outcome fails, raise
   the outcome's message/code (serialized fallback) instead of the generic
   `DECLARED_READ_FAILED`; a reader failure must be attributable (the estate's
   UID/IEA rules apply to the kernel surface too).
3. Add C# conformance coverage for the declared reader operations against a
   fixture database, so the installed-kernel acceptance exercises them beside
   `invoke`/`observe`.

## Impact

- The declared command surface is unusable on the installed kernel for every
  read: `list`, `find`, `reveal`, `catalogue`, `circuit`, `artifact`.
- The estate's demo circuit beat (`sfx capability circuit …`) and every
  catalogue/status read are blocked; `invoke`/`observe` are unaffected.
- `docs/capability-command-surface.md` records the reader operations as
  "declared reads … verified live": true of the declared reads as capabilities,
  not of the reader operations on the installed C# kernel. Note for correction
  once this request lands.
