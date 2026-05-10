import 'package:elecko26_new/core/widgets/pdf_image_renderer.dart';
import 'package:elecko26_new/core/widgets/pdf_image_renderer.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/core/utils/image_util.dart';
import 'package:elecko26_new/core/utils/party_util.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/analysis_result.dart';
import 'package:elecko26_new/domain/usecases/member_usecases.dart';
import 'package:elecko26_new/app/injection_container.dart';

class MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback? onTap;
  final int? rank;
  final AnalysisResult? analysisResult;

  const MemberCard({
    Key? key,
    required this.member,
    this.onTap,
    this.rank,
    this.analysisResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final possibility =
        analysisResult?.electionPossibility ?? member.electionPossibility;
    final partyLogoUrl = PartyUtil.getPartyLogoUrl(member.party);

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
              if (rank != null && rank! <= 3) ...[
                SizedBox(
                  width: 32,
                  child: Text(
                    '${rank}위',
                    style: AppTextStyles.headline4.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (rank != null && rank! > 3) ...[
                const SizedBox(width: 40), // 순위 공간 확보
              ],
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: _buildProfileImage(),
                    ),
                  ),
                  if (partyLogoUrl.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: 40,
                      height: 20,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(partyLogoUrl),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ]
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
                            text: ' • ${member.region}',
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
                        '당선 가능성: ${possibility != null ? '${(possibility * 100).toStringAsFixed(1)}%' : '집계중'}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '업데이트: ${member.lastAnalysisDate != null ? _formatRelativeTime(member.lastAnalysisDate!) : '정보 없음'}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
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

  Widget _buildProfileImage() {
    if (member.imageUrl.isEmpty) {
      return _buildFallbackProfile();
    }
    return PdfImageRenderer.fromUrl(
      member.imageUrl,
      placeholder: (context) => Container(color: AppColors.lightGrey),
      errorWidget: (context, error, stackTrace) => _buildFallbackProfile(),
    );
  }

  Widget _buildFallbackProfile() {
    return Container(
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
    );
  }
}
