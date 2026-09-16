# Vault manager — multi-agent execution strategy

Status: WAVES 1-2 PARTIALLY EXECUTED — W0, W2, W3 landed; W1, W4, W5, W6 next (see Execution log)
Frame: `transistor-model.md` §1 — declared authority (1) or an admitted resolver (0) in the
SDA kernel; no third place. Target model: `vault-manager-capabilities.md` (contract §3, key
custody §4, units V1–V5 §6).

This document decomposes the remaining vault work into agent-sized workstreams with explicit
file scopes, dependencies, acceptance and verification, so several agents can execute in one
turn without colliding.

## 0. Target state (invariants an agent may not violate)

- **Contract**: `sda-credential-vault-port.v1`, operations `store` and `apply`. There is **no
  `reveal`**: the outcome is a credential applied to an authorized provider invocation. Evidence
  `{disposition, opaqueBindingId, referenceName, effectScope, nonDisclosureVerified, realization}`;
  configuration `{storeLocator, allowedReferenceNames[], maximumSecretBytes, referencePolicy}`.
- **Key split**: whatever holds the ciphertext must not hold everything needed to decrypt it.
  The OS keystore **releases the key** to the realization in memory; a wrapped key file is
  acceptable only in the database-resident-ciphertext variant. The capability, its contracts and
  its declarations never name DPAPI, Keychain, TPM or KMS.
- **Realizations are providers**: `windows-credential-store-provider` (DPAPI/CNG first),
  `macos-keychain-credential-store-provider`, `linux-secret-service-credential-store-provider`,
  `cloud-secret-manager-credential-store-provider` (future). Capability rows are identical on
  every OS; only the realization binding (registry/provider profile) differs.
- **Plaintext never crosses the invocation boundary**: not in outcomes, testimony, evidence,
  observation stream, logs or rows.

## 1. Current state and the one reconciliation gap

Landed in SDA: `secret-vault-provider.mjs` (`sda-secret-vault-port.v1`, ops `store`/`resolve`),
`PLATFORM_EFFECT_PORTS` registration, `effectContextOverrides` consumed by the effect factory,
`source: "vault"` accepted by the credential port, env re-broadcast removed, OS-credential
receipt re-derived, 11 vault conformance tests, graph 53/53.

Gap (W0 below): the landed node implementation predates the updated doc. It must align to the
contract name/ops/evidence and split the OS realization out of the port.

## 2. Workstreams

| id | class | scope (files) | depends | acceptance | verify |
|---|---|---|---|---|---|
| W0 | SDA node | `languages/typescript/runtimes/node/secret-vault-provider.mjs`, `windows-credential-store-provider.mjs` (new), `external-credential-reference-binding-provider.mjs`, `semantic-execution-graph-effect-provider.mjs`, `native-mechanic-primitives.mjs`, `node-mechanic-registry.authority.v1.json`, vault test | — | contract renamed to `sda-credential-vault-port.v1`, `apply` replaces `resolve`, evidence carries `realization`; keystore access lives in the realization; a second realization stub (fake keystore) proves capability/registry rows are unchanged when the realization swaps | vault test; graph 53/53; effect ports 8/8 |
| W1 | SDA python+csharp | `languages/python/src/scenario_kernel/platform/secret_vault_provider.py` (new), `languages/csharp/src/ScenarioKernel.Adapters/Graph/SecretVaultProvider.cs` (new), registries, tests | W0 (contract) | same contract, a realization stub per language, evidence mirrors; refusals `VAULT_SEALED`/`CREDENTIAL_NOT_AVAILABLE`/`UNAUTHORIZED_REFERENCE`/`IDENTITY_MISMATCH` | python conformance; `dotnet test` |
| W2 | estate data | `sql/migrations/declare-credential-capabilities.sql` (new) via `model.declare_capability_document`; contracts `store-credential-request.v1`/`result.v1`, `resolve-credential-request.v1`/`result.v1` | W0 | two capabilities declared and installed; `store-credential` returns no plaintext and no digest; `resolve-credential` returns the application outcome only; variants `CREDENTIAL_STORED`/`CREDENTIAL_STORE_REJECTED` and `CREDENTIAL_BOUND`/`CREDENTIAL_NOT_AVAILABLE`/`UNAUTHORIZED_REFERENCE`/`IDENTITY_MISMATCH`/`VAULT_SEALED` | dry-run → preflight → install; estate tests |
| W3 | estate boot | `src/database-delivery.mjs`, `src/invoke-database-capability.mjs` | W0 | the boot selects a realization and releases the key through it into `effectContextOverrides`; no key material in config; DB connection string resolved at the connect boundary (remove the env copy) | estate tests; a boot receipt showing the handle path |
| W4 | estate data | `sql/migrations/switch-credential-authorities-to-vault.sql` (new) | W3 | equity `RAPID_API_KEY`, conveyor `LOC_GEMINI_API_KEY`/`LOC_OPENAI_API_KEY` resolve from the vault (`source: "vault"` + locator); no name present in `process.env`; conveyor still injects `x-goog-api-key` | dry-run → preflight → install; live invocation per capability |
| W5 | verification | `docs/` receipts; sentinel harness | W2, W4 | non-disclosure receipt names every channel (`--json`, `observe --trace`, evidence bundles, observation stream, DB rows) with the sentinel absent; negative receipt for a tampered store (GCM auth failure) | recorded receipts |
| W6 | docs | `docs/vault-manager-capabilities.md` (V1 status), `docs/display-observation-conformance-plan.md` references, `docs/next-experiences.md` §4 | W0 | V1 marked landed with the final contract name; open questions 1/4 resolved with the chosen realization/selection | doc review |

Not in this program: the `model.declare_scenario` object-form variants helper, and the two
pre-existing plan/receipt digest drifts (`capability.projected.test.mjs`, workspace-governance).

## 3. Agent briefs (paste-ready)

**W0 — SDA node contract alignment.**
Read `vault-manager-capabilities.md` §3–§4, then the landed `secret-vault-provider.mjs`.
Rename the contract to `sda-credential-vault-port.v1`; rename `resolve` to `apply` (no reveal);
add `realization` to the evidence; extract the keystore interaction into
`windows-credential-store-provider.mjs` (DPAPI/CNG via a native module, bounded PowerShell
`[System.Security.Cryptography.ProtectedData]` fallback) that owns key custody and exposes the
in-memory handle; add a second realization stub (in-test fake keystore) and prove the
capability/registry rows are byte-identical across realizations. Keep the vault file holding
ciphertext only; the realization releases the key. Update the registry entry and the vault
conformance test. Verify: vault test, `semantic-execution-graph.test.js`, effect-port tests.

**W1 — SDA python+csharp port.**
Read W0's final node contract and the per-language runtime patterns. Implement the same
`store`/`apply` contract with a keystore realization stub (a per-language fake handle) and the
mirrored evidence/refusals; register in `python-mechanic-registry.authority.v1.json` and
`csharp-mechanic-registry.authority.v1.json`. Tests mirror the node vectors. Do not change
capability declarations.

**W2 — estate declared capabilities.**
Read `vault-manager-capabilities.md` §2. Author the two capability documents and contracts as
JSON and one ROLLBACK-by-default migration following `sql/README.md` (guard triggers, dry-run,
preflight from the uncommitted transaction, proof result sets). Display must never echo the
secret; `apply` outcomes carry the binding proof only. Verify: `node scripts/run-migration.mjs`
dry run, then the preflight invocation, then the install; estate tests.

**W3 — estate boot realization and unseal.**
Select the realization for the host through the ordinary provider-resolution path; obtain the
key handle from the OS keystore inside the realization; place it on `effectContextOverrides` for
the kernel host (`invoke-database-capability.mjs:259,307`). Remove the DB connection-string env
copy at `database-delivery.mjs:30`, resolving at the connect boundary. No key material in files
the declaration can read. Verify: estate tests; a receipt of the handle path (no key bytes).

**W4 — live source switch.**
One ROLLBACK-by-default migration changing the three installed credential authorities from
`source: "environment"` to the vault source with a locator; nothing else moves. Verify: dry-run,
preflight per capability, install; the equity invocation resolves and the fallback route still
resolves; the conveyor injects the same header; none of the three names is in `process.env`.

**W5 — non-disclosure proof.**
Sweep the channels with a sentinel: `invoke --json`, `observe --trace` (stderr observation
stream), `evidence/` bundles, retained rows; record the receipt (channel, observed, sentinel
absent) and the tampered-store negative (GCM auth failure). No code changes unless a leak is
found — a found leak is an SDA request, not a workaround.

**W6 — documentation.**
Record V1 landed with the final contract name and the chosen realization/selection answers;
update the conformance plan's vault references; keep `next-experiences.md` §4 consistent. No
runtime edits.

## 4. Parallelization and gates

- **Wave 1 (parallel)**: W0 (SDA node), W6 (docs — may start immediately, final line updated
  after W0).
- **Wave 2 (parallel, after W0)**: W1 (SDA python+csharp), W2 (estate capabilities), W3 (estate
  boot) — disjoint file sets.
- **Wave 3 (serial, after W3)**: W4 (source switch); **W5** after W2+W4.
- W2 and W3 may run concurrently with W1; W4 must not start before W3 (the boot must be able to
  release the key or the switch makes the capabilities unusable).
- Each agent re-runs the full verification for its surface on the combined tree before reporting;
  no agent restores files from byte copies or backups (concurrent-writer discipline).

## 5. File-conflict map

| surface | owner | others must not touch |
|---|---|---|
| `languages/typescript/runtimes/node/*` + node registry | W0 | W1–W6 |
| `languages/python/*`, `languages/csharp/*`, their registries | W1 | W0, W2–W6 |
| `sql/migrations/*` | W2 then W4 (serial) | W0, W1, W3, W5, W6 |
| `src/*` boot | W3 | all |
| `docs/*` | W6 | others may append only in their receipt sections |

## 6. Risks and unknowns

- **DPAPI availability**: no native module is assumed installed; the bounded PowerShell path is
  the zero-dependency fallback, and the realization must fail closed with `VAULT_SEALED` when
  neither is available. Same-user process protection is the recorded boundary (§4.3).
- **DB access**: W2/W4 need the sidefx-database connection (`sidefx-connection-string`) for
  preflight/install; without it, deliver ROLLBACK-by-default and a dry-run receipt.
- **Rename churn**: W0 changes the contract id/ops already referenced by tests, the registry and
  the credential port's vault source; keep a single commit and re-run the whole node surface.
- **Estate loader threading**: the SDA factory now consumes `effectContextOverrides`; W3 must
  confirm the loader path end-to-end (the estate already threads the field at
  `invoke-database-capability.mjs:259,307`).

## 7. Definition of done (V2–V5)

1. `store-credential` and `resolve-credential` are declared, installed and invoke-able; their
   results contain no plaintext and no digest of it.
2. One realization (Windows) releases the key from the OS keystore inside the provider; a stub
   realization proves capability rows are unchanged when the realization swaps.
3. Equity and the conveyor resolve their credentials from the vault; none of the three names is
   in `process.env`; the exchange injects the same headers.
4. The non-disclosure receipt shows the sentinel absent from every channel, plus the tampered
   store negative.
5. Capability declarations are byte-identical across OS realizations; rotation and further
   realizations (Keychain, Secret Service/TPM, KMS) remain pure additions.

## Execution log

- **W0 — DONE** (SDA `e7b3864`). Contract `sda-credential-vault-port.v1`, ops `store`/`apply`,
  `realization` evidence; `windows-credential-store-provider.mjs` owns key custody (native DPAPI
  module first, bounded PowerShell fallback, fail-closed `VAULT_SEALED`); stub realization swap
  proves the registry entry is stable; OS-credential receipt digests re-derived. Vault 15/15,
  graph 53/53, effect ports 8/8, OS-credential 5/5.
- **W2 — DONE, ROLLBACK** (estate `4dd191f`). The four contracts and both capabilities declared
  in one ROLLBACK-by-default migration; dry-run completes with 11 result sets and
  `names_secret_material=0` on all 16 result-contract members. Install pending preflight.
- **W3 — DONE** (estate `0fb8660`). Realization resolved through `overlayBindings`/`providers`
  and threaded via `effectContextOverrides`; connect string resolved at the connect boundary,
  env copy removed. Estate suite 61 pass / 0 fail / 3 skipped.
- **Next sequence (W2b, then W4):**
  1. **W2b — overlay bindings (data)**: add the vault mechanic to the execute overlay
     (`{mechanicId: "sda-credential-vault-port.v1", providerProfileId:
     "sda-platform-effect-graph-provider.v1", providerProfileDigest: "sha256:945a4ff5…",
     implementationRef: "sda-platform-effect-graph-provider.v1"}`) and the host realization
     (`overlayBindings: [{mechanicId: "sda-credential-store-realization.v1", providerProfileId}]`,
     `providers: [{providerProfileId, module:
     "languages/typescript/runtimes/node/windows-credential-store-provider.mjs",
     export: "createWindowsCredentialStoreRealization", factory: true}]`) on the two Port
     bindings. Then run the in-transaction preflight and install the migration.
  2. **W4 — source switch**: only after a host realization can actually release a key.
     **Decision (vault doc §8, rubric §7)**: the native DPAPI/CNG module is needed now for W4;
     the in-memory stub is useful now for the W2 in-transaction preflight only and must be
     labeled as simulation at the declared seam; the bounded PowerShell path is deferred to a
     builder decision on the `restrict-memory-process` child-process confinement. Revisit if no
     conforming native module can be installed.
  3. **W1 — python/C# port** and **W5 — non-disclosure receipts** follow the gates in §4.
  4. **Follow-up defect**: `src/projection-delivery.mjs:139` carries the same env-copy pattern
     removed at `database-delivery.mjs`; classify and fix as its own unit.
