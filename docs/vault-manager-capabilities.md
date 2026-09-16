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

**Invariants.** (1) Rows never carry values. (2) The invocation channel never
carries plaintext to the caller: no CLI output, no testimony, no evidence body,
no logs. (3) The plaintext exists only inside the vault provider's call and the
exchange-header injection, in one process, for one use. (4) The master key is
never in the vault file. (5) No SDA edits from this repo (cross-language ⇒ SDA
change request).

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
| Operations | one `invoke-port` → `sda-secret-vault-store-port.v1` (configuration: vault locator, allowed reference names, max secret bytes) |
| Outcome contract | `store-credential-result.v1`: `{referenceName, entryId, storedAt, formatVersion, nonDisclosureVerified}` — no secret, no digest of the secret |
| Variants | `CREDENTIAL_STORED` (success), `CREDENTIAL_STORE_REJECTED` (failure: sealed vault, unknown reference, policy) |
| CLI display | outcome as json; the input mapping must never echo `secret` |

**Plaintext lifetime.** The caller's envelope (stdin), the port call, the
encryption, then gone. It must not appear in: the outcome, cell testimony, the
observation stream, the invocation `evidence`, retained bundles, or any row.
The store port returns a reference only.

### 2.2 `resolve-credential`

**Intent.** Given a credential requirement, bind an ephemeral one-use secret
that the same invocation's effect provider can consume; disclose only that a
binding exists.

| | |
|---|---|
| Input contract | `resolve-credential-request.v1`: `{credentialReference, invocationIdentity, requestingCapabilityId, endpointAuthorityDigest, effectScope}` — the exact shape the credential port already requires |
| Operations | one `invoke-port` → `sda-secret-vault-resolve-port.v1` (same binding semantics as the existing credential port; source = vault) |
| Outcome contract | `resolve-credential-result.v1`: `{disposition, opaqueBindingId, referenceName, effectScope, expiresAt, nonDisclosureVerified}` |
| Variants | `CREDENTIAL_BOUND` (success), `CREDENTIAL_NOT_AVAILABLE`, `UNAUTHORIZED_REFERENCE`, `IDENTITY_MISMATCH`, `VAULT_SEALED` (failure) |

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
invocation returns proof-of-binding, never the secret.** "Returns an ephemeral
secret" is true kernel-internally (the binding holds it) and false at the CLI
boundary — by design, per the user's own rule.

### 2.3 What "declares it needs a credential" means today

There is no first-class `requiresCredential` contract field. The declaration is
the credential port binding plus its `credentialAuthorities[]` (reference names,
scopes, admitted capabilities, endpoint digests, injection rule). The conveyor
already relies on exactly this shape for Gemini (§1.2), and the vault design
extends that configuration with the vault source and locator; it does not need a
new contract vocabulary.

---

## 3. The vault provider (SDA)

One new platform port with two operations (or two ports):

- `sda-secret-vault-port.v1` — `store` and `resolve`, dispatched like the
  effect ports; `resolve` must run under the same shared effect context as the
  credential port (it is a credential source), `store` is a plain effect.
- Configuration: `{vaultLocator, allowedReferenceNames[], maximumSecretBytes,
  referencePolicy}`.
- Evidence: `{disposition, referenceName, entryId|opaqueBindingId, scope,
  nonDisclosureVerified: true, detail}` — the existing evidence vocabulary,
  mirrored.
- The unsealed master key arrives as a **boot-provided handle**, not from
  configuration files the declaration can read (see §4).

**Dispatch decision to make with SDA:** either (a) extend the credential port
with `source: "vault"` and let it call the vault provider for the value, or
(b) consume `host.effectContextOverrides` in `createPlatformEffectProvider` so
the boot injects a vault-backed `credentialReader` and the credential port is
untouched. (b) is smaller and preserves the credential port's proven semantics;
(a) makes the vault visible in declared configuration. Recommend (b) first,
then (a) when cross-language providers exist.

**Cross-language.** Only node can land first (the registry's effect ports are
node implementations). python/csharp/java/go/c++ mirror through their own
runtimes; that is the same per-language pattern as the credential port today
and follows the per-language bootstrap work.

---

## 4. The unseal boundary and key management

### 4.1 Design

```
vaultDir/                       (e.g. %LOCALAPPDATA%\sfx\vault\)
  master.key.dpapi              OS-protected master key (DPAPI CurrentUser, blob)
  vault.json                    entries: {name, keyVersion, nonce, ciphertext, tag, createdAt}
```

- Master key: 32 random bytes (`crypto.randomBytes(32)`).
- Protection: DPAPI `CryptProtectData` (user scope, UI off) — the wrapped blob
  is a **separate file**; the vault file never contains the key (user's rule).
- Entries: AES-256-GCM, fresh 12-byte nonce per write, AAD binding
  `{referenceName, keyVersion, vaultId}` so ciphertext cannot be moved between
  names.
- Rotation: each entry carries `keyVersion`; rotate re-encrypts under a new
  master key; the wrapped key file is replaced atomically after all entries.
- Writes: read-modify-write with tmp + rename (the artifact-store pattern);
  single-writer assumption, documented.

### 4.2 Where the unseal happens

The unseal step belongs to the **boot**, not a declared capability
([next-experiences.md](next-experiences.md) §4; transistor model: the unseal
resolver is irreducible 0 per language). Concretely for node:

- Boot (frontdoor process) unseals DPAPI → master key (Buffer) at the connect
  boundary, builds the vault handle, hands it to the kernel host, drops the
  value when the process ends.
- The handle reaches the provider through the effect-context seam (§1.3):
  either `createPlatformEffectProvider` learns to read
  `host.effectContextOverrides` (one SDA change), or the loader wraps the
  execution provider. Prefer the SDA change.
- Node has no built-in DPAPI. Options, in preference order: (1) a small native
  module (`win-dpapi`-class) loaded by the boot; (2) PowerShell
  `[System.Security.Cryptography.ProtectedData]` via bounded subprocess (slow,
  but zero-dependency); (3) Windows Credential Manager via `wincred`-class
  module. macOS Keychain (`security`) and Linux libsecret (`secret-tool`) are
  the later cross-platform forms. This is boot code per language — the same
  code the sealed-binary and per-language-bootstrap work will carry.

### 4.3 Honest threat boundary

DPAPI CurrentUser protects the master key against **other OS users and offline
theft** (file copied elsewhere). It does **not** protect against a process
running as the same user — which includes the agent. So "the agent has no
access to secrets" holds on the *invocation channel* (the value is never
returned, printed, streamed, or retained) but not against an agent that
deliberately calls the unseal API and reads the vault file. Stronger boundaries
(Windows Hello / Credential Manager consent prompt / a vault daemon gating
unseal) are a separate decision; the doc records this limit rather than hiding
it. This is exactly why plaintext must never reach the invocation boundary: the
boundary is the guarantee's scope.

---

## 5. What it takes — classification

| Change | Class | Where |
|---|---|---|
| Vault provider (store + resolve), evidence contract, registry entries | **SDA request** | node first; `PLATFORM_EFFECT_PORTS` or `invokePlatformEffectMechanic` + `node-mechanic-registry` |
| Effect-context override consumed by the effect factory (`host.effectContextOverrides`) | **SDA request** (one seam) | `semantic-execution-graph-effect-provider.mjs:17` |
| `source: "vault"` on the credential authority (or equivalent vault reader) | **SDA request** | `external-credential-reference-binding-provider.mjs:44` |
| Remove the env re-broadcast | **SDA request** (with the vault landing) | `os-environment-credential-provider.mjs:75` |
| OS key unseal (DPAPI/Credential Manager per language) | **boot code** | `src/database-delivery.mjs` frontdoor; cross-platform later |
| Unseal handle → kernel injection | **SDA seam + boot wiring** | estate loader already threads `effectContextOverrides` (`invoke-database-capability.mjs:259,307`) |
| Contracts `store-credential-*`, `resolve-credential-*`; two capability documents; vault declaration (locator, names, scopes); variants; CLI display | **data** | JSON documents + one migration via `model.declare_capability_document` |
| Switch the installed credential authorities to the vault source (equity's `RAPID_API_KEY`; the conveyor's `LOC_GEMINI_API_KEY` / `LOC_OPENAI_API_KEY`) | **data** | `sql/migrations/` — one `source`/locator change per authority, nothing else moves |
| Remove the DB connection-string env copy; resolve at the connect boundary | **boot code** | `src/database-delivery.mjs:30` |
| Masked interactive secret prompt | **CLI** (optional; stdin already works via `--input -`) | `sidefx-cli` |

---

## 6. Implementation strategy

### V0 — this record (done)
Decision and mechanism research; no runtime changes.

### V1 — SDA vault provider, node
Primitive: vault store/resolve port with AES-GCM, DPAPI-agnostic (the key is
injected), evidence mirroring the credential port, registry entries, and the
`effectContextOverrides` seam. Accept: conformance tests for store→resolve→
exchange with a sentinel secret; the sentinel absent from every evidence field;
sealed vault reports `VAULT_SEALED`; wrong scope/digest/reference rejected.

### V2 — Declared capabilities
Author `store-credential` and `resolve-credential` documents + migration
(§2). Accept: `sfx capability invoke store-credential --input -` stores; the
result contains no plaintext or digest of it; `resolve-credential` returns
proof-of-binding only; `observe` streams no plaintext.

### V3 — Unseal and the live source switch
Boot unseal (DPAPI), handle injection, and the installed credential authorities
switched from environment to vault: equity's `RAPID_API_KEY` and the conveyor's
`LOC_GEMINI_API_KEY` / `LOC_OPENAI_API_KEY`. Accept: the equity invocation
resolves via the vault and the fallback route still resolves through real-time1;
the conveyor's credential bind still stages the same literals and the exchange
injects the same headers (`x-goog-api-key`), now from vault entries; none of the
three names is present in `process.env`.

### V4 — Non-disclosure proof
Sweep artifacts for the sentinel: invoke `--json`, `observe --trace` output,
`evidence/` bundles, the observation stream, and the database rows. Accept: a
recorded receipt that names every channel and shows the sentinel absent; a
negative receipt for a tampered vault (auth failure).

### V5 — Rotation, cross-platform, consent
Rotation; python/csharp providers; a stronger unseal consent boundary
(§4.3) if required.

**Dependencies.** V1 blocks V2; V3 needs V1's seam; V4 needs V3. The sealed
binary and per-language bootstraps carry V3's unseal code — orthogonal but
shared.

---

## 7. Open questions (for the owner)

1. **Dispatch choice:** extend the installed `bind-external-credential-reference`
   with a vault source vs declare a new `resolve-credential` capability; and
   vault as a new effect port vs the credential port's `source: "vault"`
   (recommend: override seam first, then extend the installed capability's
   source — the conveyor's declarations then need one locator, not a rewrite).
2. **Unseal implementation:** native DPAPI module vs bounded PowerShell
   subprocess vs Credential Manager (recommend: native module in the boot).
3. **Threat boundary:** is same-user process protection (agent can unseal)
   acceptable for now, or is a consent gate required before the demo?
4. **Vault location:** `%LOCALAPPDATA%\sfx\vault\` (recommend) vs a configured
   path; never the repo, never `%TEMP%`.
5. **Composition:** does `resolve-credential` need the invoke-scenario
   composition (R1) for the first version, or is resolve-and-use-in-one-scenario
   enough (recommend: enough).
6. **Store input UX:** stdin (`--input -`) suffices for machines; is a masked
   prompt required for humans in the first version?
