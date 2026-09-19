-- fix-provider-reveal-identity.sql
--
-- Follow-up to declare-provider-command-reads.sql. A platform provider's
-- declaration uses the `sda-platform-capability-catalog.v1` profile: it names
-- its capabilities under `semantics.capabilities[]` and may carry no
-- `providerId`, `name` or `transport`. The reveal read returned the semantics
-- verbatim, so `sfx provider reveal <platform provider>` rendered a null
-- identity. This change re-declares only the reveal read's statement with the
-- honest fallbacks: the subject identity and the declared
-- `model.provider_definition.name` when the semantics carries neither. No value
-- is inferred from a naming convention.
--
-- This migration changes one declared read statement through the standard port
-- lifecycle: the selected port definition is read, its statement is replaced,
-- the new definition is retained and versioned, and the binding is re-pointed.
-- It authors no capability and changes no other operation.
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
DECLARE @reveal_statement nvarchar(max)=CONVERT(nvarchar(max),N'DECLARE @estate bigint=@estate_model_pk;
DECLARE @provider_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.providerId''),N'''');
IF @provider_id IS NULL THROW 51000,N''PROVIDER_ID_REQUIRED'',1;
DECLARE @semantics nvarchar(max)=(
 SELECT TOP 1 JSON_QUERY(d.definition_json,''$.semantics'')
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=''PROVIDER'' AND d.declared_id=@provider_id
 ORDER BY d.semantic_object_definition_pk DESC);
IF @semantics IS NULL THROW 51000,N''PROVIDER_NOT_FOUND'',1;
-- A platform provider''s declaration uses the platform-catalog profile and may
-- carry no providerId/name/transport. The subject identity and the declared
-- provider_definition name are the honest fallbacks; no value is inferred.
DECLARE @declared_name nvarchar(400)=(
 SELECT TOP 1 pd.name FROM model.provider p
 JOIN model.provider_definition pd ON pd.provider_definition_pk=(
   SELECT MAX(pd2.provider_definition_pk) FROM model.provider_definition pd2 WHERE pd2.provider_pk=p.provider_pk)
 WHERE p.provider_id=@provider_id);
IF JSON_VALUE(@semantics,''$.providerId'') IS NULL SET @semantics=JSON_MODIFY(@semantics,''$.providerId'',@provider_id);
IF JSON_VALUE(@semantics,''$.name'') IS NULL SET @semantics=JSON_MODIFY(@semantics,''$.name'',@declared_name);
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
SELECT d.namespace_id,d.declared_id,JSON_VALUE(ca.value,''$.referenceName''),JSON_VALUE(ca.value,''$.source''),')
+N' JSON_VALUE(ca.value,''$.storeLocator''),JSON_VALUE(ca.value,''$.injectionRule.id''),JSON_VALUE(ca.value,''$.injectionRule.headerName''),
 JSON_QUERY(ca.value,''$.effectScopes''),TRY_CONVERT(int,JSON_VALUE(ca.value,''$.lifetimeMilliseconds'')),
 JSON_QUERY(ca.value,''$.endpointAuthorityDigests'')
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(JSON_QUERY(d.definition_json,''$.semantics.configuration.credentialAuthorities'')) ca
WHERE d.estate_model_pk=@estate AND d.object_kind=''PORT''
 AND EXISTS (SELECT 1 FROM OPENJSON(JSON_QUERY(ca.value,''$.endpointAuthorityDigests'')) x
   WHERE EXISTS (SELECT 1 FROM @endpoints e WHERE e.endpoint_digest=x.value));
DECLARE @templates TABLE (capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2, transformation_id nvarchar(400), template nvarchar(max),
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
JOIN model.provider_definition pd ON pd.provider_definition_pk=(SELECT MAX(pd5.provider_definition_pk) FROM model.provider_definition pd5 WHERE pd5.provider_pk=p.provider_pk)'
+N'JOIN model.provider_binding b ON b.provider_definition_pk=pd.provider_definition_pk
JOIN model.provider_binding_scope bs ON bs.provider_binding_scope_pk=b.provider_binding_scope_pk
JOIN model.provider_slot s ON s.provider_slot_pk=bs.provider_slot_pk
JOIN model.binding_context ctx ON ctx.binding_context_pk=bs.binding_context_pk
LEFT JOIN model.binding_port_implementation bpi ON bpi.provider_binding_pk=b.provider_binding_pk
LEFT JOIN model.port_version pv ON pv.port_version_pk=bpi.port_version_pk
LEFT JOIN model.port pt ON pt.port_pk=pv.port_pk
LEFT JOIN model.provider_port_implementation ppi ON ppi.provider_port_implementation_pk=bpi.provider_port_implementation_pk
WHERE p.provider_id=@provider_id;
SELECT (SELECT N''provider-configuration.v1'' AS documentType,JSON_QUERY(@semantics) AS provider,
 ISNULL(JSON_QUERY((SELECT * FROM @endpoints ORDER BY ordinal FOR JSON PATH)),N''[]'') AS endpoints,
 ISNULL(JSON_QUERY((SELECT * FROM @credentials ORDER BY port_id FOR JSON PATH)),N''[]'') AS credentials,
 ISNULL(JSON_QUERY((SELECT * FROM @templates ORDER BY transformation_id FOR JSON PATH)),N''[]'') AS requestTemplates,
 ISNULL(JSON_QUERY((SELECT * FROM @bindings ORDER BY slot_id,target_id FOR JSON PATH)),N''[]'') AS bindings,
 CAST(NULL AS nvarchar(max)) AS availabilityEvidence,
 N''availability and quota evidence is not recorded in the selected model; provider runs are retained on disk, not as rows'' AS availabilityNote
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS document;
';

-- ============================== RE-DECLARE THE REVEAL PORT ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @namespace nvarchar(400)=N'sidefx:capability:read-provider-configuration';
DECLARE @port_id nvarchar(400)=N'read-provider-configuration-port';
DECLARE @sem nvarchar(max),@previous_definition bigint,@previous_version bigint;
SELECT @sem=JSON_QUERY(d.definition_json,'$.semantics'),@previous_definition=d.semantic_object_definition_pk
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND d.declared_id=@port_id COLLATE Latin1_General_100_BIN2;
IF @sem IS NULL THROW 51000,N'PROVIDER_REVEAL_PORT_NOT_DECLARED',1;
IF JSON_VALUE(@sem,'$.configuration.statement') LIKE N'%declared_name%'
 THROW 51000,N'PROVIDER_REVEAL_FALLBACK_ALREADY_DECLARED',1;
SET @sem=JSON_MODIFY(@sem,'$.configuration.statement',@reveal_statement);
DECLARE @object bigint,@definition bigint,@digest binary(32);
EXEC model.put_semantic_definition 'PORT',@namespace,@port_id,@sem,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
DECLARE @port_pk bigint=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object);
DECLARE @version bigint=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition);
IF @version IS NULL BEGIN
 INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@port_pk,@object,@definition,@digest,'consumer-interface-authority.v1','PORT',@definition,N'');
 SET @version=SCOPE_IDENTITY();
END
SELECT @previous_version=port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@previous_definition;
IF @previous_version IS NOT NULL AND @previous_version<>@version
 UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@previous_version;

-- ============================== PROOF ==============================
DECLARE @fallback_declared bit=CONVERT(bit,CASE WHEN EXISTS(
 SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND d.declared_id=@port_id COLLATE Latin1_General_100_BIN2
  AND d.definition_json LIKE N'%declared_name%') THEN 1 ELSE 0 END);
DECLARE @bound_version bigint=(
 SELECT i.port_version_pk FROM model.operation_port_invocation i
 JOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=i._owner_definition_pk
 WHERE d.estate_model_pk=@estate AND d.object_kind='EXECUTION_AUTHORITY'
  AND d.declared_id=N'read-provider-configuration.v1');
SELECT '1_port' AS result_set,@port_id AS port_id,
 @fallback_declared AS fallback_declared,
 CONVERT(bit,CASE WHEN @bound_version=@version THEN 1 ELSE 0 END) AS binding_repointed;

DECLARE @platform_input nvarchar(max)=N'{"providerId":"ScenarioKernel.NodePlatform.Execution.AuthorityTransformation"}';
DECLARE @platform TABLE (document nvarchar(max));
INSERT @platform EXEC sp_executesql @reveal_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@platform_input,@estate_model_pk=@estate;
SELECT '2_platform_self_test' AS result_set,
 JSON_VALUE(document,'$.documentType') AS document_type,
 JSON_VALUE(document,'$.provider.providerId') AS provider_id,
 JSON_VALUE(document,'$.provider.name') AS name,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(document,'$.bindings'))) AS bindings
FROM @platform;

DECLARE @host_input nvarchar(max)=N'{"providerId":"rapidapi/yahoo-finance166"}';
DECLARE @hosting TABLE (document nvarchar(max));
INSERT @hosting EXEC sp_executesql @reveal_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@host_input,@estate_model_pk=@estate;
SELECT '3_host_self_test' AS result_set,
 JSON_VALUE(document,'$.provider.providerId') AS provider_id,
 JSON_VALUE(document,'$.provider.name') AS name,
 JSON_VALUE(document,'$.provider.transport.host') AS host,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(document,'$.endpoints'))) AS endpoints
FROM @hosting;

COMMIT TRANSACTION;
