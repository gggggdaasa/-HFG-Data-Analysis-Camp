/*
Q4: Salary Range by Job Title

Business Case: Recruitment team needs to know the minimum and maximum salary
for each job title to create competitive job postings.

Task: Display each employee with the salary range (min/max) for their job
title.
*/

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
