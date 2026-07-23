
WITH Transaction_Out AS (
    SELECT 
        path.account_from AS "Account Number",
        TO_DATE(detail.transaction_date, 'yyyy-MM-dd') AS "Balance Date",
        detail.value * -1 AS "Transaction Value",
        "Transaction Value" AS "Balance"
    FROM PD2023_WK07_TRANSACTION_PATH as path
    INNER JOIN PD2023_WK07_TRANSACTION_DETAIL as detail
        ON detail.transaction_id = path.transaction_id
    WHERE detail.cancelled_ = 'N'
),
Transaction_In AS (
    SELECT 
        path.account_to AS "Account Number",
        TO_DATE(detail.transaction_date, 'yyyy-MM-dd') AS "Balance Date",
        detail.value AS "Transaction Value",
        "Transaction Value" AS "Balance"
    FROM PD2023_WK07_TRANSACTION_PATH as path
    INNER JOIN PD2023_WK07_TRANSACTION_DETAIL as detail
        ON detail.transaction_id = path.transaction_id
    WHERE detail.cancelled_ = 'N'
),
Balance AS (
    SELECT *
    FROM Transaction_In
    UNION ALL
    SELECT *
    FROM Transaction_Out
    UNION ALL
    SELECT 
        acc.ACCOUNT_NUMBER AS "Account Number",
        acc.BALANCE_DATE AS "Balance Date",
        NULL AS "Transaction Value",
        acc.BALANCE AS "Balance"
    FROM PD2023_WK07_ACCOUNT_INFORMATION AS acc
), dates AS (
    SELECT *
    FROM(
        SELECT
            DATEADD('day', 
                ROW_NUMBER() OVER (ORDER BY 1),
                DATE_FROM_PARTS(2023, 1, 30)
            ) AS scaffold
        FROM TABLE(GENERATOR(ROWCOUNT => 15))
    ) AS dates
    CROSS JOIN (
        SELECT DISTINCT
            "Account Number"
        FROM BALANCE
    ) AS accounts
), pd2023_wk10 AS (
    SELECT
        dates."Account Number" AS "Account Number",
        dates.scaffold AS "Balance Date",
        "Transaction Value" AS "Transaction Value",
        SUM(COALESCE("Transaction Value", "Balance")) OVER (PARTITION BY dates."Account Number" ORDER BY dates.scaffold) AS "Balance"
    FROM dates
    LEFT OUTER JOIN (
        SELECT
            "Account Number",
            "Balance Date",
            SUM("Transaction Value") AS "Transaction Value",
            SUM(CASE WHEN "Balance Date" = DATE_FROM_PARTS(2023,1,31) THEN "Balance" END) AS "Balance"
        FROM BALANCE
        GROUP BY BALANCE."Account Number", BALANCE."Balance Date"
    ) AS BALANCE
        ON dates.scaffold = BALANCE."Balance Date" AND dates."Account Number" = BALANCE."Account Number"
)

SELECT
    "Account Number",
    "Balance",
    "Transaction Value"
FROM pd2023_wk10
WHERE "Balance Date" = DATE_FROM_PARTS(2023,2,1)
ORDER BY "Account Number", "Balance Date";