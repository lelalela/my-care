import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/presentation/walking/walking_screen.dart';

void main() {
  testWidgets('Complete flow with 10-min duration chips & completion feedback',
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

    // 4. 홈 대시보드 검증 및 10분 단위 목표 시간 조절
    expect(find.text('오늘의 운동 처방'), findsOneWidget);
    expect(find.text('목표 운동 시간 선택'), findsOneWidget);
    expect(find.text('115 SPM 워킹 코칭 시작 (40분)'), findsOneWidget);

    // 10분 단위 칩 '30분' 선택
    await tester.tap(find.text('30분'));
    await tester.pumpAndSettle();
    
    final startButton = find.text('115 SPM 워킹 코칭 시작 (30분)');
    expect(startButton, findsOneWidget);
    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();

    // 5. 워킹 코칭 화면으로 진입 (30분으로 진입)
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
