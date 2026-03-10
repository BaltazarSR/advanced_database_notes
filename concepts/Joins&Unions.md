# SQL Joins

## My understanding
If tables are the "folders" of a database, **Joins** are the tools we use to combine them. 

* **JOINs** are "horizontal" combinations. They connect two tables side-by-side based on a shared column (like a Foreign Key). You use a Join when you want to see data from Table A *and* Table B in one row.

## Why it matters
Data is almost never stored in one giant table because that would be messy and redundant (Normalization). 
* **Joins** allow us to reconstruct the "big picture" from fragmented pieces without wasting storage.

---

## Example: The Join Family

Imagine a **Books** table and an **Orders** table. Here is how different Joins affect what you see:

### 1. The Common Joins
| Join Type      | What it returns                                                                 |
| :------------- | :------------------------------------------------------------------------------ |
| **INNER JOIN** | Only rows where there is a match in **both** tables (e.g., only sold books).    |
| **LEFT JOIN**  | All books from the catalog, plus order info if it exists (otherwise `NULL`).    |
| **RIGHT JOIN** | All orders, plus book info (rarely used; usually just flipped to a Left Join).  |

### 2. The Specialized Joins
| Join Type      | What it returns                                                                 |
| :------------- | :------------------------------------------------------------------------------ |
| **FULL JOIN**  | Everything from both tables. If a book hasn't sold, it still shows it all.      |
| **CROSS JOIN** | Every possible combination (e.g., 10 books x 10 customers = 100 rows).          |
| **SELF JOIN**  | A table joining itself. Used for hierarchies (e.g., Managers in Employee lists).|


-- Review update