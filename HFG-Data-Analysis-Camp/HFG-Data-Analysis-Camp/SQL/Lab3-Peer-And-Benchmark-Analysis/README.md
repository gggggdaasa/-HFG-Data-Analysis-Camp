# Lab 3 - Analytical SQL with HR Database
### Peer & Benchmark Analysis (T-SQL / SQL Server) — Value-Based Windows, Framing & FIRST_VALUE/LAST_VALUE

---

## Question 1: Salary Adjustment Window Analysis

**Business Context:** The compensation team is reviewing salary adjustments. They want to identify employees whose salary sits within $2,000 of other employees' salaries, to understand potential compensation review peer groups.

**Task:** For each employee, calculate how many employees have salaries within $2,000 of their salary level.

**Note:** This is a *value-based* range, not a row-based one — T-SQL window frames (`ROWS`/`RANGE`) only support offsets by row count or `UNBOUNDED`/`CURRENT ROW`, not by an arbitrary value like "$2,000". A correlated subquery is used instead.

**Query:**

```sql
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
```

---

## Question 2: Quarterly Hiring Momentum

**Business Context:** HR wants to understand hiring momentum by seeing how many employees were hired in the 3 months before and after each hire date, to optimize recruitment campaigns.

**Task:** Show hiring activity within a 3-month rolling window (3 months before **or** after each hire date).

**Note:** Same idea as Q1 but on dates — a date-range rolling window, so `DATEADD` inside a correlated subquery is used rather than a window frame.

**Query:**

```sql
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
```

---

## Question 3: Commission Benchmarking

**Business Context:** Sales management wants to compare each sales representative's commission rate against the lowest and highest commission rates in the Sales department.

**Task:** Show each sales employee with the min and max commission rates in their department, using `FIRST_VALUE` / `LAST_VALUE`.

**Note:** `LAST_VALUE` needs an explicit `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` frame — the default frame only looks back to the current row, so without it `LAST_VALUE` would just return the current row's own value instead of the true maximum.

**Query:**

```sql
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
```

---

## Question 4: Salary Range by Job Title

**Business Context:** Recruitment team needs to know the minimum and maximum salary for each job title to create competitive job postings.

**Task:** Display each employee with the salary range (min/max) for their job title.

**Query:**

```sql
SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name)     AS employee_name,
    j.job_title,
    e.salary,
    MIN(e.salary) OVER (PARTITION BY e.job_id) AS min_salary_for_job,
    MAX(e.salary) OVER (PARTITION BY e.job_id) AS max_salary_for_job
FROM employees e
JOIN jobs j ON e.job_id = j.job_id
ORDER BY j.job_title, e.salary DESC;
```

---

## Question 5: Premium Jobs Analysis

**Business Context:** Talent acquisition wants to identify "premium" jobs — those where the average employee salary exceeds the job's midpoint salary by 10% or more.

**Task:** Find jobs where the actual average salary exceeds the expected midpoint salary (`(min_salary + max_salary) / 2`) by 10%+.

**Query:**

```sql
WITH job_avg AS (
    SELECT
        e.job_id,
        AVG(e.salary) AS avg_salary
    FROM employees e
    GROUP BY e.job_id
)
SELECT
    j.job_id,
    j.job_title,
    j.min_salary,
    j.max_salary,
    (j.min_salary + j.max_salary) / 2.0            AS midpoint_salary,
    ja.avg_salary,
    ROUND(
        (ja.avg_salary - (j.min_salary + j.max_salary) / 2.0)
        / ((j.min_salary + j.max_salary) / 2.0) * 100,
        2
    )                                                AS pct_above_midpoint
FROM jobs j
JOIN job_avg ja ON j.job_id = ja.job_id
WHERE ja.avg_salary > (j.min_salary + j.max_salary) / 2.0 * 1.10
ORDER BY pct_above_midpoint DESC;
```

---

## Files

- `02_queries/UseCase1_Salary_Adjustment_Window.sql`
- `02_queries/UseCase2_Quarterly_Hiring_Momentum.sql`
- `02_queries/UseCase3_Commission_Benchmarking.sql`
- `02_queries/UseCase4_Salary_Range_By_Job_Title.sql`
- `02_queries/UseCase5_Premium_Jobs_Analysis.sql`
- `Lab3_Queries_Only.sql` — all five queries combined in one file
