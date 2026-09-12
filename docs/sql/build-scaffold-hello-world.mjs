// Emit docs/sql/scaffold-hello-world.sql: a pure-SQL scaffold that creates one
// executable `hello-world-sql` capability in a new BUILDING generation and
// publishes it (default: rolled back for inspection).
//
// Read-only with respect to the database. It reads the retained say-hello-world
// capsule and the current model's mapping rules, rewrites the identity, and
// writes the .sql. Sidney runs the .sql.
import fs from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { query } from 'file:///C:/lab/sidefx-database/src/query/run.mjs';
import { canonical, bytesDigest } from 'file:///C:/lab/sidefx-database/src/migration/data.mjs';

const SOURCE_CAPABILITY = 'say-hello-world';
const CAPABILITY = 'hello-world-sql';
const SCENARIO = 'hello-world-sql';
const INPUT = 'hello-world-request';
const INPUT_CONTRACT = 'hello-world-request.v1';
const EVENT = 'hello-world-sql';
const EVENT_AUTHORITY = 'hello-world-sql.v1';
const OUTCOME = 'hello-world-greeting';
const OUTCOME_CONTRACT = 'hello-world-greeting.v1';
const PORT = 'hello-world-sql-port';
const TRANSFORMATION = 'hello-world-sql-transform.v1';
const NAMESPACE = 'sidefx:capabilities';
const PROVISIONING_RULE = 'sidefx-capability-provisioning.v1';
const PROVISIONING_PROFILE = 'authored-provisioned-capsule.v1';
const MANIFEST_PROFILE = 'JCS-IJSON-safe-integers.v1';

const sha256 = value => createHash('sha256').update(value).digest();
const hex = buf => '0x' + Buffer.from(buf).toString('hex').toUpperCase();
const lit = value => value === null || value === undefined ? 'NULL' : `N'${String(value).replaceAll("'", "''")}'`;
const envelope = (kind, id, namespace, manifestHex) => Buffer.from(canonical({
  address: { id, kind, namespace }, format: 'sidefx-semantic-definition.v1',
  semantics: { provisioning_manifest_digest: manifestHex }
}), 'utf8');

// --- read the source capsule from the database (read-only) -------------------
const rows = (await query(`
SELECT DISTINCT a.source_path, a.entry_id, c.content_bytes
FROM source.source_appearance a JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
WHERE a.capsule_digest = (
  SELECT TOP 1 a2.capsule_digest FROM source.source_appearance a2
  JOIN source.content_object c2 ON c2.content_object_pk = a2.content_object_pk
  WHERE a2.entry_id = 'capability.authority.json' AND a2.source_class = 'MANAGED_CAPSULE'
    AND c2.content_bytes LIKE CONVERT(varbinary(max), '%"say-hello-world"%'))
  AND (a.source_path LIKE N'capabilities/say-hello-world/%' OR a.source_path = N'features/say-hello-world.feature')
ORDER BY a.source_path;`, { rowLimit: 1000, retainObjects: false })).recordsets[0];
const unique = new Map();
for (const row of rows) if (!unique.has(row.source_path)) unique.set(row.source_path, row);
if (!unique.size) throw new Error('SOURCE_CAPSULE_NOT_FOUND');

const decode = value => Buffer.isBuffer(value) ? value : Buffer.from(value.base64, 'base64');
const entries = [];
for (const row of unique.values()) {
  const original = decode(row.content_bytes);
  const text = original.toString('utf8');
  const bytes = text.includes(SOURCE_CAPABILITY)
    ? Buffer.from(text.replaceAll(SOURCE_CAPABILITY, CAPABILITY).replaceAll('Hello, World!', 'Hello, World!'), 'utf8') : original;
  const sourcePath = row.source_path.replace('capabilities/say-hello-world/', `capabilities/${CAPABILITY}/`).replace('features/say-hello-world.feature', `features/${CAPABILITY}.feature`);
  entries.push({ sourcePath, entryId: row.entry_id, bytes, digest: sha256(bytes) });
}
entries.sort((a, b) => a.sourcePath < b.sourcePath ? -1 : 1);
const byPath = new Map(entries.map(e => [e.sourcePath.replace(`capabilities/${CAPABILITY}/`, ''), e]));
const json = key => JSON.parse(byPath.get(key).bytes.toString('utf8'));
const capsuleManifest = JSON.stringify(entries.map(e => ({ sourcePath: e.sourcePath, digest: e.digest.toString('hex') })));
const capsuleDigest = sha256(Buffer.from(capsuleManifest, 'utf8'));
const capsuleHex = capsuleDigest.toString('hex');
const manifestHex = capsuleHex;

const workspace = json('consumer-workspace.authority.json');
const interfaceAuthority = json('interfaces.authority.json');
const executionAuthority = json('execution-authorities.authority.json').executionAuthorities.find(a => a.id === EVENT_AUTHORITY);
const transformation = json('semantic-transformation.authority.json').transformations.find(t => t.id === TRANSFORMATION);
const contractCatalog = json('contracts/contract-catalog.json');

// --- read the current model's rules (read-only) ------------------------------
const baseRules = (await query(`
SELECT r.mapping_rule_pk, r.rule_id, r.rule_digest FROM source.estate_model_rule mr
JOIN source.mapping_rule r ON r.mapping_rule_pk = mr.mapping_rule_pk
WHERE mr.estate_model_pk = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1)
ORDER BY r.mapping_rule_pk;`, { rowLimit: 1000, retainObjects: false })).recordsets[0]
  .map(r => ({ id: r.rule_id, digest: Buffer.isBuffer(r.rule_digest) ? r.rule_digest : Buffer.from(r.rule_digest.base64, 'base64') }));

const ruleBytes = Buffer.from(canonical({
  ruleId: PROVISIONING_RULE, profile: PROVISIONING_PROFILE, canonicalization: MANIFEST_PROFILE,
  implementationDigest: sha256(Buffer.from('scaffold-hello-world.v1', 'utf8')).toString('hex'),
  selects: 'PROVISIONED_CAPSULE entries declared in this registration',
  extendsRuleDigests: baseRules.map(r => r.digest.toString('hex')),
  selection: [{ capabilityId: CAPABILITY, rootScenarioId: SCENARIO, capsuleDigest: capsuleHex,
    containerLocator: `provisioning/${CAPABILITY}.sfxcap`, entries: entries.map(e => ({ sourcePath: e.sourcePath, digest: e.digest.toString('hex') })) }]
}), 'utf8');
const ruleDigest = sha256(ruleBytes);
const manifest = bytesDigest(canonical([...baseRules.map(r => ({ id: r.id, digest: r.digest.toString('hex') })), { id: PROVISIONING_RULE, digest: ruleDigest.toString('hex') }]));

// --- namespaces --------------------------------------------------------------
const shaHex = value => sha256(Buffer.from(canonical(value), 'utf8')).toString('hex');
const ownedNs = (kind, ownerAddress) => `owner:sha256:${shaHex(ownerAddress)}`;
const scenarioNsId = ownedNs('SCENARIO', { id: CAPABILITY, kind: 'CAPABILITY', namespace: NAMESPACE });
const faceNsId = kind => ownedNs(kind, { id: SCENARIO, kind: 'SCENARIO', namespace: scenarioNsId });

const definitions = [
  { kind: 'CAPABILITY', id: CAPABILITY, nsKind: 'CAPABILITY', nsId: NAMESPACE },
  { kind: 'CONTRACT', id: INPUT_CONTRACT, nsKind: 'CONTRACT', nsId: `sidefx:capability:${CAPABILITY}` },
  { kind: 'CONTRACT', id: OUTCOME_CONTRACT, nsKind: 'CONTRACT', nsId: `sidefx:capability:${CAPABILITY}` },
  { kind: 'PORT', id: PORT, nsKind: 'PORT', nsId: `sidefx:capability:${CAPABILITY}` },
  { kind: 'TRANSFORMATION', id: TRANSFORMATION, nsKind: 'TRANSFORMATION', nsId: `sidefx:capability:${CAPABILITY}` },
  { kind: 'EXECUTION_AUTHORITY', id: EVENT_AUTHORITY, nsKind: 'EXECUTION_AUTHORITY', nsId: `sidefx:capability:${CAPABILITY}` },
  { kind: 'SCENARIO', id: SCENARIO, nsKind: 'SCENARIO', nsId: scenarioNsId },
  { kind: 'SCENARIO_INPUT', id: INPUT, nsKind: 'SCENARIO_INPUT', nsId: faceNsId('SCENARIO_INPUT') },
  { kind: 'SCENARIO_EVENT', id: EVENT, nsKind: 'SCENARIO_EVENT', nsId: faceNsId('SCENARIO_EVENT') },
  { kind: 'SCENARIO_OUTCOME', id: OUTCOME, nsKind: 'SCENARIO_OUTCOME', nsId: faceNsId('SCENARIO_OUTCOME') }
].map(d => ({ ...d, bytes: envelope(d.kind, d.id, d.nsId, manifestHex) })).map(d => ({ ...d, digest: sha256(d.bytes) }));
const def = (kind, id) => definitions.find(d => d.kind === kind && d.id === id);

// --- emit SQL ----------------------------------------------------------------
const s = [];
const p = text => s.push(text);
const content = (digest, bytes) => `IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = ${hex(digest)})
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (${hex(digest)}, ${hex(bytes)}, ${bytes.length});`;
const define = (d, nsVar, soVar, sodVar) => `${content(d.digest, d.bytes)}
INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES (${lit(d.kind)}, ${nsVar}, ${lit(d.id)});
SET ${soVar} = SCOPE_IDENTITY();
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
  VALUES (${soVar}, ${lit(d.kind)}, ${hex(d.digest)}, (SELECT content_object_pk FROM source.content_object WHERE content_digest = ${hex(d.digest)}));
SET ${sodVar} = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, ${sodVar});`;
const ns = (kind, id, varName) => `IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind = ${lit(kind)} AND namespace_id = ${lit(id)})
  INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES (${lit(kind)}, ${lit(id)});
SELECT ${varName} = namespace_pk FROM model.identity_namespace WHERE namespace_kind = ${lit(kind)} AND namespace_id = ${lit(id)};`;
const owner = (nsVar, ownerSoVar, scope) => `IF NOT EXISTS (SELECT 1 FROM model.namespace_owner WHERE namespace_pk = ${nsVar} AND owner_semantic_object_pk = ${ownerSoVar} AND scope_kind = ${lit(scope)})
  INSERT model.namespace_owner (namespace_pk, owner_semantic_object_pk, scope_kind) VALUES (${nsVar}, ${ownerSoVar}, ${lit(scope)});`;
const lineage = (sodVar, memberKind, ptr) => `INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  VALUES (${sodVar}, ${lit(memberKind)}, ${lit(ptr)}, @obs, @rule, 'DECLARATION');`;

p(`-- scaffold-hello-world.sql
--
-- Sidney runs this file. It creates one executable ${CAPABILITY} capability by
-- building a new generation that carries the current membership, adds the
-- PROVISIONED_CAPSULE and its normalized records, then validates and publishes.
-- It is SQL only: no Node/.mjs registration participates.
--
-- Default: the transaction is ROLLED BACK after the verification SELECTs. To
-- install, replace the final ROLLBACK with the two COMMENTED lines (publish then
-- commit) and re-run. After publishing, invoke through the unchanged CLI:
--
--   sfx capability invoke ${CAPABILITY} --input '{"contractId":"${INPUT_CONTRACT}","payload":{}}'
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @from bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @snap bigint = (SELECT estate_snapshot_pk FROM source.estate_model WHERE estate_model_pk = @from);
DECLARE @rule bigint, @model bigint, @obs bigint, @capAppearance bigint, @capContent bigint;
DECLARE @capNs bigint, @contractNs bigint, @portNs bigint, @transNs bigint, @eaNs bigint,
        @scenarioNs bigint, @inputNs bigint, @eventNs bigint, @outcomeNs bigint;
DECLARE @capSo bigint, @capSod bigint, @inContractSo bigint, @inContractSod bigint,
        @outContractSo bigint, @outContractSod bigint, @portSo bigint, @portSod bigint,
        @transSo bigint, @transSod bigint, @eaSo bigint, @eaSod bigint,
        @scnSo bigint, @scnSod bigint, @inSo bigint, @inSod bigint,
        @evSo bigint, @evSod bigint, @outSo bigint, @outSod bigint;
DECLARE @capPk bigint, @capVer bigint, @inContractPk bigint, @inContractVer bigint,
        @outContractPk bigint, @outContractVer bigint, @portPk bigint, @portVer bigint,
        @transPk bigint, @transVer bigint, @eaPk bigint, @eaVer bigint,
        @scnPk bigint, @scnVer bigint, @inOp bigint;

IF @from IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;
IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_id = ${lit(NAMESPACE)} AND namespace_kind = 'CAPABILITY')
  THROW 51000, 'CAPABILITY_NAMESPACE_NOT_FOUND', 1;
IF EXISTS (SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
           WHERE n.namespace_id = ${lit(NAMESPACE)} AND c.capability_id = ${lit(CAPABILITY)})
  THROW 51000, 'CAPABILITY_ALREADY_EXISTS', 1;

BEGIN TRANSACTION;

-- 1. Generation: provisioning rule and a new BUILDING model carrying membership.
${content(ruleDigest, ruleBytes)}
IF NOT EXISTS (SELECT 1 FROM source.mapping_rule WHERE rule_id = ${lit(PROVISIONING_RULE)} AND rule_digest = ${hex(ruleDigest)})
  INSERT source.mapping_rule (rule_id, rule_digest, source_profile, rule_content_object_pk, canonicalization_profile)
  VALUES (${lit(PROVISIONING_RULE)}, ${hex(ruleDigest)}, ${lit(PROVISIONING_PROFILE)},
          (SELECT content_object_pk FROM source.content_object WHERE content_digest = ${hex(ruleDigest)}), ${lit(MANIFEST_PROFILE)});
SELECT @rule = mapping_rule_pk FROM source.mapping_rule WHERE rule_id = ${lit(PROVISIONING_RULE)} AND rule_digest = ${hex(ruleDigest)};

INSERT source.estate_model (estate_snapshot_pk, mapping_manifest_digest, publication_state)
  VALUES (@snap, ${hex(manifest)}, 'BUILDING');
SET @model = SCOPE_IDENTITY();

INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk)
  SELECT @model, ed.semantic_object_definition_pk FROM model.estate_definition ed WHERE ed.estate_model_pk = @from;
INSERT model.estate_capability (estate_model_pk, capability_pk, capability_version_pk, semantic_object_definition_pk)
  SELECT @model, ec.capability_pk, ec.capability_version_pk, ec.semantic_object_definition_pk FROM model.estate_capability ec WHERE ec.estate_model_pk = @from;
INSERT source.estate_model_rule (estate_model_pk, mapping_rule_pk)
  SELECT @model, emr.mapping_rule_pk FROM source.estate_model_rule emr WHERE emr.estate_model_pk = @from;
INSERT source.estate_model_rule (estate_model_pk, mapping_rule_pk) VALUES (@model, @rule);

-- 2. Source layer: exact capsule entries and one declaration observation.
`);

for (const entry of entries) {
  p(`${content(entry.digest, entry.bytes)}
INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, entry_id)
  VALUES (@snap, (SELECT content_object_pk FROM source.content_object WHERE content_digest = ${hex(entry.digest)}),
          ${hex(sha256(Buffer.from(`${capsuleHex}:${entry.sourcePath}:${entry.digest.toString('hex')}`, 'utf8')))},
          ${lit(entry.sourcePath)}, 'PROVISIONED_CAPSULE', ${lit(`provisioning/${CAPABILITY}.sfxcap`)}, ${hex(capsuleDigest)}, ${lit(entry.entryId)});`);
  if (entry.sourcePath === `capabilities/${CAPABILITY}/capability.authority.json`) {
    p(`SET @capAppearance = SCOPE_IDENTITY();
SET @capContent = (SELECT content_object_pk FROM source.content_object WHERE content_digest = ${hex(entry.digest)});
INSERT source.source_observation (source_appearance_pk, locator, locator_digest, observation_kind, presence_state, observed_value_content_pk)
  VALUES (@capAppearance, N'', ${hex(sha256(Buffer.from('', 'utf8')))}, 'DECLARATION', 'PRESENT', @capContent);
SET @obs = SCOPE_IDENTITY();
INSERT source.declaration_observation (source_observation_pk, declared_kind, declared_id, namespace_text, observation_kind)
  VALUES (@obs, 'CAPABILITY', ${lit(CAPABILITY)}, ${lit(NAMESPACE)}, 'DECLARATION');`);
  }
}

p(`
-- 3. Namespaces and semantic definitions (witnesses for the validation gates).
${ns('CAPABILITY', NAMESPACE, '@capNs')}
${ns('CONTRACT', `sidefx:capability:${CAPABILITY}`, '@contractNs')}
${ns('PORT', `sidefx:capability:${CAPABILITY}`, '@portNs')}
${ns('TRANSFORMATION', `sidefx:capability:${CAPABILITY}`, '@transNs')}
${ns('EXECUTION_AUTHORITY', `sidefx:capability:${CAPABILITY}`, '@eaNs')}
${ns('SCENARIO', scenarioNsId, '@scenarioNs')}
${ns('SCENARIO_INPUT', faceNsId('SCENARIO_INPUT'), '@inputNs')}
${ns('SCENARIO_EVENT', faceNsId('SCENARIO_EVENT'), '@eventNs')}
${ns('SCENARIO_OUTCOME', faceNsId('SCENARIO_OUTCOME'), '@outcomeNs')}

${define(def('CAPABILITY', CAPABILITY), '@capNs', '@capSo', '@capSod')}
${define(def('CONTRACT', INPUT_CONTRACT), '@contractNs', '@inContractSo', '@inContractSod')}
${define(def('CONTRACT', OUTCOME_CONTRACT), '@contractNs', '@outContractSo', '@outContractSod')}
${define(def('PORT', PORT), '@portNs', '@portSo', '@portSod')}
${define(def('TRANSFORMATION', TRANSFORMATION), '@transNs', '@transSo', '@transSod')}
${define(def('EXECUTION_AUTHORITY', EVENT_AUTHORITY), '@eaNs', '@eaSo', '@eaSod')}
${define(def('SCENARIO', SCENARIO), '@scenarioNs', '@scnSo', '@scnSod')}
${define(def('SCENARIO_INPUT', INPUT), '@inputNs', '@inSo', '@inSod')}
${define(def('SCENARIO_EVENT', EVENT), '@eventNs', '@evSo', '@evSod')}
${define(def('SCENARIO_OUTCOME', OUTCOME), '@outcomeNs', '@outSo', '@outSod')}

-- ownership: scenario and faces belong to the capability/scenario identities.
${owner('@scenarioNs', '@capSo', 'SCENARIO')}
${owner('@inputNs', '@scnSo', 'SCENARIO_INPUT')}
${owner('@eventNs', '@scnSo', 'SCENARIO_EVENT')}
${owner('@outcomeNs', '@scnSo', 'SCENARIO_OUTCOME')}

-- 4. Capability and its root Scenario.
INSERT model.capability (namespace_pk, capability_id, semantic_object_pk, object_kind)
  VALUES (@capNs, ${lit(CAPABILITY)}, @capSo, 'CAPABILITY');
SET @capPk = SCOPE_IDENTITY();
INSERT model.capability_version (capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@capPk, @capSo, @capSod, ${hex(def('CAPABILITY', CAPABILITY).digest)}, ${lit(CAPABILITY)}, 'CAPABILITY', @capSod, N'');
SET @capVer = SCOPE_IDENTITY();
INSERT model.estate_capability (estate_model_pk, capability_pk, capability_version_pk, semantic_object_definition_pk)
  VALUES (@model, @capPk, @capVer, @capSod);
${lineage('@capSod', 'capability_version', '')}

INSERT model.scenario (namespace_pk, scenario_id, semantic_object_pk, object_kind, capability_pk)
  VALUES (@scenarioNs, ${lit(SCENARIO)}, @scnSo, 'SCENARIO', @capPk);
SET @scnPk = SCOPE_IDENTITY();
INSERT model.scenario_version (scenario_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, source_profile, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@scnPk, @scnSo, @scnSod, ${hex(def('SCENARIO', SCENARIO).digest)}, ${lit(SCENARIO)}, 'managed-feature-tags.v1', 'SCENARIO', @scnSod, N'');
SET @scnVer = SCOPE_IDENTITY();
INSERT model.capability_scenario (capability_pk, capability_version_pk, scenario_pk, scenario_version_pk, _owner_definition_pk, _canonical_pointer)
  VALUES (@capPk, @capVer, @scnPk, @scnVer, @capSod, ${lit(`/semantics/scenario_members/${SCENARIO}`)});
${lineage('@scnSod', 'scenario_version', '')}
${lineage('@capSod', 'capability_scenario', `/semantics/scenario_members/${SCENARIO}`)}
INSERT model.capability_root_scenario (capability_version_pk, scenario_pk, _owner_definition_pk, _canonical_pointer)
  VALUES (@capVer, @scnPk, @capSod, N'');
${lineage('@capSod', 'capability_root_scenario', '')}

-- 5. Contracts (schemas) and the transformation port.
INSERT model.schema_object (content_digest, dialect, content_object_pk)
  VALUES (${hex(byPath.get('contracts/input.schema.json').digest)}, 'https://json-schema.org/draft/2020-12/schema',
          (SELECT content_object_pk FROM source.content_object WHERE content_digest = ${hex(byPath.get('contracts/input.schema.json').digest)}));
INSERT model.contract (namespace_pk, contract_id, semantic_object_pk, object_kind) VALUES (@contractNs, ${lit(INPUT_CONTRACT)}, @inContractSo, 'CONTRACT');
SET @inContractPk = SCOPE_IDENTITY();
INSERT model.contract_version (contract_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, contract_kind, schema_object_pk, schema_reference_state, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@inContractPk, @inContractSo, @inContractSod, ${hex(def('CONTRACT', INPUT_CONTRACT).digest)}, ${lit(INPUT_CONTRACT)}, NULL,
          (SELECT schema_object_pk FROM model.schema_object WHERE content_digest = ${hex(byPath.get('contracts/input.schema.json').digest)}), 'RESOLVED', 'CONTRACT', @inContractSod, N'');
SET @inContractVer = SCOPE_IDENTITY();
${lineage('@inContractSod', 'contract_version', '')}
INSERT model.schema_object (content_digest, dialect, content_object_pk)
  VALUES (${hex(byPath.get('contracts/outcome.schema.json').digest)}, 'https://json-schema.org/draft/2020-12/schema',
          (SELECT content_object_pk FROM source.content_object WHERE content_digest = ${hex(byPath.get('contracts/outcome.schema.json').digest)}));
INSERT model.contract (namespace_pk, contract_id, semantic_object_pk, object_kind) VALUES (@contractNs, ${lit(OUTCOME_CONTRACT)}, @outContractSo, 'CONTRACT');
SET @outContractPk = SCOPE_IDENTITY();
INSERT model.contract_version (contract_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, contract_kind, schema_object_pk, schema_reference_state, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@outContractPk, @outContractSo, @outContractSod, ${hex(def('CONTRACT', OUTCOME_CONTRACT).digest)}, ${lit(OUTCOME_CONTRACT)}, NULL,
          (SELECT schema_object_pk FROM model.schema_object WHERE content_digest = ${hex(byPath.get('contracts/outcome.schema.json').digest)}), 'RESOLVED', 'CONTRACT', @outContractSod, N'');
SET @outContractVer = SCOPE_IDENTITY();
${lineage('@outContractSod', 'contract_version', '')}

INSERT model.port (namespace_pk, port_id, semantic_object_pk, object_kind) VALUES (@portNs, ${lit(PORT)}, @portSo, 'PORT');
SET @portPk = SCOPE_IDENTITY();
INSERT model.port_version (port_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, port_profile, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@portPk, @portSo, @portSod, ${hex(def('PORT', PORT).digest)}, NULL, 'consumer-interface-authority.v1', 'PORT', @portSod, N'');
SET @portVer = SCOPE_IDENTITY();
${lineage('@portSod', 'port_version', '')}

INSERT model.transformation (namespace_pk, transformation_id, semantic_object_pk, object_kind) VALUES (@transNs, ${lit(TRANSFORMATION)}, @transSo, 'TRANSFORMATION');
SET @transPk = SCOPE_IDENTITY();
INSERT model.transformation_version (transformation_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, expression_profile, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@transPk, @transSo, @transSod, ${hex(def('TRANSFORMATION', TRANSFORMATION).digest)}, 'json-expression-tree.v1', 'TRANSFORMATION', @transSod, N'');
SET @transVer = SCOPE_IDENTITY();
${lineage('@transSod', 'transformation_version', '')}

-- 6. Execution authority, its operation and port invocation.
INSERT model.execution_authority (namespace_pk, execution_authority_id, semantic_object_pk, object_kind)
  VALUES (@eaNs, ${lit(EVENT_AUTHORITY)}, @eaSo, 'EXECUTION_AUTHORITY');
SET @eaPk = SCOPE_IDENTITY();
INSERT model.execution_authority_version (execution_authority_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, authority_profile, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@eaPk, @eaSo, @eaSod, ${hex(def('EXECUTION_AUTHORITY', EVENT_AUTHORITY).digest)}, 'execution-authorities.v1', 'EXECUTION_AUTHORITY', @eaSod, N'');
SET @eaVer = SCOPE_IDENTITY();
${lineage('@eaSod', 'execution_authority_version', '')}
INSERT model.execution_operation (execution_authority_version_pk, operation_id, ordinal, operation_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@eaVer, NULL, 0, 'invoke-port', @eaSod, N'/semantics/authority/operations/0');
SET @inOp = SCOPE_IDENTITY();
INSERT model.operation_port_invocation (execution_operation_pk, operation_kind, port_version_pk, _owner_definition_pk, _canonical_pointer)
  VALUES (@inOp, 'invoke-port', @portVer, @eaSod, N'/semantics/authority/operations/0');
${lineage('@eaSod', 'execution_operation', '/semantics/authority/operations/0')}
${lineage('@eaSod', 'operation_port_invocation', '/semantics/authority/operations/0')}

-- 7. Scenario faces.
INSERT model.scenario_input (scenario_version_pk, input_id, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer, input_contract_version_pk, contract_reference_state)
  VALUES (@scnVer, ${lit(INPUT)}, @inSo, @inSod, @inputNs, ${hex(def('SCENARIO_INPUT', INPUT).digest)}, 'SCENARIO_INPUT', @inSod, N'', @inContractVer, 'RESOLVED');
${lineage('@inSod', 'scenario_input', '')}
INSERT model.scenario_event (scenario_version_pk, event_id, responsibility, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer, execution_authority_version_pk, authority_reference_state)
  VALUES (@scnVer, ${lit(EVENT)}, ${lit('the database-defined greeting is written to standard output')}, @evSo, @evSod, @eventNs, ${hex(def('SCENARIO_EVENT', EVENT).digest)}, 'SCENARIO_EVENT', @evSod, N'', @eaVer, 'RESOLVED');
${lineage('@evSod', 'scenario_event', '')}
INSERT model.scenario_outcome (scenario_version_pk, outcome_id, experience, terminal, terminal_disposition, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@scnVer, ${lit(OUTCOME)}, ${lit('the exact greeting is Hello, World!')}, 1, NULL, @outSo, @outSod, @outcomeNs, ${hex(def('SCENARIO_OUTCOME', OUTCOME).digest)}, 'SCENARIO_OUTCOME', @outSod, N'');
${lineage('@outSod', 'scenario_outcome', '')}
INSERT model.scenario_outcome_contract (scenario_version_pk, contract_version_pk, _owner_definition_pk, _canonical_pointer)
  VALUES (@scnVer, @outContractVer, @scnSod, N'/semantics/tags/outcome-contract');
${lineage('@scnSod', 'scenario_outcome_contract', '/semantics/tags/outcome-contract')}
`);

// 8. Transformation expression tree (nodes, children, root) with lineage.
let nodeSeq = 0;
const nodeVars = [];
const visit = (value, ptr) => {
  const varName = `@n${nodeSeq++}`;
  const kind = Array.isArray(value) ? 'ARRAY' : (value && typeof value === 'object' ? 'OBJECT' : 'LITERAL');
  const literalPkExpr = kind === 'LITERAL'
    ? `(SELECT content_object_pk FROM source.content_object WHERE content_digest = ${hex(sha256(Buffer.from(JSON.stringify(value), 'utf8')))})`
    : 'NULL';
  if (kind === 'LITERAL') p(content(sha256(Buffer.from(JSON.stringify(value), 'utf8')), Buffer.from(JSON.stringify(value), 'utf8')));
  p(`INSERT model.transformation_expression_node (transformation_version_pk, node_pointer, node_kind, operator, literal_content_pk, reference_name, _owner_definition_pk, _canonical_pointer)
  VALUES (@transVer, ${lit(ptr)}, ${lit(kind)}, NULL, ${literalPkExpr}, NULL, @transSod, ${lit(ptr)});
SET ${varName} = SCOPE_IDENTITY();
${lineage('@transSod', 'transformation_expression_node', ptr)}`);
  if (kind === 'OBJECT' || kind === 'ARRAY') {
    for (const [k, child] of Object.entries(value)) {
      const childPtr = `${ptr}/${k}`;
      const childVar = visit(child, childPtr);
      const memberKind = kind === 'ARRAY' ? 'ARRAY_MEMBER' : 'OBJECT_MEMBER';
      const memberName = kind === 'OBJECT' ? lit(k) : 'NULL';
      const ordinal = kind === 'ARRAY' ? Number(k) : 'NULL';
      p(`INSERT model.transformation_expression_child (transformation_version_pk, parent_node_pk, child_node_pk, member_kind, member_name, ordinal, _owner_definition_pk, _canonical_pointer)
  VALUES (@transVer, ${varName}, ${childVar}, ${lit(memberKind)}, ${memberName}, ${ordinal}, @transSod, ${lit(childPtr)});
${lineage('@transSod', 'transformation_expression_child', childPtr)}`);
    }
  }
  return varName;
};
const rootVar = visit(transformation.expression, '/semantics/expression');
p(`INSERT model.transformation_root (transformation_version_pk, expression_node_pk, _owner_definition_pk, _canonical_pointer)
  VALUES (@transVer, ${rootVar}, @transSod, N'/semantics/expression');
${lineage('@transSod', 'transformation_root', '/semantics/expression')}

-- 9. Verification (runs inside the transaction, before the final decision).
EXEC source.validate_model @model;
SELECT '1_CAPABILITY' AS result_set, c.capability_id, @model AS new_model_pk, @from AS from_model_pk
FROM model.capability c WHERE c.capability_pk = @capPk;
SELECT '2_SCENARIO' AS result_set, s.scenario_id, sv.scenario_version_pk, i.input_id, e.event_id, o.outcome_id
FROM model.scenario s JOIN model.scenario_version sv ON sv.scenario_pk = s.scenario_pk
LEFT JOIN model.scenario_input i ON i.scenario_version_pk = sv.scenario_version_pk
LEFT JOIN model.scenario_event e ON e.scenario_version_pk = sv.scenario_version_pk
LEFT JOIN model.scenario_outcome o ON o.scenario_version_pk = sv.scenario_version_pk
WHERE sv.scenario_version_pk = @scnVer;
SELECT '3_CONTRACTS' AS result_set, cv.name AS contract_id, cv.schema_reference_state
FROM model.contract_version cv WHERE cv.contract_version_pk IN (@inContractVer, @outContractVer);
SELECT '4_PROVIDER' AS result_set, op.operation_kind, pv.port_id, eav.execution_authority_id
FROM model.operation_port_invocation opi
JOIN model.port_version pv ON pv.port_version_pk = opi.port_version_pk
JOIN model.execution_operation eo ON eo.execution_operation_pk = opi.execution_operation_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk = eo.execution_authority_version_pk
WHERE opi.execution_operation_pk = @inOp;
SELECT '5_SOURCE' AS result_set, COUNT(*) AS capsule_entries
FROM source.source_appearance WHERE capsule_digest = ${hex(capsuleDigest)};

-- Default: inspect the five result sets, then choose.
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with these two lines and re-run:
-- EXEC source.publish_model @model;
-- COMMIT TRANSACTION;
`);

const file = path.resolve('docs/sql/scaffold-hello-world.sql');
await fs.writeFile(file, s.join('\n\n') + '\n');
console.log(JSON.stringify({ file, entries: entries.length, capsuleDigest: 'sha256:' + capsuleHex, ruleDigest: 'sha256:' + ruleDigest.toString('hex'), bytes: (await fs.readFile(file)).length }, null, 2));
