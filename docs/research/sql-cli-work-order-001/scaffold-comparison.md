# Executable scaffold comparison: what invocation actually needs

Compares the working `scaffolds/resolve-equity-market-price-evidence` capability
with the minimal `scaffold-hello-world.sql` insert, against the read path in
`src/read-authority.mjs` + `src/materialize-node.mjs` and
`sidefx-database/sql/diagnostics/capability-embodiment.sql` / `scenario-closure.sql`.

## The read path, exactly

`planNode` reads these workspace entries and nothing else (`materialize-node.mjs:42-48`):
`capability`, `feature`, `executionAuthorities`, `semanticGraph`, `interfaces`,
`fixtures`. It does **not** read `blueprint` or `projectionAuthorities`.

`capability-embodiment.sql` reads only the selection chain and the lineage that
resolves the capsule digest. `scenario-closure.sql` reads the selection chain.
`analysis.v_selected_semantic_definition` supplies mechanic declarations globally.

## A. Capsule source entries

| File | Equity | Hello world | Read by invocation |
| --- | --- | --- | --- |
| `capability.authority.json` | yes | yes | yes (`capEntry.capability`) |
| `consumer-workspace.authority.json` | yes | yes | yes (workspace itself) |
| `execution-authorities.authority.json` | yes | yes | yes |
| `semantic-graph.authority.json` | yes | yes | yes |
| `interfaces.authority.json` | yes | yes | yes |
| `fixtures.authority.json` | yes | yes | yes |
| `contracts/contract-catalog.json` + schemas | yes | yes | yes |
| `features/<id>.feature` | yes (external ref `../../features/…`) | yes | yes |
| `capabilities/<id>/capability.feature` | no | yes (workspace ref) | yes (via the workspace ref) |
| `blueprint.authority.json` | yes | no | **no** |
| `projection-authorities.authority.json` | yes | no | **no** |

Hello world includes every capsule file the read path uses. It omits only
`blueprint` and `projection-authorities`, which the node planner never reads.

## B. Normalized model rows

| Structure | Equity (registered) | Hello world | Needed at invocation |
| --- | --- | --- | --- |
| `identity_namespace`, `semantic_object`, `semantic_object_definition` (capability) | yes | yes | yes — lineage resolution |
| `capability`, `capability_version`, `estate_capability` | yes | yes | yes — selection |
| `scenario`, `scenario_version`, `capability_scenario`, `capability_root_scenario` | yes | yes | yes — selection + closure |
| `source_observation` + `declaration_observation` | yes | yes | yes |
| `source_lineage` | yes (many) | **one** | only the capability→observation row |
| `scenario_input` / `scenario_event` / `scenario_outcome` | yes | no | no — `LEFT JOIN` output only |
| `scenario_outcome_contract` | yes | no | no — `LEFT JOIN` output only |
| `estate_definition` | yes | no | no — not read for the root |
| `contract` / `contract_version` / `schema_object` | yes | no | no |
| `port` / `port_version` / `port_contract` | yes | no | no |
| `transformation` / version / expression tree | yes | no | no |
| `execution_authority` / version / `execution_operation` / `operation_*` | yes | no | no |
| `namespace_owner` | yes | no | no — validation gate only |

The normalized contract/port/transformation/execution-authority rows exist to
satisfy `source.validate_model` (registration). Invocation reads the equivalent
meaning from the retained capsule JSON instead. So they are omitted by design in
the overhead-removed path.

## C. Gaps

None for invocation. Concretely verified against the planner's requirements:

- `capEntry.capability` resolves and its `capabilityId` equals the selected id.
- `feature` declares `@scenario`, `@input-contract`, `@event-authority`,
  `@outcome-contract`, `@outcome-terminal` matching the model rows.
- `executionAuthorities` contains the feature's `@event-authority` with the same
  `owningScenarioId`; its `invoke-port` port has an `interfaces.portBindings`
  entry bound to `sda-authority-transformation-port.v1`.
- `interfaces.contractCatalog` maps the feature's input/outcome contract ids to
  schema files, and `contractValidatorCapabilityId` is `sda-schema-contract-admission.v1`
  (present in the pinned registry `contractAdmissions`).
- `interfaces.interfaces[0]` declares the stdout binding `sda-json-cli.v1`.
- One `source_lineage` row resolves the capsule digest for the capability
  definition, which `capability-embodiment.sql` requires.

## D. Differences that do not matter

- Equity references its feature externally (`../../features/<id>.feature`);
  hello world references `capability.feature` inside the capability directory and
  also ships `features/<id>.feature`. Both resolve to a capsule entry.
- Equity carries a `blueprint.authority.json` and `projection-authorities`; the
  node planner ignores them.
- Equity has a multi-port effect circuit; hello world has the single
  transformation port that yields the payload.

## Conclusion

The hello world scaffold carries everything required to invoke through the
existing runtime, plus declarations the planner ignores. The reduction is safe
because the read path resolves execution meaning from the retained capsule, not
from the normalized tables that registration/validation writes.
