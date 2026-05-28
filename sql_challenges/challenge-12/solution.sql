-- ============================================================
-- Lesson 07: KPI Dashboards — Solutions
-- ============================================================


-- ============================================================
-- EXERCISE 1: Team Velocity
-- ============================================================
--
-- 1. What is the business question?
-- How fast does each team ship completed work?

-- 2. What is the exact definition? (Include every filter, every join)
-- completed tasks / days the team has been active
-- (days since the oldest assigned task was created).
-- No story points available — raw task count is the proxy.

-- 3. What are the edge cases? (NULLs, cancelled tasks, unassigned tasks, etc.)
-- teams with no tasks get NULL velocity (NULLIF guard).
-- Cancelled tasks are excluded from completed count.

-- 4. What is the unit? (Count, percentage, hours, dollars?)
-- tasks per day (and tasks per member per day for normalization).

-- 5. What would make this metric misleading?
-- task size varies wildly, or a team finishes many
-- trivial tasks while another ships fewer but harder ones.
-- Per-member normalization partially corrects for headcount differences.

WITH team_stats AS (
    SELECT
        t.id AS team_id,
        t.name AS team_name,
        COUNT(DISTINCT u.id) AS team_size,
        COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) AS completed_tasks,
        TRUNC(SYSDATE) - TRUNC(MIN(CAST(ts.created_at AS DATE))) + 1 AS days_active
    FROM teams t
    LEFT JOIN users u ON u.team_id    = t.id
    LEFT JOIN tasks ts ON ts.assigned_to = u.id
    GROUP BY t.id, t.name
),
velocity AS (
    SELECT
        team_name,
        team_size,
        completed_tasks,
        days_active,
        ROUND(completed_tasks / NULLIF(days_active, 0), 3) AS velocity_per_day,
        ROUND(completed_tasks / NULLIF(team_size * days_active, 0), 4) AS velocity_per_member_per_day
    FROM team_stats
)
SELECT
    team_name,
    team_size,
    completed_tasks,
    days_active,
    velocity_per_day,
    velocity_per_member_per_day,
    CASE
        WHEN velocity_per_day < AVG(velocity_per_day) OVER ()
        THEN 'BELOW AVERAGE'
        ELSE 'AT OR ABOVE AVERAGE'
    END AS velocity_flag
FROM velocity
ORDER BY velocity_per_day DESC NULLS LAST;


-- ============================================================
-- EXERCISE 2: On-Time Delivery Rate
-- ============================================================
--
-- 1. What is the business question?
-- Do we complete tasks on or before the deadline?

-- 2. What is the exact definition? (Include every filter, every join)
-- on-time = completed_at date <= due_date (end-of-day boundary).
-- Tasks with no due_date are excluded — unknown deadline cannot be judged.
-- Cancelled tasks are excluded — they were never delivered.
-- A task completed at 23:59 on due_date is ON TIME;
-- a task completed at 00:01 the next day is LATE.

-- 3. What are the edge cases? (NULLs, cancelled tasks, unassigned tasks, etc.)
-- NULL completed_at (not yet done), NULL due_date.

-- 4. What is the unit? (Count, percentage, hours, dollars?)
-- percentage (0–100) per priority band.

-- 5. What would make this metric misleading?
-- Misleading if: due dates are routinely pushed out before completion,
-- or if "high" priority tasks get more time than "low" ones.

SELECT
    priority,
    COUNT(*) AS completed_tasks,
    COUNT(CASE WHEN TRUNC(CAST(completed_at AS DATE)) <= due_date THEN 1 END) AS on_time_count,
    ROUND(
        100 * COUNT(CASE WHEN TRUNC(CAST(completed_at AS DATE)) <= due_date THEN 1 END)
            / NULLIF(COUNT(*), 0)
    , 1) AS on_time_rate_pct,
    ROUND(
        AVG(CASE
            WHEN TRUNC(CAST(completed_at AS DATE)) > due_date
            THEN (CAST(completed_at AS DATE) - due_date) * 24
        END)
    , 1) AS avg_late_hours
FROM tasks
WHERE status = 'completed'
  AND completed_at IS NOT NULL
  AND due_date IS NOT NULL
GROUP BY priority
ORDER BY CASE priority
              WHEN 'critical' THEN 1
              WHEN 'high' THEN 2
              WHEN 'medium' THEN 3
              WHEN 'low' THEN 4
          END;


-- ============================================================
-- EXERCISE 3: Improved Tasks per Team
-- ============================================================
--
-- Fix: 
-- Separates active workload from historical total,
-- computes a completion rate that ignores cancelled tasks,
-- and labels each team's current load health.

SELECT
    t.name AS team_name,
    COUNT(ts.id) AS total_tasks,
    COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 END) AS active_tasks,
    ROUND(
        100 * COUNT(CASE WHEN ts.status = 'completed' THEN 1 END)
            / NULLIF(COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END), 0)
    , 1)  AS completion_rate_pct,
    CASE
        WHEN COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 END) > 10
            THEN 'Overloaded'
        WHEN COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 END) >= 5
            THEN 'Healthy'
        ELSE 'Underutilized'
    END AS health_score
FROM teams t
LEFT JOIN users u ON u.team_id = t.id
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY active_tasks DESC;


-- ============================================================
-- EXERCISE 4: Improved Average Resolution Time by Priority
-- ============================================================
--
-- Fix:
-- Breaks down resolution time per priority, adds median
-- (less sensitive to outliers than mean), min/max extremes,
-- SLA target validation, and a data-quality warning for tiny samples.

SELECT
    priority,
    COUNT(*) AS completed_count,
    ROUND(AVG(
        EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1) AS avg_resolution_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY
        EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1) AS median_resolution_hours,
    ROUND(MIN(
        EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1) AS fastest_resolution_hours,
    ROUND(MAX(
        EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1) AS slowest_resolution_hours,
    CASE
        WHEN AVG(
            EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
            EXTRACT(HOUR FROM (completed_at - created_at)) +
            EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
        ) <= CASE priority
                 WHEN 'critical' THEN 24
                 WHEN 'high' THEN 72
                 WHEN 'medium' THEN 168
                 ELSE 336
             END
        THEN 'SLA MET'
        ELSE 'SLA MISSED'
    END                                                                    AS sla_status,
    CASE WHEN COUNT(*) = 1
         THEN '** Single sample — interpret with caution **'
    END                                                                    AS data_quality_note
FROM tasks
WHERE status = 'completed'
  AND completed_at IS NOT NULL
GROUP BY priority
ORDER BY CASE priority
              WHEN 'critical' THEN 1
              WHEN 'high' THEN 2
              WHEN 'medium' THEN 3
              WHEN 'low' THEN 4
          END;


-- ============================================================
-- EXERCISE 5: Improved Overdue Tasks Report
-- ============================================================
--
-- Fix:
-- Replaces a bare COUNT with a full actionable report that
-- names the owner, quantifies lateness, and classifies severity
-- so the business can triage by impact, not just count.

-- Part A: Detailed per-task report
WITH overdue AS (
    SELECT
        ts.title,
        u.full_name AS assignee,
        t.name AS team,
        ts.priority,
        ts.due_date,
        TRUNC(SYSDATE) - ts.due_date AS days_overdue,
        CASE
            WHEN ts.priority = 'critical' THEN 'CRITICAL'
            WHEN ts.priority = 'high' AND TRUNC(SYSDATE) - ts.due_date > 2 THEN 'HIGH'
            WHEN ts.priority = 'medium' AND TRUNC(SYSDATE) - ts.due_date > 5 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS severity
    FROM tasks ts
    LEFT JOIN users u ON u.id = ts.assigned_to
    LEFT JOIN teams t ON t.id = u.team_id
    WHERE ts.due_date < TRUNC(SYSDATE)
      AND ts.status NOT IN ('completed', 'cancelled')
      AND ts.due_date IS NOT NULL
)
SELECT title, assignee, team, priority, due_date, days_overdue, severity
FROM overdue
ORDER BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        ELSE 4
    END,
    days_overdue DESC;

-- Part B: Summary with totals via ROLLUP
WITH overdue AS (
    SELECT
        TRUNC(SYSDATE) - ts.due_date AS days_overdue,
        CASE
            WHEN ts.priority = 'critical' THEN 'CRITICAL'
            WHEN ts.priority = 'high' AND TRUNC(SYSDATE) - ts.due_date > 2 THEN 'HIGH'
            WHEN ts.priority = 'medium' AND TRUNC(SYSDATE) - ts.due_date > 5 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS severity
    FROM tasks ts
    WHERE ts.due_date < TRUNC(SYSDATE)
      AND ts.status NOT IN ('completed', 'cancelled')
      AND ts.due_date IS NOT NULL
)
SELECT
    NVL(severity, 'TOTAL') AS severity,
    COUNT(*) AS overdue_count,
    ROUND(AVG(days_overdue), 1) AS avg_days_overdue
FROM overdue
GROUP BY ROLLUP(severity)
ORDER BY
    CASE NVL(severity, 'TOTAL')
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
        ELSE 5
    END;


-- ============================================================
-- EXERCISE 6: Fix the "Productivity Score"
-- ============================================================
--
-- PROBLEM: 
-- The original query counts every task ever assigned, regardless
-- of status. A user with 10 open (unstarted) tasks scores the same as one
-- who completed 10 tasks. It also uses INNER JOIN, silently excluding users
-- with no tasks. Priority and task complexity are completely ignored, so a
-- string of trivial tasks outscores one hard critical fix.
--
-- REWRITE: 
-- Weight completed tasks by priority and normalise per active day.
-- This measures output (completed, weighted by importance), not input (assigned).

SELECT
    u.full_name,
    COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) AS completed_tasks,
    TRUNC(SYSDATE) - TRUNC(MIN(CAST(ts.created_at AS DATE))) + 1 AS days_active,
    ROUND(
        SUM(CASE ts.status
                WHEN 'completed' THEN
                    CASE ts.priority
                        WHEN 'critical' THEN 4
                        WHEN 'high' THEN 3
                        WHEN 'medium' THEN 2
                        WHEN 'low' THEN 1
                        ELSE 0
                    END
                ELSE 0
            END)
        / NULLIF(TRUNC(SYSDATE) - TRUNC(MIN(CAST(ts.created_at AS DATE))) + 1, 0)
    , 3) AS weighted_productivity_per_day
FROM users u
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY u.id, u.full_name
ORDER BY weighted_productivity_per_day DESC NULLS LAST;


-- ============================================================
-- EXERCISE 7: Fix the "Team Efficiency"
-- ============================================================
--
-- PROBLEM: 
-- AVG(ts.id) averages the auto-increment primary key — a
-- sequential integer assigned at insert time. It has no relationship to
-- workload, speed, or quality. The result is a meaningless number that
-- happens to grow with the ID sequence. INNER JOIN also hides teams with
-- no tasks.
--
-- REWRITE:
-- Efficiency = ratio of completed tasks to total tasks (0–100 %).
-- Teams that finish what they start are efficient; those with many open or
-- blocked tasks are not.

SELECT
    t.name AS team_name,
    COUNT(ts.id) AS total_tasks,
    COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) AS completed_tasks,
    ROUND(
        100 * COUNT(CASE WHEN ts.status = 'completed' THEN 1 END)
            / NULLIF(COUNT(ts.id), 0)
    , 1) AS completion_rate_pct
FROM teams t
LEFT JOIN users u ON u.team_id = t.id
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY completion_rate_pct DESC NULLS LAST;


-- ============================================================
-- EXERCISE 8: Fix the "Urgency Index"
-- ============================================================
--
-- PROBLEM: 
-- Priority is VARCHAR2 — multiplying a string by 10 is a
-- type error and produces ORA-01722 (invalid number). due_date is a DATE —
-- adding a number to a string operand would also fail. The expression
-- has no mathematical meaning even conceptually.
--
-- REWRITE: 
-- Convert priority to a numeric weight (critical=4 … low=1),
-- then subtract days_until_due so that tasks due soon (or already overdue)
-- get a higher score. Formula: urgency = priority_weight − days_until_due.
-- Larger result = more urgent.

SELECT
    title,
    priority,
    status,
    due_date,
    TRUNC(due_date) - TRUNC(SYSDATE) AS days_until_due,
    CASE priority
        WHEN 'critical' THEN 4
        WHEN 'high' THEN 3
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 1
    END - (TRUNC(due_date) - TRUNC(SYSDATE)) AS urgency_score,
    CASE
        WHEN TRUNC(due_date) - TRUNC(SYSDATE) < 0 THEN 'OVERDUE'
        WHEN TRUNC(due_date) - TRUNC(SYSDATE) = 0 THEN 'DUE TODAY'
        WHEN TRUNC(due_date) - TRUNC(SYSDATE) <= 2 THEN 'DUE SOON'
        ELSE 'ON TRACK'
    END AS urgency_label
FROM tasks
WHERE status NOT IN ('completed', 'cancelled')
  AND due_date IS NOT NULL
ORDER BY urgency_score DESC;
