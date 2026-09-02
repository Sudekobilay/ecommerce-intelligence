from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List

from api.schemas import (
    CustomerProfile,
    SegmentSummaryItem,
    RecommendationRequest,
    RecommendationResponse
)
from api.services import AnalyticsService

app = FastAPI(
    title="E-Commerce Intelligence API",
    description="Customer Segmentation & Market Basket Recommendation Engine",
    version="1.0.0"
)

# Flutter ve Web istemcileri için CORS izni
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def health_check():
    return {"status": "active", "service": "E-Commerce Intelligence API"}

@app.get("/api/v1/customer/{customer_id}", response_model=CustomerProfile)
def get_customer_profile(customer_id: int):
    customer = AnalyticsService.get_customer(customer_id)
    if not customer:
        raise HTTPException(status_code=404, detail=f"Customer ID {customer_id} not found.")
    return customer

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