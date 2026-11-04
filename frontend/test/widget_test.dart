import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('Onboarding multi-select and navigation to Home Dashboard test',
      (WidgetTester tester) async {
    // 1. 앱 위젯 렌더링
    await tester.pumpWidget(const MyCareApp());
    await tester.pumpAndSettle();

    // 2. 온보딩 타이틀 및 질환 확인
    expect(find.text('My-Care'), findsOneWidget);
    expect(find.text('전당뇨'), findsOneWidget);
    expect(find.text('지방간'), findsOneWidget);

    // 3. '전당뇨'와 '지방간' 복수 선택
    await tester.tap(find.text('전당뇨'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('지방간'));
    await tester.pumpAndSettle();

    // 4. CTA 버튼 확인 및 탭하여 홈 대시보드로 이동
    final ctaButton = find.text('2개 질환 맞춤 운동 처방 받기');
    expect(ctaButton, findsOneWidget);
    await tester.tap(ctaButton);
    await tester.pumpAndSettle();

    // 5. 홈 대시보드 화면 렌더링 검증
    expect(find.text('오늘의 운동 처방'), findsOneWidget);
    expect(find.text('오늘의 맞춤 유산소'), findsOneWidget);
    expect(find.text('115'), findsOneWidget); // 전당뇨 기준 115 SPM
    expect(find.text('40분 지속'), findsOneWidget); // 전당뇨/지방간 병합 40분

    // 6. 근력 루틴 및 안전 수칙 표시 확인
    expect(find.text('오늘의 맞춤 근력 루틴'), findsOneWidget);
    expect(find.text('115 SPM 워킹 코칭 시작'), findsOneWidget);

    // 7. 워킹 코칭 시작 탭 시 안내 다이얼로그 표시 확인
    await tester.tap(find.text('115 SPM 워킹 코칭 시작'));
    await tester.pumpAndSettle();
    expect(find.text('워킹 코칭 준비'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);

    // 다이얼로그 닫기
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('워킹 코칭 준비'), findsNothing);

    // 8. 설정(재설정) 아이콘 탭하여 온보딩으로 복귀 확인
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(find.text('관리 중이거나 주의가 필요한\n질환을 모두 선택해 주세요'), findsOneWidget);
  });
}
