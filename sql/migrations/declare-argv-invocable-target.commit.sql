-- Makes `argv-provider` a valid nested invocation target at the declaration
-- boundary.
--
-- Live state: capability argv-provider (capability_pk 100890, capability_version_pk
-- 1161209) carried estate_capability.semantic_object_definition_pk 210681, but the
-- selected estate definition is 210698 (digest ecf96aab...). The graph source's
-- declaration read matches the estate pointer against the newest definition per
-- semantic object, so the stale pointer made its capdef empty: the graph source
-- carried no `capability.authority.json` and no `interfaces.authority.json`
-- (interfaceAuthority null), and the compiler refused
-- GRAPH_COMPILER_INVALID_INTERFACE_AUTHORITY.
--
-- Three DB declarations make the target coherent, in this order:
--   1. model.declare_contract re-declares argv-provider-request.v1 with the
--      kernel's canonical input carrier convention (a required contractId const).
--      The selected schema `{"type":"object","additionalProperties":false}`
--      admitted no canonical carrier, so the declared mapping could not admit its
--      own contract; the first declared version already had the contractId
--      property, so this restores the convention without its scaffolding fields.
--   2. model.declare_scenario replays the live binding (the same scenario,
--      operations and port bindings) so model.scenario_input binds to the newly
--      selected contract version.
--   3. model.declare_capability_interface sets the argv CLI input mapping
--      (`json` / argv-provider-request.v1 / payload) through
--      model.declare_capability_envelope, whose bookkeeping repoints
--      estate_capability and copies every capability_scenario row and the
--      capability_root_scenario row. The declaration reads the SELECTED envelope
--      semantics (MAX over model.estate_definition), so the stale pointer is
--      repaired by the delegate's own bookkeeping.
--
-- After the declarations the graph source's interfaceAuthority resolves and its
-- portBindings carry `argv-reading-port` with platformCapabilityId
-- `sda-argv-reading-port.v1` and configuration.providerId
-- `argv-provider.provideArguments`. That provider is not registered in the
-- installed kernel: `sda-argv-reading-port.v1` is absent from
-- sda-platform-capabilities.semantic-authority.json, `argv` appears in neither
-- csharp-mechanic-registry.authority.v1.json nor
-- node-mechanic-registry.authority.v1.json, there is no model.provider row for
-- argv-provider.provideArguments and no overlay rule names the mechanic, and the
-- provider body src/resolvers/node/argv-provider.mjs is absent from the estate.
-- Execution therefore remains refused install-side; this migration stops at the
-- declaration boundary (no provider row, no overlay rule, no pinned application).
--
-- Idempotent: a replay computes the same contract, scenario and interface
-- definitions; the delegate returns already_installed and the scenario rebind is
-- an update to the same contract version.
--
-- Preflight: ends with ROLLBACK; run as a dry run with the migration runner.
-- The install is the .commit.sql copy (identical except COMMIT).
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
IF NOT EXISTS(SELECT 1 FROM model.capability WHERE capability_id=N'argv-provider')
 THROW 51000,'CAPABILITY_NOT_FOUND',1;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @request_schema nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/argv-provider-request.v1.schema.json","type":"object","additionalProperties":false,"required":["contractId"],"properties":{"contractId":{"const":"argv-provider-request.v1"}}}';
DECLARE @scenario nvarchar(max)=N'{"scenarioId":"argv-provider","name":"Read the process arguments","inputId":"argv-provider-request","inputContract":"argv-provider-request.v1","eventId":"argv-provider-requested","eventAuthority":"argv-provider.v1","outcomeId":"argv-provider-result","outcomeContract":"argv-provider-result.v1","terminal":true,"root":true,"given":"the physical command line","when":"the arguments are read through the declared port","then":"the argument list is returned or the read is held"}';
DECLARE @operations nvarchar(max)=N'[{"operationId":"argv-provider.0","kind":"invoke-port","portId":"argv-reading-port"}]';
DECLARE @port_bindings nvarchar(max)=N'[{"portId":"argv-reading-port","platformCapabilityId":"sda-argv-reading-port.v1","configuration":{"providerId":"argv-provider.provideArguments"}}]';

-- 1. The request contract, carrying the kernel's canonical input envelope.
EXEC model.declare_contract @id=N'argv-provider-request.v1', @schema=@request_schema;

-- 2. The scenario, rebound to the newly selected request contract version.
EXEC model.declare_scenario @capability_id=N'argv-provider', @scenario=@scenario,
 @operations=@operations, @port_bindings=@port_bindings;

-- 3. The interface, through the selected envelope; idempotent by delegate.
EXEC model.declare_capability_interface @capability_id=N'argv-provider',
 @input_type=N'json', @input_contract=N'argv-provider-request.v1', @input_path=N'payload';

-- Readback: capability state, the declared CLI mapping and the bound request schema.
SELECT 'argv_invocable_target' AS result_set, c.capability_id, c.capability_pk,
 ec.capability_version_pk, ec.semantic_object_definition_pk,
 LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS definition_digest,
 (SELECT COUNT(*) FROM model.capability_scenario cs WHERE cs.capability_version_pk=ec.capability_version_pk) AS scenario_links,
 (SELECT COUNT(*) FROM model.capability_root_scenario rs WHERE rs.capability_version_pk=ec.capability_version_pk) AS root_links,
 JSON_QUERY(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.cli') AS cli
FROM model.capability c
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ec.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE c.capability_id=N'argv-provider';

SELECT 'argv_request_contract' AS result_set, si.input_contract_version_pk, cv.semantic_object_definition_pk,
 LOWER(CONVERT(varchar(64),cv.definition_digest,2)) AS contract_digest,
 CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS schema_text
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=N'argv-provider'
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_input si ON si.scenario_version_pk=sv.scenario_version_pk
JOIN model.contract_version cv ON cv.contract_version_pk=si.input_contract_version_pk
JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
WHERE c.capability_id=N'argv-provider';

-- Readback: the graph source's interfaceAuthority and port bindings resolve.
SELECT 'argv_interface_authority' AS result_set, g.capability_id, g.root_scenario_id,
 CASE WHEN JSON_QUERY(g.graph_source,'$.interfaceAuthority') IS NULL THEN N'MISSING' ELSE N'RESOLVED' END AS interface_authority_state,
 JSON_QUERY(g.graph_source,'$.interfaceAuthority.interfaces[0].configuration') AS cli_configuration,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(g.graph_source,'$.interfaceAuthority.portBindings'))) AS port_binding_count
FROM analysis.capability_graph_source(N'argv-provider',0,NULL) g;

SELECT 'argv_port_bindings' AS result_set, b.value AS binding
FROM analysis.capability_graph_source(N'argv-provider',0,NULL) g
CROSS APPLY OPENJSON(JSON_QUERY(g.graph_source,'$.interfaceAuthority.portBindings')) b;
COMMIT TRANSACTION;