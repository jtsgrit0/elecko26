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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 최소 스플래시 시간과 데이터 로딩을 동시에 진행
    final splashFuture = Future.delayed(const Duration(milliseconds: 2200));
    final dataFuture = _loadData();

    await Future.wait([splashFuture, dataFuture]);

    final localService = di.sl<elecko.LocalStorageService>();
    final initialRegion = await localService.getSelectedRegion();

    if (mounted) {
      if (initialRegion == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RegionSelectionScreen()),
        );
      } else {
        final members = await _getLoadedMembers();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(members: members)),
        );
      }
    }
  }

  Future<List<Member>> _getLoadedMembers() async {
    final getMembersUseCase = di.sl<GetMembersUseCase>();
    final calculateUseCase = di.sl<CalculateElectionPossibilityUseCase>();

    List<Member> loadedMembers = await getMembersUseCase.call();
    List<Member> updatedMembers = [];

    for (var member in loadedMembers) {
      try {
        final result = await calculateUseCase.call(member.id);
        updatedMembers.add(
            member.copyWith(electionPossibility: result.electionPossibility));
      } catch (e) {
        updatedMembers.add(member);
      }
    }
    return updatedMembers;
  }

  Future<void> _loadData() async {
    debugPrint('[InitialScreen] _loadData: 데이터 로딩 시작');
    try {
      await _getLoadedMembers();
      debugPrint('[InitialScreen] _loadData: 데이터 로딩 완료');
    } catch (e, stackTrace) {
      debugPrint('[InitialScreen] _loadData: 데이터 로딩 실패! 오류: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
