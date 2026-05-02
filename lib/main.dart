import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/app/injection_container.dart' as di;
import 'package:elecko26_new/app/app.dart';
import 'package:elecko26_new/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 앱 전체 초기화 안정성 확보 (병렬 처리)
  try {
    await Future.wait([
      di.initMinimal(),
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(milliseconds: 5000)),
    ]).timeout(const Duration(milliseconds: 8000));
  } catch (e) {
    debugPrint('[Main] Initialization Delay or Error (Proceeding anyway): $e');
  }

  runApp(const MyApp(members: []));
}
