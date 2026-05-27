import 'package:elecko26_new/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/features/home/presentation/pages/member_detail_page.dart';
import 'package:elecko26_new/core/utils/image_util.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/usecases/member_usecases.dart';
import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/core/utils/utility_functions.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';

class MemberListPage extends StatefulWidget {
  const MemberListPage({Key? key}) : super(key: key);

  @override
  State<MemberListPage> createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> {
  late final TextEditingController _searchController;
  late Stream<List<Member>> _membersStream;
  List<Member> _allMembers = [];
  List<Member> _filteredMembers = [];
  final Map<String, String> _searchIndex = {};
  String _userRegion = '전국';
  String _searchQuery = '';
  String _sortBy = 'name';
  String _filterParty = 'all';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _membersStream = sl<WatchMembersUseCase>().call();
    _membersStream.listen((members) {
      if (mounted) {
        setState(() {
          _allMembers = members;
          _applyFilters();
        });
      }
    });
    _loadUserRegion();
  }

  void _applyFilters() {
    var members = List<Member>.from(_allMembers);

    // 지역 필터링
    if (_userRegion != '전국') {
      members = members
          .where((m) => districtMatchesRegion(m.district, _userRegion))
          .toList();
    }

    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      members = members.where((m) {
        final searchStr = _searchIndex.putIfAbsent(m.id, () {
          return '${m.name} ${m.party} ${m.district} ${m.policies.join(' ')} ${m.achievementsList.join(' ')}'.toLowerCase();
        });
        return searchStr.contains(query);
      }).toList();
    }

    // 정당 필터
    if (_filterParty != 'all') {
      members = members.where((m) {
        if (_filterParty == 'democratic') return m.party == '더불어민주당';
        if (_filterParty == 'power') return m.party == '국민의힘';
        if (_filterParty == 'other') return m.party != '더불어민주당' && m.party != '국민의힘';
        return true;
      }).toList();
    }

    // 정렬
    if (_sortBy == 'name') {
      members.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'party') {
      members.sort((a, b) => a.party.compareTo(b.party));
    } else if (_sortBy == 'possibility') {
      members.sort((a, b) => b.electionPossibility.compareTo(a.electionPossibility));
    }

    _filteredMembers = members;
  }

  Future<void> _loadUserRegion() async {
    final region = await sl<MemberRepository>().getSelectedRegion();
    if (mounted) {
      setState(() {
        _userRegion = region ?? '전국';
        _applyFilters();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('의원 목록'),
      ),
      body: Column(
        children: [
          // 검색 및 필터 섹션
          _buildSearchFilterSection(),
          // 의원 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredMembers.length,
              itemBuilder: (context, index) {
                return _MemberCard(member: _filteredMembers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 검색 및 필터 섹션
  Widget _buildSearchFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색바
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: '의원 이름, 정당, 지역, 약력 검색',
              hintStyle: AppTextStyles.bodySmall,
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 필터 버튼들
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: '정렬',
                  icon: Icons.sort,
                  onPressed: () => _showSortBottomSheet(),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '정당',
                  icon: Icons.group,
                  onPressed: () => _showPartyBottomSheet(),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '지역',
                  icon: Icons.location_on,
                  onPressed: () => _showRegionSelectionDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 정렬 옵션 바텀시트
  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정렬 방식', style: AppTextStyles.headline4),
            const SizedBox(height: 16),
            _SortOption('이름순', _sortBy == 'name', () {
              setState(() => _sortBy = 'name');
              Navigator.pop(context);
            }),
            _SortOption('당선율순', _sortBy == 'possibility', () {
              setState(() => _sortBy = 'possibility');
              Navigator.pop(context);
            }),
            _SortOption('정당순', _sortBy == 'party', () {
              setState(() => _sortBy = 'party');
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  // 정당 필터 바텀시트
  void _showPartyBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정당 필터', style: AppTextStyles.headline4),
            const SizedBox(height: 16),
            _FilterOption('전체', _filterParty == 'all', () {
              setState(() => _filterParty = 'all');
              Navigator.pop(context);
            }),
            _FilterOption('더불어민주당', _filterParty == 'democratic', () {
              setState(() => _filterParty = 'democratic');
              Navigator.pop(context);
            }),
            _FilterOption('국민의힘', _filterParty == 'power', () {
              setState(() => _filterParty = 'power');
              Navigator.pop(context);
            }),
            _FilterOption('기타정당', _filterParty == 'other', () {
              setState(() => _filterParty = 'other');
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  void _showRegionSelectionDialog() {
    final regions = [
      '전국',
      '서울특별시',
      '부산광역시',
      '광주광역시',
      '대전광역시',
      '울산광역시',
      '경기도',
      '강원특별자치도',
      '충청북도',
      '충청남도',
      '전북특별자치도',
      '전라남도',
      '경상북도',
      '경상남도',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('지역 선택'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: regions.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(regions[index]),
                  onTap: () {
                    final selectedRegion = regions[index];
                    print(
                        '[MemberListPage] 지역 선택 다이얼로그: "$selectedRegion" 선택됨');

                    // 이전 지역과 다른 경우에만 상태 업데이트
                    if (_userRegion != selectedRegion) {
                      setState(() {
                        _userRegion = selectedRegion;
                        print(
                            '[MemberListPage] setState 호출 후 _userRegion = "$_userRegion"');
                      });
                      sl<MemberRepository>().saveSelectedRegion(selectedRegion);
                      print('[MemberListPage] 선택된 지역 "$selectedRegion" 저장 완료');
                    } else {
                      print(
                          '[MemberListPage] 현재 지역과 동일한 지역("$selectedRegion")을 선택하여 상태 변경 없음');
                    }
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// 의원 카드
class _MemberCard extends StatelessWidget {
  final Member member;

  const _MemberCard({required this.member});

  Color _getPartyColor(String party) {
    if (party.contains('더불어민주당')) return const Color(0xFF004EA2);
    if (party.contains('국민의힘')) return const Color(0xFFE61E2B);
    if (party.contains('정의당')) return const Color(0xFFFFCC00);
    if (party.contains('진보당')) return const Color(0xFFD6001C);
    return AppColors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final possibility = member.electionPossibility * 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // 의원 상세 페이지로 이동
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MemberDetailPage(member: member),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 프로필 이미지
              SizedBox(
                width: 70,
                height: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: member.imageUrl.isEmpty
                      ? Image.asset(
                          'assets/images/avatar.png',
                          fit: BoxFit.cover,
                        )
                      : member.imageUrl.startsWith('assets/')
                          ? Image.asset(
                              member.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                'assets/images/avatar.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : AppNetworkImage(
                              imageUrl: member.imageUrl.contains('nesdc.go.kr')
                                  ? member.imageUrl
                                  : ImageUtil.getProxyUrl(member.imageUrl,
                                      width: 120, height: 120),
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Image.asset(
                                'assets/images/avatar.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 12),
              // 의원 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: AppTextStyles.headline4,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            member.party,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _getPartyColor(member.party),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          member.district,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 당선율 바
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: possibility / 100,
                        minHeight: 4,
                        backgroundColor: AppColors.lightGrey,
                        valueColor: AlwaysStoppedAnimation(
                          possibility > 70
                              ? AppColors.success
                              : possibility > 50
                                  ? AppColors.secondary
                                  : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 당선율 및 별표
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${possibility.toStringAsFixed(1)}%',
                    style: AppTextStyles.headline4.copyWith(
                      color: possibility > 70
                          ? AppColors.success
                          : possibility > 50
                              ? AppColors.secondary
                              : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          member.isFavorite ? Icons.star : Icons.star_border,
                          color:
                              member.isFavorite ? Colors.amber : AppColors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          sl<ToggleFavoriteUseCase>().call(member.id);
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 필터 칩
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onPressed: onPressed,
      backgroundColor: AppColors.white,
      side: BorderSide(
        color: AppColors.primary.withOpacity(0.3),
      ),
    );
  }
}

// 정렬 옵션
class _SortOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption(this.label, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing:
          isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: onTap,
    );
  }
}

// 필터 옵션
class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption(this.label, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(label),
      value: isSelected,
      onChanged: (_) => onTap(),
    );
  }
}
