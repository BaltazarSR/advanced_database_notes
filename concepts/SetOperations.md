# SET OPERATIONS

## My understanding
If JOINs are "horizontal" combinations (connecting tables side-by-side), **Set Operations** are the "vertical" tools. 

* Set Operations stack query results on top of each other, like combining two lists into one.
* They treat query results as mathematical **sets** and let you combine, subtract, or find overlaps between them.
* The key rule: all queries involved must return the **same number of columns** with **compatible data types**.

## Why it matters
Sometimes you need to merge data from completely different sources or tables that don't have a clean join relationship. 
* Set operations let you combine results from separate queries without needing a foreign key.
* They're essential for reporting, data analysis, and answering questions like "Who's in both lists?" or "What's unique to this dataset?"

---

# UNION

## My understanding
UNION combines the results of two or more queries into a single result set, **removing duplicates** automatically.

* Think of it as merging two lists and keeping only unique items.
* If the same row appears in both queries, it only shows up once in the final result.

## Why it matters
When you need a complete, deduplicated list from multiple sources (like active customers from 2024 and 2025), UNION keeps your results clean without manual filtering.

## Example
```sql
-- Get all cities where we have customers OR suppliers
SELECT city FROM customers
UNION
SELECT city FROM suppliers;
-- Result: Each city appears only once
```

---

# UNION ALL

## My understanding
UNION ALL does the same thing as UNION, but **keeps all rows**, including duplicates.

* It's faster than UNION because it doesn't need to check for and remove duplicates.
* Use it when you know there won't be duplicates or when you actually want to count duplicates.

## Why it matters
When you're analyzing data and duplicates are meaningful (like counting total transactions from multiple sources), or when performance matters and you know duplicates won't occur.

## Example
```sql
-- Get all transactions from online and in-store sales
SELECT order_id, amount FROM online_sales
UNION ALL
SELECT order_id, amount FROM store_sales;
-- Result: If order #123 exists in both, it appears twice
```

---

# INTERSECT

## My understanding
INTERSECT returns only the rows that appear in **both** query results.

* It's like the "overlap" in a Venn diagram—only what's common to both sets.
* Duplicates are automatically removed from the result.

## Why it matters
Perfect for finding commonalities: "Which customers bought products in both January AND February?" or "Which features are supported by both versions?"

## Example
```sql
-- Find customers who made purchases in BOTH Q1 and Q2
SELECT customer_id FROM q1_orders
INTERSECT
SELECT customer_id FROM q2_orders;
-- Result: Only customers who appear in both quarters
```

---

# MINUS (or EXCEPT)

## My understanding
MINUS returns rows from the first query that **do not** appear in the second query.

* It's subtraction for datasets: "Show me everything in A that's NOT in B."
* Note: Some databases call this EXCEPT instead of MINUS (PostgreSQL, SQL Server use EXCEPT; Oracle uses MINUS).

## Why it matters
Essential for finding gaps, exclusions, or what's missing: "Which products have never been ordered?" or "Which employees haven't completed training?"

## Example
```sql
-- Find all customers who registered but never made a purchase
SELECT customer_id FROM registered_users
MINUS
SELECT customer_id FROM orders;
-- Result: Only customers with no orders
```

---

## Quick Comparison

| Operation      | What it returns                          | Handles Duplicates?           |
| :------------- | :--------------------------------------- | :---------------------------- |
| **UNION**      | All rows from both queries               | Removes duplicates            |
| **UNION ALL**  | All rows from both queries               | Keeps duplicates (faster)     |
| **INTERSECT**  | Only rows that appear in BOTH            | Removes duplicates            |
| **MINUS**      | Rows in first query NOT in second        | Removes duplicates            |
