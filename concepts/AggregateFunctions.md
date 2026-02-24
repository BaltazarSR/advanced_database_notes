# AGGREGATE FUNCTIONS

## My understanding
If a SQL query is usually a magnifying glass that looks at individual rows, **Aggregate Functions** are the "zoom out" button. 

* Instead of looking at 1,000 individual sales, aggregate functions crunch them all down into a **single value**. 
* They take a collection of data points and return a mathematical summary, effectively "collapsing" the rows based on the logic you provide.

## Why it matters
Raw data is often too noisy to be useful for decision-making. You rarely need to see 50,000 individual transactions; you need to see the **total revenue** or the **average order value**.
* **Aggregation** turns "data" into "insights." 
* It allows us to perform high-level reporting and spot trends without drowning in the details.

---

## Example: The "Math Squad"

Imagine a **Store_Sales** table. Aggregate functions allow you to answer different types of business questions instantly:

### 1. The Core Functions
|       Function    |              What it does            |                  Real-world Question                |
| :---------------- | :----------------------------------- | :-------------------------------------------------- |
|      **SUM()**    |    Adds up all values in a column.   | "How much total money did we make today?"           |
|      **AVG()**    |       Calculates the mean value.     | "What is the typical price of an item in our shop?" |
|    **COUNT()**    | Counts the number of rows or values. | "How many customers visited us this afternoon?"     |
| **MIN() / MAX()** |  Finds the lowest or highest value.  | "What was our cheapest vs. most expensive sale?"    |

### 2. The Power Pairings
Aggregates are rarely used alone; they usually hang out with these two clauses to make sense of the results:

* **GROUP BY:** This is the "By" clause. It tells SQL how to slice the data before crunching it. Instead of the total sum of *all* sales, you get the sum **BY** category (e.g., Electronics vs. Clothing).
* **HAVING:** This is the "Filter" for your results. Since you can't use `WHERE` on a sum you just calculated, you use `HAVING` to say, "Only show me categories where the total sales are over $1,000."