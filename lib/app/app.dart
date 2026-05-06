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
import 'package:elecko26_new/data/datasources/local_storage_service.dart'
    as elecko;
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

    // 타임아웃: 어떤 경우에도 10초 후에는 지역 선택으로 이동 (디버깅을 위해 늘림)
    final timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        debugPrint('[InitialScreen] 초기화 강제 타임아웃 발생');
        _navigateToRegionSelection();
      }
    });

    try {
      // 프레임 렌더링을 기다리지 않고 즉시 의존성 확인 시도
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('[InitialScreen] 의존성 확인 시도');

      final localService = di.sl<elecko.LocalStorageService>();
      final initialRegion = await localService.getSelectedRegion();
      debugPrint('[InitialScreen] 초기 지역: $initialRegion');

      timeoutTimer.cancel();
      if (!mounted) return;

      if (initialRegion != null && initialRegion.isNotEmpty) {
        debugPrint('[InitialScreen] _loadDataAndGoHome 호출');
        _loadDataAndGoHome(context, initialRegion);
      } else {
        debugPrint('[InitialScreen] _navigateToRegionSelection 호출');
        _navigateToRegionSelection();
      }
    } catch (e) {
      timeoutTimer.cancel();
      debugPrint('[InitialScreen] 초기화 에러: $e');
      if (mounted) _navigateToRegionSelection();
    }
    debugPrint('[InitialScreen] _initializeApp: 종료');
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
          MaterialPageRoute(
              builder: (_) =>
                  HomePage(members: members, initialRegion: region)),
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
    debugPrint('[InitialScreen] _getLoadedMembers: 시작');
    final getMembersUseCase = di.sl<GetMembersUseCase>();
    final historicalRepository = di.sl<HistoricalElectionRepository>();
    final localService = di.sl<elecko.LocalStorageService>();

    // 1. 기본 멤버 데이터 로드
    debugPrint('[InitialScreen] 멤버 데이터 로드 시도');
    List<Member> loadedMembers = await getMembersUseCase.call();
    if (loadedMembers.isEmpty) {
      debugPrint('[InitialScreen] 로드된 멤버 데이터 없음');
      return [];
    }
    debugPrint('[InitialScreen] 멤버 데이터 로드 완료: ${loadedMembers.length}명');

    // 2. 선택된 지역 확인
    debugPrint('[InitialScreen] 선택된 지역 확인 시도');
    final selectedRegion = await localService.getSelectedRegion();
    debugPrint('[InitialScreen] 선택된 지역: $selectedRegion');

    // 3. 지역별 통계 데이터 미리 로드 (계산에 필요)
    debugPrint('[InitialScreen] 지역별 통계 데이터 로드 시도');

    final Map<String, Map<String, double>> regionalPartyAverages = {};
    final Map<String, double> voterInterests = {};
    final Map<String, String?> dominantParties = {};

    // 선택된 지역이 있을 경우, 해당 지역의 데이터만 미리 로드
    if (selectedRegion != null &&
        selectedRegion.isNotEmpty &&
        selectedRegion != '전국') {
      regionalPartyAverages[selectedRegion] =
          await historicalRepository.getRegionalPartyAverages(selectedRegion);
      voterInterests[selectedRegion] =
          await historicalRepository.getVoterInterest(selectedRegion);
      dominantParties[selectedRegion] =
          await historicalRepository.getDominantParty(selectedRegion);
      debugPrint('[InitialScreen] 선택 지역 통계 데이터 로드 완료: $selectedRegion');
    } else {
      debugPrint('[InitialScreen] 선택된 지역 없음. 통계 데이터 로드 건너뜀.');
    }

    // 4. 우선순위 설정 (선택된 지역의 멤버를 먼저 계산)
    List<Member> primaryMembers = [];
    List<Member> secondaryMembers = [];

    if (selectedRegion != null &&
        selectedRegion.isNotEmpty &&
        selectedRegion != '전국') {
      for (var m in loadedMembers) {
        if (districtMatchesRegion(m.district, selectedRegion)) {
          primaryMembers.add(m);
        } else {
          secondaryMembers.add(m);
        }
      }
      debugPrint('[InitialScreen] 지역 기반 우선순위 설정 완료');
    } else {
      // 선택된 지역이 없으면, 모든 멤버를 secondary로 설정하여 계산을 지연
      secondaryMembers = List.from(loadedMembers);
      debugPrint('[InitialScreen] 기본 설정: 모든 멤버를 secondary로 설정');
    }

    // 5. 당선 가능성 계산 시작
    final Map<String, double> calculatedPossibilities = {};

    if (primaryMembers.isNotEmpty) {
      debugPrint('[InitialScreen] 우선순위 멤버 계산 시작 (${primaryMembers.length}명)');
      for (int i = 0; i < primaryMembers.length; i++) {
        final result = performMemberCalculation(
          member: primaryMembers[i],
          regionalPartyAverages: regionalPartyAverages,
          voterInterests: voterInterests,
          dominantParties: dominantParties,
        );
        calculatedPossibilities[primaryMembers[i].id] =
            result.electionPossibility;

        // 10명마다 UI 프레임 양보 (웹 멈춤 방지)
        if (i % 10 == 0) await Future.delayed(Duration.zero);
      }
      debugPrint('[InitialScreen] 우선순위 멤버 계산 완료');
    }

    // 나머지 멤버는 백그라운드에서 처리 (비동기 루프)
    // 주의: 현재 _calculateSecondaryMembersWeb는 모든 지역 데이터를 필요로 함.
    // 추후 이 부분도 최적화가 필요할 수 있음.
    debugPrint('[InitialScreen] 백그라운드 멤버 계산 시작');
    // _calculateSecondaryMembersWeb(
    //   secondaryMembers,
    //   regionalPartyAverages,
    //   voterInterests,
    //   dominantParties,
    // );
    debugPrint('[InitialScreen] 백그라운드 멤버 계산은 현재 비활성화됨.');

    // 업데이트된 리스트 반환
    debugPrint('[InitialScreen] _getLoadedMembers: 종료');
    return loadedMembers.map((m) {
      if (calculatedPossibilities.containsKey(m.id)) {
        return m.copyWith(electionPossibility: calculatedPossibilities[m.id]);
      }
      return m;
    }).toList();
  }

  /// 백그라운드 계산 (Isolate 없이 비동기 루프로 처리)
  Future<void> _calculateSecondaryMembersWeb(
    List<Member> members,
    Map<String, Map<String, double>> regionalPartyAverages,
    Map<String, double> voterInterests,
    Map<String, String?> dominantParties,
  ) async {
    if (members.isEmpty) return;
    debugPrint('[InitialScreen] 백그라운드 계산 시작 (${members.length}명)');
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
    debugPrint('[InitialScreen] 백그라운드 계산 완료');
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
