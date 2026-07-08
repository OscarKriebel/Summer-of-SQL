-- B. Customer Transactions
-- 1. What is the unique count and total amount for each transaction type?
SELECT
	txn_type,
    COUNT(*) AS transaction_count
FROM customer_transactions
GROUP BY txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
WITH deposits AS (
  SELECT
      customer_id,
      COUNT(*) AS customer_transactions,
      SUM(txn_amount) AS total_amount
  FROM customer_transactions
  WHERE txn_type = 'deposit'
  GROUP BY customer_id
)

SELECT
	ROUND(AVG(customer_transactions), 1) AS average_total_deposits,
    ROUND(AVG(total_amount), 1) AS average_deposits_amount
FROM deposits;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH customers AS (
  SELECT
      DATE_TRUNC('month', txn_date) AS transaction_month,
      customer_id,
      COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) + COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS purchase_and_withdrawal_count,
      COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
  	  COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_count,
      COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_count
  FROM customer_transactions
  GROUP BY customer_id, DATE_TRUNC('month', txn_date)
)

SELECT
	transaction_month,
	COUNT(*) AS customer_count
FROM customers
WHERE deposit_count > 1 AND purchase_and_withdrawal_count = 1
GROUP BY transaction_month;


-- 4. What is the closing balance for each customer at the end of the month?
WITH customer_balance AS (
SELECT
	customer_id,
    txn_date,
    ROW_NUMBER() OVER (PARTITION BY customer_id, DATE_TRUNC('month', txn_date) ORDER BY txn_date DESC) AS month_order,
    txn_type,
    txn_amount,
    SUM(CASE txn_type 
        	WHEN 'deposit' THEN txn_amount 
        	WHEN 'withdrawal' THEN -1 * txn_amount
        	WHEN 'purchase' THEN -1 * txn_amount
    END) OVER (PARTITION BY customer_id ORDER BY txn_date ASC) AS balance
FROM customer_transactions
)

SELECT
	customer_id,
    DATE_TRUNC('month', txn_date) AS transaction_month,
    balance
FROM customer_balance
WHERE month_order = 1
ORDER BY customer_id ASC, txn_date ASC;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
--A little confused about the wording of this one, but I have taken it to mean out of all customers, how many have had a single increase from one month to the next of at least 5%
WITH customer_balance AS (
  SELECT
      customer_id,
      txn_date,
      DATE_TRUNC('month', txn_date) AS txn_month,
      ROW_NUMBER() OVER (PARTITION BY customer_id, DATE_TRUNC('month', txn_date) ORDER BY txn_date DESC) AS month_order,
      txn_type,
      txn_amount,
      SUM(CASE txn_type 
              WHEN 'deposit' THEN txn_amount 
              WHEN 'withdrawal' THEN -1 * txn_amount
              WHEN 'purchase' THEN -1 * txn_amount
      END) OVER (PARTITION BY customer_id ORDER BY txn_date ASC) AS balance
  FROM customer_transactions
), customer_closing AS (
  SELECT
    customer_id,
  	txn_month,
  	balance AS current_balance,
  	LAG(balance) OVER (PARTITION BY customer_id ORDER BY txn_month ASC) AS previous_balance
  FROM customer_balance
  WHERE month_order = 1
)

SELECT
	ROUND(COUNT(DISTINCT customer_id) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions), 1) AS percentage_increased
FROM customer_closing
--Check that can have increase to balance and if previous was 0 then see if current is positive or compare percentage change to 5%
WHERE (previous_balance IS NOT NULL) AND ((previous_balance = 0 AND current_balance > 0) OR ((current_balance - previous_balance) * 1.0 / ABS(previous_balance)) > 0.05);