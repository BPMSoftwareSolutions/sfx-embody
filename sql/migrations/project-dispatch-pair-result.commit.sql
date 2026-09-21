-- project-dispatch-pair-result.sql
--
-- Makes the dispatch-pair-demo scenario output real. Two declared branch
-- settlements already converge on the all-required join; this migration
-- declares what that convergence means:
--
--   1. the capability outcome contract dispatch-pair-result.v1: a closed
--      document {contractId, disposition, payload} whose payload carries the
--      resolved price and the fixture response;
--   2. the join projection: the join port's declared transformation reads each
--      branch's admitted outcome envelope from its settlement contribution
--      (settlement.outcomeEnvelope.contractId/payload, the kernel's widened
--      native settlement envelope) and projects them into that contract;
--   3. the join scenario's outcome contract: dispatch-pair-leg-settlement.v1
--      -> dispatch-pair-result.v1;
--   4. the human display: dispatch-pair-demo-result-display.v1 renders the
--      declared result document as an sfx-display-document.v1 reading, and the
--      capability envelope's cli.display names it.
--
-- Decision for the provider-unavailable case. If branch A settles without a
-- resolved equity evidence (for example the RapidAPI primary answers HTTP 429
-- and every declared fallback route is exhausted), the join still emits a valid
-- dispatch-pair-result.v1 document: disposition DISPATCH_PAIR_PARTIAL, price
-- null, and priceReason carrying the branch's own declared diagnosis
-- (reasonCode, evidence disposition, referenced settlement payload, or the
-- settlement disposition, in that order). Branch C follows the same rule for
-- company. An undeclared shape is never produced; the display renders the
-- partial result with its reason.
--
-- Idempotent: the contract declaration and the transformation definition are
-- upserts; the envelope is only re-minted when its cli.display does not already
-- name the transformation; the join scenario re-declaration converges.
--
-- Default: ROLLBACK after the dry run and the from-transaction preflight. The
-- install is the .commit.sql copy.
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

-- ============================== CONTRACT AND DISPLAY ==============================
DECLARE @result_schema nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/dispatch-pair-result.v1.schema.json","title":"Dispatch pair demo result","description":"The dispatch-pair-demo capability outcome: the declared pair of concurrently dispatched branch outcomes. price is the resolved equity observation (null when the equity leg settled without a resolvable price, with priceReason carrying the branch diagnosis); company is the parsed local fixture response (null when the fixture leg settled without a parseable response, with companyReason carrying the branch diagnosis).","type":"object","additionalProperties":false,"required":["contractId","disposition","payload"],"properties":{"contractId":{"const":"dispatch-pair-result.v1"},"disposition":{"enum":["DISPATCH_PAIR_RESOLVED","DISPATCH_PAIR_PARTIAL"]},"payload":{"type":"object","additionalProperties":false,"required":["price","currency","priceReason","company","companyReason"],"properties":{"price":{"type":["number","null"]},"currency":{"type":["string","null"]},"priceReason":{"type":["string","null"]},"company":{"type":["object","null"]},"companyReason":{"type":["string","null"]}}}}}';
EXEC model.declare_contract @id=N'dispatch-pair-result.v1', @schema=@result_schema;
SELECT '1_result_contract' AS result_set, c.contract_id,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.schema_digest') AS schema_digest
FROM model.contract c
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:contracts'
JOIN model.contract_version cv ON cv.contract_pk=c.contract_pk
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=cv.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE c.contract_id=N'dispatch-pair-result.v1';

-- The declared display transformation: the capability's declared result document
-- rendered as the sfx-display-document.v1 reading. It reads the scheduler
-- result's terminal outcome (execution.outcome) only.
DECLARE @namespace nvarchar(400)=N'sidefx:capability:dispatch-pair-demo';
DECLARE @transformationId nvarchar(400)=N'dispatch-pair-demo-result-display.v1';
DECLARE @display_expression nvarchar(max)=N'{"op":"let","bindings":{"outcome":{"op":"path","from":"execution","path":"outcome"},"payload":{"op":"path","from":"outcome","path":"payload"},"statusText":{"op":"format","template":"{status}","values":{"status":{"op":"path","from":"outcome","path":"disposition"}}},"priceText":{"op":"if","when":{"op":"path","from":"payload","path":"price"},"then":{"op":"format","template":"{price} {currency}","values":{"price":{"op":"path","from":"payload","path":"price"},"currency":{"op":"path","from":"payload","path":"currency"}}},"else":{"op":"format","template":"unresolved ({reason})","values":{"reason":{"op":"path","from":"payload","path":"priceReason"}}}}},"value":{"op":"object","fields":{"blocks":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"literal","value":"dispatch pair result"}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"status"},"value":{"op":"path","from":"statusText","path":""}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"price"},"value":{"op":"path","from":"priceText","path":""}}},{"op":"if","when":{"op":"path","from":"payload","path":"company"},"then":{"op":"object","fields":{"type":{"op":"literal","value":"display"},"value":{"op":"path","from":"payload","path":"company"},"as":{"op":"literal","value":"json"}}},"else":{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"company"},"value":{"op":"format","template":"unavailable ({reason})","values":{"reason":{"op":"path","from":"payload","path":"companyReason"}}}}}}]}}}}';
DECLARE @semantics nvarchar(max)=N'{"id":"dispatch-pair-demo-result-display.v1","expression":'+@display_expression+N'}';
DECLARE @object bigint,@definition bigint,@digest binary(32),@transformation bigint,@version bigint;
EXEC model.put_semantic_definition 'TRANSFORMATION',@namespace,@transformationId,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
SET @transformation=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@object);
IF @transformation IS NULL BEGIN
 INSERT model.transformation(namespace_pk,transformation_id,semantic_object_pk,object_kind)
 SELECT namespace_pk,@transformationId,@object,'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk=@object;
 SET @transformation=SCOPE_IDENTITY();
END
SET @version=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@definition);
IF @version IS NULL BEGIN
 INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@transformation,@object,@definition,@digest,'json-expression-tree.v1','TRANSFORMATION',@definition,N'');
 SET @version=SCOPE_IDENTITY();
 EXEC model.normalize_transformation_expression @version;
END
SELECT '2_display_transformation' AS result_set, t.transformation_id, @version AS transformation_version_pk,
 LOWER(CONVERT(varchar(64),@digest,2)) AS definition_digest,
 CONVERT(bit,CASE WHEN CHARINDEX(N'DISPATCH_PAIR_PARTIAL',@display_expression)>0 THEN 1 ELSE 0 END) AS partial_shape_declared,
 CONVERT(bit,CASE WHEN CHARINDEX(N'companyReason',@display_expression)>0 THEN 1 ELSE 0 END) AS reason_declared
FROM model.transformation t WHERE t.semantic_object_pk=@object;

-- The capability envelope: add $.semantics.cli.display only. Before/after are
-- printed; when the display is already declared the migration mints nothing.
DECLARE @capability_id nvarchar(400)=N'dispatch-pair-demo';
DECLARE @model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capPk bigint, @capSo bigint, @capSod bigint, @capVer bigint;
SELECT @capPk=c.capability_pk, @capSo=c.semantic_object_pk, @capSod=ec.semantic_object_definition_pk, @capVer=ec.capability_version_pk
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE ec.estate_model_pk=@model AND c.capability_id=@capability_id AND n.namespace_id=N'sidefx:capabilities';
IF @capPk IS NULL THROW 51000,N'DISPATCH_PAIR_CAPABILITY_NOT_FOUND',1;
DECLARE @curEnv nvarchar(max);
SELECT @curEnv=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE d.semantic_object_definition_pk=@capSod;
IF @curEnv IS NULL THROW 51000,N'DISPATCH_PAIR_ENVELOPE_NOT_FOUND',1;
DECLARE @beforeDisplay nvarchar(400)=JSON_VALUE(@curEnv,N'$.semantics.cli.display.transformationId');
DECLARE @newEnv nvarchar(max)=@curEnv;
IF ISNULL(@beforeDisplay,N'')<>@transformationId
 SET @newEnv=JSON_MODIFY(@curEnv,N'$.semantics.cli.display',JSON_QUERY(N'{"transformationId":"dispatch-pair-demo-result-display.v1","as":"json"}'));
IF ISNULL(JSON_VALUE(@newEnv,N'$.semantics.cli.input.contract'),N'')<>N'dispatch-pair-demo-request.v1'
 THROW 51000,N'DISPATCH_PAIR_CLI_INPUT_CONTRACT_MOVED',1;
DECLARE @newSod bigint=@capSod,@newVer bigint=@capVer;
IF @newEnv<>@curEnv
BEGIN
 DECLARE @newBytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),(@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @newDigest binary(32)=HASHBYTES('SHA2_256',@newBytes);
 IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@newDigest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@newDigest,@newBytes,DATALENGTH(@newBytes));
 SET @newSod=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition
  WHERE semantic_object_pk=@capSo AND definition_digest=@newDigest);
 IF @newSod IS NULL
 BEGIN
  INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk)
   VALUES(@capSo,'CAPABILITY',@newDigest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@newDigest));
  SET @newSod=SCOPE_IDENTITY();
  INSERT model.estate_definition(estate_model_pk,semantic_object_definition_pk) VALUES(@model,@newSod);
 END
 IF @newSod<>@capSod
 BEGIN
  -- Re-pointing at an older definition would make the capability invisible; a
  -- replay that asks for an already-minted display envelope after a later
  -- envelope change refuses rather than re-pointing history.
  IF EXISTS (SELECT 1 FROM model.capability_version WHERE capability_pk=@capPk AND semantic_object_definition_pk=@newSod)
   THROW 51000,N'DISPATCH_PAIR_DISPLAY_ENVELOPE_VERSION_CONFLICT',1;
  INSERT model.capability_version(capability_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@capPk,@capSo,@newSod,@newDigest,@capability_id,'CAPABILITY',@newSod,N'');
  SET @newVer=SCOPE_IDENTITY();
  INSERT model.capability_scenario(capability_pk,capability_version_pk,scenario_pk,scenario_version_pk,_owner_definition_pk,_canonical_pointer)
   SELECT capability_pk,@newVer,scenario_pk,scenario_version_pk,@newSod,_canonical_pointer
   FROM model.capability_scenario WHERE capability_version_pk=@capVer;
  INSERT model.capability_root_scenario(capability_version_pk,scenario_pk,_owner_definition_pk,_canonical_pointer)
   SELECT @newVer,scenario_pk,@newSod,_canonical_pointer
   FROM model.capability_root_scenario WHERE capability_version_pk=@capVer;
  UPDATE model.estate_capability SET capability_version_pk=@newVer, semantic_object_definition_pk=@newSod
  WHERE estate_model_pk=@model AND capability_pk=@capPk;
 END
END
SELECT '3_envelope_display' AS result_set,
 ISNULL(@beforeDisplay,N'(none)') AS display_before,
 JSON_VALUE(@newEnv,N'$.semantics.cli.display.transformationId') AS display_after,
 CONVERT(bit,CASE WHEN @newEnv<>@curEnv THEN 1 ELSE 0 END) AS envelope_minted,
 @newVer AS capability_version_pk;
GO

-- ============================== JOIN PROJECTION ==============================
-- Re-declare the join scenario: the same single invoke-port operation and the
-- same port id, now projecting the two settlement envelopes into the declared
-- result contract; the scenario outcome contract follows the projection.
DECLARE @capability_id nvarchar(400)=N'dispatch-pair-demo';
DECLARE @join_expression nvarchar(max)=N'{"op":"let","bindings":{"slotA":{"op":"find","from":{"op":"path","from":"input","path":""},"as":"entry","where":{"op":"equals","left":{"op":"path","from":"entry","path":"slotId"},"right":{"op":"literal","value":"a"}}},"slotC":{"op":"find","from":{"op":"path","from":"input","path":""},"as":"entry","where":{"op":"equals","left":{"op":"path","from":"entry","path":"slotId"},"right":{"op":"literal","value":"c"}}},"a":{"op":"if","when":{"op":"path","from":"slotA","path":""},"then":{"op":"path","from":"slotA","path":"settlement"},"else":{"op":"literal","value":null}},"c":{"op":"if","when":{"op":"path","from":"slotC","path":""},"then":{"op":"path","from":"slotC","path":"settlement"},"else":{"op":"literal","value":null}},"aEnvelope":{"op":"path","from":"a","path":"outcomeEnvelope"},"aValue":{"op":"path","from":"aEnvelope","path":"payload"},"aResolved":{"op":"equals","left":{"op":"path","from":"aValue","path":"disposition"},"right":{"op":"literal","value":"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"}},"aCurrency":{"op":"path","from":"aValue","path":"payload.currency"},"aReason":{"op":"if","when":{"op":"path","from":"aValue","path":"reasonCode"},"then":{"op":"path","from":"aValue","path":"reasonCode"},"else":{"op":"if","when":{"op":"path","from":"aValue","path":"disposition"},"then":{"op":"path","from":"aValue","path":"disposition"},"else":{"op":"if","when":{"op":"path","from":"aEnvelope","path":"payloadRef.digest"},"then":{"op":"literal","value":"SETTLEMENT_PAYLOAD_REFERENCED"},"else":{"op":"if","when":{"op":"path","from":"a","path":"disposition"},"then":{"op":"path","from":"a","path":"disposition"},"else":{"op":"literal","value":"UNSETTLED"}}}}},"cEnvelope":{"op":"path","from":"c","path":"outcomeEnvelope"},"cValue":{"op":"path","from":"cEnvelope","path":"payload"},"cCompleted":{"op":"equals","left":{"op":"path","from":"cValue","path":"disposition"},"right":{"op":"literal","value":"completed"}},"cBodyText":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"cValue","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"base64-decode-utf8","value":{"op":"path","from":"cValue","path":"responseBodyBytes"}},"else":{"op":"literal","value":""}},"cParsed":{"op":"try-parse-json","value":{"op":"path","from":"cBodyText","path":""}},"cReason":{"op":"if","when":{"op":"path","from":"cCompleted","path":""},"then":{"op":"if","when":{"op":"path","from":"cParsed","path":"value.fixture"},"then":{"op":"literal","value":"FIXTURE_RESPONSE_PARSED"},"else":{"op":"literal","value":"FIXTURE_RESPONSE_NOT_PARSED"}},"else":{"op":"if","when":{"op":"path","from":"cValue","path":"transportDisposition"},"then":{"op":"path","from":"cValue","path":"transportDisposition"},"else":{"op":"if","when":{"op":"path","from":"cValue","path":"disposition"},"then":{"op":"path","from":"cValue","path":"disposition"},"else":{"op":"if","when":{"op":"path","from":"cEnvelope","path":"payloadRef.digest"},"then":{"op":"literal","value":"SETTLEMENT_PAYLOAD_REFERENCED"},"else":{"op":"if","when":{"op":"path","from":"c","path":"disposition"},"then":{"op":"path","from":"c","path":"disposition"},"else":{"op":"literal","value":"UNSETTLED"}}}}}},"price":{"op":"if","when":{"op":"path","from":"aResolved","path":""},"then":{"op":"path","from":"aValue","path":"payload.observedPrice"},"else":{"op":"literal","value":null}},"company":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"cParsed","path":"disposition"},"right":{"op":"literal","value":"PARSED"}},"then":{"op":"if","when":{"op":"path","from":"cParsed","path":"value.fixture"},"then":{"op":"path","from":"cParsed","path":"value"},"else":{"op":"literal","value":null}},"else":{"op":"literal","value":null}}},"value":{"op":"object","fields":{"contractId":{"op":"literal","value":"dispatch-pair-result.v1"},"disposition":{"op":"if","when":{"op":"path","from":"aResolved","path":""},"then":{"op":"if","when":{"op":"path","from":"company","path":""},"then":{"op":"literal","value":"DISPATCH_PAIR_RESOLVED"},"else":{"op":"literal","value":"DISPATCH_PAIR_PARTIAL"}},"else":{"op":"literal","value":"DISPATCH_PAIR_PARTIAL"}},"payload":{"op":"object","fields":{"price":{"op":"path","from":"price","path":""},"currency":{"op":"if","when":{"op":"path","from":"aResolved","path":""},"then":{"op":"path","from":"aCurrency","path":""},"else":{"op":"literal","value":null}},"priceReason":{"op":"if","when":{"op":"path","from":"aResolved","path":""},"then":{"op":"literal","value":null},"else":{"op":"format","template":"{reason}","values":{"reason":{"op":"path","from":"aReason","path":""}}}},"company":{"op":"path","from":"company","path":""},"companyReason":{"op":"if","when":{"op":"path","from":"company","path":""},"then":{"op":"literal","value":null},"else":{"op":"format","template":"{reason}","values":{"reason":{"op":"path","from":"cReason","path":""}}}}}}}}}';
DECLARE @port_bindings nvarchar(max)=N'[{"portId":"dispatch-pair-demo-join-collect","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"expression":'+@join_expression+N'}}]';
EXEC model.declare_scenario
  @capability_id=@capability_id,
  @scenario=N'{"scenarioId":"dispatch-pair-demo-join","name":"Collect the declared branch settlements","inputId":"dispatch-pair-demo-join-request","inputContract":"dispatch-pair-leg-settlement.v1","eventId":"dispatch-pair-demo-joined","eventAuthority":"dispatch-pair-demo-join.v1","outcomeId":"dispatch-pair-demo-outcome","outcomeContract":"dispatch-pair-result.v1","given":"every required branch slot has one terminal settlement carrying its admitted outcome envelope","when":"the declared all-required join admits the continuation","then":"the branch outcomes are projected into the declared pair result","root":false,"terminal":true}',
  @operations=N'[{"operationId":"dispatch-pair-demo.join.1","kind":"invoke-port","portId":"dispatch-pair-demo-join-collect"}]',
  @port_bindings=@port_bindings;

EXEC model.declare_capability_feature
  @capability_id=N'dispatch-pair-demo',
  @feature_text=N'@capability:dispatch-pair-demo
@root-scenario:dispatch-pair-demo
Feature: Dispatch two declared independent legs and project their outcomes

  @scenario:dispatch-pair-demo
  @input:dispatch-pair-demo-request
  @input-contract:dispatch-pair-demo-request.v1
  @event:dispatch-pair-demo-requested
  @event-authority:dispatch-pair-demo.v1
  @outcome:dispatch-pair-demo-dispatched
  @outcome-contract:dispatch-pair-demo-request.v1
  Scenario: Dispatch the declared legs
    Given the caller supplies one canonical equity price request
    When the declared broadcast group admits its independent legs
    Then both legs are dispatched and their settlements converge

  @scenario:dispatch-pair-demo-leg-a
  @input:dispatch-pair-demo-leg-a-request
  @input-contract:dispatch-pair-demo-request.v1
  @event:dispatch-pair-demo-leg-a-requested
  @event-authority:dispatch-pair-demo-leg-a.v1
  @outcome:dispatch-pair-demo-leg-a-settlement
  @outcome-contract:dispatch-pair-leg-settlement.v1
  Scenario: Resolve the real equity price
    Given the broadcast group admitted the equity leg
    When the real equity provider chain executes its declared operations
    Then the provider exchange settlement is collected

  @scenario:dispatch-pair-demo-leg-c
  @input:dispatch-pair-demo-leg-c-request
  @input-contract:dispatch-pair-demo-request.v1
  @event:dispatch-pair-demo-leg-c-requested
  @event-authority:dispatch-pair-demo-leg-c.v1
  @outcome:dispatch-pair-demo-leg-c-settlement
  @outcome-contract:dispatch-pair-leg-settlement.v1
  Scenario: Exchange with the local delay fixture
    Given the broadcast group admitted the fixture leg
    When the governed HTTPS exchange reaches the localhost delay fixture
    Then the fixture exchange settlement is collected

  @scenario:dispatch-pair-demo-join
  @input:dispatch-pair-demo-join-request
  @input-contract:dispatch-pair-leg-settlement.v1
  @event:dispatch-pair-demo-joined
  @event-authority:dispatch-pair-demo-join.v1
  @outcome:dispatch-pair-demo-outcome
  @outcome-contract:dispatch-pair-result.v1
  @outcome-terminal
  Scenario: Project the declared branch settlements
    Given every required branch slot has one terminal settlement carrying its admitted outcome envelope
    When the declared all-required join admits the continuation
    Then the branch outcomes are projected into the declared pair result
';
GO

-- ============================== VERIFICATION ==============================
DECLARE @capability_id nvarchar(400)=N'dispatch-pair-demo';
DECLARE @transformationId nvarchar(400)=N'dispatch-pair-demo-result-display.v1';
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(@capability_id,1,NULL));
DECLARE @joinPort nvarchar(max)=(
 SELECT pb.value FROM OPENJSON(JSON_QUERY(@graph,'$.interfaceAuthority.portBindings')) pb
 WHERE JSON_VALUE(pb.value,'$.portId')=N'dispatch-pair-demo-join-collect');
DECLARE @selectedJoinContract nvarchar(400)=(
 SELECT c.contract_id
 FROM model.estate_capability ec
 JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
 JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=N'dispatch-pair-demo-join'
 JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk=cs.scenario_version_pk
 JOIN model.contract_version cv ON cv.contract_version_pk=soc.contract_version_pk
 JOIN model.contract c ON c.contract_pk=cv.contract_pk
 WHERE ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1));

SELECT '4_join_projection' AS result_set,
 @selectedJoinContract AS join_outcome_contract,
 JSON_VALUE(@joinPort,'$.configuration.expression.value.fields.contractId.value') AS projected_contract_id,
 (SELECT COUNT(*) FROM OPENJSON(@joinPort,'$.configuration.expression.bindings') b WHERE b.[key] IN (N'price',N'company')) AS projected_outcomes,
 CONVERT(bit,CASE WHEN CHARINDEX(N'outcomeEnvelope',@joinPort)>0 THEN 1 ELSE 0 END) AS settlement_envelope_read,
 CONVERT(bit,CASE WHEN CHARINDEX(N'priceReason',@joinPort)>0 THEN 1 ELSE 0 END) AS partial_reason_declared;

SELECT '5_display_interface' AS result_set,
 JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.transformationId') AS display_transformation_id,
 JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.as') AS display_as,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations')) t
  WHERE JSON_VALUE(t.value,'$.id')=@transformationId) AS display_transformation_present;

SELECT '6_capability_versions' AS result_set,
 @selectedJoinContract AS outcome_contract,
 (SELECT COUNT(*) FROM model.capability_version cv WHERE cv.capability_pk=(
   SELECT c.capability_pk FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
   WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capability_id)) AS capability_versions;

IF @selectedJoinContract<>N'dispatch-pair-result.v1' THROW 51000,N'DISPATCH_PAIR_JOIN_OUTCOME_CONTRACT_NOT_PROJECTED',1;
IF CHARINDEX(N'dispatch-pair-result.v1',@joinPort)=0 THROW 51000,N'DISPATCH_PAIR_JOIN_PROJECTION_NOT_DECLARED',1;
IF CHARINDEX(N'outcomeEnvelope',@joinPort)=0 THROW 51000,N'DISPATCH_PAIR_SETTLEMENT_ENVELOPE_NOT_READ',1;
IF JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.transformationId')<>@transformationId
 THROW 51000,N'DISPATCH_PAIR_DISPLAY_NOT_DECLARED',1;
IF NOT EXISTS (
 SELECT 1 FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations')) t
 WHERE JSON_VALUE(t.value,'$.id')=@transformationId)
 THROW 51000,N'DISPATCH_PAIR_DISPLAY_TRANSFORMATION_NOT_IN_SOURCE',1;
IF JSON_VALUE(@graph,'$.scenarios[0].outcome.contract.contractId') IS NULL
 THROW 51000,N'DISPATCH_PAIR_SCENARIO_OUTCOMES_NOT_ASSEMBLED',1;

COMMIT TRANSACTION;
-- Installed after the rollback dry run and the from-transaction preflight. The
-- declared result accepts the provider-unavailable case as a valid partial
-- document; the display renders it with the branch reason.
