# CONDITIONAL AGGREGATION

## My understanding
Conditional aggregation means wrapping a `CASE WHEN` expression inside an aggregate function (`COUNT`, `SUM`, `AVG`) so that only rows matching a condition contribute to the result. The key insight is that a `CASE` that returns `NULL` for non-matching rows is automatically ignored by aggregate functions — `COUNT` skips NULLs, `SUM` treats them as zero.

This lets one query return multiple status-based columns at once, instead of writing a separate subquery per status.

## Why it matters
Without conditional aggregation, splitting a single table into multiple status columns requires multiple joins or subqueries that re-scan the table. One pass with `CASE WHEN` is simpler and faster.

## Example

```sql
-- Instead of three subqueries:
SELECT
    t.name AS team_name,
    COUNT(ts.id)                                                                 AS total_tasks,
    COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 END) AS active_tasks,
    COUNT(CASE WHEN ts.status = 'completed' THEN 1 END)                         AS completed_tasks
FROM teams t
LEFT JOIN users u  ON u.team_id      = t.id
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name;
```

---

# NULLIF — SAFE DIVISION

## My understanding
`NULLIF(a, b)` returns NULL if `a = b`, otherwise returns `a`. Its main use is preventing ORA-01476 (divide-by-zero) by replacing a zero denominator with NULL before the division. Dividing by NULL yields NULL, not an error.

## Why it matters
Any percentage calculation (`completed / total * 100`) crashes if `total` is zero. Wrapping the denominator in `NULLIF(..., 0)` makes the query safe without an explicit IF/CASE block.

## Example

```sql
-- Crashes when total is 0
SELECT completed_count / total_count * 100 FROM ...;

-- Safe: returns NULL instead of error when total is 0
SELECT
    ROUND(
        100 * COUNT(CASE WHEN status = 'completed' THEN 1 END)
            / NULLIF(COUNT(*), 0)
    , 1) AS completion_rate_pct
FROM tasks
GROUP BY team_id;
```

---

# PERCENTILE_CONT — MEDIAN

## My understanding
`PERCENTILE_CONT(fraction) WITHIN GROUP (ORDER BY expression)` computes a percentile by interpolating between values. Using `0.5` gives the median. Unlike `AVG`, the median is not pulled by outliers, so it better represents "typical" resolution time when one or two tasks take extremely long.

## Why it matters
Averages hide distribution. A 2-hour critical fix averaged with a 40-hour documentation update gives 21 hours — a number that represents neither task. The median shows what most tasks actually look like.

## Example

```sql
SELECT
    priority,
    ROUND(AVG(
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR   FROM (completed_at - created_at))
    ), 1) AS avg_resolution_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR   FROM (completed_at - created_at))
    ), 1) AS median_resolution_hours
FROM tasks
WHERE status = 'completed'
  AND completed_at IS NOT NULL
GROUP BY priority;
```

---

# ROLLUP — SUMMARY ROWS

## My understanding
`GROUP BY ROLLUP(col)` produces all the normal grouped rows plus one extra row with `NULL` in the grouped column, representing the grand total. `NVL(col, 'TOTAL')` replaces that NULL with a readable label.

For multiple columns, `ROLLUP(a, b)` produces subtotals for each leading prefix: `(a, b)`, `(a)`, and `()` (grand total). The number of extra rows equals the number of columns plus one.

## Why it matters
Without ROLLUP, adding a totals row requires a `UNION ALL` with a separate aggregation query. ROLLUP does it in one pass and keeps the result set clean.

## Example

```sql
-- Without ROLLUP: needs a UNION
SELECT priority, COUNT(*) AS cnt FROM tasks GROUP BY priority
UNION ALL
SELECT 'TOTAL', COUNT(*) FROM tasks;

-- With ROLLUP: one query
SELECT
    NVL(priority, 'TOTAL') AS priority,
    COUNT(*)                AS cnt
FROM tasks
GROUP BY ROLLUP(priority)
ORDER BY CASE NVL(priority, 'TOTAL')
             WHEN 'critical' THEN 1
             WHEN 'high'     THEN 2
             WHEN 'medium'   THEN 3
             WHEN 'low'      THEN 4
             ELSE 5
         END;
```
