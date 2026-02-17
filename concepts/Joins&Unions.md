# SQL Joins & Unions (Full Version)

## My understanding
If tables are the "folders" of a database, **Joins** and **Unions** are the tools we use to combine them. 

* **JOINs** are "horizontal" combinations. They connect two tables side-by-side based on a shared column (like a Foreign Key). You use a Join when you want to see data from Table A *and* Table B in one row.
* **UNIONs** are "vertical" combinations. They stack one table on top of another. You use a Union when you have two lists with the same structure and you want to combine them into one long list.

## Why it matters
Data is almost never stored in one giant table because that would be messy and redundant (Normalization). 
* **Joins** allow us to reconstruct the "big picture" from fragmented pieces without wasting storage.
* **Unions** allow us to aggregate data from different sources (like different regions or time periods) into a single unified report.

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

---

## Example: Unions (The Vertical Stack)

To use a **UNION**, the columns must match exactly in name and data type.

**Table: Active_Users**
| Name      | Status    |
| :-------- | :-------- |
| Alice     | Active    |

**Table: Retired_Users**
| Name      | Status    |
| :-------- | :-------- |
| Bob       | Retired   |

**Result of UNION:**
| Name      | Status    |
| :-------- | :-------- |
| Alice     | Active    |
| Bob       | Retired   |

---

## Key Differences Summary

| Feature            | JOIN                                 | UNION                                 |
| :----------------- | :----------------------------------- | :------------------------------------ |
| **Direction**      | Horizontal (adds columns)            | Vertical (adds rows)                  |
| **Requirement**    | Needs a common "Key" column          | Columns must match in type and order  |
| **Duplicates**     | Depends on the join logic            | `UNION` removes; `UNION ALL` keeps    |
| **Primary Goal**   | Linking related data                 | Combining similar lists               |