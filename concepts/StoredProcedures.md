# Stored Procedures

## My understanding
A stored procedure is a named block of PL/SQL logic saved in the database that you call by name. It can accept input parameters, run DML statements, handle errors, and issue COMMIT/ROLLBACK. A function is similar but it must return a value and cannot use COMMIT/ROLLBACK — that's the key distinction. Use a procedure when you need to change state; use a function when you need to compute and return a value.

## Why it matters
Packaging logic in the database means the rules live close to the data — every app that calls `transfer_funds()` gets the same validation and error handling automatically. It also keeps transactions consistent: if something fails mid-procedure, the EXCEPTION block can ROLLBACK and re-raise so the caller always knows the outcome.

One important caveat: if a procedure calls COMMIT internally, it commits any surrounding transaction the caller may have started. This can silently break larger transactions that expect to stay open.

## Example
```sql
-- Procedure: changes state, owns the transaction
CREATE OR REPLACE PROCEDURE transfer_funds(
    p_from_account IN NUMBER,
    p_to_account   IN NUMBER,
    p_amount       IN NUMBER
) AS
    v_balance NUMBER;
BEGIN
    SELECT balance INTO v_balance FROM accounts WHERE account_id = p_from_account;
    IF v_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20001, 'Insufficient funds');
    END IF;
    UPDATE accounts SET balance = balance - p_amount WHERE account_id = p_from_account;
    UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_to_account;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- Function: returns a value, usable in SELECT
CREATE OR REPLACE FUNCTION get_balance(p_account_id IN NUMBER) RETURN NUMBER AS
    v_balance NUMBER;
BEGIN
    SELECT balance INTO v_balance FROM accounts WHERE account_id = p_account_id;
    RETURN v_balance;
END;
/

-- Procedure is called with EXEC, never inside SELECT:
EXEC transfer_funds(1, 2, 100);

-- Function can be used directly in a query:
SELECT owner_name, get_balance(account_id) AS balance FROM accounts;
```
