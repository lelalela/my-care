import json
from pathlib import Path
from typing import List, Dict, Optional
from app.models.condition import (
    ConditionDetail,
    UserProfileRequest,
    WorkoutRecommendationResponse,
    MergedAerobicPrescription,
    ExerciseItem,
)

class RecommendationEngine:
    def __init__(self, data_path: Optional[Path] = None):
        if data_path is None:
            data_path = Path(__file__).resolve().parent.parent / "data" / "guidelines" / "conditions.json"
        self.data_path = data_path
        self._conditions: Dict[str, ConditionDetail] = {}
        self._load_data()

    def _load_data(self):
        with open(self.data_path, "r", encoding="utf-8") as f:
            raw_data = json.load(f)
            for item in raw_data:
                cond = ConditionDetail(**item)
                self._conditions[cond.id] = cond

    def get_all_conditions(self) -> List[Dict[str, str]]:
        return [
            {"id": cond.id, "name_ko": cond.name_ko, "name_en": cond.name_en}
            for cond in self._conditions.values()
        ]

    def get_condition_detail(self, condition_id: str) -> Optional[ConditionDetail]:
        return self._conditions.get(condition_id)

    def generate_recommendation(self, req: UserProfileRequest) -> WorkoutRecommendationResponse:
        matched_conditions: List[ConditionDetail] = [
            self._conditions[cid] for cid in req.condition_ids if cid in self._conditions
        ]

        if not matched_conditions:
            raise ValueError(f"No valid conditions found in: {req.condition_ids}")

        # 1. Collect Primary Goals
        goals = []
        for c in matched_conditions:
            goals.extend(c.target_goals)

        # 2. Compute Aerobic Prescription (Multi-condition logic)
        durations = [c.aerobic_guide.target_duration_minutes for c in matched_conditions]
        cadence_mins = [c.aerobic_guide.walking_cadence_spm.min for c in matched_conditions]
        cadence_maxs = [c.aerobic_guide.walking_cadence_spm.max for c in matched_conditions]
        cadence_recs = [c.aerobic_guide.walking_cadence_spm.recommended for c in matched_conditions]
        speed_mins = [c.aerobic_guide.walking_speed_kmh.min for c in matched_conditions]
        speed_maxs = [c.aerobic_guide.walking_speed_kmh.max for c in matched_conditions]

        # Calculate optimal intersections / averages
        target_duration = max(durations)  # Choose the duration that satisfies the maximum need, bounded by available_time
        if req.available_time_minutes:
            target_duration = min(target_duration, req.available_time_minutes)

        rec_cadence = int(sum(cadence_recs) / len(cadence_recs))
        target_cadence_min = max(cadence_mins)
        target_cadence_max = max(cadence_maxs)

        rec_speed_min = round(sum(speed_mins) / len(speed_mins), 1)
        rec_speed_max = round(sum(speed_maxs) / len(speed_maxs), 1)

        # Timing message (prioritize prediabetes if present)
        timing_message = "하루 중 편안하게 지속할 수 있는 시간대에 유산소를 진행하세요."
        if any(c.id == "prediabetes" for c in matched_conditions):
            if req.recent_meal_minutes_ago is not None:
                if req.recent_meal_minutes_ago < 30:
                    wait_min = 30 - req.recent_meal_minutes_ago
                    timing_message = f"전당뇨 관리: 식후 30분~1시간이 혈당 피크입니다. 약 {wait_min}분 후 걷기를 시작하시는 것이 가장 효과적입니다."
                elif req.recent_meal_minutes_ago <= 90:
                    timing_message = "전당뇨 관리: 지금이 혈당 스파이크를 억제하기 가장 완벽한 걷기 골든타임입니다!"
                else:
                    timing_message = "전당뇨 관리: 식후 혈당 피크 시간은 지났으나, 다음 식사 전 인슐린 감수성을 위해 가볍게 걸어주세요."
            else:
                timing_message = "전당뇨 관리: 식사 후 30분~1시간 이내에 걷기를 시작하시면 식후 혈당 스파이크 억제 효과가 극대화됩니다."

        # Aggregate Tips
        all_tips = []
        for c in matched_conditions:
            all_tips.extend(c.aerobic_guide.tips)

        aerobic_prescription = MergedAerobicPrescription(
            target_duration_minutes=target_duration,
            recommended_cadence_spm=rec_cadence,
            cadence_range={"min": target_cadence_min, "max": target_cadence_max},
            target_speed_kmh={"min": rec_speed_min, "max": rec_speed_max},
            optimal_timing_message=timing_message,
            tips=list(dict.fromkeys(all_tips))
        )

        # 3. Filter Resistance Exercises
        raw_exercises: List[ExerciseItem] = []
        for c in matched_conditions:
            raw_exercises.extend(c.resistance_guide.recommended_exercises)

        # Deduplicate exercises by name
        seen_names = set()
        unique_exercises: List[ExerciseItem] = []
        for ex in raw_exercises:
            if ex.name not in seen_names:
                seen_names.add(ex.name)
                # Environment filtering
                if req.preferred_environment == "gym" and ex.category not in ["gym_machine", "home_bodyweight"]:
                    continue
                elif req.preferred_environment == "home" and ex.category == "gym_machine":
                    continue
                unique_exercises.append(ex)

        # 4. Warnings & Contraindications
        warnings = []
        for c in matched_conditions:
            warnings.extend(c.contraindications_and_warnings)
        unique_warnings = list(dict.fromkeys(warnings))

        return WorkoutRecommendationResponse(
            user_conditions=[c.name_ko for c in matched_conditions],
            primary_goals=list(dict.fromkeys(goals)),
            aerobic_prescription=aerobic_prescription,
            resistance_exercises=unique_exercises,
            contraindications_and_safety_warnings=unique_warnings
        )
