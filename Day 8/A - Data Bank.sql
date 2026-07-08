-- A. Customer Nodes Exploration
-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT region_id || '-' || node_id) AS total_nodes
FROM customer_nodes;

-- 2. What is the number of nodes per region?
SELECT
	region_name,
	COUNT(DISTINCT node_id) AS total_nodes
FROM customer_nodes
INNER JOIN regions USING (region_id)
GROUP BY region_name
ORDER BY COUNT(DISTINCT node_id) DESC;

-- 3. How many customers are allocated to each region?
SELECT
	region_name,
    COUNT(DISTINCT customer_id) AS total_customers
FROM customer_nodes
INNER JOIN regions USING (region_id)
GROUP BY region_name;

-- 4. How many days on average are customers reallocated to a different node?
SELECT
	ROUND(AVG(end_date - start_date), 1) AS average_days_in_node
FROM customer_nodes
WHERE end_date <= current_date;

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
SELECT 
	region_name,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY end_date - start_date ASC) AS Median,
    PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY end_date - start_date ASC) AS "80th",
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY end_date - start_date ASC) AS "95th"
FROM customer_nodes
INNER JOIN regions USING (region_id)
WHERE end_date <= current_date
GROUP BY region_name;