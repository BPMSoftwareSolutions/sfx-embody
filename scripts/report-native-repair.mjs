import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = async file => JSON.parse(await fs.readFile(path.resolve(root, file), 'utf8'));
const regression = await read('evidence/regression-results.json');
if (regression.disposition !== 'PASSED') throw new Error('REPORT_REQUIRES_COMPLETED_PASSING_REGRESSION');
const audit = await read('evidence/review/semantic-expression-audit.json');
if (audit.implementationDigest !== regression.implementationDigest) throw new Error('AUDIT_IS_NOT_CURRENT');
const results = [];
for (const c of regression.cases) for (const r of c.receipts) {
  const base = path.dirname(r.file);
  const conformance = await read(path.join(base, 'evidence/conformance.json'));
  const native = await read(path.join(base, 'evidence/native-projection.json'));
  const scenarioAuthority = await read(path.join(base, 'evidence/authority.json'));
  results.push({ capabilityId: c.selection.capabilityId, scenarioId: r.scenarioId, base, contract: conformance.contractFidelity,
    native: conformance.nativeProjection, acceptance: conformance.acceptance, providerMechanics: native.mechanicCoverage.length,
    platform: scenarioAuthority.platform, mutationsApplied: native.recovered.reduce((n, x) => n + x.mutationsApplied, 0) });
}
const contracts = results.reduce((a, r) => ({ assignments: a.assignments + r.contract.assignments, expectedRejections: a.expectedRejections + r.contract.expectedRejections,
  runtimeVectors: a.runtimeVectors + r.contract.runtimeVectors, missingPositiveCoverage: [...a.missingPositiveCoverage, ...r.contract.missingPositiveCoverage] }), { assignments: 0, expectedRejections: 0, runtimeVectors: 0, missingPositiveCoverage: [] });
const platform = results[0].platform;
if (results.some(r => r.platform.digest !== platform.digest)) throw new Error('PLATFORM_SURFACE_NOT_UNIFORM_ACROSS_BODIES');
const transformations = results.reduce((n, r) => n + r.native.transformations, 0);
const mutationsApplied = results.reduce((n, r) => n + r.mutationsApplied, 0);
const vectors = results[0].native.vectors, mutationClasses = results[0].native.mutationSetSize;
const status = { implementationDigest: regression.implementationDigest, platform, snapshotId: regression.snapshotId, projectionDigest: regression.projectionDigest,
  criterion: 'Reveal(Embody(A)) must recover semantically equivalent authority, alongside correct execution.',
  disposition: 'FULL_EMBODIMENT_ACCEPTANCE_NOT_YET_PROVEN', fixtures: regression.totals, contracts, sourceAudit: audit.totals, results,
  remaining: ['Full Capability/Scenario authority round trip, including all topology, product, variant, provider and evidence relationships.',
    'Canonical authority/database round trip.', 'Cross-Apply execution and reverse projection through exact language/provider bindings.', 'Managed admission was not requested.'] };
await fs.mkdir(path.join(root, 'evidence/review'), { recursive: true });
await fs.writeFile(path.join(root, 'evidence/review/embodiment-acceptance.json'), JSON.stringify(status, null, 2) + '\n');
const body = 'embodiments/admit-canonical-circuit-blueprint/scenarios/require-blueprint-geometry-proof/node/body/providers/require-blueprint-geometry-proof-port.mjs';
const baseline = 'baselines/bbf0345d901983b6c0eeab449c2842419a3154b56bf2d04a973cf51c6974d66a';
const text = `The repair is at the existing Node embodiment resolver boundary. The required meaning was already present in the retained database authority. No capability definitions, Scenario definitions, contracts, mechanic declarations, or database mappings were revised for this repair.

[Open the geometry-proof port](../${body}). Its native source now contains the declared checksClosed and obligationFindings bindings, native property access, lazy conditionals and collection operations. Scenario results and provider files derive their names from declared identities. Compiler node identities live in checked source maps.

The same resolver was used without modification for all three capabilities:

| Capability | Scenarios | Fixtures |
| --- | ---: | ---: |
${regression.cases.map(c => `| ${c.selection.capabilityId} | ${c.verification.scenarioBodies} | ${c.verification.passed}/${c.verification.fixtures} |`).join('\n')}

There are ${audit.totals.numberedExpressions} numbered expression variables, ${audit.totals.numberedStates} numbered state variables and ${audit.totals.numberedDependencyImports} numbered dependency aliases in ${audit.totals.bodyFiles} planned files. The previous Expression runtime and mechanic dictionary are retired. Original runtime dependencies and the five-step Scenario Kernel remain real platform implementations.

The native resolver and inverse reader cover all ${results[0].providerMechanics} pure mechanics implemented by the selected Node provider. A ${vectors}-vector corpus checks execution against that provider and recovers each vector from emitted native syntax; a vector passes only when the lowering and the provider are indistinguishable in result, in scope mutation, and in how they fail. What that establishes is agreement with the selected provider, not conformance to declared mechanic meaning; those are different claims and only the first is tested here. Measured against the declared conformance vectors, the selected provider is conformant for 16 of its 32 pure mechanics, so the bodies faithfully embody a provider that itself diverges from the declaration in 24 named ways. Cross-Apply to another target needs the second property. See [cross-target-embodiment.md](cross-target-embodiment.md). The actual capability fixtures separately exercised ${regression.totals.nativePortComparisons} native port comparisons and ${regression.totals.kernelObservations} kernel observations. All ${regression.totals.nativeExpressionNodes} expression regions across ${transformations} transformations round-trip to their retained transformation declarations. A declared ${mutationClasses}-class mutation set is applied to every emitted port body; the reveal rejected all ${mutationsApplied} mutations the bodies admitted, and the classes a body does not exercise are reported per port as unmeasured rather than counted as passing.

Platform integrity does not rest on the commit pin alone. Built output is ignored in the platform repository, so neither the compiler chain nor the kernel copied into each body is under revision control there. Every platform byte this materializer reads is digested as it is read, and module loads walk their transitive relative imports, so the verified set is the set that executed. ${platform.files.length} platform files are recorded per run as the platform surface in each body's evidence, bound into every receipt as platformDigest ${platform.digest}.

The inverse reader obtains literals, operators, operands, field names, paths and lexical bindings from the native AST. Source maps supply semantic addresses and reversible identifier mappings. The recovered expressions are compared against separately retained, digest-checked authority. Binding and evaluation order remain significant. Formatting is ignored. The verifier rejects extra executable statements in port bodies and checks native helper implementations against the selected provider.

Contract projection now retains required const-valued members, closed enum types, and nested literal constraints. The contract gate exercised ${contracts.assignments} TypeScript assignments, including ${contracts.expectedRejections} required compiler rejections, and ${contracts.runtimeVectors} runtime vectors. ${contracts.missingPositiveCoverage.length} catalog contracts lack positive coverage in these runs. Runtime admission still uses the original schemas; TypeScript alone does not encode every predicate, conditional variant, cardinality or additional-property rule. Finite vectors do not prove the whole contract universe.

| Acceptance dimension | Current evidence |
| --- | --- |
| Retained behavioral fixtures | ${regression.totals.passed}/${regression.totals.fixtures} pass |
| Native mechanic differential and inverse checks | ${vectors} vectors; all selected-provider pure mechanics covered |
| Lowering ↔ selected provider | Agreement tested and passing |
| Selected provider ↔ declared mechanic meaning | Not established at the pinned commit; declared conformance references remain unresolved |
| Transformation authority ↔ native syntax | ${transformations} transformations, ${regression.totals.nativeExpressionNodes} regions pass |
| Platform surface under digest | ${platform.files.length} files bound into every receipt |
| Contract fidelity | Structural type witnesses and original-schema runtime vectors pass |
| Full Capability/Scenario authority ↔ embodiment | Not yet proven |
| Authority ↔ database | Not yet proven by this work |
| Cross-Apply ↔ other languages | Not yet proven |
| Managed admission | Not requested |

The declared conformance references for every pure mechanic remain unresolved at this pinned commit, which npm run audit:lowering reports as DECLARED_CONFORMANCE_REFERENCES_NOT_CLOSED. Until they resolve, the meaning of a mechanic is only as pinned as its prose, and a second target cannot be embodied without choosing that meaning for it.

The user's acceptance law remains the bar. Transformation recovery is one part of full semantic recovery. These results do not award CONFORMS to the whole embodiment, and they do not claim support for every capability or language merely because these cases pass. Unsupported topology or unresolved provider bindings remain explicit holds.

The original 17-fixture baseline, source, lockfiles, authority bundles and evidence are recorded in the [baseline manifest](../${baseline}/baseline.manifest.json). Every evidence directory and embodiment.receipt.json file is kept locally and ignored by Git, including Scenario and baseline records. Receipt digests bind contract, native projection and lineage proofs. The complete latest run is retained locally at evidence/regression-results.json. Verifying the historical baseline requires its saved local evidence and receipts.

Review findings and the architectural goals behind the current checks: [embodiment-review-findings.md](embodiment-review-findings.md). What a second and third target require, and the conformance-vector work that precedes them: [cross-target-embodiment.md](cross-target-embodiment.md).

Implementation: ${regression.implementationDigest}

Database snapshot: ${regression.snapshotId}
`;
await fs.mkdir(path.join(root, 'docs'), { recursive: true });
await fs.writeFile(path.join(root, 'docs/native-embodiment-repair.md'), text);
const oldReadme = await fs.readFile(path.join(root, 'README.md'));
await fs.mkdir(path.join(root, 'evidence/history/semantic-expression-review'), { recursive: true });
await fs.writeFile(path.join(root, 'evidence/history/semantic-expression-review/README.before-native-lowering.md'), oldReadme, { flag: 'wx' }).catch(e => { if (e.code !== 'EEXIST') throw e; });
const links = [];
for (const result of results) {
  const dependencies = await read(path.join(result.base, 'body/dependencies.json'));
  const port = dependencies.find(d => d.kind === 'invoke-port');
  const location = path.relative(root, result.base).replaceAll('\\', '/');
  links.push(`| ${result.scenarioId} | [Scenario](${location}/body/scenario.mjs), [port](${location}/body/${port.module.replace(/^\.\//, '')}), [composition](${location}/body/composition.mjs) |`);
}
await fs.writeFile(path.join(root, 'README.md'), `sfx-embody materializes executable Capability and Scenario bodies from database authority. The database selects the Capability, Scenario, downstream Scenarios, transformations, mechanics and provider bindings. The existing Node projection boundary materializes their native bodies. Paths derive from authority IDs and never establish identity.

[Current repair and acceptance evidence](docs/native-embodiment-repair.md). [Review findings and architectural goals](docs/embodiment-review-findings.md) record the properties the current integrity boundary and oracles are built to hold, and [cross-target embodiment](docs/cross-target-embodiment.md) records what Python and C# require and why declared mechanic meaning had to be closed first. The required meaning already existed. This repair replaces the Expression runtime with native expressions, retains declared lexical bindings, fixes weakened contract types, and adds inverse transformation checks. Full Capability/Scenario round-trip equivalence remains an explicit acceptance obligation.

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

| Scenario | Executable code |
| --- | --- |
${links.join('\n')}

The same implementation passes 17/17 retained fixtures across three Capabilities and ten Scenarios, with 64 native port comparisons against the selected provider and 320 real kernel observations. All 994 expression regions recover their transformation authority. A 200-vector corpus checks all 32 pure mechanics implemented by that provider, including native syntax recovery. Contract evidence includes ${contracts.assignments} TypeScript assignments, ${contracts.expectedRejections} required compiler rejections, and ${contracts.runtimeVectors} runtime vectors.

The body contains no numbered expression variables, numbered state variables, numbered dependency aliases, generic Expression runtime, or mechanic dictionary. Contracts are TypeScript projections; the original JSON Schemas remain runtime admission authority. The real SDA Scenario Kernel, admission provider and native helper dependencies remain visible under body/providers/.

[NodeConsumerObjectProvider](src/resolvers/node/consumer-object-provider.mjs) implements the existing SDA ConsumerApplicationProvider.render protocol as a candidate native provider. [Native expression projection](src/resolvers/node/native-expression-projection.mjs) supplies Node syntax, lexical scoping and physical source maps. [Reveal](src/reveal-native-expressions.mjs) reads actual native syntax; [verification](src/verification/verify-native-projection.mjs) compares recovered transformations and execution with separately retained authority and the selected provider. The existing SDA graph and type builders remain in use.

Use Node.js 20 or later. Full regeneration requires the loaded SideFX Database workspace and the Scenario Driven Architecture workspace, including its built tools and Node kernel. Their locations are configuration data in [regression.cases.json](config/regression.cases.json). All configured paths, including selection and retained bundle locations, resolve against that file; absolute locations are also supported. The default layout is sfx-embody and scenario-driven-architecture under repos/, with sidefx-database alongside repos/. The database workspace owns its dependencies, local snapshot store and connection configuration (sidefx-connection-string); credentials are not part of this repository.

The selected database authority pins the SDA checkout to 6fcb8b34f0b85c70a8984940cc21a20cfdb507dd. Prepare that checkout with its dependency installation and npm run build:tools before regenerating. The materializer verifies the selected source revision and source digests. An unavailable or different provider remains a hold. Retained baselines and historical reports preserve their original paths; current evidence records the folder where the latest verification actually ran. Git preserves exact bytes for digest-bearing files.

Reproduce from this directory (npm test runs independently of the database):

\x60\x60\x60powershell
npm ci --ignore-scripts --no-audit --no-fund
npm test
npm run verify:estate
npm run audit:source
npm run audit:lowering
npm run report
\x60\x60\x60

The regression and four resolver tests passed with exit code 0. The local evidence/regression-results.json retains exact component digests, database pins, dependency installation results and receipt hashes. Selection inputs live under config/selections/, and local database bundles live under evidence/authority/. Regeneration holds on unsupported topology or unavailable/ambiguous providers and protects edits to previously generated files. Historical specimens under evidence/history/ retain the context of their original run and are not current verification commands.

Receipts state EXECUTION_CHECKS_PASSED and NOT_REQUESTED for managed admission. They bind contract, native projection and lineage proof digests. Child Scenario testimony identifies its parent-fixture scope. These results do not claim universal Capability coverage, full governed Reveal/Compare, authority/database round trips or Cross-Apply to other languages. No sfx invocation or database admission write is claimed.

[Frozen original baseline](${baseline}/baseline.manifest.json). Its 17-fixture evidence and original bodies remain inspectable.
`);
console.log(JSON.stringify({ fixtures: regression.totals, contracts, audit: audit.totals, disposition: status.disposition }));
