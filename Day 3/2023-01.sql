--Output 1
SELECT 
    SPLIT_PART(tr.transaction_code, '-', 1) as "Bank",
    SUM(tr.value) as "Total Value"
FROM PD2023_WK01 as tr
GROUP BY "Bank";

--Output 2
SELECT 
    SPLIT_PART(tr.transaction_code, '-', 1) as "Bank",
    DECODE(tr.online_or_in_person, 
            1, 'Online', 
            2, 'In-Person') as "Online or In-Person",
    DECODE(EXTRACT('dayofweek', TO_DATE(SPLIT_PART(tr.transaction_date, ' ', 1), 'DD/MM/YYYY')),
            1, 'Monday',
            2, 'Tuesday',
            3, 'Wednesday',
            4, 'Thursday',
            5, 'Friday',
            6, 'Saturday',
            0, 'Sunday') as "Day of Week",
    SUM(tr.value) as "Total Value"
FROM PD2023_WK01 as tr
GROUP BY "Bank", "Online or In-Person", "Day of Week";

--Output 3
SELECT 
    SPLIT_PART(tr.transaction_code, '-', 1) as "Bank",
    tr.customer_code as "Customer Code",
    SUM(tr.value) as "Value"
FROM PD2023_WK01 as tr
GROUP BY "Bank", tr.customer_code;