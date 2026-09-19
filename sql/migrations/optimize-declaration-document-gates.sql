-- optimize-declaration-document-gates.sql
--
-- `analysis.capability_execution_declaration(..., @include_documents = 0)` is the
-- authority read the agent lane pays on every invocation (`readAuthority` ->
-- `capability-authority`): it assembles the graph source the C# kernel compiles.
-- With `@include_documents = 0` the function still expanded two document-only
-- members for the `semantic-graph.authority.json` document, which is emitted
-- only when `@include_documents = 1`:
--
--   * `analysis.capability_declared_transitions` (measured 39.3 ms for the lane);
--   * the per-scenario outcome-variant expansion.
--
-- `analysis.capability_graph_source` expands the transitions itself and never
-- reads the document, so gating both expansions on `@include_documents = 1` is
-- output-identical. The proof below captures every graph source for an
-- eight-capability probe byte-for-byte before and after and fails closed on any
-- difference.
--
-- Profiling the remaining cost (evidence/vault-20260916/lane-relevance/)
-- shows the graph source is 25,012,763 characters, of which 24,924,420 are two
-- `sda-projected-capability-invocation-port.v2` bindings
-- (`obtain-governed-model-response-port`, `obtain-fallback-model-response-port`)
-- each carrying a 12,412,7xx-character composed `declaredApplication`. A
-- declared fast path that emitted the stored `$.semantics` for
-- provider-less bindings (JSON key order only; the kernel canonicalizes keys
-- before every digest) was measured at 40,589.7 ms versus 10,868.9 ms for the
-- installed projection, because the two-UPDATE shape parsed each 12 MB binding
-- twice. It was reverted; the material graph-source lever is named as a
-- platform-mechanic request in the lane-relevance report: the projected
-- invocation port must accept a digest-resolved `declaredApplication`
-- reference instead of 12.4 MB of inline configuration.
--
-- Idempotent: a re-run captures the already-optimized function as "before" and
-- "after" and re-declares the same bytes.
--
-- Lifecycle: default ROLLBACK. Installed after the rollback dry run and the
-- from-transaction preflight (hello triple, equity c507678e, observe 26c85c04).
--
-- Proof result sets:
--   1_equality    every probe capability's graph source, before vs after
--   2_timing      the lane and hello graph-source reads, before vs after
--   3_claim       the retained body gates the document-only expansions
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
-- ============================== BEFORE ==============================
IF OBJECT_ID('tempdb..#graph_before') IS NOT NULL DROP TABLE #graph_before;
IF OBJECT_ID('tempdb..#graph_after') IS NOT NULL DROP TABLE #graph_after;
IF OBJECT_ID('tempdb..#timing') IS NOT NULL DROP TABLE #timing;
CREATE TABLE #graph_before (capability_id nvarchar(400) PRIMARY KEY, graph_digest varchar(80));
CREATE TABLE #graph_after (capability_id nvarchar(400) PRIMARY KEY, graph_digest varchar(80));
CREATE TABLE #timing (phase nvarchar(60) PRIMARY KEY, milliseconds decimal(18,3));
DECLARE @caps TABLE (ord int identity, capability_id nvarchar(400));
INSERT @caps(capability_id) VALUES
 (N'say-hello-world'),(N'resolve-equity-market-price-evidence'),
 (N'request-capability-from-objective'),(N'compose-resolve-equity-market-price-evidence'),
 (N'read-capability-circuit'),(N'read-observation-projection'),
 (N'read-observation-telemetry-authority'),(N'project-model-provider-protocol');
DECLARE @cap nvarchar(400), @v nvarchar(max), @t0 datetime2(7), @t1 datetime2(7);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT capability_id FROM @caps ORDER BY ord;
OPEN cur; FETCH NEXT FROM cur INTO @cap;
WHILE @@FETCH_STATUS=0
BEGIN
 SELECT @v=graph_source FROM analysis.capability_graph_source(@cap,0,N'sidefx:capabilities');
 INSERT #graph_before VALUES(@cap,
  'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@v)),2)));
 FETCH NEXT FROM cur INTO @cap;
END
CLOSE cur; DEALLOCATE cur;
SET @t0=SYSDATETIME();
SELECT @v=graph_source FROM analysis.capability_graph_source(N'request-capability-from-objective',0,N'sidefx:capabilities');
SET @t1=SYSDATETIME();
INSERT #timing VALUES('before_agent',DATEDIFF_BIG(microsecond,@t0,@t1)/1000.0);
SET @t0=SYSDATETIME();
SELECT @v=graph_source FROM analysis.capability_graph_source(N'say-hello-world',0,N'sidefx:capabilities');
SET @t1=SYSDATETIME();
INSERT #timing VALUES('before_hello',DATEDIFF_BIG(microsecond,@t0,@t1)/1000.0);
GO
-- ============================== THE SINGLE DECLARATION READ ==============================
-- The installed definition with exactly one change: the two document-only
-- expansions run only when documents are requested.
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

  -- Declared routing. Document-only: analysis.capability_graph_source expands
  -- the transitions itself, so this runs only for the document mode that emits
  -- semantic-graph.authority.json.
  DECLARE @routing_transitions nvarchar(max);
  IF @include_documents = 1
    SET @routing_transitions = (
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
  -- Document-only; see the routing expansion above.
  DECLARE @scenario_outcomes nvarchar(max);
  IF @include_documents = 1
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
-- ============================== AFTER AND IN-TRANSACTION PREFLIGHT ==============================
DECLARE @caps2 TABLE (ord int identity, capability_id nvarchar(400));
INSERT @caps2(capability_id) VALUES
 (N'say-hello-world'),(N'resolve-equity-market-price-evidence'),
 (N'request-capability-from-objective'),(N'compose-resolve-equity-market-price-evidence'),
 (N'read-capability-circuit'),(N'read-observation-projection'),
 (N'read-observation-telemetry-authority'),(N'project-model-provider-protocol');
DECLARE @cap2 nvarchar(400), @v2 nvarchar(max), @ta datetime2(7), @tb datetime2(7);
DECLARE cur2 CURSOR LOCAL FAST_FORWARD FOR SELECT capability_id FROM @caps2 ORDER BY ord;
OPEN cur2; FETCH NEXT FROM cur2 INTO @cap2;
WHILE @@FETCH_STATUS=0
BEGIN
 SELECT @v2=graph_source FROM analysis.capability_graph_source(@cap2,0,N'sidefx:capabilities');
 INSERT #graph_after VALUES(@cap2,
  'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@v2)),2)));
 FETCH NEXT FROM cur2 INTO @cap2;
END
CLOSE cur2; DEALLOCATE cur2;
SET @ta=SYSDATETIME();
SELECT @v2=graph_source FROM analysis.capability_graph_source(N'request-capability-from-objective',0,N'sidefx:capabilities');
SET @tb=SYSDATETIME();
INSERT #timing VALUES('after_agent',DATEDIFF_BIG(microsecond,@ta,@tb)/1000.0);
SET @ta=SYSDATETIME();
SELECT @v2=graph_source FROM analysis.capability_graph_source(N'say-hello-world',0,N'sidefx:capabilities');
SET @tb=SYSDATETIME();
INSERT #timing VALUES('after_hello',DATEDIFF_BIG(microsecond,@ta,@tb)/1000.0);

IF EXISTS (
 SELECT 1 FROM #graph_before b FULL JOIN #graph_after a ON a.capability_id=b.capability_id
 WHERE b.capability_id IS NULL OR a.capability_id IS NULL OR b.graph_digest<>a.graph_digest
) THROW 51000,N'GRAPH_SOURCE_DIVERGED',1;
IF (SELECT COUNT(*) FROM #graph_after)<>8 THROW 51000,N'GRAPH_SOURCE_PROBE_INCOMPLETE',1;

DECLARE @body nvarchar(max)=OBJECT_DEFINITION(OBJECT_ID('analysis.capability_execution_declaration'));
IF CHARINDEX(N'DECLARE @routing_transitions nvarchar(max);',@body)=0 THROW 51000,N'DECLARATION_ROUTING_NOT_GATED',1;
IF CHARINDEX(N'DECLARE @scenario_outcomes nvarchar(max);',@body)=0 THROW 51000,N'DECLARATION_OUTCOMES_NOT_GATED',1;
IF CHARINDEX(N'FIXTURE_OWNER_DEFINITION_STALE',@body)=0 THROW 51000,N'DECLARATION_FIXTURE_GUARD_LOST',1;

-- ============================== PROOF ==============================
SELECT '1_equality' AS result_set, b.capability_id,
 b.graph_digest AS before_graph_digest, a.graph_digest AS after_graph_digest,
 CONVERT(bit,CASE WHEN b.graph_digest=a.graph_digest THEN 1 ELSE 0 END) AS identical
FROM #graph_before b JOIN #graph_after a ON a.capability_id=b.capability_id
ORDER BY b.capability_id;

SELECT '2_timing' AS result_set, phase, milliseconds FROM #timing ORDER BY phase;

SELECT '3_claim' AS result_set,
 CONVERT(bit,CASE WHEN CHARINDEX(N'DECLARE @routing_transitions nvarchar(max);',@body)>0 THEN 1 ELSE 0 END) AS routing_expansion_gated,
 CONVERT(bit,CASE WHEN CHARINDEX(N'DECLARE @scenario_outcomes nvarchar(max);',@body)>0 THEN 1 ELSE 0 END) AS outcome_expansion_gated,
 CONVERT(bit,CASE WHEN CHARINDEX(N'FIXTURE_OWNER_DEFINITION_STALE',@body)>0 THEN 1 ELSE 0 END) AS fixture_guard_retained,
 LEN(@body) AS function_chars;

COMMIT TRANSACTION;
-- Installed after the rollback dry run and the from-transaction preflight:
-- eight probe graph sources byte-identical; the declared-transitions expansion
-- measured 39.3 ms (lane) and no longer runs with @include_documents = 0; the
-- hello triple and the equity c507678e / observe 26c85c04 observed path
-- digests were unchanged. The lane graph-source read itself stayed in its
-- measured 8-13 s warm band: 24,924,420 of its 25,012,763 characters are two
-- inline 12.4 MB sda-projected-capability-invocation-port.v2 bindings, which is
-- named as a platform-mechanic request in
-- evidence/vault-20260916/lane-relevance/report.md.
