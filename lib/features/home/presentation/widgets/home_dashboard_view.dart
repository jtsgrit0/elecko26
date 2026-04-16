import 'dart:async';
import 'package:flutter/material.dart';
import 'package:elecko26/core/theme/app_theme.dart';
import 'package:elecko26/core/utils/utility_functions.dart' show districtMatchesRegion;
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
  
  final List<String> _regions = [
    '전국', '서울특별시', '부산광역시', '대구광역시', '인천광역시',
    '광주광역시', '대전광역시', '울산광역시', '세종특별자치시',
    '경기도', '강원도', '충청북도', '충청남도', '전북특별자치도',
    '전라남도', '경상북도', '경상남도', '제주특별자치도'
  ];

  @override
  void initState() {
    super.initState();
    _subscription = widget.membersStream.listen((members) {
      if (mounted) setState(() => _displayMembers = members);
    });
    if (widget.cachedMembers.isNotEmpty) {
      setState(() => _displayMembers = widget.cachedMembers);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

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
                child: ListView.builder(
                  itemCount: _regions.length,
                  itemBuilder: (context, index) {
                    final region = _regions[index];
                    final isSelected = region == widget.userRegion;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onRegionChanged(region);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.lightGray,
                              width: isSelected ? 2 : 1,
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
                '당선 가능성 TOP3',
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
                padding: EdgeInsets.only(bottom: index < top3.length - 1 ? 12 : 0),
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
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.lightGray,
                        child: Text(
                          member.name.substring(0, 1),
                          style: AppTextStyles.headline4.copyWith(
                            color: AppColors.mediumGray,
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
                            '${possibility.toStringAsFixed(1)}%',
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
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(List<Member> members) {
    if (members.isEmpty) return const SizedBox.shrink();

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
    if (widget.isLoading && _displayMembers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 지역 필터링
    final filteredMembers = widget.userRegion == '전국'
        ? _displayMembers
        : _displayMembers.where((member) => districtMatchesRegion(member.district, widget.userRegion)).toList();

    // 당선 가능성 기준 정렬
    final sortedMembers = List<Member>.from(filteredMembers)
      ..sort((a, b) {
        final aPossibility = a.electionPossibility;
        final bPossibility = b.electionPossibility;
        return bPossibility.compareTo(aPossibility);
      });

    // TOP 3 추출
    final top3 = sortedMembers.take(3).toList();

    // 전체 멤버 리스트 (TOP3 제외)
    final memberList = sortedMembers.skip(3).toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isLoading) ...[
              _buildTop3Section(top3),
              _buildMemberList(memberList),
            ] else if (_displayMembers.isEmpty) ...[
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}