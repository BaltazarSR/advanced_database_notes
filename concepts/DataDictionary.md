# DATA DICTIONARY VIEWS

## My understanding
Oracle maintains a set of read-only views that describe everything inside the database — tables, indexes, constraints, dependencies, and more. The `user_` prefix shows objects owned by the current user. These views are the authoritative source of truth about schema structure.

## Why it matters
You can inspect your own schema without external tools, understand what objects exist and when they were last modified, and query dependency relationships to plan migrations or understand what breaks if you drop something.

## Example
```sql
-- List all objects in your schema, grouped by type
SELECT object_type, COUNT(*) AS cnt
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

-- Get details: name, type, and timestamps
SELECT object_name, object_type, created, last_ddl_time
FROM user_objects
ORDER BY object_type, object_name;
```

---

# USER_TABLES / USER_INDEXES / USER_CONSTRAINTS / USER_VIEWS / USER_SEQUENCES

## My understanding
Each catalog view exposes a specific object type. They all follow the same pattern: `user_<type>` returns rows for each object of that type owned by the current session.

## Why it matters
Useful for scripting migrations, auditing schema state, and feeding into `DBMS_METADATA.GET_DDL` calls that loop over all objects of a given type.

## Example
```sql
-- All tables with approximate row counts
SELECT table_name, num_rows FROM user_tables ORDER BY num_rows DESC;

-- All indexes and which table they belong to
SELECT index_name, table_name FROM user_indexes ORDER BY index_name;

-- Foreign key constraints
SELECT constraint_name, table_name, r_constraint_name
FROM user_constraints
WHERE constraint_type = 'R';
```

---

# USER_DEPENDENCIES

## My understanding
`user_dependencies` tracks which objects reference which. If a stored procedure queries a table, there is a row saying the procedure depends on the table. This lets you determine the correct order for recreating objects in a new schema.

## Why it matters
Dropping or recreating objects in the wrong order causes compilation errors. Querying `user_dependencies` before a migration tells you exactly which objects must exist before others can be created.

## Example
```sql
-- All dependency relationships in the schema
SELECT referenced_name, referencing_name, referencing_type
FROM user_dependencies
ORDER BY referenced_name;

-- Objects that depend on any table (must be created after the table)
SELECT referencing_name, referencing_type
FROM user_dependencies
WHERE referenced_name IN (SELECT table_name FROM user_tables)
ORDER BY referencing_type, referencing_name;

-- Dependency tree for PL/SQL objects
SELECT referencing_name, referencing_type,
       LISTAGG(referenced_name, ', ') WITHIN GROUP (ORDER BY referenced_name) AS dependencies
FROM user_dependencies
WHERE referencing_type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION')
GROUP BY referencing_name, referencing_type
ORDER BY referencing_type, referencing_name;
```
