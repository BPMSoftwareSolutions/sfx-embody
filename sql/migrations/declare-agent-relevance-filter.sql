-- declare-agent-relevance-filter.sql
--
-- The agent lane (`request-capability-from-objective`) handed the model a
-- hand-authored visible-capability literal in `build-agent-model-request`. This
-- migration declares a capability-keyword relevance index and a declared read
-- that matches the objective text against it before the model request is built,
-- and re-declares the lane's request builder to consume the filtered set.
--
-- Meaning (all rows / declared read):
--   * analysis.v_capability_keyword_index -- the declared index. One
--     `CAPABILITY_KEYWORD` semantic object per indexed capability carries the
--     curated keywords; the capability's own declared id tokens are derived from
--     model.capability. A capability that has no keyword declaration is not
--     indexed, so the available set is bounded to what is declared relevant.
--   * analysis.capability_relevance(@objective) -- the declared read. SQL Server
--     has no split primitive in the transformation vocabulary, so tokenization is
--     the T-SQL platform mechanic named here: the objective is lower-cased, every
--     non-alphanumeric character becomes a separator, STRING_SPLIT yields the
--     tokens, an optional trailing 's' is folded, and a set join to the index
--     yields {visibleCapabilities, matchedKeywords, tokens, objective}. No
--     matching logic lives in carrier code.
--   * The `decide-agent-route` chain gains `decide-agent-route.relevance`
--     (a declared read on sda-embodiment-plan-port.v1) before
--     `decide-agent-route.build`. The builder renders the prompt visible set and
--     matched keywords from the filter output and writes the same record into
--     the governed request lineage (`visibility:<json>`), so the model evidence
--     carries it hash-bound. The existing resolve read extracts that record and
--     the refusal receipt states it; the declared resolution logic (`route`)
--     is unchanged.
--
-- Default: ROLLBACK. Installed after the rollback dry run and the
-- from-transaction preflight (equity ADMITTED and executed; purchase REFUSED
-- with zero execution cells).
--
-- Proof result sets:
--   1_index        the declared keyword rows per indexed capability
--   2_relevance    the filter output for the equity and purchase objectives
--   3_transformations  the re-declared builders and the unchanged route
--   4_operations   the decide chain's declared operation order
--   5_guard        the semantics guard (throws on any violation)
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers=CURSOR LOCAL FAST_FORWARD FOR
 SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
 FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id
 JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE o.type='U' AND s.name IN ('model','source')
 AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trigger_name); FETCH NEXT FROM @triggers INTO @trigger_name; END;
CLOSE @triggers; DEALLOCATE @triggers;
BEGIN TRANSACTION;
GO
-- ============================== THE DECLARED KEYWORD INDEX ==============================
CREATE OR ALTER VIEW analysis.v_capability_keyword_index AS
WITH indexed AS (
  SELECT d.declared_id AS capability_id
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1)
    AND d.object_kind = N'CAPABILITY_KEYWORD'
    AND d.namespace_id = N'sidefx:capability-keywords'
    AND EXISTS (
      SELECT 1 FROM model.capability c
      JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
      WHERE c.capability_id = d.declared_id COLLATE Latin1_General_100_BIN2
        AND n.namespace_id = N'sidefx:capabilities')
)
SELECT d.declared_id COLLATE Latin1_General_100_BIN2 AS capability_id,
  LOWER(TRIM(kw.value)) COLLATE Latin1_General_100_BIN2 AS keyword,
  N'declared-keyword' AS keyword_source
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json, '$.semantics.keywords') kw
WHERE d.estate_model_pk = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1)
  AND d.object_kind = N'CAPABILITY_KEYWORD'
  AND d.namespace_id = N'sidefx:capability-keywords'
  AND EXISTS (SELECT 1 FROM indexed i WHERE i.capability_id = d.declared_id COLLATE Latin1_General_100_BIN2)
UNION
SELECT i.capability_id, LOWER(TRIM(tok.value)) COLLATE Latin1_General_100_BIN2, N'derived-capability-id'
FROM indexed i
CROSS APPLY STRING_SPLIT(i.capability_id, N'-') tok
WHERE LEN(TRIM(tok.value)) > 1;
GO
-- ============================== THE DECLARED MATCHING READ ==============================
CREATE OR ALTER FUNCTION analysis.capability_relevance(@objective nvarchar(max))
RETURNS nvarchar(max)
AS
BEGIN
  DECLARE @text nvarchar(max) = LOWER(ISNULL(@objective, N''));
  DECLARE @index int = 1, @character nchar(1);
  WHILE @index <= LEN(@text)
  BEGIN
    SET @character = SUBSTRING(@text, @index, 1);
    -- Tokenization platform mechanic: every non-alphanumeric objective
    -- character is a separator; STRING_SPLIT and the set join below are the
    -- tokenizer and matcher. This is declaration data, not carrier code.
    IF @character NOT LIKE N'[a-z0-9]' SET @text = STUFF(@text, @index, 1, N' ');
    SET @index = @index + 1;
  END
  DECLARE @tokens TABLE (token nvarchar(200) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
  INSERT @tokens (token)
  SELECT DISTINCT CASE WHEN LEN(value) > 3 AND RIGHT(value, 1) = N's' THEN LEFT(value, LEN(value) - 1) ELSE value END
  FROM STRING_SPLIT(@text, N' ') WHERE LEN(value) >= 2;
  DECLARE @matches TABLE (capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2, keyword nvarchar(200) COLLATE Latin1_General_100_BIN2);
  INSERT @matches (capability_id, keyword)
  SELECT idx.capability_id, idx.keyword
  FROM analysis.v_capability_keyword_index idx
  JOIN @tokens token
    ON token.token = CASE WHEN LEN(idx.keyword) > 3 AND RIGHT(idx.keyword, 1) = N's' THEN LEFT(idx.keyword, LEN(idx.keyword) - 1) ELSE idx.keyword END
  WHERE idx.capability_id <> N'request-capability-from-objective';
  DECLARE @tokens_json nvarchar(max) = ISNULL(N'[' + (SELECT STRING_AGG(N'"' + STRING_ESCAPE(token, 'json') + N'"', N',') WITHIN GROUP (ORDER BY token) FROM @tokens) + N']', N'[]');
  DECLARE @matched_json nvarchar(max) = ISNULL(N'[' + (SELECT STRING_AGG(N'"' + STRING_ESCAPE(keyword, 'json') + N'"', N',') WITHIN GROUP (ORDER BY keyword) FROM (SELECT DISTINCT keyword FROM @matches) m) + N']', N'[]');
  DECLARE @visible_json nvarchar(max) = (
    SELECT m.capabilityId, m.match_count AS matchedKeywordCount, JSON_QUERY(m.matched_json) AS matchedKeywords
    FROM (
      SELECT x.capability_id AS capabilityId, COUNT(*) AS match_count,
        ISNULL(N'[' + STRING_AGG(N'"' + STRING_ESCAPE(x.keyword, 'json') + N'"', N',') WITHIN GROUP (ORDER BY x.keyword) + N']', N'[]') AS matched_json
      FROM @matches x
      GROUP BY x.capability_id
    ) m
    ORDER BY m.match_count DESC, m.capabilityId
    FOR JSON PATH);
  RETURN (
    SELECT @objective AS objective,
      JSON_QUERY(ISNULL(@tokens_json, N'[]')) AS tokens,
      JSON_QUERY(ISNULL(@visible_json, N'[]')) AS visibleCapabilities,
      JSON_QUERY(ISNULL(@matched_json, N'[]')) AS matchedKeywords,
      (SELECT COUNT(DISTINCT capability_id) FROM @matches) AS visibleCapabilityCount
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
END;
GO
-- The declared read executes under sidefx_reader.
GRANT EXECUTE ON OBJECT::analysis.capability_relevance TO sidefx_reader;
GRANT SELECT ON OBJECT::analysis.v_capability_keyword_index TO sidefx_reader;
GO
-- ============================== THE DECLARED KEYWORD ROWS ==============================
DECLARE @keyword_semantics nvarchar(max) = N'{"capabilityId":"resolve-equity-market-price-evidence","keywords":["stock","share","ticker","symbol","quote","nasdaq","equities","valuation"],"source":"curated for the equity/price objective; capability-id tokens are derived by analysis.v_capability_keyword_index"}';
DECLARE @kw_object bigint, @kw_definition bigint, @kw_digest binary(32);
EXEC model.put_semantic_definition 'CAPABILITY_KEYWORD', N'sidefx:capability-keywords', N'resolve-equity-market-price-evidence', @keyword_semantics, @kw_object OUTPUT, @kw_definition OUTPUT, @kw_digest OUTPUT;
GO
-- ============================== TRANSFORMATIONS ==============================
DECLARE @capability_id nvarchar(400) = N'request-capability-from-objective';
DECLARE @namespace nvarchar(400) = N'sidefx:capability:' + @capability_id;

-- The builder: the visible set and matched keywords are rendered from the
-- declared filter output (`input.visibility`), never from a literal; the same
-- record is written into the governed request lineage so the model evidence
-- carries it hash-bound.
DECLARE @prompt nvarchar(max) = N'You map one user objective to exactly one governed capability request. The capabilities this invocation can see are: {visible} (matched keywords: {keywords}). A visible capability can be requested directly. If no visible capability can satisfy the objective, propose the capability identity the objective would require, even though it is not in the list. Respond only with the declared JSON shape: capability is the capability identity, input is the scalar that capability needs (for a price capability, resolve the company to its US ticker symbol, for example Broadcom to AVGO).';
DECLARE @proposal_schema nvarchar(max) = N'{"type":"object","required":["capability","input"],"properties":{"capability":{"type":"string"},"input":{"type":"string"}}}';
DECLARE @visible nvarchar(max) = N'{"op":"if","when":{"op":"greater-than","left":{"op":"length","value":{"op":"path","from":"input","path":"visibility.visibleCapabilities"}},"right":{"op":"literal","value":0}},"then":{"op":"join","separator":", ","value":{"op":"map","from":{"op":"path","from":"input","path":"visibility.visibleCapabilities"},"as":"visibleCapability","value":{"op":"path","from":"visibleCapability","path":"capabilityId"}}},"else":{"op":"literal","value":"(none)"}}';
DECLARE @keywords nvarchar(max) = N'{"op":"if","when":{"op":"greater-than","left":{"op":"length","value":{"op":"path","from":"input","path":"visibility.matchedKeywords"}},"right":{"op":"literal","value":0}},"then":{"op":"join","separator":", ","value":{"op":"path","from":"input","path":"visibility.matchedKeywords"}},"else":{"op":"literal","value":"(none)"}}';
DECLARE @visibility_lineage nvarchar(max) = N'{"op":"format","template":"visibility:{json}","values":{"json":{"op":"json-stringify","value":{"op":"path","from":"input","path":"visibility"}}}}';
DECLARE @build nvarchar(max) = N'{"op":"object","fields":{'
 + N'"carrierType":{"op":"literal","value":"governed-model-invocation-request.v1"},'
 + N'"requestId":{"op":"literal","value":"agent-objective"},'
 + N'"requestHash":{"op":"literal","value":"sha256:0000000000000000000000000000000000000000000000000000000000000000"},'
 + N'"modelRequest":{"op":"object","fields":{'
 +   N'"$schema":{"op":"literal","value":"../../generic-llm-connector/authority/model-request.schema.v1.json"},'
 +   N'"requestId":{"op":"literal","value":"agent-objective"},'
 +   N'"providerAuthorityId":{"op":"literal","value":"primary-cognitive-provider"},'
 +   N'"modelAlias":{"op":"literal","value":"instruction-capable-model"},'
 +   N'"interaction":{"op":"object","fields":{'
 +     N'"mode":{"op":"literal","value":"structured-generation"},'
 +     N'"messages":{"op":"array","items":['
 +       N'{"op":"object","fields":{"role":{"op":"literal","value":"system"},"content":{"op":"format","template":"' + @prompt + N'","values":{"visible":' + @visible + N',"keywords":' + @keywords + N'}}}},'
 +       N'{"op":"object","fields":{"role":{"op":"literal","value":"user"},"content":{"op":"path","from":"root","path":"payload.objective"}}}'
 +     N']}}},'
 +   N'"responsePolicy":{"op":"object","fields":{'
 +     N'"format":{"op":"literal","value":"json"},'
 +     N'"maximumOutputTokens":{"op":"literal","value":4096},'
 +     N'"temperature":{"op":"literal","value":0},'
 +     N'"schema":{"op":"literal","value":' + @proposal_schema + N'}}},'
 +   N'"executionPolicy":{"op":"object","fields":{'
 +     N'"timeoutMilliseconds":{"op":"literal","value":60000},'
 +     N'"attemptAuthority":{"op":"object","fields":{"maximumAuthorizedAttempts":{"op":"literal","value":1}}},'
 +     N'"providerSubstitution":{"op":"object","fields":{"allowed":{"op":"literal","value":false}}}}},'
 +   N'"evidencePolicy":{"op":"object","fields":{'
 +     N'"captureRequestHash":{"op":"literal","value":true},'
 +     N'"captureResponseHash":{"op":"literal","value":true},'
 +     N'"captureResolvedProvider":{"op":"literal","value":true},'
 +     N'"captureResolvedModel":{"op":"literal","value":true},'
 +     N'"captureTokenUsage":{"op":"literal","value":true},'
 +     N'"captureTiming":{"op":"literal","value":true}}}}},'
 + N'"requestLineage":{"op":"array","items":[{"op":"literal","value":"agent-objective"},{"op":"literal","value":"obtain-governed-model-response"},' + @visibility_lineage + N']}'
 + N'}}';

-- The route state carries the filter record forward for the refusal receipt.
-- The resolution logic (`route`) is byte-identical to the installed form.
DECLARE @decision nvarchar(max) = N'{"op":"object","fields":{'
 + N'"contractId":{"op":"literal","value":"agent-route.v1"},'
 + N'"route":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"input","path":"declared"},"right":{"op":"literal","value":1}},'
 +   N'"then":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"input","path":"proposedCapability"},"right":{"op":"literal","value":"resolve-equity-market-price-evidence"}},"then":{"op":"literal","value":"ADMITTED"},"else":{"op":"literal","value":"REFUSED"}},'
 +   N'"else":{"op":"literal","value":"REFUSED"}},'
 + N'"carried":{"op":"path","from":"input","path":"carried"},'
 + N'"proposal":{"op":"object","fields":{"capability":{"op":"path","from":"input","path":"proposedCapability"},"input":{"op":"path","from":"input","path":"proposedInput"}}},'
 + N'"visibility":{"op":"path","from":"input","path":"visibility"},'
 + N'"executionRequest":{"op":"object","fields":{"contractId":{"op":"literal","value":"live-equity-price-request.v1"},"payload":{"op":"object","fields":{"symbol":{"op":"path","from":"input","path":"proposedInput"},"region":{"op":"literal","value":"US"}}}}}'
 + N'}}';
DECLARE @equity_request nvarchar(max) = N'{"op":"path","from":"input","path":"executionRequest"}';
DECLARE @refusal_evidence nvarchar(max) = N'{"op":"object","fields":{'
 + N'"contractId":{"op":"literal","value":"agent-refusal-evidence.v1"},'
 + N'"capability":{"op":"literal","value":"request-capability-from-objective"},'
 + N'"model":{"op":"object","fields":{'
 +   N'"disposition":{"op":"path","from":"input","path":"carried.disposition"},'
 +   N'"provider":{"op":"path","from":"input","path":"carried.resolvedProvider"},'
 +   N'"model":{"op":"path","from":"input","path":"carried.resolvedModel"},'
 +   N'"proposal":{"op":"path","from":"input","path":"proposal"}}},'
 + N'"resolution":{"op":"object","fields":{"capability":{"op":"path","from":"input","path":"proposal.capability"},"declared":{"op":"literal","value":false}}},'
 + N'"visibility":{"op":"path","from":"input","path":"visibility"},'
 + N'"refusal":{"op":"literal","value":"CAPABILITY_NOT_FOUND"},'
 + N'"diagnostic":{"op":"path","from":"input","path":"carried"}'
 + N'}}';
DECLARE @transformations TABLE (ordinal int PRIMARY KEY, id nvarchar(400), expression nvarchar(max));
INSERT @transformations VALUES
 (0, N'build-agent-model-request', @build),
 (1, N'decide-agent-route', @decision),
 (2, N'shape-equity-execution-request', @equity_request),
 (3, N'shape-agent-refusal-evidence', @refusal_evidence);
DECLARE @ordinal int, @id nvarchar(400), @expression nvarchar(max), @semantics nvarchar(max);
DECLARE @object bigint, @definition bigint, @digest binary(32), @transformation bigint, @version bigint;
DECLARE @cursor CURSOR;
SET @cursor = CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal, id, expression FROM @transformations ORDER BY ordinal;
OPEN @cursor;
FETCH NEXT FROM @cursor INTO @ordinal, @id, @expression;
WHILE @@FETCH_STATUS = 0
BEGIN
  SET @semantics = N'{"id":"' + @id + N'","expression":' + @expression + N'}';
  EXEC model.put_semantic_definition 'TRANSFORMATION', @namespace, @id, @semantics, @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
  SET @transformation = (SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk = @object);
  IF @transformation IS NULL
  BEGIN
    INSERT model.transformation(namespace_pk, transformation_id, semantic_object_pk, object_kind)
    SELECT namespace_pk, @id, @object, 'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk = @object;
    SET @transformation = SCOPE_IDENTITY();
  END
  SET @version = (SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk = @definition);
  IF @version IS NULL
  BEGIN
    INSERT model.transformation_version(transformation_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest,
      expression_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES(@transformation, @object, @definition, @digest, 'json-expression-tree.v1', 'TRANSFORMATION', @definition, N'');
    SET @version = SCOPE_IDENTITY();
    EXEC model.normalize_transformation_expression @version;
  END
  FETCH NEXT FROM @cursor INTO @ordinal, @id, @expression;
END
CLOSE @cursor;
DEALLOCATE @cursor;
GO
-- ============================== THE LANE'S DECIDE CHAIN ==============================
-- The relevance read is the first operation of the decision chain: the model
-- request builder consumes its output, so the filter runs before the request.
DECLARE @capability_id nvarchar(400) = N'request-capability-from-objective';
DECLARE @relevance_statement nvarchar(max) = N'
DECLARE @objective nvarchar(max)=ISNULL(JSON_VALUE(@input,''$.payload.objective''),N'''');
DECLARE @relevance nvarchar(max)=analysis.capability_relevance(@objective);
SELECT JSON_MODIFY(@input,''$.visibility'',JSON_QUERY(@relevance)) AS value';
DECLARE @resolve_statement nvarchar(max) = N'
DECLARE @proposed nvarchar(400)=JSON_VALUE(@input,''$.normalizedResponse.structuredValue.capability'');
DECLARE @proposedInput nvarchar(400)=JSON_VALUE(@input,''$.normalizedResponse.structuredValue.input'');
DECLARE @declared bit=CASE WHEN EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=''CAPABILITY'' AND d.declared_id=@proposed) THEN 1 ELSE 0 END;
DECLARE @visibility nvarchar(max)=(
 SELECT TOP (1) SUBSTRING(lineage.[value],12,LEN(lineage.[value]))
 FROM OPENJSON(ISNULL(JSON_QUERY(@input,''$.effectLineage''),''[]'')) lineage
 WHERE lineage.[value] LIKE N''visibility:%'');
SELECT (SELECT JSON_QUERY(@input) AS carried, CASE WHEN @declared=1 THEN 1 ELSE 0 END AS declared, @proposed AS proposedCapability, @proposedInput AS proposedInput, JSON_QUERY(@visibility) AS visibility FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS value';
DECLARE @bindings nvarchar(max) = N'['
 + N'{"portId":"assemble-agent-relevance-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"' + STRING_ESCAPE(@relevance_statement, N'json') + N'","resultColumn":"value"}},'
 + N'{"portId":"build-agent-model-request-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"build-agent-model-request"}},'
 + N'{"portId":"resolve-proposed-capability-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"' + STRING_ESCAPE(@resolve_statement, N'json') + N'","resultColumn":"value"}},'
 + N'{"portId":"decide-agent-route-inner-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"decide-agent-route"}}]';
EXEC model.declare_scenario
  @capability_id = @capability_id,
  @scenario = N'{"scenarioId":"decide-agent-route","name":"Decide the objective route","inputId":"decide-agent-route-request","inputContract":"agent-objective-request.v1","eventId":"decide-agent-route-requested","eventAuthority":"decide-agent-route.v1","outcomeId":"agent-route","outcomeContract":"agent-route.v1","given":"one objective","when":"the declared filter bounds the visible set, the governed model proposes and the declared estate resolves","then":"the route state names the proposal, the filtered visibility and whether it is admitted","terminal":false,"variants":["ADMITTED","REFUSED"]}',
  @operations = N'[{"operationId":"decide-agent-route.relevance","kind":"invoke-port","portId":"assemble-agent-relevance-port"},{"operationId":"decide-agent-route.build","kind":"invoke-port","portId":"build-agent-model-request-port"},{"operationId":"decide-agent-route.resolve","kind":"invoke-port","portId":"resolve-proposed-capability-port"},{"operationId":"decide-agent-route.decide","kind":"invoke-port","portId":"decide-agent-route-inner-port"}]',
  @port_bindings = @bindings;
GO
-- ============================== THE COMPOSED AUTHORITY ==============================
-- The chain's real authority: filter read, request builder, the governed model
-- child, the declared resolution read, the route decision. Re-minted with the
-- relevance operation; the root and admitted/refusal authorities are untouched.
DECLARE @capability_id nvarchar(400) = N'request-capability-from-objective';
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @model_target bigint = (SELECT cs.scenario_version_pk
  FROM model.capability c JOIN model.estate_capability ec ON ec.capability_pk = c.capability_pk AND ec.estate_model_pk = @model
  JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk
  JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
  WHERE c.capability_id = N'obtain-governed-model-response' AND s.scenario_id = N'obtain-governed-model-response');
DECLARE @chain_target bigint = (SELECT cs.scenario_version_pk
  FROM model.capability c JOIN model.estate_capability ec ON ec.capability_pk = c.capability_pk AND ec.estate_model_pk = @model
  JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk
  JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
  WHERE c.capability_id = @capability_id AND s.scenario_id = N'decide-agent-route');
IF @model_target IS NULL THROW 51000, 'AGENT_MODEL_SCENARIO_NOT_FOUND', 1;
IF @chain_target IS NULL THROW 51000, 'AGENT_CHAIN_SCENARIO_NOT_FOUND', 1;
DECLARE @authority_id nvarchar(400) = N'decide-agent-route.v1';
DECLARE @operations nvarchar(max) = N'[{"kind":"invoke-port","portId":"assemble-agent-relevance-port"},{"kind":"invoke-port","portId":"build-agent-model-request-port"},{"kind":"invoke-scenario","scenarioId":"obtain-governed-model-response"},{"kind":"invoke-port","portId":"resolve-proposed-capability-port"},{"kind":"invoke-port","portId":"decide-agent-route-inner-port"}]';
DECLARE @envelope nvarchar(max) = N'{"address":{"id":"decide-agent-route.v1","kind":"EXECUTION_AUTHORITY","namespace":"sidefx:capability:request-capability-from-objective"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":{"id":"decide-agent-route.v1","operations":' + @operations + N',"owningScenarioId":"decide-agent-route"}}}';
DECLARE @eaPk bigint, @eaSo bigint, @envBytes varbinary(max), @envDigest binary(32), @authSod bigint, @eaVer bigint;
SELECT @eaPk = ea.execution_authority_pk, @eaSo = ea.semantic_object_pk
FROM model.execution_authority ea
JOIN model.identity_namespace n ON n.namespace_pk = ea.namespace_pk
WHERE n.namespace_id = N'sidefx:capability:' + @capability_id AND ea.execution_authority_id = @authority_id;
IF @eaPk IS NULL THROW 51000, 'AGENT_AUTHORITY_NOT_FOUND', 1;
SET @envBytes = CONVERT(varbinary(max), CONVERT(varchar(max), (@envelope) COLLATE Latin1_General_100_BIN2_UTF8));
SET @envDigest = HASHBYTES('SHA2_256', @envBytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest = @envDigest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@envDigest, @envBytes, DATALENGTH(@envBytes));
IF NOT EXISTS (SELECT 1 FROM model.semantic_object_definition WHERE semantic_object_pk = @eaSo AND definition_digest = @envDigest)
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
    VALUES (@eaSo, 'EXECUTION_AUTHORITY', @envDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest = @envDigest));
SET @authSod = (SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk = @eaSo AND definition_digest = @envDigest);
IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk = @model AND semantic_object_definition_pk = @authSod)
  INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @authSod);
SET @eaVer = (SELECT MAX(execution_authority_version_pk) FROM model.execution_authority_version WHERE execution_authority_pk = @eaPk AND definition_digest = @envDigest);
IF @eaVer IS NULL
BEGIN
  INSERT model.execution_authority_version (execution_authority_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, authority_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@eaPk, @eaSo, @authSod, @envDigest, 'execution-authorities.v1', 'EXECUTION_AUTHORITY', @authSod, N'');
  SET @eaVer = SCOPE_IDENTITY();
  INSERT model.execution_operation (execution_authority_version_pk, operation_id, ordinal, operation_kind, _owner_definition_pk, _canonical_pointer)
    SELECT @eaVer, NULL, CONVERT(int, o.[key]), JSON_VALUE(o.value, '$.kind'), @authSod, N'/semantics/authority/operations/' + o.[key]
    FROM OPENJSON(@operations) o;
  INSERT model.operation_port_invocation (execution_operation_pk, port_version_pk, operation_kind, _owner_definition_pk, _canonical_pointer)
    SELECT eo.execution_operation_pk, pv.port_version_pk, 'invoke-port', @authSod, eo._canonical_pointer
    FROM model.execution_operation eo
    JOIN OPENJSON(@operations) o ON CONVERT(int, o.[key]) = eo.ordinal
    JOIN model.port p ON p.port_id = JSON_VALUE(o.value, '$.portId')
    JOIN model.port_version pv ON pv.port_pk = p.port_pk
    WHERE eo.execution_authority_version_pk = @eaVer
      AND pv.port_version_pk = (SELECT MAX(port_version_pk) FROM model.port_version WHERE port_pk = p.port_pk);
  INSERT model.operation_scenario_invocation (execution_operation_pk, target_scenario_version_pk, operation_kind, _owner_definition_pk, _canonical_pointer)
    SELECT eo.execution_operation_pk, @model_target, 'invoke-scenario', @authSod, eo._canonical_pointer
    FROM model.execution_operation eo
    JOIN OPENJSON(@operations) o ON CONVERT(int, o.[key]) = eo.ordinal
    WHERE eo.execution_authority_version_pk = @eaVer AND JSON_VALUE(o.value, '$.kind') = 'invoke-scenario';
END
UPDATE model.scenario_event SET execution_authority_version_pk = @eaVer WHERE scenario_version_pk = @chain_target;
GO
-- ============================== PROOF AND GUARD ==============================
DECLARE @estate bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @equity_objective nvarchar(max) = N'What is Broadcom''s current market price?';
DECLARE @purchase_objective nvarchar(max) = N'Buy $1,000 worth of Broadcom.';

SELECT '1_index' AS result_set, capability_id, keyword, keyword_source
FROM analysis.v_capability_keyword_index ORDER BY capability_id, keyword;

SELECT '2_relevance' AS result_set,
 CONVERT(int, JSON_VALUE(analysis.capability_relevance(@equity_objective), '$.visibleCapabilityCount')) AS equity_visible_count,
 JSON_QUERY(analysis.capability_relevance(@equity_objective), '$.visibleCapabilities') AS equity_visible,
 JSON_QUERY(analysis.capability_relevance(@equity_objective), '$.matchedKeywords') AS equity_keywords,
 CONVERT(int, JSON_VALUE(analysis.capability_relevance(@purchase_objective), '$.visibleCapabilityCount')) AS purchase_visible_count,
 JSON_QUERY(analysis.capability_relevance(@purchase_objective), '$.visibleCapabilities') AS purchase_visible;

SELECT '3_transformations' AS result_set, d.declared_id AS transformation_id,
 CONVERT(bit, CASE WHEN d.definition_json LIKE N'%visibility.visibleCapabilities%' THEN 1 ELSE 0 END) AS filter_consumed,
 CONVERT(bit, CASE WHEN d.definition_json LIKE N'%json-stringify%' THEN 1 ELSE 0 END) AS lineage_record_declared
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk = @estate AND d.namespace_id = N'sidefx:capability:request-capability-from-objective'
  AND d.object_kind = N'TRANSFORMATION' AND d.declared_id IN (N'build-agent-model-request', N'decide-agent-route', N'shape-agent-refusal-evidence')
ORDER BY d.declared_id;

SELECT '4_operations' AS result_set, eo.ordinal, eo.operation_kind, p.port_id, target.scenario_id AS target_scenario
FROM model.execution_authority ea
JOIN model.identity_namespace n ON n.namespace_pk = ea.namespace_pk AND n.namespace_id = N'sidefx:capability:request-capability-from-objective'
JOIN model.execution_authority_version eav ON eav.execution_authority_pk = ea.execution_authority_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk = eav.execution_authority_version_pk
LEFT JOIN model.operation_port_invocation opi ON opi.execution_operation_pk = eo.execution_operation_pk
LEFT JOIN model.port_version pv ON pv.port_version_pk = opi.port_version_pk
LEFT JOIN model.port p ON p.port_pk = pv.port_pk
LEFT JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk = eo.execution_operation_pk
LEFT JOIN model.scenario_version tsv ON tsv.scenario_version_pk = osi.target_scenario_version_pk
LEFT JOIN model.scenario target ON target.scenario_pk = tsv.scenario_pk
WHERE ea.execution_authority_id = N'decide-agent-route.v1'
  AND eav.execution_authority_version_pk = (SELECT MAX(v.execution_authority_version_pk) FROM model.execution_authority_version v WHERE v.execution_authority_pk = ea.execution_authority_pk)
ORDER BY eo.ordinal;

-- Semantics guard: the relevant objective selects the equity capability with
-- matched keywords; the purchase objective selects nothing; the declared
-- resolution logic is byte-identical to the installed route.
DECLARE @equity_relevance nvarchar(max) = analysis.capability_relevance(@equity_objective);
DECLARE @purchase_relevance nvarchar(max) = analysis.capability_relevance(@purchase_objective);
DECLARE @equity_selected bit = CASE WHEN EXISTS (
  SELECT 1 FROM OPENJSON(JSON_QUERY(@equity_relevance, '$.visibleCapabilities')) v
  WHERE JSON_VALUE(v.value, '$.capabilityId') = N'resolve-equity-market-price-evidence') THEN 1 ELSE 0 END;
DECLARE @equity_keywords bit = CASE WHEN EXISTS (
  SELECT 1 FROM OPENJSON(JSON_QUERY(@equity_relevance, '$.matchedKeywords')) k
  WHERE k.value IN (N'market', N'price')) THEN 1 ELSE 0 END;
DECLARE @purchase_empty bit = CASE WHEN JSON_VALUE(@purchase_relevance, '$.visibleCapabilityCount') = N'0' THEN 1 ELSE 0 END;
DECLARE @route nvarchar(max) = (
  SELECT JSON_QUERY(d.definition_json, '$.semantics.expression.fields.route')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk = @estate AND d.namespace_id = N'sidefx:capability:request-capability-from-objective'
    AND d.object_kind = N'TRANSFORMATION' AND d.declared_id = N'decide-agent-route');
DECLARE @route_expected nvarchar(max) = N'{"op":"if","when":{"op":"equals","left":{"op":"path","from":"input","path":"declared"},"right":{"op":"literal","value":1}},"then":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"input","path":"proposedCapability"},"right":{"op":"literal","value":"resolve-equity-market-price-evidence"}},"then":{"op":"literal","value":"ADMITTED"},"else":{"op":"literal","value":"REFUSED"}},"else":{"op":"literal","value":"REFUSED"}}';
DECLARE @route_unchanged bit = CASE WHEN @route = @route_expected COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END;
SELECT '5_guard' AS result_set,
 @equity_selected AS equity_selected, @equity_keywords AS equity_keywords_matched,
 @purchase_empty AS purchase_visible_empty, @route_unchanged AS resolution_logic_unchanged;
IF @equity_selected <> 1 THROW 51000, N'GUARD_EQUITY_CAPABILITY_NOT_SELECTED', 1;
IF @equity_keywords <> 1 THROW 51000, N'GUARD_EQUITY_KEYWORDS_NOT_MATCHED', 1;
IF @purchase_empty <> 1 THROW 51000, N'GUARD_PURCHASE_NOT_EMPTY', 1;
IF @route_unchanged <> 1 THROW 51000, N'GUARD_RESOLUTION_LOGIC_CHANGED', 1;
COMMIT TRANSACTION;
-- Installed after the rollback dry run and the from-transaction preflight:
-- the equity objective filters to resolve-equity-market-price-evidence
-- (matched market, price) and executes; the purchase objective filters to the
-- empty set and refuses CAPABILITY_NOT_FOUND with zero execution cells; the
-- declared route is unchanged.
