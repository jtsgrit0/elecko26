import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:elecko26/app/injection_container.dart';
import 'package:elecko26/core/theme/app_theme.dart';
import 'package:elecko26/core/utils/image_util.dart';
import 'package:elecko26/core/utils/utility_functions.dart' show districtMatchesRegion;
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:elecko26/features/home/presentation/widgets/member_card.dart';

class HomeDashboardView extends StatefulWidget {
  final bool isLoading;
  final Stream<List<Member>> membersStream;
  final List<Member> cachedMembers;
  final String userRegion;
  final Future<void> Function() onRefresh;
  final Function(Member) onMemberSelected;
  final VoidCallback onNavigateToSearch;
  final Function(String) onRegionChanged;

  const HomeDashboardView({
    Key? key,
    required this.isLoading,
    required this.membersStream,
    required this.cachedMembers,
    required this.userRegion,
    required this.onRefresh,
    required this.onMemberSelected,
    required this.onNavigateToSearch,
    required this.onRegionChanged,
  }) : super(key: key);

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  List<Member> _displayMembers = [];
  StreamSubscription<List<Member>>? _subscription;
  final Map<String, double> _possibilityCache = {};

  @override
  void initState() {
    super.initState();
    _displayMembers = widget.cachedMembers;
    _subscription = widget.membersStream.listen(_onStreamData);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onStreamData(List<Member> members) {
    if (members.isEmpty) return;

    // 즉시 raw 데이터로 UI 업데이트 (리포지토리에서 이미 계산된 점수가 포함되어 있음)
    if (mounted) {
      setState(() {
        _displayMembers = members;
      });
    }
  }

  Future<void> _calculatePossibilities(List<Member> members) async {
    for (final member in members) {
      if (!_possibilityCache.containsKey(member.id)) {
        try {
          final result = await sl<CalculateElectionPossibilityUseCase>()
              .call(member.id)
              .timeout(const Duration(seconds: 2));
          _possibilityCache[member.id] = result.electionPossibility;
        } catch (e) {
          _possibilityCache[member.id] = member.electionPossibility;
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _scheduleCalculation(List<Member> members) {
    // 캐시에 없는 후보자들만 계산
    final uncached = members.where((m) => !_possibilityCache.containsKey(m.id)).toList();
    if (uncached.isNotEmpty) {
      // 다음 프레임에서 계산 실행 (빌드 중 setState 방지)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculatePossibilities(uncached);
      });
    }
  }

  double _getPossibility(Member member) {
    return _possibilityCache[member.id] ?? member.electionPossibility;
  }

  /// 지역선택 모달창 표시
  void _showRegionSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
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
            const SizedBox(height: 20),
            Text(
              '지역 선택',
              style: AppTextStyles.headline3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '확인하고 싶은 지역을 선택하세요',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _regions.length,
                itemBuilder: (context, index) {
                  final region = _regions[index];
                  final isSelected = region == widget.userRegion;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        // 홈페이지에 지역 변경 알림
                        if (context.mounted) {
                          // 부모 위젯에 지역 변경 알림
                          _onRegionSelected(region);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? AppColors.primary
                                : AppColors.lightGray,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: isSelected ? AppColors.primary : AppColors.mediumGray,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                region,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.primary : AppColors.darkGray,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                size: 20,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 지역 선택 시 처리
  void _onRegionSelected(String region) {
    // 부모 위젯에 지역 변경 알림
    if (context.mounted) {
      // 홈페이지의 _onRegionChanged 메서드 호출
      final homePageState = context.findAncestorStateOfType<_HomePageState>();
      homePageState?._onRegionChanged(region);
    }
  }


  @override
  Widget build(BuildContext context) {
    // 지역 필터링
    final filteredMembers = _displayMembers
        .where((m) => districtMatchesRegion(m.district, widget.userRegion))
        .toList();

    // 당선 가능성 기준으로 정렬 (캐시된 값 사용)
    final rankedMembers = List<Member>.from(filteredMembers)
      ..sort((a, b) => _getPossibility(b).compareTo(_getPossibility(a)));

    // 캐시에 없는 후보자들의 당선 가능성 계산
    _scheduleCalculation(rankedMembers);

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
      child: Row(
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
    );
  }

  void _showRegionSelectionModal() {
    final regions = [
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
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
            const SizedBox(height: 20),
            Text(
              '지역 선택',
              style: AppTextStyles.headline3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '확인하고 싶은 지역을 선택하세요',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: regions.length,
                itemBuilder: (context, index) {
                  final region = regions[index];
                  final isSelected = region == widget.userRegion;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _onRegionSelected(region);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.lightGray,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: isSelected ? AppColors.primary : AppColors.mediumGray,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                region,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onRegionSelected(String region) {
    // 선택된 지역으로 업데이트
    widget.onRegionChanged(region);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '당선 가능성 TOP 3',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showRegionSelectionModal(),
                  child: Row(
                    children: [
                      Text(
                        '지역설정',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(top3.length, (index) {
                final member = top3[index];
                final rank = index + 1;
                final possibility = _getPossibility(member);
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
                          '${(possibility * 100).toStringAsFixed(0)}%',
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