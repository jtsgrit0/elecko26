import 'package:flutter/material.dart';
import 'package:elecko26_new/core/widgets/app_network_image.dart';
import 'package:elecko26_new/core/utils/image_util.dart';
import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/core/utils/party_util.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/analysis_result.dart';
import 'package:elecko26_new/domain/usecases/member_usecases.dart';
import 'package:elecko26_new/features/home/presentation/widgets/member_card.dart';
import 'package:rxdart/rxdart.dart';

class FavoritesView extends StatelessWidget {
  final Stream<List<Member>> membersStream;
  final List<Member> cachedMembers;
  final Map<String, AnalysisResult> analysisResults;
  final Stream<Map<String, AnalysisResult>> analysisStream;
  final Function(Member) onMemberSelected;

  const FavoritesView({
    Key? key,
    required this.membersStream,
    required this.cachedMembers,
    required this.analysisResults,
    required this.analysisStream,
    required this.onMemberSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream:
          Rx.combineLatest2(membersStream, analysisStream, (a, b) => [a, b]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // 초기 로딩 상태 또는 데이터 없는 상태 처리
          final favoriteMembers =
              cachedMembers.where((m) => m.isFavorite).toList();
          if (favoriteMembers.isEmpty) {
            return _buildEmptyStateWithSuggestions(
                cachedMembers, analysisResults);
          }
          return _buildFavoriteList(favoriteMembers, analysisResults);
        }

        final members = snapshot.data![0] as List<Member>;
        final currentAnalysisResults =
            snapshot.data![1] as Map<String, AnalysisResult>;

        final favoriteMembers = members.where((m) => m.isFavorite).toList();

        if (favoriteMembers.isEmpty) {
          return _buildEmptyStateWithSuggestions(
              members, currentAnalysisResults);
        }

        return _buildFavoriteList(favoriteMembers, currentAnalysisResults);
      },
    );
  }

  Widget _buildFavoriteList(List<Member> favoriteMembers,
      Map<String, AnalysisResult> analysisResults) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favoriteMembers.length,
      itemBuilder: (context, index) {
        final member = favoriteMembers[index];
        final analysisResult = analysisResults[member.id];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MemberCard(
            key: ValueKey(member.id),
            member: member,
            analysisResult: analysisResult,
            onTap: () => onMemberSelected(member),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateWithSuggestions(
      List<Member> members, Map<String, AnalysisResult> analysisResults) {
    // 선거가능성 높은 후보 Top 6 추천
    final topCandidates = List<Member>.from(members)
      ..sort((a, b) {
        final aPossibility =
            analysisResults[a.id]?.electionPossibility ?? a.electionPossibility;
        final bPossibility =
            analysisResults[b.id]?.electionPossibility ?? b.electionPossibility;
        return bPossibility.compareTo(aPossibility);
      });
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
          ...suggestions.map((member) {
            final analysisResult = analysisResults[member.id];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSuggestionCard(member, analysisResult),
            );
          }),

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

  Widget _buildSuggestionCard(Member member, AnalysisResult? analysisResult) {
    final possibility =
        analysisResult?.electionPossibility ?? member.electionPossibility;

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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: member.imageUrl.trim().isEmpty
                      ? Container(
                          color: AppColors.lightGrey,
                          child: Center(
                            child: Text(
                              member.name.characters.first,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mediumGray,
                              ),
                            ),
                          ),
                        )
                      : AppNetworkImage(
                          imageUrl: member.imageUrl.contains('nesdc.go.kr')
                              ? member.imageUrl
                              : ImageUtil.getProxyUrl(member.imageUrl,
                                  width: 120, height: 120),
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: AppColors.lightGrey),
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              member.name.characters.first,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mediumGray,
                              ),
                            ),
                          ),
                        ),
                ),
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
                      value: possibility,
                      backgroundColor: AppColors.lightGrey,
                      valueColor: AlwaysStoppedAnimation(
                        possibility > 0.5
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '당선 가능성 ${(possibility * 100).toInt()}%',
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
                icon:
                    const Icon(Icons.star_border, color: AppColors.mediumGray),
                onPressed: () async {
                  try {
                    await sl<ToggleFavoriteUseCase>().call(member.id);
                  } catch (e) {
                    debugPrint('[FavoritesView] toggleFavorite failed: $e');
                  }
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
    allNews.sort((a, b) => (b['report'].publishDate as DateTime)
        .compareTo(a['report'].publishDate));

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
