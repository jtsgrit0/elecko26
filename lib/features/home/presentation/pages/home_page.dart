import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_application_1/core/utils/image_util.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/domain/entities/analysis_result.dart';
import 'package:flutter_application_1/domain/entities/member.dart';
import 'package:flutter_application_1/domain/repositories/member_repository.dart';
import 'package:flutter_application_1/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:flutter_application_1/domain/usecases/member_usecases.dart';
import 'package:flutter_application_1/domain/usecases/export_election_data_usecase.dart';
import 'package:flutter_application_1/app/injection_container.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/auth_gate.dart';
import 'package:flutter_application_1/features/home/presentation/pages/member_detail_page.dart';
import 'package:flutter_application_1/features/map/presentation/pages/map_screen.dart';
import 'package:flutter_application_1/features/auth/domain/entities/user.dart' as auth;
import 'package:flutter_application_1/features/voting/presentation/pages/polls_page.dart';
import 'package:flutter_application_1/features/profile/presentation/pages/profile_page.dart';
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
  List<_TopMember> _cachedTop3 = [];
  List<_TopMember> _cachedRanked = [];
  Member? _selectedMember;
  
  // 검색 관련 상태
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // 비교 관련 상태
  final Set<String> _selectedCompareIds = {};
  
  // 유저 상단 설정 상태
  String _userRegion = '전국';
  
  static const List<String> _regions = [
    '전국', '서울특별시', '부산광역시', '대구광역시', '인천광역시', '광주광역시', '대전광역시', '울산광역시',
    '세종특별자치시', '경기도', '강원도', '충청북도', '충청남도', '전라북도', '전라남도', '경상북도', '경상남도', '제주특별자치도'
  ];

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
              child: _MemberCard(
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
    _loadUserSettings();
    _startMemberStream();
    _triggerNesdcRefresh();
    _startDataExportTimer();
    
    // 1분마다 UI 데이터 새로고침
    _uiRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _triggerNesdcRefresh(),
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

  void _startMemberStream() {
    try {
      _membersStream = sl<WatchMembersUseCase>().call().asBroadcastStream();
    } catch (e) {
      debugPrint('[HomePage] Failed to start member stream: $e');
      _membersStream = const Stream<List<Member>>.empty();
    }
  }

  void _stopMemberStream() {
    _membersStream = Stream<List<Member>>.empty();
  }

  auth.User? _getAuthenticatedUser() {
    try {
      final currentUser = firebase.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return null;
      }

      auth.AuthProvider provider = auth.AuthProvider.anonymous;
      if (currentUser.providerData.isNotEmpty) {
        switch (currentUser.providerData.first.providerId) {
          case 'google.com':
            provider = auth.AuthProvider.google;
            break;
          case 'apple.com':
            provider = auth.AuthProvider.apple;
            break;
          case 'facebook.com':
            provider = auth.AuthProvider.facebook;
            break;
          case 'oidc.kakao':
            provider = auth.AuthProvider.kakao;
            break;
          case 'password':
            provider = auth.AuthProvider.email;
            break;
        }
      }

      return auth.User(
        id: currentUser.uid,
        email: currentUser.email,
        displayName: currentUser.displayName,
        photoUrl: currentUser.photoURL,
        provider: provider,
        createdAt: currentUser.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: currentUser.metadata.lastSignInTime ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleBottomNavTap(int index) async {
    if (index == 5) {
      final currentUser = _getAuthenticatedUser();
      if (currentUser == null) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
        if (!mounted) {
          return;
        }
      } else {
        setState(() {
          _selectedIndex = index;
          _selectedMember = null;
        });
      }
      return;
    }

    setState(() {
      _selectedIndex = index;
      _selectedMember = null;
    });
  }

  Future<void> _triggerNesdcRefresh() async {
    setState(() { _isLoading = true; });
    // 강제 갱신 트리거: 최신 후보자 JSON 및 시스템 데이터 스크랩
    try {
      await sl<MemberRepository>().refreshMembers();
      debugPrint('[Refresh] Data sync completed');
    } catch (e) {
      debugPrint('[Refresh] Data sync failed: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
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
    
    switch (_selectedIndex) {
      case 0:
        return _buildHomeDashboard();
      case 1:
        return _buildSearchPage();
      case 2:
        return _buildFavoritesPage();
      case 3:
        return _buildIntegratedNewsPage();
      case 4:
        return _buildComparisonPage();
      case 5:
        final currentUser = _getAuthenticatedUser();
        if (currentUser == null) {
          return const Center(child: Text('투표 기능은 로그인 후 이용할 수 있습니다.'));
        }
        return PollsPage(currentUser: currentUser);
      case 6:
        final currentUser = _getAuthenticatedUser();
        if (currentUser == null) {
          return const Center(child: Text('프로필 기능은 로그인 후 이용할 수 있습니다.'));
        }
        return ProfilePage(currentUser: currentUser);
      default:
        return _buildHomeDashboard();
    }
  }

  // 홈 대시보드
  Widget _buildHomeDashboard() {
    return RefreshIndicator(
      onRefresh: _triggerNesdcRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            if (!_isLoading) const SizedBox(height: 4),
            // 2026 지방선거 배너
            _buildElectionBanner(),
            const SizedBox(height: 24),
            // 주요 통계
            _buildStatistics(),
            const SizedBox(height: 24),
            // 의원 목록 요약
            _buildMemberListSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 검색 페이지
  Widget _buildSearchPage() {
    return Column(
      children: [
        _buildSearchField(),
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  // 검색 필드
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: '후보자 이름, 정당, 지역 등으로 검색',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  // 검색 결과 목록
  Widget _buildSearchResults() {
    return StreamBuilder<List<Member>>(
      stream: _membersStream,
      builder: (context, snapshot) {
        final allMembers = snapshot.data ?? _cachedMembers;
        if (allMembers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredMembers = allMembers.where((m) {
          // 지역 필터링 먼저 적용
          if (_userRegion != '전국') {
            String shortRegion = _userRegion.substring(0, 2);
            if (_userRegion == '세종특별자치시') shortRegion = '세종';
            if (_userRegion == '제주특별자치도') shortRegion = '제주';
            if (_userRegion == '전북특별자치도') shortRegion = '전북';
            
            if (!m.district.contains(shortRegion)) return false;
          }

          final query = _searchQuery.toLowerCase();
          return m.name.toLowerCase().contains(query) ||
                 m.party.toLowerCase().contains(query) ||
                 m.district.toLowerCase().contains(query) ||
                 m.bio.toLowerCase().contains(query) ||
                 m.policies.any((p) => p.toLowerCase().contains(query)) ||
                 m.achievementsList.any((a) => a.toLowerCase().contains(query));
        }).toList();

        // 당선 가능성 높은 순으로 정렬
        filteredMembers.sort((a, b) => b.electionPossibility.compareTo(a.electionPossibility));

        if (filteredMembers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: AppColors.grey),
                const SizedBox(height: 16),
                Text(
                  '검색 결과가 없습니다',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredMembers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MemberCard(
                member: filteredMembers[index],
                onTap: () => setState(() => _selectedMember = filteredMembers[index]),
              ),
            );
          },
        );
      },
    );
  }

  // 즐겨찾기 페이지
  Widget _buildFavoritesPage() {
    return StreamBuilder<List<Member>>(
      stream: _membersStream,
      builder: (context, snapshot) {
        final members = snapshot.data ?? _cachedMembers;
        final favoriteMembers = members.where((m) => m.isFavorite).toList();

        if (favoriteMembers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_border, size: 64, color: AppColors.grey),
                const SizedBox(height: 16),
                Text(
                  '즐겨찾기한 의원이 없습니다',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favoriteMembers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MemberCard(
                member: favoriteMembers[index],
                onTap: () => setState(() => _selectedMember = favoriteMembers[index]),
              ),
            );
          },
        );
      },
    );
  }

  // 비교 페이지
  Widget _buildComparisonPage() {
    return StreamBuilder<List<Member>>(
      stream: _membersStream,
      builder: (context, snapshot) {
        final members = snapshot.data ?? _cachedMembers;
        final favoriteMembers = members.where((m) => m.isFavorite).toList();

        if (favoriteMembers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: AppColors.grey.withOpacity(0.2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '비교를 위해 먼저 즐겨찾기에 의원을 추가해주세요',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          );
        }

        if (_selectedCompareIds.length == 2) {
          final member1 = members.firstWhere((m) => m.id == _selectedCompareIds.first);
          final member2 = members.firstWhere((m) => m.id == _selectedCompareIds.last);
          return _buildComparisonResults(member1, member2);
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '비교할 의원 2명을 선택해주세요 (${_selectedCompareIds.length}/2)',
                style: AppTextStyles.headline4,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: favoriteMembers.length,
                itemBuilder: (context, index) {
                  final member = favoriteMembers[index];
                  final isSelected = _selectedCompareIds.contains(member.id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      title: Text(member.name, style: AppTextStyles.headline4),
                      subtitle: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: member.party,
                              style: TextStyle(
                                color: _getPartyColor(member.party),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: ' • ${member.district}',
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      secondary: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: member.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: '${ImageUtil.getProxyUrl(member.imageUrl, width: 100, height: 100)}&v=2',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(width: 40, height: 40, color: AppColors.lightGrey),
                                errorWidget: (context, url, error) => Container(
                                  width: 40,
                                  height: 40,
                                  color: AppColors.lightGrey,
                                  child: const Icon(Icons.person, size: 20),
                                ),
                              )
                            : Container(width: 40, height: 40, color: AppColors.lightGrey, child: const Icon(Icons.person)),
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            if (_selectedCompareIds.length < 2) {
                              _selectedCompareIds.add(member.id);
                            }
                          } else {
                            _selectedCompareIds.remove(member.id);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 비교 결과 화면
  Widget _buildComparisonResults(Member m1, Member m2) {
    final color1 = _getPartyColor(m1.party);
    final color2 = _getPartyColor(m2.party);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('후보자 비교', style: AppTextStyles.headline3),
              TextButton(
                onPressed: () => setState(() => _selectedCompareIds.clear()),
                child: const Text('다시 선택'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildSimpleMemberHeader(m1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.grey.withOpacity(0.2),
                  ),
                ),
              ),
              Expanded(child: _buildSimpleMemberHeader(m2)),
            ],
          ),
          const SizedBox(height: 32),
          _buildComparisonRow('당선 가능성', m1.electionPossibility, m2.electionPossibility, color1, color2, isPercent: true),
          const SizedBox(height: 16),
          FutureBuilder<List<AnalysisResult>>(
            future: Future.wait([
              sl<CalculateElectionPossibilityUseCase>().call(m1.id),
              sl<CalculateElectionPossibilityUseCase>().call(m2.id),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final a1 = snapshot.data![0];
              final a2 = snapshot.data![1];

              return Column(
                children: [
                  _buildComparisonRow('성과도', a1.achievementScore, a2.achievementScore, color1, color2),
                  const SizedBox(height: 16),
                  _buildComparisonRow('활동도', a1.activityScore, a2.activityScore, color1, color2),
                  const SizedBox(height: 16),
                  _buildComparisonRow('정책도', a1.policyScore, a2.policyScore, color1, color2),
                  const SizedBox(height: 16),
                  _buildComparisonRow('언론도', a1.publicImageScore, a2.publicImageScore, color1, color2),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMemberHeader(Member m) {
    final partyColor = _getPartyColor(m.party);
    return GestureDetector(
      onTap: () => setState(() => _selectedMember = m),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: m.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: '${ImageUtil.getProxyUrl(m.imageUrl, width: 200, height: 200)}&v=2',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(width: 80, height: 80, color: AppColors.lightGrey),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.lightGrey,
                      child: const Icon(Icons.person, size: 40),
                    ),
                  )
                : Container(width: 80, height: 80, color: AppColors.lightGrey, child: const Icon(Icons.person, size: 40)),
          ),
          const SizedBox(height: 8),
          Text(m.name, style: AppTextStyles.headline4),
          Text(m.party, style: AppTextStyles.labelSmall.copyWith(color: partyColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(m.district, style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey)),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, double v1, double v2, Color c1, Color c2, {bool isPercent = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        final currentV1 = v1 * animValue;
        final currentV2 = v2 * animValue;
        
        final display1 = isPercent ? '${(currentV1 * 100).toStringAsFixed(1)}%' : (currentV1 * 100).toStringAsFixed(1);
        final display2 = isPercent ? '${(currentV2 * 100).toStringAsFixed(1)}%' : (currentV2 * 100).toStringAsFixed(1);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(display1, textAlign: TextAlign.right, style: TextStyle(
                    color: c1,
                    fontWeight: v1 >= v2 ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  )),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RotatedBox(
                              quarterTurns: 2,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: currentV1,
                                  backgroundColor: AppColors.lightGrey.withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation(c1.withOpacity(v1 >= v2 ? 1.0 : 0.4)),
                                  minHeight: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: currentV2,
                                backgroundColor: AppColors.lightGrey.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation(c2.withOpacity(v2 >= v1 ? 1.0 : 0.4)),
                                minHeight: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(display2, style: TextStyle(
                    color: c2,
                    fontWeight: v2 >= v1 ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  )),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

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
  Widget _buildElectionBanner() {
    final electionDate = DateTime(2026, 6, 3);
    final today = DateTime.now();
    final daysRemaining = electionDate.difference(today).inDays;
    final totalDays = electionDate.difference(DateTime(2025, 6, 3)).inDays;
    final progressRatio = (totalDays - daysRemaining) / totalDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryLight.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '2026 지방선거 당선 예측기',
                      style: AppTextStyles.headline3.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '병오년(丙午年) 붉은말의 해',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                Image.asset(
                  'assets/images/election_icon.png',
                  width: 60,
                  height: 60,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progressRatio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(
                AppColors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'D-$daysRemaining (선거일: 2026년 6월 3일)',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 주요 통계
  Widget _buildStatistics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<List<Member>>(
        stream: _membersStream,
        builder: (context, snapshot) {
          final freshMembers = snapshot.data ?? [];
          if (freshMembers.isNotEmpty) {
            _cachedMembers = freshMembers;
          }
          final allMembers = freshMembers.isNotEmpty ? freshMembers : _cachedMembers;
          final members = _getFilteredMembers(allMembers);
          final latestAnalysis = members.isNotEmpty
              ? members
                  .map((m) => m.lastAnalysisDate)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
              : null;
          final updateValue = latestAnalysis == null ? '-' : _formatRelativeTime(latestAnalysis);
          final nesdcCount = members.fold<int>(
              0,
              (sum, m) =>
                  sum + m.polls.where((p) => p.id.startsWith('nesdc_')).length);

          // 반응형 레이아웃: TOP3는 전체 너비, 분석과 여론조사위는 3:7 비율로 가로 정렬
          return Column(
            children: [
              // TOP3 카드 - 전체 너비
              _buildTop3Card(members),
              const SizedBox(height: 12),
              // 분석과 여론조사위 - 3:7 비율 가로 정렬
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _StatisticCard(
                      title: '분석 중인 의원',
                      value: members.length.toString(),
                      icon: Icons.people,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 7,
                    child: _StatisticCard(
                      title: '여론조사심의위 반영 · $updateValue',
                      value: '$nesdcCount건',
                      icon: Icons.update,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTop3Card(List<Member> members) {
    return FutureBuilder<List<_TopMember>>(
      future: _loadTop3Members(members),
      builder: (context, snapshot) {
        final freshTop3 = snapshot.data ?? [];
        if (freshTop3.isNotEmpty) {
          _cachedTop3 = freshTop3;
        }
        final top3 = freshTop3.isNotEmpty ? freshTop3 : _cachedTop3;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.success.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '당선 가능성 TOP 3',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (snapshot.connectionState == ConnectionState.waiting && top3.isEmpty)
                Text(
                  '계산 중...',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.mediumGray,
                  ),
                )
              else if (top3.isEmpty)
                Text(
                  '데이터 없음',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.mediumGray,
                  ),
                )
              else
                // 세로 정렬: 3명을 가운데 정렬하며 각 셀을 세로로 길게 표시
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(top3.length, (index) {
                    final entry = top3[index];
                    final member = entry.member;
                    final rank = index + 1;
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < top3.length - 1 ? 12 : 0),
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 순위 (분석 카드와 같은 크기, 빨간색)
                            Text(
                              '${rank}위',
                              style: AppTextStyles.headline4.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 아바타
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.lightGrey,
                                border: Border.all(color: AppColors.primary.withOpacity(0.08)),
                              ),
                              child: ClipOval(
                                child: member.imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: '${ImageUtil.getProxyUrl(member.imageUrl, width: 200, height: 200)}&v=2',
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        errorWidget: (context, url, error) {
                                          return Center(
                                            child: Text(
                                              member.name.isNotEmpty ? member.name[0] : '?',
                                              style: AppTextStyles.headline4.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Text(
                                          member.name.isNotEmpty ? member.name[0] : '?',
                                          style: AppTextStyles.headline4.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 이름 및 퍼센트
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.darkGray,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${(entry.possibility * 100).toStringAsFixed(0)}%',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<_TopMember>> _loadTop3Members(List<Member> members) async {
    if (members.isEmpty) {
      return [];
    }
    final results = <_TopMember>[];
    for (final member in members) {
      final analysis = await sl<CalculateElectionPossibilityUseCase>().call(member.id);
      results.add(_TopMember(member: member, possibility: analysis.electionPossibility));
    }
    results.sort((a, b) => b.possibility.compareTo(a.possibility));
    return results.take(3).toList();
  }

  Future<List<_TopMember>> _loadTopMembers(List<Member> members) async {
    if (members.isEmpty) {
      return [];
    }
    final results = <_TopMember>[];
    for (final member in members) {
      final analysis = await sl<CalculateElectionPossibilityUseCase>().call(member.id);
      results.add(_TopMember(member: member, possibility: analysis.electionPossibility));
    }
    results.sort((a, b) => b.possibility.compareTo(a.possibility));
    return results;
  }

  // 의원 목록 섹션
  Widget _buildMemberListSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '당선 가능성 순위',
                style: AppTextStyles.headline4,
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1), // 검색 탭으로 이동
                child: Text(
                  '전체보기',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Member>>(
            stream: _membersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && _cachedMembers.isEmpty) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          '의원 데이터 로드 중...',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final freshMembers = snapshot.data ?? [];
              if (snapshot.hasError && freshMembers.isEmpty && _cachedMembers.isEmpty) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '데이터 로드 실패',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                );
              }
              
              if (freshMembers.isNotEmpty) {
                _cachedMembers = freshMembers;
              }
              final allMembers = freshMembers.isNotEmpty ? freshMembers : _cachedMembers;
              final members = _getFilteredMembers(allMembers);
              if (members.isEmpty) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '의원 데이터가 없습니다',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                );
              }
              
              return FutureBuilder<List<_TopMember>>(
                future: _loadTopMembers(members),
                builder: (context, topSnapshot) {
                  if (topSnapshot.connectionState == ConnectionState.waiting && _cachedRanked.isEmpty) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              '당선 가능성 계산 중...',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final freshRanked = topSnapshot.data ?? [];
                  if (freshRanked.isNotEmpty) {
                    _cachedRanked = freshRanked;
                  }
                  final ranked = freshRanked.isNotEmpty ? freshRanked : _cachedRanked;
                  if (ranked.isEmpty) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '의원 데이터가 없습니다',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ranked.length,
                    itemBuilder: (context, index) {
                      final member = ranked[index].member;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MemberCard(
                          member: member,
                          onTap: () => setState(() => _selectedMember = member),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // 통합 뉴스 피드 페이지
  Widget _buildIntegratedNewsPage() {
    return StreamBuilder<List<Member>>(
      stream: _membersStream,
      builder: (context, snapshot) {
        final members = snapshot.data ?? _cachedMembers;
        final favorites = members.where((m) => m.isFavorite).toList();
        
        // 모든 즐겨찾기 의원의 뉴스를 수집하여 날짜순 정렬
        final allNews = <Map<String, dynamic>>[];
        for (var m in favorites) {
          for (var report in m.pressReports) {
            allNews.add({
              'member': m,
              'report': report,
            });
          }
        }
        allNews.sort((a, b) => (b['report'].publishDate as DateTime).compareTo(a['report'].publishDate));

        return Container(
          color: AppColors.white,
          child: Column(
            children: [
              // 제목란 (News 탭과 동일한 노란색)
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.newspaper, color: AppColors.dark, size: 28),
                      const SizedBox(width: 12),
                      Text('통합 뉴스 피드', style: AppTextStyles.headline3.copyWith(color: AppColors.dark)),
                    ],
                  ),
                ),
              ),
              if (favorites.isEmpty)
                const Expanded(child: Center(child: Text('즐겨찾기한 의원이 없습니다.')))
              else if (allNews.isEmpty)
                const Expanded(child: Center(child: Text('최신 보도 자료가 없습니다.')))
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: allNews.length,
                    separatorBuilder: (context, index) => const Divider(height: 32),
                    itemBuilder: (context, index) {
                      final item = allNews[index];
                      final Member m = item['member'];
                      final report = item['report'];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.lightGrey,
                                    child: m.imageUrl.isNotEmpty
                                        ? ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: ImageUtil.getProxyUrl(m.imageUrl, width: 48, height: 48),
                                              width: 24,
                                              height: 24,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(width: 24, height: 24, color: AppColors.lightGrey),
                                              errorWidget: (context, url, error) => const Icon(Icons.person, size: 12),
                                            ),
                                          )
                                        : const Icon(Icons.person, size: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 36,
                                    child: AspectRatio(
                                      aspectRatio: 3 / 1,
                                      child: Image.asset(
                                        _getPartyLogoUrl(m.party),
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              // 정당 마크 (텍스트 사이즈에 맞춘 사각형)
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getPartyColor(m.party),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(text: '${m.name} • ', style: AppTextStyles.labelSmall.copyWith(color: AppColors.darkGray, fontWeight: FontWeight.bold)),
                                    TextSpan(text: m.party, style: AppTextStyles.labelSmall.copyWith(color: _getPartyColor(m.party), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 12, color: AppColors.grey),
                                  const SizedBox(width: 4),
                                  Text(report.publishDate.toString().split(' ')[0], style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(report.title, style: AppTextStyles.headline4.copyWith(color: AppColors.darkGray)),
                          const SizedBox(height: 6),
                          Text(report.summary, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkGray.withOpacity(0.8)), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(4)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.source, size: 12, color: AppColors.grey),
                                    const SizedBox(width: 4),
                                    Text(report.source, style: AppTextStyles.labelSmall.copyWith(color: AppColors.darkGray)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

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
class _StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatisticCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleWidgets = subtitle == null
        ? const <Widget>[]
        : <Widget>[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headline4.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall,
          ),
          ...subtitleWidgets,
        ],
      ),
    );
  }

}

class _TopMember {
  final Member member;
  final double possibility;

  const _TopMember({
    required this.member,
    required this.possibility,
  });
}

// 의원 카드 위젯
class _MemberCard extends StatefulWidget {
  final Member member;
  final VoidCallback? onTap;

  const _MemberCard({required this.member, this.onTap});

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.member.isFavorite;
  }

  @override
  void didUpdateWidget(_MemberCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.member.isFavorite != oldWidget.member.isFavorite) {
      _isFavorite = widget.member.isFavorite;
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: member.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: '${ImageUtil.getProxyUrl(member.imageUrl, width: 160, height: 160)}&v=2',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(width: 60, height: 60, color: AppColors.lightGrey),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.8),
                                  AppColors.secondary.withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                member.name.isNotEmpty ? member.name[0] : '?',
                                style: AppTextStyles.headline3.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.8),
                                AppColors.secondary.withOpacity(0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              member.name.isNotEmpty ? member.name[0] : '?',
                              style: AppTextStyles.headline3.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 50,
                  child: AspectRatio(
                    aspectRatio: 3 / 1,
                    child: Image.asset(
                      _getPartyLogoUrl(member.party),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: AppTextStyles.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: member.party,
                          style: AppTextStyles.bodySmall.copyWith(color: _getPartyColor(member.party), fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ' • ${member.district}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FutureBuilder<AnalysisResult>(
                      future: sl<CalculateElectionPossibilityUseCase>().call(member.id),
                      builder: (context, snapshot) {
                        final possibility = snapshot.data?.electionPossibility ?? member.electionPossibility;
                        return Text(
                          '당선 가능성: ${(possibility * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '업데이트: ${_formatRelativeTime(member.lastAnalysisDate)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.grey,
              size: 16,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.star : Icons.star_border,
                color: _isFavorite ? Colors.amber : AppColors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });
                sl<ToggleFavoriteUseCase>().call(member.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}


String _formatRelativeTime(DateTime date) {
  final local = date.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  final s = local.second.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min:$s';
}

// 정당별 로고 URL (가로 3:1 비율 PNG)
String _getPartyLogoUrl(String party) {
  if (party.contains('더불어민주당')) {
    return 'assets/images/party/minjoo.png';
  } else if (party.contains('국민의힘')) {
    return 'assets/images/party/power.png';
  } else if (party.contains('정의당')) {
    return 'assets/images/party/justice.png';
  } else if (party.contains('진보당')) {
    return 'assets/images/party/progressive.png';
  } else if (party.contains('조국혁신당')) {
    return 'assets/images/party/rebuilding.png';
  } else if (party.contains('개혁신당')) {
    return 'assets/images/party/reform.png';
  } else if (party.contains('기본소득당')) {
    return 'assets/images/party/basicincome.png';
  }
  return ''; // 로고 없음
}

// 정당별 색상 도우미
Color _getPartyColor(String party) {
  if (party.contains('더불어민주당')) return const Color(0xFF004EA2);
  if (party.contains('국민의힘')) return const Color(0xFFE61E2B);
  if (party.contains('정의당')) return const Color(0xFFFFCC00);
  if (party.contains('진보당')) return const Color(0xFFD6001C);
  if (party.contains('조국혁신당')) return const Color(0xFF00A0E2);
  if (party.contains('개혁신당')) return const Color(0xFFFF7F00);
  if (party.contains('기본소득당')) return const Color(0xFF00D2C3);
  return AppColors.grey;
}
