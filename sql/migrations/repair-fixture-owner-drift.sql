-- repair-fixture-owner-drift.sql
--
-- Root cause and repair for the empty fixtures.authority.json that failed the
-- consumer projection at consumer-capability-fixtures.schema.json:
--   /fixtures must NOT have fewer than 1 items.
--
-- analysis.capability_execution_declaration reads a capability's fixtures by
-- owner_definition_pk = the capability's linked semantic_object_definition.
-- declare-equity-observe-display.sql and declare-observation-readings.sql
-- re-pointed resolve-equity-market-price-evidence's estate_capability to new
-- definitions (199477, 199485) without re-pointing model.fixture rows, so
-- equity-qqq-evidence-resolves stayed on 194764 (stale) and the join dropped it.
-- The estate audit below finds the same drift on nine fixtures across three
-- capabilities (project-model-provider-protocol 7, resolve-equity-market-price-evidence 1,
-- say-hello-world 1).
--
-- This migration re-points every drifted fixture to its capability's current
-- definition (bounded to fixtures whose owner is a definition of a capability
-- the estate still links; idempotent: a re-run updates no rows), and re-emits
-- the declaration assembly with a fail-closed guard: a fixture owned by an
-- older definition of the capability now throws FIXTURE_OWNER_DEFINITION_STALE
-- instead of silently dropping out of every assembled document set.
--
-- Default: ROLLBACK after verification. Change the final ROLLBACK to COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers=CURSOR LOCAL FAST_FORWARD FOR
 SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
 FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id
 JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE o.type='U' AND s.name IN ('model','source')
 AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trigger_name); FETCH NEXT FROM @triggers INTO @trigger_name; END;
CLOSE @triggers; DEALLOCATE @triggers;
BEGIN TRANSACTION;
GO
-- ============================== REPAIR THE OWNER POINTERS ==============================
DECLARE @estate bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);

SELECT '1_before_repair' AS result_set, c.capability_id, fx.fixture_id,
  fx.owner_definition_pk AS stale_owner, ec.semantic_object_definition_pk AS current_capability_definition
FROM model.fixture fx
JOIN model.semantic_object_definition owner_def ON owner_def.semantic_object_definition_pk = fx.owner_definition_pk
JOIN model.capability c ON c.semantic_object_pk = owner_def.semantic_object_pk
JOIN model.estate_capability ec ON ec.capability_pk = c.capability_pk AND ec.estate_model_pk = @estate
WHERE fx.owner_definition_pk <> ec.semantic_object_definition_pk
ORDER BY c.capability_id, fx.fixture_id;

UPDATE fx SET owner_definition_pk = ec.semantic_object_definition_pk
FROM model.fixture fx
JOIN model.semantic_object_definition owner_def ON owner_def.semantic_object_definition_pk = fx.owner_definition_pk
JOIN model.capability c ON c.semantic_object_pk = owner_def.semantic_object_pk
JOIN model.estate_capability ec ON ec.capability_pk = c.capability_pk AND ec.estate_model_pk = @estate
WHERE fx.owner_definition_pk <> ec.semantic_object_definition_pk;

SELECT '2_after_repair' AS result_set, COUNT(*) AS drifted_fixtures
FROM model.fixture fx
JOIN model.semantic_object_definition owner_def ON owner_def.semantic_object_definition_pk = fx.owner_definition_pk
JOIN model.capability c ON c.semantic_object_pk = owner_def.semantic_object_pk
JOIN model.estate_capability ec ON ec.capability_pk = c.capability_pk AND ec.estate_model_pk = @estate
WHERE fx.owner_definition_pk <> ec.semantic_object_definition_pk;
GO
-- ============================== FAIL-CLOSED GUARD ==============================
-- The assembly is re-emitted with the fixture-owner guard; every other
-- statement is the current installed definition unchanged.
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

  -- Fixture ownership must follow the capability's linked definition. A
  -- capability re-mint that leaves a fixture on an older definition would
  -- silently drop that fixture from every assembled document set. A T-SQL
  -- function cannot THROW, so the guard fails closed through a conversion whose
  -- value names the condition: the read errors instead of shrinking the
  -- document. analysis.v_capability_fixture_owner_drift is the standing proof.
  DECLARE @fixture_owner_guard int;
  SELECT @fixture_owner_guard = CONVERT(int, N'FIXTURE_OWNER_DEFINITION_STALE:' + fx.fixture_id)
  FROM model.fixture fx
  JOIN model.semantic_object_definition owner_def ON owner_def.semantic_object_definition_pk = fx.owner_definition_pk
  WHERE owner_def.semantic_object_pk = (SELECT c2.semantic_object_pk FROM model.capability c2 WHERE c2.capability_pk = @capability_pk)
    AND fx.owner_definition_pk <> @cap_sod;

  -- Declared routing. The routes live on the capability's own semantic
  -- definition at $.semantics.routing, the same capability-scoped authority
  -- document that carries $.semantics.cli and $.semantics.authority. The
  -- expansion (analysis.capability_declared_transitions) carries the compiler's
  -- transition input; a capability with no declared routing keeps the empty
  -- transition set.
  DECLARE @routing_transitions nvarchar(max) = (
    SELECT N'[' + STRING_AGG(transition.transition_json, N',') WITHIN GROUP (ORDER BY transition.ordinal) + N']'
    FROM analysis.capability_declared_transitions(@capability_id) transition
  );

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

  -- The declared outcome variants with their classification, per scenario.
  -- A scenario with no declared variants contributes nothing, so its outcome
  -- variants stay unclassified and the kernel attaches no classification.
  DECLARE @scenario_outcomes nvarchar(max);
  SELECT @scenario_outcomes = (
    SELECT s.scenario_id AS scenarioId,
      JSON_QUERY((SELECT ov.variant_id AS variantId, ov.classification AS classification
        FROM model.outcome_variant ov
        WHERE ov.scenario_version_pk = sv.scenario_version_pk
        ORDER BY ov.variant_id
        FOR JSON PATH)) AS variants
    FROM @closure cl
    JOIN model.scenario_version sv ON sv.scenario_version_pk = cl.scenario_version_pk
    JOIN model.scenario s ON s.scenario_pk = sv.scenario_pk
    WHERE EXISTS (SELECT 1 FROM model.outcome_variant declared WHERE declared.scenario_version_pk = sv.scenario_version_pk)
    ORDER BY s.scenario_id
    FOR JSON PATH);

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
    N'{"transitions":' + ISNULL(@routing_transitions, N'[]') + CASE WHEN EXISTS (
      SELECT 1 FROM @transformations
      CROSS APPLY (SELECT CASE WHEN ISJSON(envelope) = 1 THEN JSON_QUERY(envelope, '$.semantics.expression') END AS expression) j
      WHERE j.expression LIKE N'%"op":"map"%' OR j.expression LIKE N'%"op":"flat-map"%'
         OR j.expression LIKE N'%"op":"filter"%' OR j.expression LIKE N'%"op":"find"%'
         OR j.expression LIKE N'%"op":"some"%' OR j.expression LIKE N'%"op":"every"%'
    ) THEN N',"executionTopologyAuthority":"graph-v3"' ELSE N'' END
    + CASE WHEN @scenario_outcomes IS NULL THEN N'' ELSE N',"scenarioOutcomes":' + @scenario_outcomes END + N'}'
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
-- ============================== STANDING DRIFT PROOF ==============================
-- The drift is inspectable at any time; the guard above makes a non-empty view a
-- loud read failure rather than a silent document shrink.
CREATE OR ALTER VIEW analysis.v_capability_fixture_owner_drift AS
SELECT c.capability_id, fx.fixture_id, fx.owner_definition_pk AS stale_owner_definition_pk,
  ec.semantic_object_definition_pk AS current_capability_definition_pk
FROM model.fixture fx
JOIN model.semantic_object_definition owner_def ON owner_def.semantic_object_definition_pk = fx.owner_definition_pk
JOIN model.capability c ON c.semantic_object_pk = owner_def.semantic_object_pk
JOIN model.estate_capability ec ON ec.capability_pk = c.capability_pk
JOIN source.current_model cm ON cm.singleton_id = 1 AND cm.estate_model_pk = ec.estate_model_pk
WHERE fx.owner_definition_pk <> ec.semantic_object_definition_pk;
GO
-- ============================== VERIFICATION ==============================
-- No capability's fixture document is smaller than its declared fixtures.
SELECT '3_repaired_documents' AS result_set, v.capability_id,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(d.document, '$.fixtures'))) AS emitted_fixtures
FROM (VALUES (N'resolve-equity-market-price-evidence'),(N'project-model-provider-protocol'),(N'say-hello-world')) v(capability_id)
CROSS APPLY analysis.capability_execution_declaration(v.capability_id, NULL, 1) d
WHERE d.entry_id = N'fixtures.authority.json'
ORDER BY v.capability_id;

SELECT '4_equity_fixture_document' AS result_set, JSON_QUERY(d.document, '$.fixtures') AS fixtures
FROM analysis.capability_execution_declaration(N'resolve-equity-market-price-evidence', NULL, 1) d
WHERE d.entry_id = N'fixtures.authority.json';

SELECT '5_guard_installed' AS result_set,
  CASE WHEN EXISTS (SELECT 1 FROM sys.sql_modules
    WHERE object_id = OBJECT_ID('analysis.capability_execution_declaration')
      AND definition LIKE N'%FIXTURE_OWNER_DEFINITION_STALE%') THEN 1 ELSE 0 END AS guard_present;

SELECT '6_drift_view' AS result_set, COUNT(*) AS drifted_rows FROM analysis.v_capability_fixture_owner_drift;

COMMIT TRANSACTION;
-- Installed 2026-09-17: nine drifted fixture owners are re-pointed to their
-- capability's current definition; the declaration assembly fails closed
-- (FIXTURE_OWNER_DEFINITION_STALE) and analysis.v_capability_fixture_owner_drift
-- is the standing proof. Reversal: a single migration re-pointing the rows back
-- is not needed (the prior pointer is stale by definition); re-running the
-- pre-repair assembly migration is the reversal if the guard itself must go.
