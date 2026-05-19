# Alembic Migrations

## My understanding
Alembic is a schema migration tool for SQLAlchemy. Each migration is a Python file with two functions: `upgrade()` (the forward change) and `downgrade()` (the reversal). Every file has a `revision` ID and a `down_revision` pointer that chain all migrations into a linked list — Alembic uses this chain to know where the database currently stands and what needs to run next.

The current applied revision is stored in an `alembic_version` table inside the database itself, so every environment tracks its own state independently.

Key commands (Python API):
- `command.revision(cfg, autogenerate=True, message="...")` — generates a migration file by diffing ORM models against the live DB
- `command.upgrade(cfg, 'head')` — applies all pending migrations
- `command.downgrade(cfg, '-1')` — rolls back the most recent migration

**Important:** `downgrade()` that drops a column permanently destroys any data stored in it. There is no automatic backup.

## Why it matters
Migrations version-control the schema the same way Git versions code. Every developer and every deployment environment applies changes in the same order, making schema history auditable and reproducible without manual DDL scripts.

## Example
```python
# Generated migration file (simplified)
def upgrade():
    op.create_table(
        'comments',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('task_id', sa.Integer(), sa.ForeignKey('tasks.id', ondelete='CASCADE')),
        sa.Column('content', sa.Text(), nullable=False),
    )

def downgrade():
    op.drop_table('comments')  # all comment rows are permanently deleted
```
