-- declare-model-tool-registry.sql
--
-- Publish the model tool registry, the governed tool-call/result envelope
-- contracts, and the catalog read, as declarations only.
--
-- What this migration declares, in the selected sda-kernel-boot-data-access.v1
-- authority:
--   * one receipt-only change kind `tool-registration-change`. Registration is a
--     trusted-migration operation; the admitted installer writes exactly one TOOL
--     definition and no capability, contract, scenario, port or provider row. The
--     model tool loop is never granted this kind;
--   * the declared reads `list-tools`, `admit-tool-call` and
--     `admit-tool-registration-change`. All three are observation reads and write
--     nothing; the first resolves the catalog plus each tool's contracts;
--   * the changeContracts keys governed-tool-call.v1, governed-tool-result.v1,
--     model-tool-catalog.v1, tool-registration-change.v1 and
--     tool-registration-change-installed.v1.
--
-- What it seeds, as declarative data under sidefx:tools:
--   * the `model-tool-catalog.v1` AUTHORITY definition, generated from
--     docs/llm-authoring-tools-2026-09-21/tool-to-altitude.v1.json (31 tools);
--   * one TOOL definition per catalog entry (the registry rows the admission
--     reads resolve). The catalog entries do not name a capabilityId in the
--     source research; a future `tool-registration-change` carries one and the
--     admission requires it to resolve to a selected CAPABILITY.
--
-- It touches no capability, contract, scenario, port, provider or transformation
-- row, and no frozen SEJ graph-dispatch file.
--
-- Idempotent: the authority body is re-minted only when the new read/kind rows
-- are absent; TOOL and catalog definitions reuse their definition digest
-- (model.put_semantic_definition is digest-idempotent); a byte-identical
-- registration replay returns already_installed.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=30000;
IF @lock<0 THROW 51000,N'MODEL_TOOL_REGISTRY_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
CREATE OR ALTER PROCEDURE model.install_tool_registration_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'TOOL_REGISTRATION_TRANSACTION_REQUIRED',1;
 IF ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'tool-registration-change.v1'
  THROW 51000,'TOOL_REGISTRATION_DOCUMENT_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @tool_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.toolId'),N'');
 DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.capabilityId'),N'');
 DECLARE @input_contract nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.inputContract'),N'');
 DECLARE @output_contract nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.outputContract'),N'');
 DECLARE @effect nvarchar(40)=NULLIF(JSON_VALUE(@document,'$.effectClassification'),N'');
 IF @tool_id IS NULL OR @capability_id IS NULL OR @input_contract IS NULL OR @output_contract IS NULL
  THROW 51000,'TOOL_REGISTRATION_FIELDS_REQUIRED',1;
 IF @effect IS NOT NULL AND @effect NOT IN (N'none',N'model',N'effect')
  THROW 51000,'TOOL_REGISTRATION_EFFECT_CLASSIFICATION_INVALID',1;
 IF NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'CAPABILITY' AND d.declared_id=@capability_id)
  THROW 51000,'TOOL_REGISTRATION_CAPABILITY_NOT_DECLARED',1;
 IF EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'TOOL' AND d.namespace_id=N'sidefx:tools'
   AND JSON_VALUE(d.definition_json,'$.semantics.toolId')=@tool_id)
 BEGIN
  IF EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
   WHERE d.estate_model_pk=@estate AND d.object_kind=N'TOOL' AND d.namespace_id=N'sidefx:tools'
    AND JSON_VALUE(d.definition_json,'$.semantics.toolId')=@tool_id
    AND JSON_VALUE(d.definition_json,'$.semantics.capabilityId')=@capability_id
    AND JSON_VALUE(d.definition_json,'$.semantics.inputContract')=@input_contract
    AND JSON_VALUE(d.definition_json,'$.semantics.outputContract')=@output_contract)
  BEGIN
   SELECT N'already_installed' AS result_set,@tool_id AS tool_id,@capability_id AS capability_id,
    (SELECT N'sha256:'+LOWER(CONVERT(varchar(64),definition_digest,2)) FROM analysis.v_selected_semantic_definition
     WHERE estate_model_pk=@estate AND object_kind=N'TOOL' AND namespace_id=N'sidefx:tools'
      AND JSON_VALUE(definition_json,'$.semantics.toolId')=@tool_id) AS definition_digest;
    RETURN;
  END;
  THROW 51000,'TOOL_REGISTRATION_SHADOWING_NOT_ADMITTED',1;
 END
 DECLARE @semantics nvarchar(max)=(
  SELECT @tool_id AS toolId,@capability_id AS capabilityId,
   NULLIF(JSON_VALUE(@document,'$.class'),N'') AS class,
   NULLIF(JSON_VALUE(@document,'$.description'),N'') AS description,
   @input_contract AS inputContract,@output_contract AS outputContract,
   @effect AS effectClassification,
   NULLIF(JSON_VALUE(@document,'$.admissionKind'),N'') AS admissionKind,
   CONVERT(bit,1) AS toolEligible
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @object bigint,@definition bigint,@digest binary(32);
 EXEC model.put_semantic_definition 'TOOL',N'sidefx:tools',@tool_id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 SELECT N'tool_registration_installed' AS result_set,@tool_id AS tool_id,@capability_id AS capability_id,
  N'sha256:'+LOWER(CONVERT(varchar(64),@digest,2)) AS definition_digest;
END;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @prior_content nvarchar(80)=N'sha256:7c30b9f44eb6c9fe3c0a611c3f5d739cdd3ba00eeb6dd9385bbd1bf6a1eccf79';
DECLARE @selected nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
IF @selected IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_NOT_SELECTED',1;
DECLARE @body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@selected,N'sha256:',N''),2));
IF @body IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_BODY_MISSING',1;
IF JSON_VALUE(@body,'$.authorityId')<>@authority_id THROW 51000,N'KERNEL_BOOT_AUTHORITY_IDENTITY_DIVERGED',1;
DECLARE @declared bit=CASE WHEN EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'list-tools')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-tool-call')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-tool-registration-change')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=N'tool-registration-change')
 THEN 1 ELSE 0 END;
IF @declared=0 AND @selected<>@prior_content THROW 51000,N'KERNEL_BOOT_AUTHORITY_CHANGED_REBASE_DECLARATION',1;
DECLARE @executables TABLE(object_kind nvarchar(64) COLLATE Latin1_General_100_BIN2,row_count bigint);
INSERT @executables(object_kind,row_count)
SELECT object_kind,COUNT(*) FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind IN (N'CAPABILITY',N'CONTRACT',N'SCENARIO',N'PORT')
 GROUP BY object_kind;
DECLARE @catalog nvarchar(max)=N'{"catalogType":"model-tool-catalog.v1","entries":[{"toolId":"inventory.read","catalogRef":"S1","altitude":"shared","description":"Read the estate inventory, mechanic catalogue, provider catalogues and one capability\u0027s assembled declarations so the model reuses before inventing.","classification":"COMPOSE_EXISTING","inputContractId":"provider-catalogue-request.v1","outputContractId":"provider-catalogue-result.v1","writeClass":"read","implementation":{"mechanism":"Declared reads: list-capabilities; provider catalogue/configuration reads; model.inspect_capability; selected boot read mechanic-definitions."},"admission":{"kind":"none","installer":"none","receipt":"none"},"eligibility":{"toolEligible":true,"callable":true,"status":"partial","reason":"sfx capability list/find/reveal and sfx provider list/reveal are callable; model.inspect_capability @capability_id and the mechanic-definitions boot read are SQL/runner only; no capability wrapper for mechanic-definitions exists."}},{"toolId":"capability.search","catalogRef":"S2","altitude":"shared","description":"Find existing capabilities, contracts, scenarios and mechanics matching an intent before authoring: the reuse predicate\u0027s input.","classification":"REUSE_EXISTING","inputContractId":"list-capabilities-request.v1","outputContractId":"list-capabilities-result.v1","writeClass":"read","implementation":{"mechanism":"find scenario of list-capabilities (literal substring) and the semantic pipeline resolve -> construct -> retrieve -> ground -> bind."},"admission":{"kind":"none","installer":"none","receipt":"none"},"eligibility":{"toolEligible":true,"callable":true,"status":"partial","reason":"Exact find is callable but find \u0027market price\u0027 returns outcome:null, exit 0 (G1 bug); the semantic pipeline\u0027s projection bindings are retired and its corpus is frozen at 108 units."}},{"toolId":"capability.read","catalogRef":"S3","altitude":"shared","description":"Read one capability\u0027s declared meaning, scenario authority, installed document and retained circuit.","classification":"REUSE_EXISTING","inputContractId":"read-capability-meaning-request.v1","outputContractId":"read-declared-capability-document-result.v1","writeClass":"read","implementation":{"mechanism":"Declared read capabilities read-capability-meaning, read-scenario-authority, read-declared-authority, read-declared-capability-document, read-retained-publication."},"admission":{"kind":"none","installer":"none","receipt":"none"},"eligibility":{"toolEligible":true,"callable":true,"status":"yes","reason":"sfx capability reveal --as meaning|circuit and the declared reads are live."}},{"toolId":"contract.read","catalogRef":"S4","altitude":"shared","description":"Resolve a contract id to its version, schema bytes, digest, faces and owner: \u0027does this contract already exist?\u0027.","classification":"AUTHOR_PROFILE","inputContractId":"contract-inventory-request.v1","outputContractId":"contract-inventory-result.v1","writeClass":"read","implementation":{"mechanism":"PROPOSED statement-only declared read over model.contract / model.contract_version / model.schema_object / source.content_object, following the read-declared-capability-document reader pattern."},"admission":{"kind":"none","installer":"none","receipt":"none"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"No contract-inventory read capability is declared; only ad-hoc inspection SQL exists (T:altitude-inspect-sql.md section 4)."}},{"toolId":"preflight.run","catalogRef":"S5","altitude":"shared","description":"Prepare/dry-run/preflight/install/verify a declared change under the kind\u0027s declared verification recipe: the proof gate for every altitude.","classification":"REUSE_EXISTING","inputContractId":"declared-change.v1","outputContractId":"change-admitted.v1","writeClass":"read","implementation":{"mechanism":"declared-change.v1 executor: scope assertion, admission read, guard observe/disable/restore, granted installer call, result-contract assertion; verification recipes capability-invocation and capability-fixtures."},"admission":{"kind":"per payload changeKind (provider-binding | scenario-registration | capability-candidate | PROPOSED content kinds)","installer":"per kind granted procedure","receipt":"change-admitted.v1 plus the kind\u0027s result contract"},"eligibility":{"toolEligible":true,"callable":true,"status":"yes","reason":"run-declared-change.mjs modes and the two declared recipes are live; preflight always rolls back, install mode commits through the kind\u0027s installer."}},{"toolId":"candidate.file","catalogRef":"S6","altitude":"shared","description":"File one model-authored capability-candidate bundle as a reviewable receipt with per-altitude admissions, digest and author pins; installs nothing.","classification":"REUSE_EXISTING","inputContractId":"capability-candidate-bundle.v1","outputContractId":"capability-candidate-filed.v1","writeClass":"propose","implementation":{"mechanism":"Declared change kind capability-candidate; observation admission admit-capability-candidate (writes nothing); installer model.register_capability_candidate writes exactly one AUTHORITY receipt under sidefx:candidates."},"admission":{"kind":"capability-candidate","installer":"model.register_capability_candidate","receipt":"capability-candidate-filed.v1 / capability-candidate-receipt.v1 under sidefx:candidates"},"eligibility":{"toolEligible":true,"callable":true,"status":"partial","reason":"The capability-candidate kind is live in the estate (authority content digest sha256:7c30b9f44eb6c9fe3c0a611c3f5d739cdd3ba00eeb6dd9385bbd1bf6a1eccf79); invocation is through run-declared-change lifecycle modes, not a standalone CLI tool."}},{"toolId":"candidate.read","catalogRef":"S7","altitude":"shared","description":"Read the current candidate receipt, its per-altitude admissions, alignment result and review decision.","classification":"AUTHOR_PROFILE","inputContractId":"candidate-receipt-read-request.v1","outputContractId":"capability-candidate-receipt.v1","writeClass":"read","implementation":{"mechanism":"PROPOSED statement-only declared read over analysis.v_selected_semantic_definition (object_kind=\u0027AUTHORITY\u0027, namespace_id=\u0027sidefx:candidates\u0027), the same view the installer reads."},"admission":{"kind":"none","installer":"none","receipt":"none"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"No candidate reader is declared; the receipt is stored as an AUTHORITY definition under sidefx:candidates and is readable by ad-hoc inspection SQL only."}},{"toolId":"observation.read","catalogRef":"S8","altitude":"shared","description":"Stream or read the invocation\u0027s testimony: cell/edge timing, provider exchange request/response, and (prepared) modelResponse and failure testimony.","classification":"REUSE_EXISTING","inputContractId":"observation-projection-request.v1","outputContractId":"observation-projection.v1","writeClass":"read","implementation":{"mechanism":"Declared observation reads read-observation-projection, read-observation-telemetry-authority, read-invocation-timing; the lane never changes the outcome."},"admission":{"kind":"none","installer":"none","receipt":"none"},"eligibility":{"toolEligible":true,"callable":true,"status":"partial","reason":"sfx capability observe --json [--trace] is live; the failureCode/failureMessage and modelResponse telemetry extension is not installed in the live estate (validated 2026-09-21: no telemetry row contains those members)."}},{"toolId":"capability.document.install","catalogRef":"S9","altitude":"shared","description":"Install a whole capability (meaning, contracts, scenarios/I-E-O, operations/ports, interface) from one sidefx-capability-authority.v1 document.","classification":"COMPOSE_EXISTING","inputContractId":"sidefx-capability-authority.v1","outputContractId":"capability-document-installed.v1","writeClass":"content","implementation":{"mechanism":"model.declare_capability_document delegating to scaffold_capability, declare_contract, declare_scenario, author_capability_meaning, configure_interface; REPLACE guarded to a new capability id by the PROPOSED kind."},"admission":{"kind":"none today / PROPOSED capability-authoring","installer":"model.declare_capability_document","receipt":"AUTHORITY CAPABILITY_DOCUMENT definition under sidefx:capability-documents"},"eligibility":{"toolEligible":true,"callable":true,"status":"partial","reason":"model.declare_capability_document is live and idempotent, but it is callable only through the migration lifecycle today; no admitted capability-authoring kind exists."}},{"toolId":"intent.parse","altitude":"altitude-1","description":"Parse free text into a declared intent {capability,input} and the capability identity it targets.","classification":"REUSE_EXISTING","inputContractId":"agent-objective-request.v1","outputContractId":"capability-proposal.v1","writeClass":"read","implementation":{"mechanism":"Live agent lane request-capability-from-objective with structured-generation response policy {capability,input} through the governed model exchange; placement A may bind the admitted connector port."},"admission":{"kind":"none","installer":"none","receipt":"normalizedResponse.structuredValue in governed-model-response-evidence.v1"},"eligibility":{"toolEligible":true,"callable":true,"status":"yes","reason":"sfx capability invoke request-capability-from-objective is live through the governed Gemini exchange (placement B)."}},{"toolId":"feature.resolve","altitude":"altitude-1","description":"Deterministically resolve a feature reference into canonical {capabilityId,scenarioId,inputId,inputContractId,eventId,eventAuthorityId,outcomeId,outcomeContractId}.","classification":"AUTHOR_PROFILE","inputContractId":"capability-feature-authoring-request.v1","outputContractId":"canonical-capability-feature.v1","writeClass":"read","implementation":{"mechanism":"Deterministic port sda-canonical-capability-feature-resolution-port.v1 with configuration governedRootRefs."},"admission":{"kind":"none","installer":"none","receipt":"none"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"The port sda-canonical-capability-feature-resolution-port.v1 is admitted but its consumer overlay binding is missing (SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING)."}},{"toolId":"feature.pin","altitude":"altitude-1","description":"Persist parsed feature bytes and the scenario pins they own.","classification":"AUTHOR_PROFILE","inputContractId":"feature-binding-change.v1","outputContractId":"feature-binding-installed.v1","writeClass":"content","implementation":{"mechanism":"model.declare_capability_feature under a PROPOSED feature-binding-change kind (pinning-only, no parse claim)."},"admission":{"kind":"PROPOSED feature-binding-change","installer":"model.declare_capability_feature (through a PROPOSED document wrapper)","receipt":"PROPOSED feature-binding-installed.v1"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"model.declare_capability_feature exists, but no feature-binding-change kind is admitted and no feature parser exists; today the write is migration DML only."}},{"toolId":"meaning.author","altitude":"altitude-2","description":"Author the capability meaning: name, userStory{actor,intent,outcome}, experience{experienceId,actor,promise,observableConditions[]}.","classification":"AUTHOR_PROFILE","inputContractId":"bounded-scenario-meaning-request.v1","outputContractId":"scenario-authoring-outcome.v1","writeClass":"content","implementation":{"mechanism":"Model placement A/B produces the bounded-scenario-meaning fragment; writer model.author_capability_meaning or the capability altitude of model.declare_capability_document under PROPOSED capability-authoring."},"admission":{"kind":"none today / PROPOSED capability-authoring","installer":"model.author_capability_meaning (or model.declare_capability_document)","receipt":"AUTHORITY capability document definition"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"The model child obtain-scenario-meaning-testimony is retired (PROJECTED_CAPABILITY_BINDING_REFERENCE_MISSING); the writer and carrier exist."}},{"toolId":"scenario.author","altitude":"altitude-3","description":"Author one scenario version with faces, operations and port bindings: the hinge altitude every other artifact attaches to.","classification":"AUTHOR_PROFILE","inputContractId":"scenario-authoring-change.v1","outputContractId":"scenario-change-installed.v1","writeClass":"content","implementation":{"mechanism":"Model placement A/B produces the scenario fragment; model.declare_scenario via model.install_scenario_change (pinned) or a PROPOSED scenario-authoring kind; document member of S9."},"admission":{"kind":"scenario-registration (pinned) / PROPOSED scenario-authoring","installer":"model.install_scenario_change (PROPOSED generalized wrapper for scenario-authoring)","receipt":"scenario-change-installed.v1 plus the AUTHORITY <scenarioId>.change.v1 document"},"eligibility":{"toolEligible":true,"callable":true,"status":"partial","reason":"The pinned scenario-registration kind installs only say-hello-world with a fixed port digest; general model authoring is not admitted (the conveyor trial produced no candidate)."}},{"toolId":"contract.author","altitude":"altitude-4","description":"Author one contract {id, schema} (JSON Schema 2020-12) and validate it before any face points at it.","classification":"AUTHOR_PROFILE","inputContractId":"contract-change.v1","outputContractId":"contract-change-installed.v1","writeClass":"content","implementation":{"mechanism":"Model placement A/B plus model.declare_contract (new contract) or model.configure_contract (revision) under PROPOSED contract-change."},"admission":{"kind":"PROPOSED contract-change","installer":"model.declare_contract / model.configure_contract (through a PROPOSED document wrapper)","receipt":"PROPOSED contract-change-installed.v1"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"Writers model.declare_contract / model.configure_contract are live; no contract-change kind or candidate carrier is admitted, so writes are migration DML only."}},{"toolId":"contract.validate","altitude":"altitude-4","description":"Validate that a schema compiles and that a declared face\u0027s payload satisfies it.","classification":"REUSE_EXISTING","inputContractId":"schema-contract-admission-request.v1","outputContractId":"schema-contract-admission-result.v1","writeClass":"read","implementation":{"mechanism":"Admitted contract-validator platform capability sda-schema-contract-admission.v1 (node/python/csharp providers) invoked during graph compilation."},"admission":{"kind":"none","installer":"none","receipt":"none"},"eligibility":{"toolEligible":true,"callable":true,"status":"partial","reason":"The admitted platform capability sda-schema-contract-admission.v1 runs inside preflight.run / graph compilation; it is not a standalone command."}},{"toolId":"semantics.author","altitude":"altitude-5","description":"Produce the $.semantics envelope object from the model\u0027s normalized response and write it for the target object kind.","classification":"AUTHOR_NEW","inputContractId":"governed-model-response-evidence.v1","outputContractId":"sidefx-semantic-definition.v1","writeClass":"content","implementation":{"mechanism":"PROPOSED thin wrapper procedure that passes governed-model-response normalizedResponse to model.put_semantic_definition for the per-altitude kind; adds no semantic law."},"admission":{"kind":"PROPOSED per-altitude kinds (capability-authoring, transformation-change, ...)","installer":"PROPOSED thin wrapper over model.put_semantic_definition","receipt":"target-kind AUTHORITY/CONTRACT/... definition"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"No write-port / apply-model-output mechanism exists; no model placement whose output is an envelope; one thin wrapper procedure must be authored."}},{"toolId":"ast.author","altitude":"altitude-6","description":"Author one transformation expression ($.semantics.expression, profile json-expression-tree.v1).","classification":"AUTHOR_PROFILE","inputContractId":"transformation-change.v1","outputContractId":"transformation-change-installed.v1","writeClass":"content","implementation":{"mechanism":"Model placement A/B plus model.put_semantic_definition \u0027TRANSFORMATION\u0027 and model.normalize_transformation_expression under PROPOSED transformation-change."},"admission":{"kind":"PROPOSED transformation-change","installer":"model.put_semantic_definition \u0027TRANSFORMATION\u0027 + model.normalize_transformation_expression (through a PROPOSED wrapper)","receipt":"PROPOSED transformation-change-installed.v1"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"put_semantic_definition \u0027TRANSFORMATION\u0027 and normalize_transformation_expression are live; no transformation-change kind is admitted (mechanic registration is explicitly excluded)."}},{"toolId":"ast.normalize","altitude":"altitude-6","description":"Build transformation_root / _expression_node / _expression_child rows from an expression.","classification":"REUSE_EXISTING","inputContractId":"transformation-normalization-request.v1","outputContractId":"normalized-transformation-tree.v1","writeClass":"content","implementation":{"mechanism":"model.normalize_transformation_expression @transformation_version_pk."},"admission":{"kind":"rides PROPOSED transformation-change","installer":"model.normalize_transformation_expression","receipt":"AUTHORITY transformation definition"},"eligibility":{"toolEligible":true,"callable":true,"status":"partial","reason":"model.normalize_transformation_expression is live but callable only via migration/runner inside a transformation install."}},{"toolId":"ast.repair","altitude":"altitude-6","description":"Apply a declared mechanical repair to a normalized tree when the model\u0027s first AST fails validation.","classification":"AUTHOR_NEW","inputContractId":"transformation-repair-request.v1","outputContractId":"transformation-repair-result.v1","writeClass":"content","implementation":{"mechanism":"PROPOSED repair unit over sda-authority-transformation-port.v1; supersedes the failed transformation version under transformation-change."},"admission":{"kind":"PROPOSED transformation-change (supersession)","installer":"none (unit to be authored)","receipt":"PROPOSED transformation-change-installed.v1"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"No repair unit exists anywhere; the conveyor curate step is an identity no-op (SELECT 1)."}},{"toolId":"authority.author","altitude":"altitude-7","description":"Author the execution authority version, its ordered operations, and each operation\u0027s port binding or nested scenario invocation.","classification":"AUTHOR_PROFILE","inputContractId":"execution-authority-change.v1","outputContractId":"execution-authority-change-installed.v1","writeClass":"content","implementation":{"mechanism":"Model placement A/B plus model.declare_scenario authority/port sections, model.bind_provider, model.scaffold_composed_capability under PROPOSED execution-authority-change."},"admission":{"kind":"PROPOSED execution-authority-change","installer":"model.declare_scenario / model.bind_provider (through a PROPOSED wrapper)","receipt":"PROPOSED execution-authority-change-installed.v1"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"The authority/port writers model.declare_scenario and model.bind_provider are live; no execution-authority-change kind is admitted."}},{"toolId":"port.bind","altitude":"altitude-7","description":"Bind one port to a platform capability + configuration (or re-point it).","classification":"COMPOSE_EXISTING","inputContractId":"execution-authority-change.v1","outputContractId":"execution-authority-change-installed.v1","writeClass":"content","implementation":{"mechanism":"model.bind_provider or model.declare_scenario @port_bindings; rides capability-authoring / provider-binding; no standalone kind."},"admission":{"kind":"rides capability-authoring / provider-binding","installer":"model.bind_provider","receipt":"rides the parent kind result contract"},"eligibility":{"toolEligible":true,"callable":true,"status":"partial","reason":"model.bind_provider and the @port_bindings section of declare_scenario are live; only reachable through S9 documents or migration DML today."}},{"toolId":"provider.author","altitude":"altitude-8","description":"Author and preflight a provider-binding-change.v1 (endpoint, credential reference, mapping) against the observed sample.","classification":"REUSE_EXISTING","inputContractId":"provider-binding-change-request.v1","outputContractId":"provider-binding-change-result.v1","writeClass":"install","implementation":{"mechanism":"Declared read author-provider-configuration-change reached by sfx provider set; documented six-stage provider add: author -> render -> dry-run -> preflight -> install -> verify."},"admission":{"kind":"provider-binding","installer":"model.install_provider_binding_change","receipt":"provider-change-installed.v1"},"eligibility":{"toolEligible":true,"callable":true,"status":"yes","reason":"sfx provider set / author-provider-configuration-change author+preflight is live; install runs through the admitted provider-binding kind or migration lifecycle."}},{"toolId":"provider.read","altitude":"altitude-8","description":"List declared providers or reveal one provider\u0027s endpoints, credentials, templates and bindings.","classification":"REUSE_EXISTING","inputContractId":"provider-configuration-request.v1","outputContractId":"provider-configuration-result.v1","writeClass":"read","implementation":{"mechanism":"Declared read capabilities list-providers and read-provider-configuration."},"admission":{"kind":"none","installer":"none","receipt":"none"},"eligibility":{"toolEligible":true,"callable":true,"status":"yes","reason":"sfx provider list/reveal and the declared reads list-providers / read-provider-configuration are live."}},{"toolId":"overlay.bind","altitude":"altitude-8","description":"Author a target overlay bound to a canonical graph digest (target-specific witness without semantic mutation).","classification":"AUTHOR_PROFILE","inputContractId":"overlay-binding-change.v1","outputContractId":"overlay-binding-installed.v1","writeClass":"content","implementation":{"mechanism":"PROPOSED declared writer copying the existing overlay row shape; must not become a semantic second authority."},"admission":{"kind":"none (must stay declared data, not a second authority)","installer":"none today (DERIVED DML copy of the overlay row shape)","receipt":"none"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"No declared overlay writer exists; the only pattern is hand JSON_MODIFY migration DML."}},{"toolId":"interface.author","altitude":"altitude-9","description":"Author the declared CLI/display mapping $.semantics.cli so a candidate is reviewable and invocable.","classification":"AUTHOR_PROFILE","inputContractId":"interface-change.v1","outputContractId":"interface-configured.v1","writeClass":"content","implementation":{"mechanism":"Model placement A/B plus model.configure_interface (digest-guarded); member of model.declare_capability_document; platform capability sda-json-cli.v1 for delivery."},"admission":{"kind":"rides PROPOSED capability-authoring","installer":"model.configure_interface","receipt":"rides the parent kind result contract"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"model.configure_interface is live but only reachable through the S9 document surface or migration DML; no model unit or candidate member is admitted."}},{"toolId":"fixture.author","altitude":"altitude-10","description":"Author consumer-capability-fixtures.v1 fixtures so preflight.run can prove the candidate and identify proof obligations.","classification":"AUTHOR_PROFILE","inputContractId":"consumer-capability-fixtures.v1","outputContractId":"fixture-installed.v1","writeClass":"content","implementation":{"mechanism":"Model placement A/B plus model.add_example or the $.fixtures block of model.install_scenario_change; rides scenario-authoring / capability-authoring."},"admission":{"kind":"rides scenario-authoring / capability-authoring; today scenario-registration\u0027s fixture block","installer":"model.add_example","receipt":"rides the parent kind result contract"},"eligibility":{"toolEligible":true,"callable":true,"status":"partial","reason":"model.add_example and the $.fixtures block of model.install_scenario_change are live, but only through the pinned scenario-registration kind today."}},{"toolId":"proof.obligation.author","altitude":"altitude-10","description":"Name the evidence/proof obligations the proposed effect must satisfy: the proof alignment dimension\u0027s input.","classification":"AUTHOR_NEW","inputContractId":"proof-obligation-request.v1","outputContractId":"proof-obligation.v1","writeClass":"evaluate","implementation":{"mechanism":"PROPOSED proof-obligation contract feeding the proof dimension of alignment-evaluation.v1; no writer exists."},"admission":{"kind":"none","installer":"none (deferred)","receipt":"none"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"No proof-obligation writer, table or object kind exists (0 rows); explicitly deferred until the fixture path closes."}},{"toolId":"alignment.evaluate","altitude":"altitude-11","description":"Evaluate one candidate bundle across ten dimensions and compute convergenceDistance.","classification":"AUTHOR_NEW","inputContractId":"alignment-evaluation.v1","outputContractId":"alignment-evaluation-receipt.v1","writeClass":"evaluate","implementation":{"mechanism":"PROPOSED evaluator capability plus model.put_semantic_definition \u0027AUTHORITY\u0027 receipt under sidefx:candidates (task-specified), or a new ALIGNMENT_EVALUATION object kind; concurrent dispatch for multi-model."},"admission":{"kind":"PROPOSED alignment-evaluation","installer":"model.put_semantic_definition \u0027AUTHORITY\u0027 (sidefx:candidates receipt) / \u0027ALIGNMENT_EVALUATION\u0027","receipt":"PROPOSED alignment-evaluation-receipt.v1"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"The contract is data (alignment-evaluation.v1 is published in the authority changeContracts) but no evaluator capability and no receipt writer exist."}},{"toolId":"candidate.decide","altitude":"altitude-11","description":"Record the review decision ACCEPTED|REPAIR|REJECTED with reviewer authority and note.","classification":"AUTHOR_NEW","inputContractId":"candidate-decision.v1","outputContractId":"candidate-decision-receipt.v1","writeClass":"evaluate","implementation":{"mechanism":"PROPOSED candidate-decision kind updating the candidate receipt review member through model.put_semantic_definition \u0027AUTHORITY\u0027 under sidefx:candidates."},"admission":{"kind":"PROPOSED candidate-decision","installer":"model.put_semantic_definition \u0027AUTHORITY\u0027 (sidefx:candidates review update)","receipt":"PROPOSED candidate-decision-receipt.v1"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"No decision writer exists; the reviewer authority identity is not yet declared."}},{"toolId":"alignment.broadcast","altitude":"altitude-11","description":"Run the same authoring request across several providers and collect one candidate per provider.","classification":"COMPOSE_EXISTING","inputContractId":"authoring-broadcast-request.v1","outputContractId":"authoring-broadcast-result.v1","writeClass":"read","implementation":{"mechanism":"Declaration-controlled concurrent dispatch (graph v2) with dispatchAuthorities{mode:concurrent,maximumActiveBranches} and an all-required join."},"admission":{"kind":"none (execution is data)","installer":"none","receipt":"per-provider candidate receipts via candidate.file"},"eligibility":{"toolEligible":true,"callable":false,"status":"no","reason":"The concurrent dispatch mechanism is tested, but no authoring broadcast capability is declared."}}]}';
IF ISJSON(@catalog)<>1 THROW 51000,N'MODEL_TOOL_CATALOG_INVALID',1;
IF (SELECT COUNT(*) FROM OPENJSON(@catalog,'$.entries'))<>31 THROW 51000,N'MODEL_TOOL_CATALOG_ENTRY_COUNT_DIVERGED',1;
DECLARE @list_tools_statement nvarchar(max)=N'SELECT JSON_VALUE(e.value,''$.toolId'') AS tool_id,
       JSON_VALUE(e.value,''$.altitude'') AS altitude,
       JSON_VALUE(e.value,''$.description'') AS description,
       JSON_VALUE(e.value,''$.inputContractId'') AS input_contract,
       JSON_VALUE(e.value,''$.outputContractId'') AS output_contract,
       JSON_VALUE(e.value,''$.writeClass'') AS write_class,
       JSON_VALUE(e.value,''$.implementation.mechanism'') AS implementation_mechanism,
       JSON_VALUE(e.value,''$.admission.kind'') AS admission_kind,
       JSON_VALUE(e.value,''$.admission.installer'') AS admission_installer,
       JSON_VALUE(e.value,''$.admission.receipt'') AS admission_receipt,
       LOWER(JSON_VALUE(e.value,''$.eligibility.toolEligible'')) AS tool_eligible,
       JSON_VALUE(ic.definition_json,''$.semantics.schema_digest'') AS input_schema_digest,
       JSON_VALUE(oc.definition_json,''$.semantics.schema_digest'') AS output_schema_digest,
       CASE WHEN EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition t
         WHERE t.estate_model_pk=c.estate_model_pk AND t.object_kind=N''TOOL''
          AND JSON_VALUE(t.definition_json,''$.semantics.toolId'')=JSON_VALUE(e.value,''$.toolId'')) THEN 1 ELSE 0 END AS registered
FROM analysis.v_selected_semantic_definition c
CROSS APPLY OPENJSON(JSON_QUERY(c.definition_json,''$.semantics.entries'')) e
LEFT JOIN analysis.v_selected_semantic_definition ic
  ON ic.estate_model_pk=c.estate_model_pk AND ic.object_kind=N''CONTRACT''
 AND ic.declared_id=JSON_VALUE(e.value,''$.inputContractId'')
LEFT JOIN analysis.v_selected_semantic_definition oc
  ON oc.estate_model_pk=c.estate_model_pk AND oc.object_kind=N''CONTRACT''
 AND oc.declared_id=JSON_VALUE(e.value,''$.outputContractId'')
WHERE c.estate_model_pk=@estate_model_pk AND c.object_kind=N''AUTHORITY''
 AND c.namespace_id=N''sidefx:tools'' AND c.declared_id=N''model-tool-catalog.v1''
 AND ISNULL(LOWER(JSON_VALUE(e.value,''$.eligibility.toolEligible'')),N''false'')=N''true''
ORDER BY tool_id';
DECLARE @admit_tool_call_statement nvarchar(max)=N'DECLARE @findings TABLE(ordinal int IDENTITY(1,1),code nvarchar(100),field nvarchar(400),message nvarchar(2000));
IF ISJSON(@input)<>1
 INSERT @findings(code,field,message) VALUES(N''TOOL_CALL_DOCUMENT_REQUIRED'',NULL,N''the call must be a JSON governed-tool-call.v1 document'');
ELSE BEGIN
 DECLARE @tool_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.toolId''),N'''');
 IF JSON_VALUE(@input,''$.contractId'')<>N''governed-tool-call.v1''
  INSERT @findings(code,field,message) VALUES(N''TOOL_CALL_CONTRACT_REQUIRED'',N''contractId'',N''contractId must be governed-tool-call.v1'');
 IF @tool_id IS NULL
  INSERT @findings(code,field,message) VALUES(N''TOOL_ID_REQUIRED'',N''toolId'',N''a call must name its toolId'');
 IF JSON_VALUE(@input,''$.input.contractId'') IS NULL
  INSERT @findings(code,field,message) VALUES(N''TOOL_INPUT_CONTRACT_REQUIRED'',N''input.contractId'',N''the call input must name its contract'');
 IF @tool_id IS NOT NULL AND NOT EXISTS(
  SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''TOOL''
   AND JSON_VALUE(d.definition_json,''$.semantics.toolId'')=@tool_id
   AND ISNULL(LOWER(JSON_VALUE(d.definition_json,''$.semantics.toolEligible'')),N''false'')=N''true'')
  INSERT @findings(code,field,message) VALUES(N''TOOL_NOT_REGISTERED'',N''toolId'',N''the toolId does not resolve to an eligible selected TOOL definition'');
 IF @tool_id IS NOT NULL AND JSON_VALUE(@input,''$.input.contractId'') IS NOT NULL AND NOT EXISTS(
  SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''TOOL''
   AND JSON_VALUE(d.definition_json,''$.semantics.toolId'')=@tool_id
   AND JSON_VALUE(d.definition_json,''$.semantics.inputContract'')=JSON_VALUE(@input,''$.input.contractId''))
  INSERT @findings(code,field,message) VALUES(N''TOOL_INPUT_CONTRACT_MISMATCH'',N''input.contractId'',N''the call input contract is not the declared input contract of the tool'');
END
DECLARE @reason nvarchar(max)=ISNULL((SELECT code,field,message FROM @findings ORDER BY ordinal FOR JSON PATH),N''[]'');
SELECT CASE WHEN (SELECT COUNT(*) FROM @findings)=0 THEN N''ADMITTED'' ELSE N''HELD'' END AS disposition,@reason AS reason';
DECLARE @admit_tool_registration_statement nvarchar(max)=N'DECLARE @findings TABLE(ordinal int IDENTITY(1,1),code nvarchar(100),field nvarchar(400),message nvarchar(2000));
IF ISJSON(@input)<>1
 INSERT @findings(code,field,message) VALUES(N''TOOL_REGISTRATION_DOCUMENT_REQUIRED'',NULL,N''the document must be a JSON tool-registration-change.v1'');
ELSE BEGIN
 DECLARE @tool_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.toolId''),N'''');
 DECLARE @capability_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.capabilityId''),N'''');
 DECLARE @input_contract nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.inputContract''),N'''');
 DECLARE @output_contract nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.outputContract''),N'''');
 IF JSON_VALUE(@input,''$.contractId'')<>N''tool-registration-change.v1''
  INSERT @findings(code,field,message) VALUES(N''TOOL_REGISTRATION_CONTRACT_REQUIRED'',N''contractId'',N''contractId must be tool-registration-change.v1'');
 IF @tool_id IS NULL
  INSERT @findings(code,field,message) VALUES(N''TOOL_ID_REQUIRED'',N''toolId'',N''a registration must name its toolId'');
 IF @capability_id IS NULL
  INSERT @findings(code,field,message) VALUES(N''TOOL_CAPABILITY_REQUIRED'',N''capabilityId'',N''a registration must name the selected capability the tool annotates'');
 ELSE IF NOT EXISTS(
  SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''CAPABILITY'' AND d.declared_id=@capability_id)
  INSERT @findings(code,field,message) VALUES(N''TOOL_CAPABILITY_NOT_DECLARED'',N''capabilityId'',N''the capabilityId does not resolve to a selected CAPABILITY'');
 IF @input_contract IS NULL
  INSERT @findings(code,field,message) VALUES(N''TOOL_INPUT_CONTRACT_REQUIRED'',N''inputContract'',N''a registration must name the tool input contract'');
 ELSE IF NOT EXISTS(
  SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''CONTRACT'' AND d.declared_id=@input_contract)
  INSERT @findings(code,field,message) VALUES(N''TOOL_INPUT_CONTRACT_NOT_DECLARED'',N''inputContract'',N''the inputContract does not resolve to a selected CONTRACT'');
 IF @output_contract IS NULL
  INSERT @findings(code,field,message) VALUES(N''TOOL_OUTPUT_CONTRACT_REQUIRED'',N''outputContract'',N''a registration must name the tool output contract'');
 ELSE IF NOT EXISTS(
  SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''CONTRACT'' AND d.declared_id=@output_contract)
  INSERT @findings(code,field,message) VALUES(N''TOOL_OUTPUT_CONTRACT_NOT_DECLARED'',N''outputContract'',N''the outputContract does not resolve to a selected CONTRACT'');
 DECLARE @effect nvarchar(40)=NULLIF(JSON_VALUE(@input,''$.effectClassification''),N'''');
 IF @effect IS NOT NULL AND @effect NOT IN (N''none'',N''model'',N''effect'')
  INSERT @findings(code,field,message) VALUES(N''TOOL_EFFECT_CLASSIFICATION_INVALID'',N''effectClassification'',N''effectClassification must be one of none, model, effect'');
 IF @tool_id IS NOT NULL AND EXISTS(
  SELECT 1 FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''TOOL''
   AND JSON_VALUE(d.definition_json,''$.semantics.toolId'')=@tool_id
   AND (ISNULL(JSON_VALUE(d.definition_json,''$.semantics.capabilityId''),N'''')<>ISNULL(@capability_id,N'''')
    OR ISNULL(JSON_VALUE(d.definition_json,''$.semantics.inputContract''),N'''')<>ISNULL(@input_contract,N'''')
    OR ISNULL(JSON_VALUE(d.definition_json,''$.semantics.outputContract''),N'''')<>ISNULL(@output_contract,N'''')))
  INSERT @findings(code,field,message) VALUES(N''TOOL_ID_SHADOWING'',N''toolId'',N''the toolId is already registered with a different capability or contract set'');
END
DECLARE @reason nvarchar(max)=ISNULL((SELECT code,field,message FROM @findings ORDER BY ordinal FOR JSON PATH),N''[]'');
SELECT CASE WHEN (SELECT COUNT(*) FROM @findings)=0 THEN N''ADMITTED'' ELSE N''HELD'' END AS disposition,@reason AS reason';
DECLARE @list_tools_read nvarchar(max)=(
 SELECT N'list-tools' AS readId,
  N'List every eligible tool in the model tool catalog with its altitude, write class, contracts, implementing mechanism and admission facts, resolving each contract to its selected schema digest and each tool to its registry row. Writes nothing.' AS purpose,
  N'observation' AS classification,
  N'tsql' AS sourceKind,
  @list_tools_statement AS statement,
  JSON_QUERY(N'[{"parameter":"estate_model_pk","kind":"pinned-session"}]') AS parameters,
  JSON_QUERY(N'{"recordsets":[{"index":0,"role":"model-tool-catalog","columns":["tool_id","altitude","description","input_contract","output_contract","write_class","implementation_mechanism","admission_kind","admission_installer","admission_receipt","tool_eligible","input_schema_digest","output_schema_digest","registered"]}]}') AS resultMapping
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @admit_tool_call_read nvarchar(max)=(
 SELECT N'admit-tool-call' AS readId,
  N'Validate a governed-tool-call.v1 envelope against the selected tool registry: the toolId must resolve to an eligible TOOL definition and the input contract must be that tool declared input contract. Returns ADMITTED or HELD with field-named findings; writes nothing.' AS purpose,
  N'observation' AS classification,
  N'tsql' AS sourceKind,
  @admit_tool_call_statement AS statement
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @admit_tool_registration_read nvarchar(max)=(
 SELECT N'admit-tool-registration-change' AS readId,
  N'Validate a tool-registration-change.v1 document: required fields, a resolving capabilityId, declared input/output contracts and no shadowing of an existing toolId. Returns ADMITTED or HELD with field-named findings; writes nothing.' AS purpose,
  N'observation' AS classification,
  N'tsql' AS sourceKind,
  @admit_tool_registration_statement AS statement
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @tool_registration_kind nvarchar(max)=(
 SELECT N'tool-registration-change' AS changeKind,
  N'tool-registration-change.v1' AS payloadContract,
  N'tool-registration-admission.v1' AS admissionId,
  JSON_QUERY(N'{"changeId":"install-tool-registration-change","parameterName":"document"}') AS install,
  JSON_QUERY(N'{"kind":"capability-invocation","capabilityPath":"capabilityId","inputPath":"preflight.input","expectedPath":"preflight.expected","dispositionPath":"route.resolvedDisposition"}') AS verification
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @tool_registration_admission nvarchar(max)=(
 SELECT N'tool-registration-admission.v1' AS admissionId,
  N'ADMITTED' AS lifecycle,
  N'tool-registration-change' AS changeKind,
  N'tool-registration-change.v1' AS payloadContract,
  N'tool-registration-change.v1' AS payloadAdmissionContract,
  N'install-tool-registration-change' AS changeId,
  N'document' AS parameterName,
  N'admit-tool-registration-change' AS readId,
  N'change-admitted.v1' AS resultContract,
  JSON_QUERY(N'{"executeProcedure":{"sourceKind":"tsql","name":"model.install_tool_registration_change"},"suspendGuardSets":["model-write-guards"]}') AS privileges
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @tool_registration_operation nvarchar(max)=(
 SELECT N'install-tool-registration-change' AS changeId,
  N'tsql' AS sourceKind,
  N'effect' AS classification,
  JSON_QUERY(N'{"kind":"procedure","name":"model.install_tool_registration_change"}') AS operation,
  JSON_QUERY(N'[{"name":"document","contract":"tool-registration-change.v1","binding":"parameter","encoding":"json"}]') AS parameters,
  N'tool-registration-change-installed.v1' AS resultContract,
  JSON_QUERY(N'{"transaction":"required","isolation":"serializable"}') AS scope,
  JSON_QUERY(N'[{"declaredGuardSuspension":"model-write-guards","restoreRequired":true}]') AS preconditions
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @c_tool_registration_change nvarchar(max)=N'{"title":"Tool registration change","description":"Registers one receipt-only TOOL definition in sidefx:tools. Registration is a trusted-migration or admitted-registry operation; the model tool loop is never granted this kind and no capability, contract, scenario, port or provider row is written.","type":"object","additionalProperties":false,"required":["contractId","toolId","capabilityId","class","inputContract","outputContract"],"properties":{"contractId":{"const":"tool-registration-change.v1"},"toolId":{"type":"string","minLength":1,"maxLength":400},"capabilityId":{"type":"string","minLength":1,"maxLength":400},"class":{"type":"string","minLength":1,"maxLength":50},"description":{"type":"string","minLength":1,"maxLength":8000},"inputContract":{"type":"string","minLength":1,"maxLength":400},"outputContract":{"type":"string","minLength":1,"maxLength":400},"effectClassification":{"enum":["none","model","effect"]},"admissionKind":{"type":"string","minLength":1,"maxLength":400},"toolEligible":{"type":"boolean"},"preflight":{"type":"object","additionalProperties":false,"properties":{"input":{"type":"object"},"expected":{"type":"object"},"disposition":{"type":"string","minLength":1,"maxLength":100}}},"route":{"type":"object","additionalProperties":false,"properties":{"resolvedDisposition":{"enum":["ADMITTED","HELD"]}}}}}';
DECLARE @c_tool_registration_installed nvarchar(max)=N'{"title":"Tool registration installed","description":"Exactly-one-row result of model.install_tool_registration_change: the registered toolId, its capabilityId and the definition digest. Byte-identical replay returns already_installed and writes no new definition row.","type":"object","additionalProperties":false,"required":["result_set","tool_id","capability_id","definition_digest"],"properties":{"result_set":{"enum":["tool_registration_installed","already_installed"]},"tool_id":{"type":"string","minLength":1,"maxLength":400},"capability_id":{"type":"string","minLength":1,"maxLength":400},"definition_digest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}}}';
DECLARE @c_governed_tool_call nvarchar(max)=N'{"title":"Governed tool call","description":"One model tool call: registered toolId, contract-identified input payload and the governed-invocation conversation identity. Declared data; carries no SQL, change id or privilege.","type":"object","additionalProperties":false,"required":["contractId","toolId","input","conversation"],"properties":{"contractId":{"const":"governed-tool-call.v1"},"toolId":{"type":"string","minLength":1,"maxLength":400},"input":{"type":"object","additionalProperties":false,"required":["contractId","payload"],"properties":{"contractId":{"type":"string","minLength":1,"maxLength":400},"payload":{"type":"object"}}},"conversation":{"type":"object","additionalProperties":false,"required":["requestId","requestHash","responseHash","attemptNumber","toolCallIndex","effectLineage"],"properties":{"requestId":{"type":"string","minLength":1,"maxLength":400},"requestHash":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"responseHash":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"attemptNumber":{"type":"integer","minimum":1},"toolCallIndex":{"type":"integer","minimum":0},"effectLineage":{"type":"array","minItems":1,"items":{"type":"string","minLength":1,"maxLength":800}}}}}}';
DECLARE @c_governed_tool_result nvarchar(max)=N'{"title":"Governed tool result","description":"The result of one governed tool call: call digest, disposition, outcome document, admission row, receipt identity and effect lineage. Never carries changeId, privileges or prepare pins.","type":"object","additionalProperties":false,"required":["contractId","toolId","callDigest","disposition","outcome","admission","receipt","effectLineage"],"properties":{"contractId":{"const":"governed-tool-result.v1"},"toolId":{"type":"string","minLength":1,"maxLength":400},"callDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"disposition":{"enum":["TERMINATED","HELD","REFUSED","FAILED"]},"outcome":{"type":"object","additionalProperties":false,"required":["contractId","payload"],"properties":{"contractId":{"type":"string","minLength":1,"maxLength":400},"payload":{"type":"object"}}},"admission":{"type":"object","additionalProperties":false,"required":["readId","disposition","reason"],"properties":{"readId":{"type":"string","minLength":1,"maxLength":200},"disposition":{"enum":["ADMITTED","HELD"]},"reason":{"type":"string","minLength":1,"maxLength":8000}}},"receipt":{"type":"object","additionalProperties":false,"required":["kind","declaredId","definitionDigest"],"properties":{"kind":{"type":"string","minLength":1,"maxLength":100},"declaredId":{"type":"string","minLength":1,"maxLength":400},"definitionDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}}},"effectLineage":{"type":"array","minItems":1,"items":{"type":"string","minLength":1,"maxLength":800}}}}';
DECLARE @c_model_tool_catalog nvarchar(max)=N'{"title":"Model tool catalog","description":"The declared model tool catalog: one entry per standard tool with altitude, purpose, contracts, write class, implementing mechanism, admission facts and eligibility. Declared data; grants no execution authority.","type":"object","additionalProperties":false,"required":["catalogType","entries"],"properties":{"catalogType":{"const":"model-tool-catalog.v1"},"entries":{"type":"array","minItems":1,"items":{"type":"object","additionalProperties":false,"required":["toolId","altitude","description","inputContractId","outputContractId","writeClass","implementation","admission","eligibility"],"properties":{"toolId":{"type":"string","minLength":1,"maxLength":200},"altitude":{"type":"string","minLength":1,"maxLength":20},"description":{"type":"string","minLength":1,"maxLength":8000},"inputContractId":{"type":"string","minLength":1,"maxLength":400},"outputContractId":{"type":"string","minLength":1,"maxLength":400},"writeClass":{"enum":["read","propose","install","content","evaluate"]},"implementation":{"type":"object"},"admission":{"type":"object"},"eligibility":{"type":"object"}}}}}}';
IF @declared=0
BEGIN
 SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@list_tools_read));
 SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@admit_tool_call_read));
 SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@admit_tool_registration_read));
 SET @body=JSON_MODIFY(@body,'append $.changeKinds',JSON_QUERY(@tool_registration_kind));
 SET @body=JSON_MODIFY(@body,'append $.changeAdmissions',JSON_QUERY(@tool_registration_admission));
 SET @body=JSON_MODIFY(@body,'append $.changeOperations',JSON_QUERY(@tool_registration_operation));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."tool-registration-change.v1"',JSON_QUERY(@c_tool_registration_change));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."tool-registration-change-installed.v1"',JSON_QUERY(@c_tool_registration_installed));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."governed-tool-call.v1"',JSON_QUERY(@c_governed_tool_call));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."governed-tool-result.v1"',JSON_QUERY(@c_governed_tool_result));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."model-tool-catalog.v1"',JSON_QUERY(@c_model_tool_catalog));
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content binary(32)=HASHBYTES('SHA2_256',@bytes);
 DECLARE @new_content nvarchar(80)=N'sha256:'+LOWER(CONVERT(varchar(64),@content,2));
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content)<>@bytes THROW 51000,N'MODEL_TOOL_REGISTRY_CONTENT_DIVERGED',1;
 DECLARE @authority_semantics nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
  WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
 SET @authority_semantics=JSON_MODIFY(@authority_semantics,'$.contentDigest',@new_content);
 DECLARE @authority_object bigint,@authority_definition bigint,@authority_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@authority_semantics,@authority_object OUTPUT,@authority_definition OUTPUT,@authority_digest OUTPUT;
END
DECLARE @catalog_object bigint,@catalog_definition bigint,@catalog_digest binary(32);
EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:tools',N'model-tool-catalog.v1',@catalog,@catalog_object OUTPUT,@catalog_definition OUTPUT,@catalog_digest OUTPUT;
DECLARE @tool_semantics TABLE(tool_id nvarchar(400) COLLATE Latin1_General_100_BIN2,semantics nvarchar(max));
INSERT @tool_semantics(tool_id,semantics)
SELECT JSON_VALUE(e.value,'$.toolId'),
 (SELECT JSON_VALUE(e.value,'$.toolId') AS toolId,
   JSON_VALUE(e.value,'$.altitude') AS altitude,
   JSON_VALUE(e.value,'$.writeClass') AS class,
   JSON_VALUE(e.value,'$.description') AS description,
   JSON_VALUE(e.value,'$.inputContractId') AS inputContract,
   JSON_VALUE(e.value,'$.outputContractId') AS outputContract,
   JSON_VALUE(e.value,'$.admission.kind') AS admissionKind,
   CONVERT(bit,1) AS toolEligible
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
FROM OPENJSON(@catalog,'$.entries') e;
IF (SELECT COUNT(*) FROM @tool_semantics)<>31 THROW 51000,N'MODEL_TOOL_REGISTRY_TOOL_COUNT_DIVERGED',1;
DECLARE @tool_id nvarchar(400),@tool_semantics_row nvarchar(max);
DECLARE tool_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT tool_id,semantics FROM @tool_semantics ORDER BY tool_id;
OPEN tool_cursor;
FETCH NEXT FROM tool_cursor INTO @tool_id,@tool_semantics_row;
WHILE @@FETCH_STATUS=0
BEGIN
 DECLARE @tool_object bigint,@tool_definition bigint,@tool_digest binary(32);
 EXEC model.put_semantic_definition 'TOOL',N'sidefx:tools',@tool_id,@tool_semantics_row,@tool_object OUTPUT,@tool_definition OUTPUT,@tool_digest OUTPUT;
 FETCH NEXT FROM tool_cursor INTO @tool_id,@tool_semantics_row;
END
CLOSE tool_cursor;
DEALLOCATE tool_cursor;
IF OBJECT_ID(N'model.install_tool_registration_change') IS NULL THROW 51000,N'MODEL_TOOL_REGISTRY_INSTALLER_MISSING',1;
DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
DECLARE @declared_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@result_content,N'sha256:',N''),2));
IF JSON_VALUE(@declared_body,'$.authorityDigest')<>N'sha256:a34639fce305a43c02c4cc5f072a4e3a98c1f1ba90ffb23739d321a9e21a7db3' THROW 51000,N'MODEL_TOOL_REGISTRY_AUTHORITY_DIGEST_DIVERGED',1;
IF (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads') WHERE JSON_VALUE(value,'$.readId') IN (N'list-tools',N'admit-tool-call',N'admit-tool-registration-change'))<>3
 OR (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=N'tool-registration-change')<>1
 OR (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeAdmissions') WHERE JSON_VALUE(value,'$.readId')=N'admit-tool-registration-change')<>1
 OR (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeOperations') WHERE JSON_VALUE(value,'$.changeId')=N'install-tool-registration-change')<>1
 OR (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeContracts') WHERE [key] IN (N'tool-registration-change.v1',N'tool-registration-change-installed.v1',N'governed-tool-call.v1',N'governed-tool-result.v1',N'model-tool-catalog.v1'))<>5
 THROW 51000,N'MODEL_TOOL_REGISTRY_DECLARATION_INCOMPLETE',1;
SELECT N'model_tool_registry_declared' AS result_set,N'7c30b9f44eb6c9fe3c0a611c3f5d739cdd3ba00eeb6dd9385bbd1bf6a1eccf79' AS prior_content_digest,
 @result_content AS declared_content_digest,
 CASE WHEN @declared=1 THEN N'already_declared' WHEN @selected=@prior_content THEN N'redeclared' ELSE N'reconciled' END AS disposition,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads')) AS read_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeKinds')) AS change_kind_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeAdmissions')) AS change_admission_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeContracts')) AS change_contract_count;
SELECT N'declared_read' AS result_set,JSON_VALUE(value,'$.readId') AS read_id,JSON_VALUE(value,'$.classification') AS classification,
 CASE WHEN JSON_QUERY(value,'$.parameters') IS NULL THEN 0 ELSE 1 END AS pinned_parameter
FROM OPENJSON(@declared_body,'$.reads')
WHERE JSON_VALUE(value,'$.readId') IN (N'list-tools',N'admit-tool-call',N'admit-tool-registration-change')
ORDER BY read_id;
SELECT N'declared_change_kind' AS result_set,JSON_VALUE(value,'$.changeKind') AS change_kind,JSON_VALUE(value,'$.payloadContract') AS payload_contract,
 JSON_VALUE(value,'$.install.changeId') AS install_change_id,JSON_VALUE(value,'$.verification.kind') AS verification_kind
FROM OPENJSON(@declared_body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=N'tool-registration-change';
SELECT N'declared_change_contract' AS result_set,[key] AS contract_id
FROM OPENJSON(@declared_body,'$.changeContracts')
WHERE [key] IN (N'tool-registration-change.v1',N'tool-registration-change-installed.v1',N'governed-tool-call.v1',N'governed-tool-result.v1',N'model-tool-catalog.v1')
ORDER BY [key];
SELECT N'catalog_seed' AS result_set,JSON_VALUE(definition_json,'$.semantics.catalogType') AS catalog_type,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(definition_json,'$.semantics.entries'))) AS entry_count,
 N'sha256:'+LOWER(CONVERT(varchar(64),definition_digest,2)) AS definition_digest
FROM analysis.v_selected_semantic_definition
WHERE estate_model_pk=@estate AND object_kind=N'AUTHORITY' AND namespace_id=N'sidefx:tools' AND declared_id=N'model-tool-catalog.v1';
SELECT N'registry_seed' AS result_set,COUNT(*) AS tool_count,
 SUM(CASE WHEN ISNULL(LOWER(JSON_VALUE(definition_json,'$.semantics.toolEligible')),N'false')=N'true' THEN 1 ELSE 0 END) AS tool_eligible
FROM analysis.v_selected_semantic_definition
WHERE estate_model_pk=@estate AND object_kind=N'TOOL' AND namespace_id=N'sidefx:tools';
DECLARE @capability_now bigint=(SELECT COUNT(*) FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=@estate AND object_kind=N'CAPABILITY');
DECLARE @contract_now bigint=(SELECT COUNT(*) FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=@estate AND object_kind=N'CONTRACT');
DECLARE @scenario_now bigint=(SELECT COUNT(*) FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=@estate AND object_kind=N'SCENARIO');
DECLARE @port_now bigint=(SELECT COUNT(*) FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=@estate AND object_kind=N'PORT');
SELECT N'executable_content_unchanged' AS result_set,
 ISNULL((SELECT CASE WHEN row_count=@capability_now THEN 1 ELSE 0 END FROM @executables WHERE object_kind=N'CAPABILITY'),1) AS capability_unchanged,
 ISNULL((SELECT CASE WHEN row_count=@contract_now THEN 1 ELSE 0 END FROM @executables WHERE object_kind=N'CONTRACT'),1) AS contract_unchanged,
 ISNULL((SELECT CASE WHEN row_count=@scenario_now THEN 1 ELSE 0 END FROM @executables WHERE object_kind=N'SCENARIO'),1) AS scenario_unchanged,
 ISNULL((SELECT CASE WHEN row_count=@port_now THEN 1 ELSE 0 END FROM @executables WHERE object_kind=N'PORT'),1) AS port_unchanged,
 (SELECT COUNT(*) FROM @executables) AS compared_kinds;
DECLARE @list_tools_table TABLE(tool_id nvarchar(400),altitude nvarchar(50),description nvarchar(max),input_contract nvarchar(400),output_contract nvarchar(400),
 write_class nvarchar(50),implementation_mechanism nvarchar(max),admission_kind nvarchar(400),admission_installer nvarchar(400),admission_receipt nvarchar(400),
 tool_eligible nvarchar(10),input_schema_digest nvarchar(100),output_schema_digest nvarchar(100),registered int);
INSERT @list_tools_table EXEC sp_executesql @list_tools_statement,N'@estate_model_pk bigint',@estate_model_pk=@estate;
SELECT N'list_tools_summary' AS result_set,COUNT(*) AS tool_count,
 SUM(CASE WHEN input_schema_digest IS NOT NULL THEN 1 ELSE 0 END) AS input_contracts_resolved,
 SUM(CASE WHEN input_schema_digest IS NULL THEN 1 ELSE 0 END) AS input_contracts_null,
 SUM(CASE WHEN output_schema_digest IS NOT NULL THEN 1 ELSE 0 END) AS output_contracts_resolved,
 SUM(CASE WHEN output_schema_digest IS NULL THEN 1 ELSE 0 END) AS output_contracts_null,
 SUM(registered) AS registry_rows
FROM @list_tools_table;
SELECT N'list_tools' AS result_set,tool_id,altitude,write_class,input_contract,output_contract,
 CASE WHEN input_schema_digest IS NULL THEN 0 ELSE 1 END AS input_resolved,
 CASE WHEN output_schema_digest IS NULL THEN 0 ELSE 1 END AS output_resolved,registered
FROM @list_tools_table ORDER BY tool_id;
DECLARE @admit_result TABLE(disposition nvarchar(20),reason nvarchar(max));
DECLARE @valid_registration nvarchar(max)=N'{"contractId":"tool-registration-change.v1","toolId":"self.test.tool","capabilityId":"list-capabilities","class":"read","description":"Admission self-test registration.","inputContract":"list-capabilities-request.v1","outputContract":"list-capabilities-result.v1","effectClassification":"none","admissionKind":"none"}';
INSERT @admit_result EXEC sp_executesql @admit_tool_registration_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@valid_registration,@estate_model_pk=@estate;
SELECT N'admit_tool_registration_valid' AS result_set,* FROM @admit_result;
DELETE @admit_result;
DECLARE @held_registration nvarchar(max)=N'{"contractId":"tool-registration-change.v1","toolId":"self.test.held","capabilityId":"capability-that-does-not-exist","class":"read","inputContract":"list-capabilities-request.v1","outputContract":"list-capabilities-result.v1"}';
INSERT @admit_result EXEC sp_executesql @admit_tool_registration_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@held_registration,@estate_model_pk=@estate;
SELECT N'admit_tool_registration_held' AS result_set,* FROM @admit_result;
DELETE @admit_result;
DECLARE @valid_call nvarchar(max)=N'{"contractId":"governed-tool-call.v1","toolId":"provider.author","input":{"contractId":"provider-binding-change-request.v1","payload":{"providerId":"demo"}},"conversation":{"requestId":"agent-objective","requestHash":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","responseHash":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","attemptNumber":1,"toolCallIndex":0,"effectLineage":["agent-objective","obtain-governed-model-response"]}}';
INSERT @admit_result EXEC sp_executesql @admit_tool_call_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@valid_call,@estate_model_pk=@estate;
SELECT N'admit_tool_call_valid' AS result_set,* FROM @admit_result;
DELETE @admit_result;
DECLARE @mismatched_call nvarchar(max)=N'{"contractId":"governed-tool-call.v1","toolId":"provider.author","input":{"contractId":"wrong-contract.v1","payload":{}},"conversation":{"requestId":"agent-objective","requestHash":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","responseHash":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","attemptNumber":1,"toolCallIndex":0,"effectLineage":["agent-objective"]}}';
INSERT @admit_result EXEC sp_executesql @admit_tool_call_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@mismatched_call,@estate_model_pk=@estate;
SELECT N'admit_tool_call_held' AS result_set,* FROM @admit_result;
COMMIT TRANSACTION;
