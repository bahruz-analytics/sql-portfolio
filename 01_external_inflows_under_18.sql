/*
CASE STUDY / NÜMUNƏ ANALİZ:
External Inflows to Student Cards Under Age 18
18 yaşdan aşağı tələbə kartlarına kənar mədaxillər (Maskalanmış)

Business Objective / Biznes məqsədi:
Identify and classify external incoming transactions to student card accounts
owned by customers under the age of 18.

18 yaşdan aşağı müştərilərə məxsus tələbə kartlarına üçüncü tərəflərdən
daxil olan mədaxillərin aşkar edilməsi və təsnifatı.

Confidentiality / Məxfilik:
All table names, column names, identifiers, and business codes are anonymized.
Original query logic and structure are preserved for portfolio purposes.

Bütün cədvəl və sütun adları, identifikatorlar və biznes kodları maskalanmışdır.
Skriptin məntiqi və strukturu qorunub saxlanılmışdır.
*/

------------------------------------------------------------
-- STEP 1 / ADDIM 1
-- Select customers under age 18 with student cards
-- 18 yaşdan aşağı tələbə kartı olan müştərilərin seçilməsi
------------------------------------------------------------
WITH student_cards_under_18 AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.account_number,
        c.birth_date
    FROM dim_customer c
    JOIN dim_card d
        ON d.customer_id = c.customer_id
       AND d.card_type = 'STUDENT_CARD'
    WHERE c.birth_date > ADD_MONTHS(SYSDATE, -18 * 12)
)

------------------------------------------------------------
-- STEP 2 / ADDIM 2
-- Identify and classify external incoming transactions
-- Kənar mədaxil əməliyyatlarının müəyyən edilməsi və təsnifatı
------------------------------------------------------------
SELECT
    s.customer_id,
    s.customer_name,
    s.account_number,
    t.transaction_date,
    t.transaction_id,
    t.counterparty_account,
    t.amount_value,
    t.transaction_description,

    CASE
        WHEN t.transaction_direction = 'IN'
             AND t.counterparty_account <> s.account_number
             AND t.transaction_channel = 'CASH'
        THEN 'CASH_IN'                -- Nağd mədaxil

        WHEN t.transaction_direction = 'IN'
             AND t.counterparty_account <> s.account_number
        THEN 'EXTERNAL_INFLOW'        -- Kənar mədaxil

        ELSE 'OTHER'
    END AS inflow_type

FROM fact_transactions t
JOIN student_cards_under_18 s
    ON s.account_number = t.related_account

------------------------------------------------------------
-- STEP 3 / ADDIM 3
-- Apply control filters
-- Nəzarət və filtr şərtlərinin tətbiqi
------------------------------------------------------------
WHERE t.transaction_date >= DATE '2025-01-01'
  AND t.transaction_status = 'COMPLETED';
