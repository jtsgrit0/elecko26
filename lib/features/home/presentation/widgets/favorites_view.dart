import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:elecko26/core/theme/app_theme.dart';
import 'package:elecko26/core/utils/party_util.dart';
import 'package:elecko26/domain/entities/member.dart';

class FavoritesView extends StatelessWidget {
  final Stream<List<Member>> membersStream;
  final List<Member> cachedMembers;
  final Function(Member) onMemberSelected;

  const FavoritesView({
    Key? key,
    required this.membersStream,
    required this.cachedMembers,
    required this.onMemberSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Member>>(
      stream: membersStream,
      builder: (context, snapshot) {
        final members = snapshot.data ?? cachedMembers;
        final favoriteMembers = members.where((m) => m.isFavorite).toList();

        if (favoriteMembers.isEmpty) {
          return _buildEmptyStateWithSuggestions(members);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favoriteMembers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MemberCard(
                key: ValueKey(favoriteMembers[index].id),
                member: favoriteMembers[index],
                onTap: () => onMemberSelected(favoriteMembers[index]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyStateWithSuggestions(List<Member> members) {
    // 선거가능성 높은 후보 Top 6 추천
    final topCandidates = List<Member>.from(members)
      ..sort((a, b) => (b.electionPossibility).compareTo(a.electionPossibility));
    final suggestions = topCandidates.take(6).toList();

    return RefreshIndicator(
      onRefresh: () async {},
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.star_border, size: 40, color: AppColors.white),
                SizedBox(height: 12),
                Text(
                  '즐겨찾기한 의원이 없습니다',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '후보를 즐겨찾기하면 빠른 소식을 받을 수 있어요!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 추천 후보 섹션
          const Text(
            '🔥 인기 후보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.map((member) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSuggestionCard(member),
          )),

          // 최신 뉴스 섹션
          const SizedBox(height: 24),
          const Text(
            '📰 최신 소식',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildLatestNews(suggestions),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Member member) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onMemberSelected(member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 프로필 이미지
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(10),
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
                          member.name.characters.first,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${member.party} · ${member.district}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mediumGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // 선거가능성 바
                    LinearProgressIndicator(
                      value: member.electionPossibility,
                      backgroundColor: AppColors.lightGrey,
                      valueColor: AlwaysStoppedAnimation(
                        member.electionPossibility > 0.5
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '당선 가능성 ${(member.electionPossibility * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 즐겨찾기 버튼
              IconButton(
                icon: const Icon(Icons.star_border, color: AppColors.mediumGray),
                onPressed: () {
                  // 즐겨찾기 추가 (MemberCard의 toggleFavorite 사용)
                  // 사용자가 직접 탭해서 추가하도록 유도
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLatestNews(List<Member> members) {
    final allNews = <Map<String, dynamic>>[];
    for (var m in members) {
      for (var report in m.pressReports) {
        allNews.add({
          'member': m,
          'report': report,
        });
      }
    }
    allNews.sort((a, b) =>
        (b['report'].publishDate as DateTime).compareTo(a['report'].publishDate));

    final latestNews = allNews.take(5).toList();

    if (latestNews.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              '아직 등록된 뉴스가 없습니다',
              style: TextStyle(color: AppColors.mediumGray),
            ),
          ),
        ),
      ];
    }

    return latestNews.map((item) {
      final member = item['member'] as Member;
      final report = item['report'];
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PartyUtil.getPartyColor(member.party).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.article,
              color: PartyUtil.getPartyColor(member.party),
            ),
          ),
          title: Text(
            report.title ?? '뉴스 제목 없음',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${member.name} · ${report.source ?? ''}',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () => onMemberSelected(member),
        ),
      );
    }).toList();
  }
}
