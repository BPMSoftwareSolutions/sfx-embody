-- declare-model-provider-protocol-routing.sql
--
-- Declares the selection routing of the declared model-provider protocol
-- projection: the capability's root scenario routes on its declared outcome
-- variants, and each variant selects the sibling scenario that performs that
-- request type. The estate's graph-source assembly emitted an empty transition
-- set for every capability, so the compiled graph rejected every sibling
-- scenario as UNREACHABLE_CELL and the capability could not be projected or
-- invoked. This migration declares the transitions for the one capability the
-- verifier needs, in the assembly itself, following the graph-native topology
-- precedent (declare-graph-native-consumer-topology.sql).
--
-- The declared mapping is the projection transformation's own requestType
-- vocabulary (transform-model-provider-protocol-projection) matched to the
-- sibling scenario ids; every sibling target is a declared scenario of the same
-- capability and every variant is a declared outcome variant of the root.
--
--   variant                              -> sibling scenario
--   normalize-gemini-blocking            -> normalize-gemini-blocking-finish-testimony
--   normalize-model-response-format      -> normalize-model-response-format
--   normalize-observation                -> normalize-gemini-success-testimony
--   normalize-provider-http-failure      -> normalize-provider-http-failure-testimony
--   normalize-provider-transport         -> normalize-provider-transport-testimony
--   project-gemini-endpoint              -> project-gemini-endpoint-and-credential-rule
--   project-gemini-structured            -> project-gemini-structured-request
--   project-gemini-text                  -> project-gemini-text-request
--   project-openai-structured            -> project-openai-structured-request
--   project-openai-text                  -> project-openai-text-request
--   prove-determinism                    -> prove-deterministic-protocol-projection
--   prove-effects                        -> prove-no-http-effect-in-protocol-projection
--   reject-unsupported-adapter-authority -> reject-unsupported-adapter-authority
--   reject-unsupported-interaction-mode  -> reject-unsupported-interaction-mode
--   reject-unsupported-provider          -> reject-unsupported-provider-protocol
--   reject-unsupported-schema-vocabulary -> reject-unsupported-schema-vocabulary
--
-- The route carrier is also repaired to be admissible as the sibling
-- scenarios' declared input contract: the route projection merges the route
-- variant onto the input carrier and the root scenario declares the shared
-- input contract as its outcome contract. Cross-contract selection edges would
-- otherwise require a binding authority the estate does not declare.
--
-- Idempotent: CREATE OR ALTER replaces the assembly in place, the projection
-- declaration digest gate returns UNCHANGED on replay and the outcome-contract
-- update is a fixed assignment; a second run emits the same definitions and the
-- same transitions. A capability with no declared routing keeps the empty
-- transition set.
--
-- Default: ROLLBACK. Install only after the from-transaction preflight passes:
--   node scripts/run-migration.mjs sql/migrations/declare-model-provider-protocol-routing.sql
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
-- The route projection returns the input carrier with the route variant.
DECLARE @route_semantics nvarchar(max) = N'{"id":"transform-model-provider-protocol-route","expression":{"op":"merge","values":[{"from":"input","op":"path","path":""},{"op":"object","fields":{"route":{"from":"input","op":"path","path":"payload.requestType"}}}]}}';
DECLARE @route_object bigint, @route_definition bigint, @route_digest binary(32);
EXEC model.put_semantic_definition 'TRANSFORMATION', N'sidefx:capability:project-model-provider-protocol',
  N'transform-model-provider-protocol-route', @route_semantics,
  @route_object OUTPUT, @route_definition OUTPUT, @route_digest OUTPUT;
-- The root scenario declares the shared input contract as its outcome contract.
DECLARE @root_scenario_version bigint = (
  SELECT TOP 1 sv.scenario_version_pk
  FROM model.estate_capability ec
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
  JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk
  JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
  JOIN model.scenario_version sv ON sv.scenario_version_pk = cs.scenario_version_pk
  WHERE ec.estate_model_pk = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1)
    AND c.capability_id = N'project-model-provider-protocol'
    AND s.scenario_id = N'project-model-provider-protocol');
DECLARE @input_contract_version bigint = (
  SELECT cv.contract_version_pk FROM model.contract c
  JOIN model.contract_version cv ON cv.contract_pk = c.contract_pk
  WHERE c.contract_id = N'project-model-provider-protocol-input.v1');
IF @root_scenario_version IS NULL OR @input_contract_version IS NULL THROW 51000, 'MODEL_PROVIDER_PROTOCOL_ROUTE_TARGET_MISSING', 1;
UPDATE model.scenario_outcome_contract SET contract_version_pk = @input_contract_version
  WHERE scenario_version_pk = @root_scenario_version;
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

  -- Declared selection routing. The route outcome's variant selects the sibling
  -- scenario that performs that request type; the mapping rows below are the
  -- declared authority for each capability that routes. A capability with no
  -- declared routing keeps the empty transition set.
  DECLARE @routing_transitions nvarchar(max) = (
    SELECT declared.transitions
    FROM (VALUES
      (N'project-model-provider-protocol', N'[{"transitionId":"route-normalize-gemini-blocking","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"normalize-gemini-blocking-finish-testimony","inputId":"gemini-blocking-finish-normalization","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"normalize-gemini-blocking"},{"transitionId":"route-normalize-model-response-format","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"normalize-model-response-format","inputId":"model-response-format-normalization","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"normalize-model-response-format"},{"transitionId":"route-normalize-observation","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"normalize-gemini-success-testimony","inputId":"gemini-success-observation-normalization","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"normalize-observation"},{"transitionId":"route-normalize-provider-http-failure","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"normalize-provider-http-failure-testimony","inputId":"provider-http-failure-normalization","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"normalize-provider-http-failure"},{"transitionId":"route-normalize-provider-transport","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"normalize-provider-transport-testimony","inputId":"provider-transport-failure-normalization","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"normalize-provider-transport"},{"transitionId":"route-project-gemini-endpoint","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"project-gemini-endpoint-and-credential-rule","inputId":"gemini-endpoint-protocol-projection-request","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"project-gemini-endpoint"},{"transitionId":"route-project-gemini-structured","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"project-gemini-structured-request","inputId":"gemini-structured-protocol-projection-request","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"project-gemini-structured"},{"transitionId":"route-project-gemini-text","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"project-gemini-text-request","inputId":"gemini-text-protocol-projection-request","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"project-gemini-text"},{"transitionId":"route-project-openai-structured","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"project-openai-structured-request","inputId":"openai-structured-protocol-projection-request","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"project-openai-structured"},{"transitionId":"route-project-openai-text","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"project-openai-text-request","inputId":"openai-text-protocol-projection-request","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"project-openai-text"},{"transitionId":"route-prove-determinism","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"prove-deterministic-protocol-projection","inputId":"deterministic-protocol-projection-observations","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"prove-determinism"},{"transitionId":"route-prove-effects","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"prove-no-http-effect-in-protocol-projection","inputId":"protocol-projection-effect-observations","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"prove-effects"},{"transitionId":"route-reject-unsupported-adapter-authority","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"reject-unsupported-adapter-authority","inputId":"unsupported-adapter-authority-projection","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"reject-unsupported-adapter-authority"},{"transitionId":"route-reject-unsupported-interaction-mode","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"reject-unsupported-interaction-mode","inputId":"unsupported-interaction-mode-projection","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"reject-unsupported-interaction-mode"},{"transitionId":"route-reject-unsupported-provider","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"reject-unsupported-provider-protocol","inputId":"unsupported-provider-protocol-projection","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"reject-unsupported-provider"},{"transitionId":"route-reject-unsupported-schema-vocabulary","from":{"scenarioId":"project-model-provider-protocol","outcomeId":"model-provider-protocol-route"},"to":{"scenarioId":"reject-unsupported-schema-vocabulary","inputId":"unsupported-schema-vocabulary-projection","contractId":"project-model-provider-protocol-input.v1"},"semanticProgress":"declared","topologyKind":"selection","selectsVariant":"reject-unsupported-schema-vocabulary"}]')
    ) AS declared(capability_id, transitions)
    WHERE declared.capability_id = @capability_id COLLATE Latin1_General_100_BIN2
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
      (SELECT s.scenario_id AS scenarioId,
        JSON_QUERY((SELECT ov.variant_id AS variantId, ov.classification AS classification
          FROM model.outcome_variant ov WHERE ov.scenario_version_pk = sv.scenario_version_pk
          ORDER BY ov.variant_id FOR JSON PATH)) AS variants
        FROM model.capability_scenario cs
        JOIN model.scenario_version sv ON sv.scenario_version_pk = cs.scenario_version_pk
        JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
        WHERE cs.capability_version_pk = ec.capability_version_pk
          AND EXISTS (SELECT 1 FROM model.outcome_variant declared WHERE declared.scenario_version_pk = sv.scenario_version_pk)
        ORDER BY s.scenario_id FOR JSON PATH) AS scenario_outcomes,
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
      JSON_QUERY(b.scenarios) AS scenarios, JSON_QUERY(b.scenario_outcomes) AS scenarioOutcomes,
      JSON_QUERY((SELECT JSON_QUERY(d.document, '$.transitions')
        FROM analysis.capability_execution_declaration(@capability_id, @namespace_id, 1) d
        WHERE d.entry_id = N'semantic-graph.authority.json')) AS transitions,
      JSON_QUERY(b.execution_authorities) AS executionAuthorities, JSON_QUERY(b.interface_authority) AS interfaceAuthority,
      JSON_QUERY(b.semantic_transformations) AS semanticTransformations, JSON_QUERY(b.contract_authorities) AS contractAuthorities
      FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)),
    JSON_QUERY(b.interface_authority, '$.interfaces[0].configuration'), @documents
  FROM base b;
  RETURN;
END;
GO
-- ============================== VERIFICATION ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
SELECT '0_root_outcome_contract' AS result_set, s.scenario_id, ct.contract_id AS outcome_contract
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk=sv.scenario_version_pk
JOIN model.contract_version cv ON cv.contract_version_pk=soc.contract_version_pk
JOIN model.contract ct ON ct.contract_pk=cv.contract_pk
WHERE ec.estate_model_pk=@estate AND c.capability_id=N'project-model-provider-protocol'
  AND s.scenario_id=N'project-model-provider-protocol';
SELECT '1_declared_transitions' AS result_set, d.capability_id,
  COUNT(j.value) AS transition_count,
  MIN(JSON_VALUE(j.value,'$.selectsVariant')) AS first_variant
FROM analysis.capability_execution_declaration(N'project-model-provider-protocol', NULL, 1) d
CROSS APPLY OPENJSON(JSON_QUERY(d.document,'$.transitions')) j
WHERE d.entry_id=N'semantic-graph.authority.json'
GROUP BY d.capability_id;
SELECT '2_graph_source_transitions' AS result_set, g.capability_id,
  COUNT(j.value) AS transition_count,
  SUM(CASE WHEN JSON_VALUE(j.value,'$.topologyKind')=N'selection' THEN 1 ELSE 0 END) AS selection_edges
FROM analysis.capability_graph_source(N'project-model-provider-protocol', 1, NULL) g
CROSS APPLY OPENJSON(JSON_QUERY(g.graph_source,'$.transitions')) j
GROUP BY g.capability_id;
SELECT '3_other_capability_unchanged' AS result_set, g.capability_id,
  ISNULL((SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(g.graph_source,'$.transitions'))), 0) AS transition_count
FROM analysis.capability_graph_source(N'resolve-sidefx-eligible-providers', 1, NULL) g;
COMMIT TRANSACTION;
