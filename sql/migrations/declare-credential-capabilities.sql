-- declare-credential-capabilities.sql
--
-- W2 of docs/vault-manager-agent-strategy.md: the two declared capabilities of
-- the credential vault (docs/vault-manager-capabilities.md section 2), authored
-- through the JSON surface (`model.declare_capability_document`) and installed
-- by one migration.
--
--   store-credential   one invoke-port -> sda-credential-vault-port.v1 `store`.
--                      Input: store-credential-request.v1 {referenceName, secret,
--                      scope?}; the secret is the only plaintext member. Result:
--                      store-credential-result.v1 -- a non-disclosing receipt
--                      {disposition, referenceName, entryId, storedAt,
--                      formatVersion, realization?, nonDisclosureVerified}; no
--                      secret and no digest or derivative of the secret.
--   resolve-credential one invoke-port -> sda-credential-vault-port.v1 `apply`.
--                      Input: resolve-credential-request.v1
--                      {credentialReference, invocationIdentity,
--                      requestingCapabilityId, endpointAuthorityDigest,
--                      effectScope}; the exact shape the credential port already
--                      requires. Result: resolve-credential-result.v1 -- the
--                      application outcome and binding proof (disposition,
--                      opaqueBindingId, referenceName, effectScope, expiresAt,
--                      nonDisclosureVerified), never "secret revealed".
--
-- There is no reveal operation and no reveal outcome: the kernel-internal
-- one-use binding is applied to the authorized provider invocation, and the
-- standalone invocation returns proof-of-application only.
--
-- Reference policy. The apply policy is the union of the installed credential
-- authorities (source environment today; W4 switches them to the vault without
-- changing names, digests, scopes or injection rules): RAPID_API_KEY (primary
-- and fallback endpoint digests), LOC_GEMINI_API_KEY and LOC_OPENAI_API_KEY.
-- The vault port admits exactly the declared names, requesting capabilities,
-- endpoint authority digests, effect scopes and injection rules.
--
-- Display. The CLI display selects the terminal outcome only (`outcome` as
-- json); the input mapping is the canonical JSON envelope, so no display or
-- input mapping member ever echoes `secret`. The declared variants register in
-- the outcome-variant registry (model.outcome_variant) with their
-- success/failure classification, and the operation refusals ride the execution
-- authority as declared `outcomeVariants`; the streamed display reads those
-- classifications. VAULT_SEALED is declared on both capabilities because both
-- port operations fail closed with it when no key handle is available.
--
-- Dependencies (outside this repository's migrations):
--   * SDA W0: the vault primitive named `sda-credential-vault-port.v1` with
--     operations store/apply, its registry entry, and its compiler knowledge
--     (KNOWN_EFFECT_PORT_IDS / PLATFORM_EFFECT_PORTS).
--   * Estate `run-declared-graph-execute`: one new overlay binding
--       {"mechanicId":"sda-credential-vault-port.v1",
--        "providerProfileId":"sda-platform-effect-graph-provider.v1",
--        "providerProfileDigest":"sha256:945a4ff5c2a0c550f35a18296888f6941a303f02c17de3c942cacace2f7e1358",
--        "implementationRef":"sda-platform-effect-graph-provider.v1"}
--     merged into configuration.overlayBindings with the pattern of
--     complete-run-declared-graph-pure-mechanic-bindings.sql. Measured without
--     it: the from-transaction preflight resolves the capability's read path and
--     fails at SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING:
--     'sda-credential-vault-port.v1'. This migration must not change that
--     existing authority row; it is recorded here as the one estate-side binding
--     the invocation needs.
--   * W3: the boot releases the OS-keystore key handle into
--     effectContextOverrides.secretVaultKeyHandle; without it both operations
--     return VAULT_SEALED, never plaintext.
--   * The vault realization resolves `%LOCALAPPDATA%\sfx\vault` (the declared
--     store locator) and reads `configuration.storeLocator` per section 3 of
--     docs/vault-manager-capabilities.md.
--
-- Source documents, carried here byte-identical:
--   examples/json-authoring/store-credential.authority.json
--   examples/json-authoring/resolve-credential.authority.json
--
-- Idempotent: the procedure's document-digest gate returns UNCHANGED on replay
-- and mints no further capability version; each document is installed twice to
-- prove the replay is a no-op. The migration prints the proof result sets from
-- inside the uncommitted transaction.
--
-- Default: ROLLBACK. Install only after the from-transaction preflight passes:
--   node scripts/run-migration.mjs sql/migrations/declare-credential-capabilities.sql
-- To install, replace the final rollback statement with a commit statement and
-- run the same command.
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
CLOSE @triggers;
DEALLOCATE @triggers;
GO
-- =====================================================================
-- store-credential. The document is byte-identical to
-- examples/json-authoring/store-credential.authority.json.
-- Installed, then installed a second time to prove the replay is a no-op.
-- =====================================================================
DECLARE @store_credential nvarchar(max) = N'{
  "document": "sidefx-capability-authority.v1",
  "capabilityId": "store-credential",
  "meaning": {
    "intent": "store a plaintext credential in the local vault under an allowed reference name",
    "outcome": "the caller receives a non-disclosing receipt naming the reference and entry; the secret is never returned, displayed or retained"
  },
  "cli": { "display": { "select": "outcome", "as": "json" } },
  "contracts": [
    { "id": "store-credential-request.v1",
      "schema": {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "https://schemas.sidefx.local/contracts/store-credential-request.v1.schema.json",
        "title": "Store credential request",
        "description": "One plaintext secret under an allowed vault reference name. The secret is the only plaintext member and never appears in an outcome, testimony or row.",
        "type": "object",
        "additionalProperties": false,
        "required": ["contractId", "payload"],
        "properties": {
          "contractId": { "const": "store-credential-request.v1" },
          "payload": {
            "type": "object",
            "additionalProperties": false,
            "required": ["referenceName", "secret"],
            "properties": {
              "referenceName": { "type": "string", "minLength": 1 },
              "secret": { "type": "string", "minLength": 1 },
              "scope": { "type": "string" }
            }
          }
        }
      } },
    { "id": "store-credential-result.v1",
      "schema": {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "https://schemas.sidefx.local/contracts/store-credential-result.v1.schema.json",
        "title": "Store credential result",
        "description": "The vault receipt: the disposition plus reference and entry metadata. No secret, no digest or derivative of the secret, and no reveal variant.",
        "type": "object",
        "additionalProperties": false,
        "required": ["disposition", "referenceName", "entryId", "storedAt", "formatVersion", "nonDisclosureVerified"],
        "properties": {
          "disposition": { "enum": ["CREDENTIAL_STORED", "CREDENTIAL_STORE_REJECTED", "VAULT_SEALED"] },
          "referenceName": { "type": "string" },
          "entryId": { "type": "string" },
          "storedAt": { "type": ["string", "null"] },
          "formatVersion": { "type": "string" },
          "realization": { "type": "string" },
          "nonDisclosureVerified": { "const": true }
        }
      } }
  ],
  "scenarios": [
    {
      "scenarioId": "store-credential",
      "name": "Store a credential in the local vault",
      "inputId": "store-credential-request",
      "inputContract": "store-credential-request.v1",
      "eventId": "store-credential-requested",
      "eventAuthority": "store-credential.v1",
      "outcomeId": "store-credential-result",
      "outcomeContract": "store-credential-result.v1",
      "terminal": true,
      "root": true,
      "given": "a plaintext secret, an allowed reference name and the vault declared policy",
      "when": "the credential vault store operation runs under the OS keystore realization",
      "then": "a non-disclosing receipt names the reference and entry and the secret appears nowhere",
      "variants": [
        { "variantId": "CREDENTIAL_STORED", "classification": "success" },
        { "variantId": "CREDENTIAL_STORE_REJECTED", "classification": "failure" },
        { "variantId": "VAULT_SEALED", "classification": "failure" }
      ],
      "operations": [
        { "operationId": "store-credential.0", "kind": "invoke-port",
          "portId": "store-credential-port",
          "outcomeVariants": [
            { "variantId": "CREDENTIAL_STORED", "classification": "success" },
            { "variantId": "CREDENTIAL_STORE_REJECTED", "classification": "failure" },
            { "variantId": "VAULT_SEALED", "classification": "failure" }
          ] }
      ],
      "portBindings": [
        { "portId": "store-credential-port",
          "platformCapabilityId": "sda-credential-vault-port.v1",
          "configuration": {
            "operation": "store",
            "storeLocator": "%LOCALAPPDATA%\\sfx\\vault",
            "allowedReferenceNames": ["RAPID_API_KEY", "LOC_GEMINI_API_KEY", "LOC_OPENAI_API_KEY"],
            "maximumSecretBytes": 4096
          } }
      ]
    }
  ]
}';
EXEC model.declare_capability_document @document=@store_credential;
EXEC model.declare_capability_document @document=@store_credential;
GO
-- =====================================================================
-- resolve-credential. The document is byte-identical to
-- examples/json-authoring/resolve-credential.authority.json.
-- Installed, then installed a second time to prove the replay is a no-op.
-- =====================================================================
DECLARE @resolve_credential nvarchar(max) = N'{
  "document": "sidefx-capability-authority.v1",
  "capabilityId": "resolve-credential",
  "meaning": {
    "intent": "resolve a credential requirement into a one-use binding for an authorized provider invocation",
    "outcome": "the caller observes the application outcome and binding proof only; no secret is revealed and no digest of it is returned"
  },
  "cli": { "display": { "select": "outcome", "as": "json" } },
  "contracts": [
    { "id": "resolve-credential-request.v1",
      "schema": {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "https://schemas.sidefx.local/contracts/resolve-credential-request.v1.schema.json",
        "title": "Resolve credential request",
        "description": "A credential requirement: which reference, for which authorized invocation, under which endpoint authority digest and effect scope. No secret material.",
        "type": "object",
        "additionalProperties": false,
        "required": ["contractId", "payload"],
        "properties": {
          "contractId": { "const": "resolve-credential-request.v1" },
          "payload": {
            "type": "object",
            "additionalProperties": false,
            "required": ["credentialReference", "invocationIdentity", "requestingCapabilityId", "endpointAuthorityDigest", "effectScope"],
            "properties": {
              "credentialReference": { "type": "string", "minLength": 1 },
              "invocationIdentity": { "type": "string", "minLength": 1 },
              "requestingCapabilityId": { "type": "string", "minLength": 1 },
              "endpointAuthorityDigest": { "type": "string", "pattern": "^sha256:[0-9a-f]{64}$" },
              "effectScope": { "type": "string", "minLength": 1 }
            }
          }
        }
      } },
    { "id": "resolve-credential-result.v1",
      "schema": {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "https://schemas.sidefx.local/contracts/resolve-credential-result.v1.schema.json",
        "title": "Resolve credential result",
        "description": "The application outcome and binding proof of a credential applied to an authorized provider invocation. No secret, no digest or derivative of the secret, and no reveal variant.",
        "type": "object",
        "additionalProperties": false,
        "required": ["disposition", "opaqueBindingId", "referenceName", "effectScope", "expiresAt", "nonDisclosureVerified"],
        "properties": {
          "disposition": { "enum": ["CREDENTIAL_BOUND", "CREDENTIAL_NOT_AVAILABLE", "UNAUTHORIZED_REFERENCE", "IDENTITY_MISMATCH", "VAULT_SEALED"] },
          "opaqueBindingId": { "type": "string" },
          "referenceName": { "type": "string" },
          "effectScope": { "type": "string" },
          "invocationIdentity": { "type": "string" },
          "endpointAuthorityDigest": { "type": "string" },
          "expiresAt": { "type": ["string", "null"] },
          "realization": { "type": "string" },
          "nonDisclosureVerified": { "const": true }
        }
      } }
  ],
  "scenarios": [
    {
      "scenarioId": "resolve-credential",
      "name": "Apply a credential to an authorized provider invocation",
      "inputId": "resolve-credential-request",
      "inputContract": "resolve-credential-request.v1",
      "eventId": "resolve-credential-requested",
      "eventAuthority": "resolve-credential.v1",
      "outcomeId": "resolve-credential-result",
      "outcomeContract": "resolve-credential-result.v1",
      "terminal": true,
      "root": true,
      "given": "a credential requirement naming the reference, requesting capability, endpoint authority digest and effect scope",
      "when": "the credential vault apply operation places the one-use binding in the invocation effect context",
      "then": "the application outcome and binding proof are returned and the secret is not revealed",
      "variants": [
        { "variantId": "CREDENTIAL_BOUND", "classification": "success" },
        { "variantId": "CREDENTIAL_NOT_AVAILABLE", "classification": "failure" },
        { "variantId": "UNAUTHORIZED_REFERENCE", "classification": "failure" },
        { "variantId": "IDENTITY_MISMATCH", "classification": "failure" },
        { "variantId": "VAULT_SEALED", "classification": "failure" }
      ],
      "operations": [
        { "operationId": "resolve-credential.0", "kind": "invoke-port",
          "portId": "resolve-credential-port",
          "outcomeVariants": [
            { "variantId": "CREDENTIAL_BOUND", "classification": "success" },
            { "variantId": "CREDENTIAL_NOT_AVAILABLE", "classification": "failure" },
            { "variantId": "UNAUTHORIZED_REFERENCE", "classification": "failure" },
            { "variantId": "IDENTITY_MISMATCH", "classification": "failure" },
            { "variantId": "VAULT_SEALED", "classification": "failure" }
          ] }
      ],
      "portBindings": [
        { "portId": "resolve-credential-port",
          "platformCapabilityId": "sda-credential-vault-port.v1",
          "configuration": {
            "operation": "apply",
            "storeLocator": "%LOCALAPPDATA%\\sfx\\vault",
            "allowedReferenceNames": ["RAPID_API_KEY", "LOC_GEMINI_API_KEY", "LOC_OPENAI_API_KEY"],
            "maximumSecretBytes": 4096,
            "referencePolicy": [
              { "referenceName": "RAPID_API_KEY",
                "requestingCapabilityIds": ["resolve-equity-market-price-evidence"],
                "endpointAuthorityDigests": ["sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b", "sha256:17bd0ab8347e100f7987de6b1a0144d3555c43aea73fedf90786030593a76769"],
                "effectScopes": ["ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY"],
                "lifetimeMilliseconds": 15000,
                "injectionRule": { "id": "rapidapi-x-rapidapi-key.v1", "headerName": "X-RapidAPI-Key" } },
              { "referenceName": "LOC_GEMINI_API_KEY",
                "requestingCapabilityIds": ["execute-governed-model-invocation", "obtain-governed-model-response", "author-tooling-capability-candidate", "execute-projected-model-provider-attempt"],
                "endpointAuthorityDigests": ["sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04"],
                "effectScopes": ["governed-model-invocation"],
                "lifetimeMilliseconds": 120000,
                "injectionRule": { "id": "gemini-x-goog-api-key.v1", "headerName": "x-goog-api-key" } },
              { "referenceName": "LOC_OPENAI_API_KEY",
                "requestingCapabilityIds": ["execute-governed-model-invocation", "obtain-governed-model-response", "author-tooling-capability-candidate", "execute-projected-model-provider-attempt", "speech-provider"],
                "endpointAuthorityDigests": ["sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109"],
                "effectScopes": ["governed-model-invocation", "speech-provider-exchange"],
                "lifetimeMilliseconds": 120000,
                "injectionRule": { "id": "openai-bearer-authorization.v1", "headerName": "authorization" } }
            ]
          } }
      ]
    }
  ]
}';
EXEC model.declare_capability_document @document=@resolve_credential;
EXEC model.declare_capability_document @document=@resolve_credential;
GO
-- ============================== VERIFICATION ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

-- 1. The document ledger holds the installed document digest for each capability.
SELECT '1_document_ledger' AS result_set, d.declared_id AS capability_id,
       JSON_VALUE(d.definition_json,'$.semantics.document_digest') AS document_digest
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='CAPABILITY_DOCUMENT'
  AND d.declared_id IN (N'store-credential',N'resolve-credential')
ORDER BY d.declared_id;

-- 2. The four contracts and their schema content addresses.
SELECT '2_contracts' AS result_set, c.contract_id,
       JSON_VALUE(d.definition_json,'$.semantics.schema_id') AS schema_id,
       JSON_VALUE(d.definition_json,'$.semantics.schema_digest') AS schema_digest
FROM model.contract c
JOIN model.contract_version cv ON cv.contract_pk=c.contract_pk
JOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=cv.semantic_object_definition_pk
WHERE d.estate_model_pk=@estate
  AND c.contract_id IN (N'store-credential-request.v1',N'store-credential-result.v1',
                        N'resolve-credential-request.v1',N'resolve-credential-result.v1')
ORDER BY c.contract_id;

-- 3. The scenario faces resolve to the declared request and result contracts.
SELECT '3_scenario_contracts' AS result_set, c.capability_id, s.scenario_id,
       ict.contract_id AS input_contract_id, oct.contract_id AS outcome_contract_id
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_input si ON si.scenario_version_pk=sv.scenario_version_pk
JOIN model.contract_version icv ON icv.contract_version_pk=si.input_contract_version_pk
JOIN model.contract ict ON ict.contract_pk=icv.contract_pk
JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk=sv.scenario_version_pk
JOIN model.contract_version ocv ON ocv.contract_version_pk=soc.contract_version_pk
JOIN model.contract oct ON oct.contract_pk=ocv.contract_pk
WHERE ec.estate_model_pk=@estate AND c.capability_id IN (N'store-credential',N'resolve-credential')
ORDER BY c.capability_id;

-- 4. The two declared Ports name the credential vault primitive and select its
--    store/apply operation. No configuration member is a secret.
SELECT '4_declared_ports' AS result_set, c.capability_id, s.scenario_id,
       pv.port_profile,
       JSON_VALUE(pd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
       JSON_VALUE(pd.definition_json,'$.semantics.configuration.operation') AS operation,
       JSON_QUERY(pd.definition_json,'$.semantics.configuration.allowedReferenceNames') AS allowed_reference_names,
       JSON_VALUE(pd.definition_json,'$.semantics.configuration.maximumSecretBytes') AS maximum_secret_bytes,
       CASE WHEN JSON_QUERY(pd.definition_json,'$.semantics.configuration.secret') IS NULL THEN 0 ELSE 1 END AS configuration_carries_secret,
       CASE WHEN JSON_QUERY(pd.definition_json,'$.semantics.configuration.referencePolicy') IS NULL THEN 0 ELSE 1 END AS declares_reference_policy
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
JOIN analysis.v_selected_semantic_definition pd ON pd.semantic_object_definition_pk=pv.semantic_object_definition_pk
WHERE ec.estate_model_pk=@estate AND c.capability_id IN (N'store-credential',N'resolve-credential')
ORDER BY c.capability_id;

-- 5. The declared scenario variants and their classification: the outcome-variant
--    registry the kernel compiles and the streamed display reads.
SELECT '5_scenario_variants' AS result_set, c.capability_id, s.scenario_id,
       ov.variant_id, ov.classification
FROM model.outcome_variant ov
JOIN model.scenario_version sv ON sv.scenario_version_pk=ov.scenario_version_pk
JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
JOIN model.capability_scenario cs ON cs.scenario_version_pk=sv.scenario_version_pk
JOIN model.capability_version cv ON cv.capability_version_pk=cs.capability_version_pk
JOIN model.capability c ON c.capability_pk=cv.capability_pk
JOIN model.estate_capability ec ON ec.estate_model_pk=@estate AND ec.capability_version_pk=cv.capability_version_pk
WHERE c.capability_id IN (N'store-credential',N'resolve-credential')
ORDER BY c.capability_id, ov.variant_id;

-- 6. The declared operation refusals ride the execution authority: the port
--    dispositions classified at mechanic/provider/physical altitude.
SELECT '6_operation_variants' AS result_set, c.capability_id,
       CONVERT(int,op.[key]) AS ordinal,
       JSON_VALUE(op.value,'$.operationId') AS operation_id,
       JSON_VALUE(op.value,'$.portId') AS port_id,
       JSON_QUERY(op.value,'$.outcomeVariants') AS outcome_variants
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.semantic_object_definition sd ON sd.semantic_object_definition_pk=eav.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sd.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS envelope) env
CROSS APPLY OPENJSON(env.envelope,'$.semantics.authority.operations') op
WHERE ec.estate_model_pk=@estate AND c.capability_id IN (N'store-credential',N'resolve-credential')
ORDER BY c.capability_id, CONVERT(int,op.[key]);

-- 7. The result contracts are closed and their whole vocabulary is the
--    application outcome and binding proof: no secret and no digest member.
SELECT '7_result_contract_members' AS result_set, c.contract_id, prop.[key] AS member,
       CASE WHEN prop.[key] IN (N'secret',N'secretDigest',N'secretHash',N'secretSha256') THEN 1 ELSE 0 END AS names_secret_material
FROM model.contract c
JOIN model.contract_version cv ON cv.contract_pk=c.contract_pk
JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS schema_document) sch
CROSS APPLY OPENJSON(sch.schema_document,'$.properties') prop
WHERE c.contract_id IN (N'store-credential-result.v1',N'resolve-credential-result.v1')
ORDER BY c.contract_id, member;

-- 8. The CLI display selects the canonical outcome only; no input mapping echoes
--    the secret.
SELECT '8_cli_display' AS result_set, c.capability_id,
       JSON_VALUE(JSON_QUERY(env.envelope,'$.semantics.cli'),'$.display.select') AS display_select,
       JSON_VALUE(JSON_QUERY(env.envelope,'$.semantics.cli'),'$.display.as') AS display_as,
       CASE WHEN JSON_QUERY(env.envelope,'$.semantics.cli.input') IS NULL THEN 0 ELSE 1 END AS declares_input_mapping
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.semantic_object_definition sd ON sd.semantic_object_definition_pk=ec.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sd.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS envelope) env
WHERE ec.estate_model_pk=@estate AND c.capability_id IN (N'store-credential',N'resolve-credential')
ORDER BY c.capability_id;

-- 9. The read path sees both capabilities.
SELECT '9_graph_source' AS result_set, g.capability_id, g.root_scenario_id
FROM analysis.v_capability_graph_source g
WHERE g.capability_id IN (N'store-credential',N'resolve-credential')
ORDER BY g.capability_id;

-- 10. The two declared definitions are distinct versions (the scaffold and the
--     declared interface); the document replays minted no duplicate definition.
SELECT '10_capability_versions' AS result_set, c.capability_id, COUNT(*) AS versions,
       COUNT(DISTINCT cv.definition_digest) AS distinct_definitions
FROM model.capability c
JOIN model.capability_version cv ON cv.capability_pk=c.capability_pk
WHERE c.capability_id IN (N'store-credential',N'resolve-credential')
GROUP BY c.capability_id
ORDER BY c.capability_id;

-- 11. Coverage: every reference name the installed credential authorities
--     declare is allowed by both vault capabilities and carries an apply policy
--     entry.
WITH installed_authority AS (
  SELECT DISTINCT JSON_VALUE(a.value,'$.referenceName') AS reference_name
  FROM analysis.v_selected_semantic_definition d
  CROSS APPLY OPENJSON(JSON_QUERY(d.definition_json,'$.semantics.configuration.credentialAuthorities')) a
  WHERE d.object_kind='PORT' AND d.estate_model_pk=@estate
),
vault_config AS (
  SELECT JSON_QUERY(d.definition_json,'$.semantics.configuration.allowedReferenceNames') AS allowed,
         JSON_QUERY(d.definition_json,'$.semantics.configuration.referencePolicy') AS policy
  FROM analysis.v_selected_semantic_definition d
  WHERE d.object_kind='PORT' AND d.estate_model_pk=@estate
    AND d.namespace_id=N'sidefx:capability:resolve-credential' AND d.declared_id=N'resolve-credential-port'
),
store_config AS (
  SELECT JSON_QUERY(d.definition_json,'$.semantics.configuration.allowedReferenceNames') AS allowed
  FROM analysis.v_selected_semantic_definition d
  WHERE d.object_kind='PORT' AND d.estate_model_pk=@estate
    AND d.namespace_id=N'sidefx:capability:store-credential' AND d.declared_id=N'store-credential-port'
)
SELECT '11_policy_coverage' AS result_set, ia.reference_name,
  (SELECT COUNT(*) FROM OPENJSON((SELECT allowed FROM store_config)) s
   WHERE s.value=ia.reference_name COLLATE Latin1_General_100_BIN2) AS allowed_in_store,
  (SELECT COUNT(*) FROM OPENJSON((SELECT allowed FROM vault_config)) s
   WHERE s.value=ia.reference_name COLLATE Latin1_General_100_BIN2) AS allowed_in_apply,
  (SELECT COUNT(*) FROM OPENJSON((SELECT policy FROM vault_config)) p
   WHERE JSON_VALUE(p.value,'$.referenceName')=ia.reference_name COLLATE Latin1_General_100_BIN2) AS apply_policy_entries
FROM installed_authority ia
WHERE ia.reference_name IS NOT NULL
ORDER BY ia.reference_name;
ROLLBACK TRANSACTION;
-- To install, replace the rollback above with a commit and run:
--   node scripts/run-migration.mjs sql/migrations/declare-credential-capabilities.sql
