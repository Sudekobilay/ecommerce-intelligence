import pandas as pd
import ast
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data", "processed")

# 1. Segmentlenmiş Müşteri Verisini Yükleme
customers_df = pd.read_csv(
    os.path.join(DATA_DIR, "kmeans_clustered_customers.csv"),
    index_col="Customer ID"
)

# 2. Birliktelik Kurallarını Yükleme
rules_df = pd.read_csv(os.path.join(DATA_DIR, "association_rules.csv"))

def _parse_frozenset(val):
    if isinstance(val, str):
        if val.startswith("frozenset"):
            inner = val.replace("frozenset({", "").replace("})", "").replace("'", "")
            return [x.strip() for x in inner.split(",") if x.strip()]
    return list(val)

rules_df['antecedents_list'] = rules_df['antecedents'].apply(_parse_frozenset)
rules_df['consequents_list'] = rules_df['consequents'].apply(_parse_frozenset)

class AnalyticsService:

    @staticmethod
    def get_customer(customer_id: int):
        if customer_id not in customers_df.index:
            return None
        row = customers_df.loc[customer_id]
        return {
            "customer_id": customer_id,
            "recency": float(row["recency"]),
            "frequency": float(row["frequency"]),
            "monetary": float(row["monetary"]),
            "rf_score": str(row["RF_SCORE"]),
            "segment": str(row["segment"]),
            "kmeans_cluster": int(row["kmeans_cluster"])
        }

    @staticmethod
    def get_segments_summary():
        summary = customers_df.groupby("segment").agg(
            customer_count=("monetary", "count"),
            monetary_total=("monetary", "sum"),
            monetary_mean=("monetary", "mean")
        ).reset_index()

        total_rev = customers_df["monetary"].sum()
        total_cust = len(customers_df)

        summary["revenue_share_pct"] = (summary["monetary_total"] / total_rev) * 100
        summary["customer_share_pct"] = (summary["customer_count"] / total_cust) * 100

        results = []
        for _, r in summary.iterrows():
            results.append({
                "segment": r["segment"],
                "customer_count": int(r["customer_count"]),
                "revenue_share_pct": round(float(r["revenue_share_pct"]), 2),
                "customer_share_pct": round(float(r["customer_share_pct"]), 2),
                "monetary_mean": round(float(r["monetary_mean"]), 2)
            })
        return results

    @staticmethod
    def get_recommendations(items: list, top_n: int = 3):
        matched_rules = []
        for _, row in rules_df.iterrows():
            antecedents = row['antecedents_list']
            consequents = row['consequents_list']
            if any(item in antecedents for item in items):
                for target in consequents:
                    if target not in items:
                        matched_rules.append({
                            "product": target,
                            "confidence": round(float(row["confidence"]), 4),
                            "lift": round(float(row["lift"]), 4)
                        })

        if not matched_rules:
            return []

        df_matched = pd.DataFrame(matched_rules).drop_duplicates(subset=["product"])
        df_matched = df_matched.sort_values(by=["lift", "confidence"], ascending=[False, False])
        return df_matched.head(top_n).to_dict(orient="records")