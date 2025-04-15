
/*
VERSION 1:
Dividing the per skill total by the Total demand of skills
meaning, it should sum to 100% (99.7 after rounding)
*/
SELECT
    skill_id,
    COUNT(*) as per_skill_total,
    ROUND((COUNT(*)::numeric / (SELECT COUNT(*) FROM skills_job_dim)) * 100, 2) AS perc
FROM
    skills_job_dim
GROUP BY
    skill_id
--------------------------------------------------------------------------------------------

/*
VERSION 2:
Dividing the per skill total by the Total number of postings (distinct job_id)
meaning, it should sum more than 100%, since theres more than one skill_id per postings (547.35 after rounding)
// Believe this means there's an avg of 5.47 skills per posting
*/

--Percentage of postings each skill is in:
with demand_percent as (
SELECT
    skill_id,
    COUNT(*) as per_skill_total,
    ROUND((COUNT(*)::numeric / (SELECT COUNT(distinct job_id) FROM skills_job_dim)) * 100, 2) AS perc
FROM
    skills_job_dim
GROUP BY
    skill_id
)
select
    dp.skill_id,
    skills,
    'All Postings' AS job_title_short,
    perc
from
    demand_percent dp
inner join skills_dim sd on
    dp.skill_id = sd.skill_id
order by
    perc DESC

----

-- # Testing adding title filter
-- Q: Do I want to add a ranking so I am able to filter for the top 25?


-- Step 1: Get total postings per job_title_short
WITH total_posts_per_title AS (
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
)
-- Step 3: Join and calculate %

SELECT
    psc.skill_id,
    sd.skills,
    psc.job_title_short,
    ROUND((psc.per_skill_total::numeric / tpt.total_postings) * 100, 2) AS perc
FROM per_skill_count psc
INNER JOIN total_posts_per_title tpt ON psc.job_title_short = tpt.job_title_short
INNER JOIN skills_dim sd ON psc.skill_id = sd.skill_id
ORDER BY psc.job_title_short, perc DESC



-----------
-- Combining Version 2 with the title filter
-- Original query

WITH title_level AS (
    SELECT
        skjd.skill_id,
        jpf.job_title_short,
        COUNT(*) AS per_skill_total
    FROM skills_job_dim skjd
    JOIN job_postings_fact jpf ON skjd.job_id = jpf.job_id
    GROUP BY skjd.skill_id, jpf.job_title_short
),
title_total AS (
    SELECT
        job_title_short,
        COUNT(DISTINCT job_id) AS total
    FROM job_postings_fact
    GROUP BY job_title_short
),
overall_total AS (
    SELECT COUNT(DISTINCT job_id) AS total_postings FROM job_postings_fact
),
overall_skill_count AS (
    SELECT
        skill_id,
        COUNT(*) AS per_skill_total
    FROM skills_job_dim
    GROUP BY skill_id
),
title_perc AS (
    SELECT
        tl.skill_id,
        tl.job_title_short,
        ROUND(tl.per_skill_total::numeric / tt.total * 100, 2) AS perc
    FROM title_level tl
    JOIN title_total tt ON tl.job_title_short = tt.job_title_short
),
overall_perc AS (
    SELECT
        osc.skill_id,
        'All Postings' AS job_title_short,
        ROUND(osc.per_skill_total::numeric / ot.total_postings * 100, 2) AS perc
    FROM overall_skill_count osc, overall_total ot
)
-- Combine both
SELECT * FROM title_perc
UNION ALL
SELECT * FROM overall_perc
order by job_title_short, perc DESC









-----------
--My Union Test:

with demand_percent as (
    SELECT
        skill_id,
        COUNT(*) as per_skill_total, -- FIXME: Pretty sure this is not needed
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
        perc
    from demand_percent dp
    inner join skills_dim sd on
        dp.skill_id = sd.skill_id
),

----

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
        ROUND((psc.per_skill_total::numeric / tpt.total_postings) * 100, 2) AS perc
    FROM per_skill_count psc
    INNER JOIN total_posts_per_title tpt ON psc.job_title_short = tpt.job_title_short
    INNER JOIN skills_dim sd ON psc.skill_id = sd.skill_id
)
SELECT * FROM title_perc
UNION ALL
SELECT * FROM total_perc
order by job_title_short, perc DESC

---------------------------------------------------------------------------------------------

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

----

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
order by job_title_short, perc asc