-- Excercise 1
-- Questions:

-- a) What scan type do you see? Why?
-- This is a full table scan, it reads the whole table and selects the ones matching the condition.

-- b) site_id has values 1–5. Is this high or low cardinality?
-- Low cardinality, each value could cover 20% of the table.

-- c) Would adding an index on site_id help? Why or why not?
-- I would say no, because it is not worth it when the index covers a good part of the table. 
-- It is better to just read the whole table than to be switching between rows.


-- Excercise 2

-- Index
CREATE INDEX idx_pv_visit_date ON patient_visits(visit_date);


-- Questions:

-- a) Does Oracle use the index for this range?
-- Most likely, roughly 4% of rows, which is selective enough.

-- b) Change the range to the last 7 days. Does the plan change?
-- Even more selective, ~1% of rows, so the index scan is even more certain.

-- c) Change to the last 700 days. What happens?
-- The table only has 2 years of data, so this touches nearly every row. 
-- Oracle will switch to a full table scan.

-- d) Why does the range size affect whether Oracle uses the index?
-- Each index hit requires two steps: look up the index entry, 
-- then fetch the actual row. For small ranges that's a bargain. 
-- For huge ranges, those round-trips cost more than just reading the table straight through. 


-- Excercise 3

-- Questions:
-- a) Does the plan use the composite index?
-- Yes, the composite index (patient_id, visit_date) is used, 
-- Oracle can narrow to rows where patient_id = 1234 and then within those, 
-- filter by date.

-- b) Now try querying ONLY on visit_date (no patient_id). Does the composite index get used? Why not?
-- No. The composite index is not usable. The index sorts by both of the composites.

-- c) What's the rule about column order in composite indexes? 
-- A composite index can only be used from the left. 
-- Queries on the first column alone work. 
-- Queries skipping the first column cannot use the index. 


-- Excercise 4

-- Questions:
-- a) What scan type did the second query use?
-- Full table scan.

-- b) Why does wrapping a column in a function break index use?
-- The index stores the raw patient_id values. 
-- Wrapping the column in TO_CHAR() means Oracle has to transform 
-- every single value first before comparing

-- c) How would you rewrite the second query to allow index use?
WHERE patient_id = 5432


-- Excercise 5

-- For each scenario below, decide:
--   a) Would you add an index?
--   b) On which column(s)?
--   c) Any concerns?

-- Scenario A
-- a) Yes
-- b) Add an index on the date column. 
-- c) The nightly load will be slightly slower due to the index,
-- but this is acceptable as the queries are made during the day.

-- Scenario B
-- a) Yes
-- b) In customer_id because it's high cardinality
-- c) With the high inserts per minute the index could add overhead 
-- but it would be minimal

-- Scenario C
-- a) Yes
-- b) A unique index in email because of high cardinality
-- c) Not in here