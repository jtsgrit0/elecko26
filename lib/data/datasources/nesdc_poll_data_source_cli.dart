import 'dart:convert';
import 'dart:io';

import 'package:elecko26_new/core/config/app_config.dart';
import 'package:elecko26_new/core/config/refresh_config.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class NesdcPollEntry {
  final String registrationNo;
  final String agency;
  final String client;
  final String method;
  final String sampleFrame;
  final String pollName;
  final DateTime registeredDate;
  final String region;
  final String sourceUrl;
  final String? status;

  NesdcPollEntry({
    required this.registrationNo,
    required this.agency,
    required this.client,
    required this.method,
    required this.sampleFrame,
    required this.pollName,
    required this.registeredDate,
    required this.region,
    required this.sourceUrl,
    this.status,
  });
}

class NesdcPollDetail {
  final String detailUrl;
  final DateTime? surveyDate;
  final int? sampleSize;
  final double? marginOfError;
  final String? resultFileUrl;
  final String? detailText;
  final String? resultText;
  final Map<String, String> fields;

  NesdcPollDetail({
    required this.detailUrl,
    required this.surveyDate,
    required this.sampleSize,
    required this.marginOfError,
    required this.resultFileUrl,
    required this.detailText,
    required this.resultText,
    required this.fields,
  });

  factory NesdcPollDetail.fromJson(Map<String, dynamic> json,
      {required String detailUrl}) {
    DateTime? parseDate(String? value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      final normalized = value.replaceAll('.', '-').replaceAll('/', '-');
      return DateTime.tryParse(normalized);
    }

    return NesdcPollDetail(
      detailUrl: detailUrl,
      surveyDate: parseDate(json['surveyDate'] as String?),
      sampleSize: (json['sampleSize'] as num?)?.toInt(),
      marginOfError: (json['marginOfError'] as num?)?.toDouble(),
      resultFileUrl: json['resultFileUrl'] as String?,
      detailText: json['detailText'] as String?,
      resultText: json['resultText'] as String?,
      fields: (json['fields'] as Map?)?.map(
            (key, value) => MapEntry('$key', '$value'),
          ) ??
          <String, String>{},
    );
  }
}

class NesdcPollDataSourceCli {
  NesdcPollDataSourceCli({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, NesdcPollDetail> _detailCache = {};

  Future<List<NesdcPollEntry>> fetchLatest({int pages = kNesdcPagesToFetch}) async {
    final localEntries = await _loadLocalEntries();
    if (localEntries.isNotEmpty) {
      return localEntries;
    }

    final remoteEntries = await _loadRemoteEntries();
    if (remoteEntries.isNotEmpty) {
      return remoteEntries;
    }

    return <NesdcPollEntry>[];
  }

  Future<NesdcPollDetail?> fetchDetail(String detailUrl) async {
    final cached = _detailCache[detailUrl];
    if (cached != null) {
      return cached;
    }

    final localDetail = await _loadCachedDetail(detailUrl);
    if (localDetail != null) {
      _detailCache[detailUrl] = localDetail;
      return localDetail;
    }

    final target = _toTargetUri(detailUrl);
    final response = await _client.get(target, headers: _defaultHeaders());
    if (response.statusCode != 200) {
      return null;
    }

    final body = _decodeBody(response);
    final document = html_parser.parse(body);
    final fields = _extractFields(document);
    final detailText = document.body?.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final resultFileUrl = _findResultFileUrl(document);

    final detail = NesdcPollDetail(
      detailUrl: detailUrl,
      surveyDate: _parseDate(fields, detailText),
      sampleSize: _parseSampleSize(fields, detailText),
      marginOfError: _parseMarginOfError(fields, detailText),
      resultFileUrl: resultFileUrl,
      detailText: detailText,
      resultText: null,
      fields: fields,
    );

    _detailCache[detailUrl] = detail;
    return detail;
  }

  Future<List<NesdcPollEntry>> _loadLocalEntries() async {
    for (final path in const [
      'data/nesdc_polls.json',
      'assets/data/nesdc_polls.json',
    ]) {
      final file = File(path);
      if (!await file.exists()) {
        continue;
      }
      final entries = _parsePollsJson(await file.readAsString());
      if (entries.isNotEmpty) {
        return entries;
      }
    }
    return <NesdcPollEntry>[];
  }

  Future<List<NesdcPollEntry>> _loadRemoteEntries() async {
    try {
      final response = await _client.get(Uri.parse(AppConfig.nesdcDataUrl));
      if (response.statusCode != 200) {
        return <NesdcPollEntry>[];
      }
      return _parsePollsJson(response.body);
    } catch (_) {
      return <NesdcPollEntry>[];
    }
  }

  Future<NesdcPollDetail?> _loadCachedDetail(String detailUrl) async {
    for (final path in const [
      'data/nesdc_polls.json',
      'assets/data/nesdc_polls.json',
    ]) {
      final file = File(path);
      if (!await file.exists()) {
        continue;
      }
      final decoded = jsonDecode(await file.readAsString());
      final rawEntries = decoded is List
          ? decoded
          : (decoded is Map ? decoded['entries'] : null);
      if (rawEntries is! List) {
        continue;
      }

      for (final raw in rawEntries) {
        if (raw is! Map) {
          continue;
        }
        final sourceUrl = '${raw['sourceUrl'] ?? ''}';
        if (sourceUrl != detailUrl) {
          continue;
        }
        final detailJson = raw['detail'];
        if (detailJson is Map) {
          return NesdcPollDetail.fromJson(
            Map<String, dynamic>.from(detailJson),
            detailUrl: detailUrl,
          );
        }
      }
    }
    return null;
  }

  List<NesdcPollEntry> _parsePollsJson(String jsonString) {
    final decoded = jsonDecode(jsonString);
    final rawEntries = decoded is List
        ? decoded
        : (decoded is Map ? decoded['entries'] : null);
    if (rawEntries is! List) {
      return <NesdcPollEntry>[];
    }

    final entries = <NesdcPollEntry>[];
    for (final raw in rawEntries) {
      if (raw is! Map) {
        continue;
      }

      final registeredDate =
          DateTime.tryParse('${raw['registeredDate']}') ?? DateTime.now();
      final entry = NesdcPollEntry(
        registrationNo: '${raw['registrationNo'] ?? ''}',
        agency: '${raw['agency'] ?? ''}',
        client: '${raw['client'] ?? ''}',
        method: '${raw['method'] ?? ''}',
        sampleFrame: '${raw['sampleFrame'] ?? ''}',
        pollName: '${raw['pollName'] ?? ''}',
        registeredDate: registeredDate,
        region: '${raw['region'] ?? ''}',
        sourceUrl: '${raw['sourceUrl'] ?? ''}',
        status: raw['status'] == null ? null : '${raw['status']}',
      );
      entries.add(entry);

      final detailJson = raw['detail'];
      if (detailJson is Map) {
        _detailCache[entry.sourceUrl] = NesdcPollDetail.fromJson(
          Map<String, dynamic>.from(detailJson),
          detailUrl: entry.sourceUrl,
        );
      }
    }
    return entries;
  }

  DateTime? _parseDate(Map<String, String> fields, String? detailText) {
    final fromField = fields.entries
        .firstWhere(
          (e) => e.key.contains('조사기간'),
          orElse: () => const MapEntry('', ''),
        )
        .value;
    if (fromField.isNotEmpty) {
      final normalized = fromField.split('~').first.trim();
      return DateTime.tryParse(normalized.replaceAll('.', '-'));
    }
    return null;
  }

  int? _parseSampleSize(Map<String, String> fields, String? detailText) {
    final fromField = fields.entries
        .firstWhere(
          (e) => e.key.contains('사례수'),
          orElse: () => const MapEntry('', ''),
        )
        .value;
    if (fromField.isNotEmpty) {
      return int.tryParse(fromField.replaceAll(RegExp(r'[^0-9]'), ''));
    }
    return null;
  }

  double? _parseMarginOfError(Map<String, String> fields, String? detailText) {
    final fromField = fields.entries
        .firstWhere(
          (e) => e.key.contains('표본오차'),
          orElse: () => const MapEntry('', ''),
        )
        .value;
    if (fromField.isNotEmpty) {
      final match = RegExp(r'([0-9.]+)%').firstMatch(fromField);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '');
      }
    }
    return null;
  }

  Map<String, String> _extractFields(html_dom.Document document) {
    final fields = <String, String>{};
    final ths = document.querySelectorAll('th');
    for (final th in ths) {
      final key = th.text.trim();
      final value = th.nextElementSibling?.text.trim();
      if (key.isNotEmpty && value != null && value.isNotEmpty) {
        fields[key] = value;
      }
    }
    return fields;
  }

  String? _findResultFileUrl(html_dom.Document document) {
    final links = document.querySelectorAll('a');
    for (final link in links) {
      final href = link.attributes['href'];
      if (href != null && (href.endsWith('.pdf') || href.endsWith('.hwp'))) {
        return href;
      }
    }
    return null;
  }

  Uri _toTargetUri(String urlOrPath) {
    final uri = Uri.parse(urlOrPath);
    if (uri.hasScheme) {
      return uri;
    }
    return Uri.parse('https://www.nesdc.go.kr').resolve(urlOrPath);
  }

  Map<String, String> _defaultHeaders() {
    return const {
      'User-Agent': AppConfig.kDefaultUserAgent,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    };
  }

  String _decodeBody(http.Response response) {
    try {
      return utf8.decode(response.bodyBytes);
    } catch (_) {
      return response.body;
    }
  }
}
