import 'package:flutter_application_1/domain/entities/analysis_result.dart';

/// AnalysisResult 모델 (API 응답용)
class AnalysisResultModel extends AnalysisResult {
  AnalysisResultModel({
    required super.memberId,
    required super.analysisDate,
    required super.electionPossibility,
    required super.previousPossibility,
    required super.possibilityChange,
    required super.achievementScore,
    required super.activityScore,
    required super.policyScore,
    required super.publicImageScore,
    required super.improvements,
    required super.strengths,
    required super.weaknesses,
    required super.analysisReport,
    required super.dailyTrends,
  });

  factory AnalysisResultModel.fromJson(Map<String, dynamic> json) {
    return AnalysisResultModel(
      memberId: json['memberId'] as String,
      analysisDate: DateTime.parse(json['analysisDate'] as String),
      electionPossibility: (json['electionPossibility'] as num).toDouble(),
      previousPossibility: (json['previousPossibility'] as num).toDouble(),
      possibilityChange: (json['possibilityChange'] as num).toDouble(),
      achievementScore: (json['achievementScore'] as num).toDouble(),
      activityScore: (json['activityScore'] as num).toDouble(),
      policyScore: (json['policyScore'] as num).toDouble(),
      publicImageScore: (json['publicImageScore'] as num).toDouble(),
      improvements: List<String>.from(json['improvements'] as List),
      strengths: List<String>.from(json['strengths'] as List),
      weaknesses: List<String>.from(json['weaknesses'] as List),
      analysisReport: json['analysisReport'] as String,
      dailyTrends: (json['dailyTrends'] as List)
          .map((e) => DailyPossibilityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

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
      'improvements': improvements,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'analysisReport': analysisReport,
      'dailyTrends': dailyTrends.map((e) => (e as DailyPossibilityModel).toJson()).toList(),
    };
  }
}

class DailyPossibilityModel extends DailyPossibility {
  DailyPossibilityModel({
    required super.date,
    required super.possibility,
    required super.reason,
  });

  factory DailyPossibilityModel.fromJson(Map<String, dynamic> json) {
    return DailyPossibilityModel(
      date: DateTime.parse(json['date'] as String),
      possibility: (json['possibility'] as num).toDouble(),
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'possibility': possibility,
      'reason': reason,
    };
  }
}
