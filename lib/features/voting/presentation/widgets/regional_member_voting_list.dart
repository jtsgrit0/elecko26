import 'package:flutter/material.dart';
import 'package:elecko26/core/theme/app_theme.dart';
import 'package:elecko26/core/utils/utility_functions.dart';
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/domain/repositories/member_repository.dart';
import 'package:elecko26/app/injection_container.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RegionalMemberVotingList extends StatefulWidget {
  final String region;

  const RegionalMemberVotingList({
    Key? key,
    required this.region,
  }) : super(key: key);

  @override
  State<RegionalMemberVotingList> createState() =>
      _RegionalMemberVotingListState();
}

class _RegionalMemberVotingListState extends State<RegionalMemberVotingList> {
  List<Member> _members = [];
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
      // 지역구 필터링 (예: "서울", "부산" 등 광역 단위 매칭)
      final allMembers = await sl<MemberRepository>().getAllMembers();
      final filtered = allMembers.where((m) {
        return districtMatchesRegion(m.district, widget.region);
      }).toList();

      setState(() {
        _members = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_members.isEmpty) {
      return Center(
        child: Text(
          '${widget.region} 지역의 등록된 후보가 없습니다.',
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '${widget.region} 지역구 의원 투표',
                style: AppTextStyles.headline3
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              return _RegionalMemberCard(member: _members[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _RegionalMemberCard extends StatelessWidget {
  final Member member;

  const _RegionalMemberCard({
    Key? key,
    required this.member,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 프로필 이미지
            Hero(
              tag: 'member_vote_${member.id}',
              child: Container(
                width: 80,
                height: 80,
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
                  Text(
                    member.name,
                    style: AppTextStyles.headline3
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${member.party} | ${member.district}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.mediumGray),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('${member.name} 의원을 지지하셨습니다!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('지지하기',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
