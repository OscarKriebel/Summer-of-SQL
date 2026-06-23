WITH monthbank AS (
    SELECT 
        TO_CHAR(TO_DATE(TRANSACTION_DATE, 'DD/MM/YYYY HH24:MI:SS'), 'MMMM') AS "Transaction Date",
        SPLIT_PART(TRANSACTION_CODE, '-', 0) AS "Bank",
        SUM(VALUE) AS "Value",
        ROW_NUMBER() OVER (PARTITION BY "Transaction Date" ORDER BY "Value" DESC) AS "Rank"
    FROM PD2023_WK01
    GROUP BY "Transaction Date", "Bank"
)

SELECT 
    "Transaction Date",
    "Bank",
    "Value",
    "Rank" AS "Bank Rank per Month",
    AVG("Value") OVER (PARTITION BY "Rank") AS "Avg Transaction per Rank",
    AVG("Rank") OVER (PARTITION BY "Bank") AS "Avg Rank per Bank"
FROM monthbank;