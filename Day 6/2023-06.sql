WITH unpivoted AS (
    --Unpivot ratings into customers, platform, category, rating per row
    SELECT
        customer_id,
        SPLIT_PART("Category", '___', 1) AS platform,
        SPLIT_PART("Category", '___', 2) AS category,
        "Value"
    FROM pd2023_wk06_dsb_customer_survey
        UNPIVOT ("Value" FOR "Category" IN (MOBILE_APP___EASE_OF_USE, MOBILE_APP___EASE_OF_ACCESS, MOBILE_APP___NAVIGATION, MOBILE_APP___LIKELIHOOD_TO_RECOMMEND, MOBILE_APP___OVERALL_RATING, ONLINE_INTERFACE___EASE_OF_USE, ONLINE_INTERFACE___EASE_OF_ACCESS, ONLINE_INTERFACE___NAVIGATION, ONLINE_INTERFACE___LIKELIHOOD_TO_RECOMMEND, ONLINE_INTERFACE___OVERALL_RATING))
), ratings AS (
    --Move platform onto column to have single row for customer, category and rating for better comparison
    SELECT
        *
    FROM unpivoted
        PIVOT (MIN("Value") FOR platform IN ('MOBILE_APP', 'ONLINE_INTERFACE'))
), preferences AS (
    --Compare average rating per customer between their mobile and online average rating and bucket them
    SELECT
        customer_id,
        CASE
            WHEN AVG("'MOBILE_APP'") - AVG("'ONLINE_INTERFACE'") >= 2 THEN 'Mobile App Superfan'
            WHEN AVG("'MOBILE_APP'") - AVG("'ONLINE_INTERFACE'") >= 1 THEN 'Mobile App Fan'
            WHEN AVG("'MOBILE_APP'") - AVG("'ONLINE_INTERFACE'") <= -2 THEN 'Online Interface Superfan'
            WHEN AVG("'MOBILE_APP'") - AVG("'ONLINE_INTERFACE'") <= -1 THEN 'Online Interface Fan'
            ELSE 'Neutral'
        END AS preference
    FROM ratings
    WHERE category != 'OVERALL_RATING'
    GROUP BY customer_id
)

SELECT
    preference,
    --Get percentage of total
    ROUND((COUNT(customer_id) * 100.0) / (SELECT COUNT(customer_id) FROM pd2023_wk06_dsb_customer_survey), 1) AS "% of Total"
FROM preferences
GROUP BY preference;