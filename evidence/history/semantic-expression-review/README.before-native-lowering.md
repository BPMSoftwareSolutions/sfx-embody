# Scenario embodiments

The database selects the Capability, Scenario, execution authority, downstream
Scenario invocations, transformations, mechanic declarations and provider bindings.
Files are materialized bodies. Their directory names do not establish identity.

## Inspect the code

The executed composition is under
`embodiments/adapt-job-market-intelligence-evidence/scenarios/`:

| Scenario | Body | Evidence |
| --- | --- | --- |
| adapt-job-market-intelligence-evidence | [Scenario](embodiments/adapt-job-market-intelligence-evidence/scenarios/adapt-job-market-intelligence-evidence/node/body/scenario.mjs), [composition](embodiments/adapt-job-market-intelligence-evidence/scenarios/adapt-job-market-intelligence-evidence/node/body/composition.mjs), [port](embodiments/adapt-job-market-intelligence-evidence/scenarios/adapt-job-market-intelligence-evidence/node/body/providers/port-0.mjs), [mechanics](embodiments/adapt-job-market-intelligence-evidence/scenarios/adapt-job-market-intelligence-evidence/node/body/providers/mechanics.mjs) | [Receipt](embodiments/adapt-job-market-intelligence-evidence/scenarios/adapt-job-market-intelligence-evidence/node/embodiment.receipt.json), [fixture results](embodiments/adapt-job-market-intelligence-evidence/scenarios/adapt-job-market-intelligence-evidence/node/evidence/fixture-results.json) |
| verify-jmi-record-binding | [Scenario](embodiments/adapt-job-market-intelligence-evidence/scenarios/verify-jmi-record-binding/node/body/scenario.mjs), [mechanics](embodiments/adapt-job-market-intelligence-evidence/scenarios/verify-jmi-record-binding/node/body/providers/mechanics.mjs) | [Receipt](embodiments/adapt-job-market-intelligence-evidence/scenarios/verify-jmi-record-binding/node/embodiment.receipt.json) |
| verify-jmi-type-admission | [Scenario](embodiments/adapt-job-market-intelligence-evidence/scenarios/verify-jmi-type-admission/node/body/scenario.mjs), [mechanics](embodiments/adapt-job-market-intelligence-evidence/scenarios/verify-jmi-type-admission/node/body/providers/mechanics.mjs) | [Receipt](embodiments/adapt-job-market-intelligence-evidence/scenarios/verify-jmi-type-admission/node/embodiment.receipt.json) |
| bind-jmi-adapter-receipt | [Scenario](embodiments/adapt-job-market-intelligence-evidence/scenarios/bind-jmi-adapter-receipt/node/body/scenario.mjs), [mechanics](embodiments/adapt-job-market-intelligence-evidence/scenarios/bind-jmi-adapter-receipt/node/body/providers/mechanics.mjs) | [Receipt](embodiments/adapt-job-market-intelligence-evidence/scenarios/bind-jmi-adapter-receipt/node/embodiment.receipt.json) |

Each body contains native contract types under `contracts/`, exact copied SDA
kernel/admission source under `providers/sda/`, and a package manifest and lock.
Each target contains its plan, source lineage, AST reveal, fixture testimony and
conformance result under `evidence/`.

The same renderer now generates and executes three complete Capability fixture
sets. [regression-results.json](regression-results.json) records one unchanged
implementation digest across every case and includes dependency-install commands,
exit statuses, receipt digests and native execution summaries.

| Capability | Scenario bodies executed | Retained fixtures |
| --- | ---: | ---: |
| [adapt-job-market-intelligence-evidence](embodiments/adapt-job-market-intelligence-evidence/scenarios/adapt-job-market-intelligence-evidence/node/body/scenario.mjs) | 4 | 5/5 passed |
| [admit-canonical-circuit-blueprint](embodiments/admit-canonical-circuit-blueprint/scenarios/admit-canonical-circuit-blueprint/node/body/scenario.mjs) | 5 | 8/8 passed |
| [resolve-sidefx-eligible-providers](embodiments/resolve-sidefx-eligible-providers/scenarios/resolve-sidefx-eligible-providers/node/body/scenario.mjs) | 1 | 4/4 passed |

The blueprint composition executes `require-blueprint-geometry-proof` and its
other declared child Scenarios. Their receipts now retain execution proof within
the complete parent fixtures. Each root's native mechanic bodies are in its
`body/providers/mechanics.mjs`; its executable dependencies are visible in
`body/composition.mjs`.

## Architecture and exact implementation scope

[NodeConsumerObjectProvider](resolvers/node/consumer-object-provider.mjs) is a
**candidate implementation** of SDA's existing `ConsumerApplicationProvider.render`
protocol. It has not been admitted into SDA or Harness. It lowers the declared
ordered invocations into explicit native Scenario methods and dependency objects.
It extracts the selected Node provider's mechanic statements into native classes;
its object construction follows the mechanic declaration's `authoringForm`.
Stored source order is preserved, including sequential `let` bindings.

The Node provider also handles physical type projection details exposed by the
additional Capabilities: quoted property names, separate constant export
namespaces, nullable type-array representation and relative schema references.
It supplies equivalent nullable/reference views to the existing SDA type builder
and retains those adaptations in `evidence/contract-projection.json`. Runtime
admission still uses the original schema bytes and the complete declared contract
catalog, including referenced schemas. Definition-only shared schemas are
available for reference resolution without becoming fabricated object types.

[materialize-node.mjs](materialize-node.mjs) uses the existing SDA Gherkin builder,
semantic execution graph compiler and native contract projection machinery. It
copies the existing five-step Scenario Kernel, disposition resolver, schema
admission provider and their relative import dependencies. These remain visible
inside each body. No provider selection is inferred from an ID's spelling.

Capability-specific values in generated bodies came from retained authority
bytes. The reader, renderer and verifier contain no Capability-specific branch.
Physical paths are derived from selected IDs; execution uses declarations and
explicit dependency bindings. Missing/ambiguous sources and unsupported operations
stop materialization. This candidate currently supports ordered `invoke-port`
transformations and `invoke-scenario`; it holds unsupported transition topology
and multiple native mechanic providers. It does not establish universal coverage.

The selected database snapshot pins SDA source commit
`6fcb8b34f0b85c70a8984940cc21a20cfdb507dd`. Runtime/build artifact digests are recorded
in each plan. The generated JavaScript is executable directly; the contract models
are TypeScript from SDA's existing structural renderer. No C#/Python/Java/Go/C++
body has been fabricated where exact database binding evidence is absent.

## Executed proof

`node verify-estate.mjs regression.cases.json` completed with exit code 0:

- All 17 database-retained fixtures passed across the three Capabilities above.
- Ten Scenario bodies executed, producing 320 five-step kernel observations and
  6,248 mechanic invocation observations.
- All 112 emitted mechanic classes across those bodies have the same statements
  as the selected native provider; comparison uses the TypeScript AST printer.
- Generated contract types passed strict TypeScript checks.
- Real contract admission rejected invalid input in all three Capabilities;
  explicitly injected child failures propagated to their parents in both
  compositions with child Scenarios. The injection exists only in the
  verifier, not the generated composition.

`node --test node-resolver.test.mjs` also passed four checks for nullable schema
equivalence, declared relative-reference resolution, preservation of literal
data, and explicit rejection of unsupported unions. The first failed combined
run exposed a contract-root registration issue; the shared fix was applied before
the final successful immutable-implementation run.

The reveal records physical structure and native statement fidelity. This is not
the complete governed Reveal/Compare/Cross-Apply admission workflow. Receipts say
`EXECUTION_CHECKS_PASSED`, with `managedAdmission: NOT_REQUESTED`. Child receipts
explicitly identify executions within parent fixtures rather than claiming
independent child fixture coverage.

## Reproduce

Regenerate from the live database, install each body's pinned dependencies and
execute all three fixture sets with one command:

```powershell
node .\verify-estate.mjs .\regression.cases.json
```

`regression.cases.json` contains only source locations and selection inputs. The
runner verifies the same database snapshot and implementation component digests
throughout the run. Adding a supported Capability means adding its selection
data; there is no Capability-specific executable branch. Passing these three
cases establishes those concrete executions, not universal estate or language
coverage.

From this directory, use `npm ci --ignore-scripts --no-audit --no-fund` to restore
the development dependencies pinned from the retained platform package. Then:

```powershell
node .\read-authority.mjs C:\lab\sidefx-database .\selection.json .\authority-bundle.json
node .\materialize-node.mjs .\authority-bundle.json C:\lab\repos\scenario-driven-architecture .
```

Install each emitted body's dependencies using `npm ci --ignore-scripts --no-audit
--no-fund` from its `body/` directory. For a newly generated body without a lock,
use `npm install --ignore-scripts --no-audit --no-fund` first. The verifier pins each
resulting lock in its receipt. Then run the actual generated composition:

```powershell
node .\verify-node.mjs .\embodiments\adapt-job-market-intelligence-evidence\scenarios\adapt-job-market-intelligence-evidence\node C:\lab\repos\scenario-driven-architecture .
```

All three commands above were exercised with exit code 0. Selection is input data
in `selection.json`; the second selection is `second-capability.input.json`.
Re-materialization resets the receipt to awaiting execution until verification
succeeds again. Database query receipts retain the exact source snapshot and
resolution evidence. No `sfx` invocation, managed admission, commit or publication
is claimed by this lab proof.
