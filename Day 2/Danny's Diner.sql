/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	sales.customer_id,
    SUM(menu.price) AS total_spent
FROM dannys_diner.sales AS sales
INNER JOIN dannys_diner.menu AS menu
	ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY SUM(menu.price) DESC;

-- 2. How many days has each customer visited the restaurant?
SELECT 
	customer_id,
    COUNT(DISTINCT order_date) AS days_visited
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY COUNT(DISTINCT order_date) DESC;

-- 3. What was the first item from the menu purchased by each customer?
WITH first_purchase AS (
  SELECT 
  	sales.customer_id,
  	menu.product_name,
  	sales.order_date,
  	DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date ASC) AS ranking
  FROM dannys_diner.sales AS sales
  INNER JOIN dannys_diner.menu AS menu
  	ON sales.product_id = menu.product_id
)

SELECT 
	customer_id,
    product_name,
    order_date
FROM first_purchase
WHERE ranking = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH purchases AS (
  	SELECT 
  		sales.product_id,
  		menu.product_name,
  		menu.price,
  		SUM(menu.price) AS total
  	FROM dannys_diner.sales AS sales
  	INNER JOIN dannys_diner.menu AS menu
  		ON sales.product_id = menu.product_id
  	GROUP BY sales.product_id, menu.product_name, menu.price
  	ORDER BY SUM(menu.price) DESC
  	LIMIT 1
)

SELECT
	sales.customer_id,
    purchases.product_name,
    SUM(purchases.price) AS total_customer_spent,
    purchases.total AS total_spent
FROM purchases
INNER JOIN dannys_diner.sales AS sales
	ON purchases.product_id = sales.product_id
GROUP BY sales.customer_id, purchases.product_name, purchases.total
ORDER BY SUM(purchases.price) DESC;

-- 5. Which item was the most popular for each customer?
WITH purchases AS (
  SELECT 
  	sales.customer_id,
  	sales.product_id,
  	menu.product_name,
  	COUNT(*) AS bought,
  	DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY COUNT(*) DESC) AS ranking
  FROM dannys_diner.sales AS sales
  INNER JOIN dannys_diner.menu AS menu
  	ON sales.product_id = menu.product_id
  GROUP BY sales.customer_id, sales.product_id, menu.product_name
)

SELECT 
	customer_id,
    product_name,
    bought
FROM purchases
WHERE ranking = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH purchases AS (
  SELECT 
  	sales.customer_id AS customer_id,
  	menu.product_name,
  	sales.order_date,
  	DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date ASC) AS ranking
  FROM dannys_diner.sales AS sales
  INNER JOIN dannys_diner.members AS members
  	ON sales.customer_id = members.customer_id
  INNER JOIN dannys_diner.menu AS menu
  	ON sales.product_id = menu.product_id
  WHERE sales.order_date >= members.join_date
)

SELECT
	customer_id,
    product_name,
    order_date
FROM purchases
WHERE ranking = 1
GROUP BY customer_id, product_name, order_date;

-- 7. Which item was purchased just before the customer became a member?
WITH purchases AS (
  SELECT 
  	sales.customer_id AS customer_id,
  	menu.product_name,
  	sales.order_date,
  	DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS ranking
  FROM dannys_diner.sales AS sales
  INNER JOIN dannys_diner.members AS members
  	ON sales.customer_id = members.customer_id
  INNER JOIN dannys_diner.menu AS menu
  	ON sales.product_id = menu.product_id
  WHERE sales.order_date < members.join_date
)

SELECT
	customer_id,
    product_name,
    order_date
FROM purchases
WHERE ranking = 1
GROUP BY customer_id, product_name, order_date;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
	sales.customer_id,
    SUM(menu.price) AS total_amount_spent,
    COUNT(*) AS total_items
FROM dannys_diner.sales AS sales
INNER JOIN dannys_diner.members AS members
	ON sales.customer_id = members.customer_id
INNER JOIN dannys_diner.menu AS menu
	ON sales.product_id = menu.product_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
	sales.customer_id,
    SUM(10 * (CASE WHEN menu.product_name = 'sushi' THEN menu.price * 2 ELSE menu.price END)) AS points
FROM dannys_diner.sales AS sales
INNER JOIN dannys_diner.menu AS menu
	ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT 
  sales.customer_id AS customer_id,
  SUM(
      CASE WHEN sales.order_date BETWEEN members.join_date AND members.join_date + INTERVAL '6 days' 
      	   THEN (20 * (CASE WHEN menu.product_name = 'sushi' THEN menu.price * 2 ELSE menu.price END))
      	   ELSE (10 * (CASE WHEN menu.product_name = 'sushi' THEN menu.price * 2 ELSE menu.price END)) 
      END) AS points
FROM dannys_diner.sales AS sales
INNER JOIN dannys_diner.menu AS menu
  ON sales.product_id = menu.product_id
INNER JOIN dannys_diner.members AS members
  ON sales.customer_id = members.customer_id
WHERE sales.order_date < TIMESTAMP '2021-02-01'
GROUP BY sales.customer_id;

-- Bonus. Join All The Things and Rank All The Things
WITH insight AS (SELECT
	sales.customer_id AS customer_id,
    sales.order_date AS order_date,
    menu.product_name AS product_name,
    menu.price AS price,
    CASE WHEN members.customer_id IS NULL OR sales.order_date < members.join_date 
    	THEN 'N' ELSE 'Y' END AS member
FROM dannys_diner.sales AS sales
INNER JOIN dannys_diner.menu AS menu
	ON sales.product_id = menu.product_id
LEFT JOIN dannys_diner.members AS members
	ON sales.customer_id = members.customer_id
ORDER BY sales.customer_id, sales.order_date ASC),
rankings AS (
  SELECT
  	customer_id,
  	order_date,
  	DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS ranking
  FROM insight
  WHERE member = 'Y'
  GROUP BY customer_id, order_date
)

SELECT 
	insight.customer_id,
    insight.order_date,
    insight.product_name,
    insight.price,
    insight.member,
	rankings.ranking
FROM insight
LEFT JOIN rankings
	ON insight.customer_id = rankings.customer_id AND insight.order_date = rankings.order_date;