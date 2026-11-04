import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/repository/prescription_repository.dart';
import 'package:frontend/domain/model/condition_type.dart';
import 'package:frontend/presentation/selection/exercise_selection_screen.dart';
import 'package:frontend/presentation/selection/widgets/biweekly_routine_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('2-Week Alternating Split Routine Tests', () {
    const repository = PrescriptionRepository();

    test('Repository generates 14-day alternating split plan correctly', () {
      final plan = repository.generateBiWeeklyRoutine(
        conditions: {ConditionType.prediabetes, ConditionType.fattyLiver},
        environment: ExerciseEnvironment.gym,
      );

      // 14일 플랜 생성 확인
      expect(plan.days.length, 14);
      expect(plan.week1Days.length, 7);
      expect(plan.week2Days.length, 7);

      // 1주차 검증: 월·수·금·일 (4일 운동, 3일 안심 휴식일)
      expect(plan.week1Days[0].isRestDay, false); // 월 (하체 A)
      expect(plan.week1Days[0].title, contains('루틴 A'));
      expect(plan.week1Days[1].isRestDay, true);  // 화 (휴식)
      expect(plan.week1Days[2].isRestDay, false); // 수 (상체밀기 B)
      expect(plan.week1Days[3].isRestDay, true);  // 목 (휴식)
      expect(plan.week1Days[4].isRestDay, false); // 금 (상체당기기/코어 C)
      expect(plan.week1Days[5].isRestDay, true);  // 토 (휴식)
      expect(plan.week1Days[6].isRestDay, false); // 일 (하체복합 A')

      // 2주차 검증: 화·목·토 (3일 운동, 4일 안심 휴식일)
      expect(plan.week2Days[0].isRestDay, true);  // 월 (휴식)
      expect(plan.week2Days[1].isRestDay, false); // 화 (상체밀기 B')
      expect(plan.week2Days[2].isRestDay, true);  // 수 (휴식)
      expect(plan.week2Days[3].isRestDay, false); // 목 (상체등/코어 C')
      expect(plan.week2Days[4].isRestDay, true);  // 금 (휴식)
      expect(plan.week2Days[5].isRestDay, false); // 토 (하체 A)
      expect(plan.week2Days[6].isRestDay, true);  // 일 (휴식)

      // 부위별 48시간 이상 초회복 간격 보장 검증
      final workoutWeek1 = plan.week1Days.where((d) => !d.isRestDay).toList();
      expect(workoutWeek1.length, 4);
      final workoutWeek2 = plan.week2Days.where((d) => !d.isRestDay).toList();
      expect(workoutWeek2.length, 3);
    });

    testWidgets('UI: BiWeekly Routine View tab switching & rest day card rendering',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final plan = repository.generateBiWeeklyRoutine(
        conditions: {ConditionType.prediabetes, ConditionType.fattyLiver},
        environment: ExerciseEnvironment.gym,
      );

      int currentWeek = 1;
      int currentDayIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: BiWeeklyRoutineView(
                    plan: plan,
                    selectedWeek: currentWeek,
                    selectedDayIndex: currentDayIndex,
                    onSelectWeek: (w) => setState(() => currentWeek = w),
                    onSelectDayIndex: (d) => setState(() => currentDayIndex = d),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. 1주차 기본 렌더링 확인 (월요일 루틴 A)
      expect(find.text('1주차: 월·수·금·일 (주 4회)'), findsOneWidget);
      expect(find.text('2주차: 화·목·토 (주 3회)'), findsOneWidget);
      expect(find.textContaining('루틴 A'), findsWidgets);
      expect(find.textContaining('GLUT4'), findsWidgets);

      // 2. 화요일(휴식일) 칩 탭
      await tester.tap(find.text('화'));
      await tester.pumpAndSettle();

      // 휴식일 카드 노출 검증
      expect(find.textContaining('안심 휴식일입니다'), findsOneWidget);
      expect(find.textContaining('무리한 웨이트 대신 가벼운 산책이나 충분한 수분 섭취를 권장'), findsOneWidget);

      // 3. 2주차 탭 전환
      await tester.tap(find.text('2주차: 화·목·토 (주 3회)'));
      await tester.pumpAndSettle();

      // 2주차 월요일은 기본 휴식일
      expect(find.textContaining('안심 휴식일입니다'), findsOneWidget);

      // 2주차 화요일 칩 탭 (루틴 B')
      await tester.tap(find.text('화'));
      await tester.pumpAndSettle();
      expect(find.textContaining('루틴 B\''), findsWidgets);
    });

    testWidgets('ExerciseSelectionScreen: Switch between single mode & bi-weekly mode',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseSelectionScreen(
            selectedConditions: {ConditionType.prediabetes, ConditionType.fattyLiver},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 모드 세그먼트 확인
      final biWeeklyModeBtn = find.text('📅 격일 2주 순환 루틴 (추천)');
      final singleModeBtn = find.text('⚙️ 단일 맞춤 선택');
      expect(biWeeklyModeBtn, findsOneWidget);
      expect(singleModeBtn, findsOneWidget);

      // 격일 2주 순환 모드로 전환
      await tester.tap(biWeeklyModeBtn);
      await tester.pumpAndSettle();

      // 2주 순환 뷰 노출 확인
      expect(find.text('1주차: 월·수·금·일 (주 4회)'), findsOneWidget);
      expect(find.textContaining('루틴 시작 ➔'), findsOneWidget);

      // 화요일(휴식일) 선택 시 버튼 텍스트 변경 확인
      await tester.tap(find.text('화'));
      await tester.pumpAndSettle();
      expect(find.textContaining('오늘은 안심 휴식일'), findsOneWidget);
    });
  });
}
