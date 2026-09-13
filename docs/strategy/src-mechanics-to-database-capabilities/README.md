# Feature writeups — `src/` mechanics to database capabilities

Canonical `.feature` writeups for every capability the
[`src/` → database strategy](../src-mechanics-to-database-capabilities.md) creates
or changes. Format follows the estate convention (see `agentic-harness/features`).

| Feature | Status | Strategy phase | Why it changes |
| --- | --- | --- | --- |
| `read-estate-query.feature` | NEW | Phase 1 | The database read has no declared operation. `declared-query-evaluation` evaluates an admitted JSON document, not SQL; this capability owns the SQL read. |
| `deliver-governed-capability-invocation.feature` | NEW | Phase 2 | The two deliveries differ only by a policy literal; this declares the carrier and the policy. |
| `project-capability-revelation.feature` | UPDATE | Phase 4 | Narration becomes declared projections and formats, not separate hand-authored formatters. |
| `project-capability-circuit.feature` | NEW | Phase 4 | The two circuit diagram builders become one projection of the declared graph. |
| `resolve-capability-proof-obligations.feature` | UPDATE | Phase 5 | The native-mutation and validator/compiler checks must resolve to declared obligations before the code checks retire. |
| `execute-declared-capability.feature` | NEW | Phase 6 | The declaration is the body; execute the declared operations with bound providers and retire the generate-and-run triple. |

## Notes for review

- **Statuses.** NEW means the capability does not exist in the selected model;
  UPDATE means the capability exists and its declared meaning must change.
- **Contracts are proposals.** Contract ids follow the estate convention but are
  not yet declared rows. They become real when the migration is authored.
- **Phase 3 (provider bindings) has no feature here.** It authors binding rows for
  existing capabilities, not a new capability. Its capability writeup is
  `resolve-provider-slot-bindings.feature` in the
  [cross-target strategy](../python-csharp-embodiment/resolve-provider-slot-bindings.feature).
- **No meaning lives here.** These writeups describe behavior to be declared in
  the database. Nothing in this folder is executed.
