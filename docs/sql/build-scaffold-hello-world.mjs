// Emit docs/sql/scaffold-hello-world.sql. Read-only against the database.
//
// Minimal workshop scaffold:
//   - retained capsule source (read path resolves authority from it)
//   - exactly one lineage row (the read path's capsule-digest resolution)
//   - selection rows in the CURRENT model, no generation/validation/publish
//   - same-identity message change updates the shared content references
//
// Declares the capacity's stdout binding in the retained interfaces authority
// ({ kind: "cli", platformCapabilityId: "sda-json-cli.v1" }); the platform
// provider Interface.JsonCli executes deliverArtifact(outcome, process.stdout).
import fs from 'node:fs/promises';
import path from 'node:path';
import { query } from 'file:///C:/lab/sidefx-database/src/query/run.mjs';

const NAMESPACE = 'sidefx:capabilities';
const rows = (await query(`
SELECT DISTINCT a.entry_id, c.content_bytes FROM source.source_appearance a
JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
WHERE a.capsule_digest = (
  SELECT TOP 1 a2.capsule_digest FROM source.source_appearance a2
  JOIN source.content_object c2 ON c2.content_object_pk = a2.content_object_pk
  WHERE a2.entry_id='capability.authority.json' AND a2.source_class='MANAGED_CAPSULE'
    AND c2.content_bytes LIKE CONVERT(varbinary(max),'%"say-hello-world"%'))
  AND a.source_path LIKE N'capabilities/say-hello-world/%';`, { rowLimit: 200, retainObjects: false })).recordsets[0];
const src = new Map(rows.map(r => [r.entry_id, Buffer.isBuffer(r.content_bytes) ? r.content_bytes : Buffer.from(r.content_bytes.base64, 'base64')]));
const textOf = id => src.get(id).toString('utf8');
const catalog = textOf('contracts/contract-catalog.json');
const inputSchema = textOf('contracts/input.schema.json');
const lit = t => `N'${t.replaceAll("'", "''")}'`;
const esc = v => `STRING_ESCAPE(${v}, 'json')`;
const bytesExpr = expr => `CONVERT(varbinary(max), CONVERT(varchar(max), (${expr}) COLLATE Latin1_General_100_BIN2_UTF8))`;

// path expression, entryId expression, text variable, short key
const files = [
  { key: 'cap', path: `N'capabilities/' + @CapabilityId + N'/capability.authority.json'`, entry: `N'capability.authority.json'`, text: '@capText' },
  { key: 'featW', path: `N'capabilities/' + @CapabilityId + N'/capability.feature'`, entry: `N'features/{id}.feature.workspace-alias'`, text: '@featureText' },
  { key: 'feat', path: `N'features/' + @CapabilityId + N'.feature'`, entry: `N'features/{id}.feature'`, text: '@featureText' },
  { key: 'ws', path: `N'capabilities/' + @CapabilityId + N'/consumer-workspace.authority.json'`, entry: lit('consumer-workspace.authority.json'), text: '@workspaceText' },
  { key: 'exec', path: `N'capabilities/' + @CapabilityId + N'/execution-authorities.authority.json'`, entry: lit('execution-authorities.authority.json'), text: '@execText' },
  { key: 'iface', path: `N'capabilities/' + @CapabilityId + N'/interfaces.authority.json'`, entry: lit('interfaces.authority.json'), text: '@interfacesText' },
  { key: 'trans', path: `N'capabilities/' + @CapabilityId + N'/semantic-transformation.authority.json'`, entry: lit('semantic-transformation.authority.json'), text: '@transText' },
  { key: 'fixtures', path: `N'capabilities/' + @CapabilityId + N'/fixtures.authority.json'`, entry: lit('fixtures.authority.json'), text: '@fixturesText' },
  { key: 'graph', path: `N'capabilities/' + @CapabilityId + N'/semantic-graph.authority.json'`, entry: lit('semantic-graph.authority.json'), text: `N'{ "transitions": [] }'` },
  { key: 'catalog', path: `N'capabilities/' + @CapabilityId + N'/contracts/contract-catalog.json'`, entry: lit('contracts/contract-catalog.json'), text: lit(catalog) },
  { key: 'inSchema', path: `N'capabilities/' + @CapabilityId + N'/contracts/input.schema.json'`, entry: lit('contracts/input.schema.json'), text: lit(inputSchema) },
  { key: 'outSchema', path: `N'capabilities/' + @CapabilityId + N'/contracts/outcome.schema.json'`, entry: lit('contracts/outcome.schema.json'), text: '@outcomeSchemaText' }
];
const messageFiles = ['trans', 'outSchema'];

const s = [];
const p = x => s.push(x);

p(`-- scaffold-hello-world.sql
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
${files.map(f => `DECLARE @b_${f.key} varbinary(max), @d_${f.key} binary(32);`).join('\n')}

IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;
IF @rule IS NULL THROW 51000, 'MODEL_MAPPING_RULE_NOT_FOUND', 1;

-- 1. Capability meaning. @CapabilityId and @Message are the only inputs.
SET @capText = N'{
  "capabilityId": "' + ${esc('@CapabilityId')} + N'",
  "name": "' + ${esc('@CapabilityId')} + N'",
  "mode": "capability",
  "userStory": { "actor": "caller", "intent": "write a database-defined message to standard output", "outcome": "the caller observes the configured message" },
  "experience": { "experienceId": "' + ${esc('@CapabilityId')} + N'.v1", "actor": "caller",
    "promise": "the configured message is delivered through the sda-json-cli.v1 standard-output interface",
    "observableConditions": [ { "conditionId": "message-delivered-to-standard-output" } ] },
  "rootScenarioId": "' + ${esc('@CapabilityId')} + N'"
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
SET @workspaceText = N'{ "workspaceType": "consumer-workspace-authority.v1", "consumerId": "' + ${esc('@CapabilityId')} + N'", "projectionTargets": [ "node" ],
  "capabilities": [ { "featureId": "' + ${esc('@CapabilityId')} + N'.feature", "feature": "capability.feature", "capability": "capability.authority.json",
  "semanticGraph": "semantic-graph.authority.json", "executionAuthorities": "execution-authorities.authority.json", "interfaces": "interfaces.authority.json", "fixtures": "fixtures.authority.json" } ] }';
SET @execText = N'{ "authorityType": "execution-authorities.v1", "executionAuthorities": [ { "id": "' + ${esc('@EventAuthorityId')} + N'", "owningScenarioId": "' + ${esc('@CapabilityId')} + N'",
  "operations": [ { "kind": "invoke-port", "portId": "' + ${esc('@PortId')} + N'" } ] } ] }';
SET @interfacesText = N'{ "interfaceAuthorityType": "consumer-interface-authority.v1", "contractValidatorCapabilityId": "sda-schema-contract-admission.v1", "contractCatalog": "contracts/contract-catalog.json",
  "interfaces": [ { "interfaceId": "' + ${esc('@CapabilityId')} + N'-cli", "kind": "cli", "rootScenarioId": "' + ${esc('@CapabilityId')} + N'", "platformCapabilityId": "sda-json-cli.v1", "projectionTargets": [ "node" ] } ],
  "portBindings": [ { "portId": "' + ${esc('@PortId')} + N'", "platformCapabilityId": "sda-authority-transformation-port.v1",
    "configuration": { "transformationAuthorityRef": "semantic-transformation.authority.json", "transformationId": "' + ${esc('@TransformationId')} + N'" } } ], "projectionBindings": [] }';
SET @transText = N'{ "authorityType": "semantic-transformation-authority.v1", "transformations": [ { "id": "' + ${esc('@TransformationId')} + N'",
  "expression": { "op": "object", "fields": { "contractId": { "op": "literal", "value": "' + ${esc('@OutcomeContract')} + N'" },
    "payload": { "op": "object", "fields": { "message": { "op": "literal", "value": "' + ${esc('@Message')} + N'" } } } } } } ] }';
SET @fixturesText = N'{ "fixtureType": "consumer-capability-fixtures.v1", "fixtures": [ { "fixtureId": "writes-the-configured-message", "input": { "contractId": "' + ${esc('@InputContract')} + N'", "payload": {} },
  "expected": { "disposition": "terminated", "terminalScenarioId": "' + ${esc('@CapabilityId')} + N'", "scenarioSequence": [ "' + ${esc('@CapabilityId')} + N'" ],
    "outcomeAssertions": [ { "conditionId": "exact-message", "path": "payload.message", "operator": "equals", "value": "' + ${esc('@Message')} + N'" } ] } } ] }';
SET @outcomeSchemaText = N'{ "$schema": "https://json-schema.org/draft/2020-12/schema", "$id": "https://schemas.agentic-harness.local/contracts/hello-world-greeting.v1.schema.json",
  "type": "object", "additionalProperties": false, "required": [ "contractId", "payload" ],
  "properties": { "contractId": { "const": "hello-world-greeting.v1" }, "payload": { "type": "object", "additionalProperties": false, "required": [ "message" ],
    "properties": { "message": { "const": "' + ${esc('@Message')} + N'" } } } } }';

-- 2. Encode each file once. The capsule digest is derived from these bytes.
${files.map(f => `SET @b_${f.key} = ${bytesExpr(f.text)};\nSET @d_${f.key} = HASHBYTES('SHA2_256', @b_${f.key});`).join('\n')}
SET @manifest = ${files.map(f => `N'${f.key}:' + LOWER(CONVERT(varchar(64), @d_${f.key}, 2))`).join(' + CHAR(10) + ')};
SET @capsule = HASHBYTES('SHA2_256', ${bytesExpr('@manifest')});

-- 3. Content objects are content-addressed and inserted when absent.
BEGIN TRANSACTION;
${files.map(f => `IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_${f.key}) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_${f.key}, @b_${f.key}, DATALENGTH(@b_${f.key}));`).join('\n')}

-- A prior identity for this @CapabilityId makes this a message change, not a create.
SELECT @prevCapsule = a.capsule_digest FROM source.source_appearance a
  WHERE a.source_path = N'capabilities/' + @CapabilityId + N'/capability.authority.json'
  ORDER BY a.source_appearance_pk DESC;

IF @prevCapsule IS NULL
BEGIN
  -- Create: appearances, declaration, selection rows and the one lineage row.
${files.map(f => `  SET @path = ${f.path}; SET @entryId = ${f.entry}; SET @appearance = HASHBYTES('SHA2_256', ${bytesExpr(`LOWER(CONVERT(varchar(64), @capsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_${f.key}, 2))`)});
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
    VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_${f.key}), @appearance, @path, 'PROVISIONED_CAPSULE', N'provisioning/' + @CapabilityId + N'.sfxcap', @capsule, @entryId);`).join('\n')}

  INSERT source.source_observation (source_appearance_pk, locator, locator_digest, observation_kind, presence_state, observed_value_content_pk)
    SELECT TOP 1 a.source_appearance_pk, N'', HASHBYTES('SHA2_256', ${bytesExpr(`N''`)}), 'DECLARATION', 'PRESENT', a.content_object_pk
    FROM source.source_appearance a WHERE a.capsule_digest=@capsule AND a.source_path=N'capabilities/' + @CapabilityId + N'/capability.authority.json';
  SET @obs = SCOPE_IDENTITY();
  INSERT source.declaration_observation (source_observation_pk, declared_kind, declared_id, namespace_text, observation_kind)
    VALUES (@obs, 'CAPABILITY', @CapabilityId, ${lit(NAMESPACE)}, 'DECLARATION');

  SELECT @capNs = namespace_pk FROM model.identity_namespace WHERE namespace_kind='CAPABILITY' AND namespace_id=${lit(NAMESPACE)};
  IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='SCENARIO' AND namespace_id=N'owner:scenario:' + @CapabilityId)
    INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('SCENARIO', N'owner:scenario:' + @CapabilityId);
  SELECT @scenarioNs = namespace_pk FROM model.identity_namespace WHERE namespace_kind='SCENARIO' AND namespace_id=N'owner:scenario:' + @CapabilityId;

  SET @env = N'{ "address": { "id": "' + ${esc('@CapabilityId')} + N'", "kind": "CAPABILITY", "namespace": "sidefx:capabilities" }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": "' + LOWER(CONVERT(varchar(64), @capsule, 2)) + N'" } }';
  SET @envBytes = ${bytesExpr('@env')};
  SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@envDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES ('CAPABILITY', @capNs, @CapabilityId); SET @capSo = SCOPE_IDENTITY();
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@capSo, 'CAPABILITY', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@envDigest)); SET @capSod = SCOPE_IDENTITY();
  INSERT model.capability (namespace_pk, capability_id, semantic_object_pk, object_kind) VALUES (@capNs, @CapabilityId, @capSo, 'CAPABILITY'); SET @capPk = SCOPE_IDENTITY();
  INSERT model.capability_version (capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@capPk, @capSo, @capSod, @envDigest, @CapabilityId, 'CAPABILITY', @capSod, N''); SET @capVer = SCOPE_IDENTITY();
  INSERT model.estate_capability (estate_model_pk, capability_pk, capability_version_pk, semantic_object_definition_pk) VALUES (@model, @capPk, @capVer, @capSod);

  SET @env = N'{ "address": { "id": "' + ${esc('@CapabilityId')} + N'", "kind": "SCENARIO", "namespace": "owner:scenario:' + ${esc('@CapabilityId')} + N'" }, "format": "sidefx-semantic-definition.v1", "semantics": { "provisioning_manifest_digest": "' + LOWER(CONVERT(varchar(64), @capsule, 2)) + N'" } }';
  SET @envBytes = ${bytesExpr('@env')};
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
  SET @appearance = HASHBYTES('SHA2_256', ${bytesExpr(`LOWER(CONVERT(varchar(64), @prevCapsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_trans, 2))`)});
  UPDATE source.source_appearance SET content_object_pk=(SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_trans), appearance_digest=@appearance
    WHERE capsule_digest=@prevCapsule AND source_path=@path;
  SET @path = N'capabilities/' + @CapabilityId + N'/contracts/outcome.schema.json';
  SET @appearance = HASHBYTES('SHA2_256', ${bytesExpr(`LOWER(CONVERT(varchar(64), @prevCapsule, 2)) + N':' + @path + N':' + LOWER(CONVERT(varchar(64), @d_outSchema, 2))`)});
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
`);

const out = s.join('\n').replaceAll('DOUBLE=;\n', '');
const file = path.resolve('docs/sql/scaffold-hello-world.sql');
await fs.writeFile(file, out + '\n');
console.log(JSON.stringify({ file, bytes: Buffer.byteLength(out) }, null, 2));
