
-- Step 1

CREATE TABLE tickets (
    ticket_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title        VARCHAR2(200) NOT NULL,
    status       VARCHAR2(20)  DEFAULT 'open'   NOT NULL,
    priority     VARCHAR2(10)  DEFAULT 'medium' NOT NULL,
    assigned_to  NUMBER,
    created_at   TIMESTAMP     DEFAULT SYSTIMESTAMP,
    resolved_at  TIMESTAMP
);

CREATE TABLE ticket_assignments (
    assignment_id NUMBER    GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id     NUMBER    NOT NULL REFERENCES tickets(ticket_id),
    assigned_to   NUMBER    NOT NULL,
    assigned_by   NUMBER,
    valid_from    TIMESTAMP NOT NULL,
    valid_to      TIMESTAMP
);


-- Step 2

INSERT INTO tickets (title, status, priority, assigned_to, created_at, resolved_at) VALUES
('Cannot login to portal',     'resolved',    'high',     1, TIMESTAMP '2026-04-01 08:00:00', TIMESTAMP '2026-04-01 10:30:00');
INSERT INTO tickets (title, status, priority, assigned_to, created_at, resolved_at) VALUES
('Payment processing error',   'resolved',    'critical', 2, TIMESTAMP '2026-04-02 09:00:00', TIMESTAMP '2026-04-02 11:00:00');
INSERT INTO tickets (title, status, priority, assigned_to, created_at, resolved_at) VALUES
('Slow dashboard loading',     'resolved',    'medium',   1, TIMESTAMP '2026-04-03 10:00:00', TIMESTAMP '2026-04-04 14:00:00');
INSERT INTO tickets (title, status, priority, assigned_to, created_at, resolved_at) VALUES
('Password reset not working', 'in_progress', 'high',     3, TIMESTAMP '2026-04-05 11:00:00', NULL);
INSERT INTO tickets (title, status, priority, assigned_to, created_at, resolved_at) VALUES
('Export CSV missing columns', 'open',        'low',      1, TIMESTAMP '2026-04-06 14:00:00', NULL);
COMMIT;


-- Step 3

CREATE OR REPLACE TRIGGER trg_ticket_assignment_log
    AFTER INSERT OR UPDATE OF assigned_to ON tickets
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, NULL, :NEW.created_at);
    ELSIF UPDATING THEN
        UPDATE ticket_assignments
           SET valid_to = SYSTIMESTAMP
         WHERE ticket_id = :OLD.ticket_id
           AND valid_to IS NULL;

        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, NULL, SYSTIMESTAMP);
    END IF;
END;
/

-- Reassign ticket 3 from agent 1 to agent 2
UPDATE tickets SET assigned_to = 2 WHERE ticket_id = 3;
COMMIT;

-- Verify: both old and new assignment are recorded
SELECT ticket_id, assigned_to, valid_from, valid_to
FROM   ticket_assignments
WHERE  ticket_id = 3
ORDER  BY valid_from;


-- Step 4

CREATE TABLE dim_agent (
    agent_key   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_name  VARCHAR2(100) NOT NULL,
    team        VARCHAR2(50)  NOT NULL
);

CREATE TABLE fact_ticket_daily (
    date_key          NUMBER       NOT NULL,
    agent_key         NUMBER       NOT NULL REFERENCES dim_agent(agent_key),
    status            VARCHAR2(20) NOT NULL,
    priority          VARCHAR2(10) NOT NULL,
    tickets_created   NUMBER       DEFAULT 0,
    tickets_resolved  NUMBER       DEFAULT 0
);


-- Step 5

INSERT INTO dim_agent (agent_name, team) VALUES ('Sara Lopez',  'Tier-1 Support');
INSERT INTO dim_agent (agent_name, team) VALUES ('Tom Baker',   'Tier-2 Support');
INSERT INTO dim_agent (agent_name, team) VALUES ('Nina Patel',  'Tier-1 Support');
INSERT INTO dim_agent (agent_name, team) VALUES ('Omar Hassan', 'Tier-2 Support');
COMMIT;


-- Step 6

-- See Colab notebook


-- Step 7

SELECT
    f.date_key,
    a.agent_name,
    a.team,
    f.status,
    f.priority,
    f.tickets_created,
    f.tickets_resolved
FROM  fact_ticket_daily f
JOIN  dim_agent         a ON a.agent_key = f.agent_key
ORDER BY f.date_key, a.agent_name;
