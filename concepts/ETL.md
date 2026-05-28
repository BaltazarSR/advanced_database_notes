# ETL

## My understanding
ETL stands for Extract, Transform, Load. It's the process of pulling data from a source system (Extract), cleaning and reshaping it in code (Transform), and writing the results into a destination system (Load). It's how you move data from an OLTP database into a data warehouse.

## Why it matters
Analytical queries (aggregations, time-series, dashboards) are expensive on OLTP tables because the schema is optimized for writes, not reads. ETL lets you pre-compute and restructure that data into a shape that makes analytics fast and simple.

## Example
```python
# EXTRACT
tickets_df     = pd.read_sql("SELECT * FROM tickets", engine)
assignments_df = pd.read_sql("SELECT * FROM ticket_assignments", engine)

# TRANSFORM — find who was assigned at creation time using SCD2 lookup
created = tickets_df.merge(assignments_df, on='ticket_id')
created = created[
    (created['created_at'] >= created['valid_from']) &
    (created['valid_to'].isna() | (created['created_at'] < created['valid_to']))
]
fact = created.groupby(['date_key', 'agent_key', 'status', 'priority']).size()

# LOAD — upsert into the data warehouse
cursor.execute("MERGE INTO fact_ticket_daily ...")
conn.commit()
```

---

# MERGE INTO (Upsert)

## My understanding
`MERGE INTO` combines INSERT and UPDATE into one statement. It checks if a matching row exists: if yes, it updates it; if no, it inserts a new one. This makes ETL pipelines idempotent — safe to re-run without creating duplicates.

## Why it matters
ETL jobs often run on a schedule. Without upsert logic, re-running would either fail on unique constraint violations or create duplicate rows.

## Example
```sql
MERGE INTO fact_ticket_daily f
USING (SELECT :1 AS date_key, :2 AS agent_key, :3 AS status,
              :4 AS priority, :5 AS tickets_created, :6 AS tickets_resolved
         FROM dual) src
ON (f.date_key = src.date_key AND f.agent_key = src.agent_key
AND f.status   = src.status   AND f.priority  = src.priority)
WHEN NOT MATCHED THEN INSERT
    (date_key, agent_key, status, priority, tickets_created, tickets_resolved)
    VALUES (src.date_key, src.agent_key, src.status, src.priority,
            src.tickets_created, src.tickets_resolved)
WHEN MATCHED THEN UPDATE SET
    tickets_created  = src.tickets_created,
    tickets_resolved = src.tickets_resolved;
```
