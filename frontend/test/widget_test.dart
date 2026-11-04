import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('Onboarding multi-select condition smoke test', (WidgetTester tester) async {
    // 1. 앱 위젯 렌더링
    await tester.pumpWidget(const MyCareApp());
    await tester.pumpAndSettle();

    // 2. 타이틀 및 헤더 확인
    expect(find.text('My-Care'), findsOneWidget);
    expect(find.text('전당뇨'), findsOneWidget);
    expect(find.text('지방간'), findsOneWidget);

    // 3. 질환 미선택 시 하단 안내 문구 확인
    expect(find.text('관리 중인 질환을 1개 이상 선택해 주세요'), findsOneWidget);

    // 4. '전당뇨' 카드 탭하여 선택
    await tester.tap(find.text('전당뇨'));
    await tester.pumpAndSettle();

    // 5. 버튼 문구 검증
    expect(find.text('1개 질환 맞춤 운동 처방 받기'), findsOneWidget);

    // 6. 스크롤하여 결합 처방 배너 검증
    final bannerFinder = find.text('식후 30~60분 이내 걷기 골든타임 적용');
    await tester.scrollUntilVisible(bannerFinder, 200, scrollable: find.byType(Scrollable));
    expect(bannerFinder, findsOneWidget);

    // 7. '고혈압' 추가 선택
    final hypertensionFinder = find.text('고혈압');
    await tester.scrollUntilVisible(hypertensionFinder, -200, scrollable: find.byType(Scrollable));
    await tester.tap(hypertensionFinder);
    await tester.pumpAndSettle();

    expect(find.text('2개 질환 맞춤 운동 처방 받기'), findsOneWidget);

    final bpFinder = find.text('발살바 호흡 차단 및 안전한 머신 서킷 우선');
    await tester.scrollUntilVisible(bpFinder, 200, scrollable: find.byType(Scrollable));
    expect(bpFinder, findsOneWidget);
  });
}
