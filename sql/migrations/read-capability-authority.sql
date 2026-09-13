-- read-capability-authority.sql
--
-- Declares `read-capability-authority`: the read step of the long-form
-- embodiment composition. Its outcome is the transportable authority
-- declaration the plan step consumes.
--
-- Default: ROLLBACK. Replace with COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
DECLARE @request nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/construct-embodiment-plan-request.v1.schema.json","title":"Construct Embodiment Plan Request","type":"object","additionalProperties":false,"required":["capabilityId"],"properties":{"capabilityId":{"type":"string","minLength":1},"scenarioId":{"type":"string","minLength":1},"target":{"type":"string","enum":["node"]}}}';
DECLARE @declaration nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/capability-authority-declaration.v1.schema.json","title":"Capability Authority Declaration","type":"object","additionalProperties":false,"required":["contractId","capabilityId","scenarioId","target","snapshotId","projectionDigest"],"properties":{"contractId":{"const":"capability-authority-declaration.v1"},"capabilityId":{"type":"string","minLength":1},"scenarioId":{"type":"string","minLength":1},"target":{"type":"string","minLength":1},"snapshotId":{"type":"string","minLength":1},"projectionDigest":{"type":"string","minLength":1},"viewDefinitionDigest":{"type":"string"},"authority":{"type":"object"},"closure":{"type":"object"},"mechanics":{"type":"object"}}}';
EXEC model.scaffold_estate_provider_capability
  @capability_id=N'read-capability-authority',
  @provider_module=N'src/resolvers/node/authority-read-provider.mjs',
  @provider_export=N'readCapabilityAuthority',
  @input_contract=N'construct-embodiment-plan-request.v1', @input_schema=@request,
  @outcome_contract=N'capability-authority-declaration.v1', @outcome_schema=@declaration,
  @description=N'Read a capability''s retained authority as a declaration';
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
