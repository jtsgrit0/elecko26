import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/features/auth/domain/entities/user.dart' as auth;
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/domain/usecases/member_usecases.dart';
import 'package:elecko26_new/domain/entities/analysis_result.dart';
import 'package:elecko26_new/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:elecko26_new/features/auth/presentation/pages/auth_gate.dart';
import 'package:elecko26_new/features/home/presentation/widgets/comparison_view.dart';
import 'package:elecko26_new/features/home/presentation/widgets/favorites_view.dart';
import 'package:elecko26_new/features/home/presentation/widgets/home_dashboard_view.dart';
import 'package:elecko26_new/features/home/presentation/widgets/integrated_news_view.dart';
import 'package:elecko26_new/features/home/presentation/widgets/search_view.dart';
import 'package:elecko26_new/features/map/presentation/pages/map_screen.dart';
import 'package:elecko26_new/features/voting/presentation/pages/polls_page.dart';
import 'member_detail_page.dart';

class HomePage extends StatefulWidget {
  final List<Member> members;

  const HomePage({Key? key, required this.members}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ValueNotifier<int> _selectedIndexNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String> _userRegionNotifier = ValueNotifier<String>('전국');
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> _favoriteCountNotifier = ValueNotifier<int>(0);

  Stream<List<Member>> get _membersStream =>
      sl<MemberRepository>().watchMembers();

  List<Member> _cachedMembers = [];
  Map<String, AnalysisResult> _analysisResults = {};
  StreamController<Map<String, AnalysisResult>>? _analysisStreamController;

  Member? _selectedMember;
  auth.User? _currentUser;
  StreamSubscription? _authSubscription;
  StreamSubscription? _membersSubscription;
  StreamSubscription? _regionSubscription;
  StreamSubscription? _analysisSubscription;

  @override
  void initState() {
    super.initState();
    _cachedMembers = widget.members;

    _updateFavoriteCount(_cachedMembers);
    _initializeListeners();
    _initializeAnalysisStream();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _membersSubscription?.cancel();
    _regionSubscription?.cancel();
    _analysisSubscription?.cancel();
    _analysisStreamController?.close();
    _selectedIndexNotifier.dispose();
    _userRegionNotifier.dispose();
    _isLoadingNotifier.dispose();
    _favoriteCountNotifier.dispose();
    super.dispose();
  }

  Future<void> _initializeListeners() async {
    final memberRepository = sl<MemberRepository>();

    _membersSubscription = memberRepository.watchMembers().listen((members) {
      if (mounted) {
        setState(() {
          _cachedMembers = members;
        });
        _updateFavoriteCount(members);
      }
    });

    _regionSubscription =
        memberRepository.watchSelectedRegion().listen((region) {
      if (mounted) {
        _userRegionNotifier.value =
            (region != null && region.isNotEmpty) ? region : '전국';
      }
    });

    _authSubscription =
        memberRepository.watchCurrentUser().listen((auth.User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  void _initializeAnalysisStream() {
    _analysisStreamController =
        StreamController<Map<String, AnalysisResult>>.broadcast();
    _analysisSubscription = _allMembersAnalysisTicker().listen(
      (results) {
        if (mounted) {
          setState(() {
            _analysisResults = results;
          });
          _analysisStreamController?.add(results);
        }
      },
      onError: (e) {
        if (kDebugMode) {
          print("Error in analysis stream: $e");
        }
      },
    );
  }

  Stream<Map<String, AnalysisResult>> _allMembersAnalysisTicker() async* {
    final useCase = sl<CalculateElectionPossibilityUseCase>();
    while (true) {
      if (_cachedMembers.isNotEmpty) {
        final newResults = Map<String, AnalysisResult>.from(_analysisResults);
        for (final member in _cachedMembers) {
          try {
            final result = await useCase.call(member.id);
            newResults[member.id] = result;
          } catch (e) {
            if (!newResults.containsKey(member.id)) {
              newResults[member.id] = AnalysisResult.fallback(
                member.electionPossibility,
              );
            }
          }
        }
        yield newResults;
      }
      await Future.delayed(const Duration(minutes: 1));
    }
  }

  void _updateFavoriteCount(List<Member> members) {
    final count = members.where((m) => m.isFavorite).length;
    _favoriteCountNotifier.value = count;
  }

  Future<void> _updateAnalysisForMember(String memberId) async {
    final useCase = sl<CalculateElectionPossibilityUseCase>();
    try {
      final result = await useCase.call(memberId);
      if (mounted) {
        setState(() {
          _analysisResults[memberId] = result;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error updating analysis for member $memberId: $e");
      }
    }
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '설정',
              style: AppTextStyles.headline4,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('관심 지역 변경'),
              subtitle: ValueListenableBuilder<String>(
                valueListenable: _userRegionNotifier,
                builder: (context, region, _) => Text('현재: $region'),
              ),
              onTap: () {
                Navigator.pop(context);
                _selectedIndexNotifier.value = 0; // 홈으로 이동
              },
            ),
            const Divider(),
            if (_currentUser != null)
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('로그아웃',
                    style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  await sl<MemberRepository>().logout();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login, color: AppColors.primary),
                title: const Text('로그인/회원가입'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuthGate()),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBottomNavTap(int index) async {
    // 투표(4) 및 관심후보(5) 탭은 로그인 필수
    if (index == 4 || index == 5) {
      if (_currentUser == null) {
        final success = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
        // AuthGate에서 로그인 성공 시 true를 반환.
        // 사용자가 성공적으로 로그인하면 해당 탭으로 이동합니다.
        if (success == true) {
          _selectedIndexNotifier.value = index;
        }
        // 로그인하지 않았거나 실패한 경우, 탭 전환을 하지 않고 현재 탭에 머무릅니다.
        return;
      }
    }
    _selectedIndexNotifier.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedMember == null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: _buildAppBar(),
            )
          : null, // 상세 페이지는 자체 AppBar 사용
      body: WillPopScope(
        onWillPop: () async {
          if (_selectedMember != null) {
            setState(() => _selectedMember = null);
            return false; // 뒤로가기 방지, 내부적으로 처리
          } else if (_selectedIndexNotifier.value != 0) {
            _selectedIndexNotifier.value = 0;
            return false; // 뒤로가기 방지, 내부적으로 처리
          }
          return !kIsWeb; // 웹이 아닌 경우에만 뒤로가기 허용
        },
        child: _buildBody(),
      ),
      bottomNavigationBar:
          _selectedMember == null ? _buildBottomNavBar() : null,
    );
  }

  List<Widget> _buildTabWidgets() {
    return [
      // 0: 대시보드
      ValueListenableBuilder<String>(
        valueListenable: _userRegionNotifier,
        builder: (context, region, _) => ValueListenableBuilder<bool>(
          valueListenable: _isLoadingNotifier,
          builder: (context, isLoading, _) => HomeDashboardView(
            isLoading: isLoading,
            membersStream: _membersStream,
            cachedMembers: _cachedMembers,
            userRegion: region,
            onRefresh: () async {
              await sl<MemberRepository>().refreshMembers();
            },
            onMemberSelected: (m) => setState(() => _selectedMember = m),
            onNavigateToSearch: () => _selectedIndexNotifier.value = 1,
            onRegionChanged: (newRegion) async {
              setState(() {
                _userRegionNotifier.value = newRegion;
              });
              await sl<MemberRepository>().saveSelectedRegion(newRegion);
            },
          ),
        ),
      ),
      // 1: 검색
      ValueListenableBuilder<String>(
        valueListenable: _userRegionNotifier,
        builder: (context, region, _) => SearchView(
          membersStream: _membersStream,
          cachedMembers: _cachedMembers,
          userRegion: region,
          onMemberSelected: (m) => setState(() => _selectedMember = m),
        ),
      ),
      // 2: 비교
      ComparisonView(
        membersStream: _membersStream,
        cachedMembers: _cachedMembers,
        onMemberSelected: (m) => setState(() => _selectedMember = m),
      ),
      // 3: 뉴스
      IntegratedNewsView(
        membersStream: _membersStream,
        cachedMembers: _cachedMembers,
      ),
      // 4: 투표
      PollsPage(
        currentUser: _currentUser ??
            auth.User(
              id: 'guest',
              provider: auth.AuthProvider.anonymous,
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
            ),
      ),
      // 5: 즐겨찾기
      FavoritesView(
        key: const ValueKey('favorites_view'),
        membersStream: _membersStream,
        cachedMembers: _cachedMembers,
        onMemberSelected: (m) => setState(() => _selectedMember = m),
      ),
      // 6: 지도
      MapScreen(
        selectedIndexNotifier: _selectedIndexNotifier,
        tabIndex: 6,
      ),
    ];
  }

  Widget _buildBody() {
    final tabWidgets = _buildTabWidgets();

    return Stack(
      children: [
        // 메인 탭 화면 (항상 하단에 유지하여 상태 및 스크롤 보존)
        ValueListenableBuilder<int>(
          valueListenable: _selectedIndexNotifier,
          builder: (context, index, _) {
            return IndexedStack(
              index: index,
              children: tabWidgets,
            );
          },
        ),
        // 상세 페이지 (오버레이 형식으로 표시하여 돌아가기 시 탭 화면이 즉시 나타남)
        if (_selectedMember != null)
          Positioned.fill(
            child: Container(
              color: AppColors.white,
              child: MemberDetailPage(
                member: _selectedMember!,
                onBack: () async {
                  await _updateAnalysisForMember(_selectedMember!.id);
                  if (mounted) {
                    setState(() => _selectedMember = null);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      title: Row(
        children: [
          Image.asset(
            'assets/images/election_icon.png',
            height: 32,
          ),
          const SizedBox(width: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '2026 당예기',
                style: AppTextStyles.headline4.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              _buildDDayBadge(),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  '누가 적토마에 올라탈 것인가!',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: AppColors.dark),
          onPressed: _showSettingsModal,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.grey, size: 18),
                      const SizedBox(width: 4),
                      ValueListenableBuilder<String>(
                        valueListenable: _userRegionNotifier,
                        builder: (context, region, _) => Text(
                          region,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.dark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.primary, size: 18),
                    const SizedBox(width: 4),
                    ValueListenableBuilder<int>(
                      valueListenable: _favoriteCountNotifier,
                      builder: (context, count, _) => Text(
                        '$count',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDDayBadge() {
    final electionDate = DateTime(2026, 6, 3);
    final now = DateTime.now();
    final difference =
        electionDate.difference(DateTime(now.year, now.month, now.day)).inDays;

    String dDayText;
    Color badgeColor;

    if (difference == 0) {
      dDayText = 'D-Day';
      badgeColor = AppColors.error;
    } else if (difference > 0) {
      dDayText = 'D-$difference';
      badgeColor = AppColors.primary;
    } else {
      dDayText = 'D+${difference.abs()}';
      badgeColor = AppColors.mediumGray;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        dDayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return ValueListenableBuilder<int>(
      valueListenable: _selectedIndexNotifier,
      builder: (context, index, _) => Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: _handleBottomNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.grey,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              activeIcon: Icon(Icons.search, weight: 700),
              label: '검색',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.compare_arrows),
              activeIcon: Icon(Icons.compare_arrows, weight: 700),
              label: '비교',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: '뉴스',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.how_to_vote_outlined),
              activeIcon: Icon(Icons.how_to_vote),
              label: '투표',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_outline),
              activeIcon: Icon(Icons.star),
              label: '관심후보',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: '지도',
            ),
          ],
        ),
      ),
    );
  }
}
