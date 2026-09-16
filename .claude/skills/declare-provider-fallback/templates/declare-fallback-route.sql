-- declare-fallback-route.sql  (TEMPLATE - copy into sql/migrations/ and rename)
--
-- Declares a fallback provider route on <<CAPABILITY_ID>>: the route's ports,
-- the operations that reach it, the selection between the routes' evidence, and
-- the outcome variants that name each result.
--
-- Every <<PLACEHOLDER>> below is authority that must come from the model or
-- from the declaration that grants the route. The guard in section 0 refuses to
-- run while any placeholder survives. Do not fill one with a plausible value to
-- get past it - an unobtainable value means the change is blocked, and that is
-- a finding, not a number to invent. This is especially true of
-- <<FALLBACK_ENDPOINT_AUTHORITY_DIGEST>>: nothing in this estate computes it.
--
-- Default: ROLLBACK after verification. Replace the final ROLLBACK TRANSACTION;
-- with COMMIT TRANSACTION; to install, after the from-transaction preflight
-- passes for all three cases (primary succeeds / primary fails / both fail).
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Drop the workshop data guards so this script can write.
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

-- ======================= 0. declared parameters =======================
DECLARE @capability_id nvarchar(400) = N'<<CAPABILITY_ID>>';
DECLARE @scenario_id   nvarchar(400) = N'<<ROOT_SCENARIO_ID>>';

-- The primary route, as already declared. Read, do not restate from memory.
DECLARE @primary_exchange_port   nvarchar(400) = N'<<PRIMARY_EXCHANGE_PORT_ID>>';
DECLARE @primary_credential_port nvarchar(400) = N'<<PRIMARY_CREDENTIAL_PORT_ID>>';

-- The fallback route.
DECLARE @fallback_request_port    nvarchar(400) = N'<<FALLBACK_REQUEST_PORT_ID>>';
DECLARE @fallback_credential_port nvarchar(400) = N'<<FALLBACK_CREDENTIAL_PORT_ID>>';
DECLARE @fallback_exchange_port   nvarchar(400) = N'<<FALLBACK_EXCHANGE_PORT_ID>>';
DECLARE @fallback_provider_id     nvarchar(400) = N'<<FALLBACK_PROVIDER_ID>>';
DECLARE @fallback_binding_id      nvarchar(400) = N'<<FALLBACK_BINDING_ID>>';
DECLARE @fallback_url_prefix      nvarchar(1000)= N'<<FALLBACK_URL_PREFIX>>';
DECLARE @fallback_credential_ref  nvarchar(400) = N'<<FALLBACK_CREDENTIAL_REFERENCE_NAME>>';
DECLARE @fallback_injection_rule  nvarchar(400) = N'<<FALLBACK_INJECTION_RULE_ID>>';
DECLARE @fallback_header_name     nvarchar(400) = N'<<FALLBACK_INJECTION_HEADER_NAME>>';
DECLARE @fallback_effect_scope    nvarchar(400) = N'<<FALLBACK_EFFECT_SCOPE>>';
-- Declared authority. Obtain it; never compute or copy it.
DECLARE @fallback_digest          nvarchar(200) = N'<<FALLBACK_ENDPOINT_AUTHORITY_DIGEST>>';

-- Refuse to run on unresolved authority.
IF EXISTS (SELECT 1 FROM (VALUES
  (@capability_id),(@scenario_id),(@primary_exchange_port),(@primary_credential_port),
  (@fallback_request_port),(@fallback_credential_port),(@fallback_exchange_port),
  (@fallback_provider_id),(@fallback_binding_id),(@fallback_credential_ref),
  (@fallback_injection_rule),(@fallback_header_name),(@fallback_effect_scope),
  (@fallback_digest)) v(value) WHERE v.value LIKE N'<<%>>')
 THROW 51000,'FALLBACK_ROUTE_AUTHORITY_NOT_DECLARED',1;
IF EXISTS (SELECT 1 FROM (VALUES (@fallback_url_prefix)) v(value) WHERE v.value LIKE N'<<%>>')
 THROW 51000,'FALLBACK_ROUTE_AUTHORITY_NOT_DECLARED',1;

DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
IF @estate IS NULL THROW 51000,'CURRENT_MODEL_NOT_FOUND',1;

-- ============================== BEFORE ==============================
-- Prove the generation this change is a diff against: the declared operation
-- order, the ports behind them, and the variants already classified.
SELECT 'BEFORE_operations' AS result_set, op.ordinal, op.operation_kind, p.port_id
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=@capability_id
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=@scenario_id
JOIN model.scenario_event ev ON ev.scenario_version_pk=cs.scenario_version_pk
JOIN model.execution_operation op ON op.execution_authority_version_pk=ev.execution_authority_version_pk
LEFT JOIN model.operation_port_invocation i ON i.execution_operation_pk=op.execution_operation_pk
LEFT JOIN model.port_version pv ON pv.port_version_pk=i.port_version_pk
LEFT JOIN model.port p ON p.port_pk=pv.port_pk
WHERE ec.estate_model_pk=@estate
ORDER BY op.ordinal;

SELECT 'BEFORE_variants' AS result_set, ov.variant_id, ov.classification
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=@capability_id
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.outcome_variant ov ON ov.scenario_version_pk=cs.scenario_version_pk
WHERE ec.estate_model_pk=@estate
ORDER BY ov.variant_id;

-- ============ 1. the transformation that builds the fallback request ============
-- Expression profile json-expression-tree.v1. It receives `input` (the primary
-- exchange's evidence) and `root` (the scenario input) and nothing else, so it
-- must copy forward everything the selection in section 2 will need from the
-- primary attempt. Bindings lower in document order: dependency order, never
-- alphabetical.
DECLARE @fallback_request_expression nvarchar(max) = N'<<FALLBACK_REQUEST_EXPRESSION_JSON>>';
IF @fallback_request_expression LIKE N'<<%>>' THROW 51000,'FALLBACK_REQUEST_EXPRESSION_NOT_DECLARED',1;

DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;
DECLARE @object bigint,@definition bigint,@digest binary(32);
DECLARE @semantics nvarchar(max)=(SELECT JSON_QUERY(@fallback_request_expression) AS expression
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
EXEC model.put_semantic_definition 'TRANSFORMATION',@namespace,@fallback_request_port,@semantics,
  @object OUTPUT,@definition OUTPUT,@digest OUTPUT;
DECLARE @transformation bigint=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@object);
IF @transformation IS NULL THROW 51000,'FALLBACK_TRANSFORMATION_NOT_REGISTERED',1;
DECLARE @version bigint=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@definition);
IF @version IS NULL BEGIN
 INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
  expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@transformation,@object,@definition,@digest,'json-expression-tree.v1','TRANSFORMATION',@definition,N'');
 SET @version=SCOPE_IDENTITY();
 EXEC model.normalize_transformation_expression @version;
END;

-- ================ 2. the selection between the routes' evidence ================
-- Re-declare the normalizing transformation so the outcome, its disposition and
-- its provider identity follow the route that actually answered. bindingId,
-- providerId and nativeShape must become selections; leaving them literal
-- attributes one provider's evidence to another.
DECLARE @selection_transformation nvarchar(400) = N'<<SELECTION_TRANSFORMATION_ID>>';
DECLARE @selection_expression nvarchar(max) = N'<<SELECTION_EXPRESSION_JSON>>';
IF @selection_transformation LIKE N'<<%>>' OR @selection_expression LIKE N'<<%>>'
 THROW 51000,'FALLBACK_SELECTION_NOT_DECLARED',1;
SET @semantics=(SELECT JSON_QUERY(@selection_expression) AS expression FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
EXEC model.put_semantic_definition 'TRANSFORMATION',@namespace,@selection_transformation,@semantics,
  @object OUTPUT,@definition OUTPUT,@digest OUTPUT;
SET @transformation=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@object);
SET @version=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@definition);
IF @version IS NULL BEGIN
 INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
  expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@transformation,@object,@definition,@digest,'json-expression-tree.v1','TRANSFORMATION',@definition,N'');
 SET @version=SCOPE_IDENTITY();
 EXEC model.normalize_transformation_expression @version;
END;

-- =============== 3. ports, operations and variants, in one call ===============
-- model.declare_scenario upserts the port bindings, mints the execution
-- authority when the envelope digest is new, and upserts the variants. Every
-- operation must be invoke-port with a declared binding; an invoke-scenario
-- operation throws SCENARIO_OPERATION_BINDING_NOT_DECLARED here - mint the
-- authority version directly for that shape instead.
--
-- Carry the whole port inventory, not just the new rows: the call declares the
-- scenario's ports as given. Preserve the primary route's bindings verbatim.
DECLARE @port_bindings nvarchar(max) = N'[' +
  -- ... every existing port binding of this scenario, unchanged ...
  N'<<EXISTING_PORT_BINDINGS_JSON>>' + N',' +
  -- the fallback request builder
  N'{"portId":"' + STRING_ESCAPE(@fallback_request_port,'json') + N'",' +
   N'"platformCapabilityId":"sda-authority-transformation-port.v1",' +
   N'"configuration":{"transformationId":"' + STRING_ESCAPE(@fallback_request_port,'json') + N'"}},' +
  -- the fallback credential binding
  N'{"portId":"' + STRING_ESCAPE(@fallback_credential_port,'json') + N'",' +
   N'"platformCapabilityId":"sda-external-credential-reference-binding-port.v1",' +
   N'"configuration":{"credentialAuthorities":[{' +
     N'"referenceName":"' + STRING_ESCAPE(@fallback_credential_ref,'json') + N'",' +
     N'"source":"environment",' +
     N'"effectScopes":["' + STRING_ESCAPE(@fallback_effect_scope,'json') + N'"],' +
     N'"requestingCapabilityIds":["' + STRING_ESCAPE(@capability_id,'json') + N'"],' +
     N'"endpointAuthorityDigests":["' + STRING_ESCAPE(@fallback_digest,'json') + N'"],' +
     N'"injectionRule":{"id":"' + STRING_ESCAPE(@fallback_injection_rule,'json') + N'",' +
       N'"headerName":"' + STRING_ESCAPE(@fallback_header_name,'json') + N'"}' +
   N'}]}},' +
  -- the fallback exchange
  N'{"portId":"' + STRING_ESCAPE(@fallback_exchange_port,'json') + N'",' +
   N'"platformCapabilityId":"sda-governed-http-exchange-port.v1",' +
   N'"configuration":{' +
     N'"credentialInjectionRules":[{"id":"' + STRING_ESCAPE(@fallback_injection_rule,'json') + N'",' +
       N'"headerName":"' + STRING_ESCAPE(@fallback_header_name,'json') + N'"}],' +
     N'"endpointAuthorities":[{' +
       N'"endpointAuthorityDigest":"' + STRING_ESCAPE(@fallback_digest,'json') + N'",' +
       N'"urlPrefixes":["' + STRING_ESCAPE(@fallback_url_prefix,'json') + N'"],' +
       N'"methods":["GET"],' +
       N'"allowedRequestHeaders":[<<FALLBACK_ALLOWED_REQUEST_HEADERS>>],' +
       N'"allowedResponseHeaders":[<<FALLBACK_ALLOWED_RESPONSE_HEADERS>>]' +
     N'}]}}' +
N']';
IF @port_bindings LIKE N'%<<%>>%' THROW 51000,'FALLBACK_PORT_BINDINGS_NOT_DECLARED',1;
IF ISJSON(@port_bindings)<>1 THROW 51000,'FALLBACK_PORT_BINDINGS_INVALID',1;

-- Operation order. Every declared operation runs; there is no guard. The
-- fallback's request builder is the only place the route can vary, and what the
-- exchange port then does with a guarded request is port behavior to verify in
-- the preflight - not to assume here.
DECLARE @operations nvarchar(max) = N'[' +
  N'<<EXISTING_OPERATIONS_JSON>>' + N',' +
  N'{"kind":"invoke-port","portId":"' + STRING_ESCAPE(@fallback_request_port,'json') + N'"},' +
  N'{"kind":"invoke-port","portId":"' + STRING_ESCAPE(@fallback_credential_port,'json') + N'"},' +
  N'{"kind":"invoke-port","portId":"' + STRING_ESCAPE(@fallback_exchange_port,'json') + N'"},' +
  N'{"kind":"invoke-port","portId":"' + STRING_ESCAPE(@selection_transformation,'json') + N'"}' +
N']';
IF @operations LIKE N'%<<%>>%' THROW 51000,'FALLBACK_OPERATIONS_NOT_DECLARED',1;
IF ISJSON(@operations)<>1 THROW 51000,'FALLBACK_OPERATIONS_INVALID',1;

-- Faces unchanged; variants extended. Classification is success|failure only.
-- Name the fallback's own results: a result resolved through the fallback, and
-- "no route completed", are different statements from the primary's
-- unavailability.
DECLARE @scenario nvarchar(max) = N'<<SCENARIO_DECLARATION_JSON>>';
IF @scenario LIKE N'%<<%>>%' THROW 51000,'FALLBACK_SCENARIO_NOT_DECLARED',1;
IF ISJSON(@scenario)<>1 THROW 51000,'FALLBACK_SCENARIO_INVALID',1;

EXEC model.declare_scenario @capability_id, @scenario, @operations, @port_bindings;

-- ============================== AFTER ==============================
SELECT 'AFTER_operations' AS result_set, op.ordinal, op.operation_kind, p.port_id
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=@capability_id
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=@scenario_id
JOIN model.scenario_event ev ON ev.scenario_version_pk=cs.scenario_version_pk
JOIN model.execution_operation op ON op.execution_authority_version_pk=ev.execution_authority_version_pk
LEFT JOIN model.operation_port_invocation i ON i.execution_operation_pk=op.execution_operation_pk
LEFT JOIN model.port_version pv ON pv.port_version_pk=i.port_version_pk
LEFT JOIN model.port p ON p.port_pk=pv.port_pk
WHERE ec.estate_model_pk=@estate
ORDER BY op.ordinal;

SELECT 'AFTER_variants' AS result_set, ov.variant_id, ov.classification
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=@capability_id
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.outcome_variant ov ON ov.scenario_version_pk=cs.scenario_version_pk
WHERE ec.estate_model_pk=@estate
ORDER BY ov.variant_id;

-- Adding operations changes the provider-slot inventory. Re-declare the slot
-- requirements in this same change, or the blueprint that asserts the prior
-- operation count diverges.

ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
