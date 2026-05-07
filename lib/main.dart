import 'dart:async';
import 'package:flutter/material.dart';
import 'package:elecko26_new/app/injection_container.dart' as di;
import 'package:elecko26_new/app/app.dart';

Future<void> main() async {
  debugPrint('[Main] main 함수 시작');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[Main] WidgetsFlutterBinding.ensureInitialized() 완료');

  // 앱 전체 초기화 안정성 확보
  try {
    debugPrint('[Main] DI 초기화 시작');
    await di.initMinimal().timeout(const Duration(milliseconds: 15000));
    debugPrint('[Main] DI 초기화 완료');
  } catch (e) {
    debugPrint('[Main] Initialization Delay or Error (Proceeding anyway): $e');
  }

  debugPrint('[Main] runApp 호출 직전');
  runApp(const MyApp(members: []));
  debugPrint('[Main] runApp 호출 완료 (이 메시지는 보이지 않을 수 있음)');
}
