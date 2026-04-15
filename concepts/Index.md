# INDEXES

## My understanding
An index is a separate data structure the database maintains alongside a table to make lookups faster. Instead of scanning every row (a full table scan), the database uses the index to jump directly to the rows that match a query. The trade-off is that indexes cost space and slow down INSERT/UPDATE/DELETE slightly, because the index must be kept in sync with the table.

## Why it matters
On large tables, the difference between a full table scan and an index lookup can be the difference between seconds and milliseconds. Indexes are the primary tool for query performance tuning, but adding too many hurts write-heavy tables.

## Example

```sql
-- Without an index: Oracle does a full table scan
SELECT * FROM patient_visits WHERE patient_id = 1234;

-- Create a B-tree index on patient_id
CREATE INDEX idx_pv_patient ON patient_visits(patient_id);

-- Now the same query uses the index (range scan instead of full scan)
SELECT * FROM patient_visits WHERE patient_id = 1234;

-- Gather stats so the optimizer knows the index exists
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/
```

---

# CARDINALITY AND WHEN NOT TO INDEX

## My understanding
Cardinality refers to how many distinct values a column has. High cardinality (e.g., `patient_id` with 10,000 values) benefits from indexing because the index filters aggressively. Low cardinality (e.g., `status` with 3 values) often does not — returning 33% of a table is barely better than a full scan, so Oracle's optimizer may ignore the index anyway.

## Why it matters
Creating an index on a low-cardinality column wastes space and adds write overhead without improving read performance. The optimizer decides whether to use an index based on selectivity.

## Example

```sql
-- site_id has values 1–5 (very low cardinality)
-- An index here is rarely useful — Oracle will likely do a full table scan anyway
CREATE INDEX idx_pv_site ON patient_visits(site_id);

SELECT * FROM patient_visits WHERE site_id = 3;
-- If site_id = 3 matches ~20% of rows, the optimizer skips the index

-- patient_id has 10,000 distinct values (high cardinality)
-- An index here filters down to ~0.01% of rows — very effective
SELECT * FROM patient_visits WHERE patient_id = 5432;
```

---

# COMPOSITE INDEX

## My understanding
A composite (multi-column) index covers more than one column. The column order matters: the index is most useful when queries filter on the leading column first. A query that only filters on the second column cannot use the composite index from the middle.

## Why it matters
A single composite index can replace two separate single-column indexes and is more efficient for queries that always filter on both columns together. The leading column rule is critical to understand — getting the order wrong means the index is ignored.

## Example

```sql
-- Composite index: patient_id is the leading column
CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

-- Uses the index — leading column is present
SELECT * FROM patient_visits
WHERE patient_id = 1234 AND visit_date > SYSDATE - 90;

-- Also uses the index — leading column alone is enough
SELECT * FROM patient_visits WHERE patient_id = 1234;

-- Does NOT use the composite index — leading column is missing
SELECT * FROM patient_visits WHERE visit_date > SYSDATE - 90;
```

---