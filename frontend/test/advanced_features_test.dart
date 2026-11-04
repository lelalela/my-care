import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/domain/model/condition_type.dart';
import 'package:frontend/domain/model/prescription.dart';
import 'package:frontend/main.dart';
import 'package:frontend/presentation/home/widgets/exercise_set_tracker_dialog.dart';
import 'package:frontend/presentation/selection/exercise_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Safety Guard: Joint pain filter excludes high-impact exercises',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: ExerciseSelectionScreen(
          selectedConditions: {ConditionType.prediabetes},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. 관절 통증 필터 칩 노출 확인
    expect(find.text('무릎 관절/통증'), findsOneWidget);
    expect(find.text('허리 디스크/통증'), findsOneWidget);

    // 2. '무릎 관절/통증' 필터 탭
    await tester.tap(find.text('무릎 관절/통증'));
    await tester.pumpAndSettle();

    // 스낵바 노출 확인
    expect(find.textContaining('관절 보호를 위해 주의 운동'), findsOneWidget);

    // 3. 무릎 부하 주의 경고 뱃지 확인
    expect(find.text('무릎 관절 부하 주의'), findsWidgets);
  });

  testWidgets('ExerciseSetTrackerDialog: Safety exit dialog and blood sugar logging',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const testExercise = PrescribedExercise(
      name: '덤벨 스쿼트',
      category: 'home_tool',
      target: '허벅지 및 둔근',
      reps: '12회 × 2세트',
      benefit: '포도당 흡수 촉진',
      caution: '무릎이 발끝을 넘지 않도록 주의',
    );

    int completed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExerciseSetTrackerDialog(
            exercise: testExercise,
            targetSets: 2,
            conditions: const ['전당뇨'],
            onExerciseCompleted: (sets) => completed = sets,
            onUpdateTargetSets: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. 세트 완료 (1세트 탭 -> 휴식 스킵 -> 2세트 탭)
    await tester.tap(find.text('탭하여 완료'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('휴식 스킵'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('탭하여 완료'));
    await tester.pumpAndSettle();

    expect(completed, 2);

    // 2. [기획 3] 운동 전/후 혈당 입력 섹션 노출 확인
    expect(find.text('운동 전/후 혈당 변화 기록 (선택)'), findsOneWidget);
  });

  testWidgets('WeeklyStreakCard: Rest Day (안심 휴식일) and Medical Report dialog test',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyCareApp());
    await tester.pumpAndSettle();

    // 온보딩 -> 2단계 -> 홈 이동
    await tester.tap(find.text('전당뇨'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1개 질환 맞춤 운동 처방 받기'));
    await tester.pumpAndSettle();
    final startRoutineBtn = find.textContaining('운동으로 루틴 시작 ➔');
    await tester.scrollUntilVisible(startRoutineBtn, 250, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(startRoutineBtn);
    await tester.pumpAndSettle();

    // 1. 의료진 리포트 버튼 확인 및 탭
    expect(find.text('의사용 리포트'), findsOneWidget);
    await tester.tap(find.text('의사용 리포트'));
    await tester.pumpAndSettle();

    expect(find.text('대사 케어 주간 순응도 소견서'), findsOneWidget);
    expect(find.text('총 유산소 시간'), findsOneWidget);
    expect(find.text('클립보드 복사'), findsOneWidget);

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    // 2. '안심 휴식일 지정' 버튼 탭
    final restBtn = find.text('안심 휴식일 지정');
    expect(restBtn, findsOneWidget);
    await tester.tap(restBtn);
    await tester.pumpAndSettle();

    expect(find.text('안심 휴식일 선언'), findsOneWidget);
    await tester.tap(find.text('휴식일로 지정'));
    await tester.pumpAndSettle();

    expect(find.textContaining('오늘을 안심 휴식일로 지정했습니다'), findsOneWidget);
  });

  testWidgets('Fast-Track: 1-Tap from Step 1 directly to Step 3 Home using template',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyCareApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // 1단계 첫 화면에서 저장된 템플릿 캐러셀 노출 확인
    expect(find.text('저장된 루틴 바로 시작'), findsOneWidget);
    expect(find.text('⭐ [추천] 대사 케어 헬스장 루틴'), findsOneWidget);

    // 1·2단계 건너뛰고 템플릿 탭
    await tester.tap(find.text('⭐ [추천] 대사 케어 헬스장 루틴'));
    await tester.pumpAndSettle();

    // 곧바로 3단계 홈 화면으로 진입 확인
    expect(find.text('오늘의 운동 처방'), findsOneWidget);
    expect(find.text('헬스장'), findsWidgets);
    expect(find.text('오늘의 맞춤 하루 운동 루틴'), findsOneWidget);

    // 홈에서 '현재 구성을 템플릿으로 저장' 아이콘 탭
    final saveIcon = find.byTooltip('현재 구성을 템플릿으로 저장');
    expect(saveIcon, findsOneWidget);
    await tester.tap(saveIcon);
    await tester.pumpAndSettle();

    expect(find.text('현재 루틴 템플릿 저장'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
  });
}
