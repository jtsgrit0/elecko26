import 'dart:async';
import 'package:flutter/foundation.dart';
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
import 'package:elecko26_new/data/datasources/local_storage_service.dart' as elecko;
import 'package:elecko26_new/features/home/presentation/pages/region_selection_screen.dart';
import 'package:elecko26_new/features/home/presentation/widgets/splash_screen.dart';

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
      home: InitialScreen(members: members),
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
    debugPrint('[InitialScreen] _initializeApp: 시작');
    
    // 타임아웃 설정: 5초 이상 걸리면 강제로 지역 선택 화면으로 이동
    final timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        debugPrint('[InitialScreen] 초기화 타임아웃 -> 강제 화면 전환');
        _navigateToRegionSelection();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // 의존성 주입이 완료될 때까지 잠시 대기 (웹 환경 안정성 확보)
        await Future.delayed(const Duration(milliseconds: 500));
        
        final localService = di.sl<elecko.LocalStorageService>();
        final initialRegion = await localService.getSelectedRegion();

        timeoutTimer.cancel(); // 정상 완료 시 타이머 취소

        if (!mounted) return;

        if (initialRegion == null || initialRegion.isEmpty) {
          debugPrint('[InitialScreen] 지역 선택 정보 없음 -> 이동');
          _navigateToRegionSelection();
        } else {
          debugPrint('[InitialScreen] 기존 지역 ($initialRegion) -> 로딩 시작');
          _loadDataAndGoHome(context, initialRegion);
        }
      } catch (e) {
        timeoutTimer.cancel();
        debugPrint('[InitialScreen] 초기화 에러: $e');
        if (mounted) _navigateToRegionSelection();
      }
    });
  }

  void _navigateToRegionSelection() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (routeContext) => RegionSelectionScreen(
          onRegionSelected: (region) async {
            try {
              final localService = di.sl<elecko.LocalStorageService>();
              await localService.saveSelectedRegion(region);
            } catch (_) {}
            if (routeContext.mounted) {
              _loadDataAndGoHome(routeContext, region);
            }
          },
        ),
      ),
    );
  }

  Future<void> _loadDataAndGoHome(BuildContext context, String region) async {
    try {
      debugPrint('[InitialScreen] 데이터 로딩 시작 (지역: $region)');
      final members = await _getLoadedMembers();
      
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(members: members)),
        );
      }
    } catch (e) {
      debugPrint('[InitialScreen] 데이터 로딩 실패: $e');
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage(members: [])),
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
        if (districtMatchesRegion(m.district, selectedRegion)) {
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

    // 5. 당선 가능성 계산 시작
    final Map<String, double> calculatedPossibilities = {};

    if (primaryMembers.isNotEmpty) {
      if (kIsWeb) {
        // 웹 환경: 비동기 루프로 처리
        debugPrint('[InitialScreen] 웹 환경 계산 시작');
        for (int i = 0; i < primaryMembers.length; i++) {
          final result = performMemberCalculation(
            member: primaryMembers[i],
            regionalPartyAverages: regionalPartyAverages,
            voterInterests: voterInterests,
            dominantParties: dominantParties,
          );
          calculatedPossibilities[primaryMembers[i].id] = result.electionPossibility;
          if (i % 10 == 0) await Future.delayed(Duration.zero);
        }
      } else {
        // 모바일 환경: Isolate 전용 함수 호출 (격리됨)
        final results = await _calculatePrimaryMembersMobile(
          primaryMembers,
          regionalPartyAverages,
          voterInterests,
          dominantParties,
        );
        calculatedPossibilities.addAll(results);
      }
    }

    // 나머지 멤버는 백그라운드에서 처리 (Future로 비동기 실행)
    if (kIsWeb) {
      _calculateSecondaryMembersWeb(
        secondaryMembers,
        regionalPartyAverages,
        voterInterests,
        dominantParties,
      );
    } else {
      _calculateSecondaryMembersInBackground(
        secondaryMembers,
        regionalPartyAverages,
        voterInterests,
        dominantParties,
      );
    }

    // 업데이트된 리스트 반환
    return loadedMembers.map((m) {
      if (calculatedPossibilities.containsKey(m.id)) {
        return m.copyWith(electionPossibility: calculatedPossibilities[m.id]);
      }
      return m;
    }).toList();
  }

  /// 웹 환경 백그라운드 계산 (Isolate 미지원 대응)
  Future<void> _calculateSecondaryMembersWeb(
    List<Member> members,
    Map<String, Map<String, double>> regionalPartyAverages,
    Map<String, double> voterInterests,
    Map<String, String?> dominantParties,
  ) async {
    if (members.isEmpty) return;
    debugPrint('[InitialScreen] 웹 백그라운드 계산 시작 (${members.length}명)');
    for (int i = 0; i < members.length; i++) {
      performMemberCalculation(
        member: members[i],
        regionalPartyAverages: regionalPartyAverages,
        voterInterests: voterInterests,
        dominantParties: dominantParties,
      );
      // 20개마다 한 번씩 쉬어감 (UI 부하 최소화)
      if (i % 20 == 0) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    debugPrint('[InitialScreen] 웹 백그라운드 계산 완료');
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

  /// 모바일 전용 Isolate 계산 실행 (웹 에러 방지를 위해 격리됨)
  Future<Map<String, double>> _calculatePrimaryMembersMobile(
    List<Member> members,
    Map<String, Map<String, double>> regionalPartyAverages,
    Map<String, double> voterInterests,
    Map<String, String?> dominantParties,
  ) async {
    final Map<String, double> results = {};
    final ReceivePort receivePort = ReceivePort();

    await _calculateBatchInIsolate(
      members,
      regionalPartyAverages,
      voterInterests,
      dominantParties,
      receivePort,
    );

    int receivedCount = 0;
    try {
      await for (var message in receivePort
          .take(members.length)
          .timeout(const Duration(seconds: 10))) {
        results[message['memberId']] = message['electionPossibility'];
        receivedCount++;
        if (receivedCount >= members.length) break;
      }
    } catch (e) {
      debugPrint('[Main] Isolate calculation timeout or error: $e');
    } finally {
      receivePort.close();
    }
    return results;
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
