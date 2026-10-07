/*
Use Case 3: Career Progression & Job Change Analysis

Business Use Case: Career advisors and managers want to monitor employee
progression over time to detect patterns of advancement or lateral moves
and identify career development opportunities.

Objective: Track employee job history to analyze career trajectories,
identifying progression patterns across job changes.

Question: For each employee, show their name, job history (job ID,
department), start date, end date, previous job end date, and next
job start date. Order by employee and chronologically by start date.
*/

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

/*
=====================================================================
SAMPLE OUTPUT (verified against the populated HR database)
Full result set: 10 rows (all records in job_history).
=====================================================================

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

=====================================================================
*/
