# SQLAlchemy ORM

## My understanding
ORM (Object-Relational Mapping) maps database tables to Python classes. Each class inherits from `declarative_base()`, each column becomes a `Column(...)` attribute, and foreign keys are declared with `ForeignKey("table.column")`. You interact with the database by creating, modifying, and deleting Python objects — SQLAlchemy translates those operations to SQL automatically.

`relationship()` lets you navigate between related objects without writing JOINs. `back_populates` keeps both sides of the relationship in sync. `cascade="all, delete-orphan"` means child rows are deleted automatically when the parent is deleted.

Session lifecycle:
- `session.add(obj)` — stages the object in memory
- `session.flush()` — sends SQL to the DB within the current transaction (useful to get auto-generated IDs before committing)
- `session.commit()` — writes everything permanently
- `session.delete(obj)` — marks the object for deletion on the next commit

## Why it matters
- No raw SQL strings means no SQL injection risk — values are always parameterized
- Relationships make cross-table navigation readable (`task.assignee.full_name` instead of a JOIN)
- Switching database engines requires only a connection string change, not rewritten queries

## Example
```python
class Task(Base):
    __tablename__ = "tasks"
    id          = Column(Integer, primary_key=True)
    title       = Column(String(200), nullable=False)
    assigned_to = Column(Integer, ForeignKey("users.id"))
    assignee    = relationship("User", back_populates="tasks")
    comments    = relationship("Comment", back_populates="task", cascade="all, delete-orphan")

with Session(engine) as session:
    task = Task(title="Fix login bug", assigned_to=1)
    session.add(task)
    session.commit()
    print(task.assignee.full_name)  # navigates FK without writing a JOIN
```
