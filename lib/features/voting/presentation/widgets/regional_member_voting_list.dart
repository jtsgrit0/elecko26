import 'package:flutter/material.dart';
import 'package:elecko26/core/theme/app_theme.dart';
import 'package:elecko26/core/utils/utility_functions.dart';
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/domain/repositories/member_repository.dart';
import 'package:elecko26/app/injection_container.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:elecko26/data/datasources/local_storage_service.dart';

class RegionalMemberVotingList extends StatefulWidget {
  final String region;
  final VoidCallback? onChangeRegion;

  const RegionalMemberVotingList({
    super.key,
    required this.region,
    this.onChangeRegion,
  });

  @override
  State<RegionalMemberVotingList> createState() =>
      _RegionalMemberVotingListState();
}

class _RegionalMemberVotingListState extends State<RegionalMemberVotingList> {
  List<Member> _members = [];
  Map<String, String> _votes = {}; // district -> memberId
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegionalMembers();
  }

  @override
  void didUpdateWidget(RegionalMemberVotingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.region != widget.region) {
      _loadRegionalMembers();
    }
  }

  Future<void> _loadRegionalMembers() async {
    setState(() => _isLoading = true);
    try {
      final localStorage = sl<LocalStorageService>();
      final votes = await localStorage.getAllVotes();

      // 1단계: 캐시된 데이터를 먼저 즉시 표시 (블로킹 없음)
      final cached = await sl<MemberRepository>().getCachedMembers();
      if (cached.isNotEmpty) {
        final filtered = cached.where((m) {
          return districtMatchesRegion(m.district, widget.region);
        }).toList();
        if (mounted) {
          setState(() {
            _members = filtered;
            _votes = votes;
            _isLoading = false;
          });
        }
        return; // 캐시 데이터로 즉시 표시 완료
      }

      // 2단계: 캐시 비어있을 때만 전체 로드 (최초 1회)
      final allMembers = await sl<MemberRepository>().getAllMembers();
      final filtered = allMembers.where((m) {
        return districtMatchesRegion(m.district, widget.region);
      }).toList();

      if (mounted) {
        setState(() {
          _members = filtered;
          _votes = votes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleVote(String district, Member member) async {
    final localStorage = sl<LocalStorageService>();
    final currentVote = _votes[district];
    
    if (currentVote == member.id) {
      // 투표 취소
      await localStorage.removeVote(district);
      setState(() {
        _votes.remove(district);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} 의원 지지를 취소했습니다.')),
        );
      }
    } else {
      // 투표하기 (또는 변경)
      await localStorage.saveVote(district, member.id);
      setState(() {
        _votes[district] = member.id;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} 의원을 지지하셨습니다!')),
        );
      }
    }
  }

  Map<String, List<Member>> get _groupedMembers {
    final Map<String, List<Member>> grouped = {};
    for (final member in _members) {
      if (!grouped.containsKey(member.district)) {
        grouped[member.district] = [];
      }
      grouped[member.district]!.add(member);
    }
    // 선거구명(district)을 사전순으로 정렬
    final sortedKeys = grouped.keys.toList()..sort();
    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.region} 지역의 등록된 후보가 없습니다.',
              style: AppTextStyles.bodyMedium,
            ),
            if (widget.onChangeRegion != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: widget.onChangeRegion,
                icon: const Icon(Icons.location_on),
                label: const Text('다른 지역 선택'),
              ),
            ],
          ],
        ),
      );
    }

    final groupedMembers = _groupedMembers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              const Icon(Icons.how_to_vote,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.region} 의원 투표',
                  style: AppTextStyles.headline3
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (widget.onChangeRegion != null)
                TextButton(
                  onPressed: widget.onChangeRegion,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('지역 변경', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: groupedMembers.length,
            itemBuilder: (context, index) {
              final district = groupedMembers.keys.elementAt(index);
              final membersInDistrict = groupedMembers[district]!;
              return _buildDistrictSection(district, membersInDistrict);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDistrictSection(String district, List<Member> membersInDistrict) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                color: AppColors.primary,
                margin: const EdgeInsets.only(right: 8),
              ),
              Text(
                district,
                style: AppTextStyles.headline3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              const Spacer(),
              Text(
                '1표 행사가능',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...membersInDistrict.map((member) {
          final isVoted = _votes[district] == member.id;
          return _RegionalMemberCard(
            member: member,
            isVoted: isVoted,
            onVote: () => _handleVote(district, member),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _RegionalMemberCard extends StatelessWidget {
  final Member member;
  final bool isVoted;
  final VoidCallback onVote;

  const _RegionalMemberCard({
    required this.member,
    required this.isVoted,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isVoted ? 4 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isVoted ? AppColors.primary : Colors.grey.withOpacity(0.2),
          width: isVoted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 프로필 이미지
            Hero(
              tag: 'member_vote_${member.id}',
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(12),
                  image: member.imageUrl.trim().isEmpty
                      ? null
                      : DecorationImage(
                          image: CachedNetworkImageProvider(member.imageUrl),
                          fit: BoxFit.cover,
                        ),
                ),
                child: member.imageUrl.trim().isEmpty
                    ? Center(
                        child: Text(
                          getProfileInitial(member.name),
                          style: AppTextStyles.headline4,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            // 의원 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: AppTextStyles.headline3
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (isVoted) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.party,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.mediumGray),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onVote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isVoted 
                            ? AppColors.primary 
                            : AppColors.primary.withOpacity(0.1),
                        foregroundColor: isVoted 
                            ? AppColors.white 
                            : AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isVoted ? '지지함' : '지지하기',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
