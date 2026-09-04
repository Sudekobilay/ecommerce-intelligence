from fastapi import FastAPI, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from typing import List
from fastapi.responses import PlainTextResponse
from api.schemas import (
    CustomerProfile,
    SegmentSummaryItem,
    RecommendationRequest,
    RecommendationResponse,
    OverviewResponse,
    SimulationRequest,
    SimulationResponse
)
from api.services import AnalyticsService

# Global bellek içi önbellek
OVERVIEW_CACHE = None

app = FastAPI(
    title="E-Commerce Intelligence API",
    description="Customer Segmentation, Intelligence Scorecards, Churn Prediction & What-If Simulation Engine",
    version="1.3.0"
)

# Flutter ve Web istemcileri için CORS izni
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def startup_event():
    global OVERVIEW_CACHE
    try:
        OVERVIEW_CACHE = AnalyticsService.get_macro_overview()
        print("INFO: Makro BI agregasyonları başarıyla önbelleğe alındı.")
    except Exception as e:
        print(f"WARN: BI önbelleği oluşturulamadı: {e}")

@app.get("/")
def health_check():
    return {"status": "active", "service": "E-Commerce Intelligence API", "version": "1.3.0"}

@app.get("/api/v1/analytics/overview", response_model=OverviewResponse)
def get_macro_overview():
    """
    Şirketin genel sağlık durumunu, makro KPI'ları, segment yüzdelerini
    ve kural tabanlı otomatik iş içgörülerini döner.
    """
    global OVERVIEW_CACHE
    if OVERVIEW_CACHE is None:
        try:
            OVERVIEW_CACHE = AnalyticsService.get_macro_overview()
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))
    return OVERVIEW_CACHE

@app.get("/api/v1/customer/{customer_id}", response_model=CustomerProfile)
def get_customer_profile(customer_id: int):
    """
    Müşteri RFM skorları, Percentile dilimleri,
    Müşteri Sağlık Skoru (CHS) ve Reçeteli Aksiyon Planını döner.
    """
    customer = AnalyticsService.get_customer(customer_id)
    if not customer:
        raise HTTPException(
            status_code=404, 
            detail=f"Customer ID {customer_id} bulunamadı."
        )
    return customer

@app.post("/api/v1/customer/{customer_id}/simulate", response_model=SimulationResponse)
def simulate_customer(customer_id: int, payload: SimulationRequest):
    """
    Gün 13: What-If Gelecek Senaryoları Simülasyon Motoru.
    Müşteriye yapılacak temasların Churn Olasılığı ve Sağlık Skoru üzerindeki net etkisini hesaplar.
    """
    sim_result = AnalyticsService.simulate_customer_scenario(
        customer_id=customer_id,
        days_to_next_order=payload.days_to_next_order,
        additional_orders=payload.additional_orders,
        additional_spend=payload.additional_spend
    )
    if not sim_result:
        raise HTTPException(
            status_code=404, 
            detail=f"Customer ID {customer_id} bulunamadı."
        )
    return sim_result

@app.get("/api/v1/segments/summary", response_model=List[SegmentSummaryItem])
def get_segments_summary():
    return AnalyticsService.get_segments_summary()

@app.post("/api/v1/recommendations", response_model=RecommendationResponse)
def get_basket_recommendations(payload: RecommendationRequest):
    recs = AnalyticsService.get_recommendations(payload.items, payload.top_n)
    return {
        "input_items": payload.items,
        "recommendations": recs
    }

@app.get("/api/v1/segments/{segment_name}/export")
def export_segment_audience(segment_name: str):
    """
    Gün 14: Hedef Kitle Dışa Aktarma (Audience Export).
    Belirli bir segmentteki müşterileri pazarlama araçlarına (Meta Ads, Klaviyo)
    uygun CSV dosyası olarak stream eder.
    """
    csv_data = AnalyticsService.export_segment_csv(segment_name)
    if not csv_data:
        raise HTTPException(
            status_code=404, 
            detail=f"'{segment_name}' segmentine ait müşteri bulunamadı."
        )

    filename = f"audience_{segment_name.lower().replace(' ', '_')}.csv"
    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@app.get("/api/v1/analytics/cohort")
def get_cohort_analysis():
    """
    Gün 14: Müşteri Edinimi ve Tutma (Retention Cohort Matrix) Analizi.
    Müşterilerin ilk alışveriş aylarından itibaren platforma bağlılık oranlarını döner.
    """
    return AnalyticsService.get_cohort_retention_matrix()