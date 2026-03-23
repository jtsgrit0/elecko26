import 'package:flutter_application_1/domain/entities/poll.dart';

/// 국회의원 엔티티
class Member {
  final String id;
  final String name;
  final String party;
  final String district;
  final String imageUrl;
  final String bio;
  final DateTime electionDate;
  final int term;
  
  // 이력 및 경력
  final List<String> achievementsList;
  final List<String> actions;
  final List<String> policies;
  final List<PressReport> pressReports;
  
  // 여론조사 데이터
  final List<Poll> polls;
  
  // 분석 관련
  final double electionPossibility;
  final DateTime lastAnalysisDate;
  final List<String> improvementPoints;

  Member({
    required this.id,
    required this.name,
    required this.party,
    required this.district,
    required this.imageUrl,
    required this.bio,
    required this.electionDate,
    required this.term,
    required this.achievementsList,
    required this.actions,
    required this.policies,
    required this.pressReports,
    required this.polls,
    required this.electionPossibility,
    required this.lastAnalysisDate,
    required this.improvementPoints,
  });

  Member copyWith({
    String? id,
    String? name,
    String? party,
    String? district,
    String? imageUrl,
    String? bio,
    DateTime? electionDate,
    int? term,
    List<String>? achievementsList,
    List<String>? actions,
    List<String>? policies,
    List<PressReport>? pressReports,
    List<Poll>? polls,
    double? electionPossibility,
    DateTime? lastAnalysisDate,
    List<String>? improvementPoints,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      party: party ?? this.party,
      district: district ?? this.district,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      electionDate: electionDate ?? this.electionDate,
      term: term ?? this.term,
      achievementsList: achievementsList ?? this.achievementsList,
      actions: actions ?? this.actions,
      policies: policies ?? this.policies,
      pressReports: pressReports ?? this.pressReports,
      polls: polls ?? this.polls,
      electionPossibility: electionPossibility ?? this.electionPossibility,
      lastAnalysisDate: lastAnalysisDate ?? this.lastAnalysisDate,
      improvementPoints: improvementPoints ?? this.improvementPoints,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class PressReport {
  final String id;
  final String title;
  final String source;
  final String url;
  final DateTime publishDate;
  final String summary;
  final String sentiment; // positive, neutral, negative

  PressReport({
    required this.id,
    required this.title,
    required this.source,
    required this.url,
    required this.publishDate,
    required this.summary,
    required this.sentiment,
  });
}
