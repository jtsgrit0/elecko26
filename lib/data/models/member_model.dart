import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/poll.dart';

/// Member 모델 (API 응답용)
class MemberModel extends Member {
  const MemberModel({
    required super.id,
    required super.name,
    required super.party,
    required super.district,
    super.description,
    super.imageUrl,
    super.polls,
    super.electionPossibility,
    super.isFavorite,
    super.pressReports,
    super.historical2018PartyRates,
    super.lastAnalysisDate,
    super.achievementsList,
    super.policies,
    super.improvementPoints,
    super.socialContributions,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    // 날짜 파싱 안전 장치
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      if (dateValue is String) {
        return DateTime.tryParse(dateValue);
      }
      return null;
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    List<String> parseStringList(dynamic value) {
      if (value is! List) {
        return <String>[];
      }
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    List<PressReport> parsePressReports(dynamic value) {
      if (value is! List) {
        return <PressReport>[];
      }
      return value
          .whereType<Map>()
          .map((e) => PressReportModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<SocialContribution> parseSocialContributions(dynamic value) {
      if (value is! List) {
        return <SocialContribution>[];
      }
      return value
          .whereType<Map>()
          .map((e) =>
              SocialContributionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    Map<String, double> parseHistoricalRates(dynamic value) {
      if (value is! Map) return <String, double>{};

      return value
          .map((key, val) => MapEntry(key.toString(), parseDouble(val)));
    }

    return MemberModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '알 수 없음') as String,
      party: (json['party'] ?? '무소속') as String,
      district: (json['district'] ?? '전국') as String,
      description: (json['description'] ?? '') as String,
      imageUrl: (json['imageUrl'] ?? '') as String,
      achievementsList: parseStringList(json['achievementsList']),
      policies: parseStringList(json['policies']),
      pressReports: parsePressReports(json['pressReports']),
      polls: (json['polls'] as List? ?? [])
          .map((e) => PollModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      electionPossibility: parseDouble(json['electionPossibility']),
      lastAnalysisDate: parseDate(json['lastAnalysisDate']),
      improvementPoints: parseStringList(json['improvementPoints']),
      socialContributions: parseSocialContributions(
        json['socialContributions'],
      ),
      isFavorite: json['isFavorite'] as bool? ?? false,
      historical2018PartyRates:
          parseHistoricalRates(json['historical2018PartyRates']),
    );
  }

  @override
  MemberModel copyWith({
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
    return MemberModel(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'party': party,
      'district': district,
      'description': description,
      'imageUrl': imageUrl,
      'achievementsList': achievementsList,
      'policies': policies,
      'pressReports':
          pressReports.map((e) => (e as PressReportModel).toJson()).toList(),
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
      'lastAnalysisDate': lastAnalysisDate?.toIso8601String(),
      'improvementPoints': improvementPoints,
      'socialContributions': socialContributions
          .map((e) => (e as SocialContributionModel).toJson())
          .toList(),
      'isFavorite': isFavorite,
      'historical2018PartyRates': historical2018PartyRates,
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
      id: (json['id'] ?? '') as String,
      pollAgency: (json['pollAgency'] ?? '') as String,
      surveyDate: DateTime.tryParse(json['surveyDate'] as String? ?? '') ??
          DateTime.now(),
      supportRate: supportRateValue == null
          ? null
          : (supportRateValue as num).toDouble(),
      partyName: (json['partyName'] ?? '') as String,
      sampleSize:
          sampleSizeValue == null ? null : (sampleSizeValue as num).toInt(),
      marginOfError:
          marginValue == null ? null : (marginValue as num).toDouble(),
      source: (json['source'] ?? '') as String,
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
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      source: (json['source'] ?? '') as String,
      url: (json['url'] ?? json['link'] ?? '') as String,
      publishDate: DateTime.tryParse(json['publishDate'] as String? ?? '') ??
          DateTime.now(),
      summary: (json['summary'] ?? json['content'] ?? '') as String,
      sentiment: (json['sentiment'] ?? 'neutral') as String,
    );
  }

  @override
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
      id: (json['id'] ?? '') as String,
      type: (json['type'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      source: (json['source'] ?? '') as String,
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
