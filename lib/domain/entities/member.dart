import 'package:equatable/equatable.dart';
import 'package:elecko26_new/domain/entities/party.dart';

class Member extends Equatable {
  final String id;
  final String name;
  final Party? party;
  final String constituency;
  final int electionCount;
  final DateTime termStartDate;
  final DateTime termEndDate;
  final DateTime birthDate;
  final String gender;
  final String education;
  final String career;
  final String? facebookUrl;
  final String? twitterUrl;
  final String? youtubeUrl;
  final String? blogUrl;

  const Member({
    required this.id,
    required this.name,
    this.party,
    required this.constituency,
    required this.electionCount,
    required this.termStartDate,
    required this.termEndDate,
    required this.birthDate,
    required this.gender,
    required this.education,
    required this.career,
    this.facebookUrl,
    this.twitterUrl,
    this.youtubeUrl,
    this.blogUrl,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        party,
        constituency,
        electionCount,
        termStartDate,
        termEndDate,
        birthDate,
        gender,
        education,
        career,
        facebookUrl,
        twitterUrl,
        youtubeUrl,
        blogUrl,
      ];

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      name: json['name'] as String,
      party: json['party'] != null ? Party.fromJson(json['party']) : null,
      constituency: json['constituency'] as String,
      electionCount: json['electionCount'] as int,
      termStartDate: DateTime.parse(json['termStartDate'] as String),
      termEndDate: DateTime.parse(json['termEndDate'] as String),
      birthDate: DateTime.parse(json['birthDate'] as String),
      gender: json['gender'] as String,
      education: json['education'] as String,
      career: json['career'] as String,
      facebookUrl: json['facebookUrl'] as String?,
      twitterUrl: json['twitterUrl'] as String?,
      youtubeUrl: json['youtubeUrl'] as String?,
      blogUrl: json['blogUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'party': party?.toJson(),
      'constituency': constituency,
      'electionCount': electionCount,
      'termStartDate': termStartDate.toIso8601String(),
      'termEndDate': termEndDate.toIso8601String(),
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'education': education,
      'career': career,
      'facebookUrl': facebookUrl,
      'twitterUrl': twitterUrl,
      'youtubeUrl': youtubeUrl,
      'blogUrl': blogUrl,
    };
  }
}
