import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_application_1/app/injection_container.dart' as di;
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/home/presentation/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 의존성 주입 설정
  try {
    if (kIsWeb) {
      await di.initMinimal();
    } else {
      await di.init();
    }
  } catch (e, st) {
    // 초기화 실패 시 로그 출력하되 앱은 계속 실행
    // (추후에 필요한 서비스가 없다면 기능 제한이 발생할 수 있음)
    // 로그를 통해 원인 분석하도록 합니다.
    // ignore: avoid_print
    print('DI init failed: $e\n$st');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2026 지방선거 - 국회의원 AI 분석',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      home: const HomePage(),
    );
  }
}
