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

  List<String> _sidoOptions = ['전체'];
  Map<String, List<String>> _sigunguOptions = {
    '전체': ['전체']
  };
  String _selectedSido = '전체';
  String _selectedSigungu = '전체';

  @override
  void initState() {
    super.initState();
    _updateFilterOptions();
  }

  void _updateFilterOptions() {
    final allMembers = widget.cachedMembers;
    if (allMembers.isEmpty) return;

    final sidos = <String>{'전체'};
    final sigungus = <String, Set<String>>{
      '전체': {'전체'}
    };

    for (final member in allMembers) {
      if (member.sido.isNotEmpty) {
        sidos.add(member.sido);
        if (!sigungus.containsKey(member.sido)) {
          sigungus[member.sido] = {'전체'};
        }
        if (member.sigungu.isNotEmpty) {
          sigungus[member.sido]!.add(member.sigungu);
        }
      }
    }

    setState(() {
      _sidoOptions = sidos.toList()..sort();
      _sigunguOptions =
          sigungus.map((key, value) => MapEntry(key, value.toList()..sort()));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final sigunguOptions = _sigunguOptions[_selectedSido] ?? ['전체'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '시·도',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sidoOptions.map((sido) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: sido,
                    isSelected: _selectedSido == sido,
                    onTap: () {
                      setState(() {
                        _selectedSido = sido;
                        _selectedSigungu = '전체';
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '시·군·구',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: sigunguOptions.map((sigungu) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: sigungu,
                    isSelected: _selectedSigungu == sigungu,
                    onTap: () {
                      setState(() {
                        _selectedSigungu = sigungu;
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
          // 지역 필터링
          if (_selectedSido != '전체' && m.sido != _selectedSido) {
            return false;
          }
          if (_selectedSigungu != '전체' && m.sigungu != _selectedSigungu) {
            return false;
          }

          // 검색어 필터링
          final query = _searchQuery.toLowerCase();
          if (query.isNotEmpty) {
            return m.name.toLowerCase().contains(query) ||
                m.party.toLowerCase().contains(query) ||
                m.constituency.toLowerCase().contains(query) ||
                m.description.toLowerCase().contains(query) ||
                m.policies.any((p) => p.toLowerCase().contains(query)) ||
                m.achievementsList.any((a) => a.toLowerCase().contains(query));
          }

          return true;
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
}
