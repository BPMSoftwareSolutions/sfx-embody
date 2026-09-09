-- Correct the absence-comparison literal `"undefined"` -> `"null"` in all three
-- places the database stores it.
--
-- Self-contained: resolves the published model from source.current_model, so it
-- runs as-is in SSMS / Azure Data Studio. Run the whole file. Do not insert GO
-- between blocks -- the DECLAREs are batch-scoped.
--
-- ENDS IN ROLLBACK. Read the verification output, then change the last line to
-- COMMIT.
--
-- ====================================================================
-- THE DEFECT
-- ====================================================================
-- Each affected node is the right operand of a comparison whose left operand is
-- json-stringify(path(...)). An absent path yields the string "null", never
-- "undefined". So the comparison is false for absent input, the []/false branch
-- is unreachable, and the absent value is carried forward -- where `length`
-- throws OPERAND_NOT_MEASURABLE and `filter` throws on null.
--
-- 35 occurrences across 5 capabilities:
--   generate-executable-capability-scaffold  12
--   provision-capability-artifacts            8
--   admit-registry-asset                      8
--   resolve-capability-proof-obligations      4
--   resolve-estate-dependency-closure         3
--
-- ====================================================================
-- THE THREE LOCATIONS
-- ====================================================================
-- 1. source.content_object.content_bytes, reached through
--    source.source_appearance.entry_id = 'semantic-transformation.authority.json'
--    5 documents. THIS IS THE ONE THAT CHANGES BEHAVIOUR -- planNode reads
--    these bytes. Rewritten, so each becomes a new content object; only the
--    CURRENT snapshot's appearance is repointed. Snapshot 1 keeps its original
--    bytes so prior generations still read as captured.
--
-- 2. model.transformation_expression_node.literal_content_pk
--    35 rows pointing at content_object 5029 ('"undefined"', 11 bytes),
--    repointed at a new object holding '"null"' (6 bytes). All 35 are the right
--    operand of a comparison; nothing outside this table references 5029.
--    Object 5029 is left in place and becomes unreferenced (DELETE is exactly
--    what the guards exist to prevent).
--
-- 3. model.semantic_object_definition.canonical_content_pk  (5 rows)
--    plus model.semantic_object_definition.definition_digest
--    plus model.transformation_version.definition_digest
--    The canonical definition JSON embeds the same literal. definition_digest
--    is HASHBYTES('SHA2_256', canonical_content_bytes) -- verified derived, and
--    identical on both tables -- so it is recomputed here rather than asserted.
--
-- ====================================================================
-- WHAT THIS BYPASSES, AND WHAT IT LEAVES BROKEN
-- ====================================================================
-- Five AFTER INSERT,UPDATE,DELETE guards THROW 51003
-- 'IMMUTABLE_INSPECTION_DATA' when `deleted` is populated, which an UPDATE
-- always populates. They are disabled and re-enabled inside this transaction.
-- Requires owner ALTER; sidefx_importer is INSERT-only by grant.
--   source.guard_content_object
--   source.guard_source_appearance
--   model.guard_transformation_expression_node
--   model.guard_semantic_object_definition
--   model.guard_transformation_version
--
-- KNOWN RESIDUE -- not fixable in SQL:
--   source.source_appearance.capsule_digest still names the pre-fix capsule for
--   the affected entries. A capsule digest covers packed capsule entries and the
--   packing format is not in the database, so it cannot be recomputed here.
--   Nothing in SQL validates or recomputes it (`capsule_digest` appears twice in
--   the whole migration set: a column declaration and one selector), and
--   capability-embodiment.sql uses it only as a grouping key -- so this breaks
--   nothing at read time. It stays wrong until a capsule is repacked.
--
-- ALSO NOT DONE HERE:
--   source.validate_model is not run and cannot be -- it requires
--   publication_state = 'BUILDING' and this model is PUBLISHED.
--   Re-running capture/derive reproduces the ORIGINAL bytes and will disagree
--   with the current-snapshot rows.
--   Preparations in runtime.capability_preparation planned from pre-fix bytes
--   are stale for the 5 affected capabilities.
-- ====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @estate_model_pk bigint =
  (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @snap bigint =
  (SELECT estate_snapshot_pk FROM source.estate_model WHERE estate_model_pk = @estate_model_pk);

BEGIN TRANSACTION;

-- ---------------------------------------------------------------- preconditions
IF NOT EXISTS (SELECT 1 FROM source.content_object
               WHERE content_object_pk = 5029
                 AND CONVERT(varchar(max), content_bytes) = '"undefined"')
  THROW 60100, 'LITERAL_5029_NOT_AT_EXPECTED_VALUE', 1;

IF (SELECT COUNT(*) FROM model.transformation_expression_node
     WHERE literal_content_pk = 5029) <> 35
  THROW 60101, 'EXPRESSION_NODE_COUNT_UNEXPECTED', 1;

-- ---------------------------------------------------------------- disable guards
ALTER TABLE source.content_object                 DISABLE TRIGGER guard_content_object;
ALTER TABLE source.source_appearance              DISABLE TRIGGER guard_source_appearance;
ALTER TABLE model.transformation_expression_node  DISABLE TRIGGER guard_transformation_expression_node;
ALTER TABLE model.semantic_object_definition      DISABLE TRIGGER guard_semantic_object_definition;
ALTER TABLE model.transformation_version          DISABLE TRIGGER guard_transformation_version;


-- ================================================================
-- LOCATION 1: semantic-transformation.authority.json documents
-- ================================================================
SELECT co.content_object_pk AS old_pk,
       CONVERT(varbinary(max),
         REPLACE(CONVERT(varchar(max), co.content_bytes), '"undefined"', '"null"')) AS new_bytes
INTO #docs
FROM source.content_object co
WHERE co.content_object_pk IN (
        SELECT DISTINCT a.content_object_pk
        FROM source.source_appearance a
        WHERE a.estate_snapshot_pk = @snap
          AND a.entry_id = 'semantic-transformation.authority.json')
  AND CONVERT(varchar(max), co.content_bytes) LIKE '%"undefined"%';

IF (SELECT COUNT(*) FROM #docs) <> 5 THROW 60102, 'DOCUMENT_COUNT_UNEXPECTED', 1;

ALTER TABLE #docs ADD new_digest binary(32) NULL, new_length bigint NULL;
UPDATE #docs SET new_digest = HASHBYTES('SHA2_256', new_bytes),
                 new_length = DATALENGTH(new_bytes);

INSERT source.content_object (content_digest, content_bytes, byte_length)
SELECT d.new_digest, d.new_bytes, d.new_length
FROM #docs d
WHERE NOT EXISTS (SELECT 1 FROM source.content_object c
                   WHERE c.content_digest = d.new_digest);

UPDATE a
   SET a.content_object_pk = c.content_object_pk
FROM source.source_appearance a
JOIN #docs d ON d.old_pk = a.content_object_pk
JOIN source.content_object c ON c.content_digest = d.new_digest
WHERE a.estate_snapshot_pk = @snap
  AND a.entry_id = 'semantic-transformation.authority.json';

IF @@ROWCOUNT <> 5 THROW 60103, 'DOCUMENT_APPEARANCE_REPOINT_COUNT_UNEXPECTED', 1;


-- ================================================================
-- LOCATION 2: the shared literal in the normalized expression tree
-- ================================================================
DECLARE @null_bytes varbinary(max) = CONVERT(varbinary(max), '"null"');
DECLARE @null_digest binary(32) = HASHBYTES('SHA2_256', @null_bytes);

INSERT source.content_object (content_digest, content_bytes, byte_length)
SELECT @null_digest, @null_bytes, DATALENGTH(@null_bytes)
WHERE NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @null_digest);

DECLARE @null_pk bigint =
  (SELECT content_object_pk FROM source.content_object WHERE content_digest = @null_digest);

UPDATE model.transformation_expression_node
   SET literal_content_pk = @null_pk
 WHERE literal_content_pk = 5029;

IF @@ROWCOUNT <> 35 THROW 60104, 'EXPRESSION_NODE_REPOINT_COUNT_UNEXPECTED', 1;


-- ================================================================
-- LOCATION 3: canonical definition JSON and the digests derived from it
-- ================================================================
SELECT d.semantic_object_definition_pk AS def_pk,
       d.canonical_content_pk          AS old_pk,
       d.definition_digest             AS old_digest,
       CONVERT(varbinary(max),
         REPLACE(CONVERT(varchar(max), co.content_bytes), '"undefined"', '"null"')) AS new_bytes
INTO #defs
FROM model.semantic_object_definition d
JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
WHERE CONVERT(varchar(max), co.content_bytes) LIKE '%"undefined"%';

IF (SELECT COUNT(*) FROM #defs) <> 5 THROW 60105, 'DEFINITION_COUNT_UNEXPECTED', 1;

ALTER TABLE #defs ADD new_digest binary(32) NULL, new_length bigint NULL;
UPDATE #defs SET new_digest = HASHBYTES('SHA2_256', new_bytes),
                 new_length = DATALENGTH(new_bytes);

-- Every stored definition_digest must currently be the hash of its canonical
-- content; if that ever stops holding, recomputing it here would be wrong.
IF EXISTS (SELECT 1 FROM #defs f
           JOIN source.content_object co ON co.content_object_pk = f.old_pk
           WHERE f.old_digest <> HASHBYTES('SHA2_256', co.content_bytes))
  THROW 60106, 'DEFINITION_DIGEST_NOT_DERIVED_FROM_CANONICAL_CONTENT', 1;

INSERT source.content_object (content_digest, content_bytes, byte_length)
SELECT f.new_digest, f.new_bytes, f.new_length
FROM #defs f
WHERE NOT EXISTS (SELECT 1 FROM source.content_object c
                   WHERE c.content_digest = f.new_digest);

-- model.transformation_version references the definition on a COMPOSITE key
-- (semantic_object_definition_pk, semantic_object_pk, object_kind,
--  definition_digest), so the parent digest cannot move while the FK is
-- enforced and the child cannot move first. Suspend it across both updates and
-- re-validate with WITH CHECK, which re-verifies every existing row.
--
-- Only transformation_version carries definition_digest for these 5
-- definitions. model.estate_definition (15 rows) and source.source_lineage
-- (24,614 rows) reference the definition pk only, not the digest, so they are
-- unaffected by this change.
ALTER TABLE model.transformation_version
  NOCHECK CONSTRAINT FK_model_transformation_version_38605ba41d7d;

UPDATE d
   SET d.canonical_content_pk = c.content_object_pk,
       d.definition_digest    = f.new_digest
FROM model.semantic_object_definition d
JOIN #defs f ON f.def_pk = d.semantic_object_definition_pk
JOIN source.content_object c ON c.content_digest = f.new_digest;

IF @@ROWCOUNT <> 5 THROW 60107, 'DEFINITION_UPDATE_COUNT_UNEXPECTED', 1;

-- transformation_version carries its own copy of the same digest.
UPDATE tv
   SET tv.definition_digest = f.new_digest
FROM model.transformation_version tv
JOIN #defs f ON f.def_pk = tv.semantic_object_definition_pk;

IF @@ROWCOUNT <> 5 THROW 60108, 'TRANSFORMATION_VERSION_DIGEST_COUNT_UNEXPECTED', 1;

-- Re-validates every row, not just the ones changed. Fails here if the parent
-- and child digests disagree anywhere.
ALTER TABLE model.transformation_version
  WITH CHECK CHECK CONSTRAINT FK_model_transformation_version_38605ba41d7d;

IF EXISTS (SELECT 1 FROM sys.foreign_keys
           WHERE name = 'FK_model_transformation_version_38605ba41d7d'
             AND (is_disabled = 1 OR is_not_trusted = 1))
  THROW 60109, 'TRANSFORMATION_VERSION_FK_NOT_TRUSTED_AFTER_RECHECK', 1;


-- ---------------------------------------------------------------- re-enable guards
ALTER TABLE source.content_object                 ENABLE TRIGGER guard_content_object;
ALTER TABLE source.source_appearance              ENABLE TRIGGER guard_source_appearance;
ALTER TABLE model.transformation_expression_node  ENABLE TRIGGER guard_transformation_expression_node;
ALTER TABLE model.semantic_object_definition      ENABLE TRIGGER guard_semantic_object_definition;
ALTER TABLE model.transformation_version          ENABLE TRIGGER guard_transformation_version;


-- ================================================================
-- VERIFICATION -- all three locations, all must be 0
-- ================================================================
SELECT
  (SELECT COUNT_BIG(*) FROM source.source_appearance a
     JOIN source.content_object co ON co.content_object_pk = a.content_object_pk
    WHERE a.estate_snapshot_pk = @snap
      AND a.entry_id = 'semantic-transformation.authority.json'
      AND CONVERT(varchar(max), co.content_bytes) LIKE '%"undefined"%')
    AS loc1_documents_expect_0,
  (SELECT COUNT_BIG(*) FROM model.transformation_expression_node n
     JOIN source.content_object co ON co.content_object_pk = n.literal_content_pk
    WHERE CONVERT(varchar(max), co.content_bytes) = '"undefined"')
    AS loc2_expression_nodes_expect_0,
  (SELECT COUNT_BIG(*) FROM model.semantic_object_definition d
     JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
    WHERE CONVERT(varchar(max), co.content_bytes) LIKE '%"undefined"%')
    AS loc3_definitions_expect_0;

-- Every definition_digest still equals the hash of its canonical content,
-- and transformation_version still agrees with it.
SELECT
  (SELECT COUNT_BIG(*) FROM model.semantic_object_definition d
     JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
    WHERE d.definition_digest <> HASHBYTES('SHA2_256', co.content_bytes))
    AS definitions_with_stale_digest_expect_0,
  (SELECT COUNT_BIG(*) FROM model.transformation_version tv
     JOIN model.semantic_object_definition d
       ON d.semantic_object_definition_pk = tv.semantic_object_definition_pk
    WHERE tv.definition_digest <> d.definition_digest)
    AS versions_disagreeing_with_definition_expect_0;

-- Snapshot 1 untouched: still 5 documents carrying the old literal.
SELECT COUNT_BIG(*) AS snapshot1_documents_still_original_expect_5
FROM source.source_appearance a
JOIN source.content_object co ON co.content_object_pk = a.content_object_pk
WHERE a.estate_snapshot_pk = 1
  AND a.entry_id = 'semantic-transformation.authority.json'
  AND CONVERT(varchar(max), co.content_bytes) LIKE '%"undefined"%';

-- Rewritten documents, digests recomputed from stored bytes.
-- byte delta must be exactly 5 * occurrences ("undefined" -> "null" loses 5).
SELECT a.source_path, c.content_object_pk, c.byte_length,
       'sha256:' + LOWER(CONVERT(varchar(64), c.content_digest, 2)) AS content_digest,
       CASE WHEN HASHBYTES('SHA2_256', c.content_bytes) = c.content_digest
            THEN 'DIGEST_OK' ELSE 'DIGEST_MISMATCH' END AS digest_check
FROM source.source_appearance a
JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
WHERE a.estate_snapshot_pk = @snap
  AND a.entry_id = 'semantic-transformation.authority.json'
  AND c.content_digest IN (SELECT new_digest FROM #docs)
ORDER BY a.source_path;

-- KNOWN RESIDUE: entries whose capsule_digest no longer covers their bytes.
SELECT a.source_path,
       'sha256:' + LOWER(CONVERT(varchar(64), a.capsule_digest, 2)) AS stale_capsule_digest
FROM source.source_appearance a
JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
WHERE a.estate_snapshot_pk = @snap
  AND a.entry_id = 'semantic-transformation.authority.json'
  AND c.content_digest IN (SELECT new_digest FROM #docs)
ORDER BY a.source_path;

DROP TABLE #docs;
DROP TABLE #defs;

-- Inspect the results above, then swap ROLLBACK for COMMIT to keep them.
ROLLBACK TRANSACTION;
-- COMMIT TRANSACTION;
