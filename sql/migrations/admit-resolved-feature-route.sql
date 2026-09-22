-- admit-resolved-feature-route.sql
--
-- Lane 4, item 3b: the decided route stops admitting only the hard-coded equity
-- capability.
--
-- Today decide-agent-route (sidefx:capability:request-capability-from-objective)
-- admits a proposal only when the model-proposed capability equals the literal
-- 'resolve-equity-market-price-evidence' (declare-agent-relevance-filter.sql:194).
-- The resolved proposal already carries the declaration fact ('declared', read by
-- resolve-proposed-capability-port); this migration replaces the literal branch
-- with that declared predicate, so the route admits the requested feature --
-- any capability declared in the selected estate -- beyond the equity identity.
--
-- The change is one TRANSFORMATION re-put plus its normalized version (DERIVED
-- DML, precedent declare-agent-relevance-filter.sql:215-250). No capability,
-- contract, scenario, port or provider row is written. executionRequest keeps
-- its equity shape; the admitted-proposal child still invokes the static equity
-- scenario, so this file must not be installed alone for a non-equity proposal:
-- dynamic child dispatch is the execution-authority-change / placement-writer
-- work (or the select-authoring-tool C2 registry route) and is not authorable
-- here. The route admission predicate itself is the deliverable.
--
-- Idempotent: a replay finds the selected expression already carrying the
-- declared predicate and writes no new version.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=30000;
IF @lock<0 THROW 51000,N'RESOLVED_FEATURE_ROUTE_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @namespace nvarchar(400)=N'sidefx:capability:request-capability-from-objective';
DECLARE @transformation_id nvarchar(400)=N'decide-agent-route';
DECLARE @equity_literal nvarchar(400)=N'resolve-equity-market-price-evidence';

DECLARE @semantics nvarchar(max),@definition bigint,@prev_version bigint;
SELECT @semantics=JSON_QUERY(d.definition_json,'$.semantics'),@definition=d.semantic_object_definition_pk,
 @prev_version=(SELECT tv.transformation_version_pk FROM model.transformation_version tv
  WHERE tv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='TRANSFORMATION'
 AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
 AND d.declared_id=@transformation_id COLLATE Latin1_General_100_BIN2;
IF @semantics IS NULL THROW 51000,N'RESOLVED_FEATURE_TRANSFORMATION_NOT_SELECTED',1;
IF JSON_QUERY(@semantics,'$.expression.fields.route') IS NULL THROW 51000,N'RESOLVED_FEATURE_ROUTE_FIELD_MISSING',1;

-- The installed route carries an outer `declared` check and a nested
-- proposedCapability = 'resolve-equity-market-price-evidence' branch that is the
-- effective admission gate. The generalization is complete only when the route
-- subtree no longer names the equity literal at all.
DECLARE @literal_present bit=CASE WHEN JSON_QUERY(@semantics,'$.expression.fields.route') LIKE N'%'+@equity_literal+N'%' THEN 1 ELSE 0 END;
DECLARE @already bit=CASE WHEN @literal_present=0 THEN 1 ELSE 0 END;

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
IF (SELECT COUNT(*) FROM @baseline)<>4 THROW 51000,N'RESOLVED_FEATURE_ROUTE_BASELINE_MISSING',1;

DECLARE @declared_route nvarchar(max)=N'{"op":"if","when":{"op":"equals","left":{"op":"path","from":"input","path":"declared"},"right":{"op":"literal","value":1}},"then":{"op":"literal","value":"ADMITTED"},"else":{"op":"literal","value":"REFUSED"}}';
DECLARE @object bigint,@new_definition bigint,@digest binary(32),@version bigint,@transformation bigint;
IF @already=0
BEGIN
 SET @semantics=JSON_MODIFY(@semantics,'$.expression.fields.route',JSON_QUERY(@declared_route));
 EXEC model.put_semantic_definition 'TRANSFORMATION',@namespace,@transformation_id,@semantics,
  @object OUTPUT,@new_definition OUTPUT,@digest OUTPUT;
 SET @transformation=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@object);
 IF @transformation IS NULL
 BEGIN
  INSERT model.transformation(namespace_pk,transformation_id,semantic_object_pk,object_kind)
  SELECT namespace_pk,@transformation_id,@object,'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk=@object;
  SET @transformation=SCOPE_IDENTITY();
 END
 SET @version=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@new_definition);
 IF @version IS NULL
 BEGIN
  INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
   expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@transformation,@object,@new_definition,@digest,'json-expression-tree.v1','TRANSFORMATION',@new_definition,N'');
  SET @version=SCOPE_IDENTITY();
  EXEC model.normalize_transformation_expression @version;
 END
END
ELSE SET @version=@prev_version;

DECLARE @after_semantics nvarchar(max)='';
SELECT @after_semantics=JSON_QUERY(d.definition_json,'$.semantics')
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='TRANSFORMATION'
 AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
 AND d.declared_id=@transformation_id COLLATE Latin1_General_100_BIN2;
IF @after_semantics IS NULL THROW 51000,N'RESOLVED_FEATURE_ROUTE_NOT_SELECTED',1;
IF JSON_VALUE(@after_semantics,'$.expression.fields.route.when.left.path')<>N'declared'
 THROW 51000,N'RESOLVED_FEATURE_ROUTE_NOT_GENERALIZED',1;
IF JSON_QUERY(@after_semantics,'$.expression.fields.route') LIKE N'%'+@equity_literal+N'%'
 THROW 51000,N'RESOLVED_FEATURE_ROUTE_EQUITY_LITERAL_REMAINS',1;
IF (SELECT COUNT(*) FROM model.transformation_version tv JOIN model.transformation t ON t.transformation_pk=tv.transformation_pk
 WHERE t.transformation_id=@transformation_id AND tv.transformation_version_pk=@version)<1
 THROW 51000,N'RESOLVED_FEATURE_ROUTE_VERSION_MISSING',1;

IF @already=0 AND (SELECT definition_digest FROM model.transformation_version WHERE transformation_version_pk=@version)<>@digest
 THROW 51000,N'RESOLVED_FEATURE_ROUTE_VERSION_DIGEST_DIVERGED',1;
SELECT N'1_route_predicate' AS result_set,@transformation_id AS transformation_id,
 JSON_VALUE(@after_semantics,'$.expression.fields.route.when.left.path') AS predicate_left_path,
 JSON_VALUE(@after_semantics,'$.expression.fields.route.then.value') AS admitted_literal,
 JSON_VALUE(@after_semantics,'$.expression.fields.route.else.value') AS refused_literal,
 @version AS transformation_version_pk,
 LOWER(CONVERT(varchar(64),(SELECT definition_digest FROM model.transformation_version WHERE transformation_version_pk=@version),2)) AS definition_digest;

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
SELECT N'2_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id
 WHERE b.digest<>a.digest AND b.capability_id<>N'request-capability-from-objective')
 THROW 51000,N'RESOLVED_FEATURE_ROUTE_UNRELATED_CAPABILITY_CHANGED',1;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id
 WHERE b.capability_id=N'request-capability-from-objective' AND b.digest=a.digest)
 AND @already=0 THROW 51000,N'RESOLVED_FEATURE_ROUTE_CONSUMER_DIGEST_UNCHANGED',1;
SELECT N'3_disposition' AS result_set,CASE WHEN @already=1 THEN N'already_generalized' ELSE N'redeclared' END AS disposition;
ROLLBACK TRANSACTION;
