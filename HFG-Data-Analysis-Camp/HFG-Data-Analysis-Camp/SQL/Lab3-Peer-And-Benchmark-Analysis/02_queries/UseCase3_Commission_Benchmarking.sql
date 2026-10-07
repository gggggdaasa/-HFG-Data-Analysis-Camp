/*
Q3: Commission Benchmarking

Business Case: Sales management wants to compare each sales representative's
commission rate against the lowest and highest commission rates in the Sales
department.

Task: Show each sales employee with the min and max commission rates in their
department, using FIRST_VALUE / LAST_VALUE.

Note: LAST_VALUE requires an explicit ROWS BETWEEN UNBOUNDED PRECEDING AND
UNBOUNDED FOLLOWING frame — the default frame only looks back to the current
row, which would make LAST_VALUE return the current row's own value.
*/

SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name)     AS employee_name,
    d.department_name,
    e.commission_pct,
    FIRST_VALUE(e.commission_pct) OVER (
        PARTITION BY e.department_id
        ORDER BY e.commission_pct ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                            AS min_commission_rate,
    LAST_VALUE(e.commission_pct) OVER (
        PARTITION BY e.department_id
        ORDER BY e.commission_pct ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                            AS max_commission_rate
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'Sales'
  AND e.commission_pct IS NOT NULL
ORDER BY e.commission_pct DESC;
