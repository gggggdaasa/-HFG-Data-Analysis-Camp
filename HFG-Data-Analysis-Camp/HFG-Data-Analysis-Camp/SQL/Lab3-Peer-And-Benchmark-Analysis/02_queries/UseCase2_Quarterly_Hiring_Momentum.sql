/*
Q2: Quarterly Hiring Momentum

Business Case: HR wants to understand hiring momentum by seeing how many
employees were hired in the 3 months before and after each hire date, to
optimize recruitment campaigns.

Task: Show hiring activity within a 3-month rolling window (3 months before
OR after each hire date).

Note: This is a date-range rolling window, not a row-based one, so a
correlated subquery with DATEADD is used.
*/

SELECT
    e1.employee_id,
    CONCAT(e1.first_name, ' ', e1.last_name)   AS employee_name,
    e1.hire_date,
    (
        SELECT COUNT(*)
        FROM employees e2
        WHERE e2.hire_date BETWEEN DATEADD(MONTH, -3, e1.hire_date)
                                AND DATEADD(MONTH, 3, e1.hire_date)
          AND e2.employee_id <> e1.employee_id
    )                                            AS hires_within_3_months
FROM employees e1
ORDER BY e1.hire_date;
