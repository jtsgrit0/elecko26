import 'dart:isolate';

import 'package:elecko26_new/domain/entities/analysis_result.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/usecases/possibility_calculator.dart';
import 'package:elecko26_new/core/utils/utility_functions.dart';

// Isolate에서 실행될 최상위 함수
// 이 함수는 CalculateElectionPossibilityUseCase의 핵심 로직을 포함합니다.
Future<void> calculateElectionPossibilityInIsolate(
    Map<String, dynamic> message) async {
  final SendPort sendPort = message['sendPort'];
  final Member member = message['member'];
  final Map<String, Map<String, double>> regionalPartyAverages =
      message['regionalPartyAverages'];
  final Map<String, double> voterInterests = message['voterInterests'];
  final Map<String, String?> dominantParties = message['dominantParties'];

  final result = performMemberCalculation(
    member: member,
    regionalPartyAverages: regionalPartyAverages,
    voterInterests: voterInterests,
    dominantParties: dominantParties,
  );

  sendPort.send({
    'memberId': member.id,
    'analysisResult': result.toJson(),
  });
}

AnalysisResult performMemberCalculation({
  required Member member,
  required Map<String, Map<String, double>> regionalPartyAverages,
  required Map<String, double> voterInterests,
  required Map<String, String?> dominantParties,
}) {
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

  final region = getParentRegion(member.district) == ''
      ? '전국'
      : getParentRegion(member.district);

  // 미리 로드된 데이터를 사용
  final averages = regionalPartyAverages[region];
  voterInterest = voterInterests[region] ?? 0.5;
  final dominant = dominantParties[region];

  if (averages != null) {
    final partyRate = averages[member.party];
    if (partyRate != null && party2018Support == 0.0) {
      historicalBaseSupport = (partyRate / 100.0).clamp(0.0, 1.0);
    }

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
  }

  // A) 다중 요소 가중치 방식 계산 (공통 계산기 사용)
  final scores = PossibilityCalculator.calculateMultiFactorScores(
    member: member,
    historicalBaseSupport: historicalBaseSupport,
    voterInterest: voterInterest,
  );

  final dailyTrends = <DailyPossibility>[];
  final electionPossibility = scores['overall']!;

  // C) 상세 분석 데이터
  final analysis = _performDetailedAnalysis(member, scores, historicalContext);

  return AnalysisResult(
    memberId: member.id,
    analysisDate: DateTime.now(),
    electionPossibility: electionPossibility,
    previousPossibility: electionPossibility - 0.02,
    possibilityChange: 0.02,
    achievementScore: scores['achievement']!,
    activityScore: scores['activity']!,
    policyScore: scores['policy']!,
    publicImageScore: scores['publicImage']!,
    socialContributionScore: scores['socialContribution']!,
    pollScore: scores['poll']!,
    historicalScore: scores['historical']!,
    improvements: analysis['improvements']!,
    strengths: analysis['strengths']!,
    weaknesses: analysis['weaknesses']!,
    analysisReport: analysis['report']!,
    dailyTrends: dailyTrends,
    snsAnalysis: _calculateSnsAnalysis(member),
  );
}

// CalculateElectionPossibilityUseCase의 private 메서드들을 여기에 복사하거나
// 별도의 유틸리티 함수로 분리하여 Isolate에서 접근 가능하도록 합니다.

/// C) 상세 분석 데이터
Map<String, dynamic> _performDetailedAnalysis(
  Member member,
  Map<String, double> scores, [
  String? historicalContext,
]) {
  final strengths = <String>[];
  final weaknesses = <String>[];

  // 1. 강점 분석 (실제 데이터 기반)
  if (member.achievementsList.isNotEmpty) {
    // 가장 최근 성과를 강점으로 추출
    strengths.add('성과: ${member.achievementsList.first}');
  }
  if (scores['poll']! > 0.6) {
    strengths.add('지지율: 상대적으로 높은 여론조사 지지율 확보');
  }
  // 긍정 보도 키워드 추출
  final positivePress =
      member.pressReports.where((r) => r.sentiment == 'positive').toList();
  if (positivePress.isNotEmpty) {
    strengths.add('평판: 언론의 긍정적 평가 (${positivePress.first.title})');
  }

  // 2. 약점 분석 (데이터 공백 및 부정 실적 기반)
  if (member.policies.isEmpty) {
    weaknesses.add('정책: 아직 구체적인 정책 공약이 발표되지 않음');
  }
  final negativePress =
      member.pressReports.where((r) => r.sentiment == 'negative').toList();
  if (negativePress.isNotEmpty) {
    weaknesses.add('논란: 최근 부정적 이슈 감지 (${negativePress.first.title})');
  }
  if (scores['poll']! < 0.45) {
    weaknesses.add('지지세: 중도층 및 지지 기반 확장 필요');
  }

  // 3. 개선 필요 사항을 약점으로 추가 (데이터 보강)
  if (member.improvementPoints.isNotEmpty) {
    // 개선점 중 핵심적인 내용을 약점/도전 과제로 포함
    for (var point in member.improvementPoints.take(2)) {
      if (!weaknesses.contains(point)) {
        weaknesses.add(point);
      }
    }
  }

  // 4. 개선점 제시 (JSON의 improvementPoints 필드 적극 활용)
  final improvements = <String>[];
  if (member.improvementPoints.isNotEmpty) {
    improvements.addAll(member.improvementPoints);
  } else {
    // 데이터가 없을 경우에만 자동 생성
    if (scores['activity']! < 0.6) {
      improvements.add('SNS 및 오프라인 활동 빈도 확대 필요');
    }
    if (scores['policy']! < 0.6) {
      improvements.add('유권자 체감형 생활 밀착 정책 개발 필요');
    }
  }

  final historicalPct = scores['historical'] != null
      ? (scores['historical']! * 100).toStringAsFixed(1)
      : 'N/A';

  final report = '''
【${member.name} 의원 당선 가능성 분석 보고서】

1. 개요
분석일: ${DateTime.now().toString().split(' ')[0]}
현재 당선 가능성: ${(scores['overall']! * 100).toStringAsFixed(1)}%

2. 점수 분석
- 성과지수: ${(scores['achievement']! * 100).toStringAsFixed(1)}% (10~12%)
- 활동도: ${(scores['activity']! * 100).toStringAsFixed(1)}% (10~12%)
- 정책도: ${(scores['policy']! * 100).toStringAsFixed(1)}% (10~12%)
- 언론도: ${(scores['publicImage']! * 100).toStringAsFixed(1)}% (10~12%)
- 사회공헌: ${(scores['socialContribution']! * 100).toStringAsFixed(1)}% (10~12% - 신설)
- 여론조사 지지율: ${scores['poll']! < 0 ? '미반영 (지지율 미공개)' : '${(scores['poll']! * 100).toStringAsFixed(1)}% (30% - 가중치)'}
- 역대 선거 지역 기반: $historicalPct% (${scores['poll']! < 0 ? '40% - 미반영분 재분배' : '20% - 가중치'})
${scores['poll']! < 0 ? '\n※ 여론조사 미반영에 따라 지역 성향 및 실적 중심의 예측 모델로 보정되었습니다.\n' : ''}
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
