WITH holiday_filldown AS (
    SELECT
        Date || '-' || FIRST_VALUE(year) OVER (PARTITION BY groupings ORDER BY ROW_NUM) AS holiday_date,
        bank_holiday
    FROM (
        SELECT
            *,
            COUNT(CASE WHEN year != '' THEN year END) OVER (ORDER BY ROW_NUM) AS groupings
        FROM pd2023_wk12_uk_bank_holidays
    ) AS year_groupings
), uk_holidays AS (
    SELECT
        TO_DATE(holiday_date, 'DD-MON-YYYY') AS holiday_date,
        bank_holiday
    FROM holiday_filldown
    WHERE bank_holiday != ''
), customer_groups AS (
    SELECT
        TO_DATE(date, 'DD/MM/YYYY') AS reporting_date,
        new_customers,
        (
            bank_holiday IS NULL AND
            DAYOFWEEK(TO_DATE(date, 'DD/MM/YYYY')) NOT IN (0, 6)
        ) AS is_reporting_day,
        COUNT(CASE WHEN (
            bank_holiday IS NULL AND
            DAYOFWEEK(TO_DATE(date, 'DD/MM/YYYY')) NOT IN (0, 6)
        ) THEN 1 END) OVER (ORDER BY TO_DATE(date, 'DD/MM/YYYY') DESC) AS reporting_group
    FROM pd2023_wk12_new_customers
    LEFT OUTER JOIN uk_holidays
        ON TO_DATE(date, 'DD/MM/YYYY') = holiday_date
    ORDER BY TO_DATE(date, 'DD/MM/YYYY') ASC
), customers_summed AS (
    SELECT
        reporting_date,
        is_reporting_day,
        new_customers,
        SUM(new_customers) OVER (PARTITION BY reporting_group ORDER BY reporting_date ASC) AS new_customers_sum
    FROM customer_groups
    ORDER BY reporting_date
), uk_customers AS (
    SELECT
        CASE WHEN MONTH(DATEADD('day', 1, reporting_date)) != MONTH(reporting_date)
        THEN
            TO_CHAR(DATEADD('day', 1, reporting_date), 'MMMM') || '-' || YEAR(DATEADD('day', 1, reporting_date))::VARCHAR(255)
        ELSE 
            TO_CHAR(reporting_date, 'MMMM') || '-' || YEAR(reporting_date)::VARCHAR(255)
        END AS "Reporting Month",
        new_customers_sum AS "UK New Customers",
        ROW_NUMBER() OVER (PARTITION BY "Reporting Month" ORDER BY reporting_date ASC) AS "Reporting Day",
        reporting_date AS "Reporting Date"
    FROM customers_summed
    WHERE is_reporting_day
    ORDER BY reporting_date ASC
), roi_customers AS (
    SELECT
        TO_DATE(reporting_date, 'DD/MM/YYYY') AS "ROI Reporting Date",
        reporting_day AS "ROI Reporting Day",
        new_customers AS "ROI New Customers",
        reporting_month AS "ROI Reporting Month"
    FROM pd2023_wk12_roi_new_customers
), uk_and_roi_customers AS (
    SELECT
        *,
        COUNT("Reporting Date") OVER (ORDER BY "ROI Reporting Date" DESC) AS "New Date Group"
    FROM uk_customers
    FULL OUTER JOIN roi_customers
        ON uk_customers."Reporting Date" = roi_customers."ROI Reporting Date"
    ORDER BY "ROI Reporting Date" ASC
), customers AS (
    SELECT
        COALESCE((TO_DATE('1-' || "Reporting Month", 'D-MMMM-YYYY') != TO_DATE('1-' || "ROI Reporting Month", 'D-MON-YY')), TRUE) AS "Misalignment Flag",
        "Reporting Month",
        "Reporting Day",
        "Reporting Date",
        "UK New Customers",
        COALESCE(SUM("ROI New Customers") OVER (PARTITION BY "New Date Group" ORDER BY "ROI Reporting Date"), 0) AS "ROI New Customers",
        "ROI Reporting Month"
    FROM uk_and_roi_customers
)

SELECT *
FROM customers
WHERE "Reporting Month" IS NOT NULL
ORDER BY "Reporting Date" ASC;