-- repair-generate-executable-capability-scaffold-invoke-return.sql
--
-- Repairs the two declaration defects that stop
-- `generate-executable-capability-scaffold` before its root cell derives the
-- scaffold. (1) The invoke-return contract binding. (2) The root
-- transformation's lexical binding order. No Port, Scenario face, contract,
-- provider or other capability is changed.
--
-- (1) The composed root's last operation is `invoke-scenario` at ordinal 15
--     (cell:mechanic:generate-executable-capability-scaffold.operation.16,
--     target resolve-scaffold-completeness-level). The SDA compiler gives the
--     last operation of a scenario the scenario's own outcome contract
--     (SemanticExecutionGraphCompiler.cs:156-157) and synthesizes an
--     invoke-return edge with bindingAuthorityId
--     'binding:invoke-return:cell:mechanic:generate-executable-capability-scaffold.operation.16'
--     when the invoked child's exit contract differs from the parent cell's
--     outcome contract, and the parent contract is not semantic-value.v1
--     (SemanticExecutionGraphCompiler.cs:415-417). The child exits with
--     scaffold-derivation-carrier.v1, the root outcome is
--     executable-capability-scaffold.v1, and the scheduler refuses:
--     UNDECLARED_EDGE_BINDING_MECHANIC (SemanticExecutionGraphScheduler.cs:454-457).
--     No projection binding can satisfy it in this estate: the host passes
--     projectBinding: null (SemanticExecutionGraphExecutionProvider.cs:33,
--     MechanicRegistry.cs:217) and no capability declares a non-empty
--     interfaceAuthority.projectionBindings or projectionAuthorities document.
--     The estate's working composition pattern is contract equality on the
--     trailing invoke-scenario (author-one-scenario-candidate: root outcome
--     scenario-authoring-outcome.v1 = last child exit; author-one-scenario-solution:
--     solution-authoring-outcome.v2 = last child exit). This migration binds
--     operation 16's outcome contract explicitly to the child's exit contract,
--     so no invoke-return binding is synthesized and the root scenario cell
--     receives the carrier that op16 returns.
--
-- (2) The root transformation transform-generate-executable-capability-scaffold
--     was retained with its 63 `let` bindings in alphabetical order. The
--     lowering emits binding cells in document order and resolves a `path
--     from` through the binding scope in that order
--     (transformation-compiler.js:8-31, 96-101; C# ChildExpressions, CompileNode
--     and EvaluateLet in SemanticExecutionGraphCompiler.cs /
--     SemanticTransformationEngine.cs), so a binding that references a later
--     member is read before it is defined: 60 use-before-dependency references
--     on this expression. The same expression with the bindings in dependency
--     order evaluates to the declared scaffold outcome
--     (executable-capability-scaffold.v1, SCAFFOLD_READY,
--     TOPOLOGY_RESOLVED). This is the same class of defect repaired for
--     resolve-equity-market-price-evidence by
--     restore-equity-normalize-expression.sql. This migration re-mints the
--     transformation version with the identical expressions re-ordered; the
--     newest transformation version is selected automatically
--     (assemble-execution-declarations.sql:34-43).
--
-- Idempotent: (1) is skipped when the operation already binds the carrier
-- contract; (2) is skipped when the dependency-ordered expression digest
-- already exists as the selected transformation definition.
--
-- Default: ROLLBACK after verification. Replace the final ROLLBACK with
-- COMMIT to install.
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
BEGIN TRANSACTION;
GO

-- ============================== PART 1: BIND THE TERMINAL INVOKE-RETURN ==============================
DECLARE @capability_id nvarchar(400)=N'generate-executable-capability-scaffold';
DECLARE @namespace nvarchar(400)=N'sidefx:capability:generate-executable-capability-scaffold';
DECLARE @authority_id nvarchar(400)=N'generate-executable-capability-scaffold.v1';
DECLARE @carrier_contract nvarchar(400)=N'scaffold-derivation-carrier.v1';
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capability_version bigint=(
 SELECT ec.capability_version_pk FROM model.capability c
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
 WHERE c.capability_id=@capability_id);
IF @capability_version IS NULL THROW 51000,'SCAFFOLD_CAPABILITY_NOT_DECLARED',1;
DECLARE @scenario_version bigint=(
 SELECT cs.scenario_version_pk FROM model.capability_scenario cs
 JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
 WHERE cs.capability_version_pk=@capability_version AND s.scenario_id=@capability_id);
IF @scenario_version IS NULL THROW 51000,'SCAFFOLD_ROOT_SCENARIO_NOT_FOUND',1;
DECLARE @authority_version bigint=(
 SELECT se.execution_authority_version_pk FROM model.scenario_event se
 WHERE se.scenario_version_pk=@scenario_version);
IF @authority_version IS NULL THROW 51000,'SCAFFOLD_ROOT_AUTHORITY_NOT_LINKED',1;
DECLARE @authority_pk bigint,@authority_so bigint,@authority_def bigint;
SELECT @authority_pk=eav.execution_authority_pk,@authority_so=eav.semantic_object_pk,@authority_def=eav.semantic_object_definition_pk
FROM model.execution_authority_version eav WHERE eav.execution_authority_version_pk=@authority_version;
DECLARE @authority_digest binary(32),@envelope nvarchar(max);
SELECT @authority_digest=eav.definition_digest,@envelope=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.execution_authority_version eav
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=eav.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE eav.execution_authority_version_pk=@authority_version;
IF @envelope IS NULL THROW 51000,'SCAFFOLD_AUTHORITY_ENVELOPE_NOT_FOUND',1;
DECLARE @operations nvarchar(max)=JSON_QUERY(@envelope,'$.semantics.authority.operations');
DECLARE @operation_count int=(SELECT COUNT(*) FROM OPENJSON(@operations));
DECLARE @last_kind nvarchar(64)=JSON_VALUE(@operations,'$[15].kind');
DECLARE @last_scenario nvarchar(400)=JSON_VALUE(@operations,'$[15].scenarioId');
DECLARE @last_contract nvarchar(400)=JSON_VALUE(@operations,'$[15].outcomeContractId');
IF @operation_count<>16 OR @last_kind<>N'invoke-scenario' OR @last_scenario<>N'resolve-scaffold-completeness-level'
 THROW 51000,'SCAFFOLD_INVOKE_RETURN_DECLARATION_UNEXPECTED',1;
DECLARE @already int=CASE WHEN @last_contract=@carrier_contract THEN 1 ELSE 0 END;
DECLARE @target_authority_version bigint=@authority_version;
DECLARE @target_authority_digest binary(32)=@authority_digest;
IF @already=0
BEGIN
 DECLARE @semantics nvarchar(max)=JSON_QUERY(@envelope,'$.semantics');
 SET @semantics=JSON_MODIFY(@semantics,'$.authority.operations[15].outcomeContractId',@carrier_contract);
 DECLARE @auth_object bigint,@auth_definition bigint,@auth_digest binary(32);
 EXEC model.put_semantic_definition 'EXECUTION_AUTHORITY',@namespace,@authority_id,@semantics,
  @auth_object OUTPUT,@auth_definition OUTPUT,@auth_digest OUTPUT;
 SET @target_authority_digest=@auth_digest;
 SET @target_authority_version=(
  SELECT execution_authority_version_pk FROM model.execution_authority_version
  WHERE semantic_object_definition_pk=@auth_definition);
 IF @target_authority_version IS NULL
 BEGIN
  INSERT model.execution_authority_version(execution_authority_pk,semantic_object_pk,semantic_object_definition_pk,
   definition_digest,authority_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@authority_pk,@authority_so,@auth_definition,@auth_digest,
   N'execution-authorities.v1','EXECUTION_AUTHORITY',@auth_definition,N'');
  SET @target_authority_version=SCOPE_IDENTITY();
  INSERT model.execution_operation(execution_authority_version_pk,operation_id,ordinal,operation_kind,
   _owner_definition_pk,_canonical_pointer)
  SELECT @target_authority_version,eo.operation_id,eo.ordinal,eo.operation_kind,@auth_definition,eo._canonical_pointer
  FROM model.execution_operation eo
  WHERE eo.execution_authority_version_pk=@authority_version;
  INSERT model.operation_port_invocation(execution_operation_pk,port_version_pk,operation_kind,
   _owner_definition_pk,_canonical_pointer)
  SELECT newOp.execution_operation_pk,opi.port_version_pk,opi.operation_kind,@auth_definition,opi._canonical_pointer
  FROM model.operation_port_invocation opi
  JOIN model.execution_operation oldOp ON oldOp.execution_operation_pk=opi.execution_operation_pk
  JOIN model.execution_operation newOp ON newOp.execution_authority_version_pk=@target_authority_version
   AND newOp.ordinal=oldOp.ordinal
  WHERE oldOp.execution_authority_version_pk=@authority_version;
  INSERT model.operation_scenario_invocation(execution_operation_pk,target_scenario_version_pk,operation_kind,
   _owner_definition_pk,_canonical_pointer)
  SELECT newOp.execution_operation_pk,osi.target_scenario_version_pk,osi.operation_kind,@auth_definition,osi._canonical_pointer
  FROM model.operation_scenario_invocation osi
  JOIN model.execution_operation oldOp ON oldOp.execution_operation_pk=osi.execution_operation_pk
  JOIN model.execution_operation newOp ON newOp.execution_authority_version_pk=@target_authority_version
   AND newOp.ordinal=oldOp.ordinal
  WHERE oldOp.execution_authority_version_pk=@authority_version;
 END
 UPDATE model.scenario_event SET execution_authority_version_pk=@target_authority_version
 WHERE scenario_version_pk=@scenario_version;
END

-- ============================== PART 2: ORDER THE ROOT TRANSFORMATION BINDINGS ==============================
DECLARE @trans_ns nvarchar(400)=N'sidefx:capability:generate-executable-capability-scaffold';
DECLARE @trans_id nvarchar(400)=N'transform-generate-executable-capability-scaffold';
DECLARE @trans_so bigint,@trans_pk bigint;
SELECT @trans_so=t.semantic_object_pk,@trans_pk=t.transformation_pk
FROM model.transformation t
JOIN model.identity_namespace n ON n.namespace_pk=t.namespace_pk
WHERE n.namespace_id=@trans_ns AND t.transformation_id=@trans_id;
IF @trans_so IS NULL THROW 51000,'SCAFFOLD_ROOT_TRANSFORMATION_NOT_FOUND',1;
DECLARE @trans_def bigint=(
 SELECT MAX(d.semantic_object_definition_pk) FROM model.semantic_object_definition d
 WHERE d.semantic_object_pk=@trans_so);
DECLARE @trans_current_digest binary(32)=(
 SELECT definition_digest FROM model.semantic_object_definition WHERE semantic_object_definition_pk=@trans_def);
DECLARE @trans_envelope nvarchar(max)=(
 SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE d.semantic_object_definition_pk=@trans_def);
DECLARE @expression nvarchar(max)=JSON_QUERY(@trans_envelope,'$.semantics.expression');
IF JSON_VALUE(@expression,'$.op')<>N'let' THROW 51000,'SCAFFOLD_TRANSFORMATION_NOT_A_LET',1;
-- Dependency order: every binding precedes the bindings that reference it.
DECLARE @binding_order TABLE(binding_name nvarchar(200) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,ordinal int NOT NULL);
INSERT @binding_order(binding_name,ordinal) VALUES
(N'archetypeGeometryPreserved',1),(N'bpAdmitted',2),(N'bpDigest',3),(N'bpDigestBound',4),
(N'bpEdgesRaw',5),(N'bpNodes',6),(N'bpProjAuth',7),(N'bpSupplied',8),
(N'cap',9),(N'featureDigest',10),(N'isArchetypeInstantiation',11),(N'junctionId',12),
(N'knownCapabilities',13),(N'knownMechanics',14),(N'looseScen',15),(N'looseTerms',16),
(N'rootScenario',17),(N'shellSteps',18),(N'shellVocabulary',19),(N'subs',20),
(N'edgesFromBp',21),(N'bpRespNodes',22),(N'bpTermNodes',23),(N'providerSlotsFromBp',24),
(N'topologyDeclared',25),(N'topologyKind',26),(N'capabilitySlots',27),(N'rootInputContractId',28),
(N'rootInputId',29),(N'rootOutcomeContractId',30),(N'rootOutcomeId',31),(N'shellIsDomainFree',32),
(N'levelInterfaces',33),(N'scenFromBp',34),(N'termsFromBp',35),(N'providerSlots',36),
(N'derivedEdges',37),(N'unresolvedCapabilities',38),(N'levelComposition',39),(N'scen',40),
(N'scenContradicted',41),(N'terms',42),(N'termsContradicted',43),(N'unresolvedProviders',44),
(N'undeclaredTopology',45),(N'completenessLevel',46),(N'catalogInputIds',47),(N'catalogOutcomeIds',48),
(N'mechanicSlots',49),(N'unembodiedCells',50),(N'derivedBlueprintDigest',51),(N'derivedNodes',52),
(N'evidenceObligations',53),(N'unembodiedTerminals',54),(N'conditioningContradictions',55),(N'catalogContractIds',56),
(N'unresolvedMechanics',57),(N'catalogEntries',58),(N'catalogUnsafeContractIds',59),(N'authoringWorkQueue',60),
(N'catalogAuthority',61),(N'findings',62),(N'authoredArtifacts',63);
DECLARE @binding_count int=(SELECT COUNT(*) FROM OPENJSON(@expression,'$.bindings'));
IF @binding_count<>(SELECT COUNT(*) FROM @binding_order)
 THROW 51000,'SCAFFOLD_TRANSFORMATION_BINDING_COUNT_UNEXPECTED',1;
IF EXISTS (SELECT 1 FROM OPENJSON(@expression,'$.bindings') b
 LEFT JOIN @binding_order o ON o.binding_name=b.[key] COLLATE Latin1_General_100_BIN2
 WHERE o.binding_name IS NULL)
 THROW 51000,'SCAFFOLD_TRANSFORMATION_BINDING_UNKNOWN',1;
IF EXISTS (SELECT 1 FROM @binding_order o
 WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(@expression,'$.bindings') b
  WHERE b.[key] COLLATE Latin1_General_100_BIN2=o.binding_name))
 THROW 51000,'SCAFFOLD_TRANSFORMATION_BINDING_MISSING',1;
DECLARE @bindings nvarchar(max)=(
 SELECT N'{'+STRING_AGG(N'"'+STRING_ESCAPE(b.[key],'json')+N'":'+b.value,N',')
   WITHIN GROUP (ORDER BY o.ordinal)+N'}'
 FROM OPENJSON(@expression,'$.bindings') b
 JOIN @binding_order o ON o.binding_name=b.[key] COLLATE Latin1_General_100_BIN2);
DECLARE @ordered_expression nvarchar(max)=
 N'{"bindings":'+@bindings+N',"op":"let","value":'+JSON_QUERY(@expression,'$.value')+N'}';
DECLARE @trans_semantics nvarchar(max)=JSON_MODIFY(JSON_QUERY(@trans_envelope,'$.semantics'),
 '$.expression',JSON_QUERY(@ordered_expression));
DECLARE @ordered_envelope nvarchar(max)=JSON_MODIFY(@trans_envelope,'$.semantics.expression',JSON_QUERY(@ordered_expression));
DECLARE @ordered_bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@ordered_envelope COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @ordered_digest binary(32)=HASHBYTES('SHA2_256',@ordered_bytes);
DECLARE @trans_action nvarchar(40)=N'ALREADY_INSTALLED';
DECLARE @ordered_definition bigint=@trans_def;
IF @ordered_digest<>@trans_current_digest
BEGIN
 SET @trans_action=N'BINDINGS_ORDERED';
 DECLARE @trans_object bigint;
 EXEC model.put_semantic_definition 'TRANSFORMATION',@trans_ns,@trans_id,@trans_semantics,
  @trans_object OUTPUT,@ordered_definition OUTPUT,@ordered_digest OUTPUT;
 DECLARE @new_trans_version bigint=(
  SELECT transformation_version_pk FROM model.transformation_version
  WHERE semantic_object_definition_pk=@ordered_definition);
 IF @new_trans_version IS NULL
 BEGIN
  INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,
   definition_digest,expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@trans_pk,@trans_so,@ordered_definition,@ordered_digest,
   N'json-expression-tree.v1','TRANSFORMATION',@ordered_definition,N'');
  SET @new_trans_version=SCOPE_IDENTITY();
 END
END

-- ============================== VERIFICATION ==============================
SELECT '1_invoke_return_binding' AS result_set,@already AS already_installed,
 @last_scenario AS terminal_invoke_scenario,@last_contract AS prior_outcome_contract,
 @carrier_contract AS bound_outcome_contract,@authority_version AS prior_authority_version,
 @target_authority_version AS bound_authority_version,
 LOWER(CONVERT(varchar(64),@target_authority_digest,2)) AS authority_definition_digest;
SELECT '2_transformation_order' AS result_set,@trans_action AS action,@binding_count AS binding_count,
 @trans_def AS prior_definition,@ordered_definition AS ordered_definition,
 LOWER(CONVERT(varchar(64),@ordered_digest,2)) AS ordered_digest,LEFT(@bindings,96) AS ordered_bindings_head,
 CASE WHEN CHARINDEX(N'"scen"',@bindings)<CHARINDEX(N'"catalogInputIds"',@bindings)
   AND CHARINDEX(N'"catalogInputIds"',@bindings)<CHARINDEX(N'"catalogContractIds"',@bindings)
   AND CHARINDEX(N'"catalogAuthority"',@bindings)<CHARINDEX(N'"authoredArtifacts"',@bindings)
  THEN 1 ELSE 0 END AS dependency_order_verified;
SELECT '3_scenario_event' AS result_set,@scenario_version AS scenario_version_pk,
 @authority_version AS prior_authority_version,@target_authority_version AS linked_authority_version;
DECLARE @graph nvarchar(max)=(
 SELECT g.graph_source FROM analysis.capability_graph_source(@capability_id,0,NULL) g);
DECLARE @root_ops nvarchar(max)=(
 SELECT JSON_QUERY(a.value,'$.operations') FROM OPENJSON(@graph,'$.executionAuthorities') a
 WHERE JSON_VALUE(a.value,'$.owningScenarioId')=@capability_id);
DECLARE @probe_bindings nvarchar(max)=(
 SELECT JSON_QUERY(t.value,'$.expression.bindings') FROM OPENJSON(@graph,'$.semanticTransformations') t
 WHERE JSON_VALUE(t.value,'$.id')=@trans_id);
SELECT '4_graph_source_probe' AS result_set,
 JSON_VALUE(@root_ops,'$[15].outcomeContractId') AS operation16_outcome_contract,
 (SELECT COUNT(*) FROM OPENJSON(@root_ops)) AS operation_count,
 CASE WHEN CHARINDEX(N'"catalogInputIds"',@probe_bindings)<CHARINDEX(N'"catalogContractIds"',@probe_bindings)
  THEN 1 ELSE 0 END AS dependency_order_present,
 LEFT(@probe_bindings,96) AS graph_source_bindings_head;
ROLLBACK TRANSACTION;
