-- The `"undefined"` absence-comparison defect, located in both places the
-- database stores it.
--
-- Self-contained: resolves the published model from source.current_model, so it
-- runs as-is in SSMS / Azure Data Studio against the `sidefx` database. Run the
-- whole file. Do not insert GO between blocks -- the DECLAREs are batch-scoped.
--
-- THE DEFECT
-- Each affected node is the right operand of a comparison whose left operand is
-- json-stringify(path(...)). When the path is absent, json-stringify yields the
-- string "null". It can never yield "undefined". So the comparison is false for
-- absent input, the []/false branch is unreachable, and the absent value is
-- carried forward -- where `length` throws OPERAND_NOT_MEASURABLE and `filter`
-- throws on null.
--
-- Correct literal value: "null"
--
-- THE TWO STORAGE LOCATIONS
--   1. NORMALIZED  model.transformation_expression_node.literal_content_pk
--                  -> source.content_object (the shared literal)
--   2. SOURCE DOC  source.content_object reached through
--                  source.source_appearance.entry_id =
--                  'semantic-transformation.authority.json'
--
-- planNode reads the SOURCE DOCUMENT, not the normalized nodes. Correcting only
-- the normalized rows changes nothing at invocation time. Both must agree.

SET NOCOUNT ON;

DECLARE @estate_model_pk bigint =
  (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);

DECLARE @snap bigint =
  (SELECT estate_snapshot_pk FROM source.estate_model WHERE estate_model_pk = @estate_model_pk);


---------------------------------------------------------------------------
-- 1. LOCATION ONE (normalized): the shared literal content object.
--    Observed: content_object_pk 5029, 11 bytes, 35 referencing expression
--    nodes, 0 source appearances. No "null" content object exists yet.
--
--    Why the bytes cannot simply be edited: content_object is content-addressed
--    with a unique index on content_digest (AK_source_content_object_054f8126d141).
--    Editing bytes without the digest breaks content addressing; editing both
--    rewrites the identity every reference resolves through. The fix is to
--    repoint literal_content_pk at a "null" content object.
---------------------------------------------------------------------------
SELECT co.content_object_pk,
       'sha256:' + LOWER(CONVERT(varchar(64), co.content_digest, 2)) AS content_digest,
       co.byte_length,
       CAST(CONVERT(varchar(max), co.content_bytes) AS nvarchar(max)) AS bytes,
       (SELECT COUNT_BIG(*) FROM model.transformation_expression_node n
         WHERE n.literal_content_pk = co.content_object_pk)          AS referencing_expression_nodes,
       (SELECT COUNT_BIG(*) FROM source.source_appearance a
         WHERE a.content_object_pk = co.content_object_pk)           AS referencing_appearances
FROM source.content_object co
WHERE CAST(CONVERT(varchar(max), co.content_bytes) AS nvarchar(max)) IN ('"undefined"', '"null"');


---------------------------------------------------------------------------
-- 2. LOCATION ONE, row by row: every normalized node to repoint.
--    These are the rows whose literal_content_pk must move to a "null" object.
---------------------------------------------------------------------------
SELECT n.expression_node_pk,
       ns.namespace_id,
       t.transformation_id,
       n.node_pointer,
       n.node_kind,
       n.literal_content_pk
FROM model.transformation_expression_node n
JOIN model.transformation_version tv ON tv.transformation_version_pk = n.transformation_version_pk
JOIN model.transformation t          ON t.transformation_pk = tv.transformation_pk
JOIN model.identity_namespace ns     ON ns.namespace_pk = t.namespace_pk
JOIN source.content_object co        ON co.content_object_pk = n.literal_content_pk
WHERE n.node_kind = 'LITERAL'
  AND CAST(CONVERT(varchar(max), co.content_bytes) AS nvarchar(max)) = '"undefined"'
ORDER BY ns.namespace_id, n.node_pointer;

-- Shape check: every one of these should be the right operand of a comparison.
SELECT CASE WHEN n.node_pointer LIKE '%/right/value'
            THEN 'right-operand-of-comparison' ELSE 'OTHER' END AS shape,
       COUNT(*) AS rows_affected
FROM model.transformation_expression_node n
JOIN source.content_object co ON co.content_object_pk = n.literal_content_pk
WHERE n.node_kind = 'LITERAL'
  AND CAST(CONVERT(varchar(max), co.content_bytes) AS nvarchar(max)) = '"undefined"'
GROUP BY CASE WHEN n.node_pointer LIKE '%/right/value'
              THEN 'right-operand-of-comparison' ELSE 'OTHER' END;


---------------------------------------------------------------------------
-- 3. LOCATION TWO (source documents): the bytes planNode actually reads.
--    One content_object per capability, each carrying N occurrences of the
--    literal. These are the documents whose bytes must change, which means a
--    new content_digest per document.
---------------------------------------------------------------------------
SELECT a.source_path,
       co.content_object_pk,
       'sha256:' + LOWER(CONVERT(varchar(64), co.content_digest, 2)) AS content_digest,
       co.byte_length,
       (LEN(CAST(CONVERT(varchar(max), co.content_bytes) AS nvarchar(max)))
        - LEN(REPLACE(CAST(CONVERT(varchar(max), co.content_bytes) AS nvarchar(max)), '"undefined"', '')))
         / LEN('"undefined"')                                        AS undefined_occurrences,
       (SELECT COUNT_BIG(*) FROM source.source_appearance x
         WHERE x.content_object_pk = co.content_object_pk)           AS appearances
FROM source.source_appearance a
JOIN source.content_object co ON co.content_object_pk = a.content_object_pk
WHERE a.estate_snapshot_pk = @snap
  AND a.entry_id = 'semantic-transformation.authority.json'
  AND CAST(CONVERT(varchar(max), co.content_bytes) AS nvarchar(max)) LIKE '%"undefined"%'
GROUP BY a.source_path, co.content_object_pk, co.content_digest, co.byte_length,
         CAST(CONVERT(varchar(max), co.content_bytes) AS nvarchar(max))
ORDER BY undefined_occurrences DESC;


---------------------------------------------------------------------------
-- 4. RECONCILIATION. The two locations must account for the same defects.
--    Observed: 35 normalized rows; 12+8+8+4+3 = 35 document occurrences.
---------------------------------------------------------------------------
SELECT
  (SELECT COUNT_BIG(*)
     FROM model.transformation_expression_node n
     JOIN source.content_object co ON co.content_object_pk = n.literal_content_pk
    WHERE n.node_kind = 'LITERAL'
      AND CAST(CONVERT(varchar(max), co.content_bytes) AS nvarchar(max)) = '"undefined"')
  AS normalized_node_rows,
  (SELECT SUM((LEN(CAST(CONVERT(varchar(max), c2.content_bytes) AS nvarchar(max)))
             - LEN(REPLACE(CAST(CONVERT(varchar(max), c2.content_bytes) AS nvarchar(max)), '"undefined"', '')))
             / LEN('"undefined"'))
     FROM (SELECT DISTINCT a2.content_object_pk
             FROM source.source_appearance a2
            WHERE a2.estate_snapshot_pk = @snap
              AND a2.entry_id = 'semantic-transformation.authority.json') d
     JOIN source.content_object c2 ON c2.content_object_pk = d.content_object_pk)
  AS source_document_occurrences;


---------------------------------------------------------------------------
-- WHAT A FIX HAS TO DO, given the above
--
--   Location 2 (authoritative for invocation):
--     For each of the 5 documents, replace every '"undefined"' with '"null"',
--     which changes byte_length and content_digest. Because content_object is
--     content-addressed and shared, this is a new content object per document
--     plus a repoint of source_appearance.content_object_pk (2 appearances
--     each) -- the same mechanic as apply-contract-fix.sql.
--
--   Location 1 (keeps the normalized model honest):
--     Insert one content object holding '"null"' (11 -> 6 bytes) and repoint
--     the 35 model.transformation_expression_node.literal_content_pk rows to it.
--     Leave content_object 5029 in place; it becomes unreferenced.
--
--   Both locations sit behind AFTER INSERT,UPDATE,DELETE guards that THROW
--   51003 'IMMUTABLE_INSPECTION_DATA' on UPDATE:
--     source.guard_content_object, source.guard_source_appearance,
--     and the model-side guard on transformation_expression_node.
--   Check that third guard before writing anything.
---------------------------------------------------------------------------
SELECT OBJECT_SCHEMA_NAME(t.parent_id) + '.' + OBJECT_NAME(t.parent_id) AS guarded_table,
       t.name AS trigger_name, t.is_disabled
FROM sys.triggers t
WHERE t.parent_id IN (OBJECT_ID('source.content_object'),
                      OBJECT_ID('source.source_appearance'),
                      OBJECT_ID('model.transformation_expression_node'))
ORDER BY guarded_table;
