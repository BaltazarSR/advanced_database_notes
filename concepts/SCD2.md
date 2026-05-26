# SCD2 — Slowly Changing Dimension Type 2

## My understanding
SCD2 is a technique for tracking historical changes to a record over time. Instead of overwriting the old value, you keep all versions by adding `valid_from` and `valid_to` timestamps. The currently active row has `valid_to = NULL`. When something changes, you close the old row (set its `valid_to`) and insert a new one.

## Why it matters
Without SCD2, you only know the current state. With it, you can answer "who was assigned to this ticket last Tuesday?" — which is critical for accurate reporting. If a task was created by agent A but resolved by agent B (after reassignment), SCD2 lets you correctly credit A for creation and B for resolution.

## Example

Assignment history table with SCD2:

| assignment_id | ticket_id | assigned_to | valid_from          | valid_to            |
|---------------|-----------|-------------|---------------------|---------------------|
| 1             | 3         | 1 (Sara)    | 2026-04-03 10:00:00 | 2026-04-05 09:12:00 |
| 2             | 3         | 2 (Tom)     | 2026-04-05 09:12:00 | NULL                |

```sql
-- Trigger that maintains this history automatically
CREATE OR REPLACE TRIGGER trg_ticket_assignment_log
    AFTER INSERT OR UPDATE OF assigned_to ON tickets
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, NULL, :NEW.created_at);
    ELSIF UPDATING THEN
        -- Close the old row
        UPDATE ticket_assignments
           SET valid_to = SYSTIMESTAMP
         WHERE ticket_id = :OLD.ticket_id AND valid_to IS NULL;
        -- Open a new row
        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, NULL, SYSTIMESTAMP);
    END IF;
END;
```

---

# Point-in-Time Lookup

## My understanding
To find which version of an SCD2 record was active at a specific timestamp, use this filter:
```
valid_from <= target_timestamp AND (valid_to IS NULL OR valid_to > target_timestamp)
```
This returns the one row whose validity window contains the target timestamp.

## Why it matters
This is how ETL pipelines correctly assign credit in historical data. Without it, all credit goes to whoever is currently assigned, which is wrong when reassignments happened.

## Example
```python
# In pandas: find who was assigned at ticket creation time
created = tickets_df.merge(assignments_df, on='ticket_id')
created = created[
    (created['created_at'] >= created['valid_from']) &
    (created['valid_to'].isna() | (created['created_at'] < created['valid_to']))
]
# The result: one row per ticket with the correct historical assignee
```

```sql
-- In SQL: same logic
SELECT ta.assigned_to
FROM   ticket_assignments ta
WHERE  ta.ticket_id  = 3
  AND  ta.valid_from <= TIMESTAMP '2026-04-03 10:00:00'
  AND  (ta.valid_to IS NULL OR ta.valid_to > TIMESTAMP '2026-04-03 10:00:00');
-- Returns Sara (agent 1), not Tom — even though Tom is the current assignee
```
