import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/app/injection_container.dart' as di;
import 'package:elecko26_new/core/config/app_config.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/features/home/presentation/pages/home_page.dart';
import 'package:elecko26_new/firebase_options.dart';
// import 'package:elecko26_new/features/splash/presentation/pages/splash_page.dart';
// import 'package:elecko26_new/features/on_boarding/presentation/pages/on_boarding_page.dart';
// import 'package:elecko26_new/features/auth/presentation/pages/auth_gate.dart';
// import 'package:elecko26_new/features/auth/presentation/pages/login_page.dart';
// import 'package:elecko26_new/features/auth/presentation/pages/register_page.dart';
// import 'package:elecko26_new/features/candidate_detail/presentation/pages/candidate_detail_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<void> _bootstrapFuture = _bootstrap();

  Future<void> _bootstrap() async {
    // 앱 전체 초기화에 절대로 8초 이상 넘기지 않음
    try {
      await _performInitialization().timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[Bootstrap] 초기화 한도 초과(8s) 또는 오류: $e');
      // 최악의 경우에도 최소한의 DI는 등록하고 진행 (0.5초 제한)
      try {
        await di.initMinimal().timeout(const Duration(milliseconds: 500));
      } catch (_) {}
    }
    debugPrint('[Bootstrap] 부트스트랩 완료');
  }

  Future<void> _performInitialization() async {
    if (AppConfig.enableFirebase) {
      try {
        // Firebase 초기화에 5초 타임아웃 적용
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[Bootstrap] Firebase 초기화 실패/타임아웃: $e');
      }
    }

    await di.initMinimal();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            title: '2026 당예기',
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 56),
                      const SizedBox(height: 16),
                      const Text(
                        '앱 초기화 중 문제가 발생했습니다.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            title: '2026 당예기',
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      '2026 당예기 불러오는 중...',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return MaterialApp(
          title: '2026 당예기',
          theme: AppTheme.lightTheme.copyWith(
            // 페이지 전환 애니메이션 단축 (기본 ZoomPage보다 빠른 Fade)
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
          ),
          scrollBehavior: const _FastScrollBehavior(),
          home: const HomePage(),
        );
      },
    );
  }
}

/// 스크롤 반응성 극대화: 마우스/터치/트랙패드 모두 드래그 허용
class _FastScrollBehavior extends ScrollBehavior {
  const _FastScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
}
