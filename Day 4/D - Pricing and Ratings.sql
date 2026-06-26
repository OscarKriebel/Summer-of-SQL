-- D. Pricing and Ratings
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT
	SUM(CASE WHEN pizza_id = 1 THEN 12 ELSE 10 END) AS total_amount_earned
FROM customer_orders
INNER JOIN runner_orders USING (order_id)
WHERE runner_orders.pickup_time != 'null';

-- 2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
WITH fixed_customer AS (
  SELECT
  	ROW_NUMBER() OVER (ORDER BY 1) AS id, order_id, customer_id, pizza_id, order_time,
  	CASE WHEN exclusions = 'null' OR exclusions = '' THEN NULL ELSE exclusions END,
  	CASE WHEN extras = 'null' OR extras = '' THEN NULL ELSE extras END
  FROM customer_orders
), extra AS (
  SELECT
    id,
  	UNNEST(STRING_TO_ARRAY(extras, ', ')) AS extras
  FROM fixed_customer
), pizzas AS (
  SELECT
    id,
    pizza_id,
    COUNT(extra.extras) AS extras
  FROM fixed_customer
  LEFT JOIN extra USING (id)
  GROUP BY id, pizza_id
)

SELECT SUM(CASE WHEN pizza_id = 1 THEN 12 + extras ELSE 10 + extras END) AS amount 
FROM pizzas;

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "rating" INTEGER
);

INSERT INTO runner_ratings ("order_id", "runner_id", "rating") VALUES
('1', '1', '5'),
('2', '1', '4'),
('3', '1', '3'),
('4', '2', '2'),
('5', '3', '1'),
('7', '2', '5'),
('8', '2', '4'),
('10', '1', '3');

-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id, order_id, runner_id, rating, order_time, pickup_time, Time between order and pickup, Delivery duration, Average speed, Total number of pizzas
WITH fixed_customer AS (
  SELECT
  	ROW_NUMBER() OVER (ORDER BY 1) AS id, order_id, customer_id, pizza_id, order_time,
  	CASE WHEN exclusions = 'null' OR exclusions = '' THEN NULL ELSE exclusions END,
  	CASE WHEN extras = 'null' OR extras = '' THEN NULL ELSE extras END
  FROM customer_orders
), fixed_runners AS (
  SELECT
	order_id,
    runner_id,
    CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END AS pickup_time,
    CASE WHEN distance = 'null' THEN NULL ELSE TRIM(REPLACE(distance, 'km', ''))::numeric END AS distance,
    CASE WHEN duration = 'null' THEN NULL ELSE REGEXP_REPLACE(duration, '[^0-9]', '', 'g')::numeric END AS duration,
    CASE WHEN cancellation = '' OR cancellation = 'null' THEN NULL ELSE cancellation END AS cancellation
  FROM runner_orders
), orders AS (
  SELECT
  	customer_id,
    order_id,
    order_time,
  	COUNT(pizza_id) AS total_pizzas
  FROM fixed_customer
  GROUP BY customer_id, order_id, order_time
)

SELECT
	orders.customer_id,
    orders.order_id,
    runners.runner_id,
    ratings.rating,
    orders.order_time,
    runners.pickup_time,
    DATE_PART('minute',runners.pickup_time::timestamp - orders.order_time) AS time_between_order_and_pickup,
    runners.duration AS delivery_duration,
    ROUND((runners.distance / (runners.duration / 60))::numeric, 2) AS average_speed,
    orders.total_pizzas AS total_number_of_pizzas
FROM orders
INNER JOIN fixed_runners AS runners USING (order_id)
LEFT JOIN runner_ratings AS ratings
	ON runners.runner_id = ratings.runner_id AND runners.order_id = ratings.order_id;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
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
	SUM(CASE WHEN pizza_id = 1 THEN 12 - (0.3 * fixed_runners.distance) ELSE 10 - (0.3 * fixed_runners.distance) END) AS total_amount_earned
FROM customer_orders
INNER JOIN fixed_runners USING (order_id)
WHERE fixed_runners.pickup_time != 'null';

-- E. Bonus Questions
-- 6. If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
INSERT INTO pizza_names ("pizza_id", "pizza_name") VALUES
(3, 'Supreme');

INSERT INTO pizza_recipes ("pizza_id", "toppings") VALUES
(3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');