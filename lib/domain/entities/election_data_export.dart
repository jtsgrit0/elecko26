/// 당선 가능성 영향 데이터 JSON 내보내기 엔티티
class ElectionDataExport {
  final DateTime exportedAt;
  final String version;
  final List<MemberElectionData> members;
  final ElectionMetadata metadata;

  ElectionDataExport({
    required this.exportedAt,
    required this.version,
    required this.members,
    required this.metadata,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'exportedAt': exportedAt.toIso8601String(),
      'version': version,
      'timestamp': exportedAt.millisecondsSinceEpoch,
      'metadata': metadata.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'totalMembers': members.length,
      'lastUpdated': exportedAt.toIso8601String(),
    };
  }
}

/// 각 의원의 선거 데이터
class MemberElectionData {
  final String id;
  final String name;
  final String party;
  final String district;
  final double electionPossibility;
  final double possibilityChange;
  final DateTime analyzedAt;
  
  // 점수 상세 데이터
  final double achievementScore;
  final double activityScore;
  final double policyScore;
  final double publicImageScore;
  final double pollScore;
  
  // 여론조사 데이터
  final List<PollDataExport> polls;
  
  // SNS 분석 데이터
  final SnsAnalysisExport? snsAnalysis;
  
  // 언론 보도 데이터
  final int pressReportsCount;
  final double sentimentAverage;
  
  // 추이 데이터
  final List<DailyTrendExport> recentTrends;

  MemberElectionData({
    required this.id,
    required this.name,
    required this.party,
    required this.district,
    required this.electionPossibility,
    required this.possibilityChange,
    required this.analyzedAt,
    required this.achievementScore,
    required this.activityScore,
    required this.policyScore,
    required this.publicImageScore,
    required this.pollScore,
    required this.polls,
    this.snsAnalysis,
    required this.pressReportsCount,
    required this.sentimentAverage,
    required this.recentTrends,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'party': party,
      'district': district,
      'timestamp': analyzedAt.millisecondsSinceEpoch,
      'analyzedAt': analyzedAt.toIso8601String(),
      'electionPossibility': (electionPossibility * 100).toStringAsFixed(2),
      'electionPossibilityPercent': (electionPossibility * 100).toStringAsFixed(1),
      'possibilityChange': (possibilityChange * 100).toStringAsFixed(2),
      'possibilityChangePercent': (possibilityChange * 100).toStringAsFixed(1),
      'scores': {
        'achievement': (achievementScore * 100).toStringAsFixed(1),
        'activity': (activityScore * 100).toStringAsFixed(1),
        'policy': (policyScore * 100).toStringAsFixed(1),
        'publicImage': (publicImageScore * 100).toStringAsFixed(1),
        'poll': (pollScore * 100).toStringAsFixed(1),
      },
      'polls': {
        'count': polls.length,
        'data': polls.map((p) => p.toJson()).toList(),
      },
      'snsAnalysis': snsAnalysis?.toJson(),
      'pressReports': {
        'count': pressReportsCount,
        'sentimentAverage': (sentimentAverage * 100).toStringAsFixed(1),
      },
      'trends': {
        'recent': recentTrends.map((t) => t.toJson()).toList(),
        'count': recentTrends.length,
      },
    };
  }
}

/// 여론조사 데이터 (내보내기용)
class PollDataExport {
  final String pollAgency;
  final DateTime surveyDate;
  final double? supportRate;
  final int? sampleSize;
  final double? marginOfError;

  PollDataExport({
    required this.pollAgency,
    required this.surveyDate,
    this.supportRate,
    this.sampleSize,
    this.marginOfError,
  });

  Map<String, dynamic> toJson() {
    return {
      'pollAgency': pollAgency,
      'surveyDate': surveyDate.toIso8601String(),
      'surveyTimestamp': surveyDate.millisecondsSinceEpoch,
      'supportRate': supportRate != null ? (supportRate! * 100).toStringAsFixed(1) : null,
      'sampleSize': sampleSize,
      'marginOfError': marginOfError?.toStringAsFixed(1),
    };
  }
}

/// SNS 분석 데이터 (내보내기용)
class SnsAnalysisExport {
  final int totalMentions;
  final int positiveMentions;
  final int neutralMentions;
  final int negativeMentions;
  final double sentimentScore;
  final List<String> topMentions;
  final String engagementTrend;

  SnsAnalysisExport({
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
      'sentiment': {
        'positive': positiveMentions,
        'neutral': neutralMentions,
        'negative': negativeMentions,
      },
      'sentimentScore': (sentimentScore * 100).toStringAsFixed(1),
      'topMentions': topMentions,
      'engagementTrend': engagementTrend,
      'sentimentRatio': {
        'positive': totalMentions > 0 ? ((positiveMentions / totalMentions) * 100).toStringAsFixed(1) : "0.0",
        'neutral': totalMentions > 0 ? ((neutralMentions / totalMentions) * 100).toStringAsFixed(1) : "0.0",
        'negative': totalMentions > 0 ? ((negativeMentions / totalMentions) * 100).toStringAsFixed(1) : "0.0",
      },
    };
  }
}

/// 일일 추이 데이터 (내보내기용)
class DailyTrendExport {
  final DateTime date;
  final double possibility;

  DailyTrendExport({
    required this.date,
    required this.possibility,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'timestamp': date.millisecondsSinceEpoch,
      'possibility': (possibility * 100).toStringAsFixed(1),
    };
  }
}

/// 선거 데이터 메타 정보
class ElectionMetadata {
  final int totalMembers;
  final int membersAnalyzed;
  final double averageElectionPossibility;
  final int totalPolls;
  final int dataSourcesCount;
  final Map<String, int> membersByParty;

  ElectionMetadata({
    required this.totalMembers,
    required this.membersAnalyzed,
    required this.averageElectionPossibility,
    required this.totalPolls,
    required this.dataSourcesCount,
    required this.membersByParty,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalMembers': totalMembers,
      'membersAnalyzed': membersAnalyzed,
      'averageElectionPossibility': (averageElectionPossibility * 100).toStringAsFixed(1),
      'totalPolls': totalPolls,
      'dataSourcesCount': dataSourcesCount,
      'membersByParty': membersByParty,
      'analysisVersion': 'v2.0',
    };
  }
}
