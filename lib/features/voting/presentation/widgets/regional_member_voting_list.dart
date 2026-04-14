import 'package:flutter/material.dart';
import 'package:elecko26/core/theme/app_theme.dart';
import 'package:elecko26/core/utils/utility_functions.dart';
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/domain/repositories/member_repository.dart';
import 'package:elecko26/app/injection_container.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:elecko26/data/datasources/local_storage_service.dart';
import 'dart:async';
import 'package:elecko26/features/home/presentation/widgets/member_card.dart';
import 'package:elecko26/features/home/presentation/pages/member_detail_page.dart';

class RegionalMemberVotingList extends StatefulWidget {
  final String region;
  final VoidCallback? onChangeRegion;
  final VoidCallback? onVoteChanged;

  const RegionalMemberVotingList({
    super.key,
    required this.region,
    this.onChangeRegion,
    this.onVoteChanged,
  });

  @override
  State<RegionalMemberVotingList> createState() =>
      _RegionalMemberVotingListState();
}

class _RegionalMemberVotingListState extends State<RegionalMemberVotingList> {
  List<Member> _members = [];
  Map<String, String> _votes = {}; // district -> memberId
  Map<String, int> _voteTimestamps = {}; // district -> timestamp
  bool _isLoading = true;
  StreamSubscription<List<Member>>? _memberSubscription;

  @override
  void initState() {
    super.initState();
    _loadRegionalMembers();
    _startMemberSubscription();
  }

  void _startMemberSubscription() {
    _memberSubscription?.cancel();
    _memberSubscription = sl<MemberRepository>().watchAllMembers().listen((allMembers) {
      if (mounted) {
        final filtered = allMembers.where((m) {
          return districtMatchesRegion(m.district, widget.region);
        }).toList();
        setState(() {
          _members = filtered;
        });
      }
    });
  }

  @override
  void didUpdateWidget(RegionalMemberVotingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.region != widget.region) {
      _loadRegionalMembers();
      _startMemberSubscription();
    }
  }

  @override
  void dispose() {
    _memberSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadRegionalMembers() async {
    setState(() => _isLoading = true);
    try {
      final localStorage = sl<LocalStorageService>();
      final votes = await localStorage.getAllVotes();
      final timestamps = await localStorage.getAllVoteTimestamps();

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
            _voteTimestamps = timestamps;
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
          _voteTimestamps = timestamps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleVote(String district, Member member) async {
    final memberRepository = sl<MemberRepository>();
    final currentVote = _votes[district];
    final lastVoteTime = _voteTimestamps[district];

    // 24시간 제한 체크
    if (lastVoteTime != null) {
      final diff = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastVoteTime));
      if (diff.inHours < 24) {
        final remainingHours = 23 - diff.inHours;
        final remainingMinutes = 59 - (diff.inMinutes % 60);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '지지 후보는 24시간마다 변경할 수 있습니다. (남은 시간: 약 $remainingHours시간 $remainingMinutes분)'),
              backgroundColor: Colors.orange[800],
            ),
          );
        }
        return;
      }
    }

    if (currentVote == member.id) {
      // 투표 취소
      await memberRepository.removeSupportVote(district);
      setState(() {
        _votes.remove(district);
        _voteTimestamps.remove(district);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} 의원 지지를 취소했습니다.')),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onVoteChanged?.call());
      }
    } else {
      // 투표하기 (또는 변경)
      final now = DateTime.now().millisecondsSinceEpoch;
      await memberRepository.saveSupportVote(
        district,
        member.id,
        timestamp: now,
      );
      setState(() {
        _votes[district] = member.id;
        _voteTimestamps[district] = now;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} 의원을 지지하셨습니다!')),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onVoteChanged?.call());
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
    // 선거구명(district)을 사용자 요청 순서(도지사 > 시장 > 구의원 > 군수 > 군의원)에 따라 정렬
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final priorityA = getDistrictSortPriority(a);
      final priorityB = getDistrictSortPriority(b);
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      return a.compareTo(b); // 우선순위가 같으면 가나다순
    });
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
                      Expanded(
                        child: Text(
                          member.name,
                          style: AppTextStyles.headline3
                              .copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVoted) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.party,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.mediumGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 우측 '지지하기' 버튼
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: onVote,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
