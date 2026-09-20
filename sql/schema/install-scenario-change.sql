-- Bound installer for the admitted scenario-registration kind. The caller owns
-- its serializable transaction and restoring guard scope. Admission is resolved
-- from the selected data-access authority before this procedure is entered.
CREATE OR ALTER PROCEDURE model.install_scenario_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'SCENARIO_CHANGE_TRANSACTION_REQUIRED',1;
 IF ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'scenario-registration-change.v1'
  THROW 51000,'SCENARIO_CHANGE_DOCUMENT_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @capability nvarchar(400)=JSON_VALUE(@document,'$.capabilityId');
 DECLARE @scenario nvarchar(max)=JSON_QUERY(@document,'$.scenario');
 DECLARE @scenario_id nvarchar(400)=JSON_VALUE(@scenario,'$.scenarioId');
 DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability;
 DECLARE @receipt_id nvarchar(400)=@scenario_id+N'.change.v1';
 DECLARE @prior nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics.document')
  FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=@estate
  AND object_kind='AUTHORITY' AND namespace_id=@namespace AND declared_id=@receipt_id);
 IF @prior IS NOT NULL
 BEGIN
  IF @prior COLLATE Latin1_General_100_BIN2<>@document COLLATE Latin1_General_100_BIN2
   THROW 51000,'SCENARIO_CHANGE_REVISION_NOT_ADMITTED',1;
  SELECT N'already_installed' AS result_set,@capability AS capability_id,@scenario_id AS scenario_id;
  RETURN;
 END;
 DECLARE @operations nvarchar(max)=JSON_QUERY(@document,'$.operations');
 -- Reuse the selected binding's original semantics bytes. The admitted payload
 -- names this existing binding; registration does not revise its configuration.
 DECLARE @ports nvarchar(max)=N'['+(SELECT JSON_QUERY(definition_json,'$.semantics')
  FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=@estate AND object_kind='PORT'
  AND namespace_id=@namespace AND declared_id=JSON_VALUE(@document,'$.portBindings[0].portId'))+N']';
 IF @ports IS NULL THROW 51000,'SCENARIO_CHANGE_PORT_NOT_DECLARED',1;
 DECLARE @declared TABLE(declared_scenario nvarchar(400),scenario_version_pk bigint);
 INSERT @declared EXEC model.declare_scenario @capability,@scenario,@operations,@ports;

 -- These fixtures belong to the registered scenario, not the capability's root
 -- fixture suite. Root-only consumers must not run them against another scenario.
 DECLARE @owner bigint=(SELECT sv.semantic_object_definition_pk FROM model.scenario_version sv
  JOIN @declared d ON d.scenario_version_pk=sv.scenario_version_pk);
 DECLARE @owner_digest varchar(64)=(SELECT LOWER(CONVERT(varchar(64),definition_digest,2)) FROM model.semantic_object_definition
  WHERE semantic_object_definition_pk=@owner);
 DECLARE @fixture nvarchar(max),@fixture_id nvarchar(400),@semantics nvarchar(max),@object bigint,@definition bigint,@digest binary(32);
 DECLARE fixtures CURSOR LOCAL FAST_FORWARD FOR SELECT value FROM OPENJSON(@document,'$.fixtures');
 OPEN fixtures;
 FETCH NEXT FROM fixtures INTO @fixture;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @fixture_id=JSON_VALUE(@fixture,'$.fixtureId');
  SET @semantics=(SELECT @owner_digest AS owner_definition_digest,JSON_QUERY(@fixture) AS fixture FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC model.put_semantic_definition 'FIXTURE',@namespace,@fixture_id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
  IF EXISTS(SELECT 1 FROM model.fixture WHERE owner_definition_pk=@owner AND fixture_id=@fixture_id)
   THROW 51000,'SCENARIO_CHANGE_FIXTURE_ALREADY_OWNED',1;
  INSERT model.fixture(owner_definition_pk,fixture_id,fixture_profile,semantic_object_pk,semantic_object_definition_pk,namespace_pk,
    definition_digest,object_kind,_owner_definition_pk,_canonical_pointer)
   SELECT @owner,@fixture_id,'consumer-capability-fixtures.v1',@object,@definition,namespace_pk,@digest,'FIXTURE',@definition,N''
   FROM model.semantic_object WHERE semantic_object_pk=@object;
  FETCH NEXT FROM fixtures INTO @fixture;
 END;
 CLOSE fixtures;
 DEALLOCATE fixtures;
 SET @semantics=(SELECT JSON_QUERY(@document) AS document FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC model.put_semantic_definition 'AUTHORITY',@namespace,@receipt_id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 SELECT N'scenario_change_installed' AS result_set,@capability AS capability_id,@scenario_id AS scenario_id;
END;
