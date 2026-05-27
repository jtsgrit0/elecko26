import 'package:equatable/equatable.dart';

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

  SocialContribution copyWith({
    String? id,
    String? type,
    String? description,
    DateTime? date,
    String? source,
  }) {
    return SocialContribution(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      source: source ?? this.source,
    );
  }

  @override
  List<Object?> get props => [id, type, description, date, source];

  factory SocialContribution.fromJson(Map<String, dynamic> json) {
    return SocialContribution(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(
            (json['timestamp'] as num?)?.toInt() ?? 0,
          ),
      source: (json['source'] ?? '').toString(),
    );
  }

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
