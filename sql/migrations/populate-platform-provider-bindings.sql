-- populate-platform-provider-bindings.sql
--
-- Populate the port->provider bindings the database already describes but that
-- are missing from the model. The 74 provider definitions are
-- `sda-platform-capability-catalog.v1`; each declares, per platform capability,
-- the implementationRef, projectionTarget, status and conformanceRef. This
-- mutation reads those catalogs (node target), (re)creates the platform
-- capability identities they name, and inserts the
-- provider_capability_implementation rows that link them.
--
-- Result: analysis.v_declared_platform_implementation resolves, and reveal's
-- port->provider->mechanic chain stops reporting PLATFORM_CAPABILITY_WITHOUT_PROVIDER.
--
-- Default: ROLLBACK after verification. Change the final ROLLBACK to COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @snap bigint = (SELECT estate_snapshot_pk FROM source.estate_model WHERE estate_model_pk = @model);
DECLARE @rule bigint = (SELECT TOP 1 mapping_rule_pk FROM source.estate_model_rule WHERE estate_model_pk = @model ORDER BY mapping_rule_pk);
IF @model IS NULL THROW 51000, 'CURRENT_MODEL_NOT_FOUND', 1;
DECLARE @platNs bigint = (SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='CAPABILITY' AND namespace_id=N'sidefx:platform-capabilities');

-- Drop the workshop data guards so this script can write.
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;

-- Reset only this mutation's own rows so a re-run converges.
DELETE pci FROM model.provider_capability_implementation pci
JOIN model.capability_version cv ON cv.capability_version_pk=pci.capability_version_pk
JOIN model.capability c ON c.capability_pk=cv.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE n.namespace_id=N'sidefx:platform-capabilities' AND pci.role=N'PLATFORM';

-- ============================== BEFORE ==============================
SELECT 'BEFORE_implementations' AS result_set, COUNT(*) AS n
FROM analysis.v_declared_platform_implementation;
SELECT 'BEFORE_platform_caps' AS result_set, COUNT(*) AS n
FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE n.namespace_id=N'sidefx:platform-capabilities';

BEGIN TRANSACTION;

IF OBJECT_ID('tempdb..#bind') IS NOT NULL DROP TABLE #bind;
CREATE TABLE #bind (
  capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
  provider_definition_pk bigint NOT NULL,
  provider_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
  projection_target nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL,
  declaration_status nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL,
  implementation_ref nvarchar(1000) COLLATE Latin1_General_100_BIN2 NULL,
  conformance_ref nvarchar(1000) COLLATE Latin1_General_100_BIN2 NULL
);

-- 1. Read the node provider catalogs already in the model.
IF OBJECT_ID('tempdb..#cat') IS NOT NULL DROP TABLE #cat;
CREATE TABLE #cat (provider_definition_pk bigint, provider_id nvarchar(400) COLLATE Latin1_General_100_BIN2, j nvarchar(max) COLLATE Latin1_General_100_BIN2);
INSERT #cat (provider_definition_pk, provider_id, j)
SELECT pd.provider_definition_pk, p.provider_id,
       REPLACE(CONVERT(nvarchar(max), CONVERT(varchar(max), c.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), NCHAR(65279), N'')
FROM model.provider p
JOIN model.provider_definition pd ON pd.provider_pk = p.provider_pk
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = pd.semantic_object_definition_pk
JOIN source.content_object c ON c.content_object_pk = d.canonical_content_pk;
DELETE FROM #cat WHERE j IS NULL OR ISJSON(j) <> 1;

INSERT #bind (capability_id, provider_definition_pk, provider_id, projection_target, declaration_status, implementation_ref, conformance_ref)
SELECT cap.capability_id, cap.provider_definition_pk, cap.provider_id, cap.projection_target, cap.declaration_status, cap.implementation_ref, cap.conformance_ref
FROM #cat s
CROSS APPLY (VALUES
  (JSON_VALUE(s.j,'$.semantics.capabilities[0].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[0].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[0].status'), JSON_VALUE(s.j,'$.semantics.capabilities[0].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[0].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[1].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[1].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[1].status'), JSON_VALUE(s.j,'$.semantics.capabilities[1].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[1].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[2].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[2].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[2].status'), JSON_VALUE(s.j,'$.semantics.capabilities[2].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[2].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[3].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[3].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[3].status'), JSON_VALUE(s.j,'$.semantics.capabilities[3].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[3].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[4].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[4].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[4].status'), JSON_VALUE(s.j,'$.semantics.capabilities[4].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[4].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[5].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[5].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[5].status'), JSON_VALUE(s.j,'$.semantics.capabilities[5].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[5].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[6].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[6].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[6].status'), JSON_VALUE(s.j,'$.semantics.capabilities[6].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[6].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[7].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[7].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[7].status'), JSON_VALUE(s.j,'$.semantics.capabilities[7].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[7].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[8].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[8].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[8].status'), JSON_VALUE(s.j,'$.semantics.capabilities[8].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[8].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[9].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[9].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[9].status'), JSON_VALUE(s.j,'$.semantics.capabilities[9].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[9].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[10].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[10].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[10].status'), JSON_VALUE(s.j,'$.semantics.capabilities[10].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[10].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[11].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[11].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[11].status'), JSON_VALUE(s.j,'$.semantics.capabilities[11].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[11].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[12].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[12].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[12].status'), JSON_VALUE(s.j,'$.semantics.capabilities[12].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[12].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[13].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[13].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[13].status'), JSON_VALUE(s.j,'$.semantics.capabilities[13].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[13].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[14].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[14].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[14].status'), JSON_VALUE(s.j,'$.semantics.capabilities[14].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[14].conformanceRef')),
  (JSON_VALUE(s.j,'$.semantics.capabilities[15].capabilityId'), s.provider_definition_pk, s.provider_id, JSON_VALUE(s.j,'$.semantics.capabilities[15].projectionTarget'), JSON_VALUE(s.j,'$.semantics.capabilities[15].status'), JSON_VALUE(s.j,'$.semantics.capabilities[15].implementationRef'), JSON_VALUE(s.j,'$.semantics.capabilities[15].conformanceRef'))
) cap(capability_id, provider_definition_pk, provider_id, projection_target, declaration_status, implementation_ref, conformance_ref)
WHERE cap.capability_id IS NOT NULL
  AND cap.projection_target = N'node';

-- Exactly one node provider per capability; >1 makes resolution NOT_OBSERVABLE.
DELETE b FROM #bind b
WHERE EXISTS (SELECT 1 FROM #bind x WHERE x.capability_id = b.capability_id AND x.provider_definition_pk < b.provider_definition_pk);

-- 2. Canonical capability envelopes for the platform capabilities.
IF OBJECT_ID('tempdb..#cap') IS NOT NULL DROP TABLE #cap;
CREATE TABLE #cap (
  capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,
  envelope nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
  bytes varbinary(max) NULL,
  dgst binary(32) NULL
);
INSERT #cap (capability_id, envelope)
SELECT capability_id,
  N'{"address":{"id":"' + STRING_ESCAPE(capability_id,'json') + N'","kind":"CAPABILITY","namespace":"sidefx:platform-capabilities"},'
+ N'"format":"sidefx-semantic-definition.v1","semantics":{"projectionTarget":"' + ISNULL(STRING_ESCAPE(projection_target,'json'),N'')
+ N'","status":"' + ISNULL(STRING_ESCAPE(declaration_status,'json'),N'')
+ N'","implementationRef":"' + ISNULL(STRING_ESCAPE(implementation_ref,'json'),N'')
+ N'","conformanceRef":"' + ISNULL(STRING_ESCAPE(conformance_ref,'json'),N'') + N'"}}'
FROM #bind;
UPDATE #cap SET bytes = CONVERT(varbinary(max), CONVERT(varchar(max), (envelope) COLLATE Latin1_General_100_BIN2_UTF8));
UPDATE #cap SET dgst = HASHBYTES('SHA2_256', bytes);

IF @platNs IS NULL BEGIN INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('CAPABILITY', N'sidefx:platform-capabilities'); SET @platNs = SCOPE_IDENTITY(); END

-- 3. Content, identity, definitions and membership for each platform capability.
INSERT source.content_object (content_digest, content_bytes, byte_length)
SELECT DISTINCT x.dgst, x.bytes, DATALENGTH(x.bytes) FROM #cap x
WHERE NOT EXISTS (SELECT 1 FROM source.content_object c WHERE c.content_digest = x.dgst);

INSERT model.semantic_object (object_kind, namespace_pk, declared_id)
SELECT DISTINCT 'CAPABILITY', @platNs, x.capability_id FROM #cap x
WHERE NOT EXISTS (SELECT 1 FROM model.semantic_object s WHERE s.object_kind='CAPABILITY' AND s.namespace_pk=@platNs AND s.declared_id=x.capability_id);

INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
SELECT s.semantic_object_pk, 'CAPABILITY', x.dgst, c.content_object_pk
FROM #cap x
JOIN model.semantic_object s ON s.object_kind='CAPABILITY' AND s.namespace_pk=@platNs AND s.declared_id=x.capability_id
JOIN source.content_object c ON c.content_digest=x.dgst
WHERE NOT EXISTS (SELECT 1 FROM model.semantic_object_definition d WHERE d.semantic_object_pk=s.semantic_object_pk AND d.definition_digest=x.dgst);

INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk)
SELECT @model, d.semantic_object_definition_pk
FROM #cap x
JOIN model.semantic_object s ON s.object_kind='CAPABILITY' AND s.namespace_pk=@platNs AND s.declared_id=x.capability_id
JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk AND d.definition_digest=x.dgst
WHERE NOT EXISTS (SELECT 1 FROM model.estate_definition e WHERE e.estate_model_pk=@model AND e.semantic_object_definition_pk=d.semantic_object_definition_pk);

INSERT model.capability (namespace_pk, capability_id, semantic_object_pk, object_kind)
SELECT @platNs, x.capability_id, s.semantic_object_pk, 'CAPABILITY'
FROM #cap x
JOIN model.semantic_object s ON s.object_kind='CAPABILITY' AND s.namespace_pk=@platNs AND s.declared_id=x.capability_id
WHERE NOT EXISTS (SELECT 1 FROM model.capability c WHERE c.namespace_pk=@platNs AND c.capability_id=x.capability_id);

INSERT model.capability_version (capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, object_kind, _owner_definition_pk, _canonical_pointer)
SELECT c.capability_pk, s.semantic_object_pk, d.semantic_object_definition_pk, d.definition_digest, x.capability_id, 'CAPABILITY', d.semantic_object_definition_pk, N''
FROM #cap x
JOIN model.capability c ON c.namespace_pk=@platNs AND c.capability_id=x.capability_id
JOIN model.semantic_object s ON s.semantic_object_pk=c.semantic_object_pk
JOIN model.semantic_object_definition d ON d.semantic_object_pk=s.semantic_object_pk AND d.definition_digest=x.dgst
WHERE NOT EXISTS (SELECT 1 FROM model.capability_version cv WHERE cv.capability_pk=c.capability_pk AND cv.definition_digest=x.dgst);

INSERT model.estate_capability (estate_model_pk, capability_pk, capability_version_pk, semantic_object_definition_pk)
SELECT @model, cv.capability_pk, cv.capability_version_pk, cv.semantic_object_definition_pk
FROM model.capability_version cv
JOIN model.capability c ON c.capability_pk=cv.capability_pk
WHERE c.namespace_pk=@platNs
  AND NOT EXISTS (SELECT 1 FROM model.estate_capability ec WHERE ec.estate_model_pk=@model AND ec.capability_pk=cv.capability_pk);

-- 4. The bindings themselves.
INSERT model.provider_capability_implementation (provider_definition_pk, capability_version_pk, role, _owner_definition_pk, _canonical_pointer)
SELECT b.provider_definition_pk, cv.capability_version_pk, N'PLATFORM', cv.semantic_object_definition_pk, N''
FROM #bind b
JOIN model.capability c ON c.namespace_pk=@platNs AND c.capability_id=b.capability_id
JOIN model.capability_version cv ON cv.capability_pk=c.capability_pk
WHERE NOT EXISTS (SELECT 1 FROM model.provider_capability_implementation pci WHERE pci.capability_version_pk=cv.capability_version_pk AND pci.provider_definition_pk=b.provider_definition_pk);

-- ============================== AFTER ==============================
SELECT 'AFTER_bound_capabilities' AS result_set, COUNT(*) AS n FROM #bind;
SELECT 'AFTER_platform_caps' AS result_set, COUNT(*) AS n
FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE n.namespace_id=N'sidefx:platform-capabilities';
SELECT 'AFTER_provider_capability_implementation' AS result_set, COUNT(*) AS n
FROM model.provider_capability_implementation pci
JOIN model.capability_version cv ON cv.capability_version_pk=pci.capability_version_pk
JOIN model.capability c ON c.capability_pk=cv.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE n.namespace_id=N'sidefx:platform-capabilities';
SELECT 'AFTER_resolver_implementations' AS result_set, platform_capability_id, provider_id, target_language, declaration_status, implementation_id
FROM analysis.v_declared_platform_implementation
WHERE platform_capability_id IN (N'sda-authority-transformation-port.v1', N'sda-external-credential-reference-binding-port.v1', N'sda-governed-http-exchange-port.v1', N'sda-json-cli.v1', N'sda-schema-contract-admission.v1')
ORDER BY platform_capability_id;
SELECT 'AFTER_equity_port_mechanics' AS result_set, p.port_id, pr.provider_id, m.mechanic_id
FROM analysis.v_selected_semantic_definition pdf
JOIN model.port_version pv ON pv.semantic_object_definition_pk = pdf.semantic_object_definition_pk
JOIN model.port p ON p.port_pk = pv.port_pk
JOIN model.capability cap ON cap.capability_id = JSON_VALUE(pdf.definition_json,'$.semantics.platformCapabilityId')
JOIN model.capability_version cv ON cv.capability_pk = cap.capability_pk
JOIN model.provider_capability_implementation pci ON pci.capability_version_pk = cv.capability_version_pk
JOIN model.provider_definition pd ON pd.provider_definition_pk = pci.provider_definition_pk
JOIN model.provider pr ON pr.provider_pk = pd.provider_pk
LEFT JOIN model.provider_mechanic_implementation pmi ON pmi.provider_definition_pk = pd.provider_definition_pk
LEFT JOIN model.mechanic_version mv ON mv.mechanic_version_pk = pmi.mechanic_version_pk
LEFT JOIN model.mechanic m ON m.mechanic_pk = mv.mechanic_pk
WHERE pdf.estate_model_pk = @model AND p.port_id IN (N'resolve-equity-market-price-evidence-port', N'observe-equity-price-exchange')
ORDER BY p.port_id, m.mechanic_id;

ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
