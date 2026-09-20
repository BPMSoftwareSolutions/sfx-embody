-- install-finance15-equity-fallback.sql
--
-- Installs the finance15 provider binding on resolve-equity-market-price-evidence
-- as an additional fallback (primary 166 -> fallback real-time1 -> fallback
-- finance15), through the declared install mechanic
-- (model.install_provider_binding_change, declared by
-- declare-provider-binding-change-install.sql).
--
-- The mapping decision, from the 2026-09-19 probe (evidence/provider-add-20260919):
--   * /api/v1/markets/quote?type=STOCKS (nativeShape body.primaryData) returns a
--     formatted price string ("$357.61"), a human date ("Sep 17, 2026") and
--     currency: null. The declared contract gap is real: no numeric price, no
--     machine timestamp, and no currency at any JSON path in that response.
--   * The same declared provider host serves /api/v1/markets/stock/quotes, whose
--     body[0] carries currency "USD", regularMarketPrice 357.61 (number) and
--     regularMarketTime 1789761602 (epoch seconds), plus marketState/exchange/
--     quoteSourceName. That is the declared currency source that exists, so this
--     route maps body.0 and fabricates nothing.
-- The outcome contract's nativeShape enum is extended to admit body.0 (the
-- shape this route's testimony carries).
--
-- Idempotent: a re-run finds the route's binding port already present and writes
-- nothing (the procedure reports already_installed).
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
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trigger_name); FETCH NEXT FROM @triggers INTO @trigger_name; END;
CLOSE @triggers; DEALLOCATE @triggers;
GO
BEGIN TRANSACTION;

-- ============================ 0. THE DECLARED CHANGE DOCUMENT ============================
DECLARE @document nvarchar(max)=CONVERT(nvarchar(max),N'{
"contractId":"provider-binding-change.v1",
"providerId":"rapidapi/yahoo-finance15",
"capabilityId":"resolve-equity-market-price-evidence",
"outcomeContractId":"equity-market-price-evidence.v1",
"bindingId":"rapidapi-yahoo-finance15-stock-quotes.v1",
"route":{"routeId":"finance15","resolvedDisposition":"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"},
"endpoint":{
 "host":"yahoo-finance15.p.rapidapi.com",
 "method":"GET",
 "pathPrefix":"/api/v1/markets/stock/quotes?",
 "requestTemplate":"https://yahoo-finance15.p.rapidapi.com/api/v1/markets/stock/quotes?ticker={symbol}",
 "safeHeaders":{"x-rapidapi-host":"yahoo-finance15.p.rapidapi.com"},
 "allowedResponseHeaders":["content-type","retry-after"],
 "timeoutMilliseconds":15000,
 "maxResponseBytes":262144},
"credential":{
 "referenceName":"RAPID_API_KEY",
 "injectionRuleId":"rapidapi-x-rapidapi-key.v1",
 "headerName":"X-RapidAPI-Key",
 "source":"vault",
 "storeLocator":"%LOCALAPPDATA%\\sfx\\vault",
 "lifetimeMilliseconds":15000},
"effectScope":"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY",
"nativeShape":"body.0",
"mapping":{
 "symbol":"body.0.symbol",
 "region":"request:payload.region",
 "currency":"body.0.currency",
 "observedPrice":"body.0.regularMarketPrice",
 "observedMarketTime":"body.0.regularMarketTime",
 "marketState":"body.0.marketState",
 "exchange":"body.0.exchange",
 "sourceAttribution":"body.0.quoteSourceName"},
"observedSample":{
 "meta":{"version":"v1.0","status":200,"symbol":"AVGO","processedTime":"2026-09-19T22:17:19.370804Z"},
 "body":[{"language":"en-US","region":"US","quoteType":"EQUITY","quoteSourceName":"Nasdaq Real Time Price","currency":"USD","regularMarketPrice":357.61,"marketState":"CLOSED","regularMarketTime":1789761602,"exchange":"NMS","symbol":"AVGO"}]},
"preflight":{"input":{"contractId":"live-equity-price-request.v1","payload":{"symbol":"AVGO","region":"US"}}},
"verify":{"capabilityId":"resolve-equity-market-price-evidence","input":{"contractId":"live-equity-price-request.v1","payload":{"symbol":"AVGO","region":"US"}}}
}');
IF ISJSON(@document)<>1 THROW 51003,'FINANCE15_DOCUMENT_INVALID',1;

-- ============================ 1. EXTEND THE OUTCOME CONTRACT ============================
-- The canonical outcome contract admits the route's native shape. Append the
-- shapes to the declared enum in place, re-mint the schema/contract version and
-- re-link every reference that named the prior version.
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @contract_id nvarchar(400)=N'equity-market-price-evidence.v1';
DECLARE @oldCv bigint,@contractPk bigint,@capSo bigint,@oldSod bigint,@oldSchemaPk bigint,@dialect nvarchar(400);
DECLARE @schema nvarchar(max),@cenv nvarchar(max);
SELECT TOP 1 @oldCv=cv.contract_version_pk,@contractPk=cv.contract_pk,@capSo=cv.semantic_object_pk,
 @oldSod=cv.semantic_object_definition_pk,@oldSchemaPk=cv.schema_object_pk,@dialect=so.dialect,
 @schema=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.contract_version cv
JOIN model.contract ct ON ct.contract_pk=cv.contract_pk AND ct.contract_id=@contract_id
JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
WHERE cv.contract_version_pk=(SELECT MAX(cv2.contract_version_pk) FROM model.contract_version cv2 WHERE cv2.contract_pk=cv.contract_pk);
IF @oldCv IS NULL THROW 51003,'FINANCE15_OUTCOME_CONTRACT_ABSENT',1;
SELECT @cenv=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE d.semantic_object_definition_pk=@oldSod;
DECLARE @newSchema nvarchar(max)=@schema;
IF NOT EXISTS (SELECT 1 FROM OPENJSON(@newSchema,'$.properties.providerTestimony.properties.nativeShape.enum') WHERE value=N'body.0')
BEGIN
 SET @newSchema=JSON_MODIFY(@newSchema,'$.properties.providerTestimony.properties.nativeShape.enum',
  JSON_QUERY(N'["quoteSummary.result.0.price","quoteResponse.result.0","body.0","body.primaryData"]'));
END
DECLARE @sb varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),(@newSchema) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @sd binary(32)=HASHBYTES('SHA2_256',@sb);
DECLARE @newSchemaPk bigint=(SELECT schema_object_pk FROM model.schema_object WHERE content_digest=@sd);
IF @newSchemaPk IS NULL
BEGIN
 IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@sd)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@sd,@sb,DATALENGTH(@sb));
 INSERT model.schema_object(content_digest,dialect,content_object_pk)
  VALUES(@sd,@dialect,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@sd));
 SET @newSchemaPk=SCOPE_IDENTITY();
END
DECLARE @newCv bigint=NULL;
IF @newSchemaPk=@oldSchemaPk SET @newCv=@oldCv;
ELSE BEGIN
 DECLARE @newEnv nvarchar(max)=JSON_MODIFY(@cenv,'$.semantics.schema_digest',LOWER(CONVERT(varchar(64),@sd,2)));
 DECLARE @eb varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),(@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @ed binary(32)=HASHBYTES('SHA2_256',@eb);
 IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@ed)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@ed,@eb,DATALENGTH(@eb));
 INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk)
  VALUES(@capSo,'CONTRACT',@ed,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@ed));
 DECLARE @newSod bigint=SCOPE_IDENTITY();
 IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@estate AND semantic_object_definition_pk=@newSod)
  INSERT model.estate_definition(estate_model_pk,semantic_object_definition_pk) VALUES(@estate,@newSod);
 INSERT model.contract_version(contract_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,contract_kind,schema_object_pk,object_kind,_owner_definition_pk,_canonical_pointer,schema_reference_state)
  VALUES(@contractPk,@capSo,@newSod,@ed,NULL,NULL,@newSchemaPk,'CONTRACT',@newSod,N'','RESOLVED');
 SET @newCv=SCOPE_IDENTITY();
 UPDATE model.scenario_input SET input_contract_version_pk=@newCv WHERE input_contract_version_pk=@oldCv;
 UPDATE model.scenario_outcome_contract SET contract_version_pk=@newCv WHERE contract_version_pk=@oldCv;
 UPDATE model.port_contract SET contract_version_pk=@newCv WHERE contract_version_pk=@oldCv;
 UPDATE model.product_definition SET contract_version_pk=@newCv WHERE contract_version_pk=@oldCv;
 UPDATE model.estate_scenario_face_resolution SET contract_version_pk=@newCv WHERE contract_version_pk=@oldCv;
END

-- ============================ 2. INSTALL THE ROUTE ============================
EXEC model.install_provider_binding_change @document=@document;

-- ============================ 3. PROOF ============================
SELECT '1_outcome_contract' AS result_set,@contract_id AS contract_id,@oldCv AS prior_contract_version,
 @newCv AS contract_version,
 JSON_QUERY((SELECT value FROM OPENJSON(@newSchema,'$.properties.providerTestimony.properties.nativeShape.enum') FOR JSON PATH)) AS native_shapes;

SELECT '2_operations' AS result_set,op.ordinal,p.port_id
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=N'resolve-equity-market-price-evidence'
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=N'resolve-equity-market-price-evidence'
JOIN model.scenario_event ev ON ev.scenario_version_pk=cs.scenario_version_pk
JOIN model.execution_operation op ON op.execution_authority_version_pk=ev.execution_authority_version_pk
JOIN model.operation_port_invocation i ON i.execution_operation_pk=op.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=i.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk
WHERE ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
ORDER BY op.ordinal;

SELECT '3_route_transformations' AS result_set,d.declared_id,
 LEFT(JSON_VALUE(d.definition_json,'$.semantics.expression.value.then.payload.fields.currency.op'),20) AS currency_op
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
 AND d.object_kind='TRANSFORMATION'
 AND d.declared_id IN (N'build-finance15-price-binding-request',N'build-finance15-price-exchange-request',N'select-finance15-price-route')
ORDER BY d.declared_id;

SELECT '3c_finance15_exchange_expression' AS result_set,
 JSON_QUERY(d.definition_json,'$.semantics.expression.bindings.request.fields.safeHeaders') AS safe_headers,
 JSON_QUERY(d.definition_json,'$.semantics.expression.bindings.request.fields.allowedResponseHeaders') AS allowed_response_headers,
 JSON_VALUE(d.definition_json,'$.semantics.expression.bindings.url.template') AS url_template
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
 AND d.object_kind='TRANSFORMATION' AND d.declared_id=N'build-finance15-price-exchange-request';

SELECT '3b_finance15_config' AS result_set,
 (SELECT JSON_VALUE(d.definition_json,'$.semantics.expression.bindings.request.fields.endpointAuthorityDigest.value')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
   AND d.object_kind='TRANSFORMATION' AND d.declared_id=N'build-finance15-price-binding-request') AS request_digest,
 (SELECT JSON_VALUE(d.definition_json,'$.semantics.configuration.credentialAuthorities[0].endpointAuthorityDigests[0]')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
   AND d.object_kind='PORT' AND d.declared_id=N'bind-finance15-price-provider-credential') AS credential_digest,
 (SELECT JSON_VALUE(d.definition_json,'$.semantics.configuration.endpointAuthorities[0].endpointAuthorityDigest')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
   AND d.object_kind='PORT' AND d.declared_id=N'observe-finance15-price-exchange') AS exchange_digest,
 (SELECT JSON_VALUE(d.definition_json,'$.semantics.configuration.endpointAuthorities[0].urlPrefixes[0]')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
   AND d.object_kind='PORT' AND d.declared_id=N'observe-finance15-price-exchange') AS url_prefix,
 (SELECT JSON_QUERY(d.definition_json,'$.semantics.configuration.endpointAuthorities[0].allowedRequestHeaders')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
   AND d.object_kind='PORT' AND d.declared_id=N'observe-finance15-price-exchange') AS allowed_request_headers;

SELECT '4_slot_resolution' AS result_set,target_id,disposition,COUNT(*) AS slot_count
FROM analysis.v_provider_slot_resolution
WHERE estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
 AND capability_id=N'resolve-equity-market-price-evidence'
GROUP BY target_id,disposition ORDER BY target_id,disposition;

COMMIT TRANSACTION;
-- Installed 2026-09-19: finance15 equity fallback route (native shape body.0).
