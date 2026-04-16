import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:elecko26/firebase_options.dart';
import 'package:elecko26/app/injection_container.dart' as di;
import 'package:elecko26/core/theme/app_theme.dart';
import 'package:elecko26/features/home/presentation/pages/home_page.dart';
import 'package:elecko26/core/config/app_config.dart';
import 'package:elecko26/domain/usecases/update_2018_party_support_from_pdf_usecase.dart';
import 'package:get_it/get_it.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.enableFirebase) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("✅ Firebase Initialize Success");
    } catch (e) {
      print("⚠️ Firebase Initialize Failed: $e");
    }
  }

  try {
    if (kIsWeb) {
      await di.initMinimal();
    } else {
      await di.init();
    }
  } catch (e, st) {
    print('DI init failed: $e\n$st');
  }

  // 2018년도 PDF 데이터 자동 업데이트 (백그라운드에서 실행)
  _update2018PartySupportData();

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

/// 2018년도 PDF 데이터 자동 업데이트 (백그라운드에서 실행)
Future<void> _update2018PartySupportData() async {
  try {
    print('🔄 2018년도 정당 지지율 데이터 자동 업데이트 시작...');
    
    final useCase = GetIt.instance<Update2018PartySupportFromPdfUseCase>();
    await useCase.executeAutoUpdate();
    
    print('✅ 2018년도 정당 지지율 데이터 업데이트 완료');
  } catch (e) {
    print('⚠️ 2018년도 데이터 업데이트 실패: $e');
    // 실패해도 앱 실행에는 영향 없음
  }
}
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