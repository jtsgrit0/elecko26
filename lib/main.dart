import 'package:firebase_core/firebase_core.dart';
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
    if (AppConfig.enableFirebase) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        debugPrint('[Bootstrap] Firebase initialization skipped/duplicate: $e');
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
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('후보 데이터를 준비하는 중입니다...'),
                  ],
                ),
              ),
            ),
          );
        }

        return MaterialApp(
          title: '2026 당예기',
          theme: AppTheme.lightTheme,
          home: const HomePage(),
        );
      },
    );
  }
}
