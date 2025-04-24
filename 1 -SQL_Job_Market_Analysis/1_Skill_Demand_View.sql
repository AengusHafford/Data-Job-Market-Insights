-- Skill Demand Percentage
-- Purpose: Calculates the percentage of postings that mention a given skill,
-- grouped by job title. Includes an "All Postings" aggregate for global trends,
-- and ranks skills per title.

-- Creating a view to simplify downstream queries via filtering,
-- reduce result size, and improve performance for Tableau exports.
CREATE VIEW skill_demand_percent AS

-- Step 1: Calculate the total number of mentions per skill across all job postings,
-- and what percentage of all postings each skill appears in.
WITH demand_percent AS (
    SELECT
        skill_id,
        COUNT(*) AS per_skill_total,  -- Total times the skill appears
        ROUND((COUNT(*)::numeric / (SELECT COUNT(DISTINCT job_id) FROM skills_job_dim)) * 100, 2) AS pct  -- Global percentage
    FROM skills_job_dim
    GROUP BY skill_id
),

-- Assign a consistent "All Postings" label for global totals.
-- This avoids Tableau's default aggregation logic when using 'All' in filters,
-- which can distort percentages. The label acts as a controlled global baseline.
total_pct AS (
    SELECT
        dp.skill_id,
        skills,
        'All Postings' AS job_title_short,
        per_skill_total,
        pct
    FROM demand_percent dp
    INNER JOIN skills_dim sd ON dp.skill_id = sd.skill_id
),

-- Count the number of job postings per title (used for normalization)
total_posts_per_title AS (
    SELECT
        job_title_short,
        COUNT(DISTINCT job_id) AS total_postings
    FROM job_postings_fact
    GROUP BY job_title_short
),

-- Step 2: Count how many times each skill appears within each job title
per_skill_count AS (
    SELECT
        skjd.skill_id,
        jpf.job_title_short,
        COUNT(*) AS per_skill_total
    FROM skills_job_dim skjd
    INNER JOIN job_postings_fact jpf ON skjd.job_id = jpf.job_id
    GROUP BY skjd.skill_id, jpf.job_title_short
),

-- Step 3: Calculate the % of postings per title that mention each skill
title_pct AS (
    SELECT
        psc.skill_id,
        sd.skills,
        psc.job_title_short,
        psc.per_skill_total,
        ROUND((psc.per_skill_total::numeric / tpt.total_postings) * 100, 2) AS pct
    FROM per_skill_count psc
    INNER JOIN total_posts_per_title tpt ON psc.job_title_short = tpt.job_title_short
    INNER JOIN skills_dim sd ON psc.skill_id = sd.skill_id
)

-- Final Output: Combine per-title and "All Postings" data
-- Rank skills per title by their percentage of appearance
SELECT *,
    RANK() OVER (PARTITION BY job_title_short ORDER BY pct DESC) AS rnk
FROM title_pct

UNION ALL

SELECT *,
    RANK() OVER (PARTITION BY job_title_short ORDER BY pct DESC) AS rnk
FROM total_pct

ORDER BY job_title_short, pct DESC;




