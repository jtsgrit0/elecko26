import 'dart:async';
import 'dart:isolate';
import 'package:elecko26_new/features/home/presentation/widgets/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/app/injection_container.dart' as di;
import 'package:elecko26_new/core/config/app_config.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/core/utils/isolate_calculations.dart';
import 'package:elecko26_new/core/utils/utility_functions.dart';
import 'package:elecko26_new/domain/entities/analysis_result.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:elecko26_new/domain/usecases/member_usecases.dart';
import 'package:elecko26_new/domain/repositories/historical_election_repository.dart';
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
      members = await _getLoadedMembers(); // 데이터를 먼저 로드합니다.
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
    final historicalRepository = di.sl<HistoricalElectionRepository>();

    List<Member> loadedMembers = await getMembersUseCase.call();

    // 모든 지역 정보를 미리 로드
    final Set<String> allRegions = loadedMembers
        .map((m) => getParentRegion(m.district) == ''
            ? '전국'
            : getParentRegion(m.district))
        .toSet();

    final Map<String, Map<String, double>> regionalPartyAverages = {};
    final Map<String, double> voterInterests = {};
    final Map<String, String?> dominantParties = {};

    for (final region in allRegions) {
      regionalPartyAverages[region] =
          await historicalRepository.getRegionalPartyAverages(region);
      voterInterests[region] =
          await historicalRepository.getVoterInterest(region);
      dominantParties[region] =
          await historicalRepository.getDominantParty(region);
    }

    final ReceivePort receivePort = ReceivePort();
    final List<Future<Map<String, dynamic>>> isolateResults = [];

    for (final member in loadedMembers) {
      isolateResults.add(
        Isolate.spawn(
          calculateElectionPossibilityInIsolate,
          {
            'sendPort': receivePort.sendPort,
            'member': member,
            'regionalPartyAverages': regionalPartyAverages,
            'voterInterests': voterInterests,
            'dominantParties': dominantParties,
          },
        ).then((_) {
          // Isolate.spawn은 Future<Isolate>를 반환하므로, 실제 결과는 receivePort에서 받아야 합니다.
          // 여기서는 단순히 Isolate가 성공적으로 스폰되었음을 나타냅니다.
          return {}; // 임시 반환값
        }),
      );
    }

    // 모든 Isolate의 결과를 기다립니다.
    final Map<String, AnalysisResult> analysisResults = {};
    int completedCalculations = 0;

    await for (var message in receivePort) {
      final String memberId = message['memberId'];
      final AnalysisResult result =
          AnalysisResult.fromJson(message['analysisResult']);
      analysisResults[memberId] = result;
      completedCalculations++;

      if (completedCalculations == loadedMembers.length) {
        receivePort.close();
        break;
      }
    }

    final updatedMembers = loadedMembers.map((member) {
      final result = analysisResults[member.id];
      if (result != null) {
        return member.copyWith(electionPossibility: result.electionPossibility);
      }
      return member;
    }).toList();

    return updatedMembers;
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
