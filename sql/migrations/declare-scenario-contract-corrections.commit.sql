-- declare-scenario-contract-corrections.commit.sql
--
-- Corrects the nine divergent terminal invocations of the working set (evidence
-- doc section 5, op pks 51, 567, 1100, 1142, 1209, 1230, 1781, 1805, 3495) by
-- re-declaring each invoking scenario with its declared outcome contract
-- corrected to the invoked scenario's exit contract. The corrected contract id
-- is resolved from live rows: operation_scenario_invocation -> target
-- scenario_version -> scenario_outcome_contract -> contract, and the contract
-- must live in namespace sidefx:contracts; otherwise this migration stops
-- (SCENARIO_CORRECTION_TARGET_CONTRACT_NAMESPACE_UNEXPECTED) rather than
-- inventing one. The law is contract identity: the declaration resolves the
-- contract id to its estate-selected version, which for op 567's target
-- (authorized-narration-generation-request.v1) is 110810 while the target's own
-- scenario face still points at version 231 -- the same contract, and the
-- classification below counts contract identity, with version drift reported
-- separately.
--
-- The invoking authorities of these nine predate the installed declaration's
-- property order (their enveiope authority object is `id, operations,
-- owningScenarioId`; the installed body writes `id, owningScenarioId,
-- operations`), so a declaration would mint a second authority version and the
-- invoke-scenario binding gate would refuse it (their `$.scenarioId` values are
-- scenario ids, not capability ids). For each scenario the migration therefore
-- completes the declaration-canonical authority version first -- the exact
-- envelope the installed body computes for the same operations, with
-- execution_operation / operation_port_invocation /
-- operation_scenario_invocation copied from the live authority version. The
-- declaration then finds that version, makes no new one, and the working
-- scenario_event points at the declaration-described authority.
--
-- For op 3495 (scenario version 320) the live authority version 111992 carries
-- the hand-patch of repair-generate-executable-capability-scaffold-invoke-return
-- (`operations[15].outcomeContractId = scaffold-derivation-carrier.v1`). The
-- correction strips the per-operation outcome contract before completing the
-- authority, so the wired authority is declaration-description only; the old
-- patched version remains as a superseded row and its rows are reported.
--
-- Every declaration runs inside this one transaction. The whole migration is
-- idempotent: the loop runs twice and the second pass must produce zero row
-- deltas (the corrected declaration document is byte-stable). Classification is
-- read against the selected definition of each semantic object, so a corrected
-- scenario supersedes its old version in the working set.
--
-- COMMIT twin of declare-scenario-contract-corrections.sql.
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
-- ============================== BASELINE (selected definitions) ==============================
SET NOCOUNT ON;
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
WITH seldefs AS (
  SELECT d.semantic_object_pk, MAX(d.semantic_object_definition_pk) AS def_pk
  FROM model.estate_definition ed
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
  WHERE ed.estate_model_pk=@estate GROUP BY d.semantic_object_pk),
maxes AS (
  SELECT execution_authority_version_pk AS eav, MAX(ordinal) AS maxord
  FROM model.execution_operation GROUP BY execution_authority_version_pk),
occ AS (
  SELECT DISTINCT execution_authority_version_pk AS eav, scenario_version_pk AS isv
  FROM model.scenario_event WHERE execution_authority_version_pk IS NOT NULL),
x AS (
  SELECT i.execution_operation_pk AS op, e.execution_authority_version_pk AS eav, e.ordinal, m.maxord,
         o.isv AS isv, i.target_scenario_version_pk AS tsv,
         soci.contract_version_pk AS inv_cv, soct.contract_version_pk AS tgt_cv, icv.contract_pk AS inv_contract_pk, tcv.contract_pk AS tgt_contract_pk
  FROM model.operation_scenario_invocation i
  JOIN model.execution_operation e ON e.execution_operation_pk=i.execution_operation_pk
  JOIN maxes m ON m.eav=e.execution_authority_version_pk
  JOIN model.execution_authority_version eavx ON eavx.execution_authority_version_pk=e.execution_authority_version_pk
  LEFT JOIN occ o ON o.eav=e.execution_authority_version_pk
  LEFT JOIN model.scenario_version ivs ON ivs.scenario_version_pk=o.isv
  LEFT JOIN model.scenario_version tvs ON tvs.scenario_version_pk=i.target_scenario_version_pk
  LEFT JOIN model.scenario_outcome_contract soci ON soci.scenario_version_pk=o.isv
  LEFT JOIN model.contract_version icv ON icv.contract_version_pk=soci.contract_version_pk
  LEFT JOIN model.scenario_outcome_contract soct ON soct.scenario_version_pk=i.target_scenario_version_pk
  LEFT JOIN model.contract_version tcv ON tcv.contract_version_pk=soct.contract_version_pk
  WHERE e.ordinal=m.maxord
    AND EXISTS (SELECT 1 FROM seldefs se WHERE se.semantic_object_pk=eavx.semantic_object_pk AND se.def_pk=eavx.semantic_object_definition_pk)
    AND EXISTS (SELECT 1 FROM seldefs si WHERE si.semantic_object_pk=ivs.semantic_object_pk AND si.def_pk=ivs.semantic_object_definition_pk)
    AND EXISTS (SELECT 1 FROM seldefs st WHERE st.semantic_object_pk=tvs.semantic_object_pk AND st.def_pk=tvs.semantic_object_definition_pk))
SELECT 'B1_baseline_classification' AS result_set,
 CASE WHEN x.inv_cv IS NULL AND x.tgt_cv IS NULL THEN 'MISSING_BOTH'
      WHEN x.inv_cv IS NULL THEN 'MISSING_INVOKER'
      WHEN x.tgt_cv IS NULL THEN 'MISSING_TARGET'
      WHEN x.inv_contract_pk=x.tgt_contract_pk THEN 'CONSISTENT'
      ELSE 'DIVERGENT' END AS class,
 COUNT(*) AS pairs, COUNT(DISTINCT x.op) AS ops, SUM(CASE WHEN x.inv_cv=x.tgt_cv THEN 1 ELSE 0 END) AS version_consistent, SUM(CASE WHEN x.inv_cv IS NULL OR x.tgt_cv IS NULL OR x.inv_cv<>x.tgt_cv THEN 1 ELSE 0 END) AS version_drift
FROM x
GROUP BY CASE WHEN x.inv_cv IS NULL AND x.tgt_cv IS NULL THEN 'MISSING_BOTH'
      WHEN x.inv_cv IS NULL THEN 'MISSING_INVOKER'
      WHEN x.tgt_cv IS NULL THEN 'MISSING_TARGET'
      WHEN x.inv_contract_pk=x.tgt_contract_pk THEN 'CONSISTENT'
      ELSE 'DIVERGENT' END
ORDER BY class;
GO
-- ============================== CORRECTIONS (one declaration per scenario, two passes) ==============================
SET NOCOUNT ON;
SET XACT_ABORT OFF;
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
IF OBJECT_ID('tempdb..#snaptable') IS NOT NULL DROP TABLE #snaptable;
CREATE TABLE #snaptable(k nvarchar(120) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY);
INSERT #snaptable(k) VALUES
 (N'source.content_object'),(N'model.semantic_object'),(N'model.semantic_object_definition'),(N'model.estate_definition'),
 (N'model.execution_authority'),(N'model.execution_authority_version'),(N'model.execution_operation'),
 (N'model.operation_port_invocation'),(N'model.operation_scenario_invocation'),(N'model.scenario'),
 (N'model.scenario_version'),(N'model.scenario_input'),(N'model.scenario_event'),(N'model.scenario_outcome'),
 (N'model.scenario_outcome_contract'),(N'model.outcome_variant'),(N'model.capability_scenario'),
 (N'model.capability_root_scenario'),(N'model.port'),(N'model.port_version'),(N'model.contract_version');
IF OBJECT_ID('tempdb..#snap') IS NOT NULL DROP TABLE #snap;
CREATE TABLE #snap(phase varchar(12) NOT NULL, k nvarchar(120) COLLATE Latin1_General_100_BIN2 NOT NULL, n bigint NOT NULL);
DECLARE @snap_parts nvarchar(max)=(
 SELECT STRING_AGG(N'SELECT @phase AS phase,N'''+k+N''' AS k,COUNT(*) AS n FROM '+k,N' UNION ALL ') WITHIN GROUP (ORDER BY k)
 FROM #snaptable);
DECLARE @snap_statement nvarchar(max)=N'INSERT #snap(phase,k,n) '+@snap_parts;
IF OBJECT_ID('tempdb..#nine') IS NOT NULL DROP TABLE #nine;
CREATE TABLE #nine(op bigint NOT NULL PRIMARY KEY);
INSERT #nine(op) VALUES (51),(567),(1100),(1142),(1209),(1230),(1781),(1805),(3495);
IF OBJECT_ID('tempdb..#c2') IS NOT NULL DROP TABLE #c2;
CREATE TABLE #c2(op bigint NOT NULL PRIMARY KEY, cap_id nvarchar(400) NOT NULL, scenario_id nvarchar(400) NOT NULL,
 old_sv bigint NOT NULL, eav bigint NOT NULL, maxord int NOT NULL, terminal_kind nvarchar(100) NULL,
 out_contract nvarchar(400) NULL, out_cv bigint NULL, contract_namespace nvarchar(400) NULL,
 name nvarchar(max) NULL, input_id nvarchar(400) NULL, input_contract nvarchar(400) NULL,
 event_id nvarchar(400) NULL, authority nvarchar(400) NULL, outcome_id nvarchar(400) NULL,
 terminal bit NOT NULL, is_root bit NOT NULL, given_text nvarchar(max) NULL, when_text nvarchar(max) NULL,
 then_text nvarchar(max) NULL, ops nvarchar(max) NULL, ports nvarchar(max) NULL);
IF OBJECT_ID('tempdb..#corr') IS NOT NULL DROP TABLE #corr;
CREATE TABLE #corr(pass int NOT NULL, op bigint NOT NULL, cap_id nvarchar(400) NOT NULL, scenario_id nvarchar(400) NOT NULL,
 prior_sv bigint NOT NULL, wired_sv bigint NOT NULL, corrected_contract nvarchar(400) NOT NULL,
 PRIMARY KEY(pass,op));
EXEC sp_executesql @snap_statement,N'@phase varchar(12)',@phase='p0';
DECLARE @pass int=1;
WHILE @pass<=2
BEGIN
 DELETE #c2;
 INSERT #c2(op,cap_id,scenario_id,old_sv,eav,maxord,terminal_kind,out_contract,out_cv,contract_namespace,name,input_id,input_contract,event_id,authority,outcome_id,terminal,is_root,given_text,when_text,then_text,ops,ports)
 SELECT n.op, c.capability_id, s.scenario_id, sv.scenario_version_pk, eav.execution_authority_version_pk, mx.maxord,
  JSON_VALUE(avenv.content_bytes_text,'$.semantics.authority.operations['+CAST(mx.maxord AS nvarchar(10))+'].kind'),
  ct.contract_id, soct.contract_version_pk, tn.namespace_id,
  sv.name, si.input_id, cti.contract_id, se.event_id, ea.execution_authority_id, so.outcome_id, so.terminal,
  CASE WHEN EXISTS (SELECT 1 FROM model.capability_root_scenario rs
    JOIN model.estate_capability rec ON rec.capability_version_pk=rs.capability_version_pk AND rec.estate_model_pk=@estate
    WHERE rs.scenario_pk=s.scenario_pk) THEN 1 ELSE 0 END,
  JSON_VALUE(svenv.content_bytes_text,'$.semantics.scenario.steps[0].text'),
  JSON_VALUE(svenv.content_bytes_text,'$.semantics.scenario.steps[1].text'),
  JSON_VALUE(svenv.content_bytes_text,'$.semantics.scenario.steps[2].text'),
  JSON_QUERY(avenv.content_bytes_text,'$.semantics.authority.operations'),
  (SELECT N'['+STRING_AGG(JSON_QUERY(penv.content_bytes_text,'$.semantics'),N',') WITHIN GROUP (ORDER BY peo.ordinal)+N']'
   FROM model.operation_port_invocation popi
   JOIN model.execution_operation peo ON peo.execution_operation_pk=popi.execution_operation_pk
   JOIN model.port_version ppv ON ppv.port_version_pk=popi.port_version_pk
   JOIN model.semantic_object_definition psd ON psd.semantic_object_definition_pk=ppv.semantic_object_definition_pk
   JOIN source.content_object pco ON pco.content_object_pk=psd.canonical_content_pk
   CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),pco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) content_bytes_text) penv
   WHERE peo.execution_authority_version_pk=eav.execution_authority_version_pk)
 FROM #nine n
 JOIN model.execution_operation eo ON eo.execution_operation_pk=n.op
 JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
 JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
 JOIN (SELECT execution_authority_version_pk AS eav, MAX(ordinal) AS maxord FROM model.execution_operation GROUP BY execution_authority_version_pk) mx
  ON mx.eav=eav.execution_authority_version_pk
 JOIN (SELECT DISTINCT execution_authority_version_pk AS eav, scenario_version_pk AS isv FROM model.scenario_event WHERE execution_authority_version_pk IS NOT NULL) occ
  ON occ.eav=eav.execution_authority_version_pk
 JOIN model.scenario_version sv ON sv.scenario_version_pk=occ.isv
 JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
 JOIN model.capability c ON c.capability_pk=s.capability_pk
 JOIN model.scenario_input si ON si.scenario_version_pk=sv.scenario_version_pk
 JOIN model.contract_version icv ON icv.contract_version_pk=si.input_contract_version_pk
 JOIN model.contract cti ON cti.contract_pk=icv.contract_pk
 JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
 JOIN model.execution_authority ea ON ea.execution_authority_pk=eav.execution_authority_pk
 JOIN model.scenario_outcome so ON so.scenario_version_pk=sv.scenario_version_pk
 JOIN model.scenario_outcome_contract soct ON soct.scenario_version_pk=osi.target_scenario_version_pk
 JOIN model.contract_version tcv ON tcv.contract_version_pk=soct.contract_version_pk
 JOIN model.contract ct ON ct.contract_pk=tcv.contract_pk
 JOIN model.identity_namespace tn ON tn.namespace_pk=ct.namespace_pk
 JOIN model.semantic_object_definition avsd ON avsd.semantic_object_definition_pk=eav.semantic_object_definition_pk
 JOIN source.content_object avco ON avco.content_object_pk=avsd.canonical_content_pk
 CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),avco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) content_bytes_text) avenv
 JOIN model.semantic_object_definition svsd ON svsd.semantic_object_definition_pk=sv.semantic_object_definition_pk
 JOIN source.content_object svco ON svco.content_object_pk=svsd.canonical_content_pk
 CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),svco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) content_bytes_text) svenv;
 IF EXISTS (SELECT 1 FROM #c2 WHERE out_contract IS NULL) THROW 51000,'SCENARIO_CORRECTION_TARGET_CONTRACT_NOT_DECLARED',1;
 IF EXISTS (SELECT 1 FROM #c2 WHERE contract_namespace IS NULL OR contract_namespace<>N'sidefx:contracts') THROW 51000,'SCENARIO_CORRECTION_TARGET_CONTRACT_NAMESPACE_UNEXPECTED',1;
 IF EXISTS (SELECT 1 FROM #c2 WHERE terminal_kind IS NULL OR terminal_kind<>N'invoke-scenario') THROW 51000,'SCENARIO_CORRECTION_TERMINAL_NOT_INVOKE_SCENARIO',1;
 DECLARE @op bigint,@cap_id nvarchar(400),@scenario_id nvarchar(400),@old_sv bigint,@eav bigint,@maxord int;
 DECLARE @out_contract nvarchar(400),@name nvarchar(max),@input_id nvarchar(400),@input_contract nvarchar(400);
 DECLARE @event_id nvarchar(400),@authority nvarchar(400),@outcome_id nvarchar(400),@terminal bit,@is_root bit;
 DECLARE @given nvarchar(max),@when_text nvarchar(max),@then_text nvarchar(max),@ops nvarchar(max),@ports nvarchar(max);
 DECLARE @semantics nvarchar(max),@pobj bigint,@pdef bigint,@pdigest binary(32),@seed_eav bigint,@auth_namespace nvarchar(400);
 DECLARE @doc nvarchar(max),@new_sv bigint;
 DECLARE @work CURSOR;
 SET @work=CURSOR LOCAL FAST_FORWARD FOR SELECT op FROM #c2 ORDER BY op;
 OPEN @work;
 FETCH NEXT FROM @work INTO @op;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SELECT @cap_id=cap_id,@scenario_id=scenario_id,@old_sv=old_sv,@eav=eav,@maxord=maxord,
   @out_contract=out_contract,@name=name,@input_id=input_id,@input_contract=input_contract,
   @event_id=event_id,@authority=authority,@outcome_id=outcome_id,@terminal=terminal,@is_root=is_root,
   @given=given_text,@when_text=when_text,@then_text=then_text,@ops=ops,@ports=COALESCE(ports,N'[]')
  FROM #c2 WHERE op=@op;
  -- withdraw the per-operation outcome contract (the scaffold hand-patch) so the
  -- completed authority is exactly the declaration's description
  IF JSON_VALUE(@ops,N'$['+CAST(@maxord AS nvarchar(10))+N'].outcomeContractId') IS NOT NULL
   SET @ops=JSON_MODIFY(@ops,N'$['+CAST(@maxord AS nvarchar(10))+N'].outcomeContractId',NULL);
  -- complete the declaration-canonical authority version when the estate only
  -- carries the pre-declaration envelope order
  SET @semantics=(SELECT @authority AS [authority.id],@scenario_id AS [authority.owningScenarioId],JSON_QUERY(@ops) AS [authority.operations] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @auth_namespace=N'sidefx:capability:'+@cap_id;
  EXEC model.put_semantic_definition 'EXECUTION_AUTHORITY',@auth_namespace,@authority,@semantics,@pobj OUTPUT,@pdef OUTPUT,@pdigest OUTPUT;
  SET @seed_eav=(SELECT execution_authority_version_pk FROM model.execution_authority_version WHERE semantic_object_definition_pk=@pdef);
  IF @seed_eav IS NULL
  BEGIN
   INSERT model.execution_authority_version(execution_authority_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,authority_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   SELECT eav.execution_authority_pk,eav.semantic_object_pk,@pdef,@pdigest,eav.authority_profile,eav.object_kind,@pdef,eav._canonical_pointer
   FROM model.execution_authority_version eav WHERE eav.execution_authority_version_pk=@eav;
   SET @seed_eav=SCOPE_IDENTITY();
   INSERT model.execution_operation(execution_authority_version_pk,operation_id,ordinal,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT @seed_eav,eo.operation_id,eo.ordinal,eo.operation_kind,@pdef,eo._canonical_pointer
   FROM model.execution_operation eo WHERE eo.execution_authority_version_pk=@eav;
   INSERT model.operation_port_invocation(execution_operation_pk,port_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT newop.execution_operation_pk,opi.port_version_pk,opi.operation_kind,@pdef,opi._canonical_pointer
   FROM model.operation_port_invocation opi
   JOIN model.execution_operation oldop ON oldop.execution_operation_pk=opi.execution_operation_pk AND oldop.execution_authority_version_pk=@eav
   JOIN model.execution_operation newop ON newop.execution_authority_version_pk=@seed_eav AND newop.ordinal=oldop.ordinal;
   INSERT model.operation_scenario_invocation(execution_operation_pk,target_scenario_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT newop.execution_operation_pk,osi.target_scenario_version_pk,osi.operation_kind,@pdef,osi._canonical_pointer
   FROM model.operation_scenario_invocation osi
   JOIN model.execution_operation oldop ON oldop.execution_operation_pk=osi.execution_operation_pk AND oldop.execution_authority_version_pk=@eav
   JOIN model.execution_operation newop ON newop.execution_authority_version_pk=@seed_eav AND newop.ordinal=oldop.ordinal;
  END
  SET @doc=(SELECT @scenario_id AS scenarioId,@name AS name,@input_id AS inputId,@input_contract AS inputContract,
   @event_id AS eventId,@authority AS eventAuthority,@outcome_id AS outcomeId,@out_contract AS outcomeContract,
   CONVERT(bit,@terminal) AS [terminal],CONVERT(bit,@is_root) AS [root],@given AS [given],@when_text AS [when],@then_text AS [then]
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  BEGIN TRY
   EXEC model.declare_scenario @capability_id=@cap_id,@scenario=@doc,@operations=@ops,@port_bindings=@ports;
  END TRY
  BEGIN CATCH
   DECLARE @diagmsg nvarchar(2048)=N'SCENARIO_CORRECTION_REFUSED_OP_'+CONVERT(nvarchar(20),@op)+N'_'+ERROR_MESSAGE();
   THROW 51000,@diagmsg,1;
  END CATCH;
  SET @new_sv=(SELECT cs.scenario_version_pk FROM model.capability c
   JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
   JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
   JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
   WHERE c.capability_id=@cap_id AND s.scenario_id=@scenario_id);
  INSERT #corr VALUES(@pass,@op,@cap_id,@scenario_id,@old_sv,@new_sv,@out_contract);
  FETCH NEXT FROM @work INTO @op;
 END
 CLOSE @work;
 DEALLOCATE @work;
 IF @pass=1 EXEC sp_executesql @snap_statement,N'@phase varchar(12)',@phase='p1';
 SET @pass=@pass+1;
END
EXEC sp_executesql @snap_statement,N'@phase varchar(12)',@phase='p2';
SELECT 'C1_corrections' AS result_set, c.pass, c.op, c.cap_id, c.scenario_id,
 (SELECT ct.contract_id FROM model.scenario_outcome_contract soc
  JOIN model.contract_version cv ON cv.contract_version_pk=soc.contract_version_pk
  JOIN model.contract ct ON ct.contract_pk=cv.contract_pk WHERE soc.scenario_version_pk=c.prior_sv) AS prior_contract,
 c.corrected_contract, c.prior_sv, c.wired_sv,
 (SELECT COUNT(*) FROM model.scenario_version sv WHERE sv.scenario_version_pk=c.wired_sv) AS wired_sv_exists
FROM #corr c ORDER BY c.pass, c.op;
SELECT 'C2_pass_deltas' AS result_set,
 (SELECT SUM(n) FROM #snap WHERE phase='p0') AS rows_before_pass1,
 (SELECT SUM(n) FROM #snap WHERE phase='p1') AS rows_after_pass1,
 (SELECT COUNT(*) FROM #snap b JOIN #snap a ON a.k=b.k WHERE b.phase='p0' AND a.phase='p1' AND a.n<>b.n) AS tables_changed_pass1,
 (SELECT SUM(n) FROM #snap WHERE phase='p2') AS rows_after_pass2,
 (SELECT COUNT(*) FROM #snap b JOIN #snap a ON a.k=b.k WHERE b.phase='p1' AND a.phase='p2' AND a.n<>b.n) AS tables_changed_pass2;
GO
-- ============================== POST-CORRECTION CLASSIFICATION ==============================
SET NOCOUNT ON;
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
WITH seldefs AS (
  SELECT d.semantic_object_pk, MAX(d.semantic_object_definition_pk) AS def_pk
  FROM model.estate_definition ed
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
  WHERE ed.estate_model_pk=@estate GROUP BY d.semantic_object_pk),
maxes AS (
  SELECT execution_authority_version_pk AS eav, MAX(ordinal) AS maxord
  FROM model.execution_operation GROUP BY execution_authority_version_pk),
occ AS (
  SELECT DISTINCT execution_authority_version_pk AS eav, scenario_version_pk AS isv
  FROM model.scenario_event WHERE execution_authority_version_pk IS NOT NULL),
x AS (
  SELECT i.execution_operation_pk AS op, e.execution_authority_version_pk AS eav, e.ordinal, m.maxord,
         o.isv AS isv, i.target_scenario_version_pk AS tsv,
         soci.contract_version_pk AS inv_cv, soct.contract_version_pk AS tgt_cv, icv.contract_pk AS inv_contract_pk, tcv.contract_pk AS tgt_contract_pk
  FROM model.operation_scenario_invocation i
  JOIN model.execution_operation e ON e.execution_operation_pk=i.execution_operation_pk
  JOIN maxes m ON m.eav=e.execution_authority_version_pk
  JOIN model.execution_authority_version eavx ON eavx.execution_authority_version_pk=e.execution_authority_version_pk
  LEFT JOIN occ o ON o.eav=e.execution_authority_version_pk
  LEFT JOIN model.scenario_version ivs ON ivs.scenario_version_pk=o.isv
  LEFT JOIN model.scenario_version tvs ON tvs.scenario_version_pk=i.target_scenario_version_pk
  LEFT JOIN model.scenario_outcome_contract soci ON soci.scenario_version_pk=o.isv
  LEFT JOIN model.contract_version icv ON icv.contract_version_pk=soci.contract_version_pk
  LEFT JOIN model.scenario_outcome_contract soct ON soct.scenario_version_pk=i.target_scenario_version_pk
  LEFT JOIN model.contract_version tcv ON tcv.contract_version_pk=soct.contract_version_pk
  WHERE e.ordinal=m.maxord
    AND EXISTS (SELECT 1 FROM seldefs se WHERE se.semantic_object_pk=eavx.semantic_object_pk AND se.def_pk=eavx.semantic_object_definition_pk)
    AND EXISTS (SELECT 1 FROM seldefs si WHERE si.semantic_object_pk=ivs.semantic_object_pk AND si.def_pk=ivs.semantic_object_definition_pk)
    AND EXISTS (SELECT 1 FROM seldefs st WHERE st.semantic_object_pk=tvs.semantic_object_pk AND st.def_pk=tvs.semantic_object_definition_pk))
SELECT 'C3_final_classification' AS result_set,
 CASE WHEN x.inv_cv IS NULL AND x.tgt_cv IS NULL THEN 'MISSING_BOTH'
      WHEN x.inv_cv IS NULL THEN 'MISSING_INVOKER'
      WHEN x.tgt_cv IS NULL THEN 'MISSING_TARGET'
      WHEN x.inv_contract_pk=x.tgt_contract_pk THEN 'CONSISTENT'
      ELSE 'DIVERGENT' END AS class,
 COUNT(*) AS pairs, COUNT(DISTINCT x.op) AS ops, SUM(CASE WHEN x.inv_cv=x.tgt_cv THEN 1 ELSE 0 END) AS version_consistent, SUM(CASE WHEN x.inv_cv IS NULL OR x.tgt_cv IS NULL OR x.inv_cv<>x.tgt_cv THEN 1 ELSE 0 END) AS version_drift
FROM x
GROUP BY CASE WHEN x.inv_cv IS NULL AND x.tgt_cv IS NULL THEN 'MISSING_BOTH'
      WHEN x.inv_cv IS NULL THEN 'MISSING_INVOKER'
      WHEN x.tgt_cv IS NULL THEN 'MISSING_TARGET'
      WHEN x.inv_contract_pk=x.tgt_contract_pk THEN 'CONSISTENT'
      ELSE 'DIVERGENT' END
ORDER BY class;
GO
-- ============================== SCENARIO 320 WIRING (hand-patch withdrawn) ==============================
SET NOCOUNT ON;
SELECT 'C4_wiring_320' AS result_set, c.op, c.scenario_id, c.prior_sv, c.wired_sv, c.corrected_contract,
 oldeav.execution_authority_version_pk AS old_authority_version,
 JSON_VALUE(oldenv.content_bytes_text,'$.semantics.authority.operations[15].outcomeContractId') AS old_operation16_outcome_contract,
 LOWER(CONVERT(varchar(64),oldeav.definition_digest,2)) AS old_authority_digest,
 (SELECT COUNT(*) FROM model.scenario_event ose WHERE ose.execution_authority_version_pk=oldeav.execution_authority_version_pk) AS old_event_refs,
 neweav.execution_authority_version_pk AS new_authority_version,
 JSON_VALUE(newenv.content_bytes_text,'$.semantics.authority.operations[15].outcomeContractId') AS new_operation16_outcome_contract,
 LOWER(CONVERT(varchar(64),neweav.definition_digest,2)) AS new_authority_digest,
 (SELECT COUNT(*) FROM model.scenario_event nse WHERE nse.execution_authority_version_pk=neweav.execution_authority_version_pk) AS new_event_refs,
 CASE WHEN newenv.content_bytes_text LIKE N'%outcomeContractId%' THEN 1 ELSE 0 END AS new_envelope_any_operation_contract
FROM #corr c
JOIN model.scenario_event ose ON ose.scenario_version_pk=c.prior_sv
JOIN model.execution_authority_version oldeav ON oldeav.execution_authority_version_pk=ose.execution_authority_version_pk
JOIN model.semantic_object_definition oldsd ON oldsd.semantic_object_definition_pk=oldeav.semantic_object_definition_pk
JOIN source.content_object oldco ON oldco.content_object_pk=oldsd.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),oldco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) content_bytes_text) oldenv
JOIN model.scenario_event nse ON nse.scenario_version_pk=c.wired_sv
JOIN model.execution_authority_version neweav ON neweav.execution_authority_version_pk=nse.execution_authority_version_pk
JOIN model.semantic_object_definition newsd ON newsd.semantic_object_definition_pk=neweav.semantic_object_definition_pk
JOIN source.content_object newco ON newco.content_object_pk=newsd.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),newco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) content_bytes_text) newenv
WHERE c.op=3495 AND c.pass=2;
GO
-- ============================== REPORT ==============================
SET NOCOUNT ON;
SELECT 'C5_unproven' AS result_set,
 (SELECT COUNT(*) FROM #corr WHERE pass=1) AS pass1_declarations,
 (SELECT COUNT(*) FROM #corr WHERE pass=2) AS pass2_replays,
 (SELECT COUNT(*) FROM #corr WHERE pass=1 AND prior_sv<>wired_sv) AS scenarios_superseded,
 (SELECT COUNT(*) FROM #corr WHERE pass=1 AND corrected_contract IS NULL) AS unresolved_target_contracts;
COMMIT TRANSACTION;
