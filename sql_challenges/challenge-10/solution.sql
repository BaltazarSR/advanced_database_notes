-- ============================================
-- EXERCISE 1: Explore your schema
-- ============================================
-- List all the objects in your schema using user_objects
-- Group by object_type and count them
-- Which object types do you have? functions, indexes, LOB, procedure, sequences, tables and triggers.


-- Sample solution:
SELECT object_type, COUNT(*) AS cnt
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

[
  {
    "object_type": "INDEX",
    "cnt": 1
  },
  {
    "object_type": "PROCEDURE",
    "cnt": 1
  },
  {
    "object_type": "TABLE",
    "cnt": 1
  }
]

-- Also get details:
SELECT object_name, object_type, created, last_ddl_time
FROM user_objects
ORDER BY object_type, object_name;

[
  {
    "object_name": "SYS_C003679944",
    "object_type": "INDEX",
    "created": "2026-04-21T15:24:06Z",
    "last_ddl_time": "2026-04-21T15:24:06Z"
  },
  {
    "object_name": "DEPOSIT_FUNDS",
    "object_type": "PROCEDURE",
    "created": "2026-04-21T15:44:17Z",
    "last_ddl_time": "2026-04-21T15:44:17Z"
  },
  {
    "object_name": "ACCOUNTS",
    "object_type": "TABLE",
    "created": "2026-04-21T15:24:06Z",
    "last_ddl_time": "2026-04-21T15:24:06Z"
  }
]

-- ============================================
-- EXERCISE 2: Basic GET_DDL
-- ============================================
-- First, set transform params for clean output:
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

-- Get DDL for one of your tables (replace MY_TABLE with actual name)
SELECT DBMS_METADATA.GET_DDL('TABLE', 'ACCOUNTS') FROM DUAL;

  CREATE TABLE "A01643496_SCHEMA_9I2QX"."ACCOUNTS" 
   (	"ACCOUNT_ID" NUMBER, 
	"OWNER_NAME" VARCHAR2(50) NOT NULL ENABLE, 
	"BALANCE" NUMBER(10,2) NOT NULL ENABLE, 
	 CHECK (balance >= 0) ENABLE, 
	 PRIMARY KEY ("ACCOUNT_ID")
  USING INDEX  ENABLE
   ) ;

-- Or get all tables at once:
SELECT DBMS_METADATA.GET_DDL('TABLE', 'ACCOUNTS')
FROM user_tables
ORDER BY table_name;

  CREATE TABLE "A01643496_SCHEMA_9I2QX"."ACCOUNTS" 
   (	"ACCOUNT_ID" NUMBER, 
	"OWNER_NAME" VARCHAR2(50) NOT NULL ENABLE, 
	"BALANCE" NUMBER(10,2) NOT NULL ENABLE, 
	 CHECK (balance >= 0) ENABLE, 
	 PRIMARY KEY ("ACCOUNT_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS"  ENABLE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" 

-- Identify the key parts in the output:
--   - Column definitions (NAME, TYPE, NULL/NOT NULL)
    "ACCOUNT_ID" NUMBER                        -- nullable (no constraint)
    "OWNER_NAME" VARCHAR2(50) NOT NULL ENABLE  -- max 50 chars, required
    "BALANCE"    NUMBER(10,2) NOT NULL ENABLE  -- 10 digits, 2 decimal places, required

--   - Constraints (PRIMARY KEY, FK, CHECK)
    CHECK (balance >= 0) ENABLE        -- balance can never go negative
    PRIMARY KEY ("ACCOUNT_ID") ENABLE  -- account_id uniquely identifies each row

--   - Storage parameters (if included)
    PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255
    STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 ...)
    TABLESPACE "USERS"

-- ============================================
-- EXERCISE 3: Clean DDL for portability
-- ============================================
-- Remove schema names from DDL so it works in any schema

BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'EMIT_SCHEMA', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

-- Compare the output with and without EMIT_SCHEMA:
-- With EMIT_SCHEMA (default):   CREATE TABLE "SALES"."ORDERS" ...
-- Without EMIT_SCHEMA:          CREATE TABLE "ORDERS" ...

-- Try it yourself:
SELECT DBMS_METADATA.GET_DDL('TABLE', 'ACCOUNTS')
FROM user_tables
WHERE ROWNUM = 1;

  CREATE TABLE "ACCOUNTS" 
   (	"ACCOUNT_ID" NUMBER, 
	"OWNER_NAME" VARCHAR2(50) NOT NULL ENABLE, 
	"BALANCE" NUMBER(10,2) NOT NULL ENABLE, 
	 CHECK (balance >= 0) ENABLE, 
	 PRIMARY KEY ("ACCOUNT_ID")
  USING INDEX  ENABLE
   ) ;


-- ============================================
-- EXERCISE 4: Plan a migration
-- ============================================
-- You're moving to a new schema with a different name.
-- What changes would you need to make to your exported DDL?

-- Scenario: Migrating from SCHEMA_OLD to SCHEMA_NEW

-- 1. First, identify schema names embedded in your DDL:
SELECT DBMS_METADATA.GET_DDL('TABLE', 'ACCOUNTS')
FROM user_tables
WHERE 'ACCOUNTS' = 'ANY_TABLE_WITH_FK';

--NO RESULTS

-- 2. Check for schema-qualified references:
SELECT constraint_name, 'ACCOUNTS', r_constraint_name
FROM user_constraints
WHERE constraint_type = 'R';

--NO RESULTS

-- 3. If you find FK constraints pointing to other schemas, you need to:
--    - Update the REFERENCES clause to point to new schema name
--    - Or make sure target table exists in same schema

-- 4. Write a migration checklist:
--    □ Export all DDL with EMIT_SCHEMA = false
--    □ Review FK constraints for schema references
--    □ Update constraint references if needed
--    □ Reload in order: tables → constraints → indexes → views → code

-- ============================================
-- EXERCISE 5: Dependency order
-- ============================================
-- Look at user_dependencies to understand object relationships

-- See all dependencies in your schema:
SELECT referenced_name, name AS referencing_name, type AS referencing_type
FROM user_dependencies
ORDER BY referenced_name;

[
  {
    "referenced_name": "ACCOUNTS",
    "referencing_name": "DEPOSIT_FUNDS",
    "referencing_type": "PROCEDURE"
  },
  {
    "referenced_name": "DBMS_OUTPUT",
    "referencing_name": "DEPOSIT_FUNDS",
    "referencing_type": "PROCEDURE"
  },
  {
    "referenced_name": "DBMS_STANDARD",
    "referencing_name": "DEPOSIT_FUNDS",
    "referencing_type": "PROCEDURE"
  },
  {
    "referenced_name": "STANDARD",
    "referencing_name": "DEPOSIT_FUNDS",
    "referencing_type": "PROCEDURE"
  },
  {
    "referenced_name": "SYS_STUB_FOR_PURITY_ANALYSIS",
    "referencing_name": "DEPOSIT_FUNDS",
    "referencing_type": "PROCEDURE"
  }
]

-- Find objects that depend on TABLES (to know what needs tables first):
SELECT name AS referencing_name, type AS referencing_type
FROM user_dependencies
WHERE referenced_name IN (
  SELECT table_name FROM user_tables
)
ORDER BY type, name;

[
  {
    "referencing_name": "DEPOSIT_FUNDS",
    "referencing_type": "PROCEDURE"
  }
]

-- Find direct dependencies for a specific object (replace PROC_NAME):
SELECT referenced_name, referenced_type
FROM user_dependencies
WHERE name = 'PROC_NAME';

-- NO RESULT

-- Build a dependency tree for PL/SQL objects:
SELECT name AS referencing_name, type AS referencing_type,
       LISTAGG(referenced_name, ', ') WITHIN GROUP (ORDER BY referenced_name) AS dependencies
FROM user_dependencies
WHERE type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION')
GROUP BY name, type
ORDER BY type, name;

[
  {
    "referencing_name": "DEPOSIT_FUNDS",
    "referencing_type": "PROCEDURE",
    "dependencies": "ACCOUNTS, DBMS_OUTPUT, DBMS_STANDARD, STANDARD, SYS_STUB_FOR_PURITY_ANALYSIS"
  }
]

-- ============================================
-- EXERCISE 6: Design your own backup strategy
-- ============================================
-- Given:
--   - No expdp access (no directory privileges)
--   - Need to move your schema to another database
--   - Only have SQL access
--
-- Design the steps you would take:

-- STEP 1: Document your current schema structure
SELECT object_type, COUNT(*) FROM user_objects GROUP BY object_type;
SELECT table_name, num_rows FROM user_tables ORDER BY num_rows DESC;

[
  {
    "object_type": "TABLE",
    "count(*)": 1
  },
  {
    "object_type": "PROCEDURE",
    "count(*)": 1
  },
  {
    "object_type": "INDEX",
    "count(*)": 1
  }
]

-- STEP 2: Extract all DDL (run all these)
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

-- Extract tables (spool to file or copy output):
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name) FROM user_tables;

  CREATE TABLE "A01643496_SCHEMA_9I2QX"."ACCOUNTS" 
   (	"ACCOUNT_ID" NUMBER, 
	"OWNER_NAME" VARCHAR2(50) NOT NULL ENABLE, 
	"BALANCE" NUMBER(10,2) NOT NULL ENABLE, 
	 CHECK (balance >= 0) ENABLE, 
	 PRIMARY KEY ("ACCOUNT_ID")
  USING INDEX  ENABLE
   ) ;

-- Extract indexes:
SELECT DBMS_METADATA.GET_DDL('INDEX', index_name) FROM user_indexes;

  CREATE UNIQUE INDEX "A01643496_SCHEMA_9I2QX"."SYS_C003679944" ON "A01643496_SCHEMA_9I2QX"."ACCOUNTS" ("ACCOUNT_ID") 
  ;

-- Extract views:
SELECT DBMS_METADATA.GET_DDL('VIEW', view_name) FROM user_views;

-- NO RESULT

-- Extract sequences:
SELECT DBMS_METADATA.GET_DDL('SEQUENCE', sequence_name) FROM user_sequences;

-- NO RESULT

-- Extract constraints:
SELECT DBMS_METADATA.GET_DDL('CONSTRAINT', constraint_name) FROM user_constraints;

[
  {
    "dbms_metadata.get_ddl('constraint',constraint_name)": "\n  ALTER TABLE \"A01643496_SCHEMA_9I2QX\".\"ACCOUNTS\" MODIFY (\"OWNER_NAME\" NOT NULL ENABLE);"
  },
  {
    "dbms_metadata.get_ddl('constraint',constraint_name)": "\n  ALTER TABLE \"A01643496_SCHEMA_9I2QX\".\"ACCOUNTS\" MODIFY (\"BALANCE\" NOT NULL ENABLE);"
  },
  {
    "dbms_metadata.get_ddl('constraint',constraint_name)": "\n  ALTER TABLE \"A01643496_SCHEMA_9I2QX\".\"ACCOUNTS\" ADD CHECK (balance >= 0) ENABLE;"
  },
  {
    "dbms_metadata.get_ddl('constraint',constraint_name)": "\n  ALTER TABLE \"A01643496_SCHEMA_9I2QX\".\"ACCOUNTS\" ADD PRIMARY KEY (\"ACCOUNT_ID\")\n  USING INDEX  ENABLE;"
  }
]

-- Extract code:
SELECT DBMS_METADATA.GET_DDL('PROCEDURE', object_name) FROM user_objects WHERE object_type = 'PROCEDURE';


  CREATE OR REPLACE EDITIONABLE PROCEDURE "A01643496_SCHEMA_9I2QX"."DEPOSIT_FUNDS" (
    p_account_id  IN NUMBER,
    p_amount      IN NUMBER
    ) AS
    BEGIN
        -- Step 1: Validate amount
        IF p_amount <= 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Deposit amount must be greater than zero.');
        END IF;

        -- Step 2: Add the amount
        UPDATE accounts
        SET balance = balance + p_amount
        WHERE account_id = p_account_id;

        -- Step 3: Commit on success
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Deposit of $' || p_amount || ' to account ' || p_account_id || ' successful.');

    EXCEPTION
        WHEN OTHERS THEN
            -- Step 4: Rollback and re-raise on any error
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Deposit failed. Changes rolled back.');
            RAISE;
    END;

SELECT DBMS_METADATA.GET_DDL('FUNCTION', object_name) FROM user_objects WHERE object_type = 'FUNCTION';

-- NO RESULT

SELECT DBMS_METADATA.GET_DDL('PACKAGE', object_name) FROM user_objects WHERE object_type = 'PACKAGE';

-- NO RESULT

-- STEP 3: Reload in new schema (use proper order)
-- 1. Create tables (no constraints yet)
-- 2. Create sequences
-- 3. Create indexes
-- 4. Add constraints (enable FKs)
-- 5. Create views
-- 6. Create procedures/functions/packages
-- 7. Create triggers

-- STEP 4: Verify everything transferred
SELECT object_type, COUNT(*) FROM user_objects GROUP BY object_type;
[
  {
    "object_type": "TABLE",
    "count(*)": 1
  },
  {
    "object_type": "PROCEDURE",
    "count(*)": 1
  },
  {
    "object_type": "INDEX",
    "count(*)": 1
  }
]

SELECT table_name, num_rows FROM user_tables ORDER BY table_name;
[
  {
    "table_name": "ACCOUNTS",
    "num_rows": 3
  }
]

SELECT index_name, table_name FROM user_indexes ORDER BY index_name;
[
  {
    "index_name": "SYS_C003679944",
    "table_name": "ACCOUNTS"
  }
]

-- ============================================
-- DISCUSSION QUESTIONS
-- ============================================
 
-- Q1: What are the limitations of DBMS_METADATA vs expdp?
--  DBMS_METADATA only exports DDL, requires manual spool/cursor,
--  and can't handle very large schemas easily.
--  expdp is faster, can export data, handles large schemas, but needs directory access.
--  Choose DBMS_METADATA when you have no DBA access or need educational visibility.
--  Choose expdp when you have proper access and need speed/completeness.

-- Q2: If you have circular dependencies (A depends on B, B depends on A),
--     how would you handle the reload?
--  Oracle handles most circular dependencies automatically if you create
--  objects first and enable constraints later.
--  For PL/SQL circular dependencies, create the package spec first,
--  then the package body second.
--  DBMS_METADATA returns objects in a valid order - trust the dependency analysis.
 
-- Q3: Your company is migrating from one Oracle database to another.
--     They give you read-only access to the old database and want you
--     to recreate the schema on the new database.
--     What's your plan?
--  1. Document source schema structure (user_objects, user_tables, etc.)
--  2. Set EMIT_SCHEMA=false and extract clean DDL
--  3. Check for dependencies and schema-qualified references
--  4. Review and clean up the DDL (remove storage, fix schema names)
--  5. Create new schema user on target
--  6. Run DDL in proper order (tables -> constraints -> indexes -> views -> code)
--  7. Verify with object counts and sample queries
--  8. If possible, export sample data via INSERT statements or CSV
 
 
-- ============================================
-- FURTHER INVESTIGATION
-- ============================================
 
-- The techniques in this lesson work on freesql.com with basic SQL access.
-- When you have full Oracle access (DBA, directory privileges, etc.),
-- consider these more advanced approaches:
 
-- 1. expdp / impdp (Data Pump)
--    The standard Oracle export/import tool.
--    Requires: CREATE ANY DIRECTORY privilege + directory object.
--    Can export schemas, tablespaces, full databases.
--    Handles data + DDL (unlike DBMS_METADATA which is DDL only).
--    Example:
--    expdp system/password@db SCHEMAS=MY_SCHEMA DIRECTORY=MY_DIR DUMPFILE=backup.dmp
 
-- 2. SQLcl "script" command
--    SQL Developer Command Line can export entire schema to JSON or ZIP.
--    Has a "rolling migration" feature for schema comparisons.
 
-- 3. Oracle SQL Developer (GUI)
--    Has "Database Export" wizard for schema backup.
--    Point-and-click, no CLI needed.
 
-- 4. Partitioned tables & transportable tablespaces
--    For very large schemas, Oracle's transportable tablespace
--    feature can move entire tablespaces between databases.
 
-- 5. Cloud-native tools (if using Oracle Cloud)
--    Oracle Cloud Infrastructure Database Migration service
--    handles full schema migration with automatic conversion.