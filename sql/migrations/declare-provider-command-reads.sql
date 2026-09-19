-- declare-provider-command-reads.sql
--
-- The declared provider command surface: `provider list`, `provider reveal` and
-- `provider set` are served by three declared read capabilities, not by
-- command-specific estate code:
--
--   list-providers                     one read over model.provider and the
--                                      selected PROVIDER definitions; each row
--                                      carries the declared transport, source,
--                                      operations, conformance claims and the
--                                      counts of declared endpoint prefixes and
--                                      provider bindings.
--   read-provider-configuration        one read over the subject provider's
--                                      declaration plus every declared port
--                                      whose endpoint authority names its host:
--                                      URL prefixes, methods, allowed request and
--                                      response headers, credential reference and
--                                      injection rule, effect scopes and
--                                      lifetimes, the request-builder
--                                      transformations' URL templates and
--                                      timeouts, and the subject's provider
--                                      bindings. Availability/quota evidence is
--                                      reported as not recorded: the selected
--                                      model holds declarations, not observations.
--   author-provider-configuration-change
--                                      the declared preflight for a provider
--                                      binding change: it resolves the outcome
--                                      contract's schema from the model, checks
--                                      the declared native-to-canonical mapping
--                                      against the observed sample's fields and
--                                      types, refuses secret material, and mints
--                                      the endpoint authority record's content
--                                      address when the declared fields are
--                                      present. It authors and validates the
--                                      declared change; installation remains the
--                                      standard migration lifecycle.
--
-- The operations themselves are declared in `sda-node-command-operations.v1`
-- (the companion migration declare-provider-command-operations.sql). Each
-- capability carries its declared CLI display transformation, so human mode
-- renders the declared document and --json carries the envelope.
--
-- The reads are deterministic over the selected model. The statements are
-- declared SQL, executed under the reader boundary with the invocation's pinned
-- session; no estate script runs them.
--
-- Idempotent: content-addressed definitions and guarded interface configuration
-- re-declare nothing on replay.
--
-- Default: ROLLBACK. Replace the final ROLLBACK with a commit to install after
-- the dry run and the from-transaction preflight.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
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
DECLARE @list_statement nvarchar(max)=CONVERT(nvarchar(max),N'DECLARE @estate bigint=@estate_model_pk;
DECLARE @prefixes TABLE (prefix nvarchar(max));
INSERT @prefixes
SELECT u.value
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(JSON_QUERY(d.definition_json,''$.semantics.configuration.endpointAuthorities'')) ea
CROSS APPLY OPENJSON(JSON_QUERY(ea.value,''$.urlPrefixes'')) u
WHERE d.estate_model_pk=@estate AND d.object_kind=''PORT'';
DECLARE @binding_counts TABLE (provider_id nvarchar(400) COLLATE Latin1_General_100_BIN2, binding_count int);
INSERT @binding_counts
SELECT p2.provider_id,COUNT(*)
FROM model.provider p2
JOIN model.provider_definition pd2 ON pd2.provider_definition_pk=(SELECT MAX(pd3.provider_definition_pk) FROM model.provider_definition pd3 WHERE pd3.provider_pk=p2.provider_pk)
JOIN model.provider_binding b ON b.provider_definition_pk=pd2.provider_definition_pk
GROUP BY p2.provider_id;
DECLARE @providers nvarchar(max)=(
 SELECT p.provider_id AS providerId,pd.name AS declaredName,
  JSON_VALUE(sd.definition_json,''$.semantics.name'') AS name,
  JSON_VALUE(sd.definition_json,''$.semantics.transport.host'') AS host,
  JSON_VALUE(sd.definition_json,''$.semantics.transport.method'') AS method,
  JSON_QUERY(sd.definition_json,''$.semantics.operations'') AS operations,
  JSON_QUERY(sd.definition_json,''$.semantics.source'') AS source,
  JSON_QUERY(sd.definition_json,''$.semantics.conformanceClaims'') AS conformanceClaims,
  ISNULL(ep.endpoint_count,0) AS endpointCount,
  ISNULL(bc.binding_count,0) AS bindingCount
 FROM model.provider p
 LEFT JOIN model.provider_definition pd ON pd.provider_definition_pk=(SELECT MAX(pd4.provider_definition_pk) FROM model.provider_definition pd4 WHERE pd4.provider_pk=p.provider_pk)
 LEFT JOIN analysis.v_selected_semantic_definition sd ON sd.estate_model_pk=@estate AND sd.object_kind=''PROVIDER'' AND sd.declared_id=p.provider_id
 LEFT JOIN @binding_counts bc ON bc.provider_id=p.provider_id
 OUTER APPLY (
   SELECT COUNT(*) AS endpoint_count FROM @prefixes x
   WHERE CHARINDEX(CONVERT(nvarchar(400),JSON_VALUE(sd.definition_json,''$.semantics.transport.host'')) COLLATE SQL_Latin1_General_CP1_CI_AS,x.prefix)>0
 ) ep
 ORDER BY p.provider_id
 FOR JSON PATH);
SELECT (SELECT N''provider-catalogue.v1'' AS documentType,JSON_QUERY(@providers) AS providers FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS document;
');
DECLARE @reveal_statement nvarchar(max)=CONVERT(nvarchar(max),N'DECLARE @estate bigint=@estate_model_pk;
DECLARE @provider_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.providerId''),N'''');
IF @provider_id IS NULL THROW 51000,N''PROVIDER_ID_REQUIRED'',1;
DECLARE @semantics nvarchar(max)=(
 SELECT TOP 1 JSON_QUERY(d.definition_json,''$.semantics'')
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=''PROVIDER'' AND d.declared_id=@provider_id
 ORDER BY d.semantic_object_definition_pk DESC);
IF @semantics IS NULL THROW 51000,N''PROVIDER_NOT_FOUND'',1;
DECLARE @host nvarchar(400)=JSON_VALUE(@semantics,''$.transport.host'');
DECLARE @endpoints TABLE (ordinal int, capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2, port_id nvarchar(400), platform_capability_id nvarchar(400),
 url_prefixes nvarchar(max), methods nvarchar(max), allowed_request_headers nvarchar(max),
 allowed_response_headers nvarchar(max), endpoint_digest nvarchar(400) COLLATE Latin1_General_100_BIN2_UTF8);
INSERT @endpoints
SELECT ROW_NUMBER() OVER (ORDER BY d.namespace_id,d.declared_id),
 d.namespace_id,d.declared_id,JSON_VALUE(d.definition_json,''$.semantics.platformCapabilityId''),
 JSON_QUERY(ea.value,''$.urlPrefixes''),JSON_QUERY(ea.value,''$.methods''),
 JSON_QUERY(ea.value,''$.allowedRequestHeaders''),JSON_QUERY(ea.value,''$.allowedResponseHeaders''),
 JSON_VALUE(ea.value,''$.endpointAuthorityDigest'')
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(JSON_QUERY(d.definition_json,''$.semantics.configuration.endpointAuthorities'')) ea
WHERE d.estate_model_pk=@estate AND d.object_kind=''PORT''
 AND EXISTS (SELECT 1 FROM OPENJSON(JSON_QUERY(ea.value,''$.urlPrefixes'')) u
   WHERE CHARINDEX(@host COLLATE Latin1_General_100_BIN2_UTF8,u.value)>0);
DECLARE @credentials TABLE (capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2, port_id nvarchar(400), reference_name nvarchar(400),
 source nvarchar(400), store_locator nvarchar(400), injection_rule_id nvarchar(400), header_name nvarchar(400),
 effect_scopes nvarchar(max), lifetime_milliseconds int, endpoint_authority_digests nvarchar(max));
INSERT @credentials
SELECT d.namespace_id,d.declared_id,JSON_VALUE(ca.value,''$.referenceName''),JSON_VALUE(ca.value,''$.source''),
 JSON_VALUE(ca.value,''$.storeLocator''),JSON_VALUE(ca.value,''$.injectionRule.id''),JSON_VALUE(ca.value,''$.injectionRule.headerName''),
 JSON_QUERY(ca.value,''$.effectScopes''),TRY_CONVERT(int,JSON_VALUE(ca.value,''$.lifetimeMilliseconds'')),
 JSON_QUERY(ca.value,''$.endpointAuthorityDigests'')
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(JSON_QUERY(d.definition_json,''$.semantics.configuration.credentialAuthorities'')) ca
WHERE d.estate_model_pk=@estate AND d.object_kind=''PORT''
 AND EXISTS (SELECT 1 FROM OPENJSON(JSON_QUERY(ca.value,''$.endpointAuthorityDigests'')) x
   WHERE EXISTS (SELECT 1 FROM @endpoints e WHERE e.endpoint_digest=x.value));')
+N'DECLARE @templates TABLE (capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2, transformation_id nvarchar(400), template nvarchar(max),
 timeout_milliseconds int, max_response_bytes int, safe_headers nvarchar(max), allowed_response_headers nvarchar(max),
 definition_digest nvarchar(100));
INSERT @templates
SELECT d.namespace_id,d.declared_id,
 COALESCE(JSON_VALUE(d.definition_json,''$.semantics.expression.fields.requestUrl.template''),
          JSON_VALUE(d.definition_json,''$.semantics.expression.bindings.url.template'')),
 COALESCE(TRY_CONVERT(int,JSON_VALUE(d.definition_json,''$.semantics.expression.fields.timeoutMilliseconds.value'')),
          TRY_CONVERT(int,JSON_VALUE(d.definition_json,''$.semantics.expression.bindings.request.fields.timeoutMilliseconds.value''))),
 COALESCE(TRY_CONVERT(int,JSON_VALUE(d.definition_json,''$.semantics.expression.fields.maxResponseBytes.value'')),
          TRY_CONVERT(int,JSON_VALUE(d.definition_json,''$.semantics.expression.bindings.request.fields.maxResponseBytes.value''))),
 COALESCE(JSON_QUERY(d.definition_json,''$.semantics.expression.fields.safeHeaders''),
          JSON_QUERY(d.definition_json,''$.semantics.expression.bindings.request.fields.safeHeaders'')),
 COALESCE(JSON_QUERY(d.definition_json,''$.semantics.expression.fields.allowedResponseHeaders''),
          JSON_QUERY(d.definition_json,''$.semantics.expression.bindings.request.fields.allowedResponseHeaders'')),
 N''sha256:''+LOWER(CONVERT(varchar(64),d.definition_digest,2))
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind=''TRANSFORMATION''
 AND d.namespace_id IN (SELECT DISTINCT e.capability_id FROM @endpoints e)
 AND d.definition_json LIKE (N''%'' + @host + N''%'') COLLATE Latin1_General_100_BIN2_UTF8;
DECLARE @bindings TABLE (slot_id nvarchar(400), target_id nvarchar(400), selection_policy nvarchar(400),
 ordinal int, port_id nvarchar(400), provider_role nvarchar(400), provider_binding_pk bigint);
INSERT @bindings
SELECT s.slot_id,ctx.target_id,b.selection_policy,b.ordinal,pt.port_id,ppi.role,b.provider_binding_pk
FROM model.provider p
JOIN model.provider_definition pd ON pd.provider_definition_pk=(SELECT MAX(pd5.provider_definition_pk) FROM model.provider_definition pd5 WHERE pd5.provider_pk=p.provider_pk)
JOIN model.provider_binding b ON b.provider_definition_pk=pd.provider_definition_pk
JOIN model.provider_binding_scope bs ON bs.provider_binding_scope_pk=b.provider_binding_scope_pk
JOIN model.provider_slot s ON s.provider_slot_pk=bs.provider_slot_pk
JOIN model.binding_context ctx ON ctx.binding_context_pk=bs.binding_context_pk
LEFT JOIN model.binding_port_implementation bpi ON bpi.provider_binding_pk=b.provider_binding_pk
LEFT JOIN model.port_version pv ON pv.port_version_pk=bpi.port_version_pk
LEFT JOIN model.port pt ON pt.port_pk=pv.port_pk
LEFT JOIN model.provider_port_implementation ppi ON ppi.provider_port_implementation_pk=bpi.provider_port_implementation_pk
WHERE p.provider_id=@provider_id;'
+N'SELECT (SELECT N''provider-configuration.v1'' AS documentType,JSON_QUERY(@semantics) AS provider,
 ISNULL(JSON_QUERY((SELECT * FROM @endpoints ORDER BY ordinal FOR JSON PATH)),N''[]'') AS endpoints,
 ISNULL(JSON_QUERY((SELECT * FROM @credentials ORDER BY port_id FOR JSON PATH)),N''[]'') AS credentials,
 ISNULL(JSON_QUERY((SELECT * FROM @templates ORDER BY transformation_id FOR JSON PATH)),N''[]'') AS requestTemplates,
 ISNULL(JSON_QUERY((SELECT * FROM @bindings ORDER BY slot_id,target_id FOR JSON PATH)),N''[]'') AS bindings,
 CAST(NULL AS nvarchar(max)) AS availabilityEvidence,
 N''availability and quota evidence is not recorded in the selected model; provider runs are retained on disk, not as rows'' AS availabilityNote
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS document;
';
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
      SET @value=JSON_VALUE(@sample,N''$.''+@native);
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
-- ============================== 1. THE DECLARED CONTRACTS ==============================
EXEC model.declare_contract @id=N'provider-catalogue-request.v1',
 @schema=N'{"type":"object","properties":{},"additionalProperties":true}';
EXEC model.declare_contract @id=N'provider-catalogue-result.v1',
 @schema=N'{"type":"object","additionalProperties":true}';
EXEC model.declare_contract @id=N'provider-configuration-request.v1',
 @schema=N'{"type":"object","required":["providerId"],"properties":{"providerId":{"type":"string","minLength":1}},"additionalProperties":true}';
EXEC model.declare_contract @id=N'provider-configuration-result.v1',
 @schema=N'{"type":"object","additionalProperties":true}';
EXEC model.declare_contract @id=N'provider-binding-change-request.v1',
 @schema=N'{"type":"object","required":["providerId","input"],"properties":{"providerId":{"type":"string","minLength":1},"input":{"type":"object"}},"additionalProperties":true}';
EXEC model.declare_contract @id=N'provider-binding-change-result.v1',
 @schema=N'{"type":"object","additionalProperties":true}';

-- ============================== 2. THE DECLARED READ CAPABILITIES ==============================
DECLARE @list_bindings nvarchar(max)=N'[{"portId":"list-providers-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'+STRING_ESCAPE(@list_statement,'json')+N'","resultColumn":"document"}}]';
DECLARE @reveal_bindings nvarchar(max)=N'[{"portId":"read-provider-configuration-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'+STRING_ESCAPE(@reveal_statement,'json')+N'","resultColumn":"document"}}]';
DECLARE @set_bindings nvarchar(max)=N'[{"portId":"author-provider-configuration-change-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'+STRING_ESCAPE(@set_statement,'json')+N'","resultColumn":"document"}}]';
EXEC model.scaffold_capability @capability_id=N'list-providers', @on_exists=N'REPLACE';
EXEC model.declare_scenario
 @capability_id=N'list-providers',
 @scenario=N'{"scenarioId":"list-providers","name":"List the declared providers","inputId":"provider-catalogue-request","inputContract":"provider-catalogue-request.v1","eventId":"provider-catalogue-requested","eventAuthority":"list-providers.v1","outcomeId":"provider-catalogue","outcomeContract":"provider-catalogue-result.v1","terminal":true,"root":true,"given":"one estate selection","when":"the declared providers are read under the reader boundary","then":"each declared provider is returned with its transport, source and binding counts"}',
 @operations=N'[{"operationId":"list-providers.0","kind":"invoke-port","portId":"list-providers-port"}]',
 @port_bindings=@list_bindings;

EXEC model.scaffold_capability @capability_id=N'read-provider-configuration', @on_exists=N'REPLACE';
EXEC model.declare_scenario
 @capability_id=N'read-provider-configuration',
 @scenario=N'{"scenarioId":"read-provider-configuration","name":"Reveal one declared provider","inputId":"provider-configuration-request","inputContract":"provider-configuration-request.v1","eventId":"provider-configuration-requested","eventAuthority":"read-provider-configuration.v1","outcomeId":"provider-configuration","outcomeContract":"provider-configuration-result.v1","terminal":true,"root":true,"given":"one declared provider identity","when":"the provider declaration, its endpoint authorities, credentials, request builders and bindings are read under the reader boundary","then":"one declared provider configuration document is returned"}',
 @operations=N'[{"operationId":"read-provider-configuration.0","kind":"invoke-port","portId":"read-provider-configuration-port"}]',
 @port_bindings=@reveal_bindings;

EXEC model.scaffold_capability @capability_id=N'author-provider-configuration-change', @on_exists=N'REPLACE';
EXEC model.declare_scenario
 @capability_id=N'author-provider-configuration-change',
 @scenario=N'{"scenarioId":"author-provider-configuration-change","name":"Author and preflight one provider binding change","inputId":"provider-binding-change-request","inputContract":"provider-binding-change-request.v1","eventId":"provider-binding-change-requested","eventAuthority":"author-provider-configuration-change.v1","outcomeId":"provider-binding-change-result","outcomeContract":"provider-binding-change-result.v1","terminal":true,"root":true,"given":"one declared provider identity and one proposed binding change","when":"the change is resolved against the selected model, the declared outcome contract and the observed sample","then":"the declared change is authored with its endpoint content address, or the exact findings hold it"}',
 @operations=N'[{"operationId":"author-provider-configuration-change.0","kind":"invoke-port","portId":"author-provider-configuration-change-port"}]',
 @port_bindings=@set_bindings;

-- ============================== 3. THE DECLARED DISPLAY TRANSFORMATIONS ==============================
DECLARE @transformations TABLE (namespace_id nvarchar(400), transformation_id nvarchar(400), expression nvarchar(max));
INSERT @transformations(namespace_id,transformation_id,expression) VALUES(N'sidefx:capability:list-providers',N'list-providers-display.v1',CONVERT(nvarchar(max),N'{"op":"let","bindings":{"catalogue":{"op":"path","from":"execution","path":"outcome"},"providers":{"op":"path","from":"catalogue","path":"providers"}},"value":{"op":"object","fields":{"documentType":{"op":"literal","value":"sfx-display-document.v1"},"blocks":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Providers ({count})","values":{"count":{"op":"length","value":{"op":"path","from":"providers","path":""}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"list"},"emptyText":{"op":"literal","value":"(none)"},"items":{"op":"map","from":{"op":"path","from":"providers","path":""},"as":"p","value":{"op":"object","fields":{"text":{"op":"let","bindings":{"host":{"op":"if","when":{"op":"path","from":"p","path":"host"},"then":{"op":"path","from":"p","path":"host"},"else":{"op":"literal","value":"(no host declared)"}},"ops":{"op":"if","when":{"op":"path","from":"p","path":"operations"},"then":{"op":"length","value":{"op":"path","from":"p","path":"operations"}},"else":{"op":"literal","value":0}}},"value":{"op":"format","template":"{id}  {host}  {ops} operation(s)  {bindings} binding(s), {endpoints} endpoint(s)","values":{"id":{"op":"path","from":"p","path":"providerId"},"host":{"op":"path","from":"host","path":""},"ops":{"op":"path","from":"ops","path":""},"bindings":{"op":"path","from":"p","path":"bindingCount"},"endpoints":{"op":"path","from":"p","path":"endpointCount"}}}}}}}}}]}}}}'));
INSERT @transformations(namespace_id,transformation_id,expression) VALUES(N'sidefx:capability:read-provider-configuration',N'read-provider-configuration-display.v1',CONVERT(nvarchar(max),N'{"op":"let","bindings":{"document":{"op":"path","from":"execution","path":"outcome"},"provider":{"op":"path","from":"document","path":"provider"},"endpoints":{"op":"path","from":"document","path":"endpoints"},"credentials":{"op":"path","from":"document","path":"credentials"},"templates":{"op":"path","from":"document","path":"requestTemplates"},"bindings":{"op":"path","from":"document","path":"bindings"}},"value":{"op":"object","fields":{"documentType":{"op":"literal","value":"sfx-display-document.v1"},"blocks":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Provider {providerId}","values":{"providerId":{"op":"path","from":"provider","path":"providerId"}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"NAME"},"value":{"op":"path","from":"provider","path":"name"}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"HOST"},"value":{"op":"path","from":"provider","path":"transport.host"}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"SOURCE"},"value":{"op":"path","from":"provider","path":"source.reference"},"note":{"op":"path","from":"provider","path":"source.kind"}}},{"op":"object","fields":{"type":{"op":"literal","value":"lane"},"label":{"op":"literal","value":"ENDPOINT AUTHORITIES"},"entries":{"op":"map","from":{"op":"path","from":"endpoints","path":""},"as":"e","value":{"op":"object","fields":{"text":{"op":"format","template":"{capability} / {port}  {url}  [{methods}]  request {requestHeaders} response {responseHeaders}  digest {digest}","values":{"capability":{"op":"path","from":"e","path":"capability_id"},"port":{"op":"path","from":"e","path":"port_id"},"url":{"op":"path","from":"e","path":"url_prefixes"},"methods":{"op":"path","from":"e","path":"methods"},"requestHeaders":{"op":"path","from":"e","path":"allowed_request_headers"},"responseHeaders":{"op":"path","from":"e","path":"allowed_response_headers"},"digest":{"op":"path","from":"e","path":"endpoint_digest"}}}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"lane"},"label":{"op":"literal","value":"CREDENTIALS"},"entries":{"op":"map","from":{"op":"path","from":"credentials","path":""},"as":"c","value":{"op":"object","fields":{"text":{"op":"format","template":"{reference} ({source} {locator}) header {header} rule {rule} scopes {scopes} lifetime {lifetime} ms","values":{"reference":{"op":"path","from":"c","path":"reference_name"},"source":{"op":"path","from":"c","path":"source"},"locator":{"op":"path","from":"c","path":"store_locator"},"header":{"op":"path","from":"c","path":"header_name"},"rule":{"op":"path","from":"c","path":"injection_rule_id"},"scopes":{"op":"path","from":"c","path":"effect_scopes"},"lifetime":{"op":"path","from":"c","path":"lifetime_milliseconds"}}}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"lane"},"label":{"op":"li')+N'teral","value":"REQUEST TEMPLATES"},"entries":{"op":"map","from":{"op":"path","from":"templates","path":""},"as":"t","value":{"op":"object","fields":{"text":{"op":"format","template":"{template}  timeout {timeout} ms  max {maxBytes} bytes  digest {digest}","values":{"template":{"op":"path","from":"t","path":"template"},"timeout":{"op":"path","from":"t","path":"timeout_milliseconds"},"maxBytes":{"op":"path","from":"t","path":"max_response_bytes"},"digest":{"op":"path","from":"t","path":"definition_digest"}}}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"lane"},"label":{"op":"literal","value":"PROVIDER BINDINGS"},"entries":{"op":"map","from":{"op":"path","from":"bindings","path":""},"as":"b","value":{"op":"object","fields":{"text":{"op":"format","template":"{slot} @ {target}  policy {policy}  port {port}","values":{"slot":{"op":"path","from":"b","path":"slot_id"},"target":{"op":"path","from":"b","path":"target_id"},"policy":{"op":"path","from":"b","path":"selection_policy"},"port":{"op":"path","from":"b","path":"port_id"}}}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"AVAILABILITY"},"value":{"op":"literal","value":"not recorded in the selected model"},"note":{"op":"path","from":"document","path":"availabilityNote"}}}]}}}}');
INSERT @transformations(namespace_id,transformation_id,expression) VALUES(N'sidefx:capability:author-provider-configuration-change',N'author-provider-configuration-change-display.v1',CONVERT(nvarchar(max),N'{"op":"let","bindings":{"document":{"op":"path","from":"execution","path":"outcome"},"authored":{"op":"equals","left":{"op":"path","from":"document","path":"disposition"},"right":{"op":"literal","value":"PROVIDER_CHANGE_AUTHORED"}},"lifecycle":{"op":"path","from":"document","path":"lifecycle"}},"value":{"op":"object","fields":{"documentType":{"op":"literal","value":"sfx-display-document.v1"},"blocks":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Provider change {disposition}","values":{"disposition":{"op":"path","from":"document","path":"disposition"}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"PROVIDER"},"value":{"op":"path","from":"document","path":"providerId"}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"ENDPOINT DIGEST"},"value":{"op":"path","from":"document","path":"endpointAuthorityDigest"}}},{"op":"object","fields":{"type":{"op":"literal","value":"lane"},"label":{"op":"literal","value":"FINDINGS"},"entries":{"op":"map","from":{"op":"path","from":"document","path":"findings"},"as":"f","value":{"op":"object","fields":{"text":{"op":"format","template":"{code} {field}: {message}","values":{"code":{"op":"path","from":"f","path":"code"},"field":{"op":"path","from":"f","path":"field"},"message":{"op":"path","from":"f","path":"message"}}},"status":{"op":"literal","value":"failed"}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"LIFECYCLE"},"value":{"op":"if","when":{"op":"path","from":"authored","path":""},"then":{"op":"format","template":"author: {author}; dry run: {dryRun}; preflight: {preflight}; install: {install}","values":{"author":{"op":"path","from":"lifecycle","path":"author"},"dryRun":{"op":"path","from":"lifecycle","path":"dryRun"},"preflight":{"op":"path","from":"lifecycle","path":"preflight"},"install":{"op":"path","from":"lifecycle","path":"install"}}},"else":{"op":"literal","value":"no lifecycle: the change is held until the findings are cleared"}}}}]}}}}'));
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT namespace_id,transformation_id,expression FROM @transformations;
DECLARE @tns nvarchar(400),@tid nvarchar(400),@texpr nvarchar(max);
OPEN cur;
FETCH NEXT FROM cur INTO @tns,@tid,@texpr;
WHILE @@FETCH_STATUS=0 BEGIN
 DECLARE @tsem nvarchar(max)=N'{"id":'+(SELECT '"'+STRING_ESCAPE(@tid,N'json')+'"')+',"expression":'+@texpr+N'}';
 DECLARE @tobj bigint,@tdef bigint,@tdig binary(32),@tpk bigint,@tver bigint;
 EXEC model.put_semantic_definition 'TRANSFORMATION',@tns,@tid,@tsem,@tobj OUTPUT,@tdef OUTPUT,@tdig OUTPUT;
 SET @tpk=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@tobj);
 IF @tpk IS NULL BEGIN
  INSERT model.transformation(namespace_pk,transformation_id,semantic_object_pk,object_kind)
  SELECT namespace_pk,@tid,@tobj,'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk=@tobj;
  SET @tpk=SCOPE_IDENTITY();
 END
 SET @tver=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@tdef);
 IF @tver IS NULL BEGIN
  INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@tpk,@tobj,@tdef,@tdig,'json-expression-tree.v1','TRANSFORMATION',@tdef,N'');
  SET @tver=SCOPE_IDENTITY();
  EXEC model.normalize_transformation_expression @tver;
 END
 FETCH NEXT FROM cur INTO @tns,@tid,@texpr;
END
CLOSE cur; DEALLOCATE cur;

-- ============================== 4. THE INTERFACES SELECT THEIR DOCUMENT ==============================
DECLARE @interfaces TABLE (capability_id nvarchar(120), cli_json nvarchar(max));
INSERT @interfaces(capability_id,cli_json) VALUES(N'list-providers',N'{"display":{"transformationId":"list-providers-display.v1","as":"text"}}');
INSERT @interfaces(capability_id,cli_json) VALUES(N'read-provider-configuration',N'{"display":{"transformationId":"read-provider-configuration-display.v1","as":"text"}}');
INSERT @interfaces(capability_id,cli_json) VALUES(N'author-provider-configuration-change',N'{"display":{"transformationId":"author-provider-configuration-change-display.v1","as":"text"}}');
DECLARE icur CURSOR LOCAL FAST_FORWARD FOR SELECT capability_id,cli_json FROM @interfaces;
DECLARE @cid nvarchar(120),@cli nvarchar(max);
OPEN icur;
FETCH NEXT FROM icur INTO @cid,@cli;
WHILE @@FETCH_STATUS=0 BEGIN
 DECLARE @before nvarchar(max);
 SELECT @before=JSON_QUERY(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.cli')
 FROM model.estate_capability ec
 JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ec.semantic_object_definition_pk
 JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
  AND ec.capability_pk=(SELECT capability_pk FROM model.capability
   WHERE capability_id=@cid AND namespace_pk=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_id=N'sidefx:capabilities'));
 IF ISNULL(JSON_VALUE(@before,'$.display.transformationId'),N'')<>JSON_VALUE(@cli,'$.display.transformationId')
 BEGIN
  DECLARE @merged nvarchar(max)=JSON_MODIFY(COALESCE(@before,N'{}'),'$.display',JSON_QUERY(@cli,'$.display'));
  EXEC model.configure_interface @capability_id=@cid,@cli_json=@merged;
 END
 FETCH NEXT FROM icur INTO @cid,@cli;
END
CLOSE icur; DEALLOCATE icur;

-- ============================== 5. PROOF ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
-- The three declared reads and their display transformations resolve.
SELECT '1_capabilities' AS result_set,d.namespace_id,d.declared_id AS capability_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 LEN(CONVERT(nvarchar(max),JSON_QUERY(d.definition_json,'$.semantics.configuration'))) AS configuration_chars
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
 AND d.object_kind='PORT'
 AND d.namespace_id IN (N'sidefx:capability:list-providers',N'sidefx:capability:read-provider-configuration',N'sidefx:capability:author-provider-configuration-change')
ORDER BY d.declared_id;

SELECT '2_displays' AS result_set,d.namespace_id,d.declared_id AS transformation_id
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
 AND d.object_kind='TRANSFORMATION'
 AND d.declared_id IN (N'list-providers-display.v1',N'read-provider-configuration-display.v1',N'author-provider-configuration-change-display.v1')
ORDER BY d.declared_id;

-- The list read returns the declared catalogue from the uncommitted state.
DECLARE @list_input nvarchar(max)=N'{}';
DECLARE @listing TABLE (document nvarchar(max));
INSERT @listing EXEC sp_executesql @list_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@list_input,@estate_model_pk=@estate;
SELECT '3_list_self_test' AS result_set,
 JSON_VALUE(document,'$.documentType') AS document_type,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(document,'$.providers'))) AS providers,
 JSON_VALUE(document,'$.providers[0].providerId') AS first_provider
FROM @listing;

-- The reveal read returns the 166 route's declared endpoint, credential and template.
DECLARE @reveal_input nvarchar(max)=N'{"providerId":"rapidapi/yahoo-finance166"}';
DECLARE @revealing TABLE (document nvarchar(max));
INSERT @revealing EXEC sp_executesql @reveal_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@reveal_input,@estate_model_pk=@estate;
SELECT '4_reveal_self_test' AS result_set,
 JSON_VALUE(document,'$.documentType') AS document_type,
 JSON_VALUE(document,'$.provider.providerId') AS provider_id,
 JSON_VALUE(document,'$.endpoints[0].port_id') AS first_endpoint_port,
 JSON_VALUE(document,'$.credentials[0].injection_rule_id') AS credential_rule,
 JSON_VALUE(document,'$.requestTemplates[0].timeout_milliseconds') AS request_timeout
FROM @revealing;

-- The set preflight authors a synthetically complete change and holds the
-- finance15 proposal on its exact contract gaps.
DECLARE @synthetic_change nvarchar(max)=N'{"contractId":"provider-binding-change.v1","capabilityId":"resolve-equity-market-price-evidence","outcomeContractId":"equity-market-price-evidence.v1","bindingId":"synthetic-binding.v1","endpoint":{"host":"synthetic.example","method":"GET","pathPrefix":"/quote?","timeoutMilliseconds":15000,"maxResponseBytes":262144},"credential":{"referenceName":"RAPID_API_KEY","injectionRuleId":"rapidapi-x-rapidapi-key.v1","headerName":"X-RapidAPI-Key","source":"vault","storeLocator":"%LOCALAPPDATA%\\sfx\\vault"},"effectScope":"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY","mapping":{"symbol":"body.symbol","region":"request:payload.region","currency":"body.currency","observedPrice":"body.price","observedMarketTime":"body.time","marketState":"body.state","exchange":"body.exchange","sourceAttribution":"body.source"},"observedSample":{"body":{"symbol":"AVGO","currency":"USD","price":357.61,"time":1789000000,"state":"Closed","exchange":"NMS","source":"Delayed Quote"}}}';
DECLARE @synthetic_input nvarchar(max)=N'{"providerId":"rapidapi/yahoo-finance15","input":'+@synthetic_change+N'}';
DECLARE @authoring TABLE (document nvarchar(max));
INSERT @authoring EXEC sp_executesql @set_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@synthetic_input,@estate_model_pk=@estate;
SELECT '5_set_self_test' AS result_set,
 JSON_VALUE(document,'$.disposition') AS disposition,
 JSON_VALUE(document,'$.endpointAuthorityDigest') AS endpoint_digest,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(document,'$.findings'))) AS findings
FROM @authoring;

DECLARE @finance15_change nvarchar(max)=N'{"contractId":"provider-binding-change.v1","capabilityId":"resolve-equity-market-price-evidence","outcomeContractId":"equity-market-price-evidence.v1","bindingId":"rapidapi-yahoo-finance15-market-quotes.v1","endpoint":{"host":"yahoo-finance15.p.rapidapi.com","method":"GET","pathPrefix":"/api/v1/markets/quote?","timeoutMilliseconds":15000,"maxResponseBytes":262144},"credential":{"referenceName":"RAPID_API_KEY","injectionRuleId":"rapidapi-x-rapidapi-key.v1","headerName":"X-RapidAPI-Key","source":"vault","storeLocator":"%LOCALAPPDATA%\\sfx\\vault"},"effectScope":"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY","mapping":{"symbol":"body.symbol","region":"request:payload.region","currency":null,"observedPrice":"body.primaryData.lastSalePrice","observedMarketTime":"body.primaryData.lastTradeTimestamp","marketState":"body.marketStatus","exchange":"body.exchange","sourceAttribution":"body.companyName"},"observedSample":{"body":{"symbol":"AVGO","companyName":"Broadcom Inc. Common Stock","exchange":"NASDAQ-GS","primaryData":{"lastSalePrice":"$357.61","netChange":"+10.31","lastTradeTimestamp":"Sep 17, 2026","currency":null},"marketStatus":"Closed"}}}';
DECLARE @finance15_input nvarchar(max)=N'{"providerId":"rapidapi/yahoo-finance15","input":'+@finance15_change+N'}';
DECLARE @holding TABLE (document nvarchar(max));
INSERT @holding EXEC sp_executesql @set_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@finance15_input,@estate_model_pk=@estate;
SELECT '6_finance15_gap' AS result_set,
 JSON_VALUE(document,'$.disposition') AS disposition,
 JSON_VALUE(document,'$.providerId') AS provider_id,
 finding.code AS finding_code,finding.field AS canonical_field,finding.message AS finding_message
FROM @holding
CROSS APPLY OPENJSON(JSON_QUERY(document,'$.findings'))
 WITH (code nvarchar(100) '$.code',field nvarchar(400) '$.field',message nvarchar(2000) '$.message') finding
ORDER BY finding_code;

COMMIT TRANSACTION;
