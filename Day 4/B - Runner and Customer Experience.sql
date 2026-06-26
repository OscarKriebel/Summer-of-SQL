-- B. Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
	DATE_PART('week', registration_date + 3) AS week,
    COUNT(runner_id) AS total_runners
FROM runners
GROUP BY DATE_PART('week', registration_date + 3)
ORDER BY DATE_PART('week', registration_date + 3) ASC;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH orders AS (
  SELECT
	order_id,
    order_time
  FROM customer_orders
  GROUP BY order_id, order_time
)

SELECT
	runner_orders.runner_id,
    ROUND(AVG(DATE_PART('minute',runner_orders.pickup_time::timestamp - orders.order_time)::numeric), 2) AS average_time_in_minutes
FROM orders
INNER JOIN runner_orders USING (order_id)
WHERE runner_orders.pickup_time != 'null'
GROUP BY runner_orders.runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH orders AS (
  SELECT
	order_id,
    order_time,
  	COUNT(pizza_id) AS pizzas
  FROM customer_orders
  GROUP BY order_id, order_time
),
pizza_orders AS (
	SELECT
		orders.order_id,
    	orders.pizzas,
      DATE_PART('minute', runner_orders.pickup_time::timestamp - orders.order_time) AS time_in_minutes,
      ROUND((DATE_PART('minute', runner_orders.pickup_time::timestamp - orders.order_time) / orders.pizzas)::numeric, 2) AS minutes_per_pizza
  FROM orders
  INNER JOIN runner_orders USING (order_id)
  WHERE runner_orders.pickup_time != 'null'
)

SELECT
	pizzas,
    ROUND(AVG(minutes_per_pizza)::numeric, 2) AS average_time_per_pizza
FROM pizza_orders
GROUP BY pizzas;

-- 4. What was the average distance travelled for each customer?
WITH fixed_runners AS (
  SELECT
	order_id,
    runner_id,
    CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END AS pickup_time,
    CASE WHEN distance = 'null' THEN NULL ELSE TRIM(REPLACE(distance, 'km', ''))::numeric END AS distance,
    CASE WHEN duration = 'null' THEN NULL ELSE REGEXP_REPLACE(duration, '[^0-9]', '', 'g')::numeric END AS duration,
    CASE WHEN cancellation = '' OR cancellation = 'null' THEN NULL ELSE cancellation END AS cancellation
  FROM runner_orders
)

SELECT
	co.customer_id,
    ROUND(AVG(fr.distance)::numeric, 1) AS average_distance
FROM fixed_runners AS fr
INNER JOIN (
  SELECT
  	order_id,
    customer_id
  FROM customer_orders
  GROUP BY order_id, customer_id
) AS co USING (order_id)
WHERE fr.distance IS NOT NULL
GROUP BY co.customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
WITH fixed_runners AS (
  SELECT
	order_id,
    runner_id,
    CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END AS pickup_time,
    CASE WHEN distance = 'null' THEN NULL ELSE TRIM(REPLACE(distance, 'km', ''))::numeric END AS distance,
    CASE WHEN duration = 'null' THEN NULL ELSE REGEXP_REPLACE(duration, '[^0-9]', '', 'g')::numeric END AS duration,
    CASE WHEN cancellation = '' OR cancellation = 'null' THEN NULL ELSE cancellation END AS cancellation
  FROM runner_orders
)

SELECT MAX(duration) - MIN(duration) AS delivery_time_difference
FROM fixed_runners
WHERE pickup_time IS NOT NULL;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
WITH fixed_runners AS (
  SELECT
	order_id,
    runner_id,
    CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END AS pickup_time,
    CASE WHEN distance = 'null' THEN NULL ELSE TRIM(REPLACE(distance, 'km', ''))::numeric END AS distance,
    CASE WHEN duration = 'null' THEN NULL ELSE REGEXP_REPLACE(duration, '[^0-9]', '', 'g')::numeric END AS duration,
    CASE WHEN cancellation = '' OR cancellation = 'null' THEN NULL ELSE cancellation END AS cancellation
  FROM runner_orders
)

SELECT
	runner_id,
    ROUND(AVG(distance / (duration / 60))::numeric, 2) AS average_speed_in_km_per_hour
FROM fixed_runners
WHERE pickup_time IS NOT NULL
GROUP BY runner_id;

-- 7. What is the successful delivery percentage for each runner?
WITH fixed_runners AS (
  SELECT
	order_id,
    runner_id,
    CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END AS pickup_time,
    CASE WHEN distance = 'null' THEN NULL ELSE TRIM(REPLACE(distance, 'km', ''))::numeric END AS distance,
    CASE WHEN duration = 'null' THEN NULL ELSE REGEXP_REPLACE(duration, '[^0-9]', '', 'g')::numeric END AS duration,
    CASE WHEN cancellation = '' OR cancellation = 'null' THEN NULL ELSE cancellation END AS cancellation
  FROM runner_orders
)

SELECT
	runner_id,
    ROUND(((COUNT(pickup_time) * 1.0) / COUNT(*))::numeric, 2) AS successful_delivery_percentage
FROM fixed_runners
GROUP BY runner_id;