/// 처방된 유산소 가이드 모델
class AerobicPrescription {
  const AerobicPrescription({
    required this.durationMinutes,
    required this.cadenceSpm,
    required this.cadenceMin,
    required this.cadenceMax,
    required this.speedMin,
    required this.speedMax,
    required this.timingMessage,
    required this.tips,
  });

  final int durationMinutes;
  final int cadenceSpm;
  final int cadenceMin;
  final int cadenceMax;
  final double speedMin;
  final double speedMax;
  final String timingMessage;
  final List<String> tips;
}

/// 처방된 근력/홈트레이닝 운동 항목
class PrescribedExercise {
  const PrescribedExercise({
    required this.name,
    required this.category,
    required this.target,
    required this.reps,
    required this.benefit,
    required this.caution,
    this.source,
    this.jointCautions = const [],
  });

  final String name;
  final String category; // 'gym_machine', 'home_bodyweight', 'home_tool'
  final String target;
  final String reps;
  final String benefit;
  final String caution;
  final String? source; // 국민체력100 출처 등
  final List<String> jointCautions; // 'knee', 'back', 'shoulder' 등
}

/// 종합 운동 처방 결과 모델
class WorkoutPrescription {
  const WorkoutPrescription({
    required this.conditionNames,
    required this.primaryGoals,
    required this.aerobic,
    required this.exercises,
    required this.safetyWarnings,
  });

  final List<String> conditionNames;
  final List<String> primaryGoals;
  final AerobicPrescription aerobic;
  final List<PrescribedExercise> exercises;
  final List<String> safetyWarnings;
}
