SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    CASE
        WHEN ty.name IN ('nvarchar', 'nchar')
            AND c.max_length > 0
            THEN c.max_length / 2
        ELSE c.max_length
    END AS max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed
FROM sys.tables t
JOIN sys.schemas s
    ON s.schema_id = t.schema_id
JOIN sys.columns c
    ON c.object_id = t.object_id
JOIN sys.types ty
    ON ty.user_type_id = c.user_type_id
ORDER BY
    s.name,
    t.name,
    c.column_id;