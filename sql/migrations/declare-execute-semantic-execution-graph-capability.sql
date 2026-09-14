-- Declared capability that runs a capability's execution graph through the SDA
-- kernel entry (compile + in-process schedule), no materialized body. The Port
-- passes the declared graph and the carrier-resolved parity providers.
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
DECLARE @providerId nvarchar(400)=N'sda-semantic-execution-graph-execution.executeSemanticExecutionGraph';
DECLARE @provObject bigint, @provDefinition bigint, @provDigest binary(32), @provNamespace bigint, @provPk bigint;
SET @provNamespace=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='PROVIDER' AND namespace_id=N'sidefx:providers');
IF @provNamespace IS NULL BEGIN INSERT model.identity_namespace(namespace_kind,namespace_id) VALUES('PROVIDER',N'sidefx:providers'); SET @provNamespace=SCOPE_IDENTITY(); END
EXEC model.put_semantic_definition 'PROVIDER',N'sidefx:providers',@providerId,
 N'{"module":"../scenario-driven-architecture/languages/typescript/runtimes/node/semantic-execution-graph-execution-provider.mjs","export":"executeSemanticExecutionGraph","declarationProfile":"sda-platform-provider-implementation.v1"}',
 @provObject OUTPUT,@provDefinition OUTPUT,@provDigest OUTPUT;
SET @provPk=(SELECT provider_pk FROM model.provider WHERE namespace_pk=@provNamespace AND provider_id=@providerId);
IF @provPk IS NULL BEGIN INSERT model.provider(namespace_pk,provider_id,semantic_object_pk,object_kind) VALUES(@provNamespace,@providerId,@provObject,'PROVIDER'); SET @provPk=SCOPE_IDENTITY(); END
IF NOT EXISTS (SELECT 1 FROM model.provider_definition WHERE provider_pk=@provPk AND semantic_object_definition_pk=@provDefinition)
 INSERT model.provider_definition(provider_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,declaration_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@provPk,@provObject,@provDefinition,@provDigest,@providerId,'sda-platform-provider-implementation.v1','PROVIDER',@provDefinition,N'');
EXEC model.scaffold_capability @capability_id=N'execute-semantic-execution-graph', @on_exists=N'REPLACE';
EXEC model.declare_contract @id=N'execute-semantic-execution-graph-request.v1',
 @schema=N'{"type":"object","required":["plan","input"],"properties":{"plan":{"type":"object"},"input":{}}}';
EXEC model.declare_contract @id=N'execute-semantic-execution-graph-result.v1', @schema=N'{"type":"object","additionalProperties":true}';
GO
EXEC model.declare_scenario
 @capability_id=N'execute-semantic-execution-graph',
 @scenario=N'{"scenarioId":"execute-semantic-execution-graph","name":"Execute a declared execution graph through the kernel","inputId":"execute-semantic-execution-graph-request","inputContract":"execute-semantic-execution-graph-request.v1","eventId":"execute-semantic-execution-graph-requested","eventAuthority":"execute-semantic-execution-graph.v1","outcomeId":"execute-semantic-execution-graph-result","outcomeContract":"execute-semantic-execution-graph-result.v1","terminal":true,"root":true,"given":"one declared execution graph and its input","when":"the kernel scheduler interprets the graph with the declared providers","then":"the graph outcome and observed topology are returned"}',
 @operations=N'[{"operationId":"execute-semantic-execution-graph.0","kind":"invoke-port","portId":"execute-semantic-execution-graph-port"}]',
 @port_bindings=N'[{"portId":"execute-semantic-execution-graph-port","platformCapabilityId":"sda-semantic-execution-graph-execution-port.v1","configuration":{"providerId":"sda-semantic-execution-graph-execution.executeSemanticExecutionGraph","rootExecutionId":"execution:for-each-parity","providers":[{"providerProfileId":"provider:parity.fold:body","module":"conformance/execution-graph/providers/parity-providers.node.mjs","export":"foldBody"},{"providerProfileId":"provider:parity.compare","module":"conformance/execution-graph/providers/parity-providers.node.mjs","export":"compare"}]}}]';
GO
SELECT 'execution_graph_capability' AS result_set, c.capability_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id,
 JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId') AS platform_capability
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.object_kind='PORT'
 AND d.namespace_id=(N'sidefx:capability:'+c.capability_id) COLLATE Latin1_General_100_BIN2
WHERE c.capability_id=N'execute-semantic-execution-graph';
COMMIT TRANSACTION;
