from pydantic import BaseModel
from typing import List, Optional, Dict, Any

# --- GÜN 12 ANALİTİK ŞEMALARI ---
class PrescriptiveAction(BaseModel):
    risk_level: str
    action_title: str
    action_detail: str
    recommended_channel: str

class CustomerScorecard(BaseModel):
    health_score: int
    health_status: str
    monetary_percentile: float
    frequency_percentile: float
    recency_percentile: float

class CustomerProfile(BaseModel):
    customer_id: int
    recency: float
    frequency: float
    monetary: float
    r_score: int
    f_score: int
    m_score: int
    rf_score: Optional[str] = None
    rfm_score: Optional[str] = None
    segment: str
    kmeans_cluster: int
    scorecard: Optional[CustomerScorecard] = None
    action_plan: Optional[PrescriptiveAction] = None

# --- DASHBOARD & MAKRO BİLEŞENLERİ ---
class SegmentDistributionItem(BaseModel):
    segment: str
    count: int
    percentage: float

class AutomatedInsightItem(BaseModel):
    type: str
    category: str
    title: str
    description: str

class OverviewResponse(BaseModel):
    total_customers: int
    total_revenue: float
    total_transactions: int
    average_order_value: float
    segment_distribution: List[SegmentDistributionItem]
    automated_insights: List[AutomatedInsightItem]

class SegmentSummaryItem(BaseModel):
    segment: str
    customer_count: int
    revenue_share_pct: float
    customer_share_pct: float
    monetary_mean: float

class RecommendationRequest(BaseModel):
    items: List[str]
    top_n: Optional[int] = 3

class RecommendedItem(BaseModel):
    product: str
    confidence: float
    lift: float

class RecommendationResponse(BaseModel):
    input_items: List[str]
    recommendations: List[RecommendedItem]

    # --- GÜN 13: WHAT-IF SIMULATION SCHEMAS ---
class SimulationRequest(BaseModel):
    days_to_next_order: int = 15       # Müşterinin kaç gün içinde sipariş vereceği senaryosu
    additional_orders: int = 1         # Eklenecek tahmini sipariş sayısı
    additional_spend: float = 100.0    # Sepete eklenecek tahmini harcama tutarı (£)

class SimulationMetricComparison(BaseModel):
    current: float
    simulated: float
    delta: float

class SimulationResponse(BaseModel):
    customer_id: int
    health_score: SimulationMetricComparison
    churn_probability_pct: SimulationMetricComparison
    risk_assessment: str
    impact_summary: str

    # --- GÜN 15: AUTH SCHEMAS ---
class LoginRequest(BaseModel):
    email: str
    password: str
    role: str  # 'executive' veya 'marketing'

class LoginResponse(BaseModel):
    success: bool
    message: str
    email: str
    role: str
    token: str