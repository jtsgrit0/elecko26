import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:elecko26_new/core/config/app_config.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:elecko26_new/core/utils/asset_loader.dart';

import 'nesdc_pdf_text_extractor_stub.dart'
    if (dart.library.ui) 'nesdc_pdf_text_extractor.dart';

import 'package:elecko26_new/core/config/refresh_config.dart';
import 'package:elecko26_new/data/datasources/local_storage_service.dart';

// All other classes and methods from the original file are kept,
// except for the parts that use flutter_inappwebview.

final bool kIsNesdcProxyEnabled = AppConfig.kNesdcBaseUrl.trim().isNotEmpty;

final Uri _nesdcOrigin = Uri.parse('https://www.nesdc.go.kr');

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

  Map<String, dynamic> toJson() {
    return {
      'surveyDate': surveyDate?.toIso8601String(),
      'sampleSize': sampleSize,
      'marginOfError': marginOfError,
      'resultFileUrl': resultFileUrl,
      'detailText': detailText,
      'resultText': resultText,
      'fields': fields,
    };
  }

  double? findSupportRate(Iterable<String> names) {
    final source = resultText ?? detailText;
    if (source == null || source.isEmpty) {
      return null;
    }
    final uniqueNames = names
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final name in uniqueNames) {
      final value = _extractRate(source, name);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  double? _extractRate(String text, String name) {
    final normalizedName = _normalizeRateText(name);
    final lines = text.split(RegExp(r'[\r\n]+'));
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }
      final normalizedLine = _normalizeRateText(line);
      if (!normalizedLine.contains(normalizedName)) {
        continue;
      }

      final directMatch = RegExp(
              '${RegExp.escape(normalizedName)}[:：]?([0-9]{1,2}(?:\\.[0-9]+)?)%')
          .firstMatch(normalizedLine);
      if (directMatch != null) {
        final value = double.tryParse(directMatch.group(1) ?? '');
        if (value != null) {
          return value / 100;
        }
      }

      final reverseMatch = RegExp(
              '([0-9]{1,2}(?:\\.[0-9]+)?)%[^0-9]{0,6}${RegExp.escape(normalizedName)}')
          .firstMatch(normalizedLine);
      if (reverseMatch != null) {
        final value = double.tryParse(reverseMatch.group(1) ?? '');
        if (value != null) {
          return value / 100;
        }
      }

      final percentMatches = RegExp(r'([0-9]{1,2}(?:\.[0-9]+)?)%')
          .allMatches(normalizedLine)
          .toList();
      if (percentMatches.isNotEmpty) {
        final nameIndex = normalizedLine.indexOf(normalizedName);
        final best = percentMatches.reduce((a, b) {
          final aDist = (a.start - nameIndex).abs();
          final bDist = (b.start - nameIndex).abs();
          return aDist <= bDist ? a : b;
        });
        final value = double.tryParse(best.group(1) ?? '');
        if (value != null) {
          return value / 100;
        }
      }

      final hasRateKeyword = normalizedLine.contains('지지') ||
          normalizedLine.contains('득표') ||
          normalizedLine.contains('선호');
      if (hasRateKeyword) {
        final numberMatches =
            RegExp(r'([0-9]{1,2}(?:\.[0-9]+)?)').allMatches(normalizedLine);
        for (final match in numberMatches) {
          final value = double.tryParse(match.group(1) ?? '');
          if (value != null && value >= 0 && value <= 100) {
            return value / 100;
          }
        }
      }
    }

    final flat = _normalizeRateText(text.replaceAll('\n', ' '));
    final fallback = RegExp(
        '${RegExp.escape(normalizedName)}[:：]?([0-9]{1,2}(?:\\.[0-9]+)?)%');
    final fallbackMatch = fallback.firstMatch(flat);
    if (fallbackMatch != null) {
      final value = double.tryParse(fallbackMatch.group(1) ?? '');
      if (value != null) {
        return value / 100;
      }
    }
    return null;
  }

  String _normalizeRateText(String text) {
    return text.replaceAll(RegExp(r'[\s·•\-\(\)\[\]{}<>]'), '');
  }
}

class NesdcPollDataSource {
  NesdcPollDataSource({
    http.Client? client,
    AssetLoader? assetLoader,
    LocalStorageService? localStorageService,
  })  : _client = client ?? http.Client(),
        _assetLoader = assetLoader ?? AssetLoader(),
        _localStorageService = localStorageService;

  final http.Client _client;
  final AssetLoader _assetLoader;
  final LocalStorageService? _localStorageService;
  final Map<String, NesdcPollDetail> _detailCache = {};

  NesdcPollDetail? getCachedDetail(String url) => _detailCache[url];

  Future<List<NesdcPollEntry>> fetchLatest({int pages = 5}) async {
    return fetchPolls('');
  }

  Future<NesdcPollDetail?> fetchDetail(String detailUrl) async {
    return fetchPollDetail(detailUrl);
  }

  Future<List<NesdcPollEntry>> fetchPolls(String region) async {
    final cacheKey = 'nesdc_polls_$region';
    final cached = _localStorageService?.getString(cacheKey);
    if (cached != null) {
      try {
        final data = jsonDecode(cached) as List;
        return data.map((e) {
          final map = e as Map<String, dynamic>;
          return NesdcPollEntry(
            registrationNo: map['registrationNo'] ?? '',
            agency: map['agency'] ?? '',
            client: map['client'] ?? '',
            method: map['method'] ?? '',
            sampleFrame: map['sampleFrame'] ?? '',
            pollName: map['pollName'] ?? '',
            registeredDate: DateTime.tryParse(map['registeredDate'] ?? '') ??
                DateTime.now(),
            region: map['region'] ?? '',
            sourceUrl: map['sourceUrl'] ?? '',
            status: map['status'] as String?,
          );
        }).toList();
      } catch (e) {
        print('Failed to parse cached polls: $e');
      }
    }

    final target = _toTargetUri('/popup/cal_result.do');
    final response = await _client.post(
      _wrapProxy(target),
      headers: _defaultHeaders(),
      body: {
        'searchType': '1',
        'searchKeyword': region,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch polls: ${response.statusCode}');
    }

    final body = _decodeBody(response);
    final document = html_parser.parse(body);
    final rows = document.querySelectorAll('tbody > tr');
    final entries = <NesdcPollEntry>[];
    for (final row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 8) {
        continue;
      }
      final registrationNo = cells[0].text.trim();
      final agency = cells[1].text.trim();
      final client = cells[2].text.trim();
      final method = cells[3].text.trim();
      final sampleFrame = cells[4].text.trim();
      final pollName = cells[5].text.trim();
      final registeredDate = DateTime.tryParse(cells[6].text.trim());
      final region = cells[7].text.trim();
      final sourceUrl = cells[5].querySelector('a')?.attributes['href'];
      final status = cells.length > 8 ? cells[8].text.trim() : null;

      if (registeredDate == null || sourceUrl == null) {
        continue;
      }

      entries.add(
        NesdcPollEntry(
          registrationNo: registrationNo,
          agency: agency,
          client: client,
          method: method,
          sampleFrame: sampleFrame,
          pollName: pollName,
          registeredDate: registeredDate,
          region: region,
          sourceUrl: sourceUrl,
          status: status,
        ),
      );
    }

    final cacheData = jsonEncode(entries
        .map((e) => {
              'registrationNo': e.registrationNo,
              'agency': e.agency,
              'client': e.client,
              'method': e.method,
              'sampleFrame': e.sampleFrame,
              'pollName': e.pollName,
              'registeredDate': e.registeredDate.toIso8601String(),
              'region': e.region,
              'sourceUrl': e.sourceUrl,
              'status': e.status,
            })
        .toList());
    await _localStorageService?.setString(cacheKey, cacheData);

    return entries;
  }

  Future<NesdcPollDetail?> fetchPollDetail(String detailUrl) async {
    final cachedDetail = _detailCache[detailUrl];
    if (cachedDetail != null) {
      return cachedDetail;
    }

    final cacheKey = 'nesdc_poll_detail_${detailUrl.hashCode}';
    final cached = _localStorageService?.getString(cacheKey);
    if (cached != null) {
      try {
        final detail = NesdcPollDetail.fromJson(jsonDecode(cached),
            detailUrl: detailUrl);
        _detailCache[detailUrl] = detail;
        return detail;
      } catch (e) {
        print('Failed to parse cached poll detail: $e');
      }
    }

    String? body;
    // Web environment does not support HeadlessInAppWebView.
    // Fallback to http proxy method.
    final target = _toTargetUri(detailUrl);
    final response =
        await _client.get(_wrapProxy(target), headers: _defaultHeaders());
    if (response.statusCode == 200) {
      body = _decodeBody(response);
    } else {
      return null;
    }

    final document = html_parser.parse(body);
    final fields = <String, String>{};
    final rows = document.querySelectorAll('tbody > tr');
    for (final row in rows) {
      final th = row.querySelector('th');
      final td = row.querySelector('td');
      if (th != null && td != null) {
        fields[th.text.trim()] = td.text.trim();
      }
    }

    final surveyDate = DateTime.tryParse(fields['조사기간'] ?? '');
    final sampleSize = int.tryParse(
        (fields['조사완료사례수'] ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
    final marginOfError = double.tryParse(
        (fields['최대허용 표본오차'] ?? '').replaceAll(RegExp(r'[^0-9.]'), ''));
    final resultFileUrl =
        document.querySelector('a[href*=".pdf"]')?.attributes['href'];

    String? detailText;
    try {
      detailText = document.body?.text.trim();
    } catch (e) {
      print('Failed to extract detail text: $e');
    }

    String? resultText;
    if (resultFileUrl != null) {
      try {
        final url = _toTargetUri(resultFileUrl);
        final response = await _client.get(_wrapProxy(url));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          resultText = extractPdfText(bytes);
        }
      } catch (e) {
        print('Failed to fetch or parse PDF: $e');
      }
    }

    final detail = NesdcPollDetail(
      detailUrl: detailUrl,
      surveyDate: surveyDate,
      sampleSize: sampleSize,
      marginOfError: marginOfError,
      resultFileUrl: resultFileUrl,
      detailText: detailText,
      resultText: resultText,
      fields: fields,
    );

    _detailCache[detailUrl] = detail;
    await _localStorageService?.setString(cacheKey, jsonEncode(detail.toJson()));
    return detail;
  }

  Uri _toTargetUri(String path) {
    if (path.startsWith('http')) {
      return Uri.parse(path);
    }
    return _nesdcOrigin.replace(path: path);
  }

  Uri _wrapProxy(Uri target) {
    if (kIsNesdcProxyEnabled) {
      return Uri.parse(AppConfig.kNesdcBaseUrl)
          .replace(queryParameters: {'url': target.toString()});
    }
    return target;
  }

  Map<String, String> _defaultHeaders() {
    return {
      'User-Agent': AppConfig.kDefaultUserAgent,
    };
  }

  String _decodeBody(http.Response response) {
    try {
      return utf8.decode(response.bodyBytes);
    } catch (e) {
      return response.body;
    }
  }
}
