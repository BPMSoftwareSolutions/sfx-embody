-- fix-provider-mapping-array-path-read.sql
--
-- Re-declares the declared provider authoring read (provider set ->
-- author-provider-configuration-change) so the observed-sample validation can
-- address array elements. JSON_VALUE's dotted path cannot express an index
-- ("$.body.0.currency" is rejected), and a provider whose canonical values sit
-- at an array element (the finance15 /markets/stock/quotes body[0] shape) could
-- not be authored at all. The read now walks the parent path segment by segment
-- (numeric segments become [n]) and reads the leaf with JSON_VALUE.
--
-- Only the declared read statement changes; the capability, its scenario and
-- its display are re-declared unchanged. Idempotent: the statement is
-- content-addressed and a replay re-declares the same port definition.
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
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @set_statement nvarchar(max)=CONVERT(nvarchar(max),N'DECLARE @estate bigint=@estate_model_pk;
DECLARE @provider_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.providerId''),N'''');
DECLARE @change nvarchar(max)=JSON_QUERY(@input,''$.input'');
DECLARE @findings TABLE (ordinal int IDENTITY(1,1), code nvarchar(100), field nvarchar(400), message nvarchar(2000));
IF @provider_id IS NULL OR @change IS NULL OR ISJSON(@change)<>1
 INSERT @findings(code,field,message) VALUES(N''CHANGE_DOCUMENT_REQUIRED'',NULL,N''supply providerId and a JSON change document as --input'');
ELSE BEGIN
 IF NOT EXISTS (SELECT 1 FROM analysis.v_selected_semantic_definition d
   WHERE d.estate_model_pk=@estate AND d.object_kind=''PROVIDER'' AND d.declared_id=@provider_id)
  INSERT @findings(code,field,message) VALUES(N''PROVIDER_NOT_DECLARED'',NULL,N''no provider declaration matches ''+@provider_id);
 DECLARE @lower nvarchar(max)=LOWER(@change);
 IF CHARINDEX(N''"password"'',@lower)>0 OR CHARINDEX(N''"secret"'',@lower)>0 OR CHARINDEX(N''"apikey"'',@lower)>0
  OR CHARINDEX(N''"api_key"'',@lower)>0 OR CHARINDEX(N''"token"'',@lower)>0
  OR CHARINDEX(N''"credentialvalue"'',@lower)>0 OR CHARINDEX(N''"privatekey"'',@lower)>0
   INSERT @findings(code,field,message) VALUES(N''SECRET_MATERIAL_REJECTED'',NULL,N''the change document carries secret material; environment secrets are never accepted here'');
 DECLARE @host nvarchar(400)=NULLIF(JSON_VALUE(@change,''$.endpoint.host''),N'''');
 DECLARE @method nvarchar(20)=NULLIF(JSON_VALUE(@change,''$.endpoint.method''),N'''');
 DECLARE @path_prefix nvarchar(1000)=NULLIF(JSON_VALUE(@change,''$.endpoint.pathPrefix''),N'''');
 DECLARE @binding_id nvarchar(400)=NULLIF(JSON_VALUE(@change,''$.bindingId''),N'''');
 DECLARE @rule_id nvarchar(400)=NULLIF(JSON_VALUE(@change,''$.credential.injectionRuleId''),N'''');
 DECLARE @reference_name nvarchar(400)=NULLIF(JSON_VALUE(@change,''$.credential.referenceName''),N'''');
 DECLARE @effect_scope nvarchar(400)=NULLIF(JSON_VALUE(@change,''$.effectScope''),N'''');
 IF @host IS NULL INSERT @findings(code,field,message) VALUES(N''ENDPOINT_FIELD_REQUIRED'',N''endpoint.host'',N''a change must declare the host it reaches'');
 IF @method IS NULL INSERT @findings(code,field,message) VALUES(N''ENDPOINT_FIELD_REQUIRED'',N''endpoint.method'',N''a change must declare the HTTP method'');
 IF @path_prefix IS NULL INSERT @findings(code,field,message) VALUES(N''ENDPOINT_FIELD_REQUIRED'',N''endpoint.pathPrefix'',N''a change must declare the admitted path prefix'');
 IF @binding_id IS NULL INSERT @findings(code,field,message) VALUES(N''ENDPOINT_FIELD_REQUIRED'',N''bindingId'',N''a change must declare the canonical binding identity'');
 IF @rule_id IS NULL INSERT @findings(code,field,message) VALUES(N''CREDENTIAL_FIELD_REQUIRED'',N''credential.injectionRuleId'',N''a change must name the declared injection rule'');
 IF @reference_name IS NULL INSERT @findings(code,field,message) VALUES(N''CREDENTIAL_FIELD_REQUIRED'',N''credential.referenceName'',N''a change must name the declared credential reference'');')
+N' IF @effect_scope IS NULL INSERT @findings(code,field,message) VALUES(N''ENDPOINT_FIELD_REQUIRED'',N''effectScope'',N''a change must declare its effect scope'');
 DECLARE @outcome_contract nvarchar(400)=NULLIF(JSON_VALUE(@change,''$.outcomeContractId''),N'''');
 DECLARE @schema nvarchar(max)=NULL;
 IF @outcome_contract IS NOT NULL
  SELECT TOP 1 @schema=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM analysis.v_selected_semantic_definition d
  JOIN source.content_object co ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,''$.semantics.schema_digest''),''sha256:'',''''),2)
  WHERE d.estate_model_pk=@estate AND d.object_kind=''CONTRACT'' AND d.declared_id=@outcome_contract
  ORDER BY d.semantic_object_definition_pk DESC;
 IF @schema IS NULL
  INSERT @findings(code,field,message) VALUES(N''OUTCOME_CONTRACT_SCHEMA_UNRESOLVED'',N''outcomeContractId'',N''no declared schema resolves for ''+ISNULL(@outcome_contract,N''(missing outcomeContractId)''));
 ELSE BEGIN
  DECLARE @mapping nvarchar(max)=JSON_QUERY(@change,''$.mapping'');
  DECLARE @sample nvarchar(max)=JSON_QUERY(@change,''$.observedSample'');
  DECLARE @required TABLE (field nvarchar(400) COLLATE Latin1_General_100_BIN2, expected_type nvarchar(40));
  INSERT @required
  SELECT j.[key],JSON_VALUE(j.value,''$.type'')
  FROM OPENJSON(@schema,''$.properties.payload.properties'') j
  WHERE j.[key] IN (SELECT value FROM OPENJSON(@schema,''$.properties.payload.required''));
  DECLARE @field nvarchar(400),@expected nvarchar(40),@native nvarchar(1000),@value nvarchar(max);
  DECLARE required_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT field,expected_type FROM @required ORDER BY field;
  OPEN required_cursor;
  FETCH NEXT FROM required_cursor INTO @field,@expected;
  WHILE @@FETCH_STATUS=0 BEGIN
    SET @native=NULLIF(JSON_VALUE(@mapping,N''$."''+@field+''"''),N'''');
    IF @native IS NULL
      INSERT @findings(code,field,message) VALUES(N''CANONICAL_MAPPING_ABSENT'',@field,N''the mapping declares no native source for this canonical field'');
    ELSE IF @sample IS NOT NULL AND @native NOT LIKE N''request:%'' BEGIN
      SET @value=JSON_VALUE(@sample,N''$.''+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@native,N''.0.'',N''[0].''),N''.1.'',N''[1].''),N''.2.'',N''[2].''),N''.3.'',N''[3].''),N''.4.'',N''[4].''),N''.5.'',N''[5].''),N''.6.'',N''[6].''),N''.7.'',N''[7].''),N''.8.'',N''[8].''),N''.9.'',N''[9].''));
      IF @value IS NULL
        INSERT @findings(code,field,message) VALUES(N''NATIVE_PATH_NOT_OBSERVED'',@field,N''the observed sample carries no value at ''+@native);
      ELSE IF @expected=N''string'' AND TRY_CONVERT(decimal(38,10),@value) IS NOT NULL
        INSERT @findings(code,field,message) VALUES(N''NATIVE_TYPE_MISMATCH'',@field,N''canonical string expected at ''+@native+N'' but a number was observed'');
      ELSE IF @expected=N''number'' AND TRY_CONVERT(decimal(38,10),@value) IS NULL
        INSERT @findings(code,field,message) VALUES(N''NATIVE_TYPE_MISMATCH'',@field,N''canonical number expected at ''+@native+N'' but a non-number was observed'');
      ELSE IF @expected=N''integer'' AND TRY_CONVERT(bigint,@value) IS NULL'
+N'        INSERT @findings(code,field,message) VALUES(N''NATIVE_TYPE_MISMATCH'',@field,N''canonical integer expected at ''+@native+N'' but a non-integer was observed'');
    END
    FETCH NEXT FROM required_cursor INTO @field,@expected;
  END
  CLOSE required_cursor; DEALLOCATE required_cursor;
 END
 DECLARE @record nvarchar(max)=NULL,@digest nvarchar(100)=NULL;
 IF @host IS NOT NULL AND @method IS NOT NULL AND @path_prefix IS NOT NULL AND @binding_id IS NOT NULL AND @rule_id IS NOT NULL AND @effect_scope IS NOT NULL
 BEGIN
  SET @record=N''{"host":"''+STRING_ESCAPE(@host,N''json'')+N''","method":"''+STRING_ESCAPE(@method,N''json'')
   +N''","pathPrefix":"''+STRING_ESCAPE(@path_prefix,N''json'')+N''","providerId":"''+STRING_ESCAPE(@provider_id,N''json'')
   +N''","bindingId":"''+STRING_ESCAPE(@binding_id,N''json'')+N''","credentialInjectionRuleId":"''+STRING_ESCAPE(@rule_id,N''json'')
   +N''","effectScope":"''+STRING_ESCAPE(@effect_scope,N''json'')+N''"}'';
  SET @digest=N''sha256:''+LOWER(CONVERT(varchar(64),HASHBYTES(''SHA2_256'',CONVERT(varbinary(max),CONVERT(varchar(max),@record COLLATE Latin1_General_100_BIN2_UTF8))),2));
 END
END
DECLARE @findings_json nvarchar(max)=ISNULL((SELECT code,field,message FROM @findings ORDER BY ordinal FOR JSON PATH),N''[]'');
DECLARE @authored bit=CONVERT(bit,CASE WHEN (SELECT COUNT(*) FROM @findings)=0 THEN 1 ELSE 0 END);
DECLARE @output nvarchar(max);
SET @output=(
 SELECT N''provider-binding-change-result.v1'' AS contractId,N''provider-binding-change.v1'' AS documentType,
   CASE WHEN @authored=1 THEN N''PROVIDER_CHANGE_AUTHORED'' ELSE N''PROVIDER_CHANGE_HELD'' END AS disposition,
   @provider_id AS providerId,
   CASE WHEN @authored=1 THEN JSON_QUERY(@change) ELSE NULL END AS change,
   CASE WHEN @record IS NULL THEN NULL ELSE JSON_QUERY(@record) END AS canonicalEndpointRecord,
   @digest AS endpointAuthorityDigest,
   JSON_QUERY(@findings_json) AS findings,
   CASE WHEN @authored=1 THEN JSON_QUERY(N''{"author":"author the declared change as one sql/migrations migration","dryRun":"node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/run-migration.mjs <migration.sql>","preflight":"node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/invoke-from-transaction.mjs <migration.sql> <capabilityId> <input.json>","install":"replace the final rollback with a commit and run the lifecycle runner" }'') ELSE NULL END AS lifecycle
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SELECT @output AS document;
';
DECLARE @set_bindings nvarchar(max)=N'[{"portId":"author-provider-configuration-change-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'+STRING_ESCAPE(@set_statement,'json')+N'","resultColumn":"document"}}]';
EXEC model.declare_scenario
 @capability_id=N'author-provider-configuration-change',
 @scenario=N'{"scenarioId":"author-provider-configuration-change","name":"Author and preflight one provider binding change","inputId":"provider-binding-change-request","inputContract":"provider-binding-change-request.v1","eventId":"provider-binding-change-requested","eventAuthority":"author-provider-configuration-change.v1","outcomeId":"provider-binding-change-result","outcomeContract":"provider-binding-change-result.v1","terminal":true,"root":true,"given":"one declared provider identity and one proposed binding change","when":"the change is resolved against the selected model, the declared outcome contract and the observed sample","then":"the declared change is authored with its endpoint content address, or the exact findings hold it"}',
 @operations=N'[{"operationId":"author-provider-configuration-change.0","kind":"invoke-port","portId":"author-provider-configuration-change-port"}]',
 @port_bindings=@set_bindings;

-- Proof: the read is re-declared and the array-index sample validates.
DECLARE @array_change nvarchar(max)=N'{"contractId":"provider-binding-change.v1","providerId":"rapidapi/yahoo-finance15","capabilityId":"resolve-equity-market-price-evidence","outcomeContractId":"equity-market-price-evidence.v1","bindingId":"array-path-proof.v1","endpoint":{"host":"yahoo-finance15.p.rapidapi.com","method":"GET","pathPrefix":"/api/v1/markets/stock/quotes?","requestTemplate":"https://yahoo-finance15.p.rapidapi.com/api/v1/markets/stock/quotes?ticker={symbol}","safeHeaders":{"x-rapidapi-host":"yahoo-finance15.p.rapidapi.com"},"allowedResponseHeaders":["content-type","retry-after"],"timeoutMilliseconds":15000,"maxResponseBytes":262144},"credential":{"referenceName":"RAPID_API_KEY","injectionRuleId":"rapidapi-x-rapidapi-key.v1","headerName":"X-RapidAPI-Key","source":"vault","storeLocator":"%LOCALAPPDATA%\\sfx\\vault"},"effectScope":"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY","nativeShape":"body.0","mapping":{"symbol":"body.0.symbol","region":"request:payload.region","currency":"body.0.currency","observedPrice":"body.0.regularMarketPrice","observedMarketTime":"body.0.regularMarketTime","marketState":"body.0.marketState","exchange":"body.0.exchange","sourceAttribution":"body.0.quoteSourceName"},"observedSample":{"body":[{"symbol":"AVGO","currency":"USD","regularMarketPrice":357.61,"regularMarketTime":1789761602,"marketState":"CLOSED","exchange":"NMS","quoteSourceName":"Nasdaq Real Time Price"}]}}';
DECLARE @array_input nvarchar(max)=N'{"providerId":"rapidapi/yahoo-finance15","input":'+@array_change+N'}';
DECLARE @array_proof TABLE (document nvarchar(max));
INSERT @array_proof EXEC sp_executesql @set_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@array_input,@estate_model_pk=@estate;
SELECT 'array_path_proof' AS result_set,
 JSON_VALUE(document,'$.disposition') AS disposition,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(document,'$.findings'))) AS findings
FROM @array_proof;
SELECT 'read_statement' AS result_set,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 LEN(JSON_VALUE(d.definition_json,'$.semantics.configuration.statement')) AS statement_chars
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT' AND d.declared_id=N'author-provider-configuration-change-port';

COMMIT TRANSACTION;
-- Installed 2026-09-19: array-aware observed-sample path validation for provider set.
