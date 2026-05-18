import 'package:flutter/material.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/core/utils/utility_functions.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/core/widgets/app_network_image.dart';
import 'package:elecko26_new/data/datasources/local_storage_service.dart';
import 'dart:async';
import 'package:elecko26_new/features/home/presentation/widgets/member_card.dart';
import 'package:elecko26_new/features/home/presentation/pages/member_detail_page.dart';
import 'package:elecko26_new/core/utils/image_util.dart';

class RegionalMemberVotingList extends StatefulWidget {
  final String region;
  final VoidCallback? onChangeRegion;
  final VoidCallback? onVoteChanged;
  final Function(Member)? onMemberVoted;

  const RegionalMemberVotingList({
    super.key,
    required this.region,
    this.onChangeRegion,
    this.onVoteChanged,
    this.onMemberVoted,
  });

  @override
  State<RegionalMemberVotingList> createState() =>
      _RegionalMemberVotingListState();
}

class _RegionalMemberVotingListState extends State<RegionalMemberVotingList>
    with SingleTickerProviderStateMixin {
  List<Member> _members = [];
  Map<String, String> _votes = {}; // district -> memberId
  Map<String, int> _voteTimestamps = {}; // district -> timestamp
  bool _isLoading = true;
  StreamSubscription<List<Member>>? _memberSubscription;
  StreamSubscription<Map<String, String>>? _voteSubscription;

  // 지지하기 성공 애니메이션을 위한 맵
  Map<String, bool> _recentlyVoted = {}; // memberId -> recently voted

  @override
  void initState() {
    super.initState();
    _loadRegionalMembers();
    _startMemberSubscription();
    _startVoteSubscription();
  }

  void _startMemberSubscription() {
    _memberSubscription?.cancel();
    _memberSubscription =
        sl<MemberRepository>().watchAllMembers().listen((allMembers) {
      if (mounted) {
        final filtered = allMembers.where((m) {
          return districtMatchesRegion(m.district, widget.region);
        }).toList();
        setState(() {
          _members = filtered;
          _updateGroupedMembers(); // 데이터 변경 시 그룹화 캐시 업데이트
        });
      }
    });
  }

  void _startVoteSubscription() {
    _voteSubscription?.cancel();
    _voteSubscription = sl<MemberRepository>().watchAllVotes().listen((votes) {
      if (mounted) {
        setState(() {
          _votes = votes;
          _updateGroupedMembers(); // 데이터 변경 시 그룹화 캐시 업데이트
        });
      }
    });
  }

  // 선거구 그룹화 결과 캐싱 (매 빌드 시마다 연산 방지)
  Map<String, List<Member>> _cachedGroupedMembers = {};

  void _updateGroupedMembers() {
    final Map<String, List<Member>> grouped = {};
    for (final member in _members) {
      if (!grouped.containsKey(member.district)) {
        grouped[member.district] = [];
      }
      grouped[member.district]!.add(member);
    }

    // 선거구명(district)을 사용자 요청 순서(도지사 > 시장 > 구의원 > 군수 > 군의원)에 따라 정렬
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final orderA = getDistrictSortPriority(a);
        final orderB = getDistrictSortPriority(b);
        if (orderA != orderB) return orderA.compareTo(orderB);
        return a.compareTo(b);
      });

    final Map<String, List<Member>> sortedGrouped = {};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    _cachedGroupedMembers = sortedGrouped;
  }

  @override
  void didUpdateWidget(RegionalMemberVotingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.region != widget.region) {
      _loadRegionalMembers();
      _startMemberSubscription();
      _startVoteSubscription();
    }
  }

  @override
  void dispose() {
    _memberSubscription?.cancel();
    _voteSubscription?.cancel();
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
            _updateGroupedMembers();
          });
        }
        return;
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
          _updateGroupedMembers();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleVote(String district, Member member) {
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

    // 기존 지지 후보가 있다면 즉시 삭제 (같은 지역구)
    if (currentVote != null && currentVote != member.id) {
      // 기존 후보의 체크 표시 제거
      setState(() {
        _recentlyVoted.remove(currentVote);
      });
    }

    // [Optimistic Update] 네트워크 요청 전 즉시 UI 반영
    final now = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _votes[district] = member.id;
      _voteTimestamps[district] = now;
      _recentlyVoted[member.id] = true; // 애니메이션 표시
    });

    // 애니메이션 효과 제거 (2초 후)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _recentlyVoted.remove(member.id);
        });
      }
    });

    // 백그라운드에서 실제 저장 (UI 블로킹 방지)
    memberRepository
        .saveSupportVote(
      district,
      member.id,
      timestamp: now,
    )
        .catchError((e) {
      // 실패 시 원래 상태로 복구
      if (mounted) {
        setState(() {
          if (currentVote != null) {
            _votes[district] = currentVote;
          } else {
            _votes.remove(district);
          }
          if (lastVoteTime != null) {
            _voteTimestamps[district] = lastVoteTime;
          } else {
            _voteTimestamps.remove(district);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('지지하기 처리 중 오류가 발생했습니다.')),
        );
      }
      return null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name} 의원을 지지하셨습니다! \n지지후보 탭에서 확인하세요.'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: '지지후보 보기',
            textColor: AppColors.white,
            onPressed: () {
              // 부모 위젯에서 탭 전환을 처리할 수 있도록 콜백 호출
              widget.onMemberVoted?.call(member);
              // 필요하다면 여기서 탭 전환을 요청할 수 있음
            },
          ),
        ),
      );

      // 즉시 실시간 업데이트 - 새로고침 없이 바로 반영
      widget.onVoteChanged?.call();
      widget.onMemberVoted?.call(member);
    }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              const Icon(Icons.how_to_vote, color: AppColors.primary, size: 24),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('지역 변경',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        Expanded(
          child: RepaintBoundary(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _cachedGroupedMembers.length,
              itemBuilder: (context, index) {
                final district = _cachedGroupedMembers.keys.elementAt(index);
                final membersInDistrict = _cachedGroupedMembers[district]!;
                return _buildDistrictSection(district, membersInDistrict);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistrictSection(
      String district, List<Member> membersInDistrict) {
    return Column(
      key: ValueKey(_votes[district]), // 지지 상태 변경 시 섹션 전체 리빌드
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
            key: ValueKey(
                '$district-${member.id}-$isVoted-${_recentlyVoted[member.id] ?? false}'), // 카드 단위 리빌드
            member: member,
            isVoted: isVoted,
            onVote: () => _handleVote(district, member),
            recentlyVoted: _recentlyVoted[member.id] ?? false,
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
  final bool recentlyVoted;

  const _RegionalMemberCard({
    Key? key,
    required this.member,
    required this.isVoted,
    required this.onVote,
    this.recentlyVoted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: recentlyVoted
              ? AppColors.success
              : (isVoted ? AppColors.primary : AppColors.lightGray),
          width: recentlyVoted ? 2 : (isVoted ? 2 : 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 프로필 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                height: 70,
                color: AppColors.lightGrey,
                child: member.imageUrl.trim().isEmpty
                    ? Center(
                        child: Text(
                          getProfileInitial(member.name),
                          style: AppTextStyles.headline4,
                        ),
                      )
                    : AppNetworkImage(
                        imageUrl: member.imageUrl.contains('nesdc.go.kr')
                            ? member.imageUrl
                            : ImageUtil.getProxyUrl(member.imageUrl,
                                width: 140, height: 140),
                        fit: BoxFit.cover,
                        memCacheWidth: 140,
                        memCacheHeight: 140,
                        placeholder: (context, url) =>
                            Container(color: AppColors.lightGrey),
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            getProfileInitial(member.name),
                            style: AppTextStyles.headline4,
                          ),
                        ),
                      ),
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
                        const Icon(Icons.check_circle,
                            size: 16, color: AppColors.primary),
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
                  foregroundColor:
                      isVoted ? AppColors.white : AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isVoted ? '지지함' : '지지하기',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
