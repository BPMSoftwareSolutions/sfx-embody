-- select-one-definition-per-declared-id.sql
--
-- A declared id can carry several definitions: a later definition supersedes an
-- earlier one rather than overwriting it. analysis.v_selected_semantic_definition
-- currently returns every one of them, so consumers read the union of superseded
-- and current declarations (the "_REPEATED" / "DEFINITIONS_DISAGREE" findings).
--
-- This selects the current definition per declared id: the highest
-- semantic_object_definition_pk for each semantic_object in the selected model.
-- Superseded definitions are not removed; they simply stop being the one read.
--
-- Default: ROLLBACK after verification. Change the final ROLLBACK to COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- ============================== BEFORE ==============================
SELECT 'BEFORE_definitions' AS result_set, declared_id, object_kind, COUNT(*) AS defs
FROM analysis.v_selected_semantic_definition
WHERE declared_id IN (N'resolve-equity-market-price-evidence.v1', N'resolve-equity-market-price-evidence-port', N'transform-resolve-equity-market-price-evidence')
GROUP BY declared_id, object_kind;
GO
CREATE OR ALTER VIEW analysis.v_selected_semantic_definition AS
SELECT ed.estate_model_pk,d.semantic_object_definition_pk,d.object_kind,
       s.namespace_pk,n.namespace_id,s.declared_id,d.definition_digest,
       CASE WHEN ISJSON(decoded.source_text)=1 THEN decoded.source_text END AS definition_json
FROM source.current_model cm
JOIN model.estate_definition ed ON ed.estate_model_pk=cm.estate_model_pk
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
JOIN model.semantic_object s ON s.semantic_object_pk=d.semantic_object_pk
JOIN model.identity_namespace n ON n.namespace_pk=s.namespace_pk
JOIN source.content_object c ON c.content_object_pk=d.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),c.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) COLLATE Latin1_General_100_BIN2 AS source_text) decoded
WHERE d.semantic_object_definition_pk=(
    SELECT MAX(d2.semantic_object_definition_pk)
    FROM model.estate_definition ed2
    JOIN model.semantic_object_definition d2 ON d2.semantic_object_definition_pk=ed2.semantic_object_definition_pk
    WHERE ed2.estate_model_pk=ed.estate_model_pk AND d2.semantic_object_pk=d.semantic_object_pk);
GO
-- ============================== AFTER ==============================
SELECT 'AFTER_definitions' AS result_set, declared_id, object_kind, COUNT(*) AS defs
FROM analysis.v_selected_semantic_definition
WHERE declared_id IN (N'resolve-equity-market-price-evidence.v1', N'resolve-equity-market-price-evidence-port', N'transform-resolve-equity-market-price-evidence')
GROUP BY declared_id, object_kind;
SELECT 'AFTER_selected_authority' AS result_set, declared_id, semantic_object_definition_pk AS sod
FROM analysis.v_selected_semantic_definition
WHERE declared_id=N'resolve-equity-market-price-evidence.v1';
SELECT 'AFTER_resolver_implementations' AS result_set, COUNT(*) AS n
FROM analysis.v_declared_platform_implementation;

ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
