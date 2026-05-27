import 'package:equatable/equatable.dart';

class PressReport extends Equatable {
  final String id;
  final String title;
  final String source;
  final String url;
  final DateTime publishDate;
  final String summary;
  final String sentiment;

  const PressReport({
    required this.id,
    required this.title,
    required this.source,
    required this.url,
    required this.publishDate,
    required this.summary,
    required this.sentiment,
  });

  PressReport copyWith({
    String? id,
    String? title,
    String? source,
    String? url,
    DateTime? publishDate,
    String? summary,
    String? sentiment,
  }) {
    return PressReport(
      id: id ?? this.id,
      title: title ?? this.title,
      source: source ?? this.source,
      url: url ?? this.url,
      publishDate: publishDate ?? this.publishDate,
      summary: summary ?? this.summary,
      sentiment: sentiment ?? this.sentiment,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        source,
        url,
        publishDate,
        summary,
        sentiment,
      ];

  factory PressReport.fromJson(Map<String, dynamic> json) {
    return PressReport(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      url: (json['url'] ?? json['link'] ?? '').toString(),
      publishDate: DateTime.tryParse(json['publishDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(
            (json['publishTimestamp'] as num?)?.toInt() ?? 0,
          ),
      summary: (json['summary'] ?? json['content'] ?? '').toString(),
      sentiment: (json['sentiment'] ?? 'neutral').toString(),
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
