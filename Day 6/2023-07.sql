WITH account_information AS (
    --Unnest Account Holder ID into different rows based on delimiter
    --And filter out the accounts we don't want
    SELECT
        account_number,
        account_type,
        balance_date,
        balance,
        b.value::STRING AS account_holder_id
    FROM pd2023_wk07_account_information a, LATERAL FLATTEN(INPUT => SPLIT(a.account_holder_id, ', ')) b
    WHERE account_type != 'Platinum' AND account_holder_id IS NOT NULL
)

SELECT
    transaction_id AS "Transaction ID",
    transaction_path.account_to AS "Account To",
    transaction_detail.transaction_date AS "Transaction Date",
    transaction_detail.value AS "Value",
    account_information.account_number AS "Account Number",
    account_information.account_type AS "Account Type",
    account_information.balance_date AS "Balance Date",
    account_information.balance AS "Balance",
    account_holders.name AS "Name",
    account_holders.date_of_birth AS "Date of Birth",
    '0' || account_holders.contact_number AS "Contact Number",
    account_holders.first_line_of_address AS "First Line of Address"
FROM pd2023_wk07_transaction_path AS transaction_path
INNER JOIN pd2023_wk07_transaction_detail AS transaction_detail USING (transaction_id)
INNER JOIN account_information
    ON transaction_path.account_from = account_information.account_number
INNER JOIN pd2023_wk07_account_holders AS account_holders
    ON account_information.account_holder_id = account_holders.account_holder_id
WHERE transaction_detail.value > 1000 AND transaction_detail.cancelled_ = 'N';