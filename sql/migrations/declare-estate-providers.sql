-- Declare estate provider implementations as providers; stop binding a module path in Ports.
-- The helper view resolves configuration.estateProvider from the provider row selected by
-- the Port's providerId, so no Port names a file and the executor still reads the resolved
-- provider from the assembled interfaces document.
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
WHILE @@FETCH_STATUS=0 BEGIN
 EXEC(N'DROP TRIGGER '+@trigger_name);
 FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
GO
CREATE OR ALTER FUNCTION analysis.fn_estate_provider_semantics(@provider_id nvarchar(400))
RETURNS nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 DECLARE @sem nvarchar(max);
 SELECT TOP 1 @sem = JSON_QUERY(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics')
 FROM model.provider p
 JOIN model.provider_definition pd ON pd.provider_pk = p.provider_pk
 JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = pd.semantic_object_definition_pk
 JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
 JOIN analysis.v_selected_semantic_definition sd ON sd.semantic_object_definition_pk = pd.semantic_object_definition_pk
 WHERE sd.estate_model_pk = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
   AND p.provider_id = @provider_id
 ORDER BY pd.provider_definition_pk DESC;
 RETURN @sem;
END;
GO
CREATE OR ALTER VIEW analysis.v_estate_provider_resolved_port_semantics AS
SELECT n.namespace_id,
  CASE WHEN JSON_VALUE(sd.definition_json,'$.semantics.configuration.providerId') IS NULL
       THEN JSON_QUERY(sd.definition_json,'$.semantics')
       ELSE JSON_MODIFY(JSON_QUERY(sd.definition_json,'$.semantics'), '$.configuration.estateProvider',
              JSON_QUERY(analysis.fn_estate_provider_semantics(JSON_VALUE(sd.definition_json,'$.semantics.configuration.providerId'))))
  END AS semantics
FROM analysis.v_selected_semantic_definition sd
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk = sd.semantic_object_definition_pk
JOIN model.port p ON p.semantic_object_pk = sod.semantic_object_pk
JOIN model.identity_namespace n ON n.namespace_pk = p.namespace_pk
WHERE sd.estate_model_pk = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
  AND sd.object_kind = 'PORT';
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @providers TABLE (provider_id nvarchar(400), module nvarchar(400), export nvarchar(400));
INSERT @providers (provider_id, module, export)
SELECT DISTINCT REPLACE(REPLACE(m.module,'src/resolvers/node/',''),'.mjs','')+N'.'+m.export, m.module, m.export
FROM (
 SELECT JSON_VALUE(d.definition_json,'$.semantics.configuration.estateProvider.module') AS module,
        JSON_VALUE(d.definition_json,'$.semantics.configuration.estateProvider.export') AS export
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
   AND JSON_QUERY(d.definition_json,'$.semantics.configuration.estateProvider') IS NOT NULL
) m;
DECLARE @pid nvarchar(400), @module nvarchar(400), @export nvarchar(400);
DECLARE @object bigint, @definition bigint, @digest binary(32), @sem nvarchar(max);
DECLARE @prov bigint, @namespace bigint;
DECLARE providers CURSOR LOCAL FAST_FORWARD FOR SELECT provider_id, module, export FROM @providers;
OPEN providers;
FETCH NEXT FROM providers INTO @pid, @module, @export;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @namespace=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='PROVIDER' AND namespace_id=N'sidefx:providers');
 IF @namespace IS NULL BEGIN INSERT model.identity_namespace(namespace_kind,namespace_id) VALUES('PROVIDER',N'sidefx:providers'); SET @namespace=SCOPE_IDENTITY(); END
 SET @sem=N'{"module":"'+@module+N'","export":"'+@export+N'","declarationProfile":"sda-estate-provider-implementation.v1"}';
 EXEC model.put_semantic_definition 'PROVIDER',N'sidefx:providers',@pid,@sem,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 SET @prov=(SELECT provider_pk FROM model.provider WHERE namespace_pk=@namespace AND provider_id=@pid);
 IF @prov IS NULL BEGIN INSERT model.provider(namespace_pk,provider_id,semantic_object_pk,object_kind) VALUES(@namespace,@pid,@object,'PROVIDER'); SET @prov=SCOPE_IDENTITY(); END
 IF NOT EXISTS (SELECT 1 FROM model.provider_definition WHERE provider_pk=@prov AND semantic_object_definition_pk=@definition)
  INSERT model.provider_definition(provider_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,declaration_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@prov,@object,@definition,@digest,@pid,'sda-estate-provider-implementation.v1','PROVIDER',@definition,N'');
 FETCH NEXT FROM providers INTO @pid, @module, @export;
END
CLOSE providers;
DEALLOCATE providers;
GO
CREATE OR ALTER VIEW analysis.v_capability_execution_declaration AS
WITH cap AS (
  SELECT ec.estate_model_pk, c.capability_pk, c.capability_id COLLATE Latin1_General_100_BIN2 AS capability_id,
         ec.capability_version_pk, ec.semantic_object_definition_pk AS cap_sod
  FROM source.current_model cm
  JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
),
def AS (
  SELECT sod, object_kind, declared_id, namespace_pk, semantic_object_pk, envelope
  FROM (
    SELECT d.semantic_object_definition_pk AS sod, d.object_kind, s.declared_id, s.namespace_pk, s.semantic_object_pk,
           CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS envelope,
           ROW_NUMBER() OVER (PARTITION BY d.semantic_object_pk ORDER BY d.semantic_object_definition_pk DESC) AS rn
    FROM model.semantic_object_definition d
    JOIN model.semantic_object s ON s.semantic_object_pk = d.semantic_object_pk
    JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
  ) x WHERE rn = 1
),
capdef AS (
  SELECT cap.capability_id, def.envelope
  FROM cap JOIN def ON def.sod = cap.cap_sod
),
cli AS (
  SELECT cap.capability_id, JSON_QUERY(capdef.envelope, '$.semantics.cli') AS configuration
  FROM cap JOIN capdef ON capdef.capability_id = cap.capability_id
),
directcontract AS (
  SELECT x.capability_id, x.contract_id, x.schema_content_pk
  FROM (
    SELECT cap.capability_id, ct.contract_id, so.content_object_pk AS schema_content_pk,
           ROW_NUMBER() OVER (PARTITION BY cap.capability_id, ct.contract_id ORDER BY sv.scenario_version_pk DESC, cv.contract_version_pk DESC) AS rn
    FROM cap
    JOIN model.capability_scenario cs ON cs.capability_version_pk = cap.capability_version_pk
    JOIN analysis.v_scenario_invocation_closure c ON c.selected_scenario_version_pk = cs.scenario_version_pk
    JOIN model.scenario_version sv ON sv.scenario_version_pk = c.downstream_scenario_version_pk
    LEFT JOIN model.scenario_input si ON si.scenario_version_pk = sv.scenario_version_pk
    LEFT JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk = sv.scenario_version_pk
    JOIN model.contract_version cv ON cv.contract_version_pk IN (si.input_contract_version_pk, soc.contract_version_pk)
    JOIN model.contract ct ON ct.contract_pk = cv.contract_pk
    JOIN model.schema_object so ON so.schema_object_pk = cv.schema_object_pk
  ) x WHERE x.rn = 1
),
capcontract AS (
 SELECT capability_id,contract_id,schema_content_pk FROM directcontract
 UNION
 SELECT DISTINCT direct.capability_id,ct.contract_id,closure.schema_content_pk
 FROM directcontract direct
 CROSS APPLY analysis.fn_contract_schema_closure(direct.schema_content_pk) closure
 JOIN model.schema_object so ON so.content_object_pk=closure.schema_content_pk
 JOIN model.contract_version cv ON cv.schema_object_pk=so.schema_object_pk
 JOIN model.contract ct ON ct.contract_pk=cv.contract_pk
 JOIN analysis.v_selected_semantic_definition selected ON selected.semantic_object_definition_pk=cv.semantic_object_definition_pk
  AND selected.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
 WHERE closure.schema_content_pk<>direct.schema_content_pk
),
-- Every capability whose Scenarios appear in this capability's declared invocation
-- closure, including the capability itself. A referenced capability's Ports and
-- Transformations become part of the consuming capability's declaration so the
-- planner can render a composed Scenario without a second declaration read.
reach AS (
  SELECT DISTINCT cap.capability_id,
    (N'sidefx:capability:' + dc.capability_id) COLLATE Latin1_General_100_BIN2 AS namespace_id
  FROM cap
  JOIN model.capability_scenario cs ON cs.capability_version_pk = cap.capability_version_pk
  JOIN analysis.v_scenario_invocation_closure c ON c.capability_version_pk = cap.capability_version_pk AND c.selected_scenario_version_pk = cs.scenario_version_pk
  JOIN model.scenario_version dsv ON dsv.scenario_version_pk = c.downstream_scenario_version_pk
  JOIN model.scenario ds ON ds.scenario_pk = dsv.scenario_pk
  JOIN model.capability dc ON dc.capability_pk = ds.capability_pk
),
reachable AS (
  SELECT DISTINCT cap.capability_id,
    CONVERT(nvarchar(400), JSON_VALUE(op.value, '$.portId')) COLLATE Latin1_General_100_BIN2 AS port_id
  FROM cap
  JOIN model.capability_scenario cs ON cs.capability_version_pk = cap.capability_version_pk
  JOIN analysis.v_scenario_invocation_closure c ON c.selected_scenario_version_pk = cs.scenario_version_pk
  JOIN model.scenario_event se ON se.scenario_version_pk = c.downstream_scenario_version_pk
  JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk = se.execution_authority_version_pk
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = eav.semantic_object_definition_pk
  JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
  CROSS APPLY OPENJSON(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.authority.operations') op
  WHERE JSON_VALUE(op.value, '$.portId') IS NOT NULL
)
-- capability.authority.json
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/capability.authority.json') COLLATE Latin1_General_100_BIN2 AS source_path,
  N'capability.authority.json' COLLATE Latin1_General_100_BIN2 AS entry_id,
  (JSON_QUERY(capdef.envelope, '$.semantics.authority')) COLLATE Latin1_General_100_BIN2 AS document
FROM cap JOIN capdef ON capdef.capability_id = cap.capability_id
UNION ALL
-- execution-authorities.authority.json
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/execution-authorities.authority.json') COLLATE Latin1_General_100_BIN2,
  N'execution-authorities.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"authorityType":"execution-authorities.v1","executionAuthorities":['
   + ISNULL((SELECT STRING_AGG(JSON_QUERY(x.env, '$.semantics.authority'), N',')
             FROM (
               SELECT DISTINCT eav.execution_authority_version_pk,
                 CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS env
               FROM model.capability_scenario cs
               JOIN analysis.v_scenario_invocation_closure c ON c.selected_scenario_version_pk = cs.scenario_version_pk
               JOIN model.scenario_event se ON se.scenario_version_pk = c.downstream_scenario_version_pk
               JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk = se.execution_authority_version_pk
               JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = eav.semantic_object_definition_pk
               JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
               WHERE cs.capability_version_pk = cap.capability_version_pk
             ) x), N'') + N']}') COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- semantic-transformation.authority.json
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/semantic-transformation.authority.json') COLLATE Latin1_General_100_BIN2,
  N'semantic-transformation.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"authorityType":"semantic-transformation-authority.v1","transformations":['
   + ISNULL((SELECT STRING_AGG(JSON_QUERY(def.envelope, '$.semantics'), N',')
             FROM def JOIN model.transformation t ON t.semantic_object_pk = def.semantic_object_pk
             JOIN model.identity_namespace n ON n.namespace_pk = t.namespace_pk
             WHERE n.namespace_id COLLATE Latin1_General_100_BIN2 IN (SELECT r.namespace_id FROM reach r WHERE r.capability_id = cap.capability_id)), N'') + N']}') COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- semantic-graph.authority.json (assembled; no separate declaration)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/semantic-graph.authority.json') COLLATE Latin1_General_100_BIN2,
  N'semantic-graph.authority.json' COLLATE Latin1_General_100_BIN2,
  N'{"transitions":[]}' COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- interfaces.authority.json: CLI interface (configuration from the model declaration),
-- contract catalog, port bindings from PORT declarations.
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/interfaces.authority.json') COLLATE Latin1_General_100_BIN2,
  N'interfaces.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"interfaceAuthorityType":"consumer-interface-authority.v1","contractValidatorCapabilityId":"sda-schema-contract-admission.v1","contractCatalog":"contracts/contract-catalog.json","interfaces":[{"interfaceId":"'
   + cap.capability_id + N'-cli","kind":"cli","rootScenarioId":"' + cap.capability_id + N'","platformCapabilityId":"sda-json-cli.v1"'
   + CASE WHEN cli.configuration IS NULL THEN N'' ELSE N',"configuration":' + CONVERT(nvarchar(max), cli.configuration) END
   + N'}],"portBindings":['
   + ISNULL((SELECT STRING_AGG(resolved.semantics, N',')
             FROM analysis.v_estate_provider_resolved_port_semantics resolved
             WHERE resolved.namespace_id COLLATE Latin1_General_100_BIN2 IN (SELECT r.namespace_id FROM reach r WHERE r.capability_id = cap.capability_id)), N'') + N'],"projectionBindings":[]}') COLLATE Latin1_General_100_BIN2
FROM cap JOIN cli ON cli.capability_id = cap.capability_id
UNION ALL
-- consumer-workspace.authority.json (assembled from the capability's members)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/consumer-workspace.authority.json') COLLATE Latin1_General_100_BIN2,
  N'consumer-workspace.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"workspaceType":"consumer-workspace-authority.v1","consumerId":"' + cap.capability_id + N'","projectionTargets":["node"],'
   + N'"capabilities":[{"featureId":"' + cap.capability_id + N'.feature","feature":"capability.feature","capability":"capability.authority.json",'
   + N'"semanticGraph":"semantic-graph.authority.json","executionAuthorities":"execution-authorities.authority.json",'
   + N'"interfaces":"interfaces.authority.json","fixtures":"fixtures.authority.json"}]}') COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- capabilities/<id>/capability.feature (one text per capability: the declared
-- feature's current version, preferring the parsed declaration over the retained
-- text carrier; text resolved by the declaration's content_digest)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/capability.feature') COLLATE Latin1_General_100_BIN2,
  N'capability.feature' COLLATE Latin1_General_100_BIN2,
  x.text COLLATE Latin1_General_100_BIN2
FROM cap
OUTER APPLY (
  SELECT TOP 1 CONVERT(nvarchar(max), CONVERT(varchar(max), fco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text
  FROM model.capability c2
  JOIN model.feature_version fv ON fv.feature_pk = c2.feature_pk
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = fv.semantic_object_definition_pk
  JOIN source.content_object env ON env.content_object_pk = d.canonical_content_pk
  JOIN source.content_object fco ON fco.content_digest = CONVERT(binary(32), N'0x' + JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), env.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.content_digest'), 1)
  WHERE c2.capability_pk = cap.capability_pk
  ORDER BY CASE fv.source_profile WHEN N'parsed-feature-declaration.v1' THEN 0 WHEN N'retained-feature-binding.v1' THEN 1 ELSE 2 END,
           fv.feature_version_pk DESC
) x
WHERE x.text IS NOT NULL
UNION ALL
-- contracts/contract-catalog.json
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/contracts/contract-catalog.json') COLLATE Latin1_General_100_BIN2,
  N'contracts/contract-catalog.json' COLLATE Latin1_General_100_BIN2,
  (N'{' + ISNULL((SELECT STRING_AGG(N'"' + cc.contract_id + N'":"' + cc.contract_id + N'.schema.json"', N',')
                  FROM capcontract cc WHERE cc.capability_id = cap.capability_id), N'') + N'}') COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- contracts/<id>.schema.json (schema bytes resolved by the contract's schema object)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/contracts/' + cc.contract_id + N'.schema.json') COLLATE Latin1_General_100_BIN2,
  (N'contracts/' + cc.contract_id + N'.schema.json') COLLATE Latin1_General_100_BIN2,
  (CONVERT(nvarchar(max), CONVERT(varchar(max), sco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)) COLLATE Latin1_General_100_BIN2
FROM cap JOIN capcontract cc ON cc.capability_id = cap.capability_id
JOIN source.content_object sco ON sco.content_object_pk = cc.schema_content_pk
UNION ALL
-- fixtures.authority.json (assembled from FIXTURE declarations owned by the capability)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/fixtures.authority.json') COLLATE Latin1_General_100_BIN2,
  N'fixtures.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"fixtureType":"consumer-capability-fixtures.v1","fixtures":['
   + ISNULL((SELECT STRING_AGG(JSON_QUERY(def.envelope, '$.semantics.fixture'), N',')
             FROM def JOIN model.fixture fx ON fx.semantic_object_definition_pk = def.sod
             WHERE fx.owner_definition_pk = cap.cap_sod), N'') + N']}') COLLATE Latin1_General_100_BIN2
FROM cap;
GO
DECLARE @estate2 bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @ports TABLE (namespace_id nvarchar(400), port_id nvarchar(400), provider_id nvarchar(400), semantics nvarchar(max), previous_version bigint);
INSERT @ports (namespace_id, port_id, provider_id, semantics, previous_version)
SELECT d.namespace_id, d.declared_id,
 REPLACE(REPLACE(m.module,'src/resolvers/node/',''),'.mjs','')+N'.'+m.export,
 JSON_QUERY(d.definition_json,'$.semantics'),
 (SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
CROSS APPLY (SELECT JSON_VALUE(d.definition_json,'$.semantics.configuration.estateProvider.module') AS module,
                    JSON_VALUE(d.definition_json,'$.semantics.configuration.estateProvider.export') AS export) m
WHERE d.estate_model_pk=@estate2 AND d.object_kind='PORT'
  AND JSON_QUERY(d.definition_json,'$.semantics.configuration.estateProvider') IS NOT NULL;
DECLARE @ns nvarchar(400), @port nvarchar(400), @provid nvarchar(400), @sem nvarchar(max), @prevver bigint;
DECLARE @object2 bigint, @definition2 bigint, @digest2 binary(32), @portpk bigint, @version bigint;
DECLARE ports CURSOR LOCAL FAST_FORWARD FOR SELECT namespace_id, port_id, provider_id, semantics, previous_version FROM @ports;
OPEN ports;
FETCH NEXT FROM ports INTO @ns, @port, @provid, @sem, @prevver;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @sem=JSON_MODIFY(@sem,'$.configuration.providerId',@provid);
 SET @sem=JSON_MODIFY(@sem,'$.configuration.estateProvider',NULL);
 EXEC model.put_semantic_definition 'PORT',@ns,@port,@sem,@object2 OUTPUT,@definition2 OUTPUT,@digest2 OUTPUT;
 SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object2);
 SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition2);
 IF @version IS NULL BEGIN
  INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@portpk,@object2,@definition2,@digest2,'consumer-interface-authority.v1','PORT',@definition2,N'');
  SET @version=SCOPE_IDENTITY();
 END
 UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
 FETCH NEXT FROM ports INTO @ns, @port, @provid, @sem, @prevver;
END
CLOSE ports;
DEALLOCATE ports;
SELECT 'estate_provider_ports' AS result_set, (SELECT COUNT(*) FROM @ports) AS stripped_ports,
 (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d WHERE d.estate_model_pk=@estate2 AND d.object_kind='PORT' AND JSON_QUERY(d.definition_json,'$.semantics.configuration.estateProvider') IS NOT NULL) AS modules_remaining,
 (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d WHERE d.estate_model_pk=@estate2 AND d.object_kind='PORT' AND JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') IS NOT NULL) AS ports_with_provider;
SELECT 'resolved_port_sample' AS result_set,
 JSON_VALUE(semantics,'$.configuration.providerId') AS provider_id,
 JSON_VALUE(semantics,'$.configuration.estateProvider.module') AS module
FROM analysis.v_estate_provider_resolved_port_semantics
 WHERE namespace_id = N'sidefx:capability:execute-declared-capability';
COMMIT TRANSACTION;
