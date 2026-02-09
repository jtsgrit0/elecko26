import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/domain/entities/analysis_result.dart';
import 'package:flutter_application_1/domain/entities/member.dart';
import 'package:flutter_application_1/domain/entities/poll.dart';
import 'package:flutter_application_1/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:flutter_application_1/domain/usecases/member_usecases.dart';
import 'package:flutter_application_1/app/injection_container.dart';

class MemberDetailPage extends StatefulWidget {
  final Member member;

  const MemberDetailPage({Key? key, required this.member}) : super(key: key);

  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> with WidgetsBindingObserver {
  late Stream<Member> _memberStream;
  late Stream<AnalysisResult> _analysisStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startMemberStream();
    _startAnalysisStream();
  }

  void _startMemberStream() {
    _memberStream = sl<WatchMemberByIdUseCase>().call(widget.member.id);
  }

  void _stopMemberStream() {
    _memberStream = Stream<Member>.empty();
  }

  void _startAnalysisStream() {
    _analysisStream = _analysisTicker(widget.member.id);
  }

  void _stopAnalysisStream() {
    _analysisStream = Stream<AnalysisResult>.empty();
  }

  Stream<AnalysisResult> _analysisTicker(String memberId) async* {
    while (true) {
      yield await sl<CalculateElectionPossibilityUseCase>().call(memberId);
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _startMemberStream();
        _startAnalysisStream();
      });
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      setState(() {
        _stopMemberStream();
        _stopAnalysisStream();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Member>(
      stream: _memberStream,
      builder: (context, memberSnapshot) {
        final member = memberSnapshot.data ?? widget.member;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              member.name,
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.primary,
            elevation: 0,
          ),
          body: StreamBuilder<AnalysisResult>(
            stream: _analysisStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFD63031),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '분석 중...',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '분석 데이터를 불러올 수 없습니다.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.darkGray,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return Center(
                  child: Text(
                    '분석 데이터를 불러올 수 없습니다.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.darkGray,
                    ),
                  ),
                );
              }

              final analysis = snapshot.data!;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // 프로필 섹션
                    _buildProfileSection(member),
                    const SizedBox(height: 24),

                    // 당선 가능성 섹션
                    _buildElectionPossibilitySection(analysis),
                    const SizedBox(height: 24),

                    // 상세 점수 섹션
                    _buildDetailedScoresSection(analysis),
                    const SizedBox(height: 24),
                    // 여론조사 섹션
                    _buildPollsSection(member),
                    const SizedBox(height: 24),
                    // 강점 및 약점
                    _buildStrengthsAndWeaknesses(analysis),
                    const SizedBox(height: 24),

                    // 개선점
                    _buildImprovementsSection(analysis),
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
      },
    );
  }

  Widget _buildProfileSection(Member member) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // 프로필 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: member.imageUrl.isNotEmpty
                ? Image.network(
                    member.imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withOpacity(0.8), AppColors.secondary.withOpacity(0.6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            member.name[0],
                            style: AppTextStyles.headline1.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.8), AppColors.secondary.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        member.name[0],
                        style: AppTextStyles.headline1.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.district,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  member.term > 0 ? '임기: ${member.term}대' : '임기: 비현직',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionPossibilitySection(AnalysisResult analysis) {
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
              '당선 가능성',
              style: AppTextStyles.headline3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(analysis.electionPossibility * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.headline1.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
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
            const SizedBox(height: 16),
            // 진행 바
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: analysis.electionPossibility,
                minHeight: 8,
                backgroundColor: AppColors.lightGray,
                valueColor: AlwaysStoppedAnimation<Color>(
                  analysis.electionPossibility > 0.7
                      ? AppColors.success
                      : analysis.electionPossibility > 0.5
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
            '성과도',
            analysis.achievementScore,
            '주요 성과와 경력',
          ),
          const SizedBox(height: 12),
          _buildScoreItem(
            '활동도',
            analysis.activityScore,
            '의정 활동',
          ),
          const SizedBox(height: 12),
          _buildScoreItem(
            '정책도',
            analysis.policyScore,
            '정책 제안',
          ),
          const SizedBox(height: 12),
          _buildScoreItem(
            '언론도',
            analysis.publicImageScore,
            '언론 평가 및 신뢰도',
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, double score, String description) {
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
    final nesdcCount = member.polls.where((poll) => poll.id.startsWith('nesdc_')).length;
    final lastUpdated = member.lastAnalysisDate;

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
              Row(
                children: [
                  Text(
                    '📊 여론조사',
                    style: AppTextStyles.headline3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                  if (nesdcCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'NESDC ${nesdcCount}건',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (lastUpdated != null) ...[
                const SizedBox(height: 6),
                Text(
                  '업데이트: ${_formatDateTime(lastUpdated)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (member.polls.isEmpty)
                Text(
                  '여론조사 데이터 없음',
                  style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.mediumGray,
                ),
              )
            else
              Column(
                children: [
                  // 여론조사 통계
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Expanded(
                          child: _buildPollStatCard(
                            '평균 지지율',
                            _formatAverageSupport(member.polls),
                            AppColors.primary,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPollStatCard(
                          '조사 기관 수',
                          '${member.polls.map((p) => p.pollAgency).toSet().length}개',
                          AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPollStatCard(
                          '조사 건수',
                          '${member.polls.length}건',
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 개별 여론조사 항목
                  ...member.polls.map((poll) => _buildPollItem(poll)).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatAverageSupport(List<Poll> polls) {
    final validRates = polls.map((p) => p.supportRate).whereType<double>().toList();
    if (validRates.isEmpty) {
      return '미공개';
    }
    final avgRate = validRates.fold<double>(0, (sum, r) => sum + r) / validRates.length;
    return '${(avgRate * 100).toStringAsFixed(1)}%';
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

  Widget _buildPollStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollItem(Poll poll) {
    final supportText = poll.supportRate == null
        ? '결과 미공개'
        : '${(poll.supportRate! * 100).toStringAsFixed(1)}%';
    final sampleText = poll.sampleSize == null ? '미공개' : '${poll.sampleSize}명';
    final marginText = poll.marginOfError == null
        ? '미공개'
        : '±${poll.marginOfError!.toStringAsFixed(1)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGray),
        color: AppColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                poll.pollAgency,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              Text(
                poll.surveyDate.toString().split(' ')[0],
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.mediumGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '지지율',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                      Text(
                        supportText,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '표본',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                      Text(
                        sampleText,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.darkGray,
                        ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오차한계',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                      Text(
                        marginText,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.darkGray,
                        ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (poll.notes != null && poll.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              poll.notes!,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.mediumGray,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
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
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 6,
              height: 6,
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

  Widget _buildTrendChartSection(AnalysisResult analysis) {
    final recentTrends = analysis.dailyTrends.length > 30
        ? analysis.dailyTrends.sublist(analysis.dailyTrends.length - 30)
        : analysis.dailyTrends;
    final hasTrends = recentTrends.isNotEmpty;
    final latest = hasTrends ? recentTrends.last : null;
    final earliest = hasTrends ? recentTrends.first : null;
    final delta = hasTrends ? (latest!.possibility - earliest!.possibility) : 0.0;
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '30초 간격',
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    final range = (maxValue - minValue).abs() < 0.0001 ? 0.1 : (maxValue - minValue);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const gridLines = 4;
    for (var i = 0; i <= gridLines; i++) {
      final y = chartRect.top + (chartRect.height / gridLines) * i;
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), gridPaint);
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
        final yOpen = chartRect.bottom - ((open - minValue) / range) * chartRect.height;
        final yClose = chartRect.bottom - ((close - minValue) / range) * chartRect.height;
        final yHigh = chartRect.bottom - ((high - minValue) / range) * chartRect.height;
        final yLow = chartRect.bottom - ((low - minValue) / range) * chartRect.height;

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
