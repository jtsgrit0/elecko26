import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/app/injection_container.dart' as di;
import 'package:elecko26_new/app/app.dart';
import 'package:elecko26_new/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[Main] WidgetsFlutterBinding.ensureInitialized() 완료');

  // 앱 전체 초기화 안정성 확보 (병렬 처리)
  try {
    debugPrint('[Main] 초기화 시작 (Firebase, DI)');
    await Future.wait([
      di.initMinimal(),
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(milliseconds: 10000)), // Firebase 타임아웃 10초로 늘림
    ]).timeout(const Duration(milliseconds: 15000)); // 전체 타임아웃 15초로 늘림
    debugPrint('[Main] 초기화 완료');
  } catch (e) {
    debugPrint('[Main] Initialization Delay or Error (Proceeding anyway): $e');
  }

  debugPrint('[Main] runApp 호출');
  runApp(const MyApp(members: []));
}
