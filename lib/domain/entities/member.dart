import 'package:equatable/equatable.dart';
import 'package:elecko26_new/domain/entities/poll.dart';

class Member extends Equatable {
  final String id;
  final String name;
  final String party;
  final String district;
  final String description;
  final String imageUrl;
  final List<Poll> polls;
  final double electionPossibility;
  final bool isFavorite;
  final List<PressReport> pressReports;
  final Map<String, double> historical2018PartyRates;
  final DateTime? lastAnalysisDate;
  final List<String> achievementsList;
  final List<String> policies;
  final List<String> improvementPoints;
  final List<SocialContribution> socialContributions;

  const Member({
    required this.id,
    required this.name,
    required this.party,
    required this.district,
    this.description = '',
    this.imageUrl = '',
    this.polls = const [],
    this.electionPossibility = 0.0,
    this.isFavorite = false,
    this.pressReports = const [],
    this.historical2018PartyRates = const {},
    this.lastAnalysisDate,
    this.achievementsList = const [],
    this.policies = const [],
    this.improvementPoints = const [],
    this.socialContributions = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        party,
        district,
        description,
        imageUrl,
        polls,
        electionPossibility,
        isFavorite,
        pressReports,
        historical2018PartyRates,
        lastAnalysisDate,
        achievementsList,
        policies,
        improvementPoints,
        socialContributions,
      ];

  Member copyWith({
    String? id,
    String? name,
    String? party,
    String? district,
    String? description,
    String? imageUrl,
    List<Poll>? polls,
    double? electionPossibility,
    bool? isFavorite,
    List<PressReport>? pressReports,
    Map<String, double>? historical2018PartyRates,
    DateTime? lastAnalysisDate,
    List<String>? achievementsList,
    List<String>? policies,
    List<String>? improvementPoints,
    List<SocialContribution>? socialContributions,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      party: party ?? this.party,
      district: district ?? this.district,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      polls: polls ?? this.polls,
      electionPossibility: electionPossibility ?? this.electionPossibility,
      isFavorite: isFavorite ?? this.isFavorite,
      pressReports: pressReports ?? this.pressReports,
      historical2018PartyRates:
          historical2018PartyRates ?? this.historical2018PartyRates,
      lastAnalysisDate: lastAnalysisDate ?? this.lastAnalysisDate,
      achievementsList: achievementsList ?? this.achievementsList,
      policies: policies ?? this.policies,
      improvementPoints: improvementPoints ?? this.improvementPoints,
      socialContributions: socialContributions ?? this.socialContributions,
    );
  }
}

class PressReport extends Equatable {
  final String id;
  final String title;
  final String source;
  final String url;
  final DateTime publishDate;
  final String summary;
  final String sentiment; // positive, neutral, negative

  const PressReport({
    required this.id,
    required this.title,
    required this.source,
    required this.url,
    required this.publishDate,
    required this.summary,
    required this.sentiment,
  });

  @override
  List<Object?> get props =>
      [id, title, source, url, publishDate, summary, sentiment];

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

class SocialContribution extends Equatable {
  final String id;
  final String type;
  final String description;
  final DateTime date;
  final String source;

  const SocialContribution({
    required this.id,
    required this.type,
    required this.description,
    required this.date,
    required this.source,
  });

  @override
  List<Object?> get props => [id, type, description, date, source];
}
