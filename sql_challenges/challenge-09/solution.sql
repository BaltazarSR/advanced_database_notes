-- SQL Challenge 09 – Transactions & Stored Procedures
-- Oracle 23ai / freesql.com
-- ============================================================

-- Setup: run this once before the exercises
-- ============================================================

DROP TABLE accounts PURGE;

CREATE TABLE accounts (
    account_id   NUMBER PRIMARY KEY,
    owner_name   VARCHAR2(50) NOT NULL,
    balance      NUMBER(10,2) NOT NULL CHECK (balance >= 0)
);

INSERT INTO accounts VALUES (1, 'Alice',  1000.00);
INSERT INTO accounts VALUES (2, 'Bob',     500.00);
INSERT INTO accounts VALUES (3, 'Charlie', 250.00);
COMMIT;

SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Expected: Alice=1000, Bob=500, Charlie=250


-- ============================================================
-- Exercise 1 — Manual transaction (warm-up)
-- ============================================================
-- Transfer $50 from Charlie (3) to Alice (1).
-- Verify balances before and after COMMIT.

-- Before:
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- Your SQL here:
UPDATE accounts SET balance = balance - 50 WHERE account_id = 3; -- Charlie pays
UPDATE accounts SET balance = balance + 50 WHERE account_id = 1; -- Alice receives

-- After:
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

COMMIT;

-- ============================================================
-- Exercise 2 — Catch yourself with ROLLBACK
-- ============================================================
-- Start a transfer of $10,000 from Bob (2) to Charlie (3).
-- Check balances before committing — does Bob have enough?
-- ROLLBACK and verify balances are restored.

-- Verify before
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- Your SQL here:
UPDATE accounts SET balance = balance - 10000 WHERE account_id = 2; -- Bob
UPDATE accounts SET balance = balance + 10000 WHERE account_id = 3; -- Charlie

-- Check mid-transaction — Bob's balance would go negative
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- Nope — undo everything
ROLLBACK;

-- Verify restored:
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- ============================================================
-- Exercise 3 — SAVEPOINT checkpoint
-- ============================================================
-- 1. Add $25 to Alice's balance
-- 2. Set a SAVEPOINT
-- 3. Deduct $25 from Charlie (wrong account)
-- 4. ROLLBACK to savepoint
-- 5. Deduct $25 from Bob instead
-- 6. COMMIT

-- Your SQL here:

-- Step 1: Add $25 to Alice
UPDATE accounts SET balance = balance + 25 WHERE account_id = 1;

-- Step 2: Set a savepoint — a "bookmark" you can rewind to
SAVEPOINT before_deduction;

-- Step 3: Deduct $25 from Charlie by mistake
UPDATE accounts SET balance = balance - 25 WHERE account_id = 3;

-- Step 4: Rollback to the savepoint
ROLLBACK TO SAVEPOINT before_deduction;

-- Step 5: Deduct from the correct account (Bob)
UPDATE accounts SET balance = balance - 25 WHERE account_id = 2;

-- Step 6: Commit everything
COMMIT;

-- Verify: Alice=1075, Bob=475, Charlie=200 (from Exercise 1 state)
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- Verify final state:
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- ============================================================
-- Exercise 4 — Write your own stored procedure
-- ============================================================
-- Create deposit_funds(p_account_id, p_amount):
--   1. Validate p_amount > 0 (raise error if not)
--   2. Add p_amount to the account balance
--   3. COMMIT on success
--   4. ROLLBACK + re-raise on any error
-- Test: EXEC deposit_funds(3, 75);

-- Your SQL here:

CREATE OR REPLACE PROCEDURE deposit_funds(
    p_account_id  IN NUMBER,
    p_amount      IN NUMBER
) AS
BEGIN
    -- Step 1: Validate amount
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Deposit amount must be greater than zero.');
    END IF;

    -- Step 2: Add the amount
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_account_id;

    -- Step 3: Commit on success
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Deposit of $' || p_amount || ' to account ' || p_account_id || ' successful.');

EXCEPTION
    WHEN OTHERS THEN
        -- Step 4: Rollback and re-raise on any error
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Deposit failed. Changes rolled back.');
        RAISE;
END;
/

-- Test it
SET SERVEROUTPUT ON;
EXEC deposit_funds(3, 75);

-- Verify
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- Test the validation
EXEC deposit_funds(3, -50);  -- Should error


-- ============================================================
-- Exercise 5 — Discussion (answer in comments)
-- ============================================================

-- Q1: You're building a patient appointment booking system.
-- A booking requires:
--   a) Reserve the time slot
--   b) Create the appointment record
--   c) Send a confirmation notification
-- Which of these should be inside the transaction? Which should be outside? Why?

-- A1:
-- Inside the transaction: 
--     a and b, reserving the slot and creating the appointment 
--     record must succeed or fail together.
-- Outside the transaction: 
--     c, an email or SMS thats already been sent to the patient cant be ROLLBACK. 
--     Fire the notification only after the COMMIT confirms everything succeeded.


-- Q2: Your stored procedure calls COMMIT at the end.
-- A developer calls your procedure from inside their own larger transaction.
-- What problem does this create?

-- A2:
-- The procedure's COMMIT will commit the entire outer transaction too, 
-- not just its own piece. The developer loses control of when things get 
-- finalized. If their larger transaction fails afterward and they try to ROLLBACK, 
-- it's too late.

-- Q3: You have a function called calculate_copay() and a procedure called post_payment().
-- A colleague wants to use calculate_copay() inside a SELECT statement.
-- Can they? Can they do the same with post_payment()? Why or why not?

-- A3:
-- Yes, calculate_copay() can be used in a SELECT functions are designed for this, 
-- they take inputs and return a value without modifying anything, post_payment() cannot. 
-- Procedures perform actions (modifying data, committing, rolling back) You call procedures with EXEC.