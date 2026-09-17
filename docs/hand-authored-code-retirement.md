# Hand-authored code retirement — ledger and agent sequence

**Status.** Recorded 2026-09-17 from a full read-only inventory of the estate's
authored code (28 files, 4,690 LOC: 14 under `src/`, 13 `.mjs` + 1 `.sql` under
`scripts/`, no `bin/`). Rule: declared authority (1) or an admitted resolver (0);
the code cannot remain in its found location. The **host floor** is the honest
exception: the loader/runner/session/sandbox/transport that executes declarations
cannot itself be declared. This ledger drives the migration agents.

## Classification

| Class | Files | Disposition |
|---|---|---|
| **HOST_FLOOR** (12) | `restrict-memory-process` (sandbox), `database-connect-boundary`, `database-read-session`, `database-delivery` (frontdoor), `read-authority` (loader read; SQL residue), `invoke-database-capability` (loader; reduce via unit), `read-workspace-config` (orphan decision), `credential-vault-realization` (split candidate), `scripts/run-migration`, `scripts/invoke-from-transaction`, `scripts/extract-inflight-bundle`, `scripts/run-query` (redundant) | Stays; only the named reductions |
| **THIN_CARRIER** (2) | `read-execution-delivery`, `projection-delivery` | Keep minimized; fold into the declared boot read where allowed |
| **UID_MEANING** (5) | `execution-drilldown`, `semantic-address`, `observation-filter` ✅, `scripts/read-scenario-round-trip-authority` (NEW unit), `scripts/queries/list-projected-bodies.sql` | Declare, then delete |
| **VERIFICATION** (6) | `src/timing-coherence` + `scripts/verify-timing-coherence`, `verify-projected-testimony`, `verify-demo` (NEW), `verify-credential-non-disclosure` (NEW), `projected-performance` | Become declared readings/receipts, then retire the script |
| **ONE_TIME** (3) | `build-scaffold-hello-world` (delete now), `transition-credential-authorities-to-vault` (delete now), `publish-projected-bodies` (retire on SDA request 9) | Delete when its unit is receipted |

## Agent sequence

```
P0  delete build-scaffold-hello-world, transition-credential-authorities-to-vault   (parallel, now)
P1.1 U3 reader documents (reveal/list/find/catalogue/circuit/artifact)              (parallel)
P1.2 NEW scenario-authority read; delete read-scenario-round-trip-authority,
     then decide the read-workspace-config orphan
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

**Blocked now:** `execution-drilldown` and `semantic-address` need kernel
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
`invoke-database-capability` floor-vs-UID reading; `read-authority` SQL constants;
the `credential-vault-realization` split; the `read-workspace-config` orphan; the
timing oracle question; the `run-query` backdoor; and whether verification
harnesses are admitted test floor or declared readings.
