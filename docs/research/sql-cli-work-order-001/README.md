# Hello World SQL scaffold: observed result

2026-09-12 · SQL candidate generation verified; CLI execution blocked.

Open [scaffold-hello-world.sql](../../sql/scaffold-hello-world.sql) in a normal SQL Server session against the existing SideFX database. Change `@CapabilityId` and `@Message` to generate another candidate. Run outside an existing transaction; the file owns its transaction and rolls it back.

The file returns five review datasets: scaffold, change, reuse, verification, and rubric/flywheel. It creates **session-local candidate data**, not a persisted or CLI-invocable capability. Its empty-request contract, feature/Gherkin, execution operation, message, outcome contract and unresolved provider slot are inspectable. There is no stdout implementation in this file.

## What ran

The [retained verification](verification.json) binds the SQL file digest and contains both actual SQL result sets and the actual `sfx` failure.

| Trial | Observed result |
| --- | --- |
| `hello-world-sql` / `Hello World` | Candidate data and JSON operation input match the parameters; transaction count returns to zero and the candidate temp table is gone after rollback. |
| `hello-world-sql-repeat` / `Hello SQL's 世界` | The same SQL operation preserves the changed identity, apostrophe and Unicode message; rollback is observed again. This proves repeatable candidate generation, not a second executed capability. |
| Selected Node registry | 31 event bindings inspected from the same `PINNED_PLATFORM_AUTHORITY` source class used by the existing capability reader. No stdout event binding identified. |
| CLI invocation below | Exit 4, `CAPABILITY_NOT_FOUND`; no stdout mechanic executed. |

Actual command, run from `C:/lab/repos/sfx-embody`:

```powershell
sfx capability invoke hello-world-sql --input '{}' --json
```

The existing `say-hello-world` capability is not a substitute: its selected authority invokes a transformation returning a greeting. The CLI serializing that result does not prove the standard-output mechanic required by work order 001.

## Exact missing work

The follow-up [gap resolution](gap-resolution.md) confirms these with live evidence and specifies the smallest change that closes each.

1. **Stdout event binding:** no admitted `invocation: "effects"` port writes text to standard output. The registry is pinned platform authority (`716811046f52dd2a67f9ff308a50d755571cbbad`, clean worktree), so a provider must be added to `languages/typescript/runtimes/node/` and admitted through a managed platform update. A registry name match alone is insufficient evidence of compatibility.
2. **Working-data delivery:** the intended working tables are guarded. An in-place `UPDATE source.content_object` is rejected with SQL error `51003 IMMUTABLE_INSPECTION_DATA` (`guard_content_object`), so the working representation cannot be edited as-is. Add a mutable `workshop` store the runtime can read, rather than mutating sealed tables or weakening their guards; a separate CLI connection also cannot read session-local tables.
3. **Stdout surface:** `sidefx-cli` consumes the delivery's stdout as one canonical JSON object, so the message is only visible inside the result JSON, not as raw text. This is a separate CLI/delivery presentation change.

These are implementation gaps. No managed promotion prerequisite was imposed and no publication guard was disabled. Existing capabilities, sealed capsules and selected model were unchanged. The SQL file reports these gaps instead of fabricating a provider or a successful execution receipt.

## Work-order scorecard

| Measure | Observed state |
| --- | --- |
| Contribution | Proposed **3/3**: the intended SQL → CLI loop is the requested result. |
| End-to-end evidence | **0/2**: the stdout loop remains untested because execution is blocked. |
| Required CLI checks | **0/4** complete. SQL candidate tests are separate component evidence. |
| External source edits | **0**; no capability-specific or generic runtime/CLI source changed. |
| Managed-promotion prerequisites | **0**. |
| First/repeat delivery minutes, human steps and savings | **Unmeasured**; no successful executable delivery to compare. |

After those two gaps close, repeat the four work-order checks through the real CLI: create/invoke, SQL-only message change, restore, and create/invoke a second identity. Retain actual stdout-call evidence and measure delivery/repetition effort before claiming completion.
