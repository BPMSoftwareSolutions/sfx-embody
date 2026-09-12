-- scaffold-hello-world.sql
--
-- Parameterized SQL scaffold for an executable Hello World capability.
--
-- Standard-output binding (traced, not invented):
--   platform capability : sda-json-cli.v1   (kind interface-delivery)
--   provider            : ScenarioKernel.NodePlatform.Interface.JsonCli
--   operation           : deliverArtifact(outcome, destination = process.stdout)
-- A capability declares it in interfaces.authority.json as
--   { "kind": "cli", "platformCapabilityId": "sda-json-cli.v1" }
-- This scaffold reuses that established binding. The unchanged CLI invokes the
-- capability and the outcome is delivered to stdout.
--
-- Lifecycle: the selected model is PUBLISHED and its membership is immutable, so
-- the supported SQL path creates a new BUILDING generation carrying the current
-- membership and publishes it. No Harness managed admission is involved.
--
-- Re-run behavior: if @CapabilityId already exists, its prior membership is
-- replaced (superseded) in the new generation, so changing @Message and re-running
-- delivers the changed message under the same identity.
--
-- Default: ROLLBACK after verification. To install, replace the final ROLLBACK
-- with the two commented lines and re-run. After install:
--   sfx capability invoke <@CapabilityId> --input '{"contractId":"hello-world-request.v1","payload":{}}'
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

DECLARE @from bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @snap bigint = (SELECT estate_snapshot_pk FROM source.estate_model WHERE estate_model_pk = @from);
DECLARE @capsule binary(32) = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (N'sfx-hello-world-capsule:' + @CapabilityId) COLLATE Latin1_General_100_BIN2_UTF8)));
DECLARE @path nvarchar(400), @entryId nvarchar(200), @bytes varbinary(max), @digest binary(32), @appearance binary(32), @v varbinary(max);
DECLARE @rule bigint, @model bigint, @obs bigint, @capPk bigint, @prevCapPk bigint, @capNs bigint;
DECLARE @contractNs bigint, @portNs bigint, @transNs bigint, @eaNs bigint,
        @scenarioNs bigint, @inputNs bigint, @eventNs bigint, @outcomeNs bigint;
DECLARE @capSo bigint, @capSod bigint, @inContractSo bigint, @inContractSod bigint,
        @outContractSo bigint, @outContractSod bigint, @portSo bigint, @portSod bigint,
        @transSo bigint, @transSod bigint, @eaSo bigint, @eaSod bigint,
        @scnSo bigint, @scnSod bigint, @inSo bigint, @inSod bigint,
        @evSo bigint, @evSod bigint, @outSo bigint, @outSod bigint;
DECLARE @capVer bigint, @inContractPk bigint, @inContractVer bigint, @outContractPk bigint,
        @outContractVer bigint, @portPk bigint, @portVer bigint, @transPk bigint, @transVer bigint,
        @eaPk bigint, @eaVer bigint, @scnPk bigint, @scnVer bigint, @inOp bigint, @n0 bigint, @n1 bigint, @n2 bigint, @n3 bigint;
DECLARE @env nvarchar(max), @envBytes varbinary(max), @envDigest binary(32);
DECLARE @schemaBytes varbinary(max), @schemaDigest binary(32);
DECLARE @capText nvarchar(max), @featureText nvarchar(max), @workspaceText nvarchar(max),
        @execText nvarchar(max), @interfacesText nvarchar(max), @transText nvarchar(max),
        @fixturesText nvarchar(max), @outcomeSchemaText nvarchar(max);
DECLARE @retire TABLE (sod bigint);

IF @from IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;
IF NOT EXISTS (SELECT 1 FROM source.mapping_rule WHERE rule_id = N'sidefx-capability-provisioning.v1') THROW 51000, 'PROVISIONING_RULE_NOT_FOUND', 1;

-- 1. Readable capability meaning; @CapabilityId and @Message are the only inputs.
SET @capText = N'{
  "capabilityId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'",
  "name": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'",
  "mode": "capability",
  "userStory": {
    "actor": "caller",
    "intent": "write a database-defined message to standard output",
    "outcome": "the caller observes the configured message"
  },
  "experience": {
    "experienceId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'.v1",
    "actor": "caller",
    "promise": "the configured message is delivered to the caller through the sda-json-cli.v1 standard-output interface",
    "observableConditions": [ { "conditionId": "message-delivered-to-standard-output" } ]
  },
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
SET @workspaceText = N'{
  "workspaceType": "consumer-workspace-authority.v1",
  "consumerId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'",
  "projectionTargets": [ "node" ],
  "capabilities": [ {
    "featureId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'.feature",
    "feature": "capability.feature",
    "capability": "capability.authority.json",
    "semanticGraph": "semantic-graph.authority.json",
    "executionAuthorities": "execution-authorities.authority.json",
    "interfaces": "interfaces.authority.json",
    "fixtures": "fixtures.authority.json"
  } ]
}';
SET @execText = N'{
  "authorityType": "execution-authorities.v1",
  "executionAuthorities": [ {
    "id": "' + STRING_ESCAPE(@EventAuthorityId, 'json') + N'",
    "owningScenarioId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'",
    "operations": [ { "kind": "invoke-port", "portId": "' + STRING_ESCAPE(@PortId, 'json') + N'" } ]
  } ]
}';
SET @interfacesText = N'{
  "interfaceAuthorityType": "consumer-interface-authority.v1",
  "contractValidatorCapabilityId": "sda-schema-contract-admission.v1",
  "contractCatalog": "contracts/contract-catalog.json",
  "interfaces": [ {
    "interfaceId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'-cli",
    "kind": "cli",
    "rootScenarioId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'",
    "platformCapabilityId": "sda-json-cli.v1",
    "projectionTargets": [ "node" ]
  } ],
  "portBindings": [ {
    "portId": "' + STRING_ESCAPE(@PortId, 'json') + N'",
    "platformCapabilityId": "sda-authority-transformation-port.v1",
    "configuration": { "transformationAuthorityRef": "semantic-transformation.authority.json", "transformationId": "' + STRING_ESCAPE(@TransformationId, 'json') + N'" }
  } ],
  "projectionBindings": []
}';
SET @transText = N'{
  "authorityType": "semantic-transformation-authority.v1",
  "transformations": [ {
    "id": "' + STRING_ESCAPE(@TransformationId, 'json') + N'",
    "expression": { "op": "object", "fields": {
      "contractId": { "op": "literal", "value": "' + STRING_ESCAPE(@OutcomeContract, 'json') + N'" },
      "payload": { "op": "object", "fields": { "message": { "op": "literal", "value": "' + STRING_ESCAPE(@Message, 'json') + N'" } } }
    } }
  } ]
}';
SET @fixturesText = N'{
  "fixtureType": "consumer-capability-fixtures.v1",
  "fixtures": [ {
    "fixtureId": "writes-the-configured-message",
    "input": { "contractId": "' + STRING_ESCAPE(@InputContract, 'json') + N'", "payload": {} },
    "expected": { "disposition": "terminated", "terminalScenarioId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'", "scenarioSequence": [ "' + STRING_ESCAPE(@CapabilityId, 'json') + N'" ],
      "outcomeAssertions": [ { "conditionId": "exact-message", "path": "payload.message", "operator": "equals", "value": "' + STRING_ESCAPE(@Message, 'json') + N'" } ] }
  } ]
}';
SET @outcomeSchemaText = N'{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://schemas.agentic-harness.local/contracts/hello-world-greeting.v1.schema.json",
  "type": "object",
  "additionalProperties": false,
  "required": [ "contractId", "payload" ],
  "properties": {
    "contractId": { "const": "hello-world-greeting.v1" },
    "payload": { "type": "object", "additionalProperties": false, "required": [ "message" ], "properties": { "message": { "const": "' + STRING_ESCAPE(@Message, 'json') + N'" } } }
  }
}';

BEGIN TRANSACTION;

-- 2. Generation: BUILDING model carrying current membership (superseded excluded).
SELECT @rule = mapping_rule_pk FROM source.mapping_rule WHERE rule_id = N'sidefx-capability-provisioning.v1';
SELECT @prevCapPk = c.capability_pk FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
  WHERE n.namespace_id = N'sidefx:capabilities' AND c.capability_id = @CapabilityId;
IF @prevCapPk IS NOT NULL
BEGIN
  INSERT @retire SELECT cv.semantic_object_definition_pk FROM model.estate_capability ec JOIN model.capability_version cv ON cv.capability_version_pk = ec.capability_version_pk WHERE ec.estate_model_pk = @from AND ec.capability_pk = @prevCapPk;
  INSERT @retire SELECT sv.semantic_object_definition_pk FROM model.estate_capability ec JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk JOIN model.scenario_version sv ON sv.scenario_version_pk = cs.scenario_version_pk WHERE ec.estate_model_pk = @from AND ec.capability_pk = @prevCapPk;
  INSERT @retire SELECT i.semantic_object_definition_pk FROM model.estate_capability ec JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk JOIN model.scenario_input i ON i.scenario_version_pk = cs.scenario_version_pk WHERE ec.estate_model_pk = @from AND ec.capability_pk = @prevCapPk;
  INSERT @retire SELECT e.semantic_object_definition_pk FROM model.estate_capability ec JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk JOIN model.scenario_event e ON e.scenario_version_pk = cs.scenario_version_pk WHERE ec.estate_model_pk = @from AND ec.capability_pk = @prevCapPk;
  INSERT @retire SELECT o.semantic_object_definition_pk FROM model.estate_capability ec JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk JOIN model.scenario_outcome o ON o.scenario_version_pk = cs.scenario_version_pk WHERE ec.estate_model_pk = @from AND ec.capability_pk = @prevCapPk;
END
INSERT source.estate_model (estate_snapshot_pk, mapping_manifest_digest, publication_state)
  VALUES (@snap, HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (N'hello-world-generation:' + @CapabilityId) COLLATE Latin1_General_100_BIN2_UTF8))), 'BUILDING');
SET @model = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk)
  SELECT @model, semantic_object_definition_pk FROM model.estate_definition WHERE estate_model_pk = @from
    AND semantic_object_definition_pk NOT IN (SELECT sod FROM @retire);
INSERT model.estate_capability (estate_model_pk, capability_pk, capability_version_pk, semantic_object_definition_pk)
  SELECT @model, capability_pk, capability_version_pk, semantic_object_definition_pk FROM model.estate_capability
  WHERE estate_model_pk = @from AND capability_pk <> ISNULL(@prevCapPk, 0);
INSERT source.estate_model_rule (estate_model_pk, mapping_rule_pk)
  SELECT @model, mapping_rule_pk FROM source.estate_model_rule WHERE estate_model_pk = @from;

-- 3. Retained capsule source: the read path resolves authority from it.


SET @path = N'capabilities/' + @CapabilityId + N'/capability.authority.json'; SET @entryId = N'capability.authority.json';
SET @bytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@capText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @digest = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @digest, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
  VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest), @appearance,
          @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);
INSERT source.source_observation (source_appearance_pk, locator, locator_digest, observation_kind, presence_state, observed_value_content_pk)
  VALUES (SCOPE_IDENTITY(), N'', HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), N'' COLLATE Latin1_General_100_BIN2_UTF8))), 'DECLARATION', 'PRESENT',
          (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest));
SET @obs = SCOPE_IDENTITY();
INSERT source.declaration_observation (source_observation_pk, declared_kind, declared_id, namespace_text, observation_kind)
  VALUES (@obs, 'CAPABILITY', @CapabilityId, N'sidefx:capabilities', 'DECLARATION');

SET @path = N'capabilities/' + @CapabilityId + N'/capability.feature'; SET @entryId = N'features/{id}.feature.workspace-alias';
SET @bytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@featureText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @digest = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @digest, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
  VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest), @appearance,
          @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);

SET @path = N'features/' + @CapabilityId + N'.feature'; SET @entryId = N'features/{id}.feature';
SET @bytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@featureText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @digest = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @digest, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
  VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest), @appearance,
          @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);

SET @path = N'capabilities/' + @CapabilityId + N'/consumer-workspace.authority.json'; SET @entryId = N'consumer-workspace.authority.json';
SET @bytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@workspaceText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @digest = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @digest, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
  VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest), @appearance,
          @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);

SET @path = N'capabilities/' + @CapabilityId + N'/execution-authorities.authority.json'; SET @entryId = N'execution-authorities.authority.json';
SET @bytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@execText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @digest = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @digest, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
  VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest), @appearance,
          @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);

SET @path = N'capabilities/' + @CapabilityId + N'/interfaces.authority.json'; SET @entryId = N'interfaces.authority.json';
SET @bytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@interfacesText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @digest = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @digest, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
  VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest), @appearance,
          @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);

SET @path = N'capabilities/' + @CapabilityId + N'/semantic-transformation.authority.json'; SET @entryId = N'semantic-transformation.authority.json';
SET @bytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@transText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @digest = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @digest, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
  VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest), @appearance,
          @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);

SET @path = N'capabilities/' + @CapabilityId + N'/fixtures.authority.json'; SET @entryId = N'fixtures.authority.json';
SET @bytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@fixturesText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @digest = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @digest, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
  VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest), @appearance,
          @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);

SET @path = N'capabilities/' + @CapabilityId + N'/semantic-graph.authority.json'; SET @entryId = N'semantic-graph.authority.json';
SET @bytes = CONVERT(varbinary(max), CONVERT(varchar(max), (N'{ "transitions": [] }') COLLATE Latin1_General_100_BIN2_UTF8));
SET @digest = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @digest, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
  VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest), @appearance,
          @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);

SET @path = N'capabilities/' + @CapabilityId + N'/contracts/contract-catalog.json'; SET @entryId = N'contracts/contract-catalog.json';
SET @bytes = CONVERT(varbinary(max), CONVERT(varchar(max), (N'{
  "hello-world-request.v1": "input.schema.json",
  "hello-world-greeting.v1": "outcome.schema.json"
}
') COLLATE Latin1_General_100_BIN2_UTF8));
SET @digest = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @digest, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
  VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest), @appearance,
          @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);

SET @path = N'capabilities/' + @CapabilityId + N'/contracts/input.schema.json'; SET @entryId = N'contracts/input.schema.json';
SET @bytes = CONVERT(varbinary(max), CONVERT(varchar(max), (N'{
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
SET @digest = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @digest, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
  VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest), @appearance,
          @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);

SET @path = N'capabilities/' + @CapabilityId + N'/contracts/outcome.schema.json'; SET @entryId = N'contracts/outcome.schema.json';
SET @bytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@outcomeSchemaText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @digest = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
SET @appearance = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @digest, 2))) COLLATE Latin1_General_100_BIN2_UTF8)));
INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
  VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest), @appearance,
          @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);

-- 4. Normalized records required by validation and the read path.
DECLARE @contractNsId nvarchar(400) = N'sidefx:capability:' + @CapabilityId;
DECLARE @scenarioNsId nvarchar(400) = N'owner:scenario:' + @CapabilityId;
DECLARE @inputNsId nvarchar(400) = N'owner:input:' + @CapabilityId;
DECLARE @eventNsId nvarchar(400) = N'owner:event:' + @CapabilityId;
DECLARE @outcomeNsId nvarchar(400) = N'owner:outcome:' + @CapabilityId;
IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='CAPABILITY' AND namespace_id=N'sidefx:capabilities')
  THROW 51000, 'CAPABILITY_NAMESPACE_NOT_FOUND', 1;
SELECT @capNs = namespace_pk FROM model.identity_namespace WHERE namespace_kind='CAPABILITY' AND namespace_id=N'sidefx:capabilities';
IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='CONTRACT' AND namespace_id=@contractNsId) INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('CONTRACT', @contractNsId);
SELECT @contractNs = namespace_pk FROM model.identity_namespace WHERE namespace_kind='CONTRACT' AND namespace_id=@contractNsId;
IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='PORT' AND namespace_id=@contractNsId) INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('PORT', @contractNsId);
SELECT @portNs = namespace_pk FROM model.identity_namespace WHERE namespace_kind='PORT' AND namespace_id=@contractNsId;
IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='TRANSFORMATION' AND namespace_id=@contractNsId) INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('TRANSFORMATION', @contractNsId);
SELECT @transNs = namespace_pk FROM model.identity_namespace WHERE namespace_kind='TRANSFORMATION' AND namespace_id=@contractNsId;
IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='EXECUTION_AUTHORITY' AND namespace_id=@contractNsId) INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('EXECUTION_AUTHORITY', @contractNsId);
SELECT @eaNs = namespace_pk FROM model.identity_namespace WHERE namespace_kind='EXECUTION_AUTHORITY' AND namespace_id=@contractNsId;
IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='SCENARIO' AND namespace_id=@scenarioNsId) INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('SCENARIO', @scenarioNsId);
SELECT @scenarioNs = namespace_pk FROM model.identity_namespace WHERE namespace_kind='SCENARIO' AND namespace_id=@scenarioNsId;
IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='SCENARIO_INPUT' AND namespace_id=@inputNsId) INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('SCENARIO_INPUT', @inputNsId);
SELECT @inputNs = namespace_pk FROM model.identity_namespace WHERE namespace_kind='SCENARIO_INPUT' AND namespace_id=@inputNsId;
IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='SCENARIO_EVENT' AND namespace_id=@eventNsId) INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('SCENARIO_EVENT', @eventNsId);
SELECT @eventNs = namespace_pk FROM model.identity_namespace WHERE namespace_kind='SCENARIO_EVENT' AND namespace_id=@eventNsId;
IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='SCENARIO_OUTCOME' AND namespace_id=@outcomeNsId) INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('SCENARIO_OUTCOME', @outcomeNsId);
SELECT @outcomeNs = namespace_pk FROM model.identity_namespace WHERE namespace_kind='SCENARIO_OUTCOME' AND namespace_id=@outcomeNsId;


IF NOT EXISTS (SELECT 1 FROM model.semantic_object WHERE object_kind=N'CAPABILITY' AND namespace_pk=@capNs AND declared_id=@CapabilityId)
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES (N'CAPABILITY', @capNs, @CapabilityId);
SELECT @capSo = semantic_object_pk FROM model.semantic_object WHERE object_kind=N'CAPABILITY' AND namespace_pk=@capNs AND declared_id=@CapabilityId;
SET @env = N'{ "address": { "id": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'", "kind": "' + N'CAPABILITY' + N'", "namespace": (SELECT namespace_id FROM model.identity_namespace WHERE namespace_pk=@capNs) }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": LOWER(CONVERT(varchar(64), @capsule, 2)) } }';
SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), @env COLLATE Latin1_General_100_BIN2_UTF8));
SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@envDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@capSo, N'CAPABILITY', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@envDigest));
SET @capSod = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @capSod);

IF NOT EXISTS (SELECT 1 FROM model.semantic_object WHERE object_kind=N'SCENARIO' AND namespace_pk=@scenarioNs AND declared_id=@CapabilityId)
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES (N'SCENARIO', @scenarioNs, @CapabilityId);
SELECT @scnSo = semantic_object_pk FROM model.semantic_object WHERE object_kind=N'SCENARIO' AND namespace_pk=@scenarioNs AND declared_id=@CapabilityId;
SET @env = N'{ "address": { "id": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'", "kind": "' + N'SCENARIO' + N'", "namespace": (SELECT namespace_id FROM model.identity_namespace WHERE namespace_pk=@scenarioNs) }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": LOWER(CONVERT(varchar(64), @capsule, 2)) } }';
SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), @env COLLATE Latin1_General_100_BIN2_UTF8));
SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@envDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@scnSo, N'SCENARIO', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@envDigest));
SET @scnSod = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @scnSod);

IF NOT EXISTS (SELECT 1 FROM model.semantic_object WHERE object_kind=N'SCENARIO_INPUT' AND namespace_pk=@inputNs AND declared_id=@InputId)
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES (N'SCENARIO_INPUT', @inputNs, @InputId);
SELECT @inSo = semantic_object_pk FROM model.semantic_object WHERE object_kind=N'SCENARIO_INPUT' AND namespace_pk=@inputNs AND declared_id=@InputId;
SET @env = N'{ "address": { "id": "' + STRING_ESCAPE(@InputId, 'json') + N'", "kind": "' + N'SCENARIO_INPUT' + N'", "namespace": (SELECT namespace_id FROM model.identity_namespace WHERE namespace_pk=@inputNs) }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": LOWER(CONVERT(varchar(64), @capsule, 2)) } }';
SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), @env COLLATE Latin1_General_100_BIN2_UTF8));
SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@envDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@inSo, N'SCENARIO_INPUT', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@envDigest));
SET @inSod = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @inSod);

IF NOT EXISTS (SELECT 1 FROM model.semantic_object WHERE object_kind=N'SCENARIO_EVENT' AND namespace_pk=@eventNs AND declared_id=@CapabilityId)
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES (N'SCENARIO_EVENT', @eventNs, @CapabilityId);
SELECT @evSo = semantic_object_pk FROM model.semantic_object WHERE object_kind=N'SCENARIO_EVENT' AND namespace_pk=@eventNs AND declared_id=@CapabilityId;
SET @env = N'{ "address": { "id": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'", "kind": "' + N'SCENARIO_EVENT' + N'", "namespace": (SELECT namespace_id FROM model.identity_namespace WHERE namespace_pk=@eventNs) }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": LOWER(CONVERT(varchar(64), @capsule, 2)) } }';
SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), @env COLLATE Latin1_General_100_BIN2_UTF8));
SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@envDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@evSo, N'SCENARIO_EVENT', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@envDigest));
SET @evSod = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @evSod);

IF NOT EXISTS (SELECT 1 FROM model.semantic_object WHERE object_kind=N'SCENARIO_OUTCOME' AND namespace_pk=@outcomeNs AND declared_id=@OutcomeId)
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES (N'SCENARIO_OUTCOME', @outcomeNs, @OutcomeId);
SELECT @outSo = semantic_object_pk FROM model.semantic_object WHERE object_kind=N'SCENARIO_OUTCOME' AND namespace_pk=@outcomeNs AND declared_id=@OutcomeId;
SET @env = N'{ "address": { "id": "' + STRING_ESCAPE(@OutcomeId, 'json') + N'", "kind": "' + N'SCENARIO_OUTCOME' + N'", "namespace": (SELECT namespace_id FROM model.identity_namespace WHERE namespace_pk=@outcomeNs) }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": LOWER(CONVERT(varchar(64), @capsule, 2)) } }';
SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), @env COLLATE Latin1_General_100_BIN2_UTF8));
SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@envDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@outSo, N'SCENARIO_OUTCOME', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@envDigest));
SET @outSod = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @outSod);

IF NOT EXISTS (SELECT 1 FROM model.semantic_object WHERE object_kind=N'CONTRACT' AND namespace_pk=@contractNs AND declared_id=@InputContract)
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES (N'CONTRACT', @contractNs, @InputContract);
SELECT @inContractSo = semantic_object_pk FROM model.semantic_object WHERE object_kind=N'CONTRACT' AND namespace_pk=@contractNs AND declared_id=@InputContract;
SET @env = N'{ "address": { "id": "' + STRING_ESCAPE(@InputContract, 'json') + N'", "kind": "' + N'CONTRACT' + N'", "namespace": (SELECT namespace_id FROM model.identity_namespace WHERE namespace_pk=@contractNs) }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": LOWER(CONVERT(varchar(64), @capsule, 2)) } }';
SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), @env COLLATE Latin1_General_100_BIN2_UTF8));
SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@envDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@inContractSo, N'CONTRACT', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@envDigest));
SET @inContractSod = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @inContractSod);

IF NOT EXISTS (SELECT 1 FROM model.semantic_object WHERE object_kind=N'CONTRACT' AND namespace_pk=@contractNs AND declared_id=@OutcomeContract)
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES (N'CONTRACT', @contractNs, @OutcomeContract);
SELECT @outContractSo = semantic_object_pk FROM model.semantic_object WHERE object_kind=N'CONTRACT' AND namespace_pk=@contractNs AND declared_id=@OutcomeContract;
SET @env = N'{ "address": { "id": "' + STRING_ESCAPE(@OutcomeContract, 'json') + N'", "kind": "' + N'CONTRACT' + N'", "namespace": (SELECT namespace_id FROM model.identity_namespace WHERE namespace_pk=@contractNs) }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": LOWER(CONVERT(varchar(64), @capsule, 2)) } }';
SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), @env COLLATE Latin1_General_100_BIN2_UTF8));
SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@envDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@outContractSo, N'CONTRACT', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@envDigest));
SET @outContractSod = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @outContractSod);

IF NOT EXISTS (SELECT 1 FROM model.semantic_object WHERE object_kind=N'PORT' AND namespace_pk=@portNs AND declared_id=@PortId)
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES (N'PORT', @portNs, @PortId);
SELECT @portSo = semantic_object_pk FROM model.semantic_object WHERE object_kind=N'PORT' AND namespace_pk=@portNs AND declared_id=@PortId;
SET @env = N'{ "address": { "id": "' + STRING_ESCAPE(@PortId, 'json') + N'", "kind": "' + N'PORT' + N'", "namespace": (SELECT namespace_id FROM model.identity_namespace WHERE namespace_pk=@portNs) }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": LOWER(CONVERT(varchar(64), @capsule, 2)) } }';
SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), @env COLLATE Latin1_General_100_BIN2_UTF8));
SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@envDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@portSo, N'PORT', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@envDigest));
SET @portSod = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @portSod);

IF NOT EXISTS (SELECT 1 FROM model.semantic_object WHERE object_kind=N'TRANSFORMATION' AND namespace_pk=@transNs AND declared_id=@TransformationId)
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES (N'TRANSFORMATION', @transNs, @TransformationId);
SELECT @transSo = semantic_object_pk FROM model.semantic_object WHERE object_kind=N'TRANSFORMATION' AND namespace_pk=@transNs AND declared_id=@TransformationId;
SET @env = N'{ "address": { "id": "' + STRING_ESCAPE(@TransformationId, 'json') + N'", "kind": "' + N'TRANSFORMATION' + N'", "namespace": (SELECT namespace_id FROM model.identity_namespace WHERE namespace_pk=@transNs) }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": LOWER(CONVERT(varchar(64), @capsule, 2)) } }';
SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), @env COLLATE Latin1_General_100_BIN2_UTF8));
SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@envDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@transSo, N'TRANSFORMATION', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@envDigest));
SET @transSod = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @transSod);

IF NOT EXISTS (SELECT 1 FROM model.semantic_object WHERE object_kind=N'EXECUTION_AUTHORITY' AND namespace_pk=@eaNs AND declared_id=@EventAuthorityId)
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES (N'EXECUTION_AUTHORITY', @eaNs, @EventAuthorityId);
SELECT @eaSo = semantic_object_pk FROM model.semantic_object WHERE object_kind=N'EXECUTION_AUTHORITY' AND namespace_pk=@eaNs AND declared_id=@EventAuthorityId;
SET @env = N'{ "address": { "id": "' + STRING_ESCAPE(@EventAuthorityId, 'json') + N'", "kind": "' + N'EXECUTION_AUTHORITY' + N'", "namespace": (SELECT namespace_id FROM model.identity_namespace WHERE namespace_pk=@eaNs) }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": LOWER(CONVERT(varchar(64), @capsule, 2)) } }';
SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), @env COLLATE Latin1_General_100_BIN2_UTF8));
SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@envDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@eaSo, N'EXECUTION_AUTHORITY', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@envDigest));
SET @eaSod = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @eaSod);

IF NOT EXISTS (SELECT 1 FROM model.namespace_owner WHERE namespace_pk=@scenarioNs AND owner_semantic_object_pk=@capSo AND scope_kind='SCENARIO')
  INSERT model.namespace_owner (namespace_pk, owner_semantic_object_pk, scope_kind) VALUES (@scenarioNs, @capSo, 'SCENARIO');
IF NOT EXISTS (SELECT 1 FROM model.namespace_owner WHERE namespace_pk=@inputNs AND owner_semantic_object_pk=@scnSo AND scope_kind='SCENARIO_INPUT')
  INSERT model.namespace_owner (namespace_pk, owner_semantic_object_pk, scope_kind) VALUES (@inputNs, @scnSo, 'SCENARIO_INPUT');
IF NOT EXISTS (SELECT 1 FROM model.namespace_owner WHERE namespace_pk=@eventNs AND owner_semantic_object_pk=@scnSo AND scope_kind='SCENARIO_EVENT')
  INSERT model.namespace_owner (namespace_pk, owner_semantic_object_pk, scope_kind) VALUES (@eventNs, @scnSo, 'SCENARIO_EVENT');
IF NOT EXISTS (SELECT 1 FROM model.namespace_owner WHERE namespace_pk=@outcomeNs AND owner_semantic_object_pk=@scnSo AND scope_kind='SCENARIO_OUTCOME')
  INSERT model.namespace_owner (namespace_pk, owner_semantic_object_pk, scope_kind) VALUES (@outcomeNs, @scnSo, 'SCENARIO_OUTCOME');

IF @prevCapPk IS NULL
  INSERT model.capability (namespace_pk, capability_id, semantic_object_pk, object_kind) VALUES (@capNs, @CapabilityId, @capSo, 'CAPABILITY');
SELECT @capPk = c.capability_pk FROM model.capability c WHERE c.namespace_pk=@capNs AND c.capability_id=@CapabilityId;
IF @prevCapPk IS NULL SET @capPk = SCOPE_IDENTITY();
INSERT model.capability_version (capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, object_kind, _owner_definition_pk, _canonical_pointer)
  SELECT @capPk, @capSo, @capSod, definition_digest, @CapabilityId, 'CAPABILITY', @capSod, N'' FROM model.semantic_object_definition WHERE semantic_object_definition_pk=@capSod;
SET @capVer = SCOPE_IDENTITY();
INSERT model.estate_capability (estate_model_pk, capability_pk, capability_version_pk, semantic_object_definition_pk) VALUES (@model, @capPk, @capVer, @capSod);
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@capSod, 'capability_version', N'', @obs, @rule, 'DECLARATION');

IF NOT EXISTS (SELECT 1 FROM model.scenario WHERE capability_pk=@capPk AND scenario_id=@CapabilityId)
  INSERT model.scenario (namespace_pk, scenario_id, semantic_object_pk, object_kind, capability_pk) VALUES (@scenarioNs, @CapabilityId, @scnSo, 'SCENARIO', @capPk);
SELECT @scnPk = scenario_pk FROM model.scenario WHERE capability_pk=@capPk AND scenario_id=@CapabilityId;
INSERT model.scenario_version (scenario_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, source_profile, object_kind, _owner_definition_pk, _canonical_pointer)
  SELECT @scnPk, @scnSo, @scnSod, definition_digest, @CapabilityId, 'managed-feature-tags.v1', 'SCENARIO', @scnSod, N'' FROM model.semantic_object_definition WHERE semantic_object_definition_pk=@scnSod;
SET @scnVer = SCOPE_IDENTITY();
INSERT model.capability_scenario (capability_pk, capability_version_pk, scenario_pk, scenario_version_pk, _owner_definition_pk, _canonical_pointer)
  VALUES (@capPk, @capVer, @scnPk, @scnVer, @capSod, N'/semantics/scenario_members/' + @CapabilityId);
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@scnSod, 'scenario_version', N'', @obs, @rule, 'DECLARATION');
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@capSod, 'capability_scenario', N'/semantics/scenario_members/' + @CapabilityId, @obs, @rule, 'DECLARATION');
INSERT model.capability_root_scenario (capability_version_pk, scenario_pk, _owner_definition_pk, _canonical_pointer) VALUES (@capVer, @scnPk, @capSod, N'');
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@capSod, 'capability_root_scenario', N'', @obs, @rule, 'DECLARATION');

-- Contracts.
SET @schemaBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (N'{
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
SET @schemaDigest = HASHBYTES('SHA2_256', @schemaBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@schemaDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@schemaDigest, @schemaBytes, DATALENGTH(@schemaBytes));
IF NOT EXISTS (SELECT 1 FROM model.schema_object WHERE content_digest=@schemaDigest) INSERT model.schema_object (content_digest, dialect, content_object_pk) VALUES (@schemaDigest, 'https://json-schema.org/draft/2020-12/schema', (SELECT content_object_pk FROM source.content_object WHERE content_digest=@schemaDigest));
INSERT model.contract (namespace_pk, contract_id, semantic_object_pk, object_kind) VALUES (@contractNs, @InputContract, @inContractSo, 'CONTRACT');
SET @inContractPk = SCOPE_IDENTITY();
INSERT model.contract_version (contract_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, contract_kind, schema_object_pk, schema_reference_state, object_kind, _owner_definition_pk, _canonical_pointer)
  SELECT @inContractPk, @inContractSo, @inContractSod, definition_digest, @InputContract, NULL, (SELECT schema_object_pk FROM model.schema_object WHERE content_digest=@schemaDigest), 'RESOLVED', 'CONTRACT', @inContractSod, N'' FROM model.semantic_object_definition WHERE semantic_object_definition_pk=@inContractSod;
SET @inContractVer = SCOPE_IDENTITY();
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@inContractSod, 'contract_version', N'', @obs, @rule, 'DECLARATION');
SET @schemaBytes = CONVERT(varbinary(max), CONVERT(varchar(max), @outcomeSchemaText COLLATE Latin1_General_100_BIN2_UTF8));
SET @schemaDigest = HASHBYTES('SHA2_256', @schemaBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@schemaDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@schemaDigest, @schemaBytes, DATALENGTH(@schemaBytes));
IF NOT EXISTS (SELECT 1 FROM model.schema_object WHERE content_digest=@schemaDigest) INSERT model.schema_object (content_digest, dialect, content_object_pk) VALUES (@schemaDigest, 'https://json-schema.org/draft/2020-12/schema', (SELECT content_object_pk FROM source.content_object WHERE content_digest=@schemaDigest));
INSERT model.contract (namespace_pk, contract_id, semantic_object_pk, object_kind) VALUES (@contractNs, @OutcomeContract, @outContractSo, 'CONTRACT');
SET @outContractPk = SCOPE_IDENTITY();
INSERT model.contract_version (contract_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, contract_kind, schema_object_pk, schema_reference_state, object_kind, _owner_definition_pk, _canonical_pointer)
  SELECT @outContractPk, @outContractSo, @outContractSod, definition_digest, @OutcomeContract, NULL, (SELECT schema_object_pk FROM model.schema_object WHERE content_digest=@schemaDigest), 'RESOLVED', 'CONTRACT', @outContractSod, N'' FROM model.semantic_object_definition WHERE semantic_object_definition_pk=@outContractSod;
SET @outContractVer = SCOPE_IDENTITY();
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@outContractSod, 'contract_version', N'', @obs, @rule, 'DECLARATION');

-- Port, transformation, execution authority, faces.
INSERT model.port (namespace_pk, port_id, semantic_object_pk, object_kind) VALUES (@portNs, @PortId, @portSo, 'PORT');
SET @portPk = SCOPE_IDENTITY();
INSERT model.port_version (port_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, port_profile, object_kind, _owner_definition_pk, _canonical_pointer)
  SELECT @portPk, @portSo, @portSod, definition_digest, NULL, 'consumer-interface-authority.v1', 'PORT', @portSod, N'' FROM model.semantic_object_definition WHERE semantic_object_definition_pk=@portSod;
SET @portVer = SCOPE_IDENTITY();
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@portSod, 'port_version', N'', @obs, @rule, 'DECLARATION');
INSERT model.transformation (namespace_pk, transformation_id, semantic_object_pk, object_kind) VALUES (@transNs, @TransformationId, @transSo, 'TRANSFORMATION');
SET @transPk = SCOPE_IDENTITY();
INSERT model.transformation_version (transformation_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, expression_profile, object_kind, _owner_definition_pk, _canonical_pointer)
  SELECT @transPk, @transSo, @transSod, definition_digest, 'json-expression-tree.v1', 'TRANSFORMATION', @transSod, N'' FROM model.semantic_object_definition WHERE semantic_object_definition_pk=@transSod;
SET @transVer = SCOPE_IDENTITY();
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@transSod, 'transformation_version', N'', @obs, @rule, 'DECLARATION');
INSERT model.execution_authority (namespace_pk, execution_authority_id, semantic_object_pk, object_kind) VALUES (@eaNs, @EventAuthorityId, @eaSo, 'EXECUTION_AUTHORITY');
SET @eaPk = SCOPE_IDENTITY();
INSERT model.execution_authority_version (execution_authority_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, authority_profile, object_kind, _owner_definition_pk, _canonical_pointer)
  SELECT @eaPk, @eaSo, @eaSod, definition_digest, 'execution-authorities.v1', 'EXECUTION_AUTHORITY', @eaSod, N'' FROM model.semantic_object_definition WHERE semantic_object_definition_pk=@eaSod;
SET @eaVer = SCOPE_IDENTITY();
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@eaSod, 'execution_authority_version', N'', @obs, @rule, 'DECLARATION');
INSERT model.execution_operation (execution_authority_version_pk, operation_id, ordinal, operation_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@eaVer, NULL, 0, 'invoke-port', @eaSod, N'/semantics/authority/operations/0');
SET @inOp = SCOPE_IDENTITY();
INSERT model.operation_port_invocation (execution_operation_pk, operation_kind, port_version_pk, _owner_definition_pk, _canonical_pointer)
  VALUES (@inOp, 'invoke-port', @portVer, @eaSod, N'/semantics/authority/operations/0');
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@eaSod, 'execution_operation', N'/semantics/authority/operations/0', @obs, @rule, 'DECLARATION');
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@eaSod, 'operation_port_invocation', N'/semantics/authority/operations/0', @obs, @rule, 'DECLARATION');

INSERT model.scenario_input (scenario_version_pk, input_id, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer, input_contract_version_pk, contract_reference_state)
  SELECT @scnVer, @InputId, @inSo, @inSod, @inputNs, definition_digest, 'SCENARIO_INPUT', @inSod, N'', @inContractVer, 'RESOLVED' FROM model.semantic_object_definition WHERE semantic_object_definition_pk=@inSod;
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@inSod, 'scenario_input', N'', @obs, @rule, 'DECLARATION');
INSERT model.scenario_event (scenario_version_pk, event_id, responsibility, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer, execution_authority_version_pk, authority_reference_state)
  SELECT @scnVer, @CapabilityId, N'the database-defined message is passed to the standard-output interface', @evSo, @evSod, @eventNs, definition_digest, 'SCENARIO_EVENT', @evSod, N'', @eaVer, 'RESOLVED' FROM model.semantic_object_definition WHERE semantic_object_definition_pk=@evSod;
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@evSod, 'scenario_event', N'', @obs, @rule, 'DECLARATION');
INSERT model.scenario_outcome (scenario_version_pk, outcome_id, experience, terminal, terminal_disposition, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer)
  SELECT @scnVer, @OutcomeId, N'the configured message is delivered to standard output', 1, NULL, @outSo, @outSod, @outcomeNs, definition_digest, 'SCENARIO_OUTCOME', @outSod, N'' FROM model.semantic_object_definition WHERE semantic_object_definition_pk=@outSod;
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@outSod, 'scenario_outcome', N'', @obs, @rule, 'DECLARATION');
INSERT model.scenario_outcome_contract (scenario_version_pk, contract_version_pk, _owner_definition_pk, _canonical_pointer) VALUES (@scnVer, @outContractVer, @scnSod, N'/semantics/tags/outcome-contract');
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@scnSod, 'scenario_outcome_contract', N'/semantics/tags/outcome-contract', @obs, @rule, 'DECLARATION');

-- Transformation expression tree.
INSERT model.transformation_expression_node (transformation_version_pk, node_pointer, node_kind, operator, literal_content_pk, reference_name, _owner_definition_pk, _canonical_pointer)
  VALUES (@transVer, N'/semantics/expression', 'OBJECT', NULL, NULL, NULL, @transSod, N'/semantics/expression'); SET @n0 = SCOPE_IDENTITY();
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@transSod, 'transformation_expression_node', N'/semantics/expression', @obs, @rule, 'DECLARATION');
SET @v = CONVERT(varbinary(max), CONVERT(varchar(max), (CHAR(34) + STRING_ESCAPE(@OutcomeContract, 'json') + CHAR(34)) COLLATE Latin1_General_100_BIN2_UTF8));
SET @digest = HASHBYTES('SHA2_256', @v);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @v, DATALENGTH(@v));
INSERT model.transformation_expression_node (transformation_version_pk, node_pointer, node_kind, operator, literal_content_pk, reference_name, _owner_definition_pk, _canonical_pointer)
  VALUES (@transVer, N'/semantics/expression/contractId', 'LITERAL', NULL, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest), NULL, @transSod, N'/semantics/expression/contractId'); SET @n1 = SCOPE_IDENTITY();
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@transSod, 'transformation_expression_node', N'/semantics/expression/contractId', @obs, @rule, 'DECLARATION');
INSERT model.transformation_expression_node (transformation_version_pk, node_pointer, node_kind, operator, literal_content_pk, reference_name, _owner_definition_pk, _canonical_pointer)
  VALUES (@transVer, N'/semantics/expression/payload', 'OBJECT', NULL, NULL, NULL, @transSod, N'/semantics/expression/payload'); SET @n2 = SCOPE_IDENTITY();
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@transSod, 'transformation_expression_node', N'/semantics/expression/payload', @obs, @rule, 'DECLARATION');
SET @v = CONVERT(varbinary(max), CONVERT(varchar(max), (CHAR(34) + STRING_ESCAPE(@Message, 'json') + CHAR(34)) COLLATE Latin1_General_100_BIN2_UTF8));
SET @digest = HASHBYTES('SHA2_256', @v);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @v, DATALENGTH(@v));
INSERT model.transformation_expression_node (transformation_version_pk, node_pointer, node_kind, operator, literal_content_pk, reference_name, _owner_definition_pk, _canonical_pointer)
  VALUES (@transVer, N'/semantics/expression/payload/message', 'LITERAL', NULL, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest), NULL, @transSod, N'/semantics/expression/payload/message'); SET @n3 = SCOPE_IDENTITY();
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@transSod, 'transformation_expression_node', N'/semantics/expression/payload/message', @obs, @rule, 'DECLARATION');
INSERT model.transformation_expression_child (transformation_version_pk, parent_node_pk, child_node_pk, member_kind, member_name, ordinal, _owner_definition_pk, _canonical_pointer) VALUES (@transVer, @n0, @n1, 'OBJECT_MEMBER', 'contractId', NULL, @transSod, N'/semantics/expression/contractId');
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@transSod, 'transformation_expression_child', N'/semantics/expression/contractId', @obs, @rule, 'DECLARATION');
INSERT model.transformation_expression_child (transformation_version_pk, parent_node_pk, child_node_pk, member_kind, member_name, ordinal, _owner_definition_pk, _canonical_pointer) VALUES (@transVer, @n0, @n2, 'OBJECT_MEMBER', 'payload', NULL, @transSod, N'/semantics/expression/payload');
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@transSod, 'transformation_expression_child', N'/semantics/expression/payload', @obs, @rule, 'DECLARATION');
INSERT model.transformation_expression_child (transformation_version_pk, parent_node_pk, child_node_pk, member_kind, member_name, ordinal, _owner_definition_pk, _canonical_pointer) VALUES (@transVer, @n2, @n3, 'OBJECT_MEMBER', 'message', NULL, @transSod, N'/semantics/expression/payload/message');
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@transSod, 'transformation_expression_child', N'/semantics/expression/payload/message', @obs, @rule, 'DECLARATION');
INSERT model.transformation_root (transformation_version_pk, expression_node_pk, _owner_definition_pk, _canonical_pointer) VALUES (@transVer, @n0, @transSod, N'/semantics/expression');
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (@transSod, 'transformation_root', N'/semantics/expression', @obs, @rule, 'DECLARATION');

-- 5. Validation and verification.
EXEC source.validate_model @model;
SELECT '1_CAPABILITY' AS result_set, c.capability_id, @model AS new_generation, @from AS from_generation FROM model.capability c WHERE c.capability_pk = @capPk;
SELECT '2_SCENARIO' AS result_set, s.scenario_id, i.input_id, e.event_id, o.outcome_id
FROM model.scenario s JOIN model.scenario_version sv ON sv.scenario_pk = s.scenario_pk
LEFT JOIN model.scenario_input i ON i.scenario_version_pk = sv.scenario_version_pk
LEFT JOIN model.scenario_event e ON e.scenario_version_pk = sv.scenario_version_pk
LEFT JOIN model.scenario_outcome o ON o.scenario_version_pk = sv.scenario_version_pk
WHERE sv.scenario_version_pk = @scnVer;
SELECT '3_STDOUT_BINDING' AS result_set, 'sda-json-cli.v1' AS platform_capability, 'deliverArtifact(process.stdout)' AS operation;
SELECT '4_PROVIDER' AS result_set, eo.operation_kind, pv.port_id, eav.execution_authority_id
FROM model.operation_port_invocation opi
JOIN model.port_version pv ON pv.port_version_pk = opi.port_version_pk
JOIN model.execution_operation eo ON eo.execution_operation_pk = opi.execution_operation_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk = eo.execution_authority_version_pk
WHERE opi.execution_operation_pk = @inOp;
SELECT '5_SOURCE' AS result_set, COUNT(*) AS capsule_entries FROM source.source_appearance WHERE capsule_digest = @capsule;

-- Default: inspect the result sets, then choose.
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with these two lines and re-run:
-- EXEC source.publish_model @model;
-- COMMIT TRANSACTION;

