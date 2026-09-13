# Python/C# embodiment implementation status

2026-09-13. Profile selection and the binding resolver are installed. The full
Python/C# embodiment strategy is not complete.

| Step | Installed or observed |
| --- | --- |
| M0 | Saved the working Node plan outcome and readable authority bundles, plus the Python/C# failure outcomes, under `evidence/python-csharp-embodiment/baseline/`. |
| M1 | Reads six provider profiles from normalized declarations. The default target is a port configuration row. Node's complete plan outcome matches M0, including both digests. |
| M2 | Installed 165 binding scopes, 41 bindings and 38 port implementation links. Installed the resolver root and the read → resolve → plan composition with matching contracts. The declared planner admission returns a held outcome when resolution reports findings. |
| M2 remaining | The complete feature drafts and their additional scenarios are not admitted by this installation. Node body construction still uses the existing materializer; the binding set supplies its admission and authority input. Per-operation provider-driven body construction remains unfinished. |
| M3 | Audited the existing slot requirements and the equity capability's actual invoked ports. No new Python/C# effect or admission implementation was asserted. |
| M4–M7 | The context producer, rendering, native execution and Node convergence are not installed. |

The installed migrations, in order, are
[select-embodiment-provider-profiles.sql](../../../sql/migrations/select-embodiment-provider-profiles.sql),
[resolve-provider-slot-bindings.sql](../../../sql/migrations/resolve-provider-slot-bindings.sql),
and [declare-embodiment-target-selection.sql](../../../sql/migrations/declare-embodiment-target-selection.sql).
Each passed a rollback dry run and an uncommitted composition invocation before
installation. The files now end in `COMMIT TRANSACTION` because they are installed.
The binding migration refuses a second installation; the selection migrations
reuse their existing definitions. No Git commit was made.

The authority reader also depends on the reader change in
`C:/lab/sidefx-database/sql/diagnostics/capability-embodiment.sql`, which carries the
profile view as the fourth result set. The query provider reads the SQL statement
stored in its port configuration. The statement, contracts, admission schema and
held outcome are authored in the migration. The transaction preflight supplies
the same connection to nested authority and query reads.

The existing 55 slots produce the following results. The 14 slots in the second
column have profile requirements after this migration but still have no normalized
port or mechanic requirement.

| Target | No port/mechanic requirement | No matching port implementation | Bound |
| --- | ---: | ---: | ---: |
| Node | 14 | 0 | 41 |
| Python | 14 | 41 | 0 |
| C# | 14 | 41 | 0 |

An empty binding set does not establish operational coverage. In particular,
`resolve-equity-market-price-evidence` has **zero declared slots** and five invoked
ports. Its current normalized platform implementation links resolve for Node and
do not resolve for Python or C#. This is reproducible with
[python-csharp-embodiment-requirements.sql](../../../sql/inspect/python-csharp-embodiment-requirements.sql).
The captured result is
`evidence/python-csharp-embodiment/equity-provider-requirements.json`. Missing links
are not, by themselves, proof that a native body does not exist.

The physical provider finding is separate. The equity root invokes credential
binding and governed HTTP exchange. The selected declarations name
`external-credential-reference-binding-provider.mjs` and
`governed-http-exchange-provider.mjs` under the Node runtime. Inspection of the
current consumer hosts found that:

- Python's `languages/python/src/scenario_kernel/platform/consumer.py:121–208`
  assigns one handler to every profile. That handler reads fixture outcomes,
  evaluates expressions, or returns the input; it does not load an implementation
  from a binding reference.
- C#'s `languages/csharp/src/ScenarioKernel.Adapters/Consumer/AdmittedConsumerPlatform.cs:240–272`
  likewise assigns the same handler to every profile and returns the input when
  no fixture outcome or expression handles the operation.

These paths are relative to the pinned platform repository at
`C:/lab/repos/scenario-driven-architecture`. Both files were verified unchanged
from the bundle's platform commit, `716811046f52dd2a67f9ff308a50d755571cbbad`;
the check is saved in `evidence/python-csharp-embodiment/provider-source-check.json`.
They establish a consumer-provider
implementation requirement, not a need to change every language kernel. Merely
inserting bindings cannot make those existing handlers call the missing effects.
Following [AGENTS.md](../../../AGENTS.md), this is recorded as a finding; no
provider behavior, fixture success, or kernel change was invented to make the
equity invocation pass.

Verification completed:

- 23 unit tests passed, including the declared default target, missing profiles,
  transaction query transport, incomplete results and held planning.
- Uncommitted and real CLI Node construction preserve the full M0 plan outcome.
  `planDigest` remains `sha256:d21dbcbb414ad5aa799412e3f897e8109e0b9a3048e9d469dccbcc3fb9fc35f5`;
  `artifactDigest` remains `sha256:b785cb9a8e58516982e5970ee992d759b6526d65a389b23050731c0f2b9d3c2a`.
- Uncommitted and real CLI construction for `read-authorized-file` on Python and
  C# returns `EMBODIMENT_PLAN_HELD` with `PROVIDER_IMPLEMENTATION_ABSENT` for its
  declared slot. These checks exercise resolution and admission, not Python/C#
  execution.
- Real CLI equity construction for Python and C# still fails with
  `SELECTED_NATIVE_MECHANIC_BODY_NOT_RECOGNIZED`.
- `npm run verify:memory` fails with
  `SCENARIO_SOURCE_RESOLUTION:adapt-job-market-intelligence-evidence`. The same
  failure was reproduced using the unchanged materializer. The claimed 17-fixture
  parity has therefore not been re-established.

The preflight cases are in
[embodiment-binding.preflight.json](../../../config/embodiment-binding.preflight.json).
The command outputs and comparisons are retained under
`evidence/python-csharp-embodiment/`.
