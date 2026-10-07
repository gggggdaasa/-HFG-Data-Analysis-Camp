# Lab 1 - Analytical SQL with HR Database
### Window Functions Practice (T-SQL / SQL Server)

---

## Use Case 1: Departmental Compensation Analysis

**Business Use Case:** HR managers need visibility into employee compensation by department to identify salary equity issues, benchmark performance, and support compensation planning.

**Objective:** Aggregate compensation metrics (average salary, employee count, highest salary) for each employee's department to support comparative analysis.

**Question:** Show each employee's name, department, salary, job title, the average salary of their department, number of employees in the department, and the maximum salary achieved within the department.

**Query:**

```sql
SELECT
    CONCAT(e.first_name, ' ', e.last_name)                   AS employee_name,
    d.department_name,
    e.salary,
    j.job_title,
    AVG(e.salary) OVER (PARTITION BY e.department_id)        AS dept_avg_salary,
    COUNT(*)      OVER (PARTITION BY e.department_id)        AS dept_employee_count,
    MAX(e.salary) OVER (PARTITION BY e.department_id)        AS dept_max_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN jobs j         ON e.job_id       = j.job_id
ORDER BY d.department_name, e.salary DESC;
```

**Result** (full set: 106 rows — one per employee. Sample below: top earner per department):

| Employee | Department | Salary | Job Title | Dept Avg Salary | Dept Employee Count | Dept Max Salary |
|---|---|---|---|---|---|---|
| Shelley Higgins | Accounting | 12008.0 | Accounting Manager | 10154.0 | 2 | 12008.0 |
| Jennifer Whalen | Administration | 4400.0 | Administration Assistant | 4400.0 | 1 | 4400.0 |
| Steven King | Executive | 24000.0 | President | 19333.33 | 3 | 24000.0 |
| Nancy Greenberg | Finance | 12008.0 | Finance Manager | 8601.33 | 6 | 12008.0 |
| Susan Mavris | Human Resources | 6500.0 | Human Resources Representative | 6500.0 | 1 | 6500.0 |
| Alexander Hunold | IT | 9000.0 | Programmer | 5760.0 | 5 | 9000.0 |
| Michael Hartstein | Marketing | 13000.0 | Marketing Manager | 9500.0 | 2 | 13000.0 |
| Hermann Baer | Public Relations | 10000.0 | Public Relations Representative | 10000.0 | 1 | 10000.0 |
| Den Raphaely | Purchasing | 11000.0 | Purchasing Manager | 4150.0 | 6 | 11000.0 |
| John Russell | Sales | 14000.0 | Sales Manager | 8955.88 | 34 | 14000.0 |
| Adam Fripp | Shipping | 8200.0 | Stock Manager | 3475.56 | 45 | 8200.0 |

---

## Use Case 2: Employee Performance Ranking by Tenure & Salary

**Business Use Case:** The HR director is ranking high-value employees for promotion consideration, leadership development programs, and retention initiatives.

**Objective:** Rank employees by compensation and tenure within their department and overall, identifying top performers earning above the department average.

**Question:** List employees who earn above their department's average salary with their name, department, salary, hire date, overall salary rank, dense rank within department, and row number within department based on descending salary.

**Query:**

```sql
WITH dept_salary AS (
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.department_id,
        e.salary,
        e.hire_date,
        AVG(e.salary) OVER (PARTITION BY e.department_id) AS dept_avg_salary
    FROM employees e
)
SELECT
    CONCAT(ds.first_name, ' ', ds.last_name)                                      AS employee_name,
    d.department_name,
    ds.salary,
    ds.hire_date,
    RANK()       OVER (ORDER BY ds.salary DESC)                                   AS overall_salary_rank,
    DENSE_RANK() OVER (PARTITION BY ds.department_id ORDER BY ds.salary DESC)     AS dept_dense_rank,
    ROW_NUMBER() OVER (PARTITION BY ds.department_id ORDER BY ds.salary DESC)     AS dept_row_num
FROM dept_salary ds
JOIN departments d ON ds.department_id = d.department_id
WHERE ds.salary > ds.dept_avg_salary
ORDER BY d.department_name, ds.salary DESC;
```

**Result** (full set: 38 rows — every employee earning above their department's average salary):

| Employee | Department | Salary | Hire Date | Overall Rank | Dept Dense Rank | Dept Row Num |
|---|---|---|---|---|---|---|
| Shelley Higgins | Accounting | 12008.0 | 2002-06-07 | 5 | 1 | 1 |
| Steven King | Executive | 24000.0 | 2003-06-17 | 1 | 1 | 1 |
| Nancy Greenberg | Finance | 12008.0 | 2002-08-17 | 5 | 1 | 1 |
| Daniel Faviet | Finance | 9000.0 | 2002-08-16 | 21 | 2 | 2 |
| Alexander Hunold | IT | 9000.0 | 2006-01-03 | 21 | 1 | 1 |
| Bruce Ernst | IT | 6000.0 | 2007-05-21 | 29 | 2 | 2 |
| Michael Hartstein | Marketing | 13000.0 | 2004-02-17 | 4 | 1 | 1 |
| Den Raphaely | Purchasing | 11000.0 | 2002-12-07 | 9 | 1 | 1 |
| John Russell | Sales | 14000.0 | 2004-10-01 | 2 | 1 | 1 |
| Karen Partners | Sales | 13500.0 | 2005-01-05 | 3 | 2 | 2 |
| Alberto Errazuriz | Sales | 12000.0 | 2005-03-10 | 7 | 3 | 3 |
| Lisa Ozer | Sales | 11500.0 | 2005-03-11 | 8 | 4 | 4 |
| Gerald Cambrault | Sales | 11000.0 | 2007-10-15 | 9 | 5 | 5 |
| Ellen Abel | Sales | 11000.0 | 2004-05-11 | 9 | 5 | 6 |
| Eleni Zlotkey | Sales | 10500.0 | 2008-01-29 | 12 | 6 | 7 |
| Clara Vishney | Sales | 10500.0 | 2005-11-11 | 12 | 6 | 8 |
| Peter Tucker | Sales | 10000.0 | 2005-01-30 | 14 | 7 | 9 |
| Janette King | Sales | 10000.0 | 2004-01-30 | 14 | 7 | 10 |
| Harrison Bloom | Sales | 10000.0 | 2006-03-23 | 14 | 7 | 11 |
| Tayler Fox | Sales | 9600.0 | 2006-01-24 | 17 | 8 | 12 |
| David Bernstein | Sales | 9500.0 | 2005-03-24 | 18 | 9 | 13 |
| Patrick Sully | Sales | 9500.0 | 2004-03-04 | 18 | 9 | 14 |
| Danielle Greene | Sales | 9500.0 | 2007-03-19 | 18 | 9 | 15 |
| Peter Hall | Sales | 9000.0 | 2005-08-20 | 21 | 10 | 16 |
| Allan McEwen | Sales | 9000.0 | 2004-08-01 | 21 | 10 | 17 |
| Adam Fripp | Shipping | 8200.0 | 2005-04-10 | 25 | 1 | 1 |
| Matthew Weiss | Shipping | 8000.0 | 2004-07-18 | 26 | 2 | 2 |
| Payam Kaufling | Shipping | 7900.0 | 2003-05-01 | 27 | 3 | 3 |
| Shanta Vollman | Shipping | 6500.0 | 2005-10-10 | 28 | 4 | 4 |
| Kevin Mourgos | Shipping | 5800.0 | 2007-11-16 | 30 | 5 | 5 |
| Nandita Sarchand | Shipping | 4200.0 | 2004-01-27 | 31 | 6 | 6 |
| Alexis Bull | Shipping | 4100.0 | 2005-02-20 | 32 | 7 | 7 |
| Sarah Bell | Shipping | 4000.0 | 2004-02-04 | 33 | 8 | 8 |
| Britney Everett | Shipping | 3900.0 | 2005-03-03 | 34 | 9 | 9 |
| Kelly Chung | Shipping | 3800.0 | 2005-06-14 | 35 | 10 | 10 |
| Renske Ladwig | Shipping | 3600.0 | 2003-07-14 | 36 | 11 | 11 |
| Jennifer Dilly | Shipping | 3600.0 | 2005-08-13 | 36 | 11 | 12 |
| Trenna Rajs | Shipping | 3500.0 | 2003-10-17 | 38 | 12 | 13 |

---

## Use Case 3: Career Progression & Job Change Analysis

**Business Use Case:** Career advisors and managers want to monitor employee progression over time to detect patterns of advancement or lateral moves and identify career development opportunities.

**Objective:** Track employee job history to analyze career trajectories, identifying progression patterns across job changes.

**Question:** For each employee, show their name, job history (job ID, department), start date, end date, previous job end date, and next job start date. Order by employee and chronologically by start date.

**Query:**

```sql
SELECT
    CONCAT(e.first_name, ' ', e.last_name)                                        AS employee_name,
    jh.job_id,
    jh.department_id,
    jh.start_date,
    jh.end_date,
    LAG(jh.end_date)    OVER (PARTITION BY jh.employee_id ORDER BY jh.start_date) AS previous_job_end_date,
    LEAD(jh.start_date) OVER (PARTITION BY jh.employee_id ORDER BY jh.start_date) AS next_job_start_date
FROM job_history jh
JOIN employees e ON jh.employee_id = e.employee_id
ORDER BY e.employee_id, jh.start_date;
```

**Result** (full set: 10 rows — all records in `job_history`):

| Employee | Job ID | Department | Start Date | End Date | Previous Job End Date | Next Job Start Date |
|---|---|---|---|---|---|---|
| Neena Kochhar | AC_ACCOUNT | 110 | 1997-09-21 | 2001-10-27 |  | 2001-10-28 |
| Neena Kochhar | AC_MGR | 110 | 2001-10-28 | 2005-03-15 | 2001-10-27 |  |
| Lex De Haan | IT_PROG | 60 | 2001-01-13 | 2006-07-24 |  |  |
| Den Raphaely | ST_CLERK | 50 | 2006-03-24 | 2007-12-31 |  |  |
| Payam Kaufling | ST_CLERK | 50 | 2007-01-01 | 2007-12-31 |  |  |
| Jonathon Taylor | SA_REP | 80 | 2006-03-24 | 2006-12-31 |  | 2007-01-01 |
| Jonathon Taylor | SA_MAN | 80 | 2007-01-01 | 2007-12-31 | 2006-12-31 |  |
| Jennifer Whalen | AD_ASST | 90 | 1995-09-17 | 2001-06-17 |  | 2002-07-01 |
| Jennifer Whalen | AC_ACCOUNT | 90 | 2002-07-01 | 2006-12-31 | 2001-06-17 |  |
| Michael Hartstein | MK_REP | 20 | 2004-02-17 | 2007-12-19 |  |  |
