# AGGREGATE VS ANALYTIC FUNCTIONS

## My understanding
Both aggregate and analytic functions calculate over many rows. But aggregates (like with GROUP BY) squash output to one row per group. Adding the OVER() clause converts an aggregate to an analytic, which preserves all input rows.

## Why it matters
I can see individual row details AND the aggregate calculation simultaneously. Without OVER(), I lose all the other column values when using GROUP BY.

## Example
```sql
-- Aggregate: Returns only 1 row with total count
SELECT COUNT(*) FROM bricks;

-- Analytic: Returns all rows, each showing the total count
SELECT COUNT(*) OVER() FROM bricks;

-- With all columns visible
SELECT b.*, 
       COUNT(*) OVER() total_count
FROM bricks b;
```

---

# PARTITION BY

## My understanding
PARTITION BY splits rows into groups, similar to GROUP BY, but for analytic functions. Each partition is calculated independently while keeping all rows in the result.

## Why it matters
I can see group-level aggregates alongside individual row data. It's like having GROUP BY without losing the detail rows.

## Example
```sql
-- Using GROUP BY: Loses individual row details
SELECT colour, COUNT(*), SUM(weight)
FROM bricks
GROUP BY colour;

-- Using PARTITION BY: Keeps all rows
SELECT b.*,
       COUNT(*) OVER(PARTITION BY colour) bricks_per_colour,
       SUM(weight) OVER(PARTITION BY colour) weight_per_colour
FROM bricks b;
```

---

# ORDER BY (in window functions)

## My understanding
ORDER BY within OVER() determines how rows are sorted before computing the analytic function. This enables running totals and cumulative calculations.

## Why it matters
It lets me create running totals, cumulative averages, and sequential calculations. The order directly affects which rows are included in each calculation.

## Example
```sql
SELECT b.*,
       COUNT(*) OVER(ORDER BY brick_id) running_total,
       SUM(weight) OVER(ORDER BY brick_id) running_weight
FROM bricks b;
```
Shows cumulative count and weight up to each brick_id.

---

# PARTITION BY + ORDER BY

## My understanding
Combining both clauses first divides data into partitions, then orders rows within each partition. This gives running totals per group.

## Why it matters
I can calculate running statistics within categories. Each partition has its own running calculation that resets at partition boundaries.

## Example
```sql
SELECT b.*,
       COUNT(*) OVER(
         PARTITION BY colour
         ORDER BY brick_id
       ) running_total_per_colour,
       SUM(weight) OVER(
         PARTITION BY colour
         ORDER BY brick_id
       ) running_weight_per_colour
FROM bricks b;
```

---

# WINDOWING CLAUSE: ROWS vs RANGE

## My understanding
When using ORDER BY, SQL adds a default window: `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`. This includes all rows with values ≤ current row's value. ROWS counts physical rows, RANGE considers logical values.

## Why it matters
The default RANGE can include rows "after" the current one if they share the same sort value, causing unexpected results. ROWS BETWEEN gives precise control over exactly which physical rows to include.

## Example
```sql
-- Default RANGE: Rows with same weight get same totals (includes "future" rows)
SELECT b.*,
       COUNT(*) OVER(ORDER BY weight) running_total
FROM bricks b
ORDER BY weight;

-- Explicit ROWS: Only includes physical rows up to current
SELECT b.*,
       COUNT(*) OVER(
         ORDER BY weight
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) running_total
FROM bricks b
ORDER BY weight;
```

---

# DETERMINISTIC RESULTS

## My understanding
When ORDER BY doesn't uniquely identify rows, running totals for tied rows are non-deterministic—they can vary between executions. Adding more columns to ORDER BY until each combination is unique fixes this.

## Why it matters
Without unique ordering, query results aren't repeatable. This causes inconsistent reports and unpredictable behavior.

## Example
```sql
-- Non-deterministic: Rows with same weight can have different running totals each run
SELECT b.*,
       COUNT(*) OVER(
         ORDER BY weight
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) running_total
FROM bricks b;

-- Deterministic: Adding brick_id makes order unique
SELECT b.*,
       COUNT(*) OVER(
         ORDER BY weight, brick_id
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) running_total
FROM bricks b;
```

---

# SLIDING WINDOWS

## My understanding
Instead of unbounded preceding (all previous rows), I can specify a subset like "previous N rows" or "previous N values". The window slides as each row is processed.

## Why it matters
Essential for moving averages, recent trend analysis, and comparing nearby values without including the entire history.

## Example
```sql
-- ROWS: Current + 1 physical row before
-- RANGE: Current value + values that are 1 less
SELECT b.*,
       SUM(weight) OVER(
         ORDER BY weight
         ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
       ) sliding_row_weight,
       SUM(weight) OVER(
         ORDER BY weight
         RANGE BETWEEN 1 PRECEDING AND CURRENT ROW
       ) sliding_value_weight
FROM bricks b;

-- Window around current row (before AND after)
SELECT b.*,
       SUM(weight) OVER(
         ORDER BY weight
         ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
       ) sliding_window
FROM bricks b;
```

---

# OFFSET WINDOWS (Excluding Current Row)

## My understanding
I can create windows that exclude the current row by offsetting both boundaries. This lets me look at rows entirely before or after the current one.

## Why it matters
Useful for comparing current values to previous/next ranges without including the current value in the calculation.

## Example
```sql
SELECT b.*,
       COUNT(*) OVER(
         ORDER BY weight
         RANGE BETWEEN 2 PRECEDING AND 1 PRECEDING
       ) count_2_lower,
       COUNT(*) OVER(
         ORDER BY weight
         RANGE BETWEEN 1 FOLLOWING AND 2 FOLLOWING
       ) count_2_higher
FROM bricks b;
```
First count: rows with weight 1 or 2 less (not including current)
Second count: rows with weight 1 or 2 more (not including current)

---

# FILTERING ANALYTIC FUNCTIONS

## My understanding
Analytic functions are computed after WHERE, so I can't filter on them directly in WHERE. I must use a subquery or CTE to compute the analytic, then filter in the outer query.

## Why it matters
I often want to filter based on aggregate results (like "show only colors with 2+ bricks") while keeping row details. This requires the subquery pattern.

## Example
```sql
-- This FAILS - analytic not available in WHERE
SELECT colour FROM bricks
WHERE COUNT(*) OVER(PARTITION BY colour) >= 2;

-- This WORKS - filter in outer query
SELECT * FROM (
  SELECT b.*,
         COUNT(*) OVER(PARTITION BY colour) colour_count
  FROM bricks b
)
WHERE colour_count >= 2;
```

---

# ROW_NUMBER, RANK, DENSE_RANK

## My understanding
These three functions assign increasing numbers starting at 1, but handle ties differently:
- ROW_NUMBER: every row gets unique sequential number
- RANK: ties get same number, then skips (1,2,2,4)
- DENSE_RANK: ties get same number, no skips (1,2,2,3)

## Why it matters
Choosing the right function changes results when values tie. ROW_NUMBER for uniqueness, RANK for competition-style ranking, DENSE_RANK for "top N distinct values."

## Example
```sql
SELECT brick_id, weight,
       ROW_NUMBER() OVER(ORDER BY weight) rn,
       RANK() OVER(ORDER BY weight) rk,
       DENSE_RANK() OVER(ORDER BY weight) dr
FROM bricks;
```
If weights are [1,1,2,3], results are:
- ROW_NUMBER: 1,2,3,4
- RANK: 1,1,3,4
- DENSE_RANK: 1,1,2,3

---

# LAG and LEAD

## My understanding
LAG retrieves values from previous rows, LEAD gets values from following rows. Both move backwards/forwards in the ordered result set.

## Why it matters
I can compare current row to previous or next values without self-joins. Useful for calculating differences, detecting changes, or filling gaps.

## Example
```sql
SELECT b.*,
       LAG(shape) OVER(ORDER BY brick_id) prev_shape,
       LEAD(shape) OVER(ORDER BY brick_id) next_shape
FROM bricks b;
```

---

# FIRST_VALUE and LAST_VALUE

## My understanding
FIRST_VALUE returns the first value in the ordered window, LAST_VALUE returns the last. But by default, LAST_VALUE only goes to current row, not the actual last row.

## Why it matters
I can compare each row to the first or last value in the set. For true last value, I must change the window to `UNBOUNDED FOLLOWING`.

## Example
```sql
-- Default: last_value only goes to current row
SELECT b.*,
       FIRST_VALUE(weight) OVER(ORDER BY brick_id) first_weight,
       LAST_VALUE(weight) OVER(ORDER BY brick_id) last_weight_so_far
FROM bricks b;

-- To get actual last value in entire dataset
SELECT b.*,
       FIRST_VALUE(weight) OVER(ORDER BY brick_id) first_weight,
       LAST_VALUE(weight) OVER(
         ORDER BY brick_id
         RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
       ) actual_last_weight
FROM bricks b;
```
