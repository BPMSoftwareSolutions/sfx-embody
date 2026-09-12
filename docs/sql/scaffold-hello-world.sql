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
-- Self-contained. It drops only the guards on the tables it touches, removes any
-- prior entries for @CapabilityId, then creates the capability fresh.
--
-- Default: ROLLBACK after verification. Change the final ROLLBACK to COMMIT to
-- install so the CLI can invoke it; the invoke-from-transaction harness instead
-- invokes against the uncommitted rows before rollback.
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @CapabilityId nvarchar(120) = N'hello-world-sql';
DECLARE @GreetingTemplate nvarchar(200) = N'Hello {name}!';
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
DECLARE @priorCapPk bigint, @priorCapVer bigint, @priorCapSo bigint, @priorCapSod bigint, @priorScnPk bigint, @priorScnVer bigint, @priorScnSo bigint, @priorScnSod bigint;
DECLARE @env nvarchar(max), @envBytes varbinary(max), @envDigest binary(32);
DECLARE @capText nvarchar(max), @featureText nvarchar(max), @workspaceText nvarchar(max), @execText nvarchar(max),
        @interfacesText nvarchar(max), @transText nvarchar(max), @fixturesText nvarchar(max), @outcomeSchemaText nvarchar(max), @inputSchemaText nvarchar(max);
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

-- 1. Capability meaning. @CapabilityId and @GreetingTemplate are the only inputs.
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
' + N'    Then the caller observes the greeting for the supplied name on standard output
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
    "payload": { "op": "object", "fields": { "message": { "op": "format", "template": "' + STRING_ESCAPE(@GreetingTemplate, 'json') + N'", "values": { "name": { "op": "path", "from": "input", "path": "payload.name" } } } } } } } } ] }';
SET @fixturesText = N'{ "fixtureType": "consumer-capability-fixtures.v1", "fixtures": [ { "fixtureId": "greets-the-supplied-name", "input": { "contractId": "' + STRING_ESCAPE(@InputContract, 'json') + N'", "payload": { "name": "Sidney" } },
  "expected": { "disposition": "terminated", "terminalScenarioId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'", "scenarioSequence": [ "' + STRING_ESCAPE(@CapabilityId, 'json') + N'" ],
    "outcomeAssertions": [ { "conditionId": "exact-message", "path": "payload.message", "operator": "equals", "value": "' + STRING_ESCAPE(REPLACE(@GreetingTemplate, N'{name}', N'Sidney'), 'json') + N'" } ] } } ] }';
SET @inputSchemaText = N'{ "$schema": "https://json-schema.org/draft/2020-12/schema", "$id": "https://schemas.agentic-harness.local/contracts/hello-world-request.v1.schema.json",
  "type": "object", "additionalProperties": false, "required": [ "contractId", "payload" ],
  "properties": { "contractId": { "const": "hello-world-request.v1" }, "payload": { "type": "object", "additionalProperties": false, "required": [ "name" ],
    "properties": { "name": { "type": "string", "minLength": 1 } } } } }';
SET @outcomeSchemaText = N'{ "$schema": "https://json-schema.org/draft/2020-12/schema", "$id": "https://schemas.agentic-harness.local/contracts/hello-world-greeting.v1.schema.json",
  "type": "object", "additionalProperties": false, "required": [ "contractId", "payload" ],
  "properties": { "contractId": { "const": "hello-world-greeting.v1" }, "payload": { "type": "object", "additionalProperties": false, "required": [ "message" ],
    "properties": { "message": { "type": "string", "minLength": 1 } } } } }';

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
SET @b_inSchema = CONVERT(varbinary(max), CONVERT(varchar(max), (@inputSchemaText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_inSchema = HASHBYTES('SHA2_256', @b_inSchema);
SET @b_outSchema = CONVERT(varbinary(max), CONVERT(varchar(max), (@outcomeSchemaText) COLLATE Latin1_General_100_BIN2_UTF8));
SET @d_outSchema = HASHBYTES('SHA2_256', @b_outSchema);
SET @manifest = N'cap:' + LOWER(CONVERT(varchar(64), @d_cap, 2)) + CHAR(10) + N'featW:' + LOWER(CONVERT(varchar(64), @d_featW, 2)) + CHAR(10) + N'feat:' + LOWER(CONVERT(varchar(64), @d_feat, 2)) + CHAR(10) + N'ws:' + LOWER(CONVERT(varchar(64), @d_ws, 2)) + CHAR(10) + N'exec:' + LOWER(CONVERT(varchar(64), @d_exec, 2)) + CHAR(10) + N'iface:' + LOWER(CONVERT(varchar(64), @d_iface, 2)) + CHAR(10) + N'trans:' + LOWER(CONVERT(varchar(64), @d_trans, 2)) + CHAR(10) + N'fixtures:' + LOWER(CONVERT(varchar(64), @d_fixtures, 2)) + CHAR(10) + N'graph:' + LOWER(CONVERT(varchar(64), @d_graph, 2)) + CHAR(10) + N'catalog:' + LOWER(CONVERT(varchar(64), @d_catalog, 2)) + CHAR(10) + N'inSchema:' + LOWER(CONVERT(varchar(64), @d_inSchema, 2)) + CHAR(10) + N'outSchema:' + LOWER(CONVERT(varchar(64), @d_outSchema, 2));
SET @capsule = HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (@manifest) COLLATE Latin1_General_100_BIN2_UTF8)));

-- 3. Content objects are content-addressed and inserted when absent.
BEGIN TRANSACTION;

-- Minimal workshop enablement for exactly the tables this script touches.
DROP TRIGGER IF EXISTS source.guard_content_object;
DROP TRIGGER IF EXISTS source.guard_source_appearance;
DROP TRIGGER IF EXISTS source.guard_source_observation;
DROP TRIGGER IF EXISTS source.guard_declaration_observation;
DROP TRIGGER IF EXISTS source.guard_source_lineage;
DROP TRIGGER IF EXISTS model.guard_estate_capability;
DROP TRIGGER IF EXISTS model.guard_estate_definition;
DROP TRIGGER IF EXISTS model.guard_capability;
DROP TRIGGER IF EXISTS model.guard_capability_version;
DROP TRIGGER IF EXISTS model.guard_scenario;
DROP TRIGGER IF EXISTS model.guard_scenario_version;
DROP TRIGGER IF EXISTS model.guard_capability_scenario;
DROP TRIGGER IF EXISTS model.guard_capability_root_scenario;
DROP TRIGGER IF EXISTS model.guard_semantic_object;
DROP TRIGGER IF EXISTS model.guard_semantic_object_definition;
REVOKE UPDATE, DELETE ON SCHEMA::source FROM sidefx_importer;
REVOKE UPDATE, DELETE ON SCHEMA::model FROM sidefx_importer;
GRANT DELETE ON OBJECT::source.source_appearance TO sidefx_importer;
GRANT DELETE ON OBJECT::source.source_observation TO sidefx_importer;
GRANT DELETE ON OBJECT::source.declaration_observation TO sidefx_importer;
GRANT DELETE ON OBJECT::source.source_lineage TO sidefx_importer;
GRANT DELETE ON OBJECT::model.estate_capability TO sidefx_importer;
GRANT DELETE ON OBJECT::model.estate_definition TO sidefx_importer;
GRANT DELETE ON OBJECT::model.capability TO sidefx_importer;
GRANT DELETE ON OBJECT::model.capability_version TO sidefx_importer;
GRANT DELETE ON OBJECT::model.scenario TO sidefx_importer;
GRANT DELETE ON OBJECT::model.scenario_version TO sidefx_importer;
GRANT DELETE ON OBJECT::model.capability_scenario TO sidefx_importer;
GRANT DELETE ON OBJECT::model.capability_root_scenario TO sidefx_importer;
GRANT DELETE ON OBJECT::model.semantic_object TO sidefx_importer;
GRANT DELETE ON OBJECT::model.semantic_object_definition TO sidefx_importer;
GRANT UPDATE ON OBJECT::source.source_appearance TO sidefx_importer;
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

-- Drop the workshop data guards (every guard/%immutable% trigger in model and
-- source), consistent with the other workshop scripts, so this script can write.
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;
GRANT UPDATE ON OBJECT::model.capability TO sidefx_importer;

-- Remove any prior entries for this @CapabilityId, dependency order, then create fresh.
SELECT @priorCapPk = c.capability_pk FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@CapabilityId;
IF @priorCapPk IS NOT NULL
BEGIN
  SELECT @priorCapVer = MAX(cv.capability_version_pk) FROM model.capability_version cv WHERE cv.capability_pk=@priorCapPk;
  SELECT @priorCapSo = MAX(cv.semantic_object_pk), @priorCapSod = MAX(cv.semantic_object_definition_pk) FROM model.capability_version cv WHERE cv.capability_version_pk=@priorCapVer;
  SELECT @priorScnPk = MAX(s.scenario_pk), @priorScnSo = MAX(s.semantic_object_pk) FROM model.scenario s WHERE s.capability_pk=@priorCapPk;
  SELECT @priorScnVer = MAX(sv.scenario_version_pk), @priorScnSod = MAX(sv.semantic_object_definition_pk) FROM model.scenario_version sv WHERE sv.scenario_pk=@priorScnPk;

  IF OBJECT_ID('tempdb..#priorSod') IS NOT NULL DROP TABLE #priorSod;
  CREATE TABLE #priorSod (sod bigint PRIMARY KEY, so bigint NULL);
  INSERT #priorSod (sod, so) SELECT @priorCapSod, @priorCapSo WHERE @priorCapSod IS NOT NULL;
  INSERT #priorSod (sod, so) SELECT @priorScnSod, @priorScnSo WHERE @priorScnSod IS NOT NULL;
  INSERT #priorSod (sod, so) SELECT si.semantic_object_definition_pk, si.semantic_object_pk FROM model.scenario_input si WHERE si.scenario_version_pk=@priorScnVer;
  INSERT #priorSod (sod, so) SELECT se.semantic_object_definition_pk, se.semantic_object_pk FROM model.scenario_event se WHERE se.scenario_version_pk=@priorScnVer;
  INSERT #priorSod (sod, so) SELECT so.semantic_object_definition_pk, so.semantic_object_pk FROM model.scenario_outcome so WHERE so.scenario_version_pk=@priorScnVer;
  INSERT #priorSod (sod, so) SELECT eav.semantic_object_definition_pk, eav.semantic_object_pk FROM model.execution_authority_version eav JOIN model.execution_authority ea ON ea.execution_authority_pk=eav.execution_authority_pk JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk WHERE n.namespace_id=N'sidefx:capability:'+@CapabilityId;
  INSERT #priorSod (sod, so) SELECT pv.semantic_object_definition_pk, pv.semantic_object_pk FROM model.port_version pv JOIN model.port p ON p.port_pk=pv.port_pk JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk WHERE n.namespace_id=N'sidefx:capability:'+@CapabilityId;
  INSERT #priorSod (sod, so) SELECT tv.semantic_object_definition_pk, tv.semantic_object_pk FROM model.transformation_version tv JOIN model.transformation t ON t.transformation_pk=tv.transformation_pk JOIN model.identity_namespace n ON n.namespace_pk=t.namespace_pk WHERE n.namespace_id=N'sidefx:capability:'+@CapabilityId;
  INSERT #priorSod (sod, so) SELECT oc.semantic_object_definition_pk, oc.semantic_object_pk FROM model.observable_condition oc WHERE oc.owner_definition_pk=@priorCapSod;
  INSERT #priorSod (sod, so) SELECT fv.semantic_object_definition_pk, fv.semantic_object_pk FROM model.feature_version fv JOIN model.feature f ON f.feature_pk=fv.feature_pk WHERE f.feature_id=@CapabilityId;

  DELETE ipi FROM model.operation_port_invocation ipi WHERE ipi._owner_definition_pk IN (SELECT sod FROM #priorSod);
  DELETE osi FROM model.operation_scenario_invocation osi WHERE osi._owner_definition_pk IN (SELECT sod FROM #priorSod);
  DELETE eo FROM model.execution_operation eo WHERE eo._owner_definition_pk IN (SELECT sod FROM #priorSod);
  DELETE eav FROM model.execution_authority_version eav WHERE eav.semantic_object_definition_pk IN (SELECT sod FROM #priorSod);
  DELETE ea FROM model.execution_authority ea WHERE ea.semantic_object_pk IN (SELECT so FROM #priorSod WHERE so IS NOT NULL);
  DELETE tc FROM model.transformation_expression_child tc WHERE tc.transformation_version_pk IN (SELECT tv.transformation_version_pk FROM model.transformation_version tv WHERE tv.semantic_object_definition_pk IN (SELECT sod FROM #priorSod));
  DELETE tn FROM model.transformation_expression_node tn WHERE tn.transformation_version_pk IN (SELECT tv.transformation_version_pk FROM model.transformation_version tv WHERE tv.semantic_object_definition_pk IN (SELECT sod FROM #priorSod));
  DELETE tr FROM model.transformation_root tr WHERE tr.transformation_version_pk IN (SELECT tv.transformation_version_pk FROM model.transformation_version tv WHERE tv.semantic_object_definition_pk IN (SELECT sod FROM #priorSod));
  DELETE tv FROM model.transformation_version tv WHERE tv.semantic_object_definition_pk IN (SELECT sod FROM #priorSod);
  DELETE t FROM model.transformation t WHERE t.semantic_object_pk IN (SELECT so FROM #priorSod WHERE so IS NOT NULL);
  DELETE pv FROM model.port_version pv WHERE pv.semantic_object_definition_pk IN (SELECT sod FROM #priorSod);
  DELETE p FROM model.port p WHERE p.semantic_object_pk IN (SELECT so FROM #priorSod WHERE so IS NOT NULL);
  DELETE soc FROM model.scenario_outcome_contract soc WHERE soc.scenario_version_pk=@priorScnVer;
  DELETE si FROM model.scenario_input si WHERE si.scenario_version_pk=@priorScnVer;
  DELETE se FROM model.scenario_event se WHERE se.scenario_version_pk=@priorScnVer;
  DELETE so FROM model.scenario_outcome so WHERE so.scenario_version_pk=@priorScnVer;
  DELETE crs FROM model.capability_root_scenario crs WHERE crs.capability_version_pk=@priorCapVer;
  DELETE cs FROM model.capability_scenario cs WHERE cs.capability_version_pk=@priorCapVer;
  DELETE oc FROM model.observable_condition oc WHERE oc.owner_definition_pk=@priorCapSod;
  DELETE fs FROM model.feature_scenario fs WHERE fs.feature_version_pk IN (SELECT fv.feature_version_pk FROM model.feature_version fv JOIN model.feature f ON f.feature_pk=fv.feature_pk WHERE f.feature_id=@CapabilityId);
  DELETE ecf FROM model.estate_capability_feature ecf WHERE ecf.capability_pk=@priorCapPk;
  DELETE fv FROM model.feature_version fv WHERE fv.feature_pk IN (SELECT feature_pk FROM model.feature WHERE feature_id=@CapabilityId);
  DELETE f FROM model.feature f WHERE f.feature_id=@CapabilityId;
  DELETE sv FROM model.scenario_version sv WHERE sv.scenario_version_pk=@priorScnVer;
  DELETE s FROM model.scenario s WHERE s.capability_pk=@priorCapPk;
  DELETE ec FROM model.estate_capability ec WHERE ec.capability_pk=@priorCapPk;
  UPDATE model.capability SET feature_pk=NULL WHERE capability_pk=@priorCapPk;
  DELETE cvv FROM model.capability_version cvv WHERE cvv.capability_pk=@priorCapPk;
  DELETE cc FROM model.capability cc WHERE cc.capability_pk=@priorCapPk;
  DELETE no FROM model.namespace_owner no WHERE no.owner_semantic_object_pk IN (SELECT so FROM #priorSod WHERE so IS NOT NULL);
  DELETE l2 FROM source.source_lineage l2 WHERE l2.semantic_object_definition_pk IN (SELECT sod FROM #priorSod);
  DELETE ed FROM model.estate_definition ed WHERE ed.semantic_object_definition_pk IN (SELECT sod FROM #priorSod);
  DELETE d FROM model.semantic_object_definition d WHERE d.semantic_object_definition_pk IN (SELECT sod FROM #priorSod);
  DELETE s2 FROM model.semantic_object s2 WHERE s2.semantic_object_pk IN (SELECT so FROM #priorSod WHERE so IS NOT NULL);
  DELETE l FROM source.source_lineage l WHERE l.source_observation_pk IN (SELECT o.source_observation_pk FROM source.source_observation o JOIN source.source_appearance a ON a.source_appearance_pk=o.source_appearance_pk WHERE a.source_path LIKE N'capabilities/'+@CapabilityId+N'/%' OR a.source_path=N'features/'+@CapabilityId+N'.feature');
  DELETE dop FROM source.declaration_observation dop WHERE dop.source_observation_pk IN (SELECT o.source_observation_pk FROM source.source_observation o JOIN source.source_appearance a ON a.source_appearance_pk=o.source_appearance_pk WHERE a.source_path LIKE N'capabilities/'+@CapabilityId+N'/%' OR a.source_path=N'features/'+@CapabilityId+N'.feature');
  DELETE o FROM source.source_observation o WHERE o.source_appearance_pk IN (SELECT source_appearance_pk FROM source.source_appearance WHERE source_path LIKE N'capabilities/'+@CapabilityId+N'/%' OR source_path=N'features/'+@CapabilityId+N'.feature');
  DELETE a FROM source.source_appearance a WHERE a.source_path LIKE N'capabilities/'+@CapabilityId+N'/%' OR a.source_path=N'features/'+@CapabilityId+N'.feature';
  DROP TABLE #priorSod;
END

-- Create fresh: appearances, declaration, selection rows and the one lineage row.
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

  -- ================= Normalized model chain (managed shapes) =================
  -- Every definition is a content-addressed sidefx-semantic-definition.v1 envelope.
  -- Digests are computed bottom-up and referenced by the envelopes that depend on
  -- them, exactly as the estate normalizer derives them.

  DECLARE @capId nvarchar(400) = @CapabilityId;
  DECLARE @ownedCapNs nvarchar(400), @ownedScnNs nvarchar(400);
  DECLARE @capAddress nvarchar(1000) = N'{"id":"' + STRING_ESCAPE(@capId,'json') + N'","kind":"CAPABILITY","namespace":"sidefx:capabilities"}';
  SET @ownedCapNs = N'owner:sha256:' + LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (@capAddress) COLLATE Latin1_General_100_BIN2_UTF8))), 2));
  DECLARE @scnAddress nvarchar(1000) = N'{"id":"' + STRING_ESCAPE(@capId,'json') + N'","kind":"SCENARIO","namespace":"' + @ownedCapNs + N'"}';
  SET @ownedScnNs = N'owner:sha256:' + LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (@scnAddress) COLLATE Latin1_General_100_BIN2_UTF8))), 2));

  DECLARE @featureAst nvarchar(max) =
    N'{"description":"","examples":[],"keyword":"Scenario","name":"' + STRING_ESCAPE(@capId,'json') + N' greeting",'
    + N'"steps":[{"keyword":"Given ","keywordType":"Context","text":"a caller name"},'
    + N'{"keyword":"When ","keywordType":"Action","text":"the greeting is requested"},'
    + N'{"keyword":"Then ","keywordType":"Outcome","text":"the caller receives the greeting with the name substituted"}],'
    + N'"tags":[{"name":"@scenario:' + @capId + N'"},{"name":"@input:' + @InputId + N'"},{"name":"@input-contract:' + @InputContract + N'"},'
    + N'{"name":"@event:' + @capId + N'"},{"name":"@event-authority:' + @EventAuthorityId + N'"},'
    + N'{"name":"@outcome:' + @OutcomeId + N'"},{"name":"@outcome-contract:' + @OutcomeContract + N'"},{"name":"@outcome-terminal"}]}';

  DECLARE @tags nvarchar(max) =
    N'{"capability":["' + @capId + N'"],"event":["' + @capId + N'"],"event-authority":["' + @EventAuthorityId + N'"],'
    + N'"input":["' + @InputId + N'"],"input-contract":["' + @InputContract + N'"],"outcome":["' + @OutcomeId + N'"],'
    + N'"outcome-contract":["' + @OutcomeContract + N'"],"outcome-terminal":[true],"root-scenario":["' + @capId + N'"],"scenario":["' + @capId + N'"]}';

  -- Provisioning manifest: one fragment per retained source document plus the feature.
  SET @manifest = N'[' +
    N'{"fragment":"' + LOWER(CONVERT(varchar(64), @d_cap, 2)) + N'","role":"capability.authority.json"},'
    + N'{"fragment":"' + LOWER(CONVERT(varchar(64), @d_ws, 2)) + N'","role":"consumer-workspace.authority.json"},'
    + N'{"fragment":"' + LOWER(CONVERT(varchar(64), @d_exec, 2)) + N'","role":"execution-authorities.authority.json"},'
    + N'{"fragment":"' + LOWER(CONVERT(varchar(64), @d_iface, 2)) + N'","role":"interfaces.authority.json"},'
    + N'{"fragment":"' + LOWER(CONVERT(varchar(64), @d_graph, 2)) + N'","role":"semantic-graph.authority.json"},'
    + N'{"fragment":"' + LOWER(CONVERT(varchar(64), @d_trans, 2)) + N'","role":"semantic-transformation.authority.json"},'
    + N'{"fragment":"' + LOWER(CONVERT(varchar(64), @d_fixtures, 2)) + N'","role":"fixtures.authority.json"},'
    + N'{"fragment":"' + LOWER(CONVERT(varchar(64), @d_feat, 2)) + N'","role":"feature"}]';
  DECLARE @manifestHex varchar(64) = LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (@manifest) COLLATE Latin1_General_100_BIN2_UTF8))), 2));

  -- (data guards were dropped and grants adjusted before the cleanup above)

  -- Envelopes; digest each immediately so later envelopes can reference it.
  DECLARE @defs TABLE (kind varchar(50) COLLATE Latin1_General_100_BIN2, ns_kind varchar(50) COLLATE Latin1_General_100_BIN2, declared_id nvarchar(400) COLLATE Latin1_General_100_BIN2, namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2, dgst binary(32), bytes varbinary(max));
  DECLARE @d_capDef binary(32), @d_scnDef binary(32), @d_auth binary(32), @d_portDef binary(32), @d_transDef binary(32),
          @d_cond binary(32), @d_contractIn binary(32), @d_contractOut binary(32),
          @d_input binary(32), @d_event binary(32), @d_out binary(32), @d_featRet binary(32), @d_featPar binary(32),
          @portPk bigint, @portVer bigint, @transPk bigint, @transVer bigint, @eaPk bigint, @eaVer bigint, @opPk bigint,
          @schemaInPk bigint, @schemaOutPk bigint, @contractInPk bigint, @contractInVer bigint, @contractOutPk bigint, @contractOutVer bigint,
          @featNs bigint, @featSo bigint, @featSodR bigint, @featSodP bigint, @featPk bigint, @featVerR bigint, @featVerP bigint;

  -- CAPABILITY
  SET @env = N'{"address":{"id":"' + @capId + N'","kind":"CAPABILITY","namespace":"sidefx:capabilities"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":' + @capText + N',"contributions":' + @manifest + N',"scenario_members":{"' + @capId + N'":' + @featureAst + N'}}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_capDef = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('CAPABILITY','CAPABILITY',@capId,N'sidefx:capabilities',@d_capDef,@envBytes);

  -- SCENARIO
  SET @env = N'{"address":{"id":"' + @capId + N'","kind":"SCENARIO","namespace":"' + @ownedCapNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"authority_manifest_digest":"' + @manifestHex + N'","scenario":' + @featureAst + N',"tags":' + @tags + N'}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_scnDef = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('SCENARIO','SCENARIO',@capId,@ownedCapNs,@d_scnDef,@envBytes);

  -- TRANSFORMATION
  SET @env = N'{"address":{"id":"' + @TransformationId + N'","kind":"TRANSFORMATION","namespace":"sidefx:capability:' + @capId + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"expression":{"fields":{"contractId":{"op":"literal","value":"' + @OutcomeContract + N'"},"payload":{"fields":{"message":{"op":"format","template":"' + STRING_ESCAPE(@GreetingTemplate,'json') + N'","values":{"name":{"from":"input","op":"path","path":"payload.name"}}}},"op":"object"}},"op":"object"},"id":"' + @TransformationId + N'"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_transDef = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('TRANSFORMATION','TRANSFORMATION',@TransformationId,N'sidefx:capability:' + @capId,@d_transDef,@envBytes);

  -- PORT
  SET @env = N'{"address":{"id":"' + @PortId + N'","kind":"PORT","namespace":"sidefx:capability:' + @capId + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"' + @TransformationId + N'"},"platformCapabilityId":"sda-authority-transformation-port.v1","portId":"' + @PortId + N'"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_portDef = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('PORT','PORT',@PortId,N'sidefx:capability:' + @capId,@d_portDef,@envBytes);

  -- EXECUTION_AUTHORITY
  SET @env = N'{"address":{"id":"' + @EventAuthorityId + N'","kind":"EXECUTION_AUTHORITY","namespace":"sidefx:capability:' + @capId + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":{"id":"' + @EventAuthorityId + N'","operations":[{"kind":"invoke-port","portId":"' + @PortId + N'"}],"owningScenarioId":"' + @capId + N'"},"authority_manifest_digest":"' + @manifestHex + N'"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_auth = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('EXECUTION_AUTHORITY','EXECUTION_AUTHORITY',@EventAuthorityId,N'sidefx:capability:' + @capId,@d_auth,@envBytes);

  -- CONTRACT (request, greeting) — computed first so the input face can reference it.
  SET @env = N'{"address":{"id":"' + @InputContract + N'","kind":"CONTRACT","namespace":"sidefx:contracts"},"format":"sidefx-semantic-definition.v1","semantics":{"schema_digest":"' + LOWER(CONVERT(varchar(64), @d_inSchema, 2)) + N'"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_contractIn = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('CONTRACT','CONTRACT',@InputContract,N'sidefx:contracts',@d_contractIn,@envBytes);
  SET @env = N'{"address":{"id":"' + @OutcomeContract + N'","kind":"CONTRACT","namespace":"sidefx:contracts"},"format":"sidefx-semantic-definition.v1","semantics":{"schema_digest":"' + LOWER(CONVERT(varchar(64), @d_outSchema, 2)) + N'"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_contractOut = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('CONTRACT','CONTRACT',@OutcomeContract,N'sidefx:contracts',@d_contractOut,@envBytes);

  -- SCENARIO_INPUT
  SET @env = N'{"address":{"id":"' + @InputId + N'","kind":"SCENARIO_INPUT","namespace":"' + @ownedScnNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"declared_reference":"' + @InputContract + N'","id":"' + @InputId + N'","owner_definition_digest":"' + LOWER(CONVERT(varchar(64), @d_scnDef, 2)) + N'","role":"input","target_definition_digest":"' + LOWER(CONVERT(varchar(64), @d_contractIn, 2)) + N'","text":"a caller name"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_input = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('SCENARIO_INPUT','SCENARIO_INPUT',@InputId,@ownedScnNs,@d_input,@envBytes);

  -- SCENARIO_EVENT
  SET @env = N'{"address":{"id":"' + @capId + N'","kind":"SCENARIO_EVENT","namespace":"' + @ownedScnNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"declared_reference":"' + @EventAuthorityId + N'","id":"' + @capId + N'","owner_definition_digest":"' + LOWER(CONVERT(varchar(64), @d_scnDef, 2)) + N'","role":"event","target_definition_digest":"' + LOWER(CONVERT(varchar(64), @d_auth, 2)) + N'","text":"the greeting is requested"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_event = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('SCENARIO_EVENT','SCENARIO_EVENT',@capId,@ownedScnNs,@d_event,@envBytes);

  -- SCENARIO_OUTCOME
  SET @env = N'{"address":{"id":"' + @OutcomeId + N'","kind":"SCENARIO_OUTCOME","namespace":"' + @ownedScnNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"declared_reference":null,"id":"' + @OutcomeId + N'","owner_definition_digest":"' + LOWER(CONVERT(varchar(64), @d_scnDef, 2)) + N'","role":"outcome","text":"the caller receives the greeting with the name substituted"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_out = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('SCENARIO_OUTCOME','SCENARIO_OUTCOME',@OutcomeId,@ownedScnNs,@d_out,@envBytes);

  -- OBSERVABLE_CONDITION
  SET @env = N'{"address":{"id":"message-delivered-to-standard-output","kind":"OBSERVABLE_CONDITION","namespace":"' + @ownedCapNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"condition":{"conditionId":"message-delivered-to-standard-output"},"owner_definition_digest":"' + LOWER(CONVERT(varchar(64), @d_capDef, 2)) + N'"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_cond = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('OBSERVABLE_CONDITION','OBSERVABLE_CONDITION',N'message-delivered-to-standard-output',@ownedCapNs,@d_cond,@envBytes);

  -- Set-based identity, definition and model membership rows.
  INSERT source.content_object (content_digest, content_bytes, byte_length)
    SELECT x.dgst, x.bytes, DATALENGTH(x.bytes) FROM @defs x WHERE NOT EXISTS (SELECT 1 FROM source.content_object c WHERE c.content_digest=x.dgst);
  INSERT model.identity_namespace (namespace_kind, namespace_id)
    SELECT DISTINCT x.ns_kind, x.namespace_id FROM @defs x WHERE NOT EXISTS (SELECT 1 FROM model.identity_namespace n WHERE n.namespace_kind=x.ns_kind AND n.namespace_id=x.namespace_id);
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id)
    SELECT DISTINCT x.kind, n.namespace_pk, x.declared_id FROM @defs x JOIN model.identity_namespace n ON n.namespace_kind=x.ns_kind AND n.namespace_id=x.namespace_id
    WHERE NOT EXISTS (SELECT 1 FROM model.semantic_object s WHERE s.object_kind=x.kind AND s.namespace_pk=n.namespace_pk AND s.declared_id=x.declared_id);
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
    SELECT s.semantic_object_pk, x.kind, x.dgst, c.content_object_pk FROM @defs x
    JOIN model.identity_namespace n ON n.namespace_kind=x.ns_kind AND n.namespace_id=x.namespace_id
    JOIN model.semantic_object s ON s.object_kind=x.kind AND s.namespace_pk=n.namespace_pk AND s.declared_id=x.declared_id
    JOIN source.content_object c ON c.content_digest=x.dgst
    WHERE NOT EXISTS (SELECT 1 FROM model.semantic_object_definition d WHERE d.semantic_object_pk=s.semantic_object_pk AND d.definition_digest=x.dgst);
  INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk)
    SELECT @model, d.semantic_object_definition_pk FROM @defs x
    JOIN model.identity_namespace n ON n.namespace_kind=x.ns_kind AND n.namespace_id=x.namespace_id
    JOIN model.semantic_object s ON s.object_kind=x.kind AND s.namespace_pk=n.namespace_pk AND s.declared_id=x.declared_id
    JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk AND d.definition_digest=x.dgst
    WHERE NOT EXISTS (SELECT 1 FROM model.estate_definition e WHERE e.estate_model_pk=@model AND e.semantic_object_definition_pk=d.semantic_object_definition_pk);

  -- Resolve pks.
  SELECT @capSo=s.semantic_object_pk,@capSod=d.semantic_object_definition_pk FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk WHERE n.namespace_id=N'sidefx:capabilities' AND s.declared_id=@capId AND d.definition_digest=@d_capDef;
  SELECT @scnSo=s.semantic_object_pk,@scnSod=d.semantic_object_definition_pk FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk WHERE n.namespace_id=@ownedCapNs AND s.declared_id=@capId AND d.definition_digest=@d_scnDef;
  SELECT @capNs=namespace_pk FROM model.identity_namespace WHERE namespace_kind='CAPABILITY' AND namespace_id=N'sidefx:capabilities';
  SELECT @scenarioNs=namespace_pk FROM model.identity_namespace WHERE namespace_kind='SCENARIO' AND namespace_id=@ownedCapNs;

  INSERT model.capability (namespace_pk, capability_id, semantic_object_pk, object_kind) VALUES (@capNs, @capId, @capSo, 'CAPABILITY'); SET @capPk = SCOPE_IDENTITY();
  INSERT model.capability_version (capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@capPk, @capSo, @capSod, @d_capDef, @capId, 'CAPABILITY', @capSod, N''); SET @capVer = SCOPE_IDENTITY();
  INSERT model.estate_capability (estate_model_pk, capability_pk, capability_version_pk, semantic_object_definition_pk) VALUES (@model, @capPk, @capVer, @capSod);

  INSERT model.scenario (namespace_pk, scenario_id, semantic_object_pk, object_kind, capability_pk) VALUES (@scenarioNs, @capId, @scnSo, 'SCENARIO', @capPk); SET @scnPk = SCOPE_IDENTITY();
  INSERT model.scenario_version (scenario_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, source_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@scnPk, @scnSo, @scnSod, @d_scnDef, @capId, 'managed-feature-tags.v1', 'SCENARIO', @scnSod, N''); SET @scnVer = SCOPE_IDENTITY();
  INSERT model.capability_scenario (capability_pk, capability_version_pk, scenario_pk, scenario_version_pk, _owner_definition_pk, _canonical_pointer)
    VALUES (@capPk, @capVer, @scnPk, @scnVer, @capSod, N'/semantics/scenario_members/' + @capId);
  INSERT model.capability_root_scenario (capability_version_pk, scenario_pk, _owner_definition_pk, _canonical_pointer) VALUES (@capVer, @scnPk, @capSod, N'');

  -- Contracts and schemas. Contract identities are shared estate identities
  -- (say-hello-world uses the same two), so reuse them; only mint what is missing.
  IF NOT EXISTS (SELECT 1 FROM model.schema_object WHERE content_digest=@d_inSchema)
    INSERT model.schema_object (content_digest, dialect, content_object_pk) VALUES (@d_inSchema, N'https://json-schema.org/draft/2020-12/schema', (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_inSchema));
  SET @schemaInPk=(SELECT schema_object_pk FROM model.schema_object WHERE content_digest=@d_inSchema);
  IF NOT EXISTS (SELECT 1 FROM model.schema_object WHERE content_digest=@d_outSchema)
    INSERT model.schema_object (content_digest, dialect, content_object_pk) VALUES (@d_outSchema, N'https://json-schema.org/draft/2020-12/schema', (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_outSchema));
  SET @schemaOutPk=(SELECT schema_object_pk FROM model.schema_object WHERE content_digest=@d_outSchema);
  SELECT @contractInPk=ct.contract_pk FROM model.contract ct JOIN model.identity_namespace n ON n.namespace_pk=ct.namespace_pk WHERE n.namespace_id=N'sidefx:contracts' AND ct.contract_id=@InputContract;
  IF @contractInPk IS NULL
  BEGIN
    INSERT model.contract (namespace_pk, contract_id, semantic_object_pk, object_kind)
      SELECT n.namespace_pk, @InputContract, s.semantic_object_pk, 'CONTRACT' FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk WHERE n.namespace_id=N'sidefx:contracts' AND s.declared_id=@InputContract;
    SET @contractInPk=SCOPE_IDENTITY();
  END
  SELECT @contractInVer=contract_version_pk FROM model.contract_version WHERE contract_pk=@contractInPk AND definition_digest=@d_contractIn;
  IF @contractInVer IS NULL
  BEGIN
    INSERT model.contract_version (contract_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, contract_kind, schema_object_pk, object_kind, _owner_definition_pk, _canonical_pointer, schema_reference_state)
      SELECT @contractInPk, s.semantic_object_pk, d.semantic_object_definition_pk, d.definition_digest, NULL, NULL, @schemaInPk, 'CONTRACT', d.semantic_object_definition_pk, N'', 'RESOLVED'
      FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
      WHERE n.namespace_id=N'sidefx:contracts' AND s.declared_id=@InputContract AND d.definition_digest=@d_contractIn;
    SET @contractInVer=SCOPE_IDENTITY();
  END
  SELECT @contractOutPk=ct.contract_pk FROM model.contract ct JOIN model.identity_namespace n ON n.namespace_pk=ct.namespace_pk WHERE n.namespace_id=N'sidefx:contracts' AND ct.contract_id=@OutcomeContract;
  IF @contractOutPk IS NULL
  BEGIN
    INSERT model.contract (namespace_pk, contract_id, semantic_object_pk, object_kind)
      SELECT n.namespace_pk, @OutcomeContract, s.semantic_object_pk, 'CONTRACT' FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk WHERE n.namespace_id=N'sidefx:contracts' AND s.declared_id=@OutcomeContract;
    SET @contractOutPk=SCOPE_IDENTITY();
  END
  SELECT @contractOutVer=contract_version_pk FROM model.contract_version WHERE contract_pk=@contractOutPk AND definition_digest=@d_contractOut;
  IF @contractOutVer IS NULL
  BEGIN
    INSERT model.contract_version (contract_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, contract_kind, schema_object_pk, object_kind, _owner_definition_pk, _canonical_pointer, schema_reference_state)
      SELECT @contractOutPk, s.semantic_object_pk, d.semantic_object_definition_pk, d.definition_digest, NULL, NULL, @schemaOutPk, 'CONTRACT', d.semantic_object_definition_pk, N'', 'RESOLVED'
      FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
      WHERE n.namespace_id=N'sidefx:contracts' AND s.declared_id=@OutcomeContract AND d.definition_digest=@d_contractOut;
    SET @contractOutVer=SCOPE_IDENTITY();
  END

  -- Port and transformation.
  INSERT model.port (namespace_pk, port_id, semantic_object_pk, object_kind)
    SELECT n.namespace_pk, @PortId, s.semantic_object_pk, 'PORT' FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk WHERE n.namespace_id=N'sidefx:capability:' + @capId AND s.declared_id=@PortId; SET @portPk=SCOPE_IDENTITY();
  INSERT model.port_version (port_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, port_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    SELECT @portPk, s.semantic_object_pk, d.semantic_object_definition_pk, d.definition_digest, NULL, 'consumer-interface-authority.v1', 'PORT', d.semantic_object_definition_pk, N''
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=N'sidefx:capability:' + @capId AND s.declared_id=@PortId AND d.definition_digest=@d_portDef; SET @portVer=SCOPE_IDENTITY();
  INSERT model.transformation (namespace_pk, transformation_id, semantic_object_pk, object_kind)
    SELECT n.namespace_pk, @TransformationId, s.semantic_object_pk, 'TRANSFORMATION' FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk WHERE n.namespace_id=N'sidefx:capability:' + @capId AND s.declared_id=@TransformationId; SET @transPk=SCOPE_IDENTITY();
  INSERT model.transformation_version (transformation_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, expression_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    SELECT @transPk, s.semantic_object_pk, d.semantic_object_definition_pk, d.definition_digest, 'json-expression-tree.v1', 'TRANSFORMATION', d.semantic_object_definition_pk, N''
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=N'sidefx:capability:' + @capId AND s.declared_id=@TransformationId AND d.definition_digest=@d_transDef; SET @transVer=SCOPE_IDENTITY();

  -- Execution authority, operation and its port invocation.
  INSERT model.execution_authority (namespace_pk, execution_authority_id, semantic_object_pk, object_kind)
    SELECT n.namespace_pk, @EventAuthorityId, s.semantic_object_pk, 'EXECUTION_AUTHORITY' FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk WHERE n.namespace_id=N'sidefx:capability:' + @capId AND s.declared_id=@EventAuthorityId; SET @eaPk=SCOPE_IDENTITY();
  INSERT model.execution_authority_version (execution_authority_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, authority_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    SELECT @eaPk, s.semantic_object_pk, d.semantic_object_definition_pk, d.definition_digest, 'execution-authorities.v1', 'EXECUTION_AUTHORITY', d.semantic_object_definition_pk, N''
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=N'sidefx:capability:' + @capId AND s.declared_id=@EventAuthorityId AND d.definition_digest=@d_auth; SET @eaVer=SCOPE_IDENTITY();
  INSERT model.execution_operation (execution_authority_version_pk, operation_id, ordinal, operation_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@eaVer, NULL, 0, 'invoke-port', (SELECT semantic_object_definition_pk FROM model.execution_authority_version WHERE execution_authority_version_pk=@eaVer), N'/semantics/authority/operations/0'); SET @opPk=SCOPE_IDENTITY();
  INSERT model.operation_port_invocation (execution_operation_pk, port_version_pk, operation_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@opPk, @portVer, 'invoke-port', (SELECT semantic_object_definition_pk FROM model.execution_authority_version WHERE execution_authority_version_pk=@eaVer), N'/semantics/authority/operations/0');

  -- Scenario faces.
  INSERT model.scenario_input (scenario_version_pk, input_id, name, input_contract_version_pk, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer, contract_reference_state)
    SELECT @scnVer, @InputId, NULL, @contractInVer, s.semantic_object_pk, d.semantic_object_definition_pk, n.namespace_pk, d.definition_digest, 'SCENARIO_INPUT', @scnSod, N'', 'RESOLVED'
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=@ownedScnNs AND s.declared_id=@InputId AND d.definition_digest=@d_input;
  INSERT model.scenario_event (scenario_version_pk, event_id, name, responsibility, execution_authority_version_pk, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer, authority_reference_state)
    SELECT @scnVer, @capId, NULL, N'the greeting is requested', @eaVer, s.semantic_object_pk, d.semantic_object_definition_pk, n.namespace_pk, d.definition_digest, 'SCENARIO_EVENT', @scnSod, N'', 'RESOLVED'
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=@ownedScnNs AND s.declared_id=@capId AND d.definition_digest=@d_event;
  INSERT model.scenario_outcome (scenario_version_pk, outcome_id, name, experience, terminal, terminal_disposition, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer)
    SELECT @scnVer, @OutcomeId, NULL, N'the caller receives the greeting with the name substituted', 1, NULL, s.semantic_object_pk, d.semantic_object_definition_pk, n.namespace_pk, d.definition_digest, 'SCENARIO_OUTCOME', @scnSod, N''
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=@ownedScnNs AND s.declared_id=@OutcomeId AND d.definition_digest=@d_out;
  INSERT model.scenario_outcome_contract (scenario_version_pk, contract_version_pk, _owner_definition_pk, _canonical_pointer)
    VALUES (@scnVer, @contractOutVer, @scnSod, N'/semantics/tags/outcome-contract');

  -- Observable condition.
  INSERT model.observable_condition (owner_definition_pk, condition_id, statement, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer)
    SELECT @capSod, N'message-delivered-to-standard-output', NULL, s.semantic_object_pk, d.semantic_object_definition_pk, n.namespace_pk, d.definition_digest, 'OBSERVABLE_CONDITION', d.semantic_object_definition_pk, N''
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=@ownedCapNs AND s.declared_id=N'message-delivered-to-standard-output' AND d.definition_digest=@d_cond;

  -- Canonical feature (retained binding + parsed declaration) and generation membership.
  DECLARE @featureNs bigint = (SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='FEATURE' AND namespace_id=N'sidefx:features');
  IF @featureNs IS NULL BEGIN INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('FEATURE', N'sidefx:features'); SET @featureNs=SCOPE_IDENTITY(); END
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES ('FEATURE', @featureNs, @capId); SET @featSo=SCOPE_IDENTITY();
  -- retained-feature-binding.v1
  SET @env = N'{"address":{"id":"' + @capId + N'","kind":"FEATURE","namespace":"sidefx:features"},"format":"sidefx-semantic-definition.v1","semantics":{"content_digest":"' + LOWER(CONVERT(varchar(64), @d_feat, 2)) + N'","source_class":"WORKSHOP","source_path":"features/' + @capId + N'.feature"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_featRet = HASHBYTES('SHA2_256', @envBytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_featRet) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_featRet, @envBytes, DATALENGTH(@envBytes));
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@featSo, 'FEATURE', @d_featRet, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_featRet)); SET @featSodR=SCOPE_IDENTITY();
  INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @featSodR);
  -- parsed-feature-declaration.v1 (references the scenario version)
  SET @env = N'{"address":{"id":"' + @capId + N'","kind":"FEATURE","namespace":"sidefx:features"},"format":"sidefx-semantic-definition.v1","semantics":{"name":"' + STRING_ESCAPE(@capId,'json') + N' greeting","description":"A caller supplies a name and receives the configured greeting with that name substituted.","content_digest":"' + LOWER(CONVERT(varchar(64), @d_feat, 2)) + N'","source_path":"features/' + @capId + N'.feature","scenarios":[{"scenarioId":"' + @capId + N'","scenarioVersionPk":' + CONVERT(nvarchar(20), @scnVer) + N'}]}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_featPar = HASHBYTES('SHA2_256', @envBytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_featPar) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_featPar, @envBytes, DATALENGTH(@envBytes));
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@featSo, 'FEATURE', @d_featPar, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_featPar)); SET @featSodP=SCOPE_IDENTITY();
  INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @featSodP);
  INSERT model.feature (namespace_pk, feature_id, semantic_object_pk, object_kind) VALUES (@featureNs, @capId, @featSo, 'FEATURE'); SET @featPk=SCOPE_IDENTITY();
  INSERT model.feature_version (feature_pk, capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, source_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@featPk, @capPk, @featSo, @featSodR, @d_featRet, @capId, 'retained-feature-binding.v1', 'FEATURE', @featSodR, N''); SET @featVerR=SCOPE_IDENTITY();
  INSERT model.feature_version (feature_pk, capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, source_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@featPk, @capPk, @featSo, @featSodP, @d_featPar, @capId, 'parsed-feature-declaration.v1', 'FEATURE', @featSodP, N''); SET @featVerP=SCOPE_IDENTITY();
  INSERT model.feature_scenario (feature_version_pk, scenario_pk, scenario_version_pk, capability_pk, ordinal) VALUES (@featVerP, @scnPk, @scnVer, @capPk, 0);
  INSERT model.estate_capability_feature (estate_model_pk, capability_pk, capability_version_pk, feature_version_pk, binding_role) VALUES (@model, @capPk, @capVer, @featVerP, 'CANONICAL');
  UPDATE model.capability SET feature_pk=@featPk WHERE capability_pk=@capPk;

  -- Lineage: each definition traces to the declaration observation.
  INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
    SELECT d.semantic_object_definition_pk, 'member', N'', @obs, @rule, 'DECLARATION'
    FROM @defs x JOIN model.semantic_object_definition d ON d.definition_digest=x.dgst AND d.object_kind=x.kind
    WHERE NOT EXISTS (SELECT 1 FROM source.source_lineage l WHERE l.semantic_object_definition_pk=d.semantic_object_definition_pk AND l.source_observation_pk=@obs);
  INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
    SELECT v.sod, 'member', N'', @obs, @rule, 'DECLARATION' FROM (VALUES (@featSodR),(@featSodP)) v(sod)
    WHERE NOT EXISTS (SELECT 1 FROM source.source_lineage l WHERE l.semantic_object_definition_pk=v.sod AND l.source_observation_pk=@obs);
SELECT '0_BRANCH' AS result_set, 'CREATE' AS branch;

-- 4. Verification: reads the stored binding and stored content, not constants.
SELECT '1_CAPABILITY' AS result_set, c.capability_id, cv.capability_version_pk, ec.estate_model_pk
FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk=ec.capability_pk JOIN model.capability_version cv ON cv.capability_version_pk=ec.capability_version_pk
WHERE ec.estate_model_pk=@model AND c.capability_id=@CapabilityId;
SELECT '2_NORMALIZED_CHAIN' AS result_set, d.object_kind, COUNT(*) AS definitions
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@model AND (d.namespace_id=N'sidefx:capability:'+@CapabilityId OR d.namespace_id=@ownedCapNs OR d.namespace_id=@ownedScnNs OR (d.namespace_id=N'sidefx:contracts' AND d.declared_id IN (@InputContract,@OutcomeContract)))
GROUP BY d.object_kind;
SELECT '3_EXECUTION_AUTHORITY' AS result_set, d.declared_id, JSON_VALUE(d.definition_json,'$.semantics.authority.owningScenarioId') AS owningScenarioId
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@model AND d.object_kind='EXECUTION_AUTHORITY' AND d.namespace_id=N'sidefx:capability:' + @CapabilityId;
SELECT '4_FEATURE' AS result_set, f.feature_id, fv.source_profile, d.definition_digest
FROM model.capability c JOIN model.feature f ON f.feature_pk=c.feature_pk JOIN model.feature_version fv ON fv.feature_pk=f.feature_pk
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=fv.semantic_object_definition_pk
WHERE c.capability_id=@CapabilityId;
SELECT '5_LINEAGE' AS result_set, COUNT(*) AS lineage_rows FROM source.source_lineage l
JOIN model.estate_capability ec ON ec.semantic_object_definition_pk=l.semantic_object_definition_pk
JOIN model.capability c ON c.capability_pk=ec.capability_pk
WHERE ec.estate_model_pk=@model AND c.capability_id=@CapabilityId;

-- Default: inspect, then choose.
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.

