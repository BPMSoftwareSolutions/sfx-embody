-- plan-capability-embodiment.sql
--
-- Declares `plan-capability-embodiment`: the plan step of the long-form
-- embodiment composition. It consumes the authority declaration the read step
-- produced and returns the content-addressed embodiment plan.
--
-- Default: ROLLBACK. Replace with COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
DECLARE @declaration nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/capability-authority-declaration.v1.schema.json","title":"Capability Authority Declaration","type":"object","additionalProperties":false,"required":["contractId","capabilityId","scenarioId","target","snapshotId","projectionDigest"],"properties":{"contractId":{"const":"capability-authority-declaration.v1"},"capabilityId":{"type":"string","minLength":1},"scenarioId":{"type":"string","minLength":1},"target":{"type":"string","minLength":1},"snapshotId":{"type":"string","minLength":1},"projectionDigest":{"type":"string","minLength":1},"viewDefinitionDigest":{"type":"string"},"authority":{"type":"object"},"closure":{"type":"object"},"mechanics":{"type":"object"}}}';
DECLARE @plan nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/capability-embodiment-plan.v1.schema.json","title":"Capability Embodiment Plan","type":"object","additionalProperties":false,"required":["contractId","capabilityId","scenarioId","target","planDigest","artifactDigest","scenarioDefinitionDigest","platformDigest","resolverVersion","fileCount","files"],"properties":{"contractId":{"const":"capability-embodiment-plan.v1"},"capabilityId":{"type":"string","minLength":1},"scenarioId":{"type":"string","minLength":1},"target":{"type":"string","minLength":1},"planDigest":{"type":"string","pattern":"^sha256:[a-f0-9]{64}$"},"artifactDigest":{"type":"string","minLength":1},"scenarioDefinitionDigest":{"type":"string","minLength":1},"platformDigest":{"type":"string","minLength":1},"resolverVersion":{"type":"string","minLength":1},"fileCount":{"type":"integer","minimum":1},"files":{"type":"array","minItems":1,"items":{"type":"object","additionalProperties":false,"required":["relativePath","digest"],"properties":{"relativePath":{"type":"string","minLength":1},"digest":{"type":"string","pattern":"^sha256:[a-f0-9]{64}$"},"sourcePointers":{"type":"array","items":{"type":"string"}}}}}}}';
EXEC model.scaffold_estate_provider_capability
  @capability_id=N'plan-capability-embodiment',
  @provider_module=N'src/resolvers/node/embodiment-plan-provider.mjs',
  @provider_export=N'planCapabilityEmbodiment',
  @input_contract=N'capability-authority-declaration.v1', @input_schema=@declaration,
  @outcome_contract=N'capability-embodiment-plan.v1', @outcome_schema=@plan,
  @description=N'Plan a capability authority declaration into its content-addressed embodiment plan';
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
