# Vault manager capabilities — research and implementation strategy

**Status.** Research completed 2026-09-16. This is the deep-dive behind
[next-experiences.md](next-experiences.md) §4. It answers one question: **what
does it take to declare `store-credential` and `resolve-credential` as SideFX
capabilities**, with a local encrypted vault, an OS-protected key, ephemeral
secrets, and no secret ever in the model, the CLI output, or testimony.

**The target model (user's words).** "Two capabilities. One is store
credential, which takes plain input and passes it to a local vault provider that
encrypts it. Then resolve credential is a second capability that takes a
credential requirement and returns an ephemeral secret, not something that's
stored anywhere, that can hand off to the provider. For your current vault, I
definitely use an OS-protected key to protect the vault's master key. Don't put
the decryption key inside the same file. That would fit pretty cleanly with the
existing model. Capabilities declare they need a credential and providers
satisfy that. The model doesn't ever see the secret. The CLI doesn't print it
and testimony never records it."

**The refinement (user's words, second pass).** "A public key doesn't unlock a
private key. … The database can store encrypted key material, but it shouldn't
also store everything needed to decrypt it. Otherwise someone stealing that
database gets both halves. Instead, have the database hold only the encrypted
secret, while the decryption key is protected by something outside the
database. Ideally the OS's secure key store. That way your specific resolve
credential capability can unwrap the secret just in time, pass it to the
provider in memory, and then forget it. In SideFX terms, the outcome isn't
reveal secret. It's credential applied to authorized provider invocation. So
yes, split the key material, but don't put decryption entirely under the same
roof as the ciphertext. The good news is, the pattern works across operating
systems, but the physical keystore integration changes. So I think about it
through the provider lens. On Windows You'd resolve to something like DPAPI or
CNG, on Mac Keychain, on Linux, whatever Secret Service or TPM option you
standardize on. The key is, don't bake any of that into the capability. Keep
the vault — or rather the credential capability — semantic and let each OS be
just another provider behind it. Same contract, different provider realization.
That way the same SideFX capability works on Mac, Windows, Linux, and tomorrow
maybe a cloud secret manager without changing the capability itself. That's
very on brand for the provider architecture we just walked through."

**Invariants.** (1) Rows never carry plaintext. (2) The invocation channel never
carries plaintext to the caller: no CLI output, no testimony, no evidence body,
no logs. (3) The plaintext exists only inside the credential provider's call
and the exchange-header injection, in one process, for one use. (4) The store
holds ciphertext and the unwrap key is held by the OS keystore — never both
halves under one roof. (5) There is no reveal outcome: the result of resolving a
credential is *credential applied to an authorized provider invocation*.
(6) The capability is semantic; the OS keystore is a provider realization
behind one contract, so the capability rows are identical on Windows, macOS,
Linux and a future cloud secret manager. (7) No SDA edits from this repo
(cross-language ⇒ SDA change request).

---

## 1. Current state — what exists today

### 1.1 The credential mechanic (the resolve half, partly)

`SDA:languages/typescript/runtimes/node/external-credential-reference-binding-provider.mjs`
is the one credential-reference port. Shape:

- It requires `credentialReference`, `invocationIdentity`,
  `requestingCapabilityId`, `endpointAuthorityDigest`, `effectScope` (line 31).
- The port **configuration** declares `credentialAuthorities[]`:
  `referenceName`, `source`, `effectScopes`, `requestingCapabilityIds`,
  `endpointAuthorityDigests`, `injectionRule {id, headerName}`.
- Authority checks admit the requesting capability, the endpoint digest and the
  scope; a mismatch returns `IDENTITY_MISMATCH` (line 42).
- `source` must be `"environment"` today (line 44) — the vault source is
  rejected before resolution.
- Resolution reads `effectContext.credentialReader(referenceName)` (line 47) —
  default `referenceName => process.env[referenceName]`
  (`native-mechanic-primitives.mjs:22`).
- The value goes into `effectContext.credentialBindings` under a random
  `opaqueBindingId` with an expiry (default 120 s; lines 51–65), and the
  evidence returns only `opaqueBindingId`, `referenceName`, scope, the rule id
  and `nonDisclosureVerified: true` (lines 3–17).
- The HTTP exchange provider consumes the binding exactly once
  (`credentialBindings.delete`, `governed-http-exchange-provider.mjs:51`),
  re-checks identity/digest/rule/header, injects the header
  (line 116), and never exposes the value.

So the one-use opaque binding, the non-disclosure evidence contract, and the
injection path **already exist and are proven live** (equity run:
credential `BOUND`, exchange completed). What does not exist: a vault source, a
store half, and a way to inject a vault-backed reader.

### 1.2 Precedent — the candidate-authoring conveyor already binds Gemini (installed)

The "capabilities declare they need a credential and providers satisfy that"
pattern is not aspirational; it is declared and running. The live model (queried
2026-09-16) shows:

- **`bind-external-credential-reference`** — a declared capability whose port
  (`bind-credential-reference-port`, `sda-external-credential-reference-binding-port.v1`)
  carries `credentialAuthorities[]` for Gemini and OpenAI: reference names
  `LOC_GEMINI_API_KEY` / `LOC_OPENAI_API_KEY`, endpoint authority digests
  `sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04` /
  `sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109`,
  effect scope `governed-model-invocation`, injection rules
  `gemini-x-goog-api-key.v1` / `openai-bearer-authorization.v1`, a 120 s binding
  lifetime, and the admitted requesting capabilities (`execute-governed-model-invocation`,
  `obtain-governed-model-response`, `author-tooling-capability-candidate`,
  `execute-projected-model-provider-attempt`) — all with
  `source: "environment"`.
- **The candidate-authoring conveyor** (`obtain-governed-model-response` and the
  `*-conveyor` capabilities) stages its credential-bind requests as declared
  literals: `stage-os-credential-bind-request.v1` builds
  `{credentialReference: "LOC_GEMINI_API_KEY", endpointAuthorityDigest:
  "sha256:57ab352b…", effectScope: "governed-model-invocation",
  requestingCapabilityId: "obtain-governed-model-response"}` and the bind
  operation resolves it into the one-use binding the exchange consumes.

So the vault manager does **not** need a new provider-connection authoring
shape: it changes the credential *source* under an installed declaration
(`source: "environment"` → a vault source, or a vault-backed reader), and adds
the store half. Endpoint digests, scopes, injection rules, admitted
capabilities, the ephemeral binding and the non-disclosure evidence all stay as
declared; `LOC_GEMINI_API_KEY` moves from the environment into the vault under
the same reference name, and nothing else in the conveyor's declaration moves.

### 1.3 Where the effect context comes from — and the dead injection seam

- `semantic-execution-graph-effect-provider.mjs` builds **one**
  `effectContext` per invocation (line 17) and passes it to the credential and
  exchange ports (line 24). Those two ports are the entries of the
  `PLATFORM_EFFECT_PORTS` map (lines 11–14). One context, one binding map —
  that is why the credential binding is visible to the exchange.
- The factory accepts a host: `createPlatformEffectProvider(host)` and reads
  `host.effectContext` (line 17); `host.effects` can override the port map
  (line 22).
- The factory is invoked with the **estate loader's context**
  (`semantic-execution-graph-execution-provider.mjs:70`:
  `providerExport(context)` for `factory: true`).
- The estate loader already threads an override:
  `src/invoke-database-capability.mjs:259,307` accepts
  `effectContextOverrides` and places it on the context — **but no SDA code
  consumes it** (verified: no `effectContextOverrides` reference exists under
  SDA). It is a dead seam: the intended injection point, unwired.

Consequence: a vault-backed `credentialReader` cannot be supplied from
configuration today (functions are not serializable); it needs either the SDA
factory to consume the override, or a vault port inside the kernel that does its
own resolution. This is the central finding of this research.

### 1.4 The other resolvers, and their limits

- `os-environment-credential-provider.mjs` (`sda-os-environment-credential-port.v1`)
  resolves process env → `HKCU\Environment` → machine env, and **re-broadcasts
  the value into `process.env`** (line 75) — the defect
  [next-experiences.md](next-experiences.md) §4 already names. It also builds a
  private binding map per call (line 53), so its binding is not visible to the
  exchange path; it is a legacy shape.
- Only node has any OS-credential resolver; python/csharp have none
  (research findings: `docs/research/target-architecture/…Findings.md:450-493`).

### 1.5 The store precedent

`sda-filesystem-artifact-store.v1` (`filesystem-artifact-store-provider.mjs`,
registered `configuration`/`direct`) is the estate's model for a **store
effect**: it validates the destination root, refuses symlink/escape, writes
atomically (tmp + rename), and returns a *reference* (`path`, `sha256`,
`byteLength`) — never the content. A vault-store port is the same shape with
encryption at rest and vault-internal entry ids.

### 1.6 The boot's secret leaks (to remove, already classified)

- `src/database-delivery.mjs:30` copies the DB connection string into the
  delivery process env.
- Effect credentials resolve from env by default; the OS provider re-broadcasts.
- The CLI input channel already supports stdin: `sidefx-cli/src/cli.mjs:17`
  (`@file.json, or - for standard input`), so a secret can avoid argv and temp
  files today (`--input -`).

### 1.7 How platform capabilities are admitted

`kernel/semantic-authority/consumer/node-mechanic-registry.authority.v1.json`
maps `platformCapabilityId → providerModule/providerExport/invocation`. Effects
dispatch in the kernel via the two-entry port map; other mechanics dispatch via
`invokePlatformEffectMechanic` (`platform-effect-provider.mjs:243-250`, today
`read-file-bytes`, `execute-bounded-process`); `configuration`-kind entries are
resolved by the estate loader (`resolvePlatformMechanic`,
`src/invoke-database-capability.mjs:24-37`). A vault capability needs registry
entries either way.

---

## 2. The two capabilities

Both are ordinary declared capabilities (contracts, scenario, meaning,
interface, execution authority) authored through the JSON surface
(`model.declare_capability_document`) plus a migration, as A and B were. Neither
requires a transformation if the port's outcome payload is the terminal outcome
(the declared-read precedent: B's single-port scenario).

### 2.1 `store-credential`

**Intent.** Put a plaintext secret into the local vault under a reference name;
return a non-disclosing receipt.

| | |
|---|---|
| Input contract | `store-credential-request.v1`: `{referenceName, secret, scope?}` (additionalProperties false; `secret` is the only plaintext field) |
| Operations | one `invoke-port` → `sda-credential-vault-port.v1` `store` (configuration: store locator, allowed reference names, max secret bytes) |
| Outcome contract | `store-credential-result.v1`: `{referenceName, entryId, storedAt, formatVersion, nonDisclosureVerified}` — no secret, no digest of the secret |
| Variants | `CREDENTIAL_STORED` (success), `CREDENTIAL_STORE_REJECTED` (failure: sealed vault, unknown reference, policy) |
| CLI display | outcome as json; the input mapping must never echo `secret` |

**Plaintext lifetime.** The caller's envelope (stdin), the port call, the
encryption, then gone. It must not appear in: the outcome, cell testimony, the
observation stream, the invocation `evidence`, retained bundles, or any row.
The store port returns a reference only.

### 2.2 `resolve-credential`

**Intent.** Given a credential requirement, place an ephemeral one-use secret
into the authorized invocation's effect context so the provider consumes it in
memory and the invocation forgets it. **The outcome is not "secret revealed";
it is "credential applied to an authorized provider invocation."**

| | |
|---|---|
| Input contract | `resolve-credential-request.v1`: `{credentialReference, invocationIdentity, requestingCapabilityId, endpointAuthorityDigest, effectScope}` — the exact shape the credential port already requires |
| Operations | one `invoke-port` → `sda-credential-vault-port.v1` `apply` (same binding semantics as the existing credential port; source = vault realization) |
| Outcome contract | `resolve-credential-result.v1`: `{disposition, opaqueBindingId, referenceName, effectScope, invocationIdentity, endpointAuthorityDigest, expiresAt, nonDisclosureVerified}` — the result names the application (which authorized invocation the binding was placed for); the secret itself is not in the vocabulary |
| Variants | `CREDENTIAL_APPLIED` (success; classified from the port's `BOUND` evidence), `CREDENTIAL_NOT_AVAILABLE`, `UNAUTHORIZED_REFERENCE`, `IDENTITY_MISMATCH`, `VAULT_SEALED` (failure) |

**Precedent for this exact shape.** `bind-external-credential-reference`
(§1.2) is already the declared resolve capability with an environment source:
same input fields, same one-use binding, same non-disclosure evidence, and the
candidate-authoring conveyor already consumes it for Gemini. The vault work
generalizes its source, not its shape; whether the vault version is a new
capability or that capability with `source: "vault"` is open question 1.

**The hand-off rule.** A one-use binding lives in the invocation's effect
context; a separate CLI invocation cannot carry it (process boundary). Two
faithful hand-offs exist:

1. **Same scenario (works today, shippable first):** the capability that needs
   the secret declares the resolve operation immediately before its exchange
   operation — this is exactly the equity pattern; `resolve-credential` is that
   step, and a standalone invocation proves resolution without disclosure.
2. **Composition (SDA request R1):** a consumer scenario invokes the
   `resolve-credential` scenario as a child and consumes its outcome. This is
   the general "capabilities declare they need a credential" form; it waits on
   invoke-scenario composition.

The honest statement for the demo: **a standalone `resolve-credential`
invocation returns proof-of-application, never the secret.** "Returns an
ephemeral secret" is true kernel-internally (the binding holds it for the
authorized invocation) and false at the CLI boundary — there is no reveal
outcome to invoke, by design.

### 2.3 What "declares it needs a credential" means today

There is no first-class `requiresCredential` contract field. The declaration is
the credential port binding plus its `credentialAuthorities[]` (reference names,
scopes, admitted capabilities, endpoint digests, injection rule). The conveyor
already relies on exactly this shape for Gemini (§1.2), and the vault design
extends that configuration with the vault source and locator; it does not need a
new contract vocabulary.

---

## 3. The credential provider contract and its OS realizations

One new platform **contract**; the capability never names an OS and each OS is
just another provider realization behind it.

**The contract.** `sda-credential-vault-port.v1`, two operations:

- `store` — write `{referenceName, secret}` under the configured policy and
  return `{entryId, storedAt, formatVersion}` only.
- `apply` — resolve the reference into a one-use binding in the shared effect
  context of the authorized invocation and record
  `{disposition, opaqueBindingId, referenceName, effectScope,
  nonDisclosureVerified, realization}`. There is **no `reveal` operation**: the
  outcome is a credential applied to an authorized provider invocation, never a
  secret returned to a caller.

Configuration: `{storeLocator, allowedReferenceNames[], maximumSecretBytes,
referencePolicy}`. Evidence mirrors the existing credential port; nothing in
the contract mentions DPAPI, Keychain, TPM or a cloud KMS.

**The realizations.** Behind the same contract, one realization per keystore
family:

| Realization | Keystore | What it owns |
|---|---|---|
| `windows-credential-store-provider` | DPAPI / CNG / Credential Manager (TPM when present) | key custody, wrap/unwrap |
| `macos-keychain-credential-store-provider` | Keychain | key custody, wrap/unwrap |
| `linux-secret-service-credential-store-provider` | Secret Service / TPM | key custody, wrap/unwrap |
| `cloud-secret-manager-credential-store-provider` (future) | KMS / Secret Manager | remote unwrap |

The kernel already resolves provider realizations per target and host: the
mechanic registry maps a `platformCapabilityId` to the provider module, and a
plan's `realizationOverlay.providerBindings` resolves a profile through
`context.resolveProvider`
(`semantic-execution-graph-execution-provider.mjs:74-79`), with provider
profiles declared per estate — the same machinery the conveyor's provider
bindings use. The capability's rows are **identical on every OS**; only the
realization binding differs.

**Dispatch seam.** Two integration choices remain (open question 1): extend the
installed `bind-external-credential-reference` credential authority with
`source: "vault"` so it calls the realization, or consume
`host.effectContextOverrides` in `createPlatformEffectProvider` so the boot
injects a vault-backed `credentialReader` and the credential port is untouched.
Recommendation: the override seam first (smallest; preserves the proven
credential port), then the declared source once the realizations exist.

**Cross-language.** Node first (the registry's effect ports are node
implementations); python/csharp/java/go/c++ mirror the port in their runtimes.
Realizations are per language *and* per OS; capability declarations never
change.

---

## 4. Key custody and management

### 4.1 The split — ciphertext and key under different roofs

The rule: **whatever holds the encrypted secret must not also hold everything
needed to decrypt it.** A thief who takes the store gets ciphertext only.

```
ciphertext home (either):               key home (always):
  the store file                          the OS keystore, via the realization
    %LOCALAPPDATA%\sfx\vault\vault.json     DPAPI/CNG         (Windows)
  or the SideFX database as                 Keychain          (macOS)
    encrypted content rows                  Secret Service/TPM (Linux)
                                            cloud KMS         (future)
```

- A public key does not unlock a private key, and a wrapped blob beside the
  ciphertext is not a separate roof: the default is that the OS keystore
  **releases the key** (in memory, to the realization) rather than a sibling
  `.dpapi` file existing next to the store. A wrapped key file is acceptable
  only in the database-resident-ciphertext variant, where the two halves then
  genuinely sit under different roofs.
- Ciphertext: AES-256-GCM entries `{referenceName, keyVersion, nonce,
  ciphertext, tag, createdAt}`, fresh 12-byte nonce per write, AAD binding
  `{referenceName, keyVersion, vaultId}` so ciphertext cannot be moved between
  names. The database may hold the ciphertext (the model still never sees
  plaintext); it needs a semantic kind and is deferred (open question 7). The
  local store file lands first.
- Rotation: entries carry `keyVersion`; rotate re-wraps under a new master key
  released by the keystore.
- Writes: read-modify-write with tmp + rename (the artifact-store pattern);
  single-writer assumption, documented.

### 4.2 Where the unwrap happens

Inside the **provider realization**, not in the capability and not in declared
configuration: the realization talks to its OS keystore (DPAPI/CNG, Keychain,
Secret Service, KMS) and holds the in-memory handle the vault operations use,
dropping it with the process. This is irreducible 0 code per language and OS —
the same code the sealed-binary and per-language-bootstrap work will carry —
while the *selection* of the realization for the host is the ordinary provider
resolution path (§3).

For node on Windows the realization owns the choice: a native DPAPI/CNG module
first; bounded PowerShell `[System.Security.Cryptography.ProtectedData]` as the
zero-dependency fallback; Credential Manager via a `wincred`-class module as
the user-facing variant; TPM-bound keys when available. None of this is visible
to the capability, its contracts, or its declarations.

### 4.3 Honest threat boundary

The OS keystore (DPAPI CurrentUser on Windows) protects the key against
**other OS users and offline theft** (the store copied elsewhere yields
ciphertext only). It does **not** protect against a process running as the same
user — which includes the agent. So "the agent has no access to secrets" holds
on the *invocation channel* (the value is never returned, printed, streamed, or
retained) but not against an agent that deliberately calls the keystore API and
reads the store. Stronger boundaries (Windows Hello / Credential Manager
consent prompt / a vault daemon gating unwrap) are a separate decision; the doc
records this limit rather than hiding it. This is exactly why plaintext must
never reach the invocation boundary: the boundary is the guarantee's scope.

---

## 5. What it takes — classification

| Change | Class | Where |
|---|---|---|
| Credential vault **contract** (`store`/`apply`), evidence contract | **SDA request** | `PLATFORM_EFFECT_PORTS` or `invokePlatformEffectMechanic` + `node-mechanic-registry` |
| **Provider realizations** per OS (Windows DPAPI/CNG first, then Keychain, Secret Service/TPM, cloud KMS) | **provider realization (0 code per language+OS)** | one module per realization; selected through the registry / provider-profile bindings |
| Effect-context override consumed by the effect factory (`host.effectContextOverrides`) | **SDA request** (one seam) | `semantic-execution-graph-effect-provider.mjs:17` |
| `source: "vault"` on the credential authority (or equivalent realization reader) | **SDA request** | `external-credential-reference-binding-provider.mjs:44` |
| Remove the env re-broadcast | **SDA request** (with the vault landing) | `os-environment-credential-provider.mjs:75` |
| Realization selection for the host (which keystore provider binds) | **data** (provider profiles/bindings) | estate authority rows; capability rows never change per OS |
| Handle flow: keystore → realization → vault operations | **inside the realization** (boot only selects the realization) | estate loader threads `effectContextOverrides` (`invoke-database-capability.mjs:259,307`) |
| Contracts `store-credential-*`, `resolve-credential-*`; two capability documents; vault declaration (locator, names, scopes); variants; CLI display | **data** | JSON documents + one migration via `model.declare_capability_document` |
| Switch the installed credential authorities to the vault source (equity's `RAPID_API_KEY`; the conveyor's `LOC_GEMINI_API_KEY` / `LOC_OPENAI_API_KEY`) | **data** | `sql/migrations/` — one `source`/locator change per authority, nothing else moves |
| Remove the DB connection-string env copy; resolve at the connect boundary | **boot code** | `src/database-delivery.mjs:30` |
| Masked interactive secret prompt | **CLI** (optional; stdin already works via `--input -`) | `sidefx-cli` |

---

## 6. Implementation strategy

### V0 — this record (done)
Decision and mechanism research; no runtime changes.

### V1 — the contract and the first realization (node, Windows)
Primitive: `sda-credential-vault-port.v1` (`store`/`apply`) with AES-GCM,
keystore-agnostic (the realization supplies the key), evidence mirroring the
credential port, registry entries, the `effectContextOverrides` seam, and one
realization: `windows-credential-store-provider` (DPAPI/CNG key custody).
Accept: conformance tests for store→apply→exchange with a sentinel secret; the
sentinel absent from every evidence field; sealed store reports `VAULT_SEALED`;
wrong scope/digest/reference rejected; a second realization stub proves the
capability rows are unchanged when the realization swaps.

**Status: done** (SDA `e7b3864`, `bf5feb1`; estate boot W3 `0fb8660`). The
pinned native DPAPI module is loaded with the delivery's `--allow-addons`; with
no realization the port refuses with `VAULT_SEALED` and never falls back.

### V2 — Declared capabilities
Author `store-credential` and `resolve-credential` documents + migration
(§2). Accept: `sfx capability invoke store-credential --input -` stores; the
result contains no plaintext or digest of it; `resolve-credential` returns the
application outcome only (no reveal); `observe` streams no plaintext.

**Status: done and installed** (estate `4dd191f`; preflight store/apply green;
live `resolve-credential` returns `CREDENTIAL_BOUND` with realization
`windows-credential-store-provider` and no plaintext member).

### V3 — The live source switch
The installed credential authorities switched from environment to vault:
equity's `RAPID_API_KEY` and the conveyor's `LOC_GEMINI_API_KEY` /
`LOC_OPENAI_API_KEY`, with the Windows realization releasing the key from the
OS keystore. Accept: the equity invocation resolves via the vault and the
fallback route still resolves through real-time1; the conveyor's credential
bind still stages the same literals and the exchange injects the same headers
(`x-goog-api-key`), now from vault entries; none of the three names is present
in `process.env`.

**Status: done for every authority that can execute; one exchange blocked by
the frozen SDA.** All five installed authorities (equity primary and fallback,
Gemini, OpenAI reference and speech) are `source: "vault"` with the declared
locator; the transition unit stored each reference and proved `CREDENTIAL_BOUND`,
and the live equity invocation with the names absent from the environment
returned `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`. The live conveyor exchange
cannot execute on SDA `bf5feb1`: the graph path fails
`SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING: 'invoke-scenario'` (and, once
`invoke-scenario` is supplied diagnostically, `sda-projected-capability-
invocation-port.v2` / the `invocation: "llm"` connector dispatch). That is the
recorded SDA request R1/R2, not an estate data gap; the Gemini credential
requirement itself resolves from the vault (`CREDENTIAL_BOUND`, scope
`governed-model-invocation`).

### V4 — Non-disclosure proof
Sweep artifacts for the sentinel: invoke `--json`, `observe --trace` output,
`evidence/` bundles, the observation stream, and the database rows. Accept: a
recorded receipt that names every channel and shows the sentinel absent; a
negative receipt for a tampered store (GCM auth failure).

**Status: done** (W5 receipts). A random sentinel was stored under
`RAPID_API_KEY` and the executable vault paths driven through the CLI with the
names absent; every channel reports the sentinel absent (invoke `--json`,
`observe --trace` stdout and streamed observation lines, the `store-credential`
input channel, an equity provider exchange attempted with the sentinel,
7,105 `evidence/` files, 19 local delivery receipts, and the durable content
objects). The tampered vault copy returned `CREDENTIAL_NOT_AVAILABLE` (AES-GCM
authentication failure) with `nonDisclosureVerified: true`; the real value was
then restored and re-proved.

### V5 — Rotation, other realizations, consent
Rotation; macOS Keychain, Linux Secret Service/TPM and cloud KMS realizations;
python/csharp port implementations; a stronger unwrap consent boundary (§4.3)
if required. The capability rows do not change for any of these.

**Status: deferred** (unchanged scope).

**Dependencies.** V1 blocks V2; V3 needs V1's seam; V4 needs V3. The sealed
binary and per-language bootstraps carry the realization code — orthogonal but
shared.

---

## 7. Open questions (for the owner)

1. **Dispatch choice:** extend the installed `bind-external-credential-reference`
   with a vault source vs declare a new `resolve-credential` capability; and
   vault as a new effect port vs the credential port's `source: "vault"`
   (recommend: override seam first, then extend the installed capability's
   source — the conveyor's declarations then need one locator, not a rewrite).
   **Resolved:** both. A new `resolve-credential`/`store-credential` capability
   pair is declared (V2), the boot's override seam threads the realization
   (`effectContextOverrides.credentialStoreRealization`, W3), and the installed
   authorities' `source` was switched to `"vault"` with one locator each (W4).
2. **Windows realization:** native DPAPI/CNG module vs bounded PowerShell
   subprocess vs Credential Manager (recommend: native module, key held in
   DPAPI/CNG custody, never a sibling blob beside the store). Resolved for this
   host by §8: native module is needed now; the PowerShell path is deferred to a
   builder decision on the child-process confinement boundary.
   **Resolved and observed:** the pinned native module (`@primno/dpapi`) is used;
   the invocation delivery requires `--allow-addons` for it, and the key record
   is released into memory only. The PowerShell fallback remains deferred.
3. **Threat boundary:** is same-user process protection (agent can unwrap)
   acceptable for now, or is a consent gate required before the demo?
   **Resolved:** §4.3 is accepted; no consent gate (builder decision 4).
4. **Store location:** `%LOCALAPPDATA%\sfx\vault\` (recommend) vs a configured
   path; never the repo, never `%TEMP%`.
   **Resolved:** `%LOCALAPPDATA%\sfx\vault` is the declared locator; the boot
   resolves the environment reference before the kernel sees the configuration,
   so the ciphertext lands under the OS user profile, never the repo.
5. **Composition:** does `resolve-credential` need the invoke-scenario
   composition (R1) for the first version, or is resolve-and-use-in-one-scenario
   enough (recommend: enough).
   **Resolved:** enough for the credential work (equity is one scenario with
   port operations only; `resolve-credential` is a single port). The conveyor's
   own composition stays an SDA request (V3 status), not a vault dependency.
6. **Store input UX:** stdin (`--input -`) suffices for machines; is a masked
   prompt required for humans in the first version?
   **Resolved for this program:** the transition unit stores in-process and the
   CLI's stdin carrier already avoids argv; a masked interactive prompt remains
   optional CLI work.
7. **Ciphertext home:** local store file first (recommend) vs encrypted content
   rows in the SideFX database — the latter is allowed by the two-roof split
   (§4.1) but needs a semantic kind; the key stays in the OS keystore either
   way.
   **Resolved for this program:** the local store file lands first
   (`%LOCALAPPDATA%\sfx\vault\vault.json`, AES-256-GCM, AAD-bound to reference,
   key version and vault id); the database-resident variant stays a pure
   addition.

## 8. Decision record — host key release for the live source switch

Recorded under `sidefx-architecture-decision-rubric.md` §7. Resolves open question 2 for
this host.

| Decision and source location | Applicable authority and scope | Necessary now? | Expected benefit / burden | Disposition and revisit trigger |
| --- | --- | --- | --- | --- |
| How the Windows realization obtains the DPAPI key so `apply` can bind a credential; §4.2 and §6/V3–V4 | Builder intent + delegated realization discretion; §4.2: "the realization owns the choice"; the boot's `restrict-memory-process.mjs:14-39` child-process confinement is an existing admitted constraint | Without a key release on the host, `apply` returns `VAULT_SEALED`, the V3 source switch cannot be installed (both live invocations break) and V4 has no live invocation to sweep | (A) native module: +1 dependency per OS/language realization, hours to remove; (C) stub: cheap, contract path only; (B) permitting a PowerShell subprocess widens a confinement boundary | A for W4; C for the W2 preflight only; B deferred — revisit if A is unavailable/rejected |

**What executes, what is simulated, what remains unresolved.** With (A), the store→apply path
executes live: the realization releases the key from DPAPI custody in memory, the port binds
the credential to the invocation, and the provider call proceeds. With (C) in the W2
in-transaction preflight, execution is simulated only at the keystore boundary (rubric §8): the
result establishes the contract path, not the external outcome. Unresolved until the live run:
actual DPAPI release, sentinel absence across live channels (V4), and the source switch itself.

**Measurements.** Contribution: A 3 (necessary to the named live outcome), C 2 (directly
supports the W2 preflight step), B 1 (blocked hypothesis). Evidence: A 1 (implementation
inspected; no live DPAPI run yet), C 2 (observed at preflight), B 0. First-delivery effect:
A ~1–2 h (install/pin, wire, live store→apply→invoke); C ~1 h. Repetition effect: none per
comparable example; future OS realizations reuse the same seam. Continuing burden: A one native
module per OS and language realization; B a subprocess per unwrap plus a widened allowlist;
C none, and it must be removed after preflight. Reversibility: A hours (fallback path remains),
B cheap to re-block, C immediate. Distribution: the boot and future per-language hosts carry
the dependency; no capability declaration changes on any OS.

**Revisit trigger.** A conforming native DPAPI/CNG module cannot be installed (or a supply-chain
decision rejects the dependency), or a host/language has no native keystore module — then B
returns as a builder decision on the confinement boundary, not as an implementation fallback.

**Observed result after implementation.** Live, 2026-09-16. The transition unit
(`scripts/transition-credential-authorities-to-vault.mjs`) stored each of the
three references from the environment and applied it: `CREDENTIAL_BOUND` with
realization `windows-credential-store-provider` for `RAPID_API_KEY`,
`LOC_GEMINI_API_KEY` and `LOC_OPENAI_API_KEY`; the source-switch migration then
installed with 0 environment authorities and 5 vault authorities remaining. The
equity invocation with the names absent from the environment returned
`EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` (QQQ 704.72 USD, Nasdaq Real Time
Price) — the authorized provider call completed with the vault-released key. The
non-disclosure sweep found the sentinel absent from every named channel
(`invoke --json`, `observe --trace` plus the observation stream,
`evidence/` and local delivery receipts, and the durable rows) and the tampered
store failed GCM authentication. Receipts: `evidence/vault-20260916/transition/`,
`evidence/vault-20260916/non-disclosure/`, `evidence/vault-20260916/live-*.out`.
The conveyor's own exchange remains blocked by the frozen SDA graph-path
composition (V3 status).
