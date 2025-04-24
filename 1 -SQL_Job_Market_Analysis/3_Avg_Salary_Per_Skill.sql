-- Average Salary by Skill (Per Job Title)
-- Purpose: Calculates average salaries for skills that rank in the top 25
-- by demand *within each job title*, plus an "All Postings" benchmark
-- for global comparison.

-- Step 1: Per-title average salary for top-ranked skills
WITH top_skills_salary AS (
    SELECT 
        sdp.job_title_short,
        sd.skills,
        ROUND(AVG(jpf.salary_year_avg), 0) AS avg_salary
    FROM job_postings_fact jpf
    INNER JOIN skills_job_dim sjd ON jpf.job_id = sjd.job_id
    INNER JOIN skills_dim sd ON sjd.skill_id = sd.skill_id
    INNER JOIN skill_demand_percent sdp
        ON sjd.skill_id = sdp.skill_id
        AND jpf.job_title_short = sdp.job_title_short
    WHERE 
        jpf.salary_year_avg IS NOT NULL
        AND sdp.rnk <= 25 -- Limit to most relevant skills per title to reduce output size
    GROUP BY 
        sdp.job_title_short, sd.skills
),

-- Step 2: Global average salary for top-ranked skills (based on "All Postings" ranking)
-- Used for overall benchmarking in Tableau
all_postings_salary AS (
    SELECT
        'All Postings' AS job_title_short,
        sd.skills,
        ROUND(AVG(jpf.salary_year_avg), 0) AS avg_salary
    FROM job_postings_fact jpf
    INNER JOIN skills_job_dim sjd ON jpf.job_id = sjd.job_id
    INNER JOIN skills_dim sd ON sjd.skill_id = sd.skill_id
    WHERE sd.skills IN (
        SELECT skills
        FROM skill_demand_percent
        WHERE job_title_short = 'All Postings' AND rnk <= 25
    )
    GROUP BY sd.skills
)

-- Final output: combine job-title and global results
SELECT * FROM top_skills_salary

UNION ALL

SELECT * FROM all_postings_salary

ORDER BY job_title_short, avg_salary DESC;
