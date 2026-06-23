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
)

SELECT
    "Account Number",
    "Balance Date",
    "Transaction Value",
    SUM("Balance") OVER (PARTITION BY "Account Number" ORDER BY "Balance Date" ASC, "Transaction Value" DESC) AS "Balance"
FROM BALANCE;