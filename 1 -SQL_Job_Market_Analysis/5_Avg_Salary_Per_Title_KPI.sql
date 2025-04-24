-- Average and Median Salary by Job Title
-- Purpose: Calculates both average and median salaries per job title,
-- with an additional "All Postings" row for benchmarking.

-- Step 1: Per-title salary metrics
SELECT
    job_title_short,
    ROUND(AVG(salary_year_avg), 0) AS avg_salary,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY salary_year_avg)::numeric(10, 0) AS median_salary
FROM job_postings_fact
WHERE salary_year_avg IS NOT NULL
GROUP BY job_title_short

UNION ALL

-- Step 2: Global average and median for all postings (benchmark row)
SELECT
    'All Postings' AS job_title_short,
    ROUND(AVG(salary_year_avg), 0) AS avg_salary,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY salary_year_avg)::numeric(10, 0) AS median_salary
FROM job_postings_fact
WHERE salary_year_avg IS NOT NULL

-- Final output: sort by average salary, descending
ORDER BY avg_salary DESC;