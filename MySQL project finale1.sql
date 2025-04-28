create database customers;
select * from customers_final;
select COUNT(*) FROM customers_final;

create table Transactions
(
date_new date,
Id_check int,
ID_client int,
Count_products decimal(10, 3),
Sum_payment decimal(10,2))


 select * from transactions;
 select * from customers_final;


load data infile "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\TRANSACTIONS 555.csv"
into table Transactions
fields terminated  by ','
lines terminated  by '\n'
ignore 1 rows;

show variables like 'secure_file_priv';

update customers_final set gender = null where gender = '';
SET SQL_SAFE_UPDATES = 0;

UPDATE customers_final
SET gender = NULL
WHERE gender = '';
UPDATE customers_final SET age = NULL
WHERE age = '';

alter table customers_final modify age int  null;

SET SQL_SAFE_UPDATES = 1;

select * from customers_final;



##ЗАДАНИЯ И РЕШЕНИЯ


#1/список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков за указанный годовой период,
# средний чек за период с 01.06.2015 по 01.06.2016, 
# средняя сумма покупок за месяц,
# количество всех операций по клиенту за период;

SELECT
    ID_client
FROM (
    SELECT
        ID_client,
        DATE_FORMAT(date_new, '%Y-%m') AS ym
    FROM transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
    GROUP BY ID_client, ym
) t
GROUP BY ID_client
HAVING COUNT(DISTINCT ym) = 12;


SELECT
    ID_client,
    AVG(Sum_payment) AS avg_check
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY ID_client;


SELECT
    ID_client,
    SUM(Sum_payment) / COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS avg_monthly_payment
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY ID_client;

SELECT
    ID_client,
    COUNT(*) AS total_transactions
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY ID_client;


#2/ информацию в разрезе месяцев:
#средняя сумма чека в месяц;
#среднее количество операций в месяц;
#среднее количество клиентов, которые совершали операции;
#долю от общего количества операций за год и долю в месяц от общей суммы операций;
#вывести % соотношение M/F/NA в каждом месяце с их долей затрат;

SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    AVG(t.Sum_payment) AS avg_check
FROM transactions t
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY month;

SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    COUNT(*) AS total_transactions
FROM transactions t
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY month;

SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    COUNT(DISTINCT t.ID_client) AS unique_clients
FROM transactions t
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY month;



WITH base AS (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(*) AS ops_month,
        SUM(Sum_payment) AS sum_month
    FROM transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
    GROUP BY month
),
totals AS (
    SELECT
        COUNT(*) AS total_ops,
        SUM(Sum_payment) AS total_sum
    FROM transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
)
SELECT
    b.month,
    b.ops_month,
    ROUND(b.ops_month / t.total_ops * 100, 2) AS ops_share_pct,
    b.sum_month,
    ROUND(b.sum_month / t.total_sum * 100, 2) AS sum_share_pct
FROM base b
CROSS JOIN totals t;


SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    cf.Gender,
    COUNT(DISTINCT t.ID_client) AS clients,
    SUM(t.Sum_payment) AS total_payment,
    ROUND(SUM(t.Sum_payment) / (
        SELECT SUM(Sum_payment)
        FROM transactions
        WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
    ) * 100, 2) AS payment_share_pct
FROM transactions t
JOIN customers_final cf ON t.ID_client = cf.Id_client
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY month, cf.Gender
ORDER BY month, cf.Gender;



#3/ возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, 
#с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %


SELECT
    CASE
        WHEN cf.age IS NULL THEN 'No Age'
        WHEN cf.age < 10 THEN '00-09'
        WHEN cf.age BETWEEN 10 AND 19 THEN '10-19'
        WHEN cf.age BETWEEN 20 AND 29 THEN '20-29'
        WHEN cf.age BETWEEN 30 AND 39 THEN '30-39'
        WHEN cf.age BETWEEN 40 AND 49 THEN '40-49'
        WHEN cf.age BETWEEN 50 AND 59 THEN '50-59'
        WHEN cf.age BETWEEN 60 AND 69 THEN '60-69'
        ELSE '70+'
    END AS age_group,
    COUNT(*) AS operation_count,
    SUM(t.Sum_payment) AS total_sum
FROM transactions t
JOIN customers_final cf ON t.ID_client = cf.Id_client
GROUP BY age_group
ORDER BY age_group;



WITH trans_with_age AS (
    SELECT
        CASE
            WHEN cf.age IS NULL THEN 'No Age'
            WHEN cf.age < 10 THEN '00-09'
            WHEN cf.age BETWEEN 10 AND 19 THEN '10-19'
            WHEN cf.age BETWEEN 20 AND 29 THEN '20-29'
            WHEN cf.age BETWEEN 30 AND 39 THEN '30-39'
            WHEN cf.age BETWEEN 40 AND 49 THEN '40-49'
            WHEN cf.age BETWEEN 50 AND 59 THEN '50-59'
            WHEN cf.age BETWEEN 60 AND 69 THEN '60-69'
            ELSE '70+'
        END AS age_group,
        QUARTER(t.date_new) AS quarter,
        YEAR(t.date_new) AS year,
        t.Sum_payment
    FROM transactions t
    JOIN customers_final cf ON t.ID_client = cf.Id_client
),
grouped AS (
    SELECT
        year,
        quarter,
        age_group,
        COUNT(*) AS operation_count,
        SUM(Sum_payment) AS total_sum
    FROM trans_with_age
    GROUP BY year, quarter, age_group
),
totals AS (
    SELECT
        year,
        quarter,
        SUM(operation_count) AS total_ops_all,
        SUM(total_sum) AS total_sum_all
    FROM grouped
    GROUP BY year, quarter
)
SELECT
    g.year,
    g.quarter,
    g.age_group,
    g.operation_count,
    ROUND(g.total_sum, 2) AS total_sum,
    ROUND(g.operation_count / t.total_ops_all * 100, 2) AS ops_share_pct,
    ROUND(g.total_sum / t.total_sum_all * 100, 2) AS sum_share_pct
FROM grouped g
JOIN totals t ON g.year = t.year AND g.quarter = t.quarter
ORDER BY g.year ASC, g.quarter ASC, g.age_group ASC;

