-- ============================================================
-- DÉTECTION CHURN — Clients à risque d'attrition
-- Règle métier : client inactif depuis > 90 jours = à risque
-- ============================================================

WITH last_purchase AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        MAX(o.order_purchase_timestamp)             AS last_order_date,
        COUNT(DISTINCT o.order_id)                  AS total_orders,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
        AVG(r.review_score)                         AS avg_satisfaction

    FROM `raw_olist.customers`      c
    JOIN `raw_olist.orders`         o  USING (customer_id)
    JOIN `raw_olist.order_items`    oi USING (order_id)
    LEFT JOIN `raw_olist.order_reviews` r USING (order_id)
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, c.customer_state
),

churn_scoring AS (
    SELECT
        *,
        DATE_DIFF(CURRENT_DATE(), DATE(last_order_date), DAY) AS days_since_last_order,

        -- Score de risque churn (0 à 100)
        LEAST(100,
            -- Inactivité (poids fort)
            DATE_DIFF(CURRENT_DATE(), DATE(last_order_date), DAY) * 0.5
            -- Faible satisfaction (poids moyen)
            + CASE WHEN avg_satisfaction < 3 THEN 20 ELSE 0 END
            -- Faible fréquence (poids faible)
            + CASE WHEN total_orders = 1 THEN 10 ELSE 0 END
        ) AS churn_score,

        CASE
            WHEN DATE_DIFF(CURRENT_DATE(), DATE(last_order_date), DAY) > 180 THEN 'PERDU'
            WHEN DATE_DIFF(CURRENT_DATE(), DATE(last_order_date), DAY) > 90  THEN 'A RISQUE'
            WHEN DATE_DIFF(CURRENT_DATE(), DATE(last_order_date), DAY) > 30  THEN 'ATTENTION'
            ELSE 'ACTIF'
        END AS churn_status

    FROM last_purchase
)

SELECT
    churn_status,
    COUNT(*)                        AS nb_clients,
    ROUND(AVG(total_revenue), 2)   AS avg_revenue,
    ROUND(SUM(total_revenue), 2)   AS total_revenue_at_risk,
    ROUND(AVG(churn_score), 0)     AS avg_churn_score,
    ROUND(AVG(avg_satisfaction), 2) AS avg_satisfaction

FROM churn_scoring
GROUP BY churn_status
ORDER BY avg_churn_score DESC
