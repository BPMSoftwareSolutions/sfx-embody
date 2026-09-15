# The flywheel proof

**Status.** Authored and executed 2026-09-15 in one operator session. The
capability, its examples and this record landed in the estate commits of the same
day.

**Scope.** `target-experience.md` §"Where database pressure is actually
valuable: the authoring flywheel" and §"The flywheel proof";
`architecture-priorities.md` §3 Now item 3; the rubric's three observations
(`sidefx-architecture-decision-rubric.md` §1) and its benefit/burden and
break-even measures (§5). One question: **was capability B materially easier
because capability A was built?**

## Verdict (short)

**Yes, for the declared-read JSON authoring shape — and the cause is named.**
B reused A's authoring surface, declared-read port, single invocation path, a
sibling's input contract, and the document ledger A's declaration created. B
was authored from T0 to a behaviorally verified CLI invocation in **95 seconds
with zero failed attempts**, and its read returns A's authored document bytes
verbatim (SHA-256 match, §6.5). The comparison base — A's authoring effort — is
**estimated from git history, not observed** (A has no timestamped authoring
log; §7). What is **not** proven: that the flywheel extends to a different
authoring shape (pure-mechanics or provider-backed capability), and that the
install lifecycle got cheaper — it did not; B paid the same migration ceremony
A's surface established.

---

## 1. What B is, and why it is a valid comparable example

**B: `read-declared-capability-document`.** Input: one capability identity
(reused sibling contract `read-capability-meaning-request.v1`). Outcome: the
exact `sidefx-capability-authority.v1` document the current model installed for
that id, with its content address, or `documentInstalled: false` when no
document is installed for the id. It is one declared read over the model — no
provider, no network, no clock, no filesystem.

Why it is useful and not a clone of A:

- A (`count-declared-capabilities`) answers "how many capabilities does the
  model declare?" — no input, one integer. B answers "what document did the
  model install for *this named* capability, byte-for-byte?" — an input-selected
  document read. The semantic question, the input, and the result shape are new.
- It closes the round trip of the JSON authoring surface that
  `docs/json-authoring-surface.md` names as missing: `declare_capability_document`
  writes the document ledger; B reads it back. It is a bridge to the deferred
  inverted projection, not a replacement for it.
- It is the authoring loop's own recurring question: after installing a
  document, "what exactly is installed, and has it drifted from my source
  file?" B's output is diffable against `examples/json-authoring/*.authority.json`
  (and §6.5 shows the check).
- It consumes the `CAPABILITY_DOCUMENT` ledger rows the JSON surface writes for
  every document — including A's. B's own receipt for A is the flywheel visible
  in data: the second capability returns the first capability's authored bytes.

Why it is a comparable example to A: same authoring medium (one JSON
`sidefx-capability-authority.v1` document installed by
`model.declare_capability_document`), same declared-read mechanic
(`sda-embodiment-plan-port.v1` + `configuration.statement`/`resultColumn`, no
`providerId`), same single invocation path (`run-declared-graph`, unchanged
CLI), same migration lifecycle. It differs deliberately where the example earns
new value (input consumption, document result).

Artifacts:

| Artifact | Path |
|---|---|
| Authority document | `examples/json-authoring/read-declared-capability-document.authority.json` (50 lines) |
| Installed-state input | `examples/json-authoring/read-declared-capability-document.request.json` |
| Absence-case input | `examples/json-authoring/read-declared-capability-document.no-document.request.json` |
| One migration (installs B) | `sql/migrations/declare-read-declared-capability-document.sql` (170 lines) |

A was not modified. No existing capability was modified. Nothing under `src/`
was changed for this record (see §9 for the pre-existing working-tree state).

---

## 2. Observation 1 — time to first executable result, and to first verified outcome

All times local (UTC-4); UTC in parentheses where the receipts carry it.

| Milestone | Wall clock | Elapsed from T0 | Command |
|---|---|---|---|
| **T0** start authoring B (writing the JSON document) | 2026-09-15 18:03:25 (22:03:25Z) | — | — |
| Dry-run (rollback) passed | between T0 and T1 | — | `node scripts/run-migration.mjs sql/migrations/declare-read-declared-capability-document.sql` |
| **T1** first executable result: preflight from the uncommitted migration, `DISPOSITION completed` | 18:04:34 (22:04:34Z) | **1 m 09 s** | `node --experimental-vm-modules scripts/invoke-from-transaction.mjs sql/migrations/declare-read-declared-capability-document.sql read-declared-capability-document examples/json-authoring/read-declared-capability-document.request.json` |
| Install (`COMMIT`) | 18:04:52 (22:04:52Z) | 1 m 27 s | `node scripts/run-migration.mjs sql/migrations/declare-read-declared-capability-document.sql` |
| **T2** behaviorally verified invocation through the unchanged CLI | 18:05:00 (22:05:00Z) | **1 m 35 s** | `cmd /c "sfx capability invoke read-declared-capability-document --input @examples/json-authoring/read-declared-capability-document.request.json --json"` |
| Observation through `sfx capability observe` | 18:05:14 (22:05:14Z) | 1 m 49 s | `cmd /c "sfx capability observe read-declared-capability-document --input @examples/json-authoring/read-declared-capability-document.request.json"` |

Review overhead: none occurred. No independent review of B took place in this
session, so review time is **unobserved**, not zero.

Provider-backed execution: not required and not attempted. This is deliberate:
the declared RapidAPI credential is rate-limited to zero (finding F6), so B is a
declared read by construction. This record establishes the declared-read
authoring shape; it makes no provider-conformance claim.

---

## 3. Observation 2 — successful authorized executions out of attempts

| Attempt class | Attempts | Successes | Principal failure reason |
|---|---|---|---|
| Migration dry-run (rollback) | 1 | 1 | — |
| Preflight from uncommitted transaction | 1 | 1 | — |
| Install (`COMMIT`) | 1 | 1 | — |
| Post-install replay (idempotency) | 1 | 1 | — |
| `sfx capability invoke` (installed case, then absence case) | 2 | 2 | — |
| `sfx capability observe` | 1 | 1 | — |
| **Total against B** | **7** | **7** | **no failures** |

Distinct users: **1** (one operator/agent session; the estate carries no
multi-user evidence).

Two exploratory invocations of **A** failed before T0 and are recorded because
the rubric asks for principal failure reasons, not because they are B defects:

1. `cmd /c "sfx capability invoke count-declared-capabilities --json"` →
   `CAPABILITY_INPUT_REQUIRED`. A's declared CLI requires input.
2. `cmd /c "sfx capability invoke count-declared-capabilities --input '@…json' --json"`
   → `CAPABILITY_INPUT_JSON_REJECTED`. Through `cmd`, the single quotes are
   passed literally, so the `@file` carrier is not recognized. Dropping the
   quotes worked. See friction finding FF1.

---

## 4. Observation 3 — effort to deliver the next comparable example

Authoring effort for B, as observed: one 50-line JSON document, one request
example (3 lines), one absence input (3 lines), one 170-line migration (of which
~120 lines are the verification result sets copied from A's migration shape),
and the lifecycle commands above. All of it fit between 18:03:25 and 18:05:00.

### 4.1 Reuse inventory — used without modification

| Reused artifact / mechanic | How B uses it | Proof it was not modified |
|---|---|---|
| `model.declare_capability_document` (JSON surface procedure) | B is installed by passing B's document to it | Migration result sets `DECLARE_CAPABILITY_DOCUMENT: INSTALLED` then `UNCHANGED`; the procedure is the one created by `declare-json-authoring-surface.sql`, untouched |
| `sda-embodiment-plan-port.v1` (platform declared-read port) | B's only port binds `configuration.statement` + `resultColumn` and names no `providerId` | Migration result set `2_declared_read_port`: `platform_capability_id = sda-embodiment-plan-port.v1`, `names_provider_module = 0` |
| `sda-declared-read-graph-provider.v1` (declared-read mechanic) | executes the statement under the reader boundary | Cell testimony: `providerProfileId: sda-declared-read-graph-provider.v1`; preflight and invoke receipts |
| `run-declared-graph` invocation path (compile → execute) | both preflight and CLI invoke run through it | `DISPOSITION completed` receipts; `evidence.timings.executeDeclaredGraph` present |
| `read-capability-meaning-request.v1` (sibling's request contract) | B's scenario input declares this contract unchanged; no new request contract was authored | Migration result set `3_reused_input_contract`: `input_contract_id = read-capability-meaning-request.v1`; `observe` GIVEN line prints `read-declared-capability-document-request (read-capability-meaning-request.v1)` |
| `CAPABILITY_DOCUMENT` ledger rows written by the JSON surface | B resolves the digest, then the content object, from the ledger the surface writes | B's receipt for A: `documentDigest = sha256:6dace374…`, which is the ledger digest recorded for A by the surface |
| `scripts/run-migration.mjs` and `scripts/invoke-from-transaction.mjs` | dry-run, install, preflight | exact commands in §2; scripts unchanged |
| CLI `invoke`, `observe`, `reveal` | verification and observation | receipts in §6; CLI unchanged |
| Migration skeleton (guard-trigger drop, own transaction, result sets) | B's migration is a copy of the established shape | A's migration is untouched in the working tree; B's migration is a new file |
| A's `count-declared-capabilities` rows | B's verification input *is* A: the receipt returns A's installed document | §6.1 and §6.5 |

### 4.2 New maintenance B introduces

| New artifact / row | Recurring burden it implies |
|---|---|
| `examples/json-authoring/read-declared-capability-document.authority.json` | must stay byte-identical to the literal in the migration (no CLI declare path; see FF3); the digest check in §6.5 is the guard |
| `examples/json-authoring/read-declared-capability-document.request.json`, `…no-document.request.json` | none beyond keeping them valid against the reused request contract |
| `sql/migrations/declare-read-declared-capability-document.sql` | one migration per JSON document installs it (FF2); idempotent, replay verified `UNCHANGED` |
| Capability rows: shell + 2 capability versions, scenario + faces, execution authority + operation, port + version, one new contract (`read-declared-capability-document-result.v1`), document ledger row + content object | ordinary estate rows; exactly one current definition per declared id (migration result set 4) |
| Scaffold residue, inherited from the surface and identical for A: one unused `*-greeting.v1` contract, one unused `*-transform.v1` transformation, and the scaffolded canonical feature text | one orphan contract + one orphan transformation per JSON-authored capability; the feature text makes `reveal` misleading (FF4). This is surface behavior, not new to B |

Baseline check: replay after install reported `UNCHANGED` twice and capability
versions stayed at 2 — the same count A and its sibling show. `npm test` is
50 tests, 47 pass, 3 database-gated skips, 0 fail — the recorded estate
baseline, unchanged.

### 4.3 Benefit/burden and break-even (rubric §5)

- **First-delivery effect:** B's observed T0→T2 is 95 s. A's first delivery is
  bounded by a git window of 18 m 50 s that contained the surface fix, dry-run,
  preflight, install, invocations, reveal, list, tests, and a 106-line doc —
  A's capability-authoring portion inside it is not separable.
- **Repetition effect (estimated):** if a comparable capability cost A on the
  order of the whole 18 m 50 s window, B saves about 17 m per example; if A's
  capability authoring was only half that window, about 8 m per example.
  Observed for B, estimated for A.
- **Continuing burden:** no new runtime, no provider, no dependency. The
  recurring rows are two orphans per capability (same as A) plus the manual
  file↔literal equality check.
- **Break-even:** net savings per example = savings − added maintenance ≈
  0.13–0.29 h with maintenance near zero. The surface's upfront cost is
  **unknown** (authored before A, unmeasured). At 0.29 h/example, a 4 h upfront
  cost breaks even in ~14 further examples; at 0.13 h/example, ~31. These are
  arithmetic on one observed and one estimated input, not a repository
  estimate. Unknowns are left unknown.
- **Distribution:** capability authors receive the saving; the surface
  maintainer and the reader-path maintainer bear the residual friction in §8.

---

## 5. What changed because of reuse or learning

B's plan originally called for a new request contract. It was dropped when the
estate's own contracts were checked: contract identities are global
(`sidefx:contracts`), and the sibling's `read-capability-meaning-request.v1`
already declares the promise B's input needs (one capability identity,
`capabilityId` required). B therefore reuses it unchanged and declares only its
result contract. That learning removed one new artifact from every future
declared read of a capability id — evidence that the flywheel is also
procedural, not only mechanical.

---

## 6. Receipts

### 6.1 Preflight from the uncommitted migration (T1)

```
node --experimental-vm-modules scripts/invoke-from-transaction.mjs sql/migrations/declare-read-declared-capability-document.sql read-declared-capability-document examples/json-authoring/read-declared-capability-document.request.json
EXPERIMENT APPLIED (uncommitted)
DISPOSITION completed
OUTCOME {"disposition":"completed","outcome":{"capabilityId":"count-declared-capabilities","documentInstalled":true,"documentDigest":"sha256:6dace374fafb7655879fb0298948268c76c344bce87e6a87c47feb281087cb16","document":{"document":"sidefx-capability-authority.v1","capabilityId":"count-declared-capabilities",…}},"outcomeVariant":"TERMINAL",…}
```

Cell testimony from the same run: input contract
`read-capability-meaning-request.v1`, execution authority
`read-declared-capability-document.v1`, provider profile
`sda-declared-read-graph-provider.v1`, outcome contract
`read-declared-capability-document-result.v1`, outcome digest
`sha256:b2dededf…`, canonical graph digest `sha256:d112909a…`, realized graph
digest `sha256:3cb584a1…`, `executeDeclaredGraph` 371.2 ms.

### 6.2 Install (COMMIT) and replay

```
{"action":"DECLARE_CAPABILITY_DOCUMENT","disposition":"INSTALLED","capability_id":"read-declared-capability-document","document_digest":"a92552c438343f52806e7886454e40aa6b082f0a3a28d75c241ba36183bd98fc","contracts_declared":1,"scenarios_declared":1,"meaning_declared":1,"interface_declared":1}
{"action":"DECLARE_CAPABILITY_DOCUMENT","disposition":"UNCHANGED","capability_id":"read-declared-capability-document","document_digest":"a92552c4…","contracts_declared":0,"scenarios_declared":0,"meaning_declared":0,"interface_declared":0}
RS 6_capability_versions {"capability_id":"read-declared-capability-document","versions":2}
MIGRATION COMMIT COMPLETE
```

The post-install replay of the committed migration also reported `UNCHANGED`
twice and `versions: 2`.

### 6.3 `sfx capability invoke` (T2)

```
cmd /c "sfx capability invoke read-declared-capability-document --input @examples/json-authoring/read-declared-capability-document.request.json --json"
```

```
{"capabilityId":"read-declared-capability-document",
 "result":{"disposition":"completed","outcomeVariant":"TERMINAL",
   "outcome":{"capabilityId":"count-declared-capabilities","documentInstalled":true,
     "documentDigest":"sha256:6dace374fafb7655879fb0298948268c76c344bce87e6a87c47feb281087cb16",
     "document":{"document":"sidefx-capability-authority.v1","capabilityId":"count-declared-capabilities",…}}},
 "evidence":{"timings":{"executeDeclaredGraph":233.8,"processTotal":2035.8},
   "snapshotId":"sha256:1a770ac0795d10665a88166f8d8c968dc5b2d030fdfab2b837aa6071d135f9e9"}}
```

Cell time 45.1 ms; observed path digest
`sha256:1d636e4a88558dcad92014e6868d635d17b2a6820acdf54376998331c44b663f`.
(For comparison, A's invocation earlier in the same session: 103.7 ms cell,
`{"declaredCapabilities":304}`.)

Absence case:

```
cmd /c "sfx capability invoke read-declared-capability-document --input @examples/json-authoring/read-declared-capability-document.no-document.request.json --json"
→ {"capabilityId":"read-declared-capability-document","result":{"disposition":"completed",
   "outcome":{"capabilityId":"hello-world-sql","documentInstalled":false},"outcomeVariant":"TERMINAL",…}}
```

### 6.4 `sfx capability observe`

stdout:

```
Scenario read-declared-capability-document
GIVEN read-declared-capability-document-request  (read-capability-meaning-request.v1)
WHEN
THEN
  ✓ declared-capability-document  (read-declared-capability-document-result.v1)
```

stderr (telemetry, trimmed):

```
. delivery-phase readExecutionDelivery started / completed
. delivery-phase readAuthority started / completed
. delivery-phase executeDeclaredGraph started / completed
↳ scenario read-declared-capability-document admitted 0.159 ms
✓ scenario read-declared-capability-document 0.233 ms
```

### 6.5 The document returned is the document installed (byte equality)

B reports a content address. Hashing the example files with the same recipe used
by `model.put_semantic_definition` (`SHA2_256` over UTF-8 bytes, file without
trailing newline) reproduces the ledger digests exactly:

```
sha256(count-declared-capabilities.authority.json)      = 6dace374fafb7655879fb0298948268c76c344bce87e6a87c47feb281087cb16   ← A's ledger digest, returned by B
sha256(read-declared-capability-document.authority.json) = a92552c438343f52806e7886454e40aa6b082f0a3a28d75c241ba36183bd98fc  ← B's ledger digest, from the install
```

So B's invocation for A returns the exact bytes authored and installed for A —
the measurable sense in which "B was built on A".

### 6.6 `sfx capability reveal` (meaning)

```
## User story
Intent    read back the authority document the current model installed for one capability
Outcome   the caller observes the installed sidefx-capability-authority.v1 document and its content address, or that no document is installed for the id
## Scenarios (1)
  read-declared-capability-document
    input    read-declared-capability-document-request  (read-capability-meaning-request.v1)
    outcome  declared-capability-document  (read-declared-capability-document-result.v1)  [terminal]
## Execution plan (1)
    invoke-port -> read-declared-capability-document-port
## Ports (1)
  read-declared-capability-document-port  ->  sda-embodiment-plan-port.v1
## Contracts (2)
  read-capability-meaning-request.v1
  read-declared-capability-document-result.v1
```

(The "Canonical feature" block above the user story is scaffold residue, shared
with A — see FF4.)

---

## 7. A→B comparison and evidence class

| Measure | A (`count-declared-capabilities`, first JSON capability) | B (`read-declared-capability-document`) | Evidence class |
|---|---|---|---|
| Authoring artifacts for the capability | 44-line JSON document (plus a 44-line clone); the surface procedure (391-line migration) was built with it | 50-line JSON document; one migration (170 lines, verification-dominated); one result contract | observed for B; from git for A |
| Time to first executable result | not stamped; bounded inside 09:17:22→09:36:12 (18 m 50 s) | 18:03:25→18:04:34 = **1 m 09 s** | B observed; A estimated (window bound) |
| Time to behaviorally verified CLI outcome | verified inside the same window | 18:03:25→18:05:00 = **1 m 35 s** | B observed; A estimated |
| Attempts / failures | at least one failure before the fix: the surface "had never been executable" (invalid `IN (…) COLLATE` in the verification batch, procedure absent); exact count not retained | 7 attempts, 7 successes, 0 failures | B observed; A estimated |
| New contracts | 2 (request + result) | 1 result; request reused from a sibling | observed |
| Reused unchanged | — (there was nothing to reuse) | surface procedure, platform port, mechanic, invocation path, sibling contract, ledger, CLI, scripts | observed |
| Invocation cost | 103.7 ms cell / ~2.0 s process | 45.1 ms cell / ~2.0 s process | observed, same session |

**Honesty statement.** The B column is observed: every number above comes from
stamped commands in §2 or from the receipts in §6. The A column is
**estimated**: A's authoring session has no T0/T1/T2 record, only the git
window `c7af23a..268f10f` (09:17:22→09:36:12 on 2026-09-15) and the commit
message's account of what happened inside it. The commit says the migration
"had never been executable", so A's session necessarily contained at least one
failed attempt that B did not face; whether the failed attempts numbered one or
five is not retained. **What would make it observed:** the original session's
terminal log or a T0/T1/T2 note for A (none exists), or re-authoring A's
capability in a fresh namespace with timestamps recorded. Neither was done here.

---

## 8. Friction findings

Each is a finding, not a failure; the exact step that exposed it is named.

- **FF1 — the documented input spelling fails through `cmd /c`.**
  `AGENTS.md` and the usage text show `--input '@file.json'`. Through
  `cmd /c`, `cmd` passes the single quotes to Node literally, so the CLI does
  not recognize the `@` carrier and rejects the input
  (`CAPABILITY_INPUT_JSON_REJECTED`, observed invoking A before T0). Working
  form: `cmd /c "sfx capability invoke <id> --input @file.json --json"`.
  Cost: one failed invocation on A before the working spelling was found.
  What this is not: a defect in B.
- **FF2 — a JSON document can only be installed by a migration.** There is no
  `sfx capability declare --input @document.json`. Installing B required a
  full migration (guard-trigger drop, own transaction, verification result
  sets) around a 50-line document. B's migration is 170 lines, ~120 of them the
  copied verification ceremony. This is the known limit in
  `docs/json-authoring-surface.md`, re-confirmed at the install step.
- **FF3 — the document is duplicated between the example file and the SQL
  literal, with no mechanism to keep them equal.** The procedure is SQL-side,
  so the document must be embedded as a T-SQL string literal; every single
  quote must be doubled by hand or script. If they drift, the installed digest
  silently differs from the example file. B guarded this with a mechanical
  splice plus the SHA-256 equality check in §6.5; a `declare` command would
  remove the duplication. Exposed while writing the migration.
- **FF4 — a JSON-authored capability retains the scaffold's feature text.**
  Both A and B show `Feature: Write the configured text to standard output`,
  the greeting scenario, and a `*-greeting.v1` outcome contract in
  `reveal --as meaning`, above the true user story and scenarios. The document
  has no feature field, and `author_capability_meaning` does not replace the
  scaffolded feature. The scaffold also leaves an unused
  `*-transform.v1` transformation. Observed at the `reveal` step; identical for
  A, so it is the surface's behavior, not new maintenance B introduced.
- **FF5 — there is no declared-read shape for "the named thing is absent"
  other than values in one row.** B handles absence by returning
  `documentInstalled: false` rather than failing; the declared-read mechanic
  requires exactly one row/one record, and a `THROW` would surface as a failed
  read rather than a value (reasoned, not exercised here). This works, but it
  means absence is a value convention each read must invent for itself. Noted,
  not blocking.
- **FF6 — concurrent working-tree work is part of the execution conditions.**
  At the time of this record the tree carried an uncommitted reader change
  (`src/invoke-database-capability.mjs`, platform-mechanic registry resolution)
  plus three untracked migrations and a change-request doc from other work.
  All commands here ran with that state. The reader change is what resolves a
  platform-bound port to its SDA mechanic, so it was present for A's receipt
  too; nothing in this record depends on B editing `src/`. See §9.

---

## 9. Conditions and limits

- **No commits.** Per the task constraints, none of the work was committed; the
  migration is installed in the live estate from the working-tree file.
- **Concurrent work.** The working tree contained unrelated uncommitted changes
  (§8 FF6). The coherence snapshot for every invocation was
  `sha256:1a770ac0795d10665a88166f8d8c968dc5b2d030fdfab2b837aa6071d135f9e9` —
  the same snapshot A's receipt shows, so the comparison is like-for-like.
- **No provider claim.** B is offline by design; this record says nothing about
  provider conformance or live-provider capabilities.
- **No independence.** The same session authored B and recorded this proof;
  there is no separate reviewer, so review overhead is unobserved and the
  "distinct users" count is 1.
- **No git commit of the receipt.** The commands in §6 are the durable receipt;
  the raw terminal outputs are not retained as files (the task's writable scope
  was `docs/`, `examples/json-authoring/`, `sql/migrations/`, `scripts/`).

## 10. Reproduce

```powershell
# 1. Dry-run (nothing persists)
node scripts/run-migration.mjs sql/migrations/declare-read-declared-capability-document.sql

# 2. Preflight from the uncommitted state
node --experimental-vm-modules scripts/invoke-from-transaction.mjs `
  sql/migrations/declare-read-declared-capability-document.sql `
  read-declared-capability-document `
  examples/json-authoring/read-declared-capability-document.request.json

# 3. Install (the committed file ends in COMMIT TRANSACTION;)
node scripts/run-migration.mjs sql/migrations/declare-read-declared-capability-document.sql

# 4. Verify through the unchanged CLI
cmd /c "sfx capability invoke read-declared-capability-document --input @examples/json-authoring/read-declared-capability-document.request.json --json"
cmd /c "sfx capability invoke read-declared-capability-document --input @examples/json-authoring/read-declared-capability-document.no-document.request.json --json"
cmd /c "sfx capability observe read-declared-capability-document --input @examples/json-authoring/read-declared-capability-document.request.json"

# 5. Re-check the byte-equality receipt (Windows file without trailing newline)
node -e "const fs=require('fs'),c=require('crypto');const h=t=>c.createHash('sha256').update(Buffer.from(t,'utf8')).digest('hex');console.log(h(fs.readFileSync('examples/json-authoring/read-declared-capability-document.authority.json','utf8').trimEnd()))"
# expect a92552c438343f52806e7886454e40aa6b082f0a3a28d75c241ba36183bd98fc
```

**Bottom line.** The next declared-read capability authored through the JSON
surface cost one document and one migration because A's run established the
surface, the port, the path, the ledger and a reusable input contract. That is
the flywheel's first measured turn — observed for B, estimated for A, and
scoped honestly to the shape it was measured on.
