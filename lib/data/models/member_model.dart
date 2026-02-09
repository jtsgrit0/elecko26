import 'package:flutter_application_1/domain/entities/member.dart';
import 'package:flutter_application_1/domain/entities/poll.dart';

/// Member 모델 (API 응답용)
class MemberModel extends Member {
  MemberModel({
    required super.id,
    required super.name,
    required super.party,
    required super.district,
    required super.imageUrl,
    required super.bio,
    required super.electionDate,
    required super.term,
    required super.achievementsList,
    required super.actions,
    required super.policies,
    required super.pressReports,
    required super.polls,
    required super.electionPossibility,
    required super.lastAnalysisDate,
    required super.improvementPoints,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] as String,
      name: json['name'] as String,
      party: json['party'] as String,
      district: json['district'] as String,
      imageUrl: json['imageUrl'] as String,
      bio: json['bio'] as String,
      electionDate: DateTime.parse(json['electionDate'] as String),
      term: json['term'] as int,
      achievementsList: List<String>.from(json['achievementsList'] as List),
      actions: List<String>.from(json['actions'] as List),
      policies: List<String>.from(json['policies'] as List),
      pressReports: (json['pressReports'] as List)
          .map((e) => PressReportModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      polls: (json['polls'] as List? ?? [])
          .map((e) => PollModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      electionPossibility: (json['electionPossibility'] as num).toDouble(),
      lastAnalysisDate: DateTime.parse(json['lastAnalysisDate'] as String),
      improvementPoints: List<String>.from(json['improvementPoints'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'party': party,
      'district': district,
      'imageUrl': imageUrl,
      'bio': bio,
      'electionDate': electionDate.toIso8601String(),
      'term': term,
      'achievementsList': achievementsList,
      'actions': actions,
      'policies': policies,
      'pressReports': pressReports.map((e) => (e as PressReportModel).toJson()).toList(),
      'polls': polls
          .map((e) => PollModel(
                id: e.id,
                pollAgency: e.pollAgency,
                surveyDate: e.surveyDate,
                supportRate: e.supportRate,
                partyName: e.partyName,
                sampleSize: e.sampleSize,
                marginOfError: e.marginOfError,
                source: e.source,
                notes: e.notes,
              ).toJson())
          .toList(),
      'electionPossibility': electionPossibility,
      'lastAnalysisDate': lastAnalysisDate.toIso8601String(),
      'improvementPoints': improvementPoints,
    };
  }
}

class PollModel extends Poll {
  PollModel({
    required super.id,
    required super.pollAgency,
    required super.surveyDate,
    super.supportRate,
    required super.partyName,
    super.sampleSize,
    super.marginOfError,
    required super.source,
    super.notes,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    final supportRateValue = json['supportRate'];
    final sampleSizeValue = json['sampleSize'];
    final marginValue = json['marginOfError'];

    return PollModel(
      id: json['id'] as String,
      pollAgency: json['pollAgency'] as String,
      surveyDate: DateTime.parse(json['surveyDate'] as String),
      supportRate: supportRateValue == null ? null : (supportRateValue as num).toDouble(),
      partyName: json['partyName'] as String,
      sampleSize: sampleSizeValue == null ? null : (sampleSizeValue as num).toInt(),
      marginOfError: marginValue == null ? null : (marginValue as num).toDouble(),
      source: json['source'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pollAgency': pollAgency,
      'surveyDate': surveyDate.toIso8601String(),
      'supportRate': supportRate,
      'partyName': partyName,
      'sampleSize': sampleSize,
      'marginOfError': marginOfError,
      'source': source,
      'notes': notes,
    };
  }
}

class PressReportModel extends PressReport {
  PressReportModel({
    required super.id,
    required super.title,
    required super.source,
    required super.url,
    required super.publishDate,
    required super.summary,
    required super.sentiment,
  });

  factory PressReportModel.fromJson(Map<String, dynamic> json) {
    return PressReportModel(
      id: json['id'] as String,
      title: json['title'] as String,
      source: json['source'] as String,
      url: json['url'] as String,
      publishDate: DateTime.parse(json['publishDate'] as String),
      summary: json['summary'] as String,
      sentiment: json['sentiment'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'source': source,
      'url': url,
      'publishDate': publishDate.toIso8601String(),
      'summary': summary,
      'sentiment': sentiment,
    };
  }
}
