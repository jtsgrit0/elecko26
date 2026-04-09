import 'package:elecko26/features/home/presentation/widgets/search_view.dart';
import 'package:elecko26/features/home/presentation/widgets/comparison_view.dart';
import 'package:elecko26/features/home/presentation/widgets/integrated_news_view.dart';
import 'package:elecko26/features/home/presentation/widgets/home_dashboard_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:elecko26/core/utils/image_util.dart';
import 'package:elecko26/core/theme/app_theme.dart';
import 'package:elecko26/domain/entities/analysis_result.dart';
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/domain/repositories/member_repository.dart';
import 'package:elecko26/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:elecko26/domain/usecases/member_usecases.dart';
import 'package:elecko26/domain/usecases/export_election_data_usecase.dart';
import 'package:elecko26/app/injection_container.dart';
import 'package:elecko26/features/auth/presentation/pages/auth_gate.dart';
import 'package:elecko26/features/auth/domain/entities/user.dart' as auth;
import 'package:elecko26/features/auth/domain/usecases/auth_usecases.dart';
import 'package:elecko26/features/home/presentation/pages/member_detail_page.dart';
import 'package:elecko26/features/map/presentation/pages/map_screen.dart';
import 'package:elecko26/core/utils/party_util.dart';
import 'package:elecko26/core/utils/utility_functions.dart';
import 'package:elecko26/features/home/presentation/widgets/member_card.dart';
import 'package:elecko26/features/voting/presentation/pages/polls_page.dart';
import 'package:elecko26/features/home/presentation/widgets/favorites_view.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late Stream<List<Member>> _membersStream;
  Timer? _dataExportTimer;
  Timer? _uiRefreshTimer;
  bool _isLoading = false;
  List<Member> _cachedMembers = [];
  Member? _selectedMember;
  auth.User? _currentUser;
  final TextEditingController _searchController = TextEditingController();
  
  // 검색 관련 상태
  
  // 비교 관련 상태
  
  // 유저 상단 설정 상태
  String _userRegion = '전국';
  
  static const List<String> _regions = [
    '전국', '서울특별시', '부산광역시', '대구광역시', '인천광역시', '광주광역시', '대전광역시', '울산광역시',
    '세종특별자치시', '경기도', '강원도', '충청북도', '충청남도', '전라북도', '전라남도', '경상북도', '경상남도', '제주특별자치도'
  ];
  static const Map<String, List<String>> _categories = {
    '전체': ['전체', '도지사', '광역시장', '특별시장', '특별자치도지사', '시장', '군수', '구청장', '도의원', '시의원', '구의원', '군의원'],
    '광역': ['전체', '도지사', '광역시장', '특별시장', '특별자치도지사'],
    '기초': ['전체', '시장', '군수', '구청장'],
    '의회': ['전체', '도의원', '시의원', '구의원', '군의원'],
  };

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.grey,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: '지역 설정', icon: Icon(Icons.location_on_outlined)),
                  Tab(text: '즐겨찾기', icon: Icon(Icons.star_outline)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildRegionSettingTab(),
                    _buildFavoritesTab(),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextButton.icon(
                  onPressed: () => _showResetConfirmation(),
                  icon: const Icon(Icons.refresh, color: Colors.redAccent),
                  label: const Text(
                    '설정 및 데이터 초기화',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.redAccent.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('설정 초기화'),
        content: const Text('지역 설정과 즐겨찾기 목록이 모두 삭제됩니다. 정말로 초기화하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await sl<MemberRepository>().resetSettings();
              setState(() {
                _userRegion = '전국';
              });
              if (mounted) {
                Navigator.pop(context); // 팝업 닫기
                Navigator.pop(context); // 설정 모달 닫기
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('모든 설정이 초기화되었습니다.'),
                    backgroundColor: Colors.black87,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('초기화', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionSettingTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _regions.length,
      itemBuilder: (context, index) {
        final region = _regions[index];
        final isSelected = _userRegion == region;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.lightGrey.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            title: Text(
              region,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected ? AppColors.primary : AppColors.dark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected 
              ? const Icon(Icons.check_circle, color: AppColors.primary)
              : null,
            onTap: () async {
              setState(() {
                _userRegion = region;
              });
              await sl<MemberRepository>().saveSelectedRegion(region);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$region으로 지역이 설정되었습니다.'),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  List<Member> _getFilteredMembers(List<Member> members) {
    if (_userRegion == '전국') return members;
    
    // 지역명 정규화 (예: '서울특별시' -> '서울', '경기도' -> '경기')
    String shortRegion = _userRegion.substring(0, 2);
    // 특수지역 대응
    if (_userRegion == '세종특별자치시') shortRegion = '세종';
    if (_userRegion == '제주특별자치도') shortRegion = '제주';
    if (_userRegion == '전북특별자치도') shortRegion = '전북';

    return members.where((m) => m.district.contains(shortRegion)).toList();
  }

  Widget _buildFavoritesTab() {
    return StreamBuilder<List<Member>>(
      stream: _membersStream,
      builder: (context, snapshot) {
        final members = snapshot.data ?? _cachedMembers;
        final favorites = members.where((m) => m.isFavorite).toList();
        
        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_outline, size: 64, color: AppColors.grey.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  '즐겨찾기한 의원이 없습니다.',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final member = favorites[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MemberCard(
                key: ValueKey(member.id),
                member: member,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedMember = member);
                },
              ),
            );
          },
        );
      },
    );
  }
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _loadUserSettings();
    _startMemberStream();
    _triggerNesdcRefresh(isSilent: true);
    _startDataExportTimer();
    
    // 5분마다 UI 데이터 새로고침 (백그라운드에서 조용히, Isolate 최적화 적용됨)
    _uiRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _triggerNesdcRefresh(isSilent: true),
    );
  }

  Future<void> _loadUserSettings() async {
    try {
      final selectedRegion = await sl<MemberRepository>().getSelectedRegion();
      if (mounted) {
        setState(() {
          _userRegion = selectedRegion;
        });
      }
    } catch (e) {
      debugPrint('[HomePage] Failed to load user settings: $e');
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await sl<GetCurrentUserUseCase>().execute();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      debugPrint('[HomePage] Failed to load current user: $e');
    }
  }

  void _startMemberStream() {
    try {
      final stream = sl<WatchMembersUseCase>().call().asBroadcastStream();
      _membersStream = stream;
      
      // 스트림을 구독하여 로컬 캐시를 최신으로 유지 (UI 반응성 강화)
      stream.listen((members) {
        if (mounted) {
          setState(() {
            _cachedMembers = members;
          });
        }
      });
    } catch (e) {
      debugPrint('[HomePage] Failed to start member stream: $e');
      _membersStream = const Stream<List<Member>>.empty();
    }
  }


  void _stopMemberStream() {
    _membersStream = Stream<List<Member>>.empty();
  }

  Future<void> _handleBottomNavTap(int index) async {
    if (index == 5 || index == 6) {
      if (_currentUser == null) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
        await _loadCurrentUser();
        if (_currentUser != null) {
          // 로그인 성공 시 설정을 클라우드에서 동기화
          await sl<MemberRepository>().syncUserSettings();
          await _loadUserSettings(); // UI 상태 업데이트
        }
        if (!mounted) {
          return;
        }
        if (result != true || _currentUser == null) {
          return;
        }
      }
    }

    setState(() {
      _selectedIndex = index;
      _selectedMember = null;
    });
  }

  Future<void> _triggerNesdcRefresh({bool isSilent = false}) async {
    if (!isSilent) setState(() { _isLoading = true; });
    // 강제 갱신 트리거: 최신 후보자 JSON 및 시스템 데이터 스크랩
    try {
      await sl<MemberRepository>().refreshMembers();
      debugPrint('[Refresh] Data sync completed');
    } catch (e) {
      debugPrint('[Refresh] Data sync failed: $e');
    } finally {
      if (mounted && !isSilent) setState(() { _isLoading = false; });
    }
  }

  /// 1분마다 선거 데이터를 JSON으로 내보내고 GitHub에 저장
  void _startDataExportTimer() {
    // 첫 번째는 즉시 실행
    _exportElectionData();
    
    // 이후 1분마다 반복
    _dataExportTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _exportElectionData(),
    );
  }

  /// 선거 데이터 내보내기
  Future<void> _exportElectionData() async {
    try {
      final exportUseCase = sl<ExportElectionDataUseCase>();
      final exportData = await exportUseCase.call();
      
      // 콘솔에 로그 출력
      debugPrint('[ElectionData] Exported at: ${exportData.exportedAt}');
      debugPrint('[ElectionData] Members analyzed: ${exportData.metadata.membersAnalyzed}');
      debugPrint('[ElectionData] Average possibility: ${(exportData.metadata.averageElectionPossibility * 100).toStringAsFixed(1)}%');
      
      // JSON 생성 및 로컬 저장 (향후 GitHub Pages에서 서빙)
      // TODO: GitHub API 또는 파일 시스템에 저장
    } catch (e) {
      debugPrint('[ElectionData] Export failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      setState(_startMemberStream);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      setState(_stopMemberStream);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dataExportTimer?.cancel();
    _uiRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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
      body: PopScope(
        canPop: _selectedMember == null,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (!didPop && _selectedMember != null) {
            setState(() {
              _selectedMember = null;
            });
          }
        },
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // 바디 위젯 필터リング
  Widget _buildBody() {
    if (_selectedMember != null) {
      return MemberDetailPage(
        member: _selectedMember!,
        onBack: () => setState(() => _selectedMember = null),
      );
    }
    
    return IndexedStack(
      index: _selectedIndex,
      children: [
        HomeDashboardView(
          isLoading: _isLoading,
          membersStream: _membersStream,
          cachedMembers: _cachedMembers,
          userRegion: _userRegion,
          onRefresh: () => _triggerNesdcRefresh(isSilent: false),
          onMemberSelected: (m) => setState(() => _selectedMember = m),
          onNavigateToSearch: () => setState(() => _selectedIndex = 1),
        ),
        SearchView(
          membersStream: _membersStream,
          cachedMembers: _cachedMembers,
          userRegion: _userRegion,
          onMemberSelected: (m) => setState(() => _selectedMember = m),
        ),
        _buildFavoritesPage(),
        IntegratedNewsView(
          membersStream: _membersStream,
          cachedMembers: _cachedMembers,
        ),
        ComparisonView(
          membersStream: _membersStream,
          cachedMembers: _cachedMembers,
          onMemberSelected: (m) => setState(() => _selectedMember = m),
        ),
        _buildVotingGatewayPage(),
        _buildProfileGatewayPage(),
      ],
    );
  }

  Widget _buildVotingGatewayPage() {
    if (_currentUser != null) {
      return PollsPage(currentUser: _currentUser!);
    }

    return AuthGate(
      isEmbedded: true,
      onSuccess: () => _loadCurrentUser(),
    );
  }

  Widget _buildProfileGatewayPage() {
    if (_currentUser == null) {
      return AuthGate(
        isEmbedded: true,
        onSuccess: () => _loadCurrentUser(),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFFF2E7DA),
                    child: Icon(Icons.person_rounded, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentUser!.displayName ?? '내 프로필',
                    style: AppTextStyles.headline4,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentUser!.email ?? '',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () async {
                      await sl<SignOutUseCase>().execute();
                      await _loadCurrentUser();
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _selectedIndex = 0;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('로그아웃되었습니다.')),
                      );
                    },
                    child: const Text('로그아웃'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 홈 대시보드

  // 검색 페이지

  // 검색 필드





  // 검색 결과 목록

  // 즐겨찾기 페이지
  Widget _buildFavoritesPage() {
    return FavoritesView(
      membersStream: _membersStream,
      cachedMembers: _cachedMembers,
      onMemberSelected: (member) => setState(() => _selectedMember = member),
    );
  }

  // 비교 페이지

  // 비교 결과 화면



  // 커스텀 앱바
  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/election_icon.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '2026 지방선거 당선 예측기',
                            style: AppTextStyles.headline4.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '누가 적토마에 올라탈 것인가!',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.map,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 1), // 1px 간격
                  GestureDetector(
                    onTap: () => _showSettingsModal(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 1),
                  GestureDetector(
                    onTap: () async {
                      // if (!kIsWeb) {
                      //   await firebase.FirebaseAuth.instance.signOut();
                      // }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2026 지방선거 배너

  // 주요 통계




  // 의원 목록 섹션

  // 통합 뉴스 피드 페이지

  // 하단 네비게이션 바
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.grey,
      backgroundColor: AppColors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: '검색',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star),
          label: '즐겨찾기',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.newspaper),
          label: '뉴스',
        ),
        BottomNavigationBarItem(
          icon: Text(
            'VS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _selectedIndex == 4 ? AppColors.primary : AppColors.grey,
            ),
          ),
          label: '비교',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.poll),
          label: '투표',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '프로필',
        ),
      ],
      onTap: _handleBottomNavTap,
    );
  }

}

// 통계 카드 위젯


// 의원 카드 위젯
