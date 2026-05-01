# DBMS_METADATA

## My understanding
`DBMS_METADATA` is an Oracle built-in package that extracts the DDL of any object in the database as a CLOB. `GET_DDL(object_type, object_name)` returns the `CREATE` statement that would recreate that object. This is the SQL-only alternative to `expdp` when you don't have DBA or directory privileges.

## Why it matters
It lets you document or migrate a schema using nothing but a SQL connection. You can loop over `user_tables`, `user_indexes`, etc. and export every object's definition without any special privileges beyond access to your own schema.

## Example
```sql
-- One-time setup: configure clean output (no storage clauses, no tablespace)
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

SET LONG 100000
SET PAGESIZE 0

-- Extract DDL for a single table
SELECT DBMS_METADATA.GET_DDL('TABLE', 'MY_TABLE') FROM DUAL;

-- Extract DDL for all tables at once
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
ORDER BY table_name;
```

---

# SET_TRANSFORM_PARAM

## My understanding
Transform parameters control how the DDL output is formatted. The most important ones strip out environment-specific details (storage, tablespace, schema name) that would break the script when run on a different database.

## Why it matters
Without these settings, the exported DDL contains storage clauses and schema-qualified names that tie it to one specific environment. Setting `EMIT_SCHEMA = false` makes the DDL portable to any schema.

## Key parameters

| Parameter | Effect |
|-----------|--------|
| `PRETTY` | Adds readable formatting/indentation |
| `SQLTERMINATOR` | Appends `;` or `/` so scripts are directly runnable |
| `SEGMENT_ATTRIBUTES` | If false, removes INITIAL/NEXT/MINEXTENTS storage clauses |
| `STORAGE` | If false, removes STORAGE(...) clause |
| `TABLESPACE` | If false, removes TABLESPACE clause |
| `EMIT_SCHEMA` | If false, removes schema prefix — `"ORDERS"` instead of `"MYSCHEMA"."ORDERS"` |

## Example
```sql
-- With EMIT_SCHEMA = true (default):  CREATE TABLE "SALES"."ORDERS" ...
-- With EMIT_SCHEMA = false:           CREATE TABLE "ORDERS" ...

BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'EMIT_SCHEMA', false);
END;
/
```

---

# SCHEMA MIGRATION — DEPENDENCY ORDER

## My understanding
When recreating a schema from scratch, objects must be created in an order that satisfies their dependencies. Creating a view before its base table exists causes an error. The safe reload order is:

1. Tables (no FK constraints yet)
2. Sequences
3. Indexes
4. Constraints (PKs, then FKs)
5. Views
6. Procedures / Functions / Packages
7. Triggers

## Why it matters
Skipping this order causes compilation errors or invalid objects. For circular PL/SQL dependencies, the workaround is to create the package spec first and the package body second.

## Example
```sql
-- Export in the right sequence:

-- 1. Tables
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name) FROM user_tables;

-- 2. Sequences
SELECT DBMS_METADATA.GET_DDL('SEQUENCE', sequence_name) FROM user_sequences;

-- 3. Indexes
SELECT DBMS_METADATA.GET_DDL('INDEX', index_name) FROM user_indexes;

-- 4. Constraints
SELECT DBMS_METADATA.GET_DDL('CONSTRAINT', constraint_name) FROM user_constraints;

-- 5. Views
SELECT DBMS_METADATA.GET_DDL('VIEW', view_name) FROM user_views;

-- 6. PL/SQL code
SELECT DBMS_METADATA.GET_DDL('PROCEDURE', object_name) FROM user_objects WHERE object_type = 'PROCEDURE';
SELECT DBMS_METADATA.GET_DDL('FUNCTION', object_name)  FROM user_objects WHERE object_type = 'FUNCTION';
SELECT DBMS_METADATA.GET_DDL('PACKAGE', object_name)   FROM user_objects WHERE object_type = 'PACKAGE';
```

---

# DBMS_METADATA vs expdp

## My understanding
`expdp` (Data Pump Export) is the professional Oracle backup tool — it exports DDL and data together into a binary dump file, handles large schemas, and is fast. `DBMS_METADATA` only exports DDL (no data), requires manually collecting and running the SQL, but works with a basic SQL connection and no special privileges.

## Why it matters
On shared databases like freesql.com you will never have `CREATE DIRECTORY` or `DBA` privileges. `DBMS_METADATA` is the only tool available. In production environments with full DBA access, `expdp` is the right choice.

| | DBMS_METADATA | expdp |
|--|--|--|
| Exports data | No (DDL only) | Yes |
| Needs directory privilege | No | Yes |
| Speed on large schemas | Slow | Fast |
| Output format | SQL text | Binary dump |
| Where it runs | SQL session | OS command line |
