-- Rebind sda-cli-invoke-port to the registered v2 projected-capability boundary
-- with a pinned declared application for sda-cli.
--
-- Current binding (port_version 4357) is platformCapabilityId
-- `sda-node-consumer-runtime.v1` / provider `ScenarioKernel.NodePlatform`, whose
-- scheduler profile `node:provider:sda-node-consumer-runtime.v1` is NOT in the
-- installed C# registry, so the CLI refuses PROVIDER_BINDING_DIVERGENCE. This
-- migration returns the port to the REGISTERED profile
-- `node:provider:sda-projected-capability-invocation-port.v2`
-- (kernel/semantic-authority/consumer/csharp-mechanic-registry.authority.v1.json
-- lines 75-85; event port `sda-projected-capability-invocation-port.v2`,
-- composition invoke-binding-v2, lines 192-199) and pins a declared application.
--
-- The pinned boundary is the C# body
-- Consumer/ProjectedCapabilityInvocationProvider.cs CreateProjectedCapabilityInvocationProvider
-- -> Consumer/ProjectedConsumerPlatform.cs InvokeBindingV2WithApplicationAsync
-- (lines 107-158). It requires, from configuration:
--   bindingDigest, capabilityAuthorityDigest, requestPath, lineageMode, and
--   (unless resultMode is replace-carrier) resultPath; plus
--   declaredApplication (or bindingRef). It composes
--   declaredApplication.{bindingDocument,executionPlanDocument,fixturesDocument,
--   mechanicalSterilityDocument} (lines 160-175), verifies
--   bindingDigest = canonical sha256 of the parsed binding document
--   (GraphCanonical.Sha256, SemanticExecutionGraphCompiler.cs lines 1153-1206)
--   and capabilityAuthorityDigest = plan.source.capabilityAuthorityDigest
--   (lines 143-149), then executes the declared linear plan (lines 213-321).
--
-- Pinned application for sda-cli: the working live precedent whose structure is
-- copied is bind-gemini-os-credential-port (sidefx:capability:obtain-governed-
-- model-response, definition 203293): a projected-consumer-application-binding.v2
-- with all four documents inline, verified by recomputing its stored digests
-- (bindingDigest 14bb15a2... and executionPlanDigest 6da36d89... reproduced from
-- its live bytes). sda-cli has no projected application yet, so the minimal
-- missing piece is declared here: a v2 plan whose root node is the sda-cli
-- scenario (input sda-cli-invoke-request.v1 so the wrapper carrier is admitted,
-- terminal outcome sda-cli-invoke-result.v1). Operation 1 runs the live
-- sda-cli-transform.v1 greeting expression (name falls back from
-- input.payload.name to input.input.payload.name to input.capabilityId so the
-- carrier only needs capabilityId); operation 2 wraps the greeting into the
-- declared invoke result {capabilityId, disposition, result}. The outer graph's
-- operation cell must satisfy sda-cli-invoke-result.v1, so resultMode
-- replace-carrier returns the wrapped child outcome as the whole result.
--
-- capabilityAuthorityDigest is the selected sda-cli capability envelope digest
-- (model.semantic_object_definition.definition_digest, 02cbf834...); the provider
-- only compares the two declared strings.
--
-- Idempotent: a replay recomputes the same content-addressed configuration and
-- model.bind_provider installs no new port version.
--
-- COMMIT twin of rebind-sda-cli-invoke-pinned-application.sql; installs the rebind. Run the .sql twin first as the dry run.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM model.capability WHERE capability_id=N'sda-cli-invoke')
 THROW 51000,'CAPABILITY_NOT_FOUND',1;
IF NOT EXISTS(SELECT 1 FROM model.capability WHERE capability_id=N'sda-cli')
 THROW 51000,'TARGET_CAPABILITY_NOT_FOUND',1;
GO
DECLARE @estate bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);

-- Live target authority and documents -----------------------------------------
DECLARE @authority_digest nvarchar(80);
SELECT @authority_digest = N'sha256:' + LOWER(CONVERT(varchar(64), sod.definition_digest, 2))
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk = ec.capability_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk = ec.semantic_object_definition_pk
WHERE ec.estate_model_pk = @estate AND c.capability_id = N'sda-cli';
IF @authority_digest IS NULL THROW 51000,'SDA_CLI_AUTHORITY_MISSING',1;

DECLARE @request_schema nvarchar(max), @result_schema nvarchar(max);
SELECT @request_schema = ranked.schema_text
FROM (
  SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS schema_text,
    ROW_NUMBER() OVER (ORDER BY cv.contract_version_pk DESC) AS rn
  FROM model.contract ct
  JOIN model.contract_version cv ON cv.contract_pk = ct.contract_pk
  JOIN model.schema_object so ON so.schema_object_pk = cv.schema_object_pk
  JOIN source.content_object co ON co.content_object_pk = so.content_object_pk
  WHERE ct.contract_id = N'sda-cli-invoke-request.v1'
) ranked WHERE ranked.rn = 1;
SELECT @result_schema = ranked.schema_text
FROM (
  SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS schema_text,
    ROW_NUMBER() OVER (ORDER BY cv.contract_version_pk DESC) AS rn
  FROM model.contract ct
  JOIN model.contract_version cv ON cv.contract_pk = ct.contract_pk
  JOIN model.schema_object so ON so.schema_object_pk = cv.schema_object_pk
  JOIN source.content_object co ON co.content_object_pk = so.content_object_pk
  WHERE ct.contract_id = N'sda-cli-invoke-result.v1'
) ranked WHERE ranked.rn = 1;
IF @request_schema IS NULL OR @result_schema IS NULL THROW 51000,'INVOKE_CONTRACT_SCHEMA_MISSING',1;

DECLARE @greeting_expression nvarchar(max);
SELECT @greeting_expression = JSON_QUERY(ranked.envelope_text, '$.semantics.expression')
FROM (
  SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS envelope_text,
    ROW_NUMBER() OVER (ORDER BY sod.semantic_object_definition_pk DESC) AS rn
  FROM model.semantic_object so
  JOIN model.identity_namespace n ON n.namespace_pk = so.namespace_pk AND n.namespace_id = N'sidefx:capability:sda-cli'
  JOIN model.semantic_object_definition sod ON sod.semantic_object_pk = so.semantic_object_pk
  JOIN source.content_object co ON co.content_object_pk = sod.canonical_content_pk
  WHERE so.declared_id = N'sda-cli-transform.v1' AND so.object_kind = 'TRANSFORMATION'
) ranked WHERE ranked.rn = 1;
IF @greeting_expression IS NULL THROW 51000,'SDA_CLI_TRANSFORMATION_MISSING',1;

-- Pinned application documents -------------------------------------------------
DECLARE @name_fallback nvarchar(max) = N'{"op":"if","when":{"op":"path","from":"input","path":"payload.name"},"then":{"op":"path","from":"input","path":"payload.name"},"else":{"op":"if","when":{"op":"path","from":"input","path":"input.payload.name"},"then":{"op":"path","from":"input","path":"input.payload.name"},"else":{"op":"path","from":"input","path":"capabilityId"}}}';
SET @greeting_expression = JSON_MODIFY(@greeting_expression,
  '$.fields.payload.fields.message.values.name', JSON_QUERY(@name_fallback));

DECLARE @wrap_expression nvarchar(max) = N'{"op":"object","fields":{"capabilityId":{"op":"literal","value":"sda-cli"},"disposition":{"op":"literal","value":"terminated"},"result":{"op":"path","from":"input","path":"."}}}';

DECLARE @contract_authorities nvarchar(max) =
  N'{"authorityType":"consumer-contract-authorities.v1","contracts":{'
  + N'"sda-cli-invoke-request.v1":{"schemaRef":"input.schema.json","schema":' + JSON_QUERY(@request_schema) + N'},'
  + N'"sda-cli-invoke-result.v1":{"schemaRef":"outcome.schema.json","schema":' + JSON_QUERY(@result_schema) + N'}}}';

DECLARE @plan_document nvarchar(max) =
  N'{"executionEmbodimentPlanType":"consumer-execution-embodiment-plan.v2","target":"node","capabilityId":"sda-cli",'
  + N'"source":{"capabilityAuthorityDigest":"' + @authority_digest + N'"},'
  + N'"rootNodeId":"sda-cli",'
  + N'"nodes":[{"nodeId":"sda-cli","scenario":{'
  + N'"scenarioId":"sda-cli",'
  + N'"input":{"inputId":"sda-cli-invoke-request","contract":{"contractId":"sda-cli-invoke-request.v1"}},'
  + N'"event":{"eventId":"sda-cli","executionAuthorityId":"sda-cli.v1"},'
  + N'"outcome":{"outcomeId":"sda-cli-invoke-result","contract":{"contractId":"sda-cli-invoke-result.v1"},"terminal":true}},'
  + N'"operations":['
  + N'{"operationId":"sda-cli.operation.1","kind":"invoke-port","mechanicBindingId":"port:sda-cli-port"},'
  + N'{"operationId":"sda-cli.operation.2","kind":"invoke-port","mechanicBindingId":"port:wrap-invoke-result"}],'
  + N'"transition":null}],'
  + N'"compositionPolicy":{"carrierMode":"previous-admitted-outcome","contractAdmissionMode":"each-scenario-boundary","lineageMode":"retain-root-and-parent-execution","failureMode":"stop-at-first-non-success","cycleMode":"reject-recursive-invocation"},'
  + N'"mechanicBindings":['
  + N'{"bindingId":"contract-admission","mechanicType":"contract-admission","providerCapabilityId":"sda-schema-contract-admission.v1","configuration":{"contractAuthorities":' + @contract_authorities + N'}},'
  + N'{"bindingId":"port:sda-cli-port","mechanicType":"event-port","providerCapabilityId":"sda-authority-transformation-port.v1","configuration":{"expression":' + @greeting_expression + N'}},'
  + N'{"bindingId":"port:wrap-invoke-result","mechanicType":"event-port","providerCapabilityId":"sda-authority-transformation-port.v1","configuration":{"expression":' + @wrap_expression + N'}}],'
  + N'"requiredProviderCapabilityIds":["sda-authority-transformation-port.v1","sda-schema-contract-admission.v1"]}';

DECLARE @plan_digest nvarchar(80) = N'sha256:' + LOWER(CONVERT(varchar(64),
  HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), @plan_document COLLATE Latin1_General_100_BIN2_UTF8))), 2));

DECLARE @binding_document nvarchar(max) =
  N'{"bindingType":"projected-consumer-application-binding.v2","executionPlan":"execution-plans/consumer-execution-plan.node.json","executionPlanDigest":"' + @plan_digest + N'","fixtures":"fixtures/fixtures.json","mechanicalSterility":"projection-conformance.json"}';

DECLARE @binding_digest nvarchar(80) = N'sha256:' + LOWER(CONVERT(varchar(64),
  HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), @binding_document COLLATE Latin1_General_100_BIN2_UTF8))), 2));

DECLARE @fixtures_document nvarchar(max) = N'{"fixtureType":"consumer-capability-fixtures.v1","fixtures":[]}';
DECLARE @sterility_document nvarchar(max) = N'{"conformanceType":"projected-artifact-mechanical-sterility.v1","sourceOrigin":"PROJECTED","forbiddenExecutableMechanics":{}}';

DECLARE @declared_application nvarchar(max) =
  N'{"bindingDocument":"' + STRING_ESCAPE(@binding_document,'json')
  + N'","executionPlanDocument":"' + STRING_ESCAPE(@plan_document,'json')
  + N'","fixturesDocument":"' + STRING_ESCAPE(@fixtures_document,'json')
  + N'","mechanicalSterilityDocument":"' + STRING_ESCAPE(@sterility_document,'json') + N'"}';

DECLARE @configuration nvarchar(max) =
  N'{"bindingDigest":"' + @binding_digest
  + N'","capabilityAuthorityDigest":"' + @authority_digest
  + N'","lineageMode":"retain-nested-execution","requestPath":".","resultMode":"replace-carrier","declaredApplication":'
  + @declared_application + N'}';

EXEC model.bind_provider
 @capability_id=N'sda-cli-invoke',
 @mechanic_id=N'sda-cli-invoke-port',
 @provider_id=N'ScenarioKernel.NodePlatform.Execution.ProjectedCapabilityInvocationAndBinding',
 @platform_capability_id=N'sda-projected-capability-invocation-port.v2',
 @configuration_json=@configuration;
GO
-- Readback: selected invocation port semantics ---------------------------------
DECLARE @estate bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @stored_config nvarchar(max);
SELECT @stored_config = dt.text
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=N'sda-cli-invoke'
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=N'invoke'
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text) dt
WHERE ec.estate_model_pk=@estate;
SELECT 'rebind_sda_cli_invoke_pinned_application' AS result_set,
 c.capability_id, c.capability_pk, ec.capability_version_pk, s.scenario_id, eo.operation_id,
 p.port_id, n.namespace_id, pv.port_version_pk, sod.semantic_object_definition_pk, sod.object_kind,
 JSON_VALUE(@stored_config,'$.semantics.platformCapabilityId') AS platform_capability_id,
 JSON_VALUE(@stored_config,'$.semantics.configuration.bindingDigest') AS binding_digest,
 JSON_VALUE(@stored_config,'$.semantics.configuration.capabilityAuthorityDigest') AS capability_authority_digest,
 JSON_VALUE(@stored_config,'$.semantics.configuration.requestPath') AS request_path,
 JSON_VALUE(@stored_config,'$.semantics.configuration.resultMode') AS result_mode,
 JSON_VALUE(@stored_config,'$.semantics.configuration.lineageMode') AS lineage_mode,
 LEN(JSON_VALUE(@stored_config,'$.semantics.configuration.declaredApplication.bindingDocument')) AS binding_document_chars,
 LEN(JSON_VALUE(@stored_config,'$.semantics.configuration.declaredApplication.executionPlanDocument')) AS plan_document_chars
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=N'sda-cli-invoke'
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=N'invoke'
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
WHERE ec.estate_model_pk=@estate;
SELECT 'pinned_application_documents' AS result_set, k.[key] AS doc_kind, LEN(k.value) AS doc_chars, k.value AS doc_value
FROM OPENJSON(JSON_QUERY(@stored_config,'$.semantics.configuration.declaredApplication')) k
WHERE k.[key] IN ('bindingDocument','executionPlanDocument','fixturesDocument','mechanicalSterilityDocument')
ORDER BY k.[key];
SELECT 'pinned_application_digest_selfcheck' AS result_set,
 JSON_VALUE(@stored_config,'$.semantics.configuration.bindingDigest') AS stored_binding_digest,
 N'sha256:' + LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), b.value COLLATE Latin1_General_100_BIN2_UTF8))), 2)) AS recomputed_binding_digest,
 JSON_VALUE(p.value,'$.source.capabilityAuthorityDigest') AS plan_authority_digest,
 JSON_VALUE(@stored_config,'$.semantics.configuration.capabilityAuthorityDigest') AS config_authority_digest,
 N'sha256:' + LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), p.value COLLATE Latin1_General_100_BIN2_UTF8))), 2)) AS recomputed_plan_digest,
 JSON_VALUE(b.value,'$.executionPlanDigest') AS stored_plan_digest
FROM OPENJSON(JSON_QUERY(@stored_config,'$.semantics.configuration.declaredApplication')) b
CROSS JOIN OPENJSON(JSON_QUERY(@stored_config,'$.semantics.configuration.declaredApplication')) p
WHERE b.[key]=N'bindingDocument' AND p.[key]=N'executionPlanDocument';
COMMIT TRANSACTION;
