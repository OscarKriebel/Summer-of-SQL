WITH stock_init AS (
    --Union all datasets together with added date field
    SELECT *, DATE_FROM_PARTS(2023, 1, 1) AS file_date
    FROM pd2023_wk08_01
    UNION ALL
    SELECT *, DATE_FROM_PARTS(2023,21, 1) AS file_date
    FROM pd2023_wk08_02
    UNION ALL
    SELECT *, DATE_FROM_PARTS(2023, 3, 1) AS file_date
    FROM pd2023_wk08_03
    UNION ALL
    SELECT *, DATE_FROM_PARTS(2023, 4, 1) AS file_date
    FROM pd2023_wk08_04
    UNION ALL
    SELECT *, DATE_FROM_PARTS(2023, 5, 1) AS file_date
    FROM pd2023_wk08_05
    UNION ALL
    SELECT *, DATE_FROM_PARTS(2023, 6, 1) AS file_date
    FROM pd2023_wk08_06
    UNION ALL
    SELECT *, DATE_FROM_PARTS(2023, 7, 1) AS file_date
    FROM pd2023_wk08_07
    UNION ALL
    SELECT *, DATE_FROM_PARTS(2023, 8, 1) AS file_date
    FROM pd2023_wk08_08
    UNION ALL
    SELECT *, DATE_FROM_PARTS(2023, 9, 1) AS file_date
    FROM pd2023_wk08_09
    UNION ALL
    SELECT *, DATE_FROM_PARTS(2023, 10, 1) AS file_date
    FROM pd2023_wk08_10
    UNION ALL
    SELECT *, DATE_FROM_PARTS(2023, 11, 1) AS file_date
    FROM pd2023_wk08_11
    UNION ALL
    SELECT *, DATE_FROM_PARTS(2023, 12, 1) AS file_date
    FROM pd2023_wk08_12
), stocks AS (
    --Filter and convert purchase price and market cap to numerics
    SELECT
        ticker,
        sector,
        market,
        stock_name,
        file_date,
        REPLACE(purchase_price, '$', '')::DOUBLE AS purchase_price,
        CASE RIGHT(market_cap, 1)
            WHEN 'M' THEN (REPLACE(REPLACE(market_cap, '$', ''), 'M', '')::DOUBLE * 1000000)
            WHEN 'B' THEN (REPLACE(REPLACE(market_cap, '$', ''), 'B', '')::DOUBLE * 1000000000)
            ELSE REPLACE(market_cap, '$', '')::DOUBLE
        END AS market_cap
    FROM stock_init
    WHERE market_cap != 'n/a'
)

SELECT
    CASE
        WHEN market_cap < 100000000 THEN 'Small'
        WHEN market_cap < 1000000000 THEN 'Medium'
        WHEN market_cap < 100000000000 THEN 'Large'
        ELSE 'Huge'
    END AS "Market Capitalization Categorization",
    CASE
        WHEN purchase_price < 25000 THEN 'Low'
        WHEN purchase_price < 50000 THEN 'Medium'
        WHEN purchase_price < 75000 THEN 'High'
        WHEN purchase_price <= 100000 THEN 'Very High'
    END AS "Purchase Price Categorization",
    file_date AS "File Date",
    ticker AS "Ticker",
    sector AS "Sector",
    market AS "Market",
    stock_name AS "Stock Name",
    market_cap AS "Market Capitalization",
    purchase_price AS "Purchase Price",
    --Top 5 based on purchase price for month and categories
    RANK() OVER (PARTITION BY file_date, "Purchase Price Categorization", "Market Capitalization Categorization" ORDER BY purchase_price) AS "Rank"
FROM stocks
QUALIFY "Rank" <= 5