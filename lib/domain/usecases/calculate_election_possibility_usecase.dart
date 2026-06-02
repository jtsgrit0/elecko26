import 'dart:math' as math;

import 'package:elecko26_new/domain/entities/analysis_result.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/poll.dart';
import 'package:elecko26_new/core/utils/utility_functions.dart';
import 'package:elecko26_new/domain/usecases/possibility_calculator.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/domain/repositories/historical_election_repository.dart';

/// 당선 가능성을 다각적으로 산정하는 UseCase
class CalculateElectionPossibilityUseCase {
  final MemberRepository repository;
  final HistoricalElectionRepository? historicalRepository;
  final Duration _trendInterval;
  final int _maxTrendPoints;
  final math.Random _random = math.Random();
  final Map<String, List<DailyPossibility>> _trendStore = {};

  CalculateElectionPossibilityUseCase({
    required this.repository,
    this.historicalRepository,
    Duration trendInterval = const Duration(seconds: 30),
    int maxTrendPoints = 2880,
  })  : _trendInterval = trendInterval,
        _maxTrendPoints = maxTrendPoints;

  Future<AnalysisResult> call(String memberId) async {
    final member = await repository.getMemberById(memberId);

    if (member == null) {
      throw Exception('Member not found');
    }

    // 0.1) 역대 선거 데이터에서 지역 기반 지지율 및 투표 관심도 조회
    double historicalBaseSupport = 0.5;
    double voterInterest = 0.5; // 기본값
    String? historicalContext;

    // 2018년도 정당 지지율 데이터 활용
    double party2018Support = 0.0;
    if (member.historical2018PartyRates.isNotEmpty) {
      final currentPartyRate =
          member.historical2018PartyRates[member.party] ?? 0.0;
      if (currentPartyRate > 0) {
        party2018Support = currentPartyRate / 100.0;
        historicalBaseSupport = party2018Support.clamp(0.0, 1.0);
      }
    }

    if (historicalRepository != null) {
      try {
        final region = getParentRegion(member.district) == ''
            ? '전국'
            : getParentRegion(member.district);
        final averages =
            await historicalRepository!.getRegionalPartyAverages(region);
        voterInterest = await historicalRepository!.getVoterInterest(region);

        final partyRate = averages[member.party];
        if (partyRate != null && party2018Support == 0.0) {
          // 2018년 데이터가 없는 경우에만 역사적 평균 사용
          historicalBaseSupport = (partyRate / 100.0).clamp(0.0, 1.0);
        }

        final dominant = await historicalRepository!.getDominantParty(region);
        final gap = dominant != null && averages[dominant] != null
            ? (averages[dominant]! - (partyRate ?? 0)).abs()
            : 0.0;
        historicalContext = _buildHistoricalContext(
          region,
          member.party,
          (partyRate ?? party2018Support * 100),
          dominant,
          gap,
          voterInterest,
        );
      } catch (_) {}
    }

    // A) 다중 요소 가중치 방식 계산 (공통 계산기 사용)
    final scores = PossibilityCalculator.calculateMultiFactorScores(
      member: member,
      historicalBaseSupport: historicalBaseSupport,
      voterInterest: voterInterest,
    );

    final double overallScore = scores['overall'] as double;

    // B) 30초 간격 추세 생성/갱신
    final dailyTrends = _getOrUpdateTrends(
      memberId: member.id,
      baseScore: overallScore,
    );

    // C) 상세 분석 데이터
    final analysis =
        _performDetailedAnalysis(member, scores, historicalContext);

    final recentSlice = dailyTrends.length > 7
        ? dailyTrends.sublist(dailyTrends.length - 7)
        : dailyTrends;
    final recentAvg = recentSlice.fold<double>(
          0,
          (sum, dp) => sum + dp.possibility,
        ) /
        (recentSlice.isEmpty ? 1 : recentSlice.length);

    return AnalysisResult(
      memberId: member.id,
      analysisDate: DateTime.now(),
      electionPossibility: overallScore,
      previousPossibility: dailyTrends.length > 1
          ? dailyTrends[dailyTrends.length - 2].possibility
          : recentAvg - 0.02,
      possibilityChange: recentAvg -
          (dailyTrends.length > 1
              ? dailyTrends[dailyTrends.length - 2].possibility
              : recentAvg - 0.02),
      achievementScore: scores['achievement'] as double,
      activityScore: scores['activity'] as double,
      policyScore: scores['policy'] as double,
      publicImageScore: scores['publicImage'] as double,
      socialContributionScore: scores['socialContribution'] as double,
      pollScore: scores['poll'] as double,
      historicalScore: scores['historical'] as double,
      improvements: List<String>.from(analysis['improvements'] ?? []),
      strengths: List<String>.from(analysis['strengths'] ?? []),
      weaknesses: List<String>.from(analysis['weaknesses'] ?? []),
      analysisReport: analysis['report']!,
      dailyTrends: dailyTrends,
      viralIndex: scores['viralIndex'] as double? ?? 0.3,
      orgStrength: scores['orgStrength'] as double? ?? 0.3,
      expertiseScore: scores['expertise'] as double? ?? 0.3,
      snsAnalysis: _calculateSnsAnalysis(member),
    );
  }

  /// B) 30초 간격 추세 생성/갱신
  List<DailyPossibility> _getOrUpdateTrends({
    required String memberId,
    required double baseScore,
  }) {
    final now = DateTime.now();
    final trends =
        _trendStore.putIfAbsent(memberId, () => <DailyPossibility>[]);

    if (trends.isEmpty) {
      const initialPoints = 30;
      final startTime = now.subtract(
        Duration(seconds: _trendInterval.inSeconds * (initialPoints - 1)),
      );
      var current = baseScore.clamp(0.2, 0.95);
      trends.add(
        DailyPossibility(
          date: startTime,
          possibility: current,
          reason: '초기 기준점',
        ),
      );
      for (var i = 1; i < initialPoints; i++) {
        final nextScore = _nextPossibility(current, baseScore);
        final delta = nextScore - current;
        current = nextScore;
        trends.add(
          DailyPossibility(
            date:
                startTime.add(Duration(seconds: _trendInterval.inSeconds * i)),
            possibility: current,
            reason: _trendReason(delta),
          ),
        );
      }
    }

    var last = trends.last;
    final elapsed = now.difference(last.date);
    final steps = elapsed.inSeconds ~/ _trendInterval.inSeconds;

    for (var i = 0; i < steps; i++) {
      final nextScore = _nextPossibility(last.possibility, baseScore);
      final nextDate = last.date.add(_trendInterval);
      final delta = nextScore - last.possibility;
      final reason = _trendReason(delta);

      final next = DailyPossibility(
        date: nextDate,
        possibility: nextScore,
        reason: reason,
      );
      trends.add(next);
      last = next;
    }

    if (trends.length > _maxTrendPoints) {
      trends.removeRange(0, trends.length - _maxTrendPoints);
    }

    return trends;
  }

  double _nextPossibility(double previous, double baseScore) {
    final drift = (baseScore - previous) * 0.08;
    final noise = (_random.nextDouble() - 0.5) * 0.03; // 약 ±1.5%
    final next = (previous + drift + noise).clamp(0.2, 0.85);
    return next;
  }

  String _trendReason(double delta) {
    if (delta > 0.01) {
      return '여론 상승';
    }
    if (delta < -0.01) {
      return '여론 하락';
    }
    return '보합';
  }

  /// C) 상세 분석 데이터
  Map<String, dynamic> _performDetailedAnalysis(
    Member member,
    Map<String, dynamic> scores, [
    String? historicalContext,
  ]) {
    final strengths = List<String>.from(scores['strengths'] ?? []);
    final weaknesses = List<String>.from(scores['weaknesses'] ?? []);
    final improvements = List<String>.from(scores['improvements'] ?? []);

    // 기존 분석 로직 보완 (데이터가 부족할 경우 추가)
    if (strengths.isEmpty && member.achievementsList.isNotEmpty) {
      strengths.add('성과: ${member.achievementsList.first}');
    }
    if (weaknesses.isEmpty && member.policies.isEmpty) {
      weaknesses.add('정책: 아직 구체적인 정책 공약이 발표되지 않음');
    }

    final historicalPct = scores['historical'] != null
        ? (scores['historical']! * 100).toStringAsFixed(1)
        : 'N/A';

    final overall = ((scores['overall'] as double) * 100).toStringAsFixed(1);
    final poll = ((scores['poll'] as double) * 100).toStringAsFixed(1);
    final hist = ((scores['historical'] as double) * 100).toStringAsFixed(1);
    final achievement =
        ((scores['achievement'] as double) * 100).toStringAsFixed(1);
    final social =
        ((scores['socialContribution'] as double) * 100).toStringAsFixed(1);
    final public = ((scores['publicImage'] as double) * 100).toStringAsFixed(1);

    final report = '''
【${member.name} 의원 당선 가능성 분석 보고서】

1. 개요
분석일: ${DateTime.now().toString().split(' ')[0]}
현재 당선 가능성: $overall% (2018 비교 모델 적용)

2. 점수 분석 (2026 전략 가중치 반영)
- 정당 지지율(현재+2018): $poll% (가중치 60%)
- 지역별 보정 계수: $hist% (가중치 20%)
- 후보 경쟁력: $achievement% (가중치 20%)
- 세부 성과도: $achievement%
- 사회공헌도: $social%
- 언론 평판: $public%
${(scores['poll'] as double) < 0 ? '\n※ 여론조사 미반영에 따라 지역 성향 및 실적 중심의 예측 모델로 보정되었습니다.\n' : ''}
${_generateSocialSummary(member)}

3. 여론조사 현황
${_generatePollSummary(member)}

${historicalContext != null ? '4. 역대 선거 분석\n$historicalContext\n\n5. 강점' : '4. 강점'}
${strengths.isEmpty ? '• 주요 강점 분석 중' : strengths.map((s) => '• $s').join('\n')}

${historicalContext != null ? '6' : '5'}. 약점
${weaknesses.isEmpty ? '• 주요 약점 없음' : weaknesses.map((w) => '• $w').join('\n')}

${historicalContext != null ? '7' : '6'}. 권고사항
${improvements.isEmpty ? '• 현황 유지' : improvements.map((i) => '• $i').join('\n')}
    ''';

    return {
      'strengths': strengths,
      'weaknesses': weaknesses,
      'improvements': improvements,
      'report': report,
    };
  }

  /// 여론조사 요약 생성
  String _generatePollSummary(Member member) {
    if (member.polls.isEmpty) {
      return '• 여론조사 데이터 없음';
    }

    final latestPoll = member.polls.last;
    final validRates =
        member.polls.map((p) => p.supportRate).whereType<double>().toList();
    final avgRate = validRates.isNotEmpty
        ? validRates.fold<double>(0, (sum, r) => sum + r) / validRates.length
        : null;

    final buffer = StringBuffer();
    buffer.writeln(
        '• 최신 조사: ${latestPoll.pollAgency} (${latestPoll.surveyDate.toString().split(' ')[0]})');
    final latestSupport = latestPoll.supportRate == null
        ? '미반영 (결과 미공개)'
        : '${(latestPoll.supportRate! * 100).toStringAsFixed(1)}%';
    final sampleText =
        latestPoll.sampleSize == null ? '미공개' : '${latestPoll.sampleSize}명';
    buffer.writeln('• 지지율: $latestSupport (표본: $sampleText)');
    if (avgRate == null) {
      buffer.writeln('• 평균 지지율: 미반영 (결과 미공개, ${member.polls.length}건 조사 기준)');
    } else {
      buffer.writeln(
          '• 평균 지지율: ${(avgRate * 100).toStringAsFixed(1)}% (${member.polls.length}건 조사 기준)');
    }
    buffer.writeln(
        '• 조사 기관: ${member.polls.map((p) => p.pollAgency).toSet().join(', ')}');

    return buffer.toString();
  }

  /// 사회 공헌 요약 리포트 생성
  String _generateSocialSummary(Member member) {
    if (member.socialContributions.isEmpty) {
      return '• 사회 공헌: 공식적으로 확인된 기부/봉사 내역이 부족합니다. (도덕성 보강 필요)';
    }

    final latest = member.socialContributions.first;
    final buffer = StringBuffer();
    buffer.writeln('• 사회적 책임: ${member.socialContributions.length}건의 공헌 내역 확인');
    buffer.writeln('  - 최근 활동: ${latest.description} (${latest.type})');
    return buffer.toString();
  }

  /// SNS 분석 계산 (감정분석 + 언급량)
  SnsAnalysis? _calculateSnsAnalysis(Member member) {
    // 언론 보도로부터 SNS 감정 데이터 추출
    if (member.pressReports.isEmpty) {
      // SNS 데이터가 없을 경우 null 또는 기본값 반환
      return null;
    }

    int totalMentions = member.pressReports.length;
    int positiveMentions = 0;
    int neutralMentions = 0;
    int negativeMentions = 0;

    // 언론 보도의 감정 분석 데이터를 SNS 데이터로 활용
    final sentimentTexts = <String>[];
    for (var report in member.pressReports) {
      sentimentTexts.add(report.title.toLowerCase());
      if (report.sentiment == 'positive') {
        positiveMentions++;
      } else if (report.sentiment == 'neutral') {
        neutralMentions++;
      } else if (report.sentiment == 'negative') {
        negativeMentions++;
      }
    }

    // 감정 점수 계산 (-1 ~ 1 범위를 0 ~ 1로 정규화)
    final denominator = totalMentions > 0 ? totalMentions.toDouble() : 1.0;
    final sentimentScore = ((positiveMentions * 1.0 -
                negativeMentions * 1.0 +
                neutralMentions * 0.3) /
            denominator)
        .clamp(-1.0, 1.0)
        .clamp(0.0, 1.0);

    // 상위 언급 키워드 추출
    final topMentions = _extractTopKeywords(sentimentTexts, count: 5);

    // 추세 판단 (언론 보도 수 기반)
    final recentReports = member.pressReports.length > 3
        ? member.pressReports.sublist(member.pressReports.length - 3)
        : member.pressReports;
    final recentPositive =
        recentReports.where((r) => r.sentiment == 'positive').length;
    final engagementTrend =
        recentPositive > recentReports.length ~/ 2 ? '상승' : '하락';

    return SnsAnalysis(
      totalMentions: totalMentions,
      positiveMentions: positiveMentions,
      neutralMentions: neutralMentions,
      negativeMentions: negativeMentions,
      sentimentScore: sentimentScore,
      topMentions: topMentions,
      engagementTrend: engagementTrend,
    );
  }

  /// 텍스트에서 상위 키워드 추출
  List<String> _extractTopKeywords(List<String> texts, {required int count}) {
    final keywords = <String>[];
    final stopWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      '발표',
      '보도',
      '했',
      '한다',
      '입니다',
      '것',
      '수',
      '들',
      '등',
      '중'
    };

    for (final text in texts) {
      final words = text
          .split(RegExp(r'[^\w가-힣]+', multiLine: true))
          .where((w) =>
              w.isNotEmpty &&
              w.length > 2 &&
              !stopWords.contains(w.toLowerCase()))
          .toList();
      keywords.addAll(words);
    }

    // 가장 빈번한 키워드 추출
    final wordFreq = <String, int>{};
    for (final word in keywords) {
      wordFreq[word] = (wordFreq[word] ?? 0) + 1;
    }

    final sortedEntries = wordFreq.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(count).map((e) => e.key).toList();
  }

  /// 역대 선거 데이터 기반 맥락 텍스트 생성
  String _buildHistoricalContext(
    String region,
    String party,
    double partyRate,
    String? dominant,
    double gap,
    double interest,
  ) {
    final sb = StringBuffer();
    sb.writeln(
        '• 해당 지역은 $party의 역대 평균 지지율이 ${partyRate.toStringAsFixed(1)}%로 집계된 지역입니다.');

    // 2018년도 탄핵 이후 선거와 현재 상황 비교 분석
    sb.writeln(
        '• 2018년 박근혜 탄핵이후 열린 선거와 비슷하게 윤석열도 탄핵되어 유사한 양상을 띄고 있는 이번 선거에 2018년도 지방선거 결과를 충분히 반영하였습니다');

    if (dominant == party) {
      if (gap > 10) {
        sb.writeln(
            '  ⚡ 압도적 우위 지역: 상대 정당 대비 ${gap.toStringAsFixed(1)}%p 차이로 매우 유리한 기반을 보유하고 있습니다.');
      } else {
        sb.writeln('• 유지/수성 필요 지역: 현재 우위를 점하고 있으나 격차가 크지 않아 적극적인 관리가 필요합니다.');
      }
    } else if (dominant != null) {
      sb.writeln(
          '• 접전 및 탈환 가능 지역: $dominant와의 격차가 ${gap.toStringAsFixed(1)}%p로, 전략적 공략 시 승산이 있습니다.');
    }

    return sb.toString();
  }
}