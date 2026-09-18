# Kernel install matrix — one installed kernel executable per host, selected as data

**Status.** Defined 2026-09-18 (K6). This is the durable recipe for building,
installing and selecting the SDA Kernel physical entry per host OS. It records
the matrix, the manifest an install is admitted by, the host-selection data
contract (config/boot data, not code branching), and the acceptance owed per
OS. It builds nothing by itself; no claim below is made beyond what is cited.

**Scope and honesty.** This machine is Windows x64 with .NET SDK `10.0.202`.
Only a `win-x64` executable can be executed here, so only `win-x64` can carry a
live-invoke acceptance. Every macOS/Linux row is **owed**, not observed; a
cross-RID `dotnet publish` on this machine is build evidence at most, never
runtime acceptance.

**Authorities.** SDA physical entries at `9ff6dc0`
(`languages/typescript/src/kernel/bootstrap/entry.mjs`,
`languages/python/src/scenario_kernel/kernel/bootstrap/entry.py`,
`languages/csharp/src/ScenarioKernel/bootstrap/KernelEntry.cs`); the recorded
cross-language parity in that commit and its conformance tests; estate
`docs/vault-manager-capabilities.md` §3/§4 (one credential contract, per-OS
realizations, two-roof key custody); `docs/embodiment-completeness.md`
(per-target parity); `docs/projected-csharp-install.md` (install-root
precedent); `docs/target-architecture.md` (boot is the only code).

**Ownership.** The publish/install tool and the C#/Python seams are another
agent's units (K4/K5 below). This doc does not edit
`languages/csharp/**`, `languages/python/**`, or estate config; the interfaces
and seams are stated in §6 and §7.

---

## 1. The matrix

The kernel build is the same declared kernel per host; only the language
build (C# by default) and the runtime identifier differ. The carrier is one
contract on every host (`sfx-command-delivery.v1` closed envelope on stdin
with `--stdin-envelope`; JSON outcome on stdout; exit 0/2/3/4).

| Host | Kernel language build | RID | Publish recipe (from SDA root) | Install root | Vault realization |
|---|---|---|---|---|---|
| Windows x64 | **C#** `ScenarioKernel` (net10.0, `OutputType=Exe`) | `win-x64` | `dotnet publish languages/csharp/src/ScenarioKernel/ScenarioKernel.csproj -c Release -r win-x64 --self-contained -o <staging>` | `%LOCALAPPDATA%\sfx\kernel\<digest>\` | `windows-credential-store-provider` — DPAPI/CNG (TPM when present); store `%LOCALAPPDATA%\sfx\vault` |
| macOS arm64 | **C#** `ScenarioKernel` | `osx-arm64` | `dotnet publish languages/csharp/src/ScenarioKernel/ScenarioKernel.csproj -c Release -r osx-arm64 --self-contained -o <staging>` | `~/Library/Application Support/sfx/kernel/<digest>/` | `macos-keychain-credential-store-provider` — Keychain; store `~/Library/Application Support/sfx/vault` |
| macOS x64 | **C#** `ScenarioKernel` | `osx-x64` | same, `-r osx-x64` | `~/Library/Application Support/sfx/kernel/<digest>/` | `macos-keychain-credential-store-provider` — Keychain |
| Linux x64 | **C#** `ScenarioKernel` | `linux-x64` | same, `-r linux-x64` | `${XDG_DATA_HOME:-~/.local/share}/sfx/kernel/<digest>/` | `linux-secret-service-credential-store-provider` — Secret Service / TPM; store `${XDG_DATA_HOME:-~/.local/share}/sfx/vault` |
| Linux arm64 | **C#** `ScenarioKernel` | `linux-arm64` | same, `-r linux-arm64` | `${XDG_DATA_HOME:-~/.local/share}/sfx/kernel/<digest>/` | `linux-secret-service-credential-store-provider` — Secret Service / TPM |

`<digest>` is the manifest's `artifactDigest` (§2); install directories are
immutable and digest-named. `<staging>` is a scratch directory under the
install root's parent; the installer computes the digest there, then renames
to `<digest>` (and reports `ALREADY_INSTALLED` without overwrite on a digest
that already exists).

**Fallbacks (recorded, never implicit).** C# is the default because the entry
exists with the recorded parity triple. Where a host has no admitted C# build,
the declared fallback chain is Node first, then Python; the chain is data in
the host record (§3), not a code branch:

| Fallback | Build | Invocation | Install root | Status |
|---|---|---|---|---|
| Node (reference) | none (source/runtime) | `node languages/typescript/src/kernel/bootstrap/entry.mjs --stdin-envelope` | source tree, or a staged tree carrying the declared kernel path | live today on this host; the estate delivery already runs it |
| Python | none (package) | `python -m scenario_kernel.kernel.bootstrap.entry --stdin-envelope` | `pip install` target or staged `src/` on `PYTHONPATH` | in-tree entry and tests exist (`9ff6dc0`); no installed form admitted |

Node offers the observation channel (`SIDEFX_OBSERVE=1` → `SFX_OBSERVATION`
lines on stderr); C# and Python currently refuse it with
`OBSERVATION_CHANNEL_NOT_OFFERED_BY_CARRIER:<language>`. See §4 and §6.

---

## 2. The install manifest

No manifest schema exists yet in either repo; K4 emits it. K6 fixes these
fields as the admission contract. `manifestDigest` is the SHA-256 of the
stable JSON serialization of the manifest with `manifestDigest` removed
(keys sorted ordinal, no insignificant whitespace, UTF-8). `artifactDigest` is
the SHA-256 of the published tree: for every file, relative path (with `/`),
then the file's SHA-256, one `path<TAB>hash` line per file, sorted ordinal,
LF-terminated; directory entries excluded.

| Field | Required | Meaning |
|---|---|---|
| `manifestType` | yes | `sfx-kernel-install-manifest.v1` (proposed) |
| `kernelLanguage` | yes | `csharp` (default), `node`, `python` |
| `kernelSpecification` | yes | `scenario-kernel.v1` (the binding manifests' value) |
| `hostOs` | yes | `windows` \| `macos` \| `linux` |
| `hostArch` | yes | `x64` \| `arm64` |
| `rid` | yes | `win-x64` \| `osx-arm64` \| `osx-x64` \| `linux-x64` \| `linux-arm64`; absent for Node/Python fallbacks |
| `entryPoint` | yes | relative path (`ScenarioKernel.exe`, `ScenarioKernel`, `entry.mjs`) |
| `entryArgs` | yes | e.g. `["--stdin-envelope", "--config", "kernel-host.json"]` |
| `carrierContract` | yes | `sfx-command-delivery.v1` |
| `observationChannel` | yes | `{stream, prefix, status}` — `status: OFFERED \| OWED` (Node `OFFERED`; C#/Python `OWED` today) |
| `sdaRevision` | yes | SDA commit the build was published from (`git rev-parse HEAD`) |
| `publishCommand` | yes | the exact command run, replayable |
| `artifactDigest` | yes | tree digest above; names the install root |
| `manifestDigest` | yes | digest of this manifest without this field |
| `vaultRealization` | yes | `{providerProfileId, keystore, storeLocator, module, status}` |
| `parity` | yes | `{fixture, observedPathDigest, canonicalGraphDigest, realizedGraphDigest}` |
| `conformanceReceipt` | yes | retained path/digest of the per-OS conformance run |
| `publishedAt` | audit | ISO timestamp; never part of selection semantics |

Example (`win-x64`, fields illustrative except the recorded digests in
`parity`):

```json
{
  "manifestType": "sfx-kernel-install-manifest.v1",
  "kernelLanguage": "csharp",
  "kernelSpecification": "scenario-kernel.v1",
  "hostOs": "windows",
  "hostArch": "x64",
  "rid": "win-x64",
  "entryPoint": "ScenarioKernel.exe",
  "entryArgs": ["--stdin-envelope", "--config", "kernel-host.json"],
  "carrierContract": "sfx-command-delivery.v1",
  "observationChannel": { "stream": "stderr", "prefix": "SFX_OBSERVATION", "status": "OWED" },
  "sdaRevision": "<commit>",
  "publishCommand": "dotnet publish languages/csharp/src/ScenarioKernel/ScenarioKernel.csproj -c Release -r win-x64 --self-contained -o <staging>",
  "artifactDigest": "sha256:<tree digest>",
  "manifestDigest": "sha256:<manifest digest>",
  "vaultRealization": {
    "providerProfileId": "windows-credential-store-provider",
    "keystore": "DPAPI/CNG",
    "storeLocator": "%LOCALAPPDATA%\\sfx\\vault",
    "module": "languages/typescript/runtimes/node/windows-credential-store-provider.mjs",
    "status": "OBSERVED"
  },
  "parity": {
    "fixture": "say-hello-world",
    "observedPathDigest": "sha256:20864ba25e20de3698d3affd2303f6064a7f50528ae79db9c33f24847a7f70ba",
    "canonicalGraphDigest": "sha256:8b859397e5bf18f8d24580ecfb3859fedc09f4150a69b40f7447273cbb014931",
    "realizedGraphDigest": "sha256:f7655bd9b1897fb19e823a226f0e9538f7ec9f6c85a0374c0f0f866b999a72de"
  },
  "conformanceReceipt": "evidence/kernel/win-x64/<receipt>.json",
  "publishedAt": "2026-09-18T00:00:00Z"
}
```

---

## 3. Host selection as data

Nothing selects a kernel build in code. There are three data layers, all
already read by the existing boot/delivery path:

1. **The project delivery** (`sfx.config.json`, `sfx-project.v1`, read by the
   CLI `sidefx-cli/src/configuration.mjs`): a `deliveries.<id>` record of
   `{type: "process", command, args, cwd}`. `config/sfx.commands.json` maps
   surfaces (`database-invocation`, `database-projection`) to a delivery id.
   Today both deliveries hardcode `node .../entry.mjs`; that is the seam where
   the installed executable replaces the runtime command.
2. **The host record** (proposed `sfx-kernel-host.v1`, generated by the
   installer next to the project config): the selection datum.
   - `{deliveryId, hostOs, hostArch, manifestPath, manifestDigest, command,
     args, cwd, fallback[]}`.
   - `fallback[]` is an ordered list of `{manifestDigest, command, args}`.
     The chain is declared; the caller walks it on `KERNEL_BUILD_NOT_ADMITTED`
     only. There is no implicit fallback.
3. **The kernel boot config** (`sfx-database-memory-runtime.v1`, passed with
   `--config`): `sdaRoot`, `connectionCredentialReference`, `credentialVault`
   (`storeLocator`, `credentialStoreRealization {providerProfileId, module,
   export}`), `queryRowLimit`, `requestTimeoutMs`. This is where the per-OS
   vault realization and the installed tree's root are declared to the kernel.
   The Node entry accepts all of these keys (requires the credential-reference
   form and rejects the retired `connectionEnvironmentVariable` key); C# and
   Python accept `sdaRoot` and the bounds but still read the env form for the
   connection (seam §6.4).

**Selection rule (data).** The caller resolves `hostOs` + `hostArch` → the
host record; the host record names manifest and command; the caller verifies
`manifestDigest` and launches `command args` with `--stdin-envelope`. The
kernel language is a manifest field, never a caller branch. On a host with no
admitted manifest, the declared `fallback[]` chain is walked in order.

**Admission and pinning (replayable).** A build is admitted when:

- a publish log exists for the recorded `sdaRevision` + `rid` + command;
- `artifactDigest` recomputes from the published tree;
- `manifestDigest` matches the value pinned by the host record;
- the `parity` triple equals the recorded fixture triple;
- the SDA revision is pinned (no branch/dirty source: the tool refuses a dirty
  tree).

Replays re-run `publishCommand` at `sdaRevision` and compare `artifactDigest`;
a mismatch is `KERNEL_BUILD_DIGEST_MISMATCH` and fails closed. Changing an
admitted build means a new digest-named directory and a new pinned
`manifestDigest`; admitted directories are never mutated.

---

## 4. Acceptance per OS

**Parity bar.** For each admitted fixture (the recorded one is
`say-hello-world`), through both `capability invoke` and `capability observe`:

- the same carrier contract: closed `sfx-command-delivery.v1` envelope on
  stdin via `--stdin-envelope`; the same stdout result shape; the same exit
  codes (0 delivered / 2 usage / 3 not offered / 4 delivery-integrity); the
  same failure envelope (`disposition: failed`, `errorCode`);
- the same outcome digests: `observedPathDigest`
  `sha256:20864ba25e20de3698d3affd2303f6064a7f50528ae79db9c33f24847a7f70ba`,
  `canonicalGraphDigest`
  `sha256:8b859397e5bf18f8d24580ecfb3859fedc09f4150a69b40f7447273cbb014931`,
  `realizedGraphDigest`
  `sha256:f7655bd9b1897fb19e823a226f0e9538f7ec9f6c85a0374c0f0f866b999a72de`,
  and `authoritySource: DATABASE` with the one-session read counts (1
  connection / 1 pin / 1 reader switch / 7 queries);
- for `observe`, the selected-altitude `SFX_OBSERVATION` stream and the same
  outcome digests. The bar is only reachable where the observation channel is
  offered; C#/Python owe it (§6).

**Evidence required per OS** (retained under `evidence/kernel/<rid>/`):

1. publish log: the exact command with `-r <rid>` and its output;
2. the manifest JSON plus recomputed `artifactDigest` and `manifestDigest`;
3. a live invoke **from the installed root on that OS**: the executable path,
   the envelope, stdout and exit code, with the triple asserted;
4. a live observe from the installed root (when offered): stream capture plus
   the same triple;
5. per-OS conformance receipts (C# `dotnet test`, Python `pytest`, Node tests);
6. for live effects, a vault realization `store`/`apply` on that OS and a
   non-disclosure sweep mirroring `vault-manager-capabilities.md` V4.

**Status at K6.**

| Host / RID | Build evidence | Installed live invoke | Observe parity | Vault realization | Status |
|---|---|---|---|---|---|
| Windows x64 / `win-x64` | source-tree conformance and the parity triple recorded (`9ff6dc0`); **no published install yet** | **owed** (needs K4 tool) | **owed** (C# carrier refuses `SIDEFX_OBSERVE=1`) | DPAPI live (V3/V4 receipts) | partial |
| macOS arm64 / `osx-arm64` | owed | owed | owed | Keychain module owed (vault §6 V5) | owed |
| macOS x64 / `osx-x64` | owed | owed | owed | Keychain module owed | owed |
| Linux x64 / `linux-x64` | owed | owed | owed | Secret Service/TPM module owed | owed |
| Linux arm64 / `linux-arm64` | owed | owed | owed | Secret Service/TPM module owed | owed |
| Node fallback (any host) | n/a (runtime) | live on this host through the estate delivery | **offered** | Windows live | admitted fallback |
| Python fallback (any host) | in-tree entry/tests (`9ff6dc0`); no installed form | owed | owed (refuses today) | none | not admitted |

**Owed on this machine specifically.** Only `win-x64` can be executed here.
The `win-x64` publish + install + live invoke is owed to K4's tool. The other
four RIDs can be *published* from this machine only if the .NET runtime packs
resolve; even then the result is build evidence, and the row stays owed until
executed on its OS. No macOS/Linux acceptance is claimed from a Windows run.

---

## 5. Sequence and dependencies

K6 follows K4 (publish/install tooling) and K5 (the C#/Python seams); K6 is
the data/recipe layer they feed:

| Unit | Owns | K6 consumes |
|---|---|---|
| K4 | publish/install tool for the C# kernel per RID; emits the install tree and manifest | the tool's `--rid` / output-dir / manifest interface (§7), the manifest fields (§2), digest-named install roots (§1) |
| K5 | C#/Python seams: observation channel, vault credential boot parity, installed-path root resolution | observe parity becomes reachable; boot config can select the per-OS realization on C#/Python |
| K6 | this matrix, manifest contract, host-selection data contract, acceptance plan | — |

**What the per-OS work reuses.** One publish tool invoked five times with
`--rid`; one manifest schema and one digest rule; one carrier-conformance
suite (the same `say-hello-world` envelope and triple); one host record and
one fallback chain; one vault contract with one realization module per OS
(the capability rows never change per OS, per vault §3). The only per-OS code
is the vault realization body named by data.

**Install-root resolution seam.** All three entries currently resolve their
SDA root from their own source location (`runtime-configuration.mjs:16`,
`runtime_configuration.py:18`, `RuntimeConfiguration.cs:26,58`), and the
mechanic registries read authority JSON under `sdaRoot`
(`MechanicRegistry.cs:17,21`, `mechanic_registry.py:19`, and the Node
loader). An installed tree under `%LOCALAPPDATA%` will not satisfy
`FindRepositoryRoot`/`parents[6]`. The install must therefore ship a boot
config with `sdaRoot` pointing at an admitted root (source checkout or a
staged copy of the declared registry authorities) and the entry must accept
it; closing that is K5.

---

## 6. Seams reported, not edited

1. **No publish/install tool.** Does not exist; interface required in §8.
2. **Estate host selection not yet data.** `sfx.config.json` deliveries
   hardcode `node .../entry.mjs`; the host record (§3) and the delivery
   template are estate-config edits owned by K4/orchestrator.
3. **Observation channel absent in C#/Python.**
   `KernelEntry.cs:460`, `command_carrier.py:139`,
   `CommandCarrier.cs:137` refuse `SIDEFX_OBSERVE=1`
   (`OBSERVATION_CHANNEL_NOT_OFFERED_BY_CARRIER:<language>`). Observe parity is
   unreachable until K5.
4. **C#/Python boot credential contract is the retired env form.**
   `RuntimeConfiguration.cs:21` and `runtime_configuration.py:20` use
   `sidefx-connection-string`; the Node boot at `9ff6dc0` resolves
   `DB_CONNECTION_STRING` from the declared vault and rejects the env key
   (`runtime-configuration.mjs:17,62`). C#/Python vault parity is K5.
5. **Node per-OS realization defaults are Windows-only.**
   `runtime-configuration.mjs:18,20-24` default the store locator to
   `%LOCALAPPDATA%\sfx\vault` and the realization to
   `windows-credential-store-provider`; per-OS host data must override both
   (vault §3: realization selection is data).
6. **macOS/Linux vault realizations do not exist** (vault §6 V5):
   `macos-keychain-credential-store-provider`,
   `linux-secret-service-credential-store-provider`.
7. **Installed-root root resolution** (§5): source-location root discovery
   and `sdaRoot`-relative registry reads must accept the installed tree.
8. **Cross-RID publish prerequisites.** `dotnet publish` for a non-host RID
   needs the matching runtime packs (network/NuGet); the tool must report a
   clear failure (`KERNEL_RUNTIME_PACK_UNAVAILABLE`) rather than produce a
   partial tree.
9. **Manifest schema.** `sfx-kernel-install-manifest.v1` is proposed here;
   no schema file exists in either repo. K4 emits it; a schema is owed with
   the tool.
10. **Windows arm64** is outside this matrix (not in the requested host set);
    adding it is a new RID row and a new manifest, no code change.

---

## 7. Required publish-tool interface (K4)

The tool is a process invoked once per RID; it must not edit
`languages/csharp/**`, `languages/python/**` or estate config, and must be
deterministic (same SDA revision + RID → same `artifactDigest`; .NET
reproducible builds are the default). Required interface:

```
<tool> --rid <rid> --output-dir <dir> --manifest <file>
       [--source-root <SDA checkout>]
       [--self-contained true|false]   # default true
       [--kernel-language csharp]      # default csharp
```

| Option | Required | Contract |
|---|---|---|
| `--rid` | yes | one of `win-x64`, `osx-x64`, `osx-arm64`, `linux-x64`, `linux-arm64`; maps to `-r <rid>`. Unknown value → `KERNEL_RID_UNSUPPORTED`; omitted → `KERNEL_RID_REQUIRED` (no implicit host inference in the tool; host selection is data, §3) |
| `--output-dir` | yes | install root. The tool publishes to a staging directory, computes `artifactDigest`, renames into `<output-dir>/<artifactDigest>/`, and refuses to overwrite an existing digest (`ALREADY_INSTALLED`, verify only). `output-dir` itself is the OS convention from §1 |
| `--manifest` | yes | manifest output path; canonical default `<output-dir>/<artifactDigest>/kernel-install-manifest.json`. The tool writes the §2 fields, computes `manifestDigest`, and exits 0 only after the manifest write succeeds |
| `--source-root` | optional | SDA checkout; default `SDA_ROOT` or the repository relative path. Refuses a dirty tree (`KERNEL_SOURCE_DIRTY`) and records `sdaRevision` |
| `--self-contained` | optional | default `true` (no runtime prerequisite on the target host) |

**Publish body per RID** (the recorded `publishCommand`):

```
dotnet publish languages/csharp/src/ScenarioKernel/ScenarioKernel.csproj \
  -c Release -r <rid> --self-contained -o <staging>
```

**Stdout receipt** (so orchestrators can pin without parsing the tree):

```json
{ "rid": "win-x64", "outputDir": "...", "manifest": "...",
  "manifestDigest": "sha256:...", "artifactDigest": "sha256:...",
  "sdaRevision": "...", "status": "INSTALLED" }
```

The tool does not launch the executable; the per-OS acceptance invocations
(§4) are separate, retained receipts.
