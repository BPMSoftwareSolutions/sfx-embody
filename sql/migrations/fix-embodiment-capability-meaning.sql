-- fix-embodiment-capability-meaning.sql
--
-- The embodiment capabilities were scaffolded for structure and inherited the
-- scaffolded greeting meaning and CLI mapping. The greeting CLI mapping is what
-- remapped a raw inline input into payload.name, so inline JSON invocations of
-- the read/plan/compose/write capabilities failed with READ_CAPABILITY_ID_REQUIRED.
-- This authors each capability's own meaning in place and clears the scaffolded
-- CLI mapping and scenario members, and retires the scaffolded feature profiles.
--
-- Default: ROLLBACK. Replace with COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
EXEC model.author_capability_meaning @capability_id=N'read-capability-authority',
  @intent=N'read a capability''s retained authority as a declaration',
  @outcome=N'the retained authority declaration is returned';
EXEC model.author_capability_meaning @capability_id=N'plan-capability-embodiment',
  @intent=N'plan a capability authority declaration into its content-addressed embodiment plan',
  @outcome=N'the content-addressed embodiment plan is returned';
EXEC model.author_capability_meaning @capability_id=N'construct-embodiment-plan',
  @intent=N'read a capability identity''s retained authority then plan its content-addressed embodiment',
  @outcome=N'the content-addressed embodiment plan is returned';
EXEC model.author_capability_meaning @capability_id=N'write-capability-embodiment',
  @intent=N'write a capability embodiment plan beneath the authorized embodiment root',
  @outcome=N'the materialization record is returned';
EXEC model.author_capability_meaning @capability_id=N'materialize-capability-embodiment',
  @intent=N'read, plan and write a capability identity''s embodiment',
  @outcome=N'the materialization record is returned';
SELECT '1_meaning' AS result_set, c.capability_id,
       JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.authority.userStory.intent') AS intent,
       JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.cli') AS cli
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ec.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE c.capability_id IN (N'read-capability-authority',N'plan-capability-embodiment',N'construct-embodiment-plan',N'write-capability-embodiment',N'materialize-capability-embodiment')
ORDER BY c.capability_id;
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
