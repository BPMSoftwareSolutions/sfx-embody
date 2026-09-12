-- authoring-procedures.sql
--
-- Reusable model-authoring procedures. Each procedure makes one declared change,
-- returns the affected identities and before/after values, and participates in the
-- caller's transaction. None of them begin, commit or roll back a transaction.
--
-- Rubric: docs/sidefx-architecture-decision-rubric.md §9.
-- Decisions applied here (see §9.3 necessity test and §9.5):
--   * Write model.* declarations plus the content-addressed bytes the model and the
--     read path actually consume: semantic-definition envelopes, contract schema
--     bytes, and the feature text. These are execution/delivery necessity.
--   * Write no source.source_appearance / source_observation /
--     source_declaration_observation / source_lineage and no raw capsule-file
--     content_object rows. The read path (analysis.v_capability_execution_declaration
--     via capability-embodiment.sql) does not consult them, so omitting them changes
--     none of §9.1's six events. Not necessary.
--   * Never call source.validate_model / source.publish_model and never create a new
--     estate_model generation. That is publication machinery (§9.5), not the loop.
--   * Procedures live in the existing model schema; no new schema or authority
--     boundary is introduced for a loop that does not require one (§2, §6).
--
-- Installation only. The caller supplies the transaction.

SET NOCOUNT ON;
GO

-- =====================================================================
-- model.scaffold_capability
-- Create the least executable realization of an Input -> Event -> Outcome
-- capability: meaning, input/output contracts, a minimal executable scenario,
-- its port/transformation/execution authority, and its CLI declaration.
-- =====================================================================
CREATE OR ALTER PROCEDURE model.scaffold_capability
  @capability_id    nvarchar(120),
  @greeting_template nvarchar(200) = N'Hello {name}!',
  @input_id         nvarchar(120) = NULL,
  @input_contract   nvarchar(160) = NULL,
  @outcome_id       nvarchar(120) = NULL,
  @outcome_contract nvarchar(160) = NULL,
  @on_exists        nvarchar(20)  = N'REPLACE'
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CapabilityId nvarchar(120) = @capability_id;
  DECLARE @GreetingTemplate nvarchar(200) = @greeting_template;
  DECLARE @InputId nvarchar(120) = ISNULL(@input_id, @capability_id + N'-request');
  DECLARE @InputContract nvarchar(160) = ISNULL(@input_contract, @capability_id + N'-request.v1');
  DECLARE @OutcomeId nvarchar(120) = ISNULL(@outcome_id, @capability_id + N'-greeting');
  DECLARE @OutcomeContract nvarchar(160) = ISNULL(@outcome_contract, @capability_id + N'-greeting.v1');
  DECLARE @PortId nvarchar(160) = @CapabilityId + N'-port';
  DECLARE @TransformationId nvarchar(160) = @CapabilityId + N'-transform.v1';
  DECLARE @EventAuthorityId nvarchar(160) = @CapabilityId + N'.v1';

  DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
  IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;

  DECLARE @exists bit = CASE WHEN EXISTS (
      SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
      WHERE n.namespace_id = N'sidefx:capabilities' AND c.capability_id = @CapabilityId) THEN 1 ELSE 0 END;
  DECLARE @action nvarchar(20) = CASE WHEN @exists = 1 THEN N'REPLACE' ELSE N'CREATE' END;
  IF @exists = 1
  BEGIN
    IF @on_exists = N'ERROR' THROW 51001, 'CAPABILITY_ALREADY_EXISTS', 1;
    IF @on_exists NOT IN (N'REPLACE') THROW 51001, 'ON_EXISTS_INVALID', 1;
  END

  DECLARE @capNs bigint, @scenarioNs bigint, @capSo bigint, @capSod bigint, @scnSo bigint, @scnSod bigint, @capPk bigint, @capVer bigint, @scnPk bigint, @scnVer bigint;
  DECLARE @priorCapPk bigint, @priorCapVer bigint, @priorCapSo bigint, @priorCapSod bigint, @priorScnPk bigint, @priorScnVer bigint, @priorScnSo bigint, @priorScnSod bigint;
  DECLARE @env nvarchar(max), @envBytes varbinary(max);
  DECLARE @capText nvarchar(max), @featureText nvarchar(max), @workspaceText nvarchar(max), @execText nvarchar(max),
          @interfacesText nvarchar(max), @transText nvarchar(max), @fixturesText nvarchar(max), @outcomeSchemaText nvarchar(max), @inputSchemaText nvarchar(max);
  DECLARE @b_cap varbinary(max), @d_cap binary(32);
  DECLARE @b_feat varbinary(max), @d_feat binary(32);
  DECLARE @b_inSchema varbinary(max), @d_inSchema binary(32);
  DECLARE @b_outSchema varbinary(max), @d_outSchema binary(32);
  DECLARE @manifest nvarchar(max), @manifestHex varchar(64);

  -- 1. Declared text. @CapabilityId and @GreetingTemplate are the only required inputs.
  SET @capText = N'{
  "capabilityId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'",
  "name": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'",
  "mode": "capability",
  "userStory": { "actor": "caller", "intent": "write a database-defined message to standard output", "outcome": "the caller observes the configured message" },
  "experience": { "experienceId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'.v1", "actor": "caller",
    "promise": "the configured message is delivered through the sda-json-cli.v1 standard-output interface",
    "observableConditions": [ { "conditionId": "message-delivered-to-standard-output" } ] },
  "rootScenarioId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'"
}';
  DECLARE @cliJson nvarchar(max) = N'{"display":{"select":"outcome.payload.message","as":"text"},"input":{"type":"text","contract":"' + STRING_ESCAPE(@InputContract,'json') + N'","path":"payload.name"}}';
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
' + N'    Then the caller observes the greeting for the supplied name on standard output
';
  SET @workspaceText = N'{ "workspaceType": "consumer-workspace-authority.v1", "consumerId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'", "projectionTargets": [ "node" ],
  "capabilities": [ { "featureId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'.feature", "feature": "capability.feature", "capability": "capability.authority.json",
  "semanticGraph": "semantic-graph.authority.json", "executionAuthorities": "execution-authorities.authority.json", "interfaces": "interfaces.authority.json", "fixtures": "fixtures.authority.json" } ] }';
  SET @execText = N'{ "authorityType": "execution-authorities.v1", "executionAuthorities": [ { "id": "' + STRING_ESCAPE(@EventAuthorityId, 'json') + N'", "owningScenarioId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'",
  "operations": [ { "kind": "invoke-port", "portId": "' + STRING_ESCAPE(@PortId, 'json') + N'" } ] } ] }';
  SET @interfacesText = N'{ "interfaceAuthorityType": "consumer-interface-authority.v1", "contractValidatorCapabilityId": "sda-schema-contract-admission.v1", "contractCatalog": "contracts/contract-catalog.json",
  "interfaces": [ { "interfaceId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'-cli", "kind": "cli", "rootScenarioId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'", "platformCapabilityId": "sda-json-cli.v1", "configuration": { "display": { "select": "outcome.payload.message", "as": "text" }, "input": { "type": "text", "contract": "' + @InputContract + N'", "path": "payload.name" } }, "projectionTargets": [ "node" ] } ],
  "portBindings": [ { "portId": "' + STRING_ESCAPE(@PortId, 'json') + N'", "platformCapabilityId": "sda-authority-transformation-port.v1",
    "configuration": { "transformationAuthorityRef": "semantic-transformation.authority.json", "transformationId": "' + STRING_ESCAPE(@TransformationId, 'json') + N'" } } ], "projectionBindings": [] }';
  SET @transText = N'{ "authorityType": "semantic-transformation-authority.v1", "transformations": [ { "id": "' + STRING_ESCAPE(@TransformationId, 'json') + N'",
  "expression": { "op": "object", "fields": { "contractId": { "op": "literal", "value": "' + STRING_ESCAPE(@OutcomeContract, 'json') + N'" },
    "payload": { "op": "object", "fields": { "message": { "op": "format", "template": "' + STRING_ESCAPE(@GreetingTemplate, 'json') + N'", "values": { "name": { "op": "path", "from": "input", "path": "payload.name" } } } } } } } } ] }';
  SET @fixturesText = N'{ "fixtureType": "consumer-capability-fixtures.v1", "fixtures": [ { "fixtureId": "greets-the-supplied-name", "input": { "contractId": "' + STRING_ESCAPE(@InputContract, 'json') + N'", "payload": { "name": "Sidney" } },
  "expected": { "disposition": "terminated", "terminalScenarioId": "' + STRING_ESCAPE(@CapabilityId, 'json') + N'", "scenarioSequence": [ "' + STRING_ESCAPE(@CapabilityId, 'json') + N'" ],
    "outcomeAssertions": [ { "conditionId": "exact-message", "path": "payload.message", "operator": "equals", "value": "' + STRING_ESCAPE(REPLACE(@GreetingTemplate, N'{name}', N'Sidney'), 'json') + N'" } ] } } ] }';
  SET @inputSchemaText = N'{ "$schema": "https://json-schema.org/draft/2020-12/schema", "$id": "https://schemas.agentic-harness.local/contracts/' + STRING_ESCAPE(@InputContract, 'json') + N'.schema.json",
  "type": "object", "additionalProperties": false, "required": [ "contractId", "payload" ],
  "properties": { "contractId": { "const": "' + STRING_ESCAPE(@InputContract, 'json') + N'" }, "payload": { "type": "object", "additionalProperties": false, "required": [ "name" ],
    "properties": { "name": { "type": "string", "minLength": 1 } } } } }';
  SET @outcomeSchemaText = N'{ "$schema": "https://json-schema.org/draft/2020-12/schema", "$id": "https://schemas.agentic-harness.local/contracts/' + STRING_ESCAPE(@OutcomeContract, 'json') + N'.schema.json",
  "type": "object", "additionalProperties": false, "required": [ "contractId", "payload" ],
  "properties": { "contractId": { "const": "' + STRING_ESCAPE(@OutcomeContract, 'json') + N'" }, "payload": { "type": "object", "additionalProperties": false, "required": [ "message" ],
    "properties": { "message": { "type": "string", "minLength": 1 } } } } }';

  -- 2. Encode only the bytes the model and read path consume:
  --    contract schemas (referenced by schema_object) and the feature text
  --    (referenced by the retained feature binding).
  SET @b_inSchema = CONVERT(varbinary(max), CONVERT(varchar(max), (@inputSchemaText) COLLATE Latin1_General_100_BIN2_UTF8));
  SET @d_inSchema = HASHBYTES('SHA2_256', @b_inSchema);
  SET @b_outSchema = CONVERT(varbinary(max), CONVERT(varchar(max), (@outcomeSchemaText) COLLATE Latin1_General_100_BIN2_UTF8));
  SET @d_outSchema = HASHBYTES('SHA2_256', @b_outSchema);
  SET @b_feat = CONVERT(varbinary(max), CONVERT(varchar(max), (@featureText) COLLATE Latin1_General_100_BIN2_UTF8));
  SET @d_feat = HASHBYTES('SHA2_256', @b_feat);

  -- 3. Workshop enablement: drop the data guards the other workshop scripts drop.
  DECLARE @trg nvarchar(400), @trgCur CURSOR;
  SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
  OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg;
  WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
  CLOSE @trgCur; DEALLOCATE @trgCur;

  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_inSchema) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_inSchema, @b_inSchema, DATALENGTH(@b_inSchema));
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_outSchema) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_outSchema, @b_outSchema, DATALENGTH(@b_outSchema));
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_feat) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_feat, @b_feat, DATALENGTH(@b_feat));

  -- 4. Explicit behavior when the target exists: remove the prior model entries,
  --    then create fresh.
  SELECT @priorCapPk = c.capability_pk FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
    WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@CapabilityId;
  IF @priorCapPk IS NOT NULL
  BEGIN
    SELECT @priorCapVer = MAX(cv.capability_version_pk) FROM model.capability_version cv WHERE cv.capability_pk=@priorCapPk;
    SELECT @priorCapSo = MAX(cv.semantic_object_pk), @priorCapSod = MAX(cv.semantic_object_definition_pk) FROM model.capability_version cv WHERE cv.capability_version_pk=@priorCapVer;
    SELECT @priorScnPk = MAX(s.scenario_pk), @priorScnSo = MAX(s.semantic_object_pk) FROM model.scenario s WHERE s.capability_pk=@priorCapPk;
    SELECT @priorScnVer = MAX(sv.scenario_version_pk), @priorScnSod = MAX(sv.semantic_object_definition_pk) FROM model.scenario_version sv WHERE sv.scenario_pk=@priorScnPk;

    IF OBJECT_ID('tempdb..#priorSod') IS NOT NULL DROP TABLE #priorSod;
    CREATE TABLE #priorSod (sod bigint PRIMARY KEY, so bigint NULL);
    INSERT #priorSod (sod, so) SELECT @priorCapSod, @priorCapSo WHERE @priorCapSod IS NOT NULL;
    INSERT #priorSod (sod, so) SELECT @priorScnSod, @priorScnSo WHERE @priorScnSod IS NOT NULL;
    INSERT #priorSod (sod, so) SELECT si.semantic_object_definition_pk, si.semantic_object_pk FROM model.scenario_input si WHERE si.scenario_version_pk=@priorScnVer;
    INSERT #priorSod (sod, so) SELECT se.semantic_object_definition_pk, se.semantic_object_pk FROM model.scenario_event se WHERE se.scenario_version_pk=@priorScnVer;
    INSERT #priorSod (sod, so) SELECT so.semantic_object_definition_pk, so.semantic_object_pk FROM model.scenario_outcome so WHERE so.scenario_version_pk=@priorScnVer;
    INSERT #priorSod (sod, so) SELECT eav.semantic_object_definition_pk, eav.semantic_object_pk FROM model.execution_authority_version eav JOIN model.execution_authority ea ON ea.execution_authority_pk=eav.execution_authority_pk JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk WHERE n.namespace_id=N'sidefx:capability:'+@CapabilityId;
    INSERT #priorSod (sod, so) SELECT pv.semantic_object_definition_pk, pv.semantic_object_pk FROM model.port_version pv JOIN model.port p ON p.port_pk=pv.port_pk JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk WHERE n.namespace_id=N'sidefx:capability:'+@CapabilityId;
    INSERT #priorSod (sod, so) SELECT tv.semantic_object_definition_pk, tv.semantic_object_pk FROM model.transformation_version tv JOIN model.transformation t ON t.transformation_pk=tv.transformation_pk JOIN model.identity_namespace n ON n.namespace_pk=t.namespace_pk WHERE n.namespace_id=N'sidefx:capability:'+@CapabilityId;
    INSERT #priorSod (sod, so) SELECT oc.semantic_object_definition_pk, oc.semantic_object_pk FROM model.observable_condition oc WHERE oc.owner_definition_pk=@priorCapSod;
    INSERT #priorSod (sod, so) SELECT fv.semantic_object_definition_pk, fv.semantic_object_pk FROM model.feature_version fv JOIN model.feature f ON f.feature_pk=fv.feature_pk WHERE f.feature_id=@CapabilityId;

    DELETE soc FROM model.scenario_outcome_contract soc WHERE soc.scenario_version_pk IN (SELECT scenario_version_pk FROM model.scenario_version WHERE scenario_pk=@priorScnPk);
    DELETE si FROM model.scenario_input si WHERE si.scenario_version_pk IN (SELECT scenario_version_pk FROM model.scenario_version WHERE scenario_pk=@priorScnPk);
    DELETE se FROM model.scenario_event se WHERE se.scenario_version_pk IN (SELECT scenario_version_pk FROM model.scenario_version WHERE scenario_pk=@priorScnPk);
    DELETE so FROM model.scenario_outcome so WHERE so.scenario_version_pk IN (SELECT scenario_version_pk FROM model.scenario_version WHERE scenario_pk=@priorScnPk);
    DELETE ipi FROM model.operation_port_invocation ipi WHERE ipi._owner_definition_pk IN (SELECT sod FROM #priorSod);
    DELETE osi FROM model.operation_scenario_invocation osi WHERE osi._owner_definition_pk IN (SELECT sod FROM #priorSod);
    DELETE eo FROM model.execution_operation eo WHERE eo._owner_definition_pk IN (SELECT sod FROM #priorSod);
    DELETE eav FROM model.execution_authority_version eav WHERE eav.semantic_object_definition_pk IN (SELECT sod FROM #priorSod);
    DELETE ea FROM model.execution_authority ea WHERE ea.semantic_object_pk IN (SELECT so FROM #priorSod WHERE so IS NOT NULL);
    DELETE tc FROM model.transformation_expression_child tc WHERE tc.transformation_version_pk IN (SELECT tv.transformation_version_pk FROM model.transformation_version tv WHERE tv.semantic_object_definition_pk IN (SELECT sod FROM #priorSod));
    DELETE tn FROM model.transformation_expression_node tn WHERE tn.transformation_version_pk IN (SELECT tv.transformation_version_pk FROM model.transformation_version tv WHERE tv.semantic_object_definition_pk IN (SELECT sod FROM #priorSod));
    DELETE tr FROM model.transformation_root tr WHERE tr.transformation_version_pk IN (SELECT tv.transformation_version_pk FROM model.transformation_version tv WHERE tv.semantic_object_definition_pk IN (SELECT sod FROM #priorSod));
    DELETE tv FROM model.transformation_version tv WHERE tv.semantic_object_definition_pk IN (SELECT sod FROM #priorSod);
    DELETE t FROM model.transformation t WHERE t.semantic_object_pk IN (SELECT so FROM #priorSod WHERE so IS NOT NULL);
    DELETE pv FROM model.port_version pv WHERE pv.semantic_object_definition_pk IN (SELECT sod FROM #priorSod);
    DELETE p FROM model.port p WHERE p.semantic_object_pk IN (SELECT so FROM #priorSod WHERE so IS NOT NULL);
    DELETE crs FROM model.capability_root_scenario crs WHERE crs.capability_version_pk IN (SELECT capability_version_pk FROM model.capability_version WHERE capability_pk=@priorCapPk);
    DELETE cs FROM model.capability_scenario cs WHERE cs.capability_pk=@priorCapPk;
    DELETE oc FROM model.observable_condition oc WHERE oc.owner_definition_pk=@priorCapSod;
    UPDATE model.capability SET feature_pk=NULL WHERE capability_pk=@priorCapPk;
    DELETE fs FROM model.feature_scenario fs WHERE fs.feature_version_pk IN (SELECT fv.feature_version_pk FROM model.feature_version fv JOIN model.feature f ON f.feature_pk=fv.feature_pk WHERE f.feature_id=@CapabilityId);
    DELETE ecf FROM model.estate_capability_feature ecf WHERE ecf.capability_pk=@priorCapPk;
    DELETE fv FROM model.feature_version fv WHERE fv.feature_pk IN (SELECT feature_pk FROM model.feature WHERE feature_id=@CapabilityId);
    DELETE f FROM model.feature f WHERE f.feature_id=@CapabilityId;
    DELETE sv FROM model.scenario_version sv WHERE sv.scenario_pk=@priorScnPk;
    DELETE s FROM model.scenario s WHERE s.capability_pk=@priorCapPk;
    DELETE ec FROM model.estate_capability ec WHERE ec.capability_pk=@priorCapPk;
    DELETE cvv FROM model.capability_version cvv WHERE cvv.capability_pk=@priorCapPk;
    DELETE cc FROM model.capability cc WHERE cc.capability_pk=@priorCapPk;
    -- Superseded definitions and any pre-existing source rows are left in place:
    -- the read path selects the latest definition per semantic object, and this
    -- authoring surface writes no source rows. Deleting them would require
    -- touching source.source_lineage, which is outside this surface.
    DROP TABLE #priorSod;
  END

  -- 5. Normalized model chain. Every definition is a content-addressed
  --    sidefx-semantic-definition.v1 envelope.
  DECLARE @capId nvarchar(400) = @CapabilityId;
  DECLARE @ownedCapNs nvarchar(400), @ownedScnNs nvarchar(400);
  DECLARE @capAddress nvarchar(1000) = N'{"id":"' + STRING_ESCAPE(@capId,'json') + N'","kind":"CAPABILITY","namespace":"sidefx:capabilities"}';
  SET @ownedCapNs = N'owner:sha256:' + LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (@capAddress) COLLATE Latin1_General_100_BIN2_UTF8))), 2));
  DECLARE @scnAddress nvarchar(1000) = N'{"id":"' + STRING_ESCAPE(@capId,'json') + N'","kind":"SCENARIO","namespace":"' + @ownedCapNs + N'"}';
  SET @ownedScnNs = N'owner:sha256:' + LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (@scnAddress) COLLATE Latin1_General_100_BIN2_UTF8))), 2));

  DECLARE @featureAst nvarchar(max) =
    N'{"description":"","examples":[],"keyword":"Scenario","name":"' + STRING_ESCAPE(@capId,'json') + N' greeting",'
    + N'"steps":[{"keyword":"Given ","keywordType":"Context","text":"a caller name"},'
    + N'{"keyword":"When ","keywordType":"Action","text":"the greeting is requested"},'
    + N'{"keyword":"Then ","keywordType":"Outcome","text":"the caller receives the greeting with the name substituted"}],'
    + N'"tags":[{"name":"@scenario:' + @capId + N'"},{"name":"@input:' + @InputId + N'"},{"name":"@input-contract:' + @InputContract + N'"},'
    + N'{"name":"@event:' + @capId + N'"},{"name":"@event-authority:' + @EventAuthorityId + N'"},'
    + N'{"name":"@outcome:' + @OutcomeId + N'"},{"name":"@outcome-contract:' + @OutcomeContract + N'"},{"name":"@outcome-terminal"}]}';

  DECLARE @tags nvarchar(max) =
    N'{"capability":["' + @capId + N'"],"event":["' + @capId + N'"],"event-authority":["' + @EventAuthorityId + N'"],'
    + N'"input":["' + @InputId + N'"],"input-contract":["' + @InputContract + N'"],"outcome":["' + @OutcomeId + N'"],'
    + N'"outcome-contract":["' + @OutcomeContract + N'"],"outcome-terminal":[true],"root-scenario":["' + @capId + N'"],"scenario":["' + @capId + N'"]}';

  SET @manifest = N'[' +
    N'{"fragment":"' + LOWER(CONVERT(varchar(64), @d_feat, 2)) + N'","role":"feature"}]';
  SET @manifestHex = LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (@manifest) COLLATE Latin1_General_100_BIN2_UTF8))), 2));

  DECLARE @defs TABLE (kind varchar(50) COLLATE Latin1_General_100_BIN2, ns_kind varchar(50) COLLATE Latin1_General_100_BIN2, declared_id nvarchar(400) COLLATE Latin1_General_100_BIN2, namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2, dgst binary(32), bytes varbinary(max));
  DECLARE @d_capDef binary(32), @d_scnDef binary(32), @d_auth binary(32), @d_portDef binary(32), @d_transDef binary(32),
          @d_cond binary(32), @d_contractIn binary(32), @d_contractOut binary(32),
          @d_input binary(32), @d_event binary(32), @d_out binary(32), @d_featRet binary(32), @d_featPar binary(32),
          @portPk bigint, @portVer bigint, @transPk bigint, @transVer bigint, @eaPk bigint, @eaVer bigint, @opPk bigint,
          @schemaInPk bigint, @schemaOutPk bigint, @contractInPk bigint, @contractInVer bigint, @contractOutPk bigint, @contractOutVer bigint,
          @featNs bigint, @featSo bigint, @featSodR bigint, @featSodP bigint, @featPk bigint, @featVerR bigint, @featVerP bigint;

  -- CAPABILITY
  SET @env = N'{"address":{"id":"' + @capId + N'","kind":"CAPABILITY","namespace":"sidefx:capabilities"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":' + @capText + N',"cli":' + @cliJson + N',"contributions":' + @manifest + N',"scenario_members":{"' + @capId + N'":' + @featureAst + N'}}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_capDef = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('CAPABILITY','CAPABILITY',@capId,N'sidefx:capabilities',@d_capDef,@envBytes);

  -- SCENARIO
  SET @env = N'{"address":{"id":"' + @capId + N'","kind":"SCENARIO","namespace":"' + @ownedCapNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"authority_manifest_digest":"' + @manifestHex + N'","scenario":' + @featureAst + N',"tags":' + @tags + N'}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_scnDef = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('SCENARIO','SCENARIO',@capId,@ownedCapNs,@d_scnDef,@envBytes);

  -- TRANSFORMATION
  SET @env = N'{"address":{"id":"' + @TransformationId + N'","kind":"TRANSFORMATION","namespace":"sidefx:capability:' + @capId + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"expression":{"fields":{"contractId":{"op":"literal","value":"' + @OutcomeContract + N'"},"payload":{"fields":{"message":{"op":"format","template":"' + STRING_ESCAPE(@GreetingTemplate,'json') + N'","values":{"name":{"from":"input","op":"path","path":"payload.name"}}}},"op":"object"}},"op":"object"},"id":"' + @TransformationId + N'"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_transDef = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('TRANSFORMATION','TRANSFORMATION',@TransformationId,N'sidefx:capability:' + @capId,@d_transDef,@envBytes);

  -- PORT
  SET @env = N'{"address":{"id":"' + @PortId + N'","kind":"PORT","namespace":"sidefx:capability:' + @capId + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"' + @TransformationId + N'"},"platformCapabilityId":"sda-authority-transformation-port.v1","portId":"' + @PortId + N'"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_portDef = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('PORT','PORT',@PortId,N'sidefx:capability:' + @capId,@d_portDef,@envBytes);

  -- EXECUTION_AUTHORITY
  SET @env = N'{"address":{"id":"' + @EventAuthorityId + N'","kind":"EXECUTION_AUTHORITY","namespace":"sidefx:capability:' + @capId + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":{"id":"' + @EventAuthorityId + N'","operations":[{"kind":"invoke-port","portId":"' + @PortId + N'"}],"owningScenarioId":"' + @capId + N'"},"authority_manifest_digest":"' + @manifestHex + N'"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_auth = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('EXECUTION_AUTHORITY','EXECUTION_AUTHORITY',@EventAuthorityId,N'sidefx:capability:' + @capId,@d_auth,@envBytes);

  -- CONTRACTS
  SET @env = N'{"address":{"id":"' + @InputContract + N'","kind":"CONTRACT","namespace":"sidefx:contracts"},"format":"sidefx-semantic-definition.v1","semantics":{"schema_digest":"' + LOWER(CONVERT(varchar(64), @d_inSchema, 2)) + N'"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_contractIn = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('CONTRACT','CONTRACT',@InputContract,N'sidefx:contracts',@d_contractIn,@envBytes);
  SET @env = N'{"address":{"id":"' + @OutcomeContract + N'","kind":"CONTRACT","namespace":"sidefx:contracts"},"format":"sidefx-semantic-definition.v1","semantics":{"schema_digest":"' + LOWER(CONVERT(varchar(64), @d_outSchema, 2)) + N'"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_contractOut = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('CONTRACT','CONTRACT',@OutcomeContract,N'sidefx:contracts',@d_contractOut,@envBytes);

  -- SCENARIO_INPUT
  SET @env = N'{"address":{"id":"' + @InputId + N'","kind":"SCENARIO_INPUT","namespace":"' + @ownedScnNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"declared_reference":"' + @InputContract + N'","id":"' + @InputId + N'","owner_definition_digest":"' + LOWER(CONVERT(varchar(64), @d_scnDef, 2)) + N'","role":"input","target_definition_digest":"' + LOWER(CONVERT(varchar(64), @d_contractIn, 2)) + N'","text":"a caller name"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_input = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('SCENARIO_INPUT','SCENARIO_INPUT',@InputId,@ownedScnNs,@d_input,@envBytes);

  -- SCENARIO_EVENT
  SET @env = N'{"address":{"id":"' + @capId + N'","kind":"SCENARIO_EVENT","namespace":"' + @ownedScnNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"declared_reference":"' + @EventAuthorityId + N'","id":"' + @capId + N'","owner_definition_digest":"' + LOWER(CONVERT(varchar(64), @d_scnDef, 2)) + N'","role":"event","target_definition_digest":"' + LOWER(CONVERT(varchar(64), @d_auth, 2)) + N'","text":"the greeting is requested"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_event = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('SCENARIO_EVENT','SCENARIO_EVENT',@capId,@ownedScnNs,@d_event,@envBytes);

  -- SCENARIO_OUTCOME
  SET @env = N'{"address":{"id":"' + @OutcomeId + N'","kind":"SCENARIO_OUTCOME","namespace":"' + @ownedScnNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"declared_reference":null,"id":"' + @OutcomeId + N'","owner_definition_digest":"' + LOWER(CONVERT(varchar(64), @d_scnDef, 2)) + N'","role":"outcome","text":"the caller receives the greeting with the name substituted"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_out = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('SCENARIO_OUTCOME','SCENARIO_OUTCOME',@OutcomeId,@ownedScnNs,@d_out,@envBytes);

  -- OBSERVABLE_CONDITION
  SET @env = N'{"address":{"id":"message-delivered-to-standard-output","kind":"OBSERVABLE_CONDITION","namespace":"' + @ownedCapNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"condition":{"conditionId":"message-delivered-to-standard-output"},"owner_definition_digest":"' + LOWER(CONVERT(varchar(64), @d_capDef, 2)) + N'"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_cond = HASHBYTES('SHA2_256', @envBytes);
  INSERT @defs VALUES ('OBSERVABLE_CONDITION','OBSERVABLE_CONDITION',N'message-delivered-to-standard-output',@ownedCapNs,@d_cond,@envBytes);

  -- 6. Set-based identity, definition and model membership rows.
  INSERT source.content_object (content_digest, content_bytes, byte_length)
    SELECT x.dgst, x.bytes, DATALENGTH(x.bytes) FROM @defs x WHERE NOT EXISTS (SELECT 1 FROM source.content_object c WHERE c.content_digest=x.dgst);
  INSERT model.identity_namespace (namespace_kind, namespace_id)
    SELECT DISTINCT x.ns_kind, x.namespace_id FROM @defs x WHERE NOT EXISTS (SELECT 1 FROM model.identity_namespace n WHERE n.namespace_kind=x.ns_kind AND n.namespace_id=x.namespace_id);
  INSERT model.semantic_object (object_kind, namespace_pk, declared_id)
    SELECT DISTINCT x.kind, n.namespace_pk, x.declared_id FROM @defs x JOIN model.identity_namespace n ON n.namespace_kind=x.ns_kind AND n.namespace_id=x.namespace_id
    WHERE NOT EXISTS (SELECT 1 FROM model.semantic_object s WHERE s.object_kind=x.kind AND s.namespace_pk=n.namespace_pk AND s.declared_id=x.declared_id);
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
    SELECT s.semantic_object_pk, x.kind, x.dgst, c.content_object_pk FROM @defs x
    JOIN model.identity_namespace n ON n.namespace_kind=x.ns_kind AND n.namespace_id=x.namespace_id
    JOIN model.semantic_object s ON s.object_kind=x.kind AND s.namespace_pk=n.namespace_pk AND s.declared_id=x.declared_id
    JOIN source.content_object c ON c.content_digest=x.dgst
    WHERE NOT EXISTS (SELECT 1 FROM model.semantic_object_definition d WHERE d.semantic_object_pk=s.semantic_object_pk AND d.definition_digest=x.dgst);
  INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk)
    SELECT @model, d.semantic_object_definition_pk FROM @defs x
    JOIN model.identity_namespace n ON n.namespace_kind=x.ns_kind AND n.namespace_id=x.namespace_id
    JOIN model.semantic_object s ON s.object_kind=x.kind AND s.namespace_pk=n.namespace_pk AND s.declared_id=x.declared_id
    JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk AND d.definition_digest=x.dgst
    WHERE NOT EXISTS (SELECT 1 FROM model.estate_definition e WHERE e.estate_model_pk=@model AND e.semantic_object_definition_pk=d.semantic_object_definition_pk);

  SELECT @capSo=s.semantic_object_pk,@capSod=d.semantic_object_definition_pk FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk WHERE n.namespace_id=N'sidefx:capabilities' AND s.declared_id=@capId AND d.definition_digest=@d_capDef;
  SELECT @scnSo=s.semantic_object_pk,@scnSod=d.semantic_object_definition_pk FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk WHERE n.namespace_id=@ownedCapNs AND s.declared_id=@capId AND d.definition_digest=@d_scnDef;
  SELECT @capNs=namespace_pk FROM model.identity_namespace WHERE namespace_kind='CAPABILITY' AND namespace_id=N'sidefx:capabilities';
  SELECT @scenarioNs=namespace_pk FROM model.identity_namespace WHERE namespace_kind='SCENARIO' AND namespace_id=@ownedCapNs;

  INSERT model.capability (namespace_pk, capability_id, semantic_object_pk, object_kind) VALUES (@capNs, @capId, @capSo, 'CAPABILITY'); SET @capPk = SCOPE_IDENTITY();
  INSERT model.capability_version (capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@capPk, @capSo, @capSod, @d_capDef, @capId, 'CAPABILITY', @capSod, N''); SET @capVer = SCOPE_IDENTITY();
  INSERT model.estate_capability (estate_model_pk, capability_pk, capability_version_pk, semantic_object_definition_pk) VALUES (@model, @capPk, @capVer, @capSod);

  INSERT model.scenario (namespace_pk, scenario_id, semantic_object_pk, object_kind, capability_pk) VALUES (@scenarioNs, @capId, @scnSo, 'SCENARIO', @capPk); SET @scnPk = SCOPE_IDENTITY();
  INSERT model.scenario_version (scenario_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, source_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@scnPk, @scnSo, @scnSod, @d_scnDef, @capId, 'managed-feature-tags.v1', 'SCENARIO', @scnSod, N''); SET @scnVer = SCOPE_IDENTITY();
  INSERT model.capability_scenario (capability_pk, capability_version_pk, scenario_pk, scenario_version_pk, _owner_definition_pk, _canonical_pointer)
    VALUES (@capPk, @capVer, @scnPk, @scnVer, @capSod, N'/semantics/scenario_members/' + @capId);
  INSERT model.capability_root_scenario (capability_version_pk, scenario_pk, _owner_definition_pk, _canonical_pointer) VALUES (@capVer, @scnPk, @capSod, N'');

  -- Contracts and schemas: shared estate identities; mint what is missing.
  IF NOT EXISTS (SELECT 1 FROM model.schema_object WHERE content_digest=@d_inSchema)
    INSERT model.schema_object (content_digest, dialect, content_object_pk) VALUES (@d_inSchema, N'https://json-schema.org/draft/2020-12/schema', (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_inSchema));
  SET @schemaInPk=(SELECT schema_object_pk FROM model.schema_object WHERE content_digest=@d_inSchema);
  IF NOT EXISTS (SELECT 1 FROM model.schema_object WHERE content_digest=@d_outSchema)
    INSERT model.schema_object (content_digest, dialect, content_object_pk) VALUES (@d_outSchema, N'https://json-schema.org/draft/2020-12/schema', (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_outSchema));
  SET @schemaOutPk=(SELECT schema_object_pk FROM model.schema_object WHERE content_digest=@d_outSchema);

  SELECT @contractInPk=ct.contract_pk FROM model.contract ct JOIN model.identity_namespace n ON n.namespace_pk=ct.namespace_pk WHERE n.namespace_id=N'sidefx:contracts' AND ct.contract_id=@InputContract;
  IF @contractInPk IS NULL
  BEGIN
    INSERT model.contract (namespace_pk, contract_id, semantic_object_pk, object_kind)
      SELECT n.namespace_pk, @InputContract, s.semantic_object_pk, 'CONTRACT' FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk WHERE n.namespace_id=N'sidefx:contracts' AND s.declared_id=@InputContract;
    SET @contractInPk=SCOPE_IDENTITY();
  END
  SELECT @contractInVer=contract_version_pk FROM model.contract_version WHERE contract_pk=@contractInPk AND definition_digest=@d_contractIn;
  IF @contractInVer IS NULL
  BEGIN
    INSERT model.contract_version (contract_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, contract_kind, schema_object_pk, object_kind, _owner_definition_pk, _canonical_pointer, schema_reference_state)
      SELECT @contractInPk, s.semantic_object_pk, d.semantic_object_definition_pk, d.definition_digest, NULL, NULL, @schemaInPk, 'CONTRACT', d.semantic_object_definition_pk, N'', 'RESOLVED'
      FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
      WHERE n.namespace_id=N'sidefx:contracts' AND s.declared_id=@InputContract AND d.definition_digest=@d_contractIn;
    SET @contractInVer=SCOPE_IDENTITY();
  END
  SELECT @contractOutPk=ct.contract_pk FROM model.contract ct JOIN model.identity_namespace n ON n.namespace_pk=ct.namespace_pk WHERE n.namespace_id=N'sidefx:contracts' AND ct.contract_id=@OutcomeContract;
  IF @contractOutPk IS NULL
  BEGIN
    INSERT model.contract (namespace_pk, contract_id, semantic_object_pk, object_kind)
      SELECT n.namespace_pk, @OutcomeContract, s.semantic_object_pk, 'CONTRACT' FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk WHERE n.namespace_id=N'sidefx:contracts' AND s.declared_id=@OutcomeContract;
    SET @contractOutPk=SCOPE_IDENTITY();
  END
  SELECT @contractOutVer=contract_version_pk FROM model.contract_version WHERE contract_pk=@contractOutPk AND definition_digest=@d_contractOut;
  IF @contractOutVer IS NULL
  BEGIN
    INSERT model.contract_version (contract_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, contract_kind, schema_object_pk, object_kind, _owner_definition_pk, _canonical_pointer, schema_reference_state)
      SELECT @contractOutPk, s.semantic_object_pk, d.semantic_object_definition_pk, d.definition_digest, NULL, NULL, @schemaOutPk, 'CONTRACT', d.semantic_object_definition_pk, N'', 'RESOLVED'
      FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
      WHERE n.namespace_id=N'sidefx:contracts' AND s.declared_id=@OutcomeContract AND d.definition_digest=@d_contractOut;
    SET @contractOutVer=SCOPE_IDENTITY();
  END

  -- Port and transformation.
  INSERT model.port (namespace_pk, port_id, semantic_object_pk, object_kind)
    SELECT n.namespace_pk, @PortId, s.semantic_object_pk, 'PORT' FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk WHERE n.namespace_id=N'sidefx:capability:' + @capId AND s.declared_id=@PortId; SET @portPk=SCOPE_IDENTITY();
  INSERT model.port_version (port_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, port_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    SELECT @portPk, s.semantic_object_pk, d.semantic_object_definition_pk, d.definition_digest, NULL, 'consumer-interface-authority.v1', 'PORT', d.semantic_object_definition_pk, N''
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=N'sidefx:capability:' + @capId AND s.declared_id=@PortId AND d.definition_digest=@d_portDef; SET @portVer=SCOPE_IDENTITY();
  INSERT model.transformation (namespace_pk, transformation_id, semantic_object_pk, object_kind)
    SELECT n.namespace_pk, @TransformationId, s.semantic_object_pk, 'TRANSFORMATION' FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk WHERE n.namespace_id=N'sidefx:capability:' + @capId AND s.declared_id=@TransformationId; SET @transPk=SCOPE_IDENTITY();
  INSERT model.transformation_version (transformation_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, expression_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    SELECT @transPk, s.semantic_object_pk, d.semantic_object_definition_pk, d.definition_digest, 'json-expression-tree.v1', 'TRANSFORMATION', d.semantic_object_definition_pk, N''
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=N'sidefx:capability:' + @capId AND s.declared_id=@TransformationId AND d.definition_digest=@d_transDef; SET @transVer=SCOPE_IDENTITY();

  -- Execution authority, operation and its port invocation.
  INSERT model.execution_authority (namespace_pk, execution_authority_id, semantic_object_pk, object_kind)
    SELECT n.namespace_pk, @EventAuthorityId, s.semantic_object_pk, 'EXECUTION_AUTHORITY' FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk WHERE n.namespace_id=N'sidefx:capability:' + @capId AND s.declared_id=@EventAuthorityId; SET @eaPk=SCOPE_IDENTITY();
  INSERT model.execution_authority_version (execution_authority_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, authority_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    SELECT @eaPk, s.semantic_object_pk, d.semantic_object_definition_pk, d.definition_digest, 'execution-authorities.v1', 'EXECUTION_AUTHORITY', d.semantic_object_definition_pk, N''
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=N'sidefx:capability:' + @capId AND s.declared_id=@EventAuthorityId AND d.definition_digest=@d_auth; SET @eaVer=SCOPE_IDENTITY();
  INSERT model.execution_operation (execution_authority_version_pk, operation_id, ordinal, operation_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@eaVer, NULL, 0, 'invoke-port', (SELECT semantic_object_definition_pk FROM model.execution_authority_version WHERE execution_authority_version_pk=@eaVer), N'/semantics/authority/operations/0'); SET @opPk=SCOPE_IDENTITY();
  INSERT model.operation_port_invocation (execution_operation_pk, port_version_pk, operation_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@opPk, @portVer, 'invoke-port', (SELECT semantic_object_definition_pk FROM model.execution_authority_version WHERE execution_authority_version_pk=@eaVer), N'/semantics/authority/operations/0');

  -- Scenario faces.
  INSERT model.scenario_input (scenario_version_pk, input_id, name, input_contract_version_pk, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer, contract_reference_state)
    SELECT @scnVer, @InputId, NULL, @contractInVer, s.semantic_object_pk, d.semantic_object_definition_pk, n.namespace_pk, d.definition_digest, 'SCENARIO_INPUT', @scnSod, N'', 'RESOLVED'
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=@ownedScnNs AND s.declared_id=@InputId AND d.definition_digest=@d_input;
  INSERT model.scenario_event (scenario_version_pk, event_id, name, responsibility, execution_authority_version_pk, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer, authority_reference_state)
    SELECT @scnVer, @capId, NULL, N'the greeting is requested', @eaVer, s.semantic_object_pk, d.semantic_object_definition_pk, n.namespace_pk, d.definition_digest, 'SCENARIO_EVENT', @scnSod, N'', 'RESOLVED'
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=@ownedScnNs AND s.declared_id=@capId AND d.definition_digest=@d_event;
  INSERT model.scenario_outcome (scenario_version_pk, outcome_id, name, experience, terminal, terminal_disposition, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer)
    SELECT @scnVer, @OutcomeId, NULL, N'the caller receives the greeting with the name substituted', 1, NULL, s.semantic_object_pk, d.semantic_object_definition_pk, n.namespace_pk, d.definition_digest, 'SCENARIO_OUTCOME', @scnSod, N''
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=@ownedScnNs AND s.declared_id=@OutcomeId AND d.definition_digest=@d_out;
  INSERT model.scenario_outcome_contract (scenario_version_pk, contract_version_pk, _owner_definition_pk, _canonical_pointer)
    VALUES (@scnVer, @contractOutVer, @scnSod, N'/semantics/tags/outcome-contract');

  -- Observable condition.
  INSERT model.observable_condition (owner_definition_pk, condition_id, statement, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer)
    SELECT @capSod, N'message-delivered-to-standard-output', NULL, s.semantic_object_pk, d.semantic_object_definition_pk, n.namespace_pk, d.definition_digest, 'OBSERVABLE_CONDITION', d.semantic_object_definition_pk, N''
    FROM model.identity_namespace n JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk
    WHERE n.namespace_id=@ownedCapNs AND s.declared_id=N'message-delivered-to-standard-output' AND d.definition_digest=@d_cond;

  -- Canonical feature (retained binding + parsed declaration) and generation membership.
  DECLARE @featureNs bigint = (SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='FEATURE' AND namespace_id=N'sidefx:features');
  IF @featureNs IS NULL BEGIN INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('FEATURE', N'sidefx:features'); SET @featureNs=SCOPE_IDENTITY(); END
  SELECT @featSo = semantic_object_pk FROM model.semantic_object WHERE object_kind='FEATURE' AND namespace_pk=@featureNs AND declared_id=@capId;
  IF @featSo IS NULL BEGIN INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES ('FEATURE', @featureNs, @capId); SET @featSo=SCOPE_IDENTITY(); END
  SET @env = N'{"address":{"id":"' + @capId + N'","kind":"FEATURE","namespace":"sidefx:features"},"format":"sidefx-semantic-definition.v1","semantics":{"content_digest":"' + LOWER(CONVERT(varchar(64), @d_feat, 2)) + N'","source_class":"WORKSHOP","source_path":"features/' + @capId + N'.feature"}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_featRet = HASHBYTES('SHA2_256', @envBytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_featRet) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_featRet, @envBytes, DATALENGTH(@envBytes));
  SELECT @featSodR = semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@featSo AND definition_digest=@d_featRet;
  IF @featSodR IS NULL BEGIN
    INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@featSo, 'FEATURE', @d_featRet, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_featRet)); SET @featSodR=SCOPE_IDENTITY();
  END
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@featSodR)
    INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @featSodR);
  SET @env = N'{"address":{"id":"' + @capId + N'","kind":"FEATURE","namespace":"sidefx:features"},"format":"sidefx-semantic-definition.v1","semantics":{"name":"' + STRING_ESCAPE(@capId,'json') + N' greeting","description":"A caller supplies a name and receives the configured greeting with that name substituted.","content_digest":"' + LOWER(CONVERT(varchar(64), @d_feat, 2)) + N'","source_path":"features/' + @capId + N'.feature","scenarios":[{"scenarioId":"' + @capId + N'","scenarioVersionPk":' + CONVERT(nvarchar(20), @scnVer) + N'}]}}';
  SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8)); SET @d_featPar = HASHBYTES('SHA2_256', @envBytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@d_featPar) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@d_featPar, @envBytes, DATALENGTH(@envBytes));
  SELECT @featSodP = semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@featSo AND definition_digest=@d_featPar;
  IF @featSodP IS NULL BEGIN
    INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk) VALUES (@featSo, 'FEATURE', @d_featPar, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@d_featPar)); SET @featSodP=SCOPE_IDENTITY();
  END
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@featSodP)
    INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @featSodP);
  INSERT model.feature (namespace_pk, feature_id, semantic_object_pk, object_kind) VALUES (@featureNs, @capId, @featSo, 'FEATURE'); SET @featPk=SCOPE_IDENTITY();
  INSERT model.feature_version (feature_pk, capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, source_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@featPk, @capPk, @featSo, @featSodR, @d_featRet, @capId, 'retained-feature-binding.v1', 'FEATURE', @featSodR, N''); SET @featVerR=SCOPE_IDENTITY();
  INSERT model.feature_version (feature_pk, capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, source_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@featPk, @capPk, @featSo, @featSodP, @d_featPar, @capId, 'parsed-feature-declaration.v1', 'FEATURE', @featSodP, N''); SET @featVerP=SCOPE_IDENTITY();
  INSERT model.feature_scenario (feature_version_pk, scenario_pk, scenario_version_pk, capability_pk, ordinal) VALUES (@featVerP, @scnPk, @scnVer, @capPk, 0);
  INSERT model.estate_capability_feature (estate_model_pk, capability_pk, capability_version_pk, feature_version_pk, binding_role) VALUES (@model, @capPk, @capVer, @featVerP, 'CANONICAL');
  UPDATE model.capability SET feature_pk=@featPk WHERE capability_pk=@capPk;

  -- 7. Result: the affected identities.
  SELECT N'SCAFFOLD' AS action, @action AS disposition, @CapabilityId AS capability_id,
         @capPk AS capability_pk, @capVer AS capability_version_pk, @capSod AS capability_definition_pk,
         @scnPk AS scenario_pk, @scnVer AS scenario_version_pk,
         @GreetingTemplate AS greeting_template, @InputContract AS input_contract, @OutcomeContract AS outcome_contract;
END;
GO

-- =====================================================================
-- model.configure_mechanic
-- Change a capability's mechanic parameter (the greeting template) and the
-- example's expectation, without recreating the capability. Returns the
-- before/after values.
-- =====================================================================
CREATE OR ALTER PROCEDURE model.configure_mechanic
  @capability_id     nvarchar(120),
  @greeting_template nvarchar(200)
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
  IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;

  DECLARE @capPk bigint, @capSod bigint;
  SELECT @capPk = c.capability_pk, @capSod = ec.semantic_object_definition_pk
  FROM model.estate_capability ec
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
  JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
  WHERE ec.estate_model_pk = @model AND c.capability_id = @capability_id AND n.namespace_id = N'sidefx:capabilities';
  IF @capPk IS NULL THROW 51001, 'CAPABILITY_NOT_FOUND', 1;

  DECLARE @transPk bigint, @transSo bigint, @transId nvarchar(400);
  SELECT TOP 1 @transPk = t.transformation_pk, @transSo = t.semantic_object_pk, @transId = t.transformation_id
  FROM model.transformation t JOIN model.identity_namespace n ON n.namespace_pk = t.namespace_pk
  WHERE n.namespace_id = N'sidefx:capability:' + @capability_id
  ORDER BY t.transformation_pk;
  IF @transPk IS NULL THROW 51001, 'MECHANIC_NOT_FOUND', 1;

  DECLARE @curSod bigint, @curEnv nvarchar(max);
  SELECT TOP 1 @curSod = d.semantic_object_definition_pk,
         @curEnv = CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM model.semantic_object_definition d
  JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
  WHERE d.semantic_object_pk = @transSo
  ORDER BY d.semantic_object_definition_pk DESC;
  DECLARE @before nvarchar(400) = JSON_VALUE(@curEnv, '$.semantics.expression.fields.payload.fields.message.template');

  DECLARE @newEnv nvarchar(max) = JSON_MODIFY(@curEnv, '$.semantics.expression.fields.payload.fields.message.template', @greeting_template);
  IF @newEnv IS NULL THROW 51001, 'MECHANIC_TEMPLATE_NOT_FOUND', 1;

  DECLARE @newBytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
  DECLARE @newDigest binary(32) = HASHBYTES('SHA2_256', @newBytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@newDigest)
    INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@newDigest, @newBytes, DATALENGTH(@newBytes));
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
    VALUES (@transSo, 'TRANSFORMATION', @newDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@newDigest));
  DECLARE @newSod bigint = SCOPE_IDENTITY();
  INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @newSod);

  -- New transformation version and the port version that references it.
  DECLARE @newTransVer bigint;
  INSERT model.transformation_version (transformation_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, expression_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@transPk, @transSo, @newSod, @newDigest, 'json-expression-tree.v1', 'TRANSFORMATION', @newSod, N'');
  SET @newTransVer = SCOPE_IDENTITY();

  -- Keep the example's expectation in agreement with the mechanic.
  DECLARE @fixtureId nvarchar(400), @fixSo bigint, @fixSod bigint, @fixEnv nvarchar(max), @fixNew nvarchar(max);
  SELECT TOP 1 @fixtureId = fx.fixture_id, @fixSo = fx.semantic_object_pk, @fixSod = fx.semantic_object_definition_pk
  FROM model.fixture fx WHERE fx.owner_definition_pk = @capSod;
  IF @fixSod IS NOT NULL
  BEGIN
    SELECT @fixEnv = CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
    FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
    WHERE d.semantic_object_definition_pk = @fixSod;
    SET @fixNew = JSON_MODIFY(@fixEnv, '$.semantics.fixture.expected.outcomeAssertions[0].value', REPLACE(@greeting_template, N'{name}', N'Sidney'));
    IF @fixNew IS NOT NULL
    BEGIN
      DECLARE @fixBytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@fixNew) COLLATE Latin1_General_100_BIN2_UTF8));
      DECLARE @fixDigest binary(32) = HASHBYTES('SHA2_256', @fixBytes);
      IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@fixDigest)
        INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@fixDigest, @fixBytes, DATALENGTH(@fixBytes));
      INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
        VALUES (@fixSo, 'FIXTURE', @fixDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@fixDigest));
      DECLARE @fixNewSod bigint = SCOPE_IDENTITY();
      INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @fixNewSod);
      UPDATE model.fixture SET semantic_object_definition_pk=@fixNewSod, definition_digest=@fixDigest WHERE semantic_object_pk=@fixSo AND owner_definition_pk=@capSod;
    END
  END

  SELECT N'CONFIGURE_MECHANIC' AS action, @capability_id AS capability_id, @transId AS mechanic_id,
         @before AS template_before, @greeting_template AS template_after,
         @curSod AS definition_before, @newSod AS definition_after, @newTransVer AS transformation_version_pk, @fixtureId AS fixture_id;
END;
GO

-- =====================================================================
-- model.inspect_capability
-- Return the assembled meaning, contracts, mechanics, bindings and the
-- unresolved references execution would still have to resolve.
-- =====================================================================
CREATE OR ALTER PROCEDURE model.inspect_capability
  @capability_id nvarchar(120)
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
  IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;

  DECLARE @capPk bigint, @capVer bigint, @capSod bigint;
  SELECT @capPk = ec.capability_pk, @capVer = ec.capability_version_pk, @capSod = ec.semantic_object_definition_pk
  FROM model.estate_capability ec
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
  JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
  WHERE ec.estate_model_pk = @model AND c.capability_id = @capability_id AND n.namespace_id = N'sidefx:capabilities';
  IF @capPk IS NULL THROW 51001, 'CAPABILITY_NOT_FOUND', 1;

  SELECT N'identity' AS result_set, c.capability_id, @capVer AS capability_version_pk, @capSod AS capability_definition_pk,
         'sha256:' + LOWER(CONVERT(varchar(64), d.definition_digest, 2)) AS capability_definition_digest,
         JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.authority.userStory.intent') AS intent
  FROM model.capability c
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = @capSod
  JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
  WHERE c.capability_pk = @capPk;

  SELECT N'assembled_declarations' AS result_set, v.source_path, v.entry_id,
         DATALENGTH(CONVERT(varbinary(max), CONVERT(varchar(max), v.document) COLLATE Latin1_General_100_BIN2_UTF8)) AS byte_length
  FROM analysis.v_capability_execution_declaration v
  WHERE v.capability_id = @capability_id
  ORDER BY v.source_path;

  SELECT N'cli_configuration' AS result_set, JSON_QUERY(v.document, '$.interfaces[0].configuration') AS configuration
  FROM analysis.v_capability_execution_declaration v
  WHERE v.capability_id = @capability_id AND v.entry_id = N'interfaces.authority.json';

  SELECT N'mechanic' AS result_set, t.transformation_id, t.transformation_pk,
         JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.expression.fields.payload.fields.message.template') AS greeting_template
  FROM model.transformation t
  JOIN model.identity_namespace n ON n.namespace_pk = t.namespace_pk
  JOIN model.semantic_object_definition d ON d.semantic_object_pk = t.semantic_object_pk
  JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
  WHERE n.namespace_id = N'sidefx:capability:' + @capability_id
    AND d.semantic_object_definition_pk = (SELECT MAX(d2.semantic_object_definition_pk) FROM model.semantic_object_definition d2 WHERE d2.semantic_object_pk = t.semantic_object_pk)
  ORDER BY t.transformation_pk;

  SELECT N'example' AS result_set, fx.fixture_id, fx.fixture_profile,
         JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.fixture.expected.outcomeAssertions[0].value') AS expected_value
  FROM model.fixture fx
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = fx.semantic_object_definition_pk
  JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
  WHERE fx.owner_definition_pk = @capSod;

  SELECT N'unresolved_references' AS result_set, x.reference_kind, x.reference_id, x.state
  FROM (
    SELECT N'contract' AS reference_kind, ct.contract_id AS reference_id, cv.schema_reference_state AS state
    FROM model.contract_version cv JOIN model.contract ct ON ct.contract_pk = cv.contract_pk
    WHERE cv.contract_version_pk IN (
      SELECT si.input_contract_version_pk FROM model.scenario_input si
      JOIN model.capability_scenario cs ON cs.scenario_version_pk = si.scenario_version_pk
      WHERE cs.capability_version_pk = @capVer
      UNION
      SELECT soc.contract_version_pk FROM model.scenario_outcome_contract soc
      JOIN model.capability_scenario cs ON cs.scenario_version_pk = soc.scenario_version_pk
      WHERE cs.capability_version_pk = @capVer)
    UNION ALL
    SELECT N'scenario_input', si.input_id, si.contract_reference_state
    FROM model.scenario_input si JOIN model.capability_scenario cs ON cs.scenario_version_pk = si.scenario_version_pk
    WHERE cs.capability_version_pk = @capVer
    UNION ALL
    SELECT N'scenario_event', se.event_id, se.authority_reference_state
    FROM model.scenario_event se JOIN model.capability_scenario cs ON cs.scenario_version_pk = se.scenario_version_pk
    WHERE cs.capability_version_pk = @capVer
  ) x
  WHERE x.state <> N'RESOLVED';
END;
GO

-- =====================================================================
-- model.configure_interface
-- Declare the capability's CLI input mapping and display projection on the
-- capability definition (semantics.cli). Only the parameters supplied are
-- changed; the rest of the declaration is preserved. Returns before/after.
-- =====================================================================
CREATE OR ALTER PROCEDURE model.configure_interface
  @capability_id   nvarchar(120),
  @input_type      nvarchar(40)  = NULL,
  @input_contract  nvarchar(160) = NULL,
  @input_path      nvarchar(400) = NULL,
  @display_select  nvarchar(400) = NULL,
  @display_as      nvarchar(40)  = NULL,
  @defaults_json   nvarchar(max) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
  IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;
  IF @defaults_json IS NOT NULL AND ISJSON(@defaults_json) <> 1 THROW 51001, 'DEFAULTS_JSON_INVALID', 1;

  DECLARE @capPk bigint, @capSo bigint, @capSod bigint;
  SELECT @capPk = c.capability_pk, @capSo = c.semantic_object_pk, @capSod = ec.semantic_object_definition_pk
  FROM model.estate_capability ec
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
  JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
  WHERE ec.estate_model_pk = @model AND c.capability_id = @capability_id AND n.namespace_id = N'sidefx:capabilities';
  IF @capPk IS NULL THROW 51001, 'CAPABILITY_NOT_FOUND', 1;

  DECLARE @curEnv nvarchar(max);
  SELECT @curEnv = CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
  WHERE d.semantic_object_definition_pk = @capSod;
  DECLARE @before nvarchar(max) = JSON_QUERY(@curEnv, '$.semantics.cli');

  DECLARE @cli nvarchar(max) = ISNULL(JSON_QUERY(@curEnv, '$.semantics.cli'), N'{}');
  IF @input_type     IS NOT NULL SET @cli = JSON_MODIFY(@cli, '$.input.type', @input_type);
  IF @input_contract IS NOT NULL SET @cli = JSON_MODIFY(@cli, '$.input.contract', @input_contract);
  IF @input_path     IS NOT NULL SET @cli = JSON_MODIFY(@cli, '$.input.path', @input_path);
  IF @display_select IS NOT NULL SET @cli = JSON_MODIFY(@cli, '$.display.select', @display_select);
  IF @display_as     IS NOT NULL SET @cli = JSON_MODIFY(@cli, '$.display.as', @display_as);
  IF @defaults_json  IS NOT NULL SET @cli = JSON_MODIFY(@cli, '$.defaults', JSON_QUERY(@defaults_json));
  DECLARE @newEnv nvarchar(max) = JSON_MODIFY(@curEnv, '$.semantics.cli', JSON_QUERY(@cli));

  DECLARE @newBytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
  DECLARE @newDigest binary(32) = HASHBYTES('SHA2_256', @newBytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@newDigest)
    INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@newDigest, @newBytes, DATALENGTH(@newBytes));
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
    VALUES (@capSo, 'CAPABILITY', @newDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@newDigest));
  DECLARE @newSod bigint = SCOPE_IDENTITY();
  INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @newSod);

  DECLARE @scnPk bigint = (SELECT MAX(scenario_pk) FROM model.scenario WHERE capability_pk=@capPk);
  DECLARE @scnVer bigint = (SELECT MAX(cs.scenario_version_pk) FROM model.capability_scenario cs WHERE cs.capability_pk=@capPk);
  INSERT model.capability_version (capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@capPk, @capSo, @newSod, @newDigest, @capability_id, 'CAPABILITY', @newSod, N'');
  DECLARE @newVer bigint = SCOPE_IDENTITY();
  INSERT model.capability_scenario (capability_pk, capability_version_pk, scenario_pk, scenario_version_pk, _owner_definition_pk, _canonical_pointer)
    VALUES (@capPk, @newVer, @scnPk, @scnVer, @newSod, N'');
  INSERT model.capability_root_scenario (capability_version_pk, scenario_pk, _owner_definition_pk, _canonical_pointer) VALUES (@newVer, @scnPk, @newSod, N'');
  UPDATE model.estate_capability SET capability_version_pk=@newVer, semantic_object_definition_pk=@newSod WHERE estate_model_pk=@model AND capability_pk=@capPk;

  SELECT N'CONFIGURE_INTERFACE' AS action, @capability_id AS capability_id, @newVer AS capability_version_pk, @newSod AS definition_after,
         @before AS cli_before, JSON_QUERY(@newEnv, '$.semantics.cli') AS cli_after;
END;
GO

-- =====================================================================
-- model.add_example
-- Store an input and expected outcome as a FIXTURE owned by the capability so
-- the same capability can be exercised repeatedly. Re-adding a fixture id
-- replaces its expectation. Returns the fixture and its expected value.
-- =====================================================================
CREATE OR ALTER PROCEDURE model.add_example
  @capability_id   nvarchar(120),
  @fixture_id      nvarchar(400),
  @input_json      nvarchar(max),
  @expected_json   nvarchar(max),
  @fixture_profile nvarchar(100) = N'consumer-capability-fixtures.v1'
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  IF @input_json IS NULL OR ISJSON(@input_json)<>1 THROW 51001, 'FIXTURE_INPUT_JSON_REQUIRED', 1;
  IF @expected_json IS NULL OR ISJSON(@expected_json)<>1 THROW 51001, 'FIXTURE_EXPECTED_JSON_REQUIRED', 1;

  DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
  IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;
  DECLARE @capPk bigint, @capSod bigint;
  SELECT @capPk = c.capability_pk, @capSod = ec.semantic_object_definition_pk
  FROM model.estate_capability ec
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
  JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
  WHERE ec.estate_model_pk = @model AND c.capability_id = @capability_id AND n.namespace_id = N'sidefx:capabilities';
  IF @capPk IS NULL THROW 51001, 'CAPABILITY_NOT_FOUND', 1;
  DECLARE @capDigestHex varchar(64) = LOWER(CONVERT(varchar(64), (SELECT definition_digest FROM model.semantic_object_definition WHERE semantic_object_definition_pk=@capSod), 2));
  DECLARE @namespace nvarchar(400) = N'sidefx:capability:' + @capability_id;

  DECLARE @fixture nvarchar(max) = N'{"fixtureId":"' + STRING_ESCAPE(@fixture_id,'json') + N'","input":' + @input_json + N',"expected":' + @expected_json + N'}';
  DECLARE @env nvarchar(max) = N'{"address":{"id":"' + STRING_ESCAPE(@fixture_id,'json') + N'","kind":"FIXTURE","namespace":"' + STRING_ESCAPE(@namespace,'json') + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"owner_definition_digest":"' + @capDigestHex + N'","fixture":' + @fixture + N'}}';
  DECLARE @bytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8));
  DECLARE @digest binary(32) = HASHBYTES('SHA2_256', @bytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest)
    INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));

  IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='FIXTURE' AND namespace_id=@namespace)
    INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('FIXTURE', @namespace);
  DECLARE @fixNs bigint = (SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='FIXTURE' AND namespace_id=@namespace);
  DECLARE @fixSo bigint = (SELECT semantic_object_pk FROM model.semantic_object WHERE object_kind='FIXTURE' AND namespace_pk=@fixNs AND declared_id=@fixture_id);
  IF @fixSo IS NULL BEGIN INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES ('FIXTURE', @fixNs, @fixture_id); SET @fixSo=SCOPE_IDENTITY(); END
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
    VALUES (@fixSo, 'FIXTURE', @digest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest));
  DECLARE @newSod bigint = SCOPE_IDENTITY();
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@newSod)
    INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @newSod);

  IF EXISTS (SELECT 1 FROM model.fixture WHERE owner_definition_pk=@capSod AND fixture_id=@fixture_id)
    UPDATE model.fixture SET semantic_object_definition_pk=@newSod, definition_digest=@digest, fixture_profile=@fixture_profile
    WHERE owner_definition_pk=@capSod AND fixture_id=@fixture_id;
  ELSE
    INSERT model.fixture (owner_definition_pk, fixture_id, fixture_profile, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer)
      VALUES (@capSod, @fixture_id, @fixture_profile, @fixSo, @newSod, @fixNs, @digest, 'FIXTURE', @newSod, N'');

  SELECT N'ADD_EXAMPLE' AS action, @capability_id AS capability_id, @fixture_id AS fixture_id, @newSod AS definition_after,
         JSON_VALUE(@fixture, '$.expected.outcomeAssertions[0].value') AS expected_value;
END;
GO

-- =====================================================================
-- model.add_provider
-- Declare a provider's identity, supported capabilities, operations and
-- connection configuration, and create the implementation relationships the
-- resolution views read (provider_capability_implementation). Supported
-- capabilities must already exist as platform capabilities; anything not found
-- is returned unresolved.
-- =====================================================================
CREATE OR ALTER PROCEDURE model.add_provider
  @provider_id       nvarchar(400),
  @name              nvarchar(400) = NULL,
  @capabilities_json nvarchar(max) = NULL,
  @operations_json   nvarchar(max) = NULL,
  @configuration_json nvarchar(max) = NULL,
  @on_exists         nvarchar(20) = N'REPLACE'
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  IF @capabilities_json IS NOT NULL AND ISJSON(@capabilities_json)<>1 THROW 51001, 'CAPABILITIES_JSON_INVALID', 1;
  IF @operations_json   IS NOT NULL AND ISJSON(@operations_json)<>1 THROW 51001, 'OPERATIONS_JSON_INVALID', 1;
  IF @configuration_json IS NOT NULL AND ISJSON(@configuration_json)<>1 THROW 51001, 'CONFIGURATION_JSON_INVALID', 1;

  DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
  IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;
  DECLARE @name2 nvarchar(400) = ISNULL(@name, @provider_id);

  DECLARE @provNs bigint = (SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='PROVIDER' AND namespace_id=N'sidefx:providers');
  IF @provNs IS NULL BEGIN INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('PROVIDER', N'sidefx:providers'); SET @provNs=SCOPE_IDENTITY(); END

  IF EXISTS (SELECT 1 FROM model.provider WHERE namespace_pk=@provNs AND provider_id=@provider_id) AND @on_exists='ERROR'
    THROW 51001, 'PROVIDER_ALREADY_EXISTS', 1;

  DECLARE @env nvarchar(max) = N'{"address":{"id":"' + STRING_ESCAPE(@provider_id,'json') + N'","kind":"PROVIDER","namespace":"sidefx:providers"},"format":"sidefx-semantic-definition.v1","semantics":{"providerId":"'
    + STRING_ESCAPE(@provider_id,'json') + N'","name":"' + STRING_ESCAPE(@name2,'json')
    + N'","candidateCapabilities":' + ISNULL(@capabilities_json, N'[]')
    + N',"operations":' + ISNULL(@operations_json, N'[]')
    + N',"configuration":' + ISNULL(@configuration_json, N'{}')
    + N',"conformanceClaims":{"admission":"NOT_CLAIMED"},"source":{}}}';
  DECLARE @bytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8));
  DECLARE @digest binary(32) = HASHBYTES('SHA2_256', @bytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest)
    INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));

  DECLARE @provSo bigint = (SELECT semantic_object_pk FROM model.semantic_object WHERE object_kind='PROVIDER' AND namespace_pk=@provNs AND declared_id=@provider_id);
  IF @provSo IS NULL BEGIN INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES ('PROVIDER', @provNs, @provider_id); SET @provSo=SCOPE_IDENTITY(); END
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
    VALUES (@provSo, 'PROVIDER', @digest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest));
  DECLARE @newSod bigint = SCOPE_IDENTITY();
  INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @newSod);

  DECLARE @provPk bigint = (SELECT provider_pk FROM model.provider WHERE namespace_pk=@provNs AND provider_id=@provider_id);
  IF @provPk IS NULL BEGIN INSERT model.provider (namespace_pk, provider_id, semantic_object_pk, object_kind) VALUES (@provNs, @provider_id, @provSo, 'PROVIDER'); SET @provPk=SCOPE_IDENTITY(); END
  INSERT model.provider_definition (provider_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, declaration_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@provPk, @provSo, @newSod, @digest, @name2, 'sfx-provider-catalog.v1', 'PROVIDER', @newSod, N'');
  DECLARE @provDefPk bigint = SCOPE_IDENTITY();

  -- Implementation relationships: link to each supported platform capability version.
  IF OBJECT_ID('tempdb..#linked') IS NOT NULL DROP TABLE #linked;
  CREATE TABLE #linked (capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2, capability_version_pk bigint NULL);
  IF @capabilities_json IS NOT NULL
    INSERT #linked (capability_id, capability_version_pk)
    SELECT j.value,
           (SELECT TOP 1 cv.capability_version_pk FROM model.capability c
              JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
              JOIN model.capability_version cv ON cv.capability_pk=c.capability_pk
              WHERE n.namespace_id=N'sidefx:platform-capabilities' AND c.capability_id=j.value
              ORDER BY cv.capability_version_pk DESC)
    FROM OPENJSON(@capabilities_json) j;

  INSERT model.provider_capability_implementation (provider_definition_pk, capability_version_pk, role, _owner_definition_pk, _canonical_pointer)
    SELECT @provDefPk, l.capability_version_pk, N'PLATFORM', @provDefPk, N''
    FROM #linked l
    WHERE l.capability_version_pk IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM model.provider_capability_implementation x WHERE x.provider_definition_pk=@provDefPk AND x.capability_version_pk=l.capability_version_pk);

  SELECT N'ADD_PROVIDER' AS action, @provider_id AS provider_id, @provDefPk AS provider_definition_pk, @newSod AS definition_after,
         (SELECT COUNT(*) FROM #linked WHERE capability_version_pk IS NOT NULL) AS capabilities_linked;
  SELECT N'unresolved_capabilities' AS result_set, l.capability_id
  FROM #linked l WHERE l.capability_version_pk IS NULL;
END;
GO

-- =====================================================================
-- model.configure_provider
-- Change a provider's declared configuration (name, operations, connection
-- configuration references) without recreating its consumers. Returns
-- before/after.
-- =====================================================================
CREATE OR ALTER PROCEDURE model.configure_provider
  @provider_id        nvarchar(400),
  @name               nvarchar(400) = NULL,
  @operations_json    nvarchar(max) = NULL,
  @configuration_json nvarchar(max) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  IF @operations_json    IS NOT NULL AND ISJSON(@operations_json)<>1 THROW 51001, 'OPERATIONS_JSON_INVALID', 1;
  IF @configuration_json IS NOT NULL AND ISJSON(@configuration_json)<>1 THROW 51001, 'CONFIGURATION_JSON_INVALID', 1;

  DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
  IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;

  DECLARE @provPk bigint, @provSo bigint, @curSod bigint, @curEnv nvarchar(max);
  SELECT @provPk = p.provider_pk, @provSo = p.semantic_object_pk
  FROM model.provider p JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
  WHERE n.namespace_id=N'sidefx:providers' AND p.provider_id=@provider_id;
  IF @provPk IS NULL THROW 51001, 'PROVIDER_NOT_FOUND', 1;
  SELECT TOP 1 @curSod = d.semantic_object_definition_pk,
         @curEnv = CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE d.semantic_object_pk=@provSo ORDER BY d.semantic_object_definition_pk DESC;
  DECLARE @before nvarchar(max) = @curEnv;

  DECLARE @newEnv nvarchar(max) = @curEnv;
  IF @name               IS NOT NULL SET @newEnv = JSON_MODIFY(@newEnv, '$.semantics.name', @name);
  IF @operations_json    IS NOT NULL SET @newEnv = JSON_MODIFY(@newEnv, '$.semantics.operations', JSON_QUERY(@operations_json));
  IF @configuration_json IS NOT NULL SET @newEnv = JSON_MODIFY(@newEnv, '$.semantics.configuration', JSON_QUERY(@configuration_json));

  DECLARE @bytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
  DECLARE @digest binary(32) = HASHBYTES('SHA2_256', @bytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest)
    INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
    VALUES (@provSo, 'PROVIDER', @digest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest));
  DECLARE @newSod bigint = SCOPE_IDENTITY();
  INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @newSod);
  DECLARE @priorDefPk bigint = (SELECT MAX(provider_definition_pk) FROM model.provider_definition WHERE provider_pk=@provPk);
  INSERT model.provider_definition (provider_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, declaration_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    SELECT @provPk, @provSo, @newSod, @digest, JSON_VALUE(@newEnv,'$.semantics.name'), ISNULL(MAX(declaration_profile),'sfx-provider-catalog.v1'), 'PROVIDER', @newSod, N''
    FROM model.provider_definition WHERE provider_pk=@provPk;
  DECLARE @newDefPk bigint = SCOPE_IDENTITY();
  INSERT model.provider_capability_implementation (provider_definition_pk, capability_version_pk, role, _owner_definition_pk, _canonical_pointer)
    SELECT @newDefPk, x.capability_version_pk, x.role, @newSod, N''
    FROM model.provider_capability_implementation x
    WHERE x.provider_definition_pk=@priorDefPk
      AND NOT EXISTS (SELECT 1 FROM model.provider_capability_implementation y WHERE y.provider_definition_pk=@newDefPk AND y.capability_version_pk=x.capability_version_pk);

  SELECT N'CONFIGURE_PROVIDER' AS action, @provider_id AS provider_id, @curSod AS definition_before, @newSod AS definition_after,
         JSON_QUERY(@before,'$.semantics.configuration') AS configuration_before, JSON_QUERY(@newEnv,'$.semantics.configuration') AS configuration_after;
END;
GO

-- =====================================================================
-- model.bind_provider
-- Select a provider for a capability mechanic (port). Ensures the provider is
-- linked to the platform capability it will supply (provider_capability_
-- implementation) and points the port declaration at that platform capability,
-- carrying any input/output configuration mappings. Assumption: provider
-- selection is the platform capability named by the port plus the
-- provider_capability_implementation link; there is no per-capability provider
-- binding table.
-- =====================================================================
CREATE OR ALTER PROCEDURE model.bind_provider
  @capability_id          nvarchar(120),
  @mechanic_id            nvarchar(400),
  @provider_id            nvarchar(400),
  @platform_capability_id nvarchar(400) = NULL,
  @configuration_json     nvarchar(max) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  IF @configuration_json IS NOT NULL AND ISJSON(@configuration_json)<>1 THROW 51001, 'CONFIGURATION_JSON_INVALID', 1;

  DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
  IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;

  DECLARE @portPk bigint, @portSo bigint, @portSod bigint;
  SELECT @portPk = p.port_pk, @portSo = p.semantic_object_pk, @portSod = d.semantic_object_definition_pk
  FROM model.port p
  JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
  JOIN model.semantic_object_definition d ON d.semantic_object_pk=p.semantic_object_pk
  WHERE n.namespace_id=N'sidefx:capability:' + @capability_id AND p.port_id=@mechanic_id
    AND d.semantic_object_definition_pk=(SELECT MAX(d2.semantic_object_definition_pk) FROM model.semantic_object_definition d2 WHERE d2.semantic_object_pk=p.semantic_object_pk);
  IF @portPk IS NULL THROW 51001, 'MECHANIC_NOT_FOUND', 1;

  DECLARE @provDefPk bigint, @provEnv nvarchar(max);
  SELECT TOP 1 @provDefPk=pd.provider_definition_pk,
         @provEnv=CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM model.provider p JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
  JOIN model.provider_definition pd ON pd.provider_pk=p.provider_pk
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=pd.semantic_object_definition_pk
  JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE n.namespace_id=N'sidefx:providers' AND p.provider_id=@provider_id
  ORDER BY pd.provider_definition_pk DESC;
  IF @provDefPk IS NULL THROW 51001, 'PROVIDER_NOT_FOUND', 1;

  DECLARE @pcid nvarchar(400) = @platform_capability_id;
  IF @pcid IS NULL SELECT TOP 1 @pcid = j.value FROM OPENJSON(@provEnv, '$.semantics.candidateCapabilities') j;
  IF @pcid IS NULL THROW 51001, 'PLATFORM_CAPABILITY_REQUIRED', 1;

  DECLARE @cvpk bigint = (SELECT TOP 1 cv.capability_version_pk
    FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
    JOIN model.capability_version cv ON cv.capability_pk=c.capability_pk
    WHERE n.namespace_id=N'sidefx:platform-capabilities' AND c.capability_id=@pcid
    ORDER BY cv.capability_version_pk DESC);
  IF @cvpk IS NULL THROW 51001, 'PLATFORM_CAPABILITY_NOT_FOUND', 1;

  IF NOT EXISTS (SELECT 1 FROM model.provider_capability_implementation WHERE provider_definition_pk=@provDefPk AND capability_version_pk=@cvpk)
    INSERT model.provider_capability_implementation (provider_definition_pk, capability_version_pk, role, _owner_definition_pk, _canonical_pointer)
      VALUES (@provDefPk, @cvpk, N'PLATFORM', @provDefPk, N'');

  DECLARE @curEnv nvarchar(max);
  SELECT @curEnv = CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE d.semantic_object_definition_pk=@portSod;

  DECLARE @newEnv nvarchar(max) = JSON_MODIFY(@curEnv, '$.semantics.platformCapabilityId', @pcid);
  IF @configuration_json IS NOT NULL SET @newEnv = JSON_MODIFY(@newEnv, '$.semantics.configuration', JSON_QUERY(@configuration_json));
  DECLARE @bytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
  DECLARE @digest binary(32) = HASHBYTES('SHA2_256', @bytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest)
    INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@digest, @bytes, DATALENGTH(@bytes));
  DECLARE @newSod bigint = (SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@portSo AND definition_digest=@digest);
  IF @newSod IS NULL
  BEGIN
    INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
      VALUES (@portSo, 'PORT', @digest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest));
    SET @newSod = SCOPE_IDENTITY();
    IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@newSod)
      INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @newSod);
    INSERT model.port_version (port_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, port_profile, object_kind, _owner_definition_pk, _canonical_pointer)
      VALUES (@portPk, @portSo, @newSod, @digest, NULL, 'consumer-interface-authority.v1', 'PORT', @newSod, N'');
  END
  DECLARE @newPortVer bigint = (SELECT TOP 1 port_version_pk FROM model.port_version WHERE port_pk=@portPk AND semantic_object_definition_pk=@newSod ORDER BY port_version_pk DESC);
  UPDATE ipi SET port_version_pk=@newPortVer FROM model.operation_port_invocation ipi
  WHERE ipi.port_version_pk IN (SELECT port_version_pk FROM model.port_version WHERE port_pk=@portPk);

  SELECT N'BIND_PROVIDER' AS action, @capability_id AS capability_id, @mechanic_id AS mechanic_id, @provider_id AS provider_id,
         @pcid AS platform_capability_id, @newSod AS definition_after, @newPortVer AS port_version_pk;
END;
GO

-- =====================================================================
-- model.normalize_transformation_expression
-- Rebuild the normalized expression tree (root / node / child) for one
-- transformation_version from its definition envelope's $.semantics.expression.
-- The tree is the layer scenario_transformation_mechanics and reveal read; it
-- is derived, so it is rebuilt rather than authored.
-- =====================================================================
CREATE OR ALTER PROCEDURE model.normalize_transformation_expression
  @transformation_version_pk bigint
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @sod bigint = (SELECT semantic_object_definition_pk FROM model.transformation_version WHERE transformation_version_pk=@transformation_version_pk);
  IF @sod IS NULL THROW 51001, 'TRANSFORMATION_VERSION_NOT_FOUND', 1;
  DECLARE @env nvarchar(max) = (SELECT CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
     FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk WHERE d.semantic_object_definition_pk=@sod);
  DECLARE @expr nvarchar(max) = JSON_QUERY(@env, '$.semantics.expression');
  IF @expr IS NULL RETURN;

  DELETE FROM model.transformation_root WHERE transformation_version_pk=@transformation_version_pk;
  DELETE FROM model.transformation_expression_child WHERE transformation_version_pk=@transformation_version_pk;
  DELETE FROM model.transformation_expression_node WHERE transformation_version_pk=@transformation_version_pk;

  IF OBJECT_ID('tempdb..#work') IS NOT NULL DROP TABLE #work;
  CREATE TABLE #work (id int IDENTITY PRIMARY KEY, frag nvarchar(max), pointer nvarchar(4000), parentPk bigint NULL,
                      memberKind nvarchar(40) NULL, memberName nvarchar(400) NULL, ordinal int NULL, done bit DEFAULT 0);
  INSERT #work (frag, pointer) VALUES (@expr, N'/semantics/expression');

  DECLARE @id int, @frag nvarchar(max), @pointer nvarchar(4000), @parentPk bigint, @memberKind nvarchar(40), @memberName nvarchar(400), @ordinal int;
  DECLARE @nodePk bigint, @ch nchar(1), @trim nvarchar(max);
  WHILE EXISTS (SELECT 1 FROM #work WHERE done=0)
  BEGIN
    SELECT TOP 1 @id=id, @frag=frag, @pointer=pointer, @parentPk=parentPk, @memberKind=memberKind, @memberName=memberName, @ordinal=ordinal
    FROM #work WHERE done=0 ORDER BY id;
    SET @trim = LTRIM(RTRIM(@frag));
    SET @ch = LEFT(@trim, 1);
    IF @ch = '{' OR @ch = '['
    BEGIN
      INSERT model.transformation_expression_node (transformation_version_pk, node_pointer, node_kind, _owner_definition_pk, _canonical_pointer)
        VALUES (@transformation_version_pk, @pointer, CASE WHEN @ch='{' THEN 'OBJECT' ELSE 'ARRAY' END, @sod, @pointer);
      SET @nodePk = SCOPE_IDENTITY();
      IF @parentPk IS NULL
        INSERT model.transformation_root (transformation_version_pk, expression_node_pk, _owner_definition_pk, _canonical_pointer) VALUES (@transformation_version_pk, @nodePk, @sod, @pointer);
      ELSE
        INSERT model.transformation_expression_child (transformation_version_pk, parent_node_pk, child_node_pk, member_kind, member_name, ordinal, _owner_definition_pk, _canonical_pointer)
          VALUES (@transformation_version_pk, @parentPk, @nodePk, ISNULL(@memberKind,'OBJECT_MEMBER'), @memberName, @ordinal, @sod, @pointer);
      INSERT #work (frag, pointer, parentPk, memberKind, memberName, ordinal)
      SELECT CASE j.[type] WHEN 1 THEN N'"' + STRING_ESCAPE(j.value,'json') + N'"' WHEN 0 THEN N'null' ELSE j.value END,
             @pointer + N'/' + j.[key], @nodePk,
             CASE WHEN @ch='{' THEN 'OBJECT_MEMBER' ELSE 'ARRAY_ELEMENT' END, j.[key],
             CASE WHEN @ch='[' THEN TRY_CONVERT(int, j.[key]) ELSE NULL END
      FROM OPENJSON(@trim) j;
    END
    ELSE
    BEGIN
      DECLARE @litBytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@trim) COLLATE Latin1_General_100_BIN2_UTF8));
      DECLARE @litDigest binary(32) = HASHBYTES('SHA2_256', @litBytes);
      IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@litDigest)
        INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@litDigest, @litBytes, DATALENGTH(@litBytes));
      INSERT model.transformation_expression_node (transformation_version_pk, node_pointer, node_kind, literal_content_pk, _owner_definition_pk, _canonical_pointer)
        VALUES (@transformation_version_pk, @pointer, 'LITERAL', (SELECT content_object_pk FROM source.content_object WHERE content_digest=@litDigest), @sod, @pointer);
      SET @nodePk = SCOPE_IDENTITY();
      IF @parentPk IS NULL
        INSERT model.transformation_root (transformation_version_pk, expression_node_pk, _owner_definition_pk, _canonical_pointer) VALUES (@transformation_version_pk, @nodePk, @sod, @pointer);
      ELSE
        INSERT model.transformation_expression_child (transformation_version_pk, parent_node_pk, child_node_pk, member_kind, member_name, ordinal, _owner_definition_pk, _canonical_pointer)
          VALUES (@transformation_version_pk, @parentPk, @nodePk, ISNULL(@memberKind,'OBJECT_MEMBER'), @memberName, @ordinal, @sod, @pointer);
    END
    UPDATE #work SET done=1 WHERE id=@id;
  END
END;
GO

-- =====================================================================
-- model.add_mechanic
-- Attach a mechanic to a capability's transformation as a new expression
-- field (the mechanic's op plus the supplied arguments), at an execution
-- position. @mode = REUSE attaches an existing model.mechanic; AUTHOR declares
-- a new reusable mechanic (namespace sidefx:mechanics) from @arguments_json
-- (a mechanic object containing authoringForm). Rebuilds the expression tree.
-- =====================================================================
CREATE OR ALTER PROCEDURE model.add_mechanic
  @capability_id nvarchar(120),
  @mechanic_id   nvarchar(400),
  @mode          nvarchar(20) = N'REUSE',
  @arguments_json nvarchar(max) = NULL,
  @output_field  nvarchar(400),
  @position      int = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  IF @arguments_json IS NOT NULL AND ISJSON(@arguments_json)<>1 THROW 51001, 'ARGUMENTS_JSON_INVALID', 1;
  IF @output_field IS NULL OR @output_field = N'' THROW 51001, 'OUTPUT_FIELD_REQUIRED', 1;
  IF @mode NOT IN (N'REUSE', N'AUTHOR') THROW 51001, 'MODE_INVALID', 1;

  DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
  IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;

  DECLARE @mechSo bigint, @mechEnv nvarchar(max), @op nvarchar(400);
  IF @mode = N'REUSE'
  BEGIN
    SELECT TOP 1 @mechSo = m.semantic_object_pk, @mechEnv = CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
    FROM model.mechanic m
    JOIN model.identity_namespace n ON n.namespace_pk = m.namespace_pk
    JOIN model.mechanic_version mv ON mv.mechanic_pk = m.mechanic_pk
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = mv.semantic_object_definition_pk
    JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
    WHERE n.namespace_id = N'sidefx:mechanics' AND m.mechanic_id = @mechanic_id
    ORDER BY d.semantic_object_definition_pk DESC;
    IF @mechSo IS NULL THROW 51001, 'MECHANIC_NOT_FOUND', 1;
    SET @op = JSON_VALUE(@mechEnv, '$.semantics.mechanic.authoringForm.operation');
  END
  ELSE
  BEGIN
    -- Declare a new reusable mechanic from the supplied mechanic object.
    DECLARE @mechNs bigint = (SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='MECHANIC' AND namespace_id=N'sidefx:mechanics');
    IF @mechNs IS NULL BEGIN INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('MECHANIC', N'sidefx:mechanics'); SET @mechNs=SCOPE_IDENTITY(); END
    SET @mechEnv = N'{"address":{"id":"' + STRING_ESCAPE(@mechanic_id,'json') + N'","kind":"MECHANIC","namespace":"sidefx:mechanics"},"format":"sidefx-semantic-definition.v1","semantics":{"authorityId":"semantic-value-mechanics.v1","mechanic":' + ISNULL(@arguments_json, N'{}') + N'}}';
    DECLARE @mb varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@mechEnv) COLLATE Latin1_General_100_BIN2_UTF8));
    DECLARE @md binary(32) = HASHBYTES('SHA2_256', @mb);
    IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@md) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@md, @mb, DATALENGTH(@mb));
    SET @mechSo = (SELECT semantic_object_pk FROM model.semantic_object WHERE object_kind='MECHANIC' AND namespace_pk=@mechNs AND declared_id=@mechanic_id);
    IF @mechSo IS NULL BEGIN INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES ('MECHANIC', @mechNs, @mechanic_id); SET @mechSo=SCOPE_IDENTITY(); END
    INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
      VALUES (@mechSo, 'MECHANIC', @md, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@md));
    DECLARE @msod bigint = SCOPE_IDENTITY();
    IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@msod)
      INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @msod);
    DECLARE @mechPk bigint = (SELECT mechanic_pk FROM model.mechanic WHERE namespace_pk=@mechNs AND mechanic_id=@mechanic_id);
    IF @mechPk IS NULL BEGIN INSERT model.mechanic (namespace_pk, mechanic_id, semantic_object_pk, object_kind) VALUES (@mechNs, @mechanic_id, @mechSo, 'MECHANIC'); SET @mechPk=SCOPE_IDENTITY(); END
    INSERT model.mechanic_version (mechanic_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, definition_profile, object_kind, _owner_definition_pk, _canonical_pointer)
      VALUES (@mechPk, @mechSo, @msod, @md, @mechanic_id, 'sfx-mechanic.v1', 'MECHANIC', @msod, N'');
    SET @op = JSON_VALUE(@arguments_json, '$.authoringForm.operation');
  END
  IF @op IS NULL THROW 51001, 'MECHANIC_OPERATION_UNRESOLVED', 1;

  -- Resolve the capability's transformation and latest definition.
  DECLARE @transPk bigint, @transSo bigint, @curSod bigint, @env nvarchar(max);
  SELECT TOP 1 @transPk = t.transformation_pk, @transSo = t.semantic_object_pk
  FROM model.transformation t JOIN model.identity_namespace n ON n.namespace_pk=t.namespace_pk
  WHERE n.namespace_id = N'sidefx:capability:' + @capability_id ORDER BY t.transformation_pk;
  IF @transPk IS NULL THROW 51001, 'MECHANIC_NOT_FOUND', 1;
  SELECT TOP 1 @curSod = d.semantic_object_definition_pk, @env = CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE d.semantic_object_pk=@transSo ORDER BY d.semantic_object_definition_pk DESC;

  DECLARE @expr nvarchar(max) = JSON_QUERY(@env, '$.semantics.expression');
  DECLARE @mechValue nvarchar(max) = JSON_MODIFY(ISNULL(@arguments_json, N'{}'), '$.op', @op);
  DECLARE @newExpr nvarchar(max) = JSON_MODIFY(@expr, '$.fields.' + @output_field, JSON_QUERY(@mechValue));
  IF @newExpr IS NULL THROW 51001, 'EXPRESSION_COMPOSE_FAILED', 1;
  DECLARE @newEnv nvarchar(max) = JSON_MODIFY(@env, '$.semantics.expression', JSON_QUERY(@newExpr));

  DECLARE @nb varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
  DECLARE @nd binary(32) = HASHBYTES('SHA2_256', @nb);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@nd) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@nd, @nb, DATALENGTH(@nb));
  DECLARE @newSod bigint = (SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@transSo AND definition_digest=@nd);
  DECLARE @newTransVer bigint;
  IF @newSod IS NULL
  BEGIN
    INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
      VALUES (@transSo, 'TRANSFORMATION', @nd, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@nd));
    SET @newSod = SCOPE_IDENTITY();
    IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@newSod)
      INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @newSod);
    INSERT model.transformation_version (transformation_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, expression_profile, object_kind, _owner_definition_pk, _canonical_pointer)
      VALUES (@transPk, @transSo, @newSod, @nd, 'json-expression-tree.v1', 'TRANSFORMATION', @newSod, N'');
    SET @newTransVer = SCOPE_IDENTITY();
  END
  ELSE
    SET @newTransVer = (SELECT TOP 1 transformation_version_pk FROM model.transformation_version WHERE transformation_pk=@transPk AND semantic_object_definition_pk=@newSod ORDER BY transformation_version_pk DESC);
  EXEC model.normalize_transformation_expression @transformation_version_pk=@newTransVer;

  SELECT N'ADD_MECHANIC' AS action, @capability_id AS capability_id, @mechanic_id AS mechanic_id, @mode AS mode,
         @output_field AS output_field, @position AS execution_position, @op AS operation, @newSod AS definition_after, @newTransVer AS transformation_version_pk;
END;
GO

-- =====================================================================
-- model.remove_mechanic
-- Remove a mechanic attachment (the expression field named @output_field) from
-- a capability's transformation, rebuild the tree, and expose affected
-- dependents (sibling fields whose mapping still references the removed field).
-- =====================================================================
CREATE OR ALTER PROCEDURE model.remove_mechanic
  @capability_id nvarchar(120),
  @output_field  nvarchar(400)
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
  IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;

  DECLARE @transPk bigint, @transSo bigint, @env nvarchar(max);
  SELECT TOP 1 @transPk = t.transformation_pk, @transSo = t.semantic_object_pk
  FROM model.transformation t JOIN model.identity_namespace n ON n.namespace_pk=t.namespace_pk
  WHERE n.namespace_id = N'sidefx:capability:' + @capability_id ORDER BY t.transformation_pk;
  IF @transPk IS NULL THROW 51001, 'MECHANIC_NOT_FOUND', 1;
  SELECT TOP 1 @env = CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE d.semantic_object_pk=@transSo ORDER BY d.semantic_object_definition_pk DESC;

  DECLARE @expr nvarchar(max) = JSON_QUERY(@env, '$.semantics.expression');
  IF JSON_QUERY(@expr, '$.fields.' + @output_field) IS NULL THROW 51001, 'MECHANIC_ATTACHMENT_NOT_FOUND', 1;

  -- Remove the superseding definitions that carry this attachment, so the prior
  -- definition (without it) becomes the selected one. Attachment definitions are
  -- authored here and carry no source lineage.
  DECLARE @fieldPath nvarchar(4000) = N'$.semantics.expression.fields.' + @output_field;
  IF OBJECT_ID('tempdb..#delSod') IS NOT NULL DROP TABLE #delSod;
  CREATE TABLE #delSod (sod bigint PRIMARY KEY, tv bigint);
  INSERT #delSod (sod, tv)
  SELECT d.semantic_object_definition_pk, tv2.transformation_version_pk
  FROM model.transformation_version tv2
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=tv2.semantic_object_definition_pk
  JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE tv2.transformation_pk=@transPk
    AND JSON_QUERY(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), @fieldPath) IS NOT NULL;
  DELETE c FROM model.transformation_expression_child c JOIN #delSod x ON x.tv=c.transformation_version_pk;
  DELETE r FROM model.transformation_root r JOIN #delSod x ON x.tv=r.transformation_version_pk;
  DELETE n FROM model.transformation_expression_node n JOIN #delSod x ON x.tv=n.transformation_version_pk;
  DELETE tv2 FROM model.transformation_version tv2 JOIN #delSod x ON x.tv=tv2.transformation_version_pk;
  DELETE ed FROM model.estate_definition ed JOIN #delSod x ON x.sod=ed.semantic_object_definition_pk;
  DELETE so FROM model.semantic_object_definition so JOIN #delSod x ON x.sod=so.semantic_object_definition_pk
    WHERE NOT EXISTS (SELECT 1 FROM source.source_lineage sl WHERE sl.semantic_object_definition_pk=so.semantic_object_definition_pk);

  DECLARE @fields nvarchar(max);
  SELECT @fields = N'{' + STRING_AGG(N'"' + STRING_ESCAPE(j.[key],'json') + N'":' + j.value, N',') + N'}'
  FROM OPENJSON(@expr, '$.fields') j WHERE j.[key] <> @output_field;
  SET @fields = ISNULL(@fields, N'{}');
  DECLARE @newExpr nvarchar(max) = JSON_MODIFY(@expr, '$.fields', JSON_QUERY(@fields));
  DECLARE @newEnv nvarchar(max) = JSON_MODIFY(@env, '$.semantics.expression', JSON_QUERY(@newExpr));

  DECLARE @nb varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
  DECLARE @nd binary(32) = HASHBYTES('SHA2_256', @nb);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@nd) INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@nd, @nb, DATALENGTH(@nb));
  DECLARE @newSod bigint = (SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@transSo AND definition_digest=@nd);
  DECLARE @newTransVer bigint;
  IF @newSod IS NULL
  BEGIN
    INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
      VALUES (@transSo, 'TRANSFORMATION', @nd, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@nd));
    SET @newSod = SCOPE_IDENTITY();
    IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@newSod)
      INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @newSod);
    INSERT model.transformation_version (transformation_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, expression_profile, object_kind, _owner_definition_pk, _canonical_pointer)
      VALUES (@transPk, @transSo, @newSod, @nd, 'json-expression-tree.v1', 'TRANSFORMATION', @newSod, N'');
    SET @newTransVer = SCOPE_IDENTITY();
  END
  ELSE
    SET @newTransVer = (SELECT TOP 1 transformation_version_pk FROM model.transformation_version WHERE transformation_pk=@transPk AND semantic_object_definition_pk=@newSod ORDER BY transformation_version_pk DESC);
  EXEC model.normalize_transformation_expression @transformation_version_pk=@newTransVer;

  SELECT N'REMOVE_MECHANIC' AS action, @capability_id AS capability_id, @output_field AS output_field, @newSod AS definition_after, @newTransVer AS transformation_version_pk;
  SELECT N'dependents' AS result_set, j.[key] AS dependent_field
  FROM OPENJSON(@expr, '$.fields') j
  WHERE j.[key] <> @output_field AND j.value LIKE N'%' + @output_field + N'%';
END;
GO
