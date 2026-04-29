import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'member_card.dart';

class HomeDashboardView extends StatefulWidget {
  final bool isLoading;
  final Stream<List<Member>> membersStream;
  final List<Member> cachedMembers;
  final String userRegion;
  final ValueChanged<Member> onMemberSelected;
  final VoidCallback onNavigateToSearch;
  final ValueChanged<String> onRegionChanged;

  const HomeDashboardView({
    Key? key,
    required this.isLoading,
    required this.membersStream,
    required this.cachedMembers,
    required this.userRegion,
    required this.onMemberSelected,
    required this.onNavigateToSearch,
    required this.onRegionChanged,
  }) : super(key: key);

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Member> _displayMembers = [];
  StreamSubscription? _subscription;

  final List<String> _regions = [
    '서울특별시',
    '부산광역시',
    '대구광역시',
    '인천광역시',
    '광주광역시',
    '대전광역시',
    '울산광역시',
    '세종특별자치시',
    '경기도',
    '강원특별자치도',
    '충청북도',
    '충청남도',
    '전북특별자치도',
    '전라남도',
    '경상북도',
    '경상남도',
    '제주특별자치도',
    '전국',
  ];

  @override
  void initState() {
    super.initState();
    _displayMembers = widget.cachedMembers;

    _subscription = widget.membersStream.listen((members) {
      if (mounted) {
        setState(() {
          _displayMembers = members;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<Member> get _filteredSortedMembers {
    List<Member> filtered;
    if (widget.userRegion == '전국') {
      filtered = List.from(_displayMembers);
    } else {
      filtered = _displayMembers
          .where((m) => m.province == widget.userRegion)
          .toList();
    }

    // 당선 가능성 내림차순 정렬
    filtered
        .sort((a, b) => b.electionPossibility.compareTo(a.electionPossibility));
    return filtered;
  }

  List<Member> get _top3 {
    final sorted = _filteredSortedMembers;
    return sorted.take(3).toList();
  }

  List<Member> get _memberList {
    final sorted = _filteredSortedMembers;
    if (sorted.length <= 3) return [];
    return sorted.sublist(3, sorted.length > 13 ? 13 : sorted.length);
  }

  String get _updateValue {
    if (_displayMembers.isEmpty) return '-';
    // 가장 최근 업데이트 날짜 찾기
    final latest = _displayMembers
        .map((m) => m.lastAnalysisDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return '${latest.month}/${latest.day} ${latest.hour}:${latest.minute}';
  }

  int get _nesdcCount {
    int total = 0;
    for (var m in _displayMembers) {
      total += m.pressReports.length;
    }
    return total;
  }

  void _showRegionSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                '지역 선택',
                style: AppTextStyles.headline4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: RepaintBoundary(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemExtent: 72,
                    itemCount: _regions.length,
                    itemBuilder: (context, index) {
                      final region = _regions[index];
                      final isSelected = region == widget.userRegion;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            widget.onRegionChanged(region);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : AppColors.surface,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.lightGray,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.mediumGray,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    region,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.darkGray,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
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
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필요

    // 캐시된 데이터가 있으면 바로 표시, 로딩 중이어도 기존 데이터 유지
    if (widget.isLoading &&
        _displayMembers.isEmpty &&
        widget.cachedMembers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    final filteredMembers = _filteredSortedMembers;
    final top3 = _top3;
    final memberList = _memberList;
    final updateValue = _updateValue;
    final nesdcCount = _nesdcCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 데이터가 있으면 항상 표시 (로딩 중이어도 기존 데이터 유지)
          if (filteredMembers.isNotEmpty) ...[
            // 통계 섹션 (분석의원, 여론조사심의회)
            _buildStatisticsSection(
                filteredMembers.length, nesdcCount, updateValue),
            const SizedBox(height: 24),
            _buildTop3Section(top3),
            _buildMemberList(memberList),
          ] else if (widget.isLoading) ...[
            // 데이터가 없고 로딩 중일 때만 로딩바 표시
            const Center(child: CircularProgressIndicator(color: Colors.red)),
          ] else ...[
            // 데이터가 없고 로딩도 안할 때는 빈 상태 표시
            Center(
              child: Text(
                '표시할 후보자가 없습니다.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.mediumGray,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(
      int memberCount, int nesdcCount, String updateValue) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _StatisticCard(
            title: '분석의원',
            value: memberCount.toString(),
            icon: Icons.people,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 7,
          child: _StatisticCard(
            title: '여론조사심의회 · $updateValue',
            value: '${nesdcCount}건',
            icon: Icons.update,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTop3Section(List<Member> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '당선 가능성 TOP 3',
                style: AppTextStyles.headline4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => _showRegionSelectionModal(),
                child: Row(
                  children: [
                    Text(
                      '지역설정',
                      style: AppTextStyles.bodyMedium.copyWith(
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
              final possibility = member.electionPossibility;
              return Padding(
                padding:
                    EdgeInsets.only(bottom: index < top3.length - 1 ? 12 : 0),
                child: GestureDetector(
                  onTap: () => widget.onMemberSelected(member),
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: AppColors.lightGray,
                            child: member.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: member.imageUrl,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 100,
                                    memCacheHeight: 100,
                                    placeholder: (context, url) =>
                                        Container(color: AppColors.lightGrey),
                                    errorWidget: (context, url, error) =>
                                        Center(
                                      child: Text(
                                        member.name.substring(0, 1),
                                        style: AppTextStyles.headline4.copyWith(
                                          color: AppColors.mediumGray,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      member.name.substring(0, 1),
                                      style: AppTextStyles.headline4.copyWith(
                                        color: AppColors.mediumGray,
                                      ),
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
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${member.party} · ${member.district}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.mediumGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(possibility * 100).toStringAsFixed(1)}%',
                              style: AppTextStyles.headline4.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '당선가능성',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(List<Member> members) {
    if (members.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '후보자 목록',
                  style: AppTextStyles.headline4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: widget.onNavigateToSearch,
                  child: const Text('전체보기'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '당선 가능성이 높은 추가 후보자가 없습니다.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.mediumGray,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '후보자 목록',
                style: AppTextStyles.headline4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: widget.onNavigateToSearch,
                child: const Text('전체보기'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: List.generate(
              members.length,
              (index) {
                final member = members[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MemberCard(
                    member: member,
                    onTap: () => widget.onMemberSelected(member),
                  ),
                );
              },
            ),
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
        border: Border.all(color: color.withOpacity(0.15)),
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
