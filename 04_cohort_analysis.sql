-- ============================================================
-- ANALYSE DE COHORTES — Rétention par mois d'acquisition
-- Mesure le taux de clients qui reviennent acheter chaque mois
-- ============================================================

WITH first_purchase AS (
    -- Mois d'acquisition de chaque client
    SELECT
        c.customer_unique_id,
        DATE_TRUNC(DATE(MIN(o.order_purchase_timestamp)), MONTH) AS cohort_month
    FROM `raw_olist.customers`  c
    JOIN `raw_olist.orders`     o USING (customer_id)
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

all_purchases AS (
    -- Toutes les commandes avec le mois de la cohorte
    SELECT
        c.customer_unique_id,
        fp.cohort_month,
        DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH) AS order_month,

        -- Offset en mois depuis l'acquisition
        DATE_DIFF(
            DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH),
            fp.cohort_month,
            MONTH
        ) AS month_number

    FROM `raw_olist.customers`  c
    JOIN `raw_olist.orders`     o  USING (customer_id)
    JOIN first_purchase         fp USING (customer_unique_id)
    WHERE o.order_status = 'delivered'
),

cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS cohort_total
    FROM first_purchase
    GROUP BY cohort_month
),

cohort_retention AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_unique_id) AS nb_clients
    FROM all_purchases
    GROUP BY cohort_month, month_number
)

SELECT
    cr.cohort_month,
    cs.cohort_total,
    cr.month_number,
    cr.nb_clients,

    -- Taux de rétention
    ROUND(100.0 * cr.nb_clients / cs.cohort_total, 1) AS retention_rate_pct

FROM cohort_retention cr
JOIN cohort_size cs USING (cohort_month)
WHERE cr.cohort_month >= '2017-01-01'
ORDER BY cohort_month, month_number
