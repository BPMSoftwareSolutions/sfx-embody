sfx-embody materializes executable Capability and Scenario bodies from database authority. The database selects the Capability, Scenario, downstream Scenarios, transformations, mechanics and provider bindings. The existing Node projection boundary materializes their native bodies. Paths derive from authority IDs and never establish identity.

[Deterministic scenario experience research](docs/research/scenario-experiences/README.md) inventories all 824 selected scenarios and 630 contracts, analyzes input-form and outcome-view generation, and proposes a presentation architecture and acceptance criteria. The accompanying census and renderer probes are research artifacts; the proposed capability is not implemented.

[Current repair and acceptance evidence](docs/native-embodiment-repair.md), and [bounded execution closure](docs/bounded-execution-closure.md) records why invoking one capability must expand only the capabilities it declares a dependency on. [Review findings and architectural goals](docs/embodiment-review-findings.md) record the properties the current integrity boundary and oracles are built to hold, and [cross-target embodiment](docs/cross-target-embodiment.md) records what Python and C# require and why declared mechanic meaning had to be closed first. The required meaning already existed. This repair replaces the Expression runtime with native expressions, retains declared lexical bindings, fixes weakened contract types, and adds inverse transformation checks. Full Capability/Scenario round-trip equivalence remains an explicit acceptance obligation.

| Directory | Contents |
| --- | --- |
| src/ | Database reader, materializer, language resolvers, native Reveal and verification |
| scripts/ | Regression, audit, reporting and baseline commands |
| tests/ | Resolver regression tests |
| config/ | Workspace paths and Capability/Scenario selections |
| embodiments/ | Capability → scenarios → Scenario → language → body and evidence |
| evidence/ | Local database query results, regression results and review evidence; ignored by Git |
| evidence/history/ | Local historical exploration records and superseded review specimens |
| docs/ | Current implementation findings and acceptance limits |
| baselines/ | Frozen original source, bodies and evidence with byte manifests |

Every directory named evidence and every embodiment.receipt.json file is ignored by Git, including those inside Scenarios and frozen baselines. Generated bodies remain version controlled. Verification and audit commands recreate current evidence and receipts locally; historical baseline verification requires its saved local evidence and receipts.

[Database invocation investigation](docs/database-direct-invocation.md) follows expanded execution through to live SQL-to-memory invocation. `planNode` produces the same native bytes in memory; `writeNodePlan` is an optional persistence step. The candidate memory loader runs those unchanged bytes and resolves contracts from the in-memory resource map. A restricted-process live proof passed for the provider resolver, and `npm run verify:memory` checks retained-fixture parity across the three configured capabilities. This is a bounded execution proof, not a completed database-native change or capsulization surface.

Invoke from this directory using the project's explicit database process binding:

```powershell
sfx capability invoke resolve-sidefx-eligible-providers --input '@examples/provider-resolution.request.json' --json
```

The exercised command returned exit 0 and `PROVIDERS_RESOLVED`. It reads the
capability and declared root Scenario from SQL, executes the selected native body
in memory, and returns the kernel result and authority/storage evidence. Install
the current `sidefx-cli` and prepare the dependencies described below first.
`scripts/verify-sfx-invocation.ps1` repeats the native success and failure checks.
The sample input is retained fixture authority for the pure provider resolver;
it does not call or admit an external provider. Database revision authoring and
capsulization are still separate work.

| Scenario | Executable code |
| --- | --- |
| adapt-job-market-intelligence-evidence | [Scenario](embodiments/adapt-job-market-intelligence-evidence/scenarios/adapt-job-market-intelligence-evidence/node/body/scenario.mjs), [port](embodiments/adapt-job-market-intelligence-evidence/scenarios/adapt-job-market-intelligence-evidence/node/body/providers/adapt-job-market-intelligence-evidence-port.mjs), [composition](embodiments/adapt-job-market-intelligence-evidence/scenarios/adapt-job-market-intelligence-evidence/node/body/composition.mjs) |
| bind-jmi-adapter-receipt | [Scenario](embodiments/adapt-job-market-intelligence-evidence/scenarios/bind-jmi-adapter-receipt/node/body/scenario.mjs), [port](embodiments/adapt-job-market-intelligence-evidence/scenarios/bind-jmi-adapter-receipt/node/body/providers/bind-jmi-adapter-receipt-port.mjs), [composition](embodiments/adapt-job-market-intelligence-evidence/scenarios/bind-jmi-adapter-receipt/node/body/composition.mjs) |
| verify-jmi-record-binding | [Scenario](embodiments/adapt-job-market-intelligence-evidence/scenarios/verify-jmi-record-binding/node/body/scenario.mjs), [port](embodiments/adapt-job-market-intelligence-evidence/scenarios/verify-jmi-record-binding/node/body/providers/verify-jmi-record-binding-port.mjs), [composition](embodiments/adapt-job-market-intelligence-evidence/scenarios/verify-jmi-record-binding/node/body/composition.mjs) |
| verify-jmi-type-admission | [Scenario](embodiments/adapt-job-market-intelligence-evidence/scenarios/verify-jmi-type-admission/node/body/scenario.mjs), [port](embodiments/adapt-job-market-intelligence-evidence/scenarios/verify-jmi-type-admission/node/body/providers/verify-jmi-type-admission-port.mjs), [composition](embodiments/adapt-job-market-intelligence-evidence/scenarios/verify-jmi-type-admission/node/body/composition.mjs) |
| admit-canonical-circuit-blueprint | [Scenario](embodiments/admit-canonical-circuit-blueprint/scenarios/admit-canonical-circuit-blueprint/node/body/scenario.mjs), [port](embodiments/admit-canonical-circuit-blueprint/scenarios/admit-canonical-circuit-blueprint/node/body/providers/admit-canonical-circuit-blueprint-port.mjs), [composition](embodiments/admit-canonical-circuit-blueprint/scenarios/admit-canonical-circuit-blueprint/node/body/composition.mjs) |
| emit-immutable-blueprint-authority | [Scenario](embodiments/admit-canonical-circuit-blueprint/scenarios/emit-immutable-blueprint-authority/node/body/scenario.mjs), [port](embodiments/admit-canonical-circuit-blueprint/scenarios/emit-immutable-blueprint-authority/node/body/providers/emit-immutable-blueprint-authority-port.mjs), [composition](embodiments/admit-canonical-circuit-blueprint/scenarios/emit-immutable-blueprint-authority/node/body/composition.mjs) |
| require-blueprint-conformance-evidence | [Scenario](embodiments/admit-canonical-circuit-blueprint/scenarios/require-blueprint-conformance-evidence/node/body/scenario.mjs), [port](embodiments/admit-canonical-circuit-blueprint/scenarios/require-blueprint-conformance-evidence/node/body/providers/require-blueprint-conformance-evidence-port.mjs), [composition](embodiments/admit-canonical-circuit-blueprint/scenarios/require-blueprint-conformance-evidence/node/body/composition.mjs) |
| require-blueprint-geometry-proof | [Scenario](embodiments/admit-canonical-circuit-blueprint/scenarios/require-blueprint-geometry-proof/node/body/scenario.mjs), [port](embodiments/admit-canonical-circuit-blueprint/scenarios/require-blueprint-geometry-proof/node/body/providers/require-blueprint-geometry-proof-port.mjs), [composition](embodiments/admit-canonical-circuit-blueprint/scenarios/require-blueprint-geometry-proof/node/body/composition.mjs) |
| require-current-approved-review-receipt | [Scenario](embodiments/admit-canonical-circuit-blueprint/scenarios/require-current-approved-review-receipt/node/body/scenario.mjs), [port](embodiments/admit-canonical-circuit-blueprint/scenarios/require-current-approved-review-receipt/node/body/providers/require-current-approved-review-receipt-port.mjs), [composition](embodiments/admit-canonical-circuit-blueprint/scenarios/require-current-approved-review-receipt/node/body/composition.mjs) |
| resolve-sidefx-eligible-providers | [Scenario](embodiments/resolve-sidefx-eligible-providers/scenarios/resolve-sidefx-eligible-providers/node/body/scenario.mjs), [port](embodiments/resolve-sidefx-eligible-providers/scenarios/resolve-sidefx-eligible-providers/node/body/providers/resolve-sidefx-eligible-providers-port.mjs), [composition](embodiments/resolve-sidefx-eligible-providers/scenarios/resolve-sidefx-eligible-providers/node/body/composition.mjs) |

The same implementation passes 17/17 retained fixtures across three Capabilities and ten Scenarios, with 64 native port comparisons against the selected provider and 320 real kernel observations. All 994 expression regions recover their transformation authority. A 200-vector corpus checks all 32 pure mechanics implemented by that provider, including native syntax recovery. All 21 declared conformance references the retained lineage uses now resolve at the pinned commit; binding each to its vectors remains outstanding. Contract evidence includes 2337 TypeScript assignments, 976 required compiler rejections, and 25764 runtime vectors.

The body contains no numbered expression variables, numbered state variables, numbered dependency aliases, generic Expression runtime, or mechanic dictionary. Contracts are TypeScript projections; the original JSON Schemas remain runtime admission authority. The real SDA Scenario Kernel, admission provider and native helper dependencies remain visible under body/providers/.

[NodeConsumerObjectProvider](src/resolvers/node/consumer-object-provider.mjs) implements the existing SDA ConsumerApplicationProvider.render protocol as a candidate native provider. [Native expression projection](src/resolvers/node/native-expression-projection.mjs) supplies Node syntax, lexical scoping and physical source maps. [Reveal](src/reveal-native-expressions.mjs) reads actual native syntax; [verification](src/verification/verify-native-projection.mjs) compares recovered transformations and execution with separately retained authority and the selected provider. The existing SDA graph and type builders remain in use.

Use Node.js 20 or later. Full regeneration requires the loaded SideFX Database workspace and the Scenario Driven Architecture workspace, including its built tools and Node kernel. Their locations are configuration data in [regression.cases.json](config/regression.cases.json). All configured paths, including selection and retained bundle locations, resolve against that file; absolute locations are also supported. The default layout is sfx-embody and scenario-driven-architecture under repos/, with sidefx-database alongside repos/. The database workspace owns its dependencies, local snapshot store and connection configuration (sidefx-connection-string); credentials are not part of this repository.

The selected database authority pins the SDA checkout to 716811046f52dd2a67f9ff308a50d755571cbbad. Prepare that checkout with its dependency installation and npm run build:tools before regenerating. The materializer verifies the selected source revision and source digests. An unavailable or different provider remains a hold. Retained baselines and historical reports preserve their original paths; current evidence records the folder where the latest verification actually ran. Git preserves exact bytes for digest-bearing files.

Reproduce from this directory (npm test runs independently of the database):

```powershell
npm ci --ignore-scripts --no-audit --no-fund
npm test
npm run verify:estate
npm run audit:source
npm run audit:lowering
npm run report
```

The regression and four resolver tests passed with exit code 0. The local evidence/regression-results.json retains exact component digests, database pins, dependency installation results and receipt hashes. Selection inputs live under config/selections/, and local database bundles live under evidence/authority/. Regeneration holds on unsupported topology or unavailable/ambiguous providers and protects edits to previously generated files. Historical specimens under evidence/history/ retain the context of their original run and are not current verification commands.

Receipts state EXECUTION_CHECKS_PASSED and NOT_REQUESTED for managed admission. They bind contract, native projection and lineage proof digests. Child Scenario testimony identifies its parent-fixture scope. These results do not claim universal Capability coverage, full governed Reveal/Compare, authority/database round trips or Cross-Apply to other languages. The separate sfx invocation above exercises the candidate database provider; no database admission write is claimed.

[Frozen original baseline](baselines/bbf0345d901983b6c0eeab449c2842419a3154b56bf2d04a973cf51c6974d66a/baseline.manifest.json). Its 17-fixture evidence and original bodies remain inspectable.
