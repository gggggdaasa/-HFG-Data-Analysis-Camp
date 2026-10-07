/*
Q5: Premium Jobs Analysis

Business Case: Talent acquisition wants to identify "premium" jobs — those
where the average employee salary exceeds the job's midpoint salary by 10%
or more.

Task: Find jobs where the actual average salary exceeds the expected midpoint
salary ((min_salary + max_salary) / 2) by 10%+.
*/

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
