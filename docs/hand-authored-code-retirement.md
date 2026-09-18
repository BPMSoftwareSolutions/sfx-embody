# Hand-authored code retirement — ledger and agent sequence

**Status.** Recorded 2026-09-17 from a full read-only inventory of the estate's
authored code (28 files, 4,690 LOC: 14 under `src/`, 13 `.mjs` + 1 `.sql` under
`scripts/`, no `bin/`). Rule: declared authority (1) or an admitted resolver (0);
the code cannot remain in its found location. Estate `docs/transistor-model.md:44-49`:
*"There is no grey area. Either it's resolver(0) code living in the SDA Kernel or
it's declared(1) in the database, period."*

**Builder clarification, recorded verbatim:**
- **Boot is resolver (0).**
- These are resolver (0), per `target-architecture.md` Disposition (the two "code" rows): **frontdoor/loader, DB query runner, bootstrap installer (the irreducible three)** and **delivery/workspace config (`read-workspace-config`) (boot config)**.

A file the target architecture eliminates is **delete (eliminated by
target-architecture Disposition)**; deletion is the action, not a home. This
ledger drives the migration agents.

## Classification

| Class | Files | Home | Disposition |
|---|---|---|---|
| **boot (resolver (0)): frontdoor/loader, DB query runner, bootstrap installer (the irreducible three), delivery/workspace config (`read-workspace-config`) (boot config)** (12) | `restrict-memory-process` (sandbox), `database-connect-boundary`, `database-read-session`, `database-delivery` (frontdoor), `read-authority` (loader read; SQL residue), `invoke-database-capability` (loader; reduce via unit), `read-workspace-config` (resolver (0) boot-config instance retired with zero consumers; W1.2), `credential-vault-realization` (split candidate), `scripts/run-migration`, `scripts/invoke-from-transaction`, `scripts/extract-inflight-bundle`, `scripts/run-query` (redundant) | **resolver (0)** | The mechanics remain resolver (0); portable meaning the boot still carries moves to declared (1); the named reductions delete the residue |
| **thin boot carriers** (2) | `read-execution-delivery`, `projection-delivery` | **resolver (0)** | Fold into the single declared boot read, then delete the carrier |
| **UID meaning** (5) | `execution-drilldown`, `semantic-address`, `observation-filter` ✅, `scripts/read-scenario-round-trip-authority` (NEW unit), `scripts/queries/list-projected-bodies.sql` | **declared (1)** | Declare as rows, then delete the file; deletion is the action |
| **verification as readings/receipts** (6) | `src/timing-coherence` + `scripts/verify-timing-coherence`, `verify-projected-testimony`, `verify-demo` (NEW), `verify-credential-non-disclosure` (NEW), `projected-performance` | **declared (1)** | Declare the reading/receipt as data, then delete the script; deletion is the action |
| **one-time units** (3) | `build-scaffold-hello-world` (delete now), `transition-credential-authorities-to-vault` (delete now), `publish-projected-bodies` (retire on SDA request 9) | **no-home defect (K029)** | Delete when its unit is receipted; deletion is the only resolution |

Homes are only declared (1) and resolver (0). Delete is a disposition, never a
home. A file with neither home is a no-home defect under K029.

## Agent sequence

```
P0  delete build-scaffold-hello-world, transition-credential-authorities-to-vault   (parallel, now)
P1.1 U3 reader documents (reveal/list/find/catalogue/circuit/artifact)              (parallel)
P1.2 NEW scenario-authority read; delete read-scenario-round-trip-authority,
     then retire the read-workspace-config instance (resolver (0), boot config)
P2.1 IEA: declared read-invocation-timing + receipt is the acceptance;
     retire timing-coherence + verify-timing-coherence (independent-oracle decision)
P2.2 NEW non-disclosure receipt; retire verify-credential-non-disclosure
P2.3 NEW demo-acceptance receipt; retire verify-demo (after W1.4 verbatim pass)
P2.4 projected-testimony reading after SDA requests 7/8; retire verify-projected-testimony;
     then projected-performance -> declared reading (W2 trigger)
P2.5 projected-bodies read after SDA request 9; retire publish-projected-bodies,
     list-projected-bodies.sql, and run-query when unused
P3.1 telemetry + observation transformations from declared rows (depends P1.1)
P3.2 delete execution-drilldown, semantic-address; fold the scalar picker
P3.3 shrink invoke-database-capability to the loader seams
P3.4 fold read-execution-delivery and the read-authority SQL constants
P4  per-language bootstraps / sealed binary (deferred: admission, distribution)
```

**Kernel dependency:** `execution-drilldown` and `semantic-address` need kernel
testimony to carry the per-event `semanticAddress`/entry (SDA: testimony schema
opening bundled with F1/F2; display record D3). A declared SQL read per streamed
event would add ~716 round trips and break the stream clock, so it was refused.

**Landed so far:** `observation-filter.mjs` deleted with its allowlist declared
(`read-observation-telemetry-authority`, estate `9c3254c`); circuit attestation
names unobserved leaves through the declared parent chain (`70f60f2`); the driver
retired (`6962040`); W1.1 reader documents declared
(`declare-reader-display-documents.sql`: reveal/list/find/catalogue/circuit/
artifact), the boot reader branch and the CLI `meaningLines`/`capabilityLine`/
`format` dispatch deleted, live reveal and `--format markdown` byte-equal.

**Builder decisions outstanding** (from the inventory): the
`invoke-database-capability` resolver-vs-declared reading; `read-authority` SQL
constants; the `credential-vault-realization` split; the `read-workspace-config`
boot-config instance (resolver (0); retired with zero consumers in W1.2); the
timing oracle question; the `run-query` backdoor; and the homing of
each verification harness as a declared (1) reading/receipt or an admitted
resolver (0) harness (a harness file with neither home is a no-home defect under
K029).
