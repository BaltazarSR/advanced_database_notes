# BASICS

# SELECT

## My understanding
SELECT is used to choose which columns I want to display from a table.

## Why it matters
It allows me to see only the data I need instead of all the data.

## Example
    SELECT Title FROM movies;

---

# FROM

## My understanding
FROM tells SQL which table the data is coming from.

## Why it matters
Without FROM, SQL would not know where to get the data.

## Example
    SELECT * FROM movies;

---

# WHERE

## My understanding
WHERE is used to filter rows based on a condition.

## Why it matters
It helps limit the results to only the relevant data.

## Example
    SELECT * FROM movies
    WHERE year >= 2000;

---

# Comparison Operators (=, !=, <, >, <=, >=)

## My understanding
Comparison operators are used to compare values in conditions.

## Why it matters
They allow precise filtering of data.

## Example
    SELECT * FROM movies
    WHERE director != "John Lasseter";

---

# Logical Operators (AND, OR)

## My understanding
Logical operators combine multiple conditions in a WHERE clause.

## Why it matters
They allow more complex filtering.

## Example
    SELECT * FROM movies
    WHERE year >= 2000 AND year <= 2010;

---

# LIKE

## My understanding
LIKE is used to search for a pattern in text values.

## Why it matters
It helps when I do not know the exact value.

## Example
    SELECT * FROM movies
    WHERE title LIKE "Toy Story%";

---

# DISTINCT

## My understanding
DISTINCT removes duplicate values from the result.

## Why it matters
It helps show only unique data.

## Example
    SELECT DISTINCT director FROM movies;

---

# ORDER BY

## My understanding
ORDER BY sorts the results in ascending or descending order.

## Why it matters
Sorted results are easier to read and analyze.

## Example
    SELECT * FROM movies
    ORDER BY year DESC;

---

# LIMIT

## My understanding
LIMIT controls how many rows are returned.

## Why it matters
It is useful when only a few results are needed.

## Example
    SELECT * FROM movies
    LIMIT 5;

---

# OFFSET

## My understanding
OFFSET skips a specific number of rows before showing results.

## Why it matters
It is useful for pagination.

## Example
    SELECT * FROM movies
    LIMIT 5 OFFSET 5;

---

# Subquery

## My understanding
A subquery is a query inside another query.

## Why it matters
It allows the result of one query to be used in another.

## Example
    SELECT * FROM north_american_cities
    WHERE longitude < (
        SELECT longitude
        FROM north_american_cities
        WHERE city = "Chicago"
    );

---

# SELECT *

## My understanding
SELECT * returns all columns from a table.

## Why it matters
It is a quick way to view all data in a table.

## Example
    SELECT * FROM north_american_cities;


-- Review update