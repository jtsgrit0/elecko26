import 'package:elecko26_new/domain/entities/analysis_result.dart';
import 'package:elecko26_new/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:elecko26_new/app/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/core/utils/image_util.dart';
import 'package:elecko26_new/core/utils/party_util.dart';
import 'package:elecko26_new/core/utils/utility_functions.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/features/home/presentation/widgets/member_card.dart';

class ComparisonView extends StatefulWidget {
  final Stream<List<Member>> membersStream;
  final List<Member> cachedMembers;
  final Function(Member) onMemberSelected;

  const ComparisonView({
    Key? key,
    required this.membersStream,
    required this.cachedMembers,
    required this.onMemberSelected,
  }) : super(key: key);

  @override
  State<ComparisonView> createState() => _ComparisonViewState();
}

class _ComparisonViewState extends State<ComparisonView> {
  final Set<String> _selectedCompareIds = {};

  Widget _buildComparisonPage() {
    return StreamBuilder<List<Member>>(
      stream: widget.membersStream,
      builder: (context, snapshot) {
        final members = snapshot.data ?? widget.cachedMembers;
        final favoriteMembers = members.where((m) => m.isFavorite).toList();

        if (favoriteMembers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: AppColors.grey.withOpacity(0.2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '비교를 위해 먼저 즐겨찾기에 의원을 추가해주세요',
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          );
        }

        if (_selectedCompareIds.length == 2) {
          final member1 =
              members.firstWhere((m) => m.id == _selectedCompareIds.first);
          final member2 =
              members.firstWhere((m) => m.id == _selectedCompareIds.last);
          return _buildComparisonResults(member1, member2);
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '비교할 의원 2명을 선택해주세요 (${_selectedCompareIds.length}/2)',
                style: AppTextStyles.headline4,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: favoriteMembers.length,
                itemBuilder: (context, index) {
                  final member = favoriteMembers[index];
                  final isSelected = _selectedCompareIds.contains(member.id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color:
                        isSelected ? AppColors.primary.withOpacity(0.05) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      title: Text(member.name, style: AppTextStyles.headline4),
                      subtitle: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: member.party,
                              style: TextStyle(
                                color: PartyUtil.getPartyColor(member.party),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: ' • ${member.district}',
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      secondary: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: member.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl:
                                    '${ImageUtil.getProxyUrl(member.imageUrl, width: 100, height: 100)}&v=2',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                    width: 40,
                                    height: 40,
                                    color: AppColors.lightGrey),
                                errorWidget: (context, url, error) => Container(
                                  width: 40,
                                  height: 40,
                                  color: AppColors.lightGrey,
                                  child: Center(
                                    child: Text(
                                      getProfileInitial(member.name),
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                color: AppColors.lightGrey,
                                child: Center(
                                  child: Text(
                                    getProfileInitial(member.name),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            if (_selectedCompareIds.length < 2) {
                              _selectedCompareIds.add(member.id);
                            }
                          } else {
                            _selectedCompareIds.remove(member.id);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComparisonResults(Member m1, Member m2) {
    final color1 = PartyUtil.getPartyColor(m1.party);
    final color2 = PartyUtil.getPartyColor(m2.party);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('후보자 비교', style: AppTextStyles.headline3),
              TextButton(
                onPressed: () => setState(() => _selectedCompareIds.clear()),
                child: const Text('다시 선택'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildSimpleMemberHeader(m1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.grey.withOpacity(0.2),
                  ),
                ),
              ),
              Expanded(child: _buildSimpleMemberHeader(m2)),
            ],
          ),
          const SizedBox(height: 32),
          _buildComparisonRow('당선 가능성', m1.electionPossibility,
              m2.electionPossibility, color1, color2,
              isPercent: true),
          const SizedBox(height: 16),
          FutureBuilder<List<AnalysisResult>>(
            future: Future.wait([
              sl<CalculateElectionPossibilityUseCase>().call(m1.id),
              sl<CalculateElectionPossibilityUseCase>().call(m2.id),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final a1 = snapshot.data![0];
              final a2 = snapshot.data![1];

              return Column(
                children: [
                  _buildComparisonRow('성과도', a1.achievementScore,
                      a2.achievementScore, color1, color2),
                  const SizedBox(height: 16),
                  _buildComparisonRow('활동도', a1.activityScore, a2.activityScore,
                      color1, color2),
                  const SizedBox(height: 16),
                  _buildComparisonRow(
                      '정책도', a1.policyScore, a2.policyScore, color1, color2),
                  const SizedBox(height: 16),
                  _buildComparisonRow('언론도', a1.publicImageScore,
                      a2.publicImageScore, color1, color2),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMemberHeader(Member m) {
    final partyColor = PartyUtil.getPartyColor(m.party);
    return GestureDetector(
      onTap: () => widget.onMemberSelected(m),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: m.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl:
                        '${ImageUtil.getProxyUrl(m.imageUrl, width: 200, height: 200)}&v=2',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                        width: 80, height: 80, color: AppColors.lightGrey),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.lightGrey,
                      child: Center(
                        child: Text(
                          getProfileInitial(m.name),
                          style: AppTextStyles.headline3.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: AppColors.lightGrey,
                    child: Center(
                      child: Text(
                        getProfileInitial(m.name),
                        style: AppTextStyles.headline3.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(m.name, style: AppTextStyles.headline4),
          Text(m.party,
              style: AppTextStyles.labelSmall
                  .copyWith(color: partyColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(m.district,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey)),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
      String label, double v1, double v2, Color c1, Color c2,
      {bool isPercent = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        final currentV1 = v1 * animValue;
        final currentV2 = v2 * animValue;

        final display1 = isPercent
            ? '${(currentV1 * 100).toStringAsFixed(1)}%'
            : (currentV1 * 100).toStringAsFixed(1);
        final display2 = isPercent
            ? '${(currentV2 * 100).toStringAsFixed(1)}%'
            : (currentV2 * 100).toStringAsFixed(1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(display1,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: c1,
                        fontWeight:
                            v1 >= v2 ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      )),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RotatedBox(
                              quarterTurns: 2,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: currentV1,
                                  backgroundColor:
                                      AppColors.lightGrey.withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation(
                                      c1.withOpacity(v1 >= v2 ? 1.0 : 0.4)),
                                  minHeight: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: currentV2,
                                backgroundColor:
                                    AppColors.lightGrey.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation(
                                    c2.withOpacity(v2 >= v1 ? 1.0 : 0.4)),
                                minHeight: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(display2,
                      style: TextStyle(
                        color: c2,
                        fontWeight:
                            v2 >= v1 ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      )),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildComparisonPage();
  }
}
