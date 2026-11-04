import '../../domain/model/condition_type.dart';
import '../../domain/model/prescription.dart';

/// 맞춤 운동 처방 생성 리포지토리
/// 백엔드 FastAPI 엔진과 동일한 임상 가이드라인 병합 알고리즘을 로컬에서도 실행할 수 있도록 지원합니다.
class PrescriptionRepository {
  const PrescriptionRepository();

  WorkoutPrescription generatePrescription({
    required Set<ConditionType> conditions,
    required ExerciseEnvironment environment,
  }) {
    final conditionList = conditions.toList();
    final names = conditionList.map((c) => c.name).toList();

    // 1. 유산소 지속 시간 및 케이던스 병합
    int targetDuration = 35;
    int targetCadence = 110;
    int cadenceMin = 100;
    int cadenceMax = 120;
    String timingMessage = '가장 편안한 시간대에 지속 가능한 속도로 걷기';
    final tips = <String>[];

    if (conditions.contains(ConditionType.prediabetes)) {
      timingMessage = '식후 30~60분 이내 (혈당 스파이크 억제 골든타임)';
      targetCadence = 115;
      cadenceMin = 105;
      cadenceMax = 125;
      targetDuration = 40;
      tips.add('식후 30분 시점에 걷기 시작 시 식후 혈당 급상승을 최대 30% 억제합니다.');
    }

    if (conditions.contains(ConditionType.fattyLiver)) {
      if (targetDuration < 40) targetDuration = 40;
      tips.add('40분 이상 지속적인 유산소 운동이 간세포 내 중성지방 연소를 극대화합니다.');
    }

    if (conditions.contains(ConditionType.dyslipidemia)) {
      if (targetDuration < 45) targetDuration = 45;
      tips.add('주 4~5회, 45분 이상 유산소를 지속할 때 혈중 HDL이 증가합니다.');
    }

    if (conditions.contains(ConditionType.obesity)) {
      tips.add('발목 및 무릎 관절 보호를 위해 쿠션화 착용과 평지 걷기를 권장합니다.');
    }

    if (conditions.contains(ConditionType.gout)) {
      if (targetCadence > 110) targetCadence = 110;
      tips.add('탈수를 막기 위해 운동 전후 및 도중에 물을 충분히 섭취해 주세요.');
    }

    final aerobic = AerobicPrescription(
      durationMinutes: targetDuration,
      cadenceSpm: targetCadence,
      cadenceMin: cadenceMin,
      cadenceMax: cadenceMax,
      speedMin: 4.8,
      speedMax: 5.6,
      timingMessage: timingMessage,
      tips: tips,
    );

    // 2. 근력 및 보조 운동 풀 구성 (환경별 필터링)
    final allExercises = <PrescribedExercise>[
      // 머신 운동 (헬스장)
      const PrescribedExercise(
        name: '시티드 레그프레스',
        category: 'gym_machine',
        target: '하체 (대퇴사두근, 둔근)',
        reps: '12~15회 × 3세트',
        benefit: '전신 포도당의 70%를 소모하는 하체 대근육 강화',
        caution: '무릎을 완전히 펴서 관절을 잠그지(lock) 마세요.',
      ),
      const PrescribedExercise(
        name: '체스트 프레스 머신',
        category: 'gym_machine',
        target: '상체 (대흉근, 삼두근)',
        reps: '12~15회 × 3세트',
        benefit: '자세 흔들림 없이 안전하게 상체 대근육 자극',
        caution: '밀어낼 때 숨을 내쉬고, 절대로 숨을 참지 마세요.',
      ),
      const PrescribedExercise(
        name: '랫 풀 다운',
        category: 'gym_machine',
        target: '등 (광배근, 능형근)',
        reps: '12~15회 × 3세트',
        benefit: '상체 코어 안정화 및 척추 기립근 자세 교정',
        caution: '과도하게 상체를 뒤로 눕히지 말고 가슴을 펴세요.',
      ),

      // 홈트레이닝 (맨몸/소도구)
      const PrescribedExercise(
        name: '체어 스쿼트 (의자 스쿼트)',
        category: 'home_bodyweight',
        target: '하체 (허벅지, 엉덩이)',
        reps: '12~15회 × 3세트',
        benefit: '관절 무리 없이 식후 포도당을 빠르게 흡수',
        caution: '의자에 엉덩이가 살짝 닿는 느낌으로 안전하게 수행하세요.',
      ),
      const PrescribedExercise(
        name: '월 푸시업 (벽 밀기)',
        category: 'home_bodyweight',
        target: '상체 (가슴, 팔)',
        reps: '15~20회 × 3세트',
        benefit: '혈압 상승 부담이 없는 안전한 상체 근력 운동',
        caution: '손목 각도를 편안하게 조절하고 호흡을 끊지 마세요.',
      ),
      const PrescribedExercise(
        name: '글루트 브릿지',
        category: 'home_bodyweight',
        target: '둔근 및 햄스트링',
        reps: '12~15회 × 3세트',
        benefit: '허리 통증 완화 및 둔근 활성화',
        caution: '허리를 과도하게 꺾지 말고 엉덩이 힘으로 들어 올리세요.',
      ),
    ];

    List<PrescribedExercise> filteredExercises;
    if (environment == ExerciseEnvironment.gym) {
      filteredExercises = allExercises.where((e) => e.category == 'gym_machine').toList();
    } else if (environment == ExerciseEnvironment.home) {
      filteredExercises = allExercises.where((e) => e.category == 'home_bodyweight').toList();
    } else {
      // all: 주요 머신 2개 + 홈트 2개 추천
      filteredExercises = [
        allExercises[0], // 레그프레스
        allExercises[1], // 체스트프레스
        allExercises[3], // 체어 스쿼트
        allExercises[5], // 글루트 브릿지
      ];
    }

    // 3. 임상 주의사항 및 안전 가이드 취합
    final warnings = <String>[];
    if (conditions.contains(ConditionType.hypertension)) {
      warnings.add('발살바 호흡(힘줄 때 숨 참기) 금기: 힘을 줄 때 반드시 입으로 부드럽게 숨을 내쉬세요.');
      warnings.add('머리가 심장보다 아래로 내려가는 운동(디클라인, 거꾸리)은 피하세요.');
    }
    if (conditions.contains(ConditionType.prediabetes)) {
      warnings.add('공복 상태에서의 격렬한 운동은 저혈당 위험이 있으므로 식후 운동을 지켜주세요.');
    }
    if (conditions.contains(ConditionType.fattyLiver)) {
      warnings.add('지방간 회복을 위해 운동 후 알코올(술) 섭취는 엄격히 금지됩니다.');
    }
    if (conditions.contains(ConditionType.gout)) {
      warnings.add('젖산이 급격히 쌓이는 고강도 인터벌/무산소 운동은 요산 배출을 방해하므로 지양하세요.');
      warnings.add('탈수로 인한 통풍 발작 예방을 위해 시간당 200ml 이상의 미온수를 마시세요.');
    }
    if (conditions.contains(ConditionType.obesity)) {
      warnings.add('점프 동작이나 딱딱한 아스팔트 바닥에서의 조깅은 관절 충격을 주므로 피하세요.');
    }

    final goals = conditions.map((c) => c.clinicalFocus).toList();

    return WorkoutPrescription(
      conditionNames: names,
      primaryGoals: goals,
      aerobic: aerobic,
      exercises: filteredExercises,
      safetyWarnings: warnings,
    );
  }
}
