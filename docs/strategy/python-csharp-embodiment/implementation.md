# Python/C# embodiment implementation status

2026-09-13. Work is continuing. No requirement has been found that calls for a
change to every conforming language kernel.

The real CLI constructs and materializes the equity embodiment for Node, Python
and C#. Each materialization writes five declared files and verifies their digests.
`execute-declared-capability` reads the selected authority and bindings, admits
input, runs the native consumer, and admits the outcome. Real CLI invocations on
all three targets return `EXECUTION_COMPLETED` with
`EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`.

Python and C# execute their own graph schedulers and transformations. Credential
binding and HTTP exchange use the existing governed Node providers. Contract
admission uses the existing Node schema-admission provider, including its schema
digest checks. Those dependencies are declared; these results do not establish
independent Python/C# implementations of HTTP, credential binding, or schema
admission. No platform kernel source has been changed.

| Step | Verified state |
| --- | --- |
| M0 | Original Node plan and Python/C# failure evidence retained under `evidence/python-csharp-embodiment/baseline/`. |
| M1 | Six profiles are read from normalized declarations. Target defaults and provider selection are declared in rows. The original selection migration preserved the baseline Node digests. |
| M2 | Binding resolution runs between authority reading and planning. All five invoked equity ports resolve for Node, Python and C#. The remaining estate requirements must still be reconciled against the full feature drafts. |
| M3 | The two equity effects are bound to the native consumers through the existing governed providers. Native consumer probes reject invalid input and a contract-invalid outcome. A separate declaration correction avoids decoding a missing HTTP response body. |
| M4 | The plan producer and its three scenarios are installed. Its context still needs complete integration with the consuming projection pipeline. |
| M5 | Python/C# plan construction and materialization are installed and verified through the real CLI. The files contain the execution plan, binding, fixture authority, source map and candidate evidence. Candidate evidence does not claim conveyor acceptance. |
| M6 | Declared execution and consumer contract admission are installed and verified through the real CLI. The consuming pipeline's eight-part fixture obligations and complete normalized execution-slot bindings remain to be completed. |
| M7 | Node planning, execution, writing and direct CLI invocation use the consumer plan. All 17 original regression fixture outcomes passed in-flight. Real CLI execution and observation resolve live equity evidence on all three targets; Node materialization reproduces the tested new digests. Retirement of the old generated bodies and estate/memory verification remain in progress. |

Installed migrations, in order:

1. [select-embodiment-provider-profiles.sql](../../../sql/migrations/select-embodiment-provider-profiles.sql)
2. [resolve-provider-slot-bindings.sql](../../../sql/migrations/resolve-provider-slot-bindings.sql)
3. [declare-embodiment-target-selection.sql](../../../sql/migrations/declare-embodiment-target-selection.sql)
4. [link-declared-target-provider-implementations.sql](../../../sql/migrations/link-declared-target-provider-implementations.sql)
5. [declare-equity-provider-slot-requirements.sql](../../../sql/migrations/declare-equity-provider-slot-requirements.sql)
6. [declare-consumer-execution-embodiment-plan.sql](../../../sql/migrations/declare-consumer-execution-embodiment-plan.sql)
7. [guard-equity-response-decoding.sql](../../../sql/migrations/guard-equity-response-decoding.sql)
8. [bind-native-consumer-effect-providers.sql](../../../sql/migrations/bind-native-consumer-effect-providers.sql)
9. [bind-consumer-embodiment-planning.sql](../../../sql/migrations/bind-consumer-embodiment-planning.sql)
10. [execute-declared-capability.sql](../../../sql/migrations/execute-declared-capability.sql)
11. [bind-consumer-contract-admission.sql](../../../sql/migrations/bind-consumer-contract-admission.sql)
12. [declare-regression-provider-slot-requirements.sql](../../../sql/migrations/declare-regression-provider-slot-requirements.sql)
13. [restore-regression-expression-order.sql](../../../sql/migrations/restore-regression-expression-order.sql)
14. [include-declared-schema-references.sql](../../../sql/migrations/include-declared-schema-references.sql)
15. [include-relative-schema-references.sql](../../../sql/migrations/include-relative-schema-references.sql)
16. [restore-provider-fixture-input-order.sql](../../../sql/migrations/restore-provider-fixture-input-order.sql)
17. [converge-node-consumer-plan.sql](../../../sql/migrations/converge-node-consumer-plan.sql)
18. [bind-declared-execution-delivery.sql](../../../sql/migrations/bind-declared-execution-delivery.sql)

Each was dry-run and invoked against its uncommitted state before installation.
Installed scripts end in `COMMIT TRANSACTION`. The working base now includes
commit `967ca09` (`M5 complete. We crushin it baby`). The subsequent work remains
uncommitted.

The Node convergence preflight exposed declaration regressions against the working
generation: expression member order, an incorrect blueprint schema, missing
referenced schemas, and member order in four provider-resolution fixture inputs.
Those corrections were each tested inside their uncommitted transaction before
installation. The four provider fixtures now execute their declared inputs with
their original expected digests; their values and expectations were preserved.
The Node convergence preflight also caught a provider input-selection defect:
the provider used an enclosing input when the scheduler supplied the resumed
transformation Port's input. The corrected provider declaration passed the full
preflight before installation. No kernel source was changed. Evidence is retained
in `m7.*.preflight.txt` and `m7.*.installed.json`.

Direct CLI invocation reads the execution capability, request/result mappings and
default target from declarations. Its in-flight cases exercise the actual CLI
delivery function, including explicit namespace selection, input rejection and
native provider observations. Real `observe` invocations for Node, Python and C#
returned the resolved outcome and streamed telemetry with filesystem writes
disabled. See `m7.direct-*.installed.json` and `m7.direct-*.observe.txt`.

The C# provider dependencies are retained by digest in database rows. Run
`node scripts/materialize-consumer-provider-dependencies.mjs` to restore and
verify the selected compiled dependencies under `providers/consumer-execution/`.
That directory is ignored. The platform's locked npm dependencies are also
required by its existing schema-admission provider.

Evidence includes `m5.*.installed.json` for materialization,
`m6.admission-*.installed.json` for real invocation,
`native-*.admission.probe.json` for native input/outcome rejection, and
`native-node.probe.json` for the Node consumer-plan probe, all under
`evidence/python-csharp-embodiment/`.

Still required: finish the canonical feature obligations and normalized bindings;
connect the produced context to `project-consumer-execution-embodiment-v2`;
execute its eight-part fixture authority; converge Node; preserve the 17 fixture
outcomes and establish the new digests; and finish estate, memory and replay
verification. These are implementation work, not kernel blockers.
