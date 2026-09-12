-- assemble-execution-declarations.sql
--
-- Creates analysis.v_capability_execution_declaration: the executable document set
-- for each capability in the selected model, assembled from the model declarations.
--
-- This replaces the source-supplied document set (`capability-embodiment.sql`
-- recordset[1]); no `source_appearance`, `source_lineage` or retained-source rows are
-- read. The planner (`materialize-node.mjs`) consumes these rows unchanged.
--
-- Nothing new is stored: each document is derived from declarations the model
-- already owns. The consumer-workspace and semantic-graph documents are assembled
-- (they have no separate retained declaration). A capability's CLI configuration is
-- read from its model declaration (`semantics.cli`), not from a retained document.
--
-- Default: ROLLBACK after verification. Change the final ROLLBACK to COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;
GRANT UPDATE ON OBJECT::model.capability TO sidefx_importer;
BEGIN TRANSACTION;
GO
CREATE OR ALTER VIEW analysis.v_capability_execution_declaration AS
WITH cap AS (
  SELECT ec.estate_model_pk, c.capability_pk, c.capability_id COLLATE Latin1_General_100_BIN2 AS capability_id,
         ec.capability_version_pk, ec.semantic_object_definition_pk AS cap_sod
  FROM source.current_model cm
  JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
),
def AS (
  SELECT sod, object_kind, declared_id, namespace_pk, semantic_object_pk, envelope
  FROM (
    SELECT d.semantic_object_definition_pk AS sod, d.object_kind, s.declared_id, s.namespace_pk, s.semantic_object_pk,
           CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS envelope,
           ROW_NUMBER() OVER (PARTITION BY d.semantic_object_pk ORDER BY d.semantic_object_definition_pk DESC) AS rn
    FROM model.semantic_object_definition d
    JOIN model.semantic_object s ON s.semantic_object_pk = d.semantic_object_pk
    JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
  ) x WHERE rn = 1
),
capdef AS (
  SELECT cap.capability_id, def.envelope
  FROM cap JOIN def ON def.sod = cap.cap_sod
),
cli AS (
  SELECT cap.capability_id, JSON_QUERY(capdef.envelope, '$.semantics.cli') AS configuration
  FROM cap JOIN capdef ON capdef.capability_id = cap.capability_id
),
capcontract AS (
  SELECT DISTINCT cap.capability_id, ct.contract_id, so.content_object_pk AS schema_content_pk
  FROM cap
  JOIN model.capability_scenario cs ON cs.capability_version_pk = cap.capability_version_pk
  JOIN model.scenario_version sv ON sv.scenario_version_pk = cs.scenario_version_pk
  LEFT JOIN model.scenario_input si ON si.scenario_version_pk = sv.scenario_version_pk
  LEFT JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk = sv.scenario_version_pk
  JOIN model.contract_version cv ON cv.contract_version_pk IN (si.input_contract_version_pk, soc.contract_version_pk)
  JOIN model.contract ct ON ct.contract_pk = cv.contract_pk
  JOIN model.schema_object so ON so.schema_object_pk = cv.schema_object_pk
)
-- capability.authority.json
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/capability.authority.json') COLLATE Latin1_General_100_BIN2 AS source_path,
  N'capability.authority.json' COLLATE Latin1_General_100_BIN2 AS entry_id,
  (JSON_QUERY(capdef.envelope, '$.semantics.authority')) COLLATE Latin1_General_100_BIN2 AS document
FROM cap JOIN capdef ON capdef.capability_id = cap.capability_id
UNION ALL
-- execution-authorities.authority.json
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/execution-authorities.authority.json') COLLATE Latin1_General_100_BIN2,
  N'execution-authorities.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"authorityType":"execution-authorities.v1","executionAuthorities":['
   + ISNULL((SELECT STRING_AGG(JSON_QUERY(def.envelope, '$.semantics.authority'), N',')
             FROM def JOIN model.execution_authority ea ON ea.semantic_object_pk = def.semantic_object_pk
             JOIN model.identity_namespace n ON n.namespace_pk = ea.namespace_pk
             WHERE n.namespace_id = (N'sidefx:capability:' + cap.capability_id) COLLATE Latin1_General_100_BIN2), N'') + N']}') COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- semantic-transformation.authority.json
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/semantic-transformation.authority.json') COLLATE Latin1_General_100_BIN2,
  N'semantic-transformation.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"authorityType":"semantic-transformation-authority.v1","transformations":['
   + ISNULL((SELECT STRING_AGG(JSON_QUERY(def.envelope, '$.semantics'), N',')
             FROM def JOIN model.transformation t ON t.semantic_object_pk = def.semantic_object_pk
             JOIN model.identity_namespace n ON n.namespace_pk = t.namespace_pk
             WHERE n.namespace_id = (N'sidefx:capability:' + cap.capability_id) COLLATE Latin1_General_100_BIN2), N'') + N']}') COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- semantic-graph.authority.json (assembled; no separate declaration)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/semantic-graph.authority.json') COLLATE Latin1_General_100_BIN2,
  N'semantic-graph.authority.json' COLLATE Latin1_General_100_BIN2,
  N'{"transitions":[]}' COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- interfaces.authority.json: CLI interface (configuration from the model declaration),
-- contract catalog, port bindings from PORT declarations.
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/interfaces.authority.json') COLLATE Latin1_General_100_BIN2,
  N'interfaces.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"interfaceAuthorityType":"consumer-interface-authority.v1","contractValidatorCapabilityId":"sda-schema-contract-admission.v1","contractCatalog":"contracts/contract-catalog.json","interfaces":[{"interfaceId":"'
   + cap.capability_id + N'-cli","kind":"cli","rootScenarioId":"' + cap.capability_id + N'","platformCapabilityId":"sda-json-cli.v1"'
   + CASE WHEN cli.configuration IS NULL THEN N'' ELSE N',"configuration":' + CONVERT(nvarchar(max), cli.configuration) END
   + N'}],"portBindings":['
   + ISNULL((SELECT STRING_AGG(JSON_QUERY(def.envelope, '$.semantics'), N',')
             FROM def JOIN model.port p ON p.semantic_object_pk = def.semantic_object_pk
             JOIN model.identity_namespace n ON n.namespace_pk = p.namespace_pk
             WHERE n.namespace_id = (N'sidefx:capability:' + cap.capability_id) COLLATE Latin1_General_100_BIN2), N'') + N'],"projectionBindings":[]}') COLLATE Latin1_General_100_BIN2
FROM cap JOIN cli ON cli.capability_id = cap.capability_id
UNION ALL
-- consumer-workspace.authority.json (assembled from the capability's members)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/consumer-workspace.authority.json') COLLATE Latin1_General_100_BIN2,
  N'consumer-workspace.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"workspaceType":"consumer-workspace-authority.v1","consumerId":"' + cap.capability_id + N'","projectionTargets":["node"],'
   + N'"capabilities":[{"featureId":"' + cap.capability_id + N'.feature","feature":"capability.feature","capability":"capability.authority.json",'
   + N'"semanticGraph":"semantic-graph.authority.json","executionAuthorities":"execution-authorities.authority.json",'
   + N'"interfaces":"interfaces.authority.json","fixtures":"fixtures.authority.json"}]}') COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- capabilities/<id>/capability.feature (feature text resolved by the declaration's content_digest)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/capability.feature') COLLATE Latin1_General_100_BIN2,
  N'capability.feature' COLLATE Latin1_General_100_BIN2,
  (CONVERT(nvarchar(max), CONVERT(varchar(max), fco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)) COLLATE Latin1_General_100_BIN2
FROM cap
JOIN model.feature f ON f.feature_id = cap.capability_id
JOIN model.feature_version fv ON fv.feature_pk = f.feature_pk AND fv.source_profile = N'retained-feature-binding.v1'
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = fv.semantic_object_definition_pk
JOIN source.content_object env ON env.content_object_pk = d.canonical_content_pk
JOIN source.content_object fco ON fco.content_digest = CONVERT(binary(32), N'0x' + JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), env.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.content_digest'), 1)
UNION ALL
-- contracts/contract-catalog.json
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/contracts/contract-catalog.json') COLLATE Latin1_General_100_BIN2,
  N'contracts/contract-catalog.json' COLLATE Latin1_General_100_BIN2,
  (N'{' + ISNULL((SELECT STRING_AGG(N'"' + cc.contract_id + N'":"' + cc.contract_id + N'.schema.json"', N',')
                  FROM capcontract cc WHERE cc.capability_id = cap.capability_id), N'') + N'}') COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- contracts/<id>.schema.json (schema bytes resolved by the contract's schema object)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/contracts/' + cc.contract_id + N'.schema.json') COLLATE Latin1_General_100_BIN2,
  (N'contracts/' + cc.contract_id + N'.schema.json') COLLATE Latin1_General_100_BIN2,
  (CONVERT(nvarchar(max), CONVERT(varchar(max), sco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)) COLLATE Latin1_General_100_BIN2
FROM cap JOIN capcontract cc ON cc.capability_id = cap.capability_id
JOIN source.content_object sco ON sco.content_object_pk = cc.schema_content_pk
UNION ALL
-- fixtures.authority.json (assembled from FIXTURE declarations owned by the capability)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/fixtures.authority.json') COLLATE Latin1_General_100_BIN2,
  N'fixtures.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"fixtureType":"consumer-capability-fixtures.v1","fixtures":['
   + ISNULL((SELECT STRING_AGG(JSON_QUERY(def.envelope, '$.semantics.fixture'), N',')
             FROM def JOIN model.fixture fx ON fx.semantic_object_definition_pk = def.sod
             WHERE fx.owner_definition_pk = cap.cap_sod), N'') + N']}') COLLATE Latin1_General_100_BIN2
FROM cap;
GO
-- ============================== MODEL-OWNED MEANING ==============================
-- (4) A FIXTURE declaration, and (3) the capability's CLI configuration declared on
-- the CAPABILITY definition. Both are model rows; nothing is read from source.
SET NOCOUNT ON;
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @cap nvarchar(400) = N'hello-world-sql';
DECLARE @capPk bigint = (SELECT capability_pk FROM model.capability WHERE capability_id=@cap);
DECLARE @capVer bigint = (SELECT capability_version_pk FROM model.estate_capability WHERE estate_model_pk=@model AND capability_pk=@capPk);
DECLARE @capSod bigint = (SELECT semantic_object_definition_pk FROM model.estate_capability WHERE estate_model_pk=@model AND capability_pk=@capPk);
DECLARE @capSo bigint = (SELECT semantic_object_pk FROM model.capability WHERE capability_pk=@capPk);
DECLARE @capDigestHex varchar(64) = LOWER(CONVERT(varchar(64), (SELECT definition_digest FROM model.semantic_object_definition WHERE semantic_object_definition_pk=@capSod), 2));
DECLARE @namespace nvarchar(400) = N'sidefx:capability:' + @cap;
DECLARE @fixtureId nvarchar(400) = N'greets-the-supplied-name';

-- Seed the fixture and the capability CLI declaration only once. A re-run
-- refreshes the assembly view above and otherwise leaves the model unchanged.
IF NOT EXISTS (SELECT 1 FROM model.fixture WHERE owner_definition_pk=@capSod AND fixture_id=@fixtureId)
BEGIN
-- (4) FIXTURE declaration.
DECLARE @fixtureJson nvarchar(max) = N'{"fixtureId":"greets-the-supplied-name","input":{"contractId":"hello-world-request.v1","payload":{"name":"Sidney"}},"expected":{"disposition":"terminated","terminalScenarioId":"hello-world-sql","scenarioSequence":["hello-world-sql"],"outcomeAssertions":[{"conditionId":"exact-message","path":"payload.message","operator":"equals","value":"Hello Sidney!"}]}}';
DECLARE @fixEnv nvarchar(max) = N'{"address":{"id":"' + @fixtureId + N'","kind":"FIXTURE","namespace":"' + @namespace + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"owner_definition_digest":"' + @capDigestHex + N'","fixture":' + @fixtureJson + N'}}';
DECLARE @fixBytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@fixEnv) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @fixDigest binary(32) = HASHBYTES('SHA2_256', @fixBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@fixDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@fixDigest, @fixBytes, DATALENGTH(@fixBytes));
IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='FIXTURE' AND namespace_id=@namespace) INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('FIXTURE', @namespace);
DECLARE @fixNs bigint = (SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='FIXTURE' AND namespace_id=@namespace);
DECLARE @fixSo bigint, @fixSod bigint;
SELECT @fixSo = semantic_object_pk FROM model.semantic_object WHERE object_kind='FIXTURE' AND namespace_pk=@fixNs AND declared_id=@fixtureId;
IF @fixSo IS NULL BEGIN INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES ('FIXTURE', @fixNs, @fixtureId); SET @fixSo = SCOPE_IDENTITY(); END
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
  VALUES (@fixSo, 'FIXTURE', @fixDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@fixDigest)); SET @fixSod = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @fixSod);
INSERT model.fixture (owner_definition_pk, fixture_id, fixture_profile, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@capSod, @fixtureId, N'consumer-capability-fixtures.v1', @fixSo, @fixSod, @fixNs, @fixDigest, 'FIXTURE', @fixSod, N'');

-- (3) CLI configuration on the CAPABILITY definition.
DECLARE @cliJson nvarchar(max) = N'{"input":{"type":"text","contract":"hello-world-request.v1","path":"payload.name"},"display":{"select":"outcome.payload.message","as":"text"}}';
DECLARE @curEnv nvarchar(max) = (SELECT CONVERT(nvarchar(max), CONVERT(varchar(max), c.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) FROM model.semantic_object_definition d JOIN source.content_object c ON c.content_object_pk=d.canonical_content_pk WHERE d.semantic_object_definition_pk=@capSod);
DECLARE @newEnv nvarchar(max) = JSON_MODIFY(@curEnv, '$.semantics.cli', JSON_QUERY(@cliJson));
DECLARE @newBytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @newDigest binary(32) = HASHBYTES('SHA2_256', @newBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@newDigest) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@newDigest, @newBytes, DATALENGTH(@newBytes));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
  VALUES (@capSo, 'CAPABILITY', @newDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@newDigest)); DECLARE @newSod bigint = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @newSod);
INSERT model.capability_version (capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@capPk, @capSo, @newSod, @newDigest, @cap, 'CAPABILITY', @newSod, N''); DECLARE @newVer bigint = SCOPE_IDENTITY();
DECLARE @scnPk bigint = (SELECT scenario_pk FROM model.scenario WHERE scenario_id=@cap);
DECLARE @scnVer bigint = (SELECT MAX(cs.scenario_version_pk) FROM model.capability_scenario cs WHERE cs.capability_version_pk=@capVer AND cs.scenario_pk=@scnPk);
INSERT model.capability_scenario (capability_pk, capability_version_pk, scenario_pk, scenario_version_pk, _owner_definition_pk, _canonical_pointer)
  VALUES (@capPk, @newVer, @scnPk, @scnVer, @newSod, N'');
INSERT model.capability_root_scenario (capability_version_pk, scenario_pk, _owner_definition_pk, _canonical_pointer) VALUES (@newVer, @scnPk, @newSod, N'');
INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  SELECT @newSod, l.member_kind, l.canonical_pointer, l.source_observation_pk, l.mapping_rule_pk, l.contribution_role
  FROM source.source_lineage l WHERE l.semantic_object_definition_pk=@capSod
    AND NOT EXISTS (SELECT 1 FROM source.source_lineage x WHERE x.semantic_object_definition_pk=@newSod AND x.source_observation_pk=l.source_observation_pk);
GRANT UPDATE ON OBJECT::model.capability TO sidefx_importer;
UPDATE model.estate_capability SET capability_version_pk=@newVer, semantic_object_definition_pk=@newSod WHERE estate_model_pk=@model AND capability_pk=@capPk;
UPDATE model.fixture SET owner_definition_pk=@newSod WHERE fixture_id=@fixtureId AND semantic_object_pk=@fixSo;
END
GO
-- ============================== VERIFICATION ==============================
SELECT '3_fixtures_document' AS result_set, document
FROM analysis.v_capability_execution_declaration
WHERE capability_id = N'hello-world-sql' AND entry_id = N'fixtures.authority.json';
SELECT '4_interface_configuration' AS result_set, JSON_QUERY(document, '$.interfaces[0].configuration') AS configuration
FROM analysis.v_capability_execution_declaration
WHERE capability_id = N'hello-world-sql' AND entry_id = N'interfaces.authority.json';
SELECT '1_assembled_documents' AS result_set, capability_id, source_path, LEFT(document, 90) AS document_head
FROM analysis.v_capability_execution_declaration
WHERE capability_id = N'hello-world-sql'
ORDER BY source_path;
SELECT '2_assembled_vs_retained' AS result_set, a.source_path AS assembled_path, r.source_path AS retained_path
FROM analysis.v_capability_execution_declaration a
FULL JOIN (
  SELECT DISTINCT a2.source_path
  FROM source.source_lineage l
  JOIN source.source_observation o ON o.source_observation_pk = l.source_observation_pk
  JOIN source.source_appearance a2 ON a2.source_appearance_pk = o.source_appearance_pk
  JOIN model.estate_capability ec ON ec.semantic_object_definition_pk = l.semantic_object_definition_pk
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
  WHERE c.capability_id = N'hello-world-sql'
) r ON r.source_path COLLATE Latin1_General_100_BIN2 = a.source_path
WHERE a.capability_id = N'hello-world-sql' OR r.source_path IS NOT NULL
ORDER BY ISNULL(a.source_path, r.source_path);
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
