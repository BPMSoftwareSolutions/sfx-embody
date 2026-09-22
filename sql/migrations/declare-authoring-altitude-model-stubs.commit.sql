-- declare-authoring-altitude-model-stubs.sql
--
-- The claim under test: an LLM-provider STUB can be declared at every authoring
-- altitude as database rows, and the declared graph resolves and executes; no
-- altitude blocks declaration or execution.
--
-- One new capability `authoring-altitude-model-stubs` carries 11 STUB scenarios,
-- one per altitude (1 feature parse, 2 capability meaning, 3 scenario I/E/O,
-- 4 contracts/schemas, 5 semantic authority envelope, 6 transformation AST,
-- 7 execution authorities/ports, 8 providers/bindings/overlays, 9 interface/CLI
-- display, 10 fixtures/proof, 11 alignment evaluation). Every scenario declares
-- one STUB port bound to `sda-authority-transformation-port.v1` whose
-- transformation emits exactly one canned altitude-shaped output literal and
-- nothing else. The altitude outputs chain by contract equality: altitude N's
-- declared output contract is altitude N+1's declared input contract (the
-- estate's working drop-in composition pattern), and the root runs its own stub
-- first and then invokes the remaining altitudes in order, so one invocation
-- executes all 11 stub scenarios and ports and the observation lane testifies
-- for each.
--
-- Contract rows (12): one shared request (authoring-altitude-model-stubs-request.v1)
-- and one output per altitude (altitude-N-<name>-output.v1). Shapes are minimal
-- and derived from the per-tool shapes in
-- docs/llm-authoring-tools-2026-09-21/tool-to-altitude.v1.json and
-- tool-registry-and-write-sql.md: each canned object names its shape source.
--
-- Everything is authored with the estate's own procedures (model.declare_contract,
-- model.scaffold_capability, model.put_semantic_definition,
-- model.normalize_transformation_expression, model.declare_scenario,
-- model.declare_capability_feature) and the composed-authority mint pattern of
-- declare-run-declared-graph-capability.sql / declare-two-child-routing-proof.sql /
-- declare-agent-capability.sql. No existing capability, contract, scenario, port,
-- transformation, authority or provider row is modified.
--
-- Idempotent: the declaration is skipped when the capability already carries all
-- 11 scenarios; a replay prints `already_declared` and writes nothing.
--
-- Default: ROLLBACK after verification. The install is the .commit.sql copy
-- (final ROLLBACK replaced by COMMIT); run this file to dry-run.
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

-- ============================== 0. BASELINE GRAPH DIGESTS ==============================
-- Three unrelated capabilities whose assembled graph source must be byte-identical
-- before and after this declaration. The same three are re-read after declaration
-- and compared before the transaction is released.
DECLARE @baseline TABLE (capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY, digest varchar(64), bytes bigint);
INSERT @baseline (capability_id, digest, bytes)
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world', 1, NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'route-two-child-proof', 1, NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence', 1, NULL) g;
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'AUTHORING_ALTITUDE_BASELINE_MISSING',1;
SELECT N'0_baseline_digests' AS result_set, capability_id, digest AS graph_digest_before, bytes AS graph_source_bytes FROM @baseline ORDER BY capability_id;

-- ============================== 1. IDENTITY AND IDEMPOTENCE ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capability_id nvarchar(400)=N'authoring-altitude-model-stubs';
DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;
DECLARE @request_contract nvarchar(400)=N'authoring-altitude-model-stubs-request.v1';
DECLARE @alt TABLE (
 ordinal int NOT NULL PRIMARY KEY,
 altitude_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 altitude_name nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
 scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 authority_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 port_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 transformation_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 output_contract nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 tool_ref nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
 canned nvarchar(max) NOT NULL);
INSERT @alt VALUES (1,N'altitude-1-feature-parse',N'Feature parse',N'authoring-altitude-model-stubs',N'authoring-altitude-model-stubs.v1',N'authoring-altitude-model-stubs-port',N'authoring-altitude-model-stubs-transform.v1',N'altitude-1-feature-parse-output.v1',N'feature.resolve',N'{"capability":"resolve-equity-market-price-evidence","input":"AVGO","featureReference":"features/authoring-altitude-model-stubs.feature","classification":"AUTHOR_PROFILE"}');
INSERT @alt VALUES (2,N'altitude-2-capability-meaning',N'Capability meaning',N'altitude-2-capability-meaning',N'altitude-2-capability-meaning.v1',N'altitude-2-capability-meaning-stub-port',N'altitude-2-capability-meaning-stub-transform.v1',N'altitude-2-capability-meaning-output.v1',N'meaning.author',N'{"capabilityId":"authoring-altitude-model-stubs","meaning":{"name":"Declared model stubs at every authoring altitude","userStory":{"actor":"caller","intent":"author capability meaning","outcome":"meaning observable"},"experience":{"promise":"stub","observableConditions":["stub-condition"]}},"definitionDigest":"sha256:0000000000000000000000000000000000000000000000000000000000000002"}');
INSERT @alt VALUES (3,N'altitude-3-scenario-io',N'Scenario inputs/events/outcomes',N'altitude-3-scenario-io',N'altitude-3-scenario-io.v1',N'altitude-3-scenario-io-stub-port',N'altitude-3-scenario-io-stub-transform.v1',N'altitude-3-scenario-io-output.v1',N'scenario.author',N'{"result_set":"scenario_change_installed","capability_id":"authoring-altitude-model-stubs","scenario_id":"altitude-3-scenario-io","faces":["input","event","outcome"],"portBindings":[{"portId":"altitude-3-scenario-io-stub-port"}]}');
INSERT @alt VALUES (4,N'altitude-4-contracts-schemas',N'Contracts and schemas',N'altitude-4-contracts-schemas',N'altitude-4-contracts-schemas.v1',N'altitude-4-contracts-schemas-stub-port',N'altitude-4-contracts-schemas-stub-transform.v1',N'altitude-4-contracts-schemas-output.v1',N'contract.author',N'{"contract_id":"altitude-4-contracts-schemas-output.v1","definition_digest":"sha256:0000000000000000000000000000000000000000000000000000000000000004","schema_digest":"sha256:0000000000000000000000000000000000000000000000000000000000000004","faceBindings":[{"scenarioId":"altitude-4-contracts-schemas","face":"input"}]}');
INSERT @alt VALUES (5,N'altitude-5-semantic-authority-envelope',N'Semantic authority envelope',N'altitude-5-semantic-authority-envelope',N'altitude-5-semantic-authority-envelope.v1',N'altitude-5-semantic-authority-envelope-stub-port',N'altitude-5-semantic-authority-envelope-stub-transform.v1',N'altitude-5-semantic-authority-envelope-output.v1',N'semantics.author',N'{"address":{"id":"altitude-5-semantic-authority-envelope","kind":"AUTHORITY","namespace":"sidefx:stubs"},"format":"sidefx-semantic-definition.v1","semantics":{"envelope":"stub","altitude":5}}');
INSERT @alt VALUES (6,N'altitude-6-transformation-ast',N'Transformation AST',N'altitude-6-transformation-ast',N'altitude-6-transformation-ast.v1',N'altitude-6-transformation-ast-stub-port',N'altitude-6-transformation-ast-stub-transform.v1',N'altitude-6-transformation-ast-output.v1',N'ast.author',N'{"transformation_id":"altitude-6-transformation-ast-stub-transform.v1","transformation_version_pk":0,"expression":{"op":"object","fields":{"stub":{"op":"literal","value":true}}},"normalization":{"root":"stub","nodes":1}}');
INSERT @alt VALUES (7,N'altitude-7-execution-authorities-ports',N'Execution authorities and ports',N'altitude-7-execution-authorities-ports',N'altitude-7-execution-authorities-ports.v1',N'altitude-7-execution-authorities-ports-stub-port',N'altitude-7-execution-authorities-ports-stub-transform.v1',N'altitude-7-execution-authorities-ports-output.v1',N'authority.author',N'{"authority_id":"altitude-7-execution-authorities-ports.v1","definition_digest":"sha256:0000000000000000000000000000000000000000000000000000000000000007","operation_count":1,"operations":[{"operationId":"altitude-7-execution-authorities-ports.stub","kind":"invoke-port"}],"portBindings":[{"portId":"altitude-7-execution-authorities-ports-stub-port"}]}');
INSERT @alt VALUES (8,N'altitude-8-providers-bindings-overlays',N'Providers, bindings, overlays',N'altitude-8-providers-bindings-overlays',N'altitude-8-providers-bindings-overlays.v1',N'altitude-8-providers-bindings-overlays-stub-port',N'altitude-8-providers-bindings-overlays-stub-transform.v1',N'altitude-8-providers-bindings-overlays-output.v1',N'provider.author',N'{"providerId":"altitude-8-stub-provider","disposition":"PROVIDER_CHANGE_AUTHORED","bindingId":"altitude-8-providers-bindings-overlays-stub-binding.v1","overlay":{"mechanicId":"sda-authority-transformation-port.v1","providerProfileId":"sda-semantic-value-graph-provider.v1"}}');
INSERT @alt VALUES (9,N'altitude-9-interface-cli-display',N'Interface and CLI display',N'altitude-9-interface-cli-display',N'altitude-9-interface-cli-display.v1',N'altitude-9-interface-cli-display-stub-port',N'altitude-9-interface-cli-display-stub-transform.v1',N'altitude-9-interface-cli-display-output.v1',N'interface.author',N'{"capabilityId":"authoring-altitude-model-stubs","interfaceId":"altitude-9-interface-cli-display-cli","cli":{"input":{"type":"text","contract":"authoring-altitude-model-stubs-request.v1","path":"payload.objective"},"display":{"select":"outcome.canned","as":"json"}}}');
INSERT @alt VALUES (10,N'altitude-10-fixtures-proof',N'Fixtures and proof',N'altitude-10-fixtures-proof',N'altitude-10-fixtures-proof.v1',N'altitude-10-fixtures-proof-stub-port',N'altitude-10-fixtures-proof-stub-transform.v1',N'altitude-10-fixtures-proof-output.v1',N'fixture.author',N'{"fixture_id":"altitude-10-stub-fixture","input":{"contractId":"authoring-altitude-model-stubs-request.v1","payload":{}},"expected":{"disposition":"terminated","scenarioSequence":["altitude-10-fixtures-proof"]},"fixtureProfile":"consumer-capability-fixtures.v1"}');
INSERT @alt VALUES (11,N'altitude-11-alignment-evaluation',N'Alignment evaluation',N'altitude-11-alignment-evaluation',N'altitude-11-alignment-evaluation.v1',N'altitude-11-alignment-evaluation-stub-port',N'altitude-11-alignment-evaluation-stub-transform.v1',N'altitude-11-alignment-evaluation-output.v1',N'alignment.evaluate',N'{"candidateId":"altitude-11-stub-candidate","alignment":{"disposition":"ALIGNED","altitudes":11},"review":{"decision":"PENDING","reviewerAuthorityId":null},"contractId":"alignment-evaluation.v1"}');
IF (SELECT COUNT(*) FROM @alt)<>11 THROW 51000,N'AUTHORING_ALTITUDE_TABLE_INCOMPLETE',1;
DECLARE @capability_pk bigint=(SELECT c.capability_pk FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capability_id);
DECLARE @already bit=CASE WHEN @capability_pk IS NOT NULL AND (SELECT COUNT(*) FROM model.scenario s WHERE s.capability_pk=@capability_pk AND s.scenario_id IN (SELECT scenario_id FROM @alt))=11 THEN 1 ELSE 0 END;

IF @already=0
BEGIN
-- ============================== 2. CONTRACTS ==============================
-- One shared request contract and one output contract per altitude. All shapes are
-- minimal; the output schemas require exactly the canned members the stub emits.
DECLARE @request_schema nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/authoring-altitude-model-stubs-request.v1.schema.json","type":"object","additionalProperties":true,"properties":{"objective":{"type":"string"}}}';
EXEC model.declare_contract @request_contract, @request_schema;
DECLARE @c_ordinal int, @c_altitude_id nvarchar(400), @c_output nvarchar(400), @c_schema nvarchar(max);
DECLARE contract_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal, altitude_id, output_contract FROM @alt ORDER BY ordinal;
OPEN contract_cursor;
FETCH NEXT FROM contract_cursor INTO @c_ordinal, @c_altitude_id, @c_output;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @c_schema=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/'+@c_output+N'.schema.json","type":"object","additionalProperties":true,"required":["contractId","altitude","altitudeId","altitudeName","stub","shapeSource","canned"],"properties":{"contractId":{"const":"'+@c_output+N'"},"altitude":{"const":'+CONVERT(nvarchar(10),@c_ordinal)+N'},"altitudeId":{"const":"'+@c_altitude_id+N'"},"altitudeName":{"type":"string"},"stub":{"const":true},"shapeSource":{"type":"string"},"canned":{"type":"object"}}}';
 EXEC model.declare_contract @c_output, @c_schema;
 FETCH NEXT FROM contract_cursor INTO @c_ordinal, @c_altitude_id, @c_output;
END
CLOSE contract_cursor; DEALLOCATE contract_cursor;

-- ============================== 3. CAPABILITY SHELL ==============================
-- The shell creates the capability, its feature, its root scenario and the default
-- port/transformation in this capability's own namespace. Altitude 1 reuses those
-- two ids; every other altitude declares its own STUB port and transformation. The
-- shell's own request/greeting contracts are distinct placeholders so they cannot
-- shadow the shared request contract declared in section 2.
EXEC model.scaffold_capability @capability_id=@capability_id, @greeting_template=N'authoring-altitude-model-stubs STUB',
 @input_id=N'authoring-altitude-model-stubs-shell-request', @input_contract=N'authoring-altitude-model-stubs-shell-request.v1',
 @outcome_id=N'authoring-altitude-model-stubs-shell-greeting', @outcome_contract=N'authoring-altitude-model-stubs-shell-greeting.v1';
SET @capability_pk=(SELECT c.capability_pk FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capability_id);
IF @capability_pk IS NULL THROW 51000,N'AUTHORING_ALTITUDE_SHELL_NOT_CREATED',1;

-- ============================== 4. STUB TRANSFORMATIONS ==============================
-- Each transformation emits one canned altitude-shaped output literal. Input is
-- ignored by design (the altitude carrier is not interpreted by the stub).
DECLARE @t_ordinal int, @t_id nvarchar(400), @t_contract nvarchar(400), @t_altitude_id nvarchar(400), @t_name nvarchar(200), @t_tool nvarchar(200), @t_canned nvarchar(max), @t_expr nvarchar(max), @t_semantics nvarchar(max);
DECLARE @t_object bigint, @t_definition bigint, @t_digest binary(32), @t_pk bigint, @t_version bigint;
DECLARE transformation_cursor CURSOR LOCAL FAST_FORWARD FOR
 SELECT ordinal, transformation_id, output_contract, altitude_id, altitude_name, tool_ref, canned FROM @alt ORDER BY ordinal;
OPEN transformation_cursor;
FETCH NEXT FROM transformation_cursor INTO @t_ordinal, @t_id, @t_contract, @t_altitude_id, @t_name, @t_tool, @t_canned;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @t_expr=N'{"op":"object","fields":{"contractId":{"op":"literal","value":"'+@t_contract+N'"},"altitude":{"op":"literal","value":'+CONVERT(nvarchar(10),@t_ordinal)+N'},"altitudeId":{"op":"literal","value":"'+@t_altitude_id+N'"},"altitudeName":{"op":"literal","value":"'+@t_name+N'"},"stub":{"op":"literal","value":true},"shapeSource":{"op":"literal","value":"tool-to-altitude.v1.json#'+@t_tool+N'"},"canned":{"op":"literal","value":'+@t_canned+N'}}}';
 SET @t_semantics=N'{"id":"'+@t_id+N'","expression":'+@t_expr+N'}';
 EXEC model.put_semantic_definition 'TRANSFORMATION',@namespace,@t_id,@t_semantics,@t_object OUTPUT,@t_definition OUTPUT,@t_digest OUTPUT;
 SET @t_pk=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@t_object);
 IF @t_pk IS NULL
 BEGIN
  INSERT model.transformation(namespace_pk,transformation_id,semantic_object_pk,object_kind)
   SELECT namespace_pk,@t_id,@t_object,'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk=@t_object;
  SET @t_pk=SCOPE_IDENTITY();
 END
 SET @t_version=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@t_definition);
 IF @t_version IS NULL
 BEGIN
  INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@t_pk,@t_object,@t_definition,@t_digest,'json-expression-tree.v1','TRANSFORMATION',@t_definition,N'');
  SET @t_version=SCOPE_IDENTITY();
  EXEC model.normalize_transformation_expression @t_version;
 END
 FETCH NEXT FROM transformation_cursor INTO @t_ordinal, @t_id, @t_contract, @t_altitude_id, @t_name, @t_tool, @t_canned;
END
CLOSE transformation_cursor; DEALLOCATE transformation_cursor;

-- ============================== 5. STUB SCENARIOS ==============================
-- One scenario per altitude. Altitude 1 is the root (non-terminal) and carries the
-- shared request contract; every later altitude's input contract is the previous
-- altitude's output contract, so the whole chain is contract-clean. The root's
-- declared outcome is the LAST altitude's output contract: the root's trailing
-- operation is the invoke of altitude 11, whose exit contract must equal the root
-- outcome contract or the compiler synthesizes an undeclared invoke-return binding.
DECLARE @s_ordinal int, @s_altitude_id nvarchar(400), @s_name nvarchar(200), @s_scenario_id nvarchar(400), @s_authority nvarchar(400), @s_port nvarchar(400), @s_transform nvarchar(400), @s_out_contract nvarchar(400), @s_out_id nvarchar(400), @s_in_contract nvarchar(400), @s_scn nvarchar(max), @s_ops nvarchar(max), @s_bind nvarchar(max);
DECLARE scenario_cursor CURSOR LOCAL FAST_FORWARD FOR
 SELECT ordinal, altitude_id, altitude_name, scenario_id, authority_id, port_id, transformation_id, output_contract FROM @alt ORDER BY ordinal;
OPEN scenario_cursor;
FETCH NEXT FROM scenario_cursor INTO @s_ordinal, @s_altitude_id, @s_name, @s_scenario_id, @s_authority, @s_port, @s_transform, @s_out_contract;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @s_in_contract=CASE WHEN @s_ordinal=1 THEN @request_contract ELSE (SELECT output_contract FROM @alt WHERE ordinal=@s_ordinal-1) END;
 SET @s_out_contract=CASE WHEN @s_ordinal=1 THEN (SELECT output_contract FROM @alt WHERE ordinal=11) ELSE @s_out_contract END;
 SET @s_out_id=CASE WHEN @s_ordinal=1 THEN (SELECT altitude_id FROM @alt WHERE ordinal=11)+N'-output' ELSE @s_altitude_id+N'-output' END;
 SET @s_scn=N'{"scenarioId":"'+@s_scenario_id+N'","name":"STUB altitude '+CONVERT(nvarchar(10),@s_ordinal)+N': '+@s_name+N'","inputId":"'+@s_altitude_id+N'-request","inputContract":"'+@s_in_contract+N'","eventId":"'+@s_altitude_id+N'-requested","eventAuthority":"'+@s_authority+N'","outcomeId":"'+@s_out_id+N'","outcomeContract":"'+@s_out_contract+N'","given":"STUB: the altitude-'+CONVERT(nvarchar(10),@s_ordinal)+N' model-output carrier is declared","when":"STUB: the altitude stub port executes its canned transformation","then":"STUB: the canned '+@s_name+N' output is returned","root":'+CASE WHEN @s_ordinal=1 THEN N'true' ELSE N'false' END+N',"terminal":'+CASE WHEN @s_ordinal=1 THEN N'false' ELSE N'true' END+N'}';
 SET @s_ops=N'[{"operationId":"'+@s_altitude_id+N'.stub","kind":"invoke-port","portId":"'+@s_port+N'"}]';
 SET @s_bind=N'[{"portId":"'+@s_port+N'","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"'+@s_transform+N'"}}]';
 EXEC model.declare_scenario @capability_id, @s_scn, @s_ops, @s_bind;
 FETCH NEXT FROM scenario_cursor INTO @s_ordinal, @s_altitude_id, @s_name, @s_scenario_id, @s_authority, @s_port, @s_transform, @s_out_contract;
END
CLOSE scenario_cursor; DEALLOCATE scenario_cursor;

-- ============================== 6. CLI CONFIGURATION ==============================
-- Model-owned CLI configuration on the capability definition (the declare-agent-capability
-- re-mint pattern). The typed input is the shared request contract; the display path
-- names the canned object.
DECLARE @cli_cap_pk bigint, @cli_cap_so bigint, @cli_cap_sod bigint, @cli_cap_ver bigint;
SELECT @cli_cap_pk=c.capability_pk,@cli_cap_so=c.semantic_object_pk,@cli_cap_sod=ec.semantic_object_definition_pk,@cli_cap_ver=ec.capability_version_pk
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE ec.estate_model_pk=@estate AND c.capability_id=@capability_id AND n.namespace_id=N'sidefx:capabilities';
IF @cli_cap_pk IS NULL THROW 51000,N'AUTHORING_ALTITUDE_CAPABILITY_NOT_FOUND',1;
DECLARE @cli_cur nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE d.semantic_object_definition_pk=@cli_cap_sod);
IF @cli_cur IS NULL THROW 51000,N'AUTHORING_ALTITUDE_ENVELOPE_NOT_FOUND',1;
DECLARE @cli_json nvarchar(max)=N'{"input":{"type":"text","contract":"'+@request_contract+N'","path":"payload.objective"},"display":{"select":"outcome.canned","as":"json"}}';
DECLARE @cli_env nvarchar(max)=JSON_MODIFY(@cli_cur,'$.semantics.cli',JSON_QUERY(@cli_json));
DECLARE @cli_bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),(@cli_env) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @cli_digest binary(32)=HASHBYTES('SHA2_256',@cli_bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@cli_digest)
 INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@cli_digest,@cli_bytes,DATALENGTH(@cli_bytes));
DECLARE @cli_sod bigint=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@cli_cap_so AND definition_digest=@cli_digest);
IF @cli_sod IS NULL
BEGIN
 INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk)
  VALUES(@cli_cap_so,'CAPABILITY',@cli_digest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@cli_digest));
 SET @cli_sod=SCOPE_IDENTITY();
 IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@estate AND semantic_object_definition_pk=@cli_sod)
  INSERT model.estate_definition(estate_model_pk,semantic_object_definition_pk) VALUES(@estate,@cli_sod);
END
IF @cli_sod<>@cli_cap_sod
BEGIN
 INSERT model.capability_version(capability_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@cli_cap_pk,@cli_cap_so,@cli_sod,@cli_digest,@capability_id,'CAPABILITY',@cli_sod,N'');
 DECLARE @cli_new_ver bigint=SCOPE_IDENTITY();
 INSERT model.capability_scenario(capability_pk,capability_version_pk,scenario_pk,scenario_version_pk,_owner_definition_pk,_canonical_pointer)
  SELECT capability_pk,@cli_new_ver,scenario_pk,scenario_version_pk,@cli_sod,_canonical_pointer FROM model.capability_scenario WHERE capability_version_pk=@cli_cap_ver;
 INSERT model.capability_root_scenario(capability_version_pk,scenario_pk,_owner_definition_pk,_canonical_pointer)
  SELECT @cli_new_ver,scenario_pk,@cli_sod,_canonical_pointer FROM model.capability_root_scenario WHERE capability_version_pk=@cli_cap_ver;
 UPDATE model.estate_capability SET capability_version_pk=@cli_new_ver,semantic_object_definition_pk=@cli_sod WHERE estate_model_pk=@estate AND capability_pk=@cli_cap_pk;
END

-- ============================== 7. COMPOSED AUTHORITIES ==============================
-- The root authority runs the altitude-1 STUB port and then invokes altitudes 2..11 in
-- order; each later altitude runs its own STUB port. Contract equality holds on every
-- invoke-scenario edge (the state entering each child is the child's declared input
-- contract) and on the trailing invoke (the last child exits with the root outcome
-- contract), so no invoke-return binding is synthesized.
DECLARE @m_cap_ver bigint=(SELECT capability_version_pk FROM model.estate_capability WHERE estate_model_pk=@estate AND capability_pk=(SELECT capability_pk FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capability_id));
IF @m_cap_ver IS NULL THROW 51000,N'AUTHORING_ALTITUDE_CAPABILITY_VERSION_MISSING',1;
DECLARE @root_ops nvarchar(max)=(SELECT N'['+STRING_AGG(N'{"kind":"invoke-scenario","scenarioId":"'+scenario_id+N'"}',N',') WITHIN GROUP (ORDER BY ordinal)+N']' FROM @alt WHERE ordinal>1);
SET @root_ops=N'[{"kind":"invoke-port","portId":"'+(SELECT port_id FROM @alt WHERE ordinal=1)+N'"},'+SUBSTRING(@root_ops,2,LEN(@root_ops));
DECLARE @m_ordinal int, @m_altitude_id nvarchar(400), @m_scenario nvarchar(400), @m_authority nvarchar(400), @m_port nvarchar(400), @m_ops nvarchar(max);
DECLARE @m_ea_pk bigint, @m_ea_so bigint, @m_semantics nvarchar(max), @m_env nvarchar(max), @m_bytes varbinary(max), @m_digest binary(32), @m_sod bigint, @m_eaver bigint;
DECLARE mint_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal, altitude_id, scenario_id, authority_id, port_id FROM @alt ORDER BY ordinal;
OPEN mint_cursor;
FETCH NEXT FROM mint_cursor INTO @m_ordinal, @m_altitude_id, @m_scenario, @m_authority, @m_port;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @m_ops=CASE WHEN @m_ordinal=1 THEN @root_ops ELSE N'[{"kind":"invoke-port","portId":"'+@m_port+N'"}]' END;
 SELECT @m_ea_pk=ea.execution_authority_pk,@m_ea_so=ea.semantic_object_pk
 FROM model.execution_authority ea
 JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk
 WHERE n.namespace_id=@namespace AND ea.execution_authority_id=@m_authority;
 IF @m_ea_pk IS NULL THROW 51000,N'AUTHORING_ALTITUDE_AUTHORITY_NOT_FOUND',1;
 SET @m_semantics=(SELECT @m_authority AS [authority.id],@m_scenario AS [authority.owningScenarioId],JSON_QUERY(@m_ops) AS [authority.operations] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 SET @m_env=N'{"address":{"id":"'+@m_authority+N'","kind":"EXECUTION_AUTHORITY","namespace":"'+@namespace+N'"},"format":"sidefx-semantic-definition.v1","semantics":'+@m_semantics+'}';
 SET @m_bytes=CONVERT(varbinary(max),CONVERT(varchar(max),(@m_env) COLLATE Latin1_General_100_BIN2_UTF8));
 SET @m_digest=HASHBYTES('SHA2_256',@m_bytes);
 IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@m_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@m_digest,@m_bytes,DATALENGTH(@m_bytes));
 IF NOT EXISTS (SELECT 1 FROM model.semantic_object_definition WHERE semantic_object_pk=@m_ea_so AND definition_digest=@m_digest)
  INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk)
   VALUES(@m_ea_so,'EXECUTION_AUTHORITY',@m_digest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@m_digest));
 SET @m_sod=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@m_ea_so AND definition_digest=@m_digest);
 IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@estate AND semantic_object_definition_pk=@m_sod)
  INSERT model.estate_definition(estate_model_pk,semantic_object_definition_pk) VALUES(@estate,@m_sod);
 SET @m_eaver=(SELECT MAX(execution_authority_version_pk) FROM model.execution_authority_version WHERE execution_authority_pk=@m_ea_pk AND definition_digest=@m_digest);
 IF @m_eaver IS NULL
 BEGIN
  INSERT model.execution_authority_version(execution_authority_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,authority_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@m_ea_pk,@m_ea_so,@m_sod,@m_digest,'execution-authorities.v1','EXECUTION_AUTHORITY',@m_sod,N'');
  SET @m_eaver=SCOPE_IDENTITY();
  INSERT model.execution_operation(execution_authority_version_pk,operation_id,ordinal,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT @m_eaver,JSON_VALUE(o.value,'$.operationId'),CONVERT(int,o.[key]),JSON_VALUE(o.value,'$.kind'),@m_sod,N'/semantics/authority/operations/'+o.[key]
   FROM OPENJSON(@m_ops) o;
  INSERT model.operation_port_invocation(execution_operation_pk,port_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT eo.execution_operation_pk,pv.port_version_pk,'invoke-port',@m_sod,eo._canonical_pointer
   FROM model.execution_operation eo
   JOIN OPENJSON(@m_ops) o ON CONVERT(int,o.[key])=eo.ordinal
   JOIN model.port p ON p.port_id=JSON_VALUE(o.value,'$.portId')
   JOIN model.identity_namespace pn ON pn.namespace_pk=p.namespace_pk AND pn.namespace_id=@namespace
   JOIN model.port_version pv ON pv.port_pk=p.port_pk AND pv.port_version_pk=(SELECT MAX(pv2.port_version_pk) FROM model.port_version pv2 WHERE pv2.port_pk=p.port_pk)
   WHERE eo.execution_authority_version_pk=@m_eaver;
  INSERT model.operation_scenario_invocation(execution_operation_pk,target_scenario_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT eo.execution_operation_pk,tcs.scenario_version_pk,'invoke-scenario',@m_sod,eo._canonical_pointer
   FROM model.execution_operation eo
   JOIN OPENJSON(@m_ops) o ON CONVERT(int,o.[key])=eo.ordinal
   JOIN model.scenario tgt ON tgt.scenario_id=JSON_VALUE(o.value,'$.scenarioId') AND tgt.capability_pk=@capability_pk
   JOIN model.capability_scenario tcs ON tcs.scenario_pk=tgt.scenario_pk AND tcs.capability_version_pk=@m_cap_ver
   WHERE eo.execution_authority_version_pk=@m_eaver AND JSON_VALUE(o.value,'$.kind')='invoke-scenario';
 END
 UPDATE se SET se.execution_authority_version_pk=@m_eaver
 FROM model.scenario_event se
 JOIN model.capability_scenario tcs ON tcs.scenario_version_pk=se.scenario_version_pk AND tcs.capability_version_pk=@m_cap_ver
 JOIN model.scenario tgt ON tgt.scenario_pk=tcs.scenario_pk
 WHERE tgt.scenario_id=@m_scenario AND tgt.capability_pk=@capability_pk;
 FETCH NEXT FROM mint_cursor INTO @m_ordinal, @m_altitude_id, @m_scenario, @m_authority, @m_port;
END
CLOSE mint_cursor; DEALLOCATE mint_cursor;

-- ============================== 8. FEATURE ==============================
DECLARE @f_text nvarchar(max)=N'@capability:'+@capability_id+N'
@root-scenario:'+@capability_id+N'
Feature: Declared model stubs at every authoring altitude (11 STUB scenarios)

';
DECLARE @f_ordinal int, @f_altitude_id nvarchar(400), @f_name nvarchar(200), @f_scenario nvarchar(400), @f_authority nvarchar(400), @f_output nvarchar(400), @f_out_id nvarchar(400), @f_in nvarchar(400), @f_terminal nvarchar(40);
DECLARE feature_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal, altitude_id, altitude_name, scenario_id, authority_id, output_contract FROM @alt ORDER BY ordinal;
OPEN feature_cursor;
FETCH NEXT FROM feature_cursor INTO @f_ordinal, @f_altitude_id, @f_name, @f_scenario, @f_authority, @f_output;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @f_in=CASE WHEN @f_ordinal=1 THEN @request_contract ELSE (SELECT output_contract FROM @alt WHERE ordinal=@f_ordinal-1) END;
 SET @f_output=CASE WHEN @f_ordinal=1 THEN (SELECT output_contract FROM @alt WHERE ordinal=11) ELSE @f_output END;
 SET @f_out_id=CASE WHEN @f_ordinal=1 THEN (SELECT altitude_id FROM @alt WHERE ordinal=11)+N'-output' ELSE @f_altitude_id+N'-output' END;
 SET @f_terminal=CASE WHEN @f_ordinal=1 THEN N'' ELSE N'  @outcome-terminal
' END;
 SET @f_text=@f_text
  +N'  @scenario:'+@f_scenario+N'
  @input:'+@f_altitude_id+N'-request
  @input-contract:'+@f_in+N'
  @event:'+@f_altitude_id+N'-requested
  @event-authority:'+@f_authority+N'
  @outcome:'+@f_out_id+N'
  @outcome-contract:'+@f_output+N'
'+@f_terminal+N'  Scenario: STUB altitude '+CONVERT(nvarchar(10),@f_ordinal)+N' '+@f_name+N'
    Given STUB: the altitude-'+CONVERT(nvarchar(10),@f_ordinal)+N' model-output carrier is declared
    When STUB: the altitude stub port executes its canned transformation
    Then STUB: the canned '+@f_name+N' output is returned

';
 FETCH NEXT FROM feature_cursor INTO @f_ordinal, @f_altitude_id, @f_name, @f_scenario, @f_authority, @f_output;
END
CLOSE feature_cursor; DEALLOCATE feature_cursor;
EXEC model.declare_capability_feature @capability_id, @f_text;
END

-- ============================== 9. VERIFICATION ==============================
DECLARE @graph nvarchar(max)=(SELECT g.graph_source FROM analysis.capability_graph_source(@capability_id,1,NULL) g);
IF @graph IS NULL THROW 51000,N'AUTHORING_ALTITUDE_GRAPH_NOT_ASSEMBLED',1;
DECLARE @graph_scenarios int=(SELECT COUNT(*) FROM OPENJSON(@graph,'$.scenarios'));
DECLARE @graph_authorities int=(SELECT COUNT(*) FROM OPENJSON(@graph,'$.executionAuthorities'));
DECLARE @graph_ports int=(SELECT COUNT(*) FROM OPENJSON(@graph,'$.interfaceAuthority.portBindings'));
DECLARE @graph_transformations int=(SELECT COUNT(*) FROM OPENJSON(@graph,'$.semanticTransformations'));
DECLARE @graph_root nvarchar(400)=JSON_VALUE(@graph,'$.rootScenarioId');
DECLARE @root_op_count int=(SELECT COUNT(*) FROM OPENJSON(@graph,'$.executionAuthorities') au CROSS APPLY OPENJSON(au.value,'$.operations') op WHERE JSON_VALUE(au.value,'$.owningScenarioId')=@capability_id);
DECLARE @root_invoke_count int=(SELECT COUNT(*) FROM OPENJSON(@graph,'$.executionAuthorities') au CROSS APPLY OPENJSON(au.value,'$.operations') op WHERE JSON_VALUE(au.value,'$.owningScenarioId')=@capability_id AND JSON_VALUE(op.value,'$.kind')='invoke-scenario');
IF @graph_scenarios<>11 OR @graph_authorities<>11 OR @graph_ports<>11 OR @graph_transformations<>11
 THROW 51000,N'AUTHORING_ALTITUDE_DECLARED_GRAPH_INCOMPLETE',1;
IF @root_op_count<>11 OR @root_invoke_count<>10
 THROW 51000,N'AUTHORING_ALTITUDE_ROOT_CHAIN_INCOMPLETE',1;
IF EXISTS (SELECT 1 FROM OPENJSON(@graph,'$.scenarios') sc
 WHERE JSON_VALUE(sc.value,'$.input.contract.contractId') IS NULL OR JSON_VALUE(sc.value,'$.outcome.contract.contractId') IS NULL)
 THROW 51000,N'AUTHORING_ALTITUDE_SCENARIO_CONTRACT_UNRESOLVED',1;

SELECT N'1_declared_stubs' AS result_set, a.ordinal, a.altitude_id, si.input_id,
 cti.contract_id AS input_contract, cto.contract_id AS outcome_contract,
 CONVERT(bit,so.terminal) AS terminal, a.port_id, a.transformation_id, a.authority_id, a.tool_ref
FROM @alt a
JOIN model.capability c ON c.capability_id=@capability_id
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.capability_scenario cs ON cs.capability_pk=c.capability_pk AND cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=a.scenario_id
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
LEFT JOIN model.scenario_input si ON si.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.contract_version cvi ON cvi.contract_version_pk=si.input_contract_version_pk
LEFT JOIN model.contract cti ON cti.contract_pk=cvi.contract_pk
LEFT JOIN model.scenario_outcome so ON so.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.contract_version cvo ON cvo.contract_version_pk=soc.contract_version_pk
LEFT JOIN model.contract cto ON cto.contract_pk=cvo.contract_pk
ORDER BY a.ordinal;

SELECT N'2_contracts' AS result_set, ct.contract_id, co.byte_length
FROM model.contract ct
JOIN model.contract_version cv ON cv.contract_pk=ct.contract_pk
JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
WHERE ct.contract_id IN (@request_contract, N'altitude-1-feature-parse-output.v1', N'altitude-2-capability-meaning-output.v1', N'altitude-3-scenario-io-output.v1', N'altitude-4-contracts-schemas-output.v1', N'altitude-5-semantic-authority-envelope-output.v1', N'altitude-6-transformation-ast-output.v1', N'altitude-7-execution-authorities-ports-output.v1', N'altitude-8-providers-bindings-overlays-output.v1', N'altitude-9-interface-cli-display-output.v1', N'altitude-10-fixtures-proof-output.v1', N'altitude-11-alignment-evaluation-output.v1')
GROUP BY ct.contract_id, co.byte_length
ORDER BY ct.contract_id;

SELECT N'3_stub_ports' AS result_set, a.ordinal, a.port_id,
 JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.transformationId') AS transformation_id,
 N'STUB' AS stub_marker
FROM @alt a
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@namespace AND d.declared_id=a.port_id
ORDER BY a.ordinal;

SELECT N'4_graph_authorities' AS result_set, JSON_VALUE(au.value,'$.id') AS authority_id,
 JSON_VALUE(au.value,'$.owningScenarioId') AS owning_scenario,
 (SELECT COUNT(*) FROM OPENJSON(au.value,'$.operations')) AS operation_count,
 (SELECT COUNT(*) FROM OPENJSON(au.value,'$.operations') op WHERE JSON_VALUE(op.value,'$.kind')='invoke-scenario') AS invoke_scenario_count
FROM OPENJSON(@graph,'$.executionAuthorities') au
ORDER BY JSON_VALUE(au.value,'$.owningScenarioId');

SELECT N'5_graph_scenarios' AS result_set, JSON_VALUE(sc.value,'$.scenarioId') AS scenario_id,
 JSON_VALUE(sc.value,'$.input.contract.contractId') AS input_contract,
 JSON_VALUE(sc.value,'$.outcome.contract.contractId') AS outcome_contract,
 JSON_VALUE(sc.value,'$.event.executionAuthorityId') AS event_authority,
 CONVERT(bit,JSON_VALUE(sc.value,'$.outcome.terminal')) AS terminal
FROM OPENJSON(@graph,'$.scenarios') sc
ORDER BY JSON_VALUE(sc.value,'$.scenarioId');

-- Baseline comparison: the three unrelated capabilities must be unchanged.
DECLARE @after TABLE (capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY, digest varchar(64), bytes bigint);
INSERT @after (capability_id, digest, bytes)
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world', 1, NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'route-two-child-proof', 1, NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence', 1, NULL) g;
SELECT N'6_digest_compare' AS result_set, b.capability_id, b.digest AS before_digest, a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id
ORDER BY b.capability_id;
IF EXISTS (SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'AUTHORING_ALTITUDE_UNRELATED_CAPABILITY_CHANGED',1;

SELECT N'7_disposition' AS result_set, @capability_id AS capability_id,
 CASE WHEN @already=1 THEN N'already_declared' ELSE N'declared' END AS disposition,
 @graph_scenarios AS scenario_count, @graph_ports AS port_count,
 (SELECT COUNT(*) FROM model.contract ct WHERE ct.contract_id IN (@request_contract, N'altitude-1-feature-parse-output.v1', N'altitude-2-capability-meaning-output.v1', N'altitude-3-scenario-io-output.v1', N'altitude-4-contracts-schemas-output.v1', N'altitude-5-semantic-authority-envelope-output.v1', N'altitude-6-transformation-ast-output.v1', N'altitude-7-execution-authorities-ports-output.v1', N'altitude-8-providers-bindings-overlays-output.v1', N'altitude-9-interface-cli-display-output.v1', N'altitude-10-fixtures-proof-output.v1', N'altitude-11-alignment-evaluation-output.v1')) AS contract_count,
 @graph_authorities AS authority_count, @graph_transformations AS transformation_count,
 @graph_root AS root_scenario_id, @root_op_count AS root_operation_count, @root_invoke_count AS root_invoke_scenario_count,
 LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), @graph) COLLATE Latin1_General_100_BIN2_UTF8)), 2)) AS graph_source_digest;
COMMIT TRANSACTION;
