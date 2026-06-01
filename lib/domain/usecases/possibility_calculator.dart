import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/poll.dart';

/// 당선 가능성 계산 로직을 담당하는 유틸리티 클래스
class PossibilityCalculator {
  // 정당별 최신 전국 지지율 트렌드 기본값
  static double _getPartyDefaultSupport(String party) {
    final name = party.trim();
    if (name.contains('더불어민주당') || name.contains('민주당')) return 0.385;
    if (name.contains('국민의힘')) return 0.342;
    if (name.contains('조국혁신당')) return 0.118;
    if (name.contains('개혁신당')) return 0.048;
    if (name.contains('진보당')) return 0.025;
    if (name.contains('정의당') || name.contains('녹색정의당')) return 0.018;
    if (name.contains('자유통일당')) return 0.015;
    return 0.075; // 무소속 및 기타 정당
  }

  // 출마 지역구별 정당 적합도 프리미엄/패널티
  static double _getRegionalPartyPremium(String district, String party) {
    final d = district.toLowerCase();
    final p = party.toLowerCase();
    
    // 대구, 경북, 부산, 울산, 경남 (영남권) -> 국민의힘 강세
    if (d.contains('대구') || d.contains('경북') || d.contains('경상북도') || d.contains('울산') || d.contains('부산') || d.contains('경남') || d.contains('경상남도')) {
      if (p.contains('국민의힘')) return 0.0775;
      if (p.contains('민주당') || p.contains('혁신당') || p.contains('진보당')) return -0.0525;
    }
    // 광주, 전남, 전북 (호남권) -> 야권 강세
    if (d.contains('광주') || d.contains('전남') || d.contains('전라남') || d.contains('전북') || d.contains('전라북')) {
      if (p.contains('민주당')) return 0.0825;
      if (p.contains('혁신당')) return 0.0425;
      if (p.contains('국민의힘')) return -0.076;
    }
    // 대전, 세종, 충청 -> 스윙벨트 미세보정
    if (d.contains('대전') || d.contains('세종') || d.contains('충청')) {
      return 0.012;
    }
    return 0.0;
  }

  /// 다중 요소 가중치 방식 계산
  static Map<String, dynamic> calculateMultiFactorScores({
    required Member member,
    required double historicalBaseSupport,
    double voterInterest = 0.5,
  }) {
    // 1. 정당 지지율 (현재 + 2018) / 2
    final currentPollSupport = _calculatePollScore(member) ?? _getPartyDefaultSupport(member.party);
    
    final historical2018 =
        member.historical2018PartyRates[member.party] ?? historicalBaseSupport;

    // 정당 지지율 점수 (0~1)
    final partyScore = (currentPollSupport + historical2018) / 2.0;

    // 2. 지역별 보정 계수 (과거 결과 + 현재 추이)
    final regionalAdjustment = (partyScore * 0.8 + historical2018 * 0.2);

    // 3. 후보 경쟁력 (인지도 + 조직력 + 전문성)
    final viralIndex = _calculateViralIndex(member);
    final organizationalStrength = _calculateOrganizationalStrength(member);
    final expertiseScore = _calculateExpertiseScore(member);

    // 후보 경쟁력 가중치: 인지도 30% + 조직력 30% + 전문성 40%
    double candidateCompetitiveness = (viralIndex * 0.3 +
        organizationalStrength * 0.3 +
        expertiseScore * 0.4);

    // 현역 프리미엄 (+5~10%)
    if (member.career.contains('의원') || member.career.contains('현재')) {
      candidateCompetitiveness += 0.1;
    }

    // 무당층 보정 로직 적용 (우세 정당일 경우에만)
    final dominantParty = _determineDominantParty(member, historical2018);
    final adjustedPartyScore =
        _applySwingVoterCorrection(partyScore, member.party, dominantParty);

    // 최종 당선 가능성 공식 (P) = (정당지지율 * 0.6) + (지역별보정계수 * 0.2) + (후보경쟁력 * 0.2)
    double overall = (adjustedPartyScore * 0.6) +
        (regionalAdjustment * 0.2) +
        (candidateCompetitiveness * 0.2);

    // [지역 성향 프리미엄 반영]
    final regionalPremium = _getRegionalPartyPremium(member.district, member.party);
    overall += regionalPremium;

    // [후보자 개인 나이 보정]
    final age = DateTime.now().year - member.birthDate.year;
    double ageAdjustment = 0.0;
    if (age < 40) {
      ageAdjustment = 0.0125; // 청년 가점
    } else if (age > 70) {
      ageAdjustment = -0.0075; // 고령 감점
    }
    overall += ageAdjustment;

    // [후보자 약력 및 경력 분량 보정] 제거
    // final careerLinesCount = member.career.split('\n').length;
    // final careerScoreAdjustment = (careerLinesCount * 0.003).clamp(0.0, 0.02);
    // overall += careerScoreAdjustment;

    // '나'번 후보 특수 로직: (민주당 1-나 등)
    if (member.districtName.contains('나') && partyScore > 0.45) {
      overall = overall.clamp(0.70, 0.95);
    }

    // 투표 관심도 조정
    final interestAdjustment = (voterInterest - 0.5) * 0.06;
    overall = (overall + interestAdjustment).clamp(0.01, 0.95); // 0.95로 상한선 조정

    // PDF에서 이미 계산된 후보 점수를 기준선으로 유지
    final pdfBaseline = member.electionPossibility.clamp(0.0, 0.95); // 0.95로 상한선 조정
    if (pdfBaseline > 0.0) {
      overall = (overall * 0.72) + (pdfBaseline * 0.28);
    }

    // [후보 고유 해시 기반 초정밀 변별도 부여 - Jitter]
    final pdfAdjustment = _calculatePdfCandidateAdjustment(member);
    overall = (overall + pdfAdjustment).clamp(0.01, 0.95); // 0.95로 상한선 조정

    // 모든 처리가 끝난 후 미세 Jitter(Jitter 해시값에 0.035 이내 부여) 추가 적용
    final uniqueSig = '${member.id}_${member.name}_${member.district}_sig';
    final jitterHash = _stableHash(uniqueSig);
    final jitterOffset = ((jitterHash % 50000) / 50000.0 - 0.5) * 0.07; // -3.5% ~ +3.5%
    overall = (overall + jitterOffset).clamp(0.01, 0.95); // 0.95로 상한선 조정

    // 사회 공헌도 계산 (기존 로직 유지)
    final socialScore = _calculateSocialScore(member);

    // 강점/약점/개선점 생성
    final strengths = _generateStrengths(member, expertiseScore, socialScore);
    final weaknesses =
        _generateWeaknesses(member, viralIndex, adjustedPartyScore);
    final improvements = _generateImprovements(member, weaknesses);

    // 격전지 지수 계산
    final battlegroundIndex =
        calculateBattlegroundIndex(member, adjustedPartyScore);

    return {
      'achievement': expertiseScore,
      'activity': viralIndex,
      'policy': _calculateDetailScore(member.policies,
          maxValue: 15, memberId: member.id, seed: 3),
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
      'battlegroundIndex': battlegroundIndex,
      'pdfAdjustment': pdfAdjustment,
    };
  }

  static double _calculatePdfCandidateAdjustment(Member member) {
    final signature = [
      member.sourceUrl,
      member.name,
      member.party,
      member.constituency,
      member.districtName,
      member.region,
      member.electionType,
      member.candidateStatus,
      member.occupation,
      member.education,
      member.career,
      member.gender,
      member.birthDate.toIso8601String(),
      member.electionCount.toString(),
      member.tags.join(','),
      member.polls.length.toString(),
      member.pressReports.length.toString(),
      member.socialContributions.length.toString(),
      member.achievementsList.length.toString(),
      member.policies.length.toString(),
      member.improvementPoints.length.toString(),
    ].join('|');

    final hash = _stableHash(signature);
    final hashOffset = ((hash % 1000000) / 1000000.0 - 0.5) * 0.10;

    final secondaryHash = _stableHash(
      'pdf|${member.name}|${member.party}|${member.constituency}|'
      '${member.districtName}|${member.electionType}|${member.candidateStatus}|'
      '${member.electionCount}|${member.birthDate.toIso8601String()}',
    );
    final secondaryOffset =
        ((secondaryHash % 1000000) / 1000000.0 - 0.5) * 0.05;

    double featureBoost = 0.0;
    if (member.sourceUrl.isNotEmpty) featureBoost += 0.01;
    if (member.candidateStatus.contains('후보')) featureBoost += 0.01;
    if (member.candidateStatus.contains('예비')) featureBoost += 0.005;
    if (member.tags.isNotEmpty) {
      featureBoost += (member.tags.length.clamp(0, 6) as int) * 0.002;
    }
    if (member.electionCount > 0) {
      featureBoost += (member.electionCount.clamp(0, 4) as int) * 0.003;
    }
    featureBoost += (member.confidence.clamp(0.0, 1.0) - 0.5) * 0.02;
    if (member.career.length > 80) featureBoost += 0.006;
    if (member.education.length > 60) featureBoost += 0.004;
    if (member.polls.isNotEmpty) featureBoost += 0.003;
    if (member.pressReports.isNotEmpty) featureBoost += 0.003;
    if (member.socialContributions.isNotEmpty) featureBoost += 0.002;

    return (hashOffset + secondaryOffset + featureBoost).clamp(-0.08, 0.08).toDouble();
  }

  static int _stableHash(String input) {
    var hash = 0;
    for (final codeUnit in input.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
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
    if (member.career.contains('위원장') || member.career.contains('대표'))
      score += 0.2;

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
    if (member.education.contains('박사'))
      score += 0.2;
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

  static List<String> _generateStrengths(
      Member member, double achievement, double social) {
    final list = <String>[];
    if (achievement > 0.7)
      list.add(
          '전문성: ${member.education.contains('박사') ? '박사 학위' : '고도의 전문 경력'} 기반 정책 설계 능력');
    if (member.career.contains('위원장'))
      list.add('조직력: 당내 주요 직책 역임 및 지역 당원 결집력 우수');
    if (member.pressReports.any((r) => r.title.contains(member.name)))
      list.add('인지도: 지역 내 뉴스 노출 및 바이럴 지수 상위권');
    if (list.isEmpty) list.add('성실한 지역 활동 및 주민 소통 능력');
    return list;
  }

  static List<String> _generateWeaknesses(
      Member member, double publicImage, double party) {
    final list = <String>[];
    if (member.pressReports.length < 5) list.add('인지도: 온라인 및 언론 노출 빈도 보완 필요');
    if (party < 0.35) list.add('정당세: 지역 내 정당 지지율 정체 극복 과제');
    if (member.criminalRecord.isNotEmpty && member.criminalRecord != '없음')
      list.add('리스크: 도덕성 검증에 대한 선제적 대응 필요');
    if (list.isEmpty) list.add('청년층 및 신규 유입 유권자 대상 인지도 확장 과제');
    return list;
  }

  /// 우세 정당 판단 - 2018년 데이터를 기반으로 해당 지역의 우세 정당 결정
  static String? _determineDominantParty(Member member, double historical2018) {
    // 2018년 지지율이 45% 이상인 정당을 우세 정당으로 판단
    if (historical2018 >= 0.45) {
      return member.party;
    }

    // 현재 여론조사 데이터가 있다면 함께 고려
    final currentPollSupport = _calculatePollScore(member);
    if (currentPollSupport != null && currentPollSupport >= 0.45) {
      return member.party;
    }

    return null;
  }

  /// 격전지 지수 계산 - 과거 득표율 차이와 현재 오차범위 내 조사를 비교하여 '안정', '경합', '위험'으로 표시
  static String calculateBattlegroundIndex(Member member, double partyScore) {
    // 2018년 데이터와 현재 지지율을 종합하여 격전지 지수 판단
    final historical2018 = member.historical2018PartyRates[member.party] ?? 0.0;

    // 종합 점수 계산 (2018년 40%, 현재 60% 가중치)
    final combinedScore = (historical2018 * 0.4) + (partyScore * 0.6);

    if (combinedScore >= 0.6) {
      return '안정'; // 우세한 지역
    } else if (combinedScore >= 0.4) {
      return '경합'; // 접전 지역
    } else {
      return '위험'; // 열세 지역
    }
  }

  /// 무당층 보정 로직 - 설문조사에서 "지지 정당 없음"이라고 답한 층의 30~40%는 결국 투표일 직전 우세 정당으로 쏠리는 경향을 반영
  static double _applySwingVoterCorrection(
      double partyScore, String memberParty, String? dominantParty) {
    // 무당층 비율 15%, 그 중 35%가 우세 정당으로 쏠림
    const swingVoterRatio = 0.15;
    const swingVoterInclination = 0.35;

    // 해당 정당이 우세 정당인 경우에만 보정 적용
    if (dominantParty != null && dominantParty == memberParty) {
      return partyScore + (swingVoterRatio * swingVoterInclination);
    }
    return partyScore;
  }

  static List<String> _generateImprovements(
      Member member, List<String> weaknesses) {
    final list = <String>[];
    if (weaknesses.any((w) => w.contains('인지도')))
      list.add('네이버 뉴스 및 SNS 검색 노출 최적화(SEO) 전략 필요');
    if (member.career.contains('의원')) list.add('의정 활동 성과(조례 발의 등)의 시각적 홍보 강화');
    if (member.party == '더불어민주당')
      list.add('정권 지원론을 활용한 지역 예산 확보 능력 강조');
    else
      list.add('거대 양당 구도를 넘어서는 후보 개인의 전문성 브랜딩 필요');
    return list;
  }
}