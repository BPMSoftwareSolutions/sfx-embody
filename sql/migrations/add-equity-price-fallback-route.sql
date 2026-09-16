-- add-equity-price-fallback-route.sql
--
-- Declares the real-time fallback route for resolve-equity-market-price-evidence:
--   primary   yahoo-finance166 /api/stock/get-price        (declared, classified)
--   fallback  yahoo-finance-real-time1 /market/get-quotes  (this change)
--
-- Both routes share the same RAPID_API_KEY credential reference; each route has
-- its own endpoint authority. The fallback endpoint authority digest below is
-- the content address of the endpoint-authority record declared in the same
-- script (SHA-256 over its UTF-8 bytes, the estate's canonical envelope recipe).
-- It is minted here because the record is declared here; it is not copied from
-- another route or invented without a backing declaration.
--
-- Route mechanics, all declared:
--   * The primary route's five operations are unchanged and run first. Its
--     normalize step produces the canonical primary outcome (success payload or
--     EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE).
--   * The fallback's binding-request transformation receives that outcome: if the
--     primary resolved, it emits a guard object that fails credential admission
--     pre-network and no exchange happens; otherwise it builds the fallback
--     binding request, carrying the primary outcome forward in effectLineage
--     (the one array the effect ports echo).
--   * The fallback exchange-request transformation builds the request from root
--     (symbol/region) plus the one-use binding; when the credential step did not
--     bind, it emits a guard object, which the exchange port rejects at endpoint
--     admission with exchangeCount 0 - a skipped route performs no transport.
--   * The final selection returns the fallback's canonical outcome when its
--     exchange completed, otherwise the carried primary outcome, so provider
--     identity always follows the route that answered.
--
-- Adding operations changes the provider-slot inventory: the blueprint declared
-- by declare-equity-provider-slot-requirements.sql still asserts five operations
-- and must be re-declared (recorded as a follow-up; it is not on the invocation
-- path).
--
-- Default: ROLLBACK. Replace the final ROLLBACK with COMMIT to install.
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
WHILE @@FETCH_STATUS=0 BEGIN
 EXEC(N'DROP TRIGGER '+@trigger_name);
 FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
GO
BEGIN TRANSACTION;

DECLARE @capability_id nvarchar(400) = N'resolve-equity-market-price-evidence';
DECLARE @namespace nvarchar(400) = N'sidefx:capability:' + @capability_id;

-- The declared endpoint authority record. Its content address is the route's digest.
DECLARE @endpoint_authority nvarchar(max) = N'{"host":"yahoo-finance-real-time1.p.rapidapi.com","method":"GET","pathPrefix":"/market/get-quotes?","providerId":"rapidapi/yahoo-finance-real-time1","bindingId":"rapidapi-yahoo-finance-real-time1-market-quotes.v1","credentialInjectionRuleId":"rapidapi-x-rapidapi-key.v1","effectScope":"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY"}';
DECLARE @fallback_digest nvarchar(200) = N'sha256:' + LOWER(CONVERT(varchar(64),
  HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (@endpoint_authority) COLLATE Latin1_General_100_BIN2_UTF8))), 2));

-- 1. The three declared transformations for the route.
DECLARE @object bigint, @definition bigint, @digest binary(32), @transformation bigint, @version bigint, @semantics nvarchar(max);
DECLARE @transformations TABLE (idx int PRIMARY KEY, id nvarchar(400), expression nvarchar(max));
INSERT @transformations VALUES
 (0, N'build-fallback-price-binding-request', N'{"op":"let","bindings":{"done":{"op":"equals","left":{"op":"path","from":"input","path":"disposition"},"right":{"op":"literal","value":"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"}},"carrier":{"op":"array","items":[{"op":"path","from":"input","path":""}]},"request":{"op":"object","fields":{"credentialReference":{"op":"literal","value":"RAPID_API_KEY"},"invocationIdentity":{"op":"literal","value":"equity-market-price-evidence.v1"},"requestingCapabilityId":{"op":"literal","value":"resolve-equity-market-price-evidence"},"endpointAuthorityDigest":{"op":"literal","value":"' + @fallback_digest + '"},"effectScope":{"op":"literal","value":"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY"},"effectLineage":{"op":"path","from":"carrier","path":""}}}},"value":{"op":"if","when":{"op":"path","from":"done","path":""},"then":{"op":"object","fields":{"effectLineage":{"op":"path","from":"carrier","path":""}}},"else":{"op":"path","from":"request","path":""}}}'),
 (1, N'build-fallback-price-exchange-request', N'{"op":"let","bindings":{"bound":{"op":"equals","left":{"op":"path","from":"input","path":"disposition"},"right":{"op":"literal","value":"BOUND"}},"url":{"op":"format","template":"https://yahoo-finance-real-time1.p.rapidapi.com/market/get-quotes?region={region}&symbols={symbols}","values":{"region":{"op":"path","from":"root","path":"payload.region"},"symbols":{"op":"path","from":"root","path":"payload.symbol"}}},"request":{"op":"object","fields":{"requestUrl":{"op":"path","from":"url","path":""},"method":{"op":"literal","value":"GET"},"safeHeaders":{"op":"object","fields":{"x-rapidapi-host":{"op":"literal","value":"yahoo-finance-real-time1.p.rapidapi.com"}}},"allowedResponseHeaders":{"op":"array","items":[{"op":"literal","value":"content-type"},{"op":"literal","value":"retry-after"}]},"timeoutMilliseconds":{"op":"literal","value":15000},"maxResponseBytes":{"op":"literal","value":262144},"requestBodyText":{"op":"literal","value":""},"invocationIdentity":{"op":"literal","value":"equity-market-price-evidence.v1"},"endpointAuthorityDigest":{"op":"literal","value":"' + @fallback_digest + '"},"credentialInjectionRuleId":{"op":"literal","value":"rapidapi-x-rapidapi-key.v1"},"opaqueCredentialBinding":{"op":"object","fields":{"bindingId":{"op":"path","from":"input","path":"opaqueBindingId"},"credentialInjectionRuleId":{"op":"literal","value":"rapidapi-x-rapidapi-key.v1"}}},"effectLineage":{"op":"path","from":"input","path":"effectLineage"}}}},"value":{"op":"if","when":{"op":"path","from":"bound","path":""},"then":{"op":"path","from":"request","path":""},"else":{"op":"object","fields":{"effectLineage":{"op":"path","from":"input","path":"effectLineage"}}}}}'),
 (2, N'select-equity-price-route', N'{"op":"let","bindings":{"fallbackCompleted":{"op":"equals","left":{"op":"path","from":"input","path":"disposition"},"right":{"op":"literal","value":"completed"}},"prior":{"op":"path","from":"input","path":"effectLineage.0"}},"value":{"op":"if","when":{"op":"path","from":"fallbackCompleted","path":""},"then":{"op":"let","bindings":{"payload":{"op":"try-parse-json","value":{"op":"base64-decode-utf8","value":{"op":"path","from":"input","path":"responseBodyBytes"}}},"quote":{"op":"path","from":"payload","path":"value.quoteResponse.result.0"}},"value":{"op":"object","fields":{"contractId":{"op":"literal","value":"equity-market-price-evidence.v1"},"disposition":{"op":"literal","value":"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"},"payload":{"op":"object","fields":{"symbol":{"op":"path","from":"quote","path":"symbol"},"region":{"op":"path","from":"root","path":"payload.region"},"currency":{"op":"path","from":"quote","path":"currency"},"observedPrice":{"op":"path","from":"quote","path":"regularMarketPrice"},"observedMarketTime":{"op":"path","from":"quote","path":"regularMarketTime"},"marketState":{"op":"path","from":"quote","path":"marketState"},"exchange":{"op":"path","from":"quote","path":"exchange"},"sourceAttribution":{"op":"path","from":"quote","path":"quoteSourceName"}}},"providerTestimony":{"op":"object","fields":{"bindingId":{"op":"literal","value":"rapidapi-yahoo-finance-real-time1-market-quotes.v1"},"providerId":{"op":"literal","value":"rapidapi/yahoo-finance-real-time1"},"nativeShape":{"op":"literal","value":"quoteResponse.result.0"}}}}}},"else":{"op":"path","from":"prior","path":""}}}');

DECLARE @idx int, @id nvarchar(400), @expression nvarchar(max);
DECLARE @cursor CURSOR;
SET @cursor = CURSOR LOCAL FAST_FORWARD FOR SELECT idx, id, expression FROM @transformations ORDER BY idx;
OPEN @cursor;
FETCH NEXT FROM @cursor INTO @idx, @id, @expression;
WHILE @@FETCH_STATUS = 0 BEGIN
  SET @semantics = N'{"id":"' + @id + N'","expression":' + @expression + N'}';
  EXEC model.put_semantic_definition 'TRANSFORMATION', @namespace, @id, @semantics, @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
  SET @transformation = (SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk = @object);
  IF @transformation IS NULL BEGIN
    INSERT model.transformation(namespace_pk, transformation_id, semantic_object_pk, object_kind)
    SELECT namespace_pk, @id, @object, 'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk = @object;
    SET @transformation = SCOPE_IDENTITY();
  END;
  SET @version = (SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk = @definition);
  IF @version IS NULL BEGIN
    INSERT model.transformation_version(transformation_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest,
      expression_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES(@transformation, @object, @definition, @digest, 'json-expression-tree.v1', 'TRANSFORMATION', @definition, N'');
    SET @version = SCOPE_IDENTITY();
    EXEC model.normalize_transformation_expression @version;
  END;
  FETCH NEXT FROM @cursor INTO @idx, @id, @expression;
END;
CLOSE @cursor;
DEALLOCATE @cursor;

-- 2. The complete port inventory (9 unchanged + 5 route ports) and operation order.
DECLARE @port_bindings nvarchar(max) = CONVERT(nvarchar(max), N'[{"portId":"resolve-equity-market-price-evidence-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"transform-resolve-equity-market-price-evidence"}},{"portId":"retain-provider-realization-outside-market-price-semantics-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"retain-provider-realization-outside-market-price-semantics-preserve"}},{"portId":"hold-unavailable-equity-market-price-provider-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"hold-unavailable-equity-market-price-provider-preserve"}},{"portId":"reject-nonconforming-native-market-price-testimony-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"reject-nonconforming-native-market-price-testimony-preserve"}},{"portId":"build-equity-price-binding-request","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"build-equity-price-binding-request"}},{"portId":"bind-equity-price-provider-credential","platformCapabilityId":"sda-external-credential-reference-binding-port.v1","configuration":{"credentialAuthorities":[{"effectScopes":["ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY"],"endpointAuthorityDigests":["sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b"],"injectionRule":{"headerName":"X-RapidAPI-Key","id":"rapidapi-x-rapidapi-key.v1"},"lifetimeMilliseconds":15000,"referenceName":"RAPID_API_KEY","requestingCapabilityIds":["resolve-equity-market-price-evidence"],"source":"environment"}]}},{"portId":"build-equity-price-exchange-request","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"build-equity-price-exchange-request"}},{"portId":"observe-equity-price-exchange","platformCapabilityId":"sda-governed-http-exchange-port.v1","configuration":{"credentialInjectionRules":[{"headerName":"X-RapidAPI-Key","id":"rapidapi-x-rapidapi-key.v1"}],"endpointAuthorities":[{"allowedRequestHeaders":["x-rapidapi-host"],"allowedResponseHeaders":["content-type","retry-after"],"endpointAuthorityDigest":"sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b","methods":["GET"],"urlPrefixes":["https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?"]}]}},{"portId":"normalize-equity-price-evidence","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","tr') + N'ansformationId":"normalize-equity-price-evidence"}},{"portId":"build-fallback-price-binding-request","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"build-fallback-price-binding-request"}},{"portId":"bind-fallback-price-provider-credential","platformCapabilityId":"sda-external-credential-reference-binding-port.v1","configuration":{"credentialAuthorities":[{"effectScopes":["ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY"],"endpointAuthorityDigests":["' + @fallback_digest + N'"],"injectionRule":{"headerName":"X-RapidAPI-Key","id":"rapidapi-x-rapidapi-key.v1"},"lifetimeMilliseconds":15000,"referenceName":"RAPID_API_KEY","requestingCapabilityIds":["resolve-equity-market-price-evidence"],"source":"environment"}]}},{"portId":"build-fallback-price-exchange-request","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"build-fallback-price-exchange-request"}},{"portId":"observe-fallback-price-exchange","platformCapabilityId":"sda-governed-http-exchange-port.v1","configuration":{"credentialInjectionRules":[{"headerName":"X-RapidAPI-Key","id":"rapidapi-x-rapidapi-key.v1"}],"endpointAuthorities":[{"allowedRequestHeaders":["x-rapidapi-host"],"allowedResponseHeaders":["content-type","retry-after"],"endpointAuthorityDigest":"' + @fallback_digest + N'","methods":["GET"],"urlPrefixes":["https://yahoo-finance-real-time1.p.rapidapi.com/market/get-quotes?"]}]}},{"portId":"select-equity-price-route","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"select-equity-price-route"}}]';
DECLARE @operations nvarchar(max) = CONVERT(nvarchar(max), N'[{"operationId":"resolve-equity-market-price-evidence.operation.1","kind":"invoke-port","portId":"build-equity-price-binding-request"},{"operationId":"resolve-equity-market-price-evidence.operation.2","kind":"invoke-port","portId":"bind-equity-price-provider-credential","outcomeVariants":["SUCCESS",{"variantId":"BOUND","classification":"success"},{"variantId":"CREDENTIAL_NOT_AVAILABLE","classification":"failure"},{"variantId":"UNAUTHORIZED_REFERENCE","classification":"failure"},{"variantId":"IDENTITY_MISMATCH","classification":"failure"}]},{"operationId":"resolve-equity-market-price-evidence.operation.3","kind":"invoke-port","portId":"build-equity-price-exchange-request"},{"operationId":"resolve-equity-market-price-evidence.operation.4","kind":"invoke-port","portId":"observe-equity-price-exchange","outcomeVariants":["SUCCESS","FAILURE","CANCELLED",{"variantId":"completed","classification":"success"},{"variantId":"retained-non-success","classification":"failure"},{"variantId":"rejected-endpoint","classification":"failure"},{"variantId":"transport-failed","classification":"failure"},{"variantId":"rejected-credential","classification":"failure"},{"variantId":"cancelled","classification":"failure"},{"variantId":"oversized-response-rejected","classification":"failure"},{"variantId":"timed-out","classification":"failure"}]},{"operationId":"resolve-equity-market-price-evidence.operation.5","kind":"invoke-port","portId":"normalize-equity-price-evidence","outcomeVariants":["SUCCESS",{"variantId":"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED","classification":"success"},{"variantId":"NATIVE_MARKET_PRICE_TESTIMONY_REJECTED","classification":"failure"},{"variantId":"EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE","classification":"failure"}]},{"operationId":"resolve-equity-market-price-evidence.operation.6","kind":"invoke-port","portId":"build-fallback-price-binding-request"},{"operationId":"resolve-equity-market-price-evidence.operation.7","kind":"invoke-port","portId":"bind-fallback-price-provider-credential","outcomeVariants":["SUCCESS",{"variantId":"BOUND","classification":"success"},{"variantId":"CREDENTIAL_NOT_AVAILABLE","classification":"failure"},{"variantId":"UNAUTHORIZED_REFERENCE","classification":"failure"},{"variantId":"IDENTITY_MISMATCH","classification":"failure"}]},{"operationId":"resolve-equity-market-price-evidence.operation.8","kind":"invoke-port","portId":"build-fallback-price-exchange-request"},{"operationId":"resolve-equity-market-price-evidence.operation.9","kind":"invoke-port","portId":"observe-fallback-price-exchange","outcomeVariants":["SUCCESS","FAILURE","CANCELLED",{"variantId":"completed","classification":"success"},{"variantId":"retained-non-success","classification":"failure"},{"variantId":"rejected-endpoint","classification":"failure"},{"variantId":"transport-failed","classification":"failure"},{"variantId":"rejected-credential","classification":"failure"},{"variantId":"cancelled","classification":"failure"},{"variantId":"oversized-respons') + N'e-rejected","classification":"failure"},{"variantId":"timed-out","classification":"failure"}]},{"operationId":"resolve-equity-market-price-evidence.operation.10","kind":"invoke-port","portId":"select-equity-price-route","outcomeVariants":["SUCCESS",{"variantId":"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED","classification":"success"},{"variantId":"EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE","classification":"failure"}]}]';
-- 3. Register every port binding (idempotent). model.declare_scenario is not
--    used here: it requires contracts in the global sidefx:contracts namespace,
--    while this capability's contracts are capability-scoped, so the equity
--    authority has always been minted directly (restore-equity-root-authority.sql).
DECLARE @port_id nvarchar(400), @binding nvarchar(max), @port bigint, @port_version bigint;
DECLARE @ports TABLE (port_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY, port_version_pk bigint);
DECLARE @port_cursor CURSOR;
SET @port_cursor = CURSOR LOCAL FAST_FORWARD FOR SELECT JSON_VALUE(value, '$.portId'), value FROM OPENJSON(@port_bindings);
OPEN @port_cursor;
FETCH NEXT FROM @port_cursor INTO @port_id, @binding;
WHILE @@FETCH_STATUS = 0 BEGIN
  EXEC model.put_semantic_definition 'PORT', @namespace, @port_id, @binding, @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
  SET @port = (SELECT port_pk FROM model.port WHERE semantic_object_pk = @object);
  IF @port IS NULL BEGIN
    INSERT model.port(namespace_pk, port_id, semantic_object_pk, object_kind)
    SELECT namespace_pk, @port_id, @object, 'PORT' FROM model.semantic_object WHERE semantic_object_pk = @object;
    SET @port = SCOPE_IDENTITY();
  END;
  SET @port_version = (SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk = @definition);
  IF @port_version IS NULL BEGIN
    INSERT model.port_version(port_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, port_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES(@port, @object, @definition, @digest, 'consumer-interface-authority.v1', 'PORT', @definition, N'');
    SET @port_version = SCOPE_IDENTITY();
  END;
  INSERT @ports VALUES(@port_id, @port_version);
  FETCH NEXT FROM @port_cursor INTO @port_id, @binding;
END;
CLOSE @port_cursor;
DEALLOCATE @port_cursor;

-- 4. Mint the ten-operation execution authority directly and re-point the event.
DECLARE @operations_envelope nvarchar(max) = (
  SELECT JSON_VALUE(o.value, '$.kind') AS kind, JSON_VALUE(o.value, '$.portId') AS portId,
    JSON_QUERY(o.value, '$.outcomeVariants') AS outcomeVariants
  FROM OPENJSON(@operations) o ORDER BY CONVERT(int, o.[key]) FOR JSON PATH);
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @authority_pk bigint, @authority_so bigint, @scenario_version bigint, @capability_version bigint;
SELECT @capability_version = ec.capability_version_pk
FROM model.capability c
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk AND n.namespace_id = N'sidefx:capabilities'
JOIN model.estate_capability ec ON ec.capability_pk = c.capability_pk AND ec.estate_model_pk = @model
WHERE c.capability_id = @capability_id;
SET @scenario_version = (SELECT cs.scenario_version_pk FROM model.capability_scenario cs
  JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
  WHERE cs.capability_version_pk = @capability_version AND s.scenario_id = @capability_id);
SELECT @authority_pk = ea.execution_authority_pk, @authority_so = ea.semantic_object_pk
FROM model.execution_authority ea
JOIN model.identity_namespace n ON n.namespace_pk = ea.namespace_pk AND n.namespace_id = @namespace
WHERE ea.execution_authority_id = @capability_id + N'.v1';
DECLARE @authority_envelope nvarchar(max) = N'{"address":{"id":"' + @capability_id + N'.v1","kind":"EXECUTION_AUTHORITY","namespace":"' + @namespace + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":{"id":"' + @capability_id + N'.v1","operations":' + @operations_envelope + N',"owningScenarioId":"' + @capability_id + N'"}}}';
DECLARE @authority_bytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@authority_envelope) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @authority_digest binary(32) = HASHBYTES('SHA2_256', @authority_bytes);
DECLARE @authority_sod bigint = NULL, @authority_version bigint = NULL;
SELECT @authority_sod = semantic_object_definition_pk, @authority_version = execution_authority_version_pk
FROM model.execution_authority_version WHERE execution_authority_pk = @authority_pk AND definition_digest = @authority_digest;
IF @authority_version IS NULL BEGIN
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @authority_digest)
    INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@authority_digest, @authority_bytes, DATALENGTH(@authority_bytes));
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
    VALUES (@authority_so, 'EXECUTION_AUTHORITY', @authority_digest, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @authority_digest));
  SET @authority_sod = SCOPE_IDENTITY();
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk = @model AND semantic_object_definition_pk = @authority_sod)
    INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @authority_sod);
  INSERT model.execution_authority_version (execution_authority_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, authority_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@authority_pk, @authority_so, @authority_sod, @authority_digest, 'execution-authorities.v1', 'EXECUTION_AUTHORITY', @authority_sod, N'');
  SET @authority_version = SCOPE_IDENTITY();
  INSERT model.execution_operation (execution_authority_version_pk, operation_id, ordinal, operation_kind, _owner_definition_pk, _canonical_pointer)
    SELECT @authority_version, JSON_VALUE(o.value, '$.operationId'), CONVERT(int, o.[key]), JSON_VALUE(o.value, '$.kind'), @authority_sod, N'/semantics/authority/operations/' + o.[key]
    FROM OPENJSON(@operations) o;
  INSERT model.operation_port_invocation (execution_operation_pk, port_version_pk, operation_kind, _owner_definition_pk, _canonical_pointer)
    SELECT eo.execution_operation_pk, p.port_version_pk, 'invoke-port', @authority_sod, eo._canonical_pointer
    FROM model.execution_operation eo
    JOIN OPENJSON(@operations) o ON CONVERT(int, o.[key]) = eo.ordinal
    JOIN @ports p ON p.port_id = JSON_VALUE(o.value, '$.portId')
    WHERE eo.execution_authority_version_pk = @authority_version;
END;
UPDATE model.scenario_event SET execution_authority_version_pk = @authority_version
WHERE scenario_version_pk = @scenario_version AND event_id = N'equity-market-price-evidence-requested';

-- 5. Proof.

-- 4. Proof result sets.
SELECT 'fallback_digest' AS result_set, @fallback_digest AS endpoint_authority_digest;
SELECT 'operations' AS result_set, op.ordinal, op.operation_kind, p.port_id,
  JSON_QUERY(o.value, '$.outcomeVariants') AS outcome_variants
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk = ec.capability_pk AND c.capability_id = @capability_id
JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk AND s.scenario_id = @capability_id
JOIN model.scenario_event ev ON ev.scenario_version_pk = cs.scenario_version_pk
JOIN model.execution_operation op ON op.execution_authority_version_pk = ev.execution_authority_version_pk
JOIN model.operation_port_invocation i ON i.execution_operation_pk = op.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk = i.port_version_pk
JOIN model.port p ON p.port_pk = pv.port_pk
JOIN OPENJSON(@operations) o ON CONVERT(int, o.[key]) = op.ordinal
WHERE ec.estate_model_pk = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1)
ORDER BY op.ordinal;
SELECT 'variants' AS result_set, ov.variant_id, ov.classification
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk = ec.capability_pk AND c.capability_id = @capability_id
JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk
JOIN model.outcome_variant ov ON ov.scenario_version_pk = cs.scenario_version_pk
WHERE ec.estate_model_pk = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1)
ORDER BY ov.variant_id;

COMMIT TRANSACTION;
-- Installed 2026-09-16: fallback route resolve-equity-market-price-evidence (primary 166 -> yahoo-finance-real-time1).
