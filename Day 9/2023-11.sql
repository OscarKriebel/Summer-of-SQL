WITH branches AS (
    SELECT
        branch AS "Branch",
        branch_long AS "Branch Long",
        branch_lat AS "Branch Lat",
        branch_long / (180 / PI()) AS "Branch Longitude",
        branch_lat / (180 / PI()) AS "Branch Latitude"
    FROM pd2023_wk11_dsb_branches
), customers AS (
    SELECT
        customer AS "Customer",
        address_long AS "Address Long",
        address_lat AS "Address Lat",
        address_long / (180 / PI()) AS "Customer Longitude",
        address_lat / (180 / PI()) AS "Customer Latitude"
    FROM pd2023_wk11_dsb_customer_locations
), distances AS (
    SELECT
        *,
        --3963.0 * arccos[(sin(lat1) * sin(lat2)) + cos(lat1) * cos(lat2) * cos(long2 - long1)]
        --Where 1 is the customer and 2 is the branch
        ROUND(3963.0 * ACOS((SIN("Customer Latitude") * sin("Branch Latitude")) + cos("Customer Latitude") * cos("Branch Latitude") * cos("Branch Longitude" - "Customer Longitude")), 2) AS "Distance"
    FROM customers
    CROSS JOIN branches
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "Customer" ORDER BY "Distance" ASC) = 1
    ORDER BY "Customer", "Distance"
)

SELECT
    "Branch",
    "Branch Long",
    "Branch Lat",
    "Distance",
    ROW_NUMBER() OVER (PARTITION BY "Branch" ORDER BY "Distance" ASC) AS "Customer Priority",
    "Customer",
    "Address Long",
    "Address Lat"
FROM distances
ORDER BY "Branch", "Customer Priority" ASC;