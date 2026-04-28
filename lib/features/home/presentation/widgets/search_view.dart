import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:elecko26_new/core/utils/image_util.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/core/utils/utility_functions.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/features/home/presentation/widgets/member_card.dart';

class SearchView extends StatefulWidget {
  final Stream<List<Member>> membersStream;
  final List<Member> cachedMembers;
  final String userRegion;
  final Function(Member) onMemberSelected;

  const SearchView({
    Key? key,
    required this.membersStream,
    required this.cachedMembers,
    required this.userRegion,
    required this.onMemberSelected,
  }) : super(key: key);

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchCategory = '전체';
  String _searchOffice = '전체';
  Timer? _debounceTimer;
  List<Member> _allMembers = [];
  List<Member> _filteredMembers = [];
  StreamSubscription? _membersSubscription;

  @override
  bool get wantKeepAlive => true;

  static const List<String> _searchCategories = ['전체', '광역', '기초', '의회'];
  static const Map<String, List<String>> _officeOptionsByCategory = {
    '전체': [
      '전체',
      '도지사',
      '광역시장',
      '특별시장',
      '특별자치도지사',
      '시장',
      '군수',
      '구청장',
      '도의원',
      '시의원',
      '구의원',
      '군의원'
    ],
    '광역': ['전체', '도지사', '광역시장', '특별시장', '특별자치도지사'],
    '기초': ['전체', '시장', '군수', '구청장'],
    '의회': ['전체', '도의원', '시의원', '구의원', '군의원'],
  };

  @override
  void initState() {
    super.initState();
    _allMembers = widget.cachedMembers;
    _applyFilters();
    _membersSubscription = widget.membersStream.listen((members) {
      if (mounted) {
        setState(() {
          _allMembers = members;
          _applyFilters();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _membersSubscription?.cancel();
    super.dispose();
  }

  List<Member> _getFilteredMembers(List<Member> members) {
    return members
        .where((m) => districtMatchesRegion(m.district, widget.userRegion))
        .toList();
  }

  Widget _buildSearchPage() {
    return Column(
      children: [
        _buildSearchField(),
        _buildSearchFilters(),
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            }
          });
        },
        decoration: InputDecoration(
          hintText: '후보자 이름, 정당, 지역 등으로 검색',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchFilters() {
    final officeOptions = _officeOptionsByCategory[_searchCategory] ??
        _officeOptionsByCategory['전체']!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '후보 분류',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _searchCategories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: category,
                    isSelected: _searchCategory == category,
                    onTap: () {
                      setState(() {
                        _searchCategory = category;
                        _searchOffice = '전체';
                        _applyFilters();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '직위 필터',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: officeOptions.map((office) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: office,
                    isSelected: _searchOffice == office,
                    onTap: () {
                      setState(() {
                        _searchOffice = office;
                        _applyFilters();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightGrey,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? AppColors.white : AppColors.darkGray,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    final filtered = _allMembers.where((m) {
      if (!districtMatchesRegion(m.district, widget.userRegion)) return false;
      if (!_matchesSearchCategory(m)) return false;
      if (!_matchesSearchOffice(m)) return false;

      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(query) ||
          m.party.toLowerCase().contains(query) ||
          m.district.toLowerCase().contains(query);
    }).toList();

    // 상위 50명 이미지 선행 로딩
    _precacheMemberImages(context, filtered.take(50).toList());

    // 당선 가능성 높은 순으로 정렬
    filtered.sort(
        (a, b) => b.electionPossibility.compareTo(a.electionPossibility));

    _filteredMembers = filtered;
  }

  Widget _buildSearchResults() {
    if (_allMembers.isEmpty && _filteredMembers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildResultList(_filteredMembers);
  }

  Widget _buildResultList(List<Member> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MemberCard(
            key: ValueKey(results[index].id),
            member: results[index],
            onTap: () => widget.onMemberSelected(results[index]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수 호출
    return _buildSearchPage();
  }

  bool _matchesSearchCategory(Member member) {
    if (_searchCategory == '전체') {
      return true;
    }

    final district = member.district;
    switch (_searchCategory) {
      case '광역':
        return district.contains('도지사') ||
            district.contains('광역시장') ||
            district.contains('특별시장') ||
            district.contains('특별자치도지사');
      case '기초':
        return (district.endsWith('시장') &&
                !district.contains('광역시장') &&
                !district.contains('특별시장')) ||
            district.endsWith('군수') ||
            district.endsWith('구청장');
      case '의회':
        return district.endsWith('도의원') ||
            district.endsWith('시의원') ||
            district.endsWith('구의원') ||
            district.endsWith('군의원');
      default:
        return true;
    }
  }

  bool _matchesSearchOffice(Member member) {
    if (_searchOffice == '전체') {
      return true;
    }

    final district = member.district;
    switch (_searchOffice) {
      case '도지사':
        return district.contains('도지사') && !district.contains('특별자치도지사');
      case '광역시장':
        return district.contains('광역시장');
      case '특별시장':
        return district.contains('특별시장');
      case '특별자치도지사':
        return district.contains('특별자치도지사');
      case '시장':
        return district.endsWith('시장') &&
            !district.contains('광역시장') &&
            !district.contains('특별시장');
      default:
        return district.endsWith(_searchOffice);
    }
  }

  void _precacheMemberImages(BuildContext context, List<Member> members) {
    for (final member in members) {
      if (member.imageUrl.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(
            ImageUtil.getProxyUrl(member.imageUrl, width: 120, height: 120),
          ),
          context,
        );
      }
    }
  }
}
