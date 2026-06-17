-- ============================================================
-- ANALYSE RFM — Segmentation client par Récence, Fréquence, Montant
-- Dataset : Olist (e-commerce brésilien, 100k commandes)
-- Auteur  : William KOUKOUI
-- ============================================================

-- ÉTAPE 1 : Calcul des métriques brutes par client
WITH customer_metrics AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,

        -- Récence : nb de jours depuis le dernier achat
        DATE_DIFF(
            CURRENT_DATE(),
            DATE(MAX(o.order_purchase_timestamp)),
            DAY
        ) AS recency_days,

        -- Fréquence : nb de commandes distinctes
        COUNT(DISTINCT o.order_id) AS frequency,

        -- Montant : CA total généré par le client
        ROUND(SUM(oi.price + oi.freight_value), 2) AS monetary_value,

        -- Panier moyen
        ROUND(AVG(oi.price + oi.freight_value), 2) AS avg_basket

    FROM `raw_olist.customers`      c
    JOIN `raw_olist.orders`         o  USING (customer_id)
    JOIN `raw_olist.order_items`    oi USING (order_id)
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, c.customer_state
),

-- ÉTAPE 2 : Attribution des scores RFM (1 à 4)
rfm_scores AS (
    SELECT
        *,
        -- R : 4 = très récent, 1 = inactif depuis longtemps
        NTILE(4) OVER (ORDER BY recency_days ASC)   AS r_score,
        -- F : 4 = très fréquent
        NTILE(4) OVER (ORDER BY frequency DESC)     AS f_score,
        -- M : 4 = gros panier
        NTILE(4) OVER (ORDER BY monetary_value DESC) AS m_score
    FROM customer_metrics
),

-- ÉTAPE 3 : Segmentation métier
rfm_segments AS (
    SELECT
        *,
        CONCAT(
            CAST(r_score AS STRING),
            CAST(f_score AS STRING),
            CAST(m_score AS STRING)
        ) AS rfm_code,

        CASE
            WHEN r_score = 4 AND f_score = 4 AND m_score = 4 THEN '🏆 CHAMPION'
            WHEN r_score >= 3 AND f_score >= 3               THEN '💛 CLIENT FIDELE'
            WHEN r_score = 4 AND f_score <= 2               THEN '🆕 NOUVEAU CLIENT'
            WHEN r_score >= 3 AND f_score = 1               THEN '🌱 CLIENT POTENTIEL'
            WHEN r_score <= 2 AND f_score >= 3               THEN '⚠️  CLIENT A RISQUE'
            WHEN r_score = 1 AND f_score <= 2               THEN '❌ CLIENT PERDU'
            ELSE '📊 CLIENT MOYEN'
        END AS rfm_segment

    FROM rfm_scores
)

-- RÉSULTAT FINAL : Distribution des segments
SELECT
    rfm_segment,
    COUNT(*)                        AS nb_clients,
    ROUND(AVG(monetary_value), 2)  AS avg_ca,
    ROUND(SUM(monetary_value), 2)  AS total_ca,
    ROUND(AVG(frequency), 1)       AS avg_orders,
    ROUND(AVG(recency_days), 0)    AS avg_recency_days,

    -- Part du segment dans le CA total
    ROUND(
        100.0 * SUM(monetary_value) / SUM(SUM(monetary_value)) OVER (),
        1
    ) AS ca_share_pct

FROM rfm_segments
GROUP BY rfm_segment
ORDER BY avg_ca DESC
