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
    // 2.5초 후에는 무조건 로딩을 종료하도록 보장
    final forcedExit = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        debugPrint('[Bootstrap] 강제 초기화 완료 (Timer)');
        // FutureBuilder를 완료시키기 위해 더 이상 할 일 없음 (이미 리턴됨)
      }
    });

    try {
      // 초기화 작업 수행 (최대 2초 한도)
      await _performInitialization().timeout(
        const Duration(milliseconds: 2000),
        onTimeout: () => debugPrint('[Bootstrap] 초기화 시간 초과 (2s)'),
      );
    } catch (e) {
      debugPrint('[Bootstrap] 초기화 중 오류: $e');
    } finally {
      forcedExit.cancel();
      debugPrint('[Bootstrap] 부트스트랩 최종 완료');
    }
  }

  Future<void> _performInitialization() async {
    // 1. 필수 DI (SharedPreferences 등) 우선 실행 (보통 500ms 이내)
    await di.initMinimal().timeout(const Duration(seconds: 2));

    // 2. Firebase 초기화 (배경 실행 허용)
    if (AppConfig.enableFirebase) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(milliseconds: 1000));
      } catch (e) {
        debugPrint('[Bootstrap] Firebase 지연 중 (배경 진행): $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2026 당예기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        // 페이지 전환 애니메이션 단축
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
      home: FutureBuilder<void>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorScreen(snapshot.error.toString());
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildLoadingScreen();
          }
          return const HomePage();
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: Colors.red,
                strokeWidth: 5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '2026 당예기 불러오는 중...',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                '앱 초기화 중 문제가 발생했습니다.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // 재시도 로직 (필요 시)
                },
                child: const Text('재시도'),
              ),
            ],
          ),
        ),
      ),
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
