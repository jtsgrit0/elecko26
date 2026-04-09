import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:elecko26/core/theme/app_theme.dart';
import 'package:elecko26/core/utils/image_util.dart';
import 'package:elecko26/core/utils/party_util.dart';
import 'package:elecko26/core/utils/utility_functions.dart';
import 'package:elecko26/domain/entities/member.dart';
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
  List<Member> __localCachedMembers = [];

  @override
  void initState() {
    super.initState();
    __localCachedMembers = widget.cachedMembers;
  }

  List<Member> _getFilteredMembers(List<Member> members) {
    return members
        .where((m) => districtMatchesRegion(m.district, widget.userRegion))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Member>>(
      stream: widget.membersStream,
      builder: (context, snapshot) {
        final freshMembers = snapshot.data ?? [];
        if (freshMembers.isNotEmpty) {
          __localCachedMembers = freshMembers;
        }
        final allMembers =
            freshMembers.isNotEmpty ? freshMembers : __localCachedMembers;
        final filteredMembers = _getFilteredMembers(allMembers);

        // 정렬된 멤버 리스트 준비 (동기 방식)
        final rankedMembers = List<Member>.from(filteredMembers)
          ..sort(
              (a, b) => b.electionPossibility.compareTo(a.electionPossibility));

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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 4,
                  ),
                if (!widget.isLoading) const SizedBox(height: 4),
                // 2026 지방선거 배너
                _buildElectionBanner(),
                const SizedBox(height: 24),
                // 주요 통계
                _buildStatistics(filteredMembers),
                const SizedBox(height: 24),
                // 당선 가능성 TOP 3
                _buildTop3Section(rankedMembers.take(3).toList()),
                const SizedBox(height: 24),
                // 의원 목록 요약
                _buildMemberListSection(rankedMembers),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
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
                const Icon(
                  Icons.how_to_vote,
                  color: AppColors.white,
                  size: 40,
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

  Widget _buildStatistics(List<Member> members) {
    final latestAnalysis = members.isNotEmpty
        ? members
            .map((m) => m.lastAnalysisDate)
            .reduce((a, b) => a.isAfter(b) ? a : b)
        : null;
    final updateValue =
        latestAnalysis == null ? '-' : formatRelativeTime(latestAnalysis);
    final nesdcCount = members.fold<int>(
        0,
        (sum, m) =>
            sum + m.polls.where((p) => p.id.startsWith('nesdc_')).length);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
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
      ),
    );
  }

  Widget _buildTop3Section(List<Member> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.success.withOpacity(0.2),
          ),
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
            const SizedBox(height: 12),
            Column(
              children: List.generate(top3.length, (index) {
                final member = top3[index];
                final rank = index + 1;
                return Padding(
                  padding:
                      EdgeInsets.only(bottom: index < top3.length - 1 ? 12 : 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${rank}위',
                          style: AppTextStyles.headline4.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl:
                                '${ImageUtil.getProxyUrl(member.imageUrl, width: 100, height: 100)}',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.lightGrey,
                              child: Center(
                                child: Text(getProfileInitial(member.name)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${member.party} • ${member.district}',
                                style: AppTextStyles.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(member.electionPossibility * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.headline4.copyWith(
                            color: AppColors.success,
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
      ),
    );
  }

  Widget _buildMemberListSection(List<Member> members) {
    if (members.isEmpty) return const SizedBox.shrink();

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
                onPressed: () => widget.onNavigateToSearch(),
                child: const Text('전체보기'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length, // 홈에서는 전체 목록을 노출
            itemBuilder: (context, index) {
              final member = members[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MemberCard(
                  key: ValueKey(member.id),
                  member: member,
                  onTap: () => widget.onMemberSelected(member),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

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
        border: Border.all(color: color.withOpacity(0.2)),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.headline4.copyWith(color: color)),
          Text(title, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
