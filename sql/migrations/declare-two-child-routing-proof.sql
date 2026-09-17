-- declare-two-child-routing-proof.sql
--
-- The smallest declared-routing case: one capability, one root scenario, two
-- child scenarios, and one selectsVariant route per declared outcome variant
-- (left -> left child, right -> right child). The routes are declared on the
-- capability's own semantic definition at $.semantics.routing, the form the
-- emit-declared-routing unit reads; a run with branch "left" executes only the
-- left child and a run with branch "right" executes only the right child.
--
-- Why one route per variant is the smallest exhaustive case: the graph compiler
-- admits every declared capability scenario as a cell and the validator rejects
-- any cell unreachable from the root (UNREACHABLE_CELL, SDA
-- semantic-execution-graph/validator.js). A single route would leave the other
-- child unreachable; the smallest admissible two-child case routes each declared
-- variant, and each route is one selectsVariant edge from a declared outcome
-- variant (UNDECLARED_BRANCH_VARIANT is checked against the from cell's
-- declared variants).
--
-- Everything is authored with the estate's own authoring procedures
-- (model.declare_contract, model.scaffold_capability, model.declare_scenario,
-- model.declare_capability_feature); the capability definition is re-minted to
-- carry the routing and its string-input CLI configuration.
--
-- Idempotent: declare_contract/put_semantic_definition reuse content-addressed
-- definitions, scaffold_capability REPLACEs its own capability, declare_scenario
-- upserts scenario versions and variants, and a re-run emits the same routing.
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
-- ============================== CONTRACTS ==============================
-- One shared route contract is both the root outcome and both children's input:
-- a selection edge whose endpoints declare the same contract needs no binding
-- authority (EDGE_CONTRACT_MISMATCH otherwise). The request carries the branch;
-- the testimony names the child that produced it.
DECLARE @request_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/route-two-child-request.v1.schema.json","type":"object","additionalProperties":false,"required":["contractId","payload"],"properties":{"contractId":{"const":"route-two-child-request.v1"},"payload":{"type":"object","additionalProperties":false,"required":["branch"],"properties":{"branch":{"enum":["left","right"]}}}}}';
EXEC model.declare_contract N'route-two-child-request.v1', @request_schema;
DECLARE @route_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/route-two-child-route.v1.schema.json","type":"object","additionalProperties":false,"required":["contractId","route"],"properties":{"contractId":{"const":"route-two-child-route.v1"},"route":{"enum":["left","right"]}}}';
EXEC model.declare_contract N'route-two-child-route.v1', @route_schema;
DECLARE @testimony_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/route-two-child-testimony.v1.schema.json","type":"object","additionalProperties":false,"required":["contractId","selected"],"properties":{"contractId":{"const":"route-two-child-testimony.v1"},"selected":{"enum":["left","right"]}}}';
EXEC model.declare_contract N'route-two-child-testimony.v1', @testimony_schema;
SELECT '1_contracts' AS result_set, ct.contract_id, cv.schema_object_pk
FROM model.contract ct
JOIN model.contract_version cv ON cv.contract_pk = ct.contract_pk
WHERE ct.contract_id IN (N'route-two-child-request.v1', N'route-two-child-route.v1', N'route-two-child-testimony.v1')
ORDER BY ct.contract_id;
GO
-- ============================== CAPABILITY SHELL ==============================
-- The least executable realization; model.declare_scenario below replaces the
-- scaffold's single greeting scenario with the routing root, and adds the two
-- child scenarios.
EXEC model.scaffold_capability @capability_id = N'route-two-child-proof', @greeting_template = N'route two child proof';
GO
-- ============================== DECLARE THE ROUTES ==============================
-- $.semantics.routing on the capability's own definition: the declared row form
-- {fromScenario, variant, toScenario, topologyKind}. transitionId defaults to
-- route-<fromScenario>-<variant> in the expansion. The CLI input maps a text
-- branch onto payload.branch and displays the selected child's testimony.
DECLARE @capability_id nvarchar(400) = N'route-two-child-proof';
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @capPk bigint, @capSo bigint, @capSod bigint, @capVer bigint;
SELECT @capPk = c.capability_pk, @capSo = c.semantic_object_pk,
  @capSod = ec.semantic_object_definition_pk, @capVer = ec.capability_version_pk
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk = ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
WHERE ec.estate_model_pk = @model AND c.capability_id = @capability_id AND n.namespace_id = N'sidefx:capabilities';
IF @capPk IS NULL THROW 51000, 'TWO_CHILD_CAPABILITY_NOT_FOUND', 1;
DECLARE @curEnv nvarchar(max);
SELECT @curEnv = CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.semantic_object_definition d
JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
WHERE d.semantic_object_definition_pk = @capSod;
IF @curEnv IS NULL THROW 51000, 'TWO_CHILD_ENVELOPE_NOT_FOUND', 1;
DECLARE @cli nvarchar(max) = N'{"input":{"type":"text","contract":"route-two-child-request.v1","path":"payload.branch"},"display":{"select":"outcome.selected","as":"text"}}';
DECLARE @routing nvarchar(max) = N'[{"fromScenario":"route-two-child-proof","variant":"left","toScenario":"route-two-child-left","topologyKind":"selection"},{"fromScenario":"route-two-child-proof","variant":"right","toScenario":"route-two-child-right","topologyKind":"selection"}]';
DECLARE @newEnv nvarchar(max) = JSON_MODIFY(JSON_MODIFY(@curEnv, '$.semantics.cli', JSON_QUERY(@cli)), '$.semantics.routing', JSON_QUERY(@routing));
DECLARE @bytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @digest binary(32) = HASHBYTES('SHA2_256', @bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @digest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
DECLARE @sod bigint = (SELECT semantic_object_definition_pk FROM model.semantic_object_definition
  WHERE semantic_object_pk = @capSo AND definition_digest = @digest);
IF @sod IS NULL
BEGIN
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
    VALUES (@capSo, 'CAPABILITY', @digest, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @digest));
  SET @sod = SCOPE_IDENTITY();
  INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @sod);
END
IF @sod <> @capSod
BEGIN
  INSERT model.capability_version (capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@capPk, @capSo, @sod, @digest, @capability_id, 'CAPABILITY', @sod, N'');
  DECLARE @newVer bigint = SCOPE_IDENTITY();
  INSERT model.capability_scenario (capability_pk, capability_version_pk, scenario_pk, scenario_version_pk, _owner_definition_pk, _canonical_pointer)
    SELECT capability_pk, @newVer, scenario_pk, scenario_version_pk, @sod, _canonical_pointer
    FROM model.capability_scenario WHERE capability_version_pk = @capVer;
  INSERT model.capability_root_scenario (capability_version_pk, scenario_pk, _owner_definition_pk, _canonical_pointer)
    SELECT @newVer, scenario_pk, @sod, _canonical_pointer
    FROM model.capability_root_scenario WHERE capability_version_pk = @capVer;
  UPDATE model.estate_capability SET capability_version_pk = @newVer, semantic_object_definition_pk = @sod
  WHERE estate_model_pk = @model AND capability_pk = @capPk;
END
SELECT '2_routing_declared' AS result_set, @capability_id AS capability_id,
  JSON_VALUE(@routing, '$[0].variant') AS first_variant, JSON_VALUE(@routing, '$[1].variant') AS second_variant;
GO
-- ============================== TRANSFORMATIONS ==============================
-- The root's single operation reads the requested branch and emits the route
-- (the value whose "route" key the scheduler's variant inference reads); each
-- child emits its own testimony literal.
DECLARE @capability_id nvarchar(400) = N'route-two-child-proof';
DECLARE @namespace nvarchar(400) = N'sidefx:capability:' + @capability_id;
DECLARE @transformations TABLE (ordinal int PRIMARY KEY, id nvarchar(400), expression nvarchar(max));
INSERT @transformations VALUES
 (0, N'transform-route-two-child-route.v1', N'{"op":"object","fields":{"contractId":{"op":"literal","value":"route-two-child-route.v1"},"route":{"op":"path","from":"input","path":"payload.branch"}}}'),
 (1, N'transform-route-two-child-left.v1', N'{"op":"object","fields":{"contractId":{"op":"literal","value":"route-two-child-testimony.v1"},"selected":{"op":"literal","value":"left"}}}'),
 (2, N'transform-route-two-child-right.v1', N'{"op":"object","fields":{"contractId":{"op":"literal","value":"route-two-child-testimony.v1"},"selected":{"op":"literal","value":"right"}}}');
DECLARE @ordinal int, @id nvarchar(400), @expression nvarchar(max), @semantics nvarchar(max);
DECLARE @object bigint, @definition bigint, @digest binary(32), @transformation bigint, @version bigint;
DECLARE @cursor CURSOR;
SET @cursor = CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal, id, expression FROM @transformations ORDER BY ordinal;
OPEN @cursor;
FETCH NEXT FROM @cursor INTO @ordinal, @id, @expression;
WHILE @@FETCH_STATUS = 0
BEGIN
  SET @semantics = N'{"id":"' + @id + N'","expression":' + @expression + N'}';
  EXEC model.put_semantic_definition 'TRANSFORMATION', @namespace, @id, @semantics, @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
  SET @transformation = (SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk = @object);
  IF @transformation IS NULL
  BEGIN
    INSERT model.transformation(namespace_pk, transformation_id, semantic_object_pk, object_kind)
    SELECT namespace_pk, @id, @object, 'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk = @object;
    SET @transformation = SCOPE_IDENTITY();
  END
  SET @version = (SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk = @definition);
  IF @version IS NULL
  BEGIN
    INSERT model.transformation_version(transformation_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest,
      expression_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES(@transformation, @object, @definition, @digest, 'json-expression-tree.v1', 'TRANSFORMATION', @definition, N'');
    SET @version = SCOPE_IDENTITY();
    EXEC model.normalize_transformation_expression @version;
  END
  FETCH NEXT FROM @cursor INTO @ordinal, @id, @expression;
END
CLOSE @cursor;
DEALLOCATE @cursor;
SELECT '3_transformations' AS result_set, t.transformation_id, tv.expression_profile
FROM model.transformation t
JOIN model.transformation_version tv ON tv.transformation_pk = t.transformation_pk
JOIN model.identity_namespace n ON n.namespace_pk = t.namespace_pk
WHERE n.namespace_id = @namespace
ORDER BY t.transformation_id;
GO
-- ============================== SCENARIOS ==============================
-- Root (non-terminal, variants left/right) and the two terminal children. The
-- shared route contract is the root outcome and every child input, so the
-- selection edges are contract-clean.
DECLARE @capability_id nvarchar(400) = N'route-two-child-proof';
EXEC model.declare_scenario
  @capability_id = @capability_id,
  @scenario = N'{"scenarioId":"route-two-child-proof","name":"Route to one of two child scenarios","inputId":"route-two-child-request","inputContract":"route-two-child-request.v1","eventId":"route-two-child-requested","eventAuthority":"route-two-child-proof-route.v1","outcomeId":"route-two-child-route","outcomeContract":"route-two-child-route.v1","given":"the caller states which branch to take","when":"the declared route selects a child scenario","then":"the selected child testifies","root":true,"terminal":false,"variants":["left","right"]}',
  @operations = N'[{"operationId":"route-two-child-proof.route","kind":"invoke-port","portId":"route-two-child-proof-route-port"}]',
  @port_bindings = N'[{"portId":"route-two-child-proof-route-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"transform-route-two-child-route.v1"}}]';
EXEC model.declare_scenario
  @capability_id = @capability_id,
  @scenario = N'{"scenarioId":"route-two-child-left","name":"The left child testifies","inputId":"route-two-child-left-request","inputContract":"route-two-child-route.v1","eventId":"route-two-child-left-selected","eventAuthority":"route-two-child-left.v1","outcomeId":"route-two-child-left-testimony","outcomeContract":"route-two-child-testimony.v1","given":"the route selected left","when":"the left child executes its single transformation","then":"the left testimony is produced","terminal":true}',
  @operations = N'[{"operationId":"route-two-child-left.testify","kind":"invoke-port","portId":"route-two-child-left-port"}]',
  @port_bindings = N'[{"portId":"route-two-child-left-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"transform-route-two-child-left.v1"}}]';
EXEC model.declare_scenario
  @capability_id = @capability_id,
  @scenario = N'{"scenarioId":"route-two-child-right","name":"The right child testifies","inputId":"route-two-child-right-request","inputContract":"route-two-child-route.v1","eventId":"route-two-child-right-selected","eventAuthority":"route-two-child-right.v1","outcomeId":"route-two-child-right-testimony","outcomeContract":"route-two-child-testimony.v1","given":"the route selected right","when":"the right child executes its single transformation","then":"the right testimony is produced","terminal":true}',
  @operations = N'[{"operationId":"route-two-child-right.testify","kind":"invoke-port","portId":"route-two-child-right-port"}]',
  @port_bindings = N'[{"portId":"route-two-child-right-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"transform-route-two-child-right.v1"}}]';
EXEC model.declare_capability_feature
  @capability_id = N'route-two-child-proof',
  @feature_text = N'@capability:route-two-child-proof
@root-scenario:route-two-child-proof
Feature: Route to one of two child scenarios

  @scenario:route-two-child-proof
  @input:route-two-child-request
  @input-contract:route-two-child-request.v1
  @event:route-two-child-requested
  @event-authority:route-two-child-proof-route.v1
  @outcome:route-two-child-route
  @outcome-contract:route-two-child-route.v1
  Scenario: The declared route selects a child
    Given the caller states which branch to take
    When the declared route selects a child scenario
    Then the selected child testifies

  @scenario:route-two-child-left
  @input:route-two-child-left-request
  @input-contract:route-two-child-route.v1
  @event:route-two-child-left-selected
  @event-authority:route-two-child-left.v1
  @outcome:route-two-child-left-testimony
  @outcome-contract:route-two-child-testimony.v1
  @outcome-terminal
  Scenario: The left child testifies
    Given the route selected left
    When the left child executes its single transformation
    Then the left testimony is produced

  @scenario:route-two-child-right
  @input:route-two-child-right-request
  @input-contract:route-two-child-route.v1
  @event:route-two-child-right-selected
  @event-authority:route-two-child-right.v1
  @outcome:route-two-child-right-testimony
  @outcome-contract:route-two-child-testimony.v1
  @outcome-terminal
  Scenario: The right child testifies
    Given the route selected right
    When the right child executes its single transformation
    Then the right testimony is produced
';
GO
-- ============================== VERIFICATION ==============================
DECLARE @estate bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
SELECT '4_scenarios' AS result_set, s.scenario_id, CONVERT(bit, so.terminal) AS terminal,
  si.input_id, ct_in.contract_id AS input_contract, cto.contract_id AS outcome_contract,
  ISNULL((SELECT STRING_AGG(ov.variant_id, N',') FROM model.outcome_variant ov WHERE ov.scenario_version_pk = sv.scenario_version_pk), N'(none)') AS variants
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk = ec.capability_pk AND c.capability_id = N'route-two-child-proof'
JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk = cs.scenario_version_pk
LEFT JOIN model.scenario_input si ON si.scenario_version_pk = sv.scenario_version_pk
LEFT JOIN model.contract_version cvi ON cvi.contract_version_pk = si.input_contract_version_pk
LEFT JOIN model.contract ct_in ON ct_in.contract_pk = cvi.contract_pk
LEFT JOIN model.scenario_outcome so ON so.scenario_version_pk = sv.scenario_version_pk
LEFT JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk = sv.scenario_version_pk
LEFT JOIN model.contract_version cvo ON cvo.contract_version_pk = soc.contract_version_pk
LEFT JOIN model.contract cto ON cto.contract_pk = cvo.contract_pk
WHERE ec.estate_model_pk = @estate
ORDER BY s.scenario_id;

SELECT '5_declared_transitions' AS result_set, transition.capability_id, transition.ordinal,
  JSON_VALUE(transition.transition_json, '$.transitionId') AS transition_id,
  JSON_VALUE(transition.transition_json, '$.selectsVariant') AS selects_variant,
  JSON_VALUE(transition.transition_json, '$.to.scenarioId') AS to_scenario
FROM analysis.capability_declared_transitions(N'route-two-child-proof') transition
ORDER BY transition.ordinal;

SELECT '6_graph_source' AS result_set, g.capability_id,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(g.graph_source, '$.transitions'))) AS transition_count,
  JSON_QUERY(g.graph_source, '$.transitions') AS transitions
FROM analysis.capability_graph_source(N'route-two-child-proof', 1, NULL) g;

SELECT '7_semantic_graph_document' AS result_set, JSON_QUERY(d.document, '$.transitions') AS transitions
FROM analysis.capability_graph_source(N'route-two-child-proof', 1, NULL) g
CROSS APPLY OPENJSON(g.documents) WITH (entry_id nvarchar(500) '$.entry_id', document nvarchar(max) '$.document') d
WHERE d.entry_id = N'semantic-graph.authority.json';

COMMIT TRANSACTION;
-- Installed 2026-09-17: route-two-child-proof declares two selectsVariant routes
-- from its declared outcome variants and each branch executes only its child.
-- Reversal: a single migration that removes the capability (or its routing).
