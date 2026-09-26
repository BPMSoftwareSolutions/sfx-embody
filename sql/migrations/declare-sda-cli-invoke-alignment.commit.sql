-- declare-sda-cli-invoke-alignment.sql
--
-- Declaration-surface alignment for capability sda-cli-invoke, fixing the five
-- findings of outputs/sda-cli-invoke-context-final/context-audit.json:
--
--   AUTHORITY_GRAPH_ROOT_DIFFERS      envelope authority.rootScenarioId = sda-cli-invoke
--                                     but capability_root_scenario = invoke.
--   INTERFACE_ROOT_NOT_IN_GRAPH       the derived interface root (capability id,
--                                     sda-cli-invoke) was absent from the graph.
--   FEATURE_VERSION_BINDING_NOT_READ  no version-owned binding on the selected
--                                     capability version 1161235; the binding row
--                                     was stranded on version 1161234.
--   FEATURE_SCENARIO_SELECTION_DIFFERS feature scenarios sda-cli-invoke@102139 vs
--                                     selected owned invoke@102140.
--   FEATURE_PROSE_DIFFERS_FROM_SOURCE  parsed feature steps did not occur in the
--                                     retained source bytes (content_object 184877).
--   altitude 8                        sda-cli-invoke-port named platform
--                                     sda-node-consumer-runtime.v1 with no provider.
--
-- Declared vocabulary only (model.declare_capability_envelope, model.declare_scenario,
-- model.declare_capability_feature, model.bind_provider); no hand-edited rows.
--
-- The corrected scenario id is the capability id, sda-cli-invoke, declared with the
-- faces/contracts of the current invoke scenario (sv 102140) and the prose of the
-- retained source bytes. Its invocation operation is the estate's declared
-- invoke-scenario mechanism. The intended target is the runtime-named capability
-- (the caller's $.capabilityId); invoke-scenario resolves $.scenarioId as a literal
-- capability id in sidefx:capabilities at declaration time, so a request-named target
-- is not expressible with this vocabulary. The only capability named by the
-- declaration's own semantics is sda-cli-invoke itself, so the operation statically
-- targets sda-cli-invoke (the platform carriers sda-node-consumer-runtime.v1 /
-- sda-json-cli.v1 live in sidefx:platform-capabilities and are refused
-- SCENARIO_INVOKED_CAPABILITY_NOT_DECLARED). The request-named selection therefore
-- remains the open finding "Nested capability selection depends on runtime input".
--
-- The legacy invoke scenario is retained (no vocabulary removes a capability_scenario
-- link) and is re-declared with the same input/outcome contracts and retained-source
-- prose so the feature declaration can name every owned scenario. It is given its own
-- event authority id (invoke.v1) because the graph/snapshot requires unique authority
-- ids across scenarios.
--
-- The version-owned feature binding cannot be restored with the installed vocabulary:
-- the only writer, model.declare_capability_feature, updates
-- estate_capability_feature.feature_version_pk only WHERE capability_version_pk equals
-- the selected version; no procedure inserts a binding row for a new selected version,
-- and model.install_feature_binding_change is a stub refusing
-- FEATURE_BINDING_CHANGE_NOT_IMPLEMENTED. This migration therefore creates the
-- corrected feature version and declares it for the selected scenario set, and reports
-- FEATURE_VERSION_BINDING_NOT_READ as open with the missing writer named; the
-- presentation reader falls back to identity context for it.
--
-- Idempotent: when the aligned state is already present the work block is skipped and
-- the readbacks show BEFORE = AFTER.
--
-- Preflight: ends with ROLLBACK; run it first. The install is the .commit.sql twin
-- (identical except the final COMMIT).
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

DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capability nvarchar(400)=N'sda-cli-invoke';
DECLARE @retained_digest char(64)=N'7f2a7f93a06e5a9322827276ef7732339a43c5254128cd95918fd83fa7d7bc49';
DECLARE @retained_content_pk bigint=(SELECT content_object_pk FROM source.content_object WHERE content_digest=CONVERT(binary(32),@retained_digest,2));
IF @retained_content_pk IS NULL THROW 51000,'ALIGNMENT_RETAINED_SOURCE_MISSING',1;
DECLARE @retained_text nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) FROM source.content_object WHERE content_object_pk=@retained_content_pk);

DECLARE @capability_pk bigint,@cv bigint,@cap_sod bigint,@cap_envelope nvarchar(max),@latest_sod bigint,@feature_pk bigint;
SELECT @capability_pk=c.capability_pk,@cv=ec.capability_version_pk,@cap_sod=ec.semantic_object_definition_pk,@feature_pk=c.feature_pk
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
WHERE ec.estate_model_pk=@estate AND c.capability_id=@capability;
IF @capability_pk IS NULL THROW 51000,'ALIGNMENT_CAPABILITY_NOT_FOUND',1;
SET @cap_envelope=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM model.semantic_object_definition sod JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
 WHERE sod.semantic_object_definition_pk=@cap_sod);
SET @latest_sod=(SELECT MAX(sod.semantic_object_definition_pk) FROM model.semantic_object_definition sod
 WHERE sod.semantic_object_pk=(SELECT semantic_object_pk FROM model.capability WHERE capability_pk=@capability_pk));

DECLARE @declared_root nvarchar(400)=JSON_VALUE(@cap_envelope,'$.semantics.authority.rootScenarioId');
DECLARE @graph_root nvarchar(400);
SET @graph_root=(SELECT s.scenario_id FROM model.capability_root_scenario rs JOIN model.scenario s ON s.scenario_pk=rs.scenario_pk WHERE rs.capability_version_pk=@cv);
DECLARE @graph_source nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(@capability,0,NULL));
DECLARE @interface_root nvarchar(400)=JSON_VALUE(@graph_source,'$.interfaceAuthority.interfaces[0].rootScenarioId');
DECLARE @interface_present bit=CASE WHEN JSON_QUERY(@graph_source,'$.interfaceAuthority.interfaces[0]') IS NULL THEN 0 ELSE 1 END;
DECLARE @scenario_set nvarchar(max)=(SELECT STRING_AGG(CONVERT(nvarchar(max),s.scenario_id),N',') WITHIN GROUP (ORDER BY s.scenario_id)
 FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk WHERE cs.capability_version_pk=@cv);
DECLARE @selection_source varchar(100),@selected_fv bigint;
IF EXISTS(SELECT 1 FROM model.estate_capability_feature WHERE estate_model_pk=@estate AND capability_version_pk=@cv)
BEGIN SET @selection_source='estate_capability_feature';
 SELECT TOP 1 @selected_fv=feature_version_pk FROM model.estate_capability_feature WHERE estate_model_pk=@estate AND capability_version_pk=@cv ORDER BY feature_version_pk DESC; END
ELSE IF EXISTS(SELECT 1 FROM model.capability_feature WHERE capability_version_pk=@cv)
BEGIN SET @selection_source='capability_feature';
 SELECT TOP 1 @selected_fv=feature_version_pk FROM model.capability_feature WHERE capability_version_pk=@cv ORDER BY feature_version_pk DESC; END
ELSE
BEGIN SET @selection_source='capability.feature_pk / selected estate definition';
 SELECT TOP 1 @selected_fv=fv.feature_version_pk FROM model.feature_version fv
 JOIN analysis.v_selected_semantic_definition sd ON sd.semantic_object_definition_pk=fv.semantic_object_definition_pk AND sd.estate_model_pk=@estate
 WHERE fv.feature_pk=@feature_pk ORDER BY fv.feature_version_pk DESC; END
DECLARE @feature_scenario_set nvarchar(max),@owned_scenario_set nvarchar(max);
SET @feature_scenario_set=(SELECT STRING_AGG(CONVERT(nvarchar(max),s.scenario_id+N'@'+CONVERT(nvarchar(20),fs.scenario_version_pk)),N',') WITHIN GROUP (ORDER BY s.scenario_id)
 FROM model.feature_scenario fs JOIN model.scenario s ON s.scenario_pk=fs.scenario_pk WHERE fs.feature_version_pk=@selected_fv);
SET @owned_scenario_set=(SELECT STRING_AGG(CONVERT(nvarchar(max),s.scenario_id+N'@'+CONVERT(nvarchar(20),cs.scenario_version_pk)),N',') WITHIN GROUP (ORDER BY s.scenario_id)
 FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk WHERE cs.capability_version_pk=@cv);
DECLARE @prose_missing int=(
 SELECT COUNT(*) FROM model.feature_scenario fs
 JOIN model.scenario_version sv ON sv.scenario_version_pk=fs.scenario_version_pk
 JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=sv.semantic_object_definition_pk
 JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text) dec
 CROSS APPLY OPENJSON(dec.text,'$.semantics.scenario.steps') st
 WHERE fs.feature_version_pk=@selected_fv AND CHARINDEX(JSON_VALUE(st.value,'$.text'),@retained_text)=0);
DECLARE @providerless int=(
 SELECT COUNT(*) FROM OPENJSON(@graph_source,'$.interfaceAuthority.portBindings') b
 WHERE NULLIF(ISNULL(JSON_VALUE(b.value,'$.configuration.providerId'),JSON_VALUE(b.value,'$.configuration.providerProfileId')),N'') IS NULL);
DECLARE @binding_platform nvarchar(400)=JSON_VALUE(@graph_source,'$.interfaceAuthority.portBindings[0].platformCapabilityId');
DECLARE @binding_provider nvarchar(400)=ISNULL(JSON_VALUE(@graph_source,'$.interfaceAuthority.portBindings[0].configuration.providerId'),JSON_VALUE(@graph_source,'$.interfaceAuthority.portBindings[0].configuration.providerProfileId'));

CREATE TABLE #finding(phase varchar(8) NOT NULL,code varchar(48) NOT NULL,detail nvarchar(2000) NOT NULL);
INSERT #finding(phase,code,detail) VALUES
 ('BEFORE','AUTHORITY_GRAPH_ROOT_DIFFERS',N'declared root='+ISNULL(@declared_root,N'<null>')+N'; graph root='+ISNULL(@graph_root,N'<null>')),
 ('BEFORE','INTERFACE_ROOT_NOT_IN_GRAPH',N'interface present='+CONVERT(nvarchar(1),@interface_present)+N'; interface root='+ISNULL(@interface_root,N'<null>')+N'; graph scenarios='+ISNULL(@scenario_set,N'<none>')),
 ('BEFORE','FEATURE_VERSION_BINDING_NOT_READ',N'selection source='+ISNULL(@selection_source,N'<null>')+N'; selected feature version='+ISNULL(CONVERT(nvarchar(20),@selected_fv),N'<null>')+N'; selected capability version='+CONVERT(nvarchar(20),@cv)),
 ('BEFORE','FEATURE_SCENARIO_SELECTION_DIFFERS',N'feature scenarios='+ISNULL(@feature_scenario_set,N'<none>')+N'; owned scenarios='+ISNULL(@owned_scenario_set,N'<none>')),
 ('BEFORE','FEATURE_PROSE_DIFFERS_FROM_SOURCE',N'feature steps absent from retained source='+CONVERT(nvarchar(10),@prose_missing)),
 ('BEFORE','ALTITUDE_8_PROVIDERLESS_BINDING',N'provider-less bindings='+CONVERT(nvarchar(10),@providerless)+N'; first binding platform='+ISNULL(@binding_platform,N'<null>')+N'; provider='+ISNULL(@binding_provider,N'<none>'));

DECLARE @aligned bit=CASE WHEN @declared_root=@capability AND @graph_root=@capability
 AND JSON_VALUE(@cap_envelope,'$.semantics.cli.input.type')=N'json'
 AND JSON_VALUE(@cap_envelope,'$.semantics.cli.display.as')=N'json'
 AND @cap_sod=@latest_sod
 AND @feature_scenario_set=@owned_scenario_set AND @prose_missing=0 AND @providerless=0
 THEN 1 ELSE 0 END;

IF @aligned=1
 SELECT N'already_aligned' AS action,@capability_pk AS capability_pk,@cv AS capability_version_pk,@cap_sod AS definition_pk;
ELSE
BEGIN
 -- 1. Re-select the capability version whose root scenario is the capability id
 --    (1161234 / 211093), so the corrected envelope version copies that root.
 DECLARE @root_sod bigint=(SELECT TOP 1 cv.semantic_object_definition_pk
  FROM model.capability_version cv
  JOIN model.capability_root_scenario rs ON rs.capability_version_pk=cv.capability_version_pk
  JOIN model.scenario s ON s.scenario_pk=rs.scenario_pk
  WHERE cv.capability_pk=@capability_pk AND s.scenario_id=@capability
  ORDER BY cv.capability_version_pk DESC);
 IF @root_sod IS NULL THROW 51000,'ALIGNMENT_ROOT_BEARING_VERSION_MISSING',1;
 DECLARE @sem_old nvarchar(max)=(SELECT JSON_QUERY(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics')
  FROM model.semantic_object_definition sod JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
  WHERE sod.semantic_object_definition_pk=@root_sod);
 EXEC model.declare_capability_envelope @capability_id=@capability,@semantics=@sem_old;

 -- 2. Declare the corrected envelope: the retained json CLI and the corrected
 --    scenario member. The new capability version copies the sda-cli-invoke root.
 SET @cap_sod=(SELECT semantic_object_definition_pk FROM model.estate_capability WHERE estate_model_pk=@estate AND capability_pk=@capability_pk);
 SET @cap_envelope=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM model.semantic_object_definition sod JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
  WHERE sod.semantic_object_definition_pk=@cap_sod);
 DECLARE @member nvarchar(max)=N'{"description":"","examples":[],"keyword":"Scenario","name":"Invoke a declared capability","steps":[{"keyword":"Given ","keywordType":"Context","text":"the message configured in the database"},{"keyword":"When ","keywordType":"Action","text":"the sda-json-cli.v1 standard-output interface executes with that message"},{"keyword":"Then ","keywordType":"Outcome","text":"the caller observes the greeting for the supplied name on standard output"}],"tags":[{"name":"@scenario:sda-cli-invoke"},{"name":"@input:sda-cli-invoke-request"},{"name":"@input-contract:sda-cli-invoke-request.v1"},{"name":"@event:sda-cli-invoke"},{"name":"@event-authority:sda-cli-invoke.v1"},{"name":"@outcome:sda-cli-invoke-result"},{"name":"@outcome-contract:sda-cli-invoke-result.v1"},{"name":"@outcome-terminal"}]}';
 DECLARE @sem_new nvarchar(max)=JSON_MODIFY(JSON_MODIFY(JSON_QUERY(@cap_envelope,'$.semantics'),
  '$.cli',JSON_QUERY(N'{"input":{"type":"json"},"display":{"select":"outcome","as":"json"}}')),
  '$.scenario_members."sda-cli-invoke"',JSON_QUERY(@member));
 EXEC model.declare_capability_envelope @capability_id=@capability,@semantics=@sem_new;
 SET @cap_sod=(SELECT semantic_object_definition_pk FROM model.estate_capability WHERE estate_model_pk=@estate AND capability_pk=@capability_pk);
 IF @cap_sod<>(SELECT MAX(sod.semantic_object_definition_pk) FROM model.semantic_object_definition sod
   WHERE sod.semantic_object_pk=(SELECT semantic_object_pk FROM model.capability WHERE capability_pk=@capability_pk))
  THROW 51000,'ALIGNMENT_ENVELOPE_NOT_LATEST',1;

 -- 3. Corrected scenario: id = capability id, sv 102140 faces/contracts, retained
 --    source prose, one terminal invoke-scenario targeting sda-cli-invoke.
 DECLARE @scenario nvarchar(max)=N'{"scenarioId":"sda-cli-invoke","name":"Invoke a declared capability","inputId":"sda-cli-invoke-request","inputContract":"sda-cli-invoke-request.v1","eventId":"sda-cli-invoke-requested","eventAuthority":"sda-cli-invoke.v1","outcomeId":"sda-cli-invoke-result","outcomeContract":"sda-cli-invoke-result.v1","terminal":true,"root":true,"given":"the message configured in the database","when":"the sda-json-cli.v1 standard-output interface executes with that message","then":"the caller observes the greeting for the supplied name on standard output"}';
 DECLARE @operations nvarchar(max)=N'[{"kind":"invoke-scenario","scenarioId":"sda-cli-invoke"}]';
 DECLARE @no_ports nvarchar(max)=N'[]';
 EXEC model.declare_scenario @capability_id=@capability,@scenario=@scenario,@operations=@operations,@port_bindings=@no_ports;

 -- 4. Legacy invoke scenario: retained (no vocabulary removes a capability_scenario
 --    link), re-declared with the same contracts and retained prose, own event
 --    authority so graph authority ids stay unique.
 DECLARE @legacy nvarchar(max)=N'{"scenarioId":"invoke","name":"Invoke a declared capability","inputId":"sda-cli-invoke-request","inputContract":"sda-cli-invoke-request.v1","eventId":"invoke-requested","eventAuthority":"invoke.v1","outcomeId":"sda-cli-invoke-result","outcomeContract":"sda-cli-invoke-result.v1","terminal":true,"root":false,"given":"the message configured in the database","when":"the sda-json-cli.v1 standard-output interface executes with that message","then":"the caller observes the greeting for the supplied name on standard output"}';
 EXEC model.declare_scenario @capability_id=@capability,@scenario=@legacy,@operations=@operations,@port_bindings=@no_ports;

 -- 5. Feature: the discovered mechanism model.declare_capability_feature, with the
 --    retained source bytes as the feature text. It declares the selected scenario
 --    set and rebinds the feature version for the selected capability version when
 --    an estate_capability_feature row exists there.
 EXEC model.declare_capability_feature @capability_id=@capability,@feature_text=@retained_text;

 -- 6. The retained port declaration is no longer an operation. Qualify it with the
 --    provider the estate declares for sda-node-consumer-runtime.v1 so no
 --    provider-less binding remains.
 EXEC model.bind_provider @capability_id=@capability,@mechanic_id=N'sda-cli-invoke-port',
  @provider_id=N'ScenarioKernel.NodePlatform',@platform_capability_id=N'sda-node-consumer-runtime.v1',
  @configuration_json=N'{"providerId":"ScenarioKernel.NodePlatform","authoritySource":"DATABASE","inputAdmission":{"type":"object","required":["capabilityId"],"properties":{"capabilityId":{"type":"string","minLength":1},"inputType":{"type":"string"},"input":{},"namespace":{"type":"string","minLength":1},"scenario":{"type":"string","minLength":1}}},"capabilityIdPath":"capabilityId","requestPath":"input","namespacePath":"namespace","scenarioPath":"scenario","resultPath":"result","lineageMode":"retain-nested-execution"}';
END

-- ============================== AFTER READBACKS ==============================
SET @cv=(SELECT capability_version_pk FROM model.estate_capability WHERE estate_model_pk=@estate AND capability_pk=@capability_pk);
SET @cap_sod=(SELECT semantic_object_definition_pk FROM model.estate_capability WHERE estate_model_pk=@estate AND capability_pk=@capability_pk);
SET @cap_envelope=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM model.semantic_object_definition sod JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
 WHERE sod.semantic_object_definition_pk=@cap_sod);
SET @latest_sod=(SELECT MAX(sod.semantic_object_definition_pk) FROM model.semantic_object_definition sod
 WHERE sod.semantic_object_pk=(SELECT semantic_object_pk FROM model.capability WHERE capability_pk=@capability_pk));
SET @declared_root=JSON_VALUE(@cap_envelope,'$.semantics.authority.rootScenarioId');
SET @graph_root=(SELECT s.scenario_id FROM model.capability_root_scenario rs JOIN model.scenario s ON s.scenario_pk=rs.scenario_pk WHERE rs.capability_version_pk=@cv);
SET @graph_source=(SELECT graph_source FROM analysis.capability_graph_source(@capability,0,NULL));
SET @interface_root=JSON_VALUE(@graph_source,'$.interfaceAuthority.interfaces[0].rootScenarioId');
SET @interface_present=CASE WHEN JSON_QUERY(@graph_source,'$.interfaceAuthority.interfaces[0]') IS NULL THEN 0 ELSE 1 END;
SET @scenario_set=(SELECT STRING_AGG(CONVERT(nvarchar(max),s.scenario_id),N',') WITHIN GROUP (ORDER BY s.scenario_id)
 FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk WHERE cs.capability_version_pk=@cv);
SET @selection_source=NULL; SET @selected_fv=NULL;
IF EXISTS(SELECT 1 FROM model.estate_capability_feature WHERE estate_model_pk=@estate AND capability_version_pk=@cv)
BEGIN SET @selection_source='estate_capability_feature';
 SELECT TOP 1 @selected_fv=feature_version_pk FROM model.estate_capability_feature WHERE estate_model_pk=@estate AND capability_version_pk=@cv ORDER BY feature_version_pk DESC; END
ELSE IF EXISTS(SELECT 1 FROM model.capability_feature WHERE capability_version_pk=@cv)
BEGIN SET @selection_source='capability_feature';
 SELECT TOP 1 @selected_fv=feature_version_pk FROM model.capability_feature WHERE capability_version_pk=@cv ORDER BY feature_version_pk DESC; END
ELSE
BEGIN SET @selection_source='capability.feature_pk / selected estate definition';
 SELECT TOP 1 @selected_fv=fv.feature_version_pk FROM model.feature_version fv
 JOIN analysis.v_selected_semantic_definition sd ON sd.semantic_object_definition_pk=fv.semantic_object_definition_pk AND sd.estate_model_pk=@estate
 WHERE fv.feature_pk=@feature_pk ORDER BY fv.feature_version_pk DESC; END
SET @feature_scenario_set=(SELECT STRING_AGG(CONVERT(nvarchar(max),s.scenario_id+N'@'+CONVERT(nvarchar(20),fs.scenario_version_pk)),N',') WITHIN GROUP (ORDER BY s.scenario_id)
 FROM model.feature_scenario fs JOIN model.scenario s ON s.scenario_pk=fs.scenario_pk WHERE fs.feature_version_pk=@selected_fv);
SET @owned_scenario_set=(SELECT STRING_AGG(CONVERT(nvarchar(max),s.scenario_id+N'@'+CONVERT(nvarchar(20),cs.scenario_version_pk)),N',') WITHIN GROUP (ORDER BY s.scenario_id)
 FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk WHERE cs.capability_version_pk=@cv);
SET @prose_missing=(
 SELECT COUNT(*) FROM model.feature_scenario fs
 JOIN model.scenario_version sv ON sv.scenario_version_pk=fs.scenario_version_pk
 JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=sv.semantic_object_definition_pk
 JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text) dec
 CROSS APPLY OPENJSON(dec.text,'$.semantics.scenario.steps') st
 WHERE fs.feature_version_pk=@selected_fv AND CHARINDEX(JSON_VALUE(st.value,'$.text'),@retained_text)=0);
SET @providerless=(
 SELECT COUNT(*) FROM OPENJSON(@graph_source,'$.interfaceAuthority.portBindings') b
 WHERE NULLIF(ISNULL(JSON_VALUE(b.value,'$.configuration.providerId'),JSON_VALUE(b.value,'$.configuration.providerProfileId')),N'') IS NULL);
SET @binding_platform=JSON_VALUE(@graph_source,'$.interfaceAuthority.portBindings[0].platformCapabilityId');
SET @binding_provider=ISNULL(JSON_VALUE(@graph_source,'$.interfaceAuthority.portBindings[0].configuration.providerId'),JSON_VALUE(@graph_source,'$.interfaceAuthority.portBindings[0].configuration.providerProfileId'));
DECLARE @auth_missing int,@port_missing int,@call_missing int,@contract_missing int;
SET @auth_missing=(SELECT COUNT(*) FROM OPENJSON(@graph_source,'$.scenarios') sc
 WHERE JSON_VALUE(sc.value,'$.event.executionAuthorityId') IS NOT NULL
 AND NOT EXISTS(SELECT 1 FROM OPENJSON(@graph_source,'$.executionAuthorities') au
  WHERE JSON_VALUE(au.value,'$.id')=JSON_VALUE(sc.value,'$.event.executionAuthorityId')));
SET @port_missing=(SELECT COUNT(*) FROM OPENJSON(@graph_source,'$.executionAuthorities') au
 CROSS APPLY OPENJSON(au.value,'$.operations') op
 WHERE JSON_VALUE(op.value,'$.kind')=N'invoke-port'
 AND NOT EXISTS(SELECT 1 FROM OPENJSON(@graph_source,'$.interfaceAuthority.portBindings') b
  WHERE JSON_VALUE(b.value,'$.portId')=JSON_VALUE(op.value,'$.portId')));
SET @call_missing=(SELECT COUNT(*) FROM OPENJSON(@graph_source,'$.executionAuthorities') au
 CROSS APPLY OPENJSON(au.value,'$.operations') op
 WHERE JSON_VALUE(op.value,'$.kind')=N'invoke-scenario'
 AND NOT EXISTS(SELECT 1 FROM OPENJSON(@graph_source,'$.scenarios') sc
  WHERE JSON_VALUE(sc.value,'$.scenarioId')=JSON_VALUE(op.value,'$.scenarioId')));
SET @contract_missing=(SELECT COUNT(*) FROM (
 SELECT JSON_VALUE(sc.value,'$.input.contract.contractId') AS cid FROM OPENJSON(@graph_source,'$.scenarios') sc
 UNION SELECT JSON_VALUE(sc.value,'$.outcome.contract.contractId') FROM OPENJSON(@graph_source,'$.scenarios') sc
) x WHERE x.cid IS NOT NULL
 AND NOT EXISTS(SELECT 1 FROM OPENJSON(@graph_source,'$.contractAuthorities.contracts') ck WHERE ck.[key]=x.cid));
INSERT #finding(phase,code,detail) VALUES
 ('AFTER','AUTHORITY_GRAPH_ROOT_DIFFERS',N'declared root='+ISNULL(@declared_root,N'<null>')+N'; graph root='+ISNULL(@graph_root,N'<null>')),
 ('AFTER','INTERFACE_ROOT_NOT_IN_GRAPH',N'interface present='+CONVERT(nvarchar(1),@interface_present)+N'; interface root='+ISNULL(@interface_root,N'<null>')+N'; graph scenarios='+ISNULL(@scenario_set,N'<none>')),
 ('AFTER','FEATURE_VERSION_BINDING_NOT_READ',N'selection source='+ISNULL(@selection_source,N'<null>')+N'; selected feature version='+ISNULL(CONVERT(nvarchar(20),@selected_fv),N'<null>')+N'; selected capability version='+CONVERT(nvarchar(20),@cv)),
 ('AFTER','FEATURE_SCENARIO_SELECTION_DIFFERS',N'feature scenarios='+ISNULL(@feature_scenario_set,N'<none>')+N'; owned scenarios='+ISNULL(@owned_scenario_set,N'<none>')),
 ('AFTER','FEATURE_PROSE_DIFFERS_FROM_SOURCE',N'feature steps absent from retained source='+CONVERT(nvarchar(10),@prose_missing)),
 ('AFTER','ALTITUDE_8_PROVIDERLESS_BINDING',N'provider-less bindings='+CONVERT(nvarchar(10),@providerless)+N'; first binding platform='+ISNULL(@binding_platform,N'<null>')+N'; provider='+ISNULL(@binding_provider,N'<none>'));

SELECT N'finding_readback' AS result_set,b.code,b.detail AS before_value,a.detail AS after_value,
 CASE b.code WHEN 'FEATURE_VERSION_BINDING_NOT_READ' THEN N'OPEN: no writer binds the feature to a newly selected version'
  ELSE N'RESOLVED' END AS disposition
FROM #finding b JOIN #finding a ON a.code=b.code AND a.phase='AFTER'
WHERE b.phase='BEFORE'
ORDER BY b.code;

SELECT N'declaration_result' AS result_set,c.capability_id,c.capability_pk,@cv AS capability_version_pk,@cap_sod AS definition_pk,
 LOWER(CONVERT(varchar(64),sod.definition_digest,2)) AS envelope_digest,@graph_root AS root_scenario,
 (SELECT COUNT(*) FROM model.capability_scenario cs WHERE cs.capability_version_pk=@cv) AS scenario_links,
 @selected_fv AS feature_version_pk,
 (SELECT COUNT(*) FROM model.operation_port_invocation opi
  JOIN model.execution_operation eo ON eo.execution_operation_pk=opi.execution_operation_pk
  JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
  JOIN model.scenario_event se ON se.execution_authority_version_pk=eav.execution_authority_version_pk
  JOIN model.capability_scenario cs ON cs.scenario_version_pk=se.scenario_version_pk AND cs.capability_version_pk=@cv) AS port_operations_remaining,
 (SELECT COUNT(*) FROM model.operation_scenario_invocation osi
  JOIN model.execution_operation eo2 ON eo2.execution_operation_pk=osi.execution_operation_pk
  JOIN model.execution_authority_version eav2 ON eav2.execution_authority_version_pk=eo2.execution_authority_version_pk
  JOIN model.scenario_event se2 ON se2.execution_authority_version_pk=eav2.execution_authority_version_pk
  JOIN model.capability_scenario cs2 ON cs2.scenario_version_pk=se2.scenario_version_pk AND cs2.capability_version_pk=@cv) AS invoke_scenario_operations
FROM model.capability c JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=@cap_sod
WHERE c.capability_id=@capability;

SELECT N'audit_equivalent' AS result_set,c.label,c.status,c.detail FROM (
 SELECT N'Scenario authority references' AS label,
  CASE WHEN @auth_missing=0 THEN N'resolved' ELSE N'gap' END AS status,
  CONVERT(nvarchar(2000),N'missing='+CONVERT(nvarchar(10),@auth_missing)) AS detail
 UNION ALL SELECT N'Port binding references',
  CASE WHEN @port_missing=0 THEN N'resolved' ELSE N'gap' END,
  N'missing='+CONVERT(nvarchar(10),@port_missing)
 UNION ALL SELECT N'Scenario call references',
  CASE WHEN @call_missing=0 THEN N'resolved' ELSE N'gap' END,
  N'missing='+CONVERT(nvarchar(10),@call_missing)
 UNION ALL SELECT N'Scenario contract references',
  CASE WHEN @contract_missing=0 THEN N'resolved' ELSE N'gap' END,
  N'missing='+CONVERT(nvarchar(10),@contract_missing)
 UNION ALL SELECT N'Feature version binding',
  CASE WHEN @selection_source IN (N'estate_capability_feature',N'capability_feature') THEN N'resolved' ELSE N'gap' END,
  N'selection source='+ISNULL(@selection_source,N'<null>')
 UNION ALL SELECT N'Feature and graph scenarios',
  CASE WHEN @feature_scenario_set=@owned_scenario_set THEN N'resolved' ELSE N'gap' END,
  N'feature='+ISNULL(@feature_scenario_set,N'<none>')+N'; owned='+ISNULL(@owned_scenario_set,N'<none>')
 UNION ALL SELECT N'Parsed and retained Gherkin',
  CASE WHEN @prose_missing=0 THEN N'resolved' ELSE N'gap' END,
  N'steps absent from retained source='+CONVERT(nvarchar(10),@prose_missing)
 UNION ALL SELECT N'Authority and graph roots',
  CASE WHEN @declared_root=@graph_root THEN N'resolved' ELSE N'gap' END,
  N'authority root='+ISNULL(@declared_root,N'<null>')+N'; graph root='+ISNULL(@graph_root,N'<null>')
 UNION ALL SELECT N'Interface root reference',
  CASE WHEN @interface_present=1 AND EXISTS(SELECT 1 FROM OPENJSON(@graph_source,'$.scenarios') sc WHERE JSON_VALUE(sc.value,'$.scenarioId')=@interface_root) THEN N'resolved' ELSE N'gap' END,
  N'interface root='+ISNULL(@interface_root,N'<null>')+N'; graph scenarios='+ISNULL(@scenario_set,N'<none>')
 UNION ALL SELECT N'Provider-less bindings (altitude 8)',
  CASE WHEN @providerless=0 THEN N'resolved' ELSE N'gap' END,
  N'provider-less bindings='+CONVERT(nvarchar(10),@providerless)+N'; binding platform='+ISNULL(@binding_platform,N'<null>')+N'; provider='+ISNULL(@binding_provider,N'<none>')
) c;

COMMIT TRANSACTION;
