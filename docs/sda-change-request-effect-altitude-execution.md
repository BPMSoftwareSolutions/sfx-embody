# SDA change request — physical-altitude effect execution and mechanic outcome aggregation

Format per [embodiment-completeness.md](embodiment-completeness.md): primitive /
why kernel / affected languages / data that binds it / evidence. Filed from the
estate; agents do not edit SDA.

**Status: landed — SDA `1dd253d`, verified live 2026-09-16.** The physical cell
for a platform effect port is now observational: the credential responsibility
reports `BOUND` at provider, physical and mechanic altitude, and the exchange
reports its real transport (`retained-non-success`, `reachedStage:
response-complete`, `exchangeCount: 1`, `transportDisposition: completed`) on the
rate-limited primary. The fallback route installed on top of it resolves through
the secondary provider (`add-equity-price-fallback-route.sql`, estate `9230b83`);
full verification receipts are in
[declare-provider-fallback-validation.md](declare-provider-fallback-validation.md) §5.

## Summary

The provider/physical descent materialized by SDA `6aa2434`/`171d96f` executes a
platform effect port twice: the provider cell runs the declared port, and the
physical cell runs it again with the provider cell's outcome as input. For the
credential and HTTP ports this produces synthetic failures at physical altitude —
and, worse, the **mechanic (operation) cell then surfaces the physical child's
failure as the responsibility outcome**. On the equity run the credential port
**bound successfully** (`BOUND`) yet the operation reads
`CREDENTIAL_NOT_AVAILABLE`; the display and the classification-driven stream
therefore report the credential responsibility as failed. No HTTP exchange is
attempted at all (`exchangeCount: 0` at both stages), so this is not the
rate-limited provider.

## Primitive 1 — physical-altitude effect execution

A physical-altitude cell for a platform effect port must execute the primitive's
physical effect under the declared port semantics with the port's declared input,
or be marked observational; it must not re-invoke the request pipeline with the
provider cell's outcome as its input.

- Observed: `cell:physical:…operation.2` (credential reference binding) returns
  `CREDENTIAL_NOT_AVAILABLE` while its parent `cell:provider:…operation.2`
  returns `BOUND`. The physical cell's input is the provider cell's outcome
  (`unwrapEffectPayload` then finds none of `credentialReference`,
  `invocationIdentity`, `requestingCapabilityId`, `endpointAuthorityDigest`,
  `effectScope`, so the provider returns `CREDENTIAL_NOT_AVAILABLE` with
  `detail: "required binding authority is absent"`).
- Observed: `cell:physical:…operation.4` (HTTP exchange) returns
  `rejected-endpoint` at `reachedStage: endpoint-admission` while its parent
  returns `rejected-credential` at `reachedStage: credential-binding` — two
  different stages for the same declared effect, both with `exchangeCount: 0`.

## Primitive 2 — mechanic outcome aggregation

The mechanic (operation) cell's outcome must be the declared port invocation's
outcome; a physical-altitude descent artifact must not override it.

- Observed: `cell:mechanic:…operation.2` carries
  `CREDENTIAL_NOT_AVAILABLE`, although the provider cell that actually executed
  the port returned `BOUND`. The credential responsibility therefore reads as
  failed in the declared display document and in the streamed entry, which is
  untrue of the port invocation.

## Why kernel

Cell altitude semantics and cross-altitude outcome aggregation are
resolver-level interpretation: every graph target must agree on what a
provider/physical descent means and which child's outcome becomes the
responsibility's outcome. The estate cannot work around it — inferring statuses
around kernel artifacts would fabricate meaning, which the display decision
explicitly forbids.

## Affected languages

node, python, csharp (all graph-ADMITTED targets; java/go/c++ when their
schedulers run consumer graphs).

## Data that binds it

- Capability `resolve-equity-market-price-evidence`; ports
  `bind-equity-price-provider-credential`
  (`sda-external-credential-reference-binding-port.v1`, configuration
  `credentialAuthorities[]` with `referenceName: RAPID_API_KEY`, source
  `environment`) and `observe-equity-price-exchange`
  (`sda-governed-http-exchange-port.v1`, `endpointAuthorities[]`,
  `credentialInjectionRules[]`).
- The compiled plan's descent geometry: each physical cell's parent is its
  provider cell; the provider cell's `configuration` carries the
  `{kind:"invoke-port", binding:{…}}` wrapper, the physical cell's does not.

## Evidence

Commands (estate `sfx-embody`, 2026-09-16):

```
cmd /c "sfx capability observe resolve-equity-market-price-evidence --input AVGO --json"
cmd /c "sfx capability observe resolve-equity-market-price-evidence --input AVGO --trace"
```

Observed cell variants (classification in parentheses):

```
BOUND                     (success)  provider  …operation.2
CREDENTIAL_NOT_AVAILABLE  (failure)  physical  …operation.2
CREDENTIAL_NOT_AVAILABLE  (failure)  mechanic  …operation.2
rejected-credential       (failure)  provider  …operation.4
  providerEvidence { reachedStage: "credential-binding", exchangeCount: 0, transportDisposition: "denied", redactionVerified: true }
rejected-endpoint         (failure)  physical  …operation.4
  providerEvidence { reachedStage: "endpoint-admission", exchangeCount: 0, transportDisposition: "denied", redactionVerified: true }
EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE (failure)  mechanic …operation.5, scenario
```

SDA code paths read for this request: the scheduler's provider call
(`languages/typescript/runtimes/node/semantic-execution-graph/scheduler.js`
`executeCell` passes `context.configuration = cell.execution.configuration` and
`token.input` per cell), the platform effect dispatch
(`semantic-execution-graph-effect-provider.mjs#createPlatformEffectProvider`
reads `context.configuration.binding`), and the credential provider's required
payload fields (`external-credential-reference-binding-provider.mjs`).

## Acceptance

- On the equity quota branch, the physical cells of the credential and HTTP
  ports do not invent `CREDENTIAL_NOT_AVAILABLE` / `rejected-endpoint`; the
  credential responsibility reports `BOUND`, and the exchange reports its real
  transport result (`exchangeCount ≥ 1`) once the credential is present —
  independent of whether the provider's quota rejects the call.
- The declared display document's WHEN lane and the streamed entries agree with
  the port invocation's outcome at every altitude.

## Estate-side note

No estate workaround will be applied. The classification work (`6ba5c42`,
estate `2d61e1e`, `99a870b`) is what made these artifacts visible; the estate
will not re-derive statuses around them.
