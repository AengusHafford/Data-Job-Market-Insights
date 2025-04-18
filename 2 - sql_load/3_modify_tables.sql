COPY company_dim
FROM 'C:\Users\nogas\OneDrive\Desktop\code\SQL\Luke_B_Course\csv_files\company_dim.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

COPY skills_dim
FROM 'C:\Users\nogas\OneDrive\Desktop\code\SQL\Luke_B_Course\csv_files\skills_dim.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

COPY job_postings_fact
FROM 'C:\Users\nogas\OneDrive\Desktop\code\SQL\Luke_B_Course\csv_files\job_postings_fact.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

COPY skills_job_dim
FROM 'C:\Users\nogas\OneDrive\Desktop\code\SQL\Luke_B_Course\csv_files\skills_job_dim.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');
