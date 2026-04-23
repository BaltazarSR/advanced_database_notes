# Transactions

## My understanding
A transaction is a group of SQL statements that are treated as a single unit of work — either all of them succeed and get committed, or none of them do. You control the boundary manually with `COMMIT` (make permanent) and `ROLLBACK` (undo everything since the last commit). `SAVEPOINT` lets you set a named checkpoint inside a transaction so you can roll back to a specific point without undoing the entire thing.

## Why it matters
Without transactions, a partial failure leaves the database in a broken state. For example, if you deduct money from one account but the system crashes before adding it to the other, the money just disappears. Wrapping both updates in a transaction guarantees they either both happen or neither does.

## Example
```sql
-- Transfer $100 from Alice to Bob atomically
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT; -- both changes are now permanent

-- Using SAVEPOINT to partially undo
UPDATE accounts SET balance = balance + 25 WHERE account_id = 1;
SAVEPOINT after_alice;
UPDATE accounts SET balance = balance - 25 WHERE account_id = 3; -- wrong account
ROLLBACK TO after_alice; -- undo only the last update
UPDATE accounts SET balance = balance - 25 WHERE account_id = 2; -- correct account
COMMIT;
```
