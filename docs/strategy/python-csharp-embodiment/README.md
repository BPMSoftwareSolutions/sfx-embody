# Feature writeups — Python/C# embodiment

Canonical `.feature` writeups for every capability the
[Python/C# embodiment strategy](../python-csharp-embodiment.md) creates or changes.
Format follows the estate convention (see `agentic-harness/features`).

| Feature | Status | Strategy step | Why it changes |
| --- | --- | --- | --- |
| `resolve-provider-slot-bindings.feature` | NEW | M2 | The declared drive is absent: `provider_binding_scope`/`provider_binding` are empty and `src/` hardcodes the selection. This capability resolves one provider per slot from rows. |
| `read-capability-authority.feature` | UPDATE | M1, M3 | Make the authority read target-neutral; return the requested profile's requirements and hold `PROFILE_PROVIDER_ABSENT` instead of assuming Node. |
| `plan-capability-embodiment.feature` | UPDATE | M1, M2 | Plan against the resolved provider bindings for the selected profile; no target-specific path. |
| `construct-embodiment-plan.feature` | UPDATE | M1 | Compose read → bindings → plan for any target. |
| `write-capability-embodiment.feature` | UPDATE | M4 | Target-neutral governed write; establish and verify the digests the plan produced. |
| `materialize-capability-embodiment.feature` | UPDATE | M4, M5, M6 | Materialize for any declared target; a plan-form body changes the digests by construction. |
| `project-consumer-execution-embodiment-plan.feature` | NEW | §4 | The producer of `consumer-execution-embodiment-projection-context` is absent from the model; this supplies it. |
| `project-consumer-execution-embodiment-v2.feature` | UPDATE | §4 | The admitted projection context is now a produced input, not an assumed one; contracts confirmed. |

## Notes for review

- **Statuses.** NEW means the capability does not exist in the selected model;
  UPDATE means the capability exists and its declared meaning must change.
- **Contracts are proposals.** Contract ids follow the estate convention but are
  not yet declared rows. They become real when the migration is authored.
- **Provider coverage.** Whether a target has an admitted provider for a required
  mechanic is measured per target in the strategy (§3, §5 M3); an unbound or
  absent requirement is a held finding, not a fallback.
- **No meaning lives here.** These writeups describe behavior to be declared in
  the database. Nothing in this folder is executed.
