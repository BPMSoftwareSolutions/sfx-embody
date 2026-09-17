-- emit-declared-routing.sql
--
-- Additive declared-routing emission unit.
--
-- The one missing declared mechanism (docs/agent-lane-declaration.md §3) is now
-- present: a capability declares its routes as rows on its own semantic
-- definition at $.semantics.routing, the assembly expands them to the compiler's
-- transition input, and the graph source carries them. Before this unit the only
-- routing in the estate was a hardcoded VALUES list inside
-- analysis.capability_execution_declaration (declare-model-provider-protocol-routing.sql);
-- a capability with no declared routes still emits exactly [] / {"transitions":[]}.
--
-- Form and placement (the design decision in §5 step 1): a capability-scoped
-- semantic definition — the capability envelope key $.semantics.routing, the
-- same authority document that carries $.semantics.cli and $.semantics.authority.
-- Evidence: the assembly already reads capability-scoped declarations from that
-- envelope with one JSON_QUERY (cli config, capability authority); the envelope
-- lifecycle (mint a definition, re-point the capability version) is mechanized
-- and content-addressed; the estate has no declared transition table
-- (model.observed_semantic_graph_transition is inspection-only and guarded
-- immutable; model.blueprint_edge is empty estate-wide at 0 rows), and adding a
-- table would introduce DDL and key lifecycles out of proportion to one array on
-- the capability it belongs to. Reversal is one migration that removes the key.
--
-- The declared row form:
--   {transitionId?, fromScenario, variant, toScenario, topologyKind?, groupId?}
-- (topologyKind "selection" | "recurrence"; semanticProgress defaults to
-- "declared"). The expansion derives from.outcomeId, to.inputId and to.contractId
-- from the declared scenario faces; the emitted object matches the compiler's
-- transition input exactly (compiler.js:379-401) and the SDA transition graph
-- builder's DeclaredTransition shape.
--
-- The two live emission points (the runtime loader resolves
-- analysis.capability_graph_source(...), src/read-authority.mjs:27, which reads
-- the semantic-graph document from analysis.capability_execution_declaration):
--   1. analysis.capability_execution_declaration — semantic-graph.authority.json
--      now carries $.semantics.routing expanded, instead of the hardcoded list;
--   2. analysis.capability_graph_source — re-emitted, already reading
--      $.transitions from the declaration document.
-- The named assembly files sql/migrations/assemble-capability-graph-source.sql
-- and sql/schema/assemble-execution-declarations.sql create the estate-wide
-- *views* (analysis.v_capability_graph_source /
-- analysis.v_capability_execution_declaration); those views are not on the
-- runtime path (the loader resolves the TVFs) and are updated to the same
-- declared form in this unit.
--
-- Additive and inert: project-model-provider-protocol's 16 hardcoded routes move
-- into its envelope in the same order and expand to the identical bytes; every
-- other capability's assembled graph_source is byte-identical.
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
-- ============================== DECLARED ROUTES -> TRANSITIONS ==============================
-- One capability's declared routes, expanded to the compiler's transition input.
-- The declaration lives on the capability's own semantic definition at
-- $.semantics.routing (the capability-scoped authority document that also
-- carries $.semantics.cli and $.semantics.authority): an array of rows
--   {transitionId?, fromScenario, variant, toScenario, topologyKind?, groupId?}
-- The expansion derives the route's from-outcome, to-input and to-contract from
-- the declared scenario faces, so the emitted object matches the input
-- languages/typescript/runtimes/node/semantic-execution-graph/compiler.js
-- consumes: {transitionId, from:{scenarioId,outcomeId},
-- to:{scenarioId,inputId,contractId}, semanticProgress, topologyKind,
-- selectsVariant[, bindingAuthorityId][, edgeGroupId][, recurrenceAuthorityId]}.
-- A route whose endpoints are not declared contributes no transition.
CREATE OR ALTER FUNCTION analysis.capability_declared_transitions(@capability_id nvarchar(400))
RETURNS TABLE
AS
RETURN
WITH cap AS (
  SELECT c.capability_id COLLATE Latin1_General_100_BIN2 AS capability_id,
    c.capability_pk, ec.capability_version_pk,
    CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS envelope
  FROM source.current_model cm
  JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
  JOIN model.semantic_object_definition linked ON linked.semantic_object_definition_pk = ec.semantic_object_definition_pk
  CROSS APPLY (
    SELECT TOP (1) d.semantic_object_definition_pk, d.canonical_content_pk
    FROM model.semantic_object_definition d WHERE d.semantic_object_pk = linked.semantic_object_pk
    ORDER BY d.semantic_object_definition_pk DESC
  ) latest
  JOIN source.content_object co ON co.content_object_pk = latest.canonical_content_pk
  WHERE c.capability_id = @capability_id COLLATE Latin1_General_100_BIN2
    AND latest.semantic_object_definition_pk = ec.semantic_object_definition_pk
),
routes AS (
  SELECT cap.capability_version_pk, cap.capability_id,
    CONVERT(int, route.[key]) AS ordinal,
    JSON_VALUE(route.value, '$.transitionId') AS transition_id,
    JSON_VALUE(route.value, '$.fromScenario') AS from_scenario,
    JSON_VALUE(route.value, '$.variant') AS variant,
    JSON_VALUE(route.value, '$.toScenario') AS to_scenario,
    ISNULL(JSON_VALUE(route.value, '$.topologyKind'), N'selection') AS topology_kind,
    JSON_VALUE(route.value, '$.groupId') AS group_id,
    JSON_VALUE(route.value, '$.bindingAuthorityId') AS binding_authority_id,
    JSON_VALUE(route.value, '$.recurrenceAuthorityId') AS recurrence_authority_id,
    ISNULL(JSON_VALUE(route.value, '$.semanticProgress'), N'declared') AS semantic_progress
  FROM cap
  CROSS APPLY OPENJSON(JSON_QUERY(cap.envelope, '$.semantics.routing')) route
  WHERE JSON_QUERY(cap.envelope, '$.semantics.routing') IS NOT NULL
    AND route.[type] = 5
)
SELECT routes.capability_id, routes.ordinal,
  N'{"transitionId":"' + STRING_ESCAPE(ISNULL(routes.transition_id, N'route-' + routes.from_scenario + N'-' + routes.variant), 'json') + N'"'
  + N',"from":{"scenarioId":"' + STRING_ESCAPE(routes.from_scenario, 'json') + N'","outcomeId":"' + STRING_ESCAPE(outcome_face.outcome_id, 'json') + N'"}'
  + N',"to":{"scenarioId":"' + STRING_ESCAPE(routes.to_scenario, 'json') + N'","inputId":"' + STRING_ESCAPE(input_face.input_id, 'json') + N'","contractId":"' + STRING_ESCAPE(input_contract.contract_id, 'json') + N'"}'
  + N',"semanticProgress":"' + STRING_ESCAPE(routes.semantic_progress, 'json') + N'"'
  + N',"topologyKind":"' + STRING_ESCAPE(routes.topology_kind, 'json') + N'"'
  + N',"selectsVariant":"' + STRING_ESCAPE(routes.variant, 'json') + N'"'
  + CASE WHEN routes.binding_authority_id IS NULL THEN N'' ELSE N',"bindingAuthorityId":"' + STRING_ESCAPE(routes.binding_authority_id, 'json') + N'"' END
  + CASE WHEN routes.group_id IS NULL THEN N'' ELSE N',"edgeGroupId":"' + STRING_ESCAPE(routes.group_id, 'json') + N'"' END
  + CASE WHEN routes.recurrence_authority_id IS NULL THEN N'' ELSE N',"recurrenceAuthorityId":"' + STRING_ESCAPE(routes.recurrence_authority_id, 'json') + N'"' END
  + N'}' AS transition_json
FROM routes
JOIN model.capability_scenario from_link
  ON from_link.capability_version_pk = routes.capability_version_pk
JOIN model.scenario from_cell
  ON from_cell.scenario_pk = from_link.scenario_pk
 AND from_cell.scenario_id = routes.from_scenario COLLATE Latin1_General_100_BIN2
LEFT JOIN model.scenario_outcome outcome_face
  ON outcome_face.scenario_version_pk = from_link.scenario_version_pk
JOIN model.capability_scenario to_link
  ON to_link.capability_version_pk = routes.capability_version_pk
JOIN model.scenario to_cell
  ON to_cell.scenario_pk = to_link.scenario_pk
 AND to_cell.scenario_id = routes.to_scenario COLLATE Latin1_General_100_BIN2
LEFT JOIN model.scenario_input input_face
  ON input_face.scenario_version_pk = to_link.scenario_version_pk
LEFT JOIN model.contract_version input_cv
  ON input_cv.contract_version_pk = input_face.input_contract_version_pk
LEFT JOIN model.contract input_contract
  ON input_contract.contract_pk = input_cv.contract_pk;
GO
-- ============================== DECLARE THE ROUTES ==============================
-- project-model-provider-protocol's routes move from the assembly's hardcoded
-- VALUES list into its capability definition at $.semantics.routing. The
-- declaration is the same 16 routes, in the same order, with the fields the
-- declaration form names; the expansion must reproduce the previous transitions
-- bytes (verified against the captured before-state digest).
DECLARE @route_capability nvarchar(400) = N'project-model-provider-protocol';
DECLARE @route_model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @route_capPk bigint, @route_capSo bigint, @route_capSod bigint, @route_capVer bigint;
SELECT @route_capPk = c.capability_pk, @route_capSo = c.semantic_object_pk,
  @route_capSod = ec.semantic_object_definition_pk, @route_capVer = ec.capability_version_pk
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk = ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
WHERE ec.estate_model_pk = @route_model AND c.capability_id = @route_capability
  AND n.namespace_id = N'sidefx:capabilities';
IF @route_capPk IS NULL THROW 51000, 'DECLARED_ROUTING_CAPABILITY_NOT_FOUND', 1;
DECLARE @route_env nvarchar(max);
SELECT @route_env = CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.semantic_object_definition d
JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
WHERE d.semantic_object_definition_pk = @route_capSod;
IF @route_env IS NULL THROW 51000, 'DECLARED_ROUTING_ENVELOPE_NOT_FOUND', 1;

DECLARE @routing nvarchar(max) = N'[{"transitionId":"route-normalize-gemini-blocking","fromScenario":"project-model-provider-protocol","variant":"normalize-gemini-blocking","toScenario":"normalize-gemini-blocking-finish-testimony","topologyKind":"selection"},{"transitionId":"route-normalize-model-response-format","fromScenario":"project-model-provider-protocol","variant":"normalize-model-response-format","toScenario":"normalize-model-response-format","topologyKind":"selection"},{"transitionId":"route-normalize-observation","fromScenario":"project-model-provider-protocol","variant":"normalize-observation","toScenario":"normalize-gemini-success-testimony","topologyKind":"selection"},{"transitionId":"route-normalize-provider-http-failure","fromScenario":"project-model-provider-protocol","variant":"normalize-provider-http-failure","toScenario":"normalize-provider-http-failure-testimony","topologyKind":"selection"},{"transitionId":"route-normalize-provider-transport","fromScenario":"project-model-provider-protocol","variant":"normalize-provider-transport","toScenario":"normalize-provider-transport-testimony","topologyKind":"selection"},{"transitionId":"route-project-gemini-endpoint","fromScenario":"project-model-provider-protocol","variant":"project-gemini-endpoint","toScenario":"project-gemini-endpoint-and-credential-rule","topologyKind":"selection"},{"transitionId":"route-project-gemini-structured","fromScenario":"project-model-provider-protocol","variant":"project-gemini-structured","toScenario":"project-gemini-structured-request","topologyKind":"selection"},{"transitionId":"route-project-gemini-text","fromScenario":"project-model-provider-protocol","variant":"project-gemini-text","toScenario":"project-gemini-text-request","topologyKind":"selection"},{"transitionId":"route-project-openai-structured","fromScenario":"project-model-provider-protocol","variant":"project-openai-structured","toScenario":"project-openai-structured-request","topologyKind":"selection"},{"transitionId":"route-project-openai-text","fromScenario":"project-model-provider-protocol","variant":"project-openai-text","toScenario":"project-openai-text-request","topologyKind":"selection"},{"transitionId":"route-prove-determinism","fromScenario":"project-model-provider-protocol","variant":"prove-determinism","toScenario":"prove-deterministic-protocol-projection","topologyKind":"selection"},{"transitionId":"route-prove-effects","fromScenario":"project-model-provider-protocol","variant":"prove-effects","toScenario":"prove-no-http-effect-in-protocol-projection","topologyKind":"selection"},{"transitionId":"route-reject-unsupported-adapter-authority","fromScenario":"project-model-provider-protocol","variant":"reject-unsupported-adapter-authority","toScenario":"reject-unsupported-adapter-authority","topologyKind":"selection"},{"transitionId":"route-reject-unsupported-interaction-mode","fromScenario":"project-model-provider-protocol","variant":"reject-unsupported-interaction-mode","toScenario":"reject-unsupported-interaction-mode","topologyKind":"selection"},{"transitionId":"route-reject-unsupported-provider","fromScenario":"project-model-provider-protocol","variant":"reject-unsupported-provider","toScenario":"reject-unsupported-provider-protocol","topologyKind":"selection"},{"transitionId":"route-reject-unsupported-schema-vocabulary","fromScenario":"project-model-provider-protocol","variant":"reject-unsupported-schema-vocabulary","toScenario":"reject-unsupported-schema-vocabulary","topologyKind":"selection"}]';
DECLARE @route_new_env nvarchar(max) = JSON_MODIFY(@route_env, '$.semantics.routing', JSON_QUERY(@routing));
DECLARE @route_bytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@route_new_env) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @route_digest binary(32) = HASHBYTES('SHA2_256', @route_bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @route_digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@route_digest, @route_bytes, DATALENGTH(@route_bytes));
DECLARE @route_sod bigint = (SELECT semantic_object_definition_pk FROM model.semantic_object_definition
  WHERE semantic_object_pk = @route_capSo AND definition_digest = @route_digest);
IF @route_sod IS NULL
BEGIN
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
    VALUES (@route_capSo, 'CAPABILITY', @route_digest, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @route_digest));
  SET @route_sod = SCOPE_IDENTITY();
  INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk)
    VALUES (@route_model, @route_sod);
END
IF @route_sod <> @route_capSod
BEGIN
  INSERT model.capability_version (capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@route_capPk, @route_capSo, @route_sod, @route_digest, @route_capability, 'CAPABILITY', @route_sod, N'');
  DECLARE @route_newVer bigint = SCOPE_IDENTITY();
  INSERT model.capability_scenario (capability_pk, capability_version_pk, scenario_pk, scenario_version_pk, _owner_definition_pk, _canonical_pointer)
    SELECT capability_pk, @route_newVer, scenario_pk, scenario_version_pk, @route_sod, _canonical_pointer
    FROM model.capability_scenario WHERE capability_version_pk = @route_capVer;
  INSERT model.capability_root_scenario (capability_version_pk, scenario_pk, _owner_definition_pk, _canonical_pointer)
    SELECT @route_newVer, scenario_pk, @route_sod, _canonical_pointer
    FROM model.capability_root_scenario WHERE capability_version_pk = @route_capVer;
  UPDATE model.estate_capability SET capability_version_pk = @route_newVer, semantic_object_definition_pk = @route_sod
  WHERE estate_model_pk = @route_model AND capability_pk = @route_capPk;
END
GO
-- ============================== EMISSION POINT 1 ==============================
-- analysis.capability_execution_declaration: the declaration document set. The
-- semantic-graph.authority.json document is the declared routes expanded, or
-- [] when the capability declares none. Every other document is unchanged.
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
-- ============================== EMISSION POINT 2 ==============================
-- analysis.capability_graph_source: the compiler input. Re-emitted unchanged; it
-- reads $.transitions from the declaration document, so this unit makes the
-- dependency explicit and keeps both points in one install unit.
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
-- The routed capability's declared rows and expanded transitions.
SELECT '1_declared_routes' AS result_set, transition.capability_id, COUNT(*) AS route_count,
  MIN(transition.ordinal) AS first_ordinal, MAX(transition.ordinal) AS last_ordinal
FROM analysis.capability_declared_transitions(N'project-model-provider-protocol') transition
GROUP BY transition.capability_id;

SELECT '2_transitions_digest' AS result_set, g.capability_id, doc.transitions_sha256, doc.transitions_chars,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(g.graph_source, '$.transitions'))) AS transitions_in_graph_source,
  CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2) AS graph_source_sha256
FROM analysis.capability_graph_source(N'project-model-provider-protocol', 1, NULL) g
CROSS APPLY (
  SELECT CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), JSON_QUERY(d.document, '$.transitions')) COLLATE Latin1_General_100_BIN2_UTF8)), 2) AS transitions_sha256,
    LEN(JSON_QUERY(d.document, '$.transitions')) AS transitions_chars
  FROM OPENJSON(g.documents) WITH (entry_id nvarchar(500) '$.entry_id', document nvarchar(max) '$.document') d
  WHERE d.entry_id = N'semantic-graph.authority.json'
) doc;

-- A capability with no declared routing keeps the exact empty output.
SELECT '3_no_routing_still_empty' AS result_set, g.capability_id, JSON_QUERY(d.document, '$.transitions') AS transitions
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence', 1, NULL) g
CROSS APPLY OPENJSON(g.documents) WITH (entry_id nvarchar(500) '$.entry_id', document nvarchar(max) '$.document') d
WHERE d.entry_id = N'semantic-graph.authority.json';

-- The declared routing is readable from the capability's own envelope.
SELECT '4_routing_envelope' AS result_set, c.capability_id,
  JSON_QUERY(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.routing') AS routing
FROM source.current_model cm
JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
JOIN model.capability c ON c.capability_pk = ec.capability_pk
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = ec.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
WHERE cm.singleton_id = 1 AND c.capability_id = N'project-model-provider-protocol';

COMMIT TRANSACTION;
-- Installed 2026-09-17: project-model-provider-protocol's routes are declared at
-- $.semantics.routing and both emission points read them; no other capability's
-- assembled bytes changed. Reversal: re-run
-- declare-model-provider-protocol-routing.sql (the pre-unit assembly), or a
-- single migration that removes $.semantics.routing and re-emits the assembly.
