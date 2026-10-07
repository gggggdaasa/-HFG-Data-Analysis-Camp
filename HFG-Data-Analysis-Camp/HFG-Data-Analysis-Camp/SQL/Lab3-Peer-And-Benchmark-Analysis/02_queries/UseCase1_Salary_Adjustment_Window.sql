/*
Q1: Salary Adjustment Window Analysis

Business Case: The compensation team is reviewing salary adjustments. They want
to identify employees whose salary sits within $2,000 of other employees'
salaries, to understand potential compensation review peer groups.

Task: For each employee, calculate how many employees have salaries within
$2,000 of their salary level.

Note: A value-based salary range (not row count) is required, so a correlated
subquery is used rather than a window frame (T-SQL window frames only support
row-based offsets, not value-based ones).
*/

SELECT
    e1.employee_id,
    CONCAT(e1.first_name, ' ', e1.last_name)   AS employee_name,
    e1.department_id,
    e1.salary,
    (
        SELECT COUNT(*)
        FROM employees e2
        WHERE ABS(e2.salary - e1.salary) <= 2000
          AND e2.employee_id <> e1.employee_id
    )                                            AS peers_within_2000
FROM employees e1
ORDER BY e1.salary DESC;
