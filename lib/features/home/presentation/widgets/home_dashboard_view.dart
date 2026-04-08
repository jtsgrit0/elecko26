import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:elecko26/core/theme/app_theme.dart';
import 'package:elecko26/core/utils/image_util.dart';
import 'package:elecko26/core/utils/party_util.dart';
import 'package:elecko26/core/utils/utility_functions.dart';
import 'package:elecko26/domain/entities/analysis_result.dart';
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:elecko26/app/injection_container.dart';
import 'package:elecko26/features/home/presentation/widgets/member_card.dart';

class HomeDashboardView extends StatefulWidget {
  final bool isLoading;
  final Stream<List<Member>> membersStream;
  final List<Member> cachedMembers;
  final String userRegion;
  final Future<void> Function() onRefresh;
  final Function(Member) onMemberSelected;
  final VoidCallback onNavigateToSearch;

  const HomeDashboardView({
    Key? key,
    required this.isLoading,
    required this.membersStream,
    required this.cachedMembers,
    required this.userRegion,
    required this.onRefresh,
    required this.onMemberSelected,
    required this.onNavigateToSearch,
  }) : super(key: key);

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  List<_TopMember> _cachedTop3 = [];
  List<_TopMember> _cachedRanked = [];

  // Update cachedMembers dynamically from _buildStatistics?
  // We should better use widget.cachedMembers, but in _buildStatistics it assigns to _cachedMembers
  List<Member> __localCachedMembers = [];

  @override
  void initState() {
    super.initState();
    __localCachedMembers = widget.cachedMembers;
  }

  List<Member> _getFilteredMembers(List<Member> members) {
    if (widget.userRegion == '전국') return members;
    
    // 지역명 정규화 (예: '서울특별시' -> '서울', '경기도' -> '경기')
    String shortRegion = widget.userRegion.substring(0, 2);
    // 특수지역 대응
    if (widget.userRegion == '세종특별자치시') shortRegion = '세종';
    if (widget.userRegion == '제주특별자치도') shortRegion = '제주';
    if (widget.userRegion == '전북특별자치도') shortRegion = '전북';

    return members.where((m) => m.district.contains(shortRegion)).toList();
  }

  Widget _buildHomeDashboard() {
    return RefreshIndicator(
      onRefresh: () => widget.onRefresh(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (widget.isLoading)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            if (!widget.isLoading) const SizedBox(height: 4),
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

  Widget _buildStatistics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<List<Member>>(
        stream: widget.membersStream,
        builder: (context, snapshot) {
          final freshMembers = snapshot.data ?? [];
          if (freshMembers.isNotEmpty) {
            __localCachedMembers = freshMembers;
          }
          final allMembers = freshMembers.isNotEmpty ? freshMembers : __localCachedMembers;
          final members = _getFilteredMembers(allMembers);
          final latestAnalysis = members.isNotEmpty
              ? members
                  .map((m) => m.lastAnalysisDate)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
              : null;
          final updateValue = latestAnalysis == null ? '-' : formatRelativeTime(latestAnalysis);
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
                                              getProfileInitial(member.name),
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
                                          getProfileInitial(member.name),
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
                onPressed: () => widget.onNavigateToSearch(), // 검색 탭으로 이동
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
            stream: widget.membersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && __localCachedMembers.isEmpty) {
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
              if (snapshot.hasError && freshMembers.isEmpty && __localCachedMembers.isEmpty) {
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
                __localCachedMembers = freshMembers;
              }
              final allMembers = freshMembers.isNotEmpty ? freshMembers : __localCachedMembers;
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
                        child: MemberCard(
                          member: member,
                          onTap: () => widget.onMemberSelected(member),
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



  @override
  Widget build(BuildContext context) {
    return _buildHomeDashboard();
  }
}

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
