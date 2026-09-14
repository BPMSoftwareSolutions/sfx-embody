-- LANE B TIER 3: delete two fully orphaned estate-module PROVIDER rows.
--   authority-read-provider.readCapabilityAuthority (src/resolvers/node/authority-read-provider.mjs)
--   read-authority.readAuthority                       (src/read-authority.mjs)
-- No selected PORT references either provider id in any JSON field; the guard
-- refuses the delete if one appears. Idempotent: a second run removes nothing.
--
-- Default: ROLLBACK. Replace the final ROLLBACK with COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
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
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @ids TABLE (provider_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @ids (provider_id) VALUES
 (N'authority-read-provider.readCapabilityAuthority'),
 (N'read-authority.readAuthority');

-- Guard: a selected PORT must not name either provider id in any JSON field.
DECLARE @referencing_ports int=(
 SELECT COUNT_BIG(*)
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
   AND EXISTS (SELECT 1 FROM @ids i WHERE d.definition_json LIKE N'%'+(i.provider_id COLLATE Latin1_General_100_BIN2_UTF8)+N'%'));
IF @referencing_ports>0 THROW 51000,'PROVIDER_STILL_REFERENCED_BY_SELECTED_PORT',1;

SELECT 'before_delete' AS result_set, p.provider_id, p.provider_pk,
 (SELECT COUNT(*) FROM model.provider_definition pd WHERE pd.provider_pk=p.provider_pk) AS provider_definitions,
 (SELECT COUNT(*) FROM model.provider_binding b JOIN model.provider_definition pd ON pd.provider_definition_pk=b.provider_definition_pk WHERE pd.provider_pk=p.provider_pk) AS bindings
FROM model.provider p WHERE p.provider_id IN (SELECT provider_id FROM @ids);

DELETE pd
FROM model.provider_definition pd
JOIN model.provider p ON p.provider_pk=pd.provider_pk
WHERE p.provider_id IN (SELECT provider_id FROM @ids);

DELETE p FROM model.provider p WHERE p.provider_id IN (SELECT provider_id FROM @ids);

SELECT 'after_delete' AS result_set, COUNT(*) AS providers_remaining
FROM model.provider WHERE provider_id IN (SELECT provider_id FROM @ids);
SELECT 'referencing_ports' AS result_set, @referencing_ports AS selected_ports_naming_provider;
COMMIT TRANSACTION;
