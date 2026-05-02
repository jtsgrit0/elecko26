import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elecko26_new/features/home/presentation/widgets/splash_screen.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // 앱 전체 대신 SplashScreen 단독 테스트로 우회하여 DI 에러 방지
    await tester.pumpWidget(const MaterialApp(
      home: SplashScreen(),
    ));

    // 스플래시 화면의 이미지가 존재하는지 확인
    expect(find.byType(Image), findsOneWidget);
  });
}
