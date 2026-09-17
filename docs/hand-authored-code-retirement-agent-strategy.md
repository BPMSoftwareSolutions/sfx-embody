# Hand-authored code retirement — multi-agent execution strategy

**Status.** READY. Wave 0 is executable immediately. The ledger
(`hand-authored-code-retirement.md`) owns the 28-file classification; this
document owns the agent wave, gates and receipts.

**Frame.** Declared authority (1) or an admitted resolver (0); the code cannot
remain in its found location. The 12-file **host floor** is the honest exception
and is not a deletion target.

## Invariants

- A file is deleted only when: its declared replacement is live, a parity or
  acceptance receipt is recorded, a repo-wide search shows no importer, and the
  suite is green on the combined tree.
- Kernel gaps become SDA requests (or wait on filed ones: F1/F2 requests 7/8,
  request 9, and the testimony-schema opening D3). Never a per-event SQL read,
  never a boot workaround.
- One migration per declaration; ROLLBACK by default until the in-transaction
  preflight passes, then COMMIT (standing authority). Receipts under
  `evidence/vault-20260916/retirement/<unit>/`.
- Another writer may be active: check `git status --short` first, touch only your
  unit's files, never restore anything from a byte copy.

## Workstreams

| id | class | target (delete) | declared replacement | depends | acceptance / verify |
|---|---|---|---|---|---|
| W0.1 | ONE_TIME | `scripts/build-scaffold-hello-world.mjs` | hello-world-sql capability + U1 record | — | no importer (`rg`); `npm test` |
| W0.2 | ONE_TIME | `scripts/transition-credential-authorities-to-vault.mjs` | installed vault V3 (`b660b1a`, `67fd91a`, `48ba173`) | — | receipts retained; `npm test` |
| W1.1 | U3 | reader/CLI dispatch (`invoke-database-capability` reader branch + `meaningLines`/`capabilityLine`/`format` in the CLI) | declared reader documents for reveal/list/find/catalogue/circuit/artifact | — | `tests/database-command.test.mjs`, reader cases in `tests/invocation-read.test.mjs`, `verify-demo` list/find/reveal cases, live `reveal` + `--format markdown` |
| W1.2 | UID_NEW | `scripts/read-scenario-round-trip-authority.mjs`; then decide `src/read-workspace-config.mjs` (orphan) | declared scenario-authority read (fold into the meaning reader if it covers it) | — | bundle equivalence with `evidence/review/scenario-round-trip-authority.json`; `npm test` |
| W1.3 | VERIFICATION_NEW | `scripts/verify-credential-non-disclosure.mjs` | declared non-disclosure receipt (`read-credential-non-disclosure`) | V3 done | transition idempotency + store/resolve invokes + tampered-store negative; `tests/credential-vault-realization.test.mjs` |
| W1.4 | VERIFICATION_NEW + W1.4 | `scripts/verify-demo.mjs` | declared demo-acceptance receipt (`read-demo-acceptance`) | verbatim command pass first | `demo-commands.md` verbatim three beats; receipts + `report.json` before deletion |
| W2.1 | VERIFICATION | `src/timing-coherence.mjs` | declared `read-invocation-timing` + its receipt is the acceptance | — | 715/179/181/460 windows unchanged; keep `scripts/verify-timing-coherence.mjs` as the independent oracle (default decision 5) |
| W3.1 | VERIFICATION (gated) | `scripts/verify-projected-testimony.mjs`, then `scripts/projected-performance.mjs` | projected-testimony conformance read, then a performance read | SDA requests 7/8 land | `--expect-closed` receipt; cross-target parity; W2 trigger for performance |
| W3.2 | UID + ONE_TIME (gated) | `scripts/publish-projected-bodies.mjs`, `scripts/queries/list-projected-bodies.sql`, then `scripts/run-query.mjs` when unused | `read-projected-bodies` behind the frontdoor | SDA request 9 | dry-run generation + hot-path isolation counts before deletion |
| W4.1 | UID (gated) | `src/execution-drilldown.mjs`, `src/semantic-address.mjs` | telemetry authority + observation transformations; per-event `semanticAddress` from the plan, not id parsing | SDA testimony-schema opening (D3, bundled F1/F2) + W1.1 | rewritten `tests/execution-drilldown.test.mjs`/`semantic-address.test.mjs`; equity `observe --trace/--display`; IEA re-run; circuit first-turn |
| W4.2 | floor reduction | operation table, `buildCanonicalInput`/`setInputPath`/`INPUT_TYPES`, `readCliConfiguration` inside `invoke-database-capability` | declared mappings/transformation/read | W4.1 | loader protocol untouched; `tests/database-command.test.mjs` |
| W4.3 | THIN_CARRIER | `read-execution-delivery` + the `read-authority` SQL constants | the single declared boot read | W4.2 | truncation gate + snapshot/projection coherence preserved |
| W5 | floor (deferred) | per-language bootstraps; sealed binary | SDA/bootstrap program | admission/distribution triggers | `transistor-model.md` §6/§9 |

## Wave plan

- **Wave 0 (parallel)**: W0.1, W0.2.
- **Wave 1 (parallel)**: W1.1, W1.2, W1.3, W1.4 — disjoint files; W1.1 owns
  `invoke-database-capability.mjs` for the wave.
- **Wave 2**: W2.1 after Wave 1; W4 prep (declared observation transformations)
  after W1.1 but landing only with the SDA gate.
- **Wave 3 (SDA-gated)**: W3.1, W3.2, then W4.1–W4.3.
- **Wave 4 (deferred)**: W5.

## Agent briefs (paste-ready)

**W0.x / deletions**: verify no importer (`rg <module>` outside the file and its
tests), confirm the replacement's receipt path exists, delete, run `npm test`,
commit with the receipt cited. No migration.

**W1.x / declarations**: read the display record and the reader precedent
(`declare-read-declared-capability-document.sql`, `read-declared-capability-document`);
declare the read, preflight in-transaction, COMMIT on green; capture before/after
parity; delete the code branch/file; rewrite the covering tests. The frontdoor
renders declared output only — no semantic computation in boot.

**W2.x / acceptance**: the declared reading's output must reproduce the
recorded acceptance numbers exactly; the independent oracle stays as test floor;
delete only the in-`src` computation.

**W3.x–W4.x / gated**: do not start until the named SDA artifact lands and is
verified; if the gate is open but the replacement still needs a kernel field,
report the exact field instead of simulating it.

## File-conflict map

| Surface | Owner | Notes |
|---|---|---|
| `sql/migrations/**` | one unit at a time per capability id | serialize per declaration target |
| `src/invoke-database-capability.mjs` | W1.1, then W4.2 | serialize |
| `src/database-delivery.mjs` | W1.3 | W3.x later |
| `scripts/**` | the owning unit | deletions only by owner |
| `docs/hand-authored-code-retirement.md` | each unit appends its row after landing | no restructures |

## Builder decisions (defaults keep work moving)

1. `invoke-database-capability` floor vs UID → **A: stays, reduced** (default).
2. `read-authority` SQL constants → **A: keep as the loader's declared-read carrier**.
3. `credential-vault-realization` → **keep whole** until a second OS realization.
4. `read-workspace-config` orphan → decide inside W1.2 (delete if unused).
5. Timing oracle → declared reading is acceptance; **keep the verify script as
   admitted independent test floor**.
6. `run-query` backdoor → retire after W3.2.
7. Verification harnesses → admitted test floor; their **meaning** becomes
   declared receipts.

## Definition of done

- Every UID_MEANING and VERIFICATION file is deleted with a live declared
  replacement and a parity receipt; every ONE_TIME file is deleted with receipts
  retained.
- Only HOST_FLOOR + THIN_CARRIER remain; the ledger table carries the retirement
  status of all 28 files.
- Suite green at every wave; live surfaces (agent lane, equity, say-hello-world,
  observe/display/trace, circuit, timing) remain facts-equal.

## Progress log

- `9c3254c` — `observation-filter.mjs` deleted; allowlist declared
  (`read-observation-telemetry-authority`), filter parity 17/17 byte-equal.
- `70f60f2` — circuit attestation names unobserved leaves via the declared parent
  chain (gap closed).
- `6962040` — driver retired.
- Remaining: Waves 0–4 above; gates: SDA F1/F2, request 9, testimony schema (D3).
