# Lab 2 - Analytical SQL with HR Database
### Window Functions Practice (T-SQL / SQL Server) — Ranking, Distribution & Framing

---

## Question 1: Top Performers Analysis

**Business Context:** The company wants to identify top 25% performers in each department based on salary for a special bonus program.

**Task:** Show employee details (id, name, department, salary), their salary percentile rank within their department, and filter to show only employees in the top 25% (`percent_rank <= 0.25`).

**Query:**

```sql
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
```

**Result** (36 employees qualify — top 10 shown):

| Employee ID | Employee | Department ID | Salary | Salary Percentile |
|---|---|---|---|---|
| 178 | Kimberely Grant |  | 7000.0 | 0.0 |
| 200 | Jennifer Whalen | 10 | 4400.0 | 0.0 |
| 201 | Michael Hartstein | 20 | 13000.0 | 0.0 |
| 114 | Den Raphaely | 30 | 11000.0 | 0.0 |
| 115 | Alexander Khoo | 30 | 3100.0 | 0.2 |
| 203 | Susan Mavris | 40 | 6500.0 | 0.0 |
| 121 | Adam Fripp | 50 | 8200.0 | 0.0 |
| 120 | Matthew Weiss | 50 | 8000.0 | 0.0227 |
| 122 | Payam Kaufling | 50 | 7900.0 | 0.0455 |
| 123 | Shanta Vollman | 50 | 6500.0 | 0.0682 |

---

## Question 2: Commission Percentile Analysis

**Business Context:** Sales leadership wants to identify sales representatives in the bottom 30% of commission rates for targeted coaching.

**Task:** For employees with non-null `commission_pct`, calculate their commission percentile rank, filter those in the bottom 30% (`percent_rank <= 0.30`), and include their manager information.

**Query:**

```sql
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
```

**Result** (11 employees qualify):

| Employee ID | Employee | Commission % | Manager | Commission Percentile |
|---|---|---|---|---|
| 164 | Mattea Marvins | 0.1 | Alberto Errazuriz | 0.0 |
| 165 | David Lee | 0.1 | Alberto Errazuriz | 0.0 |
| 166 | Sundar Ande | 0.1 | Alberto Errazuriz | 0.0 |
| 167 | Amit Banda | 0.1 | Alberto Errazuriz | 0.0 |
| 173 | Sundita Kumar | 0.1 | Gerald Cambrault | 0.0 |
| 179 | Charles Johnson | 0.1 | Eleni Zlotkey | 0.0 |
| 155 | Oliver Tuvault | 0.15 | John Russell | 0.1765 |
| 163 | Danielle Greene | 0.15 | Alberto Errazuriz | 0.1765 |
| 171 | William Smith | 0.15 | Gerald Cambrault | 0.1765 |
| 172 | Elizabeth Bates | 0.15 | Gerald Cambrault | 0.1765 |
| 178 | Kimberely Grant | 0.15 | Eleni Zlotkey | 0.1765 |

---

## Question 3: Employee Segmentation by Tenure

**Business Context:** Create 5 employee segments based on tenure for a differentiated benefits program.

**Task:** Calculate employee tenure in years from `hire_date`, divide employees into 5 equal groups (quintiles) based on tenure, and show quintile distribution with employee count per segment.

**Query:**

```sql
SELECT
    employee_id,
    CONCAT(first_name, ' ', last_name)          AS employee_name,
    hire_date,
    DATEDIFF(YEAR, hire_date, GETDATE())        AS tenure_years,
    NTILE(5) OVER (ORDER BY hire_date ASC)      AS tenure_quintile
FROM employees
ORDER BY tenure_quintile, hire_date;
```

**Result** (sample rows, oldest-hired quintile first):

| Employee ID | Employee | Hire Date | Tenure (yrs) | Quintile |
|---|---|---|---|---|
| 102 | Lex De Haan | 2001-01-13 | 25.56 | 1 |
| 203 | Susan Mavris | 2002-06-07 | 24.16 | 1 |
| 204 | Hermann Baer | 2002-06-07 | 24.16 | 1 |
| 205 | Shelley Higgins | 2002-06-07 | 24.16 | 1 |
| 206 | William Gietz | 2002-06-07 | 24.16 | 1 |
| 109 | Daniel Faviet | 2002-08-16 | 23.97 | 1 |
| 108 | Nancy Greenberg | 2002-08-17 | 23.96 | 1 |
| 114 | Den Raphaely | 2002-12-07 | 23.66 | 1 |
| 122 | Payam Kaufling | 2003-05-01 | 23.26 | 1 |
| 115 | Alexander Khoo | 2003-05-18 | 23.21 | 1 |
| 100 | Steven King | 2003-06-17 | 23.13 | 1 |
| 137 | Renske Ladwig | 2003-07-14 | 23.06 | 1 |

**Quintile distribution** (107 employees ÷ 5 groups):

| Quintile | Employee Count |
|---|---|
| 1 | 22 |
| 2 | 22 |
| 3 | 21 |
| 4 | 21 |
| 5 | 21 |

---

## Question 4: Department Size Classification

**Business Context:** Classify departments into 3 categories (small = 1, medium = 2, large = 3) based on employee count for resource allocation.

**Task:** Count employees per department, use `NTILE` to create 3 equal-sized groups, and label them 'Small' (1), 'Medium' (2), 'Large' (3).

**Query:**

```sql
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
```

**Result** (all 12 departments with employees):

| Department ID | Employee Count | Size Tier | Size Label |
|---|---|---|---|
| 50 | 45 | 3 | Large |
| 80 | 34 | 3 | Large |
| 30 | 6 | 3 | Large |
| 100 | 6 | 3 | Large |
| 60 | 5 | 2 | Medium |
| 90 | 3 | 2 | Medium |
| 20 | 2 | 2 | Medium |
| 110 | 2 | 2 | Medium |
|  | 1 | 1 | Small |
| 10 | 1 | 1 | Small |
| 40 | 1 | 1 | Small |
| 70 | 1 | 1 | Small |

---

## Question 5: Running Department Headcount

**Business Context:** Track cumulative hiring by department to understand growth patterns over time.

**Task:** Order employees by `hire_date` within each department, and show the cumulative headcount at each hire date.

**Query:**

```sql
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
```

**Result** (Purchasing department, id = 30, shown as example):

| Employee ID | Employee | Department ID | Hire Date | Running Headcount |
|---|---|---|---|---|
| 114 | Den Raphaely | 30 | 2002-12-07 | 1 |
| 115 | Alexander Khoo | 30 | 2003-05-18 | 2 |
| 117 | Sigal Tobias | 30 | 2005-07-24 | 3 |
| 116 | Shelli Baida | 30 | 2005-12-24 | 4 |
| 118 | Guy Himuro | 30 | 2006-11-15 | 5 |
| 119 | Karen Colmenares | 30 | 2007-08-10 | 6 |

---

## Question 6: Salary Comparison with Adjacent Peers

**Business Context:** Compare each employee's salary with their immediate neighbors (alphabetically) to identify sudden jumps.

**Task:** For each employee, show their salary, previous employee's salary, next employee's salary, the difference from previous, ordered by last name.

**Query:**

```sql
SELECT
    employee_id,
    last_name,
    salary,
    LAG(salary)  OVER (ORDER BY last_name)              AS prev_salary,
    LEAD(salary) OVER (ORDER BY last_name)              AS next_salary,
    salary - LAG(salary) OVER (ORDER BY last_name)      AS diff_from_prev
FROM employees
ORDER BY last_name;
```

**Result** (first 12 rows, alphabetical by last name):

| Employee ID | Last Name | Salary | Prev Salary | Next Salary | Diff from Prev |
|---|---|---|---|---|---|
| 174 | Abel | 11000.0 |  | 6400.0 |  |
| 166 | Ande | 6400.0 | 11000.0 | 2800.0 | -4600.0 |
| 130 | Atkinson | 2800.0 | 6400.0 | 4800.0 | -3600.0 |
| 105 | Austin | 4800.0 | 2800.0 | 10000.0 | 2000.0 |
| 204 | Baer | 10000.0 | 4800.0 | 2900.0 | 5200.0 |
| 116 | Baida | 2900.0 | 10000.0 | 6200.0 | -7100.0 |
| 167 | Banda | 6200.0 | 2900.0 | 7300.0 | 3300.0 |
| 172 | Bates | 7300.0 | 6200.0 | 4000.0 | 1100.0 |
| 192 | Bell | 4000.0 | 7300.0 | 9500.0 | -3300.0 |
| 151 | Bernstein | 9500.0 | 4000.0 | 3300.0 | 5500.0 |
| 129 | Bissot | 3300.0 | 9500.0 | 10000.0 | -6200.0 |
| 169 | Bloom | 10000.0 | 3300.0 | 4100.0 | 6700.0 |

---

## Question 7: 5-Employee Moving Average Salary

**Business Context:** Smooth out salary variations by calculating moving averages for anomaly detection.

**Task:** Within each department, calculate the moving average of salary (2 preceding, current, 2 following), ordered by salary, and identify employees whose salary deviates by more than 20% from their moving average.

**Query:**

```sql
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
```

**Result** (8 anomalies found across all departments):

| Employee ID | Employee | Department ID | Salary | Moving Avg Salary | % Deviation |
|---|---|---|---|---|---|
| 114 | Den Raphaely | 30 | 11000.0 | 5666.67 | 94.12 |
| 115 | Alexander Khoo | 30 | 3100.0 | 4950.0 | 37.37 |
| 202 | Pat Fay | 20 | 6000.0 | 9500.0 | 36.84 |
| 201 | Michael Hartstein | 20 | 13000.0 | 9500.0 | 36.84 |
| 103 | Alexander Hunold | 60 | 9000.0 | 6600.0 | 36.36 |
| 116 | Shelli Baida | 30 | 2900.0 | 4480.0 | 35.27 |
| 100 | Steven King | 90 | 24000.0 | 19333.33 | 24.14 |
| 108 | Nancy Greenberg | 100 | 12008.0 | 9736.0 | 23.34 |

---

## Question 8: Cumulative Commission Calculation

**Business Context:** Calculate cumulative commission paid per department for budget tracking.

**Task:** For employees with `commission_pct`, calculate total commission (`salary * commission_pct`), show a running total of commission by department ordered by hire date, and only include departments with at least 5 commissioned employees.

**Query:**

```sql
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
```

**Result** (department 80 - Sales - is the only department with ≥5 commissioned employees; first 12 rows shown):

| Employee ID | Department ID | Hire Date | Commission Amount | Running Commission Total |
|---|---|---|---|---|
| 156 | 80 | 2004-01-30 | 3500.0 | 3500.0 |
| 157 | 80 | 2004-03-04 | 3325.0 | 6825.0 |
| 174 | 80 | 2004-05-11 | 3300.0 | 10125.0 |
| 158 | 80 | 2004-08-01 | 3150.0 | 13275.0 |
| 145 | 80 | 2004-10-01 | 5600.0 | 18875.0 |
| 146 | 80 | 2005-01-05 | 4050.0 | 22925.0 |
| 150 | 80 | 2005-01-30 | 3000.0 | 25925.0 |
| 147 | 80 | 2005-03-10 | 3600.0 | 29525.0 |
| 159 | 80 | 2005-03-10 | 2400.0 | 31925.0 |
| 168 | 80 | 2005-03-11 | 2875.0 | 34800.0 |
| 175 | 80 | 2005-03-19 | 2200.0 | 37000.0 |
| 151 | 80 | 2005-03-24 | 2375.0 | 39375.0 |

---

## Question 9: Salary Range Analysis — ROWS vs RANGE

**Business Context:** Understand the difference between position-based and value-based windowing.

**Task:** Show employee name, department, salary; calculate the sum using `ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING`; calculate the sum using `RANGE BETWEEN 500 PRECEDING AND 500 FOLLOWING`; compare the results.

**Query:**

```sql
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

-- ROWS vs RANGE — the difference:
-- ROWS counts a fixed number of *physical rows* around the current row
-- (exactly 3 before + current + 3 after = up to 7 rows), regardless of
-- how close their salary values actually are.
-- RANGE instead looks at the *value* of ORDER BY (salary) and includes
-- every row whose salary falls within +/- 500 of the current row's salary
-- (any number of rows, and ties are all included together).
-- So two employees with the exact same salary get an IDENTICAL
-- sum_range_based (since RANGE treats tied values as one "peer group"),
-- but can get DIFFERENT sum_rows_based if their position among the
-- ordered rows differs.
```

**Result** (Shipping department, id = 50, shown as example — notice tied salaries like 2200/2200 share the same `sum_range_based` but not always the same `sum_rows_based`):

| Employee | Department ID | Salary | Sum (ROWS ±3) | Sum (RANGE ±500) |
|---|---|---|---|---|
| TJ Olson | 50 | 2100.0 | 8900.0 | 31600.0 |
| Steven Markle | 50 | 2200.0 | 11300.0 | 37000.0 |
| Hazel Philtanker | 50 | 2200.0 | 13800.0 | 37000.0 |
| James Landry | 50 | 2400.0 | 16300.0 | 51200.0 |
| Ki Gee | 50 | 2400.0 | 16700.0 | 51200.0 |
| James Marlow | 50 | 2500.0 | 17000.0 | 57200.0 |
| Joshua Patel | 50 | 2500.0 | 17300.0 | 57200.0 |
| Peter Vargas | 50 | 2500.0 | 17500.0 | 57200.0 |
| Martha Sullivan | 50 | 2500.0 | 17700.0 | 57200.0 |
| Randall Perkins | 50 | 2500.0 | 17800.0 | 57200.0 |

---

## Question 10: Finding Salary Peers

**Business Context:** For each employee, find all colleagues earning within $1000 of their salary for peer comparison.

**Task:** Use `RANGE` to count employees earning within ±$1000, and show only employees who have at least 3 salary peers.

**Query:**

```sql
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
```

**Result** (12+ employees qualify — first 12 rows shown; `-1` excludes the employee from their own peer count):

| Employee ID | Employee | Salary | Peer Count (±$1000) |
|---|---|---|---|
| 132 | TJ Olson | 2100.0 | 29 |
| 128 | Steven Markle | 2200.0 | 33 |
| 136 | Hazel Philtanker | 2200.0 | 33 |
| 127 | James Landry | 2400.0 | 36 |
| 135 | Ki Gee | 2400.0 | 36 |
| 119 | Karen Colmenares | 2500.0 | 37 |
| 131 | James Marlow | 2500.0 | 37 |
| 140 | Joshua Patel | 2500.0 | 37 |
| 144 | Peter Vargas | 2500.0 | 37 |
| 182 | Martha Sullivan | 2500.0 | 37 |
| 191 | Randall Perkins | 2500.0 | 37 |
| 118 | Guy Himuro | 2600.0 | 39 |
