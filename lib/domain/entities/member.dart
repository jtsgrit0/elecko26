import 'package:equatable/equatable.dart';
import 'package:elecko26_new/domain/entities/poll.dart';

class Member extends Equatable {
  final String id;
  final String name;
  final String party;
  final String district;
  final String districtName;
  final String region;
  final String description;
  final String imageUrl;
  final String nameHanja;
  final String gender;
  final String birthdate;
  final String address;
  final String occupation;
  final String education;
  final String career;
  final String criminalRecord;
  final String electionType;
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
    this.districtName = '',
    required this.region,
    this.description = '',
    this.imageUrl = '',
    this.nameHanja = '',
    this.gender = '',
    this.birthdate = '',
    this.address = '',
    this.occupation = '',
    this.education = '',
    this.career = '',
    this.criminalRecord = '',
    this.electionType = '',
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
        districtName,
        region,
        description,
        imageUrl,
        nameHanja,
        gender,
        birthdate,
        address,
        occupation,
        education,
        career,
        criminalRecord,
        electionType,
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
    String? districtName,
    String? region,
    String? description,
    String? imageUrl,
    String? nameHanja,
    String? gender,
    String? birthdate,
    String? address,
    String? occupation,
    String? education,
    String? career,
    String? criminalRecord,
    String? electionType,
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
      districtName: districtName ?? this.districtName,
      region: region ?? this.region,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      nameHanja: nameHanja ?? this.nameHanja,
      gender: gender ?? this.gender,
      birthdate: birthdate ?? this.birthdate,
      address: address ?? this.address,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      career: career ?? this.career,
      criminalRecord: criminalRecord ?? this.criminalRecord,
      electionType: electionType ?? this.electionType,
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
