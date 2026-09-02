from pydantic import BaseModel
from typing import List, Optional
from typing import List, Dict, Any
from pydantic import BaseModel
from typing import Optional, List

# --- GÜN 12 YENİ ŞEMALAR ---
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

# Mevcut CustomerProfile modelini şu şekilde güncelle / genişlet:
class CustomerProfile(BaseModel):
    customer_id: int
    recency: float
    frequency: float
    monetary: float
    r_score: int
    f_score: int
    m_score: int
    rfm_score: str
    segment: str
    kmeans_cluster: int
    scorecard: Optional[CustomerScorecard] = None
    action_plan: Optional[PrescriptiveAction] = None


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

class CustomerProfile(BaseModel):
    customer_id: int
    recency: float
    frequency: float
    monetary: float
    rf_score: str
    segment: str
    kmeans_cluster: int

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