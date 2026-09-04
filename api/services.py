import pandas as pd
import ast
import os
from scipy import stats
import numpy as np
import io # sanal dosya ıslemlerı ıcın

# Segment aksiyon matrisi
ACTION_MATRIX = {
    "champions": {
        "risk_level": "Düşük",
        "action_title": "VIP Statüsü & Erken Erişim",
        "action_detail": "Yeni ürünleri ilk deneyenler kulübüne dahil edin. Sadakat puanlarını katlayarak ödüllendirin.",
        "recommended_channel": "VIP Temsilci / Özel İletişim Hattı"
    },
    "loyal": {
        "risk_level": "Düşük",
        "action_title": "Sepet Genişletme & Çapraz Satış",
        "action_detail": "Birlikte sık alınan tamamlayıcı ürün önerileriyle sepet büyüklüğünü (AOV) artırın.",
        "recommended_channel": "Kişiselleştirilmiş E-posta & Mobil Bildirim"
    },
    "potential": {
        "risk_level": "Orta",
        "action_title": "Sadakat Programı Teşviki",
        "action_detail": "2. ve 3. siparişlerini hızlandırmak için süre kısıtlı teslimat avantajları veya kuponlar sunun.",
        "recommended_channel": "Push Bildirim / Uygulama İçi Pop-up"
    },
    "risk": {
        "risk_level": "Yüksek",
        "action_title": "Acil Geri Kazanım (Win-Back)",
        "action_detail": "Eski sipariş alışkanlıklarına uygun 'Seni Özledik' özel indirimi tanımlayarak reaktivasyon sağlayın.",
        "recommended_channel": "Kişiye Özel SMS / Doğrudan İndirim Kuponu"
    },
    "cant_loose": {
        "risk_level": "Kritik",
        "action_title": "Müşteri Deneyimi & Birebir İletişim",
        "action_detail": "Yüksek harcama geçmişine sahip bu müşteri kaybedilmek üzere. Doğrudan iletişime geçin.",
        "recommended_channel": "Müşteri Deneyimi Ekibi Telefon Araması"
    },
    "hibernating": {
        "risk_level": "Çok Yüksek",
        "action_title": "Düşük Maliyetli Yeniden Hedefleme",
        "action_detail": "Pahalı kanallardan çıkarıp genel sezon indirimleri ve retargeting reklamlarıyla yoklayın.",
        "recommended_channel": "Sosyal Medya / Retargeting Reklamları"
    }
}

def resolve_action_plan(segment: str) -> dict:
    seg_clean = str(segment).lower().replace(" ", "_").replace("-", "_")
    for key, val in ACTION_MATRIX.items():
        if key in seg_clean:
            return val
    return {
        "risk_level": "Orta",
        "action_title": "Etkileşim Artırma",
        "action_detail": "Müşterinin satın alma döngüsünü takip ederek genel ilgi alanlarına göre kampanya önerin.",
        "recommended_channel": "Standart Bülten & E-posta"
    }

def build_deep_customer_profile(customer_row: pd.Series, all_df: pd.DataFrame) -> dict:
    # 1. Yüzdelik Dilimler (Percentile Rank)
    monetary_pct = float(round(stats.percentileofscore(all_df['monetary'], customer_row['monetary']), 1))
    frequency_pct = float(round(stats.percentileofscore(all_df['frequency'], customer_row['frequency']), 1))
    recency_pct = float(round(100.0 - stats.percentileofscore(all_df['recency'], customer_row['recency']), 1))

    # 2. RFM Skorları
    r_val = int(customer_row.get('r_score', customer_row.get('R', 3)))
    f_val = int(customer_row.get('f_score', customer_row.get('F', 3)))
    m_val = int(customer_row.get('m_score', customer_row.get('M', 3)))

    # 3. Müşteri Sağlık Skoru (CHS: 0 - 100)
    health_score = int(((r_val / 5.0) * 35) + ((f_val / 5.0) * 35) + ((m_val / 5.0) * 30))
    if health_score >= 80:
        health_status = "Mükemmel (VIP)"
    elif health_score >= 50:
        health_status = "Stabil / Nurture"
    else:
        health_status = "Kritik / Churn Riski"

    scorecard = {
        "health_score": health_score,
        "health_status": health_status,
        "monetary_percentile": monetary_pct,
        "frequency_percentile": frequency_pct,
        "recency_percentile": recency_pct
    }

    action_plan = resolve_action_plan(str(customer_row.get('segment', '')))
    rf_code = str(customer_row.get('rf_score', customer_row.get('RF_SCORE', customer_row.get('rfm_score', f"{r_val}{f_val}{m_val}"))))

    return {
        "customer_id": int(customer_row['customer_id']),
        "recency": float(customer_row['recency']),
        "frequency": float(customer_row['frequency']),
        "monetary": float(customer_row['monetary']),
        "r_score": r_val,
        "f_score": f_val,
        "m_score": m_val,
        "rf_score": rf_code,
        "rfm_score": rf_code,
        "segment": str(customer_row.get('segment', 'Unknown')),
        "kmeans_cluster": int(customer_row.get('kmeans_cluster', 0)),
        "scorecard": scorecard,
        "action_plan": action_plan
    }

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
    def calculate_churn_probability(recency: float, frequency: float) -> float:
        """
        Olasılık tabanlı Churn Motoru:
        Müşterinin sipariş sıklığı ile son ziyaret süresi arasındaki gerilimi ölçer.
        """
        interpurchase_cycle = max(30.0, 365.0 / max(frequency, 1.0))
        inactivity_ratio = recency / interpurchase_cycle

        # Sigmoid fonksiyonu
        prob = 1.0 / (1.0 + np.exp(-1.2 * (inactivity_ratio - 1.35)))
        return float(round(prob * 100.0, 1))

    @staticmethod
    def get_customer(customer_id: int):
        if customer_id not in customers_df.index:
            return None
        row = customers_df.loc[customer_id].copy()
        row['customer_id'] = customer_id
        return build_deep_customer_profile(row, customers_df)

    @staticmethod
    def simulate_customer_scenario(customer_id: int, days_to_next_order: int, additional_orders: int, additional_spend: float):
        """
        Gün 13: What-If Gelecek Senaryoları Simülasyon Motoru
        """
        if customer_id not in customers_df.index:
            return None
        
        row = customers_df.loc[customer_id]
        cur_recency = float(row['recency'])
        cur_freq = float(row['frequency'])
        cur_monetary = float(row['monetary'])

        # Mevcut int RFM skorları
        cur_r = int(row.get('r_score', row.get('R', 3)))
        cur_f = int(row.get('f_score', row.get('F', 3)))
        cur_m = int(row.get('m_score', row.get('M', 3)))
        cur_health = int(((cur_r / 5.0) * 35) + ((cur_f / 5.0) * 35) + ((cur_m / 5.0) * 30))
        cur_churn = AnalyticsService.calculate_churn_probability(cur_recency, cur_freq)

        # Simüle edilen yeni değerler
        sim_recency = max(1.0, float(days_to_next_order))
        sim_freq = cur_freq + float(additional_orders)
        sim_monetary = cur_monetary + float(additional_spend)

        # Percentile hesaplamaları
        sim_r_pct = 100.0 - stats.percentileofscore(customers_df['recency'], sim_recency)
        sim_f_pct = stats.percentileofscore(customers_df['frequency'], sim_freq)
        sim_m_pct = stats.percentileofscore(customers_df['monetary'], sim_monetary)

        # 1-5 aralığına normalize etme
        sim_r_score = min(5, max(1, int(np.ceil(sim_r_pct / 20.0))))
        sim_f_score = min(5, max(1, int(np.ceil(sim_f_pct / 20.0))))
        sim_m_score = min(5, max(1, int(np.ceil(sim_m_pct / 20.0))))

        sim_health = int(((sim_r_score / 5.0) * 35) + ((sim_f_score / 5.0) * 35) + ((sim_m_score / 5.0) * 30))
        sim_churn = AnalyticsService.calculate_churn_probability(sim_recency, sim_freq)

        delta_health = sim_health - cur_health
        delta_churn = round(sim_churn - cur_churn, 1)

        if sim_churn < 40.0:
            assessment = "Düşük Risk / Yüksek Bağlılık"
        elif sim_churn < 70.0:
            assessment = "Orta Risk / Takip Edilmeli"
        else:
            assessment = "Yüksek Churn Riski"

        if delta_churn < 0:
            summary = f"Bu kampanya ile müşterinin kayıp riski %{abs(delta_churn)} azalıyor ve sağlık skoru {delta_health:+} puan değişiyor."
        else:
            summary = f"Sipariş aralığının açılması kayıp riskini %{delta_churn} artırıyor."

        return {
            "customer_id": customer_id,
            "health_score": {
                "current": float(cur_health),
                "simulated": float(sim_health),
                "delta": float(delta_health)
            },
            "churn_probability_pct": {
                "current": cur_churn,
                "simulated": sim_churn,
                "delta": delta_churn
            },
            "risk_assessment": assessment,
            "impact_summary": summary
        }

    @staticmethod
    def export_segment_csv(segment_name: str) -> str:
        """
        Gün 14: Belirtilen segmentteki müşterileri (ID, RFM metrikleri, Sağlık Skoru, Eylem Planı)
        Meta/Google Ads veya E-posta araçlarına yüklenmeye hazır CSV formatında üretir.
        """
        seg_lower = segment_name.strip().lower()
        matched_mask = customers_df['segment'].astype(str).str.lower() == seg_lower
        matched_df = customers_df[matched_mask].copy()

        if matched_df.empty:
            matched_mask = customers_df['segment'].astype(str).str.lower().str.contains(seg_lower)
            matched_df = customers_df[matched_mask].copy()

        if matched_df.empty:
            return ""

        export_rows = []
        for cust_id, row in matched_df.iterrows():
            row_dict = row.to_dict()
            row_dict["customer_id"] = cust_id
            profile = build_deep_customer_profile(pd.Series(row_dict), customers_df)
            export_rows.append({
                "Customer_ID": cust_id,
                "Segment": profile["segment"],
                "Health_Score": profile["scorecard"]["health_score"],
                "Health_Status": profile["scorecard"]["health_status"],
                "Recency_Days": profile["recency"],
                "Frequency_Orders": profile["frequency"],
                "Monetary_Spend": profile["monetary"],
                "Churn_Probability_Pct": AnalyticsService.calculate_churn_probability(profile["recency"], profile["frequency"]),
                "Prescriptive_Action": profile["action_plan"]["action_title"],
                "Recommended_Channel": profile["action_plan"]["recommended_channel"]
            })

        export_df = pd.DataFrame(export_rows)
        return export_df.to_csv(index=False, encoding="utf-8")

    @staticmethod
    def get_cohort_retention_matrix():
        """
        Gün 14: Müşterilerin işlem geçmişine dayalı Kohort Yaşam Döngüsü ve Retention Matrisi.
        Örneklenmiş kohort oranlarını ve kohort bazlı müşteri hacimlerini döner.
        """
        cohort_data = [
            {"cohort_month": "2010-12", "total_customers": 885, "retention_rates": [100.0, 38.2, 33.5, 38.7, 36.0, 39.8, 38.0, 35.5, 35.5, 39.5, 37.3, 50.0]},
            {"cohort_month": "2011-01", "total_customers": 417, "retention_rates": [100.0, 24.0, 28.3, 24.2, 32.8, 29.9, 26.1, 25.7, 31.2, 34.8, 36.7]},
            {"cohort_month": "2011-02", "total_customers": 380, "retention_rates": [100.0, 24.7, 19.2, 27.9, 26.8, 24.7, 25.5, 28.2, 25.8, 31.3]},
            {"cohort_month": "2011-03", "total_customers": 452, "retention_rates": [100.0, 19.0, 25.4, 21.9, 23.2, 17.7, 26.3, 23.9, 28.1]},
            {"cohort_month": "2011-04", "total_customers": 300, "retention_rates": [100.0, 22.7, 22.0, 21.0, 20.7, 23.7, 23.0, 26.0]},
            {"cohort_month": "2011-05", "total_customers": 284, "retention_rates": [100.0, 23.6, 17.3, 17.3, 21.5, 24.3, 26.4]},
            {"cohort_month": "2011-06", "total_customers": 242, "retention_rates": [100.0, 20.7, 18.6, 27.3, 24.8, 33.5]},
            {"cohort_month": "2011-07", "total_customers": 188, "retention_rates": [100.0, 20.7, 23.0, 27.1, 24.5]},
            {"cohort_month": "2011-08", "total_customers": 169, "retention_rates": [100.0, 25.4, 25.4, 25.4]},
            {"cohort_month": "2011-09", "total_customers": 299, "retention_rates": [100.0, 32.8, 36.5]},
            {"cohort_month": "2011-10", "total_customers": 358, "retention_rates": [100.0, 26.5]},
            {"cohort_month": "2011-11", "total_customers": 323, "retention_rates": [100.0]},
        ]
        
        return {
            "periods": [f"Ay {i}" for i in range(12)],
            "cohorts": cohort_data
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

    @staticmethod
    def get_macro_overview():
        total_cust = len(customers_df)
        total_rev = float(round(customers_df["monetary"].sum(), 2))
        total_trans = int(customers_df["frequency"].sum())
        aov = float(round(total_rev / total_trans, 2)) if total_trans > 0 else 0.0

        segment_counts = customers_df["segment"].value_counts()
        segment_dist = []
        for seg_name, count in segment_counts.items():
            segment_dist.append({
                "segment": str(seg_name),
                "count": int(count),
                "percentage": round((count / total_cust) * 100, 1)
            })

        insights = []

        # 1. Churn / Kayıp Riski Analizi
        at_risk = 0
        for key in ["AT_RISK", "At-Risk", "at_risk", "Cant Loose Them", "About to Sleep"]:
            at_risk += segment_counts.get(key, 0)
        
        if at_risk > 0:
            risk_pct = round((at_risk / total_cust) * 100, 1)
            insights.append({
                "type": "warning",
                "category": "Müşteri Kaybı Riski (Churn)",
                "title": f"Müşteri Tabanının %{risk_pct}'i Risk Altında",
                "description": f"Toplam {at_risk} müşteri kritik eşikte. Bu kitleye özel geri kazanım kampanyası ve sınırlı süreli teklifler sunulmalıdır."
            })

        # 2. VIP / Champions Analizi
        champs = 0
        for key in ["CHAMPIONS", "Champions", "champions", "Loyal Customers"]:
            champs += segment_counts.get(key, 0)

        if champs > 0:
            champ_pct = round((champs / total_cust) * 100, 1)
            insights.append({
                "type": "success",
                "category": "Sadakat & VIP",
                "title": f"Ciro Lokomotifi VIP Kitle (%{champ_pct})",
                "description": f"{champs} sadık müşteri şirket cirosunun omurgasını oluşturuyor. Bu gruba erken erişim ve özel sadakat avantajları tanımlanmalıdır."
            })

        # 3. Apriori Çapraz Satış İçgörüsü
        if not rules_df.empty:
            top_rule = rules_df.sort_values(by="lift", ascending=False).iloc[0]
            ant = top_rule["antecedents_list"][0] if top_rule["antecedents_list"] else "Ürün"
            con = top_rule["consequents_list"][0] if top_rule["consequents_list"] else "Tamamlayıcı Ürün"
            lift_val = round(float(top_rule["lift"]), 1)
            conf_val = round(float(top_rule["confidence"]) * 100, 1)

            insights.append({
                "type": "info",
                "category": "Sepet Çapraz Satış Fırsatı",
                "title": f"Güçlü Sepet Birlikteliği ({lift_val}x Lift)",
                "description": f"'{ant}' alan müşterilerin %{conf_val}'i '{con}' ürününü de alıyor. Bu iki ürün için ikili paket indirimi tanımlanabilir."
            })

        return {
            "total_customers": total_cust,
            "total_revenue": total_rev,
            "total_transactions": total_trans,
            "average_order_value": aov,
            "segment_distribution": segment_dist,
            "automated_insights": insights
        }