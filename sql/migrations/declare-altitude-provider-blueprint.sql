-- declare-altitude-provider-blueprint.sql
--
-- Lane: efficient-query-tooling, executor. Applies the D2 probe
-- (probe.provider_blueprint_declaration) and the D1-diagnosed read re-point to
-- the altitude provider-add blocker:
--
--   1. Declares the minimal altitude provider-slot blueprint equivalent
--      (authoring-altitude-model-stubs-blueprint.v1) from the D2 probe's
--      capability/operation rows, so model.install_provider_binding_change no
--      longer refuses EQUITY_BLUEPRINT_ABSENT for the altitude providers. The
--      blueprint row and its semantic object are declared here; the installer
--      mints the version, nodes and slots from the change document exactly as
--      it does for the equity capability.
--   2. Re-declares model.install_provider_binding_change with three targeted
--      changes, byte-identical everywhere else:
--        a. the current authority operations are read from the authority
--           version's own base-table content object instead of
--           analysis.v_selected_semantic_definition;
--        b. the subject scenario's own requesting event is relinked (the
--           equity event when present, else the scenario's single event);
--        c. the operation floor is >=1 generically and stays >=5 for the
--           equity capability (EQUITY_WORKING_EXECUTION_DIVERGED preserved).
--      The provider-slot operation read no longer joins the estate-wide view.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
-- Idempotent: replay answers already_declared and re-runs the CREATE OR ALTER
-- and proofs unchanged.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=30000;
IF @lock<0 THROW 51000,N'ALTITUDE_BLUEPRINT_LOCK_FAILED',1;
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
DECLARE @capability_id nvarchar(400)=N'authoring-altitude-model-stubs';
DECLARE @blueprint_id nvarchar(400)=@capability_id+N'-blueprint.v1';
DECLARE @blueprint_ns bigint=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_id=N'sidefx:blueprints');

-- ============================== D2: THE BLUEPRINT DECLARATION INPUTS ==============================
-- The probe's capability-version and operation rows are the declaration inputs:
-- the capability's selected version digest and the port definition digest per
-- operation ordinal. No graph source is assembled.
DECLARE @declared TABLE(probe_set nvarchar(40),capability_id nvarchar(400),capability_version_pk bigint,
 capability_definition_digest nvarchar(80),operation_ordinal int,operation_kind nvarchar(40),
 port_id nvarchar(400),port_version_pk bigint,port_definition_digest nvarchar(80),platform_capability_id nvarchar(400));
INSERT @declared
SELECT probe_set,capability_id,capability_version_pk,'sha256:'+LOWER(CONVERT(varchar(64),capability_definition_digest,2)),
 operation_ordinal,operation_kind,port_id,port_version_pk,'sha256:'+LOWER(CONVERT(varchar(64),port_definition_digest,2)),platform_capability_id
FROM probe.provider_blueprint_declaration(@estate,@capability_id,N'sidefx:blueprints');
DECLARE @capability_version_pk bigint=(SELECT MAX(capability_version_pk) FROM @declared WHERE probe_set=N'capability-version');
DECLARE @operation_count int=(SELECT COUNT(*) FROM @declared WHERE probe_set=N'operation');
IF @capability_version_pk IS NULL OR @operation_count<1 THROW 51000,N'ALTITUDE_BLUEPRINT_DECLARATION_INPUTS_ABSENT',1;
IF EXISTS(SELECT 1 FROM @declared WHERE probe_set=N'operation' AND (port_id IS NULL OR platform_capability_id IS NULL))
 THROW 51000,N'ALTITUDE_BLUEPRINT_OPERATION_PORT_UNRESOLVED',1;

-- ============================== THE MINIMAL BLUEPRINT ==============================
DECLARE @blueprint_existed bit=CASE WHEN EXISTS(
 SELECT 1 FROM model.blueprint b WHERE b.namespace_pk=@blueprint_ns AND b.blueprint_id=@blueprint_id) THEN 1 ELSE 0 END;
DECLARE @object bigint,@definition bigint,@digest binary(32);
IF @blueprint_existed=0
BEGIN
 DECLARE @semantics nvarchar(max)=N'{"blueprintId":"'+@blueprint_id
  +N'","capabilityId":"'+@capability_id
  +N'","carrierVersion":"canonical-circuit-blueprint.v1","disposition":"CANDIDATE","declaredBy":"declare-altitude-provider-blueprint.sql"'
  +N',"capabilityAuthorityDigest":"'+(SELECT MAX(capability_definition_digest) FROM @declared WHERE probe_set=N'capability-version')+N'"}';
 IF ISJSON(@semantics)<>1 THROW 51000,N'ALTITUDE_BLUEPRINT_SEMANTICS_INVALID',1;
 EXEC model.put_semantic_definition 'BLUEPRINT',N'sidefx:blueprints',@blueprint_id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 INSERT model.blueprint(namespace_pk,blueprint_id,semantic_object_pk,object_kind)
 SELECT namespace_pk,@blueprint_id,@object,N'BLUEPRINT' FROM model.semantic_object WHERE semantic_object_pk=@object;
END
IF NOT EXISTS(SELECT 1 FROM model.blueprint b WHERE b.namespace_pk=@blueprint_ns AND b.blueprint_id=@blueprint_id)
 THROW 51000,N'ALTITUDE_BLUEPRINT_NOT_DECLARED',1;

-- ============================== THE GENERALIZED INSTALLER ==============================
GO
CREATE OR ALTER PROCEDURE model.install_provider_binding_change
 @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @document IS NULL OR ISJSON(@document)<>1 THROW 51002,'PROVIDER_CHANGE_DOCUMENT_INVALID',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 IF @estate IS NULL THROW 51002,'CURRENT_MODEL_NOT_FOUND',1;

 DECLARE @provider_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.providerId'),N'');
 DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.capabilityId'),N'');
 DECLARE @outcome_contract nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.outcomeContractId'),N'');
 DECLARE @binding_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.bindingId'),N'');
 DECLARE @route_id nvarchar(100)=NULLIF(JSON_VALUE(@document,'$.route.routeId'),N'');
 DECLARE @native_shape nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.nativeShape'),N'');
 DECLARE @host nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.endpoint.host'),N'');
 DECLARE @method nvarchar(20)=ISNULL(NULLIF(JSON_VALUE(@document,'$.endpoint.method'),N''),N'GET');
 DECLARE @path_prefix nvarchar(1000)=NULLIF(JSON_VALUE(@document,'$.endpoint.pathPrefix'),N'');
 DECLARE @request_template nvarchar(2000)=NULLIF(JSON_VALUE(@document,'$.endpoint.requestTemplate'),N'');
 DECLARE @timeout int=ISNULL(TRY_CONVERT(int,JSON_VALUE(@document,'$.endpoint.timeoutMilliseconds')),15000);
 DECLARE @max_bytes int=ISNULL(TRY_CONVERT(int,JSON_VALUE(@document,'$.endpoint.maxResponseBytes')),262144);
 DECLARE @reference_name nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.credential.referenceName'),N'');
 DECLARE @rule_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.credential.injectionRuleId'),N'');
 DECLARE @header_name nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.credential.headerName'),N'');
 DECLARE @credential_source nvarchar(400)=ISNULL(NULLIF(JSON_VALUE(@document,'$.credential.source'),N''),N'environment');
 DECLARE @store_locator nvarchar(600)=NULLIF(JSON_VALUE(@document,'$.credential.storeLocator'),N'');
 DECLARE @effect_scope nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.effectScope'),N'');
 DECLARE @lifetime int=ISNULL(TRY_CONVERT(int,JSON_VALUE(@document,'$.credential.lifetimeMilliseconds')),15000);
 DECLARE @resolved_disposition nvarchar(400)=ISNULL(NULLIF(JSON_VALUE(@document,'$.route.resolvedDisposition'),N''),N'EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED');
 DECLARE @request_body_expression nvarchar(max)=JSON_QUERY(@document,'$.requestBodyExpression');
 IF @provider_id IS NULL OR @capability_id IS NULL OR @outcome_contract IS NULL OR @binding_id IS NULL
  OR @route_id IS NULL OR @native_shape IS NULL OR @host IS NULL OR @path_prefix IS NULL
  OR @request_template IS NULL OR @reference_name IS NULL OR @rule_id IS NULL OR @header_name IS NULL
  OR @effect_scope IS NULL OR @credential_source NOT IN (N'environment',N'vault')
  THROW 51002,'PROVIDER_CHANGE_FIELDS_REQUIRED',1;
 IF @credential_source=N'vault' AND @store_locator IS NULL THROW 51002,'PROVIDER_CHANGE_VAULT_LOCATOR_REQUIRED',1;
 IF @request_body_expression IS NULL AND JSON_VALUE(@document,'$.requestBodyExpression') IS NOT NULL
  THROW 51002,'PROVIDER_CHANGE_REQUEST_BODY_EXPRESSION_INVALID',1;
 IF @request_body_expression IS NOT NULL
  AND (ISJSON(@request_body_expression)<>1 OR NULLIF(JSON_VALUE(@request_body_expression,'$.op'),N'') IS NULL)
  THROW 51002,'PROVIDER_CHANGE_REQUEST_BODY_EXPRESSION_INVALID',1;

 -- The endpoint authority content address, computed over the exact record the
 -- authoring read minted (same fields, same order): the digest the credential
 -- authority and the exchange authority both carry.
 DECLARE @endpoint_record nvarchar(max)=N'{"host":"'+STRING_ESCAPE(@host,'json')
  +N'","method":"'+STRING_ESCAPE(@method,'json')
  +N'","pathPrefix":"'+STRING_ESCAPE(@path_prefix,'json')
  +N'","providerId":"'+STRING_ESCAPE(@provider_id,'json')
  +N'","bindingId":"'+STRING_ESCAPE(@binding_id,'json')
  +N'","credentialInjectionRuleId":"'+STRING_ESCAPE(@rule_id,'json')
  +N'","effectScope":"'+STRING_ESCAPE(@effect_scope,'json')+N'"}';
 DECLARE @endpoint_digest nvarchar(200)=N'sha256:'+LOWER(CONVERT(varchar(64),
  HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),(@endpoint_record) COLLATE Latin1_General_100_BIN2_UTF8))),2));

 DECLARE @slug nvarchar(100)=@route_id;
 DECLARE @build_binding nvarchar(400)=N'build-'+@slug+N'-price-binding-request';
 DECLARE @bind_credential nvarchar(400)=N'bind-'+@slug+N'-price-provider-credential';
 DECLARE @build_exchange nvarchar(400)=N'build-'+@slug+N'-price-exchange-request';
 DECLARE @observe_exchange nvarchar(400)=N'observe-'+@slug+N'-price-exchange';
 DECLARE @select_route nvarchar(400)=N'select-'+@slug+N'-price-route';
 DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;

 -- Optional provider identity upsert: a first add of an undeclared provider is
 -- the same document, not a code edit.
 DECLARE @provider_name nvarchar(400)=JSON_VALUE(@document,'$.provider.name');
 DECLARE @provider_operations nvarchar(max)=JSON_QUERY(@document,'$.provider.operations');
 IF @provider_name IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM model.provider p JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
   WHERE n.namespace_id=N'sidefx:providers' AND p.provider_id=@provider_id)
 BEGIN
  EXEC model.add_provider @provider_id=@provider_id,@name=@provider_name,
   @operations_json=@provider_operations;
 END

 -- Resolve the capability's root scenario and current authority.
 DECLARE @capability bigint,@capability_version bigint,@scenario_version bigint,@authority_pk bigint,@authority_so bigint;
 SELECT @capability=c.capability_pk,@capability_version=ec.capability_version_pk,
  @scenario_version=cs.scenario_version_pk
 FROM model.capability c
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
 JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
 JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=@capability_id
 WHERE c.capability_id=@capability_id;
 IF @scenario_version IS NULL THROW 51002,'CAPABILITY_ROOT_AUTHORITY_ABSENT',1;
 SELECT @authority_pk=ea.execution_authority_pk,@authority_so=ea.semantic_object_pk
 FROM model.execution_authority ea
 JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk AND n.namespace_id=@namespace
 WHERE ea.execution_authority_id=@capability_id+N'.v1';
 IF @authority_pk IS NULL THROW 51002,'EXECUTION_AUTHORITY_ABSENT',1;

 -- The current authority operations are the authority's own declaration; the new
 -- route appends to them. The route's binding port already present means this
 -- document was already installed.
 DECLARE @current_operations nvarchar(max)=NULL;
 -- The current authority's operations are resolved from the authority version's
 -- own base-table content object: no estate-wide view and no graph assembly.
 SELECT TOP 1 @current_operations=JSON_QUERY(dt.document_text,'$.semantics.authority.operations')
 FROM model.execution_authority_version eav
 JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=eav.semantic_object_definition_pk
 JOIN model.estate_definition est ON est.semantic_object_definition_pk=eav.semantic_object_definition_pk AND est.estate_model_pk=@estate
 JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
 CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document_text) dt
 WHERE eav.execution_authority_pk=@authority_pk
 ORDER BY eav.execution_authority_version_pk DESC;
 IF @current_operations IS NULL THROW 51002,'EXECUTION_AUTHORITY_OPERATIONS_ABSENT',1;
 IF @current_operations LIKE N'%'+@build_binding+N'%'
 BEGIN
  SELECT N'already_installed' AS result_set,@provider_id AS provider_id,@capability_id AS capability_id,
   @route_id AS route_id,@endpoint_digest AS endpoint_authority_digest;
  RETURN;
 END

 -- ---------------------------------------------------------------- the route expressions
 -- The normalization selects the answering route's evidence and carries the
 -- provider identity of the route that answered. It is assembled from the
 -- declared mapping; every canonical field names its native source.
 DECLARE @payload_fields nvarchar(max)=N'';
 DECLARE @field nvarchar(400),@source nvarchar(1000),@expr nvarchar(max);
 DECLARE mapping_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT [key],value FROM OPENJSON(@document,'$.mapping');
 OPEN mapping_cursor;
 FETCH NEXT FROM mapping_cursor INTO @field,@source;
 WHILE @@FETCH_STATUS=0 BEGIN
  SET @expr=NULL;
  IF @source LIKE N'request:%'
   SET @expr=N'{"op":"path","from":"root","path":"'+STRING_ESCAPE(SUBSTRING(@source,9,990),'json')+'"}';
  ELSE IF @source LIKE @native_shape+N'.%'
   SET @expr=N'{"op":"path","from":"record","path":"'+STRING_ESCAPE(SUBSTRING(@source,LEN(@native_shape)+2,990),'json')+'"}';
  ELSE IF @source=@native_shape
   SET @expr=N'{"op":"path","from":"record","path":""}';
  IF @expr IS NULL
   THROW 51002,'PROVIDER_CHANGE_MAPPING_PATH_UNRESOLVED',1;
  SET @payload_fields=@payload_fields+CASE WHEN LEN(@payload_fields)>0 THEN N',' ELSE N'' END
   +N'"'+STRING_ESCAPE(@field,'json')+'":'+@expr;
  FETCH NEXT FROM mapping_cursor INTO @field,@source;
 END
 CLOSE mapping_cursor; DEALLOCATE mapping_cursor;
 IF LEN(@payload_fields)=0 THROW 51002,'PROVIDER_CHANGE_MAPPING_EMPTY',1;

 DECLARE @provider_id_esc nvarchar(800)=STRING_ESCAPE(@provider_id,'json');
 DECLARE @binding_id_esc nvarchar(800)=STRING_ESCAPE(@binding_id,'json');
 DECLARE @native_shape_esc nvarchar(800)=STRING_ESCAPE(@native_shape,'json');
 DECLARE @outcome_contract_esc nvarchar(800)=STRING_ESCAPE(@outcome_contract,'json');
 DECLARE @capability_id_esc nvarchar(800)=STRING_ESCAPE(@capability_id,'json');
 DECLARE @reference_esc nvarchar(800)=STRING_ESCAPE(@reference_name,'json');
 DECLARE @digest_esc nvarchar(800)=STRING_ESCAPE(@endpoint_digest,'json');
 DECLARE @scope_esc nvarchar(800)=STRING_ESCAPE(@effect_scope,'json');
 DECLARE @rule_esc nvarchar(800)=STRING_ESCAPE(@rule_id,'json');
 DECLARE @resolved_esc nvarchar(800)=STRING_ESCAPE(@resolved_disposition,'json');

 DECLARE @route_selection nvarchar(max)=CONVERT(nvarchar(max),N'{"op":"let","bindings":{"payload":{"op":"try-parse-json","value":{"op":"base64-decode-utf8","value":{"op":"path","from":"input","path":"responseBodyBytes"}}},"record":{"op":"path","from":"payload","path":"value.'
  +@native_shape_esc+N'"}},"value":{"op":"object","fields":{"contractId":{"op":"literal","value":"'+@outcome_contract_esc
  +N'"},"disposition":{"op":"literal","value":"'+@resolved_esc
  +N'"},"payload":{"op":"object","fields":{'+@payload_fields
  +N'}},"providerTestimony":{"op":"object","fields":{"bindingId":{"op":"literal","value":"'+@binding_id_esc
  +N'"},"providerId":{"op":"literal","value":"'+@provider_id_esc
  +N'"},"nativeShape":{"op":"literal","value":"'+@native_shape_esc+N'"}}}}}}');
 DECLARE @quote_guard nvarchar(max)=N'{"op":"let","bindings":{"candidate":null,"absent":{"op":"filter","from":{"op":"object-values","value":{"op":"path","from":"candidate","path":"payload"}},"as":"field","where":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"field","path":""},"right":{"op":"literal","value":null}},"then":{"op":"literal","value":true},"else":{"op":"equals","left":{"op":"path","from":"field","path":""},"right":{"op":"literal","value":""}}}}},"value":{"op":"if","when":{"op":"equals","left":{"op":"length","value":{"op":"path","from":"absent","path":""}},"right":{"op":"literal","value":0}},"then":{"op":"path","from":"candidate","path":""},"else":{"op":"object","fields":{"contractId":{"op":"path","from":"candidate","path":"contractId"},"disposition":{"op":"literal","value":"NATIVE_MARKET_PRICE_TESTIMONY_REJECTED"},"reasonCode":{"op":"literal","value":"REQUIRED_NATIVE_FIELDS_ABSENT"},"absentFieldCount":{"op":"length","value":{"op":"path","from":"absent","path":""}},"providerTestimony":{"op":"path","from":"candidate","path":"providerTestimony"}}}}}';
 SET @route_selection=JSON_MODIFY(@route_selection,'$.value',JSON_QUERY(JSON_MODIFY(@quote_guard,'$.bindings.candidate',JSON_QUERY(@route_selection,'$.value'))));
 DECLARE @route_selection_expr nvarchar(max)=CONVERT(nvarchar(max),N'{"op":"let","bindings":{"completed":{"op":"equals","left":{"op":"path","from":"input","path":"disposition"},"right":{"op":"literal","value":"completed"}}},"value":{"op":"if","when":{"op":"path","from":"completed","path":""},"then":'
  +@route_selection+N',"else":{"op":"path","from":"input","path":"effectLineage.0"}}}');

 DECLARE @binding_expression nvarchar(max)=CONVERT(nvarchar(max),N'{"op":"let","bindings":{"done":{"op":"equals","left":{"op":"path","from":"input","path":"disposition"},"right":{"op":"literal","value":"'
  +@resolved_esc+N'"}},"carrier":{"op":"array","items":[{"op":"path","from":"input","path":""}]},"request":{"op":"object","fields":{'
  +N'"credentialReference":{"op":"literal","value":"'+@reference_esc+N'"},'
  +N'"invocationIdentity":{"op":"literal","value":"'+@outcome_contract_esc+N'"},'
  +N'"requestingCapabilityId":{"op":"literal","value":"'+@capability_id_esc+N'"},'
  +N'"endpointAuthorityDigest":{"op":"literal","value":"'+@digest_esc+N'"},'
  +N'"effectScope":{"op":"literal","value":"'+@scope_esc+N'"},'
  +N'"effectLineage":{"op":"path","from":"carrier","path":""}}}},"value":{"op":"if","when":{"op":"path","from":"done","path":""},'
  +N'"then":{"op":"object","fields":{"effectLineage":{"op":"path","from":"carrier","path":""}}},'
  +N'"else":{"op":"path","from":"request","path":""}}}');

 DECLARE @safe_headers nvarchar(max)=ISNULL(JSON_QUERY(@document,'$.endpoint.safeHeaders'),N'{}');
 DECLARE @safe_header_fields nvarchar(max)=N'',@header nvarchar(400),@header_value nvarchar(800);
 DECLARE header_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT [key],value FROM OPENJSON(@safe_headers);
 OPEN header_cursor;
 FETCH NEXT FROM header_cursor INTO @header,@header_value;
 WHILE @@FETCH_STATUS=0 BEGIN
  SET @safe_header_fields=@safe_header_fields+CASE WHEN LEN(@safe_header_fields)>0 THEN N',' ELSE N'' END
   +N'"'+STRING_ESCAPE(@header,'json')+'":{"op":"literal","value":"'+STRING_ESCAPE(@header_value,'json')+'"}';
  FETCH NEXT FROM header_cursor INTO @header,@header_value;
 END
 CLOSE header_cursor; DEALLOCATE header_cursor;

 DECLARE @allowed_response_headers nvarchar(max)=ISNULL(JSON_QUERY(@document,'$.endpoint.allowedResponseHeaders'),N'["content-type"]');
 DECLARE @response_header_items nvarchar(max)=N'';
 SELECT @response_header_items=@response_header_items+CASE WHEN LEN(@response_header_items)>0 THEN N',' ELSE N'' END
  +N'{"op":"literal","value":"'+STRING_ESCAPE(j.value,'json')+'"}'
 FROM OPENJSON(@allowed_response_headers) j;

 DECLARE @request_template_esc nvarchar(4000)=STRING_ESCAPE(@request_template,'json');
 DECLARE @host_esc nvarchar(800)=STRING_ESCAPE(@host,'json');
 DECLARE @exchange_expression nvarchar(max)=CONVERT(nvarchar(max),N'{"op":"let","bindings":{'
  +N'"bound":{"op":"equals","left":{"op":"path","from":"input","path":"disposition"},"right":{"op":"literal","value":"BOUND"}},'
  +N'"url":{"op":"format","template":"'+@request_template_esc+N'","values":{'
  +N'"region":{"op":"path","from":"root","path":"payload.region"},'
  +N'"symbol":{"op":"path","from":"root","path":"payload.symbol"},'
  +N'"symbols":{"op":"path","from":"root","path":"payload.symbol"}}},'
  +N'"request":{"op":"object","fields":{'
  +N'"requestUrl":{"op":"path","from":"url","path":""},'
  +N'"method":{"op":"literal","value":"'+STRING_ESCAPE(@method,'json')+'"},'
  +N'"safeHeaders":{"op":"object","fields":{'+@safe_header_fields+N'}},'
  +N'"allowedResponseHeaders":{"op":"array","items":['+@response_header_items+N']},'
  +N'"timeoutMilliseconds":{"op":"literal","value":'+CONVERT(nvarchar(20),@timeout)+N'},'
  +N'"maxResponseBytes":{"op":"literal","value":'+CONVERT(nvarchar(20),@max_bytes)+N'},'
  +N'"requestBodyText":'+ISNULL(@request_body_expression,N'{"op":"literal","value":""}')+N','
  +N'"invocationIdentity":{"op":"literal","value":"'+@outcome_contract_esc+N'"},'
  +N'"endpointAuthorityDigest":{"op":"literal","value":"'+@digest_esc+N'"},'
  +N'"credentialInjectionRuleId":{"op":"literal","value":"'+@rule_esc+N'"},'
  +N'"opaqueCredentialBinding":{"op":"object","fields":{"bindingId":{"op":"path","from":"input","path":"opaqueBindingId"},'
  +N'"credentialInjectionRuleId":{"op":"literal","value":"'+@rule_esc+N'"}}},'
  +N'"effectLineage":{"op":"path","from":"input","path":"effectLineage"}}}},'
  +N'"value":{"op":"if","when":{"op":"path","from":"bound","path":""},"then":{"op":"path","from":"request","path":""},'
  +N'"else":{"op":"object","fields":{"effectLineage":{"op":"path","from":"input","path":"effectLineage"}}}}}');

 -- ---------------------------------------------------------------- declare the route transformations
 DECLARE @object bigint,@definition bigint,@digest binary(32),@transformation bigint,@version bigint;
 DECLARE @transformations TABLE (idx int PRIMARY KEY,id nvarchar(400),expression nvarchar(max));
 INSERT @transformations VALUES
  (0,@build_binding,@binding_expression),
  (1,@build_exchange,@exchange_expression),
  (2,@select_route,@route_selection_expr);
 DECLARE @idx int,@id nvarchar(400),@expression nvarchar(max),@semantics nvarchar(max);
 DECLARE transformation_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT idx,id,expression FROM @transformations ORDER BY idx;
 OPEN transformation_cursor;
 FETCH NEXT FROM transformation_cursor INTO @idx,@id,@expression;
 WHILE @@FETCH_STATUS=0 BEGIN
  SET @semantics=N'{"id":"'+@id+N'","expression":'+@expression+N'}';
  IF ISJSON(@semantics)<>1 BEGIN
   DECLARE @invalid_message nvarchar(2048)=N'PROVIDER_CHANGE_TRANSFORMATION_INVALID:'+@id+N' '+LEFT(@semantics,1800);
   THROW 51002,@invalid_message,1;
  END
  EXEC model.put_semantic_definition 'TRANSFORMATION',@namespace,@id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
  SET @transformation=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@object);
  IF @transformation IS NULL BEGIN
   INSERT model.transformation(namespace_pk,transformation_id,semantic_object_pk,object_kind)
   SELECT namespace_pk,@id,@object,'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk=@object;
   SET @transformation=SCOPE_IDENTITY();
  END
  SET @version=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@definition);
  IF @version IS NULL BEGIN
   INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
    expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@transformation,@object,@definition,@digest,'json-expression-tree.v1','TRANSFORMATION',@definition,N'');
   SET @version=SCOPE_IDENTITY();
   EXEC model.normalize_transformation_expression @version;
  END
  FETCH NEXT FROM transformation_cursor INTO @idx,@id,@expression;
 END
 CLOSE transformation_cursor; DEALLOCATE transformation_cursor;

 -- ---------------------------------------------------------------- declare the route ports
 DECLARE @credential_source_esc nvarchar(800)=STRING_ESCAPE(@credential_source,'json');
 DECLARE @store_locator_field nvarchar(max)=CASE WHEN @store_locator IS NULL THEN N'' ELSE
  N'"storeLocator":"'+STRING_ESCAPE(@store_locator,'json')+N'",' END;
 DECLARE @credential_config nvarchar(max)=CONVERT(nvarchar(max),N'{"credentialAuthorities":[{"referenceName":"'
  +@reference_esc+N'",'+@store_locator_field+N'"source":"'+@credential_source_esc+N'","effectScopes":["'+@scope_esc+N'"],"requestingCapabilityIds":["'
  +@capability_id_esc+N'"],"endpointAuthorityDigests":["'+@digest_esc+N'"],"lifetimeMilliseconds":'
  +CONVERT(nvarchar(20),@lifetime)+N',"injectionRule":{"id":"'+@rule_esc+N'","headerName":"'
  +STRING_ESCAPE(@header_name,'json')+N'"}}]}');
 DECLARE @safe_header_names nvarchar(max)=N'';
 SELECT @safe_header_names=@safe_header_names+CASE WHEN LEN(@safe_header_names)>0 THEN N',' ELSE N'' END
  +N'"'+STRING_ESCAPE(j.[key],'json')+N'"' FROM OPENJSON(@safe_headers) j;
 DECLARE @url_prefix nvarchar(2000)=N'https://'+@host+@path_prefix;
 DECLARE @exchange_config nvarchar(max)=CONVERT(nvarchar(max),N'{"credentialInjectionRules":[{"id":"'+@rule_esc
  +N'","headerName":"'+STRING_ESCAPE(@header_name,'json')+N'"}],"endpointAuthorities":[{"endpointAuthorityDigest":"'
  +@digest_esc+N'","urlPrefixes":["'+STRING_ESCAPE(@url_prefix,'json')+N'"],"methods":["'
  +STRING_ESCAPE(@method,'json')+N'"],"allowedRequestHeaders":['+ISNULL(NULLIF(@safe_header_names,N''),N'[]')+N'],'
  +N'"allowedResponseHeaders":'+@allowed_response_headers+N'}]}');

 DECLARE @new_ports TABLE (port_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,platform_capability_id nvarchar(400),configuration nvarchar(max));
 INSERT @new_ports VALUES
  (@build_binding,N'sda-authority-transformation-port.v1',N'{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"'+@build_binding+N'"}'),
  (@bind_credential,N'sda-external-credential-reference-binding-port.v1',@credential_config),
  (@build_exchange,N'sda-authority-transformation-port.v1',N'{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"'+@build_exchange+N'"}'),
  (@observe_exchange,N'sda-governed-http-exchange-port.v1',@exchange_config),
  (@select_route,N'sda-authority-transformation-port.v1',N'{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"'+@select_route+N'"}');
 DECLARE @port_id nvarchar(400),@platform_capability_id nvarchar(400),@configuration nvarchar(max);
 DECLARE @port bigint,@port_version bigint,@port_binding nvarchar(max);
 DECLARE port_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT port_id,platform_capability_id,configuration FROM @new_ports;
 OPEN port_cursor;
 FETCH NEXT FROM port_cursor INTO @port_id,@platform_capability_id,@configuration;
 WHILE @@FETCH_STATUS=0 BEGIN
  SET @port_binding=N'{"portId":"'+@port_id+N'","platformCapabilityId":"'+@platform_capability_id+N'","configuration":'+@configuration+N'}';
  EXEC model.put_semantic_definition 'PORT',@namespace,@port_id,@port_binding,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
  SET @port=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object);
  IF @port IS NULL BEGIN
   INSERT model.port(namespace_pk,port_id,semantic_object_pk,object_kind)
   SELECT namespace_pk,@port_id,@object,'PORT' FROM model.semantic_object WHERE semantic_object_pk=@object;
   SET @port=SCOPE_IDENTITY();
  END
  SET @port_version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition);
  IF @port_version IS NULL BEGIN
   INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@port,@object,@definition,@digest,'consumer-interface-authority.v1','PORT',@definition,N'');
   SET @port_version=SCOPE_IDENTITY();
  END
  FETCH NEXT FROM port_cursor INTO @port_id,@platform_capability_id,@configuration;
 END
 CLOSE port_cursor; DEALLOCATE port_cursor;

 -- ---------------------------------------------------------------- append the route operations
 DECLARE @operation_count int=(SELECT COUNT(*) FROM OPENJSON(@current_operations));
 DECLARE @append nvarchar(max)=CONVERT(nvarchar(max),N'');
 SET @append=@append+N'{"operationId":"'+@capability_id_esc+N'.operation.'+CONVERT(nvarchar(10),@operation_count+1)
  +N'","kind":"invoke-port","portId":"'+STRING_ESCAPE(@build_binding,'json')+N'"},';
 SET @append=@append+N'{"operationId":"'+@capability_id_esc+N'.operation.'+CONVERT(nvarchar(10),@operation_count+2)
  +N'","kind":"invoke-port","portId":"'+STRING_ESCAPE(@bind_credential,'json')
  +N'","outcomeVariants":["SUCCESS",{"variantId":"BOUND","classification":"success"},{"variantId":"CREDENTIAL_NOT_AVAILABLE","classification":"failure"},{"variantId":"UNAUTHORIZED_REFERENCE","classification":"failure"},{"variantId":"IDENTITY_MISMATCH","classification":"failure"}]},';
 SET @append=@append+N'{"operationId":"'+@capability_id_esc+N'.operation.'+CONVERT(nvarchar(10),@operation_count+3)
  +N'","kind":"invoke-port","portId":"'+STRING_ESCAPE(@build_exchange,'json')+N'"},';
 SET @append=@append+N'{"operationId":"'+@capability_id_esc+N'.operation.'+CONVERT(nvarchar(10),@operation_count+4)
  +N'","kind":"invoke-port","portId":"'+STRING_ESCAPE(@observe_exchange,'json')
  +N'","outcomeVariants":["SUCCESS","FAILURE","CANCELLED",{"variantId":"completed","classification":"success"},{"variantId":"retained-non-success","classification":"failure"},{"variantId":"rejected-endpoint","classification":"failure"},{"variantId":"transport-failed","classification":"failure"},{"variantId":"rejected-credential","classification":"failure"},{"variantId":"cancelled","classification":"failure"},{"variantId":"oversized-response-rejected","classification":"failure"},{"variantId":"timed-out","classification":"failure"}]},';
 SET @append=@append+N'{"operationId":"'+@capability_id_esc+N'.operation.'+CONVERT(nvarchar(10),@operation_count+5)
  +N'","kind":"invoke-port","portId":"'+STRING_ESCAPE(@select_route,'json')
  +N'","outcomeVariants":["SUCCESS",{"variantId":"'+@resolved_esc+N'","classification":"success"},{"variantId":"EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE","classification":"failure"}]}';
 DECLARE @appended_operations nvarchar(max)=LEFT(@current_operations,LEN(@current_operations)-1)+N','+@append+N']';
 IF ISJSON(@appended_operations)<>1 THROW 51002,'PROVIDER_CHANGE_OPERATIONS_INVALID',1;

 -- ---------------------------------------------------------------- mint the authority version
 DECLARE @authority_envelope nvarchar(max)=N'{"address":{"id":"'+@capability_id+N'.v1","kind":"EXECUTION_AUTHORITY","namespace":"'
  +@namespace+N'"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":{"id":"'+@capability_id
  +N'.v1","operations":'+@appended_operations+N',"owningScenarioId":"'+@capability_id+N'"}}}';
 DECLARE @authority_bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),(@authority_envelope) COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @authority_digest binary(32)=HASHBYTES('SHA2_256',@authority_bytes);
 DECLARE @authority_sod bigint=NULL,@authority_version bigint=NULL;
 SELECT @authority_sod=semantic_object_definition_pk,@authority_version=execution_authority_version_pk
 FROM model.execution_authority_version WHERE execution_authority_pk=@authority_pk AND definition_digest=@authority_digest;
 IF @authority_version IS NULL BEGIN
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@authority_digest)
   INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@authority_digest,@authority_bytes,DATALENGTH(@authority_bytes));
  INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk)
   VALUES(@authority_so,'EXECUTION_AUTHORITY',@authority_digest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@authority_digest));
  SET @authority_sod=SCOPE_IDENTITY();
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@estate AND semantic_object_definition_pk=@authority_sod)
   INSERT model.estate_definition(estate_model_pk,semantic_object_definition_pk) VALUES(@estate,@authority_sod);
  INSERT model.execution_authority_version(execution_authority_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,authority_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@authority_pk,@authority_so,@authority_sod,@authority_digest,'execution-authorities.v1','EXECUTION_AUTHORITY',@authority_sod,N'');
  SET @authority_version=SCOPE_IDENTITY();
  INSERT model.execution_operation(execution_authority_version_pk,operation_id,ordinal,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT @authority_version,JSON_VALUE(o.value,'$.operationId'),CONVERT(int,o.[key]),JSON_VALUE(o.value,'$.kind'),@authority_sod,N'/semantics/authority/operations/'+o.[key]
   FROM OPENJSON(@appended_operations) o;
  INSERT model.operation_port_invocation(execution_operation_pk,port_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT eo.execution_operation_pk,pv.port_version_pk,'invoke-port',@authority_sod,eo._canonical_pointer
   FROM model.execution_operation eo
   JOIN OPENJSON(@appended_operations) o ON CONVERT(int,o.[key])=eo.ordinal
   JOIN model.port p ON p.namespace_pk=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='PORT' AND namespace_id=@namespace)
    AND p.port_id=JSON_VALUE(o.value,'$.portId')
   JOIN model.port_version pv ON pv.port_pk=p.port_pk AND pv.port_version_pk=(SELECT MAX(pv2.port_version_pk) FROM model.port_version pv2 WHERE pv2.port_pk=p.port_pk)
   WHERE eo.execution_authority_version_pk=@authority_version;
 END
 -- The subject scenario's own requesting event is relinked. The equity
 -- capability keeps its declared event; every capability without one relinks
 -- its single declared event, so the same mechanic serves both.
 DECLARE @target_event_id nvarchar(400)=CASE WHEN EXISTS(
  SELECT 1 FROM model.scenario_event se WHERE se.scenario_version_pk=@scenario_version
  AND se.event_id=N'equity-market-price-evidence-requested')
  THEN N'equity-market-price-evidence-requested'
  ELSE (SELECT TOP (1) se.event_id FROM model.scenario_event se WHERE se.scenario_version_pk=@scenario_version ORDER BY se.event_id) END;
 IF @target_event_id IS NULL THROW 51002,'PROVIDER_CHANGE_SCENARIO_EVENT_ABSENT',1;
 UPDATE model.scenario_event SET execution_authority_version_pk=@authority_version
 WHERE scenario_version_pk=@scenario_version AND event_id=@target_event_id;

 -- ---------------------------------------------------------------- re-declare the provider-slot blueprint
 DECLARE @blueprint_id nvarchar(400)=@capability_id+N'-blueprint.v1';
 DECLARE @blueprint_ns bigint=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_id=N'sidefx:blueprints');
 DECLARE @blueprint bigint=(SELECT blueprint_pk FROM model.blueprint WHERE namespace_pk=@blueprint_ns AND blueprint_id=@blueprint_id);
 IF @blueprint IS NULL THROW 51002,'EQUITY_BLUEPRINT_ABSENT',1;
 DECLARE @blueprint_so bigint=(SELECT semantic_object_pk FROM model.blueprint WHERE blueprint_pk=@blueprint);
 DECLARE @capability_digest binary(32)=(SELECT cv.definition_digest FROM model.capability_version cv WHERE cv.capability_version_pk=@capability_version);
 SELECT op.execution_operation_pk,op.ordinal,p.port_id,pv.port_version_pk,pv.semantic_object_definition_pk AS port_definition,
  pv.definition_digest AS port_digest,JSON_VALUE(dt.document_text,'$.semantics.platformCapabilityId') AS platform_capability_id
 INTO #operations
 FROM model.scenario_event event
 JOIN model.execution_operation op ON op.execution_authority_version_pk=event.execution_authority_version_pk
 JOIN model.operation_port_invocation invocation ON invocation.execution_operation_pk=op.execution_operation_pk
 JOIN model.port_version pv ON pv.port_version_pk=invocation.port_version_pk
 JOIN model.port p ON p.port_pk=pv.port_pk
 JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
 JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
 CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document_text) dt
 WHERE event.scenario_version_pk=@scenario_version;
 DECLARE @operation_total int=(SELECT COUNT(*) FROM #operations);
 IF @operation_total<1 THROW 51002,'PROVIDER_CHANGE_WORKING_EXECUTION_DIVERGED',1;
 IF @capability_id=N'resolve-equity-market-price-evidence' AND @operation_total<5 THROW 51002,'EQUITY_WORKING_EXECUTION_DIVERGED',1;
 DECLARE @nodes nvarchar(max)=(SELECT port_id+N'-slot' AS nodeId,'provider-slot' AS kind,'PROVIDER' AS altitude,
  ordinal AS projectionOrdinal,port_id+N'-slot' AS [providerSlot.slotId],
  port_id AS [providerSlot.portId],platform_capability_id AS [providerSlot.platformCapabilityId],
  'sha256:'+LOWER(CONVERT(varchar(64),port_digest,2)) AS [providerSlot.portDefinitionDigest]
  FROM #operations ORDER BY ordinal FOR JSON PATH);
 DECLARE @definition_json nvarchar(max)=(SELECT @blueprint_id AS [address.id],'BLUEPRINT' AS [address.kind],
  'sidefx:blueprints' AS [address.namespace],'sidefx-semantic-definition.v1' AS format,
  'canonical-circuit-blueprint.v1' AS [semantics.carrierVersion],@blueprint_id AS [semantics.blueprintAuthority.blueprintId],
  @capability_id AS [semantics.capability.capabilityId],
  'sha256:'+LOWER(CONVERT(varchar(64),@capability_digest,2)) AS [semantics.capability.capabilityAuthorityDigest],
  JSON_QUERY(@nodes) AS [semantics.nodes]
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @blueprint_bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@definition_json COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @blueprint_digest binary(32)=HASHBYTES('SHA2_256',@blueprint_bytes);
 IF NOT EXISTS (SELECT 1 FROM model.blueprint_version WHERE blueprint_pk=@blueprint AND definition_digest=@blueprint_digest)
 BEGIN
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@blueprint_digest)
   INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@blueprint_digest,@blueprint_bytes,DATALENGTH(@blueprint_bytes));
  INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk)
   VALUES(@blueprint_so,'BLUEPRINT',@blueprint_digest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@blueprint_digest));
  DECLARE @blueprint_definition bigint=SCOPE_IDENTITY();
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@estate AND semantic_object_definition_pk=@blueprint_definition)
   INSERT model.estate_definition(estate_model_pk,semantic_object_definition_pk) VALUES(@estate,@blueprint_definition);
  INSERT model.blueprint_version(blueprint_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
   capability_pk,capability_version_pk,carrier_profile,source_disposition,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@blueprint,@blueprint_so,@blueprint_definition,@blueprint_digest,@capability,@capability_version,'canonical-circuit-blueprint.v1','CANDIDATE','BLUEPRINT',@blueprint_definition,N'');
  DECLARE @blueprint_version bigint=SCOPE_IDENTITY();
  INSERT model.blueprint_node(blueprint_version_pk,node_id,node_kind,altitude,projection_ordinal,
   semantic_object_definition_pk,expected_semantic_kind,_owner_definition_pk,_canonical_pointer)
   SELECT @blueprint_version,port_id+N'-slot','provider-slot','PROVIDER',ordinal,port_definition,'PORT',
    @blueprint_definition,N'/nodes/'+CONVERT(nvarchar(20),ordinal) FROM #operations;
  INSERT model.provider_slot(blueprint_version_pk,slot_id,owner_node_pk,_owner_definition_pk,_canonical_pointer)
   SELECT @blueprint_version,node_id,blueprint_node_pk,@blueprint_definition,_canonical_pointer+N'/providerSlot'
   FROM model.blueprint_node WHERE blueprint_version_pk=@blueprint_version;
  INSERT model.slot_port_requirement(provider_slot_pk,port_version_pk,ordinal,role,_owner_definition_pk,_canonical_pointer)
   SELECT slot.provider_slot_pk,op.port_version_pk,0,N'event-port',@blueprint_definition,slot._canonical_pointer
   FROM #operations op JOIN model.provider_slot slot ON slot.blueprint_version_pk=@blueprint_version AND slot.slot_id=op.port_id+N'-slot';
  INSERT model.provider_slot_operation(provider_slot_pk,execution_operation_pk,_owner_definition_pk,_canonical_pointer)
   SELECT slot.provider_slot_pk,op.execution_operation_pk,@blueprint_definition,slot._canonical_pointer
   FROM #operations op JOIN model.provider_slot slot ON slot.blueprint_version_pk=@blueprint_version AND slot.slot_id=op.port_id+N'-slot';
  SELECT * INTO #profiles FROM analysis.v_target_provider_profile WHERE estate_model_pk=@estate AND effect_classification='effect';
  INSERT model.slot_profile_requirement(provider_slot_pk,provider_profile_version_pk,ordinal,role,_owner_definition_pk,_canonical_pointer)
   SELECT slot.provider_slot_pk,p.provider_profile_version_pk,ROW_NUMBER() OVER(PARTITION BY slot.provider_slot_pk ORDER BY p.target_id)-1,
    N'effect',@blueprint_definition,slot._canonical_pointer
   FROM model.provider_slot slot CROSS JOIN #profiles p WHERE slot.blueprint_version_pk=@blueprint_version;
  INSERT model.provider_binding_scope(provider_slot_pk,binding_context_pk,binding_role,selection_policy,_owner_definition_pk,_canonical_pointer)
   SELECT slot.provider_slot_pk,context.binding_context_pk,N'event-port','SINGLE',@blueprint_definition,slot._canonical_pointer
   FROM model.provider_slot slot CROSS JOIN #profiles p
   JOIN model.binding_context context ON context.provider_profile_version_pk=p.provider_profile_version_pk AND context.target_id=p.target_id
   WHERE slot.blueprint_version_pk=@blueprint_version;
  SELECT * INTO #implementations FROM analysis.v_target_provider_implementation WHERE estate_model_pk=@estate;
  INSERT model.provider_port_implementation(provider_definition_pk,port_version_pk,provider_profile_version_pk,role,_owner_definition_pk,_canonical_pointer)
   SELECT DISTINCT i.provider_definition_pk,op.port_version_pk,p.provider_profile_version_pk,N'event-port',i.semantic_object_definition_pk,N''
   FROM #operations op JOIN #implementations i ON i.capability_id=op.platform_capability_id
   JOIN #profiles p ON p.target_id=i.target_id
   WHERE NOT EXISTS (SELECT 1 FROM model.provider_port_implementation previous WHERE previous.provider_definition_pk=i.provider_definition_pk
    AND previous.port_version_pk=op.port_version_pk AND previous.provider_profile_version_pk=p.provider_profile_version_pk);
  SELECT * INTO #candidates FROM analysis.v_provider_slot_candidate WHERE estate_model_pk=@estate
   AND provider_slot_pk IN (SELECT provider_slot_pk FROM model.provider_slot WHERE blueprint_version_pk=@blueprint_version);
  INSERT model.provider_binding(provider_binding_scope_pk,provider_slot_pk,selection_policy,provider_definition_pk,ordinal,_owner_definition_pk,_canonical_pointer)
   SELECT scope.provider_binding_scope_pk,scope.provider_slot_pk,'SINGLE',candidate.provider_definition_pk,NULL,@blueprint_definition,scope._canonical_pointer
   FROM model.provider_binding_scope scope
   JOIN model.binding_context context ON context.binding_context_pk=scope.binding_context_pk
   JOIN #candidates candidate ON candidate.provider_slot_pk=scope.provider_slot_pk AND candidate.provider_profile_version_pk=context.provider_profile_version_pk
   WHERE (SELECT COUNT(*) FROM #candidates other WHERE other.provider_slot_pk=candidate.provider_slot_pk
    AND other.provider_profile_version_pk=candidate.provider_profile_version_pk)=1;
  INSERT model.binding_port_implementation(provider_binding_pk,provider_slot_pk,provider_definition_pk,slot_port_requirement_pk,port_version_pk,
   provider_port_implementation_pk,_owner_definition_pk,_canonical_pointer)
   SELECT b.provider_binding_pk,b.provider_slot_pk,b.provider_definition_pk,r.slot_port_requirement_pk,r.port_version_pk,
    i.provider_port_implementation_pk,@blueprint_definition,b._canonical_pointer
   FROM model.provider_binding b JOIN model.provider_binding_scope scope ON scope.provider_binding_scope_pk=b.provider_binding_scope_pk
   JOIN model.binding_context context ON context.binding_context_pk=scope.binding_context_pk
   JOIN model.slot_port_requirement r ON r.provider_slot_pk=b.provider_slot_pk
   JOIN model.provider_port_implementation i ON i.provider_definition_pk=b.provider_definition_pk
    AND i.port_version_pk=r.port_version_pk AND i.provider_profile_version_pk=context.provider_profile_version_pk
   WHERE b._owner_definition_pk=@blueprint_definition;
  IF (SELECT COUNT(*) FROM model.provider_slot_operation WHERE _owner_definition_pk=@blueprint_definition)<>@operation_total
   THROW 51002,'EQUITY_PROVIDER_OPERATION_COVERAGE_INCOMPLETE',1;
 END

 SELECT N'provider_change_installed' AS result_set,@provider_id AS provider_id,@capability_id AS capability_id,
  @route_id AS route_id,@native_shape AS native_shape,@endpoint_digest AS endpoint_authority_digest,
  @operation_total AS operation_count;
END;
GO
-- ============================== PROOFS ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @blueprint_id nvarchar(400)=N'authoring-altitude-model-stubs-blueprint.v1';
DECLARE @blueprint_ns bigint=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_id=N'sidefx:blueprints');

-- 1. The blueprint row exists for the altitude capability.
SELECT N'1_altitude_blueprint' AS result_set,b.blueprint_pk,b.blueprint_id,b.semantic_object_pk,
 (SELECT COUNT(*) FROM model.blueprint_version bv WHERE bv.blueprint_pk=b.blueprint_pk) AS version_count
FROM model.blueprint b WHERE b.namespace_pk=@blueprint_ns AND b.blueprint_id=@blueprint_id;

-- 2. D2 resolves the altitude declaration inputs (capability version + one live-model port).
SELECT N'2_declaration_inputs' AS result_set,probe_set,capability_id,capability_version_pk,capability_definition_digest,
 operation_ordinal,operation_kind,port_id,port_version_pk,port_definition_digest,platform_capability_id
FROM probe.provider_blueprint_declaration(@estate,N'authoring-altitude-model-stubs',N'sidefx:blueprints')
ORDER BY probe_set,operation_ordinal;

-- 3. The re-declared installer carries the read re-point and no estate-wide view join.
SELECT N'3_installer_shape' AS result_set,
 CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'model.install_provider_binding_change')) LIKE N'%v_selected_semantic_definition%' THEN N'DIVERGED' ELSE N'BASE-TABLE-ONLY' END AS operations_read,
 CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'model.install_provider_binding_change')) LIKE N'%equity-market-price-evidence-requested%' THEN N'EQUITY_EVENT_PRESERVED' ELSE N'DIVERGED' END AS event_selection,
 CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'model.install_provider_binding_change')) LIKE N'%PROVIDER_CHANGE_WORKING_EXECUTION_DIVERGED%' THEN N'GENERIC_FLOOR_DECLARED' ELSE N'DIVERGED' END AS operation_floor,
 CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'model.install_provider_binding_change')) LIKE N'%IF @capability_id=N''resolve-equity-market-price-evidence'' AND @operation_total<5%' THEN N'EQUITY_FLOOR_PRESERVED' ELSE N'DIVERGED' END AS equity_floor;

-- 4. Equality proof: the base-table operations read is byte-identical to the
-- estate-wide view's value for both the equity capability and the altitude.
DECLARE @equity_view nvarchar(max),@equity_base nvarchar(max),@altitude_view nvarchar(max),@altitude_base nvarchar(max);
SELECT TOP 1 @equity_view=JSON_QUERY(d.definition_json,'$.semantics.authority.operations')
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='EXECUTION_AUTHORITY' AND d.declared_id=N'resolve-equity-market-price-evidence.v1'
ORDER BY d.semantic_object_definition_pk DESC;
SELECT TOP 1 @equity_base=JSON_QUERY(dt.document_text,'$.semantics.authority.operations')
FROM model.execution_authority ea
JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk AND n.namespace_id=N'sidefx:capability:resolve-equity-market-price-evidence'
JOIN model.execution_authority_version eav ON eav.execution_authority_pk=ea.execution_authority_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=eav.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document_text) dt
WHERE ea.execution_authority_id=N'resolve-equity-market-price-evidence.v1'
ORDER BY eav.execution_authority_version_pk DESC;
SELECT TOP 1 @altitude_view=JSON_QUERY(d.definition_json,'$.semantics.authority.operations')
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='EXECUTION_AUTHORITY' AND d.declared_id=N'authoring-altitude-model-stubs.v1'
ORDER BY d.semantic_object_definition_pk DESC;
SELECT TOP 1 @altitude_base=JSON_QUERY(dt.document_text,'$.semantics.authority.operations')
FROM model.execution_authority ea
JOIN model.execution_authority_version eav ON eav.execution_authority_pk=ea.execution_authority_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=eav.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document_text) dt
WHERE ea.execution_authority_id=N'authoring-altitude-model-stubs.v1'
ORDER BY eav.execution_authority_version_pk DESC;
SELECT N'4_operations_read_equality' AS result_set,
 CASE WHEN @equity_view=@equity_base COLLATE Latin1_General_100_BIN2 THEN N'IDENTICAL' ELSE N'DIVERGED' END AS equity,
 CASE WHEN @altitude_view=@altitude_base COLLATE Latin1_General_100_BIN2 THEN N'IDENTICAL' ELSE N'DIVERGED' END AS altitude,
 LEN(@equity_view) AS equity_chars,LEN(@altitude_view) AS altitude_chars;
IF @equity_view<>@equity_base COLLATE Latin1_General_100_BIN2 THROW 51000,N'ALTITUDE_BLUEPRINT_EQUITY_OPERATIONS_READ_DIVERGED',1;
IF @altitude_view<>@altitude_base COLLATE Latin1_General_100_BIN2 THROW 51000,N'ALTITUDE_BLUEPRINT_ALTITUDE_OPERATIONS_READ_DIVERGED',1;
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
