-- A. Pizza Metrics
-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS orders
FROM customer_orders;

-- 2. How many unique customer orders were made?
SELECT 
	COUNT(DISTINCT order_id) AS orders
FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT
	runner_id,
    COUNT(*) AS total_orders
FROM runner_orders
WHERE runner_orders.pickup_time != 'null'
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT
	pizza_name,
    COUNT(customer_orders.order_id) AS total_pizzas
FROM customer_orders
INNER JOIN pizza_names USING (pizza_id)
INNER JOIN runner_orders USING (order_id)
WHERE runner_orders.pickup_time != 'null'
GROUP BY pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
	customer_id,
	pizza_name,
    COUNT(customer_orders.order_id) AS total_pizzas
FROM customer_orders
INNER JOIN pizza_names USING (pizza_id)
GROUP BY customer_id, pizza_name
ORDER BY customer_id, pizza_name;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT 
	customer_orders.order_id,
    COUNT(pizza_id) AS pizzas_ordered
FROM customer_orders
INNER JOIN runner_orders USING (order_id)
WHERE runner_orders.pickup_time != 'null'
GROUP BY customer_orders.order_id
ORDER BY COUNT(pizza_id) DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH customer_order AS (
  SELECT
  	order_id, customer_id, pizza_id, order_time,
  	CASE WHEN exclusions = 'null' OR exclusions = '' THEN NULL ELSE exclusions END,
  	CASE WHEN extras = 'null' OR extras = '' THEN NULL ELSE extras END
  FROM customer_orders
)

SELECT
	CASE WHEN exclusions IS NULL AND extras IS NULL THEN 'No Changes' ELSE 'At Least 1 Change' END AS "Changed?",
    COUNT(pizza_id) AS total_pizzas
FROM customer_order
GROUP BY CASE WHEN exclusions IS NULL AND extras IS NULL THEN 'No Changes' ELSE 'At Least 1 Change' END;

-- 8. How many pizzas were delivered that had both exclusions and extras?
WITH customer_order AS (
  SELECT
  	order_id, customer_id, pizza_id, order_time,
  	CASE WHEN exclusions = 'null' OR exclusions = '' THEN NULL ELSE exclusions END,
  	CASE WHEN extras = 'null' OR extras = '' THEN NULL ELSE extras END
  FROM customer_orders
)

SELECT
	CASE WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 'Both Exclusion and Extra' ELSE 'Not Both' END AS "Changed?",
    COUNT(pizza_id) AS total_pizzas
FROM customer_order
GROUP BY CASE WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 'Both Exclusion and Extra' ELSE 'Not Both' END;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT
	DATE_PART('hour', order_time) AS "hour",
	COUNT(pizza_id) AS total_pizzas
FROM customer_orders
GROUP BY DATE_PART('hour', order_time)
ORDER BY COUNT(pizza_id) DESC;

-- 10. What was the volume of orders for each day of the week?
WITH dow AS (
  SELECT
  	order_time,
  	CASE 
  		WHEN DATE_PART('dow', order_time) = 0 THEN 'Sunday'
  		WHEN DATE_PART('dow', order_time) = 1 THEN 'Monday'
  		WHEN DATE_PART('dow', order_time) = 2 THEN 'Tuesday'
  		WHEN DATE_PART('dow', order_time) = 3 THEN 'Wednesday'
  		WHEN DATE_PART('dow', order_time) = 4 THEN 'Thursday'
  		WHEN DATE_PART('dow', order_time) = 5 THEN 'Friday'
  		WHEN DATE_PART('dow', order_time) = 6 THEN 'Saturday'
  	END AS day_of_week,
  	pizza_id
  FROM customer_orders
)

SELECT
	day_of_week,
    COUNT(pizza_id) AS total_pizzas
FROM dow
GROUP BY day_of_week
ORDER BY COUNT(pizza_id) DESC;