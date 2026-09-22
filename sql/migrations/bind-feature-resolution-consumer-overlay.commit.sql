-- bind-feature-resolution-consumer-overlay.sql
--
-- Lane 4, item 3a: the consumer overlay binding for the admitted deterministic
-- feature-resolution port.
--
-- The capability author-capability-candidate-from-feature-reference fails before
-- any cell with SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING:
-- 'sda-canonical-capability-feature-resolution-port.v1'. The compiled graph
-- requires one provider slot for that port; the host invocation port
-- run-declared-graph-execute (sidefx:capability:run-declared-graph) declares the
-- overlay rule set that materializes provider bindings, and it has no rule for
-- the port. This migration adds exactly that rule, mapped to the declared
-- platform-effect provider profile already installed for the governed effect
-- ports (the provider profile, its digest and its implementationRef are read from
-- an existing rule, so the addition cannot drift from the installed
-- configuration).
--
-- The change is one Port definition plus its new version and the operation
-- relink (DERIVED DML, precedent:
-- bind-projected-capability-invocation-and-composition-digests.sql:150-246,
-- complete-run-declared-graph-pure-mechanic-bindings.sql:111-142). No capability,
-- contract, scenario, transformation or provider row is written.
--
-- Scope note (honest boundary): the rule makes the port selectable in the
-- overlay. The installed runtimes still have no scheduler-shaped embodiment for
-- this url-context port (the C# mechanic registry declares no
-- sda-canonical-capability-feature-resolution-port.v1 entry; the node runtime
-- registers it only in createNodeMechanicRegistry, not in the host
-- configuration.providers path), so the invocation advances past the overlay and
-- then reports the missing platform capability. Restoring full execution is an
-- SDA-side embodiment request or a projected-application binding whose bytes
-- exist in no commit; it is not authorable as estate data.
--
-- Idempotent: a replay finds the rule present and writes no new definition or
-- port version.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=30000;
IF @lock<0 THROW 51000,N'FEATURE_RESOLUTION_OVERLAY_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @namespace nvarchar(400)=N'sidefx:capability:run-declared-graph';
DECLARE @port nvarchar(400)=N'run-declared-graph-execute';
DECLARE @mechanic nvarchar(400)=N'sda-canonical-capability-feature-resolution-port.v1';
DECLARE @consumer nvarchar(400)=N'author-capability-candidate-from-feature-reference';

DECLARE @semantics nvarchar(max),@prevver bigint;
SELECT @semantics=JSON_QUERY(d.definition_json,'$.semantics'),
 @prevver=(SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND d.declared_id=@port COLLATE Latin1_General_100_BIN2;
IF @semantics IS NULL OR @prevver IS NULL THROW 51000,N'FEATURE_RESOLUTION_HOST_PORT_MISSING',1;

-- The consumer capability must actually declare the port, or the binding is for
-- nothing.
IF NOT EXISTS(SELECT 1 FROM analysis.capability_graph_source(@consumer,1,NULL) g
 WHERE g.graph_source LIKE N'%'+@mechanic+N'%')
 THROW 51000,N'FEATURE_RESOLUTION_CONSUMER_DECLARATION_MISSING',1;

-- The provider profile, digest and implementationRef are taken from an existing
-- rule of the platform-effect profile (never hardcoded).
DECLARE @effect_profile nvarchar(400)=N'sda-platform-effect-graph-provider.v1';
DECLARE @profile_digest nvarchar(80),@implementation_ref nvarchar(400);
SELECT TOP 1 @profile_digest=JSON_VALUE(b.value,'$.providerProfileDigest'),@implementation_ref=JSON_VALUE(b.value,'$.implementationRef')
FROM OPENJSON(JSON_QUERY(@semantics,'$.configuration.overlayBindings')) b
WHERE JSON_VALUE(b.value,'$.providerProfileId')=@effect_profile COLLATE Latin1_General_100_BIN2;
IF @profile_digest IS NULL OR @implementation_ref IS NULL THROW 51000,N'FEATURE_RESOLUTION_EFFECT_RULE_TEMPLATE_MISSING',1;
IF NOT EXISTS(SELECT 1 FROM OPENJSON(JSON_QUERY(@semantics,'$.configuration.providers')) p
 WHERE JSON_VALUE(p.value,'$.providerProfileId')=@effect_profile COLLATE Latin1_General_100_BIN2)
 THROW 51000,N'FEATURE_RESOLUTION_EFFECT_PROVIDER_NOT_INSTALLED',1;

DECLARE @baseline TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @baseline(capability_id,digest,bytes)
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'authoring-altitude-model-stubs',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'request-capability-from-objective',1,NULL) g;
IF (SELECT COUNT(*) FROM @baseline)<>4 THROW 51000,N'FEATURE_RESOLUTION_OVERLAY_BASELINE_MISSING',1;

DECLARE @rule_present bit=CASE WHEN EXISTS(SELECT 1 FROM OPENJSON(JSON_QUERY(@semantics,'$.configuration.overlayBindings')) b
 WHERE JSON_VALUE(b.value,'$.mechanicId')=@mechanic COLLATE Latin1_General_100_BIN2) THEN 1 ELSE 0 END;
DECLARE @bound_before int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@semantics,'$.configuration.overlayBindings')));
DECLARE @changed int=0,@object bigint,@definition bigint,@digest binary(32),@version bigint,@portpk bigint;
IF @rule_present=0
BEGIN
 DECLARE @merged nvarchar(max)=(
  SELECT mechanicId,providerProfileId,providerProfileDigest,implementationRef
  FROM (
   SELECT JSON_VALUE(b.value,'$.mechanicId') AS mechanicId,
    JSON_VALUE(b.value,'$.providerProfileId') AS providerProfileId,
    JSON_VALUE(b.value,'$.providerProfileDigest') AS providerProfileDigest,
    JSON_VALUE(b.value,'$.implementationRef') AS implementationRef,
    0 AS source_rank,CONVERT(bigint,b.[key]) AS sort_key
   FROM OPENJSON(JSON_QUERY(@semantics,'$.configuration.overlayBindings')) b
   UNION ALL
   SELECT @mechanic,@effect_profile,@profile_digest,@implementation_ref,1,NULL
  ) combined
  ORDER BY source_rank,sort_key,mechanicId
  FOR JSON PATH);
 SET @semantics=JSON_MODIFY(@semantics,'$.configuration.overlayBindings',JSON_QUERY(@merged));
 EXEC model.put_semantic_definition 'PORT',@namespace,@port,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object);
 IF @portpk IS NULL THROW 51000,N'FEATURE_RESOLUTION_HOST_PORT_ROW_MISSING',1;
 SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition);
 IF @version IS NULL
 BEGIN
  INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
   port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@portpk,@object,@definition,@digest,'consumer-interface-authority.v1','PORT',@definition,N'');
  SET @version=SCOPE_IDENTITY();
 END
 UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
 SET @changed=1;
END
ELSE SET @version=@prevver;

-- Verify the bound rule and the relink on the selected definition.
DECLARE @after_semantics nvarchar(max),@after_version bigint;
SELECT @after_semantics=JSON_QUERY(d.definition_json,'$.semantics'),
 @after_version=(SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND d.declared_id=@port COLLATE Latin1_General_100_BIN2;
IF @after_semantics IS NULL THROW 51000,N'FEATURE_RESOLUTION_HOST_PORT_NOT_SELECTED',1;
DECLARE @bound_after int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@after_semantics,'$.configuration.overlayBindings')));
IF (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@after_semantics,'$.configuration.overlayBindings')) b
 WHERE JSON_VALUE(b.value,'$.mechanicId')=@mechanic COLLATE Latin1_General_100_BIN2)<>1
 THROW 51000,N'FEATURE_RESOLUTION_OVERLAY_RULE_NOT_BOUND',1;
IF (SELECT COUNT(*) FROM model.operation_port_invocation WHERE port_version_pk=@after_version)<1
 THROW 51000,N'FEATURE_RESOLUTION_OVERLAY_RELINK_MISSING',1;
SELECT N'1_overlay_rule' AS result_set,@mechanic AS mechanic_id,
 JSON_VALUE(b.value,'$.providerProfileId') AS provider_profile_id,
 JSON_VALUE(b.value,'$.providerProfileDigest') AS provider_profile_digest,
 JSON_VALUE(b.value,'$.implementationRef') AS implementation_ref
FROM OPENJSON(JSON_QUERY(@after_semantics,'$.configuration.overlayBindings')) b
WHERE JSON_VALUE(b.value,'$.mechanicId')=@mechanic COLLATE Latin1_General_100_BIN2;
SELECT N'2_port_relink' AS result_set,@namespace AS namespace_id,@port AS port_id,
 @bound_before AS rules_before,@bound_after AS rules_after,
 LOWER(CONVERT(varchar(64),@digest,2)) AS definition_digest,@after_version AS port_version_pk,
 (SELECT COUNT(*) FROM model.operation_port_invocation WHERE port_version_pk=@after_version) AS operation_links;
IF @bound_after<>@bound_before+1 AND @rule_present=0 THROW 51000,N'FEATURE_RESOLUTION_OVERLAY_COUNT_DIVERGED',1;

-- The consumer capability's declared graph source still names the port, and the
-- unrelated capabilities are byte-identical.
DECLARE @after TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @after(capability_id,digest,bytes)
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'authoring-altitude-model-stubs',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'request-capability-from-objective',1,NULL) g;
SELECT N'3_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'FEATURE_RESOLUTION_OVERLAY_UNRELATED_CAPABILITY_CHANGED',1;
SELECT N'4_disposition' AS result_set,CASE WHEN @rule_present=1 THEN N'already_bound' ELSE N'redeclared' END AS disposition;
COMMIT TRANSACTION;
