import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/app/injection_container.dart' as di;
import 'package:elecko26_new/core/config/app_config.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/features/home/presentation/pages/home_page.dart';
import 'package:elecko26_new/firebase_options.dart';
import 'package:elecko26_new/data/datasources/local_storage_service.dart' as elecko;
import 'package:elecko26_new/features/home/presentation/pages/region_selection_screen.dart' as elecko_region;
import 'package:elecko26_new/features/home/presentation/widgets/location_selection_modal.dart';

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
  bool _showSplash = true;
  String? _initialRegion;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 2.2초 후에는 초기화 여부와 상관없이 무조건 메인 화면으로 진입 (사용자 경험 최우선)
    final splashTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted && _showSplash) {
        setState(() => _showSplash = false);
        debugPrint('[Main] Splash Timeout - Forcing Home Entry');
      }
    });

    try {
      // 1. 최소한의 DI 초기화 (SharedPreferences 등)
      await di.initMinimal().timeout(const Duration(milliseconds: 1500));
      
      try {
        final localService = di.sl<elecko.LocalStorageService>();
        _initialRegion = await localService.getSelectedRegion();
      } catch (e) {
        debugPrint('[Main] Failed to get initial region: $e');
      }

      // 2. Firebase 초기화
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(milliseconds: 5000));
      } catch (e) {
        debugPrint('[Main] Firebase Init Delay/Error: $e');
      }
    } catch (e) {
      debugPrint('[Main] Initialization Error: $e');
    } finally {
      splashTimer.cancel();
      if (mounted) {
        setState(() => _showSplash = false);
      }
      debugPrint('[Main] Initialization Finished');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2026 당예기',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown
        },
      ),
      theme: AppTheme.lightTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: _initialRegion == null ? _buildLoadingWithModal() : (_showSplash ? _buildLoadingScreen() : const HomePage()),
    );
  }

  Widget _buildLoadingWithModal() {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          _buildLoadingScreenContent(),
          Align(
            alignment: Alignment.bottomCenter,
            child: LocationSelectionModal(
              onRegionSelected: (region) async {
                try {
                  final localService = di.sl<elecko.LocalStorageService>();
                  await localService.saveSelectedRegion(region);
                } catch (_) {}
                setState(() {
                  _initialRegion = region;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: _buildLoadingScreenContent(),
    );
  }

  Widget _buildLoadingScreenContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 로딩 아이콘 (흰색)
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          // 로딩 텍스트 (흰색)
          const Text(
            '2026 당예기 불러오는 중...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '붉은말의 해, 당신의 선택을 분석합니다',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 120), // 아래 모달 공간 확보
        ],
      ),
    );
  }
}
