/*
=====================================================================
Lab 2 - Analytical SQL with HR Database
Window Functions Practice: Ranking, Distribution & Framing (T-SQL)
=====================================================================
IMPORTANT: Run this against the HR database, not master/tempdb/model/msdb.
If you haven't created it yet:
    CREATE DATABASE HR_Database;
Then make sure the query window is pointed at HR_Database (top dropdown
in SSMS) before running SQLDay1.sql and then this file.
=====================================================================
*/

----------------------------------------------------------------------
-- Question 1: Top Performers Analysis
-- Business Context: Identify top 25% performers in each department
-- based on salary for a special bonus program.
----------------------------------------------------------------------

WITH ranked AS (
    SELECT
        employee_id,
        CONCAT(first_name, ' ', last_name)     AS employee_name,
        department_id,
        salary,
        PERCENT_RANK() OVER (
            PARTITION BY department_id
            ORDER BY salary DESC
        )                                        AS salary_percentile
    FROM employees
)
SELECT *
FROM ranked
WHERE salary_percentile <= 0.25
ORDER BY department_id, salary DESC;


----------------------------------------------------------------------
-- Question 2: Commission Percentile Analysis
-- Business Context: Identify sales reps in the bottom 30% of
-- commission rates for targeted coaching.
----------------------------------------------------------------------

WITH comm_rank AS (
    SELECT
        e.employee_id,
        CONCAT(e.first_name, ' ', e.last_name)  AS employee_name,
        e.commission_pct,
        e.manager_id,
        CONCAT(m.first_name, ' ', m.last_name)  AS manager_name,
        PERCENT_RANK() OVER (
            ORDER BY e.commission_pct ASC
        )                                        AS commission_percentile
    FROM employees e
    LEFT JOIN employees m ON e.manager_id = m.employee_id
    WHERE e.commission_pct IS NOT NULL
)
SELECT *
FROM comm_rank
WHERE commission_percentile <= 0.30
ORDER BY commission_pct;


----------------------------------------------------------------------
-- Question 3: Employee Segmentation by Tenure
-- Business Context: Create 5 employee segments based on tenure for
-- a differentiated benefits program.
----------------------------------------------------------------------

SELECT
    employee_id,
    CONCAT(first_name, ' ', last_name)          AS employee_name,
    hire_date,
    DATEDIFF(YEAR, hire_date, GETDATE())        AS tenure_years,
    NTILE(5) OVER (ORDER BY hire_date ASC)      AS tenure_quintile
FROM employees
ORDER BY tenure_quintile, hire_date;


----------------------------------------------------------------------
-- Question 4: Department Size Classification
-- Business Context: Classify departments into 3 categories (small,
-- medium, large) based on employee count for resource allocation.
----------------------------------------------------------------------

WITH dept_counts AS (
    SELECT department_id, COUNT(*) AS employee_count
    FROM employees
    GROUP BY department_id
),
sized AS (
    SELECT
        department_id,
        employee_count,
        NTILE(3) OVER (ORDER BY employee_count) AS size_tier
    FROM dept_counts
)
SELECT
    department_id,
    employee_count,
    size_tier,
    CASE size_tier
        WHEN 1 THEN 'Small'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'Large'
    END AS size_label
FROM sized
ORDER BY employee_count DESC;


----------------------------------------------------------------------
-- Question 5: Running Department Headcount
-- Business Context: Track cumulative hiring by department to
-- understand growth patterns over time.
----------------------------------------------------------------------

SELECT
    employee_id,
    CONCAT(first_name, ' ', last_name)  AS employee_name,
    department_id,
    hire_date,
    COUNT(*) OVER (
        PARTITION BY department_id
        ORDER BY hire_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                     AS running_headcount
FROM employees
ORDER BY department_id, hire_date;


----------------------------------------------------------------------
-- Question 6: Salary Comparison with Adjacent Peers
-- Business Context: Compare each employee's salary with their
-- immediate neighbors (alphabetically) to identify sudden jumps.
----------------------------------------------------------------------

SELECT
    employee_id,
    last_name,
    salary,
    LAG(salary)  OVER (ORDER BY last_name)              AS prev_salary,
    LEAD(salary) OVER (ORDER BY last_name)              AS next_salary,
    salary - LAG(salary) OVER (ORDER BY last_name)      AS diff_from_prev
FROM employees
ORDER BY last_name;


----------------------------------------------------------------------
-- Question 7: 5-Employee Moving Average Salary
-- Business Context: Smooth out salary variations by calculating
-- moving averages for anomaly detection.
----------------------------------------------------------------------

WITH moving_avg AS (
    SELECT
        employee_id,
        CONCAT(first_name, ' ', last_name)  AS employee_name,
        department_id,
        salary,
        AVG(salary) OVER (
            PARTITION BY department_id
            ORDER BY salary
            ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
        )                                     AS moving_avg_salary
    FROM employees
)
SELECT
    *,
    ROUND(100.0 * ABS(salary - moving_avg_salary) / moving_avg_salary, 2) AS pct_deviation
FROM moving_avg
WHERE ABS(salary - moving_avg_salary) / moving_avg_salary > 0.20
ORDER BY pct_deviation DESC;


----------------------------------------------------------------------
-- Question 8: Cumulative Commission Calculation
-- Business Context: Calculate cumulative commission paid per
-- department for budget tracking.
----------------------------------------------------------------------

WITH commissioned AS (
    SELECT
        employee_id,
        department_id,
        hire_date,
        salary * commission_pct AS commission_amount
    FROM employees
    WHERE commission_pct IS NOT NULL
),
dept_qualify AS (
    SELECT department_id
    FROM commissioned
    GROUP BY department_id
    HAVING COUNT(*) >= 5
)
SELECT
    c.employee_id,
    c.department_id,
    c.hire_date,
    c.commission_amount,
    SUM(c.commission_amount) OVER (
        PARTITION BY c.department_id
        ORDER BY c.hire_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                        AS running_commission_total
FROM commissioned c
JOIN dept_qualify dq ON c.department_id = dq.department_id
ORDER BY c.department_id, c.hire_date;


----------------------------------------------------------------------
-- Question 9: Salary Range Analysis - ROWS vs RANGE
-- Business Context: Understand the difference between position-based
-- and value-based windowing.
----------------------------------------------------------------------

SELECT
    CONCAT(first_name, ' ', last_name) AS employee_name,
    department_id,
    salary,
    SUM(salary) OVER (
        PARTITION BY department_id
        ORDER BY salary
        ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING
    )                                     AS sum_rows_based,
    SUM(salary) OVER (
        PARTITION BY department_id
        ORDER BY salary
        RANGE BETWEEN 500 PRECEDING AND 500 FOLLOWING
    )                                     AS sum_range_based
FROM employees
ORDER BY department_id, salary;

-- ROWS vs RANGE -- the difference:
-- ROWS counts a fixed number of *physical rows* around the current row
-- (exactly 3 before + current + 3 after = up to 7 rows), regardless of
-- how close their salary values actually are.
-- RANGE instead looks at the *value* of ORDER BY (salary) and includes
-- every row whose salary falls within +/- 500 of the current row's salary
-- (any number of rows, and ties are all included together).
-- So two employees with the exact same salary get an IDENTICAL
-- sum_range_based (RANGE treats tied values as one "peer group"), but
-- can get DIFFERENT sum_rows_based if their position among the ordered
-- rows differs.


----------------------------------------------------------------------
-- Question 10: Finding Salary Peers
-- Business Context: For each employee, find all colleagues earning
-- within $1000 of their salary for peer comparison.
----------------------------------------------------------------------

WITH peers AS (
    SELECT
        employee_id,
        CONCAT(first_name, ' ', last_name) AS employee_name,
        salary,
        COUNT(*) OVER (
            ORDER BY salary
            RANGE BETWEEN 1000 PRECEDING AND 1000 FOLLOWING
        ) - 1                                AS peer_count
    FROM employees
)
SELECT *
FROM peers
WHERE peer_count >= 3
ORDER BY salary;
