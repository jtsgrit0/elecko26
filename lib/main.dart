import 'dart:async';
import 'dart:isolate';
import 'package:elecko26_new/features/home/presentation/widgets/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/app/injection_container.dart' as di;
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/core/utils/isolate_calculations.dart';
import 'package:elecko26_new/core/utils/utility_functions.dart';
import 'package:elecko26_new/domain/entities/member.dart';
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
    final localService = di.sl<elecko.LocalStorageService>();

    // 1. 기본 멤버 데이터 로드
    List<Member> loadedMembers = await getMembersUseCase.call();
    if (loadedMembers.isEmpty) return [];

    // 2. 선택된 지역 확인
    final selectedRegion = await localService.getSelectedRegion();

    // 3. 지역별 통계 데이터 미리 로드 (계산에 필요)
    final Set<String> allRegions = loadedMembers
        .map((m) => getParentRegion(m.district) == ''
            ? '전국'
            : getParentRegion(m.district))
        .toSet();

    final Map<String, Map<String, double>> regionalPartyAverages = {};
    final Map<String, double> voterInterests = {};
    final Map<String, String?> dominantParties = {};

    // 모든 지역 데이터를 한꺼번에 로드 (캐시 활용)
    for (final region in allRegions) {
      regionalPartyAverages[region] =
          await historicalRepository.getRegionalPartyAverages(region);
      voterInterests[region] =
          await historicalRepository.getVoterInterest(region);
      dominantParties[region] =
          await historicalRepository.getDominantParty(region);
    }

    // 4. 우선순위 설정 (선택된 지역의 멤버를 먼저 계산)
    List<Member> primaryMembers = [];
    List<Member> secondaryMembers = [];

    if (selectedRegion != null && selectedRegion.isNotEmpty && selectedRegion != '전국') {
      for (var m in loadedMembers) {
        if (getParentRegion(m.district) == selectedRegion) {
          primaryMembers.add(m);
        } else {
          secondaryMembers.add(m);
        }
      }
    } else {
      // 선택된 지역이 없으면 상위 일부만 우선 로드 (예: 100명)
      primaryMembers = loadedMembers.take(100).toList();
      secondaryMembers = loadedMembers.skip(100).toList();
    }

    // 5. Isolate를 통한 효율적 계산 (하나의 Isolate에서 배치 처리)
    final ReceivePort receivePort = ReceivePort();
    
    // 우선순위 멤버 계산 시작
    if (primaryMembers.isNotEmpty) {
      await _calculateBatchInIsolate(
        primaryMembers,
        regionalPartyAverages,
        voterInterests,
        dominantParties,
        receivePort,
      );
    }

    // 결과 수집 및 멤버 업데이트
    final Map<String, double> calculatedPossibilities = {};
    int receivedCount = 0;

    if (primaryMembers.isNotEmpty) {
      await for (var message in receivePort) {
        final String memberId = message['memberId'];
        final double possibility = message['electionPossibility'];
        calculatedPossibilities[memberId] = possibility;
        receivedCount++;
        if (receivedCount >= primaryMembers.length) break;
      }
    }
    receivePort.close();

    // 나머지 멤버는 백그라운드에서 처리 (Future로 비동기 실행)
    _calculateSecondaryMembersInBackground(
      secondaryMembers,
      regionalPartyAverages,
      voterInterests,
      dominantParties,
    );

    // 업데이트된 리스트 반환
    return loadedMembers.map((m) {
      if (calculatedPossibilities.containsKey(m.id)) {
        return m.copyWith(electionPossibility: calculatedPossibilities[m.id]);
      }
      return m;
    }).toList();
  }

  /// 백그라운드에서 나머지 멤버들의 당선 가능성 계산
  Future<void> _calculateSecondaryMembersInBackground(
    List<Member> members,
    Map<String, Map<String, double>> regionalPartyAverages,
    Map<String, double> voterInterests,
    Map<String, String?> dominantParties,
  ) async {
    if (members.isEmpty) return;
    
    // 대량의 데이터를 작은 배치로 나누어 계산 (UI 블로킹 방지)
    const int batchSize = 50;
    for (int i = 0; i < members.length; i += batchSize) {
      final end = (i + batchSize < members.length) ? i + batchSize : members.length;
      final batch = members.sublist(i, end);
      
      final ReceivePort tempPort = ReceivePort();
      await _calculateBatchInIsolate(
        batch,
        regionalPartyAverages,
        voterInterests,
        dominantParties,
        tempPort,
      );
      
      // 결과는 현재 상태에서는 무시하거나, 필요시 전역 상태(Provider/BLoC)를 통해 업데이트
      // 여기서는 초기 로딩 속도 최적화가 목적이므로 우선 계산만 수행
      tempPort.close();
      await Future.delayed(const Duration(milliseconds: 100)); // CPU 휴식
    }
  }

  /// Isolate에서 멤버 리스트를 배치로 처리
  Future<void> _calculateBatchInIsolate(
    List<Member> members,
    Map<String, Map<String, double>> regionalPartyAverages,
    Map<String, double> voterInterests,
    Map<String, String?> dominantParties,
    ReceivePort receivePort,
  ) async {
    await Isolate.spawn(
      _batchCalculationEntry,
      {
        'sendPort': receivePort.sendPort,
        'members': members,
        'regionalPartyAverages': regionalPartyAverages,
        'voterInterests': voterInterests,
        'dominantParties': dominantParties,
      },
    );
  }

  /// Isolate 진입점 (여러 멤버를 루프 돌며 계산)
  static void _batchCalculationEntry(Map<String, dynamic> message) {
    final SendPort sendPort = message['sendPort'];
    final List<Member> members = message['members'];
    final Map<String, Map<String, double>> regionalPartyAverages = message['regionalPartyAverages'];
    final Map<String, double> voterInterests = message['voterInterests'];
    final Map<String, String?> dominantParties = message['dominantParties'];

    for (var member in members) {
      // 실제 계산 로직 호출 (IsolateCalculations의 로직과 유사하게 구현 또는 호출)
      // 여기서는 설명을 위해 직접 계산 함수를 호출한다고 가정
      // Note: Isolate 내부에서는 static 함수만 호출 가능
      _doActualCalculation(member, regionalPartyAverages, voterInterests, dominantParties, sendPort);
    }
  }

  static void _doActualCalculation(
    Member member,
    Map<String, Map<String, double>> regionalPartyAverages,
    Map<String, double> voterInterests,
    Map<String, String?> dominantParties,
    SendPort sendPort,
  ) {
    final result = performMemberCalculation(
      member: member,
      regionalPartyAverages: regionalPartyAverages,
      voterInterests: voterInterests,
      dominantParties: dominantParties,
    );
    
    sendPort.send({
      'memberId': member.id,
      'electionPossibility': result.electionPossibility,
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
