/// SNS 분석 결과
class SnsAnalysis {
  final int totalMentions;
  final int positiveMentions;
  final int neutralMentions;
  final int negativeMentions;
  final double sentimentScore;
  final List<String> topMentions;
  final String engagementTrend; // '상승' / '하락' / '보합'

  SnsAnalysis({
    required this.totalMentions,
    required this.positiveMentions,
    required this.neutralMentions,
    required this.negativeMentions,
    required this.sentimentScore,
    required this.topMentions,
    required this.engagementTrend,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalMentions': totalMentions,
      'positiveMentions': positiveMentions,
      'neutralMentions': neutralMentions,
      'negativeMentions': negativeMentions,
      'sentimentScore': sentimentScore,
      'topMentions': topMentions,
      'engagementTrend': engagementTrend,
    };
  }

  factory SnsAnalysis.fromJson(Map<String, dynamic> json) {
    return SnsAnalysis(
      totalMentions: json['totalMentions'],
      positiveMentions: json['positiveMentions'],
      neutralMentions: json['neutralMentions'],
      negativeMentions: json['negativeMentions'],
      sentimentScore: json['sentimentScore'],
      topMentions: List<String>.from(json['topMentions']),
      engagementTrend: json['engagementTrend'],
    );
  }
}

/// AI 분석 결과 엔티티
class AnalysisResult {
  final String memberId;
  final DateTime analysisDate;

  // 당선 가능성 (0~100)
  final double electionPossibility;
  final double previousPossibility;
  final double possibilityChange;

  // 분석 점수
  final double achievementScore;
  final double activityScore;
  final double policyScore;
  final double publicImageScore;
  final double socialContributionScore;
  final double pollScore;
  final double historicalScore;

  // AI 분석 결과
  final List<String> improvements;
  final List<String> strengths;
  final List<String> weaknesses;
  final String analysisReport;

  // 추세 데이터
  final List<DailyPossibility> dailyTrends;

  // SNS 분석 데이터 (선택사항)
  final SnsAnalysis? snsAnalysis;

  AnalysisResult({
    required this.memberId,
    required this.analysisDate,
    required this.electionPossibility,
    required this.previousPossibility,
    required this.possibilityChange,
    required this.achievementScore,
    required this.activityScore,
    required this.policyScore,
    required this.publicImageScore,
    required this.socialContributionScore,
    required this.pollScore,
    required this.historicalScore,
    required this.improvements,
    required this.strengths,
    required this.weaknesses,
    required this.analysisReport,
    required this.dailyTrends,
    this.snsAnalysis,
  });

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'analysisDate': analysisDate.toIso8601String(),
      'electionPossibility': electionPossibility,
      'previousPossibility': previousPossibility,
      'possibilityChange': possibilityChange,
      'achievementScore': achievementScore,
      'activityScore': activityScore,
      'policyScore': policyScore,
      'publicImageScore': publicImageScore,
      'socialContributionScore': socialContributionScore,
      'pollScore': pollScore,
      'historicalScore': historicalScore,
      'improvements': improvements,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'analysisReport': analysisReport,
      'dailyTrends': dailyTrends.map((e) => e.toJson()).toList(),
      'snsAnalysis': snsAnalysis?.toJson(),
    };
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      memberId: json['memberId'],
      analysisDate: DateTime.parse(json['analysisDate']),
      electionPossibility: json['electionPossibility'],
      previousPossibility: json['previousPossibility'],
      possibilityChange: json['possibilityChange'],
      achievementScore: json['achievementScore'],
      activityScore: json['activityScore'],
      policyScore: json['policyScore'],
      publicImageScore: json['publicImageScore'],
      socialContributionScore: json['socialContributionScore'],
      pollScore: json['pollScore'],
      historicalScore: json['historicalScore'],
      improvements: List<String>.from(json['improvements']),
      strengths: List<String>.from(json['strengths']),
      weaknesses: List<String>.from(json['weaknesses']),
      analysisReport: json['analysisReport'],
      dailyTrends: (json['dailyTrends'] as List)
          .map((e) => DailyPossibility.fromJson(e))
          .toList(),
      snsAnalysis: json['snsAnalysis'] != null
          ? SnsAnalysis.fromJson(json['snsAnalysis'])
          : null,
    );
  }
}

class DailyPossibility {
  final DateTime date;
  final double possibility;
  final String reason;

  DailyPossibility({
    required this.date,
    required this.possibility,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'possibility': possibility,
      'reason': reason,
    };
  }

  factory DailyPossibility.fromJson(Map<String, dynamic> json) {
    return DailyPossibility(
      date: DateTime.parse(json['date']),
      possibility: json['possibility'],
      reason: json['reason'],
    );
  }
}
