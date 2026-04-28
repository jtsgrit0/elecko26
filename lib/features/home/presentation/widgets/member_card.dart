import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/core/utils/image_util.dart';
import 'package:elecko26_new/core/utils/party_util.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:elecko26_new/domain/usecases/member_usecases.dart';
import 'package:elecko26_new/app/injection_container.dart';

class MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback? onTap;

  const MemberCard({Key? key, required this.member, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final possibility = member.electionPossibility;
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: member.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ImageUtil.getProxyUrl(member.imageUrl,
                              width: 120, height: 120),
                          width: 60,
                          height: 60,
                          memCacheWidth: 120, // 메모리 캐시 크기 최적화 (해상도에 맞춤)
                          memCacheHeight: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                              width: 60,
                              height: 60,
                              color: AppColors.lightGrey),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.8),
                                  AppColors.secondary.withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getProfileInitial(member.name),
                                style: AppTextStyles.headline3.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.8),
                                AppColors.secondary.withOpacity(0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getProfileInitial(member.name),
                              style: AppTextStyles.headline3.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 50,
                  height: 18,
                  child: Image.asset(
                    PartyUtil.getPartyLogoUrl(member.party),
                    fit: BoxFit.contain,
                    cacheWidth: 100, // 원본 로딩 방지
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: AppTextStyles.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: member.party,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: PartyUtil.getPartyColor(member.party),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' • ${member.district}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '당선 가능성: ${(possibility * 100).toStringAsFixed(1)}%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '업데이트: ${_formatRelativeTime(member.lastAnalysisDate)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.grey,
              size: 16,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                member.isFavorite ? Icons.star : Icons.star_border,
                color: member.isFavorite ? Colors.amber : AppColors.grey,
              ),
              onPressed: () async {
                try {
                  // 리포지토리에 토글 요청 (스트림을 통해 UI가 자동으로 갱신됨)
                  await sl<ToggleFavoriteUseCase>().call(member.id);
                } catch (e) {
                  debugPrint('[MemberCard] toggleFavorite failed: $e');
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

  String _formatRelativeTime(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  String _getProfileInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.characters.first;
  }
}
