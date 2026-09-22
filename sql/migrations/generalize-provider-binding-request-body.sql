-- generalize-provider-binding-request-body.sql
--
-- The provider-binding installer installs a declared request body.
--
-- model.install_provider_binding_change (installed, quote-guard revision) emits
-- `"requestBodyText":{"op":"literal","value":""}` for every route, so every
-- admitted exchange POSTs an empty body and a Gemini generateContent provider is
-- not expressible. This successor threads the change document's optional
-- `requestBodyExpression` into the exchange transformation verbatim:
--
--   * requestBodyExpression absent  -> the existing literal "" (byte-identical).
--   * requestBodyExpression present -> installed as requestBodyText; any JSON
--     expression object with an `op` is accepted, evaluated by the existing
--     semantic-transformation evaluator (object/array/literal/path/format/...).
--     A scalar or op-less expression is refused with
--     PROVIDER_CHANGE_REQUEST_BODY_EXPRESSION_INVALID.
--   * author-provider-configuration-change (the `provider set` preflight read)
--     accepts the same member, holds a malformed one with the same code, and
--     echoes it in the authored result as `requestBodyExpression`.
--
-- The successor is derived from the installed definitions by exact anchored
-- replacement; no installed file is edited and no new mechanic is introduced.
-- The delta is proven by undoing the replacements and byte-comparing with the
-- installed text. A replay reports already_applied without re-declaring.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=30000;
IF @lock<0 THROW 51002,N'PROVIDER_BODY_LOCK_FAILED',1;
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
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

-- ============================== 1. THE INSTALLER ==============================
DECLARE @installed nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'model.install_provider_binding_change')),CHAR(13),N'');
IF @installed IS NULL THROW 51002,N'PROVIDER_BODY_INSTALLER_ABSENT',1;
DECLARE @installer_state nvarchar(20)=CASE WHEN CHARINDEX(N'@request_body_expression',@installed)>0
 THEN N'already_applied' ELSE N'applied' END;
IF @installer_state=N'applied'
BEGIN
 DECLARE @disposition_anchor nvarchar(200)=N'EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED'');';
 DECLARE @vault_anchor nvarchar(200)=N'PROVIDER_CHANGE_VAULT_LOCATOR_REQUIRED'',1;';
 DECLARE @body_anchor nvarchar(200)=N'"requestBodyText":{"op":"literal","value":""}';
 IF (LEN(@installed)-LEN(REPLACE(@installed,@disposition_anchor,N'')))/LEN(@disposition_anchor)<>1
  OR (LEN(@installed)-LEN(REPLACE(@installed,@vault_anchor,N'')))/LEN(@vault_anchor)<>1
  OR (LEN(@installed)-LEN(REPLACE(@installed,@body_anchor,N'')))/LEN(@body_anchor)<>1
  THROW 51002,N'PROVIDER_BODY_INSTALLER_CHANGED_REPREPARE',1;
 -- The document read gains the declared expression; the vault check gains its
 -- refusal; the hardcoded literal becomes the declared expression with the
 -- existing literal as the absent default.
 DECLARE @body_decl nvarchar(400)=N' DECLARE @request_body_expression nvarchar(max)=JSON_QUERY(@document,''$.requestBodyExpression'');';
 DECLARE @body_validation nvarchar(2000)=
  N' IF @request_body_expression IS NULL AND JSON_VALUE(@document,''$.requestBodyExpression'') IS NOT NULL'+NCHAR(10)
 +N'  THROW 51002,''PROVIDER_CHANGE_REQUEST_BODY_EXPRESSION_INVALID'',1;'+NCHAR(10)
 +N' IF @request_body_expression IS NOT NULL'+NCHAR(10)
 +N'  AND (ISJSON(@request_body_expression)<>1 OR NULLIF(JSON_VALUE(@request_body_expression,''$.op''),N'''') IS NULL)'+NCHAR(10)
 +N'  THROW 51002,''PROVIDER_CHANGE_REQUEST_BODY_EXPRESSION_INVALID'',1;';
 DECLARE @body_replacement nvarchar(400)=N'"requestBodyText":''+ISNULL(@request_body_expression,N''{"op":"literal","value":""}'')+N''';
 DECLARE @patched nvarchar(max)=@installed;
 SET @patched=REPLACE(@patched,@disposition_anchor,@disposition_anchor+NCHAR(10)+@body_decl);
 SET @patched=REPLACE(@patched,@vault_anchor,@vault_anchor+NCHAR(10)+@body_validation);
 SET @patched=REPLACE(@patched,@body_anchor,@body_replacement);
 -- OBJECT_DEFINITION stores the header as CREATE <spaces> PROCEDURE, so restate
 -- the alterable header before executing the patched text.
 DECLARE @procedure_at int=CHARINDEX(N'PROCEDURE',@patched);
 IF @procedure_at=0 THROW 51002,N'PROVIDER_BODY_INSTALLER_HEADER_UNEXPECTED',1;
 SET @patched=N'CREATE OR ALTER '+SUBSTRING(@patched,@procedure_at,LEN(@patched));
 EXEC(@patched);
 DECLARE @repatch nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'model.install_provider_binding_change')),CHAR(13),N'');
 IF @repatch IS NULL OR CHARINDEX(N'@request_body_expression',@repatch)=0
  THROW 51002,N'PROVIDER_BODY_INSTALLER_PATCH_ABSENT',1;
 -- Undo the three replacements from the object name on (the stored header spacing
 -- is not part of the successor's delta): the result must be the installed body.
 DECLARE @installed_body nvarchar(max)=SUBSTRING(@installed,CHARINDEX(N'model.install_provider_binding_change',@installed),LEN(@installed));
 DECLARE @undo nvarchar(max)=SUBSTRING(@repatch,CHARINDEX(N'model.install_provider_binding_change',@repatch),LEN(@repatch));
 SET @undo=REPLACE(@undo,@disposition_anchor+NCHAR(10)+@body_decl,@disposition_anchor);
 SET @undo=REPLACE(@undo,@vault_anchor+NCHAR(10)+@body_validation,@vault_anchor);
 SET @undo=REPLACE(@undo,@body_replacement,@body_anchor);
 IF @undo COLLATE Latin1_General_100_BIN2<>@installed_body COLLATE Latin1_General_100_BIN2
  THROW 51002,N'PROVIDER_BODY_INSTALLER_DIVERGED',1;
END
-- ============================== 2. THE AUTHOR READ ==============================
DECLARE @old_statement nvarchar(max);
SELECT @old_statement=j.value
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') j
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.declared_id=N'author-provider-configuration-change-port' AND j.[key]=N'statement';
IF @old_statement IS NULL THROW 51002,N'PROVIDER_BODY_AUTHOR_READ_ABSENT',1;
DECLARE @read_state nvarchar(20)=CASE WHEN CHARINDEX(N'PROVIDER_CHANGE_REQUEST_BODY_EXPRESSION_INVALID',@old_statement)>0
 THEN N'already_applied' ELSE N'applied' END;
IF @read_state=N'applied'
BEGIN
 DECLARE @findings_anchor nvarchar(400)=N'DECLARE @findings_json nvarchar(max)=ISNULL((SELECT code,field,message FROM @findings ORDER BY ordinal FOR JSON PATH),N''[]'');';
 DECLARE @projection_anchor nvarchar(200)=N'JSON_QUERY(@findings_json) AS findings,';
 IF (LEN(@old_statement)-LEN(REPLACE(@old_statement,@findings_anchor,N'')))/LEN(@findings_anchor)<>1
  OR (LEN(@old_statement)-LEN(REPLACE(@old_statement,@projection_anchor,N'')))/LEN(@projection_anchor)<>1
  THROW 51002,N'PROVIDER_BODY_AUTHOR_READ_CHANGED_REPREPARE',1;
 DECLARE @read_validation nvarchar(max)=
  N'DECLARE @request_body_expression nvarchar(max)=JSON_QUERY(@change,''$.requestBodyExpression'');'+NCHAR(10)
 +N'IF @request_body_expression IS NULL AND JSON_VALUE(@change,''$.requestBodyExpression'') IS NOT NULL'+NCHAR(10)
 +N' INSERT @findings(code,field,message) VALUES(N''PROVIDER_CHANGE_REQUEST_BODY_EXPRESSION_INVALID'',N''requestBodyExpression'',N''the declared request body expression must be one JSON expression object with an op member'');'+NCHAR(10)
 +N'IF @request_body_expression IS NOT NULL AND (ISJSON(@request_body_expression)<>1 OR NULLIF(JSON_VALUE(@request_body_expression,''$.op''),N'''') IS NULL)'+NCHAR(10)
 +N' INSERT @findings(code,field,message) VALUES(N''PROVIDER_CHANGE_REQUEST_BODY_EXPRESSION_INVALID'',N''requestBodyExpression'',N''the declared request body expression must be one JSON expression object with an op member'');';
 DECLARE @echo_projection nvarchar(200)=N'JSON_QUERY(@findings_json) AS findings,JSON_QUERY(@request_body_expression) AS requestBodyExpression,';
 DECLARE @new_statement nvarchar(max)=REPLACE(@old_statement,@findings_anchor,@read_validation+NCHAR(10)+@findings_anchor);
 SET @new_statement=REPLACE(@new_statement,@projection_anchor,@echo_projection);
 -- Undo the two replacements: the result must be the installed statement, byte for byte.
 DECLARE @read_undo nvarchar(max)=@new_statement;
 SET @read_undo=REPLACE(@read_undo,@read_validation+NCHAR(10)+@findings_anchor,@findings_anchor);
 SET @read_undo=REPLACE(@read_undo,@echo_projection,@projection_anchor);
 IF @read_undo COLLATE Latin1_General_100_BIN2<>@old_statement COLLATE Latin1_General_100_BIN2
  THROW 51002,N'PROVIDER_BODY_AUTHOR_READ_DIVERGED',1;
 DECLARE @set_bindings nvarchar(max)=N'[{"portId":"author-provider-configuration-change-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'+STRING_ESCAPE(@new_statement,'json')+N'","resultColumn":"document"}}]';
 EXEC model.declare_scenario
  @capability_id=N'author-provider-configuration-change',
  @scenario=N'{"scenarioId":"author-provider-configuration-change","name":"Author and preflight one provider binding change","inputId":"provider-binding-change-request","inputContract":"provider-binding-change-request.v1","eventId":"provider-binding-change-requested","eventAuthority":"author-provider-configuration-change.v1","outcomeId":"provider-binding-change-result","outcomeContract":"provider-binding-change-result.v1","terminal":true,"root":true,"given":"one declared provider identity and one proposed binding change","when":"the change is resolved against the selected model, the declared outcome contract and the observed sample","then":"the declared change is authored with its endpoint content address, or the exact findings hold it"}',
  @operations=N'[{"operationId":"author-provider-configuration-change.0","kind":"invoke-port","portId":"author-provider-configuration-change-port"}]',
  @port_bindings=@set_bindings;
END
SELECT N'1_patch' AS result_set,@installer_state AS installer,@read_state AS author_read,
 LEN(OBJECT_DEFINITION(OBJECT_ID(N'model.install_provider_binding_change'))) AS installer_definition_chars;
GO
-- ============================== 3. PROOFS ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_before nvarchar(100);
SELECT TOP 1 @authority_before=LOWER(CONVERT(varchar(64),d.definition_digest,2))
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=N'sda-kernel-boot-data-access.v1'
 ORDER BY d.semantic_object_definition_pk DESC;

-- Unrelated capability graph digests, before any route install.
DECLARE @baseline TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64));
INSERT @baseline(capability_id,digest)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'route-two-child-proof',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'list-providers',1,NULL) g;
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51002,N'PROVIDER_BODY_BASELINE_MISSING',1;

-- The re-declared author read carries the accepting validation.
DECLARE @read_statement nvarchar(max);
SELECT @read_statement=j.value
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') j
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.declared_id=N'author-provider-configuration-change-port' AND j.[key]=N'statement';
IF @read_statement IS NULL OR CHARINDEX(N'PROVIDER_CHANGE_REQUEST_BODY_EXPRESSION_INVALID',@read_statement)=0
 OR CHARINDEX(N'AS requestBodyExpression',@read_statement)=0
 THROW 51002,N'PROVIDER_BODY_AUTHOR_READ_NOT_REVISED',1;

-- The declared Gemini generateContent body: the invocation objective wrapped in
-- the provider payload, built from the existing projection vocabulary.
DECLARE @gemini_body nvarchar(max)=N'{"op":"object","fields":{"contents":{"op":"array","items":[{"op":"object","fields":{"role":{"op":"literal","value":"user"},"parts":{"op":"array","items":[{"op":"object","fields":{"text":{"op":"path","from":"root","path":"payload.objective"}}}]}}}]},"generationConfig":{"op":"object","fields":{"maxOutputTokens":{"op":"literal","value":1024}}}}}';
DECLARE @gemini_change nvarchar(max)=N'{"contractId":"provider-binding-change.v1","providerId":"google/gemini","capabilityId":"resolve-equity-market-price-evidence","outcomeContractId":"equity-market-price-evidence.v1","bindingId":"gemini-generate-content.v1","route":{"routeId":"gemini","resolvedDisposition":"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"},"endpoint":{"host":"generativelanguage.googleapis.com","method":"POST","pathPrefix":"/v1beta/models/gemini-2.5-flash:generateContent?","requestTemplate":"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent","safeHeaders":{"content-type":"application/json"},"allowedResponseHeaders":["content-type"],"timeoutMilliseconds":30000,"maxResponseBytes":262144},"credential":{"referenceName":"LOC_GEMINI_API_KEY","injectionRuleId":"gemini-x-goog-api-key.v1","headerName":"x-goog-api-key","source":"vault","storeLocator":"%LOCALAPPDATA%\\sfx\\vault","lifetimeMilliseconds":30000},"effectScope":"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY","nativeShape":"candidates.0.content.parts.0.text","mapping":{"symbol":"request:payload.symbol","region":"request:payload.region","currency":"request:payload.currency","observedPrice":"request:payload.observedPrice","observedMarketTime":"request:payload.observedMarketTime","marketState":"request:payload.marketState","exchange":"request:payload.exchange","sourceAttribution":"request:payload.sourceAttribution"},"observedSample":{},"requestBodyExpression":'+@gemini_body+N',"preflight":{"input":{"contractId":"live-equity-price-request.v1","payload":{"symbol":"AVGO","region":"US"}}},"verify":{"capabilityId":"resolve-equity-market-price-evidence","input":{"contractId":"live-equity-price-request.v1","payload":{"symbol":"AVGO","region":"US"}}}}';
IF ISJSON(@gemini_change)<>1 THROW 51002,N'PROVIDER_BODY_GEMINI_DOCUMENT_INVALID',1;

-- The declared provider identity the author read resolves.
IF NOT EXISTS (SELECT 1 FROM model.provider p JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
 WHERE n.namespace_id=N'sidefx:providers' AND p.provider_id=N'google/gemini')
 EXEC model.add_provider @provider_id=N'google/gemini',@name=N'Google Gemini',
  @operations_json=N'[{"operationId":"generateContent","method":"POST"}]';

-- The author read accepts the declared expression and carries it authored.
DECLARE @gemini_input nvarchar(max)=N'{"providerId":"google/gemini","input":'+@gemini_change+N'}';
DECLARE @authored TABLE(document nvarchar(max));
INSERT @authored EXEC sp_executesql @read_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@gemini_input,@estate_model_pk=@estate;
DECLARE @authored_disposition nvarchar(40)=(SELECT TOP 1 JSON_VALUE(document,'$.disposition') FROM @authored);
DECLARE @authored_change_text nvarchar(max);
SELECT TOP 1 @authored_change_text=j.value FROM @authored CROSS APPLY OPENJSON(document) j WHERE j.[key]=N'change';
DECLARE @authored_carried nvarchar(20)=CASE WHEN
 (JSON_QUERY(@authored_change_text,'$.requestBodyExpression') COLLATE Latin1_General_100_BIN2)=(@gemini_body COLLATE Latin1_General_100_BIN2)
 THEN N'CARRIED' ELSE N'DIVERGED' END;
DECLARE @authored_echo nvarchar(20)=(SELECT TOP 1 CASE WHEN
 (JSON_QUERY(document,'$.requestBodyExpression') COLLATE Latin1_General_100_BIN2)=(@gemini_body COLLATE Latin1_General_100_BIN2)
 THEN N'ECHOED' ELSE N'DIVERGED' END FROM @authored);
DECLARE @author_failure nvarchar(2048)=N'PROVIDER_BODY_AUTHOR_READ_REJECTED_DECLARED_BODY disposition='
 +ISNULL(@authored_disposition,N'(null)')+N' carried='+ISNULL(@authored_carried,N'(null)')
 +N' echo='+ISNULL(@authored_echo,N'(null)')+N' findings='
 +ISNULL((SELECT TOP 1 CONVERT(nvarchar(400),JSON_QUERY(document,'$.findings')) FROM @authored),N'(null)')
 +N' change_chars='+CONVERT(nvarchar(20),LEN(@authored_change_text))
 +N' carried_body='+ISNULL(CONVERT(nvarchar(400),JSON_QUERY(@authored_change_text,'$.requestBodyExpression')),N'(null)');
IF @authored_disposition<>N'PROVIDER_CHANGE_AUTHORED' OR @authored_carried<>N'CARRIED' OR @authored_echo<>N'ECHOED'
 THROW 51002,@author_failure,1;
SELECT N'2_author_gemini' AS result_set,@authored_disposition AS disposition,@authored_carried AS change_carried,
 @authored_echo AS result_echo,(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY((SELECT TOP 1 document FROM @authored),'$.findings'))) AS findings;

-- The author read holds a malformed declared expression.
DECLARE @bad_body_change nvarchar(max)=REPLACE(@gemini_change,N'"requestBodyExpression":'+@gemini_body,N'"requestBodyExpression":"not-an-expression"');
IF @bad_body_change=@gemini_change COLLATE Latin1_General_100_BIN2 THROW 51002,N'PROVIDER_BODY_BAD_DOC_UNPATCHED',1;
DECLARE @bad_input nvarchar(max)=N'{"providerId":"google/gemini","input":'+@bad_body_change+N'}';
DELETE FROM @authored;
INSERT @authored EXEC sp_executesql @read_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@bad_input,@estate_model_pk=@estate;
DECLARE @bad_disposition nvarchar(40)=(SELECT TOP 1 JSON_VALUE(document,'$.disposition') FROM @authored);
DECLARE @bad_code nvarchar(100)=(SELECT TOP 1 JSON_VALUE(f.value,'$.code') FROM @authored
 CROSS APPLY OPENJSON(JSON_QUERY(document,'$.findings')) f
 WHERE JSON_VALUE(f.value,'$.code')=N'PROVIDER_CHANGE_REQUEST_BODY_EXPRESSION_INVALID');
IF @bad_disposition<>N'PROVIDER_CHANGE_HELD' OR @bad_code IS NULL
 THROW 51002,N'PROVIDER_BODY_AUTHOR_READ_DID_NOT_HOLD_MALFORMED_BODY',1;
SELECT N'3_author_bad_body' AS result_set,@bad_disposition AS disposition,@bad_code AS finding_code;
-- The default path: the exact installed finance15 document through the successor
-- with one new route id generates the installed route's exchange expression byte
-- for byte, and its request body is the existing empty literal.
DECLARE @finance15_change nvarchar(max)=N'{"contractId":"provider-binding-change.v1","providerId":"rapidapi/yahoo-finance15","capabilityId":"resolve-equity-market-price-evidence","outcomeContractId":"equity-market-price-evidence.v1","bindingId":"rapidapi-yahoo-finance15-stock-quotes.v1","route":{"routeId":"finance15","resolvedDisposition":"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"},"endpoint":{"host":"yahoo-finance15.p.rapidapi.com","method":"GET","pathPrefix":"/api/v1/markets/stock/quotes?","requestTemplate":"https://yahoo-finance15.p.rapidapi.com/api/v1/markets/stock/quotes?ticker={symbol}","safeHeaders":{"x-rapidapi-host":"yahoo-finance15.p.rapidapi.com"},"allowedResponseHeaders":["content-type","retry-after"],"timeoutMilliseconds":15000,"maxResponseBytes":262144},"credential":{"referenceName":"RAPID_API_KEY","injectionRuleId":"rapidapi-x-rapidapi-key.v1","headerName":"X-RapidAPI-Key","source":"vault","storeLocator":"%LOCALAPPDATA%\\sfx\\vault","lifetimeMilliseconds":15000},"effectScope":"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY","nativeShape":"body.0","mapping":{"symbol":"body.0.symbol","region":"request:payload.region","currency":"body.0.currency","observedPrice":"body.0.regularMarketPrice","observedMarketTime":"body.0.regularMarketTime","marketState":"body.0.marketState","exchange":"body.0.exchange","sourceAttribution":"body.0.quoteSourceName"},"observedSample":{"meta":{"version":"v1.0","status":200,"symbol":"AVGO","processedTime":"2026-09-19T22:17:19.370804Z"},"body":[{"language":"en-US","region":"US","quoteType":"EQUITY","quoteSourceName":"Nasdaq Real Time Price","currency":"USD","regularMarketPrice":357.61,"marketState":"CLOSED","regularMarketTime":1789761602,"exchange":"NMS","symbol":"AVGO"}]},"preflight":{"input":{"contractId":"live-equity-price-request.v1","payload":{"symbol":"AVGO","region":"US"}}},"verify":{"capabilityId":"resolve-equity-market-price-evidence","input":{"contractId":"live-equity-price-request.v1","payload":{"symbol":"AVGO","region":"US"}}}}';
IF ISJSON(@finance15_change)<>1 THROW 51002,N'PROVIDER_BODY_FINANCE15_DOCUMENT_INVALID',1;
DECLARE @installed_expression nvarchar(max);
SELECT TOP 1 @installed_expression=JSON_QUERY(d.definition_json,'$.semantics.expression')
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='TRANSFORMATION' AND d.declared_id=N'build-finance15-price-exchange-request'
ORDER BY d.semantic_object_definition_pk DESC;
IF @installed_expression IS NULL THROW 51002,N'PROVIDER_BODY_FINANCE15_EXPRESSION_ABSENT',1;
DECLARE @finance15_bodyproof nvarchar(max)=REPLACE(@finance15_change,N'"routeId":"finance15"',N'"routeId":"finance15bodyproof"');
IF @finance15_bodyproof=@finance15_change COLLATE Latin1_General_100_BIN2 THROW 51002,N'PROVIDER_BODY_FINANCE15_DOC_UNPATCHED',1;
EXEC model.install_provider_binding_change @document=@finance15_bodyproof;
DECLARE @proof_expression nvarchar(max),@proof_body nvarchar(max);
SELECT TOP 1 @proof_expression=JSON_QUERY(d.definition_json,'$.semantics.expression'),
 @proof_body=JSON_QUERY(d.definition_json,'$.semantics.expression.bindings.request.fields.requestBodyText')
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='TRANSFORMATION' AND d.declared_id=N'build-finance15bodyproof-price-exchange-request'
ORDER BY d.semantic_object_definition_pk DESC;
IF @proof_expression IS NULL OR @proof_expression COLLATE Latin1_General_100_BIN2<>@installed_expression COLLATE Latin1_General_100_BIN2
 THROW 51002,N'PROVIDER_BODY_DEFAULT_EXPRESSION_DIVERGED',1;
IF @proof_body IS NULL OR @proof_body COLLATE Latin1_General_100_BIN2<>N'{"op":"literal","value":""}' COLLATE Latin1_General_100_BIN2
 THROW 51002,N'PROVIDER_BODY_DEFAULT_NOT_EMPTY_LITERAL',1;
SELECT N'4_default_identity' AS result_set,N'IDENTICAL' AS expression,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(nvarchar(max),@proof_expression) COLLATE Latin1_General_100_BIN2_UTF8)),2)) AS expression_digest,
 @proof_body AS request_body_text;

-- The exact finance15 document through the successor: already_installed, no write.
DECLARE @versions_before int=(SELECT COUNT(*) FROM model.transformation_version);
EXEC model.install_provider_binding_change @document=@finance15_change;
IF (SELECT COUNT(*) FROM model.transformation_version)<>@versions_before
 THROW 51002,N'PROVIDER_BODY_FINANCE15_REPLAY_WROTE',1;

-- The Gemini route installs, and its exchange transformation carries the
-- declared wrapped body, not the empty literal.
EXEC model.install_provider_binding_change @document=@gemini_change;
DECLARE @gemini_body_stored nvarchar(max),@gemini_expression nvarchar(max);
SELECT TOP 1 @gemini_body_stored=JSON_QUERY(d.definition_json,'$.semantics.expression.bindings.request.fields.requestBodyText'),
 @gemini_expression=JSON_QUERY(d.definition_json,'$.semantics.expression')
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='TRANSFORMATION' AND d.declared_id=N'build-gemini-price-exchange-request'
ORDER BY d.semantic_object_definition_pk DESC;
IF @gemini_body_stored IS NULL OR @gemini_body_stored COLLATE Latin1_General_100_BIN2<>@gemini_body COLLATE Latin1_General_100_BIN2
 THROW 51002,N'PROVIDER_BODY_GEMINI_BODY_DIVERGED',1;
IF @gemini_body_stored COLLATE Latin1_General_100_BIN2=N'{"op":"literal","value":""}' COLLATE Latin1_General_100_BIN2
 THROW 51002,N'PROVIDER_BODY_GEMINI_BODY_STILL_EMPTY',1;
SELECT N'5_gemini_body' AS result_set,N'WRAPPED' AS disposition,@gemini_body_stored AS request_body_text,
 (SELECT COUNT(*) FROM model.transformation_expression_node n
  JOIN model.transformation_version tv ON tv.transformation_version_pk=n.transformation_version_pk
  JOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=tv.semantic_object_definition_pk
  WHERE d.estate_model_pk=@estate AND d.declared_id=N'build-gemini-price-exchange-request') AS normalized_nodes;
-- ============================== 4. REFUSALS ==============================
-- Caught THROWs keep the transaction usable (XACT_ABORT off, the in-house probe
-- pattern); refused documents write nothing.
SET XACT_ABORT OFF;
DECLARE @refusal_base nvarchar(max)=REPLACE(@gemini_change,N'"routeId":"gemini"',N'"routeId":"refusalproof"');
DECLARE @refusals TABLE(ordinal int IDENTITY(1,1),label nvarchar(100),document nvarchar(max),expected nvarchar(100));
INSERT @refusals(label,document,expected) VALUES
 (N'document_invalid',N'not json',N'PROVIDER_CHANGE_DOCUMENT_INVALID'),
 (N'fields_required',N'{}',N'PROVIDER_CHANGE_FIELDS_REQUIRED'),
 (N'vault_locator',REPLACE(@refusal_base,N'"storeLocator":"%LOCALAPPDATA%\\sfx\\vault",',N''),N'PROVIDER_CHANGE_VAULT_LOCATOR_REQUIRED'),
 (N'mapping_empty',JSON_MODIFY(@refusal_base,'$.mapping',JSON_QUERY(N'{}')),N'PROVIDER_CHANGE_MAPPING_EMPTY'),
 (N'mapping_path',JSON_MODIFY(@refusal_base,'$.mapping.symbol',N'nonsense'),N'PROVIDER_CHANGE_MAPPING_PATH_UNRESOLVED'),
 (N'body_scalar',REPLACE(@refusal_base,N'"requestBodyExpression":'+@gemini_body,N'"requestBodyExpression":"not-an-expression"'),N'PROVIDER_CHANGE_REQUEST_BODY_EXPRESSION_INVALID'),
 (N'body_no_op',REPLACE(@refusal_base,N'"requestBodyExpression":'+@gemini_body,N'"requestBodyExpression":{"fields":{}}'),N'PROVIDER_CHANGE_REQUEST_BODY_EXPRESSION_INVALID');
DECLARE @refusal_label nvarchar(100),@refusal_document nvarchar(max),@refusal_expected nvarchar(100),@refusal_actual nvarchar(400);
DECLARE @observed TABLE(ordinal int IDENTITY(1,1),label nvarchar(100),expected nvarchar(100),actual nvarchar(400),disposition nvarchar(10));
DECLARE refusal_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT label,document,expected FROM @refusals ORDER BY ordinal;
OPEN refusal_cursor;
FETCH NEXT FROM refusal_cursor INTO @refusal_label,@refusal_document,@refusal_expected;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @refusal_actual=NULL;
 BEGIN TRY
  EXEC model.install_provider_binding_change @document=@refusal_document;
 END TRY
 BEGIN CATCH SET @refusal_actual=ERROR_MESSAGE(); END CATCH
 INSERT @observed(label,expected,actual,disposition)
 VALUES(@refusal_label,@refusal_expected,@refusal_actual,
  CASE WHEN @refusal_actual LIKE N'%'+@refusal_expected+N'%' THEN N'PASS' ELSE N'FAIL' END);
 FETCH NEXT FROM refusal_cursor INTO @refusal_label,@refusal_document,@refusal_expected;
END
CLOSE refusal_cursor; DEALLOCATE refusal_cursor;
SELECT N'6_refusals' AS result_set,label,expected,actual,disposition FROM @observed ORDER BY ordinal;
IF EXISTS(SELECT 1 FROM @observed WHERE disposition=N'FAIL') THROW 51002,N'PROVIDER_BODY_REFUSAL_PROBES_FAILED',1;

-- ============================== 5. UNRELATED DIGESTS ==============================
SET XACT_ABORT ON;
DECLARE @after TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64));
INSERT @after(capability_id,digest)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'route-two-child-proof',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'list-providers',1,NULL) g;
SELECT N'7_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51002,N'PROVIDER_BODY_CHANGED_UNRELATED_CAPABILITY',1;
DECLARE @authority_after nvarchar(100);
SELECT TOP 1 @authority_after=LOWER(CONVERT(varchar(64),d.definition_digest,2))
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=N'sda-kernel-boot-data-access.v1'
 ORDER BY d.semantic_object_definition_pk DESC;
SELECT N'8_authority_digest' AS result_set,@authority_before AS before_digest,@authority_after AS after_digest,
 CASE WHEN @authority_before=@authority_after THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition;
IF @authority_before<>@authority_after THROW 51002,N'PROVIDER_BODY_CHANGED_BOOT_AUTHORITY',1;

ROLLBACK TRANSACTION;
-- Dry-run complete. The install is the .commit.sql copy.
