import 'package:elecko26_new/core/utils/utility_functions.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/poll.dart';
import 'package:elecko26_new/domain/entities/press_report.dart';
import 'package:elecko26_new/domain/entities/social_contribution.dart';

/// Member 모델 (JSON 응답용)
class MemberModel extends Member {
  MemberModel({
    required String id,
    required String name,
    String party = '무소속',
    required String constituency,
    String districtName = '',
    String region = '전국',
    String nameHanja = '',
    int electionCount = 0,
    DateTime? termStartDate,
    DateTime? termEndDate,
    DateTime? birthDate,
    String gender = '',
    String address = '',
    String occupation = '',
    String education = '',
    String career = '',
    String criminalRecord = '',
    String description = '',
    String imageUrl = '',
    String electionType = '',
    String sourceUrl = '',
    String candidateStatus = '',
    double confidence = 0.0,
    List<String> tags = const [],
    String? facebookUrl,
    String? twitterUrl,
    String? youtubeUrl,
    String? blogUrl,
    List<Poll> polls = const [],
    double electionPossibility = 0.0,
    bool isFavorite = false,
    List<PressReport> pressReports = const [],
    Map<String, double> historical2018PartyRates = const {},
    DateTime? lastAnalysisDate,
    List<String> achievementsList = const [],
    List<String> policies = const [],
    List<String> improvementPoints = const [],
    List<SocialContribution> socialContributions = const [],
    String sido = '',
    String sigungu = '',
  }) : super(
          id: id,
          name: name,
          party: party,
          constituency: constituency,
          districtName: districtName,
          region: region,
          sido: sido,
          sigungu: sigungu,
          nameHanja: nameHanja,
          electionCount: electionCount,
          termStartDate: termStartDate,
          termEndDate: termEndDate,
          birthDate: birthDate,
          gender: gender,
          address: address,
          occupation: occupation,
          education: education,
          career: career,
          criminalRecord: criminalRecord,
          description: description,
          imageUrl: imageUrl,
          electionType: electionType,
          sourceUrl: sourceUrl,
          candidateStatus: candidateStatus,
          confidence: confidence,
          tags: tags,
          facebookUrl: facebookUrl,
          twitterUrl: twitterUrl,
          youtubeUrl: youtubeUrl,
          blogUrl: blogUrl,
          polls: polls,
          electionPossibility: electionPossibility,
          isFavorite: isFavorite,
          pressReports: pressReports,
          historical2018PartyRates: historical2018PartyRates,
          lastAnalysisDate: lastAnalysisDate,
          achievementsList: achievementsList,
          policies: policies,
          improvementPoints: improvementPoints,
          socialContributions: socialContributions,
        );

  static DateTime _parseDate(dynamic value, {DateTime? fallback}) {
    if (value == null) return fallback ?? DateTime(1900, 1, 1);
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
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

  static double _normalizePossibility(dynamic value) {
    final parsed = _parseDouble(value);
    if (parsed > 1.0 && parsed <= 100.0) {
      return parsed / 100.0;
    }
    return parsed.clamp(0.0, 1.0);
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
    return value.map((key, val) => MapEntry(key.toString(), _parseDouble(val)));
  }

  static List<Poll> _parsePolls(dynamic value) {
    final rawList = value is List
        ? value
        : value is Map && value['data'] is List
            ? value['data'] as List
            : const <dynamic>[];
    return rawList
        .whereType<Map>()
        .map((e) => PollModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<PressReport> _parsePressReports(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => PressReportModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (value is Map && value['data'] is List) {
      return (value['data'] as List)
          .whereType<Map>()
          .map((e) => PressReportModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return <PressReport>[];
  }

  static List<SocialContribution> _parseSocialContributions(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) =>
              SocialContributionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (value is Map && value['data'] is List) {
      return (value['data'] as List)
          .whereType<Map>()
          .map((e) =>
              SocialContributionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return <SocialContribution>[];
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    final constituency = _parseString(
      json['constituency'] ?? json['district'] ?? json['districtName'],
      fallback: '전국',
    );
    final regionRaw = _parseString(json['region']);
    final region =
        regionRaw.isNotEmpty ? regionRaw : getParentRegion(constituency);
    final sido =
        _parseString(json['sido'], fallback: getParentRegion(constituency));
    final sigungu = _parseString(json['sigungu'],
        fallback: getSigunguFromConstituency(constituency));

    return MemberModel(
      id: _parseString(json['id'], fallback: ''),
      name: _parseString(json['name'], fallback: '알 수 없음'),
      party: _parseString(
        json['party'] is Map ? (json['party'] as Map)['name'] : json['party'],
        fallback: '무소속',
      ),
      constituency: constituency,
      districtName: _parseString(
          json['districtName'] ?? json['district'] ?? constituency),
      region: region.isNotEmpty ? region : '전국',
      sido: sido,
      sigungu: sigungu,
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
      electionPossibility: _normalizePossibility(json['electionPossibility']),
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

  @override
  MemberModel copyWith({
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
    String? sido,
    String? sigungu,
  }) {
    return MemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      party: party ?? this.party,
      constituency: constituency ?? district ?? this.constituency,
      districtName: districtName ?? this.districtName,
      region: region ?? this.region,
      sido: sido ?? this.sido,
      sigungu: sigungu ?? this.sigungu,
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

  String get profileImageUrl {
    final url = imageUrl;
    if (url.isEmpty || !url.startsWith('http')) {
      return 'assets/images/avatar.png';
    }
    return 'https://wsrv.nl/?url=$url&w=120&h=120&fit=cover';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'party': party,
      'constituency': constituency,
      'districtName': districtName,
      'region': region,
      'sido': sido,
      'sigungu': sigungu,
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
      'socialContributions':
          socialContributions.map((e) => e.toJson()).toList(),
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

    double? parsedSupport;
    if (supportRateValue != null) {
      final raw = MemberModel._parseDouble(supportRateValue);
      parsedSupport = raw > 1.0 && raw <= 100.0 ? raw / 100.0 : raw;
    }

    return PollModel(
      id: MemberModel._parseString(json['id']),
      pollAgency: MemberModel._parseString(json['pollAgency']),
      surveyDate: MemberModel._parseDate(json['surveyDate']),
      supportRate: parsedSupport,
      partyName: MemberModel._parseString(json['partyName']),
      sampleSize: sampleSizeValue == null
          ? null
          : MemberModel._parseInt(sampleSizeValue),
      marginOfError:
          marginValue == null ? null : MemberModel._parseDouble(marginValue),
      source: MemberModel._parseString(json['source']),
      notes: json['notes']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pollAgency': pollAgency,
      'surveyDate': surveyDate.toIso8601String(),
      'surveyTimestamp': surveyDate.millisecondsSinceEpoch,
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
      id: MemberModel._parseString(json['id']),
      title: MemberModel._parseString(json['title']),
      source: MemberModel._parseString(json['source']),
      url: MemberModel._parseString(json['url'] ?? json['link']),
      publishDate: MemberModel._parseDate(
        json['publishDate'] ?? json['publishTimestamp'],
      ),
      summary: MemberModel._parseString(json['summary'] ?? json['content']),
      sentiment: MemberModel._parseString(
        json['sentiment'],
        fallback: 'neutral',
      ),
    );
  }

  @override
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

class SocialContributionModel extends SocialContribution {
  const SocialContributionModel({
    required super.id,
    required super.type,
    required super.description,
    required super.date,
    required super.source,
  });

  factory SocialContributionModel.fromJson(Map<String, dynamic> json) {
    return SocialContributionModel(
      id: MemberModel._parseString(json['id']),
      type: MemberModel._parseString(json['type']),
      description: MemberModel._parseString(json['description']),
      date: MemberModel._parseDate(json['date'] ?? json['timestamp']),
      source: MemberModel._parseString(json['source']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'date': date.toIso8601String(),
      'source': source,
    };
  }
}
