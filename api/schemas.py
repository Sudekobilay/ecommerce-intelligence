from pydantic import BaseModel
from typing import List, Optional

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