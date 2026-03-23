import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/domain/entities/member.dart';
import 'package:flutter_application_1/domain/usecases/member_usecases.dart';
import 'package:flutter_application_1/app/injection_container.dart';
import 'package:flutter_application_1/features/home/presentation/pages/member_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late Stream<List<Member>> _membersStream;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startMemberStream();
  }

  void _startMemberStream() {
    _membersStream = sl<WatchMembersUseCase>().call().asBroadcastStream();
  }

  void _stopMemberStream() {
    _membersStream = Stream<List<Member>>.empty();
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
    final today = DateTime(2026, 2, 4);
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
          final members = snapshot.data ?? [];
          final avgElectionRate = members.isNotEmpty
              ? (members.fold<double>(
                      0, (sum, m) => sum + m.electionPossibility) /
                  members.length *
                  100)
                  .toStringAsFixed(0)
              : '0';
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

          return Row(
            children: [
              Expanded(
                child: _StatisticCard(
                  title: '분석 중인 의원',
                  value: members.length.toString(),
                  icon: Icons.people,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatisticCard(
                  title: '평균 당선율',
                  value: '$avgElectionRate%',
                  icon: Icons.trending_up,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
                Expanded(
                  child: _StatisticCard(
                    title: 'NESDC 반영 · $updateValue',
                    value: '$nesdcCount건',
                    icon: Icons.update,
                    color: AppColors.secondary,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) {
      return '방금';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}분 전';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}시간 전';
    }
    return '${diff.inDays}일 전';
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
                '의원 목록',
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
              if (snapshot.connectionState == ConnectionState.waiting) {
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
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                        const SizedBox(height: 12),
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
              
              final members = snapshot.data ?? [];
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
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MemberCard(member: member),
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
  final IconData icon;
  final Color color;

  const _StatisticCard({
    required this.title,
    required this.value,
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
        ],
      ),
    );
  }
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
                    child: Text(
                      '당선율: ${(member.electionPossibility * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.success,
                      ),
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
