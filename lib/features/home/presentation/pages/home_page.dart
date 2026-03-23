import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/domain/entities/analysis_result.dart';
import 'package:flutter_application_1/domain/entities/member.dart';
import 'package:flutter_application_1/domain/repositories/member_repository.dart';
import 'package:flutter_application_1/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:flutter_application_1/domain/usecases/member_usecases.dart';
import 'package:flutter_application_1/domain/usecases/export_election_data_usecase.dart';
import 'package:flutter_application_1/app/injection_container.dart';
import 'package:flutter_application_1/features/home/presentation/pages/member_detail_page.dart';
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
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startMemberStream();
    _triggerNesdcRefresh();
    _startDataExportTimer();
    
    // 1분마다 UI 데이터 새로고침
    _uiRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _triggerNesdcRefresh(),
    );
  }

  void _startMemberStream() {
    _membersStream = sl<WatchMembersUseCase>().call().asBroadcastStream();
  }

  void _stopMemberStream() {
    _membersStream = Stream<List<Member>>.empty();
  }

  void _triggerNesdcRefresh() {
    setState(() { _isLoading = true; });
    // 강제 갱신 트리거: NESDC 데이터 갱신 시도
    sl<MemberRepository>()
        .refreshMembers()
        .then((_) {
          if (mounted) setState(() { _isLoading = false; });
          debugPrint('[NESDC] refreshMembers completed');
        })
        .catchError((e) {
          if (mounted) setState(() { _isLoading = false; });
          debugPrint('[NESDC] refreshMembers failed: $e');
        });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _buildAppBar(),
      ),
      body: SingleChildScrollView(
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
            // 빠른 접근 메뉴
            _buildQuickAccessMenu(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                      Text(
                        '🐴 2026 지방선거',
                        style: AppTextStyles.headline4.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '붉은말의 해 - 국회의원 분석',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  Container(
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
                      '2026 지방선거',
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
                Text(
                  '🐴',
                  style: AppTextStyles.headline1,
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
          final members = freshMembers.isNotEmpty ? freshMembers : _cachedMembers;
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
                                    ? Image.network(
                                        member.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
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
                onPressed: () {},
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
              
              if (snapshot.hasError) {
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
              
              final freshMembers = snapshot.data ?? [];
              if (freshMembers.isNotEmpty) {
                _cachedMembers = freshMembers;
              }
              final members = freshMembers.isNotEmpty ? freshMembers : _cachedMembers;
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
                        child: _MemberCard(member: member),
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

  // 빠른 접근 메뉴
  Widget _buildQuickAccessMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '빠른 접근',
            style: AppTextStyles.headline4,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAccessButton(
                  label: '분석',
                  icon: Icons.bar_chart,
                  onPressed: () {},
                  backgroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAccessButton(
                  label: '의원',
                  icon: Icons.person_outline,
                  onPressed: () {},
                  backgroundColor: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAccessButton(
                  label: '뉴스',
                  icon: Icons.newspaper,
                  onPressed: () {},
                  backgroundColor: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 하단 네비게이션 바
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.grey,
      backgroundColor: AppColors.white,
      elevation: 8,
      items: const [
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
          icon: Icon(Icons.person),
          label: '프로필',
        ),
      ],
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  // FAB
  Widget _buildFloatingActionButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          // 분석 시작
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh),
      ),
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
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
          ],
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
class _MemberCard extends StatelessWidget {
  final Member member;

  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MemberDetailPage(member: member),
          ),
        );
      },
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: member.imageUrl.isNotEmpty
                  ? Image.network(
                      member.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
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
                        );
                      },
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
                  Text(
                    '${member.party} • ${member.district}',
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }
}

// 빠른 접근 버튼
class _QuickAccessButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;

  const _QuickAccessButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.white,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
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
