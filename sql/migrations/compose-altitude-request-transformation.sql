-- compose-altitude-request-transformation.sql
--
-- Lane 1, item 2 of docs/compact-altitude-request-plan-2026-09-22.md: the
-- composing adapter transformation `compose-altitude-request.v1`, declared as
-- rows with model.put_semantic_definition 'TRANSFORMATION' +
-- model.normalize_transformation_expression (EXISTING PROCEDURES).
--
-- Carrier contract. The transformation input is the altitude carrier: the
-- object the altitude operation receives. It maps exactly six members:
--
--   altitude          <- input.altitude
--   toolId            <- input.toolId
--   objective         <- input.objective
--   inputContractId   <- input.inputContractId
--   contextRefs       <- input.contextRefs[*]  reduced to {kind,id,digest}
--   contextSlices     <- input.contextSlices[*] reduced to {ref,document}
--
-- It emits NOTHING else: no graphSource, no authority, no catalog, no plan, no
-- currentInvocationRequest, no pass-through of any carrier member. Unrecognised
-- carrier members are dropped by construction (the expression is a fixed
-- object literal), so a carrier that carried the compiled estate context
-- composes a KB-scale request. Absent contextRefs/contextSlices compose as empty
-- arrays; the 256 KB cap and the embedded-context refusal are enforced by the
-- guard capability in enforce-altitude-request-cap.sql (item 3).
--
-- Discovery correction. The plan named
-- `configuration.requestPath`/`requestTransformationRef` as the binding point.
-- The installed port mechanics have no `requestTransformationRef` member:
-- `configuration.requestPath` is a VALUE PATH into the invocation carrier
-- (sda-projected-capability-invocation-port.v2 reads `valueAt(input, requestPath)`;
-- generic-llm-connector-provider.mjs reads the same member), and the graph
-- compiler resolves a transformation only through a port binding's
-- `configuration.transformationId` (SemanticExecutionGraphCompiler
-- transformationById). The adapter therefore travels as a declared
-- TRANSFORMATION referenced by an operation port; L3 adds that operation ahead
-- of each live model operation and sets the model port's requestPath to the
-- adapter output. No port row is written here.
--
-- The transformation is declared in the altitude capability's namespace so the
-- altitude graph source (analysis.capability_graph_source reach) carries it.
-- A probe capability (`probe-compose-altitude-request`) carries a byte-identical
-- second declaration in its own namespace so the expression can be evaluated
-- end-to-end through the kernel from this migration's uncommitted state
-- (invoke-from-transaction preflight); the canonical copy is the altitude one.
--
-- Idempotent: content-addressed definitions and the document digest gate; the
-- replay proof re-runs the declarations and requires no new version.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=300000;
IF @lock<0 THROW 51000,N'ALTITUDE_ADAPTER_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

-- ============================== BASELINE ==============================
DECLARE @baseline TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64));
INSERT @baseline(capability_id,digest)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'route-two-child-proof',1,NULL) g;
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'ALTITUDE_ADAPTER_BASELINE_MISSING',1;

-- ============================== THE ADAPTER EXPRESSION ==============================
-- The expression uses only mechanics the estate already declares as pure and
-- binds for the node target (object, path, literal, if, map, array). It avoids
-- `type`/`equals` shape tests: an absent or empty collection is falsy at the
-- boolean-selection junction, so the else branch composes `[]`; a declared
-- array composes its reduced members.
DECLARE @adapter_id nvarchar(400)=N'compose-altitude-request.v1';
DECLARE @altitude_namespace nvarchar(400)=N'sidefx:capability:authoring-altitude-model-stubs';
DECLARE @probe_capability nvarchar(400)=N'probe-compose-altitude-request';
DECLARE @probe_namespace nvarchar(400)=N'sidefx:capability:'+@probe_capability;
DECLARE @expression nvarchar(max)=
  N'{"op":"object","fields":{'
 +N'"altitude":{"op":"path","from":"input","path":"altitude"},'
 +N'"toolId":{"op":"path","from":"input","path":"toolId"},'
 +N'"objective":{"op":"path","from":"input","path":"objective"},'
 +N'"inputContractId":{"op":"path","from":"input","path":"inputContractId"},'
 +N'"contextRefs":{"op":"if","when":{"op":"path","from":"input","path":"contextRefs"},"then":{"op":"map","from":{"op":"path","from":"input","path":"contextRefs"},"as":"ref","value":{"op":"object","fields":{"kind":{"op":"path","from":"ref","path":"kind"},"id":{"op":"path","from":"ref","path":"id"},"digest":{"op":"path","from":"ref","path":"digest"}}}},"else":{"op":"array","items":[]}},'
 +N'"contextSlices":{"op":"if","when":{"op":"path","from":"input","path":"contextSlices"},"then":{"op":"map","from":{"op":"path","from":"input","path":"contextSlices"},"as":"slice","value":{"op":"object","fields":{"ref":{"op":"path","from":"slice","path":"ref"},"document":{"op":"path","from":"slice","path":"document"}}}},"else":{"op":"array","items":[]}}'
 +N'}}';
DECLARE @semantics nvarchar(max)=N'{"id":"'+@adapter_id+N'","expression":'+@expression+N'}';

-- ============================== DECLARE (ALTITUDE + PROBE) ==============================
DECLARE @declared TABLE(ordinal int IDENTITY(1,1) PRIMARY KEY,namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2,transformation_id nvarchar(400) COLLATE Latin1_General_100_BIN2,object_pk bigint,definition_pk bigint,digest binary(32),transformation_pk bigint,transformation_version_pk bigint);
DECLARE @ns nvarchar(400),@tid nvarchar(400),@object bigint,@definition bigint,@digest binary(32),@transformation bigint,@version bigint;
DECLARE @declare_cursor CURSOR;
SET @declare_cursor=CURSOR LOCAL FAST_FORWARD FOR
 SELECT namespace_id,transformation_id FROM (VALUES (@altitude_namespace,@adapter_id),(@probe_namespace,@adapter_id)) v(namespace_id,transformation_id);
OPEN @declare_cursor;
FETCH NEXT FROM @declare_cursor INTO @ns,@tid;
WHILE @@FETCH_STATUS=0
BEGIN
 EXEC model.put_semantic_definition 'TRANSFORMATION',@ns,@tid,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 SET @transformation=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@object);
 IF @transformation IS NULL
 BEGIN
  INSERT model.transformation(namespace_pk,transformation_id,semantic_object_pk,object_kind)
  SELECT namespace_pk,@tid,@object,'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk=@object;
  SET @transformation=SCOPE_IDENTITY();
 END
 SET @version=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@definition);
 IF @version IS NULL
 BEGIN
  INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
   expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@transformation,@object,@definition,@digest,'json-expression-tree.v1','TRANSFORMATION',@definition,N'');
  SET @version=SCOPE_IDENTITY();
  EXEC model.normalize_transformation_expression @version;
 END
 INSERT @declared(namespace_id,transformation_id,object_pk,definition_pk,digest,transformation_pk,transformation_version_pk)
 VALUES(@ns,@tid,@object,@definition,@digest,@transformation,@version);
 FETCH NEXT FROM @declare_cursor INTO @ns,@tid;
END
CLOSE @declare_cursor; DEALLOCATE @declare_cursor;
IF (SELECT COUNT(*) FROM @declared)<>2 THROW 51000,N'ALTITUDE_ADAPTER_DECLARATION_INCOMPLETE',1;
-- Replay: both namespaces answer already-declared; no new transformation_version.
DECLARE @versions_before int=(SELECT COUNT(*) FROM model.transformation_version);
SET @declare_cursor=CURSOR LOCAL FAST_FORWARD FOR
 SELECT namespace_id,transformation_id FROM (VALUES (@altitude_namespace,@adapter_id),(@probe_namespace,@adapter_id)) v(namespace_id,transformation_id);
OPEN @declare_cursor;
FETCH NEXT FROM @declare_cursor INTO @ns,@tid;
WHILE @@FETCH_STATUS=0
BEGIN
 EXEC model.put_semantic_definition 'TRANSFORMATION',@ns,@tid,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 SET @version=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@definition);
 IF @version IS NULL THROW 51000,N'ALTITUDE_ADAPTER_REPLAY_MINTED_VERSION',1;
 FETCH NEXT FROM @declare_cursor INTO @ns,@tid;
END
CLOSE @declare_cursor; DEALLOCATE @declare_cursor;
IF (SELECT COUNT(*) FROM model.transformation_version)<>@versions_before THROW 51000,N'ALTITUDE_ADAPTER_REPLAY_WROTE',1;

-- ============================== PROBE CAPABILITY ==============================
-- A tiny capability whose only operation binds the transformation by id, so the
-- kernel resolves the declared AST (not an inline copy) and composes a request
-- from a sample carrier during the from-transaction preflight.
IF NOT EXISTS (SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='TRANSFORMATION' AND d.namespace_id=@probe_namespace COLLATE Latin1_General_100_BIN2
  AND d.declared_id=@adapter_id COLLATE Latin1_General_100_BIN2)
 THROW 51000,N'ALTITUDE_ADAPTER_PROBE_TRANSFORMATION_MISSING',1;
DECLARE @probe_document nvarchar(max)=N'{
 "document":"sidefx-capability-authority.v1",
 "capabilityId":"probe-compose-altitude-request",
 "meaning":{"intent":"prove the compact altitude request adapter composes from a sample carrier","outcome":"the compact altitude request is observable with no embedded context"},
 "cli":{"display":{"select":"outcome.payload","as":"json"}},
 "contracts":[
  {"id":"probe-compose-altitude-request-request.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/probe-compose-altitude-request-request.v1.schema.json","type":"object","additionalProperties":true}},
  {"id":"probe-compose-altitude-request-output.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/probe-compose-altitude-request-output.v1.schema.json","type":"object","additionalProperties":true}}
 ],
 "scenarios":[{
  "scenarioId":"probe-compose-altitude-request",
  "name":"Prove the composing adapter transformation",
  "inputId":"probe-compose-altitude-request-request",
  "inputContract":"probe-compose-altitude-request-request.v1",
  "eventId":"probe-compose-altitude-request-requested",
  "eventAuthority":"probe-compose-altitude-request.v1",
  "outcomeId":"probe-compose-altitude-request-output",
  "outcomeContract":"probe-compose-altitude-request-output.v1",
  "given":"a sample altitude carrier",
  "when":"the declared compose-altitude-request.v1 transformation evaluates",
  "then":"the compact altitude request is returned with no embedded context",
  "terminal":true,
  "root":true,
  "operations":[{"operationId":"probe-compose-altitude-request.0","kind":"invoke-port","portId":"probe-compose-altitude-request-port"}],
  "portBindings":[{"portId":"probe-compose-altitude-request-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"compose-altitude-request.v1"}}]
 }]
}';
EXEC model.declare_capability_document @document=@probe_document;

-- ============================== PROOFS ==============================
-- The altitude and probe definitions carry byte-identical semantics.
DECLARE @altitude_semantics nvarchar(max),@probe_semantics nvarchar(max),@altitude_version bigint,@probe_version bigint;
SELECT @altitude_semantics=JSON_QUERY(d.definition_json,'$.semantics'),
 @altitude_version=(SELECT tv.transformation_version_pk FROM model.transformation_version tv WHERE tv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='TRANSFORMATION' AND d.namespace_id=@altitude_namespace COLLATE Latin1_General_100_BIN2
 AND d.declared_id=@adapter_id COLLATE Latin1_General_100_BIN2;
SELECT @probe_semantics=JSON_QUERY(d.definition_json,'$.semantics'),
 @probe_version=(SELECT tv.transformation_version_pk FROM model.transformation_version tv WHERE tv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='TRANSFORMATION' AND d.namespace_id=@probe_namespace COLLATE Latin1_General_100_BIN2
 AND d.declared_id=@adapter_id COLLATE Latin1_General_100_BIN2;
IF @altitude_semantics IS NULL OR @probe_semantics IS NULL THROW 51000,N'ALTITUDE_ADAPTER_NOT_SELECTED',1;
IF @altitude_semantics<>@probe_semantics COLLATE Latin1_General_100_BIN2 THROW 51000,N'ALTITUDE_ADAPTER_PROBE_DIVERGED',1;
-- No embedded-context member is named anywhere in the expression.
IF @altitude_semantics LIKE N'%graphSource%' OR @altitude_semantics LIKE N'%currentInvocationRequest%'
 OR @altitude_semantics LIKE N'%"catalog"%' OR @altitude_semantics LIKE N'%"plan"%' OR @altitude_semantics LIKE N'%"authority"%'
 THROW 51000,N'ALTITUDE_ADAPTER_REFERENCES_EMBEDDED_CONTEXT',1;
-- The normalized root is an object; its `fields` node's direct members are exactly
-- the six compact members.
DECLARE @root_node bigint=(SELECT expression_node_pk FROM model.transformation_root WHERE transformation_version_pk=@altitude_version);
IF @root_node IS NULL THROW 51000,N'ALTITUDE_ADAPTER_TREE_MISSING',1;
DECLARE @fields_node bigint=(SELECT child_node_pk FROM model.transformation_expression_child
 WHERE parent_node_pk=@root_node AND member_name=N'fields' COLLATE Latin1_General_100_BIN2);
IF @fields_node IS NULL THROW 51000,N'ALTITUDE_ADAPTER_FIELDS_NODE_MISSING',1;
DECLARE @field_count int=(SELECT COUNT(*) FROM model.transformation_expression_child c WHERE c.parent_node_pk=@fields_node);
DECLARE @compact_fields int=(SELECT COUNT(*) FROM model.transformation_expression_child c WHERE c.parent_node_pk=@fields_node
 AND c.member_name COLLATE Latin1_General_100_BIN2 IN (N'altitude',N'toolId',N'objective',N'inputContractId',N'contextRefs',N'contextSlices'));
IF @field_count<>6 OR @compact_fields<>6 THROW 51000,N'ALTITUDE_ADAPTER_OUTPUT_SHAPE_CHANGED',1;

SELECT N'1_adapter_declaration' AS result_set,d.namespace_id,d.declared_id,
 LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS definition_digest,
 (SELECT COUNT(*) FROM model.transformation_expression_node n WHERE n.transformation_version_pk=tv.transformation_version_pk) AS normalized_nodes,
 (SELECT @field_count) AS root_fields
FROM analysis.v_selected_semantic_definition d
JOIN model.transformation_version tv ON tv.semantic_object_definition_pk=d.semantic_object_definition_pk
WHERE d.estate_model_pk=@estate AND d.object_kind=N'TRANSFORMATION' AND d.declared_id=@adapter_id
ORDER BY d.namespace_id;

-- The probe capability composes through the declared transformation id.
SELECT N'2_probe_binding' AS result_set,g.capability_id,g.root_scenario_id,
 j.value AS transformation_id
FROM analysis.capability_graph_source(N'probe-compose-altitude-request',1,NULL) g
CROSS APPLY OPENJSON(g.graph_source,'$.semanticTransformations') j
WHERE JSON_VALUE(j.value,'$.id')=@adapter_id;
IF NOT EXISTS (SELECT 1 FROM analysis.capability_graph_source(N'probe-compose-altitude-request',1,NULL) g
 CROSS APPLY OPENJSON(g.graph_source,'$.semanticTransformations') j WHERE JSON_VALUE(j.value,'$.id')=@adapter_id)
 THROW 51000,N'ALTITUDE_ADAPTER_PROBE_GRAPH_MISSING',1;

-- Unrelated graph digests byte-identical.
DECLARE @after TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64));
INSERT @after(capability_id,digest)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'route-two-child-proof',1,NULL) g;
SELECT N'3_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'ALTITUDE_ADAPTER_CHANGED_UNRELATED_CAPABILITY',1;

SELECT N'4_disposition' AS result_set,N'declared' AS disposition,@adapter_id AS transformation_id,
 @altitude_namespace AS canonical_namespace,@probe_namespace AS probe_namespace,
 @altitude_version AS canonical_version_pk,@probe_version AS probe_version_pk;
ROLLBACK TRANSACTION;
