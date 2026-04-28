import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/poll.dart';

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
    required super.socialContributions,
    super.isFavorite,
    super.historical2018PartyRates,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    // 날짜 파싱 안전 장치
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is String) {
        return DateTime.tryParse(dateValue) ?? DateTime.now();
      }
      return DateTime.now();
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
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
      if (value is! Map) return const {};
      return value.map((key, val) => MapEntry(key.toString(), parseDouble(val)));
    }

    return MemberModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '알 수 없음') as String,
      party: (json['party'] ?? '무소속') as String,
      district: (json['district'] ?? '전국') as String,
      imageUrl: (json['imageUrl'] ?? '') as String,
      bio: (json['bio'] ?? '') as String,
      electionDate: parseDate(json['electionDate']),
      term: parseInt(json['term']),
      achievementsList: parseStringList(json['achievementsList']),
      actions: parseStringList(json['actions']),
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
      historical2018PartyRates: parseHistoricalRates(json['historical2018PartyRates']),
    );
  }

  @override
  MemberModel copyWith({
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
    List<SocialContribution>? socialContributions,
    bool? isFavorite,
    Map<String, double>? historical2018PartyRates,
  }) {
    return MemberModel(
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
      socialContributions: socialContributions ?? this.socialContributions,
      isFavorite: isFavorite ?? this.isFavorite,
      historical2018PartyRates: historical2018PartyRates ?? this.historical2018PartyRates,
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
      'lastAnalysisDate': lastAnalysisDate.toIso8601String(),
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
  SocialContributionModel({
    required super.title,
    required super.date,
    required super.type,
    super.amount,
    required super.summary,
  });

  factory SocialContributionModel.fromJson(Map<String, dynamic> json) {
    return SocialContributionModel(
      title: (json['title'] ?? '') as String,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      type: (json['type'] ?? '') as String,
      amount: json['amount'] as String?,
      summary: (json['summary'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date.toIso8601String(),
      'type': type,
      'amount': amount,
      'summary': summary,
    };
  }
}
