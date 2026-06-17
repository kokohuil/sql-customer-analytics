# 🧠 SQL Customer Analytics — RFM, LTV, Churn & Cohorts

Analyses SQL avancées de la base client e-commerce sur **Google BigQuery**.
Couvre les principaux enjeux de la connaissance client : segmentation, valeur vie, rétention et risque d'attrition.

---

## 🎯 Cas d'usage métier

- **Segmentation RFM** → Identifier les meilleurs clients et ceux à risque pour cibler les actions marketing
- **LTV (Lifetime Value)** → Estimer la valeur future d'un client pour prioriser la rétention
- **Détection Churn** → Anticiper les départs clients avant qu'ils ne soient perdus
- **Analyse de Cohortes** → Mesurer la rétention par mois d'acquisition pour évaluer la fidélité

---

## 📁 Fichiers SQL

| Fichier | Analyse | Concepts SQL |
|---------|---------|-------------|
| `01_rfm_scoring.sql` | Segmentation RFM complète | `NTILE`, CTEs chaînées, `CASE WHEN` |
| `02_ltv_calculation.sql` | LTV historique + projection 12 mois | `SAFE_DIVIDE`, agrégations, projection |
| `03_churn_detection.sql` | Score de risque churn composite | `DATE_DIFF`, scoring pondéré |
| `04_cohort_analysis.sql` | Rétention mensuelle par cohorte | `DATE_TRUNC`, `Window Functions` |

---

## 🔑 Concepts SQL démontrés

- **Window Functions** : `NTILE`, `RANK`, `LAG`, `SUM OVER`, `COUNT OVER`
- **CTEs chaînées** : décomposition logique en étapes lisibles et maintenables
- **Agrégations conditionnelles** : `COUNTIF`, `SUMIF`, `CASE WHEN` dans les agrégats
- **Fonctions de date** : `DATE_DIFF`, `DATE_TRUNC`, `DATE_ADD`
- **Calculs de parts** : ratio avec `SUM OVER ()` pour les parts de marché

---

## 📊 Exemple de résultat — Segmentation RFM

| Segment | Nb clients | CA moyen | Récence moy. | Fréquence moy. |
|---------|-----------|---------|-------------|----------------|
| 🏆 CHAMPION | 1 245 | 487 € | 12 jours | 4,2 commandes |
| 💛 CLIENT FIDELE | 3 892 | 298 € | 34 jours | 2,8 commandes |
| ⚠️ CLIENT À RISQUE | 2 104 | 312 € | 156 jours | 3,1 commandes |
| ❌ CLIENT PERDU | 4 567 | 89 € | 380 jours | 1,1 commandes |

---

## 🚀 Utilisation

```sql
-- Exécuter dans BigQuery Query Editor ou connecter à dbt
-- Remplacer `raw_olist` par votre dataset source

-- Exemple : obtenir tous les clients à risque de churn
-- avec leur CA à risque, trié par priorité
SELECT *
FROM churn_scoring
WHERE churn_status IN ('A RISQUE', 'ATTENTION')
ORDER BY total_revenue DESC
```

---

## 🔗 Repos liés

- [`dbt-retail-analytics-pipeline`](https://github.com/<votre-username>/dbt-retail-analytics-pipeline) — Ces analyses sont intégrées en production dans les marts dbt
- [`powerbi-retail-dashboard`](https://github.com/<votre-username>/powerbi-retail-dashboard) — Visualisation des segments dans Power BI

---

## 👤 Auteur

**William KOUKOUI** — Data Analyst / Analytics Engineer
[LinkedIn](https://linkedin.com/in/william-koukoui) · [Email](mailto:william.koukoui.ai@gmail.com)
