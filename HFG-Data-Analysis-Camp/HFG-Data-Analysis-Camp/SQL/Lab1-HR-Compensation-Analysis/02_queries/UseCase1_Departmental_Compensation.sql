/*
Use Case 1: Departmental Compensation Analysis

Business Use Case: HR managers need visibility into employee compensation
by department to identify salary equity issues, benchmark performance,
and support compensation planning.

Objective: Aggregate compensation metrics (average salary, employee count,
highest salary) for each employee's department to support comparative analysis.

Question: Show each employee's name, department, salary, job title,
the average salary of their department, number of employees in the
department, and the maximum salary achieved within the department.
*/

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

/*
=====================================================================
SAMPLE OUTPUT (verified against the populated HR database)
Full result set: 106 rows (one per employee).
Below: the top earner in each department, as a representative sample.
=====================================================================

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

=====================================================================
*/
