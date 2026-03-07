-- Excercise 10

-- 10.1
SELECT MAX(years_employed) FROM employees;

-- 10.2
SELECT Role, AVG(Years_employed) as Years FROM employees
GROUP BY Role;

-- 10.3
SELECT Building, SUM(Years_employed) as Years FROM employees
GROUP BY Building;

-- Excercise 11

-- 11.1
SELECT Role, COUNT(Name) as quantity FROM employees
WHERE Role == "Artist";

-- 11.2
SELECT Role, COUNT(Name) as quantity FROM employees
GROUP BY Role

-- 11.3
SELECT Role, SUM(Years_employed) as years FROM employees
GROUP BY Role
HAVING Role == 'Engineer'

-- freesql

-- try it 1
SELECT COUNT(DISTINCT shape) as NUMBER_OF_SHAPES, STDDEV(DISTINCT weight) as DISTINCT_WEIGHT_STDDEV
FROM bricks

-- try it 2
SELECT shape, SUM(weight) as SHAPE_WEIGHT
FROM   bricks
GROUP BY shape 
ORDER BY shape ASC

-- try it 3
SELECT shape, SUM( weight ) as TOTAL_WEIGHT
FROM bricks
GROUP BY shape
HAVING TOTAL_WEIGHT < 4


-- Review update