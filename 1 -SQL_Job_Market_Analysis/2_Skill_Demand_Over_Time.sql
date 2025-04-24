-- Skill Demand Over Time
-- Purpose: Tracks monthly percentage of job postings that mention each of the top 25 skills,
-- broken down by job title and overall to track trends over time.

-- Step 1: Assign each job posting to a month
WITH month_mapping AS (
    SELECT
        job_id,
        CAST(DATE_TRUNC('month', job_posted_date) AS DATE) AS month_posted
    FROM job_postings_fact
),

-- Step 2a: Count total job postings per job title, per month
filter_posts AS (
    SELECT
        job_title_short, 
        month_posted,
        COUNT(DISTINCT jpf.job_id) as ttl_posts
    FROM job_postings_fact jpf
    JOIN month_mapping ON jpf.job_id = month_mapping.job_id
    GROUP BY job_title_short, month_posted
),

-- Step 2b: Count job postings that mention each skill, per title, per month
filter_skill_count AS (
    SELECT
        skill_id, 
        job_title_short, 
        month_posted,
        COUNT(DISTINCT jpf.job_id) as skill_count
    FROM skills_job_dim sjd
    JOIN job_postings_fact jpf ON sjd.job_id = jpf.job_id
    JOIN month_mapping ON jpf.job_id = month_mapping.job_id
    GROUP BY skill_id, job_title_short, month_posted
),

-- Step 3a: Count total job postings per month (all titles)
all_posts AS (
    SELECT
        month_posted,
        COUNT(DISTINCT job_id) AS ttl_posts
    FROM month_mapping
    GROUP BY month_posted
),

-- Step 3b: Count job postings that mention each skill per month (all titles)
all_skill_counts AS (
    SELECT
        sjd.skill_id,
        month_posted,
        COUNT(DISTINCT sjd.job_id) AS skill_count
    FROM skills_job_dim sjd
    JOIN month_mapping ON sjd.job_id = month_mapping.job_id
    GROUP BY sjd.skill_id, month_posted
),

-- Step 4a: Calculate per-skill percentage per job title, per month
per_title_final AS (
    SELECT
        fsc.job_title_short,
        fsc.month_posted, 
        sd.skills,
        ROUND((fsc.skill_count / fp.ttl_posts::numeric) * 100, 2) AS skill_pct
    FROM filter_skill_count fsc
    JOIN filter_posts fp 
        ON fsc.job_title_short = fp.job_title_short 
       AND fsc.month_posted = fp.month_posted
    JOIN skills_dim sd ON fsc.skill_id = sd.skill_id
    WHERE fsc.skill_id IN (
        SELECT skill_id
        FROM skill_demand_percent
        WHERE rnk <= 25 -- Limit to most relevant skills per title to reduce output size
    )
),

-- Step 4b: "All Postings" used instead of Tableau's "All" filter to avoid distorted aggregation.
all_postings_final AS (
    SELECT
        'All Postings' AS job_title_short,
        apf.month_posted,
        sd.skills,
        ROUND((apf.skill_count / ap.ttl_posts::numeric) * 100, 2) AS skill_pct
    FROM all_skill_counts apf
    JOIN all_posts ap ON apf.month_posted = ap.month_posted
    JOIN skills_dim sd ON apf.skill_id = sd.skill_id
   WHERE apf.skill_id IN (
        SELECT skill_id
        FROM skill_demand_percent
        WHERE rnk <= 25 -- Limit to most relevant skills per title to reduce output size
    )
)

-- Final output: combine per-title and global data for Tableau visualization
SELECT * FROM per_title_final

UNION ALL

SELECT * FROM all_postings_final

ORDER BY job_title_short, month_posted;