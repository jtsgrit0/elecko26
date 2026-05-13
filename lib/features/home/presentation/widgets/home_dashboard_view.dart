import 'dart:async';
import 'package:elecko26_new/core/widgets/app_network_image.dart';
import 'package:elecko26_new/core/widgets/pdf_image_renderer.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/core/utils/utility_functions.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/analysis_result.dart';
import 'member_card.dart';

class HomeDashboardView extends StatefulWidget {
  final bool isLoading;
  final Stream<List<Member>> membersStream;
  final List<Member> cachedMembers;
  final Map<String, AnalysisResult> cachedAnalysisResults;
  final String userRegion;
  final ValueChanged<Member> onMemberSelected;
  final VoidCallback onNavigateToSearch;
  final ValueChanged<String> onRegionChanged;

  const HomeDashboardView({
    Key? key,
    required this.isLoading,
    required this.membersStream,
    required this.cachedMembers,
    required this.cachedAnalysisResults,
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

  List<Member> _filteredAndSortedMembers = [];

  final List<String> _regions = [
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
    '강원특별자치도',
    '충청북도',
    '충청남도',
    '전북특별자치도',
    '전라남도',
    '경상북도',
    '경상남도',
    '제주특별자치도',
  ];

  @override
  void initState() {
    super.initState();
    _updateFilteredAndSortedMembers();
    _updateStats();
  }

  @override
  void didUpdateWidget(covariant HomeDashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userRegion != oldWidget.userRegion ||
        widget.cachedMembers != oldWidget.cachedMembers ||
        widget.cachedAnalysisResults != oldWidget.cachedAnalysisResults) {
      print(
          'HomeDashboardView: didUpdateWidget - userRegion: ${widget.userRegion}, cachedMembers count: ${widget.cachedMembers.length}');
      print('Current userRegion: ${widget.userRegion}');
      _updateFilteredAndSortedMembers();
      _updateStats();
    }
  }

  void _updateFilteredAndSortedMembers() {
    List<Member> filtered;
    if (widget.userRegion == '전국') {
      filtered = List.from(widget.cachedMembers);
    } else {
      filtered = widget.cachedMembers
          .where((m) => districtMatchesRegion(m.district, widget.userRegion))
          .toList();
    }

    filtered.sort((a, b) {
      final possibilityA =
          widget.cachedAnalysisResults[a.id]?.electionPossibility ??
              a.electionPossibility;
      final possibilityB =
          widget.cachedAnalysisResults[b.id]?.electionPossibility ??
              b.electionPossibility;
      return possibilityB.compareTo(possibilityA);
    });

    if (mounted) {
      setState(() {
        _filteredAndSortedMembers = filtered;
      });
    }
  }

  List<Member> get _top3 {
    return _filteredAndSortedMembers.take(3).toList();
  }

  List<Member> get _memberList {
    if (_filteredAndSortedMembers.length <= 3) {
      return [];
    }
    // 홈 탭에는 10위까지만 표시
    final end = _filteredAndSortedMembers.length > 10
        ? 10
        : _filteredAndSortedMembers.length;
    if (3 >= end) return [];
    return _filteredAndSortedMembers.sublist(3, end);
  }

  String _updateValueCache = '-';
  int _nesdcCountCache = 0;

  void _updateStats() {
    if (widget.cachedMembers.isEmpty) {
      _updateValueCache = '-';
      _nesdcCountCache = 0;
      return;
    }

    DateTime? latest;
    int totalPolls = 0;

    for (final member in widget.cachedMembers) {
      // 최신 업데이트 시간 계산
      if (member.lastAnalysisDate != null) {
        if (latest == null || member.lastAnalysisDate!.isAfter(latest)) {
          latest = member.lastAnalysisDate;
        }
      }
      // 여론조사 총계 계산
      totalPolls += member.pressReports.length;
    }

    _nesdcCountCache = totalPolls;
    if (latest == null) {
      _updateValueCache = '-';
    } else {
      _updateValueCache =
          '${latest.month}/${latest.day} ${latest.hour.toString().padLeft(2, '0')}:${latest.minute.toString().padLeft(2, '0')}';
    }
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
    super.build(context);

    if (widget.isLoading && widget.cachedMembers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_filteredAndSortedMembers.isNotEmpty) ...[
            _buildStatisticsSection(_filteredAndSortedMembers.length,
                _nesdcCountCache, _updateValueCache),
            const SizedBox(height: 24),
            _buildTop3Section(),
            _buildMemberList(),
          ] else if (widget.isLoading) ...[
            const Center(child: CircularProgressIndicator(color: Colors.red)),
          ] else ...[
            _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        '표시할 후보자가 없습니다.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.mediumGray,
        ),
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
            title: '분석후보',
            value: '$memberCount',
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

  Widget _buildTop3Section() {
    if (_top3.isEmpty) return const SizedBox.shrink();

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
                    const Icon(
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
            children: List.generate(_top3.length, (index) {
              final member = _top3[index];
              final rank = index + 1;
              final possibility = widget
                      .cachedAnalysisResults[member.id]?.electionPossibility ??
                  member.electionPossibility;
              return Padding(
                padding:
                    EdgeInsets.only(bottom: index < _top3.length - 1 ? 12 : 0),
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
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: member.imageUrl.startsWith('assets/')
                                ? Image.asset(
                                    member.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                      child: Text(
                                        member.name.substring(0, 1),
                                        style: AppTextStyles.headline4.copyWith(
                                          color: AppColors.mediumGray,
                                        ),
                                      ),
                                    ),
                                  )
                                : PdfImageRenderer.fromUrl(
                                    member.imageUrl,
                                    placeholder: (context) =>
                                        Container(color: AppColors.lightGrey),
                                    errorWidget: (context, error, stackTrace) =>
                                        Center(
                                      child: Text(
                                        member.name.substring(0, 1),
                                        style: AppTextStyles.headline4.copyWith(
                                          color: AppColors.mediumGray,
                                        ),
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
                              '${(possibility).toStringAsFixed(1)}%',
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

  Widget _buildMemberList() {
    if (_memberList.isEmpty) {
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
                '실시간 후보 순위',
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
              _memberList.length,
              (index) {
                final member = _memberList[index];
                final analysisResult = widget.cachedAnalysisResults[member.id];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MemberCard(
                    member: member,
                    rank: index + 4,
                    analysisResult: analysisResult,
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
