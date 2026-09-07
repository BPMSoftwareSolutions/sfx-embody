This is the historical review of the original interpreter-shaped baseline. The subsequent repair and current proof limits are recorded in [native-embodiment-repair.md](native-embodiment-repair.md). Original bodies and evidence are preserved under [the frozen baseline](../baselines/bbf0345d901983b6c0eeab449c2842419a3154b56bf2d04a973cf51c6974d66a/baseline.manifest.json).

At the time of this review, the bodies executed the retained fixtures, but their source did not adequately express the Capability's meaning. The principal defect was in the candidate embodiment resolver: it materialized an expression-evaluation object graph and exposed construction order as application vocabulary. Renaming numbered variables alone would leave that architecture in place.

This review inventories all 475 planned body files across the three Capabilities and ten Scenarios, verifies their hashes against the retained plans, and inspects their TypeScript/JavaScript syntax trees. There are 128 distinct file contents. Detailed inspection covers Scenario methods, port bodies, native mechanic classes, dependency composition, contract projection, testimony, and the verifier. Dependency package internals are outside this review. The working bodies and their execution receipts were not changed.

The machine-readable inventory is [semantic-expression-audit.json](C:/lab/experiments/sidefx-embodiment/review/semantic-expression-audit.json). It records 994 numbered expression variables, 17 numbered state variables, and 10 numbered port import aliases. The retained transformation authority already contains 46 named local bindings and 18 iteration bindings. Those 46 names are encoded as object keys and scope lookups; none is surfaced as a native local variable in the generated composition.

| Generated surface | Observed loss of meaning | Repair owner |
| --- | --- | --- |
| `scenario.mjs` | Scenario and I/E/O identities survive in declaration data, but the executable method uses `input`, `state1`, generic dependency lookups and untyped results | Existing Scenario embodiment resolver: preserve declared operation and result boundaries in native methods and typed values |
| `providers/port-0.mjs` | Every literal, field access and operation becomes a separately numbered `Expression` object; meaningful bindings are buried in construction parameters | Native transformation projection at the existing language resolver boundary |
| `providers/mechanics.mjs` | Reusable mechanic identities survive, but every method takes `expression, scope, evaluate`, reproducing the evaluator calling convention | Mechanic implementation/projection binding: expose native operand/result contracts and resolve pure operations during projection |
| `composition.mjs` | Named classes are imported as `Dependency0`; port IDs survive only in string-keyed injection data | Physical symbol and dependency projection from the already-declared port and Scenario IDs |
| `contracts/*.ts` | Types are separate from the untyped executable methods; required constant fields can disappear; closed enumerations can become `unknown` or `string` | Consumer contract representation/profile and the existing shared schema-to-type projection boundary |
| Mechanic observations and Reveal | Trace records identify a class and source pointer, but not a complete semantic execution occurrence; Reveal enumerates classes and compares copied statements | Existing lineage, Reveal/Compare and conformance boundaries |
| Copied SDA kernel and support files | Generic names such as `input` are appropriate inside the generic kernel; that vocabulary should not dictate the application's business vocabulary | Retain the existing control-plane responsibilities and show the declared application bindings |

**Meaning that already exists.** In `resolve-sidefx-eligible-providers`, [port-0.mjs](C:/lab/experiments/sidefx-embodiment/embodiments/resolve-sidefx-eligible-providers/scenarios/resolve-sidefx-eligible-providers/node/body/providers/port-0.mjs:7) materializes these computations:

| Current variable | Declared meaning and operands |
| --- | --- |
| `expression3` | `capabilityMatches`: binding platform Capability ID equals requested platform Capability ID |
| `expression6` | `isAdmitted`: binding lifecycle equals the declared `ADMITTED` value |
| `expression9` | `conformanceIsAdmitted`: binding conformance disposition belongs to the input's conformant dispositions |
| `expression12` | `targetIsDeclared`: requested target belongs to the binding's declared targets |
| `expression51` | `consideredProviders`: map the declared `binding` scope over input provider bindings |
| `expression56` | `eligibleProviders`: filter considered providers by the declared eligibility disposition |

These meanings came from the database-retained transformation `transform-resolve-sidefx-eligible-providers.v1`. `capabilityMatches` is a scoped binding in that transformation. It does not need a newly invented Scenario or Mechanic identity.

Inside the existing `binding` scope, the proposed native source can directly express the four declared predicates:

```typescript
const capabilityMatches =
  binding.platformCapabilityId === input.requestedPlatformCapabilityId;
const isAdmitted = binding.lifecycle === "ADMITTED";
const conformanceIsAdmitted =
  input.conformantDispositions.includes(binding.conformanceDisposition);
const targetIsDeclared = binding.declaredTargets.includes(input.requestedTarget);
```

This is a design excerpt, not an applied or verified replacement body. It uses the existing names, operands and literal authority. The containing map, selection, result construction, provider boundary and testimony must also be projected and verified. Native expressions can live inside object-oriented Scenario/provider methods. A separate application object for every literal or comparison is not necessary to preserve its mechanic identity in lineage.

The binding count does not imply that all 994 expression nodes should become 994 named business objects. Simple operands can appear inline; named bindings should become scoped locals; collections should expose their declared iteration variables; significant existing Scenario/provider boundaries should remain explicit. Compiler temporaries can remain internal where necessary and trace back to an owned expression without becoming new semantic authority.

**The deeper implementation defect.** The candidate resolver explicitly creates `expression${constructions.length}` in [consumer-object-provider.mjs](C:/lab/experiments/sidefx-embodiment/resolvers/node/consumer-object-provider.mjs:201). Its generated [Expression.execute](C:/lab/experiments/sidefx-embodiment/embodiments/resolve-sidefx-eligible-providers/scenarios/resolve-sidefx-eligible-providers/node/body/providers/expression.mjs:9) recursively invokes child expressions through `scope` and `evaluate`. Removing the operation switch did not remove runtime interpretation: the object graph still determines evaluation at runtime.

The existing Harness [Compiler Pure Expression Projection Design](C:/lab/repos/agentic-harness/docs/compiler-pure-expression-projection-design.md:20) already calls for compiling pure transformations directly into native target source. Its named `SemanticTransformationCompiler` source was not found in the searched SDA/Harness files. The inspected pinned SDA `SemanticTransformationGraphCompiler` emits execution cells and edges; it does not emit the native application functions described by that design. The document establishes a design direction, not evidence that an admitted emitter is available.

The correct implementation work remains at the existing SDA language/provider/projection boundary. The exact eligible emitter and binding must be resolved there. A new compiler beside that boundary, application-specific expression-name dictionaries, and Capability-ID dispatch would repeat the architectural problem.

**What belongs in the platform and database.** Preserve the information already present through the existing projection inputs: Capability/Scenario identity, transformation identity, scoped binding and iteration names, operand roles, I/E/O contracts, execution order, provider slots, source pointers and authority digests. The pinned [ExecutionCell model](C:/lab/repos/scenario-driven-architecture/languages/typescript/runtimes/node/semantic-execution-graph/model.d.ts:17) already includes semantic address, altitude, parent, contracts, authority and provider-slot references. That is an existing basis for lineage.

Where these facts exist in retained declarations but are lost in the projection view, repair that view or its database mapping. There is no evidence here that a new database entity is required merely to rename the expression nodes. Where a computation's business responsibility, contract or policy relationship is genuinely undeclared, enrich the owning Scenario/transformation/Mechanic authority through its existing lifecycle. Do not generate a plausible business name and treat it as an admitted fact. An ambiguous binding such as `evaluation` remains the declared name until its owning authority is clarified.

A reusable target projection policy should govern legal identifier spelling, lexical scopes, collisions, contract type names, provider member names and source mappings. It must work from declarations for every Capability. Filename spellings and construction ordinals do not establish semantic identity. The existing [embodiment guidance](C:/lab/repos/sidefx-cli/docs/sfx-embody.md:2583) assigns repairs to the lowest authoritative layer that owns the defect.

**Contract fidelity needs a separate repair.** The generated [request interface](C:/lab/experiments/sidefx-embodiment/embodiments/resolve-sidefx-eligible-providers/scenarios/resolve-sidefx-eligible-providers/node/body/contracts/sidefx-provider-resolution-request-v1.ts:8) exports constants for `contractId` and `evaluationBoundary` but omits the corresponding required properties. The generated [resolution interface](C:/lab/experiments/sidefx-embodiment/embodiments/resolve-sidefx-eligible-providers/scenarios/resolve-sidefx-eligible-providers/node/body/contracts/sidefx-semantic-provider-resolution-v1.ts:9) declares `disposition: unknown`, despite the schema's closed enumeration.

The audit found omitted required constant properties in 21 generated files representing six distinct root types; several files repeat a shared contract across Scenario bodies. The native runtime admission provider still uses the original schemas and correctly enforces these constraints. The defect is in the static representation and its disconnected executable signatures.

[contract-type-witness.ts](C:/lab/experiments/sidefx-embodiment/review/contract-type-witness.ts) compiled with zero TypeScript diagnostics while constructing a request without those required fields and assigning `42` to the disposition type. The actual schema admission rejected both; [the retained result](C:/lab/experiments/sidefx-embodiment/review/contract-type-witness.result.json) identifies the exact violations. This demonstrates why compilation alone cannot prove that a generated type expresses a contract.

The current materializer applies the kernel structural projection profile to consumer contracts. That profile extracts constant properties into separate constants, and its enum handling depends on kernel-specific override data. Consumer payload types need required literal properties and closed value unions derived from their own schemas, then actual use in Scenario/provider signatures. Repair the appropriate representation/profile and shared schema lowering rather than changing kernel representations globally or adding per-Capability type exceptions. Dynamic constraints such as patterns and collection bounds still belong to runtime admission where native types cannot express them fully.

**Execution semantics must survive a readable body.** Native projection must preserve sequential `let` evaluation and shadowing, per-item map/filter scopes, lazy branch selection and short-circuit behavior, strict equality, fresh composite literals, serialization and property order, digest inputs, error propagation, and cancellation/provider-effect boundaries. Hoisting every named computation into eager top-level constants can change behavior. Reusing a composite literal can change reference equality or mutation behavior. Native standard-library resemblance alone is not proof of equivalence.

The existing Scenario Kernel's admission/authority/execution/outcome/disposition circuit remains the control-plane boundary. Pure expression projection must not absorb provider effects, erase declared child invocations or silently alter graph topology. Mechanic lineage can map a native expression or method span to its semantic address without requiring an interpreter object to exist at runtime.

**Proof must evaluate the intended architecture.** The existing verifier checks fixture assertions, kernel observations, generated syntax/type compilation, and statement equality between the copied evaluator cases and generated mechanic methods. Those checks substantiate the retained 17-fixture execution result. Statement equality also ties the proof to the interpreter-shaped implementation: a valid native expression emitter will intentionally produce a different syntax tree.

Keep the behavioral regression baseline and add checks that:

1. Reveal reconstructs the declared Scenario/provider/Mechanic relationships and data dependencies from physical source and compares them to authority; class counts alone are insufficient.
2. Every declared local/iteration binding and meaningful result boundary is represented in its proper scope, or accounted for by a semantics-preserving inline projection.
3. Generated contract types retain required properties, constants and closed enumerations, and executable signatures actually use those types.
4. Every lowered mechanic has the selected native implementation/equivalence evidence, source mapping and relevant conformance vectors. Valid language-specific lowering should not require textual equality with an interpreter case.
5. Testimony identifies semantic execution occurrences, including scope/iteration and authority/provider provenance. The current class-name/source-pointer observations are too weak for full cell testimony; the existing `CellExecutionTestimony` model already specifies a richer contract.
6. The same unchanged resolver continues to pass the three Capability fixture suites, with additional vectors for lexical scope, laziness, equality, fresh values, serialization/digests and failures. Cross-language claims require executing the admitted targets separately.

Recommended order: agree the source shape against this authority-backed example; repair the existing native projection and consumer contract representation; preserve semantic bindings and source mappings through projection; strengthen Reveal/Compare and type fidelity; then regenerate and rerun the unchanged multi-Capability suite. This review does not amend database authority, regenerate the existing bodies, or label the proposed source shape as implemented.
