# Cross-host kernel acceptance runbook — macOS

**Status.** Written 2026-09-18; **unexecuted** for macOS. This is the recipe the
installed-kernel acceptance path (`accept`) follows per host, with the exact
macOS commands per language (install → provision on Keychain → accept). No
macOS run has happened and none is claimed below; macOS rows stay owed until a
receipt exists on that host. The Windows live result and the WSL `linux-x64`
attempt are recorded in
`evidence/vault-20260916/cross-host/` (ignored tree) and in
`SDA:docs/kernel-architecture-achieved.md` §4.8. The Windows AppContainer
full profile is also live: the installed C# kernel's `accept` under
`SIDEFX_PROCESS_ISOLATION=appcontainer` returned `ACCEPTED` (all three
invocations matched) with `fsWriteEnforcement: appcontainer`, the
`internetClient` capability, `fsWriteAllowed: false` and the job-object child
block; receipt and process testimony are in
`evidence/vault-20260916/cross-host/windows-csharp-appcontainer/`.

**Authority.** SDA installer surfaces at
`languages/csharp/src/ScenarioKernel/Install/`,
`languages/python/src/scenario_kernel/kernel/install/kernel_install.py`,
`languages/typescript/src/kernel/install/kernel-install.mjs`; the macOS vault
realization in `languages/typescript/runtimes/node/macos-keychain-credential-store-provider.mjs`
and the native C#/Python Keychain bodies; this estate's
`docs/kernel-install-matrix.md` (§1 matrix, §2 manifest, §2.2 provision) and
`docs/vault-manager-capabilities.md` (one credential contract, per-OS
realizations).

---

## 1. The accept contract

All three installer surfaces carry the same mode:

```
<installer> accept [--install-root DIR] [--manifest FILE] [--timeout MS]
```

- It verifies the admitted install first (`sfx-kernel-install-manifest.v1`,
  `artifactDigest`, `manifestDigest`), then runs the entry's **declared
  delivery command** (`entryInterpreter` + `entryArgs`, `{installRoot}`
  resolved) with a closed `sfx-command-delivery.v1` envelope on stdin.
- The child environment has every credential name removed,
  case-insensitively: `DB_CONNECTION_STRING`, `RAPID_API_KEY`,
  `LOC_OPENAI_API_KEY`, `LOC_GEMINI_API_KEY`, `sidefx-connection-string`.
  The boot credential and provider credentials must resolve through the
  declared vault realization alone.
- The three recorded invocations and their compared readings:

| invocation | compared reading |
|---|---|
| `capability invoke say-hello-world --input {}` | observed `sha256:20864ba25e20de3698d3affd2303f6064a7f50528ae79db9c33f24847a7f70ba`, canonical `sha256:8b859397e5bf18f8d24580ecfb3859fedc09f4150a69b40f7447273cbb014931`, realized `sha256:f7655bd9b1897fb19e823a226f0e9538f7ec9f6c85a0374c0f0f866b999a72de` |
| `capability invoke resolve-equity-market-price-evidence --display --input AVGO` | observed `sha256:c507678e9cd9600d502a2f86f3fbc9d0c102270be93a571926efc605c19879eb` and a live AVGO payload (`symbol`, `observedPrice > 0`, `marketState`) |
| `capability observe request-capability-from-objective --input "What is Broadcom's current market price?" --json` | observed `sha256:26c85c04c7ed278950d5d108b8568232cb00a742ebb7f3db3c76a8fc0accfb73`, overlay and story present |

- On success it writes the manifest-stamped receipt
  `sfx-kernel-acceptance.v1` to
  **`<installRoot>/kernel-acceptance-receipt.json`** (next to
  `kernel-install-manifest.json`), receiving `status: ACCEPTED` and exit 0.
  Any digest mismatch, non-terminated delivery, timeout, or unresolvable
  entry arguments writes `status: REJECTED` and exits 4. The receipt is
  installer metadata (excluded from the artifact digest), so the admitted
  tree still `verify`s after acceptance.
- The macOS acceptance additionally proves the macOS realization:
  `macos-keychain-credential-store-provider` (Keychain, service
  `sfx-credential-vault`, account = the credential reference), locator
  `~/Library/Application Support/sfx/vault`.

**Provider credentials.** The first `provision` stores only
`DB_CONNECTION_STRING` (the session needs it and cannot fetch it through a
capability). `RAPID_API_KEY` and the model keys must be stored through the
declared `store-credential` capability once the DB is reachable (estate CLI /
vault manager), not through the environment; acceptance is meaningful only
once the vault serves them.

---

## 2. Preconditions (all languages)

- SDA checkout pinned at the revision being accepted; `git` on PATH.
- Host tools: .NET SDK 10 (`dotnet --list-sdks`), Python 3.11+ (the Python
  kernel requires `tomllib` and the `pyodbc`/`cryptography` distributions), or
  Node 20+ with the repo's `node_modules` installed.
- The macOS login keychain is unlocked for the invoking user; the Secret
  Service analogue does not exist here.
- The database named by the real `DB_CONNECTION_STRING` is reachable from the
  mac, and the one-time secret is supplied on **stdin** (never an argument or
  environment variable).
- Install root convention: `~/Library/Application Support/sfx/kernel/<artifactDigest>`.

---

## 3. C# (default kernel on macOS)

```bash
SDA=~/src/scenario-driven-architecture
RID=osx-arm64                      # or osx-x64
OUT="$HOME/Library/Application Support/sfx/kernel"

# 1. install (publishes self-contained, admits by digest, writes the manifest)
dotnet run --project "$SDA/languages/csharp/src/ScenarioKernel/ScenarioKernel.csproj" -c Release -- \
  install --rid "$RID" --output-dir "$OUT" --allow-dirty
# note the reported installRoot, then:
ROOT="$OUT/<artifactDigest-hex without sha256:>"

# 2. verify
"$ROOT/KernelEntry" verify --install-root "$ROOT"

# 3. provision the ground credential on Keychain (secret on stdin)
printf '%s\n' "$DB_CONNECTION_STRING_ONCE" | \
  "$ROOT/KernelEntry" provision --install-root "$ROOT"

# 4. accept (three invocations, credentials absent, receipt written)
"$ROOT/KernelEntry" accept --install-root "$ROOT"
```

Receipt: `$ROOT/kernel-acceptance-receipt.json` (`sfx-kernel-acceptance.v1`).
The C# installer surface is compiled into `KernelEntry`; the `accept` mode
dispatches through the same physical-entry registration as
`install|verify|switch|provision` (the registration itself is the minimal
physical-entry seam; without it the surface is still reachable in-process).

The process-isolation profile is boot data: `SIDEFX_PROCESS_ISOLATION` or the
boot configuration's `processIsolation` key selects `off`, `low-integrity`
(the Windows host default) or `appcontainer`. The AppContainer profile
re-execs the entry under the per-user `sfx.scenario.kernel` container with
only the `internetClient` capability, grants the container SID read/execute
on the entry directory, stages the declared vault ciphertext and wrapped key
records into the container's own storage, and denies host filesystem writes;
a selected profile that cannot be applied fails closed.

## 4. Python

```bash
SDA=~/src/scenario-driven-architecture
RID=osx-arm64
OUT="$HOME/Library/Application Support/sfx/kernel"
PY="$SDA/languages/python/.venv/bin/python"   # 3.11+, with pyodbc and cryptography

# 0. toolchain
python3 -m venv "$SDA/languages/python/.venv"
"$PY" -m pip install pyodbc cryptography

# 1. install (stages the installed distribution closure into site-packages)
"$PY" "$SDA/languages/python/src/scenario_kernel/kernel/install/kernel_install.py" \
  install --rid "$RID" --output-dir "$OUT" --allow-dirty
ROOT="$OUT/<artifactDigest-hex without sha256:>"

# 2. verify
"$PY" "$SDA/languages/python/src/scenario_kernel/kernel/install/kernel_install.py" \
  verify --install-root "$ROOT"

# 3. provision (the CLI imports the platform realization from the source tree)
printf '%s\n' "$DB_CONNECTION_STRING_ONCE" | \
  env PYTHONPATH="$SDA/languages/python/src" \
  "$PY" "$SDA/languages/python/src/scenario_kernel/kernel/install/kernel_install.py" \
  provision --install-root "$ROOT"

# 4. accept (the source installer surface owns the mode; the installed
#    KernelEntry.py is the capability carrier, not the installer)
env PYTHONPATH="$SDA/languages/python/src" \
  "$PY" "$SDA/languages/python/src/scenario_kernel/kernel/install/kernel_install.py" \
  accept --install-root "$ROOT"
```

Receipt: `<ROOT>/kernel-acceptance-receipt.json`. The manifest records
`entryInterpreter` as the absolute venv interpreter that performed the
install; keep that venv in place.

## 5. Node

```bash
SDA=~/src/scenario-driven-architecture
RID=osx-arm64
OUT="$HOME/Library/Application Support/sfx/kernel"
NODE=node                        # 20+

# 0. toolchain (the installer runs the TypeScript build and stages node_modules)
(cd "$SDA" && npm ci)

# 1. install (runs the TypeScript build, stages node_modules)
"$NODE" "$SDA/languages/typescript/src/kernel/install/kernel-install.mjs" \
  install --rid "$RID" --output-dir "$OUT" --source-root "$SDA" --allow-dirty
ROOT="$OUT/<artifactDigest-hex without sha256:>"

# 2. verify
"$NODE" "$SDA/languages/typescript/src/kernel/install/kernel-install.mjs" \
  verify --install-root "$ROOT"

# 3. provision on Keychain (the macOS realization shells out to `security`)
printf '%s\n' "$DB_CONNECTION_STRING_ONCE" | \
  "$NODE" "$SDA/languages/typescript/src/kernel/install/kernel-install.mjs" \
  provision --install-root "$ROOT" --source-root "$SDA"

# 4. accept
"$NODE" "$SDA/languages/typescript/src/kernel/install/kernel-install.mjs" \
  accept --install-root "$ROOT"
```

**Node non-Windows permission model.** The osx/linux manifests now record the
admitted entry under Node's permission model: `--experimental-permission`
with read grants for the install root, authority and host vault roots and no
`--allow-fs-write`, so `accept` resolves the declared delivery command there.
The manifest-resolution test asserts those flags for all four non-Windows
RIDs. The macOS acceptance itself remains unexecuted on a Mac and owed until a
receipt exists on that host; step 3 (provision) is unaffected and can still be
verified on macOS.

---

## 6. Receipt and evidence per host

Retain under `evidence/<date>/cross-host/<rid>/` (this estate ignores
`evidence/`):

1. the install stdout (installRoot, `artifactDigest`, `manifestDigest`);
2. `<ROOT>/kernel-install-manifest.json` and
   `<ROOT>/kernel-acceptance-receipt.json`;
3. the `verify` and `provision` stdout;
4. any credential non-disclosure sweep proving the child environment carried
   no credential name.

No macOS step in this document has been executed; the first macOS run is
expected to produce the receipt at
`<ROOT>/kernel-acceptance-receipt.json` with the three digests in §1.
