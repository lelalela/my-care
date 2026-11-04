import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/presentation/selection/exercise_selection_screen.dart';
import 'package:frontend/presentation/walking/walking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Complete flow: Onboarding -> Home (Streak & Strength Set) -> Walking Coaching',
      (WidgetTester tester) async {
    // 1. 앱 실행
    await tester.pumpWidget(const MyCareApp());
    await tester.pumpAndSettle();

    // 2. 질환 선택 ('전당뇨' + '고혈압')
    await tester.tap(find.text('전당뇨'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('고혈압'));
    await tester.pumpAndSettle();

    // 3. 1단계 완료: 운동 선별 화면으로 이동
    final ctaButton = find.text('2개 질환 맞춤 운동 처방 받기');
    expect(ctaButton, findsOneWidget);
    await tester.tap(ctaButton);
    await tester.pumpAndSettle();

    // 3-1. 2단계: 맞춤 운동 선별 화면 검증 & 루틴 시작
    expect(find.text('2단계: 맞춤 운동 선별'), findsOneWidget);
    final startRoutineBtn = find.textContaining('운동으로 루틴 시작 ➔');
    expect(startRoutineBtn, findsOneWidget);
    await tester.tap(startRoutineBtn);
    await tester.pumpAndSettle();

    // 4. 3단계: 홈 대시보드 검증 (주간 스트릭 카드 & 목표 워킹 시간)
    expect(find.text('오늘의 운동 처방'), findsOneWidget);
    expect(find.text('오늘의 운동을 시작해 보세요!'), findsOneWidget);
    expect(find.text('목표 워킹 시간'), findsOneWidget);

    // 5. 근력 운동 영역으로 스크롤 후 세트 트래커 테스트
    final routineTitle = find.text('맞춤 근력 & 홈트');
    await tester.scrollUntilVisible(routineTitle, 250, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    final exerciseFinder = find.text('세트 시작 ⏱️').first;
    await tester.tap(exerciseFinder);
    await tester.pumpAndSettle();

    expect(find.text('세트 완료 체크'), findsOneWidget);
    await tester.tap(find.text('세트 완료 체크'));
    await tester.pumpAndSettle();

    expect(find.text('세트 간 호흡 정리 휴식'), findsOneWidget);
    expect(find.text('휴식 스킵'), findsOneWidget);
    await tester.tap(find.text('휴식 스킵'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('나중에 이어서 하기'));
    await tester.pumpAndSettle();

    // 6. 상단 유산소 영역으로 다시 스크롤 후 Stepper '10분 줄이기' 탭 (40분 -> 30분)
    final reduceButton = find.byTooltip('10분 줄이기');
    await tester.scrollUntilVisible(reduceButton, -250, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(reduceButton);
    await tester.pumpAndSettle();

    final startButton = find.text('115 SPM 워킹 코칭 시작 (30분)');
    expect(startButton, findsOneWidget);
    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();

    // 7. 워킹 코칭 화면으로 진입 (30분으로 진입)
    await tester.tap(startButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('실시간 워킹 코칭'), findsOneWidget);
    expect(find.text('목표 30분'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(WalkingScreen), matching: find.text('115')),
      findsOneWidget,
    );
    expect(find.text('예상 속도 약 5.2 km/h'), findsOneWidget);

    // 8. SPM 속도 조절 (+5 SPM)
    await tester.tap(find.text('5 SPM 빠르게'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('120'), findsOneWidget);
    expect(find.text('예상 속도 약 5.4 km/h'), findsOneWidget);

    // 9. 일시 정지 토글
    await tester.tap(find.text('일시 정지'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('다시 걷기'), findsOneWidget);

    // 10. 운동 완료 탭 및 다이얼로그 확인
    await tester.tap(find.text('운동 완료'));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 워킹 완료! 🎉'), findsOneWidget);

    // 11. 대시보드로 복귀
    await tester.tap(find.text('대시보드로 돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 운동 처방'), findsOneWidget);
  });

  testWidgets('Dynamic Set Configuration & Batch Apply test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyCareApp());
    await tester.pumpAndSettle();

    // 질환 선택 후 2단계 이동
    await tester.tap(find.text('전당뇨'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1개 질환 맞춤 운동 처방 받기'));
    await tester.pumpAndSettle();

    // 2단계에서 루틴 시작 탭하여 홈 진입
    final startRoutineBtn = find.textContaining('운동으로 루틴 시작 ➔');
    expect(startRoutineBtn, findsOneWidget);
    await tester.tap(startRoutineBtn);
    await tester.pumpAndSettle();

    // 근력 루틴 헤더로 스크롤
    final routineTitle = find.text('맞춤 근력 & 홈트');
    await tester.scrollUntilVisible(routineTitle, 250, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    // 1. 초기 상태: 기본 3세트 확인
    expect(find.text('전체 3세트'), findsOneWidget);

    // 2. 헤더의 '전체 3세트' 탭하여 일괄 2세트로 변경
    await tester.tap(find.text('전체 3세트'));
    await tester.pumpAndSettle();
    expect(find.text('목표 세트 일괄 설정'), findsOneWidget);

    // 2세트 프리셋 칩 탭
    await tester.tap(find.text('2세트'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('적용하기'));
    await tester.pumpAndSettle();

    // 3. 헤더 및 카드 텍스트가 2세트로 일괄 변경되었는지 검증
    expect(find.text('전체 2세트'), findsOneWidget);
    expect(find.textContaining('× 2세트'), findsWidgets);

    // 4. 특정 운동 진입 후 4세트로 변경 및 '일괄 적용' 체크
    final exerciseFinder = find.text('세트 시작 ⏱️').first;
    await tester.tap(exerciseFinder);
    await tester.pumpAndSettle();

    expect(find.text('목표 2세트 (변경)'), findsOneWidget);
    await tester.tap(find.text('목표 2세트 (변경)'));
    await tester.pumpAndSettle();

    expect(find.text('목표 세트 변경'), findsOneWidget);
    await tester.tap(find.text('4세트'));
    await tester.pumpAndSettle();

    // '오늘 모든 근력 운동에 일괄 적용' 체크
    await tester.tap(find.text('오늘 모든 근력 운동에 일괄 적용'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('적용하기'));
    await tester.pumpAndSettle();

    // 다이얼로그 내 4세트로 늘어났는지 확인 (1세트 ~ 4세트)
    expect(find.text('4세트'), findsWidgets);

    // 닫기
    await tester.tap(find.text('나중에 이어서 하기'));
    await tester.pumpAndSettle();

    // 홈 화면 전체가 4세트로 일괄 반영되었는지 확인
    expect(find.text('전체 4세트'), findsOneWidget);
    expect(find.textContaining('× 4세트'), findsWidgets);
  });

  testWidgets('Step 2: Gym/Home Tab Switch, Exercise Checkbox, and Template Save/Load test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyCareApp());
    await tester.pumpAndSettle();

    // 1. 질환 선택 후 2단계 이동
    await tester.tap(find.text('전당뇨'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1개 질환 맞춤 운동 처방 받기'));
    await tester.pumpAndSettle();

    expect(find.text('2단계: 맞춤 운동 선별'), findsOneWidget);

    // 기본은 홈트(식후 야외 / 실내 걷기)
    expect(find.text('식후 야외 / 실내 걷기'), findsOneWidget);

    // 2. 헬스장 탭으로 전환
    await tester.tap(find.text('🏋️ 헬스장 (기구 운동)'));
    await tester.pumpAndSettle();

    // 트레드밀 및 기구 운동 노출 확인
    expect(find.text('트레드밀 (러닝머신 워킹)'), findsOneWidget);
    expect(find.text('시티드 레그프레스'), findsOneWidget);

    // 3. 템플릿 목록 열기
    await tester.tap(find.text('템플릿'));
    await tester.pumpAndSettle();

    expect(find.text('저장된 루틴 템플릿'), findsOneWidget);
    expect(find.text('⭐ [추천] 대사 케어 헬스장 루틴'), findsOneWidget);

    // 추천 헬스장 루틴 적용 탭
    final applyBtn = find.text('적용').first;
    await tester.tap(applyBtn);
    await tester.pumpAndSettle();

    // 4. 현재 구성을 템플릿으로 저장하기 탭
    final saveTemplateBtn = find.text('현재 구성을 템플릿으로 저장 💾');
    await tester.scrollUntilVisible(saveTemplateBtn, 200);
    await tester.tap(saveTemplateBtn);
    await tester.pumpAndSettle();

    expect(find.text('루틴 템플릿 저장'), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    // 스낵바 즉시 전체 제거
    ScaffoldMessenger.of(tester.element(find.byType(ExerciseSelectionScreen))).clearSnackBars();
    await tester.pumpAndSettle();

    final startBtn = find.textContaining('운동으로 루틴 시작 ➔');
    await tester.tap(startBtn);
    await tester.pumpAndSettle();

    // 6. 3단계 홈 진입 확인: 트레드밀 코칭과 헬스장 머신들이 루틴에 배치됨
    expect(find.text('오늘의 운동 처방'), findsOneWidget);
    expect(find.text('트레드밀 (러닝머신)'), findsOneWidget);
  });
}
