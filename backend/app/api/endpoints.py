from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
from app.models.condition import (
    UserProfileRequest,
    WorkoutRecommendationResponse,
    ConditionDetail,
)
from app.services.recommendation_engine import RecommendationEngine

router = APIRouter()
engine = RecommendationEngine()

@router.get("/conditions", response_model=List[Dict[str, str]])
def list_conditions():
    """지원하는 질환 목록 반환"""
    return engine.get_all_conditions()

@router.get("/conditions/{condition_id}", response_model=ConditionDetail)
def get_condition_detail(condition_id: str):
    """특정 질환의 가이드라인 상세 정보 반환"""
    detail = engine.get_condition_detail(condition_id)
    if not detail:
        raise HTTPException(status_code=404, detail="Condition not found")
    return detail

@router.post("/recommend", response_model=WorkoutRecommendationResponse)
def get_workout_recommendation(req: UserProfileRequest):
    """사용자의 질환 및 환경에 맞춘 개인화 운동 처방 생성"""
    try:
        return engine.generate_recommendation(req)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
