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

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchCategory = '전체';
  String _searchOffice = '전체';

  // PDF 파일의 실제 선거 유형에 맞춘 카테고리
  static const List<String> _searchCategories = [
    '전체',
    '광역단체장',
    '기초단체장',
    '광역의회의원',
    '기초의회의원',
    '비례대표'
  ];
  static const Map<String, List<String>> _officeOptionsByCategory = {
    '전체': ['전체', '시·도지사', '구·시·군의장', '시·도의회의원', '구·시·군의회의원', '기초의원비례대표'],
    '광역단체장': ['전체', '시·도지사'],
    '기초단체장': ['전체', '구·시·군의장'],
    '광역의회의원': ['전체', '시·도의회의원'],
    '기초의회의원': ['전체', '구·시·군의회의원'],
    '비례대표': ['전체', '기초의원비례대표'],
  };

  @override
  void dispose() {
    _searchController.dispose();
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
          setState(() {
            _searchQuery = value;
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

  Widget _buildSearchResults() {
    return StreamBuilder<List<Member>>(
      stream: widget.membersStream,
      builder: (context, snapshot) {
        final allMembers = snapshot.data ?? widget.cachedMembers;
        if (allMembers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredMembers = allMembers.where((m) {
          // PDF에서 추출한 constituency 필드 사용
          final constituency = m.constituency;

          // 지역 필터링 적용 (사용자 지역과 일치하는 선거구만 표시)
          if (!constituency.contains(widget.userRegion)) return false;

          if (!_matchesSearchCategory(m)) return false;
          if (!_matchesSearchOffice(m)) return false;

          final query = _searchQuery.toLowerCase();
          return m.name.toLowerCase().contains(query) ||
              m.party.toLowerCase().contains(query) ||
              constituency.toLowerCase().contains(query) ||
              m.description.toLowerCase().contains(query) ||
              m.policies.any((p) => p.toLowerCase().contains(query)) ||
              m.achievementsList.any((a) => a.toLowerCase().contains(query));
        }).toList();

        // 당선 가능성 높은 순으로 정렬
        filteredMembers.sort(
            (a, b) => b.electionPossibility.compareTo(a.electionPossibility));

        if (filteredMembers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: AppColors.grey),
                const SizedBox(height: 16),
                Text(
                  '검색 결과가 없습니다',
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredMembers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MemberCard(
                key: ValueKey(filteredMembers[index].id),
                member: filteredMembers[index],
                onTap: () => widget.onMemberSelected(filteredMembers[index]),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSearchPage();
  }

  bool _matchesSearchCategory(Member member) {
    if (_searchCategory == '전체') {
      return true;
    }

    // PDF에서 추출된 선거구 형식에 맞춘 매칭 로직
    final constituency = member.constituency;
    switch (_searchCategory) {
      case '광역단체장':
        return constituency.contains('시·도지사');
      case '기초단체장':
        return constituency.contains('구·시·군의장');
      case '광역의회의원':
        return constituency.contains('시·도의회의원');
      case '기초의회의원':
        return constituency.contains('구·시·군의회의원');
      case '비례대표':
        return constituency.contains('기초의원비례대표');
      default:
        return true;
    }
  }

  bool _matchesSearchOffice(Member member) {
    if (_searchOffice == '전체') {
      return true;
    }

    final constituency = member.constituency;
    switch (_searchOffice) {
      case '시·도지사':
        return constituency.contains('시·도지사');
      case '구·시·군의장':
        return constituency.contains('구·시·군의장');
      case '시·도의회의원':
        return constituency.contains('시·도의회의원');
      case '구·시·군의회의원':
        return constituency.contains('구·시·군의회의원');
      case '기초의원비례대표':
        return constituency.contains('기초의원비례대표');
      default:
        return false;
    }
  }
}
