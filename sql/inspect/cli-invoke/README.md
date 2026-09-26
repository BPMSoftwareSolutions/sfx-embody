# cli-invoke inspection lane

Read-only inspection of the live model for one question: **what declared
mechanism carries a capability-to-capability invocation whose target is selected
from the request at runtime (not a literal), and what exact declarations make
`sda-cli-invoke` (capability pk 100909, namespace `sidefx:capabilities`) invoke
the capability named by its request?**

Every file is a standalone read: `SET NOCOUNT ON; BEGIN TRANSACTION; <selects>;
ROLLBACK TRANSACTION;`. Run each from `C:\lab\repos\sfx-embody`:

```
node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/run-migration.mjs "sql\inspect\cli-invoke\<file>.sql"
```

The runner prints the first 20 rows of each result set. Text is decoded with
`CONVERT(nvarchar(max),CONVERT(varchar(max),content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)`
where a declaration body is read.

## Answer in one paragraph

The request-derived target is declared in the **port**, consumed by an
**`invoke-port` operation**. An `invoke-port` operation's companion row
`model.operation_port_invocation.port_version_pk` is a literal port version, but
the invoked port's selected declaration can name platform capability
`sda-node-consumer-runtime.v1` with `configuration.capabilityIdPath`,
`requestPath`, `namespacePath`, `scenarioPath`, `resultPath`, `authoritySource`
and `lineageMode`; the declared provider `ScenarioKernel.NodePlatform` then
reads the capability id from the request at that path. The only declaration in
the live database that does this is `sda-cli-invoke-port` (selected definition
211571, port version 4387). The selected `sda-cli-invoke` capability version
1161266 does **not** carry the `invoke-port` operation that would consume it:
its scenarios carry only `invoke-scenario` operations with literal targets
(`target_scenario_version_pk`). The retained `invoke-port` operation survives on
the unselected versions 1161234 / 1161235. That missing operation row is the
exact incomplete declaration surface.

## Files

| File | Question it answers | How to read it |
| --- | --- | --- |
| `00-live-model-identity.sql` | Which database/estate is this, and which capability pks are named? | `database_identity` (sidefx), `current_estate_model` (estate_model_pk 34), `capability_identities` (100909 `sda-cli-invoke`, 100695 `request-capability-from-objective`, selected versions 1161266 / 910966), `model_declaration_table_counts` (the row counts later files cite). |
| `01-operation-kind-vocabulary.sql` | What is the complete operation-kind vocabulary and each kind's companion? | `operation_kind_vocabulary`: `invoke-port` 2757, `invoke-scenario` 605, `project-state` 3; each kind has rows in exactly one companion table (`operation_port_invocation` 2730, `operation_scenario_invocation` 605, `operation_state_projection` 3). The example result sets show every companion value is a literal foreign key. |
| `02-invocation-companion-columns.sql` | Can a companion row itself express a target-from-state/request? | `companion_columns` shows only FK/pointer columns (`port_version_pk`, `target_scenario_version_pk`, `transformation_version_pk`) — no capability/target/path/expression/selector/authority column. `companion_row_counts` shows `operation_transformation`, `operation_mechanic`, `operation_predecessor` are empty. `unpaired_invoke_port_operations` lists 4 selected-graph `invoke-port` operations with no companion row (2757 − 2730 = 27 unpaired overall). |
| `03-port-semantics-request-paths.sql` | Where can a request-derived target be declared, and which platform capabilities use it? | `selected_ports_with_request_members`: `sda-node-consumer-runtime.v1` has 2 selected declarations, 1 with `capabilityIdPath`; `sda-projected-capability-invocation-port.v2` has 82, 0 with `capabilityIdPath`, 24 with `declaredApplication`. `sda_cli_invoke_port_selected_declaration` is the decisive row: definition 211571, port version 4387, `capabilityIdPath=capabilityId`, `requestPath=input`, `providerId=ScenarioKernel.NodePlatform`. `v2_pinned_target_sample` shows the v2 alternative pins a literal `executionPlanDocument.capabilityId` (e.g. `execute-governed-model-invocation`). |
| `04-platform-provider-evidence.sql` | Is the provider side declared in DB tables? | `provider_capability_implementation`: provider `ScenarioKernel.NodePlatform` (pk 6) → `sda-node-consumer-runtime.v1` version 150558 role PLATFORM; provider 41 → `sda-projected-capability-invocation-port.v2` version 150570. `selected_provider_mechanics`: NodePlatform definition 196461 declares `scenario-invocation[62]` and `invoke-scenario[200] role=scenario-invocation`; the projected provider declares `projected-capability-invocation` + `pinned-capability-binding`. `consumer_runtime_overlay_binding`: rule on `run-declared-graph-execute` names `node:provider:sda-node-consumer-runtime.v1`. `overlay_profile_declaration_gap`: 0 rows in `model.provider_profile` for that id, but the rule's digest matches selected provider definition 196461. `selected_graph_provider_qualification`: the selected graph's port binding carries provider `ScenarioKernel.NodePlatform`, `providesMechanics` includes `scenario-invocation`. |
| `05-dynamic-invocation-precedent.sql` | Is there any working precedent of target-from-request? | `dynamic_target_invocations_in_selected_graphs`: 1308 selected-graph `invoke-port` operations, **0** with a request-named target (`capabilityIdPath` non-null). `consumer_runtime_invocations_in_selected_graphs`: the only consumer-runtime ports invoked in selected graphs are `database-query-provider-port`, `execute-bound-consumer-plan`, `run-pilot-container-port` — all with `capability_id_path` NULL. `v2_pinned_invocations_in_selected_graphs`: 86 v2 operations, 24 pinned applications. No precedent exists. |
| `06-request-capability-from-objective-vs-sda-cli-invoke.sql` | Side-by-side of capability 100695 (op 2629) vs capability 100909. | `request_capability_operation_2629`: `invoke-scenario`, `target_scenario_version_pk=898` (`resolve-equity-market-price-evidence`) — literal. `sda_cli_invoke_selected_operations`: version 1161266 operations 9105/9106 are `invoke-scenario` → literal `target_scenario_version_pk=102211` (`sda-cli-invoke`, a self-target). `sda_cli_invoke_retained_invoke_port_operations`: operations 8824/8825 on unselected 1161234/1161235 are `invoke-port` → `port_version_pk=4387`, `sda-cli-invoke-port`. `port_declarations_side_by_side`: the request-capability ports carry literal `transformationId` or a `statement`, never `capabilityIdPath`; `sda-cli-invoke-port` carries `capabilityIdPath=capabilityId`. |
| `07-expected-sda-cli-invoke-declaration.sql` | What rows must a corrected `sda-cli-invoke` have, and which are present? | `missing_operation_rows` returns the one missing row: capability version 1161266, scenario `sda-cli-invoke`, `invoke-port`, port_version 4387. `unexpected_operation_rows` returns none. `expected_port_member_assertions`: all 9 port-declaration members present and equal. `expected_supporting_assertions`: provider link PRESENT, overlay binding PRESENT, `provider_profile(node:provider:sda-node-consumer-runtime.v1)` MISSING. Expectations are table variables; nothing is written. |

## The named mechanism (with decisive rows)

- Operation kind: `invoke-port` (`01-operation-kind-vocabulary.sql`,
  `operation_kind_vocabulary` row 1: 2757 rows).
- Companion: `model.operation_port_invocation(execution_operation_pk,
  port_version_pk, operation_kind)` (`02-invocation-companion-columns.sql`,
  `companion_columns` row `operation_port_invocation`).
- Port declaration carrying the request-named target:
  `model.semantic_object_definition.semantic_object_definition_pk=211571`
  (`03-port-semantics-request-paths.sql`,
  `sda_cli_invoke_port_selected_declaration`), reachable as
  `model.port_version.port_version_pk=4387`.
- Provider body that reads it: provider `ScenarioKernel.NodePlatform` (pk 6),
  selected definition 196461, mechanic `scenario-invocation[62]` /
  `invoke-scenario[200] role=scenario-invocation`
  (`04-platform-provider-evidence.sql`).
- Overlay that selects the consumer-runtime provider profile for the execution
  port: `run-declared-graph-execute`, mechanicId `sda-node-consumer-runtime.v1`
  (`04-platform-provider-evidence.sql`, `consumer_runtime_overlay_binding`).
- Missing declaration in the selected graph: one row in
  `model.operation_port_invocation` plus its `model.execution_operation`
  (`operation_kind='invoke-port'`) inside selected capability version 1161266
  (`06-request-capability-from-objective-vs-sda-cli-invoke.sql`,
  `sda_cli_invoke_retained_invoke_port_operations`;
  `07-expected-sda-cli-invoke-declaration.sql`, `missing_operation_rows`).

## UNPROVEN

- **Whether the runtime requires a `model.provider_profile` row for
  `node:provider:sda-node-consumer-runtime.v1`.** The overlay rule references it
  and carries the digest of selected provider definition 196461; no
  `provider_profile` row exists. The failing query is
  `overlay_profile_declaration_gap` in `04-platform-provider-evidence.sql`
  (`provider_profile_rows = 0`). The database cannot decide whether the profile
  id is resolved through that table or through the digest.
- **Which scenario must carry the restored `invoke-port` operation.** `07` asserts
  the root scenario `sda-cli-invoke` (sv 102211); the retained precedent on
  version 1161235 carries it on scenario `invoke` (sv 102140). Both are
  consistent with the live rows (`06`,
  `sda_cli_invoke_retained_invoke_port_operations` vs
  `sda_cli_invoke_selected_operations`).
- **Which declared writer would create that operation row.** No row in `model`
  records a writer for operations; the inspection lane therefore only asserts
  the expected shape, never a procedure. The relevant empty tables are visible
  in `02-invocation-companion-columns.sql` (`companion_row_counts`).
- **Whether an `invoke-scenario` self-target in the selected graph executes.**
  `06` shows `execution_operation_pk 9105` targets its own scenario version
  102211; no selected row states the outcome, so this is not settled here.
