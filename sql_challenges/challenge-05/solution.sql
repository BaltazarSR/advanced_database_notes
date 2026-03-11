-- freesql

-- try it 1.1
select colour from my_brick_collection
union
select colour from your_brick_collection
order by colour;

-- try it 1.2
select shape from my_brick_collection
union all
select shape from your_brick_collection
order  by shape;

-- try it 2.1
select shape from my_brick_collection
minus
select shape from your_brick_collection;

-- try it 2.2
select colour from my_brick_collection
intersect
select colour from your_brick_collection
order  by colour;
