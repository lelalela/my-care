import '../../domain/model/condition_type.dart';
import '../../domain/model/prescription.dart';
import '../data_source/remote/prescription_api_client.dart';

/// 맞춤 운동 처방 생성 리포지토리
/// 백엔드 FastAPI 서버와 통신하며, 오프라인 시에도 각 질환별 전용 임상 가이드라인 알고리즘으로 동적 매핑합니다.
class PrescriptionRepository {
  const PrescriptionRepository({
    this.apiClient,
  });

  final PrescriptionApiClient? apiClient;

  /// 비동기 처방 생성 (FastAPI 우선 시도 -> 오프라인 폴백)
  Future<WorkoutPrescription> getPrescription({
    required Set<ConditionType> conditions,
    required ExerciseEnvironment environment,
    Set<String>? selectedExerciseNames,
    String? aerobicType,
    int? customAerobicDuration,
    int? customAerobicCadence,
  }) async {
    if (apiClient != null) {
      final remote = await apiClient!.fetchRecommendation(
        conditions: conditions,
        environment: environment,
      );
      if (remote != null) return remote;
    }
    return generatePrescription(
      conditions: conditions,
      environment: environment,
      selectedExerciseNames: selectedExerciseNames,
      aerobicType: aerobicType,
      customAerobicDuration: customAerobicDuration,
      customAerobicCadence: customAerobicCadence,
    );
  }

  /// 동기 처방 생성 (6대 질환별 차별화된 임상 데이터셋 기반)
  WorkoutPrescription generatePrescription({
    required Set<ConditionType> conditions,
    required ExerciseEnvironment environment,
    Set<String>? selectedExerciseNames,
    String? aerobicType,
    int? customAerobicDuration,
    int? customAerobicCadence,
  }) {
    final conditionList = conditions.toList();
    final names = conditionList.map((c) => c.name).toList();

    // 1. 유산소 지속 시간 및 케이던스 병합
    int targetDuration = customAerobicDuration ?? 35;
    int targetCadence = customAerobicCadence ?? 110;
    int cadenceMin = 100;
    int cadenceMax = 120;
    String timingMessage = '가장 편안한 시간대에 지속 가능한 속도로 걷기';
    final tips = <String>[];

    if (conditions.contains(ConditionType.prediabetes)) {
      timingMessage = '식후 30~60분 이내 (혈당 스파이크 억제 골든타임)';
      if (customAerobicCadence == null) targetCadence = 115;
      cadenceMin = 105;
      cadenceMax = 125;
      if (customAerobicDuration == null) targetDuration = 40;
      tips.add('식후 30분 시점에 걷기 시작 시 식후 혈당 급상승을 최대 30% 억제합니다.');
    }

    if (conditions.contains(ConditionType.fattyLiver)) {
      if (customAerobicDuration == null && targetDuration < 40) targetDuration = 40;
      tips.add('40분 이상 지속적인 유산소 운동이 간세포 내 중성지방 연소를 극대화합니다.');
    }

    if (conditions.contains(ConditionType.dyslipidemia)) {
      if (customAerobicDuration == null && targetDuration < 45) targetDuration = 45;
      tips.add('주 4~5회, 45분 이상 유산소를 지속할 때 혈중 HDL이 증가합니다.');
    }

    if (conditions.contains(ConditionType.obesity)) {
      tips.add('발목 및 무릎 관절 보호를 위해 쿠션화 착용과 평지 걷기를 권장합니다.');
    }

    if (conditions.contains(ConditionType.gout)) {
      if (customAerobicCadence == null && targetCadence > 110) targetCadence = 110;
      tips.add('탈수를 막기 위해 운동 전후 및 도중에 물을 충분히 섭취해 주세요.');
    }

    if (aerobicType == 'treadmill' || environment == ExerciseEnvironment.gym) {
      timingMessage = '트레드밀 속도 4.8~5.6 km/h (경사도 1~2%)로 설정하세요';
      tips.insert(0, '트레드밀 손잡이에 체중을 싣지 않고 시선을 정면으로 유지하며 걷습니다.');
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

    // 2. 6대 질환별 차별화된 전용 근력 운동 데이터베이스 매핑
    final candidateExercises = <PrescribedExercise>[];

    for (final cond in conditions) {
      switch (cond) {
        case ConditionType.prediabetes:
          // 전당뇨: 하체 대근육 및 가자미근(GLUT4) 집중
          candidateExercises.addAll([
            const PrescribedExercise(
              name: '시티드 레그프레스',
              category: 'gym_machine',
              target: '하체 대퇴사두근 & 둔근',
              reps: '12~15회 × 3세트',
              benefit: '전신 포도당의 약 70%를 소비하는 대근육 집중 활성화',
              caution: '발판을 어깨너비로 편안히 잡고 무릎을 잠그지(lock) 마세요.',
            ),
            const PrescribedExercise(
              name: '체어 스쿼트 (의자 스쿼트)',
              category: 'home_bodyweight',
              target: '허벅지 & 둔근',
              reps: '15회 × 3세트',
              benefit: '식후 실내에서 바로 할 수 있는 가장 강력한 혈당 흡수 운동',
              caution: '앉을 때 엉덩이를 뒤로 빼고 체중을 발뒤꿈치에 실으세요.',
            ),
            const PrescribedExercise(
              name: '카프 레이즈 (발뒤꿈치 들기)',
              category: 'home_bodyweight',
              target: '종아리 가자미근',
              reps: '20회 × 3세트',
              benefit: '가자미근의 인슐린 비의존성 포도당 흡수 촉진 (가자미근 푸시업 효과)',
              caution: '균형을 위해 벽이나 의자를 살짝 짚고 안전하게 수행하세요.',
            ),
            const PrescribedExercise(
              name: '랫 풀 다운',
              category: 'gym_machine',
              target: '등(광배근)',
              reps: '12회 × 3세트',
              benefit: '상체 글리코겐 저장소 확보를 위한 대근육 발달',
              caution: '상체를 과도하게 뒤로 젖히지 말고 가슴을 펴세요.',
            ),
          ]);

        case ConditionType.fattyLiver:
          // 지방간: 내장지방 산화 촉진 대근육 복합 운동
          candidateExercises.addAll([
            const PrescribedExercise(
              name: '체스트 프레스 머신',
              category: 'gym_machine',
              target: '가슴 & 삼두근',
              reps: '12회 × 3세트',
              benefit: '상체 대근육 자극으로 기초대사량 증대 및 지방 산화 촉진',
              caution: '어깨가 위로 으쓱 올라가지 않게 견갑골을 고정하세요.',
            ),
            const PrescribedExercise(
              name: '월 싯 (벽 대고 버티기)',
              category: 'home_bodyweight',
              target: '대퇴사두근 & 코어',
              reps: '30초 유지 × 3세트',
              benefit: '등척성 근수축을 통해 관절 부담 없이 지방 분해 효소 활성화',
              caution: '무릎 각도가 90도를 넘지 않도록 편안한 높이로 유지하세요.',
            ),
            const PrescribedExercise(
              name: '튜빙밴드 로우 (등 당기기)',
              category: 'home_tool',
              target: '등 근육 & 견갑대',
              reps: '15회 × 3세트',
              benefit: '소도구를 활용한 안전한 상체 후면 칼로리 연소',
              caution: '팔꿈치를 몸통 뒤로 부드럽게 당기며 호흡을 유지하세요.',
            ),
          ]);

        case ConditionType.hypertension:
          // 고혈압: 발살바 호흡 절대 금기, 저중량 고반복 머신 서킷
          candidateExercises.addAll([
            const PrescribedExercise(
              name: '레그 익스텐션 (저중량 머신)',
              category: 'gym_machine',
              target: '대퇴사두근',
              reps: '15~20회 × 2세트',
              benefit: '혈압 급상승 없이 안전하게 하체 혈류 순환 개선',
              caution: '힘을 줄 때 반드시 입으로 후~ 숨을 내쉬고 절대 숨을 참지 마세요.',
            ),
            const PrescribedExercise(
              name: '월 푸시업 (벽 밀기)',
              category: 'home_bodyweight',
              target: '상체 전반',
              reps: '15~20회 × 3세트',
              benefit: '가슴 압력 상승 부담이 전혀 없는 안전한 상체 근력 운동',
              caution: '머리가 어지럽지 않도록 일정한 리듬으로 호흡하세요.',
            ),
            const PrescribedExercise(
              name: '시티드 케이블 로우',
              category: 'gym_machine',
              target: '등 & 자세 교정',
              reps: '15회 × 2세트',
              benefit: '상체 혈액 순환을 돕고 안정된 자세 유지',
              caution: '허리를 과도하게 젖히지 말고 부드럽게 당기세요.',
            ),
          ]);

        case ConditionType.dyslipidemia:
          // 고지혈증: 지단백 분해 효소(LPL) 활성화를 위한 복합 서킷
          candidateExercises.addAll([
            const PrescribedExercise(
              name: '덤벨 루마니안 데드리프트',
              category: 'home_tool',
              target: '둔근 & 햄스트링',
              reps: '12~15회 × 3세트',
              benefit: '신체 후면 대근육 사슬을 가동하여 중성지방 대사 가속',
              caution: '허리를 곧게 펴고 무릎을 살짝 굽혀 엉덩이를 뒤로 미세요.',
            ),
            const PrescribedExercise(
              name: '슬로우 버피 (노 점프)',
              category: 'home_bodyweight',
              target: '전신 유산소 근력',
              reps: '10회 × 3세트',
              benefit: '점프 없이 안전하게 전신 대사를 끌어올려 HDL 증가에 기여',
              caution: '손목 관절에 무리가 가지 않도록 천천히 한 발씩 움직이세요.',
            ),
          ]);

        case ConditionType.obesity:
          // 비만: 무릎 관절 보호 저충격 근력
          candidateExercises.addAll([
            const PrescribedExercise(
              name: '시티드 레그컬 (머신)',
              category: 'gym_machine',
              target: '햄스트링 (허벅지 뒤쪽)',
              reps: '15회 × 3세트',
              benefit: '무릎 관절에 체중 부하를 전혀 주지 않는 안전한 하체 강화',
              caution: '엉덩이가 뜨지 않도록 손잡이를 단단히 잡으세요.',
            ),
            const PrescribedExercise(
              name: '글루트 브릿지 (바닥 운동)',
              category: 'home_bodyweight',
              target: '둔근 & 코어',
              reps: '15회 × 3세트',
              benefit: '서 있는 부담 없이 누워서 골반과 엉덩이 근육 활성화',
              caution: '허리를 과도하게 꺾지 말고 엉덩이 힘으로 들어 올리세요.',
            ),
          ]);

        case ConditionType.gout:
          // 통풍: 젖산 축적이 적은 가벼운 순환 저항 운동
          candidateExercises.addAll([
            const PrescribedExercise(
              name: '밴드 사이드 레터럴 레이즈',
              category: 'home_tool',
              target: '어깨 측면',
              reps: '15회 × 2세트 (저강도)',
              benefit: '젖산 분비를 최소화하며 상체 관절 가동성 유지',
              caution: '가벼운 저항 밴드를 사용하여 통증 없는 범위까지만 올리세요.',
            ),
            const PrescribedExercise(
              name: '머신 체스트 프레스 (저강도)',
              category: 'gym_machine',
              target: '상체 가슴',
              reps: '15회 × 2세트',
              benefit: '발가락/발목 관절에 체중 부담 없이 상체 활력 유지',
              caution: '땀을 과도하게 흘려 탈수되지 않도록 중간중간 물을 마시세요.',
            ),
          ]);
      }
    }

    // 이름 기준 중복 제거
    final uniqueExercises = <String, PrescribedExercise>{};
    for (final ex in candidateExercises) {
      uniqueExercises.putIfAbsent(ex.name, () => ex);
    }

    // 환경별 필터링
    List<PrescribedExercise> filteredList;
    if (environment == ExerciseEnvironment.gym) {
      filteredList = uniqueExercises.values
          .where((e) => e.category == 'gym_machine')
          .toList();
    } else if (environment == ExerciseEnvironment.home) {
      filteredList = uniqueExercises.values
          .where((e) => e.category == 'home_bodyweight' || e.category == 'home_tool')
          .toList();
    } else {
      filteredList = uniqueExercises.values.toList();
    }

    // 사용자가 특정 운동들을 선택한 경우 해당 운동들만 포함
    if (selectedExerciseNames != null && selectedExerciseNames.isNotEmpty) {
      filteredList = filteredList
          .where((e) => selectedExerciseNames.contains(e.name))
          .toList();
    } else if (filteredList.length > 5) {
      // 최대 4~5종목 균형 추천
      filteredList = filteredList.sublist(0, 5);
    } else if (filteredList.isEmpty) {
      // 기본 폴백 안전 운동
      filteredList = [
        const PrescribedExercise(
          name: '체어 스쿼트',
          category: 'home_bodyweight',
          target: '하체',
          reps: '12회 × 3세트',
          benefit: '안전한 대근육 포도당 대사',
          caution: '무릎 통증 시 깊이를 조절하세요.',
        ),
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
      exercises: filteredList,
      safetyWarnings: warnings,
    );
  }
}
