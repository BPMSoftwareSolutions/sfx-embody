# SDA change request — bounded provider evidence must carry the transport status

Format per [embodiment-completeness.md](embodiment-completeness.md): primitive /
why kernel / affected languages / data that binds it / evidence. Filed from the
estate; agents do not edit SDA.

## Summary

The governed HTTP exchange provider's evidence carries `httpStatus` (the real
status code; `429` on the rate-limited primary), but the kernel's
testimony bound — `providerEvidenceFor` in
`languages/typescript/runtimes/node/semantic-execution-graph/scheduler.js` —
keeps only `reachedStage`, `exchangeCount`, `transportDisposition` and
`redactionVerified`. Testimony and the streamed observation channel therefore
cannot distinguish a rate-limited exchange (`429`) from any other non-success
(`403`, `500`): all read `retained-non-success`. The estate has extended its
observation allowlists (`src/observation-filter.mjs`, `src/execution-drilldown.mjs`)
to publish a bounded `httpStatus`; the kernel bound is the remaining half.

## Primitive

The testimony-bound provider evidence for a platform effect port must include
the transport status the effect observed: a non-negative integer `httpStatus`
(`0` when no response was read), alongside `exchangeCount`.

- Observed raw evidence (equity live run, 2026-09-16): primary
  `observe-equity-price-exchange` outcome `retained-non-success`,
  `reachedStage: response-complete`, `exchangeCount: 1`,
  `transportDisposition: completed`, `httpStatus: 429`. The first four are in
  testimony; `httpStatus` is not.
- Consequence: rate-limit evidence runs cannot record the signal that
  distinguishes the quota rejection from other provider rejections; the
  fallback/rate-limit cycling design needs it.

## Why kernel

The bound is the kernel's: `providerEvidenceFor` decides which scalars of the
observed effect evidence may leave the execution. The estate's allowlists only
accept or drop what the kernel emits; they cannot recover `httpStatus` from a
bound that omitted it, and the invocation path is read-only.

## Affected languages

node; python, csharp, java, go, c++ when their schedulers/executors run consumer
graphs (mirror the same bounded field).

## Data that binds it

- Capability `resolve-equity-market-price-evidence`, ports
  `observe-equity-price-exchange` and `observe-fallback-price-exchange`
  (`sda-governed-http-exchange-port.v1`).
- Implementation reference: `governed-http-exchange-provider.mjs` emits
  `httpStatus: response.status` (and `0` on the no-response paths).

## Evidence

Live invoke 2026-09-16 (estate `9230b83` install): provider/physical testimony
`{reachedStage:"response-complete",exchangeCount:1,transportDisposition:"completed",redactionVerified:true}`
for the 429 primary exchange, while the raw evidence in the same process carries
`httpStatus: 429`. Estate allowlists list `httpStatus` and the suite passes
49/52 (3 DB-gated skips).

## Acceptance

- Testimony for provider/physical cells of an exchange carries `httpStatus`
  (bounded integer; `0` when no response was read), and `sfx capability observe`
  streams it in `providerEvidence`.
- No other raw evidence member (headers, bodies, URLs, credentials) enters
  testimony.

## Estate-side note

The estate allowlists already accept `httpStatus`; the estate will add no
workaround if it is absent — the field simply does not appear. Landing this is
additive.
