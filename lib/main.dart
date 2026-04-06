import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/app/injection_container.dart' as di;
import 'package:flutter_application_1/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 의존성 주입 설정
  if (kIsWeb) {
    await di.initMinimal();
  } else {
    await di.init();
  }

  runApp(const MyApp());
}