--C. Ingredient Optimization
-- 1. What are the standard ingredients for each pizza?
WITH recipes AS (
    SELECT 
		pizza_id,
		UNNEST(STRING_TO_ARRAY(toppings, ', '))::numeric AS topping_id
	FROM pizza_recipes
)

SELECT
	pizza_names.pizza_name,
    STRING_AGG(pizza_toppings.topping_name, ', ') AS toppings
FROM pizza_names
INNER JOIN recipes USING (pizza_id)
INNER JOIN pizza_toppings USING (topping_id)
GROUP BY pizza_names.pizza_name;

-- 2. What was the most commonly added extra?
WITH fixed_customer AS (
  SELECT
  	order_id, customer_id, pizza_id, order_time,
  	CASE WHEN exclusions = 'null' OR exclusions = '' THEN NULL ELSE exclusions END,
  	CASE WHEN extras = 'null' OR extras = '' THEN NULL ELSE extras END
  FROM customer_orders
), extra AS (
  SELECT
      order_id,
      UNNEST(STRING_TO_ARRAY(extras, ', '))::numeric AS topping_id
  FROM fixed_customer
  WHERE extras IS NOT NULL
)

SELECT
	pizza_toppings.topping_name,
    COUNT(*)
FROM extra
INNER JOIN pizza_toppings USING (topping_id)
GROUP BY pizza_toppings.topping_name
ORDER BY COUNT(*) DESC
LIMIT 1;

-- 3. What was the most common exclusion?
WITH fixed_customer AS (
  SELECT
  	order_id, customer_id, pizza_id, order_time,
  	CASE WHEN exclusions = 'null' OR exclusions = '' THEN NULL ELSE exclusions END,
  	CASE WHEN extras = 'null' OR extras = '' THEN NULL ELSE extras END
  FROM customer_orders
), exclusion AS (
  SELECT
      order_id,
      UNNEST(STRING_TO_ARRAY(exclusions, ', '))::numeric AS topping_id
  FROM fixed_customer
  WHERE exclusions IS NOT NULL
)

SELECT
	pizza_toppings.topping_name,
    COUNT(*)
FROM exclusion
INNER JOIN pizza_toppings USING (topping_id)
GROUP BY pizza_toppings.topping_name
ORDER BY COUNT(*) DESC
LIMIT 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH fixed_customer AS (
  SELECT
  	ROW_NUMBER() OVER (ORDER BY 1) AS id, order_id, customer_id, pizza_id, order_time,
  	CASE WHEN exclusions = 'null' OR exclusions = '' THEN NULL ELSE exclusions END,
  	CASE WHEN extras = 'null' OR extras = '' THEN NULL ELSE extras END
  FROM customer_orders
), pizzas_num AS (
  SELECT
  	  fc.id AS id,
      fc.order_id AS order_id,
      fc.pizza_id,
      pizza_names.pizza_name AS pizza_name,
   	  t.exclusions,
      t.extras
  FROM fixed_customer AS fc
  LEFT JOIN (
    SELECT
    	fc.id AS id,
    	UNNEST(STRING_TO_ARRAY(exclusions, ', '))::numeric AS exclusions,
    	UNNEST(STRING_TO_ARRAY(extras, ', '))::numeric AS extras 
    FROM fixed_customer AS fc
  ) AS t USING (id)
  INNER JOIN pizza_names USING (pizza_id)
), pizza_string AS (
  SELECT
      pizzas.id,
      pizzas.order_id,
      pizzas.pizza_name,
      ' - Exclude ' || STRING_AGG(pta.topping_name, ', ') AS exclusions,
      ' - Extra ' || STRING_AGG(ptb.topping_name, ', ') AS extras
  FROM pizzas_num AS pizzas
  LEFT JOIN pizza_toppings AS pta
      ON pizzas.exclusions = pta.topping_id
  LEFT JOIN pizza_toppings AS ptb
      ON pizzas.extras = ptb.topping_id
  GROUP BY pizzas.id, pizzas.order_id, pizzas.pizza_name
)

SELECT 
	order_id,
    CONCAT(pizza_name, exclusions, extras) AS pizza_order	
FROM pizza_string AS pizzas;

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
WITH fixed_customer AS (
  SELECT
  	ROW_NUMBER() OVER (ORDER BY 1) AS id, order_id, customer_id, pizza_id, order_time,
  	CASE WHEN exclusions = 'null' OR exclusions = '' THEN NULL ELSE exclusions END,
  	CASE WHEN extras = 'null' OR extras = '' THEN NULL ELSE extras END
  FROM customer_orders
), recipes AS (
    SELECT
  		fc.id,
  		fc.pizza_id,
        recipes.topping_id
  	FROM fixed_customer AS fc
    INNER JOIN (
      SELECT 
          pizza_id,
          UNNEST(STRING_TO_ARRAY(toppings, ', '))::numeric AS topping_id
      FROM pizza_recipes
    ) AS recipes USING (pizza_id)
), pizzas_num AS (
  SELECT
  	  fc.id,
  	  fc.pizza_id,
   	  t.exclusions,
      t.extras
  FROM fixed_customer AS fc
  LEFT JOIN (
    SELECT
    	fc.id AS id,
    	UNNEST(STRING_TO_ARRAY(exclusions, ', '))::numeric AS exclusions,
    	UNNEST(STRING_TO_ARRAY(extras, ', '))::numeric AS extras 
    FROM fixed_customer AS fc
  ) AS t USING (id)
), toppings AS (
  SELECT
  	id,
    pizza_id,
  	topping_id,
  	COUNT(*) AS number_on
  FROM (
    SELECT
      recipes.id,
      recipes.pizza_id,
      recipes.topping_id
    FROM recipes
    UNION ALL
    SELECT
      pizzas_num.id,
      pizzas_num.pizza_id,
      pizzas_num.extras AS topping_id
    FROM pizzas_num
    WHERE pizzas_num.extras IS NOT NULL
  ) AS pizza_toppings
  GROUP BY id, pizza_id, topping_id
), pizzas_all AS (
  SELECT
  	toppings.id,
    pizza_names.pizza_name || ': ' AS pizza_name,
  	pizza_toppings.topping_name,
  	toppings.number_on - COALESCE(exclusions.number_off, 0) AS total
  FROM toppings
  LEFT JOIN (
    SELECT
        id,
        exclusions AS topping_id,
        COUNT(*) AS number_off
    FROM pizzas_num
    WHERE exclusions IS NOT NULL
    GROUP BY id, exclusions
  ) AS exclusions USING(id, topping_id)
  INNER JOIN pizza_toppings USING (topping_id)
  INNER JOIN pizza_names USING (pizza_id)
  WHERE toppings.number_on - COALESCE(exclusions.number_off, 0) > 0
  ORDER BY id ASC, Lower(topping_name) ASC
), final AS (
   	SELECT
 	  id,
      pizza_name || STRING_AGG(CASE WHEN total > 1 THEN total::varchar(2) || 'x' || topping_name ELSE topping_name END, ', ') AS pizza
	FROM pizzas_all
 	GROUP BY id, pizza_name
)
    
SELECT
	fc.order_id,
    final.pizza
FROM final
INNER JOIN fixed_customer AS fc USING (id);

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH fixed_customer AS (
  SELECT
  	ROW_NUMBER() OVER (ORDER BY 1) AS id, co.order_id, co.customer_id, co.pizza_id, co.order_time,
  	CASE WHEN co.exclusions = 'null' OR co.exclusions = '' THEN NULL ELSE co.exclusions END AS exclusions,
  	CASE WHEN co.extras = 'null' OR co.extras = '' THEN NULL ELSE co.extras END AS extras
  FROM customer_orders AS co
  INNER JOIN runner_orders USING (order_id)
  WHERE runner_orders.pickup_time != 'null'
), recipes AS (
    SELECT
  		fc.id,
  		fc.pizza_id,
        recipes.topping_id
  	FROM fixed_customer AS fc
    INNER JOIN (
      SELECT 
          pizza_id,
          UNNEST(STRING_TO_ARRAY(toppings, ', '))::numeric AS topping_id
      FROM pizza_recipes
    ) AS recipes USING (pizza_id)
), pizzas_num AS (
  SELECT
  	  fc.id,
  	  fc.pizza_id,
   	  t.exclusions,
      t.extras
  FROM fixed_customer AS fc
  LEFT JOIN (
    SELECT
    	fc.id AS id,
    	UNNEST(STRING_TO_ARRAY(exclusions, ', '))::numeric AS exclusions,
    	UNNEST(STRING_TO_ARRAY(extras, ', '))::numeric AS extras 
    FROM fixed_customer AS fc
  ) AS t USING (id)
), toppings AS (
  SELECT
  	id,
    pizza_id,
  	topping_id,
  	COUNT(*) AS number_on
  FROM (
    SELECT
      recipes.id,
      recipes.pizza_id,
      recipes.topping_id
    FROM recipes
    UNION ALL
    SELECT
      pizzas_num.id,
      pizzas_num.pizza_id,
      pizzas_num.extras AS topping_id
    FROM pizzas_num
    WHERE pizzas_num.extras IS NOT NULL
  ) AS pizza_toppings
  GROUP BY id, pizza_id, topping_id
), pizzas_all AS (
  SELECT
  	toppings.id,
    pizza_toppings.topping_name,
  	toppings.number_on - COALESCE(exclusions.number_off, 0) AS total
  FROM toppings
  LEFT JOIN (
    SELECT
        id,
        exclusions AS topping_id,
        COUNT(*) AS number_off
    FROM pizzas_num
    WHERE exclusions IS NOT NULL
    GROUP BY id, exclusions
  ) AS exclusions USING(id, topping_id)
  INNER JOIN pizza_toppings USING (topping_id)
  WHERE toppings.number_on - COALESCE(exclusions.number_off, 0) > 0
)

SELECT
	topping_name,
    SUM(total) AS total
FROM pizzas_all
GROUP BY topping_name
ORDER BY SUM(total) DESC;