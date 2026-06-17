-- ============================================================
-- CALCUL LTV — Valeur Vie Client (Customer Lifetime Value)
-- Méthode : LTV historique + projection 12 mois
-- ============================================================

WITH customer_history AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)                          AS nb_orders,
        ROUND(SUM(oi.price), 2)                             AS total_revenue,
        ROUND(AVG(oi.price), 2)                             AS avg_order_value,

        -- Durée d'activité du client en mois
        DATE_DIFF(
            DATE(MAX(o.order_purchase_timestamp)),
            DATE(MIN(o.order_purchase_timestamp)),
            MONTH
        ) + 1 AS active_months

    FROM `raw_olist.customers`   c
    JOIN `raw_olist.orders`      o  USING (customer_id)
    JOIN `raw_olist.order_items` oi USING (order_id)
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

ltv_calculation AS (
    SELECT
        customer_unique_id,
        nb_orders,
        total_revenue,
        avg_order_value,
        active_months,

        -- Fréquence d'achat mensuelle
        ROUND(SAFE_DIVIDE(nb_orders, active_months), 2) AS purchase_frequency_monthly,

        -- LTV historique (réelle)
        total_revenue AS ltv_historical,

        -- LTV projetée 12 mois (fréquence × valeur moyenne × 12 mois)
        ROUND(
            SAFE_DIVIDE(nb_orders, NULLIF(active_months, 0))
            * avg_order_value * 12,
            2
        ) AS ltv_projected_12m,

        -- Segmentation LTV
        CASE
            WHEN total_revenue >= 1000 THEN 'HIGH LTV'
            WHEN total_revenue >= 300  THEN 'MID LTV'
            ELSE 'LOW LTV'
        END AS ltv_segment

    FROM customer_history
)

SELECT
    ltv_segment,
    COUNT(*)                            AS nb_clients,
    ROUND(AVG(ltv_historical), 2)      AS avg_ltv_historique,
    ROUND(AVG(ltv_projected_12m), 2)   AS avg_ltv_projete_12m,
    ROUND(SUM(ltv_historical), 2)      AS total_ca_segment,
    ROUND(AVG(purchase_frequency_monthly), 2) AS avg_freq_mensuelle

FROM ltv_calculation
GROUP BY ltv_segment
ORDER BY avg_ltv_historique DESC
