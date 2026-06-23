SELECT 
    transact.transaction_id as "Transaction ID",
    'GB' || swiftCodes.CHECK_DIGITS || swiftCodes.SWIFT_CODE || REPLACE(transact.sort_code, '-', '') || transact.account_number as "IBAN"
FROM PD2023_WK02_TRANSACTIONS as transact
INNER JOIN PD2023_WK02_SWIFT_CODES as swiftCodes
    ON transact.BANK = swiftCodes.BANK;