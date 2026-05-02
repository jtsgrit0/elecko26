import 'package:elecko26_new/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/core/utils/image_util.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/usecases/member_usecases.dart';
import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';

class MemberListPage extends StatefulWidget {
  const MemberListPage({Key? key}) : super(key: key);

  @override
  State<MemberListPage> createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> {
  late TextEditingController _searchController;
  late Stream<List<Member>> _membersStream;
  String _sortBy = 'possibility'; // name, party, possibility (당선 가능성 높은 순 기본)
  String _filterParty = 'all';
  String _searchQuery = '';
  String _userRegion = '전국';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _membersStream = sl<WatchMembersUseCase>().call();
    _loadUserRegion();
  }

  Future<void> _loadUserRegion() async {
    final region = await sl<MemberRepository>().getSelectedRegion();
    if (mounted) {
      setState(() {
        _userRegion = region ?? '전국';
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
            child: StreamBuilder<List<Member>>(
              stream: _membersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var members = snapshot.data ?? [];

                // 지역 필터링
                if (_userRegion != '전국') {
                  String shortRegion = _userRegion.substring(0, 2);
                  if (_userRegion == '세종특별자치시') shortRegion = '세종';
                  if (_userRegion == '제주특별자치도') shortRegion = '제주';
                  if (_userRegion == '전북특별자치도') shortRegion = '전북';

                  members = members
                      .where((m) => m.district.contains(shortRegion))
                      .toList();
                }

                // 검색 필터
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  members = members
                      .where((m) =>
                          m.name.toLowerCase().contains(query) ||
                          m.party.toLowerCase().contains(query) ||
                          m.district.toLowerCase().contains(query) ||
                          m.policies
                              .any((p) => p.toLowerCase().contains(query)) ||
                          m.achievementsList
                              .any((a) => a.toLowerCase().contains(query)))
                      .toList();
                }

                // 정당 필터
                if (_filterParty != 'all') {
                  members = members.where((m) {
                    if (_filterParty == 'democratic')
                      return m.party == '더불어민주당';
                    if (_filterParty == 'power') return m.party == '국민의힘';
                    if (_filterParty == 'other')
                      return m.party != '더불어민주당' && m.party != '국민의힘';
                    return true;
                  }).toList();
                }

                // 정렬
                if (_sortBy == 'name') {
                  members.sort((a, b) => a.name.compareTo(b.name));
                } else if (_sortBy == 'party') {
                  members.sort((a, b) => a.party.compareTo(b.party));
                } else if (_sortBy == 'possibility') {
                  members.sort((a, b) =>
                      b.electionPossibility.compareTo(a.electionPossibility));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return _MemberCard(member: members[index]);
                  },
                );
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
                  onPressed: () {},
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
              setState(() => _filterParty == 'democratic');
              Navigator.pop(context);
            }),
            _FilterOption('국민의힘', _filterParty == 'power', () {
              setState(() => _filterParty == 'power');
              Navigator.pop(context);
            }),
            _FilterOption('기타정당', _filterParty == 'other', () {
              setState(() => _filterParty == 'other');
              Navigator.pop(context);
            }),
          ],
        ),
      ),
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
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 프로필 이미지
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: member.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: AppNetworkImage(
                          imageUrl: ImageUtil.getProxyUrl(member.imageUrl,
                              width: 140, height: 140),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                              color: AppColors.lightGrey.withOpacity(0.3)),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            color: AppColors.white,
                            size: 35,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: 35,
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
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (_) => onPressed(),
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
