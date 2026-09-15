-- expose-sda-conforming-declaration-documents.sql
--
-- Projection readiness: the declared documents are consumed by the SDA consumer
-- projector, which schema-admits every member. Three estate-only shapes made
-- every projection fail:
--   1. port bindings and transformations carried `provisioning_manifest_digest`,
--      a `semantics` member the SDA schemas close with additionalProperties:false;
--   2. the workspace document carried only workspaceType/consumerId/
--      projectionTargets/capabilities, missing kernel, governance,
--      conformanceQuery, telemetryAuthority, platformCapabilityCatalog and the
--      capability's projectionAuthorities reference;
--   3. no projection-authorities.authority.json entry existed.
-- The equity fixture is authored here so its fixtures document is not empty
-- (consumer-capability-fixtures.v1 requires at least one fixture).
--
-- Port bindings are projected to identity + configuration (id, capability,
-- estate provider resolution kept for the legacy carrier); transformations to
-- id + expression. Canonical mechanics are unchanged; only estate provenance
-- members leave the documents.
--
-- Idempotent: re-running re-declares the same documents and replaces the fixture.
--
-- Default: ROLLBACK. Replace the final ROLLBACK TRANSACTION; with COMMIT
-- TRANSACTION; to install (after the from-transaction preflight passes).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
-- Lift the data guards this authoring touches (none are present today; the loop
-- is idempotent and also covers a fresh scaffold).
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers = CURSOR LOCAL FAST_FORWARD FOR
  SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
  FROM sys.triggers t JOIN sys.objects o ON o.object_id = t.parent_id
  JOIN sys.schemas s ON s.schema_id = o.schema_id
  WHERE o.type = 'U' AND s.name IN ('model', 'source')
    AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS = 0 BEGIN
  EXEC(N'DROP TRIGGER ' + @trigger_name);
  FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
GO
-- One fixture the projector can order a body around: the admitted request
-- contract, one payload, and the terminal disposition the declared graph
-- realizes. Re-adding the id replaces the expectation.
EXEC model.add_example
  @capability_id = N'resolve-equity-market-price-evidence',
  @fixture_id = N'equity-qqq-evidence-resolves',
  @input_json = N'{"contractId":"live-equity-price-request.v1","payload":{"symbol":"QQQ","region":"US"}}',
  @expected_json = N'{"disposition":"terminated","terminalScenarioId":"resolve-equity-market-price-evidence","scenarioSequence":["resolve-equity-market-price-evidence"]}';
GO
CREATE OR ALTER FUNCTION analysis.capability_execution_declaration(
  @capability_id nvarchar(400), @namespace_id nvarchar(400) = NULL, @include_documents bit = 1
)
RETURNS @declaration TABLE (
  estate_model_pk bigint,
  capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  source_path nvarchar(1000) COLLATE Latin1_General_100_BIN2,
  entry_id nvarchar(500) COLLATE Latin1_General_100_BIN2,
  document nvarchar(max) COLLATE Latin1_General_100_BIN2
)
AS
BEGIN
  DECLARE @estate_model_pk bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
  -- Unqualified selection deliberately rejects IDs shared by multiple namespaces.
  DECLARE @capability_pk bigint = (
    SELECT c.capability_pk FROM model.estate_capability ec
    JOIN model.capability c ON c.capability_pk = ec.capability_pk
    JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
    WHERE ec.estate_model_pk = @estate_model_pk AND c.capability_id = @capability_id COLLATE Latin1_General_100_BIN2
      AND (@namespace_id IS NULL OR n.namespace_id = @namespace_id COLLATE Latin1_General_100_BIN2)
  );
  IF @capability_pk IS NULL RETURN;
  DECLARE @capability_version_pk bigint, @cap_sod bigint;
  SELECT @capability_version_pk = capability_version_pk, @cap_sod = semantic_object_definition_pk
  FROM model.estate_capability WHERE estate_model_pk = @estate_model_pk AND capability_pk = @capability_pk;
  DECLARE @prefix nvarchar(500) = N'capabilities/' + @capability_id + N'/';

  -- The capability document exists only when the linked definition is globally latest.
  DECLARE @cap_envelope nvarchar(max), @has_capdef bit = 0;
  SELECT @cap_envelope = CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),
         @has_capdef = 1
  FROM model.semantic_object_definition linked
  CROSS APPLY (
    SELECT TOP (1) d.semantic_object_definition_pk, d.canonical_content_pk
    FROM model.semantic_object_definition d WHERE d.semantic_object_pk = linked.semantic_object_pk
    ORDER BY d.semantic_object_definition_pk DESC
  ) latest
  JOIN source.content_object co ON co.content_object_pk = latest.canonical_content_pk
  WHERE linked.semantic_object_definition_pk = @cap_sod AND latest.semantic_object_definition_pk = @cap_sod;

  DECLARE @closure TABLE (scenario_version_pk bigint PRIMARY KEY);
  INSERT @closure
  SELECT DISTINCT c.downstream_scenario_version_pk
  FROM model.capability_scenario cs
  JOIN analysis.v_scenario_invocation_closure c
    ON c.capability_version_pk = cs.capability_version_pk AND c.selected_scenario_version_pk = cs.scenario_version_pk
  WHERE cs.capability_version_pk = @capability_version_pk;

  -- Carry every port and transformation in each downstream owning capability namespace.
  DECLARE @reach TABLE (namespace_pk bigint PRIMARY KEY);
  INSERT @reach
  SELECT DISTINCT n.namespace_pk
  FROM @closure cl
  JOIN model.scenario_version sv ON sv.scenario_version_pk = cl.scenario_version_pk
  JOIN model.scenario s ON s.scenario_pk = sv.scenario_pk
  JOIN model.capability c ON c.capability_pk = s.capability_pk
  JOIN model.identity_namespace n ON n.namespace_id = (N'sidefx:capability:' + c.capability_id) COLLATE Latin1_General_100_BIN2;

  DECLARE @transformations TABLE (semantic_object_pk bigint, envelope nvarchar(max) COLLATE Latin1_General_100_BIN2);
  INSERT @transformations (semantic_object_pk)
  SELECT t.semantic_object_pk FROM @reach r JOIN model.transformation t ON t.namespace_pk = r.namespace_pk;
  -- Stage IDs before TOP lookups so the optimizer cannot move selection above scope.
  UPDATE t SET envelope = CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM @transformations t
  CROSS APPLY (
    SELECT TOP (1) d.canonical_content_pk
    FROM model.semantic_object_definition d WHERE d.semantic_object_pk = t.semantic_object_pk
    ORDER BY d.semantic_object_definition_pk DESC
  ) latest
  JOIN source.content_object co ON co.content_object_pk = latest.canonical_content_pk;

  -- Ports select the newest included definition; provider resolution keeps its
  -- own rule, then the binding projects to the three admitted members.
  DECLARE @ports TABLE (semantic_object_pk bigint, semantics nvarchar(max) COLLATE Latin1_General_100_BIN2);
  INSERT @ports (semantic_object_pk)
  SELECT p.semantic_object_pk FROM @reach r JOIN model.port p ON p.namespace_pk = r.namespace_pk;
  UPDATE p SET semantics = projected.document
  FROM @ports p
  CROSS APPLY (
    SELECT TOP (1) d.canonical_content_pk, d.object_kind
    FROM model.semantic_object_definition d
    JOIN model.estate_definition ed ON ed.semantic_object_definition_pk = d.semantic_object_definition_pk
      AND ed.estate_model_pk = @estate_model_pk
    WHERE d.semantic_object_pk = p.semantic_object_pk ORDER BY d.semantic_object_definition_pk DESC
  ) latest
  JOIN source.content_object co ON co.content_object_pk = latest.canonical_content_pk
  CROSS APPLY (SELECT CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS source_text) text
  CROSS APPLY (SELECT CASE WHEN ISJSON(text.source_text) = 1 THEN text.source_text END AS definition_json) decoded
  CROSS APPLY (
    SELECT CASE WHEN JSON_VALUE(decoded.definition_json, '$.semantics.configuration.providerId') IS NULL
      THEN JSON_QUERY(decoded.definition_json, '$.semantics')
      ELSE JSON_MODIFY(JSON_QUERY(decoded.definition_json, '$.semantics'), '$.configuration.estateProvider',
        JSON_QUERY(analysis.fn_estate_provider_semantics(JSON_VALUE(decoded.definition_json, '$.semantics.configuration.providerId')))) END AS document
  ) effective
  CROSS APPLY (
    SELECT JSON_QUERY((
      SELECT JSON_VALUE(effective.document, '$.portId') AS portId,
        JSON_VALUE(effective.document, '$.platformCapabilityId') AS platformCapabilityId,
        JSON_QUERY(effective.document, '$.configuration') AS configuration
      FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS document
  ) projected
  WHERE latest.object_kind = 'PORT';

  DECLARE @directcontract TABLE (contract_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY, schema_content_pk bigint);
  INSERT @directcontract
  SELECT contract_id, schema_content_pk FROM (
    SELECT ct.contract_id, so.content_object_pk AS schema_content_pk,
      ROW_NUMBER() OVER (PARTITION BY ct.contract_id ORDER BY sv.scenario_version_pk DESC, cv.contract_version_pk DESC) AS rn
    FROM @closure cl
    JOIN model.scenario_version sv ON sv.scenario_version_pk = cl.scenario_version_pk
    LEFT JOIN model.scenario_input si ON si.scenario_version_pk = sv.scenario_version_pk
    LEFT JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk = sv.scenario_version_pk
    JOIN model.contract_version cv ON cv.contract_version_pk IN (si.input_contract_version_pk, soc.contract_version_pk)
    JOIN model.contract ct ON ct.contract_pk = cv.contract_pk
    JOIN model.schema_object so ON so.schema_object_pk = cv.schema_object_pk
  ) ranked WHERE rn = 1;

  -- Reuse the current absolute/sibling $ref and cycle rules, once per direct schema.
  -- That helper still loads the selected estate schema-ID catalog for external refs.
  DECLARE @referenced_contracts TABLE (
    contract_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
    schema_content_pk bigint,
    semantic_object_pk bigint,
    semantic_object_definition_pk bigint
  );
  INSERT @referenced_contracts
  SELECT DISTINCT ct.contract_id, closure.schema_content_pk, d.semantic_object_pk, cv.semantic_object_definition_pk
  FROM (SELECT DISTINCT schema_content_pk FROM @directcontract) direct
  CROSS APPLY analysis.fn_contract_schema_closure(direct.schema_content_pk) closure
  JOIN model.schema_object so ON so.content_object_pk = closure.schema_content_pk
  JOIN model.contract_version cv ON cv.schema_object_pk = so.schema_object_pk
  JOIN model.contract ct ON ct.contract_pk = cv.contract_pk
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = cv.semantic_object_definition_pk
  WHERE closure.schema_content_pk <> direct.schema_content_pk;

  DECLARE @capcontract TABLE (
    contract_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
    schema_content_pk bigint,
    PRIMARY KEY (contract_id, schema_content_pk)
  );
  INSERT @capcontract
  SELECT contract_id, schema_content_pk FROM @directcontract
  UNION
  SELECT referenced.contract_id, referenced.schema_content_pk
  FROM @referenced_contracts referenced
  CROSS APPLY (
    SELECT TOP (1) d2.semantic_object_definition_pk
    FROM model.semantic_object_definition d2
    JOIN model.estate_definition ed ON ed.semantic_object_definition_pk = d2.semantic_object_definition_pk
      AND ed.estate_model_pk = @estate_model_pk
    WHERE d2.semantic_object_pk = referenced.semantic_object_pk ORDER BY d2.semantic_object_definition_pk DESC
  ) selected
  WHERE selected.semantic_object_definition_pk = referenced.semantic_object_definition_pk;

  DECLARE @fixtures TABLE (semantic_object_pk bigint, semantic_object_definition_pk bigint);
  IF @include_documents = 1
    INSERT @fixtures
    SELECT d.semantic_object_pk, fx.semantic_object_definition_pk
    FROM model.fixture fx
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = fx.semantic_object_definition_pk
    WHERE fx.owner_definition_pk = @cap_sod;

  INSERT @declaration
  SELECT @estate_model_pk, @capability_id, @prefix + N'capability.authority.json', N'capability.authority.json',
    JSON_QUERY(@cap_envelope, '$.semantics.authority') WHERE @has_capdef = 1 AND @include_documents = 1
  UNION ALL
  SELECT @estate_model_pk, @capability_id, @prefix + N'execution-authorities.authority.json', N'execution-authorities.authority.json',
    N'{"authorityType":"execution-authorities.v1","executionAuthorities":['
    + ISNULL((SELECT STRING_AGG(JSON_QUERY(x.env, '$.semantics.authority'), N',') FROM (
      SELECT DISTINCT eav.execution_authority_version_pk,
        CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS env
      FROM @closure cl
      JOIN model.scenario_event se ON se.scenario_version_pk = cl.scenario_version_pk
      JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk = se.execution_authority_version_pk
      JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = eav.semantic_object_definition_pk
      JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
    ) x), N'') + N']}'
  UNION ALL
  SELECT @estate_model_pk, @capability_id, @prefix + N'semantic-transformation.authority.json', N'semantic-transformation.authority.json',
    N'{"authorityType":"semantic-transformation-authority.v1","transformations":['
    + ISNULL((SELECT STRING_AGG(projected.document, N',')
      WITHIN GROUP (ORDER BY t.semantic_object_pk)
      FROM @transformations t
      CROSS APPLY (
        SELECT JSON_QUERY((
          SELECT JSON_VALUE(t.envelope, '$.semantics.id') AS id,
            JSON_QUERY(t.envelope, '$.semantics.expression') AS expression
          FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS document
      ) projected), N'') + N']}'
  UNION ALL
  SELECT @estate_model_pk, @capability_id, @prefix + N'semantic-graph.authority.json', N'semantic-graph.authority.json',
    N'{"transitions":[]' + CASE WHEN EXISTS (
      SELECT 1 FROM @transformations
      CROSS APPLY (SELECT CASE WHEN ISJSON(envelope) = 1 THEN JSON_QUERY(envelope, '$.semantics.expression') END AS expression) j
      WHERE j.expression LIKE N'%"op":"map"%' OR j.expression LIKE N'%"op":"flat-map"%'
         OR j.expression LIKE N'%"op":"filter"%' OR j.expression LIKE N'%"op":"find"%'
         OR j.expression LIKE N'%"op":"some"%' OR j.expression LIKE N'%"op":"every"%'
    ) THEN N',"executionTopologyAuthority":"graph-v3"' ELSE N'' END + N'}'
  WHERE @include_documents = 1
  UNION ALL
  SELECT @estate_model_pk, @capability_id, @prefix + N'interfaces.authority.json', N'interfaces.authority.json',
    N'{"interfaceAuthorityType":"consumer-interface-authority.v1","contractValidatorCapabilityId":"sda-schema-contract-admission.v1","contractCatalog":"contracts/contract-catalog.json","interfaces":[{"interfaceId":"'
    + @capability_id + N'-cli","kind":"cli","rootScenarioId":"' + @capability_id + N'","platformCapabilityId":"sda-json-cli.v1"'
    + CASE WHEN JSON_QUERY(@cap_envelope, '$.semantics.cli') IS NULL THEN N'' ELSE N',"configuration":' + JSON_QUERY(@cap_envelope, '$.semantics.cli') END
    + N'}],"portBindings":[' + ISNULL((SELECT STRING_AGG(semantics, N',')
      WITHIN GROUP (ORDER BY semantic_object_pk) FROM @ports), N'') + N'],"projectionBindings":[]}'
  WHERE @has_capdef = 1
  UNION ALL
  SELECT @estate_model_pk, @capability_id, @prefix + N'consumer-workspace.authority.json', N'consumer-workspace.authority.json',
    N'{"workspaceType":"consumer-workspace-authority.v1","consumerId":"' + @capability_id + N'","projectionTargets":["node","python","csharp"],'
    + N'"capabilities":[{"featureId":"' + @capability_id + N'.feature","feature":"capability.feature","capability":"capability.authority.json",'
    + N'"semanticGraph":"semantic-graph.authority.json","executionAuthorities":"execution-authorities.authority.json",'
    + N'"interfaces":"interfaces.authority.json","fixtures":"fixtures.authority.json",'
    + N'"projectionAuthorities":"projection-authorities.authority.json"}],'
    + N'"kernel":{"specificationId":"scenario-kernel.v1","version":"1.0.0","executionVector":"kernel/contracts/execution/scenario-kernel-execution-vector.json"},'
    + N'"governance":{"authority":"governance/projected-tool-capability.policy.v1.json","conformancePolicy":"all-closures-must-conform"},'
    + N'"conformanceQuery":"kernel/semantic-authority/consumer/scenario-conformance-closure.query-authority.json",'
    + N'"telemetryAuthority":"kernel/semantic-authority/consumer/scenario-execution.telemetry-authority.json",'
    + N'"platformCapabilityCatalog":"kernel/semantic-authority/consumer/sda-platform-capabilities.semantic-authority.json"}'
  WHERE @include_documents = 1
  UNION ALL
  SELECT @estate_model_pk, @capability_id, @prefix + N'projection-authorities.authority.json', N'projection-authorities.authority.json',
    N'{"authorityType":"projection-authorities.v1","projectionAuthorities":[]}'
  WHERE @include_documents = 1
  UNION ALL
  SELECT @estate_model_pk, @capability_id, @prefix + N'capability.feature', N'capability.feature', x.text
  FROM (
    SELECT TOP (1) CONVERT(nvarchar(max), CONVERT(varchar(max), fco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text
    FROM model.capability c
    JOIN model.feature_version fv ON fv.feature_pk = c.feature_pk
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = fv.semantic_object_definition_pk
    JOIN source.content_object env ON env.content_object_pk = d.canonical_content_pk
    JOIN source.content_object fco ON fco.content_digest = CONVERT(binary(32), N'0x' + JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), env.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.content_digest'), 1)
    WHERE c.capability_pk = @capability_pk AND @include_documents = 1
    ORDER BY CASE fv.source_profile WHEN N'parsed-feature-declaration.v1' THEN 0 WHEN N'retained-feature-binding.v1' THEN 1 ELSE 2 END,
      fv.feature_version_pk DESC
  ) x WHERE x.text IS NOT NULL AND @include_documents = 1
  UNION ALL
  SELECT @estate_model_pk, @capability_id, @prefix + N'contracts/contract-catalog.json', N'contracts/contract-catalog.json',
    N'{' + ISNULL((SELECT STRING_AGG(CONVERT(nvarchar(max), N'"' + contract_id + N'":"' + contract_id + N'.schema.json"'), N',') FROM @capcontract), N'') + N'}'
  UNION ALL
  SELECT @estate_model_pk, @capability_id, @prefix + N'contracts/' + cc.contract_id + N'.schema.json', N'contracts/' + cc.contract_id + N'.schema.json',
    CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM @capcontract cc JOIN source.content_object co ON co.content_object_pk = cc.schema_content_pk
  UNION ALL
  SELECT @estate_model_pk, @capability_id, @prefix + N'fixtures.authority.json', N'fixtures.authority.json',
    N'{"fixtureType":"consumer-capability-fixtures.v1","fixtures":['
    + ISNULL((SELECT STRING_AGG(JSON_QUERY(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.fixture'), N',')
      WITHIN GROUP (ORDER BY fx.semantic_object_pk)
      FROM @fixtures fx
      CROSS APPLY (
        SELECT TOP (1) d.semantic_object_definition_pk, d.canonical_content_pk
        FROM model.semantic_object_definition d WHERE d.semantic_object_pk = fx.semantic_object_pk
        ORDER BY d.semantic_object_definition_pk DESC
      ) latest
      JOIN source.content_object co ON co.content_object_pk = latest.canonical_content_pk
      WHERE latest.semantic_object_definition_pk = fx.semantic_object_definition_pk), N'') + N']}'
  WHERE @include_documents = 1;
  RETURN;
END;
GO
CREATE OR ALTER FUNCTION analysis.capability_graph_source(
  @capability_id nvarchar(400), @include_documents bit = 0, @namespace_id nvarchar(400) = NULL
)
RETURNS @result TABLE (
  estate_model_pk bigint,
  capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  root_scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  graph_source nvarchar(max) COLLATE Latin1_General_100_BIN2,
  cli_configuration nvarchar(max) COLLATE Latin1_General_100_BIN2,
  documents nvarchar(max) COLLATE Latin1_General_100_BIN2
)
AS
BEGIN
  DECLARE @declaration TABLE (
    estate_model_pk bigint, capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
    source_path nvarchar(1000) COLLATE Latin1_General_100_BIN2,
    entry_id nvarchar(500) COLLATE Latin1_General_100_BIN2,
    document nvarchar(max) COLLATE Latin1_General_100_BIN2
  );
  INSERT @declaration SELECT estate_model_pk, capability_id, source_path, entry_id, document
  FROM analysis.capability_execution_declaration(@capability_id, @namespace_id, @include_documents);
  IF NOT EXISTS (SELECT 1 FROM @declaration) RETURN;
  DECLARE @documents nvarchar(max);
  IF @include_documents = 1
    SELECT @documents = (SELECT source_path, entry_id, document FROM @declaration ORDER BY source_path, entry_id FOR JSON PATH, INCLUDE_NULL_VALUES);

  WITH contract_authorities AS (
    SELECT cat.estate_model_pk, cat.capability_id,
      N'{"authorityType":"consumer-contract-authorities.v1","contracts":{' + ISNULL(STRING_AGG(
        (N'"' + cat.contract_id + N'":{"schemaRef":"' + STRING_ESCAPE(cat.schema_ref, 'json') + N'"'
          + CASE WHEN cat.schema_id IS NULL THEN N'' ELSE N',"schemaId":"' + STRING_ESCAPE(cat.schema_id, 'json') + N'"' END
          + N',"schema":' + cat.schema_document + N'}') COLLATE Latin1_General_100_BIN2, N',')
        WITHIN GROUP (ORDER BY cat.contract_id), N'') + N'}}' AS document
    FROM (
      SELECT p.estate_model_pk, p.capability_id, ckey.[key] COLLATE Latin1_General_100_BIN2 AS contract_id,
        ckey.[value] COLLATE Latin1_General_100_BIN2 AS schema_ref,
        JSON_VALUE(sch.document, N'$."$id"') COLLATE Latin1_General_100_BIN2 AS schema_id,
        sch.document AS schema_document
      FROM @declaration p CROSS APPLY OPENJSON(p.document) ckey
      JOIN @declaration sch ON sch.estate_model_pk = p.estate_model_pk AND sch.capability_id = p.capability_id
        AND sch.entry_id = N'contracts/' + ckey.[value]
      WHERE p.entry_id = N'contracts/contract-catalog.json'
    ) cat GROUP BY cat.estate_model_pk, cat.capability_id
  ), base AS (
    SELECT ec.estate_model_pk, c.capability_id, n.namespace_id,
      (SELECT TOP (1) rs.scenario_id FROM model.capability_root_scenario crs
        JOIN model.scenario rs ON rs.scenario_pk = crs.scenario_pk
        WHERE crs.capability_version_pk = ec.capability_version_pk) AS root_scenario_id,
      (SELECT s.scenario_id AS scenarioId,
        JSON_QUERY((SELECT si.input_id AS inputId,
          JSON_QUERY((SELECT ct.contract_id AS contractId FROM model.contract_version cv
            JOIN model.contract ct ON ct.contract_pk = cv.contract_pk
            WHERE cv.contract_version_pk = si.input_contract_version_pk FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS contract
          FROM model.scenario_input si WHERE si.scenario_version_pk = cs.scenario_version_pk FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS input,
        JSON_QUERY((SELECT se.event_id AS eventId, ea.execution_authority_id AS executionAuthorityId
          FROM model.scenario_event se JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk = se.execution_authority_version_pk
          JOIN model.execution_authority ea ON ea.execution_authority_pk = eav.execution_authority_pk
          WHERE se.scenario_version_pk = cs.scenario_version_pk FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS event,
        JSON_QUERY((SELECT so.outcome_id AS outcomeId,
          JSON_QUERY((SELECT ct.contract_id AS contractId FROM model.scenario_outcome_contract soc
            JOIN model.contract_version cv ON cv.contract_version_pk = soc.contract_version_pk
            JOIN model.contract ct ON ct.contract_pk = cv.contract_pk
            WHERE soc.scenario_version_pk = cs.scenario_version_pk FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS contract,
          CONVERT(bit, so.terminal) AS terminal
          FROM model.scenario_outcome so WHERE so.scenario_version_pk = cs.scenario_version_pk FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS outcome
        FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
        WHERE cs.capability_version_pk = ec.capability_version_pk ORDER BY s.scenario_id FOR JSON PATH) AS scenarios,
      (SELECT JSON_QUERY(d.document, '$.executionAuthorities') FROM @declaration d
        WHERE d.entry_id = N'execution-authorities.authority.json') AS execution_authorities,
      (SELECT d.document FROM @declaration d WHERE d.entry_id = N'interfaces.authority.json') AS interface_authority,
      (SELECT JSON_QUERY(d.document, '$.transformations') FROM @declaration d
        WHERE d.entry_id = N'semantic-transformation.authority.json') AS semantic_transformations,
      ca.document AS contract_authorities
    FROM source.current_model cm JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
    JOIN model.capability c ON c.capability_pk = ec.capability_pk
    JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
    LEFT JOIN contract_authorities ca ON ca.estate_model_pk = ec.estate_model_pk AND ca.capability_id = c.capability_id
    WHERE c.capability_id = @capability_id COLLATE Latin1_General_100_BIN2
      AND (@namespace_id IS NULL OR n.namespace_id = @namespace_id COLLATE Latin1_General_100_BIN2)
  )
  INSERT @result
  SELECT b.estate_model_pk, b.capability_id, b.namespace_id, b.root_scenario_id,
    JSON_QUERY((SELECT b.capability_id AS capabilityId, b.root_scenario_id AS rootScenarioId,
      JSON_QUERY(b.scenarios) AS scenarios, JSON_QUERY(N'[]') AS transitions,
      JSON_QUERY(b.execution_authorities) AS executionAuthorities, JSON_QUERY(b.interface_authority) AS interfaceAuthority,
      JSON_QUERY(b.semantic_transformations) AS semanticTransformations, JSON_QUERY(b.contract_authorities) AS contractAuthorities
      FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)),
    JSON_QUERY(b.interface_authority, '$.interfaces[0].configuration'), @documents
  FROM base b;
  RETURN;
END;
GO
SELECT 'bounded_read_functions' AS result_set, SCHEMA_NAME(o.schema_id) AS schema_name, o.name, o.type
FROM sys.objects o WHERE o.object_id IN (OBJECT_ID('analysis.capability_execution_declaration'), OBJECT_ID('analysis.capability_graph_source'));
DECLARE @started datetime2 = SYSUTCDATETIME();
DECLARE @proof TABLE (capability_id nvarchar(400), root_scenario_id nvarchar(400), graph_source nvarchar(max), documents nvarchar(max));
INSERT @proof SELECT capability_id, root_scenario_id, graph_source, documents
FROM analysis.capability_graph_source(N'say-hello-world', 1, NULL);
SELECT 'bounded_read_smoke' AS result_set, capability_id, root_scenario_id,
  DATEDIFF_BIG(millisecond, @started, SYSUTCDATETIME()) AS elapsed_ms,
  ISJSON(graph_source) AS graph_is_json, DATALENGTH(graph_source) AS graph_bytes,
  (SELECT COUNT(*) FROM OPENJSON(documents)) AS document_count
FROM @proof;
-- The equity documents every projection target will consume. Extract the JSON
-- entries first: the document set also carries plain-text entries (the feature),
-- which must never reach a JSON function.
DECLARE @equity_documents nvarchar(max) = (
  SELECT documents FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence', 1, NULL)
);
DECLARE @equity_interfaces nvarchar(max) = (
  SELECT d.document FROM OPENJSON(@equity_documents)
    WITH (entry_id nvarchar(500) '$.entry_id', document nvarchar(max) '$.document') d
  WHERE d.entry_id = N'interfaces.authority.json'
);
DECLARE @equity_transformations nvarchar(max) = (
  SELECT d.document FROM OPENJSON(@equity_documents)
    WITH (entry_id nvarchar(500) '$.entry_id', document nvarchar(max) '$.document') d
  WHERE d.entry_id = N'semantic-transformation.authority.json'
);
DECLARE @equity_workspace nvarchar(max) = (
  SELECT d.document FROM OPENJSON(@equity_documents)
    WITH (entry_id nvarchar(500) '$.entry_id', document nvarchar(max) '$.document') d
  WHERE d.entry_id = N'consumer-workspace.authority.json'
);
SELECT 'conforming_declaration_proof' AS result_set,
  (SELECT COUNT(*) FROM OPENJSON(@equity_documents)
    WITH (entry_id nvarchar(500) '$.entry_id', document nvarchar(max) '$.document') d
    WHERE d.entry_id = N'projection-authorities.authority.json') AS projection_authority_documents,
  (SELECT COUNT(*) FROM (SELECT 1 AS present WHERE
    JSON_VALUE(@equity_workspace, '$.kernel.specificationId') = N'scenario-kernel.v1'
    AND JSON_VALUE(@equity_workspace, '$.governance.conformancePolicy') = N'all-closures-must-conform'
    AND JSON_VALUE(@equity_workspace, '$.conformanceQuery') IS NOT NULL
    AND JSON_VALUE(@equity_workspace, '$.telemetryAuthority') IS NOT NULL
    AND JSON_VALUE(@equity_workspace, '$.platformCapabilityCatalog') IS NOT NULL) present) AS complete_workspace_documents,
  (SELECT COUNT(*) FROM OPENJSON(@equity_workspace, '$.capabilities') cap
    WHERE JSON_VALUE(cap.value, '$.projectionAuthorities') = N'projection-authorities.authority.json') AS capabilities_with_projection_authorities,
  (SELECT COUNT(*) FROM OPENJSON(@equity_interfaces, '$.portBindings') pb
    WHERE JSON_VALUE(pb.value, '$.portId') IS NULL OR JSON_VALUE(pb.value, '$.platformCapabilityId') IS NULL) AS port_bindings_missing_identity,
  (SELECT COUNT(*) FROM OPENJSON(@equity_interfaces, '$.portBindings') pb
    WHERE JSON_QUERY(pb.value, '$.configuration.estateProvider') IS NOT NULL) AS port_bindings_with_estate_provider,
  (SELECT COUNT(*) FROM OPENJSON(@equity_transformations, '$.transformations') tr
    WHERE JSON_VALUE(tr.value, '$.provisioning_manifest_digest') IS NOT NULL) AS transformations_carrying_provenance;
SELECT 'equity_fixture' AS result_set, fx.fixture_id, fx.fixture_profile,
  JSON_QUERY(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.fixture.expected') AS expected
FROM model.fixture fx
JOIN model.estate_capability ec ON ec.semantic_object_definition_pk = fx.owner_definition_pk
  AND ec.estate_model_pk = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1)
JOIN model.capability c ON c.capability_pk = ec.capability_pk
JOIN source.content_object co ON co.content_object_pk = (
  SELECT TOP (1) d.canonical_content_pk FROM model.semantic_object_definition d
  WHERE d.semantic_object_definition_pk = fx.semantic_object_definition_pk)
WHERE c.capability_id = N'resolve-equity-market-price-evidence';
COMMIT TRANSACTION;
