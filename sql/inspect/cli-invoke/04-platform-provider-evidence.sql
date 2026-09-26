-- 04-platform-provider-evidence.sql
--
-- Proves: the provider side of the request-named mechanism is declared in DB
-- tables, for both platform capabilities the CLI-invoke port has named:
--   * sda-node-consumer-runtime.v1 -> provider ScenarioKernel.NodePlatform
--     (provider pk 6), whose selected provider definition declares the
--     scenario-invocation mechanic; a provider_capability_implementation row
--     with role PLATFORM links that provider to the platform capability.
--   * sda-projected-capability-invocation-port.v2 -> provider
--     ScenarioKernel.NodePlatform.Execution.ProjectedCapabilityInvocationAndBinding
--     (provider pk 41), which declares projected-capability-invocation and
--     pinned-capability-binding -- a pinned application, not a request-named one.
-- It also shows the selected graph source carries the provider qualification for
-- sda-cli-invoke-port (estateProvider.provider + providesMechanics including
-- scenario-invocation), and the one declaration that is referenced but absent:
-- overlay binding rule on run-declared-graph-execute names providerProfileId
-- node:provider:sda-node-consumer-runtime.v1, for which model.provider_profile
-- has zero rows. The digest on that rule equals the selected provider
-- definition of ScenarioKernel.NodePlatform, so the provider body is declared;
-- whether the kernel also reads a model.provider_profile row for an overlay
-- profile id is UNPROVEN from this database (the failing query is the
-- zero-count row in this file).
--
-- Read-only: BEGIN TRANSACTION ... ROLLBACK, SELECT only.
SET NOCOUNT ON;
BEGIN TRANSACTION;

DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

SELECT 'providers' AS result_set, p.provider_pk, p.provider_id, n.namespace_id,
  (SELECT COUNT(*) FROM model.provider_definition pd WHERE pd.provider_pk=p.provider_pk) AS provider_definitions
FROM model.provider p
JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
WHERE p.provider_id IN (N'ScenarioKernel.NodePlatform',
  N'ScenarioKernel.NodePlatform.Execution.ProjectedCapabilityInvocationAndBinding')
ORDER BY p.provider_id;

SELECT 'provider_capability_implementation' AS result_set,
  p.provider_id, pci.provider_definition_pk, c.capability_id, c.capability_pk,
  cv.capability_version_pk, pci.role
FROM model.provider_capability_implementation pci
JOIN model.provider_definition pd ON pd.provider_definition_pk=pci.provider_definition_pk
JOIN model.provider p ON p.provider_pk=pd.provider_pk
JOIN model.capability_version cv ON cv.capability_version_pk=pci.capability_version_pk
JOIN model.capability c ON c.capability_pk=cv.capability_pk
WHERE c.capability_id IN (N'sda-node-consumer-runtime.v1', N'sda-projected-capability-invocation-port.v2')
ORDER BY c.capability_id, p.provider_id, pci.provider_definition_pk;

SELECT 'selected_provider_mechanics' AS result_set, sd.declared_id AS provider_id, sd.semantic_object_definition_pk,
  CONVERT(varchar(64),sd.definition_digest,2) AS definition_digest,
  STRING_AGG(CONVERT(nvarchar(max),m.mechanic_id+N'['+CONVERT(nvarchar(20),pmi.mechanic_version_pk)+N']'+
    ISNULL(N' role='+pmi.role,N'')), N'; ') WITHIN GROUP (ORDER BY m.mechanic_id) AS declared_mechanics
FROM analysis.v_selected_semantic_definition sd
JOIN model.provider_definition pd ON pd.semantic_object_definition_pk=sd.semantic_object_definition_pk
JOIN model.provider_mechanic_implementation pmi ON pmi.provider_definition_pk=pd.provider_definition_pk
JOIN model.mechanic_version mv ON mv.mechanic_version_pk=pmi.mechanic_version_pk
JOIN model.mechanic m ON m.mechanic_pk=mv.mechanic_pk
WHERE sd.estate_model_pk=@estate AND sd.object_kind=N'PROVIDER'
  AND sd.declared_id IN (N'ScenarioKernel.NodePlatform',
    N'ScenarioKernel.NodePlatform.Execution.ProjectedCapabilityInvocationAndBinding')
GROUP BY sd.declared_id, sd.semantic_object_definition_pk, sd.definition_digest
ORDER BY sd.declared_id;

SELECT 'consumer_runtime_overlay_binding' AS result_set, so.declared_id AS port_id,
  JSON_VALUE(b.value,'$.mechanicId') AS mechanic_id,
  JSON_VALUE(b.value,'$.providerProfileId') AS provider_profile_id,
  JSON_VALUE(b.value,'$.providerProfileDigest') AS provider_profile_digest,
  JSON_VALUE(b.value,'$.implementationRef') AS implementation_ref
FROM analysis.v_selected_semantic_definition sd
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=sd.semantic_object_definition_pk
JOIN model.semantic_object so ON so.semantic_object_pk=sod.semantic_object_pk
CROSS APPLY OPENJSON(JSON_QUERY(sd.definition_json,'$.semantics.configuration.overlayBindings')) b
WHERE sd.estate_model_pk=@estate AND sd.object_kind=N'PORT'
  AND JSON_VALUE(b.value,'$.mechanicId')=N'sda-node-consumer-runtime.v1';

SELECT 'overlay_profile_declaration_gap' AS result_set,
  (SELECT COUNT(*) FROM model.provider_profile pp
    WHERE pp.provider_profile_id=N'node:provider:sda-node-consumer-runtime.v1') AS provider_profile_rows,
  (SELECT COUNT(*) FROM model.provider_profile_version ppv
    JOIN model.provider_profile pp ON pp.provider_profile_pk=ppv.provider_profile_pk
    WHERE pp.provider_profile_id=N'node:provider:sda-node-consumer-runtime.v1') AS provider_profile_version_rows,
  (SELECT COUNT(*) FROM model.semantic_object so
    WHERE so.declared_id=N'node:provider:sda-node-consumer-runtime.v1') AS semantic_object_rows,
  (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition sd
    WHERE sd.estate_model_pk=@estate AND sd.object_kind=N'PROVIDER'
      AND CONVERT(varchar(64),sd.definition_digest,2)=
          N'8261F0415F6883D83758508DFF469930801B81D0734B217F98CAEB2D04AFB226') AS digest_matches_selected_provider_definition;

SELECT 'selected_graph_provider_qualification' AS result_set,
  JSON_VALUE(g.graph_source,'$.interfaceAuthority.portBindings[0].portId') AS port_id,
  JSON_VALUE(g.graph_source,'$.interfaceAuthority.portBindings[0].platformCapabilityId') AS platform_capability_id,
  JSON_VALUE(g.graph_source,'$.interfaceAuthority.portBindings[0].configuration.estateProvider.capabilities[0].provider') AS provider_id,
  JSON_QUERY(g.graph_source,'$.interfaceAuthority.portBindings[0].configuration.estateProvider.capabilities[0].providesMechanics') AS provides_mechanics
FROM analysis.capability_graph_source(N'sda-cli-invoke',0,NULL) g;

ROLLBACK TRANSACTION;
