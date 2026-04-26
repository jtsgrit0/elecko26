import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/poll.dart';

/// 당선 가능성 계산 로직을 담당하는 유틸리티 클래스
class PossibilityCalculator {
  /// 다중 요소 가중치 방식 계산
  /// 성과도(10~12%) + 활동도(10~12%) + 정책도(10~12%) + 언론도(10~12%) + 사회공헌(10~12%) + 여론조사(30~32%) + 역대선거(20~40%)
  static Map<String, double> calculateMultiFactorScores({
    required Member member,
    required double historicalBaseSupport,
    double voterInterest = 0.5,
  }) {
    // 1. 성과도 (0~1)
    final achievementScore = _calculateDetailScore(
      member.achievementsList,
      maxValue: 20,
      memberId: member.id,
      seed: 1,
    );

    // 2. 활동도 (0~1)
    final activityScore = _calculateDetailScore(
      member.actions,
      maxValue: 30,
      memberId: member.id,
      seed: 2,
    );

    // 3. 정책도 (0~1)
    final policyScore = _calculateDetailScore(
      member.policies,
      maxValue: 15,
      memberId: member.id,
      seed: 3,
    );

    // 4. 언론도 + 감정 분석 (0~1)
    final publicImageScore = _calculatePublicImageScore(member);

    // 5. 여론조사 평균 (0~1)
    final pollScore = _calculatePollScore(member);

    // 6. 역대 선거 지역 기반 지지율 (0~1)
    final historicalScore = historicalBaseSupport;

    // 7. 사회적 헌신도 (기부, 봉사 등)
    final socialScore = _calculateSocialScore(member);

    // 가중치 동적 재분배 시스템
    double overall;
    if (pollScore != null) {
      // (1) 여론조사가 있는 경우 (Poll 30%, Social 10%)
      overall = (achievementScore * 0.10) +
          (activityScore * 0.10) +
          (policyScore * 0.10) +
          (publicImageScore * 0.10) +
          (socialScore * 0.10) +
          (pollScore * 0.30) +
          (historicalScore * 0.20);
    } else {
      // (2) 여론조사가 미공개인 경우 (Social 12%, History 40%)
      overall = (achievementScore * 0.12) +
          (activityScore * 0.12) +
          (policyScore * 0.12) +
          (publicImageScore * 0.12) +
          (socialScore * 0.12) +
          (historicalScore * 0.40);
    }

    // 투표 관심도 조정
    final interestAdjustment = (voterInterest - 0.5) * 0.06;
    overall = (overall + interestAdjustment).clamp(0.01, 0.99);

    return {
      'achievement': achievementScore,
      'activity': activityScore,
      'policy': policyScore,
      'publicImage': publicImageScore,
      'socialContribution': socialScore,
      'poll': pollScore ?? -1.0,
      'historical': historicalScore,
      'overall': overall,
      'voterInterest': voterInterest,
    };
  }

  static double _calculateDetailScore(
    List<String> items, {
    required int maxValue,
    required String memberId,
    required int seed,
  }) {
    if (items.isEmpty) return 0.2;

    final countScore = (items.length / maxValue).clamp(0.0, 1.0) * 0.7;
    final totalLength = items.fold<int>(0, (sum, item) => sum + item.length);
    final avgLength = totalLength / items.length;
    final qualityScore = (avgLength / 50).clamp(0.0, 1.0) * 0.2;
    final uniqueness = (memberId.hashCode + seed).abs() % 100 / 1000.0;

    return (countScore + qualityScore + uniqueness).clamp(0.05, 0.98);
  }

  static double _calculatePublicImageScore(Member member) {
    if (member.pressReports.isEmpty) return 0.5;

    final pressCount = member.pressReports.length;
    final countScore = (pressCount / 50).clamp(0.0, 1.0);

    int positiveCount = 0;
    int neutralCount = 0;
    int negativeCount = 0;

    for (var report in member.pressReports) {
      if (report.sentiment == 'positive') positiveCount++;
      if (report.sentiment == 'neutral') neutralCount++;
      if (report.sentiment == 'negative') negativeCount++;
    }

    final sentimentScore =
        (positiveCount * 1.0 + neutralCount * 0.5 - negativeCount * 0.5) /
            member.pressReports.length.clamp(1, double.infinity);

    return ((countScore * 0.6) + (sentimentScore.clamp(0, 1) * 0.4))
        .clamp(0, 1);
  }

  static double? _calculatePollScore(Member member) {
    if (member.polls.isEmpty) return null;

    final recentPolls = member.polls.length > 5
        ? member.polls.sublist(member.polls.length - 5)
        : member.polls;

    final validRates = recentPolls
        .map((poll) => poll.supportRate)
        .whereType<double>()
        .toList();
    if (validRates.isEmpty) return null;

    final averageSupportRate =
        validRates.fold<double>(0, (sum, rate) => sum + rate) /
            validRates.length;

    final nesdcRates = recentPolls
        .where((p) =>
            p.id.startsWith('nesdc_') ||
            p.source.toLowerCase().contains('nesdc.go.kr'))
        .map((poll) => poll.supportRate)
        .whereType<double>()
        .toList();

    if (nesdcRates.isEmpty) return averageSupportRate.clamp(0, 1);

    final nesdcAverage = nesdcRates.fold<double>(0, (sum, rate) => sum + rate) /
        nesdcRates.length;

    final blended = (nesdcAverage * 0.60) + (averageSupportRate * 0.40);
    return blended.clamp(0, 1);
  }

  static double _calculateSocialScore(Member member) {
    if (member.socialContributions.isEmpty) return 0.3;

    final countScore =
        (member.socialContributions.length / 5).clamp(0.0, 1.0) * 0.5;

    double typeScore = 0.0;
    for (var contrib in member.socialContributions) {
      if (contrib.type.contains('기부')) typeScore += 0.1;
      if (contrib.type.contains('노블레스')) typeScore += 0.15;
      if (contrib.type.contains('봉사')) typeScore += 0.05;
    }
    typeScore = typeScore.clamp(0.0, 0.3);

    final now = DateTime.now();
    double recencyScore = 0.0;
    for (var contrib in member.socialContributions) {
      final yearsDiff = now.difference(contrib.date).inDays / 365;
      if (yearsDiff <= 3) recencyScore += 0.05;
    }
    recencyScore = recencyScore.clamp(0.0, 0.2);

    return (countScore + typeScore + recencyScore).clamp(0.1, 0.99);
  }
}
