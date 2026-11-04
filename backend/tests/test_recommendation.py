import pytest
from app.services.recommendation_engine import RecommendationEngine
from app.models.condition import UserProfileRequest

def test_load_all_conditions():
    engine = RecommendationEngine()
    conditions = engine.get_all_conditions()
    assert len(conditions) >= 3
    ids = [c["id"] for c in conditions]
    assert "fatty_liver" in ids
    assert "prediabetes" in ids
    assert "hypertension" in ids

def test_user_case_fatty_liver_and_prediabetes():
    engine = RecommendationEngine()
    req = UserProfileRequest(
        condition_ids=["fatty_liver", "prediabetes"],
        preferred_environment="all",
        available_time_minutes=45,
        recent_meal_minutes_ago=40
    )
    res = engine.generate_recommendation(req)

    # 1. Condition names
    assert "지방간 (비알코올성)" in res.user_conditions
    assert "전당뇨 (공복혈당장애 / 내당능장애)" in res.user_conditions

    # 2. Aerobic Prescription check
    assert res.aerobic_prescription.target_duration_minutes <= 45
    # Cadence should be around 110~115
    assert 105 <= res.aerobic_prescription.recommended_cadence_spm <= 120
    # Optimal timing message for prediabetes meal peak
    assert "골든타임" in res.aerobic_prescription.optimal_timing_message

    # 3. Recommended exercises check
    ex_names = [e.name for e in res.resistance_exercises]
    assert any("레그프레스" in name for name in ex_names)
    assert any("체스트프레스" in name for name in ex_names)
    assert any("랫풀다운" in name for name in ex_names)
    assert any("스쿼트" in name for name in ex_names)

    # 4. Warnings check
    warnings = " ".join(res.contraindications_and_safety_warnings)
    assert "공복" in warnings or "탈수" in warnings

def test_home_environment_filtering():
    engine = RecommendationEngine()
    req = UserProfileRequest(
        condition_ids=["prediabetes"],
        preferred_environment="home"
    )
    res = engine.generate_recommendation(req)
    for ex in res.resistance_exercises:
        assert ex.category != "gym_machine"
