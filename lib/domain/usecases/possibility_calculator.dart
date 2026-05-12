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

    // 3. 후보 경쟁력 (인지도 + 조직력 + 전문성)
    final viralIndex = _calculateViralIndex(member);
    final organizationalStrength = _calculateOrganizationalStrength(member);
    final expertiseScore = _calculateExpertiseScore(member);
    
    // 후보 경쟁력 가중치: 인지도 30% + 조직력 30% + 전문성 40%
    double candidateCompetitiveness = (viralIndex * 0.3 + organizationalStrength * 0.3 + expertiseScore * 0.4);
    
    // 현역 프리미엄 (+5~10%)
    if (member.career.contains('의원') || member.career.contains('현재')) {
      candidateCompetitiveness += 0.1;
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

    // 사회 공헌도 계산 (기존 로직 유지)
    final socialScore = _calculateSocialScore(member);

    // 강점/약점/개선점 생성
    final strengths = _generateStrengths(member, expertiseScore, socialScore);
    final weaknesses = _generateWeaknesses(member, viralIndex, partyScore);
    final improvements = _generateImprovements(member, weaknesses);

    return {
      'achievement': expertiseScore,
      'activity': viralIndex, 
      'policy': _calculateDetailScore(member.policies, maxValue: 15, memberId: member.id, seed: 3),
      'publicImage': organizationalStrength,
      'socialContribution': socialScore,
      'poll': currentPollSupport,
      'historical': historical2018,
      'overall': overall,
      'voterInterest': voterInterest,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'improvements': improvements,
      'viralIndex': viralIndex,
      'orgStrength': organizationalStrength,
      'expertise': expertiseScore,
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

  static double _calculateViralIndex(Member member) {
    if (member.pressReports.isEmpty) return 0.3;
    
    // 뉴스 노출도: 기사 건수 (기본)
    double score = (member.pressReports.length / 50).clamp(0.0, 1.0) * 0.6;
    
    // 가산점: 제목에 이름이 포함된 경우 (인지도 대폭 가점)
    int titleMatchCount = 0;
    for (var report in member.pressReports) {
      if (report.title.contains(member.name)) {
        titleMatchCount++;
      }
    }
    score += (titleMatchCount / 10).clamp(0.0, 0.4);
    
    return score.clamp(0.1, 1.0);
  }

  static double _calculateOrganizationalStrength(Member member) {
    double score = 0.3;
    
    // 경력 길이에 따른 조직력 유추
    if (member.career.length > 200) score += 0.2;
    if (member.career.contains('위원장') || member.career.contains('대표')) score += 0.2;
    
    // 지지 선언 분석 (뉴스 키워드)
    for (var report in member.pressReports) {
      if (report.title.contains('지지') || report.title.contains('단체')) {
        score += 0.1;
      }
    }
    
    return score.clamp(0.1, 1.0);
  }

  static double _calculateExpertiseScore(Member member) {
    double score = 0.4;
    
    // 학력 기반 (박사/석사)
    if (member.education.contains('박사')) score += 0.2;
    else if (member.education.contains('석사')) score += 0.1;
    
    // 전문 경력 기반
    final expertsKeywords = ['변호사', '교수', '의사', '회계사', '장관', '의원', '전문가'];
    for (var kw in expertsKeywords) {
      if (member.career.contains(kw)) {
        score += 0.15;
        break; 
      }
    }
    
    // 성과지수 (조례/활동)
    score += (member.achievementsList.length / 10).clamp(0.0, 0.25);
    
    return score.clamp(0.1, 1.0);
  }

  static List<String> _generateStrengths(Member member, double achievement, double social) {
    final list = <String>[];
    if (achievement > 0.7) list.add('전문성: ${member.education.contains('박사') ? '박사 학위' : '고도의 전문 경력'} 기반 정책 설계 능력');
    if (member.career.contains('위원장')) list.add('조직력: 당내 주요 직책 역임 및 지역 당원 결집력 우수');
    if (member.pressReports.any((r) => r.title.contains(member.name))) list.add('인지도: 지역 내 뉴스 노출 및 바이럴 지수 상위권');
    if (list.isEmpty) list.add('성실한 지역 활동 및 주민 소통 능력');
    return list;
  }

  static List<String> _generateWeaknesses(Member member, double publicImage, double party) {
    final list = <String>[];
    if (member.pressReports.length < 5) list.add('인지도: 온라인 및 언론 노출 빈도 보완 필요');
    if (party < 0.35) list.add('정당세: 지역 내 정당 지지율 정체 극복 과제');
    if (member.criminalRecord.isNotEmpty && member.criminalRecord != '없음') list.add('리스크: 도덕성 검증에 대한 선제적 대응 필요');
    if (list.isEmpty) list.add('청년층 및 신규 유입 유권자 대상 인지도 확장 과제');
    return list;
  }

  static List<String> _generateImprovements(Member member, List<String> weaknesses) {
    final list = <String>[];
    if (weaknesses.any((w) => w.contains('인지도'))) list.add('네이버 뉴스 및 SNS 검색 노출 최적화(SEO) 전략 필요');
    if (member.career.contains('의원')) list.add('의정 활동 성과(조례 발의 등)의 시각적 홍보 강화');
    if (member.party == '더불어민주당') list.add('정권 지원론을 활용한 지역 예산 확보 능력 강조');
    else list.add('거대 양당 구도를 넘어서는 후보 개인의 전문성 브랜딩 필요');
    return list;
  }
}
