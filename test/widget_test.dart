import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elecko26_new/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(members: []));

    // 스플래시 화면의 이미지가 존재하는지 확인
    expect(find.byType(Image), findsOneWidget);
  });
}
