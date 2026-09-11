# Appendix for the canonical feature migration strategy

This appendix reproduces every figure cited by
[Canonical feature writeups: reconciliation and migration strategy](../../canonical-feature-migration-gap.md).
Each query was executed against selected model 34 and returns the figure it is
cited for. Each is standalone: paste it into SSMS and run it.

## 11. SQL for every finding

All of them resolve the selected model themselves:

```sql
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
```

`source.current_model` is the single selected generation. A different selected
generation returns different figures; compare pins before comparing counts (§2).

### 11.1 Inventory — 220 managed identities / 228 versions; 290 / 313 with non-managed platform (§2)

```sql
SELECT n.namespace_id,
       COUNT(DISTINCT c.capability_pk)   AS identities,
       COUNT(cv.capability_version_pk)   AS versions
FROM model.capability c
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
LEFT JOIN model.capability_version cv ON cv.capability_pk = c.capability_pk
GROUP BY n.namespace_id
ORDER BY identities DESC;
```

Returns `sidefx:capabilities` 220 / 228 and `sidefx:platform-capabilities`
70 / 85. The managed row is the migration inventory; the platform row is not.

### 11.2 The `.v1` / `.v2` catalog rows (§2.1)

The rows that prompted this section, and the reason they are excluded:

```sql
SELECT n.namespace_id, c.capability_id
FROM model.capability c
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
WHERE c.capability_id LIKE '%.v%'
ORDER BY c.capability_id;
```

All 70 are in `sidefx:platform-capabilities`; none is in `sidefx:capabilities`.

```sql
-- 68 identities end .v1 and 2 end .v2; 83 and 2 versions respectively
SELECT n.namespace_id,
       SUM(CASE WHEN c.capability_id LIKE '%.v1' THEN 1 ELSE 0 END) AS ends_v1,
       SUM(CASE WHEN c.capability_id LIKE '%.v2' THEN 1 ELSE 0 END) AS ends_v2,
       COUNT(*) AS identities
FROM model.capability c
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
WHERE c.capability_id LIKE '%.v%'
GROUP BY n.namespace_id;
```

```sql
-- 0: the catalog rows own no Scenario, so they cannot carry a canonical feature
SELECT COUNT(*) AS owned_scenarios
FROM model.capability c
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
JOIN model.capability_version cv ON cv.capability_pk = c.capability_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk = cv.capability_version_pk
WHERE n.namespace_id = 'sidefx:platform-capabilities';
```

```sql
-- 0: no managed identity is unselected, so the 70 unselected rows are all catalog
SELECT COUNT(*) AS unselected_managed
FROM model.capability c
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
WHERE n.namespace_id = 'sidefx:capabilities'
  AND NOT EXISTS (SELECT 1 FROM model.estate_capability ec
                  WHERE ec.capability_pk = c.capability_pk AND ec.estate_model_pk = @model);
```

**Before removing or reclassifying these rows, note what depends on them.** All
85 provider implementations bind to the catalog, and 25 of the 70 are named
directly by a selected PORT definition:

```sql
-- 85 provider implementations, every one against sidefx:platform-capabilities
SELECT n.namespace_id, COUNT(*) AS provider_implementations
FROM model.provider_capability_implementation pci
JOIN model.capability_version cv ON cv.capability_version_pk = pci.capability_version_pk
JOIN model.capability c ON c.capability_pk = cv.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
GROUP BY n.namespace_id;
```

```sql
-- the 25 catalog rows a selected PORT names, with how many providers implement each
SELECT c.capability_id,
       (SELECT COUNT(*) FROM model.provider_capability_implementation pci
        JOIN model.capability_version cv ON cv.capability_version_pk = pci.capability_version_pk
        WHERE cv.capability_pk = c.capability_pk) AS provider_implementations
FROM model.capability c
WHERE EXISTS (
    SELECT 1 FROM analysis.v_selected_semantic_definition d
    WHERE d.estate_model_pk = @model AND d.object_kind = 'PORT'
      AND JSON_VALUE(d.definition_json, '$.semantics.platformCapabilityId')
          COLLATE Latin1_General_100_BIN2 = c.capability_id)
ORDER BY c.capability_id;
```

The remaining 45 are named by no selected port and carry 55 provider
implementations between them. The port to platform capability to provider to
mechanic chain is the only route from a scenario to its mechanics today, so
reclassification has to preserve that binding, not just drop the rows.

### 11.3 The corpus, read from the database (§2)

The retained feature bytes reproduce every corpus figure without touching the
filesystem. `source_class = 'REPOSITORY_TRACKED'` pins one revision per path —
**without it the raw counts inflate**, because several paths retain more than one
revision (1,277 tags instead of 1,041). Distinct counts are unaffected.

```sql
WITH retained AS (
    SELECT DISTINCT a.source_path, CONVERT(varchar(max), co.content_bytes) AS text
    FROM source.source_appearance a
    JOIN source.content_object co ON co.content_object_pk = a.content_object_pk
    JOIN source.estate_model m ON m.estate_snapshot_pk = a.estate_snapshot_pk
     AND m.estate_model_pk = @model
    WHERE a.source_path LIKE 'features/%.feature'
      AND a.source_class = 'REPOSITORY_TRACKED'
), lines AS (
    SELECT r.source_path, LTRIM(RTRIM(REPLACE(value, CHAR(13), ''))) AS line
    FROM retained r CROSS APPLY STRING_SPLIT(r.text, CHAR(10))
)
SELECT (SELECT COUNT(DISTINCT source_path) FROM retained)                                         AS files,
       (SELECT COUNT(*) FROM lines WHERE line LIKE '@capability:%')                               AS capability_tags,
       (SELECT COUNT(DISTINCT SUBSTRING(line,13,400)) FROM lines WHERE line LIKE '@capability:%')  AS distinct_capability_ids,
       (SELECT COUNT(*) FROM lines WHERE line LIKE '@scenario:%')                                 AS scenario_tags,
       (SELECT COUNT(DISTINCT SUBSTRING(line,11,400)) FROM lines WHERE line LIKE '@scenario:%')    AS distinct_scenario_ids,
       (SELECT COUNT(*) FROM lines WHERE line LIKE 'Scenario:%')                                  AS scenario_blocks;
```

Returns 235 / 234 / 233 / 1,041 / 1,028 / 1,053 — the §2 baseline exactly.

### 11.4 Groups A–D (§2.2)

One shared preamble; each group is the query that follows it.

```sql
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
WITH retained AS (
    SELECT DISTINCT a.source_path, CONVERT(varchar(max), co.content_bytes) AS text
    FROM source.source_appearance a
    JOIN source.content_object co ON co.content_object_pk = a.content_object_pk
    JOIN source.estate_model m ON m.estate_snapshot_pk = a.estate_snapshot_pk
     AND m.estate_model_pk = @model
    WHERE a.source_path LIKE 'features/%.feature' AND a.source_class = 'REPOSITORY_TRACKED'
), lines AS (
    SELECT r.source_path, LTRIM(RTRIM(REPLACE(value, CHAR(13), ''))) AS line
    FROM retained r CROSS APPLY STRING_SPLIT(r.text, CHAR(10))
), owner AS (
    SELECT source_path,
           MAX(CASE WHEN line LIKE '@capability:%' THEN SUBSTRING(line,13,400) END) AS capability_id
    FROM lines GROUP BY source_path
), corpus AS (   -- declared (capability, scenario) pairs: 1,031
    SELECT DISTINCT o.capability_id COLLATE Latin1_General_100_BIN2 AS capability_id,
           SUBSTRING(l.line,11,400) COLLATE Latin1_General_100_BIN2 AS scenario_id
    FROM lines l JOIN owner o ON o.source_path = l.source_path
    WHERE l.line LIKE '@scenario:%' AND o.capability_id IS NOT NULL
), selected AS ( -- owned pairs in the selected model: 825
    SELECT c.capability_id, s.scenario_id
    FROM model.estate_capability ec
    JOIN model.capability c ON c.capability_pk = ec.capability_pk
    JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk
    JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
    WHERE ec.estate_model_pk = @model
), selected_ids AS (
    SELECT DISTINCT c.capability_id
    FROM model.estate_capability ec
    JOIN model.capability c ON c.capability_pk = ec.capability_pk
    WHERE ec.estate_model_pk = @model
)
-- ... append one of the four queries below
```

```sql
-- A. corpus declarations absent from the selected model: 38 ids, 241 scenarios
SELECT capability_id, COUNT(*) AS declared_scenarios
FROM corpus WHERE capability_id NOT IN (SELECT capability_id FROM selected_ids)
GROUP BY capability_id ORDER BY declared_scenarios DESC, capability_id;
```

```sql
-- B. selected capabilities with no capability tag in this corpus: 25 ids, 40 scenarios
SELECT si.capability_id,
       (SELECT COUNT(*) FROM selected s WHERE s.capability_id = si.capability_id) AS owned_scenarios
FROM selected_ids si WHERE si.capability_id NOT IN (SELECT capability_id FROM corpus)
ORDER BY si.capability_id;
```

```sql
-- C. shared owners, declared in the corpus and absent from the model: 3 owners, 18 pairs
SELECT c.capability_id, c.scenario_id
FROM corpus c
WHERE c.capability_id IN (SELECT capability_id FROM selected_ids)
  AND NOT EXISTS (SELECT 1 FROM selected s
                  WHERE s.capability_id = c.capability_id AND s.scenario_id = c.scenario_id)
ORDER BY c.capability_id, c.scenario_id;
```

```sql
-- D. shared owners, owned by the model and not declared in the corpus: 3 owners, 13 pairs, 9 ids
SELECT s.capability_id, s.scenario_id
FROM selected s
WHERE s.capability_id IN (SELECT capability_id FROM corpus)
  AND NOT EXISTS (SELECT 1 FROM corpus c
                  WHERE c.capability_id = s.capability_id AND c.scenario_id = s.scenario_id)
ORDER BY s.capability_id, s.scenario_id;
```

C and D disagree in opposite directions; a projector that takes the corpus as
the source of truth deletes D's 13 pairs unless the rule says otherwise (§1).

### 11.5 Untagged blocks, all in one file (§2.2)

```sql
WITH retained AS (
    SELECT DISTINCT a.source_path, CONVERT(varchar(max), co.content_bytes) AS text
    FROM source.source_appearance a
    JOIN source.content_object co ON co.content_object_pk = a.content_object_pk
    JOIN source.estate_model m ON m.estate_snapshot_pk = a.estate_snapshot_pk
     AND m.estate_model_pk = @model
    WHERE a.source_path LIKE 'features/%.feature' AND a.source_class = 'REPOSITORY_TRACKED'
), lines AS (
    SELECT r.source_path, LTRIM(RTRIM(REPLACE(value, CHAR(13), ''))) AS line
    FROM retained r CROSS APPLY STRING_SPLIT(r.text, CHAR(10))
)
SELECT source_path,
       SUM(CASE WHEN line LIKE 'Scenario:%'  THEN 1 ELSE 0 END) AS blocks,
       SUM(CASE WHEN line LIKE '@scenario:%' THEN 1 ELSE 0 END) AS tags
FROM lines
GROUP BY source_path
HAVING SUM(CASE WHEN line LIKE 'Scenario:%'  THEN 1 ELSE 0 END)
     > SUM(CASE WHEN line LIKE '@scenario:%' THEN 1 ELSE 0 END);
```

Returns exactly one row: `features/manage-capsule-estate.feature`, 12 blocks and
0 tags. All 12 untagged blocks in the corpus are in that one file, which also
carries no `@capability` tag.

### 11.6 The registration defect (§3)

The symptom the projector has to remove — a scenario definition carrying a face
and no authored specification:

```sql
-- 824 selected scenarios carry authored steps; 1 does not
SELECT SUM(CASE WHEN has_steps = 1 THEN 1 ELSE 0 END) AS with_steps,
       SUM(CASE WHEN has_steps = 0 THEN 1 ELSE 0 END) AS without_steps
FROM (
    SELECT DISTINCT c.capability_id, s.scenario_id,
           CASE WHEN EXISTS (
               SELECT 1 FROM analysis.v_selected_semantic_definition d
               WHERE d.estate_model_pk = @model AND d.object_kind = 'SCENARIO'
                 AND d.declared_id = s.scenario_id
                 AND JSON_QUERY(d.definition_json, '$.semantics.scenario.steps') NOT IN ('[]')
           ) THEN 1 ELSE 0 END AS has_steps
    FROM model.estate_capability ec
    JOIN model.capability c ON c.capability_pk = ec.capability_pk
    JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk
    JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
    WHERE ec.estate_model_pk = @model
) t;
```

```sql
-- the face-only definitions themselves: semantics.scenario absent, scenarioId present
SELECT d.declared_id,
       JSON_VALUE(d.definition_json, '$.semantics.event')   AS event_id,
       JSON_VALUE(d.definition_json, '$.semantics.input')   AS input_id,
       JSON_VALUE(d.definition_json, '$.semantics.outcome') AS outcome_id
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk = @model AND d.object_kind = 'SCENARIO'
  AND JSON_QUERY(d.definition_json, '$.semantics.scenario') IS NULL
  AND JSON_VALUE(d.definition_json, '$.semantics.scenarioId') IS NOT NULL;
```

Returns `resolve-equity-market-price-evidence`. Its canonical feature declares
four scenarios with authored steps; registration produced one face.

### 11.7 Retained feature lineage (§2)

```sql
-- retained .feature paths by arrival route (routes overlap; union is 390, §2)
SELECT a.source_class,
       COUNT(*)                            AS appearances,
       COUNT(DISTINCT a.source_path)       AS distinct_paths,
       COUNT(DISTINCT a.content_object_pk) AS distinct_contents
FROM source.source_appearance a
JOIN source.estate_model m ON m.estate_snapshot_pk = a.estate_snapshot_pk
 AND m.estate_model_pk = @model
WHERE a.source_path LIKE '%.feature'
GROUP BY a.source_class
ORDER BY appearances DESC;
```

```sql
-- every retained revision of one capability's feature, largest bytes first
SELECT a.source_class, a.source_path, a.entry_id, co.byte_length,
       LOWER(CONVERT(varchar(64), co.content_digest, 2)) AS content_digest
FROM source.source_appearance a
JOIN source.content_object co ON co.content_object_pk = a.content_object_pk
JOIN source.estate_model m ON m.estate_snapshot_pk = a.estate_snapshot_pk
 AND m.estate_model_pk = @model
WHERE a.source_path LIKE '%resolve-equity-market-price-evidence%.feature'
ORDER BY co.byte_length DESC;
```

Three byte lengths are retained for that path. Compare a digest against the
working-tree file before treating any single copy as current (§2, §8).

### 11.8 Definitions that disagree with themselves

Not a corpus finding, but it constrains re-projection (§8): 275 declared ids
already carry more than one retained definition, one of them 13.

```sql
SELECT object_kind, declared_id, COUNT(*) AS retained_definitions
FROM analysis.v_selected_semantic_definition
WHERE estate_model_pk = @model
GROUP BY object_kind, declared_id
HAVING COUNT(*) > 1
ORDER BY retained_definitions DESC, object_kind, declared_id;
```

A re-run that appends rather than reconciles makes this worse.

### 11.9 Blueprint coverage

```sql
-- 35 of the 220 selected capabilities retain a circuit blueprint candidate
SELECT COUNT(DISTINCT JSON_VALUE(d.definition_json, '$.semantics.capability.capabilityId'))
       AS capabilities_with_blueprint
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk = @model AND d.object_kind = 'BLUEPRINT';
```

```sql
-- selected capabilities with no blueprint candidate
SELECT c.capability_id
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk = ec.capability_pk
WHERE ec.estate_model_pk = @model
  AND NOT EXISTS (
      SELECT 1 FROM analysis.v_selected_semantic_definition d
      WHERE d.estate_model_pk = @model AND d.object_kind = 'BLUEPRINT'
        AND JSON_VALUE(d.definition_json, '$.semantics.capability.capabilityId')
            COLLATE Latin1_General_100_BIN2 = c.capability_id)
ORDER BY c.capability_id;
```
