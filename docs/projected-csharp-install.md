# Projected C# install — first executable on a client machine

**Status.** Completed 2026-09-17. This is the release flywheel's first turn:
a declared capability projected to C# is built and installed as an executable
under the client install root, and runs its declared graph with fixtures —
without the estate, without Node, without transport. The client receives the
installed artifact, not the emitted bodies.

## Artifacts

| Item | Path |
|---|---|
| Projected C# sources (generated) | `embodiments/resolve-equity-market-price-evidence/projected/csharp/` (4 `.generated.cs`, JSON documents) |
| Projector-emitted build projects | `ProjectedConsumerCli.generated.csproj`, `ProjectedConsumerTest.generated.csproj` |
| Client install root | `%LOCALAPPDATA%\sfx\capabilities\resolve-equity-market-price-evidence\` |
| Installed executables | `ProjectedConsumerCli.exe` (fixture/CLI surface), `ProjectedConsumerTest.exe` (fixture suite + conformance) |

The generated `.csproj` files reference the SDA C# adapters
(`SDA:languages/csharp/src/ScenarioKernel.Adapters/ScenarioKernel.Adapters.csproj`)
as a **build-time project reference**; the published output carries the
compiled kernel assemblies, so a client machine needs only the published
directory (plus the .NET runtime in framework-dependent form; use
`--self-contained -r win-x64` for a no-prerequisite artifact).

## Steps

```powershell
# 1. Project (full mechanics) — regenerates the emitted sources in the workspace
sfx capability project resolve-equity-market-price-evidence `
    --workspace embodiments\resolve-equity-market-price-evidence `
    --targets csharp --full-mechanics

# 2. Build and install (from the projected csharp directory)
$root = Join-Path $env:LOCALAPPDATA 'sfx\capabilities\resolve-equity-market-price-evidence'
dotnet publish ProjectedConsumerTest.generated.csproj -c Release -o $root
dotnet publish ProjectedConsumerCli.generated.csproj  -c Release -o $root

# 3. Run with fixtures (from the install root)
ProjectedConsumerTest.exe
ProjectedConsumerCli.exe --fixture=equity-qqq-evidence-resolves
```

## Receipts (2026-09-17)

- `ProjectedConsumerTest.exe` → **`PROJECTED_CAPABILITY_CONFORMS`**, exit 0.
  The fixture `equity-qqq-evidence-resolves` executed all ten declared
  operations natively (mechanic, provider and physical cells), produced
  `disposition: terminated`, and reported `EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE`
  with `exchangeCount: 0`, `transportDisposition: denied` — the projected body
  has no credential reader, so no live effect is reachable by construction.
- `ProjectedConsumerCli.exe --fixture=equity-qqq-evidence-resolves` → the same
  outcome JSON, exit 0.

Projection state it ran against: `PURE_PROJECTION_CONFORMS`, 12 documents / 52
files, canonical graph digest `sha256:e2d87ee2…4f67af`, 227/227 bindings
(estate `f80c68f`; schema admission SDA `fa35b99`; fixtures repair estate
`7fa3d89`).

## What this establishes

- The built body executes the declared capability graph on .NET with the same
  ten-operation structure the estate runs; the emitted sources are
  content-addressed build inputs, not hand-authored code.
- The install is a directory copy: no database, no Node runtime, no SDA
  checkout is required to **run** a previously published artifact (the
  build-time project reference is the only source dependency and disappears
  after publish).
- Fixtures are the client-run acceptance: deterministic declared facts, no
  network, no credentials. Live effects remain a governed runtime concern, not
  an install concern.

## Flywheel shape (next turns)

1. A release command that projects, publishes, and installs in one step
   (`scripts/install-projected-csharp.mjs`) with a manifest/digest receipt.
2. Replace the build-time project reference with the pinned adapter DLLs so the
   build needs no SDA source either.
3. Project the remaining capabilities and targets the same way; the installed
   set becomes the client's capability surface.
