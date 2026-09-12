# SQL → CLI: prove the working loop

2026-09-12 · Work order · End-to-end execution not yet demonstrated

**Goal:** Edit a database capability, invoke that edited definition through CLI, verify its outcome, then roll back.

```mermaid
flowchart LR
    data["Read and edit working data"] --> run["Invoke through CLI"]
    run --> result["Check actual outcomes"]
    result -->|"Rollback; use the learning"| data
```

**Flywheel:** Easier changes and varied inputs reveal defects sooner. Reuse the resulting mechanics and checks to reduce effort on the next useful change. Measure that reduction.

**Work and verification — one existing equity-price capability:**

| Step | What the command-line evidence must show |
| --- | --- |
| 1. Read | Actual working definition and Input → Event → Outcome, including missing data. |
| 2. Edit and invoke | One SQL edit changes the executed definition and produces the expected effect. |
| 3. Vary and check | Two symbols and one invalid-input case supplied directly as arguments. Requests and outcomes reconcile. Simulation leaves real-provider proof open. |
| 4. Roll back | A fresh read confirms the database change was undone. |

Reuse existing mechanics. The CLI must receive the exact edited data before rollback; separate connections do not automatically see uncommitted edits. Rollback covers the database change.

**Small scorecard — proposed assessment of this slice:**

| Measure | Now | Completion evidence |
| --- | --- | --- |
| Flywheel contribution, 0–3 | **3**: necessary to prove the requested loop | Assess its actual benefit afterward. |
| End-to-end evidence, 0–2 | **0**: untested | **2** after observing the complete intended loop. |
| CLI checkpoints | **Not run** | **4/4**, with actual outputs. |
| Effort and burden | **Unknown** | Minutes, human steps, added maintenance; compare the next useful change. |

Prefer the least-work option that proves the whole loop through CLI. Component-only proof remains partial. Keep scores and effort separate.

**Boundary:** Working data stays freely editable. Managed governance applies at capsule promotion. Broader cleanup stays outside this slice.

**Deliver:** Runnable SQL/CLI commands, actual outputs, and this scorecard. Supporting analysis stays separate.
