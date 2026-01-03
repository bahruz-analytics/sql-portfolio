/*
CASE STUDY / NÜMUNƏ ANALİZ:
Percentile-Based Amount Segmentation (Fully Masked)
Faizlər (percentile) əsasında məbləğlərin seqmentasiyası (Maskalanmış)

Description / Təsvir:
This case study demonstrates how transaction amounts can be segmented
using percentile-based logic for analytical and business insights.

Bu nümunə analizdə əməliyyat məbləğlərinin faizlər (percentile) əsasında
kateqoriyalara bölünməsi göstərilir.

Confidentiality / Məxfilik:
All table and column names are anonymized.
Business logic and query structure are preserved.

Bütün cədvəl və sütun adları maskalanmışdır.
Biznes məntiqi və sorğunun strukturu qorunub saxlanılmışdır.
*/

------------------------------------------------------------
-- STEP 1 / ADDIM 1
-- Calculate percentiles for transaction amounts
-- Əməliyyat məbləğləri üzrə faizlərin (percentile) hesablanması
------------------------------------------------------------
WITH percentile_ AS (
    SELECT
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY amount_value) AS p10,
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY amount_value) AS p20,
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY amount_value) AS p30,
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY amount_value) AS p40,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY amount_value) AS p50,
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY amount_value) AS p60,
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY amount_value) AS p70,
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY amount_value) AS p80,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY amount_value) AS p90
    FROM (
        SELECT /*+ FULL(t) PARALLEL(t, 16) */
            DISTINCT
            d.entity_id,
            d.entity_name,
            t.amount_value
        FROM fact_transactions t
        JOIN dim_entities d
            ON d.entity_id = t.related_entity_id
        WHERE t.event_date >= TRUNC(ADD_MONTHS(SYSDATE, -1), 'MM')
          AND t.event_date <  TRUNC(SYSDATE, 'MM')
          AND t.event_type = 'MASKED_EVENT'
          AND d.segment_code IN ('SEG_A', 'SEG_B', 'SEG_C')
          AND amount_value >= 400
    )
)

------------------------------------------------------------
-- STEP 2 / ADDIM 2
-- Assign percentile-based amount categories
-- Məbləğlərin faiz intervallarına görə kateqoriyalara bölünməsi
------------------------------------------------------------
SELECT
    amount_category,
    COUNT(DISTINCT entity_id) AS entity_count,
    MIN(amount_value)         AS min_amount,
    MAX(amount_value)         AS max_amount
FROM (
    SELECT
        d.entity_id,
        t.amount_value,
        CASE
            WHEN amount_value < 400   THEN 'Below Threshold'       -- Minimum həddən aşağı
            WHEN amount_value < p.p10 THEN '0–10 Percentile'       -- 0–10 faiz aralığı
            WHEN amount_value < p.p20 THEN '10–20 Percentile'      -- 10–20 faiz aralığı
            WHEN amount_value < p.p30 THEN '20–30 Percentile'
            WHEN amount_value < p.p40 THEN '30–40 Percentile'
            WHEN amount_value < p.p50 THEN '40–50 Percentile'
            WHEN amount_value < p.p60 THEN '50–60 Percentile'
            WHEN amount_value < p.p70 THEN '60–70 Percentile'
            WHEN amount_value < p.p80 THEN '70–80 Percentile'
            WHEN amount_value < p.p90 THEN '80–90 Percentile'
            ELSE '90–100 Percentile'                               -- Ən yüksək məbləğlər
        END AS amount_category
    FROM fact_transactions t
    JOIN dim_entities d
        ON d.entity_id = t.related_entity_id
    CROSS JOIN percentile_ p
)

------------------------------------------------------------
-- STEP 3 / ADDIM 3
-- Aggregate results by amount category
-- Nəticələrin məbləğ kateqoriyası üzrə yekunlaşdırılması
------------------------------------------------------------
GROUP BY amount_category
ORDER BY min_amount;
