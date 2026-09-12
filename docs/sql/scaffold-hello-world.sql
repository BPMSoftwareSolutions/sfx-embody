-- scaffold-hello-world.sql
--
-- Minimal workshop scaffold: one capability whose meaning is the retained capsule
-- source, inserted directly into the CURRENT model. No generation, no validation,
-- no lineage-completeness, no publish.
--
-- Standard-output binding (traced, not invented):
--   interfaces.authority.json -> { kind: "cli", platformCapabilityId: "sda-json-cli.v1" }
--   platform provider: ScenarioKernel.NodePlatform.Interface.JsonCli
--   operation: deliverArtifact(outcome, destination = process.stdout)
-- The transformation port yields the payload; the sda-json-cli.v1 interface delivers it.
--
-- Requires docs/sql/remove-execution-dependence-overhead.sql to have been committed.
--
-- Same identity, changed message: re-run with the same @CapabilityId and a new
-- @Message. The retained content objects for the transformation and outcome schema
-- are added and the appearances are repointed, keeping content/reference/digest
-- consistency. A new @CapabilityId scaffolds another capability.
--
-- Default: ROLLBACK after verification. To install, replace the final ROLLBACK
-- with COMMIT and re-run.
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @CapabilityId nvarchar(120) = N'hello-world-sql';
DECLARE @Message nvarchar(4000) = N'Hello, World!';
DECLARE @InputId nvarchar(120) = N'hello-world-request';
DECLARE @InputContract nvarchar(160) = N'hello-world-request.v1';
DECLARE @OutcomeId nvarchar(120) = N'hello-world-greeting';
DECLARE @OutcomeContract nvarchar(160) = N'hello-world-greeting.v1';
DECLARE @PortId nvarchar(160) = @CapabilityId + N'-port';
DECLARE @TransformationId nvarchar(160) = @CapabilityId + N'-transform.v1';
DECLARE @EventAuthorityId nvarchar(160) = @CapabilityId + N'.v1';

DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @snap bigint = (SELECT estate_snapshot_pk FROM source.estate_model WHERE estate_model_pk = @model);
DECLARE @rule bigint = (SELECT TOP 1 mr.mapping_rule_pk FROM source.estate_model_rule mr WHERE mr.estate_model_pk = @model ORDER BY mr.mapping_rule_pk);
DECLARE @capsule binary(32), @prevCapsule binary(32), @manifest nvarchar(max), @appearance binary(32), @contentPk bigint;
DECLARE @path nvarchar(400), @entryId nvarchar(200), @bytes varbinary(max), @digest binary(32), @newPk bigint;
DECLARE @obs bigint, @capNs bigint, @scenarioNs bigint, @capSo bigint, @capSod bigint, @scnSo bigint, @scnSod bigint, @capPk bigint, @capVer bigint, @scnPk bigint, @scnVer bigint;
DECLARE @env nvarchar(max), @envBytes varbinary(max), @envDigest binary(32);
DECLARE @capText nvarchar(max), @featureText nvarchar(max), @workspaceText nvarchar(max), @execText nvarchar(max),
        @interfacesText nvarchar(max), @transText nvarchar(max), @fixturesText nvarchar(max), @outcomeSchemaText nvarchar(max);
DECLARE @b_cap varbinary(max), @d_cap binary(32);
DECLARE @b_featW varbinary(max), @d_featW binary(32);
DECLARE @b_feat varbinary(max), @d_feat binary(32);
DECLARE @b_ws varbinary(max), @d_ws binary(32);
DECLARE @b_exec varbinary(max), @d_exec binary(32);
DECLARE @b_iface varbinary(max), @d_iface binary(32);
DECLARE @b_trans varbinary(max), @d_trans binary(32);
DECLARE @b_fixtures varbinary(max), @d_fixtures binary(32);
DECLARE @b_graph varbinary(max), @d_graph binary(32);
DECLARE @b_catalog varbinary(max), @d_catalog binary(32);
DECLARE @b_inSchema varbinary(max), @d_inSchema binary(32);
DECLARE @b_outSchema varbinary(max), @d_outSchema binary(32);

IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;
IF @rule IS NULL THROW 51000, 'MODEL_MAPPING_RULE_NOT_FOUND', 1;

-- 1. Capability meaning. @CapabilityId and @Message are the only inputs.
SET @capText = N'{
  "capabilityId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'",
  "name": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'",
  "mode": "capability",
  "userStory": { "actor": "caller", "intent": "write a database-defined message to standard output", "outcome": "the caller observes the configured message" },
  "experience": { "experienceId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'.v1", "actor": "caller",
    "promise": "the configured message is delivered through the sda-json-cli.v1 standard-output interface",
    "observableConditions": [ { "conditionId": "message-delivered-to-standard-output" } ] },
  "rootScenarioId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'"
}';
SET @featureText =
  N'@capability:' + @CapabilityId + N'
' + N'@root-scenario:' + @CapabilityId + N'
' + N'Feature: Write the configured text to standard output
' + N'
' + N'  @scenario:' + @CapabilityId + N'
' + N'  @input:' + @InputId + N'
' + N'  @input-contract:' + @InputContract + N'
' + N'  @event:' + @CapabilityId + N'
' + N'  @event-authority:' + @EventAuthorityId + N'
' + N'  @outcome:' + @OutcomeId + N'
' + N'  @outcome-contract:' + @OutcomeContract + N'
' + N'  @outcome-terminal
' + N'  Scenario: Write the database-defined message
' + N'    Given the message configured in the database
' + N'    When the sda-json-cli.v1 standard-output interface executes with that message
' + N'    Then the caller observes the exact message on standard output
';
SET @workspaceText = N'{ "workspaceType": "consumer-workspace-authority.v1", "consumerId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'", "projectionTargets": [ "node" ],
  "capabilities": [ { "featureId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'.feature", "feature": "capability.feature", "capability": "capability.authority.json",
  "semanticGraph": "semantic-graph.authority.json", "executionAuthorities": "execution-authorities.authority.json", "interfaces": "interfaces.authority.json", "fixtures": "fixtures.authority.json" } ] }';
SET @execText = N'{ "authorityType": "execution-authorities.v1", "executionAuthorities": [ { "id": "' + STRING_ESCAPE(@EventAuthorityId, 'json') + N'", "owningScenarioId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'",
  "operations": [ { "kind": "invoke-port", "portId": "' + STRING_ESCAPE(@PortId, 'json') + N'" } ] } ] }';
SET @interfacesText = N'{ "interfaceAuthorityType": "consumer-interface-authority.v1", "contractValidatorCapabilityId": "sda-schema-contract-admission.v1", "contractCatalog": "contracts/contract-catalog.json",
  "interfaces": [ { "interfaceId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'-cli", "kind": "cli", "rootScenarioId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'", "platformCapabilityId": "sda-json-cli.v1", "projectionTargets": [ "node" ] } ],
  "portBindings": [ { "portId": "' + STRING_ESCAPE(@PortId, 'json') + N'", "platformCapabilityId": "sda-authority-transformation-port.v1",
    "configuration": { "transformationAuthorityRef": "semantic-transformation.authority.json", "transformationId": "' + STRING_ESCAPE(@TransformationId, 'json') + N'" } } ], "projectionBindings": [] }';
SET @transText = N'{ "authorityType": "semantic-transformation-authority.v1", "transformations": [ { "id": "' + STRING_ESCAPE(@TransformationId, 'json') + N'",
  "expression": { "op": "object", "fields": { "contractId": { "op": "literal", "value": "' + STRING_ESCAPE(@OutcomeContract, 'json') + N'" },
    "payload": { "op": "object", "fields": { "message": { "op": "literal", "value": "' + STRING_ESCAPE(@Message, 'json') + N'" } } } } } } ] }';
SET @fixturesText = N'{ "fixtureType": "consumer-capability-fixtures.v1", "fixtures": [ { "fixtureId": "writes-the-configured-message", "input": { "contractId": "' + STRING_ESCAPE(@InputContract, 'json') + N'", "payload": {} },
  "expected": { "disposition": "terminated", "terminalScenarioId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'", "scenarioSequence": [ "' + STRING_ESCAPE(@CapabilityId, 'json') + N'" ],
    "outcomeAssertions": [ { "conditionId": "exact-message", "path": "payload.message", "operator": "equals", "value": "' + STRING_ESCAPE(@Message, 'json') + N'" } ] } } ] }';
SET @outcomeSchemaText = N'{ "$schema": "https://json-schema.org/draft/2020-12/schema", "$id": "https://schemas.agentic-harness.local/contracts/hello-world-greeting.v1.schema.json",
  "type": "object", "additionalProperties": false, "required": [ "contractId", "payload" ],
  "properties": { "contractId": { "const": "hello-world-greeting.v1" }, "payload": { "type": "object", "additionalProperties": false, "required": [ "message" ],
    "properties": { "message": { "const": "' + STRING_ESCAPE(@Message, 'json') + N'" } } } } }';

-- 2. Encode each file once. The capsule digest is derived from these bytes.
SET @b_cap = CONVERT(varbinary(max), CONVERT(varchar(max), (@capText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_cap = HASHBYTES('SHA2_256', @b_cap);
SET @b_featW = CONVERT(varbinary(max), CONVERT(varchar(max), (@featureText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_featW = HASHBYTES('SHA2_256', @b_featW);
SET @b_feat = CONVERT(varbinary(max), CONVERT(varchar(max), (@featureText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_feat = HASHBYTES('SHA2_256', @b_feat);
SET @b_ws = CONVERT(varbinary(max), CONVERT(varchar(max), (@workspaceText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_ws = HASHBYTES('SHA2_256', @b_ws);
SET @b_exec = CONVERT(varbinary(max), CONVERT(varchar(max), (@execText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_exec = HASHBYTES('SHA2_256', @b_exec);
SET @b_iface = CONVERT(varbinary(max), CONVERT(varchar(max), (@interfacesText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_iface = HASHBYTES('SHA2_256', @b_iface);
SET @b_trans = CONVERT(varbinary(max), CONVERT(varchar(max), (@transText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_trans = HASHBYTES('SHA2_256', @b_trans);
SET @b_fixtures = CONVERT(varbinary(max), CONVERT(varchar(max), (@fixturesText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_fixtures = HASHBYTES('SHA2_256', @b_fixtures);
SET @b_graph = CONVERT(varbinary(max), CONVERT(varchar(max), (N'{ "transitions": [] }') COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_graph = HASHBYTES('SHA2_256', @b_graph);
SET @b_catalog = CONVERT(varbinary(max), CONVERT(varchar(max), (N'{
  "hello-world-request.v1": "input.schema.json",
  "hello-world-greeting.v1": "outcome.schema.json"
}
') COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_catalog = HASHBYTES('SHA2_256', @b_catalog);
SET @b_inSchema = CONVERT(varbinary(max), CONVERT(varchar(max), (N'{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://schemas.agentic-harness.local/contracts/hello-world-request.v1.schema.json",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "contractId",
    "payload"
  ],
  "properties": {
    "contractId": {
      "const": "hello-world-request.v1"
    },
    "payload": {
      "type": "object",
      "additionalProperties": false
    }
  }
}
') COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_inSchema = HASHBYTES('SHA2_256', @b_inSchema);
SET @b_outSchema = CONVERT(varbinary(max), CONVERT(varchar(max), (@outcomeSchemaText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_outSchema = HASHBYTES('SHA2_256', @b_outSchema);
SET @manifest = N'cap:' + LOWER(CONVERT(varchar(64), @d_cap, 2)) + CHAR(10) + N'featW:' + LOWER(CONVERT(varchar(64), @d_featW, 2)) + CHAR(10) + N'feat:' + LOWER(CONVERT(varchar(64), @d_feat, 2)) + CHAR(10) + N'ws:' + LOWER(CONVERT(varchar(64), @d_ws, 2)) + CHAR(10) + N'exec:' + LOWER(CONVERT(varchar(64), @d_exec, 2)) + CHAR(10) + N'iface:' + LOWER(CONVERT(varchar(64), @d_iface, 2)) + CHAR(10) + N'trans:' + LOWER(CONVERT(varchar(64), @d_trans, 2)) + CHAR(10) + N'fixtures:' + LOWER(CONVERT(varchar(64), @d_fixtures, 2)) + CHAR(10) + N'graph:' + LOWER(CONVERT(varchar(64), @d_graph, 2)) + CHAR(10) + N'catalog:' + LOWER(CONVERT(varchar(64), @d_catalog, 2)) + CHAR(10) + N'inSchema:' + LOWER(CONVERT(varchar(64), @d_inSchema, 2)) + CHAR(10) + N'outSchema:' + LOWER(CONVERT(varchar(64), @d_outSchema, 2));
SET @capsule = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (@manifest) COLLATE Latin1_General_100_BIN2_UTF8)));

-- 3. Content objects are content-addressed and inserted when absent.
BEGIN TRANSACTION;
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_cap) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_cap, @b_cap, DATALENGTH(@b_cap));
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_featW) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_featW, @b_featW, DATALENGTH(@b_featW));
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_feat) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_feat, @b_feat, DATALENGTH(@b_feat));
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_ws) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_ws, @b_ws, DATALENGTH(@b_ws));
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_exec) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_exec, @b_exec, DATALENGTH(@b_exec));
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_iface) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_iface, @b_iface, DATALENGTH(@b_iface));
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_trans) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_trans, @b_trans, DATALENGTH(@b_trans));
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_fixtures) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_fixtures, @b_fixtures, DATALENGTH(@b_fixtures));
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_graph) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_graph, @b_graph, DATALENGTH(@b_graph));
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_catalog) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_catalog, @b_catalog, DATALENGTH(@b_catalog));
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_inSchema) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_inSchema, @b_inSchema, DATALENGTH(@b_inSchema));
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_outSchema) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_outSchema, @b_outSchema, DATALENGTH(@b_outSchema));

-- A prior identity for this @CapabilityId makes this a message change, not a create.
SELECT @prevCapsule = a.capsule_digest FROM source.source_appearance a
  WHERE a.source_path = N'capabilities/' + @CapabilityId + N'/capability.authority.json'
  ORDER BY a.source_appearance_pk DESC;

IF @prevCapsule IS NULL
BEGIN
  -- Create: appearances, declaration, selection rows and the one lineage row.
  SET @path = N'capabilities/' + @CapabilityId + N'/capability.authority.json'; SET @entryId = N'capability.authority.json'; SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_cap, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
    VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_cap), @appearance, @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);
  SET @path = N'capabilities/' + @CapabilityId + N'/capability.feature'; SET @entryId = N'features/{id}.feature.workspace-alias'; SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_featW, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
    VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_featW), @appearance, @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);
  SET @path = N'features/' + @CapabilityId + N'.feature'; SET @entryId = N'features/{id}.feature'; SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_feat, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
    VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_feat), @appearance, @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);
  SET @path = N'capabilities/' + @CapabilityId + N'/consumer-workspace.authority.json'; SET @entryId = N'consumer-workspace.authority.json'; SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_ws, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
    VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_ws), @appearance, @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);
  SET @path = N'capabilities/' + @CapabilityId + N'/execution-authorities.authority.json'; SET @entryId = N'execution-authorities.authority.json'; SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_exec, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
    VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_exec), @appearance, @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);
  SET @path = N'capabilities/' + @CapabilityId + N'/interfaces.authority.json'; SET @entryId = N'interfaces.authority.json'; SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_iface, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
    VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_iface), @appearance, @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);
  SET @path = N'capabilities/' + @CapabilityId + N'/semantic-transformation.authority.json'; SET @entryId = N'semantic-transformation.authority.json'; SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_trans, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
    VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_trans), @appearance, @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);
  SET @path = N'capabilities/' + @CapabilityId + N'/fixtures.authority.json'; SET @entryId = N'fixtures.authority.json'; SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_fixtures, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
    VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_fixtures), @appearance, @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);
  SET @path = N'capabilities/' + @CapabilityId + N'/semantic-graph.authority.json'; SET @entryId = N'semantic-graph.authority.json'; SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_graph, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
    VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_graph), @appearance, @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);
  SET @path = N'capabilities/' + @CapabilityId + N'/contracts/contract-catalog.json'; SET @entryId = N'contracts/contract-catalog.json'; SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_catalog, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
    VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_catalog), @appearance, @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);
  SET @path = N'capabilities/' + @CapabilityId + N'/contracts/input.schema.json'; SET @entryId = N'contracts/input.schema.json'; SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_inSchema, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
    VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_inSchema), @appearance, @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);
  SET @path = N'capabilities/' + @CapabilityId + N'/contracts/outcome.schema.json'; SET @entryId = N'contracts/outcome.schema.json'; SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_outSchema, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
    VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_outSchema), @appearance, @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);

  INSERT source.source_observation (source_appearance_pk, locator, locator_digest, observation_kind, presence_state, observed_value_content_pk)
    SELECT TOP 1 a.source_appearance_pk, N'', HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (N'') COLLATE Latin1_General_100_BIN2_UTF8))), 'DECLARATION', 'PRESENT', a.content_object_pk
    FROM source.source_appearance a WHERE a.capsule_digest=@capsule AND a.source_path=N'capabilities/' + @CapabilityId + N'/capability.authority.json';
  SET @obs = SCOPE_IDENTITY();
  INSERT source.declaration_observation (source_observation_pk, declared_kind, declared_id, namespace_text, observation_kind)
    VALUES (@obs, 'CAPABILITY', @CapabilityId, N'sidefx:capabilities', 'DECLARATION');

  SELECT @capNs = namespace_pk FROM model.identity_namespace WHERE namespace_kind='CAPABILITY' AND namespace_id=N'sidefx:capabilities';
  IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='SCENARIO' AND namespace_id=N'owner:scenario:' + @CapabilityId)
    INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('SCENARIO', N'owner:scenario:' + @CapabilityId);
  SELECT @scenarioNs = namespace_pk FROM model.identity_namespace WHERE namespace_kind='SCENARIO' AND namespace_id=N'owner:scenario:' + @CapabilityId;

  SET @env = N'{ "address": { "id": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'", "kind": "CAPABILITY", "namespace": "sidefx:capabilities" }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": "' + LOWER(CONVERT(varchar(64), @capsule, 2)) + N'" } }';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8));
  SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@envDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES ('CAPABILITY', @capNs, @CapabilityId); SET @capSo = SCOPE_IDENTITY();
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@capSo, 'CAPABILITY', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@envDigest)); SET @capSod = SCOPE_IDENTITY();
  INSERT model.capability (namespace_pk, capability_id, semantic_object_pk, object_kind) VALUES (@capNs, @CapabilityId, @capSo, 'CAPABILITY'); SET @capPk = SCOPE_IDENTITY();
  INSERT model.capability_version (capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@capPk, @capSo, @capSod, @envDigest, @CapabilityId, 'CAPABILITY', @capSod, N''); SET @capVer = SCOPE_IDENTITY();
  INSERT model.estate_capability (estate_model_pk, capability_pk, capability_version_pk, semantic_object_definition_pk) VALUES (@model, @capPk, @capVer, @capSod);

  SET @env = N'{ "address": { "id": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'", "kind": "SCENARIO", "namespace": "owner:scenario:' + STRING_ESCAPE(@CapabilityId, 'json') + N'" }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": "' + LOWER(CONVERT(varchar(64), @capsule, 2)) + N'" } }';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8));
  SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@envDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES ('SCENARIO', @scenarioNs, @CapabilityId); SET @scnSo = SCOPE_IDENTITY();
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@scnSo, 'SCENARIO', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@envDigest)); SET @scnSod = SCOPE_IDENTITY();
  INSERT model.scenario (namespace_pk, scenario_id, semantic_object_pk, object_kind, capability_pk) VALUES (@scenarioNs, @CapabilityId, @scnSo, 'SCENARIO', @capPk); SET @scnPk = SCOPE_IDENTITY();
  INSERT model.scenario_version (scenario_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, source_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@scnPk, @scnSo, @scnSod, @envDigest, @CapabilityId, 'managed-feature-tags.v1', 'SCENARIO', @scnSod, N''); SET @scnVer = SCOPE_IDENTITY();
  INSERT model.capability_scenario (capability_pk, capability_version_pk, scenario_pk, scenario_version_pk, _owner_definition_pk, _canonical_pointer)
    VALUES (@capPk, @capVer, @scnPk, @scnVer, @capSod, N'/semantics/scenario_members/' + @CapabilityId);
  INSERT model.capability_root_scenario (capability_version_pk, scenario_pk, _owner_definition_pk, _canonical_pointer) VALUES (@capVer, @scnPk, @capSod, N'');

  INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
    VALUES (@capSod, 'capability_version', N'', @obs, @rule, 'DECLARATION');
  SELECT '0_BRANCH' AS result_set, 'CREATE' AS branch;
END
ELSE
BEGIN
  -- Change: repoint the message-bearing appearances at the new content objects.
  SELECT @scnVer = sv.scenario_version_pk, @scnPk = sv.scenario_pk
  FROM model.capability c JOIN model.capability_version cv ON cv.capability_pk=c.capability_pk
  JOIN model.capability_scenario cs ON cs.capability_version_pk=cv.capability_version_pk
  JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
  WHERE c.capability_id=@CapabilityId;
  SET @path = N'capabilities/' + @CapabilityId + N'/semantic-transformation.authority.json';
  SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @prevCapsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_trans, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  UPDATE source.source_appearance SET content_object_pk=(SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_trans), appearance_digest=@appearance
    WHERE capsule_digest=@prevCapsule AND source_path=@path;
  SET @path = N'capabilities/' + @CapabilityId + N'/contracts/outcome.schema.json';
  SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @prevCapsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_outSchema, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
  UPDATE source.source_appearance SET content_object_pk=(SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_outSchema), appearance_digest=@appearance
    WHERE capsule_digest=@prevCapsule AND source_path=@path;
  IF @scnVer IS NOT NULL UPDATE model.scenario_outcome SET experience = N'the configured message is delivered to standard output' WHERE scenario_version_pk=@scnVer;
  SELECT '0_BRANCH' AS result_set, 'UPDATE_MESSAGE' AS branch;
END

-- 4. Verification: reads the stored binding and stored content, not constants.
SELECT '1_CAPABILITY' AS result_set, c.capability_id, cv.capability_version_pk, ec.estate_model_pk
FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk=ec.capability_pk JOIN model.capability_version cv ON cv.capability_version_pk=ec.capability_version_pk
WHERE ec.estate_model_pk=@model AND c.capability_id=@CapabilityId;
SELECT '2_STDOUT_BINDING' AS result_set,
  JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), c.content_bytes)), '$.interfaces[0].platformCapabilityId') AS platform_capability,
  JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), c.content_bytes)), '$.interfaces[0].kind') AS interface_kind,
  JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), c.content_bytes)), '$.portBindings[0].platformCapabilityId') AS payload_port,
  a.source_path
FROM source.source_appearance a JOIN source.content_object c ON c.content_object_pk=a.content_object_pk
WHERE a.source_path = N'capabilities/' + @CapabilityId + N'/interfaces.authority.json';
SELECT '3_PLATFORM_PROVIDER' AS result_set, declared_id, object_kind FROM analysis.v_selected_semantic_definition WHERE declared_id='sda-json-cli.v1';
SELECT '4_MESSAGE' AS result_set,
  JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), c.content_bytes)), '$.transformations[0].expression.fields.payload.fields.message.value') AS stored_message, a.source_path
FROM source.source_appearance a JOIN source.content_object c ON c.content_object_pk=a.content_object_pk
WHERE a.source_path = N'capabilities/' + @CapabilityId + N'/semantic-transformation.authority.json';
SELECT '5_LINEAGE' AS result_set, COUNT(*) AS lineage_rows FROM source.source_lineage l
JOIN model.estate_capability ec ON ec.semantic_object_definition_pk=l.semantic_object_definition_pk
JOIN model.capability c ON c.capability_pk=ec.capability_pk
WHERE ec.estate_model_pk=@model AND c.capability_id=@CapabilityId;

-- Default: inspect, then choose.
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.

