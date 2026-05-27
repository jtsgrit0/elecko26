import 'package:equatable/equatable.dart';
import 'package:elecko26_new/domain/entities/poll.dart';
import 'package:elecko26_new/domain/entities/press_report.dart';
import 'package:elecko26_new/domain/entities/social_contribution.dart';

class Member extends Equatable {
  final String id;
  final String name;
  final String party;
  final String constituency;
  final String districtName;
  final String region;
  final String nameHanja;
  final int electionCount;
  final DateTime termStartDate;
  final DateTime termEndDate;
  final DateTime birthDate;
  final String gender;
  final String address;
  final String occupation;
  final String education;
  final String career;
  final String criminalRecord;
  final String description;
  final String imageUrl;
  final String electionType;
  final String sourceUrl;
  final String candidateStatus;
  final double confidence;
  final List<String> tags;
  final String? facebookUrl;
  final String? twitterUrl;
  final String? youtubeUrl;
  final String? blogUrl;
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

  Member({
    required this.id,
    required this.name,
    this.party = '무소속',
    required this.constituency,
    this.districtName = '',
    this.region = '전국',
    this.nameHanja = '',
    this.electionCount = 0,
    DateTime? termStartDate,
    DateTime? termEndDate,
    DateTime? birthDate,
    this.gender = '',
    this.address = '',
    this.occupation = '',
    this.education = '',
    this.career = '',
    this.criminalRecord = '',
    this.description = '',
    this.imageUrl = '',
    this.electionType = '',
    this.sourceUrl = '',
    this.candidateStatus = '',
    this.confidence = 0.0,
    this.tags = const [],
    this.facebookUrl,
    this.twitterUrl,
    this.youtubeUrl,
    this.blogUrl,
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
  })  : termStartDate = termStartDate ?? DateTime(1900, 1, 1),
        termEndDate = termEndDate ?? DateTime(1900, 1, 1),
        birthDate = birthDate ?? DateTime(1900, 1, 1);

  String get district => constituency;

  @override
  List<Object?> get props => [
        id,
        name,
        party,
        constituency,
        districtName,
        region,
        nameHanja,
        electionCount,
        termStartDate,
        termEndDate,
        birthDate,
        gender,
        address,
        occupation,
        education,
        career,
        criminalRecord,
        description,
        imageUrl,
        electionType,
        sourceUrl,
        candidateStatus,
        confidence,
        tags,
        facebookUrl,
        twitterUrl,
        youtubeUrl,
        blogUrl,
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
    String? constituency,
    String? district,
    String? districtName,
    String? region,
    String? nameHanja,
    int? electionCount,
    DateTime? termStartDate,
    DateTime? termEndDate,
    DateTime? birthDate,
    String? gender,
    String? address,
    String? occupation,
    String? education,
    String? career,
    String? criminalRecord,
    String? description,
    String? imageUrl,
    String? electionType,
    String? sourceUrl,
    String? candidateStatus,
    double? confidence,
    List<String>? tags,
    String? facebookUrl,
    String? twitterUrl,
    String? youtubeUrl,
    String? blogUrl,
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
      constituency: constituency ?? district ?? this.constituency,
      districtName: districtName ?? this.districtName,
      region: region ?? this.region,
      nameHanja: nameHanja ?? this.nameHanja,
      electionCount: electionCount ?? this.electionCount,
      termStartDate: termStartDate ?? this.termStartDate,
      termEndDate: termEndDate ?? this.termEndDate,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      career: career ?? this.career,
      criminalRecord: criminalRecord ?? this.criminalRecord,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      electionType: electionType ?? this.electionType,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      candidateStatus: candidateStatus ?? this.candidateStatus,
      confidence: confidence ?? this.confidence,
      tags: tags ?? this.tags,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      blogUrl: blogUrl ?? this.blogUrl,
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

  static DateTime _parseDate(dynamic value, {DateTime? fallback}) {
    if (value == null) {
      return fallback ?? DateTime(1900, 1, 1);
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? (fallback ?? DateTime(1900, 1, 1));
    }
    return fallback ?? DateTime(1900, 1, 1);
  }

  static String _parseString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is Map && value.containsKey('name')) {
      return value['name']?.toString() ?? fallback;
    }
    return value.toString();
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return <String>[];
    return value
        .map((e) => e?.toString() ?? '')
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }

  static Map<String, double> _parseHistoricalRates(dynamic value) {
    if (value is! Map) return <String, double>{};
    return value.map(
      (key, val) => MapEntry(key.toString(), _parseDouble(val)),
    );
  }

  static List<Poll> _parsePolls(dynamic value) {
    final rawList = value is List
        ? value
        : value is Map && value['data'] is List
            ? value['data'] as List
            : const <dynamic>[];

    return rawList
        .whereType<Map>()
        .map((e) => Poll.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<PressReport> _parsePressReports(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => PressReport.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (value is Map && value['data'] is List) {
      return (value['data'] as List)
          .whereType<Map>()
          .map((e) => PressReport.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return <PressReport>[];
  }

  static List<SocialContribution> _parseSocialContributions(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) =>
              SocialContribution.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (value is Map && value['data'] is List) {
      return (value['data'] as List)
          .whereType<Map>()
          .map((e) =>
              SocialContribution.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return <SocialContribution>[];
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    final constituency = _parseString(
      json['constituency'] ?? json['district'] ?? json['districtName'],
      fallback: '전국',
    );
    final region = _parseString(json['region'], fallback: '');
    return Member(
      id: _parseString(json['id'], fallback: ''),
      name: _parseString(json['name'], fallback: '알 수 없음'),
      party: _parseString(
        json['party'] is Map ? (json['party'] as Map)['name'] : json['party'],
        fallback: '무소속',
      ),
      constituency: constituency,
      districtName: _parseString(
        json['districtName'] ?? json['district'] ?? constituency,
      ),
      region: region.isNotEmpty ? region : constituency,
      nameHanja: _parseString(json['nameHanja']),
      electionCount: _parseInt(json['electionCount'] ?? json['term']),
      termStartDate: _parseDate(json['termStartDate'] ?? json['termStart']),
      termEndDate: _parseDate(json['termEndDate'] ?? json['termEnd']),
      birthDate: _parseDate(json['birthDate'] ?? json['birthdate']),
      gender: _parseString(json['gender']),
      address: _parseString(json['address']),
      occupation: _parseString(json['occupation'] ?? json['job']),
      education: _parseString(json['education']),
      career: _parseString(json['career']),
      criminalRecord: _parseString(json['criminalRecord']),
      description: _parseString(json['description']),
      imageUrl: _parseString(json['imageUrl']),
      electionType: _parseString(json['electionType']),
      sourceUrl: _parseString(json['sourceUrl']),
      candidateStatus: _parseString(json['candidateStatus'] ?? json['status']),
      confidence: _parseDouble(json['confidence']),
      tags: _parseStringList(json['tags']),
      facebookUrl: json['facebookUrl']?.toString(),
      twitterUrl: json['twitterUrl']?.toString(),
      youtubeUrl: json['youtubeUrl']?.toString(),
      blogUrl: json['blogUrl']?.toString(),
      polls: _parsePolls(json['polls']),
      electionPossibility: _parseDouble(json['electionPossibility']),
      isFavorite: json['isFavorite'] as bool? ?? false,
      pressReports: _parsePressReports(json['pressReports']),
      historical2018PartyRates:
          _parseHistoricalRates(json['historical2018PartyRates']),
      lastAnalysisDate: json['lastAnalysisDate'] == null
          ? null
          : _parseDate(json['lastAnalysisDate']),
      achievementsList: _parseStringList(json['achievementsList']),
      policies: _parseStringList(json['policies']),
      improvementPoints: _parseStringList(json['improvementPoints']),
      socialContributions:
          _parseSocialContributions(json['socialContributions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'party': party,
      'constituency': constituency,
      'district': district,
      'districtName': districtName,
      'region': region,
      'nameHanja': nameHanja,
      'electionCount': electionCount,
      'termStartDate': termStartDate.toIso8601String(),
      'termEndDate': termEndDate.toIso8601String(),
      'birthDate': birthDate.toIso8601String(),
      'birthdate': birthDate.toIso8601String(),
      'gender': gender,
      'address': address,
      'occupation': occupation,
      'education': education,
      'career': career,
      'criminalRecord': criminalRecord,
      'description': description,
      'imageUrl': imageUrl,
      'electionType': electionType,
      'sourceUrl': sourceUrl,
      'candidateStatus': candidateStatus,
      'confidence': confidence,
      'tags': tags,
      'facebookUrl': facebookUrl,
      'twitterUrl': twitterUrl,
      'youtubeUrl': youtubeUrl,
      'blogUrl': blogUrl,
      'polls': polls.map((e) => e.toJson()).toList(),
      'electionPossibility': electionPossibility,
      'isFavorite': isFavorite,
      'pressReports': pressReports.map((e) => e.toJson()).toList(),
      'historical2018PartyRates': historical2018PartyRates,
      'lastAnalysisDate': lastAnalysisDate?.toIso8601String(),
      'achievementsList': achievementsList,
      'policies': policies,
      'improvementPoints': improvementPoints,
      'socialContributions': socialContributions.map((e) => e.toJson()).toList(),
    };
  }
}
