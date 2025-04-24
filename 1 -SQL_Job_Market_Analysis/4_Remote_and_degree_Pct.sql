-- Remote and Degree Requirement Percentages
-- Purpose: Calculates the share of remote roles and postings that mention a degree requirement,
-- grouped by job title. Adds an "All Postings" aggregate row for global benchmarking in Tableau.

-- Step 1: Count categories per job title
WITH counts AS (
    SELECT
        job_title_short,
        COUNT(CASE WHEN job_work_from_home = TRUE THEN 1 END) AS remote_count,
        COUNT(CASE WHEN job_work_from_home = FALSE THEN 1 END) AS non_remote_count,
        COUNT(CASE WHEN job_no_degree_mention = TRUE THEN 1 END) AS no_degree_count,
        COUNT(CASE WHEN job_no_degree_mention = FALSE THEN 1 END) AS degree_count,
        COUNT(*) AS ttl_count -- Total postings per title
    FROM job_postings_fact
    GROUP BY job_title_short
),

-- Step 2: Add a global "All Postings" row by summing each category across titles
all_postings AS (
    SELECT
        'All Postings' AS job_title_short,
        SUM(remote_count) AS remote_count,
        SUM(non_remote_count) AS non_remote_count,
        SUM(no_degree_count) AS no_degree_count,
        SUM(degree_count) AS degree_count,
        SUM(ttl_count) AS ttl_count
    FROM counts
),

-- Step 3: Combine individual and global results
combined_counts AS (
    SELECT * FROM counts
    UNION ALL
    SELECT * FROM all_postings
),

-- Step 4: Transform into long format (one row per job title + category)
long_format AS (
    SELECT 
        job_title_short,
        'Remote' AS category,
        remote_count AS count,
        ROUND(remote_count::numeric / ttl_count * 100, 2) AS pct
    FROM combined_counts

    UNION ALL

    SELECT 
        job_title_short,
        'Non-Remote',
        non_remote_count,
        ROUND(non_remote_count::numeric / ttl_count * 100, 2)
    FROM combined_counts

    UNION ALL

    SELECT 
        job_title_short,
        'Degree Required',
        degree_count,
        ROUND(degree_count::numeric / ttl_count * 100, 2)
    FROM combined_counts

    UNION ALL

    SELECT 
        job_title_short,
        'No Degree Required',
        no_degree_count,
        ROUND(no_degree_count::numeric / ttl_count * 100, 2)
    FROM combined_counts
)

-- Final output: sorted long-format results by job title and category

SELECT *
FROM long_format
ORDER BY job_title_short, category;
