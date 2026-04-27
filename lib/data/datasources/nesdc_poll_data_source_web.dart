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
    LocalStorageService? localStorageService,
  })  : _client = client ?? http.Client(),
        _localStorageService = localStorageService;

  final http.Client _client;
  final LocalStorageService? _localStorageService;
  final Map<String, NesdcPollDetail> _detailCache = {};

  /// 캐시된 상세 정보를 가져옵니다 (refreshMembers 최적화용)
  NesdcPollDetail? getCachedDetail(String url) => _detailCache[url];

  static const String _kPollsCacheKey = 'cached_nesdc_polls_json';

  Future<List<NesdcPollEntry>> fetchLatest(
      {int pages = kNesdcPagesToFetch}) async {
    // 1단계: GitHub에서 최신 데이터 다운로드 시도
    final remoteEntries = await _fetchFromRemoteGitHub();
    if (remoteEntries != null && remoteEntries.isNotEmpty) {
      return remoteEntries;
    }

    // 2단계: 로컬 캐시 확인
    final cachedEntries = await _fetchFromLocalCache();
    if (cachedEntries != null && cachedEntries.isNotEmpty) {
      return cachedEntries;
    }

    // 3단계: 기본 번들 자산(assets) 사용
    final bundledEntries = await _fetchFromBundledAssets();
    if (bundledEntries.isNotEmpty) {
      return bundledEntries;
    }

    // 웹에서는 직접 크롤링을 지원하지 않으므로 빈 리스트 반환
    return [];
  }

  Future<List<NesdcPollEntry>?> _fetchFromRemoteGitHub() async {
    try {
      final response = await _client.get(Uri.parse(AppConfig.nesdcDataUrl));
      if (response.statusCode == 200) {
        final jsonString = response.body;
        if (_localStorageService != null) {
          await _localStorageService!.setString(_kPollsCacheKey, jsonString);
        }
        return await _parsePollsJson(jsonString);
      }
    } catch (e) {
      print('⚠️ NesdcPollDataSource: Failed to download from GitHub: $e');
    }
    return null;
  }

  /// 로컬 스토리지에 캐시된 데이터를 로드합니다.
  Future<List<NesdcPollEntry>?> _fetchFromLocalCache() async {
    if (_localStorageService == null) return null;
    try {
      final cachedJson = _localStorageService!.getString(_kPollsCacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        return await _parsePollsJson(cachedJson);
      }
    } catch (e) {
      print('⚠️ NesdcPollDataSource: Failed to load from local cache: $e');
    }
    return null;
  }

  /// 앱에 번들링된 기본 에셋 데이터를 로드합니다.
  Future<List<NesdcPollEntry>> _fetchFromBundledAssets() async {
    try {
      final jsonString = await AssetLoader.loadString('data/nesdc_polls.json');
      return await _parsePollsJson(jsonString);
    } catch (e) {
      print('⚠️ NesdcPollDataSource: Failed to load from bundled assets: $e');
    }
    return [];
  }

  /// JSON 문자열을 파싱하여 NesdcPollEntry 리스트로 변환합니다.
  Future<List<NesdcPollEntry>> _parsePollsJson(String jsonString) async {
    final decoded = jsonDecode(jsonString);
    final rawEntries = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> ? decoded['entries'] : null);
    if (rawEntries is! List) return [];

    final List<NesdcPollEntry> entries = [];
    int count = 0;
    for (final raw in rawEntries) {
      if (raw is! Map<String, dynamic>) continue;

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
      if (detailJson is Map<String, dynamic>) {
        _detailCache[entry.sourceUrl] = NesdcPollDetail.fromJson(
          detailJson,
          detailUrl: entry.sourceUrl,
        );
      }
      
      // 대량 데이터 파싱 시 메인 스레드 프리징 방지
      count++;
      if (count % 200 == 0) {
        await Future.delayed(Duration.zero);
      }
    }
    return entries;
  }

  Future<NesdcPollDetail?> fetchDetail(String detailUrl) async {
    if (_detailCache.containsKey(detailUrl)) {
      return _detailCache[detailUrl];
    }

    String? body;
    // 웹 환경에서는 InAppWebView를 사용할 수 없으므로 http로 바로 요청합니다.
    final target = _toTargetUri(detailUrl);
    final response =
        await _client.get(_wrapProxy(target), headers: _defaultHeaders());
    if (response.statusCode == 200) {
      body = _decodeBody(response);
    } else {
      return null;
    }

    final document = html_parser.parse(body);

    final fields = _extractFields(document);
    final tableText = _extractTableText(document);
    final detailText = _mergeDetailText(document.outerHtml, tableText);

    final surveyDate = _parseSurveyDate(fields, detailText);
    var sampleSize = _parseSampleSize(fields, detailText);
    var marginOfError = _parseMarginOfError(fields, detailText);

    final resultFileUrl = _findResultFileUrl(document);
    String? resultText;
    if (resultFileUrl != null) {
      final fileTarget = _toTargetUri(resultFileUrl);
      final fileResponse =
          await _client.get(_wrapProxy(fileTarget), headers: _defaultHeaders());
      if (fileResponse.statusCode == 200) {
        resultText = _tryExtractPdfText(fileResponse.bodyBytes);
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
    return detail;
  }

  Uri _buildListUri(int page) {
    final target = _nesdcOrigin.replace(
      path: '/portal/bbs/B0000005/list.do',
      queryParameters: {
        'menuNo': '200467',
        'pageIndex': '$page',
      },
    );
    return _wrapProxy(target);
  }

  Uri _wrapProxy(Uri target) {
    final base = Uri.parse(AppConfig.kNesdcBaseUrl);
    if (base.host.contains('nesdc.go.kr')) {
      return target;
    }
    return base.replace(queryParameters: {'url': target.toString()});
  }

  Uri _toTargetUri(String urlOrPath) {
    final uri = Uri.parse(urlOrPath);
    if (uri.hasScheme) {
      return uri;
    }
    return _nesdcOrigin.resolve(urlOrPath);
  }

  Map<String, String> _defaultHeaders() {
    return const {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
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

  String _extractTableText(html_dom.Document document) {
    final buffer = StringBuffer();
    final tables = document.querySelectorAll('table');
    for (final table in tables) {
      buffer.writeln(table.text.replaceAll(RegExp(r'\s+'), ' ').trim());
    }
    return buffer.toString();
  }

  String _mergeDetailText(String html, String tableText) {
    final text = html_parser
        .parse(html)
        .body
        ?.text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${text ?? ''}\n\n$tableText';
  }

  DateTime? _parseSurveyDate(Map<String, String> fields, String detailText) {
    final fromField = fields.entries
        .firstWhere((e) => e.key.contains('조사기간'),
            orElse: () => const MapEntry('', ''))
        .value;
    if (fromField.isNotEmpty) {
      final parts =
          fromField.split(RegExp(r'~|~')).map((e) => e.trim()).toList();
      if (parts.isNotEmpty) {
        return DateTime.tryParse(parts.first.replaceAll('.', '-'));
      }
    }
    return null;
  }

  int? _parseSampleSize(Map<String, String> fields, String detailText) {
    final fromField = fields.entries
        .firstWhere((e) => e.key.contains('사례수'),
            orElse: () => const MapEntry('', ''))
        .value;
    if (fromField.isNotEmpty) {
      return int.tryParse(fromField.replaceAll(RegExp(r'[^0-9]'), ''));
    }
    return null;
  }

  double? _parseMarginOfError(Map<String, String> fields, String detailText) {
    final fromField = fields.entries
        .firstWhere((e) => e.key.contains('표본오차'),
            orElse: () => const MapEntry('', ''))
        .value;
    if (fromField.isNotEmpty) {
      final match = RegExp(r'([0-9.]+)%').firstMatch(fromField);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '');
      }
    }
    return null;
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

  String? _tryExtractPdfText(Uint8List bytes) {
    try {
      return extractPdfText(bytes);
    } catch (e) {
      print('⚠️ NesdcPollDataSource: Failed to extract PDF text: $e');
      return null;
    }
  }
}
