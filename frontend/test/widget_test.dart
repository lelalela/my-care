import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/presentation/walking/walking_screen.dart';

void main() {
  testWidgets('Complete flow: Onboarding -> Home -> Walking Coaching -> Complete',
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

    // 4. 홈 대시보드 검증
    expect(find.text('오늘의 운동 처방'), findsOneWidget);
    expect(find.text('115 SPM 워킹 코칭 시작'), findsOneWidget);

    // 5. 워킹 코칭 화면으로 진입 (애니메이션 반복으로 pump 사용)
    await tester.tap(find.text('115 SPM 워킹 코칭 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('실시간 워킹 코칭'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(WalkingScreen), matching: find.text('115')),
      findsOneWidget,
    );
    expect(find.text('예상 속도 약 5.2 km/h'), findsOneWidget);
    expect(find.text('일시 정지'), findsOneWidget);

    // 6. SPM 속도 조절 (+5 SPM)
    await tester.tap(find.text('5 SPM 빠르게'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('120'), findsOneWidget);
    expect(find.text('예상 속도 약 5.4 km/h'), findsOneWidget);

    // 7. 일시 정지 토글
    await tester.tap(find.text('일시 정지'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('다시 걷기'), findsOneWidget);

    // 8. 운동 완료 탭 및 다이얼로그 확인
    await tester.tap(find.text('운동 완료'));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 워킹 완료! 🎉'), findsOneWidget);

    // 9. 대시보드로 복귀
    await tester.tap(find.text('대시보드로 돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 운동 처방'), findsOneWidget);
  });
}
