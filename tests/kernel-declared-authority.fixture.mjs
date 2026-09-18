import { DATA_ACCESS_AUTHORITY_GROUND_READ } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/data-access.mjs';

// Test support for the kernel boot's declared authorities. At runtime both
// documents are database rows, installed by
// sfx-embody/sql/migrations/declare-kernel-boot-authority-rows.sql and resolved
// by the kernel's ground read and declared provider-authority read. These
// fixtures reproduce those documents so the kernel seams can be unit-tested
// without a database; the statements are the retained authority's own read
// statements.
export const COMMAND_OPERATIONS = Object.freeze({
  "operations": {
    "invoke": {
      "object": "capability",
      "subject": true,
      "input": "required",
      "inputType": true,
      "display": true
    },
    "observe": {
      "object": "capability",
      "subject": true,
      "input": "required",
      "inputType": true,
      "display": true,
      "observationAltitudes": true,
      "formats": true
    },
    "circuit": {
      "object": "capability",
      "subject": true,
      "input": "optional",
      "scenario": true,
      "reader": "read-retained-publication"
    },
    "reveal": {
      "object": "capability",
      "subject": true,
      "input": "optional",
      "scenario": true,
      "views": [
        "circuit",
        "meaning"
      ],
      "formats": [
        "text",
        "markdown"
      ],
      "readers": {
        "meaning": "read-capability-meaning",
        "circuit": "read-retained-publication"
      }
    },
    "catalogue": {
      "object": "capability",
      "subject": false,
      "input": "rejected",
      "reader": "list-capabilities"
    },
    "list": {
      "object": "capability",
      "subject": false,
      "input": "rejected",
      "reader": "list-capabilities"
    },
    "find": {
      "object": "capability",
      "subject": false,
      "input": "rejected",
      "query": true,
      "reader": "list-capabilities"
    },
    "artifact": {
      "object": "media",
      "subject": true,
      "input": "rejected",
      "reader": "read-retained-publication"
    }
  },
  "defaultView": "meaning",
  "defaultFormat": "text"
});

export const DATA_ACCESS_AUTHORITY = Object.freeze({
  "dataAccessType": "node-boot-data-access-authority.v1",
  "authorityId": "sda-node-boot-data-access.v1",
  "reads": [
    {
      "readId": "capability-authority",
      "sourceKind": "tsql",
      "statement": "\nSELECT g.capability_id,\n       g.root_scenario_id AS scenario_id,\n       g.namespace_id, g.graph_source, g.cli_configuration, g.documents\nFROM analysis.capability_graph_source(\n  CONVERT(nvarchar(400), JSON_VALUE(@input, '$.capabilityId')),\n  CONVERT(bit, JSON_VALUE(@input, '$.includeDocuments')),\n  CONVERT(nvarchar(400), JSON_VALUE(@input, '$.namespaceId'))) g\nWHERE g.estate_model_pk = @estate_model_pk\n  AND (JSON_VALUE(@input, '$.namespaceId') IS NULL OR g.namespace_id = JSON_VALUE(@input, '$.namespaceId'));"
    },
    {
      "readId": "capability-closure",
      "sourceKind": "tsql",
      "statement": "\nDECLARE @capability_id nvarchar(4000)=JSON_VALUE(@input,'$.capabilityId'),\n        @scenario_id nvarchar(4000)=JSON_VALUE(@input,'$.scenarioId'),\n        @namespace_id nvarchar(4000)=JSON_VALUE(@input,'$.namespaceId');\nDECLARE @matches bigint,@capability_version_pk bigint,@scenario_version_pk bigint;\nSELECT @matches=COUNT_BIG(*),@capability_version_pk=MAX(ec.capability_version_pk)\nFROM model.estate_capability ec\nJOIN model.capability c ON c.capability_pk=ec.capability_pk\nJOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk\nWHERE ec.estate_model_pk=@estate_model_pk AND c.capability_id=@capability_id\n  AND (@namespace_id IS NULL OR n.namespace_id=@namespace_id);\nIF @matches=0 THROW 51000,'CAPABILITY_NOT_FOUND',1;\nIF @matches<>1 THROW 51000,'CAPABILITY_NAMESPACE_AMBIGUOUS',1;\nSELECT @matches=COUNT_BIG(*),@scenario_version_pk=MAX(cs.scenario_version_pk)\nFROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk\nWHERE cs.capability_version_pk=@capability_version_pk AND s.scenario_id=@scenario_id;\nIF @matches=0 THROW 51000,'SCENARIO_NOT_IN_CAPABILITY',1;\nIF @matches<>1 THROW 51000,'SCENARIO_NAMESPACE_AMBIGUOUS',1;\nSELECT DISTINCT s.scenario_id AS downstream_scenario_id,cl.minimum_depth,cl.cycle_detected,\n       sc.capability_id AS owning_capability_id,\n       i.input_id,e.event_id,e.responsibility,o.outcome_id,sv.definition_digest AS scenario_definition_digest\nFROM analysis.v_scenario_invocation_closure cl\nJOIN model.scenario_version sv ON sv.scenario_version_pk=cl.downstream_scenario_version_pk\nJOIN model.scenario s ON s.scenario_pk=sv.scenario_pk\nJOIN model.capability sc ON sc.capability_pk=s.capability_pk\nLEFT JOIN model.scenario_input i ON i.scenario_version_pk=sv.scenario_version_pk\nLEFT JOIN model.scenario_event e ON e.scenario_version_pk=sv.scenario_version_pk\nLEFT JOIN model.scenario_outcome o ON o.scenario_version_pk=sv.scenario_version_pk\nWHERE cl.capability_version_pk=@capability_version_pk AND cl.selected_scenario_version_pk=@scenario_version_pk\nORDER BY cl.minimum_depth,s.scenario_id\nOPTION(MAXRECURSION 32767);"
    },
    {
      "readId": "mechanic-definitions",
      "sourceKind": "tsql",
      "statement": "SELECT definition_json FROM analysis.v_selected_semantic_definition\nWHERE estate_model_pk=@estate_model_pk AND object_kind='MECHANIC'"
    },
    {
      "readId": "execution-delivery",
      "sourceKind": "tsql",
      "statement": "SELECT declared_id AS provider_id,\n    JSON_QUERY(definition_json,'$.semantics.executionDelivery') AS configuration\n    FROM analysis.v_selected_semantic_definition\n    WHERE estate_model_pk=@estate_model_pk AND object_kind='PROVIDER'\n      AND JSON_QUERY(definition_json,'$.semantics.executionDelivery') IS NOT NULL;\n    SELECT JSON_VALUE(definition_json,'$.semantics.configuration.defaultTarget') AS default_target\n    FROM analysis.v_selected_semantic_definition\n    WHERE estate_model_pk=@estate_model_pk AND object_kind='PORT'\n      AND namespace_id='sidefx:capability:read-capability-authority'\n      AND declared_id='read-capability-authority-port';"
    }
  ]
});

// The kernel's single fixed ground read resolves the fixture document, exactly
// as the database row resolves the installed authority.
export function withDeclaredGroundRead(query) {
  return async (statement, options) => {
    if (statement === DATA_ACCESS_AUTHORITY_GROUND_READ) {
      return { recordsets: [[{ content_bytes: { base64: Buffer.from(JSON.stringify(DATA_ACCESS_AUTHORITY)).toString('base64') } }]] };
    }
    return await query(statement, options);
  };
}
