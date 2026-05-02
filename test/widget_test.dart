import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elecko26_new/app/app.dart';
import 'package:elecko26_new/app/injection_container.dart' as di;

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // 의존성 주입 초기화 (테스트용)
    // 에러 방지를 위해 간단히 di.init() 호출 시도
    try {
      await di.init();
    } catch (_) {
      // 이미 초기화되어 있을 경우 무시
    }

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(members: []));

    // 스플래시 화면의 이미지가 존재하는지 확인
    // (테스트 환경에서는 이미지가 로드되지 않을 수 있으므로 Type으로 확인)
    expect(find.byType(Image), findsOneWidget);
  });
}
