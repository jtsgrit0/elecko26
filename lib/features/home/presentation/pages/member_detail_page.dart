import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:elecko26_new/core/widgets/app_network_image.dart';
import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/domain/entities/analysis_result.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/poll.dart';
import 'package:elecko26_new/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:elecko26_new/domain/usecases/member_usecases.dart';
import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/core/utils/image_util.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:url_launcher/url_launcher.dart';

class MemberDetailPage extends StatefulWidget {
  final Member member;
  final VoidCallback? onBack;

  const MemberDetailPage({Key? key, required this.member, this.onBack})
      : super(key: key);

  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class PartyPollData {
  final String partyName;
  final double supportRate;

  PartyPollData(this.partyName, this.supportRate);
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  late Member _member;
  late Stream<AnalysisResult> _analysisStream;
  late AnalysisResult _initialAnalysis;

  late Future<List<PartyPollData>> _pollDataFuture;
  late Future<List<String>> _snsChannelsFuture;
  double? _supportTrend;

  // 시뮬레이션 슬라이더 상태
  double _simulatedPartySupport = 0.0;
  bool _isSimulationMode = false;
  AnalysisResult? _simulatedAnalysis;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _initialAnalysis = _buildFallbackAnalysis(_member);
    _pollDataFuture = _getPollDataFromJson(_member);
    _snsChannelsFuture = _searchSnsChannels(_member);
    _loadSupportTrend();
    _startAnalysisStream();
  }

  Future<void> _loadSupportTrend() async {
    try {
      final jsonString =
          await rootBundle.loadString('api/party_support_trends.json');
      final trendsData = json.decode(jsonString);

      final region = _member.region;
      final party = _member.party;

      if (trendsData.containsKey(region) &&
          trendsData[region].containsKey('2018') &&
          trendsData[region].containsKey('current')) {
        final pastSupport = trendsData[region]['2018'][party] ?? 0.0;
        final currentSupport = trendsData[region]['current'][party] ?? 0.0;

        if (pastSupport > 0) {
          setState(() {
            _supportTrend = currentSupport - pastSupport;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load support trend: $e');
    }
  }

  void _startAnalysisStream() {
    _analysisStream = _analysisTicker(widget.member.id);
  }

  void _stopAnalysisStream() {
    _analysisStream = Stream<AnalysisResult>.empty();
  }

  Stream<AnalysisResult> _analysisTicker(String memberId) async* {
    // 상세 페이지 렌더링 즉시 무거운 연산이 시작되지 않도록 500ms 지연
    await Future.delayed(const Duration(milliseconds: 500));
    while (true) {
      try {
        yield await sl<CalculateElectionPossibilityUseCase>()
            .call(memberId)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[MemberDetailPage] analysis fallback for $memberId: $e');
        yield _initialAnalysis;
      }
      await Future.delayed(const Duration(minutes: 1));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final member = _member;

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(
          member.name,
          style: AppTextStyles.headline2.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              member.isFavorite ? Icons.star : Icons.star_border,
              color: member.isFavorite ? Colors.amber : AppColors.white,
            ),
            onPressed: () async {
              final originalMember = _member;
              setState(() {
                _member = _member.copyWith(isFavorite: !_member.isFavorite);
              });
              try {
                await sl<ToggleFavoriteUseCase>().call(member.id);
              } catch (e) {
                debugPrint('[MemberDetailPage] toggleFavorite failed: $e');
                setState(() {
                  _member = originalMember;
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<AnalysisResult>(
        stream: _analysisStream,
        initialData: _initialAnalysis,
        builder: (context, snapshot) {
          final analysis = snapshot.data ?? _buildFallbackAnalysis(member);

          return SingleChildScrollView(
            child: Column(
              children: [
                // 프로필 섹션
                _buildProfileSection(member),
                const SizedBox(height: 16),

                // 상세 정보 섹션
                _buildDetailedInfoSection(member),
                const SizedBox(height: 24),

                // 당선 가능성 섹션
                _buildElectionPossibilitySection(analysis),
                const SizedBox(height: 24),

                // 시뮬레이션 슬라이더 섹션
                _buildSimulationSlider(analysis),
                const SizedBox(height: 24),

                // 2018년 지방선거 비교 섹션 (데칼코마니 분석)
                _buildHistoricalComparisonSection(member),
                const SizedBox(height: 24),

                // 상세 점수 섹션
                _buildDetailedScoresSection(analysis),
                const SizedBox(height: 24),
                // 여론조사 섹션
                _buildPollsSection(member),
                const SizedBox(height: 24),
                // SNS 분석 섹션
                _buildSnsAnalysisSection(member),
                const SizedBox(height: 24),
                // 강점 및 약점
                _buildStrengthsAndWeaknesses(analysis),
                const SizedBox(height: 24),

                // 개선점
                _buildImprovementsSection(analysis),
                const SizedBox(height: 24),

                // 사회적 책임 (Social Noblesse)
                _buildSocialContributionsSection(member),
                const SizedBox(height: 24),

                // 당선가능성 추이 그래프
                _buildTrendChartSection(analysis),
                const SizedBox(height: 24),

                // 분석 리포트
                _buildAnalysisReportSection(analysis),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  AnalysisResult _buildFallbackAnalysis(Member member) {
    // 홈 화면과 동일한 기준 점수 사용 (단순 평균 평균치로 덮어쓰지 않음)
    final electionPossibility = member.electionPossibility;

    final achievement = _estimateScore(member.achievementsList, 20);
    final activity = _estimateScore(member.achievementsList, 30);
    final policy = _estimateScore(member.policies, 15);
    final publicImage = electionPossibility.clamp(0.2, 0.95);
    final socialContribution = _estimateSocialScore(member.socialContributions);

    final pollScore = (achievement + activity + policy + publicImage) / 4;
    final historicalScore = pollScore; // 기본값으로 pollScore 사용

    final now = DateTime.now();
    final trends = List.generate(7, (index) {
      final dayOffset = 6 - index;
      return DailyPossibility(
        date: now.subtract(Duration(days: dayOffset)),
        possibility: electionPossibility,
        reason: '기본 분석값',
      );
    });

    return AnalysisResult(
      memberId: member.id,
      analysisDate: member.lastAnalysisDate ?? DateTime.now(),
      electionPossibility: electionPossibility,
      previousPossibility: (electionPossibility - 0.01).clamp(0.01, 0.99),
      possibilityChange: 0.01,
      achievementScore: achievement,
      activityScore: activity,
      policyScore: policy,
      publicImageScore: publicImage,
      socialContributionScore: socialContribution,
      pollScore: pollScore,
      historicalScore: historicalScore,
      improvements: member.policies.isEmpty
          ? ['정책 정보를 보강하면 상세 분석 정확도가 높아집니다.']
          : ['지역 현안 중심 메시지를 더 강화하면 좋습니다.'],
      strengths: [
        if (member.party.isNotEmpty) '${member.party} 소속 기반 인지도',
        if (member.district.isNotEmpty) '${member.district} 지역 기반 활동',
        if (member.achievementsList.isNotEmpty) '누적 성과 데이터 보유',
      ],
      weaknesses: [
        if (member.polls.isEmpty) '공개 여론조사 데이터가 제한적입니다.',
        if (member.achievementsList.isEmpty) '활동 이력 데이터가 부족합니다.',
      ],
      analysisReport: '${member.name} 후보의 기본 정보를 기반으로 빠른 분석 결과를 표시하고 있습니다.',
      viralIndex: 0.3,
      orgStrength: 0.3,
      expertiseScore: achievement,
      dailyTrends: trends,
      snsAnalysis: SnsAnalysis(
        totalMentions: 0,
        positiveMentions: 0,
        neutralMentions: 0,
        negativeMentions: 0,
        sentimentScore: 0.0,
        topMentions: const [],
        engagementTrend: '보합',
      ),
    );
  }

  double _estimateScore(List<String> items, int maxValue) {
    if (items.isEmpty) {
      return 0.35;
    }
    final quantityScore = (items.length / maxValue).clamp(0.0, 1.0) * 0.7;
    final totalLength = items.fold<int>(0, (sum, item) => sum + item.length);
    final avgLength = totalLength / items.length;
    final qualityScore = (avgLength / 50).clamp(0.0, 1.0) * 0.3;
    return (quantityScore + qualityScore).clamp(0.1, 0.95);
  }

  double _estimateSocialScore(List<SocialContribution> items) {
    if (items.isEmpty) {
      return 0.35;
    }
    final quantityScore = (items.length / 10).clamp(0.0, 1.0) * 0.7;
    final totalLength = items.fold<int>(
      0,
      (sum, item) => sum + item.description.length,
    );
    final avgLength = totalLength / items.length;
    final qualityScore = (avgLength / 60).clamp(0.0, 1.0) * 0.3;
    return (quantityScore + qualityScore).clamp(0.1, 0.95);
  }

  Color _getPartyColor(String party) {
    if (party.contains('더불어민주당')) return const Color(0xFF004EA2);
    if (party.contains('국민의힘')) return const Color(0xFFE61E2B);
    if (party.contains('정의당')) return const Color(0xFFFFCC00);
    if (party.contains('진보당')) return const Color(0xFFD6001C);
    return AppColors.grey;
  }

  Widget _buildProfileSection(Member member) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // 프로필 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppNetworkImage(
              imageUrl: ImageUtil.getProxyUrl(member.imageUrl,
                  width: 200, height: 200),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                  width: 100, height: 100, color: AppColors.lightGrey),
              errorWidget: (context, url, error) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.secondary.withOpacity(0.6)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getProfileInitial(member.name),
                      style: AppTextStyles.headline1.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: AppTextStyles.headline2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.party,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _getPartyColor(member.party),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.districtName.isNotEmpty
                      ? member.districtName
                      : member.district,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
                // const SizedBox(height: 8),
                // Text(
                //   member.term > 0 ? '임기: ${member.term}대' : '임기: 비현직',
                //   style: AppTextStyles.labelSmall.copyWith(
                //     color: AppColors.mediumGray,
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfoSection(Member member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '후보자 정보',
              style: AppTextStyles.headline3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('이름(한자)', member.nameHanja),
            _buildInfoRow('성별', member.gender),
            _buildInfoRow('생년월일', member.birthdate),
            _buildInfoRow('주소', member.address),
            _buildInfoRow('직업', member.occupation),
            _buildInfoRow('학력', member.education),
            _buildInfoRow('경력', member.career),
            _buildInfoRow('전과기록', member.criminalRecord),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionPossibilitySection(AnalysisResult analysis) {
    final trendValue = _supportTrend ?? 0.0;
    final basePossibility = analysis.electionPossibility;
    final finalPossibility = _isSimulationMode && _simulatedAnalysis != null
        ? _simulatedAnalysis!.electionPossibility
        : basePossibility + (trendValue / 100);

    // 격전지 지수 계산
    final battlegroundIndex = _calculateBattlegroundIndex(analysis);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '당선 가능성',
                  style: AppTextStyles.headline3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                // 격전지 지수 배지
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getBattlegroundColor(battlegroundIndex),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    battlegroundIndex,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_isSimulationMode) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Text(
                  '시뮬레이션 모드 - 정당 지지율: ${(_simulatedPartySupport * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${(finalPossibility * 100).toStringAsFixed(1)}%',
                      style: AppTextStyles.headline1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_supportTrend != null)
                      Text(
                        '(${(analysis.electionPossibility * 100).toStringAsFixed(1)}%)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.mediumGray,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '전일 대비',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                    Text(
                      '${(analysis.possibilityChange * 100).toStringAsFixed(2)}%',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: analysis.possibilityChange > 0
                            ? AppColors.success
                            : AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_supportTrend != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'vs 2018',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.mediumGray,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    trendValue > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color:
                        trendValue > 0 ? AppColors.success : AppColors.danger,
                    size: 16,
                  ),
                  Text(
                    '${trendValue.toStringAsFixed(1)}%p',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color:
                          trendValue > 0 ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // 진행 바
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: finalPossibility,
                minHeight: 8,
                backgroundColor: AppColors.lightGray,
                valueColor: AlwaysStoppedAnimation<Color>(
                  finalPossibility > 0.7
                      ? AppColors.success
                      : finalPossibility > 0.5
                          ? AppColors.secondary
                          : AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedScoresSection(AnalysisResult analysis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '세부 점수 분석',
            style: AppTextStyles.headline3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          _buildScoreItem(
            '지역 인지도 (Viral Index)',
            analysis.viralIndex,
            '뉴스 노출도(네이버 API), SNS 참여도, 검색량 분석 기반',
            icon: Icons.trending_up,
          ),
          const SizedBox(height: 12),
          _buildScoreItem(
            '조직력 (Org Strength)',
            analysis.orgStrength,
            '경력 기반 조직 규모, 직능 단체 지지 선언 분석 기반',
            icon: Icons.groups,
          ),
          const SizedBox(height: 12),
          _buildScoreItem(
            '전문성 및 경력 (Expertise)',
            analysis.expertiseScore,
            '학위, 주요 전문 경력, 의정 활동(조례 발의 등) 성적 기반',
            icon: Icons.verified,
          ),
          const SizedBox(height: 20),
          _buildSelfCheckBanner(),
        ],
      ),
    );
  }

  Widget _buildSelfCheckBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '더 정확한 당선 가능성을 원하시나요?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '보유 당원 수, 선거 캠프 규모 등 비공개 데이터를 직접 입력하여 100% 맞춤형 분석 리포트를 생성해보세요.',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.darkGray),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Self-Check 모드 진입 (Placeholder)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('준비 중인 기능입니다. 후보자 인증 후 이용 가능합니다.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Self-Check 데이터 입력하기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, double score, String description,
      {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
              Text(
                '${(score * 100).toStringAsFixed(1)}%',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.mediumGray,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 6,
              backgroundColor: AppColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(
                score > 0.7 ? AppColors.success : AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollsSection(Member member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<List<PartyPollData>>(
        future: _pollDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSectionContainer(
              title: '정당 지지율',
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return _buildSectionContainer(
              title: '정당 지지율',
              child: const Text('해당 지역의 여론조사 데이터가 없습니다.'),
            );
          }

          final pollData = snapshot.data!;
          return _buildSectionContainer(
            title: '정당 지지율',
            child: Column(
              children:
                  pollData.map((data) => _buildPollDataItem(data)).toList(),
            ),
          );
        },
      ),
    );
  }

  Future<List<PartyPollData>> _getPollDataFromJson(Member member) async {
    final raw = await _getPollDataWithHistory(member);
    return raw
        .map((item) => PartyPollData(
            item['partyName'], (item['supportRate'] as num).toDouble()))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getPollDataWithHistory(
      Member member) async {
    final regionName = member.region.split(' ').last;
    final districtName = member.district.split(' ').last;

    final paths = [
      'data/polls/$regionName.json',
      'data/polls/$districtName.json',
    ];

    for (final path in paths) {
      try {
        final jsonString = await rootBundle.loadString(path);
        final jsonData = json.decode(jsonString);
        final List<dynamic> pollList = jsonData['pollData'];
        return pollList.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (e) {
        continue;
      }
    }
    return [];
  }

  Widget _buildPollDataItem(PartyPollData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            data.partyName,
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            '${data.supportRate.toStringAsFixed(1)}%',
            style: AppTextStyles.bodyMedium.copyWith(
              color: _getPartyColor(data.partyName),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(
      {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headline3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildHistoricalComparisonSection(Member member) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getPollDataWithHistory(member),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox.shrink();

        final data = snapshot.data!;
        return _buildSectionContainer(
          title: '📈 2018년 동기 대비 지지율 추이',
          child: Column(
            children: [
              Text(
                '2018년 지방선거와 현재의 판세는 매우 유사합니다. 당시 득표율을 기준점(최대 기대치)으로 삼아 현재의 결집도를 분석합니다.',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.mediumGray),
              ),
              const SizedBox(height: 16),
              ...data.take(3).map((item) {
                final current = (item['supportRate'] as num).toDouble();
                final hist = (item['historical2018'] as num).toDouble();
                final diff = current - hist;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['partyName'],
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Text('${current.toStringAsFixed(1)}% (현재)',
                              style: AppTextStyles.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        children: [
                          Container(
                              height: 8,
                              decoration: BoxDecoration(
                                  color: AppColors.lightGray,
                                  borderRadius: BorderRadius.circular(4))),
                          FractionallySizedBox(
                            widthFactor: (hist / 100).clamp(0, 1),
                            child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                    color:
                                        AppColors.mediumGray.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4))),
                          ),
                          FractionallySizedBox(
                            widthFactor: (current / 100).clamp(0, 1),
                            child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                    color: _getPartyColor(item['partyName']),
                                    borderRadius: BorderRadius.circular(4))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '2018년 대비 ${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}%p',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: diff >= 0
                                ? AppColors.success
                                : AppColors.danger,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  Widget _buildSnsAnalysisSection(Member member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<List<String>>(
        future: _snsChannelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSectionContainer(
              title: 'SNS 채널 (검색 결과)',
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return _buildSectionContainer(
              title: 'SNS 채널 (검색 결과)',
              child: const Text('관련 SNS 채널을 찾을 수 없습니다.'),
            );
          }

          final snsUrls = snapshot.data!;
          return _buildSectionContainer(
            title: 'SNS 채널 (검색 결과)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: snsUrls.map((url) => _buildSnsLink(url)).toList(),
            ),
          );
        },
      ),
    );
  }

  Future<List<String>> _searchSnsChannels(Member member) async {
    final name = Uri.encodeComponent(member.name);
    final party = Uri.encodeComponent(member.party);
    final region = Uri.encodeComponent(member.region);

    // Bing 검색을 통한 SNS 채널 직접 링크 제공
    return [
      'https://www.bing.com/search?q=$name+$party+$region+인스타그램',
      'https://www.bing.com/search?q=$name+$party+$region+페이스북',
      'https://www.bing.com/search?q=$name+$party+$region+네이버블로그',
    ];
  }

  Widget _buildSnsLink(String url) {
    String label = 'SNS 검색 결과';
    if (url.contains('인스타그램'))
      label = '인스타그램 검색';
    else if (url.contains('페이스북'))
      label = '페이스북 검색';
    else if (url.contains('네이버블로그')) label = '네이버 블로그 검색';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Row(
          children: [
            Icon(Icons.search, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthsAndWeaknesses(AnalysisResult analysis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '강점',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...analysis.strengths
                      .map((s) => _buildListItem(s, AppColors.success))
                      .toList(),
                  if (analysis.strengths.isEmpty)
                    Text(
                      '분석 중',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '약점',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...analysis.weaknesses
                      .map((w) => _buildListItem(w, AppColors.danger))
                      .toList(),
                  if (analysis.weaknesses.isEmpty)
                    Text(
                      '주요 약점 없음',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                top: 10), // Adjust alignment since text is larger
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.darkGray,
                height: 1.4,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementsSection(AnalysisResult analysis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
          color: AppColors.secondary.withOpacity(0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📌 개선점 및 권고사항',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            ...analysis.improvements
                .map((i) => _buildListItem(i, AppColors.secondary))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPartySupportRateItem(
      String party, double rate, int rank, bool isCurrentParty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentParty
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.lightGray,
          width: isCurrentParty ? 2 : 1,
        ),
        color: isCurrentParty
            ? AppColors.primary.withOpacity(0.05)
            : AppColors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCurrentParty ? AppColors.primary : AppColors.lightGray,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: AppTextStyles.labelSmall.copyWith(
                  color:
                      isCurrentParty ? AppColors.white : AppColors.mediumGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              party,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight:
                    isCurrentParty ? FontWeight.bold : FontWeight.normal,
                color: isCurrentParty ? AppColors.primary : AppColors.darkGray,
              ),
            ),
          ),
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isCurrentParty ? FontWeight.bold : FontWeight.normal,
              color: isCurrentParty ? AppColors.primary : AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChartSection(AnalysisResult analysis) {
    final recentTrends = analysis.dailyTrends.length > 30
        ? analysis.dailyTrends.sublist(analysis.dailyTrends.length - 30)
        : analysis.dailyTrends;
    final hasTrends = recentTrends.isNotEmpty;
    final latest = hasTrends ? recentTrends.last : null;
    final earliest = hasTrends ? recentTrends.first : null;
    final delta =
        hasTrends ? (latest!.possibility - earliest!.possibility) : 0.0;
    final deltaPercent = delta * 100;
    final deltaColor = delta >= 0 ? AppColors.success : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '당선가능성 추이',
                  style: AppTextStyles.headline3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '1분 간격',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasTrends)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(latest!.possibility * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.headline1.copyWith(
                      color: AppColors.darkGray,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: deltaColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${delta >= 0 ? '+' : ''}${deltaPercent.toStringAsFixed(2)}%p',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: deltaColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: _buildStockChart(recentTrends),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '분석 기준: ${_formatDateTime(analysis.analysisDate)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
                const Spacer(),
                if (hasTrends)
                  Text(
                    '${_formatDateTime(recentTrends.first.date)} ~ ${_formatDateTime(recentTrends.last.date)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.mediumGray,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockChart(List<DailyPossibility> trends) {
    if (trends.isEmpty) {
      return Center(
        child: Text(
          '데이터 없음',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.mediumGray),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.04),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomPaint(
        painter: _StockChartPainter(
          values: trends.map((e) => e.possibility).toList(),
          lineColor: AppColors.primary,
          fillColor: AppColors.primary,
          gridColor: AppColors.lightGray.withOpacity(0.5),
          markerColor: AppColors.secondary,
          upColor: AppColors.success,
          downColor: AppColors.danger,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildAnalysisReportSection(AnalysisResult analysis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '분석 리포트',
              style: AppTextStyles.headline3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              analysis.analysisReport,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.darkGray,
                height: 1.6,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialContributionsSection(Member member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🤝 사회적 책임 (Social Noblesse)',
                style: AppTextStyles.headline3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${member.socialContributions.length}건',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (member.socialContributions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '공식 확인된 사회공헌 내역이 없습니다.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
              ),
            )
          else
            ...member.socialContributions.map((contrib) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGray),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            contrib.type,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatDateTime(contrib.date),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      contrib.description,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  /// 시뮬레이션 슬라이더 UI 구성
  Widget _buildSimulationSlider(AnalysisResult analysis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '정당 지지율 시뮬레이션',
                  style: AppTextStyles.headline3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                if (_isSimulationMode)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '시뮬레이션 중',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '정당 지지율을 조절하여 당선 가능성의 변화를 실시간으로 확인하세요',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.lightGray,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withOpacity(0.2),
                valueIndicatorColor: AppColors.primary,
                valueIndicatorTextStyle: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white,
                ),
              ),
              child: Slider(
                value: _simulatedPartySupport,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: '${(_simulatedPartySupport * 100).toStringAsFixed(1)}%',
                onChanged: (value) {
                  setState(() {
                    _simulatedPartySupport = value;
                    _isSimulationMode = true;
                    _recalculateWithSimulation(value);
                  });
                },
                onChangeEnd: (value) {
                  // 시뮬레이션 모드 해제
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() {
                        _isSimulationMode = false;
                      });
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_isSimulationMode && _simulatedAnalysis != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '시뮬레이션 결과',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '조정된 당선 가능성:',
                          style: AppTextStyles.bodySmall,
                        ),
                        Text(
                          '${(_simulatedAnalysis!.electionPossibility * 100).toStringAsFixed(1)}%',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '정당 지지율 ${(_simulatedPartySupport * 100).toStringAsFixed(1)}% 기준',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 격전지 지수 계산
  String _calculateBattlegroundIndex(AnalysisResult analysis) {
    // 2018년 데이터와 현재 지지율을 기반으로 격전지 지수 계산
    final historical2018 = analysis.historicalScore;
    final currentSupport = analysis.pollScore;

    // 가중치 적용 (2018년 40%, 현재 60%)
    final combinedScore = (historical2018 * 0.4) + (currentSupport * 0.6);

    if (combinedScore >= 0.6) {
      return '안정';
    } else if (combinedScore >= 0.4) {
      return '경합';
    } else {
      return '위험';
    }
  }

  /// 격전지 지수에 따른 색상 반환
  Color _getBattlegroundColor(String index) {
    switch (index) {
      case '안정':
        return Colors.green;
      case '경합':
        return Colors.orange;
      case '위험':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 시뮬레이션에 따른 재계산
  void _recalculateWithSimulation(double simulatedSupport) async {
    try {
      // 현재 분석 결과를 기반으로 시뮬레이션
      final currentAnalysis =
          _isSimulationMode ? _simulatedAnalysis : _initialAnalysis;
      if (currentAnalysis == null) return;

      // 정당 지지율 변화에 따른 당선 가능성 재계산
      final basePossibility = currentAnalysis.electionPossibility;
      const maxAdjustment = 0.3; // 최대 30% 조정

      // 시뮬레이션 지지율에 따른 조정값 계산
      final adjustment = (simulatedSupport - 0.5) * maxAdjustment;
      final newPossibility = (basePossibility + adjustment).clamp(0.01, 0.99);

      // 시뮬레이션 결과 생성
      final simulatedAnalysis = AnalysisResult(
        memberId: currentAnalysis.memberId,
        analysisDate: DateTime.now(),
        electionPossibility: newPossibility,
        previousPossibility: currentAnalysis.electionPossibility,
        possibilityChange: newPossibility - currentAnalysis.electionPossibility,
        achievementScore: currentAnalysis.achievementScore,
        activityScore: currentAnalysis.activityScore,
        policyScore: currentAnalysis.policyScore,
        publicImageScore: currentAnalysis.publicImageScore,
        socialContributionScore: currentAnalysis.socialContributionScore,
        pollScore: simulatedSupport,
        historicalScore: currentAnalysis.historicalScore,
        improvements: currentAnalysis.improvements,
        strengths: currentAnalysis.strengths,
        weaknesses: currentAnalysis.weaknesses,
        analysisReport: currentAnalysis.analysisReport,
        dailyTrends: currentAnalysis.dailyTrends,
        viralIndex: currentAnalysis.viralIndex,
        orgStrength: currentAnalysis.orgStrength,
        expertiseScore: currentAnalysis.expertiseScore,
        snsAnalysis: currentAnalysis.snsAnalysis,
      );

      setState(() {
        _simulatedAnalysis = simulatedAnalysis;
      });
    } catch (e) {
      debugPrint('Simulation error: $e');
    }
  }
}

String _formatDateTime(DateTime date) {
  return '${date.year}년 ${date.month}월 ${date.day}일';
}

String _getProfileInitial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed.characters.first;
}

class _StockChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color markerColor;
  final Color upColor;
  final Color downColor;

  _StockChartPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.markerColor,
    required this.upColor,
    required this.downColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    const padding = EdgeInsets.fromLTRB(12, 12, 12, 12);
    final chartRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.horizontal,
      size.height - padding.vertical,
    );

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range =
        (maxValue - minValue).abs() < 0.0001 ? 0.1 : (maxValue - minValue);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const gridLines = 4;
    for (var i = 0; i <= gridLines; i++) {
      final y = chartRect.top + (chartRect.height / gridLines) * i;
      canvas.drawLine(
          Offset(chartRect.left, y), Offset(chartRect.right, y), gridPaint);
    }

    final points = <Offset>[];
    final total = values.length;
    for (var i = 0; i < total; i++) {
      final x = total == 1
          ? chartRect.left + chartRect.width / 2
          : chartRect.left + (i / (total - 1)) * chartRect.width;
      final normalized = (values[i] - minValue) / range;
      final y = chartRect.bottom - normalized * chartRect.height;
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(chartRect.right, chartRect.bottom)
      ..lineTo(chartRect.left, chartRect.bottom)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          fillColor.withOpacity(0.35),
          fillColor.withOpacity(0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chartRect);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor.withOpacity(0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    if (values.length > 1) {
      final step = chartRect.width / (values.length - 1);
      final bodyWidth = math.max(4.0, math.min(12.0, step * 0.6));
      for (var i = 1; i < values.length; i++) {
        final open = values[i - 1];
        final close = values[i];
        final high = open > close ? open : close;
        final low = open < close ? open : close;
        final color = close >= open ? upColor : downColor;

        final x = points[i].dx;
        final yOpen =
            chartRect.bottom - ((open - minValue) / range) * chartRect.height;
        final yClose =
            chartRect.bottom - ((close - minValue) / range) * chartRect.height;
        final yHigh =
            chartRect.bottom - ((high - minValue) / range) * chartRect.height;
        final yLow =
            chartRect.bottom - ((low - minValue) / range) * chartRect.height;

        final wickPaint = Paint()
          ..color = color
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), wickPaint);

        final top = math.min(yOpen, yClose);
        final bottom = math.max(yOpen, yClose);
        final bodyHeight = math.max(2.0, bottom - top);
        final bodyRect = Rect.fromCenter(
          center: Offset(x, top + bodyHeight / 2),
          width: bodyWidth,
          height: bodyHeight,
        );
        final bodyPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
          bodyPaint,
        );
      }
    }

    final last = points.last;
    final markerPaint = Paint()..color = markerColor;
    canvas.drawCircle(last, 4, markerPaint);
    canvas.drawCircle(last, 9, Paint()..color = markerColor.withOpacity(0.15));
  }

  @override
  bool shouldRepaint(covariant _StockChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.markerColor != markerColor ||
        oldDelegate.upColor != upColor ||
        oldDelegate.downColor != downColor;
  }
}
