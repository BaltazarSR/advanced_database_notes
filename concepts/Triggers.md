# TRIGGERS

## My understanding
A trigger is a stored procedure that automatically runs in response to a specific event on a table — INSERT, UPDATE, or DELETE. I define when it fires (BEFORE or AFTER the event) and it executes without me calling it manually.

## Why it matters
Triggers enforce business rules and auditing at the database level, independent of the application. This means the logic runs even if data is changed outside the app (e.g., direct SQL, scripts).

## Example
```sql
-- Create an audit log table
CREATE TABLE orders_audit (
  audit_id    NUMBER GENERATED ALWAYS AS IDENTITY,
  order_id    NUMBER,
  old_status  VARCHAR2(50),
  new_status  VARCHAR2(50),
  changed_at  TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Trigger fires after each UPDATE on orders
CREATE OR REPLACE TRIGGER trg_orders_status_audit
AFTER UPDATE OF status ON orders
FOR EACH ROW
BEGIN
  INSERT INTO orders_audit (order_id, old_status, new_status)
  VALUES (:OLD.id, :OLD.status, :NEW.status);
END;
```
Now every time a row in `orders` has its status updated, the old and new values are automatically logged.

---

# BEFORE vs AFTER TRIGGERS

## My understanding
BEFORE triggers fire before the DML operation completes — I can still modify the values being inserted/updated using `:NEW`. AFTER triggers fire once the operation is done — useful for logging or cascading changes.

## Why it matters
BEFORE is the right choice when I need to validate or transform data before it hits the table. AFTER is better for audit trails or actions that depend on the final committed values.

## Example
```sql
-- BEFORE INSERT: normalize data before it is saved
CREATE OR REPLACE TRIGGER trg_normalize_email
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
  :NEW.email := LOWER(:NEW.email);
END;

-- AFTER DELETE: log deleted row
CREATE OR REPLACE TRIGGER trg_log_deleted_user
AFTER DELETE ON users
FOR EACH ROW
BEGIN
  INSERT INTO deleted_users_log (user_id, deleted_at)
  VALUES (:OLD.id, SYSTIMESTAMP);
END;
```

---

# :OLD and :NEW

## My understanding
Inside a row-level trigger, `:NEW` holds the new values being written and `:OLD` holds the values that were there before. For INSERT, only `:NEW` is populated. For DELETE, only `:OLD` is populated. For UPDATE, both are available.

## Why it matters
These pseudo-records let me compare before and after states, which is essential for auditing, conditional logic, and computing derived values.

## Example
```sql
CREATE OR REPLACE TRIGGER trg_price_change_guard
BEFORE UPDATE OF price ON products
FOR EACH ROW
BEGIN
  IF :NEW.price < 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Price cannot be negative');
  END IF;

  IF :NEW.price > :OLD.price * 2 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Price increase over 100% requires approval');
  END IF;
END;
```

---

# FOR EACH ROW vs STATEMENT-LEVEL

## My understanding
`FOR EACH ROW` makes the trigger fire once per affected row. Without it, the trigger fires once per DML statement regardless of how many rows it touches.

## Why it matters
Row-level triggers give access to `:OLD` and `:NEW` and are needed for per-row logic. Statement-level triggers are useful for bulk actions like logging that a statement ran, without caring about individual rows.

## Example
```sql
-- Row-level: fires once per row deleted
CREATE OR REPLACE TRIGGER trg_row_level
AFTER DELETE ON orders
FOR EACH ROW
BEGIN
  -- :OLD.id is available here
  INSERT INTO audit_log (ref_id) VALUES (:OLD.id);
END;

-- Statement-level: fires once even if 1000 rows are deleted
CREATE OR REPLACE TRIGGER trg_statement_level
AFTER DELETE ON orders
BEGIN
  INSERT INTO audit_log (event) VALUES ('bulk delete on orders');
END;
```

---

# DROPPING AND DISABLING TRIGGERS

## My understanding
Triggers can be disabled temporarily without dropping them, which is useful for bulk loads or maintenance. Dropping removes them permanently.

## Why it matters
Disabling during bulk inserts avoids the overhead and side effects of trigger logic firing thousands of times when I know the data is already clean.

## Example
```sql
-- Disable a trigger
ALTER TRIGGER trg_normalize_email DISABLE;

-- Re-enable it
ALTER TRIGGER trg_normalize_email ENABLE;

-- Drop it permanently
DROP TRIGGER trg_normalize_email;
```
