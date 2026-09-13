-- construct-embodiment-plan.sql
--
-- Declares `construct-embodiment-plan` by composition: the read capability's
-- authority declaration is composed before the plan capability, so the
-- embodiment plan is produced by two declared capabilities.
--
--   input (capability identity) --read--> authority declaration --plan--> plan
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
DECLARE @plan nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/capability-embodiment-plan.v1.schema.json","title":"Capability Embodiment Plan","type":"object","additionalProperties":false,"required":["contractId","capabilityId","scenarioId","target","planDigest","artifactDigest","scenarioDefinitionDigest","platformDigest","resolverVersion","fileCount","files"],"properties":{"contractId":{"const":"capability-embodiment-plan.v1"},"capabilityId":{"type":"string","minLength":1},"scenarioId":{"type":"string","minLength":1},"target":{"type":"string","minLength":1},"planDigest":{"type":"string","pattern":"^sha256:[a-f0-9]{64}$"},"artifactDigest":{"type":"string","minLength":1},"scenarioDefinitionDigest":{"type":"string","minLength":1},"platformDigest":{"type":"string","minLength":1},"resolverVersion":{"type":"string","minLength":1},"fileCount":{"type":"integer","minimum":1},"files":{"type":"array","minItems":1,"items":{"type":"object","additionalProperties":false,"required":["relativePath","digest"],"properties":{"relativePath":{"type":"string","minLength":1},"digest":{"type":"string","pattern":"^sha256:[a-f0-9]{64}$"},"sourcePointers":{"type":"array","items":{"type":"string"}}}}}}}';
EXEC model.scaffold_composed_capability
  @capability_id=N'construct-embodiment-plan',
  @input_contract=N'construct-embodiment-plan-request.v1', @input_schema=@request,
  @outcome_contract=N'capability-embodiment-plan.v1', @outcome_schema=@plan,
  @targets=N'["read-capability-authority","plan-capability-embodiment"]',
  @description=N'Read a capability identity''s retained authority then plan its content-addressed embodiment';
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.

