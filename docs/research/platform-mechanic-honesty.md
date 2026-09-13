# Platform-mechanic honesty: inventory and migration

Question that opened this: **is `consumer-object-provider` / `materialize-node`
implemented in all language kernels?**

Answer: **No.** It is Node-only.

| Language | Platform-mechanic provider implementations |
|---|---|
| typescript (node runtime) | 2 (plus the `node-mechanic-registry-loader.mjs` with the invocation branches) |
| python | 0 |
| csharp | 0 |
| java | 0 |
| go | 0 |
| kotlin | 0 |
| cpp | 0 |
| swift | 0 |

- `languages/typescript/runtimes/node/node-mechanic-registry-loader.mjs` is the only
  place that branches on `invocation` (`transformation`, `llm`, `url-context`,
  `serial`, `effects`).
- `csharp-mechanic-registry.authority.v1.json` and
  `python-mechanic-registry.authority.v1.json` declare **0 eventPorts**; the node
  registry declares **31**.

Conclusion: `url-context`, `serial`, `llm`, `effects`, `configuration`,
`consumer-object-provider` and `materialize-node` are domain concerns that happen
to live in the Node runtime. They are not language resolution. A capability wired
to those ports is silently Node-only while claiming portability.

## The fork (rubric §3, §4, §8, §5/§9)

- **Path A (status quo):** keep them as Node platform mechanics. Capabilities
  using them stay Node-only; the kernel holds domain; not portable; the SQL→CLI
  flywheel works only on Node.
- **Path B (honest):** declare each domain concern as a **capability** (feature +
  contracts + provider binding that names the existing module). The kernel keeps
  only language resolution; capability behavior transacts through the database.

Builder intent — "kernels resolve language and everything else comes from data" —
selects **B**. Contribution 3, Evidence 2.

## Inventory of the 31 node `eventPorts`

**Kernel — language resolution (stays):**
- `sda-authority-transformation-port.v1` (`transformation`) — evaluate a semantic
  expression tree in the target language.

**Language runtime (borderline, review):**
- `sda-managed-language-module-invocation-port.v1` — resolve/invoke a managed
  language module. Module loading is arguably language resolution; keep under
  review.

**Domain capability (migrate to declared capabilities):**
- `sda-json-authority-ingestion-port.v1`
- `sda-proof-binding-evaluation-port.v1`
- `sda-scenario-semantic-carrier-validation-port.v1`
- `sda-scenario-semantic-carrier-extraction-port.v1`
- `sda-scenario-semantic-carrier-evaluation-port.v1`
- `sda-canonical-capability-feature-resolution-port.v1`
- `sda-declarative-value-port.v1`
- `sda-filesystem-artifact-store.v1`
- `sda-external-observation-port.v1`
- `sda-external-credential-reference-binding-port.v1`
- `sda-governed-http-exchange-port.v1`
- `sda-governed-repository-observation-port.v1`
- `sda-governed-external-root-observation-port.v1`
- `sda-generic-llm-connector-port.v1`
- `sda-semantic-execution-graph-compilation-port.v1`
- `sda-governed-tooling-binding-transaction-port.v1`
- `sda-governed-tooling-migration-operation-port.v1`
- `sda-governed-file-system-shaping-port.v2`
- `sda-governed-external-root-batch-materialization-port.v1`
- `sda-bounded-base64-byte-digest-port.v1`
- `sda-governed-external-root-projected-application-execution-port.v1`
- `sda-governed-external-root-consumer-projection-port.v1`
- `sda-governed-disposable-root-lifecycle-port.v1`
- `sda-governed-target-execution-observation-port.v1`
- `sda-governed-serial-execution-port.v1`
- `sda-semantic-vector-index.v1`
- `sda-os-environment-credential-port.v1`
- `sda-projected-capability-invocation-port.v1` (capability-to-capability — not a
  platform port at all; composition must be an execution operation)
- `sda-projected-capability-invocation-port.v2` (same)

## First proof: governed-http-exchange

The domain concern already exists as a capability: **`observe-governed-http-exchange`**
(10 scenarios, input contract `observe-governed-http-exchange-input.v1`).
`sda-governed-http-exchange-port.v1` is the Node-only port of that same concern.

Proof shape (no kernel change):

1. Treat `observe-governed-http-exchange` as the canonical capability for governed
   HTTP exchange.
2. A consumer that currently binds the platform port (e.g. an equity
   `observe-equity-price-exchange` port) composes the capability instead, through
   an `invoke-scenario` execution operation whose input/output maps the
   capability's declared contracts.
3. Invoke / reveal / observe the consumer with the kernel untouched: the exchange
   is executed by the `observe-governed-http-exchange` capability, not by a
   Node-only port branch.

Open decision before authoring: cross-capability composition needs a declared
operation kind (the execution authority already supports `invoke-scenario` for
scenarios in the same capability closure; invoking another capability's scenario
is the honest mechanism and must be a declared relationship, not a platform
port).
