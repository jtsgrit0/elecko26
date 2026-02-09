import 'dart:math' as math;

import 'package:flutter_application_1/domain/entities/analysis_result.dart';
import 'package:flutter_application_1/domain/entities/member.dart';
import 'package:flutter_application_1/domain/entities/poll.dart';
import 'package:flutter_application_1/domain/repositories/member_repository.dart';

/// 당선 가능성을 다각적으로 산정하는 UseCase
class CalculateElectionPossibilityUseCase {
  final MemberRepository repository;
  final Duration _trendInterval;
  final int _maxTrendPoints;
  final math.Random _random = math.Random();
  final Map<String, List<DailyPossibility>> _trendStore = {};

  CalculateElectionPossibilityUseCase({
    required this.repository,
    Duration trendInterval = const Duration(seconds: 30),
    int maxTrendPoints = 2880,
  })  : _trendInterval = trendInterval,
        _maxTrendPoints = maxTrendPoints;

  Future<AnalysisResult> call(String memberId) async {
    final member = await repository.getMemberById(memberId);

    if (member == null) {
      throw Exception('Member not found');
    }

    // A) 다중 요소 가중치 방식 계산
    final scores = _calculateMultiFactorScores(member);

    // B) 30초 간격 추세 생성/갱신
    final dailyTrends = _getOrUpdateTrends(
      memberId: member.id,
      baseScore: scores['overall']!,
    );

    // C) 상세 분석 데이터
    final analysis = _performDetailedAnalysis(member, scores);

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
      electionPossibility: recentAvg,
      previousPossibility: dailyTrends.length > 1
          ? dailyTrends[dailyTrends.length - 2].possibility
          : recentAvg - 0.02,
      possibilityChange: recentAvg -
          (dailyTrends.length > 1
              ? dailyTrends[dailyTrends.length - 2].possibility
              : recentAvg - 0.02),
      achievementScore: scores['achievement']!,
      activityScore: scores['activity']!,
      policyScore: scores['policy']!,
      publicImageScore: scores['publicImage']!,
      improvements: analysis['improvements']!,
      strengths: analysis['strengths']!,
      weaknesses: analysis['weaknesses']!,
      analysisReport: analysis['report']!,
      dailyTrends: dailyTrends,
      snsAnalysis: _calculateSnsAnalysis(member),
    );
  }

  /// A) 다중 요소 가중치 방식 (여론조사 포함)
  /// 성과도(15%) + 활동도(15%) + 정책도(15%) + 언론도(15%) + 여론조사(40%)
  Map<String, double> _calculateMultiFactorScores(Member member) {
    // 1. 성과도 (0~1)
    final achievementScore = _normalizeScore(
      member.achievementsList.length,
      maxValue: 20,
    );

    // 2. 활동도 (0~1)
    final activityScore = _normalizeScore(
      member.actions.length,
      maxValue: 30,
    );

    // 3. 정책도 (0~1)
    final policyScore = _normalizeScore(
      member.policies.length,
      maxValue: 15,
    );

    // 4. 언론도 + 감정 분석 (0~1)
    final publicImageScore = _calculatePublicImageScore(member);

    // 5. 여론조사 평균 (0~1)
    final pollScore = _calculatePollScore(member);

    // 가중치 평균 계산
    final overallScore = (achievementScore * 0.15) +
        (activityScore * 0.15) +
        (policyScore * 0.15) +
        (publicImageScore * 0.15) +
        (pollScore * 0.40);  // 여론조사가 가장 중요함

    return {
      'achievement': achievementScore,
      'activity': activityScore,
      'policy': policyScore,
      'publicImage': publicImageScore,
      'poll': pollScore,
      'overall': overallScore,
    };
  }

  /// B) 30초 간격 추세 생성/갱신
  List<DailyPossibility> _getOrUpdateTrends({
    required String memberId,
    required double baseScore,
  }) {
    final now = DateTime.now();
    final trends = _trendStore.putIfAbsent(memberId, () => <DailyPossibility>[]);

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
            date: startTime.add(Duration(seconds: _trendInterval.inSeconds * i)),
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
    final next = (previous + drift + noise).clamp(0.2, 0.95);
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
    Map<String, double> scores,
  ) {
    final strengths = <String>[];
    final weaknesses = <String>[];

    // 강점 분석
    if (scores['achievement']! > 0.7) {
      strengths.add('뛰어난 정치 경력과 성과');
    }
    if (scores['activity']! > 0.7) {
      strengths.add('높은 의정 활동도');
    }
    if (scores['policy']! > 0.7) {
      strengths.add('다양한 정책 제안');
    }
    if (scores['publicImage']! > 0.7) {
      strengths.add('긍정적인 언론 평가');
    }
    if (scores['poll']! > 0.65) {
      strengths.add('높은 여론조사 지지율');
    }

    // 약점 분석
    if (scores['achievement']! < 0.4) {
      weaknesses.add('정치적 성과 미흡');
    }
    if (scores['activity']! < 0.4) {
      weaknesses.add('의정 활동도 부족');
    }
    if (scores['policy']! < 0.4) {
      weaknesses.add('정책 개발 필요');
    }
    if (scores['publicImage']! < 0.4) {
      weaknesses.add('언론 신뢰도 개선 필요');
    }
    if (scores['poll']! < 0.50) {
      weaknesses.add('여론조사 지지율 미흡');
    }

    // 개선점 제시
    final improvements = <String>[];
    if (scores['achievement']! < 0.6) {
      improvements.add('${member.name} 의원의 주요 성과를 지속적으로 홍보하기');
    }
    if (scores['activity']! < 0.6) {
      improvements.add('의정 활동 빈도와 범위를 확대하기');
    }
    if (scores['policy']! < 0.6) {
      improvements.add('지역구 현안 해결을 위한 정책안 개발');
    }
    if (scores['publicImage']! < 0.6) {
      improvements.add('긍정적인 언론 보도 확보');
    }
    if (scores['poll']! < 0.60) {
      improvements.add('여론 확대를 위한 지역 소통 강화');
    }

    final report = '''
【${member.name} 의원 당선 가능성 분석 보고서】

1. 개요
분석일: ${DateTime.now().toString().split(' ')[0]}
현재 당선 가능성: ${(scores['overall']! * 100).toStringAsFixed(1)}%

2. 점수 분석
- 성과도: ${(scores['achievement']! * 100).toStringAsFixed(1)}% (15%)
- 활동도: ${(scores['activity']! * 100).toStringAsFixed(1)}% (15%)
- 정책도: ${(scores['policy']! * 100).toStringAsFixed(1)}% (15%)
- 언론도: ${(scores['publicImage']! * 100).toStringAsFixed(1)}% (15%)
- 여론조사 지지율: ${(scores['poll']! * 100).toStringAsFixed(1)}% (40% - 가중치)

3. 여론조사 현황
${_generatePollSummary(member)}

4. 강점
${strengths.isEmpty ? '• 주요 강점 분석 중' : strengths.map((s) => '• $s').join('\n')}

5. 약점
${weaknesses.isEmpty ? '• 주요 약점 없음' : weaknesses.map((w) => '• $w').join('\n')}

6. 권고사항
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
    final validRates = member.polls
        .map((p) => p.supportRate)
        .whereType<double>()
        .toList();
    final avgRate = validRates.isNotEmpty
        ? validRates.fold<double>(0, (sum, r) => sum + r) / validRates.length
        : null;

    final buffer = StringBuffer();
    buffer.writeln('• 최신 조사: ${latestPoll.pollAgency} (${latestPoll.surveyDate.toString().split(' ')[0]})');
    final latestSupport = latestPoll.supportRate == null
        ? '결과 미공개'
        : '${(latestPoll.supportRate! * 100).toStringAsFixed(1)}%';
    final sampleText = latestPoll.sampleSize == null ? '미공개' : '${latestPoll.sampleSize}명';
    buffer.writeln('• 지지율: $latestSupport (표본: $sampleText)');
    if (avgRate == null) {
      buffer.writeln('• 평균 지지율: 결과 미공개 (${member.polls.length}건 조사 기준)');
    } else {
      buffer.writeln('• 평균 지지율: ${(avgRate * 100).toStringAsFixed(1)}% (${member.polls.length}건 조사 기준)');
    }
    buffer.writeln('• 조사 기관: ${member.polls.map((p) => p.pollAgency).toSet().join(', ')}');

    return buffer.toString();
  }

  /// 언론도 + 감정 분석 계산
  double _calculatePublicImageScore(Member member) {
    if (member.pressReports.isEmpty) {
      return 0.5; // 언론 보도가 없으면 중립
    }

    final pressCount = member.pressReports.length;
    final countScore = _normalizeScore(pressCount, maxValue: 50);

    // 감정 분석
    int positiveCount = 0;
    int neutralCount = 0;
    int negativeCount = 0;

    for (var report in member.pressReports) {
      if (report.sentiment == 'positive') positiveCount++;
      if (report.sentiment == 'neutral') neutralCount++;
      if (report.sentiment == 'negative') negativeCount++;
    }

    final sentimentScore = (positiveCount * 1.0 + neutralCount * 0.5 - negativeCount * 0.5) /
        member.pressReports.length.clamp(1, double.infinity);

    return ((countScore * 0.6) + (sentimentScore.clamp(0, 1) * 0.4)).clamp(0, 1);
  }

  /// 0~1 범위로 점수 정규화
  /// 여론조사 점수 계산 (최근 여론조사 평균)
  double _calculatePollScore(Member member) {
    if (member.polls.isEmpty) {
      return 0.5; // 여론조사가 없으면 중립
    }

    // 최근 여론조사부터 최대 5개만 사용 (최근성 반영)
    final recentPolls = member.polls.length > 5
        ? member.polls.sublist(member.polls.length - 5)
        : member.polls;

    final validRates = recentPolls
        .map((poll) => poll.supportRate)
        .whereType<double>()
        .toList();
    if (validRates.isEmpty) {
      return 0.5;
    }

    final averageSupportRate =
        validRates.fold<double>(0, (sum, rate) => sum + rate) / validRates.length;

    final nesdcRates = recentPolls
        .where(_isNesdcPoll)
        .map((poll) => poll.supportRate)
        .whereType<double>()
        .toList();

    if (nesdcRates.isEmpty) {
      // 지지율을 0~1로 정규화 (50% = 0.5, 70% = 0.7)
      return averageSupportRate.clamp(0, 1);
    }

    final nesdcAverage =
        nesdcRates.fold<double>(0, (sum, rate) => sum + rate) / nesdcRates.length;

    // NESDC 데이터를 우선 반영하되 기존 여론조사도 일부 반영
    final blended = (nesdcAverage * 0.60) + (averageSupportRate * 0.40);
    return blended.clamp(0, 1);
  }

  bool _isNesdcPoll(Poll poll) {
    if (poll.id.startsWith('nesdc_')) {
      return true;
    }
    final source = poll.source.toLowerCase();
    return source.contains('nesdc.go.kr');
  }

  double _normalizeScore(int actual, {required int maxValue}) {
    return (actual / maxValue).clamp(0, 1);
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
      sentimentTexts.add(report.summary.toLowerCase());
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
    final sentimentScore = ((positiveMentions * 1.0 - negativeMentions * 1.0 + neutralMentions * 0.3) /
        denominator)
        .clamp(-1.0, 1.0)
        .clamp(0.0, 1.0);

    // 상위 언급 키워드 추출
    final topMentions = _extractTopKeywords(sentimentTexts, count: 5);

    // 추세 판단 (언론 보도 수 기반)
    final recentReports = member.pressReports.length > 3
        ? member.pressReports.sublist(member.pressReports.length - 3)
        : member.pressReports;
    final recentPositive = recentReports.where((r) => r.sentiment == 'positive').length;
    final engagementTrend = recentPositive > recentReports.length ~/ 2 ? '상승' : '하락';

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
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 
      '발표', '보도', '했', '한다', '입니다', '것', '수', '들', '등', '중'
    };

    for (final text in texts) {
      final words = text.split(RegExp(r'[^\w가-힣]+', multiLine: true))
          .where((w) => w.isNotEmpty && w.length > 2 && !stopWords.contains(w.toLowerCase()))
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
    
    return sortedEntries
        .take(count)
        .map((e) => e.key)
        .toList();
  }
}
