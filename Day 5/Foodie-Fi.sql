-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
WITH desciption AS (
  SELECT
	customer_id,
    (CASE WHEN price IS NULL THEN 'ended their' ELSE 'started the ' || plan_name END)  || ' plan on ' || start_date AS description
  FROM subscriptions
  INNER JOIN plans USING (plan_id)
  WHERE customer_id <= 8
  ORDER BY customer_id ASC, start_date ASC
)

SELECT
	'Customer ' || customer_id || ' ' || STRING_AGG(d.description, ', then ') || '.' AS description
FROM desciption AS d
GROUP BY customer_id;


-- B. Data Analysis Questions
-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS number_of_customers
FROM subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT
	DATE_TRUNC('month', start_date) AS month,
    COUNT(customer_id) AS number_of_plans
FROM subscriptions
INNER JOIN plans USING (plan_id)
WHERE plan_name = 'trial'
GROUP BY DATE_TRUNC('month', start_date)
ORDER BY DATE_TRUNC('month', start_date) ASC;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT
	plan_name,
    COUNT(start_date) AS number_of_events
FROM subscriptions
INNER JOIN plans USING (plan_id)
WHERE DATE_PART('year', start_date) > 2020
GROUP BY plan_name;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT
	COUNT(DISTINCT customer_id) AS customer_count,
    ROUND((SELECT
	COUNT(DISTINCT customer_id) * 100.0
FROM subscriptions
INNER JOIN plans USING (plan_id)
WHERE plan_name = 'churn') / COUNT(DISTINCT customer_id), 1) AS percentage
FROM subscriptions;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH customers AS (
  SELECT
      customer_id,
      plan_name,
      start_date,
      ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date ASC) AS order
  FROM subscriptions
  INNER JOIN plans USING (plan_id)
), connected AS (
  SELECT
      *,
      LAG(customers.order, -1) OVER (PARTITION BY customer_id ORDER BY start_date ASC) AS future
  FROM customers
  WHERE plan_name IN ('trial', 'churn')
)

SELECT
	COUNT(*) AS number_of_churned_customers,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 1) AS percentage
FROM connected
WHERE plan_name = 'trial' AND future = connected.order + 1;

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH customers AS (
  SELECT
      customer_id,
      plan_name,
      start_date,
      ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date ASC) AS order
  FROM subscriptions
  INNER JOIN plans USING (plan_id)
), connected AS (
  SELECT
      *,
      LAG(customers.plan_name, -1) OVER (PARTITION BY customer_id ORDER BY start_date ASC) AS future
  FROM customers
)

SELECT
	future AS next_plan,
    COUNT(future) AS number_of_customers,
    ROUND((COUNT(future) * 100.0) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 1) AS percentage
FROM connected
WHERE plan_name = 'trial'
GROUP BY future
ORDER BY COUNT(future) DESC;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH customers AS (
  SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS ranking
  FROM subscriptions
  INNER JOIN plans USING (plan_id)
  WHERE start_date <= MAKE_DATE(2020,12,31)
)

SELECT
	plan_name,
    COUNT(customer_id) AS customer_count,
    ROUND((COUNT(customer_id) * 100.0) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 1) AS percentage
FROM customers
WHERE ranking = 1
GROUP BY plan_name
ORDER BY COUNT(customer_id) DESC;

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT
	COUNT(DISTINCT customer_id) AS number_of_customers
FROM subscriptions
INNER JOIN plans USING (plan_id)
WHERE plan_name = 'pro annual' AND DATE_PART('year', start_date) = 2020;

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH joining AS (
  SELECT
      customer_id,
      MIN(start_date) AS joining_date
  FROM subscriptions
  INNER JOIN plans USING (plan_id)
  GROUP BY customer_id
), annual AS (
  SELECT
      customer_id,
      MIN(start_date) AS annual_date
  FROM subscriptions
  INNER JOIN plans USING (plan_id)
  WHERE plan_name = 'pro annual'
  GROUP BY customer_id
), upgrade AS (
  SELECT
      customer_id,
      joining_date,
      annual_date,
      annual_date - joining_date AS number_of_days
  FROM subscriptions
  INNER JOIN plans USING (plan_id)
  INNER JOIN joining USING (customer_id)
  INNER JOIN annual USING (customer_id)
  GROUP BY customer_id, joining_date, annual_date
  ORDER BY customer_id ASC
)

SELECT
	ROUND(AVG(number_of_days * 1.0), 0) AS average_number_of_days
FROM upgrade;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH joining AS (
  SELECT
      customer_id,
      MIN(start_date) AS joining_date
  FROM subscriptions
  INNER JOIN plans USING (plan_id)
  GROUP BY customer_id
), annual AS (
  SELECT
      customer_id,
      MIN(start_date) AS annual_date
  FROM subscriptions
  INNER JOIN plans USING (plan_id)
  WHERE plan_name = 'pro annual'
  GROUP BY customer_id
), upgrade AS (
  SELECT
      customer_id,
      joining_date,
      annual_date,
      annual_date - joining_date AS number_of_days
  FROM subscriptions
  INNER JOIN plans USING (plan_id)
  INNER JOIN joining USING (customer_id)
  INNER JOIN annual USING (customer_id)
  GROUP BY customer_id, joining_date, annual_date
  ORDER BY customer_id ASC
), bucket AS (
  SELECT
      CEIL(number_of_days * 1.0 / 30) * 30 AS max_days,
      customer_id,
  	  number_of_days
  FROM upgrade
)

SELECT
	max_days - 30 || '-' || max_days AS days_bucket,
    COUNT(DISTINCT customer_id) AS customer_count
FROM bucket
GROUP BY max_days
ORDER BY max_days ASC;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH pro AS (
  SELECT
      customer_id,
      plan_name,
      start_date
  FROM subscriptions
  INNER JOIN plans USING (plan_id)
  WHERE plan_name = 'pro monthly' AND DATE_PART('year', start_date) = 2020
), basic AS (
  SELECT
      customer_id,
      plan_name,
      start_date
  FROM subscriptions
  INNER JOIN plans USING (plan_id)
  WHERE plan_name = 'basic monthly' AND DATE_PART('year', start_date) = 2020
)

SELECT
	COUNT(*) AS downgrade_count
FROM pro
INNER JOIN basic USING (customer_id)
WHERE pro.start_date < basic.start_date;