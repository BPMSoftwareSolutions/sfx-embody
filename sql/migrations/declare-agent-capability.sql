-- declare-agent-capability.sql
--
-- Declares the agent lane as a capability: request-capability-from-objective.
-- The composition that lived in src/agent-delivery.mjs is authored as rows:
-- a declared visibility prompt and proposal schema, the governed model
-- invocation as a composed child scenario, a declared read for capability
-- resolution, and declared routing that executes the admitted child or refuses
-- by absence. The unselected child runs zero cells.
--
-- Composed from proven templates:
--  - declare-two-child-routing-proof.sql (routing shape, transformation
--    authoring, variant inference through the `route` key)
--  - compose-resolve-equity-market-price-evidence.sql (direct authority mint
--    for invoke-scenario operations, faces re-pointed at shared contracts)
--  - read-declared-capability-document.sql (declared read port)
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
DECLARE @request_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/agent-objective-request.v1.schema.json","type":"object","additionalProperties":false,"required":["contractId","payload"],"properties":{"contractId":{"const":"agent-objective-request.v1"},"payload":{"type":"object","additionalProperties":false,"required":["objective"],"properties":{"objective":{"type":"string","minLength":1},"visibleCapabilities":{"type":"array","items":{"type":"string"}}}}}}';
EXEC model.declare_contract N'agent-objective-request.v1', @request_schema;
DECLARE @route_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/agent-route.v1.schema.json","type":"object","additionalProperties":true,"required":["contractId","route"],"properties":{"contractId":{"const":"agent-route.v1"},"route":{"enum":["ADMITTED","REFUSED"]}}}';
EXEC model.declare_contract N'agent-route.v1', @route_schema;
DECLARE @invocation_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/agent-invocation-evidence.v1.schema.json","type":"object","additionalProperties":true,"required":["contractId","capability","model","resolution","execution"],"properties":{"contractId":{"const":"agent-invocation-evidence.v1"}}}';
EXEC model.declare_contract N'agent-invocation-evidence.v1', @invocation_schema;
DECLARE @refusal_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/agent-refusal-evidence.v1.schema.json","type":"object","additionalProperties":true,"required":["contractId","capability","model","resolution","refusal"],"properties":{"contractId":{"const":"agent-refusal-evidence.v1"}}}';
EXEC model.declare_contract N'agent-refusal-evidence.v1', @refusal_schema;
SELECT '1_contracts' AS result_set, ct.contract_id
FROM model.contract ct
WHERE ct.contract_id IN (N'agent-objective-request.v1', N'agent-route.v1', N'agent-invocation-evidence.v1', N'agent-refusal-evidence.v1')
ORDER BY ct.contract_id;
GO
-- ============================== CAPABILITY SHELL ==============================
EXEC model.scaffold_capability @capability_id = N'request-capability-from-objective', @greeting_template = N'request capability from objective';
GO
-- ============================== TRANSFORMATIONS ==============================
DECLARE @capability_id nvarchar(400) = N'request-capability-from-objective';
DECLARE @namespace nvarchar(400) = N'sidefx:capability:' + @capability_id;
DECLARE @prompt nvarchar(max) = N'You map one user objective to exactly one governed capability request. The capabilities this invocation can see are: resolve-equity-market-price-evidence. A visible capability can be requested directly. If no visible capability can satisfy the objective, propose the capability identity the objective would require, even though it is not in the list. Respond only with the declared JSON shape: capability is the capability identity, input is the scalar that capability needs (for a price capability, resolve the company to its US ticker symbol, for example Broadcom to AVGO).';
DECLARE @proposal_schema nvarchar(max) = N'{"type":"object","required":["capability","input"],"properties":{"capability":{"type":"string"},"input":{"type":"string"}}}';
DECLARE @build nvarchar(max) = N'{"op":"object","fields":{'
 + N'"carrierType":{"op":"literal","value":"governed-model-invocation-request.v1"},'
 + N'"requestId":{"op":"literal","value":"agent-objective"},'
 + N'"requestHash":{"op":"literal","value":"sha256:0000000000000000000000000000000000000000000000000000000000000000"},'
 + N'"modelRequest":{"op":"object","fields":{'
 +   N'"$schema":{"op":"literal","value":"../../generic-llm-connector/authority/model-request.schema.v1.json"},'
 +   N'"requestId":{"op":"literal","value":"agent-objective"},'
 +   N'"providerAuthorityId":{"op":"literal","value":"primary-cognitive-provider"},'
 +   N'"modelAlias":{"op":"literal","value":"instruction-capable-model"},'
 +   N'"interaction":{"op":"object","fields":{'
 +     N'"mode":{"op":"literal","value":"structured-generation"},'
 +     N'"messages":{"op":"array","items":['
 +       N'{"op":"object","fields":{"role":{"op":"literal","value":"system"},"content":{"op":"literal","value":"' + @prompt + N'"}}},'
 +       N'{"op":"object","fields":{"role":{"op":"literal","value":"user"},"content":{"op":"path","from":"root","path":"payload.objective"}}}'
 +     N']}}},'
 +   N'"responsePolicy":{"op":"object","fields":{'
 +     N'"format":{"op":"literal","value":"json"},'
 +     N'"maximumOutputTokens":{"op":"literal","value":4096},'
 +     N'"temperature":{"op":"literal","value":0},'
 +     N'"schema":' + @proposal_schema + N'}},'
 +   N'"executionPolicy":{"op":"object","fields":{'
 +     N'"timeoutMilliseconds":{"op":"literal","value":60000},'
 +     N'"attemptAuthority":{"op":"object","fields":{"maximumAuthorizedAttempts":{"op":"literal","value":1}}},'
 +     N'"providerSubstitution":{"op":"object","fields":{"allowed":{"op":"literal","value":false}}}}},'
 +   N'"evidencePolicy":{"op":"object","fields":{'
 +     N'"captureRequestHash":{"op":"literal","value":true},'
 +     N'"captureResponseHash":{"op":"literal","value":true},'
 +     N'"captureResolvedProvider":{"op":"literal","value":true},'
 +     N'"captureResolvedModel":{"op":"literal","value":true},'
 +     N'"captureTokenUsage":{"op":"literal","value":true},'
 +     N'"captureTiming":{"op":"literal","value":true}}}}},'
 + N'"requestLineage":{"op":"array","items":[{"op":"literal","value":"agent-objective"},{"op":"literal","value":"obtain-governed-model-response"}]}'
 + N'}}';
DECLARE @decision nvarchar(max) = N'{"op":"object","fields":{'
 + N'"contractId":{"op":"literal","value":"agent-route.v1"},'
 + N'"route":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"input","path":"declared"},"right":{"op":"literal","value":1}},'
 +   N'"then":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"input","path":"proposedCapability"},"right":{"op":"literal","value":"resolve-equity-market-price-evidence"}},"then":{"op":"literal","value":"ADMITTED"},"else":{"op":"literal","value":"REFUSED"}},'
 +   N'"else":{"op":"literal","value":"REFUSED"}},'
 + N'"carried":{"op":"path","from":"input","path":"carried"},'
 + N'"proposal":{"op":"object","fields":{"capability":{"op":"path","from":"input","path":"proposedCapability"},"input":{"op":"path","from":"input","path":"proposedInput"}}},'
 + N'"executionRequest":{"op":"object","fields":{"contractId":{"op":"literal","value":"live-equity-price-request.v1"},"payload":{"op":"object","fields":{"symbol":{"op":"path","from":"input","path":"proposedInput"},"region":{"op":"literal","value":"US"}}}}}'
 + N'}}';
DECLARE @equity_request nvarchar(max) = N'{"op":"path","from":"input","path":"executionRequest"}';
DECLARE @invocation_evidence nvarchar(max) = N'{"op":"object","fields":{'
 + N'"contractId":{"op":"literal","value":"agent-invocation-evidence.v1"},'
 + N'"capability":{"op":"literal","value":"request-capability-from-objective"},'
 + N'"model":{"op":"object","fields":{'
 +   N'"disposition":{"op":"path","from":"root","path":"carried.disposition"},'
 +   N'"provider":{"op":"path","from":"root","path":"carried.resolvedProvider"},'
 +   N'"model":{"op":"path","from":"root","path":"carried.resolvedModel"},'
 +   N'"providerAuthorityId":{"op":"literal","value":"primary-cognitive-provider"},'
 +   N'"modelAlias":{"op":"literal","value":"instruction-capable-model"},'
 +   N'"proposal":{"op":"path","from":"root","path":"proposal"},'
 +   N'"requestHash":{"op":"path","from":"root","path":"carried.requestHash"},'
 +   N'"responseHash":{"op":"path","from":"root","path":"carried.responseHash"},'
 +   N'"durationMilliseconds":{"op":"path","from":"root","path":"carried.timing.durationMilliseconds"}}},'
 + N'"resolution":{"op":"object","fields":{"capability":{"op":"path","from":"root","path":"proposal.capability"},"declared":{"op":"literal","value":true}}},'
 + N'"execution":{"op":"object","fields":{'
 +   N'"capability":{"op":"path","from":"root","path":"proposal.capability"},'
 +   N'"input":{"op":"path","from":"root","path":"proposal.input"},'
 +   N'"disposition":{"op":"path","from":"input","path":"disposition"},'
 +   N'"outcome":{"op":"path","from":"input","path":"payload"},'
 +   N'"providerTestimony":{"op":"path","from":"input","path":"providerTestimony"}}}'
 + N'}}';
DECLARE @refusal_evidence nvarchar(max) = N'{"op":"object","fields":{'
 + N'"contractId":{"op":"literal","value":"agent-refusal-evidence.v1"},'
 + N'"capability":{"op":"literal","value":"request-capability-from-objective"},'
 + N'"model":{"op":"object","fields":{'
 +   N'"disposition":{"op":"path","from":"root","path":"carried.disposition"},'
 +   N'"provider":{"op":"path","from":"root","path":"carried.resolvedProvider"},'
 +   N'"model":{"op":"path","from":"root","path":"carried.resolvedModel"},'
 +   N'"proposal":{"op":"path","from":"root","path":"proposal"}}},'
 + N'"resolution":{"op":"object","fields":{"capability":{"op":"path","from":"root","path":"proposal.capability"},"declared":{"op":"literal","value":false}}},'
 + N'"refusal":{"op":"literal","value":"CAPABILITY_NOT_FOUND"}'
 + N'}}';
DECLARE @transformations TABLE (ordinal int PRIMARY KEY, id nvarchar(400), expression nvarchar(max));
INSERT @transformations VALUES
 (0, N'build-agent-model-request', @build),
 (1, N'decide-agent-route', @decision),
 (2, N'shape-equity-execution-request', @equity_request),
 (3, N'shape-agent-execution-evidence', @invocation_evidence),
 (4, N'shape-agent-refusal-evidence', @refusal_evidence);
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
SELECT '2_transformations' AS result_set, t.transformation_id
FROM model.transformation t JOIN model.identity_namespace n ON n.namespace_pk = t.namespace_pk
WHERE n.namespace_id = @namespace ORDER BY t.transformation_id;
GO
-- ============================== SCENARIOS ==============================
DECLARE @capability_id nvarchar(400) = N'request-capability-from-objective';
EXEC model.declare_scenario
  @capability_id = @capability_id,
  @scenario = N'{"scenarioId":"request-capability-from-objective","name":"Resolve one objective through the governed lane","inputId":"agent-objective-request","inputContract":"agent-objective-request.v1","eventId":"agent-objective-requested","eventAuthority":"request-capability-from-objective.v1","outcomeId":"agent-route","outcomeContract":"agent-route.v1","given":"one objective and the capabilities the invocation can see","when":"the governed model proposes one capability request and the declared estate resolves it","then":"the declared route selects the admitted execution child or the refusal child","root":true,"terminal":false,"variants":["ADMITTED","REFUSED"]}',
  @operations = N'[{"operationId":"request-capability-from-objective.build","kind":"invoke-port","portId":"build-agent-model-request-port"},{"operationId":"request-capability-from-objective.resolve","kind":"invoke-port","portId":"resolve-proposed-capability-port"},{"operationId":"request-capability-from-objective.decide","kind":"invoke-port","portId":"decide-agent-route-port"}]',
  @port_bindings = N'[{"portId":"build-agent-model-request-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"build-agent-model-request"}},{"portId":"resolve-proposed-capability-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"DECLARE @proposed nvarchar(400)=JSON_VALUE(@input,''$.normalizedResponse.structuredValue.capability'');\nDECLARE @proposedInput nvarchar(400)=JSON_VALUE(@input,''$.normalizedResponse.structuredValue.input'');\nDECLARE @declared bit=CASE WHEN EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=''CAPABILITY'' AND d.declared_id=@proposed) THEN 1 ELSE 0 END;\nSELECT (SELECT JSON_QUERY(@input) AS carried, CASE WHEN @declared=1 THEN 1 ELSE 0 END AS declared, @proposed AS proposedCapability, @proposedInput AS proposedInput FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS value","resultColumn":"value"}},{"portId":"decide-agent-route-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"decide-agent-route"}}]';
EXEC model.declare_scenario
  @capability_id = @capability_id,
  @scenario = N'{"scenarioId":"execute-admitted-proposal","name":"Execute the admitted proposal","inputId":"execute-admitted-proposal-request","inputContract":"agent-route.v1","eventId":"execute-admitted-proposal-selected","eventAuthority":"execute-admitted-proposal.v1","outcomeId":"agent-invocation-evidence","outcomeContract":"agent-invocation-evidence.v1","given":"the declared route admitted the proposed capability","when":"the admitted capability executes and the evidence is shaped","then":"the agent invocation evidence is produced","terminal":true}',
  @operations = N'[{"operationId":"execute-admitted-proposal.shape","kind":"invoke-port","portId":"shape-equity-execution-request-port"},{"operationId":"execute-admitted-proposal.shape-evidence","kind":"invoke-port","portId":"shape-agent-execution-evidence-port"}]',
  @port_bindings = N'[{"portId":"shape-equity-execution-request-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"shape-equity-execution-request"}},{"portId":"shape-agent-execution-evidence-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"shape-agent-execution-evidence"}}]';
EXEC model.declare_scenario
  @capability_id = @capability_id,
  @scenario = N'{"scenarioId":"refuse-proposed-capability","name":"Refuse the proposed capability by absence","inputId":"refuse-proposed-capability-request","inputContract":"agent-route.v1","eventId":"refuse-proposed-capability-selected","eventAuthority":"refuse-proposed-capability.v1","outcomeId":"agent-refusal-evidence","outcomeContract":"agent-refusal-evidence.v1","given":"the declared route refused the proposed capability","when":"the refusal evidence is shaped","then":"no provider is reached and no effect occurs","terminal":true}',
  @operations = N'[{"operationId":"refuse-proposed-capability.shape","kind":"invoke-port","portId":"shape-agent-refusal-evidence-port"}]',
  @port_bindings = N'[{"portId":"shape-agent-refusal-evidence-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"shape-agent-refusal-evidence"}}]';
GO
-- ============================== ROUTING AND CLI ==============================
DECLARE @capability_id nvarchar(400) = N'request-capability-from-objective';
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @capPk bigint, @capSo bigint, @capSod bigint, @capVer bigint;
SELECT @capPk = c.capability_pk, @capSo = c.semantic_object_pk,
  @capSod = ec.semantic_object_definition_pk, @capVer = ec.capability_version_pk
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk = ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
WHERE ec.estate_model_pk = @model AND c.capability_id = @capability_id AND n.namespace_id = N'sidefx:capabilities';
IF @capPk IS NULL THROW 51000, 'AGENT_CAPABILITY_NOT_FOUND', 1;
DECLARE @curEnv nvarchar(max);
SELECT @curEnv = CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.semantic_object_definition d
JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
WHERE d.semantic_object_definition_pk = @capSod;
IF @curEnv IS NULL THROW 51000, 'AGENT_ENVELOPE_NOT_FOUND', 1;
DECLARE @cli nvarchar(max) = N'{"input":{"type":"text","contract":"agent-objective-request.v1","path":"payload.objective"},"display":{"select":"outcome.payload","as":"json"}}';
DECLARE @routing nvarchar(max) = N'[{"fromScenario":"request-capability-from-objective","variant":"ADMITTED","toScenario":"execute-admitted-proposal","topologyKind":"selection"},{"fromScenario":"request-capability-from-objective","variant":"REFUSED","toScenario":"refuse-proposed-capability","topologyKind":"selection"}]';
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
SELECT '3_routing' AS result_set, @capability_id AS capability_id,
  JSON_VALUE(@routing, '$[0].variant') AS admitted_variant, JSON_VALUE(@routing, '$[1].variant') AS refused_variant;
GO
-- ============================== FEATURE ==============================
EXEC model.declare_capability_feature
  @capability_id = N'request-capability-from-objective',
  @feature_text = N'@capability:request-capability-from-objective
@root-scenario:request-capability-from-objective
Feature: Resolve one objective through the governed lane

  @scenario:request-capability-from-objective
  @input:agent-objective-request
  @input-contract:agent-objective-request.v1
  @event:agent-objective-requested
  @event-authority:request-capability-from-objective.v1
  @outcome:agent-route
  @outcome-contract:agent-route.v1
  Scenario: The declared route selects an execution child
    Given one objective and the capabilities the invocation can see
    When the governed model proposes one capability request and the declared estate resolves it
    Then the declared route selects the admitted execution child or the refusal child

  @scenario:execute-admitted-proposal
  @input:execute-admitted-proposal-request
  @input-contract:agent-route.v1
  @event:execute-admitted-proposal-selected
  @event-authority:execute-admitted-proposal.v1
  @outcome:agent-invocation-evidence
  @outcome-contract:agent-invocation-evidence.v1
  @outcome-terminal
  Scenario: Execute the admitted proposal
    Given the declared route admitted the proposed capability
    When the admitted capability executes and the evidence is shaped
    Then the agent invocation evidence is produced

  @scenario:refuse-proposed-capability
  @input:refuse-proposed-capability-request
  @input-contract:agent-route.v1
  @event:refuse-proposed-capability-selected
  @event-authority:refuse-proposed-capability.v1
  @outcome:agent-refusal-evidence
  @outcome-contract:agent-refusal-evidence.v1
  @outcome-terminal
  Scenario: Refuse the proposed capability by absence
    Given the declared route refused the proposed capability
    When the refusal evidence is shaped
    Then no provider is reached and no effect occurs
';
GO
-- ============================== COMPOSED AUTHORITIES ==============================
-- The root and the admitted child invoke other capabilities' scenarios, so their
-- authorities are minted directly with invoke-scenario operations and the
-- scenario events are re-pointed, exactly as compose-resolve-equity-market-price-evidence.
DECLARE @capability_id nvarchar(400) = N'request-capability-from-objective';
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @model_target bigint = (SELECT cs.scenario_version_pk
  FROM model.capability c JOIN model.estate_capability ec ON ec.capability_pk = c.capability_pk AND ec.estate_model_pk = @model
  JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk
  JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
  WHERE c.capability_id = N'obtain-governed-model-response' AND s.scenario_id = N'obtain-governed-model-response');
DECLARE @equity_target bigint = (SELECT cs.scenario_version_pk
  FROM model.capability c JOIN model.estate_capability ec ON ec.capability_pk = c.capability_pk AND ec.estate_model_pk = @model
  JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk
  JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
  WHERE c.capability_id = N'resolve-equity-market-price-evidence' AND s.scenario_id = N'resolve-equity-market-price-evidence');
IF @model_target IS NULL THROW 51000, 'AGENT_MODEL_SCENARIO_NOT_FOUND', 1;
IF @equity_target IS NULL THROW 51000, 'AGENT_EQUITY_SCENARIO_NOT_FOUND', 1;
DECLARE @root_envelope nvarchar(max) = N'{"address":{"id":"request-capability-from-objective.v1","kind":"EXECUTION_AUTHORITY","namespace":"sidefx:capability:request-capability-from-objective"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":{"id":"request-capability-from-objective.v1","operations":['
 + N'{"kind":"invoke-port","portId":"build-agent-model-request-port"},'
 + N'{"kind":"invoke-scenario","scenarioId":"obtain-governed-model-response"},'
 + N'{"kind":"invoke-port","portId":"resolve-proposed-capability-port"},'
 + N'{"kind":"invoke-port","portId":"decide-agent-route-port"}],'
 + N'"owningScenarioId":"request-capability-from-objective"}}}';
DECLARE @child_envelope nvarchar(max) = N'{"address":{"id":"execute-admitted-proposal.v1","kind":"EXECUTION_AUTHORITY","namespace":"sidefx:capability:request-capability-from-objective"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":{"id":"execute-admitted-proposal.v1","operations":['
 + N'{"kind":"invoke-port","portId":"shape-equity-execution-request-port"},'
 + N'{"kind":"invoke-scenario","scenarioId":"resolve-equity-market-price-evidence"},'
 + N'{"kind":"invoke-port","portId":"shape-agent-execution-evidence-port"}],'
 + N'"owningScenarioId":"execute-admitted-proposal"}}}';
DECLARE @mints TABLE (ordinal int PRIMARY KEY, authority_id nvarchar(400), scenario_id nvarchar(400), envelope nvarchar(max), operations nvarchar(max), scenario_target bigint);
INSERT @mints VALUES
 (0, N'request-capability-from-objective.v1', N'request-capability-from-objective', @root_envelope,
  N'[{"kind":"invoke-port","portId":"build-agent-model-request-port"},{"kind":"invoke-scenario","scenarioId":"obtain-governed-model-response"},{"kind":"invoke-port","portId":"resolve-proposed-capability-port"},{"kind":"invoke-port","portId":"decide-agent-route-port"}]', @model_target),
 (1, N'execute-admitted-proposal.v1', N'execute-admitted-proposal', @child_envelope,
  N'[{"kind":"invoke-port","portId":"shape-equity-execution-request-port"},{"kind":"invoke-scenario","scenarioId":"resolve-equity-market-price-evidence"},{"kind":"invoke-port","portId":"shape-agent-execution-evidence-port"}]', @equity_target);
DECLARE @m_ordinal int, @authority_id nvarchar(400), @scenario_id nvarchar(400), @env nvarchar(max), @operations nvarchar(max), @scenario_target bigint;
DECLARE @eaPk bigint, @eaSo bigint, @envBytes varbinary(max), @envDigest binary(32), @authSod bigint, @eaVer bigint;
DECLARE @mint_cursor CURSOR;
SET @mint_cursor = CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal, authority_id, scenario_id, envelope, operations, scenario_target FROM @mints ORDER BY ordinal;
OPEN @mint_cursor; FETCH NEXT FROM @mint_cursor INTO @m_ordinal, @authority_id, @scenario_id, @env, @operations, @scenario_target;
WHILE @@FETCH_STATUS = 0
BEGIN
  SELECT @eaPk = ea.execution_authority_pk, @eaSo = ea.semantic_object_pk
  FROM model.execution_authority ea
  JOIN model.identity_namespace n ON n.namespace_pk = ea.namespace_pk
  WHERE n.namespace_id = N'sidefx:capability:' + @capability_id AND ea.execution_authority_id = @authority_id;
  IF @eaPk IS NULL THROW 51000, 'AGENT_AUTHORITY_NOT_FOUND', 1;
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8));
  SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @envDigest)
    INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
  IF NOT EXISTS (SELECT 1 FROM model.semantic_object_definition WHERE semantic_object_pk = @eaSo AND definition_digest = @envDigest)
    INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
      VALUES (@eaSo, 'EXECUTION_AUTHORITY', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @envDigest));
  SET @authSod = (SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk = @eaSo AND definition_digest = @envDigest);
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk = @model AND semantic_object_definition_pk = @authSod)
    INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @authSod);
  SET @eaVer = (SELECT MAX(execution_authority_version_pk) FROM model.execution_authority_version WHERE execution_authority_pk = @eaPk AND definition_digest = @envDigest);
  IF @eaVer IS NULL
  BEGIN
    INSERT model.execution_authority_version (execution_authority_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, authority_profile, object_kind, _owner_definition_pk, _canonical_pointer)
      VALUES (@eaPk, @eaSo, @authSod, @envDigest, 'execution-authorities.v1', 'EXECUTION_AUTHORITY', @authSod, N'');
    SET @eaVer = SCOPE_IDENTITY();
    INSERT model.execution_operation (execution_authority_version_pk, operation_id, ordinal, operation_kind, _owner_definition_pk, _canonical_pointer)
      SELECT @eaVer, NULL, CONVERT(int, o.[key]), JSON_VALUE(o.value, '$.kind'), @authSod, N'/semantics/authority/operations/' + o.[key]
      FROM OPENJSON(@operations) o;
    INSERT model.operation_port_invocation (execution_operation_pk, port_version_pk, operation_kind, _owner_definition_pk, _canonical_pointer)
      SELECT eo.execution_operation_pk, pv.port_version_pk, 'invoke-port', @authSod, eo._canonical_pointer
      FROM model.execution_operation eo
      JOIN OPENJSON(@operations) o ON CONVERT(int, o.[key]) = eo.ordinal
      JOIN model.port p ON p.port_id = JSON_VALUE(o.value, '$.portId')
      JOIN model.port_version pv ON pv.port_pk = p.port_pk
      WHERE eo.execution_authority_version_pk = @eaVer
        AND pv.port_version_pk = (SELECT MAX(port_version_pk) FROM model.port_version WHERE port_pk = p.port_pk);
    INSERT model.operation_scenario_invocation (execution_operation_pk, target_scenario_version_pk, operation_kind, _owner_definition_pk, _canonical_pointer)
      SELECT eo.execution_operation_pk, @scenario_target, 'invoke-scenario', @authSod, eo._canonical_pointer
      FROM model.execution_operation eo
      JOIN OPENJSON(@operations) o ON CONVERT(int, o.[key]) = eo.ordinal
      WHERE eo.execution_authority_version_pk = @eaVer AND JSON_VALUE(o.value, '$.kind') = 'invoke-scenario';
  END
  UPDATE model.scenario_event SET execution_authority_version_pk = @eaVer
  WHERE scenario_version_pk = (SELECT cs.scenario_version_pk
    FROM model.capability_scenario cs
    JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
    WHERE cs.capability_version_pk = (SELECT capability_version_pk FROM model.estate_capability WHERE estate_model_pk = @model AND capability_pk = (SELECT capability_pk FROM model.capability WHERE capability_id = @capability_id))
      AND s.scenario_id = @scenario_id);
  FETCH NEXT FROM @mint_cursor INTO @m_ordinal, @authority_id, @scenario_id, @env, @operations, @scenario_target;
END
CLOSE @mint_cursor; DEALLOCATE @mint_cursor;
-- The invoked capabilities' scenarios cannot be linked into this capability's
-- scenario set: model.capability_scenario has a composite FK to model.scenario
-- (capability_pk, scenario_pk), so a capability may only own its own scenarios.
-- Cross-capability invoke-scenario therefore requires the graph-source assembly
-- to emit the invocation closure's scenarios as cells; see
-- docs/cross-capability-composition-finding.md.
SELECT '4_composed_authorities' AS result_set, ea.execution_authority_id, eo.ordinal, eo.operation_kind, p.port_id,
  target.scenario_id AS target_scenario
FROM model.execution_authority ea
JOIN model.identity_namespace n ON n.namespace_pk = ea.namespace_pk AND n.namespace_id = N'sidefx:capability:' + @capability_id
JOIN model.execution_authority_version eav ON eav.execution_authority_pk = ea.execution_authority_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk = eav.execution_authority_version_pk
LEFT JOIN model.operation_port_invocation opi ON opi.execution_operation_pk = eo.execution_operation_pk
LEFT JOIN model.port_version pv ON pv.port_version_pk = opi.port_version_pk
LEFT JOIN model.port p ON p.port_pk = pv.port_pk
LEFT JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk = eo.execution_operation_pk
LEFT JOIN model.scenario_version tsv ON tsv.scenario_version_pk = osi.target_scenario_version_pk
LEFT JOIN model.scenario target ON target.scenario_pk = tsv.scenario_pk
WHERE ea.execution_authority_id IN (N'request-capability-from-objective.v1', N'execute-admitted-proposal.v1')
  AND eav.execution_authority_version_pk = (SELECT MAX(execution_authority_version_pk) FROM model.execution_authority_version v WHERE v.execution_authority_pk = ea.execution_authority_pk)
ORDER BY ea.execution_authority_id, eo.ordinal;
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
