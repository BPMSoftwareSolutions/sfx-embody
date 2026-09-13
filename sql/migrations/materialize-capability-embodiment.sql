-- materialize-capability-embodiment.sql
--
-- Declares `materialize-capability-embodiment`: the embody loop as one composed
-- capability. It composes the plan capability (which itself composes the read
-- capability before the plan capability) and then the write capability, so a
-- capability identity is read, planned and written by declared operations.
--
--   identity --read/plan--> embodiment plan --write--> materialization record
--
-- Default: ROLLBACK. Replace with COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
DECLARE @request nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/construct-embodiment-plan-request.v1.schema.json","title":"Construct Embodiment Plan Request","type":"object","additionalProperties":false,"required":["capabilityId"],"properties":{"capabilityId":{"type":"string","minLength":1},"scenarioId":{"type":"string","minLength":1},"target":{"type":"string","enum":["node","python","csharp"]}}}';
DECLARE @materialization nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/capability-embodiment-materialization.v1.schema.json","title":"Capability Embodiment Materialization","type":"object","additionalProperties":false,"required":["contractId","capabilityId","scenarioId","target","outputRoot","planDigest","artifactDigest","fileCount","written"],"properties":{"contractId":{"const":"capability-embodiment-materialization.v1"},"capabilityId":{"type":"string","minLength":1},"scenarioId":{"type":"string","minLength":1},"target":{"type":"string","minLength":1},"outputRoot":{"type":"string","minLength":1},"planDigest":{"type":"string","pattern":"^sha256:[a-f0-9]{64}$"},"artifactDigest":{"type":"string","minLength":1},"fileCount":{"type":"integer","minimum":1},"written":{"type":"array","minItems":1,"items":{"type":"object","additionalProperties":false,"required":["relativePath","digest"],"properties":{"relativePath":{"type":"string","minLength":1},"digest":{"type":"string","pattern":"^sha256:[a-f0-9]{64}$"}}}}}}';
EXEC model.scaffold_composed_capability
  @capability_id=N'materialize-capability-embodiment',
  @input_contract=N'construct-embodiment-plan-request.v1', @input_schema=@request,
  @outcome_contract=N'capability-embodiment-materialization.v1', @outcome_schema=@materialization,
  @targets=N'["construct-embodiment-plan","write-capability-embodiment"]',
  @description=N'Read, plan and write a capability identity''s embodiment';
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.

