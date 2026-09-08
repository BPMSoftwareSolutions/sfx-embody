# From expanded capability to database invocation

The live SQL-to-memory path executed `resolve-sidefx-eligible-providers` without writing its authority bundle or executable body to disk. Its four complete fixture results match expanded execution, including all 28 outcome assertions. This establishes the requested execution bar for that capability through a candidate Node loading provider. It does not yet establish database-native candidate editing, capsulization, or universal capability coverage.

## 1. How an expanded capability executes

There are two existing expanded representations:

- The SDA projected application exports `executeCapability` from a generated runtime seam. `admitted-consumer-platform.mjs` binds an application using its application-binding document, checks the execution-plan digest, loads the plan, and resolves the declared provider mechanics. That adapter currently loads its application documents through filesystem URLs.
- This repository's native embodiment exports `createScenario` from `body/composition.mjs`. It constructs the real contract admission provider, event providers, and any declared child Scenarios. The returned Scenario exposes `execute(input, context)`.

The native Scenario executes the real Scenario Kernel: admit input, resolve event authority, execute the event through bound dependencies, admit outcome, and resolve disposition. Its observer receives execution testimony. Estate reconstruction is not involved in that entry point.

An invocation of the expanded native body has this shape:

```javascript
const observations = [];
const scenario = createScenario({
  observer: { observe: value => observations.push(value) },
  clock: { now: () => new Date().toISOString() }
});
const result = await scenario.execute(input, {
  executionId,
  rootExecutionId: executionId,
  rootInput: structuredClone(input),
  ancestry: [scenario.constructor.scenarioId]
});
```

See the [native composition](../embodiments/resolve-sidefx-eligible-providers/scenarios/resolve-sidefx-eligible-providers/node/body/composition.mjs) and [Scenario](../embodiments/resolve-sidefx-eligible-providers/scenarios/resolve-sidefx-eligible-providers/node/body/scenario.mjs). These bodies were not hand-edited during this investigation.

## 2. Invoke an existing database capability in expanded form

The exercised command was:

```powershell
node scripts/probe-database-invocation.mjs config/regression.cases.json resolve-sidefx-eligible-providers expanded evidence/database-direct-20260908/expanded
```

It read fresh authority through the restricted SQL reader, resolved the selected Capability/Scenario, planned the native body, wrote that body to the explicit output root, imported its composition, and invoked its database-retained fixtures. It did not invoke `sfx` or reconstruct the estate.

Results: exit 0, four fixtures passed, 28 assertions passed, 20 kernel observations, and invalid input rejected. The selected query returned 29 retained capability source records and seven platform declaration records. The native body contains 26 files.

[Expanded result](../evidence/database-direct-20260908/expanded.json) · [native stage log](../evidence/database-direct-20260908/expanded.log)

## 3. Invoke directly from the database without landing the capability on disk

Three storage boundaries were separated:

1. **Query retention.** The existing database reader previously called `putBlob` even when `writeReceipt` was false. `query(..., { retainObjects: false })` now computes the same content digests without storing query/result objects. It retains the transaction pin, restricted reader role, row limits, and coherence checks, and declares `objectRetention: MEMORY_ONLY`. It rejects requests to write a receipt for unretained objects.
2. **Body planning.** [planNode](../src/materialize-node.mjs) accepts an in-memory authority bundle and returns source, contracts, dependency metadata, digests, and planned evidence. [writeNodePlan](../src/materialize-node.mjs) performs the optional filesystem projection. The existing `materializeNode` interface composes these two operations.
3. **Body loading.** [loadMemoryScenario](../src/load-memory-scenario.mjs) loads the unchanged generated modules under `sidefx-memory://body/` addresses. Relative imports resolve only within that invocation's resource map. Contract reads resolve from the same map. The installed Ajv dependency must match the version declared by the generated package authority. Unsupported imports, missing resources, and changed source bytes fail explicitly; there is no filesystem fallback for a missing capability resource.

The resulting path is:

```text
Selected database authority
  -> coherent in-memory bundle
  -> native body plan in memory
  -> linked in-memory Scenario, contracts, and providers
  -> Scenario.execute(canonical input)
  -> result and execution evidence
```

The capability remains authoritative data in SQL. Generated JavaScript is a runtime representation in memory. This path still uses the installed Node/compiler/provider toolchain from disk; it does not require a capability-specific filesystem projection.

The [live probe](../scripts/probe-database-invocation.mjs) ran in a separate Node process with filesystem writes denied. Its filesystem read allowlist excluded both the existing expanded bodies and the database's local content store. Explicit write and expanded-body read attempts failed with `ERR_ACCESS_DENIED`. Tampered module source and a missing Scenario module were also rejected. All three SQL responses reported `MEMORY_ONLY`.

Node child processes were allowed only to preserve the planner's existing platform pin checks. The probe constrained child-process calls to the three recorded, read-only Git commands (`rev-parse`, `diff`, `ls-files`), with optional Git locks disabled. No provider request or materialization command was delegated to a child process. The parent shell retained stdout/stderr evidence after invocation. These controls support an execution/storage observation, not a malicious-code sandbox claim.

Results: exit 0, 14 modules loaded from memory, four complete fixture results identical to expanded execution, all 26 native body file digests identical, 28 assertions passed, and invalid input rejected.

[Exact exercised memory command](../evidence/database-direct-20260908/memory-command.txt) · [memory result and access evidence](../evidence/database-direct-20260908/memory.json) · [parity proof](../evidence/database-direct-20260908/parity.json)

The module loader uses Node 20's experimental VM module API. [Node's VM documentation](https://nodejs.org/download/release/v20.19.0/docs/api/vm.html#class-vmsourcetextmodule) describes loading source strings and linking their dependencies; [its permission documentation](https://nodejs.org/download/release/v20.19.0/docs/api/permissions.html) describes the process filesystem restrictions and their limits. This implementation remains an investigation provider, not an admitted production execution surface.

## Regression and authority identity

`npm run verify:memory` checks retained database bundles against existing expanded bodies. All 465 body files remain byte-identical. Complete memory/disk execution results, nested execution records, and observation fields other than timestamps match for all 17 fixtures:

| Capability | Fixtures | Outcome assertions | Kernel observations |
| --- | ---: | ---: | ---: |
| adapt-job-market-intelligence-evidence | 5 | 11 | 100 |
| admit-canonical-circuit-blueprint | 8 | 20 | 200 |
| resolve-sidefx-eligible-providers | 4 | 28 | 20 |

This broader regression uses retained bundles. The separate restricted-process proof above reads the provider resolver's authority from the live database. The existing four resolver tests and eight focused database reader tests also passed.

Both live runs selected database snapshot `sha256:1a770ac0795d10665a88166f8d8c968dc5b2d030fdfab2b837aa6071d135f9e9` and projection `sha256:e036610730972f246d8e33cd882e45dd793013076aea2e401086b93d4993a7ee`. The physical platform remains pinned to `716811046f52dd2a67f9ff308a50d755571cbbad`.

## What still separates this from the database change surface

The current [authority query](C:/lab/sidefx-database/sql/diagnostics/capability-embodiment.sql) selects normalized identities and relationships, then exports exact source documents from `source.content_object` through retained capsule lineage. The planner still parses the retained feature, execution-authority JSON, interface bindings, transformations, and contract schemas. Normalized mechanic definitions and Scenario resolution already participate, but normalized rows alone are not yet the complete compilation input.

Consequently, changing a normalized transformation or contract row would not, by itself, establish a revised executable capability through this path. Published definitions are also deliberately immutable. A database-native change surface needs an explicit candidate revision with a coherent content identity and a reader/compiler adapter that consumes that exact revision rather than the previous capsule's retained documents.

The next bounded slice should establish:

1. A selected candidate revision and its exact authority/dependency closure, preserving ambiguity and unresolved-provider findings.
2. A deterministic projection from that revision into the same in-memory compilation input. If normalized rows and retained documents coexist, the precedence and equivalence rules must be explicit.
3. Execution and proof receipts bound to the candidate revision, provider/toolchain identities, input, and outcome digests. A changed revision invalidates the predecessor's proof.
4. Capsulization consuming the same proven revision and bytes, followed by structural/closure verification and invocation parity after decoding. Packing must not recover its authority from an independently edited directory.

Capsule packing is already byte-oriented in the installed provisioner: it constructs entries and their digests from buffers before serializing a capsule. That supports removing filesystem staging from the packaging adapter in principle. It does not establish an existing managed boundary that accepts a database candidate revision, nor was capsulization or database mutation exercised here.

The achieved result is direct database-to-memory execution of an existing capability. Candidate authoring, proof persistence in the database, capsulization, and broader provider profiles remain separate work. The `sfx` connection is now implemented as described below.

## 4. Invoke through sfx

From this project directory, the native command is:

```powershell
sfx capability invoke resolve-sidefx-eligible-providers --input '@examples/provider-resolution.request.json' --json
```

The project's [sfx.config.json](../sfx.config.json) selects an explicit process
binding from [the command mapping](../config/sfx.commands.json). The CLI forwards
the unchanged typed command and canonical input using `sfx-command-delivery.v1`.
The independent [database provider](../src/database-delivery.mjs) owns SQL reads,
Node projection and memory loading. Neither the CLI nor the provider uses the
regression case list to resolve the requested capability. Omitting a Scenario
selects `model.capability_root_scenario` in the pinned SQL model; it does not
assume matching capability and Scenario names. Explicit namespace selection is
forwarded to SQL; unknown and ambiguous authority remains a failure.

The command returned exit 0 and `PROVIDERS_RESOLVED`: two considered bindings,
one eligible provider, unchanged canonical input, and 14 modules loaded from
memory. SQL authority, resolution and mechanic queries all report `MEMORY_ONLY`.
The configured provider process denies filesystem writes and reads of expanded
bodies and the database cache. After resolving the existing credential reference,
its child-process boundary permits only the planner's three read-only Git checks.
Runtime storage evidence accompanies the native result. No capability body or
authority bundle is written; the parent CLI may emit results to the user's stream.

Run `scripts/verify-sfx-invocation.ps1` to repeat the native acceptance cases and
retain their exact commands, exit codes and output streams. A null input is
delivered and rejected by the capability contract (exit 0). A missing capability
returns `CAPABILITY_NOT_FOUND` (exit 4), without a bootstrap/disk fallback.

The [retained native acceptance record](verification/database-cli-20260908.json)
contains all three commands, exit codes and exact stdout/stderr strings. The
positive input and complete domain outcome also match the prior expanded fixture
`admit-provider-once-its-target-is-declared`. This run used CLI commit `8261bd0`
and database reader commit `21ecfb0`. Validation passed: 16 CLI tests, six local
embodiment tests, 17 memory/expanded fixture comparisons (465 unchanged body
files), eight live query tests, and the database's 20 local tests. Eight optional
integration tests were skipped in the default database suite; the separate live
query invocation explicitly enabled its query integration cases.

From another directory, supply `--config C:\lab\repos\sfx-embody\sfx.config.json`.
The runtime paths are data in the project and runtime configs; adjust both the
workspace paths and the process read allowlist when using a different layout.
Install `sidefx-cli` with its new process binding support and prepare the pinned
database/compiler dependencies described in the README. Credentials remain in
the database reader's existing environment reference. Node 20.19.0 was exercised;
the VM modules and permission APIs used here remain experimental.

This is an explicit candidate provider binding. It supports authority that the
current Node planner can resolve; it does not claim managed admission, automatic
provider selection, universal capability coverage, or completed capsulization.
