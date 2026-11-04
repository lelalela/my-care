import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
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

    // 3. 처방 받기 탭
    final ctaButton = find.text('2개 질환 맞춤 운동 처방 받기');
    expect(ctaButton, findsOneWidget);
    await tester.tap(ctaButton);
    await tester.pumpAndSettle();

    // 4. 홈 대시보드 검증 (주간 스트릭 카드 & 목표 시간 칩)
    expect(find.text('오늘의 운동 처방'), findsOneWidget);
    expect(find.text('오늘의 운동을 시작해 보세요!'), findsOneWidget);
    expect(find.text('목표 운동 시간 선택'), findsOneWidget);

    // 5. 근력 운동 영역으로 스크롤 후 세트 트래커 테스트
    final routineTitle = find.text('오늘의 맞춤 근력 루틴');
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

    // 6. 상단 유산소 카드로 다시 스크롤 후 10분 단위 칩 '30분' 선택
    final chip30 = find.text('30분');
    await tester.scrollUntilVisible(chip30, -250, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(chip30);
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
}
