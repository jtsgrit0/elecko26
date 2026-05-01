import 'package:elecko26_new/features/home/presentation/widgets/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/app/injection_container.dart' as di;
import 'package:elecko26_new/core/config/app_config.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:elecko26_new/domain/usecases/member_usecases.dart';
import 'package:elecko26_new/features/home/presentation/pages/home_page.dart';
import 'package:elecko26_new/firebase_options.dart';
import 'package:elecko26_new/data/datasources/local_storage_service.dart'
    as elecko;
import 'package:elecko26_new/features/home/presentation/pages/region_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  // Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(milliseconds: 5000));
  } catch (e) {
    debugPrint('[Main] Firebase Init Delay/Error: $e');
  }

  runApp(const MyApp(members: []));
}

class MyApp extends StatelessWidget {
  final List<Member> members;
  const MyApp({super.key, required this.members});

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
      home: const InitialScreen(members: []),
    );
  }
}

class InitialScreen extends StatefulWidget {
  final List<Member> members;
  const InitialScreen({super.key, required this.members});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 데이터 로딩 시작
    debugPrint('[InitialScreen] _initializeApp: 데이터 로딩 시작');
    List<Member> members = [];
    try {
      members = await _getLoadedMembers();
      debugPrint('[InitialScreen] _initializeApp: 데이터 로딩 완료');
    } catch (e, stackTrace) {
      debugPrint('[InitialScreen] _initializeApp: 데이터 로딩 실패! 오류: $e');
      debugPrint('Stack trace: $stackTrace');
      // 오류 발생 시 빈 멤버 리스트로 진행하거나, 오류 화면을 표시할 수 있습니다.
      // 여기서는 빈 리스트로 진행하여 앱이 멈추지 않도록 합니다.
    }

    if (!mounted) return; // 위젯이 마운트 해제되었으면 더 이상 진행하지 않습니다.

    final localService = di.sl<elecko.LocalStorageService>();
    final initialRegion = await localService.getSelectedRegion();

    if (mounted) {
      if (initialRegion == null || initialRegion.isEmpty) {
        // initialRegion이 null이거나 비어있으면 지역 선택 화면으로
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RegionSelectionScreen(
              onRegionSelected: (region) async {
                final localService = di.sl<elecko.LocalStorageService>();
                await localService.saveSelectedRegion(region);
                // 지역 선택 후 다시 멤버 데이터를 로드할 필요 없이, 이미 로드된 members를 사용합니다.
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) =>
                            HomePage(members: members)), // 로드된 members 전달
                  );
                }
              },
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => HomePage(members: members)), // 로드된 members 전달
        );
      }
    }
  }

  Future<List<Member>> _getLoadedMembers() async {
    final getMembersUseCase = di.sl<GetMembersUseCase>();
    final calculateUseCase = di.sl<CalculateElectionPossibilityUseCase>();

    List<Member> loadedMembers = await getMembersUseCase.call();
    List<Future<Member>> updateFutures = loadedMembers.map((member) async {
      try {
        final result = await calculateUseCase.call(member.id);
        return member.copyWith(electionPossibility: result.electionPossibility);
      } catch (e) {
        debugPrint(
            'Error calculating election possibility for member ${member.id}: $e');
        return member;
      }
    }).toList();

    final updatedMembers = await Future.wait(updateFutures);
    return updatedMembers;
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
