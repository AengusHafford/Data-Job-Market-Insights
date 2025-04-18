-- Skill_Demand_Percent_View


CREATE VIEW skill_demand_percent AS
with demand_percent as (
    SELECT
        skill_id,
        COUNT(*) as per_skill_all, -- FIXME: Pretty sure this is not needed
        ROUND((COUNT(*)::numeric / (SELECT COUNT(distinct job_id) FROM skills_job_dim)) * 100, 2) AS perc
    FROM
        skills_job_dim
    GROUP BY
        skill_id
),

total_perc as (
    select
        dp.skill_id,
        skills,
        'All Postings' AS job_title_short,
        per_skill_all,
        perc
    from demand_percent dp
    inner join skills_dim sd on
        dp.skill_id = sd.skill_id
),

total_posts_per_title AS (
    SELECT
        job_title_short,
        COUNT(DISTINCT job_id) AS total_postings
    FROM job_postings_fact
    GROUP BY job_title_short
),

-- Step 2: Get per-skill count per title
per_skill_count AS (
    SELECT
        skjd.skill_id,
        jpf.job_title_short,
        COUNT(*) AS per_skill_total
    FROM skills_job_dim skjd
    INNER JOIN job_postings_fact jpf ON skjd.job_id = jpf.job_id
    GROUP BY skjd.skill_id, jpf.job_title_short
),
-- Step 3: Join and calculate %
title_perc as (
    SELECT
        psc.skill_id,
        sd.skills,
        psc.job_title_short,
        psc.per_skill_total,
        ROUND((psc.per_skill_total::numeric / tpt.total_postings) * 100, 2) AS perc
    FROM per_skill_count psc
    INNER JOIN total_posts_per_title tpt ON psc.job_title_short = tpt.job_title_short
    INNER JOIN skills_dim sd ON psc.skill_id = sd.skill_id
)
SELECT *,
rank() over(PARTITION BY job_title_short ORDER BY perc DESC) as rnk

FROM title_perc

UNION ALL

SELECT *,
rank() over(PARTITION BY job_title_short ORDER BY perc DESC) as rnk

FROM total_perc
order by job_title_short, perc DESC;





