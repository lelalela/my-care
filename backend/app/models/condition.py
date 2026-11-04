from typing import List, Optional, Dict
from pydantic import BaseModel, Field

class CadenceGuide(BaseModel):
    min: int
    max: int
    recommended: int

class SpeedGuide(BaseModel):
    min: float
    max: float

class AerobicGuide(BaseModel):
    frequency_days_per_week: str
    target_duration_minutes: int
    recommended_time_window: str
    intensity: str
    walking_cadence_spm: CadenceGuide
    walking_speed_kmh: SpeedGuide
    tips: List[str]

class ExerciseItem(BaseModel):
    name: str
    category: str  # gym_machine, home_bodyweight, home_tool
    target: str
    reps: str
    benefit: str
    caution: str

class ResistanceGuide(BaseModel):
    frequency_days_per_week: str
    target_sets: str
    reps_per_set: str
    target_muscles: List[str]
    recommended_exercises: List[ExerciseItem]

class ConditionDetail(BaseModel):
    id: str
    name_ko: str
    name_en: str
    target_goals: List[str]
    aerobic_guide: AerobicGuide
    resistance_guide: ResistanceGuide
    contraindications_and_warnings: List[str]

# Request & Response Models for Prescription
class UserProfileRequest(BaseModel):
    condition_ids: List[str] = Field(..., description="예: ['fatty_liver', 'prediabetes']")
    preferred_environment: Optional[str] = Field("all", description="all, gym, home")
    available_time_minutes: Optional[int] = Field(45, description="오늘 가용 운동 시간(분)")
    recent_meal_minutes_ago: Optional[int] = Field(None, description="식사 후 경과 시간(분, 전당뇨 타이밍 계산용)")

class MergedAerobicPrescription(BaseModel):
    target_duration_minutes: int
    recommended_cadence_spm: int
    cadence_range: Dict[str, int]
    target_speed_kmh: Dict[str, float]
    optimal_timing_message: str
    tips: List[str]

class WorkoutRecommendationResponse(BaseModel):
    user_conditions: List[str]
    primary_goals: List[str]
    aerobic_prescription: MergedAerobicPrescription
    resistance_exercises: List[ExerciseItem]
    contraindications_and_safety_warnings: List[str]
