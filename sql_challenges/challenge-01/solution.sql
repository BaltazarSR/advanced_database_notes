-- Excercise 1

-- 1.1
SELECT Title FROM movies;

-- 1.2
SELECT Director FROM movies;

-- 1.3
SELECT Title, Director FROM movies;

-- 1.4
SELECT Title, Year FROM movies;

-- 1.5
SELECT * FROM movies;

--Excercise 2

-- 2.1
SELECT * FROM movies
WHERE id == 6;

-- 2.2
SELECT * FROM movies
WHERE Year >= 2000 AND Year <= 2010;

-- 2.3
SELECT * FROM movies
WHERE Year < 2000 OR Year > 2010;

-- 2.4
SELECT title, year FROM movies
WHERE year <= 2003;

--Excercise 3

-- 3.1
SELECT * FROM movies
WHERE title LIKE "Toy Story%"

-- 3.2
SELECT * FROM movies
WHERE director = "John Lasseter"

-- 3.3
SELECT * FROM movies
WHERE director != "John Lasseter"

-- 3.4
SELECT * FROM movies
WHERE title Like "Wall-%"

--Excercise 4

-- 4.1
SELECT DISTINCT director FROM movies
ORDER BY director ASC

-- 4.2
SELECT * FROM movies
ORDER BY year DESC
LIMIT 4

-- 4.3
SELECT * FROM movies
ORDER BY title ASC
LIMIT 5

-- 4.4
SELECT * FROM movies
ORDER BY title ASC
LIMIT 5 OFFSET 5

--Excercise 5

-- 5.1
SELECT city, population FROM north_american_cities
WHERE country = "Canada"

-- 5.2
SELECT * FROM north_american_cities
WHERE country = "United States"
ORDER BY latitude DESC

-- 5.3
SELECT * FROM north_american_cities
WHERE longitude < (SELECT longitude FROM north_american_cities WHERE city = "Chicago")
ORDER BY longitude ASC

-- 5.4
SELECT * FROM north_american_cities
WHERE Country == "Mexico"
ORDER BY population DESC
LIMIT 2

-- 5.5
SELECT * FROM north_american_cities
WHERE Country == "United States"
ORDER BY population DESC
LIMIT 2 OFFSET 2

-- Review update