-- Exercise 1

-- ## Questions

-- 1. What relationships should `Comment` have?
-- A comment needs two belongs_to relationships,
-- one to Task and one to User.

-- 2. Should `Task` have a `comments` relationship?
-- Yes, Defining has_many :comments on Task doesn't 
-- change the database at all, it just gives you a convenient 
-- handle to fetch all comments for a task without writing a 
-- manual query every time.
-- comments = relationship("Comment", back_populates="task", cascade="all, delete-orphan")

-- 3. What should happen to comments when a task is deleted?
-- Use ON DELETE CASCADE, when a task disappears, its comments 
-- should go with it, since a comment with no task is meaningless
-- noise.


-- Exercise 2

-- 1. What does upgrade() do?
--    upgrade() runs the forward migration. Alembic autogenerate detects that the
--    `comments` table does not exist in the database and generates
--    op.create_table('comments', ...) with all columns and foreign-key constraints.
--    Running upgrade() executes that statement and creates the table.

-- 2. What does downgrade() do?
--    downgrade() reverses the migration. Alembic generates op.drop_table('comments'),
--    which removes the table and all its rows from the database.

-- 3. What happens if you downgrade this migration?
--    The comments table is dropped entirely and all stored rows are permanently
--    deleted. The alembic_version table rolls back to the previous revision.


-- Exercise 4

-- 1. What happens to the column?
--    The estimated_hours column is dropped from the tasks table. The schema reverts
--    to what it was before the migration was applied.

-- 2. What happens to the data?
--    All values stored in estimated_hours are permanently lost. Alembic does not
--    back up column data before dropping it.


-- Exercise 5

-- 1. Why use ORM instead of raw SQL?
--    ORM maps tables to Python classes so you work with objects instead of strings.
--    You get type safety, automatic SQL-injection escaping, relationship navigation
--    (task.assignee, team.users), and portability across database engines.

-- 2. Why use migrations?
--    Migrations version-control every schema change as code. Every environment
--    (dev/staging/prod) applies the same changes in the same order, making schema
--    history auditable and reversible.

-- 3. When would you rollback?
--    When a migration introduces a bug or breaking change — a bad constraint,
--    a column that causes query failures, or a schema change that conflicts with
--    the running application code.

-- 4. Difference between add() and commit()?
--    session.add() stages an object in the session's in-memory unit of work.
--    session.commit() flushes all pending changes and writes them permanently
--    to the database. Without commit(), nothing is saved to disk.

-- 5. Why are relationships useful?
--    Relationships let you navigate between related objects (task.assignee,
--    team.users) without writing JOIN queries manually. SQLAlchemy loads related
--    objects as needed, keeping application code clean and readable.
