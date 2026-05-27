import 'package:equatable/equatable.dart';

/// 후보 상세보기 및 여론조사 데이터용 Poll 엔티티
class Poll extends Equatable {
  final String id;
  final String pollAgency;
  final DateTime surveyDate;
  final double? supportRate;
  final String partyName;
  final int? sampleSize;
  final double? marginOfError;
  final String source;
  final String? notes;

  const Poll({
    required this.id,
    required this.pollAgency,
    required this.surveyDate,
    this.supportRate,
    required this.partyName,
    this.sampleSize,
    this.marginOfError,
    required this.source,
    this.notes,
  });

  Poll copyWith({
    String? id,
    String? pollAgency,
    DateTime? surveyDate,
    double? supportRate,
    String? partyName,
    int? sampleSize,
    double? marginOfError,
    String? source,
    String? notes,
  }) {
    return Poll(
      id: id ?? this.id,
      pollAgency: pollAgency ?? this.pollAgency,
      surveyDate: surveyDate ?? this.surveyDate,
      supportRate: supportRate ?? this.supportRate,
      partyName: partyName ?? this.partyName,
      sampleSize: sampleSize ?? this.sampleSize,
      marginOfError: marginOfError ?? this.marginOfError,
      source: source ?? this.source,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        pollAgency,
        surveyDate,
        supportRate,
        partyName,
        sampleSize,
        marginOfError,
        source,
        notes,
      ];

  factory Poll.fromJson(Map<String, dynamic> json) {
    final supportRateValue = json['supportRate'];
    final sampleSizeValue = json['sampleSize'];
    final marginValue = json['marginOfError'];
    return Poll(
      id: (json['id'] ?? '').toString(),
      pollAgency: (json['pollAgency'] ?? '').toString(),
      surveyDate: DateTime.tryParse(json['surveyDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(
            (json['surveyTimestamp'] as num?)?.toInt() ?? 0,
          ),
      supportRate: supportRateValue == null
          ? null
          : (supportRateValue as num).toDouble(),
      partyName: (json['partyName'] ?? '').toString(),
      sampleSize:
          sampleSizeValue == null ? null : (sampleSizeValue as num).toInt(),
      marginOfError:
          marginValue == null ? null : (marginValue as num).toDouble(),
      source: (json['source'] ?? '').toString(),
      notes: json['notes']?.toString(),
    );
  }

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
