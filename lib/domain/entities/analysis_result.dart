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
    required this.improvements,
    required this.strengths,
    required this.weaknesses,
    required this.analysisReport,
    required this.dailyTrends,
    this.snsAnalysis,
  });
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
}
