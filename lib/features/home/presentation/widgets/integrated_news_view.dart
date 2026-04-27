import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/core/utils/image_util.dart';
import 'package:elecko26_new/core/utils/party_util.dart';
import 'package:elecko26_new/domain/entities/member.dart';

class IntegratedNewsView extends StatefulWidget {
  final Stream<List<Member>> membersStream;
  final List<Member> cachedMembers;

  const IntegratedNewsView({
    Key? key,
    required this.membersStream,
    required this.cachedMembers,
  }) : super(key: key);

  @override
  State<IntegratedNewsView> createState() => _IntegratedNewsViewState();
}

class _IntegratedNewsViewState extends State<IntegratedNewsView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Member>? _lastMembers;
  List<Map<String, dynamic>>? _cachedNews;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildIntegratedNewsPage();
  }

  Widget _buildIntegratedNewsPage() {
    return StreamBuilder<List<Member>>(
      stream: widget.membersStream,
      builder: (context, snapshot) {
        final members = snapshot.data ?? widget.cachedMembers;

        // 최적화: 멤버 리스트가 변경되지 않았다면 뉴스 추출 및 정렬 스킵
        if (_cachedNews != null && _lastMembers == members) {
          return _buildNewsList(members, _cachedNews!);
        }

        final favorites = members.where((m) => m.isFavorite).toList();
        final allNews = <Map<String, dynamic>>[];
        for (var m in favorites) {
          for (var report in m.pressReports) {
            allNews.add({
              'member': m,
              'report': report,
            });
          }
        }
        allNews.sort((a, b) => (b['report'].publishDate as DateTime)
            .compareTo(a['report'].publishDate));

        _lastMembers = members;
        _cachedNews = allNews;

        return _buildNewsList(members, allNews);
      },
    );
  }

  Widget _buildNewsList(List<Member> favorites, List<Map<String, dynamic>> allNews) {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          // 제목란 (News 탭과 동일한 노란색)
          Container(
            decoration: const BoxDecoration(
              color: AppColors.accent,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.newspaper, color: AppColors.dark, size: 28),
                  const SizedBox(width: 12),
                  Text('통합 뉴스 피드',
                      style: AppTextStyles.headline3
                          .copyWith(color: AppColors.dark)),
                ],
              ),
            ),
          ),
          if (favorites.where((m) => m.isFavorite).isEmpty)
            const Expanded(child: Center(child: Text('즐겨찾기한 의원이 없습니다.')))
          else if (allNews.isEmpty)
            const Expanded(child: Center(child: Text('최신 보도 자료가 없습니다.')))
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: allNews.length,
                separatorBuilder: (context, index) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final item = allNews[index];
                  final Member m = item['member'];
                  final report = item['report'];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.lightGrey,
                                child: m.imageUrl.isNotEmpty
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: ImageUtil.getProxyUrl(
                                              m.imageUrl,
                                              width: 48,
                                              height: 48),
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                                  width: 24,
                                                  height: 24,
                                                  color: AppColors.lightGrey),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.person, size: 12),
                                        ),
                                      )
                                    : const Icon(Icons.person, size: 12),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 36,
                                child: AspectRatio(
                                  aspectRatio: 3 / 1,
                                  child: Image.asset(
                                    PartyUtil.getPartyLogoUrl(m.party),
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const SizedBox(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: PartyUtil.getPartyColor(m.party),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                    text: '${m.name} • ',
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.darkGray,
                                        fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text: m.party,
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: PartyUtil.getPartyColor(m.party),
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 12, color: AppColors.grey),
                              const SizedBox(width: 4),
                              Text(report.publishDate.toString().split(' ')[0],
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.grey)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(report.title,
                          style: AppTextStyles.headline4
                              .copyWith(color: AppColors.darkGray)),
                      const SizedBox(height: 6),
                      Text(report.summary,
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.darkGray.withOpacity(0.8)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: [
                                const Icon(Icons.source,
                                    size: 12, color: AppColors.grey),
                                const SizedBox(width: 4),
                                Text(report.source,
                                    style: AppTextStyles.labelSmall
                                        .copyWith(color: AppColors.darkGray)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
