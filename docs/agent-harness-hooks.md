# The agent harness: hooks required to work the declared estate

**Status.** Proposed 2026-09-18. Scope: the harness controls a coding agent needs
to build capabilities, run them, add providers and repair executable meaning in a
repository that holds **no execution code**. Authority for what the agent must and
must not do: [AGENTS.md](../AGENTS.md), [sql/README.md](../sql/README.md),
[transistor-model.md](transistor-model.md). This document owns the *enforcement* of
those rules, not the rules themselves.

Nothing here is installed. `.claude/settings.json` does not exist in this
repository as of this writing; the only file under `.claude/` is the
`declare-provider-fallback` skill.

## 1. Why this exists: the third place

The estate's law is that executable meaning is either **declared (1)** —
language-invariant rows — or an **admitted resolver (0)**. There is no third place.

Every control on *agent behavior* currently sits in exactly that third place.
`AGENTS.md`, `sql/README.md`, the two skills and the session's memory files are
prose: the agent reads them and complies, or does not, and nothing observes the
difference. "The model remembers to be careful" is not a resolver and not a
declaration. It is the third place, and the same law says to close it.

A hook is resolver (0) for the agent: deterministic, per-language code the harness
executes, outside the model's judgment. This document is the register of which ones
the four jobs require.

**Schema basis.** Event names, the decision contract and the input fields below are
the Claude Code settings schema as read on 2026-09-18. Re-verify against the
installed build before implementing; the `hooks` key is versioned with the client,
not with this estate.

## 2. The contract a hook has to work with

| Mechanism | Shape | Use |
| --- | --- | --- |
| Event | `hooks.<Event>[]`, each entry `{ matcher, hooks: [...] }` | `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `UserPromptSubmit`, `SessionStart`, `Stop`, `PreCompact` are the ones this register uses |
| `matcher` | Tool-name pattern, e.g. `"Bash"`, `"Write\|Edit"` | Coarse selection |
| `if` | Permission-rule syntax, e.g. `"Bash(git commit *)"` | Fine selection **without spawning a process** for non-matching calls; prefer it over grepping inside the command |
| `shell` | `"bash"` or `"powershell"` | The Windows default is PowerShell when Git Bash is absent. Pin `"bash"` explicitly — every gate below assumes POSIX text handling, and PowerShell 5.1 is the source of the native-stderr defect the estate already documents |
| Decision (PreToolUse) | stdout JSON `hookSpecificOutput.permissionDecision` = `allow` / `deny` / `ask`, with `permissionDecisionReason` | The blocking gates |
| Rewrite (PreToolUse) | `hookSpecificOutput.updatedInput` | Mechanical command repair |
| Decision (PostToolUse, Stop, UserPromptSubmit) | `decision: "block"` with `reason` | After-the-fact refusal and feedback |
| Context injection | `hookSpecificOutput.additionalContext` | Put facts in front of the model instead of hoping it recalls them |
| Exit codes | `0` = pass; `2` = blocking error, stderr returned to the model | The cheap form when no JSON is needed |
| Input | stdin JSON: `session_id`, `tool_name`, `tool_input`, plus `tool_response` on `PostToolUse` | |
| Hook types | `command`, `prompt`, `agent`, `http`, `mcp_tool` | `prompt` and `agent` put a model in the enforcement path — see §7 |

Settings precedence is user, then project, then local. `disableAllHooks: true` in
any source turns the whole register off; the register is a control on the agent,
not a control on the operator.

## 3. Where hook logic may live

This is the design question that matters most here, and it has an architectural
answer rather than a convenience one.

The estate retired its scripts. `scripts/`, `src/` and `tests/` no longer exist;
[architecture-achieved.md](architecture-achieved.md) §9 row 7 records the UID
remainder as **one** tracked research script. A directory of `.claude/hooks/*.sh`
would re-open the surface the retirement ledger just closed, and would land on that
ledger as new hand-authored estate code.

| Option | Verdict |
| --- | --- |
| Inline one-liners in `settings.json` | **Use for pure predicates** — a path test, a grep for banned vocabulary, a deny. `settings.json` is host and invocation configuration of the same kind as `sfx.config.json`: it *selects*, it does not implement |
| `.claude/hooks/*.sh` in the estate | **Avoid.** New UID in a repository whose ledger is closed. If used at all, it is a tracked exception with a retirement trigger, recorded like any other |
| SDA-homed lifecycle tools invoked by the hook | **Use for anything with logic.** The lifecycle's ground already lives in `SDA:languages/typescript/src/kernel/bootstrap/` (`run-migration.mjs`, `invoke-from-transaction.mjs`), precisely so that no estate script executes SQL. A preflight-receipt gate is lifecycle enforcement and belongs beside them |

The rule that follows: **the estate's `settings.json` selects; the kernel
resolves.** The same shape as the installed kernel executable in `sfx.config.json`.

## 4. The register

Grouped by the four jobs. "Gate" blocks; "Flag" reports and lets the call proceed;
"Inject" adds context with no decision.

### Build a capability

| # | Event / matcher | `if` | Kind | What it enforces |
| --- | --- | --- | --- | --- |
| H1 | `PreToolUse` / `Bash` | `Bash(git commit *)` | **Gate** | Step 7. If the staged set contains `sql/migrations/*.sql`, require a preflight receipt for each, newer than the migration file. Deny otherwise, naming the missing receipt |
| H2 | `PreToolUse` / `Bash` | `Bash(node *run-migration.mjs *)` | **Gate** | Read the `.sql` argument's terminator. Ending in `ROLLBACK` is a dry run — allow. Ending in `COMMIT` is an install — allow only with a passing preflight receipt for its `ROLLBACK` twin. This is the step 3 to step 4 boundary, which nothing currently observes |
| H3 | `PreToolUse` / `Bash` | `Bash(*run-file.mjs *)` | **Gate** | The named non-negotiable: that runner opens its own transaction and silently discards the script's `COMMIT`. Deny unconditionally, with the reason |
| H4 | `PreToolUse` / `Bash` | `Bash(*--json*)` | **Gate or rewrite** | Capture native JSON through `cmd /c`. PowerShell 5.1 rewrites native stderr and can break JSON mid-string. `updatedInput` can repair this mechanically; a deny with the reason is the conservative form |
| H5 | `PreToolUse` / `Write\|Edit` | — | **Gate** | Path discipline. Deny under `sql/schema/**`; deny edits to an already-tracked `sql/migrations/*.sql` (a landed migration is immutable — a change is a new migration). This is the edit reflex, caught at the tool boundary |
| H6 | `PostToolUse` / `Write` | — | **Flag** | Migration shape, on `sql/migrations/*.sql`: opens its own `BEGIN TRANSACTION`, ends in `ROLLBACK`, drops the `model` and `source` guard triggers inside the script, prints result sets. Return `decision: "block"` with the specific defect so it is repaired before the dry run |
| H7 | `PostToolUse` / `Write` | — | **Flag** | Vocabulary. On the database surface it is all rows: no `capsule`, `artifact`, `retained source` or `projection` vocabulary in a migration. A grep, and one of the few fabrication-adjacent rules that is fully deterministic |

### Run a capability

| # | Event / matcher | `if` | Kind | What it enforces |
| --- | --- | --- | --- | --- |
| H8 | `SessionStart` | — | **Inject** | Environment truth, once, as `additionalContext`: whether `../scenario-driven-architecture` is present and at which revision; whether the kernel executable named in `sfx.config.json` exists at that digest; whether `sfx` is on PATH; whether the circuit answers. Without this the agent narrates failures whose real cause is a missing checkout |
| H4 | (as above) | | | The `cmd /c` rule applies to every `invoke --json` |
| H9 | `PostToolUseFailure` / `Bash` | `Bash(sfx *)` | **Inject** | On a failed invocation, return the disposition-reading discipline rather than letting the agent theorize: which field decides the failure class (`exchangeCount: 0` means no request was made — credential binding or endpoint admission, not a provider problem) |

### Add a provider

| # | Event / matcher | `if` | Kind | What it enforces |
| --- | --- | --- | --- | --- |
| H10 | `PreToolUse` / `Bash\|Write\|Edit` | — | **Gate** | Credentials resolve from the secrets vault, never the process environment. Deny a command that sets a credential-shaped variable (`*_API_KEY=`, `$env:*_KEY`, `export *_TOKEN`) and any write to `.env*`. The estate is already vault-only; this keeps a debugging shortcut from quietly reintroducing an environment path |
| H11 | `PostToolUse` / `Write` | — | **Flag** | On a migration declaring `endpointAuthorities[]` or `credentialAuthorities[]`, require the structural fields the ports demand — an `endpointAuthorityDigest` per endpoint authority, an `injectionRule` per credential authority — and flag a fallback route authored with no captured evidence of the primary's failure |

### Maintain and repair meaning

| # | Event / matcher | `if` | Kind | What it enforces |
| --- | --- | --- | --- | --- |
| H12 | `SessionStart` | — | **Inject** | The declared-identity dump (§5) as `additionalContext`. The authority ladder in one move: what exists is what the database says exists |
| H13 | `Stop` | — | **Flag** | Scan the turn's final message for capability-identity-shaped tokens absent from the dump and report them. Heuristic, and noisy unless proposed identities are marked as proposals — but it turns fabrication from invisible into visible |
| H14 | `PreToolUse` / `Write` | — | **Inject** | On a first write to `sql/migrations/*.sql`, restate step 0: a regression is a diff against the generation that worked, and the working bundle under `evidence/<capability>/` is the baseline. Advisory — the capability under change cannot be inferred reliably from a filename |

## 5. Enabling artifacts

Three things the register needs that do not exist yet.

1. **The declared-identity dump.** One declared read, refreshed per session,
   listing every capability identity the database declares. H12 and H13 both depend
   on it. It must be a declared reading, not a query the harness invents —
   otherwise the anti-fabrication control is itself unauthorized.
2. **A preflight receipt with a fixed location and shape.** H1 and H2 are gates on
   its existence and freshness: migration path, capability id, disposition, outcome,
   timestamp, and the digest of the `.sql` as preflighted. Without the digest the
   gate is defeated by editing the migration after preflighting it.
3. **`docs/findings/` and a template.** AGENTS.md already says a blocked invocation
   "is a finding, not a reason to edit the kernel" — and a finding has nowhere to
   go. H5 blocks the wrong move; a gate with no alternative route is just pressure.
   This is the cheapest item here and the one that makes the rest humane.

**Receipts are local.** `evidence/` is gitignored and holds zero tracked files.
That is correct for the estate, and it means the H1 and H2 gates protect the machine
that produced the receipt, not the repository. On a fresh clone there are no
receipts: the gate must **fail closed** (deny, and say a preflight is required),
with the escape being to run the preflight — never a flag that skips it.

`.claude/settings.local.json` is where machine paths belong (SDA root, kernel path).
It is not currently in `.gitignore`; add it before creating one.

## 6. Staging

In value order, not schema order. Each stage is useful alone.

1. **H3, H5, H10** — pure denies, no enabling artifact, no state. An afternoon.
2. **`docs/findings/` and a template** — the affordance H5 needs to be fair.
3. **The receipt contract, then H1 and H2** — the real protection, and the only
   items here that stop a bad install rather than a bad sentence.
4. **H8** — environment truth at session start.
5. **H6, H7, H9, H11** — shape and vocabulary checks; all greps.
6. **The identity dump, then H12 and H13** — the fabrication controls, last because
   they are the weakest and the noisiest.

## 7. What hooks cannot do

Stated plainly, because a register like this invites the belief that the problem is
now handled.

- **They do not check truth.** A confident, well-formed, wrong sentence about this
  architecture passes every gate above. H13 catches an invented *identity*; it does
  not catch an invented *relationship* between two real ones. The only control for
  that is a second reader — which is what the review-closure convention in the wave
  plans already is. Keep it.
- **They bind this agent, not the repository.** Hooks fire on tool calls in a Claude
  Code session. Another writer committing this working tree — which demonstrably
  happens here — passes through none of them. Repository-level enforcement is a
  pre-commit hook or CI, and is a different document.
- **`prompt` and `agent` hook types put a model in the enforcement path.** They are
  attractive for exactly the checks that resist automation, and they are a model
  checking a model. Use them to flag, never as the gate of record; a deterministic
  grep that catches less is worth more than an LLM check that catches more
  unreliably.
- **A gate teaches nothing.** H5 blocks the edit reflex at the boundary; it does not
  make the declared route easier. Every gate above should be read as a deadline for
  building the affordance that makes the right move cheap.
- **Mid-session installs may not load.** The settings watcher only watches
  directories that held a settings file when the session started. Creating
  `.claude/settings.json` mid-session typically needs `/hooks` or a restart before
  anything fires — which means the first proof that a gate works is the session
  *after* the one that wrote it.

## 8. Open questions for the builder

1. **Receipt shape and home** — a new local schema, or a field set already emitted
   by `invoke-from-transaction.mjs`? Reusing an existing emission is strictly better
   than minting a contract for a gate.
2. **Where the gate logic is homed** — SDA bootstrap (§3's recommendation) or an
   accepted UID exception in the estate with a retirement trigger.
3. **H4's form** — mechanical repair via `updatedInput`, or deny-with-reason. Repair
   is deterministic and removes a recurring failure; deny keeps the harness out of
   the business of rewriting commands.
4. **Whether the identity dump is worth its declaration.** H12 and H13 are the
   weakest controls in the register and the only ones requiring a new declared read.
   It is a legitimate answer to build items 1 through 5 of §6 and leave fabrication
   to the reviewer.
