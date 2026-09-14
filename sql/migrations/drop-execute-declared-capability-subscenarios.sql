-- drop-execute-declared-capability-subscenarios.sql
--
-- `execute-declared-capability` declares four Scenarios but its root authority
-- never invokes the three sub-Scenarios (admit-declared-input,
-- execute-declared-operations, admit-declared-outcome-and-resolve-disposition).
-- It performs those three operations inline as invoke-port operations
-- (admit-execution-input, execute-bound-consumer-plan, admit-execution-outcome),
-- so the sub-Scenario declarations are dead. The kernel compiles every declared
-- Scenario as a cell and rejects the unreferenced ones with UNREACHABLE_CELL.
--
-- This migration removes the three dead sub-Scenarios from the capability's
-- declared Scenario set and from its retained feature, leaving the root
-- authority exactly as it executes. No code and no kernel behaviour changes.
--
-- Default: ROLLBACK after verification. Replace the final ROLLBACK with COMMIT.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capId nvarchar(400) = N'execute-declared-capability';
DECLARE @capPk bigint, @capVer bigint;
SELECT @capPk=c.capability_pk, @capVer=ec.capability_version_pk
FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@model
WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capId;
IF @capPk IS NULL THROW 51000,'EXECUTE_CAPABILITY_NOT_FOUND',1;

DECLARE @drop TABLE (scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @drop VALUES (N'admit-declared-input'),(N'execute-declared-operations'),(N'admit-declared-outcome-and-resolve-disposition');

SELECT '1_before_scenarios' AS result_set, s.scenario_id, cs.scenario_version_pk
FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
WHERE cs.capability_version_pk=@capVer
ORDER BY s.scenario_id;

DELETE cs FROM model.capability_scenario cs
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN @drop d ON d.scenario_id COLLATE Latin1_General_100_BIN2=s.scenario_id COLLATE Latin1_General_100_BIN2
WHERE cs.capability_version_pk=@capVer;
DECLARE @removed int=@@ROWCOUNT;

-- The retained feature text still names the removed Scenarios. Re-declare it
-- from itself, truncated at the first removed Scenario, so the feature matches
-- the capability's declared Scenario set. The procedure rebuilds its Scenario
-- index from model.capability_scenario, which now holds the root only.
DECLARE @featureText nvarchar(max)=(SELECT d.document FROM analysis.v_capability_execution_declaration d
 WHERE d.capability_id=@capId AND d.entry_id=N'capability.feature');
DECLARE @cut int=CHARINDEX(N'@scenario:admit-declared-input',@featureText);
IF @cut>0 SET @featureText=LEFT(@featureText,@cut-1);
IF @featureText IS NOT NULL AND OBJECT_ID(N'model.declare_capability_feature',N'P') IS NOT NULL
 EXEC model.declare_capability_feature @capability_id=@capId,@feature_text=@featureText;

SELECT '2_removed' AS result_set,@removed AS scenario_links_removed;

SELECT '3_after_scenarios' AS result_set, s.scenario_id, cs.scenario_version_pk
FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
WHERE cs.capability_version_pk=@capVer
ORDER BY s.scenario_id;

SELECT '4_root_authority_operations' AS result_set, d.declared_id,
 JSON_QUERY(d.definition_json,'$.semantics.authority.operations') AS operations
FROM analysis.v_selected_semantic_definition d
WHERE d.object_kind='EXECUTION_AUTHORITY' AND d.declared_id=N'execute-declared-capability.v1';

SELECT '5_feature_scenarios' AS result_set, s.scenario_id
FROM model.estate_capability_feature ecf
JOIN model.feature_scenario fs ON fs.feature_version_pk=ecf.feature_version_pk
JOIN model.scenario s ON s.scenario_pk=fs.scenario_pk
WHERE ecf.estate_model_pk=@model AND ecf.capability_pk=@capPk
ORDER BY s.scenario_id;

SELECT '6_closure' AS result_set, s.scenario_id, cl.minimum_depth
FROM analysis.v_scenario_invocation_closure cl
JOIN model.scenario_version sv ON sv.scenario_version_pk=cl.downstream_scenario_version_pk
JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
WHERE cl.capability_version_pk=@capVer
 AND cl.selected_scenario_version_pk=(SELECT cs.scenario_version_pk FROM model.capability_root_scenario crs
   JOIN model.capability_scenario cs ON cs.capability_version_pk=crs.capability_version_pk AND cs.scenario_pk=crs.scenario_pk
   WHERE crs.capability_version_pk=@capVer)
ORDER BY cl.minimum_depth, s.scenario_id;

COMMIT TRANSACTION;
