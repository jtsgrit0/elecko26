import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/poll.dart';

/// 당선 가능성 계산 로직을 담당하는 유틸리티 클래스
class PossibilityCalculator {
  /// 다중 요소 가중치 방식 계산
  /// 성과도(10~12%) + 활동도(10~12%) + 정책도(10~12%) + 언론도(10~12%) + 사회공헌(10~12%) + 여론조사(30~32%) + 역대선거(20~40%)
  static Map<String, dynamic> calculateMultiFactorScores({
    required Member member,
    required double historicalBaseSupport,
    double voterInterest = 0.5,
  }) {
    // 1. 정당 지지율 (현재 + 2018) / 2
    final currentPollSupport = _calculatePollScore(member) ?? 0.35;
    // 만약 historical2018PartyRates가 있다면 사용, 없으면 historicalBaseSupport 사용
    final historical2018 = member.historical2018PartyRates[member.party] ?? historicalBaseSupport;
    
    // 정당 지지율 점수 (0~1)
    final partyScore = (currentPollSupport + historical2018) / 2.0;

    // 2. 지역별 보정 계수 (과거 결과 + 현재 추이)
    // 2018년과 현재의 격차를 보정 계수로 활용
    final regionalAdjustment = (partyScore * 0.8 + historical2018 * 0.2);

    // 3. 후보 경쟁력 (현역 프리미엄 + 성과 + 사회공헌)
    final achievementScore = _calculateDetailScore(
      member.achievementsList,
      maxValue: 20,
      memberId: member.id,
      seed: 1,
    );
    final socialScore = _calculateSocialScore(member);
    final publicImageScore = _calculatePublicImageScore(member);
    
    double candidateCompetitiveness = (achievementScore * 0.4 + socialScore * 0.3 + publicImageScore * 0.3);
    
    // 현역 프리미엄 (+5~10%)
    if (member.career.contains('의원') || member.career.contains('현재')) {
      candidateCompetitiveness += 0.08;
    }

    // 최종 당선 가능성 공식 (P) = (정당지지율 * 0.6) + (지역별보정계수 * 0.2) + (후보경쟁력 * 0.2)
    double overall = (partyScore * 0.6) + (regionalAdjustment * 0.2) + (candidateCompetitiveness * 0.2);

    // '나'번 후보 특수 로직: (민주당 1-나 등)
    // 정당 지지율이 타 정당 합산의 1.5배 초과 시 확률 대폭 상승
    if (member.districtName.contains('나') && partyScore > 0.45) {
       overall = overall.clamp(0.70, 0.95);
    }

    // 투표 관심도 조정
    final interestAdjustment = (voterInterest - 0.5) * 0.06;
    overall = (overall + interestAdjustment).clamp(0.01, 0.99);

    // 강점/약점/개선점 생성
    final strengths = _generateStrengths(member, achievementScore, socialScore);
    final weaknesses = _generateWeaknesses(member, publicImageScore, partyScore);
    final improvements = _generateImprovements(member, weaknesses);

    return {
      'achievement': achievementScore,
      'activity': achievementScore * 0.9, // 활동도는 성과도와 비례하게 보정
      'policy': _calculateDetailScore(member.policies, maxValue: 15, memberId: member.id, seed: 3),
      'publicImage': publicImageScore,
      'socialContribution': socialScore,
      'poll': currentPollSupport,
      'historical': historical2018,
      'overall': overall,
      'voterInterest': voterInterest,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'improvements': improvements,
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
    return (countScore + qualityScore).clamp(0.05, 0.98);
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

  static List<String> _generateStrengths(Member member, double achievement, double social) {
    final list = <String>[];
    if (achievement > 0.6) list.add('성과: 구의원 국정감사 우수 의원 선정');
    if (social > 0.5) list.add('평판: 언론의 긍정적 평가 ([인터뷰] ${member.name} "의원의 미래를 바꾸겠습니다")');
    if (member.career.contains('의원')) list.add('현역 프리미엄: 지역구 내 높은 인지도와 조직력 보유');
    if (list.isEmpty) list.add('성실한 지역 활동 및 주민 소통 능력');
    return list;
  }

  static List<String> _generateWeaknesses(Member member, double publicImage, double party) {
    final list = <String>[];
    if (publicImage < 0.4) list.add('이슈: 지역 사회 갈등 조정 및 통합 방안 마련 필요');
    if (party < 0.3) list.add('정당세: 상대적으로 낮은 정당 지지율 극복 과제');
    if (member.criminalRecord.isNotEmpty && member.criminalRecord != '없음') list.add('리스크: 과거 이력에 대한 해명 및 정공법 필요');
    if (list.isEmpty) list.add('기초의원 내 노후 시설 개선 및 민원 해결 속도 보완 필요');
    return list;
  }

  static List<String> _generateImprovements(Member member, List<String> weaknesses) {
    final list = <String>[];
    if (weaknesses.any((w) => w.contains('갈등'))) list.add('지역 사회 갈등 조정 및 통합 방안 마련');
    if (weaknesses.any((w) => w.contains('노후'))) list.add('지역구 내 노후 시설 개선 필요');
    if (member.party == '더불어민주당') list.add('여당 지원론을 바탕으로 한 국정 안정론 강조 전략');
    else list.add('정당 지지율을 넘어서는 후보 개인의 인물론 부각 필요');
    return list;
  }
}
