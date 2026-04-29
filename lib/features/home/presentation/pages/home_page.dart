import 'package:cached_network_image/cached_network_image.dart';
import 'package:elecko26_new/core/utils/party_util.dart';
import 'package:elecko26_new/core/utils/image_util.dart';
import 'package:elecko26_new/features/home/presentation/widgets/search_view.dart';
import 'package:elecko26_new/features/home/presentation/widgets/comparison_view.dart';
import 'package:elecko26_new/features/home/presentation/widgets/integrated_news_view.dart';
import 'package:elecko26_new/features/home/presentation/widgets/home_dashboard_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/domain/usecases/member_usecases.dart';
import 'package:elecko26_new/domain/usecases/export_election_data_usecase.dart';
import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/features/auth/presentation/pages/auth_gate.dart';
import 'package:elecko26_new/features/auth/domain/entities/user.dart' as auth;
import 'package:elecko26_new/features/auth/domain/usecases/auth_usecases.dart';
import 'package:elecko26_new/features/home/presentation/pages/member_detail_page.dart';
import 'package:elecko26_new/features/map/presentation/pages/map_screen.dart';
import 'package:elecko26_new/features/home/presentation/widgets/member_card.dart';
import 'package:elecko26_new/features/voting/presentation/pages/polls_page.dart';
import 'package:elecko26_new/features/home/presentation/widgets/favorites_view.dart';
import 'package:elecko26_new/features/auth/domain/repositories/auth_repository.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:elecko26_new/core/widgets/lazy_indexed_stack.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final BehaviorSubject<List<Member>> _membersSubject =
      BehaviorSubject<List<Member>>();
  Stream<List<Member>> get _membersStream => _membersSubject.stream;
  final ValueNotifier<int> _favoriteCountNotifier = ValueNotifier<int>(0);
  Timer? _dataExportTimer;
  Timer? _uiRefreshTimer;
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  bool get _isLoading => _isLoadingNotifier.value;
  List<Member> _cachedMembers = [];
  Member? _selectedMember;
  auth.User? _currentUser;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<String>? _regionSubscription;
  StreamSubscription<auth.User?>? _authSubscription;

  // 검색 관련 상태

  // 비교 관련 상태

  // 유저 상단 설정 상태
  late final ValueNotifier<String> _userRegionNotifier =
      ValueNotifier<String>('전국');

  String get _userRegion => _userRegionNotifier.value;

  /// 지역 변경 처리
  void _onRegionChanged(String region) {
    _userRegionNotifier.value = region;
    // 지역 변경 시 멤버 목록 새로고침
    _refreshMembers();
  }

  /// 멤버 목록 새로고침
  Future<void> _refreshMembers() async {
    _isLoadingNotifier.value = true;

    try {
      // 현재 스트림을 새로고침
      _startMemberStream();

      // 잠시 대기 후 로딩 상태 해제
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _isLoadingNotifier.value = false;
      }
    } catch (e) {
      print('멤버 목록 새로고침 실패: $e');
      if (mounted) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  static const List<String> _regions = [
    '전국',
    '서울특별시',
    '부산광역시',
    '대구광역시',
    '인천광역시',
    '광주광역시',
    '대전광역시',
    '울산광역시',
    '세종특별자치시',
    '경기도',
    '강원도',
    '충청북도',
    '충청남도',
    '전북특별자치도',
    '전라남도',
    '경상북도',
    '경상남도',
    '제주특별자치도'
  ];

  void _showSettingsModal() {
    String tempSelectedRegion = _userRegion;

    // 모달 애니메이션 단축: 기본 300ms → 180ms
    final animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 130),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: animController,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
                  child: RepaintBoundary(
                    child: TabBarView(
                      children: [
                        _buildRegionSettingTab(
                          setModalState,
                          () => tempSelectedRegion,
                          (region) {
                            tempSelectedRegion = region;
                          },
                        ),
                        _buildFavoritesTab(),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextButton.icon(
                    onPressed: () => _showResetConfirmation(),
                    icon: const Icon(Icons.refresh, color: Colors.redAccent),
                    label: const Text(
                      '설정 및 데이터 초기화',
                      style: TextStyle(
                          color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.redAccent.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      // 모달 닫힌 후 컨트롤러 해제
      if (animController.isAnimating) animController.stop();
      animController.dispose();
    });
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
                _userRegionNotifier.value = '전국';
              });
              if (context.mounted) {
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('초기화', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionSettingTab(
    StateSetter setModalState,
    String Function() getTempSelectedRegion,
    ValueChanged<String> onRegionSelected,
  ) {
    return RepaintBoundary(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemExtent: 72, // 높이 고정으로 레이아웃 계산 최적화
        itemCount: _regions.length,
        itemBuilder: (context, index) {
          final region = _regions[index];
          final isSelected = getTempSelectedRegion() == region;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.05)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.lightGrey.withOpacity(0.5),
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
              onTap: () {
                // 투표탭과 동일하게 모달 내부 선택 상태를 먼저 갱신해 즉시 체크 표시
                setModalState(() {
                  onRegionSelected(region);
                });

                // 메인 화면도 즉시 반영
                _userRegionNotifier.value = region;

                // 체크 표시를 인식할 수 있도록 아주 짧게 유지 후 저장/닫기 처리 (100ms로 단축)
                Future.delayed(const Duration(milliseconds: 100), () async {
                  await sl<MemberRepository>().saveSelectedRegion(region);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                });
              },
            ),
          );
        },
      ),
    );
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
                Icon(Icons.star_outline,
                    size: 64, color: AppColors.grey.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  '즐겨찾기한 의원이 없습니다.',
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
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

  // 탭 인덱스 제어 (ValueNotifier 사용으로 리빌드 범위 최소화)
  late final ValueNotifier<int> _selectedIndexNotifier =
      ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _loadUserSettings();
    _startMemberStream();
    _triggerNesdcRefresh(isSilent: true);
    _startDataExportTimer();

    // 5분마다 UI 데이터 새로고침
    _uiRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _triggerNesdcRefresh(isSilent: true),
    );

    // 필수 이미지 미리 로딩 (캐싱)
    _precacheImages();

    // 지역 설정 변경 감지 구독
    _regionSubscription =
        sl<MemberRepository>().watchSelectedRegion().listen((region) {
      if (mounted) {
        _userRegionNotifier.value = region;
      }
    });


    // 인증 상태 변경 감지 구독 (실시간 로그아웃/로그인 대응)
    _authSubscription =
        sl<AuthRepository>().authStateChanges.listen((user) async {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
      if (user != null) {
        await sl<MemberRepository>().syncUserSettings();
        await _loadUserSettings();
      }
    });
  }

  Future<void> _loadUserSettings() async {
    try {
      final selectedRegion = await sl<MemberRepository>().getSelectedRegion();
      if (mounted) {
        _userRegionNotifier.value = selectedRegion ?? '전국';
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
      if (user != null) {
        await sl<MemberRepository>().syncUserSettings();
        await _loadUserSettings();
      }
    } catch (e) {
      debugPrint('[HomePage] Failed to load current user: $e');
    }
  }

  StreamSubscription<List<Member>>? _membersSubscription;

  void _startMemberStream() {
    try {
      _membersSubscription?.cancel();
      final stream = sl<WatchMembersUseCase>().call();
      _membersSubscription = stream.listen((members) {
        if (!_membersSubject.isClosed) {
          _membersSubject.add(members);
          // 직접 필드 업데이트 - setState 제거로 전체 재빌드 방지
          // StreamBuilder가 BehaviorSubject를 통해 자동으로 UI 갱신
          _cachedMembers = members;
          final count = members.where((m) => m.isFavorite).length;
          _favoriteCountNotifier.value = count;
        }
      });
    } catch (e) {
      debugPrint('[HomePage] Failed to start member stream: $e');
    }
  }

  void _stopMemberStream() {
    _membersSubscription?.cancel();
    _membersSubscription = null;
  }

  Future<void> _handleBottomNavTap(int index) async {
    // 투표탭(4)은 로그인 필수
    if (index == 4) {
      if (_currentUser == null) {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
        // 로그인 후 사용자 정보를 명시적으로 로드
        await _loadCurrentUser();
        if (!mounted) return;
        if (_currentUser == null) return;
      }
    }

    _selectedIndexNotifier.value = index;
    if (_selectedMember != null) {
      setState(() {
        _selectedMember = null;
      });
    }
  }

  Future<void> _triggerNesdcRefresh({bool isSilent = false}) async {
    if (!isSilent) {
      _isLoadingNotifier.value = true;
    }
    // 강제 갱신 트리거: 최신 후보자 JSON 및 시스템 데이터 스크랩
    try {
      await sl<MemberRepository>().refreshMembers();
      debugPrint('[Refresh] Data sync completed');
    } catch (e) {
      debugPrint('[Refresh] Data sync failed: $e');
    } finally {
      if (mounted && !isSilent) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  /// 1분마다 선거 데이터를 JSON으로 내보내고 GitHub에 저장
  void _startDataExportTimer() {
    // 첫 번째는 즉시 실행
    _exportElectionData();

    // 이후 1분마다 반복
    _dataExportTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        _exportElectionData();
      },
    );
  }

  /// 선거 데이터 내보내기
  Future<void> _exportElectionData() async {
    try {
      final exportUseCase = sl<ExportElectionDataUseCase>();
      final exportData = await exportUseCase.call();

      // 콘솔에 로그 출력
      debugPrint('[ElectionData] Exported at: ${exportData.exportedAt}');
      debugPrint(
          '[ElectionData] Members analyzed: ${exportData.metadata.membersAnalyzed}');
      debugPrint(
          '[ElectionData] Average possibility: ${(exportData.metadata.averageElectionPossibility * 100).toStringAsFixed(1)}%');

      // JSON 생성 및 로컬 저장 (향후 GitHub Pages에서 서빙)
      // TODO: GitHub API 또는 파일 시스템에 저장
    } catch (e) {
      debugPrint('[ElectionData] Export failed: $e');
    }
  }

  void _precacheImages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 주요 자산 미리 캐싱
      precacheImage(const AssetImage('assets/images/election_icon.png'), context);

      // 정당 로고 미리 캐싱
      final parties = ['더불어민주당', '국민의힘', '정의당', '진보당', '조국혁신당', '개혁신당', '기본소득당'];
      for (final party in parties) {
        final logo = PartyUtil.getPartyLogoUrl(party);
        if (logo.isNotEmpty) {
          precacheImage(AssetImage(logo), context);
        }
      }

      // 상위 후보자 이미지 일부 사전 캐싱
      if (_cachedMembers.isNotEmpty) {
        for (final member in _cachedMembers.take(20)) {
          if (member.imageUrl.isNotEmpty) {
            precacheImage(
              CachedNetworkImageProvider(
                ImageUtil.getProxyUrl(member.imageUrl, width: 120, height: 120),
              ),
              context,
            );
          }
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || kIsWeb) return;

    if (state == AppLifecycleState.resumed) {
      _startMemberStream();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopMemberStream();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dataExportTimer?.cancel();
    _uiRefreshTimer?.cancel();
    _regionSubscription?.cancel();
    _authSubscription?.cancel();
    _membersSubscription?.cancel();
    _searchController.dispose();
    _userRegionNotifier.dispose();
    _isLoadingNotifier.dispose();
    _selectedIndexNotifier.dispose();
    _membersSubject.close();
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
        canPop: !kIsWeb && _selectedMember == null && _selectedIndexNotifier.value == 0,
        onPopInvoked: (bool didPop) {
          if (didPop) return;

          if (_selectedMember != null) {
            setState(() {
              _selectedMember = null;
            });
            return;
          }

          if (_selectedIndexNotifier.value != 0) {
            _selectedIndexNotifier.value = 0;
            return;
          }

          // On the web, we don't want to pop the last route, which might close the tab.
          if (kIsWeb) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('메인 화면입니다.'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
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
            onRefresh: () => _triggerNesdcRefresh(isSilent: false),
            onMemberSelected: (m) => setState(() => _selectedMember = m),
            onNavigateToSearch: () => _selectedIndexNotifier.value = 1,
            onRegionChanged: (newRegion) async {
              _userRegionNotifier.value = newRegion;
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
            return LazyIndexedStack(
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
                onBack: () => setState(() => _selectedMember = null),
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
              label: '관심',
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
