# KPI DASHBOARDS

## My understanding
A KPI (Key Performance Indicator) is a metric tied to a specific business question. The most common mistake is writing the query first and calling the result a KPI. The right order is: define the contract in plain language, then write the query that implements it exactly.

The KPI contract has five parts:
1. **Business question** — what decision does this number support?
2. **Exact definition** — every filter, every join, every edge case written out explicitly.
3. **Edge cases** — NULLs, cancelled records, unassigned rows, zero denominators.
4. **Unit** — count, percentage, hours, dollars? Never leave this implicit.
5. **What makes it misleading** — what would cause the number to look good while the reality is bad?

> Tom Kyte's rule: "If you cannot explain the metric to a non-technical person in one sentence, your query is wrong."

## Why it matters
A number without a contract can be misread or gamed. For example:
- "Tasks completed" looks great for a team that closed 20 trivial tickets and ignored 3 critical bugs.
- "Average resolution time" improves if the team stops working on hard tasks and only closes easy ones.

Documenting the contract forces you to confront those loopholes before the metric reaches a dashboard that drives decisions.

## Example

```sql
-- Contract:
-- Business question: Are we completing tasks on time?
-- Definition: on-time = completed_at date <= due_date.
--   Only completed tasks with a known due_date are counted.
--   Cancelled tasks are excluded — they were never delivered.
-- Edge cases: NULL due_date excluded; NULL completed_at excluded.
-- Unit: percentage per priority band (0–100).
-- Misleading if: teams push due dates forward before completing tasks.

SELECT
    priority,
    COUNT(*) AS completed_tasks,
    COUNT(CASE WHEN TRUNC(CAST(completed_at AS DATE)) <= due_date THEN 1 END) AS on_time_count,
    ROUND(
        100 * COUNT(CASE WHEN TRUNC(CAST(completed_at AS DATE)) <= due_date THEN 1 END)
            / NULLIF(COUNT(*), 0)
    , 1) AS on_time_rate_pct
FROM tasks
WHERE status = 'completed'
  AND completed_at IS NOT NULL
  AND due_date IS NOT NULL
GROUP BY priority;
```

---

# COMMON BAD KPI PATTERNS

## My understanding
Three patterns come up repeatedly when a query produces a number that looks like a KPI but isn't:

1. **Status-blind count** — counting all rows regardless of status. A team with 50 completed tasks and 0 open tasks looks "busy," but has no current workload. Fix: split counts by status.

2. **Meaningless average** — averaging a column that has no meaningful average. `AVG(task_id)` averages an auto-increment key. Fix: identify what the number should actually represent and aggregate that instead.

3. **Type error as metric** — multiplying a VARCHAR column by a number (`priority * 10`). Oracle raises ORA-01722. Fix: convert the string to a numeric weight with CASE first.

## Why it matters
Bad KPIs reach dashboards and drive wrong decisions. Recognising the pattern in a query before it ships is much cheaper than correcting the business decisions made from it.

## Example

```sql
-- BAD: averages a meaningless primary key
SELECT t.name, AVG(ts.id) AS avg_task_id
FROM teams t
JOIN tasks ts ON ts.assigned_to = ...;

-- GOOD: ratio of completed tasks to total tasks
SELECT
    t.name AS team_name,
    ROUND(
        100 * COUNT(CASE WHEN ts.status = 'completed' THEN 1 END)
            / NULLIF(COUNT(ts.id), 0)
    , 1) AS completion_rate_pct
FROM teams t
LEFT JOIN users u  ON u.team_id      = t.id
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name;


-- BAD: multiplies a string column — ORA-01722
SELECT title, priority * 10 + due_date AS urgency_index FROM tasks;

-- GOOD: map priority to a numeric weight first
SELECT
    title,
    CASE priority
        WHEN 'critical' THEN 4
        WHEN 'high'     THEN 3
        WHEN 'medium'   THEN 2
        WHEN 'low'      THEN 1
    END - (TRUNC(due_date) - TRUNC(SYSDATE)) AS urgency_score
FROM tasks
WHERE status NOT IN ('completed', 'cancelled')
  AND due_date IS NOT NULL;
```
