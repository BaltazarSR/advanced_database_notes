-- Excercise 6

-- 6.1
SELECT m.title, b.domestic_sales, b.international_sales
FROM movies m
INNER JOIN boxoffice b
ON m.id = b.movie_id;

-- 6.2
SELECT m.title, b.domestic_sales, b.international_sales
FROM movies m
INNER JOIN boxoffice b
ON m.id = b.movie_id
WHERE b.international_sales > b.domestic_sales

-- 6.3
SELECT m.title, b.rating
FROM movies m
INNER JOIN boxoffice b
ON m.id = b.movie_id
ORDER BY b.rating DESC

--Excercise 7

-- 7.1
SELECT * 
FROM buildings b
INNER JOIN employees e
ON b.building_name = e.building
GROUP BY b.building_name

-- 7.2
SELECT * 
FROM buildings 

-- 7.3
SELECT * 
FROM buildings b
LEFT JOIN employees e
ON b.building_name = e.building
GROUP BY e.role, b.building_name;

--Data Lemur

SELECT p.page_id 
FROM pages p
LEFT JOIN page_likes pl
ON p.page_id = pl.page_id
WHERE pl.user_id IS NULL
ORDER BY page_id;

-- Review update