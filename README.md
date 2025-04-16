//TEMP

//NOTE Formatting is equivalent to obsidian
# Introduction
// ADD Introduction / summary of the project
# Background
//
# Tools I Used
//
### 📌 Skill Demand by Job Title

**Question:**  
What are the most in-demand skills for each job title based on the percentage of job postings mentioning them?

**Purpose:**  
This query calculates the percentage of postings that mention a specific skill for each job title — allowing us to rank the most relevant skills by role. An "All Postings" category is also included to show general trends across the entire dataset.

💡 *Want to see the full SQL powering this chart? Click below to expand.*

<details>
<summary>View full SQL and output example</summary>

```sql
CREATE VIEW skill_demand_percent AS
WITH demand_percent AS (
    SELECT
        skill_id,
        COUNT(*) as per_skill_all,
        ROUND((COUNT(*)::numeric / (SELECT COUNT(distinct job_id) FROM skills_job_dim)) * 100, 2) AS perc
    FROM skills_job_dim
    GROUP BY skill_id
),
total_perc AS (
    SELECT
        dp.skill_id,
        skills,
        'All Postings' AS job_title_short,
        per_skill_all,
        perc
    FROM demand_percent dp
    INNER JOIN skills_dim sd ON dp.skill_id = sd.skill_id
),
total_posts_per_title AS (
    SELECT
        job_title_short,
        COUNT(DISTINCT job_id) AS total_postings
    FROM job_postings_fact
    GROUP BY job_title_short
),
per_skill_count AS (
    SELECT
        skjd.skill_id,
        jpf.job_title_short,
        COUNT(*) AS per_skill_total
    FROM skills_job_dim skjd
    INNER JOIN job_postings_fact jpf ON skjd.job_id = jpf.job_id
    GROUP BY skjd.skill_id, jpf.job_title_short
),
title_perc AS (
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
SELECT *, RANK() OVER(PARTITION BY job_title_short ORDER BY perc DESC) AS rnk
FROM title_perc

UNION ALL

SELECT *, RANK() OVER(PARTITION BY job_title_short ORDER BY perc DESC) AS rnk
FROM total_perc
ORDER BY job_title_short, perc DESC;
```

**Output Format (Example):**

| job_title_short | skills | perc  | rnk |
|-----------------|--------|-------|-----|
| Data Analyst    | SQL    | 52.00 | 1   |
| Data Analyst    | Excel  | 43.25 | 2   |
| All Postings    | SQL    | 39.12 | 1   |

</details>

🔗 *[View this query as a standalone `.sql` file →](https://github.com/AengusHafford/Project-SQL/blob/686ab25a1d8542ec8e5d259c4f22440b1624fb9d/Job%20Analysis%20Prep/Demand_Percentage.sql)*

test:
<a href="https://github.com/AengusHafford/Project-SQL/blob/686ab25a1d8542ec8e5d259c4f22440b1624fb9d/Job%20Analysis%20Prep/Demand_Percentage.sql" target="_blank">🔗 View this query as a standalone <code>.sql</code> file →</a>

# What I learned
//
# Conclusions
//
