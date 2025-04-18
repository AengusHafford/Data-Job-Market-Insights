SELECT
    job_title_short,
    ROUND(AVG(salary_year_avg), 0) AS avg_salary,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY salary_year_avg)::numeric(10, 0) AS median_salary
FROM job_postings_fact
WHERE salary_year_avg IS NOT NULL
GROUP BY job_title_short

UNION ALL

SELECT
    'All Postings' AS job_title_short,
    ROUND(AVG(salary_year_avg), 0) AS avg_salary,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY salary_year_avg)::numeric(10, 0) AS median_salary
FROM job_postings_fact
WHERE salary_year_avg IS NOT NULL
ORDER BY avg_salary DESC;