/*
SQL -> CLI work order 001: Hello World scaffold
2026-09-12

Run in the existing SideFX SQL Server database, in SSMS or a normal SQL session.
Edit only @CapabilityId and @Message to repeat the scaffold operation.

Input: {}. Event: write the database-defined text through a stdout mechanic.
Outcome: the caller observes that text and a receipt for the actual write.
Flywheel: SQL scaffold -> CLI execution -> observed output -> SQL change -> repeat.

CURRENT RESULT: a session-local candidate plus explicit execution blockers.
This file does NOT install a CLI-invocable capability. The inspected Node event
registry contains no stdout binding, and the current CLI reads the selected
estate model rather than these working rows. Those are implementation gaps,
not requirements to promote a workshop edit into a managed capsule.

The candidate contains meaning, contracts, an operation and a provider slot.
An unresolved slot is not a provider implementation. SELECT/PRINT output and
the CLI's ordinary JSON response are not the requested stdout mechanic call.

Rollback is enabled: all candidate tables are created inside the transaction.
Five numbered review datasets are returned before rollback. Capture the results
if you want to retain the candidate. Replacing ROLLBACK with COMMIT does not
connect session-local tables to the CLI and is not a solution to the blockers.

Future CLI proof, after both blockers are resolved (NOT working syntax proof):
  sfx capability invoke hello-world-sql --input '{}' --json
  Run from C:/lab/repos/sfx-embody so its existing database delivery is selected.

No source capsule, existing capability, model selection or guard is modified.
No managed admission/publication step and no external effect is invoked.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @CapabilityId nvarchar(120) = N'hello-world-sql';
DECLARE @Message nvarchar(4000) = N'Hello World';

IF @@TRANCOUNT <> 0
    THROW 51000, 'RUN_SCAFFOLD_IN_A_SESSION_WITHOUT_AN_EXISTING_TRANSACTION', 1;
IF @CapabilityId IS NULL OR @CapabilityId = N''
   OR @CapabilityId COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-z0-9-]%'
   OR LEFT(@CapabilityId, 1) COLLATE Latin1_General_100_BIN2 NOT LIKE N'[a-z]'
    THROW 51000, 'CAPABILITY_ID_MUST_START_WITH_A_LETTER_AND_USE_LOWERCASE_LETTERS_DIGITS_HYPHENS', 1;
IF @Message IS NULL
    THROW 51000, 'MESSAGE_MUST_BE_EXPLICIT', 1;
IF OBJECT_ID(N'source.current_model', N'U') IS NULL
   OR OBJECT_ID(N'analysis.v_selected_semantic_definition', N'V') IS NULL
    THROW 51000, 'SELECT_THE_EXISTING_SIDEFX_DATABASE', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @ModelId bigint, @SnapshotId bigint, @ProjectionDigest varchar(71);
    SELECT @ModelId = cm.estate_model_pk, @SnapshotId = m.estate_snapshot_pk,
           @ProjectionDigest = 'sha256:' + LOWER(CONVERT(varchar(64), m.mapping_manifest_digest, 2))
    FROM source.current_model cm WITH (HOLDLOCK)
    JOIN source.estate_model m ON m.estate_model_pk = cm.estate_model_pk
    WHERE cm.singleton_id = 1;
    IF @ModelId IS NULL THROW 51000, 'SELECTED_MODEL_MISSING', 1;

    CREATE TABLE #Scaffold (
        capability_id nvarchar(120) NOT NULL,
        scenario_id nvarchar(120) NOT NULL,
        feature_text nvarchar(max) NOT NULL,
        input_contract_id nvarchar(160) NOT NULL,
        input_schema nvarchar(max) NOT NULL,
        event_authority_id nvarchar(160) NOT NULL,
        event_responsibility nvarchar(400) NOT NULL,
        output_contract_id nvarchar(160) NOT NULL,
        output_schema nvarchar(max) NOT NULL,
        message nvarchar(4000) NOT NULL
    );
    CREATE TABLE #Operation (
        scenario_id nvarchar(120) NOT NULL,
        ordinal int NOT NULL,
        operation_kind varchar(40) NOT NULL,
        port_id nvarchar(160) NOT NULL,
        required_mechanic nvarchar(400) NOT NULL,
        request_json nvarchar(max) NOT NULL,
        bound_platform_capability_id nvarchar(400) NULL,
        provider_module nvarchar(400) NULL,
        provider_export nvarchar(400) NULL
    );
    CREATE TABLE #Finding (
        code varchar(100) NOT NULL,
        expected nvarchar(max) NOT NULL,
        observed nvarchar(max) NOT NULL,
        evidence_source nvarchar(max) NOT NULL
    );

    DECLARE @InputContract nvarchar(160) = @CapabilityId + N'-request.v1';
    DECLARE @OutputContract nvarchar(160) = @CapabilityId + N'-write-receipt.v1';
    DECLARE @Feature nvarchar(max) =
        N'@capability:' + @CapabilityId + CHAR(10) +
        N'@root-scenario:' + @CapabilityId + CHAR(10) +
        N'Feature: Write the configured text to standard output' + CHAR(10) + CHAR(10) +
        N'  @scenario:' + @CapabilityId + CHAR(10) +
        N'  @input:empty-request' + CHAR(10) +
        N'  @input-contract:' + @InputContract + CHAR(10) +
        N'  @event:write-configured-text' + CHAR(10) +
        N'  @event-authority:' + @CapabilityId + N'.v1' + CHAR(10) +
        N'  @outcome:standard-output-written' + CHAR(10) +
        N'  @outcome-contract:' + @OutputContract + CHAR(10) +
        N'  @outcome-terminal' + CHAR(10) +
        N'  Scenario: Write the database-defined message' + CHAR(10) +
        N'    Given an empty request and the message configured in the database' + CHAR(10) +
        N'    When the standard-output mechanic executes with that message' + CHAR(10) +
        N'    Then the caller observes the exact message on stdout' + CHAR(10) +
        N'    And execution evidence identifies the actual standard-output call' + CHAR(10);

    INSERT #Scaffold
    SELECT @CapabilityId, @CapabilityId, @Feature, @InputContract,
           N'{"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","additionalProperties":false}',
           @CapabilityId + N'.v1', N'Write the database-defined message through a standard-output mechanic',
           @OutputContract,
           N'{"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","required":["text","bytesWritten"],"additionalProperties":false,"properties":{"text":{"type":"string"},"bytesWritten":{"type":"integer","minimum":0}}}',
           @Message;
    INSERT #Operation
    SELECT @CapabilityId, 1, 'invoke-port', @CapabilityId + N'-stdout-port',
           N'Write supplied text to standard output; report completion or failure of the actual write',
           (SELECT @Message AS [text] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), NULL, NULL, NULL;

    -- Read the selected snapshot's actual Node registry. Search hits are only
    -- candidates for inspection: a name containing "stdout" is not conformance.
    SELECT DISTINCT a.source_path, co.content_digest,
           CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS registry_json
    INTO #Registry
    FROM source.source_appearance a
    JOIN source.content_object co ON co.content_object_pk = a.content_object_pk
    WHERE a.estate_snapshot_pk = @SnapshotId
      AND a.source_class = 'PINNED_PLATFORM_AUTHORITY'
      AND a.source_path LIKE N'%/node-mechanic-registry.authority.v1.json';

    SELECT r.source_path, r.content_digest,
           JSON_VALUE(p.value, '$.platformCapabilityId') AS platform_capability_id,
           JSON_VALUE(p.value, '$.providerModule') AS provider_module,
           JSON_VALUE(p.value, '$.providerExport') AS provider_export,
           JSON_VALUE(p.value, '$.invocation') AS invocation
    INTO #EventPort
    FROM #Registry r
    CROSS APPLY OPENJSON(r.registry_json, '$.eventPorts') p;

    IF NOT EXISTS (SELECT 1 FROM #Registry)
        INSERT #Finding VALUES ('NODE_REGISTRY_NOT_FOUND', N'One exact Node mechanic registry',
            N'No matching registry retained in this snapshot', N'source.source_appearance / source.content_object');
    IF (SELECT COUNT(*) FROM #Registry) > 1
        INSERT #Finding VALUES ('NODE_REGISTRY_AMBIGUOUS', N'One exact Node mechanic registry',
            N'Multiple registry sources: inspect and select an exact source before binding', N'#Registry');

    INSERT #Finding
    SELECT CASE WHEN EXISTS (SELECT 1 FROM #EventPort WHERE
                   platform_capability_id LIKE N'%stdout%' OR platform_capability_id LIKE N'%standard-output%'
                   OR provider_module LIKE N'%stdout%' OR provider_module LIKE N'%standard-output%')
                THEN 'STDOUT_PROVIDER_CANDIDATE_REQUIRES_QUALIFICATION'
                ELSE 'STDOUT_PROVIDER_BINDING_NOT_FOUND' END,
           N'A callable generic stdout event provider with matching request/receipt contracts',
           CASE WHEN EXISTS (SELECT 1 FROM #EventPort WHERE
                   platform_capability_id LIKE N'%stdout%' OR platform_capability_id LIKE N'%standard-output%'
                   OR provider_module LIKE N'%stdout%' OR provider_module LIKE N'%standard-output%')
                THEN N'A name match exists; no provider is bound by this script. Inspect its semantics and implementation.'
                ELSE N'No stdout-named event binding in the selected registry; the complete event-port inventory follows.' END,
           N'Selected snapshot Node registry; #Operation binding fields remain NULL';

    INSERT #Finding VALUES ('WORKING_CANDIDATE_NOT_CONNECTED_TO_CLI',
        N'CLI executes this exact SQL working definition',
        N'This script creates session-local working rows. Current read-authority.mjs resolves source.current_model and retained capsule sources.',
        N'C:/lab/repos/sfx-embody/src/read-authority.mjs; sql/diagnostics/capability-embodiment.sql (source inspected 2026-09-12)');

    IF EXISTS (SELECT 1 FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk = ec.capability_pk
               WHERE ec.estate_model_pk = @ModelId AND c.capability_id = @CapabilityId)
        INSERT #Finding VALUES ('IDENTITY_ALREADY_SELECTED', N'A separately identifiable new working candidate',
            N'The selected model already has this capability ID. It is not modified or replaced by these working rows.', N'model.estate_capability');

    -- 1. Scaffold: the complete session-local working data, not an execution.
    SELECT '1_SCAFFOLD' AS result_set, @ModelId AS inspected_model_id,
           @ProjectionDigest AS inspected_projection_digest, s.*,
           JSON_QUERY((SELECT o.* FROM #Operation o WHERE o.scenario_id = s.scenario_id FOR JSON PATH, INCLUDE_NULL_VALUES)) AS operations,
           'SESSION_LOCAL_CANDIDATE_WITH_OPEN_SLOTS' AS scaffold_status
    FROM #Scaffold s;

    -- 2. Change: no published capability is silently cloned or overwritten.
    SELECT '2_CHANGE' AS result_set, @CapabilityId AS candidate_id, @Message AS candidate_message,
           'CREATE_SESSION_LOCAL_SCAFFOLD' AS proposed_change,
           (SELECT COUNT(*) FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk = ec.capability_pk
            WHERE ec.estate_model_pk = @ModelId AND c.capability_id = @CapabilityId) AS existing_selected_identity_count,
           'ROLLBACK' AS transaction_action, 0 AS persistent_capability_rows_written;

    -- 3. Reuse: show every event binding, so filtering cannot conceal a gap.
    SELECT '3_REUSE' AS result_set, platform_capability_id, provider_module, provider_export, invocation,
           source_path, 'sha256:' + LOWER(CONVERT(varchar(64), content_digest, 2)) AS registry_digest,
           'AVAILABLE_REGISTRY_DECLARATION_NOT_A_STDOUT_COMPATIBILITY_CLAIM' AS assessment
    FROM #EventPort ORDER BY platform_capability_id, source_path;

    -- 4. Verification: expected / observed / difference. No fabricated PASS.
    SELECT '4_VERIFICATION' AS result_set, code, expected, observed, evidence_source,
           'EXECUTION_NOT_PROVEN' AS disposition
    FROM #Finding ORDER BY code;

    -- 5. Rubric: judgments, observed SQL facts and unmeasured delivery are separate.
    SELECT '5_RUBRIC_AND_FLYWHEEL' AS result_set, 'SQL-CLI-001' AS decision_id,
           N'SQL scaffold -> CLI execution -> observed output -> SQL change -> repeat' AS flywheel,
           3 AS contribution_score, N'Required to demonstrate the requested loop' AS contribution_reason,
           0 AS end_to_end_evidence_score, N'No stdout mechanic execution demonstrated' AS evidence_reason,
           'PLANNING_ASSESSMENT' AS assessment_basis, '2026-09-12' AS assessment_date,
           0 AS observed_cli_checkpoints, 4 AS required_cli_checkpoints,
           0 AS external_source_edits, 0 AS managed_promotion_prerequisites,
           CAST(NULL AS decimal(12,2)) AS first_scaffold_minutes,
           CAST(NULL AS int) AS first_scaffold_human_steps,
           CAST(NULL AS decimal(12,2)) AS repeat_minutes,
           N'UNMEASURED: expected easier repetition; provider binding and working-data delivery still missing' AS benefit_and_burden,
           'HELD_AT_EXECUTION' AS disposition;

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
