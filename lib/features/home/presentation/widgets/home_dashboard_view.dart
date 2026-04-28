import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/core/utils/utility_functions.dart'
    show districtMatchesRegion;
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/features/home/presentation/widgets/member_card.dart';
import 'package:elecko26_new/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:get_it/get_it.dart';

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

class _HomeDashboardViewState extends State<HomeDashboardView>
    with AutomaticKeepAliveClientMixin {
  List<Member> _displayMembers = [];
  StreamSubscription<List<Member>>? _subscription;
  Map<String, double> _memberPossibilities = {}; // 멤버별 실제 당선 가능성 저장
  bool _isCalculatingPossibilities = false;
  Timer? _timer; // 실시간 시간 업데이트를 위한 타이머

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
    '강원도',
    '충청북도',
    '충청남도',
    '전북특별자치도',
    '전라남도',
    '경상북도',
    '경상남도',
    '제주특별자치도'
  ];

  @override
  void initState() {
    super.initState();

    // 캐시된 데이터가 있으면 먼저 표시하고 계산 시작
    if (widget.cachedMembers.isNotEmpty) {
      _displayMembers = widget.cachedMembers;
      // 비동기로 당선 가능성 계산 시작
      _calculateMemberPossibilities(widget.cachedMembers);
    }

    // 스트림 데이터가 도착하면 업데이트 (디바운싱 적용)
    _subscription = widget.membersStream.listen((members) {
      if (mounted && members.isNotEmpty) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _displayMembers = members;
              _updateCalculatedData();
            });
            _calculateMemberPossibilities(members);
          }
        });
      }
    });

    // 초기 데이터 계산
    if (_displayMembers.isNotEmpty) {
      _updateCalculatedData();
    }

    // 실시간 시간 업데이트를 위한 타이머 시작 (3분마다 업데이트)
    _timer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Timer? _debounceTimer;
  List<Member> _filteredSortedMembers = [];
  List<Member> _top3 = [];
  List<Member> _memberList = [];
  int _nesdcCount = 0;
  String _updateValue = '';

  // 캐시 변수
  List<Member>? _lastSourceMembers;
  String? _lastSourceRegion;

  void _updateCalculatedData() {
    // 최적화: 소스 데이터와 지역이 변경되지 않았다면 계산 스킵
    if (_lastSourceMembers == _displayMembers && 
        _lastSourceRegion == widget.userRegion && 
        _filteredSortedMembers.isNotEmpty) {
      return;
    }

    final filtered = widget.userRegion == '전국'
        ? _displayMembers
        : _displayMembers
            .where((member) =>
                districtMatchesRegion(member.district, widget.userRegion))
            .toList();

    _filteredSortedMembers = List<Member>.from(filtered)
      ..sort((a, b) {
        final aPossibility = _getMemberPossibility(a);
        final bPossibility = _getMemberPossibility(b);
        return bPossibility.compareTo(aPossibility);
      });

    _top3 = _filteredSortedMembers.take(3).toList();
    _memberList = _filteredSortedMembers
        .skip(3)
        .where((member) => _getMemberPossibility(member) >= 0.05)
        .take(10)
        .toList();

    _lastSourceMembers = _displayMembers;
    _lastSourceRegion = widget.userRegion;

    _nesdcCount = filtered.fold<int>(
        0,
        (sum, member) =>
            sum + member.polls.where((p) => p.id.startsWith('nesdc_')).length);

    final latestAnalysis = filtered.isNotEmpty
        ? filtered
            .map((m) => m.lastAnalysisDate)
            .reduce((a, b) => a.isAfter(b) ? a : b)
        : null;

    final now = latestAnalysis ?? DateTime.now();
    _updateValue =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  bool _isCalculating = false;
  List<Member>? _lastCalculatedMembers;

  Future<void> _calculateMemberPossibilities(List<Member> members) async {
    if (members.isEmpty) return;
    if (_isCalculating) return;
    
    // 단순 개수 비교가 아닌 데이터 변경 확인 (얕은 비교)
    if (_lastCalculatedMembers != null && 
        _lastCalculatedMembers!.length == members.length &&
        _lastCalculatedMembers!.first.id == members.first.id &&
        _lastCalculatedMembers!.last.id == members.last.id) {
      return;
    }

    _isCalculating = true;
    if (mounted) setState(() => _isCalculatingPossibilities = true);

    try {
      final useCase = GetIt.instance<CalculateElectionPossibilityUseCase>();

      // 상위 후보 정렬 (기본 점수 기준)
      final topCandidates = List<Member>.from(members)
        ..sort((a, b) => b.electionPossibility.compareTo(a.electionPossibility));
      
      // 상위 50명만 우선적으로 계산
      final limitedMembers = topCandidates.take(50).toList();

      for (var i = 0; i < limitedMembers.length; i++) {
        if (!mounted) break;
        
        final member = limitedMembers[i];
        try {
          final result = await useCase.call(member.id);
          _memberPossibilities[member.id] = result.electionPossibility;
        } catch (e) {
          _memberPossibilities[member.id] = member.electionPossibility;
        }

        // 10명마다 한 번씩만 UI 업데이트하여 부하 감소
        if (i > 0 && i % 10 == 0) {
          if (mounted) {
            setState(() {
              _updateCalculatedData();
            });
          }
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      if (mounted) {
        setState(() {
          _updateCalculatedData();
          _isCalculatingPossibilities = false;
          _lastCalculatedMembers = members;
        });
      }
    } finally {
      _isCalculating = false;
      if (mounted) setState(() => _isCalculatingPossibilities = false);
    }
  }

  double _getMemberPossibility(Member member) {
    return _memberPossibilities[member.id] ?? member.electionPossibility;
  }

  @override
  void didUpdateWidget(HomeDashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userRegion != oldWidget.userRegion ||
        widget.cachedMembers != oldWidget.cachedMembers) {
      _updateCalculatedData();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true; // 상태 유지 활성화

  void _showRegionSelectionModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
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
              final possibility = _getMemberPossibility(member);
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
                                    placeholder: (context, url) => Container(color: AppColors.lightGrey),
                                    errorWidget: (context, url, error) => Center(
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필요

    // 캐시된 데이터가 있으면 바로 표시, 로딩 중이어도 기존 데이터 유지
    if (widget.isLoading &&
        _displayMembers.isEmpty &&
        widget.cachedMembers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 이미 _updateCalculatedData()에서 계산됨
    final filteredMembers = _filteredSortedMembers;
    final top3 = _top3;
    final memberList = _memberList;
    final updateValue = _updateValue;
    final nesdcCount = _nesdcCount;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
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
            ] else if (widget.isLoading || _isCalculatingPossibilities) ...[
              // 데이터가 없고 로딩 중일 때만 로딩바 표시
              const Center(child: CircularProgressIndicator()),
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
