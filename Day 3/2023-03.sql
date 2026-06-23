WITH targets AS (
    SELECT
        online_or_in_person,
        CAST(RIGHT("Quarter", 1) AS INT) AS Q, --Quarter as number
        "Value" AS qtarget
    FROM PD2023_WK03_TARGETS
        UNPIVOT ("Value" FOR "Quarter" IN (q1, q2, q3, q4)) --Put Quarters on Rows
)

SELECT 
    IFF(pd.online_or_in_person = 1, 'Online', 'In-Person') AS "Online or In-Person", --Change to String
    QUARTER(TO_DATE(pd.transaction_date, 'DD/MM/YYYY HH24:MI:SS')) AS "Quarter", --Parse Date to Quarter
    SUM(pd.value) AS "Value",
    MAX(targets.qtarget) AS "Quarterly Target", --Don't aggregate multiple times
    "Value" - "Quarterly Target" AS "Variance to Target"
FROM PD2023_WK01 AS pd
INNER JOIN targets 
    ON "Quarter" = targets.q AND "Online or In-Person" = targets.online_or_in_person --Quarter and Online or Inperson
WHERE STARTSWITH(pd.transaction_code, 'DSB') --Only transactions codes with DSB
GROUP BY "Quarter", "Online or In-Person"
ORDER BY "Quarter" ASC, "Online or In-Person" DESC;