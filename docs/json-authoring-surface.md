# JSON authoring surface

Primary experience #1 ([target-experience.md](target-experience.md)): author and
manage deterministic capabilities through SQL **or** JSON, with complete
flexibility. This document records the installed JSON surface, its document
shape, the four properties it preserves, and how a JSON-authored capability is
installed and proven.

## The surface

One procedure:

```sql
EXEC model.declare_capability_document @document = N'{ ... }';
```

It writes nothing itself. Every row it causes is written by the procedures the
SQL surface already calls — `model.scaffold_capability`, `model.declare_contract`,
`model.declare_scenario`, `model.author_capability_meaning`,
`model.configure_interface` — so a JSON-authored capability and a SQL-authored
capability are the same rows. The document's shape never reaches a definition
envelope: `declare_scenario` builds its envelopes from named fields only, so the
digests do not record how the facts arrived.

## The document

`sidefx-capability-authority.v1`, one capability per document:

```json
{
  "document": "sidefx-capability-authority.v1",
  "capabilityId": "<id>",
  "meaning": { "intent": "…", "outcome": "…" },
  "cli": { "display": { "select": "outcome.payload", "as": "json" } },
  "contracts": [ { "id": "<contract id>", "schema": { } } ],
  "scenarios": [
    {
      "scenarioId": "<id>", "name": "…",
      "inputId": "…", "inputContract": "…",
      "eventId": "…", "eventAuthority": "…",
      "outcomeId": "…", "outcomeContract": "…",
      "terminal": true, "root": true,
      "given": "…", "when": "…", "then": "…",
      "operations":  [ { "operationId": "…", "kind": "invoke-port", "portId": "…" } ],
      "portBindings": [ { "portId": "…", "platformCapabilityId": "…",
                          "configuration": { "statement": "…", "resultColumn": "…" } } ]
    }
  ]
}
```

Every member is a payload an existing procedure already reads; no new authoring
vocabulary is introduced. `scenarios[*]` is the `@scenario` payload of
`declare_scenario` with its `@operations` and `@port_bindings` payloads carried
inside it. JSON-authoring is not a second meaning model; it is a second way to
hand the same facts to the same authoring procedures.

## The four properties, and where each lives

| property | where it lives |
|---|---|
| **idempotency** | the document's own SHA2_256 is recorded as the current `CAPABILITY_DOCUMENT` definition for the capability id. A second install of the same bytes returns `UNCHANGED` and writes nothing. The gate is required: `model.configure_interface` inserts definitions unconditionally and would violate the definition unique key on a replay. |
| **content-addressed digests** | every digest is still `HASHBYTES('SHA2_256', <canonical envelope bytes>)` computed by `model.put_semantic_definition`. The procedure computes exactly one digest of its own, over the document bytes, using the same recipe. |
| **current definition** | definitions are appended, never mutated, so `analysis.v_selected_semantic_definition` selects the newest per semantic object. The document ledger obeys the same rule. |
| **rollback preflight** | the document is carried by a `.sql` migration, so `scripts/invoke-from-transaction.mjs` applies it uncommitted, invokes the capability, and rolls back with no change to the boot. |

`@on_unchanged = 'REAPPLY'` forces the chain to run when a document must be
re-installed deliberately; the default `SKIP` returns `UNCHANGED`.

## How to author one

1. Write the document (start from `examples/json-authoring/`).
2. Put it in a migration under `sql/migrations/` and `EXEC
   model.declare_capability_document @document = N'{ … }';`, following the
   lifecycle in [sql/README.md](../sql/README.md): guard triggers dropped inside
   `BEGIN TRANSACTION`, final `ROLLBACK`, printing result sets.
3. Dry-run, then preflight the new capability uncommitted
   (`node --experimental-vm-modules scripts/invoke-from-transaction.mjs <file>
   <capabilityId> <input.json>`), then install (`COMMIT`) and invoke through the
   real CLI.

## Installed demonstrations

`sql/migrations/declare-json-authoring-surface.sql` installs two capabilities
from the documents in `examples/json-authoring/` and proves the properties:

- `count-declared-capabilities` — invokes to `{"declaredCapabilities": 304}`.
- `count-declared-contracts` — invokes to `{"declaredContracts": 761}`.

The migration's result sets show: the document ledger holds one digest per
capability; the JSON-authored rows carry the same profiles and the same port
standard as the SQL-authored `run-declared-query` (declared read, no
`providerId`); exactly one current definition exists per declared id; the graph
source sees both; replay reports `UNCHANGED` and mints no further capability
version.

## Limits and what remains

- The surface is SQL-side: a document is installed by a migration that calls the
  procedure. There is no `sfx capability declare --input @document.json` command
  and no JSON workspace reconstruction (the inverted projection,
  [target-experience.md](target-experience.md) item 2, remains a gap).
- A document declares one capability. Cross-capability composition is still an
  `invoke-scenario` operation, exactly as in the SQL surface.
- The bootstrap installer remains code ([target-architecture.md](target-architecture.md));
  the JSON surface installs meaning, not the boot.
